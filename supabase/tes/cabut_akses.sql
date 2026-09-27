-- ============================================================================
-- PENGUJIAN: Pegawai Berhenti: Cabut Akses Cepat & Serah Terima (T10-12 / ART-2)
--
-- Referensi:
--   - PRD M3 & M12: Kasus pegawai keluar / berhenti -> owner/admin menekan satu
--     tombol "Pegawai Berhenti" untuk mencabut akses seketika secara atomik, tanpa
--     merusak atau menghapus riwayat transaksi masa lalu (pesanan, kasir, laporan).
--   - TECH_SPEC §9 ART-2 (Role & Permission) & Aturan Bisnis 11:
--     "Menonaktifkan, bukan menghapus — data finansial dan jejak audit kekal."
--   - Catatan ROADMAP T10-12 (T-013):
--     Penutup shift = Admin Cabang; bila yang berhenti Admin Cabang = Owner Pusat.
--   - Verifikasi DoD:
--     Uji SQL: akun nonaktif ditolak masuk, tetapi laporan masa lalu tetap menampilkan namanya.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- Penyiapan Lingkungan & Entitas Uji
-- ----------------------------------------------------------------------------
-- Tenant A:
-- Owner Pusat  : 90000000-0000-0000-0000-000000000002 (Bu Oasis)
-- Admin Cabang : 90000000-0000-0000-0000-000000000003 (Pak Andi)
-- Pelayan Biasa: 90000000-0000-0000-0000-000000000005 (Dedi)
-- Cabang Pusat : a1a1a1a1-0000-0000-0000-000000000001
-- Perangkat Kasir : de000000-0000-0000-0000-000000000003

-- Buat auth user dan pegawai uji baru khusus skenario T10-12: Kasir "Doni Resign"
insert into auth.users (id, email) values
  ('90000000-0000-0000-0000-000000000099', 'doni.kasir@barokah.test')
on conflict (id) do nothing;

insert into public.pengguna (
  id, penyewa_id, nama, email, peran, aktif
) values (
  '90000000-0000-0000-0000-000000000099',
  '11111111-1111-1111-1111-111111111111',
  'Doni Kasir Resign',
  'doni.kasir@barokah.test',
  'kasir',
  true
) on conflict (id) do update set aktif = true;

insert into public.pengguna_cabang (
  pengguna_id, cabang_id, aktif
) values (
  '90000000-0000-0000-0000-000000000099',
  'a1a1a1a1-0000-0000-0000-000000000001',
  true
) on conflict (pengguna_id, cabang_id) do update set aktif = true;

-- Berikan izin buka/tutup kas untuk Doni
insert into public.izin (
  pengguna_id, kode_izin, boleh
) values
  ('90000000-0000-0000-0000-000000000099', 'tutup_kas', true)
on conflict (pengguna_id, kode_izin) do update set boleh = true;

-- Pasang PIN resmi untuk Doni ('258369')
delete from public.kredensial_pin where pengguna_id = '90000000-0000-0000-0000-000000000099';
insert into public.kredensial_pin (
  pengguna_id, pin_hash, diubah_pada
) values (
  '90000000-0000-0000-0000-000000000099',
  crypt('258369', gen_salt('bf', 4)),
  now()
);

-- Ikatkan sesi aktif perangkat untuk Doni
insert into public.sesi_perangkat (
  session_id, perangkat_id, penyewa_id, cabang_id, pengguna_id, mulai, berakhir_pada, status
) values (
  'sess_doni_resign_aktif',
  'de000000-0000-0000-0000-000000000003',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  '90000000-0000-0000-0000-000000000099',
  now(),
  now() + interval '8 hours',
  'aktif'
) on conflict (session_id) do update set status = 'aktif';

insert into public.sesi_cabang (
  pengguna_id, cabang_id
) values (
  '90000000-0000-0000-0000-000000000099',
  'a1a1a1a1-0000-0000-0000-000000000001'
) on conflict (pengguna_id) do update set cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001';

-- ----------------------------------------------------------------------------
-- KASUS 1: Doni Buka Shift Kasir & Melakukan Transaksi Penjualan Riil
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000099');

