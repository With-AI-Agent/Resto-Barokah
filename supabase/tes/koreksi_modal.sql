-- ============================================================================
-- UJI T7-06 — KOREKSI MODAL AWAL DENGAN IZIN ATASAN (Fase 7 Kas & Shift)
-- ----------------------------------------------------------------------------
-- DoD T7-06:
--  - Koreksi tercatat sebagai baris baru (bukan menimpa), riwayat koreksi tetap ada.
--  - Wajib PIN atasan (owner/admin cabang) + alasan wajib.
--  - Muncul di laporan / view `laporan_koreksi_modal`.
--  - Mitigasi risiko: append-only + verifikasi PIN kupon sekali pakai.
--  - Perhitungan tutup shift memakai modal akhir yang telah dikoreksi.
-- ============================================================================

-- Tutup shift kasir Rina yang mungkin masih terbuka dari uji sebelumnya
update public.shift_kas
   set status = 'ditutup',
       ditutup_pada = now()
 where dibuka_oleh = '90000000-0000-0000-0000-000000000004'
   and status = 'terbuka';

-- Setup PIN owner (...0002)
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select public.simpan_pin('738294', null, null,
                         'de000000-0000-0000-0000-000000000001',
                         'kunci-uji-hp-owner-0123456789');
reset role;
select uji.klaim(null);

-- ---------------------------------------------------------------------------
-- 1. Buka shift baru dengan modal awal 100.000 oleh Kasir A1
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Kasir A1
set local role authenticated;

select uji.sama(
  (select (public.buka_shift(100000, 'a1a1a1a1-0000-0000-0000-000000000001', 'Shift pagi kasir Rina'))->>'berhasil')::boolean,
  true,
  'T7-06: Kasir A1 berhasil membuka shift kas dengan modal awal 100.000'
);

-- Simpan ID shift terbuka
create temp table t_shift_uji on commit drop as
select id as shift_id
  from public.shift_kas
 where penyewa_id = '11111111-1111-1111-1111-111111111111'
   and cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001'
   and status = 'terbuka';
grant all on t_shift_uji to public;

-- ---------------------------------------------------------------------------
-- 2. Pemicu picu_shift_kas_jaga: UPDATE langsung pada modal_awal tetap DITOLAK
--    (Diuji lewat reset role agar langsung menguji pemicu picu_shift_kas_jaga)
-- ---------------------------------------------------------------------------
reset role;
select uji.harap_gagal_sebab(
  $$update public.shift_kas set modal_awal = 999999 where id = (select shift_id from t_shift_uji)$$,
  'Modal awal tidak boleh diubah langsung',
  'T7-06: Direct UPDATE pada modal_awal shift_kas ditolak oleh pemicu penjaga'
);
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- ---------------------------------------------------------------------------
-- 3. Validasi penolakan koreksi modal:
--    (a) Penyetuju bukan pegawai resto ini (lintas penyewa)
--    (b) Penyetuju bukan atasan (misal sesama kasir atau pelayan)
--    (c) Modal awal baru bernilai negatif
--    (d) Modal awal baru sama dengan nilai saat ini
--    (e) Alasan kosong
--    (f) Penyetuju atasan tetapi TANPA bukti verifikasi PIN
-- ---------------------------------------------------------------------------

-- (a) Penyetuju bukan pegawai resto ini (kasir resto B ...0007)
select uji.harap_gagal_sebab(
  $$select public.koreksi_modal_shift(
      (select shift_id from t_shift_uji),
      150000,
      'Salah hitung',
      '90000000-0000-0000-0000-000000000007'
    )$$,
  'Penyetuju tidak ditemukan atau bukan pegawai aktif',
  'T7-06 (a): Penyetuju lintas penyewa ditolak'
);

-- (b) Penyetuju bukan atasan (pelayan ...0005)
select uji.harap_gagal_sebab(
  $$select public.koreksi_modal_shift(
      (select shift_id from t_shift_uji),
      150000,
      'Salah hitung',
      '90000000-0000-0000-0000-000000000005'
    )$$,
  'Penyetuju harus merupakan atasan',
  'T7-06 (b): Penyetuju bukan atasan (pelayan/kasir) ditolak'
);

-- (c) Modal awal baru negatif
select uji.harap_gagal_sebab(
  $$select public.koreksi_modal_shift(
      (select shift_id from t_shift_uji),
      -50000,
      'Salah hitung',
      '90000000-0000-0000-0000-000000000002'
    )$$,
  'Modal awal baru wajib diisi dan tidak boleh negatif',
  'T7-06 (c): Modal awal baru negatif ditolak'
);

-- (d) Modal awal baru sama dengan modal saat ini (100.000)
select uji.harap_gagal_sebab(
  $$select public.koreksi_modal_shift(
      (select shift_id from t_shift_uji),
      100000,
      'Salah hitung',
      '90000000-0000-0000-0000-000000000002'
    )$$,
  'Modal awal baru tidak boleh sama dengan modal awal saat ini',
  'T7-06 (d): Modal awal baru sama dengan saat ini ditolak'
);

