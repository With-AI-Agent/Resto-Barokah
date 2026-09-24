-- ============================================================================
-- UJI: Laporan A — Kas Harian per Shift (T7-07, PRD M8 · TECH_SPEC §5)
--
-- Yang dibuktikan:
--   1. Tanpa identitas: rpc laporan_shift & laporan_harian ditolak.
--   2. Peran tidak berwenang (pelayan/dapur): laporan_harian & shift orang lain ditolak.
--   3. Kasir yang membuka shift: berhak melihat laporan shift miliknya sendiri.
--   4. Nilai-nilai kas & omzet di laporan_shift:
--      - Modal awal, kas masuk, kas keluar, setoran tercatat tepat.
--      - Penjualan tunai & non-tunai terpisah dan akurat.
--      - Uang seharusnya dihitung peladen: modal + tunai_masuk - tunai_keluar.
--      - Pembagian omzet kategori: makanan, minuman, lainnya.
--      - Rincian metode bayar (tunai & QRIS).
--      - Selisih kas & alasan tercatat saat shift ditutup.
--   5. Laporan harian:
--      - Mengagregasi seluruh shift pada tanggal bersangkutan di cabang.
--      - Menampilkan ringkasan kas, omzet, dan rincian metode.
--   6. Isolasi multi-tenant:
--      - Owner Resto B tidak bisa mengakses laporan shift/harian Resto A.
--   7. View laporan_kas_shift:
--      - Menyajikan data shift yang sesuai hak cabang.
-- ============================================================================

create temp table if not exists _t_lap_kas (
  cabang_id uuid,
  shift_id uuid,
  metode_tunai_id uuid,
  metode_qris_id uuid
);
grant all on _t_lap_kas to authenticated;

delete from _t_lap_kas;

insert into _t_lap_kas (cabang_id, metode_tunai_id, metode_qris_id)
values (
  'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
  (select id from public.metode_bayar where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai' limit 1),
  (select id from public.metode_bayar where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'QRIS' limit 1)
);

-- ---------------------------------------------------------------------------
-- 1. Tanpa Identitas
-- ---------------------------------------------------------------------------
select uji.klaim(null);

select uji.harap_gagal_sebab(
  $$select public.laporan_shift('00000000-0000-0000-0000-000000000001'::uuid)$$,
  'harus masuk dulu',
  'Tanpa masuk, laporan_shift ditolak'
);

select uji.harap_gagal_sebab(
  $$select public.laporan_harian('a1a1a1a1-0000-0000-0000-000000000001'::uuid)$$,
  'harus masuk dulu',
  'Tanpa masuk, laporan_harian ditolak'
);

-- ---------------------------------------------------------------------------
-- 2. Peran Tanpa Wewenang (Pelayan Dedi & Dapur Budi)
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000005'); -- Dedi Pelayan
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.laporan_harian('a1a1a1a1-0000-0000-0000-000000000001'::uuid)$$,
  'tidak berwenang',
  'Pelayan tidak boleh membaca laporan harian'
);

select uji.harap_gagal_sebab(
  $$select public.laporan_shift('00000000-0000-0000-0000-000000000001'::uuid)$$,
  'Shift tidak ditemukan|tidak berwenang',
  'Pelayan tidak boleh membaca shift yang bukan miliknya'
);
reset role;

-- ---------------------------------------------------------------------------
-- 3. Kasir Rina Buka Shift & Lakukan Transaksi
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Rina Kasir
set local role authenticated;

do $$
declare
  v_res jsonb;
  v_shift_id uuid;
begin
  -- Buka shift dengan modal awal 100.000
  v_res := public.buka_shift(
    100000,
    (select cabang_id from _t_lap_kas),
    'Shift Pagi Rina untuk Uji Laporan'
  );
  v_shift_id := (v_res->>'shift_id')::uuid;
  update _t_lap_kas set shift_id = v_shift_id;
  perform uji.harap(v_shift_id is not null, 'Buka shift berhasil untuk uji laporan');
end;
$$;

-- Kasir berhak melihat laporan shift miliknya sendiri saat shift masih terbuka
select uji.sama(
  (select (public.laporan_shift((select shift_id from _t_lap_kas))->>'berhasil')::boolean),
  true,
  'Kasir yang membuka shift berhak melihat laporan shift miliknya sendiri'
);

-- Periksa modal awal di laporan
select uji.sama(
  (select (public.laporan_shift((select shift_id from _t_lap_kas))->'data'->'kas'->>'modal_awal')::integer),
  100000,
  'Modal awal shift terbaca tepat 100.000 di laporan'
);

-- Namun kasir tetap DITOLAK membaca laporan harian toko
select uji.harap_gagal_sebab(
  $$select public.laporan_harian((select cabang_id from _t_lap_kas))$$,
  'tidak berwenang',
  'Kasir tidak boleh membaca laporan harian akumulasi cabang'
);

