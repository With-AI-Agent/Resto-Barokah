-- ============================================================================
-- PROBE HAKIM 5 (arena/1e030f6b-resto-barokah, 2026-10-06) — migrasi 0105
-- Objek: PMB1-F-083 (DIPERBAIKI ronde 3) · PMB1-F-234 (BARU) · PMB1-F-238 (BARU)
--
-- Probe ini DITULIS HAKIM sendiri (bukan salinan uji pembangun). Ia memanggil
-- artefak yang sebenarnya dari kursi peran yang sebenarnya (anon = tanpa sesi,
-- authenticated + klaim = ber-sesi) dan memuat kontrol negatif pada setiap
-- jalur. Jalankan:
--   node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-F-06.5-probe-105.sql
-- ============================================================================

-- ---------------------------------------------------------------- penyiapan
-- PIN owner (untuk bukti ujung-ke-ujung langkah A6) dan izin kelola_pegawai
-- (untuk membuktikan jalur lama 0028 tidak rusak, langkah A9b). Keduanya
-- disuntik sebagai pemilik tabel: ini penyiapan data uji, bukan artefak.
delete from public.percobaan_pin;
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000002', crypt('481516', gen_salt('bf')))
on conflict (pengguna_id) do update set pin_hash = excluded.pin_hash;

insert into public.izin (pengguna_id, kode_izin, boleh, batas_nominal, batas_persen)
values ('90000000-0000-0000-0000-000000000002', 'kelola_pegawai', true, null, null)
on conflict (pengguna_id, kode_izin) do update set boleh = excluded.boleh;

-- Kode pemulihan A (owner ber-sesi, jalur sah pembuatan kode).
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Bu Oasis (owner_pusat)
select uji.sama(
  public.buat_kode_pemulihan('kode-probe-hakim5-A-minimal-20-karakter-acak-2026'),
  'Kode pemulihan darurat berhasil disimpan. Cetak dan simpan 2 salinan fisik di amplop tersegel.',
  'A0: owner membuat kode pemulihan darurat'
);
reset role;

-- ------------------------------------------------------------------- A1-A6
-- A1. TANPA SESI (anon): pengajuan perangkat darurat diterima (migrasi 0102).
select uji.klaim(null);
set local role anon;
select uji.harap(
  public.pulihkan_perangkat(
    'kode-probe-hakim5-A-minimal-20-karakter-acak-2026',
    'hp-darurat-A-hakim5',
    'kunci-darurat-A-hakim5-9876543210',
    'a1a1a1a1-0000-0000-0000-000000000001'
  ) is not null,
  'A1: pengajuan darurat tanpa sesi diterima'
);

-- A2. KONTROL NEGATIF: aktivasi SEBELUM masa tenggang lewat -> DITOLAK.
select uji.harap_gagal_sebab(
  $$select public.selesaikan_pemulihan_darurat('kunci-darurat-A-hakim5-9876543210')$$,
  'belum melewati masa tenggang',
  'A2: aktivasi sebelum tenggang ditolak tanpa sesi'
);

-- A3. KONTROL NEGATIF: kunci SALAH sesudah tenggang lewat -> DITOLAK (pesan seragam).
reset role;
update public.pemulihan_perangkat
   set aktif_setelah = now() - interval '1 second'
 where perangkat_id = (select id from public.perangkat where nama = 'hp-darurat-A-hakim5');
set local role anon;
select uji.harap_gagal_sebab(
  $$select public.selesaikan_pemulihan_darurat('kunci-bukan-milik-owner-hakim5-0000')$$,
  'Permohonan pemulihan tidak ditemukan',
  'A3: kunci salah ditolak dengan pesan seragam'
);

-- A4. POSITIF: kunci benar sesudah tenggang -> AKTIF TANPA SESI.
select uji.sama(
  public.selesaikan_pemulihan_darurat('kunci-darurat-A-hakim5-9876543210'),
  true,
  'A4: aktivasi perangkat darurat tanpa sesi berhasil'
);

