-- ============================================================================
-- 0012 — PENUTUP CELAH TEMUAN REVIEW PR PUTARAN 8 (2026-09-17)
--
-- Kenapa ada: tiga sesi peninjau independen (jalur risiko Merah) menjawab
-- TIDAK-BERSIH atas commit `7e8c0b9`. Sebagian besar temuan adalah celah NYATA
-- di lapisan database yang tidak tertangkap uji mana pun. Aturan repo: berkas
-- migrasi yang sudah ada TIDAK disunting — semua perbaikan ditulis di sini,
-- sebagai migrasi baru. Yang ditutup di berkas ini:
--
--   1. Diskon `jenis = 'promo'` melewati SEMUA pemeriksaan izin  (PR-01)
--   2. Batas maks potongan resto tidak pernah dibaca; tumpuk diskon
--      bisa mencapai 100% subtotal                                (PR-02)
--   3. `pesanan_item.harga_saat_itu`/`subtotal` bebas diisi klien;
--      izin `ubah_harga` tidak pernah ditegakkan                    (PR-03)
--   4. Bukti PIN void tidak terikat pesanan & bisa dipakai berulang (PR-04)
--   5. Jejak pelaku perubahan `pengaturan` bisa dikarang/dihapus    (PR-05)
--   6. Diskon bisa ditanam saat subtotal masih 0                    (PR-01 laporan C)
--   7. `catat_stok('keluar', +N)` menambah saldo                    (PR-03 laporan C)
--   8. `izin_efektif_untuk()` masih membaca kolom yang sudah dihapus (PR-11)
--   9. Kunci PIN bisa dijatuhkan pegawai lain (serangan penolakan)  (PR-13)
--  10. Batas lebih bayar diperiksa tanpa mengunci baris pesanan      (PR-16)
--  11. `cabang_saya()` bergantung pada klaim token yang tidak pernah
--      diterbitkan di repo ini                                     (PR-15)
--
-- Catatan jujur: nomor migrasi perangkat (rencana lama `0012_perangkat.sql`,
-- tugas T1-24) bergeser menjadi 0013 karena nomor ini dipakai penutup celah.
--
-- Nomor TEMUAN di atas mengikuti laporan review di `docs/uji/review-pr/`.
-- Setiap perbaikan punya uji di `supabase/tes/` dan dibuktikan bisa MERAH
-- lewat uji mutasi (lihat `docs/uji/REVIEW_PR_RIWAYAT.md`).
-- ============================================================================

-- ============================================================================
-- 1. DISKON — satu pintu, cap kumulatif, dan jenis yang belum punya mesin ditolak
--    Temuan PR-01 (jenis 'promo' bebas), PR-02 (cap resto tidak dibaca),
--    PR-01 laporan C (diskon saat subtotal 0).
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
    if not public.boleh('pakai_voucher') then
      raise exception 'Anda tidak berizin memakai voucher.';
    end if;
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
  'Menjaga diskon: jenis yang belum punya mesin ditolak, batas izin per baris, SATU diskon bila tidak tumpuk, dan TOTAL potongan tidak melebihi subtotal maupun cap resto (persen/nominal).';

-- ============================================================================
-- 2. HARGA ITEM PESANAN — salinan beku wajib sama dengan harga yang berlaku
--    Temuan PR-03: izin `ubah_harga` tidak pernah ditegakkan; kasir bisa menulis
--    Rp1 untuk menu Rp27.000 dan `subtotal` sesukanya.
-- ============================================================================
create or replace function public.picu_item_harga_jujur()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_cabang   uuid;
  v_harga    integer;
