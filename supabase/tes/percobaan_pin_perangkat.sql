-- ============================================================================
-- UJI: batas percobaan PIN dua lapis saat nama perangkat dipalsukan (B F-11)
--
-- Temuan audit AUD-3 (laporan B, F-11, tingkat K-3):
--   Lapis pertama (5 kali salah / akun / 15 menit) TERBUKTI bekerja.
--   Lapis kedua (12 kali salah / perangkat / 15 menit) memakai `p_perangkat`
--   yang datang dari klien, jadi penyerang yang memutar nama perangkat tidak
--   pernah terkumpul 12 kali → lapis kedua tidak berarti baginya.
--
-- Perbaikan yang benar = identitas perangkat dari `perangkat_id` yang
-- TERVERIFIKASI (migrasi 0012, T1-24, Fase 1B). Selama belum ada, uji ini
-- mengunci yang MEMANG benar hari ini supaya tidak diam-diam memburuk:
--   1. memutar nama perangkat TIDAK menambah jatah (batas akun tetap 5),
--   2. dengan nama perangkat jujur hasilnya sama (jadi perbandingannya adil),
--   3. lapis perangkat MASIH HIDUP saat namanya jujur (percobaan ke-13 dari HP
--      yang sama ditolak) — supaya "memperbaiki" F-11 dengan MENGHAPUS lapis
--      kedua tidak lolos uji ini.
--
-- ⚠️ Setelah Fase 1B mendarat (perangkat terdaftar), uji ini WAJIB diperketat:
--    perangkat tak dikenal harus DITOLAK, sehingga bagian 1 tidak lagi melayani
--    5 percobaan melainkan 0. Butir pagar: docs/TERTANGGUH.md T-017 — jangan
--    melonggarkan uji ini tanpa menutup T-017.
--
-- Catatan teknis (jebakan yang sudah kena): panggilan fungsi di dalam LATERAL
-- yang argumennya TIDAK bergantung pada baris kiri hanya dijalankan SEKALI oleh
-- PostgreSQL (hasilnya disebar ke semua baris). Karena itu uji ini memakai blok
-- `do` dengan perulangan eksplisit, supaya jumlah panggilan nyata pasti 8/13.
-- ============================================================================

-- 0. Persiapan: PIN dua calon korban dipasang owner; penghitung percobaan
--    dikosongkan supaya berkas ini tidak bergantung urutan berkas uji lain
--    (hanya bisa dari peran pemilik tabel — klien tidak bisa).
delete from public.percobaan_pin;
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(public.simpan_pin('274918', null, '90000000-0000-0000-0000-000000000003'), 'PIN tersimpan.', 'PIN admin disiapkan sebagai korban uji');
select uji.sama(public.simpan_pin('692735', null, '90000000-0000-0000-0000-000000000006'), 'PIN tersimpan.', 'PIN dapur disiapkan sebagai korban uji');
reset role;
select uji.klaim(null);

-- 1 & 2. Penyerang = kasir (Rina). Dua kali delapan percobaan PIN salah ke satu
--        akun: (1) nama perangkat DIGANTI tiap percobaan — persis serangan S-14b
--        pada audit — lalu (2) nama perangkat TETAP sebagai pembanding.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

do $$
declare
  v_pesan    text;
  v_dilayani integer;
  v_terkunci integer;
begin
  -- 1. Nama perangkat berputar (korban: dapur, Sari)
  v_dilayani := 0; v_terkunci := 0;
  for i in 1..8 loop
    select r.pesan into v_pesan
      from public.verifikasi_pin('90000000-0000-0000-0000-000000000006', '135791', null, 'hp-palsu-' || i) r;
    if v_pesan = 'PIN salah.' then
      v_dilayani := v_dilayani + 1;
    elsif v_pesan like 'PIN terkunci%' then
      v_terkunci := v_terkunci + 1;
    end if;
  end loop;
  perform uji.harap(
    v_dilayani = 5 and v_terkunci = 3,
    'B F-11: memutar nama perangkat tidak menambah jatah (5 dilayani · 3 terkunci) — dapat '
      || v_dilayani || ' · ' || v_terkunci);

  -- 2. Nama perangkat tetap (korban: admin, Pak Andi) — angka harus sama
  v_dilayani := 0; v_terkunci := 0;
  for i in 1..8 loop
    select r.pesan into v_pesan
      from public.verifikasi_pin('90000000-0000-0000-0000-000000000003', '135791', null, 'hp-tetap-uji') r;
    if v_pesan = 'PIN salah.' then
      v_dilayani := v_dilayani + 1;
    elsif v_pesan like 'PIN terkunci%' then
      v_terkunci := v_terkunci + 1;
    end if;
  end loop;
  perform uji.harap(
    v_dilayani = 5 and v_terkunci = 3,
    'B F-11: dengan nama perangkat tetap hasilnya sama (5 dilayani · 3 terkunci) — dapat '
      || v_dilayani || ' · ' || v_terkunci);
end $$;

-- 3. Lapis perangkat masih hidup saat namanya jujur: 13 percobaan dari SATU nama
--    perangkat, disebar ke empat akun supaya batas per akun tidak ikut kena
--    (3–4 percobaan per akun; akun ke-3 & ke-4 beda resto → "PIN tidak dikenali").
reset role;
select uji.klaim(null);
delete from public.percobaan_pin;
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

do $$
declare
  v_target text[] := array['90000000-0000-0000-0000-000000000002',
                            '90000000-0000-0000-0000-000000000005',
                            '90000000-0000-0000-0000-000000000001',
                            '90000000-0000-0000-0000-000000000007'];
  v_pesan    text;
  v_panggil  integer := 0;
  v_terkunci integer := 0;
begin
  for i in 1..13 loop
    select r.pesan into v_pesan
      from public.verifikasi_pin(v_target[1 + ((i - 1) % 4)]::uuid, '135791', null, 'hp-stabil-uji') r;
    v_panggil := v_panggil + 1;
    if v_pesan like 'PIN terkunci%' then
      v_terkunci := v_terkunci + 1;
    end if;
  end loop;
  perform uji.harap(
    v_panggil = 13 and v_terkunci = 1,
    'B F-11: lapis perangkat (12 per HP) masih hidup saat namanya jujur — 13 panggilan, '
      || v_terkunci || ' terkunci');
end $$;

reset role;
select uji.klaim(null);
