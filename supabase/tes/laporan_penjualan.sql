-- ============================================================================
-- Uji SQL: Laporan Penjualan Dasar (Kategori, Metode Bayar, Tren Harian)
-- Tugas: T7-08 (PRD M8 — Dari mana uang datang)
-- ============================================================================

-- Tabel sementara penyimpan data uji laporan penjualan
create temp table _t_lap_penjualan (
  cabang_id uuid,
  cabang_dua_id uuid,
  shift_id uuid,
  metode_tunai_id uuid,
  metode_qris_id uuid,
  kategori_makanan uuid,
  kategori_minuman uuid
);
grant all on _t_lap_penjualan to authenticated;

insert into _t_lap_penjualan (
  cabang_id,
  cabang_dua_id,
  metode_tunai_id,
  metode_qris_id,
  kategori_makanan,
  kategori_minuman
) values (
  'a1a1a1a1-0000-0000-0000-000000000001',
  'a1a1a1a1-0000-0000-0000-000000000002',
  (select id from public.metode_bayar where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai' limit 1),
  (select id from public.metode_bayar where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'QRIS' limit 1),
  'cafe0000-0000-0000-0000-000000000001',
  'cafe0000-0000-0000-0000-000000000002'
);

-- ---------------------------------------------------------------------------
-- 1. Panggilan Anonim Ditolak
-- ---------------------------------------------------------------------------
select uji.harap_gagal_sebab(
  $$select public.laporan_penjualan()$$,
  'Anda harus masuk dulu',
  'Anonim tidak boleh mengakses laporan penjualan'
);

-- ---------------------------------------------------------------------------
-- 2. Peran Tanpa Wewenang (Pelayan & Kasir tanpa izin) Ditolak
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000005'); -- Joko Pelayan
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.laporan_penjualan()$$,
  'tidak berwenang',
  'Pelayan tidak boleh membaca laporan penjualan'
);

select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Rina Kasir
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.laporan_penjualan()$$,
  'tidak berwenang',
  'Kasir tanpa izin lihat_laporan tidak boleh membaca laporan penjualan'
);

-- ---------------------------------------------------------------------------
-- 3. Validasi Rentang Tanggal (Batas 90 Hari & Urutan Tanggal)
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Bu Oasis (Owner)
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.laporan_penjualan(null, '2026-09-24', '2026-09-20')$$,
  'lebih awal dari tanggal mulai',
  'Tanggal akhir lebih awal dari tanggal mulai wajib ditolak'
);

select uji.harap_gagal_sebab(
  $$select public.laporan_penjualan(null, '2026-01-01', '2026-06-01')$$,
  'maksimal 90 hari',
  'Rentang tanggal lebih dari 90 hari wajib ditolak untuk mencegah beban kueri berat'
);

-- ---------------------------------------------------------------------------
-- 4. Pembatasan Cabang Sesuai Wewenang Pantau
-- ---------------------------------------------------------------------------
-- Admin Andi (Admin Cabang A1) mencoba melihat Cabang A2
select uji.klaim('90000000-0000-0000-0000-000000000003'); -- Admin Andi (A1)
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.laporan_penjualan((select cabang_dua_id from _t_lap_penjualan))$$,
  'di luar wewenang pantauan',
  'Admin cabang tidak boleh melihat laporan cabang lain yang bukan binaannya'
);

-- Admin Andi berhasil memanggil laporan cabang binaannya sendiri
select uji.sama(
  (select (public.laporan_penjualan((select cabang_id from _t_lap_penjualan))->>'berhasil')::boolean),
  true,
  'Admin cabang berhasil mengakses laporan penjualan cabang miliknya'
);

-- ---------------------------------------------------------------------------
-- 5. Transaksi Uji untuk Validasi Angka Omzet, Kategori, Metode & Tren
-- ---------------------------------------------------------------------------
-- Buka shift untuk kasir Rina
select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Rina Kasir
set local role authenticated;

do $$
declare
  v_res jsonb;
  v_shift_id uuid;
begin
  v_res := public.buka_shift(
    100000,
    (select cabang_id from _t_lap_penjualan),
    'Shift penjualan uji T7-08'
  );
  v_shift_id := (v_res->>'shift_id')::uuid;
  update _t_lap_penjualan set shift_id = v_shift_id;
end;
$$;

-- Kasir membuat pesanan makanan & minuman lunas
do $$
declare
  v_pesanan_id uuid := gen_random_uuid();
  v_menu_makanan uuid;
  v_menu_minuman uuid;
  v_total_pesanan integer;
  v_res jsonb;