-- A4b. Keadaan sesudahnya: antrean selesai · perangkat aktif · jejak audit.
reset role;
select uji.harap(
  exists (
    select 1 from public.pemulihan_perangkat q
    join public.perangkat p on p.id = q.perangkat_id
     where p.nama = 'hp-darurat-A-hakim5'
       and q.status = 'selesai'
       and p.aktif = true
  ),
  'A4b: antrean selesai & perangkat darurat aktif'
);
select uji.harap(
  exists (
    select 1 from public.catatan_audit
     where aksi = 'selesaikan_pemulihan_darurat'
       and pelaku_id = '90000000-0000-0000-0000-000000000002'
       and nilai_baru->>'jalur' = 'tanpa_sesi'
  ),
  'A4b: jejak audit tercatat atas nama pemohon (jalur tanpa_sesi)'
);

-- A5. KONTROL NEGATIF: permohonan sudah selesai tidak bisa diaktifkan ulang.
set local role anon;
select uji.harap_gagal_sebab(
  $$select public.selesaikan_pemulihan_darurat('kunci-darurat-A-hakim5-9876543210')$$,
  'Permohonan pemulihan tidak ditemukan',
  'A5: permohonan selesai tidak bisa diaktifkan ulang'
);

-- A6. UJUNG-KE-UJUNG: owner (yang tadinya terkunci PERANGKAT_TIDAK_SAH) kini
--     bisa LOGIN lewat perangkat darurat yang baru diaktifkan.
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.harap(
  (select public.verifikasi_pin_perangkat(
     'owner.a@contoh.test',
     '481516',
     p.id,
     p.nama,
     'kunci-darurat-A-hakim5-9876543210'
   )->>'kode' from public.perangkat p where p.nama = 'hp-darurat-A-hakim5') = 'LOGIN_SUKSES',
  'A6: login owner lewat perangkat darurat = LOGIN_SUKSES (kunci induk §4b tuntas)'
);
reset role;

-- -------------------------------------------------------------- A7 isolasi
-- A7. Kunci perangkat penyewa LAIN (Warung Bandung) tidak mengaktifkan apa pun
--     (tidak ada antrean yang cocok) -> DITOLAK. Menyangkal "aktivasi buta".
select uji.klaim(null);
set local role anon;
select uji.harap_gagal_sebab(
  $$select public.selesaikan_pemulihan_darurat('kunci-uji-hp-b1-0123456789')$$,
  'Permohonan pemulihan tidak ditemukan',
  'A7: kunci perangkat penyewa B tidak mengaktifkan antrean penyewa A'
);

-- -------------------------------------------------- A8 bukti PMB1-F-238
-- A8. batalkan_pemulihan MASIH menuntut sesi: dari kursi anon (korban yang
--     kehilangan seluruh perangkat) permohonan tidak bisa dibatalkan.
--     (Id permohonan diambil lebih dulu sebagai pemilik tabel: peran anon
--     tidak punya hak baca tabel perangkat, jadi sub-bacaan tidak boleh
--     mengaburkan sebab penolakan yang sedang diuji.)
reset role;
create temp table id_a as
  select id from public.pemulihan_perangkat
   where perangkat_id = (select id from public.perangkat where nama = 'hp-darurat-A-hakim5');
grant select on id_a to public;
select uji.klaim(null);
set local role anon;
select uji.harap_gagal_sebab(
  $$select public.batalkan_pemulihan((select id from id_a), 'probe hakim 5')$$,
  'permission denied for function batalkan_pemulihan',
  'A8 (F-238): pembatalan pemulihan mustahil tanpa sesi — anon bahkan tidak diberi execute'
);
-- A8b. Sebagai authenticated TANPA izin kelola_pegawai (kasir Rina) juga ditolak:
--      jadi bukan semata-mata soal sesi, melainkan sesi + izin.
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Rina (kasir)
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.batalkan_pemulihan((select id from id_a), 'probe hakim 5')$$,
  'kelola_pegawai',
  'A8b (F-238): kasir ber-sesi pun tidak bisa membatalkan (izin kelola_pegawai)'
);
reset role;

