-- ============================================================================
-- PENGUJIAN: Kelola Cabang, Konfigurasi Printer & Multi-Penugasan (T9-09 / PRD M11 / ART-1 & ART-12)
--
-- Membuktikan secara komprehensif:
--  1. Otorisasi tambah cabang baru (owner pusat vs kasir/admin).
--  2. Tambah cabang sukses lengkap dengan zona waktu dan konfigurasi printer.
--  3. Validasi nama cabang (tolak kosong, tolak duplikat se-resto).
--  4. Validasi zona waktu resmi (WIB, WITA, WIT).
--  5. Validasi lebar kertas printer (hanya 58 atau 80 mm).
--  6. Edit profil cabang & printer default oleh owner pusat.
--  7. Otorisasi edit cabang: admin cabang hanya boleh ubah cabangnya sendiri.
--  8. Admin cabang dilarang mengubah cabang milik resto lain atau cabang lain.
--  9. Nonaktifkan cabang (soft-disable) tanpa merusak integritas riwayat transaksi (ART-12).
-- 10. Fail-closed: tolak menonaktifkan satu-satunya cabang aktif di restoran.
-- 11. Otorisasi status cabang: staf dilarang menonaktifkan cabang.
-- 12. Atur akses penugasan cabang (set_akses_cabang): pegawai merangkap multi-cabang.
-- 13. Cabut akses penugasan cabang staf.
-- 14. Tolak penugasan cabang silang resto (penyewa 1111 ke cabang 2222).
-- 15. Kasir biasa dilarang mengatur penugasan cabang.
-- 16. Pembacaan daftar cabang (ambil_daftar_cabang) mencakup statistik meja & pegawai.
-- 17. Isolasi penyewa RLS: cabang resto lain tidak bocor ke resto pemanggil (ART-1).
-- 18. Pembacaan akses cabang pegawai (ambil_akses_cabang_pegawai).
-- 19. Fail-closed: cabang ber-riwayat pesanan/meja/shift kas dilarang di-DELETE langsung.
-- 20. Cabang baru kosong tanpa riwayat transaksi boleh dihapus bersih.
-- ============================================================================

-- Identitas uji:
-- Bu Oasis (owner_pusat tenant 1111): 90000000-0000-0000-0000-000000000002
-- Pak Andi (admin_cabang tenant 1111, cabang Pusat): 90000000-0000-0000-0000-000000000003
-- Rina (kasir tenant 1111, cabang Pusat): 90000000-0000-0000-0000-000000000004
-- Ujang (kasir tenant 2222, cabang Tunggal): 90000000-0000-0000-0000-000000000007
-- Cabang Pusat (tenant 1111): a1a1a1a1-0000-0000-0000-000000000001
-- Cabang Kedua (tenant 1111): a1a1a1a1-0000-0000-0000-000000000002
-- Cabang Tunggal (tenant 2222): b1b1b1b1-0000-0000-0000-000000000001

begin;

-- ----------------------------------------------------------------------------
-- KASUS 1 & 2: Tambah cabang baru oleh owner pusat
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Bu Oasis

select uji.harap(
  (public.tambah_cabang(
    'Cabang Dago Bawah',
    'Jl. Ir. H. Juanda No. 120, Bandung',
    '022-2501234',
    'Asia/Jakarta',
    jsonb_build_object('profil_id', 'umum-58', 'lebar', 58, 'nama', 'Printer Thermal Dago')
  )->>'berhasil')::boolean = true,
  'K-01: Owner pusat berhasil membuka cabang baru lengkap dengan profil printer'
);

-- Buktikan baris cabang terpasang di database
select uji.harap(
  exists (
    select 1 from public.cabang
     where penyewa_id = '11111111-1111-1111-1111-111111111111'
       and nama = 'Cabang Dago Bawah'
       and zona_waktu = 'Asia/Jakarta'
       and (printer_default->>'lebar')::int = 58
       and aktif = true
  ),
  'K-02a: Data cabang baru, zona waktu, dan printer default tersimpan rapi'
);

