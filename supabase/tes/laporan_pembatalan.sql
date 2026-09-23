-- ============================================================================
-- UJI T5-12 — laporan pembatalan (siapa, nilai, alasan, jenis)
--
-- Dua hal yang dibuktikan berkas ini:
--
--  A. UJI GOLDEN (diminta DoD): angka laporan HARUS sama dengan data mentah.
--     Caranya bukan menuliskan angka harapan dari kepala saya, melainkan
--     membandingkan hasil view dengan hitungan langsung atas tabel `pembatalan`.
--     Kalau suatu hari view-nya salah join (mis. baris terduplikasi karena join
--     ke `pesanan_item`), jumlah kerugiannya akan membengkak dan uji ini merah.
--     Menuliskan angka tetap tidak akan menangkap itu.
--
--  B. SIAPA YANG BOLEH MEMBACA. Daftar pembatalan memperlihatkan pegawai mana
--     yang paling sering membatalkan dan berapa kerugiannya — data
--     ketenagakerjaan yang sensitif. Sebelum migrasi 0043, SIAPA PUN yang masuk
--     bisa membacanya, termasuk pelayan dan dapur yang izin `lihat_laporan`-nya
--     tegas-tegas `false`. Uji ini mengunci perbaikannya supaya tidak diam-diam
--     kembali longgar.
--
-- Data uji dibuat di sini dengan id `cc…` supaya tidak mengganggu berkas lain,
-- dan dibersihkan di akhir.
-- ============================================================================

-- ------------------------------------------------------------- penyiapan
-- Dua pesanan di Cabang A1: satu dibatalkan SEBELUM dapur, satu SESUDAH dapur.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status,
                            subtotal, pajak, service, total, kunci_idempoten)
values ('cc000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 961, current_date, 'dinein', 'draf',
        0, 0, 0, 0, 'lap-batal-1'),
       ('cc000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 962, current_date, 'dinein', 'draf',
        0, 0, 0, 0, 'lap-batal-2');

insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu,
                                 harga_saat_itu, qty, subtotal)