begin
  select p.cabang_id into v_cabang from public.pesanan p where p.id = new.pesanan_id;
  if v_cabang is null then
    raise exception 'Pesanan tidak ditemukan.';
  end if;

  if new.qty is null or new.qty <= 0 then
    raise exception 'Jumlah item harus lebih dari nol.';
  end if;
  if new.harga_saat_itu is null or new.harga_saat_itu <= 0 then
    raise exception 'Harga saat itu wajib diisi dan harus lebih dari nol.';
  end if;

  -- Pemeriksaan harga hanya untuk jalur KLIEN, dan hanya bila harganya MEMANG sedang
  -- ditulis: baris lama yang harga bekunya sudah tercatat tidak boleh diuji ulang terhadap
  -- harga menu hari ini (itu justru merusak ART-3 — riwayat tidak boleh berubah artinya).
  -- Karena itu pemeriksaan dilewati bila UPDATE tidak menyentuh harga/menu.
  if auth.uid() is not null
     and (tg_op = 'INSERT'
          or new.harga_saat_itu is distinct from old.harga_saat_itu
          or new.menu_item_id is distinct from old.menu_item_id) then
    v_harga := public.harga_berlaku(new.menu_item_id, v_cabang);
    if v_harga is null then
      raise exception 'Menu tidak ditemukan atau tidak dijual di cabang ini.';
    end if;

    -- Harga yang BERBEDA dari harga berlaku hanya boleh oleh pemegang izin `ubah_harga`
    -- (mis. admin cabang untuk promo manual). Tanpa izin itu = tolak.
    if new.harga_saat_itu <> v_harga then
      if not public.boleh('ubah_harga') then
        raise exception 'Harga menu ini Rp% — mencatat harga lain (Rp%) perlu izin ubah harga.',
          v_harga, new.harga_saat_itu;
      end if;
    end if;
  end if;

  -- Subtotal dihitung PELADEN, tidak dipercaya dari klien (Aturan Bisnis 5/ART-3).
  -- Dihitung ulang hanya bila barisnya baru atau harga/qty-nya memang berubah; perubahan
  -- kolom lain (mis. status) tidak mengubah riwayat uang.
  if tg_op = 'INSERT'
     or new.qty is distinct from old.qty
     or new.harga_saat_itu is distinct from old.harga_saat_itu then
    new.subtotal := new.harga_saat_itu * new.qty;
  end if;
  return new;
end
$$;

drop trigger if exists pesanan_item_harga_jujur on public.pesanan_item;
create trigger pesanan_item_harga_jujur
  before insert or update on public.pesanan_item
  for each row execute function public.picu_item_harga_jujur();

comment on function public.picu_item_harga_jujur() is
  'Menjaga harga baris pesanan: harga_saat_itu wajib sama dengan harga_berlaku(menu, cabang) kecuali pemanggil berizin ubah_harga; subtotal selalu dihitung ulang peladen.';

-- ============================================================================
-- 3. BUKTI PERSETUJUAN PIN — kupon sekali pakai yang TERIKAT pesanan
--    Temuan PR-04: satu persetujuan PIN bisa dipakai membatalkan banyak pesanan
--    selama 5 menit, karena bukti hanya berarti "ada catatan PIN yang cocok".
--    Temuan PR-13: pembatas percobaan menghitung kegagalan atas nama KORBAN,
--    sehingga pegawai mana pun bisa mengunci PIN owner (serangan penolakan).
-- ============================================================================
alter table public.percobaan_pin add column if not exists pemanggil_id uuid;
alter table public.percobaan_pin add column if not exists pesanan_id uuid;
alter table public.percobaan_pin add column if not exists dipakai_pada timestamptz;

comment on column public.percobaan_pin.pemanggil_id is
  'Siapa yang MENEKAN angka (auth.uid saat percobaan) — dipakai membatasi percobaan per PENCOBA, bukan atas nama korban.';
comment on column public.percobaan_pin.pesanan_id is
  'Pesanan yang disetujui saat PIN berhasil (kupon persetujuan terikat pesanan).';
comment on column public.percobaan_pin.dipakai_pada is
  'Kapan kupon persetujuan HABIS dipakai; bukan null = tidak bisa dipakai lagi.';

create index if not exists percobaan_pin_kupon_idx
  on public.percobaan_pin (pengguna_id, aksi, pesanan_id, waktu desc)
  where berhasil;

-- --------------------------------------------------------------------- verifikasi_pin
-- Ganti tanda tangan: tambah `p_pesanan_id`. Fungsi lama di-DROP lebih dulu supaya
-- tidak ada dua kandidat dengan nilai bawaan (pemanggilan 4 argumen jadi ambigu).
drop function if exists public.verifikasi_pin(uuid, text, text, text);