-- ------------------------------------------- A9 regresi jalur ber-sesi lama
-- A9. selesaikan_pemulihan (0028, jalur lama) TIDAK berubah: tanpa sesi tetap
--     ditolak; dengan sesi + izin kelola_pegawai tetap berhasil.
select uji.klaim(null);
set local role anon;
select uji.harap_gagal_sebab(
  $$select public.selesaikan_pemulihan((select id from id_a))$$,
  'permission denied for function selesaikan_pemulihan',
  'A9: jalur lama 0028 tetap tertutup bagi anon (tidak dilonggarkan 0105)'
);
reset role;

-- Permohonan kedua (kode B) untuk membuktikan jalur lama masih bekerja.
select uji.klaim('90000000-0000-0000-0000-000000000002');
select uji.sama(
  public.buat_kode_pemulihan('kode-probe-hakim5-B-minimal-20-karakter-acak-2026'),
  'Kode pemulihan darurat berhasil disimpan. Cetak dan simpan 2 salinan fisik di amplop tersegel.',
  'A9b: owner membuat kode pemulihan kedua'
);
reset role;
select uji.klaim(null);
set local role anon;
select uji.harap(
  public.pulihkan_perangkat(
    'kode-probe-hakim5-B-minimal-20-karakter-acak-2026',
    'hp-darurat-B-hakim5',
    'kunci-darurat-B-hakim5-9876543210',
    'a1a1a1a1-0000-0000-0000-000000000001'
  ) is not null,
  'A9b: pengajuan kedua diterima'
);
reset role;
update public.pemulihan_perangkat
   set aktif_setelah = now() - interval '1 second'
 where perangkat_id = (select id from public.perangkat where nama = 'hp-darurat-B-hakim5');
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(
  (select public.selesaikan_pemulihan(id) from public.pemulihan_perangkat
    where perangkat_id = (select id from public.perangkat where nama = 'hp-darurat-B-hakim5')),
  true,
  'A9b: jalur ber-sesi lama masih berfungsi (regresi nihil)'
);
reset role;

-- --------------------------------------- A10 uji bantahan: kunci kembar
-- A10. Dua permohonan MENUNGGU dengan KUNCI yang SAMA (pemilik memilih kunci
--      yang sama untuk dua perangkat darurat). 0105 tidak menerima penanda
--      permohonan: ia mencari baris 'menunggu' yang kuncinya cocok lalu
--      mengambil yang PALING BARU. Di sini diuji apa yang terjadi.
select uji.klaim('90000000-0000-0000-0000-000000000002');
select public.buat_kode_pemulihan('kode-probe-hakim5-C-minimal-20-karakter-acak-2026');
reset role;
select uji.klaim(null);
set local role anon;
select uji.harap(
  public.pulihkan_perangkat(
    'kode-probe-hakim5-C-minimal-20-karakter-acak-2026',
    'hp-darurat-C1-hakim5',
    'kunci-kembar-hakim5-9876543210',
    'a1a1a1a1-0000-0000-0000-000000000001'
  ) is not null,
  'A10: permohonan kembar pertama dibuat'
);
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');
select public.buat_kode_pemulihan('kode-probe-hakim5-D-minimal-20-karakter-acak-2026');
reset role;
select uji.klaim(null);
set local role anon;
select uji.harap(
  public.pulihkan_perangkat(
    'kode-probe-hakim5-D-minimal-20-karakter-acak-2026',
    'hp-darurat-C2-hakim5',
    'kunci-kembar-hakim5-9876543210',
    'a1a1a1a1-0000-0000-0000-000000000001'
  ) is not null,
  'A10: permohonan kembar kedua dibuat (kunci sama)'
);
reset role;
update public.pemulihan_perangkat
   set aktif_setelah = now() - interval '1 second'
 where perangkat_id in (select id from public.perangkat
                         where nama in ('hp-darurat-C1-hakim5','hp-darurat-C2-hakim5'));