-- (e) Alasan kosong
select uji.harap_gagal_sebab(
  $$select public.koreksi_modal_shift(
      (select shift_id from t_shift_uji),
      150000,
      '   ',
      '90000000-0000-0000-0000-000000000002'
    )$$,
  'Alasan koreksi modal awal wajib diisi',
  'T7-06 (e): Alasan koreksi kosong ditolak'
);

-- (f) Penyetuju atasan (owner ...0002) tetapi TANPA bukti verifikasi PIN
select uji.harap_gagal_sebab(
  $$select public.koreksi_modal_shift(
      (select shift_id from t_shift_uji),
      150000,
      'Salah hitung uang receh',
      '90000000-0000-0000-0000-000000000002'
    )$$,
  'Persetujuan belum terbukti',
  'T7-06 (f): Koreksi modal tanpa bukti PIN atasan ditolak'
);

-- ---------------------------------------------------------------------------
-- 4. JALUR SAH PERTAMA: Atasan memasukkan PIN, kasir mengoreksi modal
--    100.000 -> 150.000 (selisih +50.000)
-- ---------------------------------------------------------------------------
-- Atasan memasukkan PIN di perangkat
select (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294',
                             'koreksi_modal_shift',
                             'de000000-0000-0000-0000-000000000001',
                             'kunci-uji-hp-owner-0123456789')).berhasil;

-- Kasir memanggil koreksi modal
create temp table t_hasil_koreksi_1 on commit drop as
select public.koreksi_modal_shift(
  (select shift_id from t_shift_uji),
  150000,
  'Ketinggalan uang pecahan Rp50.000 di laci brankas saat buka kas',
  '90000000-0000-0000-0000-000000000002'
) as res;

select uji.sama(
  (select (res->>'berhasil')::boolean from t_hasil_koreksi_1),
  true,
  'T7-06: Koreksi modal awal pertama berhasil dengan persetujuan PIN owner'
);

select uji.sama(
  (select (res->'data'->>'modal_awal_sebelumnya')::integer from t_hasil_koreksi_1),
  100000,
  'T7-06: Modal awal sebelumnya tercatat 100.000'
);

select uji.sama(
  (select (res->'data'->>'modal_awal_baru')::integer from t_hasil_koreksi_1),
  150000,
  'T7-06: Modal awal baru tercatat 150.000'
);

select uji.sama(
  (select (res->'data'->>'selisih')::integer from t_hasil_koreksi_1),
  50000,
  'T7-06: Selisih koreksi tercatat +50.000'
);

-- Buktikan modal_awal pada shift_kas berubah menjadi 150.000
select uji.sama(
  (select modal_awal from public.shift_kas where id = (select shift_id from t_shift_uji)),
  150000,
  'T7-06: modal_awal pada shift_kas diperbarui menjadi 150.000'
);

-- Buktikan riwayat hanya-tambah tercatat di public.koreksi_modal_shift
select uji.sama(
  (select count(*) from public.koreksi_modal_shift where shift_id = (select shift_id from t_shift_uji)),
  1::bigint,
  'T7-06: Tepat 1 baris riwayat koreksi tercatat di tabel koreksi_modal_shift'
);

-- Buktikan jejak audit tercatat di public.catatan_audit (dilihat oleh owner yang berhak kelola_pegawai)
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.sama(
  (select count(*) from public.catatan_audit
    where entitas = 'shift_kas'
      and entitas_id = (select shift_id from t_shift_uji)
      and aksi = 'koreksi_modal_shift'),
  1::bigint,
  'T7-06: Jejak audit koreksi_modal_shift tercatat di public.catatan_audit'
);

-- Kasir Rina login kembali
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- ---------------------------------------------------------------------------
-- 5. Bukti Kupon Sekali Pakai: Memakai kembali kupon PIN lama DITOLAK
-- ---------------------------------------------------------------------------
select uji.harap_gagal_sebab(
  $$select public.koreksi_modal_shift(
      (select shift_id from t_shift_uji),
      160000,
      'Koreksi ulang tanpa verifikasi PIN baru',
      '90000000-0000-0000-0000-000000000002'
    )$$,
  'Persetujuan belum terbukti',
  'T7-06: Kupon PIN atasan yang sudah terpakai tidak bisa dipakai ulang (sekali pakai)'
);

-- ---------------------------------------------------------------------------
-- 6. JALUR SAH KEDUA: Koreksi kedua (append-only history)
--    150.000 -> 125.000 (selisih -25.000)
-- ---------------------------------------------------------------------------
-- Verifikasi PIN owner baru
select (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294',
                             'koreksi_modal_shift',
                             'de000000-0000-0000-0000-000000000001',
                             'kunci-uji-hp-owner-0123456789')).berhasil;

select (public.koreksi_modal_shift(
  (select shift_id from t_shift_uji),
  125000,
  'Koreksi ulang: Rp25.000 ternyata uang kasbon pelayan, bukan modal kasir',
  '90000000-0000-0000-0000-000000000002'
))->>'berhasil';