create or replace function public.verifikasi_pin(
  p_pengguna_id uuid,
  p_pin         text,
  p_aksi        text default null,
  p_perangkat   text default 'tidak-diketahui',
  p_pesanan_id  uuid default null
)
returns table (berhasil boolean, sisa_percobaan integer, pesan text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  BATAS_AKUN       constant integer := 5;    -- 5 kali gagal per pasangan (pencoba → akun)
  BATAS_PERANGKAT  constant integer := 12;   -- 12 kali gagal per perangkat (melintasi akun)
  JENDELA_MENIT    constant integer := 15;
  v_saya       uuid := auth.uid();
  v_perangkat  text := coalesce(nullif(p_perangkat, ''), 'tidak-diketahui');
  v_hash       text;
  v_penyewa_target uuid;
  v_aktif_target   boolean;
  v_gagal_akun integer;
  v_gagal_alat integer;
  v_berhasil   boolean;
begin
  if v_saya is null then
    return query select false, 0, 'Anda harus masuk dulu untuk memakai PIN.';
    return;
  end if;

  if p_pin is null or p_pin !~ '^\d{6}$' then
    return query select false, 0, 'PIN harus tepat 6 angka.';
    return;
  end if;

  select p.penyewa_id, p.aktif, k.pin_hash
    into v_penyewa_target, v_aktif_target, v_hash
    from public.pengguna p
    left join public.kredensial_pin k on k.pengguna_id = p.id
   where p.id = p_pengguna_id;

  if v_penyewa_target is null or v_penyewa_target <> public.penyewa_saya() or not coalesce(v_aktif_target, false) then
    -- Jangan membocorkan apakah pegawai itu ada: jawab seperti PIN salah.
    insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, pemanggil_id, pesanan_id)
    values (v_saya, v_perangkat, false, p_aksi, v_saya, p_pesanan_id);
    return query select false, 0, 'PIN tidak dikenali.';
    return;
  end if;

  -- TEMUAN PR-13: dulu penghitung ini menyaring `pp.pengguna_id = p_pengguna_id` saja —
  -- artinya 5 tebakan salah dari PEGAWAI LAIN atas nama korban mengunci PIN korban
  -- selama 15 menit (persetujuan void/diskon resto berhenti, dan jejaknya menuduh
  -- korban). Sekarang yang dibatasi adalah PERCOBAAN ORANG ITU terhadap akun itu;
  -- korban tetap bisa memakai PIN-nya sendiri, penyerang tertahan.
  select count(*) into v_gagal_akun
    from public.percobaan_pin pp
   where pp.pengguna_id = p_pengguna_id
     and pp.pemanggil_id = v_saya
     and not pp.berhasil
     and pp.waktu > now() - make_interval(mins => JENDELA_MENIT);

  select count(*) into v_gagal_alat
    from public.percobaan_pin pp
   where pp.perangkat = v_perangkat
     and pp.pemanggil_id = v_saya
     and not pp.berhasil
     and pp.waktu > now() - make_interval(mins => JENDELA_MENIT);

  if v_gagal_akun >= BATAS_AKUN or v_gagal_alat >= BATAS_PERANGKAT then
    insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, pemanggil_id, pesanan_id)
    values (p_pengguna_id, v_perangkat, false, p_aksi, v_saya, p_pesanan_id);
    return query select false, 0,
      format('PIN terkunci sementara karena terlalu banyak percobaan salah dari perangkat/akun Anda. Coba lagi setelah %s menit.', JENDELA_MENIT);
    return;
  end if;

  v_berhasil := v_hash is not null and crypt(p_pin, v_hash) = v_hash;

  insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, pemanggil_id, pesanan_id)
  values (p_pengguna_id, v_perangkat, v_berhasil, p_aksi, v_saya, p_pesanan_id);

  if not v_berhasil then
    return query select false, greatest(BATAS_AKUN - v_gagal_akun - 1, 0),
      'PIN salah.';
    return;
  end if;

  if p_aksi is not null and not public.boleh_untuk(p_pengguna_id, p_aksi) then
    return query select false, BATAS_AKUN,
      format('PIN benar, tetapi pegawai itu tidak berizin: %s.', p_aksi);
    return;
  end if;

  return query select true, BATAS_AKUN, 'PIN diterima.';
end
$$;

comment on function public.verifikasi_pin(uuid, text, text, text, uuid) is
  'Memeriksa PIN pegawai (6 angka), mencatat percobaan per PENCOBA (bukan atas nama korban), membatasi 5 gagal per pencoba-akun & 12 gagal per perangkat per 15 menit, dan menyimpan pesanan yang disetujui (kupon sekali pakai). Tidak pernah mengembalikan hash.';

revoke all on function public.verifikasi_pin(uuid, text, text, text, uuid) from public;
grant execute on function public.verifikasi_pin(uuid, text, text, text, uuid) to authenticated, service_role;

