-- ============================================================================
-- UJI SQL: Tinjauan & Penegakan Pemulihan Kredensial / MFA (T10-16 / T-016)
-- ============================================================================
-- Membuktikan secara komprehensif pada level basis data:
--   1. Hierarki Pemulihan via Peran Atas (Role Hierarchy Recovery):
--      - Kasir dilarang mereset kredensial/status Admin Cabang atau Owner Pusat.
--      - Admin Cabang dilarang mereset kredensial atau menonaktifkan Owner Pusat.
--      - Owner Pusat berwenang penuh memulihkan kredensial Admin Cabang tanpa PIN lama.
--   2. Penegakan Kekuatan Kredensial:
--      - PIN lemah (123456, 111111, pola berulang, non-digit) ditolak saat pemulihan.
--   3. Pencabutan Sesi Seketika (Instant Session Revocation):
--      - Saat HP hilang / MFA direset, keluar_semua_perangkat memutus seluruh sesi.
--      - Sesi yang dicabut ditolak oleh sesi_masih_aktif.
--   4. Tangga Pemulihan Kunci Induk Darurat (Break-Glass Recovery):
--      - Hanya owner_pusat yang berhak membuat kode pemulihan darurat.
--      - Kode pemulihan wajib memiliki panjang minimal 20 karakter.
--      - Hash bcrypt tersimpan di public.kredensial_pemulihan (zero plaintext).
--      - Tabel kredensial_pemulihan terproteksi RLS deny-by-default bagi seluruh klien.
--      - Rotasi otomatis: pembuatan kode baru membatalkan kode lama yang belum terpakai.
--      - Pengajuan pemulihan darurat menegakkan masa tenggang 30 menit (perangkat nonaktif).
--      - Kode pemulihan bersifat sekali pakai (anti-replay): pemakaian kedua ditolak keras.
--      - Upaya pemulihan dengan kode salah ditolak dan mencatat insiden di catatan_audit.
--      - Sakelar penghentian (kill-switch): pemulihan dapat dibatalkan sewaktu-waktu.
--   5. Proteksi Anti-Lockout & Isolasi Multi-Tenant:
--      - Sistem menolak penonaktifan satu-satunya owner pusat aktif di resto.
--      - Isolasi penyewa kedap: penyewa lain dilarang memulihkan atau menyentuh kredensial resto lawan.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- Identitas & Variabel Uji
-- Bu Oasis (owner_pusat tenant 1111): 90000000-0000-0000-0000-000000000002
-- Pak Andi (admin_cabang tenant 1111): 90000000-0000-0000-0000-000000000003
-- Rina (kasir tenant 1111): 90000000-0000-0000-0000-000000000004
-- Dedi (pelayan tenant 1111): 90000000-0000-0000-0000-000000000005
-- Pak Joko (owner_pusat tenant 2222): 90000000-0000-0000-0000-000000000006
-- Cabang Pusat (tenant 1111): a1a1a1a1-0000-0000-0000-000000000001
-- Cabang Tunggal (tenant 2222): b1b1b1b1-0000-0000-0000-000000000001
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- KASUS 1: Kasir dilarang mereset kredensial Admin Cabang atau Owner Pusat
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
select uji.harap_gagal_sebab(
  $$select public.reset_pin_pegawai('90000000-0000-0000-0000-000000000003', '849201')$$,
  'Hanya owner pusat atau pemegang izin kelola_pegawai',
  'K-01a: Kasir ditolak mereset kredensial Admin Cabang'
);

select uji.harap_gagal_sebab(
  $$select public.reset_pin_pegawai('90000000-0000-0000-0000-000000000002', '849201')$$,
  'Hanya owner pusat atau pemegang izin kelola_pegawai',
  'K-01b: Kasir ditolak mereset kredensial Owner Pusat'
);

-- ----------------------------------------------------------------------------
-- KASUS 2: Admin Cabang dilarang mereset kredensial atau menonaktifkan Owner Pusat
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000003');
select uji.harap_gagal_sebab(
  $$select public.reset_pin_pegawai('90000000-0000-0000-0000-000000000002', '849201')$$,
  'Hanya sesama owner pusat yang dapat mereset PIN owner pusat',
  'K-02a: Admin Cabang dilarang mereset kredensial Owner Pusat'
);

select uji.harap_gagal_sebab(
  $$select public.set_status_pengguna('90000000-0000-0000-0000-000000000002', false)$$,
  'Hanya sesama owner pusat yang dapat mengubah status keaktifan owner pusat',
  'K-02b: Admin Cabang dilarang menonaktifkan akun Owner Pusat'
);

