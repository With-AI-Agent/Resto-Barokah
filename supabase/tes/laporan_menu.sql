-- ============================================================================
-- Uji SQL: Laporan Menu Terlaris & Diskon / Voucher Terpakai
-- Tugas: T7-09 (PRD M8 & M10 — Menu andalan & biaya promosi)
-- ============================================================================

-- Tabel sementara penyimpan data uji laporan menu
create temp table _t_lap_menu (
  cabang_id uuid,
  cabang_dua_id uuid,
  shift_id uuid,
  metode_tunai_id uuid,
  metode_qris_id uuid
);
grant all on _t_lap_menu to authenticated;

insert into _t_lap_menu (
  cabang_id,
  cabang_dua_id,
  metode_tunai_id,
  metode_qris_id
) values (
  'a1a1a1a1-0000-0000-0000-000000000001',
  'a1a1a1a1-0000-0000-0000-000000000002',
  (select id from public.metode_bayar where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai' limit 1),
  (select id from public.metode_bayar where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'QRIS' limit 1)
);

-- ---------------------------------------------------------------------------
-- 1. Panggilan Anonim Ditolak
-- ---------------------------------------------------------------------------
select uji.harap_gagal_sebab(
  $$select public.laporan_menu()$$,
  'Anda harus masuk dulu',
  'Anonim tidak boleh mengakses laporan menu'
);

-- ---------------------------------------------------------------------------
-- 2. Peran Tanpa Wewenang (Pelayan & Kasir tanpa izin) Ditolak
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000005'); -- Joko Pelayan
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.laporan_menu()$$,
  'tidak berwenang',
  'Pelayan tidak boleh membaca laporan menu'
);

select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Rina Kasir
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.laporan_menu()$$,
  'tidak berwenang',
  'Kasir tanpa izin lihat_laporan tidak boleh membaca laporan menu'
);

-- ---------------------------------------------------------------------------
-- 3. Validasi Rentang Tanggal (Batas 90 Hari & Urutan Tanggal)
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Bu Oasis (Owner)
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.laporan_menu(null, '2026-09-24', '2026-09-20')$$,
  'lebih awal dari tanggal mulai',
  'Tanggal akhir lebih awal dari tanggal mulai wajib ditolak'
);

select uji.harap_gagal_sebab(
  $$select public.laporan_menu(null, '2026-01-01', '2026-06-01')$$,
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
  $$select public.laporan_menu((select cabang_dua_id from _t_lap_menu))$$,
  'di luar wewenang pantauan',
  'Admin cabang tidak boleh melihat laporan menu cabang lain yang bukan binaannya'
);

-- Admin Andi berhasil memanggil laporan cabang binaannya sendiri
select uji.sama(
  (select (public.laporan_menu((select cabang_id from _t_lap_menu))->>'berhasil')::boolean),
  true,
  'Admin cabang berhasil mengakses laporan menu cabang miliknya'
);

-- ---------------------------------------------------------------------------
-- 5. Transaksi Uji untuk Validasi Menu Terlaris & Diskon Manual
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
    (select cabang_id from _t_lap_menu),
    'Shift menu uji T7-09'
  );
  v_shift_id := (v_res->>'shift_id')::uuid;
  update _t_lap_menu set shift_id = v_shift_id;
end;
$$;

-- Kasir membuat pesanan dengan 3 porsi Nasi Goreng dan diskon manual Rp5.000
do $$
declare
  v_pesanan_id uuid := gen_random_uuid();
  v_menu_makanan uuid;
  v_total_pesanan integer;
  v_res jsonb;