-- --------------------------------------------------------------------- pembatalan
-- Pemicu pembatalan ditulis ulang: bukti persetujuan sekarang dicari sebagai KUPON
-- (terikat pesanan ini + belum dipakai), lalu ditandai habis. Bagian lain fungsi
-- dipertahankan apa adanya dari 0010.
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

  if new.nilai_kerugian = 0 then
    new.nilai_kerugian := coalesce(v_nilai, 0);
  end if;

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

-- ============================================================================
-- 4. JEJAK PELAKU PENGATURAN — tidak bisa dikarang, tidak bisa dihapus, waktunya
--    tidak bisa dimundurkan.  Temuan PR-05.
-- ============================================================================
create or replace function public.picu_pengaturan_jejak()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is not null then
    -- Menyebut ORANG LAIN sebagai pelaku = penolakan. Mengisi sama dengan pelaku sebelumnya
    -- (yaitu mengubah baris tanpa menyentuh kolom pelaku) = wajar, dan tetap ditulis ulang
    -- menjadi PEMANGGIL yang sebenarnya.
    if new.diubah_oleh is not null
       and new.diubah_oleh is distinct from auth.uid()
       and new.diubah_oleh is distinct from old.diubah_oleh then
      raise exception 'Kolom "diubah oleh" diisi sistem — tidak boleh menyebut orang lain.';
    end if;
    new.diubah_oleh := auth.uid();
    new.diubah_pada := now();          -- waktu tidak bisa dimundurkan
  else
    if new.diubah_oleh is null and old.diubah_oleh is not null then
      -- Jalur peladen tanpa identitas (mis. penyiapan awal) tetap tidak boleh MENGHAPUS jejak.
      raise exception 'Jejak pelaku perubahan pengaturan tidak boleh dihapus.';
    end if;
    if new.diubah_pada is distinct from old.diubah_pada then
      new.diubah_pada := greatest(new.diubah_pada, old.diubah_pada);   -- tidak bisa dimundurkan
    end if;
  end if;
  return new;
end
$$;

drop trigger if exists pengaturan_jaga_jejak on public.pengaturan;
create trigger pengaturan_jaga_jejak
  before update on public.pengaturan
  for each row execute function public.picu_pengaturan_jejak();

comment on function public.picu_pengaturan_jejak() is
  'Perubahan pengaturan uang WAJIB berjejak: pelaku = pemanggil yang masuk, waktunya tidak bisa dimundurkan (Aturan Bisnis 8).';

-- ============================================================================
-- 5. STOK — jenis pergerakan menentukan tanda.
--    Temuan laporan C, PR-03: `catat_stok('keluar', +5)` menambah saldo.
-- ============================================================================
create or replace function public.catat_stok(
  p_stok_bahan_id uuid,
  p_jenis         text,
  p_jumlah        numeric,
  p_alasan        text default null
)
returns numeric
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_saldo   numeric;
  v_jumlah  numeric := p_jumlah;
  v_satuan  text;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;

  if not public.boleh('ubah_stok') then
    raise exception 'Anda tidak berizin mengubah stok.';
  end if;

  if p_jenis not in ('masuk', 'keluar', 'opname', 'koreksi') then
    raise exception 'Jenis pergerakan stok tidak dikenal: %.', p_jenis;
  end if;

  select b.satuan into v_satuan from public.stok_bahan b where b.id = p_stok_bahan_id;
  if v_satuan is null then
    raise exception 'Bahan tidak ditemukan.';
  end if;

  -- TEMUAN (laporan C, PR-03): dulu angka kiriman dipakai apa adanya, sehingga
  -- `catat_stok('keluar', +5)` MENAMBAH saldo — buku besar bilang keluar, saldo naik.
  -- Sekarang arahnya ditentukan JENIS, bukan tanda kiriman:
  --   * masuk  → selalu +
  --   * keluar → selalu −
  --   * opname/koreksi → delta dua arah, jadi tandanya bermakna (0 ditolak: tidak mengubah apa pun)
  if p_jenis = 'masuk' then
    v_jumlah := abs(p_jumlah);
  elsif p_jenis = 'keluar' then
    v_jumlah := -abs(p_jumlah);
  else
    if p_jumlah = 0 then
      raise exception 'Opname/koreksi dengan perubahan nol tidak perlu dicatat.';
    end if;
  end if;

  if v_jumlah = 0 then
    raise exception 'Jumlah pergerakan stok tidak boleh nol.';
  end if;

  insert into public.stok_pergerakan (penyewa_id, stok_bahan_id, jenis, jumlah, alasan)
  values (public.penyewa_saya(), p_stok_bahan_id, p_jenis, v_jumlah, p_alasan);

  select b.jumlah into v_saldo from public.stok_bahan b where b.id = p_stok_bahan_id;
  return v_saldo;
