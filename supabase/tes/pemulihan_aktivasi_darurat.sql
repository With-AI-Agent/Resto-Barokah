-- ============================================================================
-- UJI SQL: aktivasi perangkat darurat TANPA sesi (PMB1-F-083 ronde 3 &
--          PMB1-F-234 · K-2; penanda penyewa/permohonan PMB1-F-239 · K-3,
--          migrasi 0106) — kunci induk §4b tuntas sampai akhir, TERARAH
-- ============================================================================
-- Yang dijaga (migrasi 0105 → digantikan 0106):
--   1. Owner yang kehilangan SELURUH perangkat bisa MENYELESAIKAN pemulihan
--      darurat (mengaktifkan perangkat) TANPA sesi, memakai kunci perangkat
--      yang ia pilih sendiri saat pengajuan (bukti kepemilikan).
--   2. Masa tenggang 30 menit tetap ditegakkan: aktivasi sebelum waktunya
--      ditolak.
--   3. Kunci salah / permohonan tak dikenal / id tak dikenal ditolak dengan
--      pesan seragam (anti-orakel).
--   4. Sesudah aktif: antrean 'selesai', perangkat aktif=true, dan LOGIN
--      owner lewat perangkat itu benar-benar berhasil (ujung-ke-ujung:
--      verifikasi_pin_perangkat mengembalikan LOGIN_SUKSES).
--   5. Permohonan yang sudah selesai tidak bisa diaktifkan ulang.
-- Yang DITAMBAHKAN migrasi 0106 (PMB1-F-239, KEPUTUSAN LEE 2026-10-07):
--   6. Aktivasi TERIKAT pada SATU permohonan lewat id permohonan yang
--      dikembalikan pulihkan_perangkat saat pengajuan — tidak ada lagi
--      pemilihan bebas lintas penyewa. Dibuktikan:
--      6a. Permohonan kembar SATU penyewa berkunci sama: mengaktifkan
--          permohonan PERTAMA (bukan yang terbaru) bekerja, dan permohonan
--          kedua tidak tersentuh (deterministik, penanda = id).
--      6b. Kunci kembar LINTAS penyewa: panggilan pemohon A dengan kuncinya
--          hanya mengaktifkan permohonan penyewa A; permohonan penyewa B
--          yang lebih baru TIDAK tersentuh (probe H-F-06.5 A11 pra-0106
--          membuktikan kebalikannya).
-- Jalankan: node alat/uji-sql.mjs supabase/tes/pemulihan_aktivasi_darurat.sql
-- ============================================================================

-- Penyiapan: PIN owner dipasang sebagai pemilik tabel (pola tes perangkat lain)
-- supaya langkah ujung-ke-ujung bisa membuktikan login.
delete from public.percobaan_pin;
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000002', crypt('481516', gen_salt('bf')))
on conflict (pengguna_id) do update set pin_hash = excluded.pin_hash;

-- Penyiapan: owner membuat kode pemulihan darurat (jalur ber-sesi sah).
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Bu Oasis (owner_pusat)
select uji.sama(
  public.buat_kode_pemulihan('kode-uji-aktivasi-darurat-2026-masih-sangat-panjang'),
  'Kode pemulihan darurat berhasil disimpan. Cetak dan simpan 2 salinan fisik di amplop tersegel.',
  'F-083 r3: owner membuat kode pemulihan darurat'
);
reset role;

-- 1. TANPA SESI: owner mengajukan pemulihan darurat (jalur 0102). Id
--    permohonan yang dikembalikan DISIMPAN — itulah penanda aktivasi (F-239).
select uji.klaim(null);
set local role anon;
create temp table uji_permohonan_aktivasi as
select public.pulihkan_perangkat(
  'kode-uji-aktivasi-darurat-2026-masih-sangat-panjang',
  'hp-aktivasi-darurat-f083',
  'kunci-aktivasi-darurat-0123456789',
  'a1a1a1a1-0000-0000-0000-000000000001'
) as permohonan_id;
select uji.harap(
  (select permohonan_id from uji_permohonan_aktivasi) is not null,
  'F-083 r3: pengajuan pemulihan darurat tanpa sesi berhasil & id permohonan diterima'
);
reset role;

-- 2. Masa tenggang ditegakkan: aktivasi SEBELUM 30 menit -> DITOLAK,
--    sekalipun pemegang id permohonan yang benar memanggil.
set local role anon;
select uji.harap_gagal_sebab(
  $$select public.selesaikan_pemulihan_darurat(
      (select permohonan_id from uji_permohonan_aktivasi),
      'kunci-aktivasi-darurat-0123456789')$$,
  'Permohonan pemulihan tidak ditemukan',
  'F-234: aktivasi sebelum masa tenggang lewat ditolak (tanpa sesi)'
);

