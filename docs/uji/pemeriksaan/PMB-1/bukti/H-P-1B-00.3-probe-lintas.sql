-- ============================================================================
-- PROBE HAKIM H-P-1B-00.3 — regresi lintas-pegawai pada persetujuan otomatis
-- kode resmi (migrasi 0107, langkah 7a, commit dc875ae).
--
-- Pertanyaan: apakah pegawai yang TIDAK pernah disetujui owner untuk pasangan
-- (pegawai x perangkat) ikut lolos login dari perangkat hasil kode resmi?
-- Dasar: docs/KEAMANAN.md:58 — "pegawai pertama yang memakai perangkat terdaftar
-- harus disetujui owner/admin berizin".
--
-- Cara jalan:  node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-P-1B-00.3-probe-lintas.sql
-- Harapan:
--   * KONTROL (Rina, penerima kode yang dimaksud)  → LULUS (LOGIN_SUKSES)
--   * CACAT NYATA (Dedi, pelayan, tak pernah disetujui) → GAGAL = cacat HIDUP
--     (dapat LOGIN_SUKSES, harap PERANGKAT_BELUM_DISETUJUI). Bila kelak LULUS,
--     cacat sudah tertutup.
-- Berkas ini memanggil artefak yang diuji (RPC verifikasi_pin_perangkat) dari
-- kursi anon, dan kode resmi dibuat sebagai pemilik (owner) lewat tabel.
-- ============================================================================

delete from public.percobaan_pin;
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000004', crypt('739205', gen_salt('bf')))
on conflict (pengguna_id) do update set pin_hash = excluded.pin_hash;
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000005', crypt('246810', gen_salt('bf')))
on conflict (pengguna_id) do update set pin_hash = excluded.pin_hash;

-- Owner menerbitkan kode resmi dengan peran_diizinkan BAWAAN (kasir, pelayan, dapur).
insert into public.kode_pendaftaran_perangkat (penyewa_id, cabang_id, kode, nama_perangkat, jenis, dibuat_oleh)
values ('11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001',
        'LINTASHAKIM', 'Tablet Lintas Hakim', 'pos', '90000000-0000-0000-0000-000000000002');

select uji.klaim(null);
set local role anon;
select uji.harap(
  (public.daftarkan_perangkat_dengan_kode('LINTASHAKIM', 'kunci-lintas-hakim-0123456789')->>'berhasil')::boolean,
  'H-P-1B-00.3: pendaftaran perangkat lewat kode resmi berhasil (jalur sah T1-24)'
);
reset role;
create temp table probe_lintas_dev as
  select id from public.perangkat where nama = 'Tablet Lintas Hakim' limit 1;
grant select on probe_lintas_dev to anon;

-- --- KONTROL: Rina (kasir, penerima kode) — harus LULUS -----------------------
select uji.klaim(null);
set local role anon;
select uji.sama(
  (public.verifikasi_pin_perangkat('kasir.a1@contoh.test', '739205',
     (select id from probe_lintas_dev), 'Tablet Lintas Hakim', null))->>'kode',
  'LOGIN_SUKSES',
  'KONTROL H-P-1B-00.3: Rina (kasir) dari perangkat kode resmi → LOGIN_SUKSES'
);
reset role;

-- --- CACAT NYATA: Dedi (pelayan) — tak pernah disetujui owner untuk pasangan ini
-- Harapan desain KEAMANAN:58 = PERANGKAT_BELUM_DISETUJUI. GAGAL di sini = cacat hidup.
select uji.klaim(null);
set local role anon;
select uji.sama(
  (public.verifikasi_pin_perangkat('pelayan.a@contoh.test', '246810',
     (select id from probe_lintas_dev), 'Tablet Lintas Hakim', null))->>'kode',
  'PERANGKAT_BELUM_DISETUJUI',
  'CACAT NYATA H-P-1B-00.3: Dedi (pelayan) tak pernah disetujui owner, namun lolos dari perangkat kode resmi'
);
reset role;