-- Buka shift kasir dengan modal awal Rp 100.000
select uji.harap(
  (public.buka_shift(100000, 'a1a1a1a1-0000-0000-0000-000000000001')->>'berhasil')::boolean,
  'K-01a: Doni berhasil membuka shift kasir dengan modal awal'
);

-- Buat satu pesanan dan terima pembayaran tunai Rp 45.000
do $$
declare
  v_shift_id   uuid;
  v_pesanan_id uuid;
begin
  select id into v_shift_id
    from public.shift_kas
   where dibuka_oleh = '90000000-0000-0000-0000-000000000099'
     and status = 'terbuka'
   limit 1;

  insert into public.pesanan (
    penyewa_id, cabang_id, shift_id, kasir_id, nomor, tipe, status, subtotal, total, tanggal, kunci_idempoten
  ) values (
    '11111111-1111-1111-1111-111111111111',
    'a1a1a1a1-0000-0000-0000-000000000001',
    v_shift_id,
    '90000000-0000-0000-0000-000000000099',
    199,
    'dinein',
    'lunas',
    45000,
    45000,
    current_date,
    'idemp-doni-pesanan-001'
  ) returning id into v_pesanan_id;

  insert into public.pembayaran (
    pesanan_id, shift_id, kasir_id, metode_id, metode_nama_saat_itu, jenis_saat_itu, jumlah, diterima, kembalian, kunci_idempoten
  ) values (
    v_pesanan_id,
    v_shift_id,
    '90000000-0000-0000-0000-000000000099',
    (select id from public.metode_bayar where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai' limit 1),
    'Tunai',
    'tunai',
    45000,
    50000,
    5000,
    'idemp-doni-bayar-001'
  );
end;
$$;

-- Verifikasi laporan kas shift menampilkan nama kasir "Doni Kasir Resign"
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner Pusat
select uji.harap(
  exists (
    select 1
      from public.laporan_kas_shift lks
     where lks.dibuka_oleh = '90000000-0000-0000-0000-000000000099'
       and lks.kasir_buka_nama = 'Doni Kasir Resign'
       and lks.penjualan_tunai = 45000
  ),
  'K-01b: Laporan kas shift awal mencatat Doni Kasir Resign dengan omzet tunai Rp 45.000'
);

-- ----------------------------------------------------------------------------
-- KASUS 2: Otorisasi & Pagar Hierarki pada public.pegawai_berhenti
-- ----------------------------------------------------------------------------
-- Staf biasa (Dedi - pelayan) dilarang mencabut akses siapa pun
select uji.klaim('90000000-0000-0000-0000-000000000005');
select uji.harap_gagal_sebab(
  'select public.pegawai_berhenti(''90000000-0000-0000-0000-000000000099'');',
  'Hanya owner pusat atau pemegang izin kelola_pegawai yang dapat mencabut akses pegawai\.',
  'K-02a: Pelayan dilarang memanggil pegawai_berhenti'
);

-- Dilarang mencabut akses akun sendiri lewat alur ini
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Bu Oasis (Owner)
select uji.harap_gagal_sebab(
  'select public.pegawai_berhenti(''90000000-0000-0000-0000-000000000002'');',
  'Anda tidak dapat mencabut akses akun Anda sendiri melalui alur pegawai berhenti\.',
  'K-02b: Cegah cabut akses diri sendiri via alur pegawai berhenti'
);

-- Admin cabang dilarang memberhentikan Owner Pusat
select uji.klaim('90000000-0000-0000-0000-000000000003'); -- Pak Andi (Admin)
select uji.harap_gagal_sebab(
  'select public.pegawai_berhenti(''90000000-0000-0000-0000-000000000002'');',
  'Hanya sesama owner pusat yang dapat memberhentikan owner pusat\.',
  'K-02c: Admin cabang dilarang memberhentikan owner pusat'
);

-- ----------------------------------------------------------------------------
-- KASUS 3: Eksekusi Pegawai Berhenti oleh Atasan Berwenang (Admin Cabang / Owner)
-- ----------------------------------------------------------------------------
-- Pak Andi (Admin Cabang berizin kelola_pegawai) mencabut akses Doni Kasir yang berhenti
select uji.klaim('90000000-0000-0000-0000-000000000003');

select uji.harap(
  (
    select (public.pegawai_berhenti(
      '90000000-0000-0000-0000-000000000099',
      'Karyawan mengundurkan diri (resign) per 27 September 2026',
      'Kunci laci kas fisik diserahkan ke Admin Pak Andi. Kasir meninggalkan shift terbuka.'
    )->>'berhasil')::boolean
  ),
  'K-03a: Admin cabang sukses mengeksekusi pegawai_berhenti untuk Doni Kasir'
);

-- ----------------------------------------------------------------------------
-- KASUS 4: Verifikasi Dampak Atomik Pencabutan Akses
-- ----------------------------------------------------------------------------
-- 1. Status Akun Nonaktif (Soft-Disable)
select uji.harap(
  (select aktif = false from public.pengguna where id = '90000000-0000-0000-0000-000000000099'),
  'K-04a: Akun pengguna Doni berubah menjadi aktif = false'
);
select uji.harap(
  (select aktif = false from public.pengguna_cabang where pengguna_id = '90000000-0000-0000-0000-000000000099'),
  'K-04b: Penugasan cabang Doni dinonaktifkan (aktif = false)'
);

-- 2. Seluruh Sesi Perangkat & Cabang Diakhiri Seketika (Status = 'dicabut')
select uji.harap(
  (select status = 'dicabut' from public.sesi_perangkat where session_id = 'sess_doni_resign_aktif'),
  'K-04c: Sesi perangkat Doni seketika berstatus dicabut'
);
select uji.harap(
  not exists (
    select 1
      from public.sesi_cabang
     where pengguna_id = '90000000-0000-0000-0000-000000000099'
  ),
  'K-04d: Sesi cabang aktif Doni dihapus bersih sehingga cabang_saya() gugur'
);

-- 3. Kredensial PIN Dimatikan (Dihapus dari basis data)
select uji.harap(
  not exists (select 1 from public.kredensial_pin where pengguna_id = '90000000-0000-0000-0000-000000000099'),
  'K-04e: PIN Doni terhapus bersih dari kredensial_pin'
);

-- 4. Shift Kasir Terbuka Ditandai "Perlu Tutup Atasan"
select uji.harap(
  exists (
    select 1
      from public.shift_kas
     where dibuka_oleh = '90000000-0000-0000-0000-000000000099'
       and status = 'terbuka'
       and perlu_tutup_atasan = true
       and catatan_serah_terima ilike '%Kunci laci kas fisik diserahkan ke Admin Pak Andi%'
  ),
  'K-04f: Shift kasir terbuka milik Doni ditandai perlu_tutup_atasan = true dengan catatan serah terima'
);

-- 5. Jejak Audit Kriptografis Tercatat di catatan_audit
select uji.harap(
  exists (
    select 1
      from public.catatan_audit
     where aksi = 'pegawai_berhenti'
       and entitas = 'pengguna'
       and entitas_id = '90000000-0000-0000-0000-000000000099'
       and pelaku_id = '90000000-0000-0000-0000-000000000003'
       and nilai_baru->>'ada_shift_terbuka' = 'true'
  ),
  'K-04g: Jejak audit kekal pegawai_berhenti tercatat lengkap dengan identitas pelaku & target'
);

-- ----------------------------------------------------------------------------
-- KASUS 5: Upaya Masuk / Login Doni Ditolak Seketika (Fail-Closed)
-- ----------------------------------------------------------------------------
-- Upaya verifikasi PIN perangkat oleh Doni ditolak fail-closed
select uji.harap(
  (
    select (public.verifikasi_pin_perangkat(
      'doni.kasir@barokah.test',
      '258369',
      'de000000-0000-0000-0000-000000000003',
      'kunci-uji-hp-kasir-0123456789'
    )->>'berhasil')::boolean = false
  ),
  'K-05a: Upaya login PIN Doni ditolak (berhasil = false)'
);

-- Upaya panggilan sesi_masih_aktif dengan sesi Doni yang dicabut mengembalikan false
select uji.harap(
  (
    select status <> 'aktif'
      from public.sesi_perangkat
     where session_id = 'sess_doni_resign_aktif'
  ),
  'K-05b: Status sesi Doni bukan aktif sehingga sesi_masih_aktif menolak akses'
);

-- ----------------------------------------------------------------------------
-- KASUS 6: Atasan Membaca Shift Menggantung & Menutup Shift Kasir (Serah Terima)
-- ----------------------------------------------------------------------------
-- Pak Andi (Admin Cabang) memeriksa shift terbuka yang perlu ditutup
select uji.klaim('90000000-0000-0000-0000-000000000003');

select uji.harap(
  exists (
    select 1
      from public.ambil_shift_perlu_tutup('a1a1a1a1-0000-0000-0000-000000000001') s
     where s.dibuka_oleh = '90000000-0000-0000-0000-000000000099'
       and s.nama_kasir = 'Doni Kasir Resign'
       and s.perlu_tutup_atasan = true
  ),
  'K-06a: Admin cabang mendeteksi shift kasir Doni di ambil_shift_perlu_tutup'
);

-- Pak Andi menghitung uang fisik di laci kas:
-- Modal awal Rp 100.000 + Penjualan tunai Rp 45.000 = Rp 145.000 (cocok tanpa selisih)
do $$
declare
  v_shift_id uuid;
  v_tutup    jsonb;
begin
  select id into v_shift_id
    from public.shift_kas
   where dibuka_oleh = '90000000-0000-0000-0000-000000000099'
     and status = 'terbuka';

  v_tutup := public.tutup_shift(
    145000,
    null,
    v_shift_id,
    'Shift ditutup Admin Cabang Pak Andi pasca serah terima kas kasir berhenti.'
  );

  if not (v_tutup->>'berhasil')::boolean then
    raise exception 'Gagal menutup shift: %', v_tutup->>'pesan';
  end if;
end;
$$;

-- Verifikasi shift telah ditutup dengan benar
select uji.harap(
  exists (
    select 1
      from public.shift_kas
     where dibuka_oleh = '90000000-0000-0000-0000-000000000099'
       and status = 'ditutup'
       and ditutup_oleh = '90000000-0000-0000-0000-000000000003'
       and ditutup_oleh_atasan = true
       and perlu_tutup_atasan = false
       and selisih = 0
  ),
  'K-06b: Shift kasir Doni berhasil ditutup oleh atasan dengan ditutup_oleh_atasan = true'
);

-- ----------------------------------------------------------------------------
-- KASUS 7: Laporan Masa Lalu TETAP Memuat Nama Kasir Doni (Data Tidak Rusak)
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner Pusat

-- Laporan kas per shift tetap menampilkan kasir_buka_nama = 'Doni Kasir Resign'
select uji.harap(
  exists (
    select 1
      from public.laporan_kas_shift
     where dibuka_oleh = '90000000-0000-0000-0000-000000000099'
       and kasir_buka_nama = 'Doni Kasir Resign'
       and kasir_tutup_nama = 'Pak Andi'
       and total_penjualan = 45000
       and status = 'ditutup'
  ),
  'K-07a: Laporan kas shift masa lalu tetap menampilkan nama Doni Kasir Resign dan Pak Andi'
);

-- Data transaksi penjualan tetap mencatat kasir_id Doni
select uji.harap(
  exists (
    select 1
      from public.pesanan p
      join public.pengguna u on u.id = p.kasir_id
     where p.kasir_id = '90000000-0000-0000-0000-000000000099'
       and u.nama = 'Doni Kasir Resign'
       and p.nomor = 199
  ),
  'K-07b: Pesanan 199 tetap terhubung ke akun Doni Kasir Resign'
);

-- ----------------------------------------------------------------------------
-- KASUS 8: Integritas Fail-Closed: DILARANG Hard-Delete Pegawai Ber-riwayat
-- ----------------------------------------------------------------------------
-- Pemicu picu_pengguna_cegah_hapus wajib memblokir upaya penghapusan fisik baris Doni
select uji.harap_gagal_sebab(
  'delete from public.pengguna where id = ''90000000-0000-0000-0000-000000000099'';',
  'tidak dapat dihapus karena memiliki riwayat transaksi',
  'K-08: Hard-delete akun pegawai ber-riwayat dicegah fail-closed oleh picu_pengguna_cegah_hapus'
);

rollback;
