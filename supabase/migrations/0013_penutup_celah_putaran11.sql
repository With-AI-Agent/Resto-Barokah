-- ============================================================================
-- 0013 — PENUTUP CELAH REVIEW PUTARAN 11 (laporan penuh peninjau, 4 temuan)
--
-- Kenapa migrasi baru: `0001`–`0012` DIBEKUKAN (aturan proyek). Perbaikan celah yang
-- ditemukan peninjau ditulis sebagai migrasi baru di atasnya.
--
-- Temuan yang ditutup di sini — SEMUANYA saya uji ulang sendiri dengan probe SQL sebelum
-- diperbaiki (probe-nya LULUS, artinya celahnya memang hidup di kode saat itu):
--   PR-01 (K-2, uang)   : diskon `jenis='voucher'` bisa dicatat kasir 100% subtotal tanpa voucher
--   PR-02 (K-3, status) : pesanan bisa LAHIR `lunas`/`batal`/`dikirim` lewat INSERT langsung
--   PR-03 (K-3, jejak)  : `nilai_kerugian` pembatalan bisa dikarang klien
--   PR-04 (K-4, dokumen): angka "21 berkas uji" basi (nyatanya 28) — diperbaiki di dokumen
--                         + dijaga pemeriksa (`alat/periksa-panduan.py`), bukan di migrasi ini
--
-- Cara membuktikan: `bash alat/uji-database.sh` harus `0 GAGAL`, dan
-- `python3 alat/uji-mutasi-0012.py` harus membuktikan tiap penjaga baru ini bisa MERAH.

-- ============================================================================
-- 1. DISKON VOUCHER — gagal-aman selama mesin voucher belum ada (TEMUAN PR-01)
-- ============================================================================
create or replace function public.picu_diskon_batas()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pesanan     record;
  v_sudah       integer;      -- total nilai diskon yang sudah ada
  v_jumlah      integer;      -- berapa diskon yang sudah tercatat
  v_tumpuk      boolean;      -- apakah resto mengizinkan tumpuk diskon
  v_cap_persen  numeric;      -- batas maks potongan resto (persen)
  v_cap_nominal integer;      -- batas maks potongan resto (rupiah; null = tanpa batas)
  v_total       integer;      -- total potongan sesudah baris ini
  v_persen      numeric;      -- persen EFEKTIF (dihitung dari uang, bukan dari klien)