end
$$;

comment on function public.catat_stok(uuid, text, numeric, text) is
  'Satu pintu mencatat pergerakan stok. Arah ditentukan jenis: masuk selalu menambah, keluar selalu mengurangi (tanda kiriman diabaikan), opname/koreksi memakai delta apa adanya.';

-- ============================================================================
-- 6. SATU RUMUS IZIN UNTUK SIAPA PUN — `izin_efektif_untuk` ditulis ulang
--    Temuan PR-11: fungsi ini masih membaca kolom `pengguna_cabang.peran` yang
--    DIHAPUS migrasi 0011, sehingga panggilan dengan cabang meledak dan klaim
--    "satu rumus izin, dua pintu" batal. Sekarang: rumusnya sama dengan
--    `izin_efektif` (peran tunggal dari `pengguna.peran`), hanya subjeknya orang lain.
-- ============================================================================
drop function if exists public.izin_efektif_untuk(uuid, text, uuid);

create or replace function public.izin_efektif_untuk(
  p_pengguna_id uuid,
  p_aksi        text,
  p_cabang_id   uuid default null
)
returns table (boleh boolean, batas_nominal integer, batas_persen numeric)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_peran   text;
  v_aktif   boolean;
begin
  select p.penyewa_id, p.peran, p.aktif
    into v_penyewa, v_peran, v_aktif
    from public.pengguna p where p.id = p_pengguna_id;

  if v_penyewa is null or not coalesce(v_aktif, false) then
    return query select false, null::integer, null::numeric;
    return;
  end if;

  -- ISOLASI LINTAS RESTO (temuan audit AUD-3 K-1, 2026-09-17): fungsi ini SECURITY DEFINER
  -- sehingga melewati RLS — tanpa pemeriksaan ini, pegawai resto A bisa membaca izin dan
  -- BATAS DISKON pegawai resto B hanya dengan menebak UUID-nya. Pemanggil tanpa identitas
  -- (auth.uid() null) adalah jalur peladen (service_role / penyiapan) dan tetap diizinkan.
  if auth.uid() is not null and v_penyewa is distinct from public.penyewa_saya() then
    return query select false, null::integer, null::numeric;
    return;
  end if;

  if v_peran is null or v_peran = 'pemilik_platform' then
    return query select false, null::integer, null::numeric;
    return;
  end if;

  -- Kalau cabang disebut: subjek harus benar-benar anggota cabang itu, kecuali owner pusat
  -- yang memang tidak bertugas di kasir. Tidak ada lagi "peran per cabang" (ART-12).
  if p_cabang_id is not null and v_peran <> 'owner_pusat' then
    if not exists (
      select 1 from public.pengguna_cabang pc
       where pc.pengguna_id = p_pengguna_id
         and pc.cabang_id = p_cabang_id
         and pc.aktif
    ) then
      return query select false, null::integer, null::numeric;
      return;
    end if;
  end if;

  return query
    select coalesce(k.boleh, false), k.batas_nominal, k.batas_persen
      from (
        select i.boleh, i.batas_nominal, i.batas_persen, 0 as urutan
          from public.izin i
         where i.pengguna_id = p_pengguna_id
           and i.kode_izin = p_aksi
        union all
        select ip.boleh, ip.batas_nominal, ip.batas_persen, 1 as urutan
          from public.izin_peran ip
         where ip.penyewa_id = v_penyewa
           and ip.peran = v_peran
           and ip.kode_izin = p_aksi
      ) k
     order by k.urutan
     limit 1;

  if not found then
    return query select false, null::integer, null::numeric;
    return;
  end if;
end
$$;

comment on function public.izin_efektif_untuk(uuid, text, uuid) is
  'Izin yang berlaku untuk PEGAWAI LAIN: peran tunggal dari pengguna.peran + centang khusus pegawai menang atas bawaan peran; akun nonaktif, resto lain, atau bukan anggota cabang yang disebut = TOLAK.';

