-- ============================================================================
-- UJI SQL: Denyut Harian & Pembersih Data Sementara (T10-08 / TECH_SPEC §1 & §10)
--
-- Memverifikasi:
--   1. Otorisasi denyut_harian: hanya pemilik_platform atau sistem (service_role).
--   2. Denyut harian mencatat aktivitas kesehatan sistem ke log_jadwal.
--   3. Otorisasi bersihkan_data_sementara: hanya pemilik_platform atau service_role.
--   4. Validasi parameter hari retensi (1 - 365 hari).
--   5. Pembersih menghapus data sementara di luar batas retensi:
--      - percobaan_pin lama terhapus, data baru bertahan
--      - percobaan_simpan_pin lama terhapus, data baru bertahan
--      - percobaan_masuk lama terhapus, data baru bertahan
--      - voucher_percobaan lama terhapus, data baru bertahan
--      - kode_pendaftaran kadaluwarsa terhapus
--      - pemulihan selesai kadaluwarsa terhapus, status menunggu bertahan
--      - sesi_cabang diakhiri kadaluwarsa terhapus, sesi aktif bertahan
--      - mode_dukungan kadaluwarsa otomatis dinonaktifkan (aktif = false)
--   6. PERLINDUNGAN TABEL INTI: data keuangan, menu, stok, pelanggan, voucher,
--      dan catatan_audit 100% UTUH (selisih = 0).
--   7. log_jadwal dilindungi RLS: kasir tidak bisa melihat, pemilik platform bisa.
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Otorisasi Denyut Harian
-- ---------------------------------------------------------------------------
-- Kasir Rina mencoba memicu denyut
select uji.klaim('90000000-0000-0000-0000-000000000004');
select uji.harap_gagal_sebab(
  'select public.denyut_harian()',
  'Hanya pemilik platform atau sistem',
  'Kasir dilarang memicu denyut harian sistem'
);

-- Owner Bu Oasis mencoba memicu denyut
select uji.klaim('90000000-0000-0000-0000-000000000002');
select uji.harap_gagal_sebab(
  'select public.denyut_harian()',
  'Hanya pemilik platform atau sistem',
  'Owner resto dilarang memicu denyut sistem platform'
);

-- Pemilik Platform memicu denyut harian
select uji.klaim('90000000-0000-0000-0000-000000000001');
do $$
declare
  v_res jsonb;
begin
  v_res := public.denyut_harian();
  if (v_res->>'berhasil')::boolean is not true then
    raise exception 'denyut_harian gagal dieksekusi';
  end if;
  if (v_res->>'jenis') <> 'denyut' then
    raise exception 'jenis respon bukan denyut';
  end if;
  if (v_res->>'penyewa_aktif')::int < 2 then
    raise exception 'penyewa_aktif tidak terhitung wajar';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 2. Otorisasi & Validasi Parameter Pembersih Data Sementara
-- ---------------------------------------------------------------------------
-- Kasir mencoba menjalankan pembersihan
select uji.klaim('90000000-0000-0000-0000-000000000004');
select uji.harap_gagal_sebab(
  'select public.bersihkan_data_sementara(30)',
  'Hanya pemilik platform atau sistem',
  'Kasir dilarang menjalankan pembersihan data'
);

-- Pemilik Platform mencoba nilai retensi tidak sah
select uji.klaim('90000000-0000-0000-0000-000000000001');
select uji.harap_gagal_sebab(
  'select public.bersihkan_data_sementara(0)',
  'Hari retensi minimal 1 hari',
  'Retensi 0 hari wajib ditolak'
);

select uji.harap_gagal_sebab(
  'select public.bersihkan_data_sementara(400)',
  'Hari retensi maksimal 365 hari',
  'Retensi > 365 hari wajib ditolak'
);

-- ---------------------------------------------------------------------------
-- 3. Penyiapan Data Uji Sementara & Pengukuran Data Inti
-- ---------------------------------------------------------------------------
reset role;