begin
  select p.id, p.subtotal, p.penyewa_id into v_pesanan
    from public.pesanan p where p.id = new.pesanan_id;
  if v_pesanan.id is null then
    raise exception 'Pesanan tidak ditemukan.';
  end if;

  -- ------------------------------------------------------------------ jenis
  if new.jenis = 'manual' then
    -- Persen EFEKTIF dihitung dari UANG (nilai diskon / subtotal pesanan), bukan dari kolom
    -- `persen` kiriman klien — temuan audit AUD-3 K-2 (B F-06).
    v_persen := coalesce(
      case when coalesce(v_pesanan.subtotal, 0) > 0
           then round(new.nilai::numeric * 100 / v_pesanan.subtotal, 2) end,
      new.persen,
      100);
    if not public.boleh('beri_diskon', new.nilai, v_persen) then
      raise exception 'Diskon ini melebihi batas izin Anda. Minta persetujuan atasan (PIN).';
    end if;
  elsif new.jenis = 'voucher' then
    -- TEMUAN review putaran11 PR-01 (K-2): enum mengizinkan 'voucher', kolom `voucher_id`
    -- masih TANPA kunci asing (menyusul di T1-12) dan tabel `voucher` BELUM ada. Dengan hanya
    -- memeriksa izin `pakai_voucher` (bawaan kasir = true), kasir bisa mencatat diskon
    -- "voucher" sebesar 100% subtotal tanpa voucher apa pun — batas 25.000/5% untuk diskon
    -- manual dilewati hanya dengan menulis jenis lain. Prinsip yang sama seperti 'promo':
    -- jenis yang mesinnya BELUM ada = DITUTUP (gagal-aman), bukan dibiarkan tanpa aturan.
    -- T1-19/T1-20 WAJIB mengganti cabang ini dengan pemeriksaan voucher sungguhan
    -- (voucher_id wajib ada, milik resto ini, belum dipakai, nilainya sama dengan diskon).
    raise exception 'Diskon voucher belum aktif (mesin voucher menunggu T1-12/T1-19/T1-20). Pakai diskon manual dengan persetujuan.';
  elsif new.jenis = 'promo' then
    -- TEMUAN PR-01: enum mengizinkan 'promo', tetapi mesinnya (T1-19/T1-20) belum ada —
    -- dan cabang `if` yang tidak ditulis berarti TIDAK ADA pemeriksaan sama sekali:
    -- kasir bisa mencatat diskon 100% subtotal dengan jenis ini. Selama mesinnya belum
    -- ada, jalur ini DITUTUP (gagal-aman), bukan dibiarkan tanpa aturan.
    raise exception 'Diskon promo otomatis belum aktif (menunggu T1-19/T1-20). Pakai diskon manual dengan persetujuan.';
  else
    raise exception 'Jenis diskon tidak dikenal: %.', new.jenis;
  end if;

  -- --------------------------------------------------- tumpuk, nilai, subtotal
  select coalesce(sum(d.nilai), 0)::integer, count(*)
    into v_sudah, v_jumlah
    from public.diskon_transaksi d
   where d.pesanan_id = new.pesanan_id;

  if v_jumlah > 0 then
    select p.tumpuk_diskon into v_tumpuk from public.pengaturan p where p.penyewa_id = v_pesanan.penyewa_id;
    if not coalesce(v_tumpuk, false) then
      raise exception 'Resto ini hanya mengizinkan satu diskon per transaksi.';
    end if;
  end if;

  if new.nilai <= 0 then
    raise exception 'Nilai diskon harus lebih besar dari nol.';
  end if;

  -- TEMUAN (laporan C, PR-01): dulu pemeriksaan dilewati saat subtotal 0, sehingga kasir
  -- bisa MENANAM diskon 25.000 di pesanan kosong lebih dulu; karena barisnya append-only
  -- (tidak bisa dihapus klien), potongan itu menempel sampai pesanan diisi. Sekarang:
  -- subtotal wajib sudah tercatat sebelum diskon boleh dicatat.
  if coalesce(v_pesanan.subtotal, 0) <= 0 then
    raise exception 'Subtotal pesanan belum tercatat — diskon belum boleh dicatat (hitung pesanan dulu).';
  end if;

  v_total := v_sudah + new.nilai;
  if v_total > v_pesanan.subtotal then
    raise exception 'Total diskon (%) melebihi subtotal pesanan (%).', v_total, v_pesanan.subtotal;
  end if;

  -- TEMUAN PR-02: kolom cap tingkat resto didefinisikan sejak 0002 tetapi TIDAK PERNAH
  -- dibaca satu baris pun. Akibatnya owner bisa memasang cap 10%/Rp5.000, menyalakan
  -- tumpuk diskon, lalu kasir memecah diskon besar menjadi banyak baris kecil — tiap
  -- baris lolos pemeriksaan per-baris, totalnya 100% subtotal. Cap sekarang diperiksa
  -- pada TOTAL (kumulatif), bukan per baris.
  select p.batas_maks_potongan_persen, p.batas_maks_potongan_nominal
    into v_cap_persen, v_cap_nominal
    from public.pengaturan p where p.penyewa_id = v_pesanan.penyewa_id;
  if v_cap_persen is not null and v_cap_persen < 100
     and v_total::numeric * 100 > v_pesanan.subtotal::numeric * v_cap_persen then
    raise exception 'Total potongan (%) melebihi batas maks potongan resto (% persen dari subtotal).',
      v_total, trim(to_char(v_cap_persen, 'FM999990.99'));
  end if;
  if v_cap_nominal is not null and v_total > v_cap_nominal then
    raise exception 'Total potongan (%) melebihi batas maks potongan resto (%).', v_total, v_cap_nominal;
  end if;

  if new.pelaku_id is null then
    new.pelaku_id := auth.uid();
  end if;
  -- Jejak pelaku tidak boleh dikarang klien (temuan audit AUD-3 K-2, 2026-09-17).
  if auth.uid() is not null and new.pelaku_id is distinct from auth.uid() then
    raise exception 'Pelaku diskon diisi sistem — tidak boleh menyebut orang lain.';
  end if;
  return new;
end
$$;

comment on function public.picu_diskon_batas() is
  'Menjaga diskon: jenis yang mesinnya belum ada (promo, voucher) DITOLAK gagal-aman, batas izin per baris, SATU diskon bila tidak tumpuk, dan TOTAL potongan tidak melebihi subtotal maupun cap resto (persen/nominal).';