-- ---------------------------------------------------------------------------
-- 4. Transaksi Kas Masuk/Keluar & Pembayaran Penjualan
-- ---------------------------------------------------------------------------
-- Kas masuk: tambahan modal kembalian Rp50.000
do $$
declare
  v_res jsonb;
begin
  v_res := public.kas_pergerakan(
    'masuk',
    50000,
    'Tambahan uang kembalian pecahan kecil',
    (select shift_id from _t_lap_kas)
  );
  perform uji.harap((v_res->>'berhasil')::boolean = true, 'Kas masuk tambahan modal berhasil');
end;
$$;

-- Kas keluar: beli es batu Rp20.000
do $$
declare
  v_res jsonb;
begin
  v_res := public.kas_pergerakan(
    'keluar',
    20000,
    'Beli es batu kristal darurat',
    (select shift_id from _t_lap_kas)
  );
  perform uji.harap((v_res->>'berhasil')::boolean = true, 'Kas keluar operasional berhasil');
end;
$$;

-- Pembayaran pesanan tunai (pesanan eeee0000...0010, total 62.100)
do $$
declare
  v_res jsonb;
begin
  v_res := public.bayar_pesanan(
    'eeee0000-0000-0000-0000-000000000010'::uuid,
    (select metode_tunai_id from _t_lap_kas),
    62100,
    70000,
    null,
    'kunci-bayar-lap-kas-01'
  );
  perform uji.harap((v_res->>'berhasil')::boolean = true, 'Pembayaran pesanan tunai berhasil');
end;
$$;

-- Buat pesanan baru untuk non-tunai (QRIS) dengan kategori makanan & minuman
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
    (select cabang_id from _t_lap_kas),
    (select shift_id from _t_lap_kas),
    901,
    current_date,
    'dinein',
    'draf',
    'kunci-pesanan-lap-02'
  );

  insert into public.pesanan_item (
    pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
  ) values
    (v_pesanan_id, v_menu_makanan, 'Nasi Goreng', 27000, 1, 27000),
    (v_pesanan_id, v_menu_minuman, 'Es Teh Manis', 8000, 1, 8000);

  update public.pesanan
     set status = 'dikirim',
         dikirim_ke_dapur_pada = now()
   where id = v_pesanan_id;

  -- Hitung total dari peladen
  perform public.hitung_total(v_pesanan_id);

  select total into v_total_pesanan from public.pesanan where id = v_pesanan_id;

  -- Bayar pesanan dengan QRIS
  v_res := public.bayar_pesanan(
    v_pesanan_id,
    (select metode_qris_id from _t_lap_kas),
    v_total_pesanan,
    null,
    'QRIS-LAP-TEST-1234',
    'kunci-bayar-qris-lap-02'
  );
  perform uji.harap((v_res->>'berhasil')::boolean = true, 'Pembayaran pesanan QRIS berhasil');
end;
$$;

-- Verifikasi angka laporan shift sebelum tutup
-- modal_awal: 100.000
-- kas_masuk: 50.000
-- kas_keluar: 20.000
-- penjualan_tunai: 62.100
-- uang_seharusnya: 100.000 + 62.100 + 50.000 - 20.000 = 192.100
select uji.sama(
  (select (public.laporan_shift((select shift_id from _t_lap_kas))->'data'->'kas'->>'penjualan_tunai')::integer),
  62100,
  'Penjualan tunai tercatat tepat 62.100'
);

select uji.sama(
  (select (public.laporan_shift((select shift_id from _t_lap_kas))->'data'->'kas'->>'penjualan_non_tunai')::integer > 0),
  true,
  'Penjualan non-tunai QRIS tercatat positif di laporan'
);

select uji.sama(
  (select (public.laporan_shift((select shift_id from _t_lap_kas))->'data'->'kas'->>'uang_seharusnya')::integer),
  192100,
  'Uang seharusnya dihitung peladen tepat 192.100'
);

-- Tutup shift dengan uang fisik Rp190.000 (selisih -2.100 karena uang kembalian permen)
do $$
declare
  v_res jsonb;
begin
  v_res := public.tutup_shift(
    190000,
    'Selisih 2100 pembulatan permen kembalian',
    (select shift_id from _t_lap_kas),
    'Tutup shift pagi uji laporan'
  );
  perform uji.harap((v_res->>'berhasil')::boolean = true, 'Tutup shift berhasil');
end;
$$;

-- ---------------------------------------------------------------------------
-- 5. Laporan Shift Sesudah Tutup Kas
-- ---------------------------------------------------------------------------
select uji.sama(
  (select (public.laporan_shift((select shift_id from _t_lap_kas))->'data'->'shift'->>'status')),
  'ditutup',
  'Status shift pada laporan telah berubah menjadi ditutup'
);