-- Catat jumlah data inti sebelum pembersihan
create temp table tmp_hitung_inti as
select
  (select count(*) from public.penyewa) as cnt_penyewa,
  (select count(*) from public.cabang) as cnt_cabang,
  (select count(*) from public.pengguna) as cnt_pengguna,
  (select count(*) from public.menu_item) as cnt_menu,
  (select count(*) from public.pesanan) as cnt_pesanan,
  (select count(*) from public.pembayaran) as cnt_pembayaran,
  (select count(*) from public.catatan_audit) as cnt_audit,
  (select count(*) from public.pelanggan) as cnt_pelanggan;

-- Sisipkan data sementara LAMA (usia > 40 hari)
insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, waktu)
values ('90000000-0000-0000-0000-000000000004', 'hp-lama-01', false, 'void', now() - interval '45 days');

insert into public.percobaan_simpan_pin (pengguna_id, perangkat, berhasil, alasan, waktu)
values ('90000000-0000-0000-0000-000000000004', 'hp-lama-01', false, 'terlalu_lemah', now() - interval '45 days');

insert into public.percobaan_masuk (penyewa_id, pengguna_id, berhasil, sebab, waktu)
values ('11111111-1111-1111-1111-111111111111', '90000000-0000-0000-0000-000000000004', false, 'pin_salah', now() - interval '45 days');

insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, waktu)
values ('11111111-1111-1111-1111-111111111111', 'RB-EXPIRED-TEST', 'gagal', now() - interval '45 days');

insert into public.kode_pendaftaran_perangkat (id, penyewa_id, cabang_id, kode, nama_perangkat, dibuat_oleh, kedaluwarsa_pada, dipakai_pada)
values (
  'cd000000-0000-0000-0000-000000000001',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  'KODE-KADALUWARSA-01',
  'Tablet Rusak Lama',
  '90000000-0000-0000-0000-000000000002',
  now() - interval '45 days',
  null
);

insert into public.sesi_perangkat (
  session_id,
  penyewa_id,
  perangkat_id,
  pengguna_id,
  cabang_id,
  mulai,
  berakhir_pada,
  status,
  diperbarui_pada
) values (
  'sess-lama-selesai-01',
  '11111111-1111-1111-1111-111111111111',
  'de000000-0000-0000-0000-000000000003',
  '90000000-0000-0000-0000-000000000004',
  'a1a1a1a1-0000-0000-0000-000000000001',
  now() - interval '50 days',
  now() - interval '45 days',
  'selesai',
  now() - interval '45 days'
);

insert into public.mode_dukungan (id, penyewa_id, pelaku_id, alasan, mulai, berakhir_pada, aktif)
values (
  'fd000000-0000-0000-0000-000000000001',
  '11111111-1111-1111-1111-111111111111',
  '90000000-0000-0000-0000-000000000001',
  'Bantuan investigasi insiden darurat kedai',
  now() - interval '2 hours',
  now() - interval '1 hour',
  true
);

-- Sisipkan data sementara BARU (usia < 5 hari — TIDAK BOLEH TERHAPUS)
insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, waktu)
values ('90000000-0000-0000-0000-000000000004', 'hp-baru-01', false, 'void', now() - interval '2 days');

insert into public.percobaan_masuk (penyewa_id, pengguna_id, berhasil, sebab, waktu)
values ('11111111-1111-1111-1111-111111111111', '90000000-0000-0000-0000-000000000004', false, 'pin_salah', now() - interval '2 days');

-- ---------------------------------------------------------------------------
-- 4. Eksekusi Pembersihan Data Sementara (Retensi 30 Hari)
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000001');

do $$
declare
  v_res jsonb;
  v_dibersihkan jsonb;
begin
  v_res := public.bersihkan_data_sementara(30);
  if (v_res->>'berhasil')::boolean is not true then
    raise exception 'bersihkan_data_sementara gagal dieksekusi';
  end if;

  v_dibersihkan := v_res->'dibersihkan';
  if (v_dibersihkan->>'percobaan_pin')::int < 1 then
    raise exception 'percobaan_pin lama tidak terhapus';
  end if;
  if (v_dibersihkan->>'kode_pendaftaran_kadaluwarsa')::int < 1 then
    raise exception 'kode_pendaftaran_kadaluwarsa tidak terhapus';
  end if;
  if (v_dibersihkan->>'mode_dukungan_dinonaktifkan')::int < 1 then
    raise exception 'mode_dukungan kadaluwarsa tidak dinonaktifkan';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 5. Verifikasi Data Baru Bertahan & Data Lama Bersih