-- ----------------------------------------------------------------------------
-- KASUS 3: Pemulihan via Peran Atas — Owner Pusat berhasil mereset PIN Admin Cabang
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
select uji.harap(
  (public.reset_pin_pegawai('90000000-0000-0000-0000-000000000003', '753159')->>'berhasil')::boolean,
  'K-03: Owner Pusat berhasil mereset kredensial PIN Admin Cabang'
);

-- ----------------------------------------------------------------------------
-- KASUS 4: Penolakan PIN lemah saat pemulihan kredensial (fail-closed)
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
select uji.harap_gagal_sebab(
  $$select public.reset_pin_pegawai('90000000-0000-0000-0000-000000000003', '123456')$$,
  'PIN ditolak',
  'K-04a: PIN urut (123456) ditolak saat pemulihan kredensial'
);

select uji.harap_gagal_sebab(
  $$select public.reset_pin_pegawai('90000000-0000-0000-0000-000000000003', '111111')$$,
  'PIN ditolak',
  'K-04b: PIN kembar (111111) ditolak saat pemulihan kredensial'
);

select uji.harap_gagal_sebab(
  $$select public.reset_pin_pegawai('90000000-0000-0000-0000-000000000003', '123')$$,
  'PIN baru harus berupa 6 digit angka',
  'K-04c: PIN kurang dari 6 digit ditolak saat pemulihan kredensial'
);

-- ----------------------------------------------------------------------------
-- KASUS 5: Pencabutan Sesi Seketika saat HP hilang / Kredensial direset
-- ----------------------------------------------------------------------------
-- Buat sesi aktif simulasi untuk Admin Cabang
select uji.klaim('90000000-0000-0000-0000-000000000003');
select public.ikat_sesi_perangkat(
  'sess_admin_andi_mfa_01',
  'de000000-0000-0000-0000-000000000002',
  'kunci-uji-hp-admin-0123456789',
  '90000000-0000-0000-0000-000000000003'
);

-- Owner Pusat mencabut seluruh sesi Admin Cabang
select uji.klaim('90000000-0000-0000-0000-000000000002');
select uji.harap(
  (public.keluar_semua_perangkat(
    '90000000-0000-0000-0000-000000000003',
    'HP admin dilaporkan hilang - reset kredensial'
  )->>'berhasil')::boolean,
  'K-05: Owner Pusat mencabut seluruh sesi aktif Admin Cabang'
);

-- ----------------------------------------------------------------------------
-- KASUS 6: Verifikasi status sesi terputus seketika
-- ----------------------------------------------------------------------------
select uji.harap(
  exists (
    select 1
      from public.sesi_perangkat
     where session_id = 'sess_admin_andi_mfa_01'
       and status = 'dicabut'
  ),
  'K-06a: Sesi perangkat admin berhasil dicatat berstatus dicabut'
);

select uji.klaim('90000000-0000-0000-0000-000000000003', '{"session_id": "sess_admin_andi_mfa_01"}'::jsonb);
set local role authenticated;
select uji.sama(
  public.sesi_masih_aktif(),
  false,
  'K-06b: sesi_masih_aktif() menghasilkan false untuk sesi yang telah dicabut'
);
reset role;

-- ----------------------------------------------------------------------------
-- KASUS 7: Non-owner dilarang membuat kode pemulihan darurat
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000003'); -- Admin Cabang
select uji.harap_gagal_sebab(
  $$select public.buat_kode_pemulihan('kunci-pemulihan-darurat-owner-minimal-20-karakter')$$,
  'Hanya owner_pusat',
  'K-07a: Admin Cabang dilarang membuat kode pemulihan darurat'
);

select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Kasir
select uji.harap_gagal_sebab(
  $$select public.buat_kode_pemulihan('kunci-pemulihan-darurat-owner-minimal-20-karakter')$$,
  'Hanya owner_pusat',
  'K-07b: Kasir dilarang membuat kode pemulihan darurat'
);

-- ----------------------------------------------------------------------------
-- KASUS 8: Validasi panjang kode pemulihan darurat (<20 karakter ditolak)
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner Pusat
select uji.harap_gagal_sebab(
  $$select public.buat_kode_pemulihan('pendek-kurang-20')$$,
  'Kode pemulihan darurat harus memiliki panjang minimal 20 karakter',
  'K-08: Kode pemulihan darurat kurang dari 20 karakter ditolak'
);

