-- ============================================================================
-- 0042 — T5-07: "bahan terbuang" ditentukan PELADEN, bukan dititipkan klien
-- ============================================================================
-- CACAT YANG DITUTUP (ditemukan 2026-09-23 saat mengerjakan T5-07)
--
-- Kolom `pembatalan.bahan_terbuang` ada sejak `0010`, dipakai laporan kerugian,
-- dan ikut dikirim di hampir semua jalur uji — tetapi TIDAK PERNAH DIPERIKSA
-- satu pemicu pun. Satu-satunya yang dijaga `picu_pembatalan_sah()` (0015)
-- adalah `nilai_kerugian`; `bahan_terbuang` lolos apa adanya dari klien.
--
-- Akibat nyatanya persis kebalikan dari tujuan T5-07 ("kerugian terlihat sebagai
-- angka, bukan hilang diam-diam"):
--
--   1. Kasir membatalkan pesanan yang MAKANANNYA SUDAH DIMASAK, lalu mengirim
--      `bahan_terbuang = false`. Barisnya sah, PIN atasannya benar, nilainya
--      benar — tetapi di laporan kerugian bahan, pembatalan itu tidak muncul.
--      Bahan yang benar-benar terbuang jadi tidak terlihat. Karena tabel ini
--      append-only, angka salah itu bertahan selamanya sebagai "jejak resmi".
--   2. Sebaliknya, pembatalan SEBELUM dapur mulai bisa ditandai
--      `bahan_terbuang = true` — memompa angka kerugian untuk kejadian yang
--      tidak membuang apa pun (belum ada yang dimasak).
--
-- Pola yang dipakai di sini SAMA PERSIS dengan yang sudah terbukti untuk
-- `nilai_kerugian` di 0015, termasuk sikapnya terhadap nilai bawaan:
--
--   - Nilai BAWAAN kolom (`false`, sama seperti `nilai_kerugian = 0`) berarti
--     "peladen yang mengisi" — diterima, lalu ditimpa hitungan peladen. Ini
--     penting karena pemicu tidak bisa membedakan "klien mengirim false" dari
--     "klien tidak menyebut kolomnya sama sekali"; menolaknya akan mematahkan
--     semua pemanggil jujur yang memang menyerahkan pengisian ke peladen.
--   - Nilai NON-BAWAAN yang BERTENTANGAN dengan hitungan peladen (`true` pada
--     pembatalan pra-dapur) DITOLAK, bukan ditimpa diam-diam — persis seperti
--     `nilai_kerugian` non-nol yang tidak cocok. Perangkat yang salah paham
--     harus tahu sekarang, bukan nanti saat laporan bulanan tidak cocok.
--
-- ATURAN YANG DIKUNCI
--   - `sebelum_dapur`  → bahan_terbuang = false. Belum ada yang dimasak.
--   - `sesudah_dapur`  → bahan_terbuang = true. Dapur sudah menyentuh pesanan
--     ini; bahannya tidak bisa dikembalikan ke rak.
--
-- Perhatikan: yang menutup celah utama bukan penolakannya, melainkan penimpaan
-- wajib. Kasir yang membatalkan pesanan matang lalu mengirim `false` tetap
-- tercatat sebagai bahan terbuang — kerugiannya tidak bisa disembunyikan.
--
-- Yang sengaja TIDAK diubah: seluruh pagar lain di `picu_pembatalan_sah`
-- (tahap dari dua tanda, alasan wajib, kupon PIN sekali pakai, idempotensi,
-- nilai kerugian dari salinan harga) disalin apa adanya. Fungsi ditulis ulang
-- utuh karena Postgres tidak punya "tambal sebagian fungsi".
-- ============================================================================

create or replace function public.picu_pembatalan_sah()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  JENDELA_SETUJU_MENIT constant integer := 5;   -- bukti persetujuan PIN dianggap sah selama ini
  v_pesanan record;
  v_item    record;
  v_nilai   integer;
  v_tahap   text;
  v_status  text;
  v_kupon   bigint;   -- percobaan_pin.id = bigserial
  v_terbuang boolean; -- T5-07: dihitung peladen, tidak diterima dari klien
begin
  select p.id, p.dikirim_ke_dapur_pada, p.subtotal, p.status
    into v_pesanan
    from public.pesanan p where p.id = new.pesanan_id;
  if v_pesanan.id is null then
    raise exception 'Pesanan tidak ditemukan.';
  end if;

  -- TEMUAN AUD-3 F-05 (K-2): satu target hanya boleh dibatalkan SEKALI — kiriman
  -- ULANG (klik ganda kasir / antrean perangkat offline) dulu dihitung dua kali
  -- di laporan kerugian.
  if new.pesanan_item_id is not null then
    if (select pi.status from public.pesanan_item pi where pi.id = new.pesanan_item_id) = 'batal' then
      raise exception 'Item ini sudah dibatalkan — kiriman ulang tidak dicatat lagi (satu aksi = satu jejak).';
    end if;
  elsif v_pesanan.status = 'batal' then
    raise exception 'Pesanan ini sudah dibatalkan — kiriman ulang tidak dicatat lagi (satu aksi = satu jejak).';
  end if;

  -- "Dapur sudah mulai" ditentukan dari DUA tanda: waktu kirim ke dapur DAN status
  -- pesanan. Memakai satu tanda saja rapuh: kalau salah satu lupa diisi (mis. RPC
  -- memajukan status tanpa mencatat waktunya), pembatalan bisa lolos tanpa PIN.
  v_tahap := case
               when v_pesanan.dikirim_ke_dapur_pada is not null then 'sesudah_dapur'
               else 'sebelum_dapur'
             end;
  if v_tahap = 'sebelum_dapur' then
    select p.status into v_status from public.pesanan p where p.id = new.pesanan_id;
    if v_status in ('dimasak', 'siap', 'lunas') then
      v_tahap := 'sesudah_dapur';
    end if;
  end if;
  if new.tahap <> v_tahap then
    raise exception 'Tahap pembatalan tidak sesuai keadaan pesanan (seharusnya %).', v_tahap;
  end if;

  -- Setelah dapur mulai: wajib disetujui pengguna berizin (PIN atasan).
  if new.tahap = 'sesudah_dapur' then
    if new.disetujui_oleh is null then
      raise exception 'Pembatalan setelah dapur mulai wajib disetujui pengguna berizin (PIN).';
    end if;
    if not public.boleh_untuk(new.disetujui_oleh, 'void_sesudah_dapur') then
      raise exception 'Penyetuju itu tidak berizin menyetujui pembatalan setelah dapur mulai.';
    end if;
    -- KUPON SEKALI PAKAI (temuan review PR putaran8, PR-04): bukti harus TERIKAT
    -- pesanan ini dan BELUM DIPAKAI; begitu dipakai, ditandai.
    select pp.id into v_kupon
      from public.percobaan_pin pp
     where pp.pengguna_id = new.disetujui_oleh
       and pp.berhasil
       and pp.aksi = 'void_sesudah_dapur'
       and pp.pesanan_id = new.pesanan_id
       and pp.dipakai_pada is null
       and pp.waktu > now() - make_interval(mins => JENDELA_SETUJU_MENIT)
     order by pp.waktu
     limit 1
     for update;
    if v_kupon is null then
      raise exception 'Persetujuan belum terbukti untuk pesanan ini: penyetuju harus memasukkan PIN-nya sendiri untuk pesanan ini (maksimal % menit lalu).', JENDELA_SETUJU_MENIT;
    end if;
    update public.percobaan_pin set dipakai_pada = now() where id = v_kupon;
  else
    if not public.boleh('void_sebelum_dapur') then
      raise exception 'Anda tidak berizin membatalkan pesanan sebelum dapur mulai.';
    end if;
  end if;

  -- Nilai kerugian dari SALINAN HARGA (bukan harga menu sekarang).
  if new.pesanan_item_id is not null then
    select pi.pesanan_id, pi.subtotal into v_item
      from public.pesanan_item pi where pi.id = new.pesanan_item_id;
    if v_item.pesanan_id is null or v_item.pesanan_id <> new.pesanan_id then
      raise exception 'Baris item itu bukan milik pesanan ini.';
    end if;
    v_nilai := coalesce(v_item.subtotal, 0);
  else
    v_nilai := coalesce(
      nullif(v_pesanan.subtotal, 0),
      (select coalesce(sum(pi.subtotal), 0)::integer from public.pesanan_item pi where pi.pesanan_id = new.pesanan_id)
    );
  end if;

  -- TEMUAN review putaran11 PR-03 (K-3): nilai kiriman klien tidak dipercaya.
  if new.nilai_kerugian <> 0 and new.nilai_kerugian is distinct from coalesce(v_nilai, 0) then
    raise exception 'Nilai kerugian dihitung peladen dari salinan harga (%); angka kiriman (%) tidak boleh dikarang.',
      coalesce(v_nilai, 0), new.nilai_kerugian;
  end if;
  new.nilai_kerugian := coalesce(v_nilai, 0);

  -- ---------------------------------------------------------------- T5-07 ---
  -- Bahan terbuang mengikuti TAHAP, bukan kemauan perangkat. Tahap sendiri sudah
  -- dipaksa cocok dengan keadaan pesanan di atas, jadi ini tidak bisa diakali
  -- dengan mengirim tahap yang salah.
  v_terbuang := (new.tahap = 'sesudah_dapur');
  -- Kiriman non-bawaan yang bertentangan ditolak (lihat catatan di kepala berkas);
  -- kiriman bawaan `false` berarti "peladen yang mengisi" dan ditimpa di bawah.
  if new.bahan_terbuang and not v_terbuang then
    raise exception 'Dapur belum mulai memasak pesanan ini — pembatalannya TIDAK boleh ditandai bahan terbuang (laporan kerugian tidak boleh dipompa).';
  end if;
  new.bahan_terbuang := v_terbuang;

  if new.pelaku_id is null then
    new.pelaku_id := auth.uid();
  end if;
  -- Jejak pelaku tidak boleh dikarang klien (temuan audit AUD-3 K-2).
  if auth.uid() is not null and new.pelaku_id is distinct from auth.uid() then
    raise exception 'Pelaku pembatalan diisi sistem — tidak boleh menyebut orang lain.';
  end if;
  return new;
end
$$;

comment on function public.picu_pembatalan_sah() is
  'Menjaga pembatalan: alasan wajib, tahap (sebelum/sesudah dapur) menentukan izin, persetujuan PIN terikat pesanan & sekali pakai, nilai kerugian DAN penanda bahan terbuang dihitung peladen (T5-07, 0042), dan SATU target hanya boleh dibatalkan sekali (AUD-3 F-05).';