begin
  select id into v_menu_makanan
    from public.menu_item
   where penyewa_id = '11111111-1111-1111-1111-111111111111'
     and jenis = 'makanan'
   limit 1;

  insert into public.pesanan (
    id, penyewa_id, cabang_id, shift_id, nomor, tanggal, tipe, status, kunci_idempoten
  ) values (
    v_pesanan_id,
    '11111111-1111-1111-1111-111111111111',
    (select cabang_id from _t_lap_menu),
    (select shift_id from _t_lap_menu),
    960,
    current_date,
    'dinein',
    'draf',
    'kunci-pesanan-lpm-01'
  );

  insert into public.pesanan_item (
    pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
  ) values
    (v_pesanan_id, v_menu_makanan, 'Nasi Goreng Spesial Barokah', 27000, 3, 81000);

  -- Beri diskon manual 4.000 (di bawah batas 5% kasir Rina: 5% * 81.000 = 4.050)
  insert into public.diskon_transaksi (
    pesanan_id, jenis, nominal, nilai, alasan, pelaku_id
  ) values (
    v_pesanan_id, 'manual', 4000, 4000, 'Diskon pelanggan setia T7-09', '90000000-0000-0000-0000-000000000004'
  );

  update public.pesanan
     set status = 'dikirim',
         dikirim_ke_dapur_pada = now()
   where id = v_pesanan_id;

  perform public.hitung_total(v_pesanan_id);

  select total into v_total_pesanan from public.pesanan where id = v_pesanan_id;

  -- Bayar pesanan lunas dengan Tunai
  v_res := public.bayar_pesanan(
    v_pesanan_id,
    (select metode_tunai_id from _t_lap_menu),
    v_total_pesanan,
    100000,
    null,
    'kunci-bayar-lpm-01'
  );
  perform uji.harap((v_res->>'berhasil')::boolean = true, 'Pembayaran pesanan uji menu lunas');
end;
$$;

-- ---------------------------------------------------------------------------
-- 6. Verifikasi Angka Laporan Menu (Owner Bu Oasis)
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Bu Oasis
set local role authenticated;

-- Verifikasi pemanggilan multi-cabang (semua cabang)
select uji.sama(
  (select (public.laporan_menu(null, current_date, current_date)->>'berhasil')::boolean),
  true,
  'Owner berhasil memanggil laporan menu multi-cabang'
);

-- Total porsi minimal 3
select uji.sama(
  (select (public.laporan_menu(null, current_date, current_date)->'data'->'ringkasan'->>'total_porsi')::integer >= 3),
  true,
  'Total porsi menu terjual mencakup pesanan uji'
);

-- Peringkat menu terlaris memuat nama_saat_itu item menu ('Nasi Goreng Spesial Barokah')
select uji.sama(
  (select exists (
    select 1
      from jsonb_array_elements(public.laporan_menu(null, current_date, current_date)->'data'->'peringkat_menu') elem
     where elem->>'nama_menu' = 'Nasi Goreng Spesial Barokah'
       and (elem->>'qty_terjual')::integer >= 3
  )),
  true,
  'Peringkat menu menggunakan nama_saat_itu dan mencatat jumlah porsi terjual'
);

-- Daftar diskon manual memuat diskon Rp4.000 dengan alasan yang benar
select uji.sama(
  (select exists (
    select 1
      from jsonb_array_elements(public.laporan_menu(null, current_date, current_date)->'data'->'diskon_manual') elem
     where elem->>'alasan' = 'Diskon pelanggan setia T7-09'
       and (elem->>'nilai')::integer = 4000
       and elem->>'kasir_nama' is not null
  )),
  true,
  'Daftar diskon manual memuat alasan, nilai potongan, dan nama kasir'
);

-- Total diskon manual pada ringkasan mencakup 4.000
select uji.sama(
  (select (public.laporan_menu(null, current_date, current_date)->'data'->'ringkasan'->>'total_diskon_manual')::integer >= 4000),
  true,
  'Ringkasan mencatat total diskon manual'
);

-- ---------------------------------------------------------------------------
-- 7. View public.laporan_menu_terlaris
-- ---------------------------------------------------------------------------
select uji.sama(
  (select exists (
    select 1
      from public.laporan_menu_terlaris
     where cabang_id = (select cabang_id from _t_lap_menu)
       and tanggal = current_date
       and nama_menu = 'Nasi Goreng Spesial Barokah'
       and qty_terjual >= 3
  )),
  true,
  'View laporan_menu_terlaris merekapitulasi penjualan menu cabang pada tanggal transaksi'
);

-- ---------------------------------------------------------------------------
-- 8. Isolasi Multi-Tenant
-- ---------------------------------------------------------------------------
-- Ujang sebagai owner Resto B mencoba mengakses laporan menu cabang Resto A
reset role;
update public.pengguna set peran = 'owner_pusat' where id = '90000000-0000-0000-0000-000000000007';

select uji.klaim('90000000-0000-0000-0000-000000000007'); -- Ujang (Owner Resto B)
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.laporan_menu((select cabang_id from _t_lap_menu))$$,
  'Cabang tidak ditemukan',
  'Owner resto lain tidak boleh mengakses laporan menu cabang resto berbeda'
);

-- Kembalikan peran Ujang
reset role;
update public.pengguna set peran = 'kasir' where id = '90000000-0000-0000-0000-000000000007';