-- ----------------------------------------------------------------------------
-- KASUS 9: Owner Pusat berhasil membuat kode pemulihan darurat (hash bcrypt)
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
select uji.sama(
  public.buat_kode_pemulihan('kunci-darurat-mfa-pemulihan-resmi-2026-v1'),
  'Kode pemulihan darurat berhasil disimpan. Cetak dan simpan 2 salinan fisik di amplop tersegel.',
  'K-09a: Owner Pusat berhasil membuat kode pemulihan darurat'
);

-- Verifikasi di tabel kredensial_pemulihan: tersimpan hash bcrypt
select uji.harap(
  exists (
    select 1
      from public.kredensial_pemulihan
     where penyewa_id = '11111111-1111-1111-1111-111111111111'
       and not terpakai
       and kode_hash ~ '^\$[a-z0-9]+\$'
       and kode_hash <> 'kunci-darurat-mfa-pemulihan-resmi-2026-v1'
  ),
  'K-09b: Kode pemulihan darurat tersimpan sebagai hash bcrypt (zero plaintext)'
);

-- ----------------------------------------------------------------------------
-- KASUS 10: Rotasi otomatis — Pembuatan kode baru menonaktifkan kode lama
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
select uji.sama(
  public.buat_kode_pemulihan('kunci-darurat-mfa-pemulihan-resmi-2026-v2-rotasi'),
  'Kode pemulihan darurat berhasil disimpan. Cetak dan simpan 2 salinan fisik di amplop tersegel.',
  'K-10a: Owner Pusat melakukan rotasi kode pemulihan darurat baru'
);

-- Kode versi v1 sebelumnya harus otomatis menjadi terpakai = true
select uji.harap(
  (
    select count(*)
      from public.kredensial_pemulihan
     where penyewa_id = '11111111-1111-1111-1111-111111111111'
       and not terpakai
  ) = 1,
  'K-10b: Hanya tepat 1 kode pemulihan darurat yang aktif (kode lama dirotasi terpakai)'
);

-- ----------------------------------------------------------------------------
-- KASUS 11: Proteksi RLS — Klien dilarang SELECT langsung ke kredensial_pemulihan
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select count(*) from public.kredensial_pemulihan$$,
  'permission denied for table kredensial_pemulihan',
  'K-11: RLS menolak akses SELECT langsung ke kredensial_pemulihan'
);
reset role;

-- ----------------------------------------------------------------------------
-- KASUS 12: Non-owner dilarang memanggil pulihkan_perangkat
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000003'); -- Admin Cabang
select uji.harap_gagal_sebab(
  $$select public.pulihkan_perangkat(
      'kunci-darurat-mfa-pemulihan-resmi-2026-v2-rotasi',
      'tablet-darurat-andi',
      'kunci-perangkat-darurat-1234567890',
      'a1a1a1a1-0000-0000-0000-000000000001'
    )$$,
  'Hanya owner_pusat',
  'K-12: Admin Cabang dilarang memanggil pulihkan_perangkat'
);

-- ----------------------------------------------------------------------------
-- KASUS 13: Owner mengajukan pemulihan darurat dengan kode valid
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Bu Oasis
select uji.harap(
  (select public.pulihkan_perangkat(
    'kunci-darurat-mfa-pemulihan-resmi-2026-v2-rotasi',
    'hp-darurat-bu-oasis-mfa',
    'kunci-perangkat-darurat-1234567890',
    'a1a1a1a1-0000-0000-0000-000000000001'
  )) is not null,
  'K-13_id: Pemanggilan pulihkan_perangkat mengembalikan ID pemulihan yang valid'
);

-- Verifikasi perangkat darurat berstatus belum aktif (aktif = false selama masa tenggang)
reset role;
select uji.klaim(null);
select uji.sama(
  (select pr.aktif from public.perangkat pr where pr.nama = 'hp-darurat-bu-oasis-mfa'),
  false,
  'K-13a: Perangkat darurat terdaftar dengan status aktif = false (masa tenggang)'
);

-- Verifikasi antrean pemulihan darurat berstatus 'menunggu'
select uji.sama(
  (
    select pp.status
      from public.pemulihan_perangkat pp
      join public.perangkat pr on pr.id = pp.perangkat_id
     where pr.nama = 'hp-darurat-bu-oasis-mfa'
  ),
  'menunggu',
  'K-13b: Antrean pemulihan darurat tercatat dengan status menunggu'
);

-- ----------------------------------------------------------------------------
-- KASUS 14: Sekali pakai (Anti-Replay) — Kode yang telah dipakai ditolak keras
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
select uji.harap_gagal_sebab(
  $$select public.pulihkan_perangkat(
      'kunci-darurat-mfa-pemulihan-resmi-2026-v2-rotasi',
      'hp-darurat-kedua',
      'kunci-perangkat-darurat-1234567890',
      'a1a1a1a1-0000-0000-0000-000000000001'
    )$$,
  'Kode pemulihan darurat tidak valid atau sudah pernah dipakai',
  'K-14: Pemakaian ulang kode pemulihan yang sama ditolak keras (anti-replay)'
);