begin
  select id into v_menu_makanan
    from public.menu_item
   where penyewa_id = '11111111-1111-1111-1111-111111111111'
     and jenis = 'makanan'
   limit 1;

  select id into v_menu_minuman
    from public.menu_item
   where penyewa_id = '11111111-1111-1111-1111-111111111111'
     and jenis = 'minuman'
   limit 1;

  insert into public.pesanan (
    id, penyewa_id, cabang_id, shift_id, nomor, tanggal, tipe, status, kunci_idempoten
  ) values (
    v_pesanan_id,
    '11111111-1111-1111-1111-111111111111',
    (select cabang_id from _t_lap_penjualan),
    (select shift_id from _t_lap_penjualan),
    955,
    current_date,
    'dinein',
    'draf',
    'kunci-pesanan-lpj-01'
  );

  insert into public.pesanan_item (
    pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
  ) values
    (v_pesanan_id, v_menu_makanan, 'Nasi Goreng Penjualan', 27000, 2, 54000),
    (v_pesanan_id, v_menu_minuman, 'Es Teh Penjualan', 8000, 2, 16000);

  update public.pesanan
     set status = 'dikirim',
         dikirim_ke_dapur_pada = now()
   where id = v_pesanan_id;

  perform public.hitung_total(v_pesanan_id);

  select total into v_total_pesanan from public.pesanan where id = v_pesanan_id;

  -- Bayar pesanan lunas dengan QRIS
  v_res := public.bayar_pesanan(
    v_pesanan_id,
    (select metode_qris_id from _t_lap_penjualan),
    v_total_pesanan,
    null,
    'QRIS-LPJ-REF-999',
    'kunci-bayar-lpj-01'
  );
  perform uji.harap((v_res->>'berhasil')::boolean = true, 'Pembayaran pesanan uji penjualan lunas');
end;
$$;

-- ---------------------------------------------------------------------------
-- 6. Verifikasi Angka Laporan Penjualan (Owner Bu Oasis)
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Bu Oasis
set local role authenticated;

-- Verifikasi pemanggilan multi-cabang (semua cabang)
select uji.sama(
  (select (public.laporan_penjualan(null, current_date, current_date)->>'berhasil')::boolean),
  true,
  'Owner berhasil memanggil laporan penjualan multi-cabang'
);

-- Total omzet mencakup pesanan uji (minimal 70.000)
select uji.sama(
  (select (public.laporan_penjualan(null, current_date, current_date)->'data'->'ringkasan'->>'total_omzet')::integer >= 70000),
  true,
  'Total omzet pada laporan penjualan mencakup pesanan lunas'
);

-- Omzet makanan mencakup 54.000
select uji.sama(
  (select (public.laporan_penjualan(null, current_date, current_date)->'data'->'jenis_menu'->>'omzet_makanan')::integer >= 54000),
  true,
  'Omzet jenis makanan mencakup pesanan makanan'
);

-- Omzet minuman mencakup 16.000
select uji.sama(
  (select (public.laporan_penjualan(null, current_date, current_date)->'data'->'jenis_menu'->>'omzet_minuman')::integer >= 16000),
  true,
  'Omzet jenis minuman mencakup pesanan minuman'
);

-- Rincian per kategori memuat kategori Makanan
select uji.sama(
  (select exists (
    select 1
      from jsonb_array_elements(public.laporan_penjualan(null, current_date, current_date)->'data'->'per_kategori') elem
     where (elem->>'total_omzet')::integer >= 54000
  )),
  true,
  'Rincian per kategori memuat omzet kategori makanan'
);

-- Rincian per metode bayar memuat QRIS
select uji.sama(
  (select exists (
    select 1
      from jsonb_array_elements(public.laporan_penjualan(null, current_date, current_date)->'data'->'per_metode') elem
     where elem->>'metode_nama' = 'QRIS'
       and (elem->>'total_nominal')::integer >= 70000
  )),
  true,
  'Rincian metode bayar mencatat nominal QRIS'
);

-- Tren harian memuat data hari ini
select uji.sama(
  (select exists (
    select 1
      from jsonb_array_elements(public.laporan_penjualan(null, current_date, current_date)->'data'->'tren_harian') elem
     where elem->>'tanggal' = to_char(current_date, 'YYYY-MM-DD')
       and (elem->>'total_omzet')::integer >= 70000
  )),
  true,
  'Tren harian memuat rekapan omzet tanggal hari ini'
);

-- ---------------------------------------------------------------------------
-- 7. View public.laporan_penjualan_harian
-- ---------------------------------------------------------------------------
select uji.sama(
  (select exists (
    select 1
      from public.laporan_penjualan_harian
     where cabang_id = (select cabang_id from _t_lap_penjualan)
       and tanggal = current_date
       and total_omzet >= 70000
  )),
  true,
  'View laporan_penjualan_harian merekapitulasi omzet cabang pada tanggal transaksi'
);

-- ---------------------------------------------------------------------------
-- 8. Isolasi Multi-Tenant
-- ---------------------------------------------------------------------------
-- Ujang sebagai owner Resto B mencoba mengakses laporan cabang Resto A
reset role;
update public.pengguna set peran = 'owner_pusat' where id = '90000000-0000-0000-0000-000000000007';

select uji.klaim('90000000-0000-0000-0000-000000000007'); -- Ujang (Owner Resto B)
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.laporan_penjualan((select cabang_id from _t_lap_penjualan))$$,
  'Cabang tidak ditemukan',
  'Owner resto lain tidak boleh mengakses laporan penjualan cabang resto berbeda'
);

-- Kembalikan peran Ujang
reset role;
update public.pengguna set peran = 'kasir' where id = '90000000-0000-0000-0000-000000000007';