-- Klien TIDAK boleh memanggil fungsi ini (pintu izin untuk MENILAI ORANG LAIN) — hanya
-- jalur peladen (service_role) dan fungsi SECURITY DEFINER internal. Sama seperti 0006.
revoke all on function public.izin_efektif_untuk(uuid, text, uuid) from public, anon, authenticated;
grant execute on function public.izin_efektif_untuk(uuid, text, uuid) to service_role;

-- ============================================================================
-- 7. CABANG AKTIF DARI TABEL, BUKAN DARI KLAIM YANG TIDAK PERNAH DITERBITKAN
--    Temuan PR-15: `cabang_saya()` memerlukan klaim JWT `cabang_id` yang tidak
--    ada satu pun penerbitnya di repo — di Supabase nyata hasilnya SELALU null,
--    sehingga policy admin cabang (pengguna_pilih) mati diam-diam.
--    Keputusan: satu sumber saja (tabel `sesi_cabang`, diisi saat memilih cabang).
--    Kolomnya sudah ada; mengisinya adalah tugas layar pemilihan cabang (T1-25).
-- ============================================================================
create table if not exists public.sesi_cabang (
  pengguna_id uuid primary key references public.pengguna (id) on delete cascade,
  cabang_id   uuid not null references public.cabang (id) on delete cascade,
  diubah_pada timestamptz not null default now()
);

comment on table public.sesi_cabang is
  'Cabang yang sedang dipilih pegawai (satu baris per pegawai). Satu-satunya sumber `cabang_saya()` — bukan klaim token, bukan metadata klien yang bisa diubah sendiri.';

alter table public.sesi_cabang enable row level security;
revoke all on public.sesi_cabang from public, anon, authenticated;

-- Policy "menolak semua": tabel ini hanya dibaca lewat fungsi SECURITY DEFINER.
-- Menulis pilihan cabang harus lewat RPC yang memverifikasi keanggotaan (T1-25).
create policy sesi_cabang_tolak_semua on public.sesi_cabang for all to authenticated using (false) with check (false);

create or replace function public.cabang_saya()
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select sc.cabang_id
    from public.sesi_cabang sc
    join public.pengguna_cabang pc
      on pc.pengguna_id = sc.pengguna_id
     and pc.cabang_id = sc.cabang_id
     and pc.aktif
    join public.pengguna p on p.id = sc.pengguna_id and p.aktif   -- akun nonaktif kehilangan akses
   where sc.pengguna_id = auth.uid()
   limit 1
$$;

comment on function public.cabang_saya() is
  'Cabang aktif pengguna: satu sumber saja — baris pilihan di `sesi_cabang`, DIVERIFIKASI ULANG ke keanggotaan `pengguna_cabang` yang masih aktif dan akun yang masih aktif. Null bila belum memilih / tidak berhak.';

-- ============================================================================
-- 8. PEMBAYARAN — kunci baris pesanan supaya dua pembayaran bersamaan tidak
--    sama-sama lolos batas lebih bayar.  Temuan PR-16.
--    (Badan fungsi lain dipertahankan apa adanya dari 0010.)
-- ============================================================================
create or replace function public.picu_pembayaran_jujur()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pesanan  record;
  v_metode   record;
  v_sebelum  integer;