-- ============================================================================
-- 2. NILAI KERUGIAN PEMBATALAN — dihitung peladen, angka klien tidak boleh beda (TEMUAN PR-03)
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
begin
  select p.id, p.dikirim_ke_dapur_pada, p.subtotal
    into v_pesanan
    from public.pesanan p where p.id = new.pesanan_id;
  if v_pesanan.id is null then
    raise exception 'Pesanan tidak ditemukan.';
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
    -- KUPON SEKALI PAKAI (temuan review PR putaran8, PR-04, 2026-09-17):
    -- sebelumnya bukti persetujuan hanya berarti "ada catatan PIN yang cocok" — sehingga
    -- SATU persetujuan PIN bisa dipakai membatalkan banyak pesanan selama 5 menit.
    -- Sekarang bukti harus TERIKAT pesanan ini dan BELUM DIPAKAI; begitu dipakai, ditandai.
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

  -- TEMUAN review putaran11 PR-03 (K-3): dulu nilai non-nol kiriman klien diterima APA ADANYA,
  -- sehingga kasir bisa menulis kerugian 1 rupiah untuk pesanan 54.000 (laporan kerugian
  -- under-report) atau angka besar sesukanya — kolomnya append-only, jadi angka karangan itu
  -- bertahan selamanya sebagai "jejak resmi". Sekarang nilai kerugian DIPAKSA sama dengan
  -- hitungan peladen dari SALINAN HARGA; kiriman klien hanya boleh 0 (minta diisi peladen)
  -- atau sama dengan hasil hitung. Selisih sedikit pun = penolakan.
  if new.nilai_kerugian <> 0 and new.nilai_kerugian is distinct from coalesce(v_nilai, 0) then
    raise exception 'Nilai kerugian dihitung peladen dari salinan harga (%); angka kiriman (%) tidak boleh dikarang.',
      coalesce(v_nilai, 0), new.nilai_kerugian;
  end if;
  new.nilai_kerugian := coalesce(v_nilai, 0);

  if new.pelaku_id is null then
    new.pelaku_id := auth.uid();
  end if;
  -- Jejak pelaku tidak boleh dikarang klien (temuan audit AUD-3 K-2, 2026-09-17).
  if auth.uid() is not null and new.pelaku_id is distinct from auth.uid() then
    raise exception 'Pelaku pembatalan diisi sistem — tidak boleh menyebut orang lain.';
  end if;
  return new;
end
$$;

comment on function public.picu_pembatalan_sah() is
  'Menjaga pembatalan: alasan wajib, tahap (sebelum/sesudah dapur) menentukan izin, persetujuan PIN terikat pesanan & sekali pakai, dan NILAI KERUGIAN dihitung peladen dari salinan harga (angka kiriman klien yang berbeda = ditolak).';

-- ============================================================================
-- 3. PESANAN BARU — status awal hanya `draf` dari perangkat (TEMUAN PR-02)
--
-- Kenapa ada: penjaga status (`pesanan_jaga_status`, 0009) hanya dipasang pada UPDATE.
-- Akibatnya kasir bisa membuat pesanan yang LAHIR `batal` (tanpa satu pun baris
-- `pembatalan` — Aturan Bisnis 7 dilewati) atau lahir `lunas` (tanpa pembayaran apa pun,
-- merusak arti laporan penjualan). Penjaga uang tidak menangkapnya karena angka uangnya
-- memang 0 — yang dikarang STATUS, bukan nominalnya.
-- ============================================================================
create or replace function public.picu_pesanan_status_awal()
returns trigger
language plpgsql
-- SENGAJA BUKAN `security definer` (pelajaran nyata saat menguji migrasi ini):
-- di dalam fungsi SECURITY DEFINER, `current_user` menjadi PEMILIK fungsi — jadi
-- `peran_peladen()` selalu TRUE dan penjaga ini tidak akan pernah menolak apa pun
-- (insert `status='batal'` tetap lolos walau sudah diberi penjaga). Penjaga berbasis
-- PERAN wajib berjalan dengan hak PEMANGGIL, seperti `picu_pesanan_jaga_status` (0009).
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null or public.peran_peladen() then
    return new;   -- jalur peladen (fungsi peladen/service_role): bebas, seperti penjaga status lama
  end if;
  if new.status is distinct from 'draf' then
    raise exception 'Pesanan baru harus berstatus draf (diminta %); status lain hanya boleh ditetapkan peladen setelah pembayaran/pembatalan sah.', new.status;
  end if;
  if new.dikirim_ke_dapur_pada is not null then
    raise exception 'Pesanan baru belum boleh membawa tanda kirim ke dapur.';
  end if;
  if new.dibayar_pada is not null or new.dibatalkan_pada is not null or new.alasan_batal is not null then
    raise exception 'Tanda pembayaran/pembatalan hanya boleh diisi peladen, bukan saat pesanan dibuat.';
  end if;
  return new;
end
$$;

drop trigger if exists pesanan_status_awal on public.pesanan;
create trigger pesanan_status_awal
  before insert on public.pesanan
  for each row execute function public.picu_pesanan_status_awal();

comment on function public.picu_pesanan_status_awal() is
  'Pesanan yang dibuat dari perangkat wajib lahir `draf` dan tanpa tanda kirim/bayar/batal (temuan review putaran11 PR-02).';

revoke all on function public.picu_pesanan_status_awal() from public;
grant execute on function public.picu_pesanan_status_awal() to authenticated, service_role;