-- 2b. Kunci salah sesudah tenggang lewat -> tetap DITOLAK (pesan seragam).
--     (Tenggang dimajukan lewat pemilik tabel: RLS tidak menghalangi pemilik.)
reset role;
update public.pemulihan_perangkat
   set aktif_setelah = now() - interval '1 second'
 where perangkat_id = (select id from public.perangkat where nama = 'hp-aktivasi-darurat-f083');

set local role anon;
select uji.harap_gagal_sebab(
  $$select public.selesaikan_pemulihan_darurat(
      (select permohonan_id from uji_permohonan_aktivasi),
      'kunci-salah-bukan-milik-owner-1234')$$,
  'Permohonan pemulihan tidak ditemukan',
  'F-234: kunci perangkat salah ditolak dengan pesan seragam'
);

-- 2c. F-239: id permohonan yang tidak dikenal -> ditolak pesan seragam.
select uji.harap_gagal_sebab(
  $$select public.selesaikan_pemulihan_darurat(
      'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'::uuid,
      'kunci-aktivasi-darurat-0123456789')$$,
  'Permohonan pemulihan tidak ditemukan',
  'F-239: id permohonan tak dikenal ditolak dengan pesan seragam'
);
reset role;

-- 2d. F-239 (6a): permohonan KEMBAR satu penyewa, kunci SAMA. Owner
--     mengajukan perangkat kedua dengan kunci yang sama persis.
select uji.klaim('90000000-0000-0000-0000-000000000002');
select uji.sama(
  public.buat_kode_pemulihan('kode-uji-kembar-f239-2026-cukup-panjang-sekali'),
  'Kode pemulihan darurat berhasil disimpan. Cetak dan simpan 2 salinan fisik di amplop tersegel.',
  'F-239: owner membuat kode kedua untuk permohonan kembar'
);
reset role;
set local role anon;
create temp table uji_permohonan_kembar as
select public.pulihkan_perangkat(
  'kode-uji-kembar-f239-2026-cukup-panjang-sekali',
  'hp-aktivasi-darurat-f239-kembar',
  'kunci-aktivasi-darurat-0123456789',
  'a1a1a1a1-0000-0000-0000-000000000001'
) as permohonan_id;
reset role;

update public.pemulihan_perangkat
   set aktif_setelah = now() - interval '1 second'
 where perangkat_id = (select id from public.perangkat where nama = 'hp-aktivasi-darurat-f239-kembar');

-- 2e. F-239 (6a): panggilan memegang id permohonan PERTAMA (bukan yang
--     terbaru). Pra-0106, pemilihan bebas selalu mengambil yang TERBARU dan
--     meninggalkan yang pertama — kini pilihan terarah oleh penanda.
set local role anon;
select uji.sama(
  public.selesaikan_pemulihan_darurat(
    (select permohonan_id from uji_permohonan_aktivasi),
    'kunci-aktivasi-darurat-0123456789'
  ),
  true,
  'F-239: aktivasi permohonan PERTAMA (penanda id) berhasil walau ada kembaran lebih baru'
);
reset role;
select uji.harap(
  exists (
    select 1 from public.pemulihan_perangkat
     where id = (select permohonan_id from uji_permohonan_kembar)
       and status = 'menunggu'
  ),
  'F-239: permohonan kembar yang lebih baru TIDAK tersentuh (tidak ada pemilihan bebas)'
);

-- 3. Kunci yang benar sesudah tenggang lewat -> AKTIF tanpa sesi.
--    (Permohonan pertama sudah diaktifkan pada 2e; langkah ini meneruskan
--    permohonan kembar dengan penanda id-nya sendiri.)
set local role anon;
select uji.sama(
  public.selesaikan_pemulihan_darurat(
    (select permohonan_id from uji_permohonan_kembar),
    'kunci-aktivasi-darurat-0123456789'
  ),
  true,
  'F-234/F-239: aktivasi perangkat darurat tanpa sesi berhasil sesudah tenggang'
);

-- 3b. Antrean selesai + perangkat aktif + jejak audit tercatat.
reset role;
select uji.harap(
  exists (
    select 1 from public.pemulihan_perangkat q
    join public.perangkat p on p.id = q.perangkat_id
     where p.nama = 'hp-aktivasi-darurat-f083'
       and q.status = 'selesai'
       and p.aktif = true
  ),
  'F-234: antrean selesai dan perangkat darurat aktif'
);
select uji.harap(
  exists (
    select 1 from public.catatan_audit
     where aksi = 'selesaikan_pemulihan_darurat'
       and pelaku_id = '90000000-0000-0000-0000-000000000002'
  ),
  'F-234: jejak audit aktivasi tanpa sesi tercatat atas nama pemohon'
);