-- Buktikan tabel koreksi_modal_shift kini memiliki 2 baris riwayat (bukan menimpa)
select uji.sama(
  (select count(*) from public.koreksi_modal_shift where shift_id = (select shift_id from t_shift_uji)),
  2::bigint,
  'T7-06: Riwayat koreksi kedua tercatat sebagai baris baru (total 2 baris, append-only)'
);

select uji.sama(
  (select modal_awal from public.shift_kas where id = (select shift_id from t_shift_uji)),
  125000,
  'T7-06: modal_awal pada shift_kas kini menjadi 125.000'
);

-- ---------------------------------------------------------------------------
-- 7. Pagar tabel riwayat kekal: UPDATE atau DELETE dilarang
--    (Diuji lewat reset role agar langsung menguji pemicu picu_koreksi_modal_kekal)
-- ---------------------------------------------------------------------------
reset role;

select uji.harap_gagal_sebab(
  $$update public.koreksi_modal_shift set modal_awal_baru = 999999 where shift_id = (select shift_id from t_shift_uji)$$,
  'Riwayat koreksi modal awal adalah jejak audit kekal',
  'T7-06: UPDATE pada koreksi_modal_shift dilarang bahkan oleh superuser'
);

select uji.harap_gagal_sebab(
  $$delete from public.koreksi_modal_shift where shift_id = (select shift_id from t_shift_uji)$$,
  'Riwayat koreksi modal awal adalah jejak audit kekal',
  'T7-06: DELETE pada koreksi_modal_shift dilarang bahkan oleh superuser'
);

-- Kasir Rina login kembali
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- ---------------------------------------------------------------------------
-- 8. Tutup shift kas: Uang seharusnya menggunakan modal terkoreksi (125.000)
-- ---------------------------------------------------------------------------
-- Tutup kas dengan uang fisik pas 125.000 (tanpa penjualan / kas pergerakan)
create temp table t_hasil_tutup on commit drop as
select public.tutup_shift(125000, null, (select shift_id from t_shift_uji)) as res;

select uji.sama(
  (select (res->'data'->>'uang_seharusnya')::integer from t_hasil_tutup),
  125000,
  'T7-06: Uang seharusnya saat tutup shift adalah 125.000 (modal akhir terkoreksi, bukan 100.000)'
);

select uji.sama(
  (select (res->'data'->>'selisih')::integer from t_hasil_tutup),
  0,
  'T7-06: Selisih uang fisik vs seharusnya adalah 0'
);

-- ---------------------------------------------------------------------------
-- 9. Pagar shift tertutup: Koreksi modal pada shift tertutup DITOLAK
-- ---------------------------------------------------------------------------
-- Verifikasi PIN owner baru
select (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294',
                             'koreksi_modal_shift',
                             'de000000-0000-0000-0000-000000000001',
                             'kunci-uji-hp-owner-0123456789')).berhasil;

select uji.harap_gagal_sebab(
  $$select public.koreksi_modal_shift(
      (select shift_id from t_shift_uji),
      200000,
      'Coba koreksi setelah shift tutup',
      '90000000-0000-0000-0000-000000000002'
    )$$,
  'Shift kas sudah ditutup',
  'T7-06: Koreksi modal awal pada shift yang sudah ditutup DITOLAK'
);

-- ---------------------------------------------------------------------------
-- 10. View laporan_koreksi_modal menyajikan seluruh riwayat koreksi lengkap
--     (Diakses oleh owner yang berhak melihat profil seluruh pegawai)
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.sama(
  (select count(*) from public.laporan_koreksi_modal where shift_id = (select shift_id from t_shift_uji)),
  2::bigint,
  'T7-06: View laporan_koreksi_modal memuat 2 riwayat koreksi'
);

select uji.sama(
  (select count(*) from public.laporan_koreksi_modal
    where shift_id = (select shift_id from t_shift_uji)
      and nama_pengaju = 'Rina'
      and nama_penyetuju = 'Bu Oasis'),
  2::bigint,
  'T7-06: View laporan_koreksi_modal memuat nama pengaju (Rina) dan penyetuju (Bu Oasis)'
);

-- ---------------------------------------------------------------------------
-- 11. Isolasi multi-tenant (RLS): Kasir resto B tidak bisa melihat riwayat A
-- ---------------------------------------------------------------------------
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000007'); -- Kasir Resto B
set local role authenticated;

select uji.sama(
  (select count(*) from public.koreksi_modal_shift where shift_id = (select shift_id from t_shift_uji)),
  0::bigint,
  'T7-06: RLS mencegah Kasir Resto B melihat riwayat koreksi modal Resto A'
);

select uji.sama(
  (select count(*) from public.laporan_koreksi_modal where shift_id = (select shift_id from t_shift_uji)),
  0::bigint,
  'T7-06: RLS mencegah Kasir Resto B melihat view laporan koreksi modal Resto A'
);

reset role;
select uji.klaim(null);