values ('cc000000-0000-0000-0000-0000000000a1', 'cc000000-0000-0000-0000-000000000001',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng Spesial', 30000, 2, 60000);

-- Pembatalan #1 — pra-dapur, dicatat kasir (tidak perlu persetujuan).
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- Rina, kasir A1
set local role authenticated;
insert into public.pembatalan (pesanan_id, pesanan_item_id, tahap, alasan, nilai_kerugian)
values ('cc000000-0000-0000-0000-000000000001', 'cc000000-0000-0000-0000-0000000000a1',
        'sebelum_dapur', 'Tamu berubah pikiran sebelum pesanan dimasak', 0);
insert into public.pembatalan (pesanan_id, tahap, alasan, nilai_kerugian)
values ('cc000000-0000-0000-0000-000000000002',
        'sebelum_dapur', 'Salah input meja', 0);
reset role;
select uji.klaim(null);

-- ==========================================================================
-- A. UJI GOLDEN — laporan vs data mentah
-- ==========================================================================
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- Bu Oasis, owner
set local role authenticated;

-- Jumlah baris laporan = jumlah baris mentah (tidak ada yang hilang, tidak ada
-- yang terduplikasi oleh join).
select uji.sama(
  (select count(*)::bigint from public.laporan_pembatalan
    where nomor_pesanan in (961, 962)),
  (select count(*)::bigint from public.pembatalan b
     join public.pesanan p on p.id = b.pesanan_id
    where p.nomor in (961, 962)),
  'T5-12 golden: jumlah baris laporan sama dengan data mentah'
);

-- Total kerugian laporan = total kerugian mentah.
select uji.sama(
  (select coalesce(sum(nilai_kerugian), 0)::bigint from public.laporan_pembatalan
    where nomor_pesanan in (961, 962)),
  (select coalesce(sum(b.nilai_kerugian), 0)::bigint from public.pembatalan b
     join public.pesanan p on p.id = b.pesanan_id
    where p.nomor in (961, 962)),
  'T5-12 golden: total kerugian laporan sama dengan data mentah'
);

-- ------------------------------------------- isi kolom yang diminta PRD M8
select uji.sama(
  (select pelaku_nama from public.laporan_pembatalan where nomor_pesanan = 961),
  'Rina', 'T5-12: laporan menyebut SIAPA yang membatalkan'
);
select uji.sama(
  (select alasan from public.laporan_pembatalan where nomor_pesanan = 962),
  'Salah input meja', 'T5-12: laporan menyebut ALASAN apa adanya'
);
select uji.sama(
  (select tahap from public.laporan_pembatalan where nomor_pesanan = 961),
  'sebelum_dapur', 'T5-12: laporan menyebut JENIS (pra/pasca dapur)'
);
select uji.sama(
  (select item_nama from public.laporan_pembatalan where nomor_pesanan = 961),
  'Nasi Goreng Spesial', 'T5-12: pembatalan per item menyebut item mana'
);
select uji.harap(
  (select tanggal from public.laporan_pembatalan where nomor_pesanan = 961) = current_date,
  'T5-12: laporan bisa disaring per HARI'
);
select uji.sama(
  (select cabang_id from public.laporan_pembatalan where nomor_pesanan = 961),
  'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
  'T5-12: laporan bisa disaring per CABANG'
);

-- Nama pelaku sengaja TIDAK dibekukan: yang dilaporkan adalah orangnya, jadi
-- nama yang diperbaiki harus ikut terbaca benar di laporan lama.
reset role;
select uji.klaim(null);

update public.pengguna set nama = 'Rina Kasir' where id = '90000000-0000-0000-0000-000000000004';

select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(
  (select pelaku_nama from public.laporan_pembatalan where nomor_pesanan = 961),
  'Rina Kasir', 'T5-12: nama pelaku ikut terkoreksi (bukan salinan beku)'
);
reset role;
select uji.klaim(null);

update public.pengguna set nama = 'Rina' where id = '90000000-0000-0000-0000-000000000004';

-- ==========================================================================
-- B. SIAPA YANG BOLEH MEMBACA (celah yang ditutup migrasi 0043)
-- ==========================================================================

-- Owner: punya izin lihat_laporan → melihat.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.harap(
  (select count(*) from public.laporan_pembatalan where nomor_pesanan in (961, 962)) = 2,
  'T5-12: owner (punya lihat_laporan) MELIHAT daftar pembatalan'
);
reset role;
select uji.klaim(null);

-- Admin cabang: punya izin lihat_laporan → melihat.
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
select uji.harap(
  (select count(*) from public.laporan_pembatalan where nomor_pesanan in (961, 962)) = 2,
  'T5-12: admin cabang (punya lihat_laporan) MELIHAT daftar pembatalan'
);
reset role;
select uji.klaim(null);

-- Pelayan: TIDAK punya izin lihat_laporan → tidak melihat apa pun.
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;
select uji.sama((select public.boleh('lihat_laporan')), false,
  'T5-12 prasyarat: pelayan memang tidak berizin lihat_laporan');
select uji.sama(
  (select count(*)::bigint from public.pembatalan b
     join public.pesanan p on p.id = b.pesanan_id
    where p.nomor in (961, 962)),
  0::bigint,
  'T5-12 CELAH DITUTUP: pelayan tidak bisa membaca tabel pembatalan langsung'
);
select uji.sama(
  (select count(*)::bigint from public.laporan_pembatalan where nomor_pesanan in (961, 962)),
  0::bigint,
  'T5-12: view pun tidak membocorkannya (security_invoker, bukan pintu belakang)'
);
reset role;
select uji.klaim(null);

-- Kasir: boleh MENCATAT pembatalan (sudah terbukti di penyiapan), tetapi tidak
-- boleh membaca daftarnya kembali. Dua hal berbeda, dan sengaja dipisah.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(
  (select count(*)::bigint from public.laporan_pembatalan where nomor_pesanan in (961, 962)),
  0::bigint,
  'T5-12: kasir mencatat pembatalan, tetapi tidak membaca laporannya'
);
reset role;
select uji.klaim(null);

-- Resto lain tidak melihat apa pun (isolasi penyewa tetap berlaku di atas izin).
select uji.klaim('90000000-0000-0000-0000-000000000007');
set local role authenticated;
select uji.sama(
  (select count(*)::bigint from public.laporan_pembatalan where nomor_pesanan in (961, 962)),
  0::bigint,
  'T5-12: resto lain tidak melihat pembatalan resto ini'
);
reset role;
select uji.klaim(null);

-- ----------------------------------------------------------- bersih-bersih
delete from public.pembatalan
 where pesanan_id in ('cc000000-0000-0000-0000-000000000001',
                      'cc000000-0000-0000-0000-000000000002');
delete from public.pesanan_item where pesanan_id = 'cc000000-0000-0000-0000-000000000001';
delete from public.pesanan
 where id in ('cc000000-0000-0000-0000-000000000001',
              'cc000000-0000-0000-0000-000000000002');