-- 3c. Permohonan yang sudah selesai tidak bisa diaktifkan ulang.
set local role anon;
select uji.harap_gagal_sebab(
  $$select public.selesaikan_pemulihan_darurat(
      (select permohonan_id from uji_permohonan_aktivasi),
      'kunci-aktivasi-darurat-0123456789')$$,
  'Permohonan pemulihan tidak ditemukan',
  'F-234: permohonan selesai tidak bisa diaktifkan ulang'
);
reset role;

-- 3d. F-239 (6b): kunci kembar LINTAS penyewa. Owner penyewa A mengajukan
--     perangkat darurat dengan kunci yang SAMA dengan kunci perangkat hp-b1
--     milik penyewa B (skenario: satu pemilik dua resto / kunci bawaan
--     vendor). Permohonan penyewa B lalu disuntikkan LEBIH BARU.
select uji.klaim('90000000-0000-0000-0000-000000000002');
select uji.sama(
  public.buat_kode_pemulihan('kode-uji-lintas-f239-2026-sangat-panjang-pula'),
  'Kode pemulihan darurat berhasil disimpan. Cetak dan simpan 2 salinan fisik di amplop tersegel.',
  'F-239: owner membuat kode segar untuk perangkat lintas-kunci'
);
reset role;

set local role anon;
create temp table uji_permohonan_lintas as
select public.pulihkan_perangkat(
  'kode-uji-lintas-f239-2026-sangat-panjang-pula',
  'hp-aktivasi-darurat-f239-lintas',
  'kunci-uji-hp-b1-0123456789',
  'a1a1a1a1-0000-0000-0000-000000000001'
) as permohonan_id;
reset role;

-- Suntikan permohonan penyewa B (lebih baru, kunci perangkat sama persis).
insert into public.pemulihan_perangkat
  (penyewa_id, perangkat_id, pemohon_id, diminta_pada, aktif_setelah, status)
values
  ('22222222-2222-2222-2222-222222222222',
   'de000000-0000-0000-0000-000000000008',
   '90000000-0000-0000-0000-000000000007',
   now() + interval '1 minute',
   now() - interval '1 second',
   'menunggu');

create temp table uji_permohonan_b as
select id as permohonan_id
  from public.pemulihan_perangkat
 where perangkat_id = 'de000000-0000-0000-0000-000000000008'
   and status = 'menunggu'
 order by diminta_pada desc
 limit 1;
grant select on table uji_permohonan_b to anon;

update public.pemulihan_perangkat
   set aktif_setelah = now() - interval '1 second'
 where id = (select permohonan_id from uji_permohonan_lintas);

-- Pemanggil memegang id permohonan penyewa A; kuncinya cocok dengan perangkat
-- penyewa A itu. Pra-0106, yang aktif justru permohonan penyewa B (terbaru).
set local role anon;
select uji.sama(
  public.selesaikan_pemulihan_darurat(
    (select permohonan_id from uji_permohonan_lintas),
    'kunci-uji-hp-b1-0123456789'
  ),
  true,
  'F-239: aktivasi lintas-penyewa mengenai permohonan penyewa A sendiri'
);
reset role;
select uji.harap(
  exists (
    select 1 from public.pemulihan_perangkat
     where id = (select permohonan_id from uji_permohonan_b)
       and status = 'menunggu'
  ),
  'F-239: permohonan penyewa B TIDAK tersentuh panggilan penyewa A (isolasi)'
);
select uji.harap(
  not exists (
    select 1 from public.pemulihan_perangkat
     where perangkat_id = 'de000000-0000-0000-0000-000000000008'
       and status = 'selesai'
  ),
  'F-239: permohonan hp-b1 milik penyewa B belum disentuh aktivasi mana pun'
);

-- Permohonan penyewa B tetap sah diselesaikan oleh pemegang id-nya sendiri.
set local role anon;
select uji.sama(
  public.selesaikan_pemulihan_darurat(
    (select permohonan_id from uji_permohonan_b),
    'kunci-uji-hp-b1-0123456789'
  ),
  true,
  'F-239: pemegang id permohonan penyewa B tetap bisa mengaktifkan permohonannya sendiri'
);
reset role;

-- 4. UJUNG-KE-UJUNG: owner yang tadinya terkunci PERANGKAT_TIDAK_SAH kini
--    bisa LOGIN lewat perangkat darurat yang baru diaktifkan.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.harap(
  (select public.verifikasi_pin_perangkat(
     'owner.a@contoh.test',
     '481516',
     p.id,
     p.nama,
     'kunci-aktivasi-darurat-0123456789'
   )->>'kode' from public.perangkat p where p.nama = 'hp-aktivasi-darurat-f083') = 'LOGIN_SUKSES',
  'F-234: login owner lewat perangkat darurat berhasil (kunci induk §4b tuntas)'
);
reset role;