set local role anon;
select uji.sama(
  public.selesaikan_pemulihan_darurat('kunci-kembar-hakim5-9876543210'),
  true,
  'A10: satu panggilan hanya mengaktifkan SATU permohonan'
);
reset role;
-- Catatan hakim (dibaca bersama keluaran, bukan asersi): permohonan mana yang
-- aktif dan berapa yang tersisa 'menunggu' dicetak di bawah.
select uji.harap(
  (select count(*) from public.pemulihan_perangkat q
     join public.perangkat p on p.id = q.perangkat_id
    where p.nama in ('hp-darurat-C1-hakim5','hp-darurat-C2-hakim5')
      and q.status = 'selesai') = 1,
  'A10: tepat satu dari dua permohonan berkunci sama menjadi selesai'
);
select uji.harap(
  (select count(*) from public.pemulihan_perangkat q
     join public.perangkat p on p.id = q.perangkat_id
    where p.nama in ('hp-darurat-C1-hakim5','hp-darurat-C2-hakim5')
      and q.status = 'menunggu') = 1,
  'A10: SATU permohonan kembar tertinggal menunggu (tidak ada penanda permohonan)'
);
reset role;

-- ------------------------------- A11 uji bantahan: tanpa penanda penyewa
-- A11. 0105 tidak menerima penanda penyewa maupun id permohonan: ia mencari
--      baris 'menunggu' yang kunci perangkatnya cocok di SELURUH penyewa, lalu
--      mengambil yang PALING BARU. Di sini dua permohonan menunggu sengaja
--      memakai KUNCI YANG SAMA: satu milik penyewa A (dibuat lewat jalur resmi
--      `pulihkan_perangkat`) dan satu milik penyewa B (disuntik sebagai pemilik
--      tabel, karena data uji penyewa B tidak punya owner_pusat). Permohonan B
--      diberi `diminta_pada` LEBIH BARU.
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');
select public.buat_kode_pemulihan('kode-probe-hakim5-E-minimal-20-karakter-acak-2026');
reset role;
select uji.klaim(null);
set local role anon;
select uji.harap(
  public.pulihkan_perangkat(
    'kode-probe-hakim5-E-minimal-20-karakter-acak-2026',
    'hp-darurat-E-hakim5',
    'kunci-uji-hp-b1-0123456789',      -- sengaja sama dengan kunci perangkat penyewa B
    'a1a1a1a1-0000-0000-0000-000000000001'
  ) is not null,
  'A11: permohonan penyewa A dibuat lewat jalur resmi (kunci kembar dengan B)'
);
reset role;
insert into public.pemulihan_perangkat (penyewa_id, perangkat_id, pemohon_id, diminta_pada, aktif_setelah, status)
values ('22222222-2222-2222-2222-222222222222', 'de000000-0000-0000-0000-000000000008',
        '90000000-0000-0000-0000-000000000007', now() + interval '1 minute',
        now() - interval '1 second', 'menunggu');
update public.pemulihan_perangkat
   set aktif_setelah = now() - interval '1 second'
 where perangkat_id = (select id from public.perangkat where nama = 'hp-darurat-E-hakim5');
set local role anon;
select uji.sama(
  public.selesaikan_pemulihan_darurat('kunci-uji-hp-b1-0123456789'),
  true,
  'A11: satu panggilan mengaktifkan permohonan terbaru yang kuncinya cocok'
);
reset role;
select uji.harap(
  (select q.status from public.pemulihan_perangkat q
     join public.perangkat p on p.id = q.perangkat_id
    where p.nama = 'hp-b1') = 'selesai',
  'A11: yang aktif = permohonan PENYEWA B (terbaru) — bukan permohonan penyewa A'
);
select uji.harap(
  (select q.status from public.pemulihan_perangkat q
     join public.perangkat p on p.id = q.perangkat_id
    where p.nama = 'hp-darurat-E-hakim5') = 'menunggu',
  'A11: permohonan penyewa A tertinggal menunggu (RPC tidak terikat penyewa/permohonan)'
);