-- Catatan audit tercatat
select uji.harap(
  exists (
    select 1 from public.catatan_audit
     where aksi = 'tambah_cabang'
       and entitas = 'cabang'
       and (nilai_baru->>'nama') = 'Cabang Dago Bawah'
  ),
  'K-02b: Aksi tambah cabang tercatat di catatan_audit'
);

-- Kasir atau staf biasa dilarang menambah cabang
select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Kasir Rina
select uji.harap_gagal_sebab(
  'select public.tambah_cabang(''Cabang Liar'', null, null);',
  'Hanya owner pusat yang dapat membuka cabang baru\.',
  'K-02c: Kasir ditolak membuka cabang baru'
);

-- ----------------------------------------------------------------------------
-- KASUS 3: Validasi nama cabang (kosong & duplikat)
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner

select uji.harap_gagal_sebab(
  'select public.tambah_cabang(''   '', null, null);',
  'Nama cabang harus di antara 1 dan 120 karakter\.',
  'K-03a: Nama cabang kosong ditolak'
);

select uji.harap_gagal_sebab(
  'select public.tambah_cabang(''Cabang Dago Bawah'', null, null);',
  'sudah digunakan di resto Anda',
  'K-03b: Nama cabang duplikat ditolak'
);

-- ----------------------------------------------------------------------------
-- KASUS 4: Validasi zona waktu resmi
-- ----------------------------------------------------------------------------
select uji.harap_gagal_sebab(
  'select public.tambah_cabang(''Cabang Luar Negeri'', null, null, ''America/New_York'');',
  'Zona waktu tidak valid',
  'K-04: Zona waktu di luar WIB/WITA/WIT ditolak'
);

-- ----------------------------------------------------------------------------
-- KASUS 5: Validasi lebar kertas printer
-- ----------------------------------------------------------------------------
select uji.harap_gagal_sebab(
  'select public.tambah_cabang(''Cabang Tes Printer'', null, null, ''Asia/Jakarta'', ''{"lebar": 70}'');',
  'Lebar kertas printer hanya boleh 58 atau 80 mm\.',
  'K-05: Lebar kertas selain 58 atau 80 mm ditolak'
);

-- ----------------------------------------------------------------------------
-- KASUS 6: Simpan cabang (edit profil & printer) oleh owner
-- ----------------------------------------------------------------------------
select uji.harap(
  (public.simpan_cabang(
    'a1a1a1a1-0000-0000-0000-000000000001',
    'Cabang Pusat Renovat',
    'Jl. Riau No. 50 Bandung',
    '022-7778888',
    'Asia/Jakarta',
    jsonb_build_object('profil_id', 'epson-t82', 'lebar', 80, 'nama', 'Epson T82')
  )->>'berhasil')::boolean = true,
  'K-06a: Owner berhasil mengubah profil cabang dan konfigurasi printer 80mm'
);

select uji.harap(
  exists (
    select 1 from public.cabang
     where id = 'a1a1a1a1-0000-0000-0000-000000000001'
       and nama = 'Cabang Pusat Renovat'
       and (printer_default->>'lebar')::int = 80
  ),
  'K-06b: Profil cabang dan printer baru terverifikasi di database'
);

-- ----------------------------------------------------------------------------
-- KASUS 7 & 8: Otorisasi edit cabang oleh admin cabang
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000003'); -- Pak Andi (admin cabang Pusat)

-- Pak Andi boleh mengedit cabang Pusat (tempatnya bertugas)
select uji.harap(
  (public.simpan_cabang(
    'a1a1a1a1-0000-0000-0000-000000000001',
    'Cabang Pusat Resmi',
    'Jl. Riau No. 50 Bandung',
    '022-7779999',
    'Asia/Jakarta',
    jsonb_build_object('profil_id', 'umum-58', 'lebar', 58)
  )->>'berhasil')::boolean = true,
  'K-07: Admin cabang dapat mengedit cabang tempatnya bertugas'
);