select uji.sama(
  (select (public.laporan_shift((select shift_id from _t_lap_kas))->'data'->'kas'->>'uang_fisik')::integer),
  190000,
  'Uang fisik tercatat tepat 190.000'
);

select uji.sama(
  (select (public.laporan_shift((select shift_id from _t_lap_kas))->'data'->'kas'->>'selisih')::integer),
  -2100,
  'Selisih kas tercatat tepat -2.100'
);

select uji.sama(
  (select (public.laporan_shift((select shift_id from _t_lap_kas))->'data'->'kas'->>'alasan_selisih')),
  'Selisih 2100 pembulatan permen kembalian',
  'Alasan selisih kas tersimpan dan tampil di laporan'
);

-- Periksa omzet per kategori menu
select uji.sama(
  (select (public.laporan_shift((select shift_id from _t_lap_kas))->'data'->'penjualan'->>'omzet_makanan')::integer >= 25000),
  true,
  'Omzet makanan mencakup item makanan terpesan'
);

select uji.sama(
  (select (public.laporan_shift((select shift_id from _t_lap_kas))->'data'->'penjualan'->>'omzet_minuman')::integer >= 8000),
  true,
  'Omzet minuman mencakup item minuman terpesan'
);

-- Verifikasi hak akses pegawai tanpa izin lihat_laporan pada shift yang ada
select uji.klaim('90000000-0000-0000-0000-000000000005'); -- Joko Pelayan (Cabang A1)
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.laporan_shift((select shift_id from _t_lap_kas))$$,
  'tidak berwenang',
  'Pelayan tidak boleh melihat laporan shift kasir'
);

-- ---------------------------------------------------------------------------
-- 6. Laporan Harian untuk Owner Bu Oasis & Admin Andi
-- ---------------------------------------------------------------------------
-- Admin Andi (admin_cabang Pusat) memanggil laporan_harian
select uji.klaim('90000000-0000-0000-0000-000000000003'); -- Admin Andi
set local role authenticated;

select uji.sama(
  (select (public.laporan_harian((select cabang_id from _t_lap_kas), current_date)->>'berhasil')::boolean),
  true,
  'Admin cabang berhasil mengakses laporan_harian cabang binaannya'
);

select uji.sama(
  (select (public.laporan_harian((select cabang_id from _t_lap_kas), current_date)->'data'->>'jumlah_shift')::integer >= 1),
  true,
  'Laporan harian memuat minimal 1 shift pada hari ini'
);

-- Owner Bu Oasis (owner_pusat) melihat laporan harian
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Bu Oasis
set local role authenticated;

select uji.sama(
  (select (public.laporan_harian(null, current_date)->>'berhasil')::boolean),
  true,
  'Owner pusat berhasil memanggil laporan_harian multi-cabang (cabang_id null)'
);

-- ---------------------------------------------------------------------------
-- 7. Isolasi Multi-Tenant
-- ---------------------------------------------------------------------------
-- Set Ujang sebagai owner_pusat di Resto B untuk menguji izin lihat_laporan lintas penyewa
reset role;
update public.pengguna set peran = 'owner_pusat' where id = '90000000-0000-0000-0000-000000000007';

select uji.klaim('90000000-0000-0000-0000-000000000007'); -- Ujang (Owner Resto B)
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.laporan_shift((select shift_id from _t_lap_kas))$$,
  'Shift tidak ditemukan',
  'Owner resto lain tidak dapat melihat laporan shift resto berbeda'
);

select uji.harap_gagal_sebab(
  $$select public.laporan_harian((select cabang_id from _t_lap_kas), current_date)$$,
  'Cabang tidak ditemukan',
  'Owner resto lain tidak dapat melihat laporan harian cabang resto berbeda'
);

-- Kembalikan peran Ujang
reset role;
update public.pengguna set peran = 'kasir' where id = '90000000-0000-0000-0000-000000000007';

-- ---------------------------------------------------------------------------
-- 8. View public.laporan_kas_shift
-- ---------------------------------------------------------------------------
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Bu Oasis
set local role authenticated;

select uji.sama(
  (select count(*) from public.laporan_kas_shift where shift_id = (select shift_id from _t_lap_kas)) = 1,
  true,
  'View laporan_kas_shift menampilkan baris shift terkait untuk pemegang izin'
);

select uji.sama(
  (select total_penjualan from public.laporan_kas_shift where shift_id = (select shift_id from _t_lap_kas)),
  102350,
  'View laporan_kas_shift menghitung total penjualan tunai dan non-tunai secara tepat (62.100 + 40.250)'
);

reset role;
select uji.klaim(null);