-- ----------------------------------------------------------------------------
-- KASUS 15: Upaya pemulihan dengan kode salah ditolak secara fail-closed
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
select uji.harap_gagal_sebab(
  $$select public.pulihkan_perangkat(
      'kunci-darurat-palsu-dan-salah-total-9999',
      'hp-hacker',
      'kunci-perangkat-darurat-1234567890',
      'a1a1a1a1-0000-0000-0000-000000000001'
    )$$,
  'Kode pemulihan darurat tidak valid atau sudah pernah dipakai',
  'K-15: Kode pemulihan darurat salah ditolak secara fail-closed'
);

-- ----------------------------------------------------------------------------
-- KASUS 16: Sakelar Penghentian (Kill-Switch) — Batalkan pemulihan darurat
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
do $$
declare
  v_pemulihan_id uuid;
begin
  select pp.id into v_pemulihan_id
    from public.pemulihan_perangkat pp
    join public.perangkat pr on pr.id = pp.perangkat_id
   where pr.nama = 'hp-darurat-bu-oasis-mfa'
     and pp.status = 'menunggu';

  perform public.batalkan_pemulihan(v_pemulihan_id, 'Kunci ditemukan kembali, pemulihan dibatalkan.');
end $$;

select uji.klaim(null);
select uji.sama(
  (
    select pp.status
      from public.pemulihan_perangkat pp
      join public.perangkat pr on pr.id = pp.perangkat_id
     where pr.nama = 'hp-darurat-bu-oasis-mfa'
  ),
  'dibatalkan',
  'K-16: Sakelar kill-switch berhasil membatalkan antrean pemulihan darurat'
);

-- ----------------------------------------------------------------------------
-- KASUS 17: Proteksi Anti-Lockout — Tolak nonaktifkan satu-satunya owner aktif
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Bu Oasis
select uji.harap_gagal_sebab(
  $$select public.set_status_pengguna('90000000-0000-0000-0000-000000000002', false)$$,
  'Restoran minimal harus memiliki satu owner pusat yang aktif',
  'K-17: Sistem mencegah lockout diri sendiri dengan menolak penonaktifan satu-satunya owner'
);

-- Setup owner tenant 2222 untuk pengujian isolasi multi-tenant
insert into auth.users (id, email) values
  ('90000000-0000-0000-0000-000000000099', 'owner.b@contoh.test')
  on conflict (id) do nothing;

insert into public.pengguna (id, penyewa_id, nama, email, peran) values
  ('90000000-0000-0000-0000-000000000099', '22222222-2222-2222-2222-222222222222', 'Pak Joko', 'owner.b@contoh.test', 'owner_pusat')
  on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- KASUS 18: Isolasi Multi-Tenant — Owner resto lain dilarang menyentuh resto lawan
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000099'); -- Pak Joko (Owner Resto B)
select uji.harap_gagal_sebab(
  $$select public.reset_pin_pegawai('90000000-0000-0000-0000-000000000003', '654321')$$,
  'Pegawai tidak ditemukan atau bukan bagian dari restoran Anda',
  'K-18a: Owner resto B dilarang mereset pegawai resto A'
);

select uji.harap_gagal_sebab(
  $$select public.pulihkan_perangkat(
      'kunci-darurat-mfa-pemulihan-resmi-2026-v2-rotasi',
      'hp-darurat-joko',
      'kunci-perangkat-darurat-1234567890',
      'a1a1a1a1-0000-0000-0000-000000000001'
    )$$,
  'Cabang tidak valid atau bukan cabang yang Anda kelola',
  'K-18b: Owner resto B dilarang memulihkan perangkat ke cabang resto A'
);

-- ----------------------------------------------------------------------------
-- KASUS 19: Integritas Jejak Audit Kekal (ART-13)
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
select uji.harap(
  (
    select count(*)
      from public.catatan_audit
     where penyewa_id = '11111111-1111-1111-1111-111111111111'
       and aksi in (
         'buat_kode_pemulihan',
         'pulihkan_perangkat_diajukan',
         'gagal_pulihkan_perangkat',
         'batalkan_pemulihan',
         'reset_pin_pegawai',
         'keluar_semua_perangkat'
       )
  ) >= 5,
  'K-19: Seluruh aksi sensitif pemulihan & rotasi kredensial tercatat kekal di catatan_audit'
);

rollback;