-- Pak Andi dilarang mengedit cabang Kedua (a1a1a1a1-0000-0000-0000-000000000002) tempat ia TIDAK bertugas
select uji.harap_gagal_sebab(
  'select public.simpan_cabang(''a1a1a1a1-0000-0000-0000-000000000002'', ''Cabang Kedua Bajakan'', null, null);',
  'Admin cabang hanya dapat mengubah cabang tempatnya bertugas\.',
  'K-08: Admin cabang dilarang mengedit cabang yang bukan tempatnya bertugas'
);

-- ----------------------------------------------------------------------------
-- KASUS 9: Nonaktifkan cabang (soft-disable ART-12)
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner

select uji.harap(
  (public.set_status_cabang('a1a1a1a1-0000-0000-0000-000000000002', false)->>'berhasil')::boolean = true,
  'K-09a: Owner berhasil menonaktifkan cabang kedua secara sementara'
);

select uji.harap(
  (select aktif from public.cabang where id = 'a1a1a1a1-0000-0000-0000-000000000002') = false,
  'K-09b: Status aktif cabang kedua bernilai false'
);

-- ----------------------------------------------------------------------------
-- KASUS 10: Fail-closed tolak menonaktifkan seluruh cabang
-- ----------------------------------------------------------------------------
-- Coba nonaktifkan cabang Dago Bawah
do $$
declare
  v_dago_id uuid;
begin
  select id into v_dago_id from public.cabang where nama = 'Cabang Dago Bawah';
  perform public.set_status_cabang(v_dago_id, false);
end $$;

-- Sekarang hanya Cabang Pusat Resmi yang masih aktif. Coba nonaktifkan Cabang Pusat via RPC -> WAJIB GAGAL!
select uji.harap_gagal_sebab(
  'select public.set_status_cabang(''a1a1a1a1-0000-0000-0000-000000000001'', false);',
  'Minimal harus ada satu cabang yang aktif di restoran\.',
  'K-10a: RPC set_status_cabang menolak menonaktifkan satu-satunya cabang aktif'
);

-- Coba nonaktifkan via direct UPDATE -> WAJIB GAGAL oleh trigger picu_cabang_minimal_satu_aktif
select uji.harap_gagal_sebab(
  'update public.cabang set aktif = false where id = ''a1a1a1a1-0000-0000-0000-000000000001'';',
  'Minimal harus ada satu cabang yang aktif di restoran\.',
  'K-10b: Trigger picu_cabang_minimal_satu_aktif menolak penonaktifan cabang aktif terakhir'
);

-- ----------------------------------------------------------------------------
-- KASUS 11: Otorisasi status cabang
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000003'); -- Admin cabang

select uji.harap_gagal_sebab(
  'select public.set_status_cabang(''a1a1a1a1-0000-0000-0000-000000000001'', false);',
  'Hanya owner pusat yang dapat mengubah status keaktifan cabang\.',
  'K-11: Admin cabang dilarang mengubah status keaktifan cabang'
);

-- ----------------------------------------------------------------------------
-- KASUS 12 & 13: Multi-penugasan staf cabang (set_akses_cabang ART-12)
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner

-- Tugaskan Kasir Rina ke Cabang Kedua
select uji.harap(
  (public.set_akses_cabang(
    '90000000-0000-0000-0000-000000000004',
    'a1a1a1a1-0000-0000-0000-000000000002',
    true
  )->>'berhasil')::boolean = true,
  'K-12a: Owner berhasil menugaskan kasir Rina merangkap di cabang kedua'
);

select uji.harap(
  exists (
    select 1 from public.pengguna_cabang
     where pengguna_id = '90000000-0000-0000-0000-000000000004'
       and cabang_id = 'a1a1a1a1-0000-0000-0000-000000000002'
       and aktif = true
  ),
  'K-12b: Rina terdaftar aktif di pengguna_cabang cabang kedua'
);