begin
  -- KUNCI BARIS PESANAN (temuan review PR putaran8, PR-16, 2026-09-17): tanpa `for update`,
  -- dua pembayaran bersamaan sama-sama membaca `total_dibayar()` yang belum memuat baris
  -- pihak lain sehingga keduanya lolos batas lebih bayar. Dengan mengunci barisnya, pembayaran
  -- kedua menunggu sampai yang pertama ter-commit dan melihat angka yang benar.
  select p.id, p.status, p.total, p.penyewa_id
    into v_pesanan
    from public.pesanan p
   where p.id = new.pesanan_id
   for update;

  if v_pesanan.id is null then
    raise exception 'Pesanan tidak ditemukan.';
  end if;
  if v_pesanan.status = 'batal' then
    raise exception 'Pesanan ini sudah dibatalkan — uang tidak boleh dicatat lagi.';
  end if;

  if new.metode_id is not null then
    select m.nama, m.jenis, m.butuh_referensi
      into v_metode
      from public.metode_bayar m
     where m.id = new.metode_id
       and m.penyewa_id = v_pesanan.penyewa_id;
    if v_metode.nama is null then
      raise exception 'Metode bayar itu tidak ada di resto ini.';
    end if;
    new.metode_nama_saat_itu := v_metode.nama;
    new.jenis_saat_itu := v_metode.jenis;
  end if;

  if new.jenis_saat_itu = 'tunai' then
    if new.diterima is null then
      raise exception 'Pembayaran tunai wajib menyebut uang yang diterima.';
    end if;
    if new.diterima < new.jumlah then
      raise exception 'Uang diterima (%) lebih kecil dari jumlah bayar (%).', new.diterima, new.jumlah;
    end if;
    new.kembalian := new.diterima - new.jumlah;
  else
    if new.referensi is null or length(btrim(new.referensi)) = 0 then
      raise exception 'Pembayaran bukan tunai wajib menyebut nomor referensi.';
    end if;
    new.diterima := null;
    new.kembalian := null;
  end if;

  if new.kasir_id is null then
    new.kasir_id := auth.uid();
  end if;
  -- Jejak pelaku TIDAK boleh dikarang klien (temuan audit AUD-3 K-2, 2026-09-17):
  -- sebelumnya kasir bisa menuliskan nama owner sebagai kasir pembayaran, dan karena
  -- barisnya append-only kesalahan atribusi itu permanen.
  if auth.uid() is not null and new.kasir_id is distinct from auth.uid() then
    raise exception 'Nama kasir diisi sistem — tidak boleh menyebut orang lain.';
  end if;

  -- Total pesanan WAJIB sudah dihitung sebelum uang boleh dicatat (temuan audit AUD-3 K-1,
  -- 2026-09-17). Sebelumnya pemeriksaan dilewati saat total masih 0 — dan karena hitung_total
  -- (T1-15) belum ada, semua pesanan bertotal 0 sehingga berapa pun uangnya diterima tanpa
  -- penjaga, sementara baris uang tidak bisa diubah/dihapus (tidak ada jalan pemulihan).
  -- Menolak di sini membuat uang tidak pernah tercatat di atas angka yang belum pasti.
  if coalesce(v_pesanan.total, 0) <= 0 then
    raise exception 'Total pesanan belum dihitung — pembayaran belum boleh dicatat.';
  end if;

  v_sebelum := public.total_dibayar(new.pesanan_id) + new.jumlah;
  if v_sebelum > v_pesanan.total then
    raise exception 'Total pembayaran (%) melebihi total pesanan (%).', v_sebelum, v_pesanan.total;
  end if;

  return new;
end
$$;

comment on function public.picu_pembayaran_jujur() is
  'Menjaga pembayaran: metode & referensi sah, kembalian dihitung peladen, pelaku = pemanggil, total pesanan wajib sudah dihitung, tidak melebihi total, dan baris pesanan DIKUNCI (aman dari dua pembayaran bersamaan).';

-- ------------------------------------------------------------------ pilih_cabang
-- Satu-satunya cara sah mengubah cabang aktif: RPC ini. Database memverifikasi bahwa
-- pemanggil benar-benar anggota cabang itu (lewat `pengguna_cabang` yang masih aktif),
-- jadi klien tidak bisa "mengaku" bertugas di cabang mana pun.
create or replace function public.pilih_cabang(p_cabang_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_saya uuid := auth.uid();
begin
  if v_saya is null then
    raise exception 'Anda harus masuk dulu.';
  end if;
  if not exists (
    select 1
      from public.pengguna_cabang pc
      join public.pengguna p on p.id = pc.pengguna_id and p.aktif
     where pc.pengguna_id = v_saya
       and pc.cabang_id = p_cabang_id
       and pc.aktif
  ) then
    raise exception 'Anda tidak bertugas di cabang itu.';
  end if;

  insert into public.sesi_cabang (pengguna_id, cabang_id, diubah_pada)
  values (v_saya, p_cabang_id, now())
  on conflict (pengguna_id) do update
     set cabang_id = excluded.cabang_id,
         diubah_pada = excluded.diubah_pada;

  return p_cabang_id;
end
$$;

comment on function public.pilih_cabang(uuid) is
  'Memilih cabang aktif pegawai. Diverifikasi ke keanggotaan `pengguna_cabang` (aktif) — bukan berdasarkan klaim klien. Owner pusat memakai cabang_manapun yang ia urus lewat jalur lain; untuk kasir/admin, inilah satu-satunya pintu.';

revoke all on function public.pilih_cabang(uuid) from public;
grant execute on function public.pilih_cabang(uuid) to authenticated, service_role;