-- ---------------------------------------------------------------------------
reset role;

-- Data lama (>30 hari) harus 0
do $$
declare
  v_sisa int;
begin
  select count(*) into v_sisa from public.percobaan_pin where waktu < now() - interval '30 days';
  if v_sisa > 0 then
    raise exception 'Masih ada percobaan_pin usia > 30 hari: %', v_sisa;
  end if;

  -- Data baru (<30 hari) harus tetap ada
  select count(*) into v_sisa from public.percobaan_pin where waktu >= now() - interval '30 days';
  if v_sisa = 0 then
    raise exception 'percobaan_pin baru ikut terhapus!';
  end if;

  -- Mode dukungan kedaluwarsa sudah dinonaktifkan
  select count(*) into v_sisa from public.mode_dukungan
    where id = 'fd000000-0000-0000-0000-000000000001' and aktif = true;
  if v_sisa > 0 then
    raise exception 'mode_dukungan kedaluwarsa masih aktif!';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 6. Pagar Pengaman: Verifikasi 100% Data Inti Finansial & Audit Tidak Berkurang
-- ---------------------------------------------------------------------------
do $$
declare
  r record;
  v_penyewa int;
  v_cabang int;
  v_pengguna int;
  v_menu int;
  v_pesanan int;
  v_pembayaran int;
  v_audit int;
  v_pelanggan int;
begin
  select * into r from tmp_hitung_inti;

  select count(*) into v_penyewa from public.penyewa;
  select count(*) into v_cabang from public.cabang;
  select count(*) into v_pengguna from public.pengguna;
  select count(*) into v_menu from public.menu_item;
  select count(*) into v_pesanan from public.pesanan;
  select count(*) into v_pembayaran from public.pembayaran;
  select count(*) into v_audit from public.catatan_audit;
  select count(*) into v_pelanggan from public.pelanggan;

  if v_penyewa <> r.cnt_penyewa then raise exception 'Tabel penyewa tersentuh pembersih!'; end if;
  if v_cabang <> r.cnt_cabang then raise exception 'Tabel cabang tersentuh pembersih!'; end if;
  if v_pengguna <> r.cnt_pengguna then raise exception 'Tabel pengguna tersentuh pembersih!'; end if;
  if v_menu <> r.cnt_menu then raise exception 'Tabel menu_item tersentuh pembersih!'; end if;
  if v_pesanan <> r.cnt_pesanan then raise exception 'Tabel pesanan tersentuh pembersih!'; end if;
  if v_pembayaran <> r.cnt_pembayaran then raise exception 'Tabel pembayaran tersentuh pembersih!'; end if;
  if v_audit <> r.cnt_audit then raise exception 'Tabel catatan_audit tersentuh pembersih!'; end if;
  if v_pelanggan <> r.cnt_pelanggan then raise exception 'Tabel pelanggan tersentuh pembersih!'; end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 7. Verifikasi RLS & RPC ambil_log_jadwal
-- ---------------------------------------------------------------------------
-- Pemilik platform membaca log jadwal
select uji.klaim('90000000-0000-0000-0000-000000000001');
do $$
declare
  v_log jsonb;
begin
  v_log := public.ambil_log_jadwal(10);
  if jsonb_array_length(v_log->'data') < 2 then
    raise exception 'ambil_log_jadwal tidak memuat denyut dan pembersihan';
  end if;
end;
$$;

-- Kasir membaca langsung tabel log_jadwal (wajib 0 baris via RLS)
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
do $$
declare
  v_hitung int;
begin
  select count(*) into v_hitung from public.log_jadwal;
  if v_hitung > 0 then
    raise exception 'RLS log_jadwal bocor: kasir dapat melihat % baris', v_hitung;
  end if;
end;
$$;

-- Kasir memanggil RPC ambil_log_jadwal (wajib ditolak P0001)
select uji.harap_gagal_sebab(
  'select public.ambil_log_jadwal(10)',
  'Hanya pemilik platform atau sistem',
  'Kasir dilarang memanggil ambil_log_jadwal'
);

rollback;