-- Cabut tugas Rina dari cabang kedua
select uji.harap(
  (public.set_akses_cabang(
    '90000000-0000-0000-0000-000000000004',
    'a1a1a1a1-0000-0000-0000-000000000002',
    false
  )->>'berhasil')::boolean = true,
  'K-13: Akses cabang kedua kasir Rina berhasil dicabut'
);

-- ----------------------------------------------------------------------------
-- KASUS 14: Tolak penugasan cabang silang resto (penyewa 1111 ke cabang 2222)
-- ----------------------------------------------------------------------------
select uji.harap_gagal_sebab(
  'select public.set_akses_cabang(''90000000-0000-0000-0000-000000000004'', ''b1b1b1b1-0000-0000-0000-000000000001'', true);',
  'Cabang tidak ditemukan atau bukan milik resto Anda\.',
  'K-14: Penugasan pegawai ke cabang milik penyewa lain ditolak fail-closed'
);

-- ----------------------------------------------------------------------------
-- KASUS 15: Kasir biasa dilarang mengatur akses cabang
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Kasir Rina

select uji.harap_gagal_sebab(
  'select public.set_akses_cabang(''90000000-0000-0000-0000-000000000005'', ''a1a1a1a1-0000-0000-0000-000000000001'', true);',
  'Hanya owner pusat atau admin cabang berwenang yang dapat mengatur penugasan cabang\.',
  'K-15: Kasir biasa ditolak mengatur penugasan cabang'
);

-- ----------------------------------------------------------------------------
-- KASUS 16 & 17: Ambil daftar cabang & isolasi penyewa (ART-1)
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner resto 1111

select uji.harap(
  jsonb_array_length(public.ambil_daftar_cabang()) >= 2,
  'K-16a: Owner dapat membaca daftar seluruh cabang restorannya'
);

-- Buktikan cabang resto 2222 (Warung Bandung / Cabang Tunggal) TIDAK bocor ke resto 1111
select uji.harap(
  not exists (
    select 1
      from jsonb_array_elements(public.ambil_daftar_cabang()) c
     where (c->>'id')::uuid = 'b1b1b1b1-0000-0000-0000-000000000001'
  ),
  'K-17: Cabang milik penyewa lain terisolasi sempurna (ART-1)'
);

-- ----------------------------------------------------------------------------
-- KASUS 18: Ambil akses cabang pegawai
-- ----------------------------------------------------------------------------
select uji.harap(
  jsonb_array_length(public.ambil_akses_cabang_pegawai('90000000-0000-0000-0000-000000000004')) >= 2,
  'K-18: Mengambil status penugasan seluruh cabang untuk kasir Rina'
);

-- ----------------------------------------------------------------------------
-- KASUS 19: Fail-closed: Cabang ber-riwayat dilarang di-DELETE langsung
-- ----------------------------------------------------------------------------
-- Cabang Pusat memiliki data meja di data-uji
select uji.harap_gagal_sebab(
  'delete from public.cabang where id = ''a1a1a1a1-0000-0000-0000-000000000001'';',
  'tidak dapat dihapus karena memiliki riwayat transaksi pesanan',
  'K-19: Cabang ber-riwayat operasional dilarang di-hard delete (ART-1)'
);

-- ----------------------------------------------------------------------------
-- KASUS 20: Cabang baru kosong tanpa transaksi boleh dihapus bersih
-- ----------------------------------------------------------------------------
do $$
declare
  v_dago_id uuid;
begin
  select id into v_dago_id from public.cabang where nama = 'Cabang Dago Bawah';
  delete from public.cabang where id = v_dago_id;
end $$;

select uji.harap(
  not exists (select 1 from public.cabang where nama = 'Cabang Dago Bawah'),
  'K-20: Cabang baru tanpa transaksi bersih dihapus'
);

rollback;
