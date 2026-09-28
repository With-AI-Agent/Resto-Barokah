-- ============================================================================
-- UJI: bayar_pesanan (T5-02, migrasi 0039) — pintu tunggal pencatatan uang masuk
--
-- Yang dibuktikan (DoD ROADMAP T5-02: "uji SQL 8 kasus — uang pas, lebih, kurang,
-- metode berbeda, dobel tekan"):
--   1. tanpa identitas → ditolak;
--   2. peran yang tidak boleh mencatat uang (dapur) → ditolak RLS;
--   3. jumlah nol/negatif → ditolak;
--   4. tunai: tanpa uang diterima → ditolak; uang kurang → ditolak;
--   5. tunai lebih → KEMBALIAN dihitung peladen (bukan kiriman perangkat);
--   6. pembayaran sebagian → pesanan BELUM lunas;
--   7. non-tunai tanpa referensi → ditolak; dengan referensi → sah (metode berbeda);
--   8. total tertutup → pesanan LUNAS + stempel waktu (sekali, di transaksi itu);
--   9. DOBEL TEKAN (kunci idempoten sama) → tidak menambah uang/baris;
--  10. pembayaran melebihi total → ditolak (walau uang diterima besar);
--  11. pesanan resto lain → "tidak ditemukan" (tidak membocorkan keberadaan);
--  12. jejak audit tertulis & rantai hash tetap utuh;
--  13. sesudah lunas pesanan beku (0022) — konfirmasi pagar lama tetap bekerja.
-- ============================================================================

-- Data uji tambahan (dibuat sebagai pemilik tabel, di luar RLS — pola yang sama
-- dipakai supabase/tes/isolasi_lintas_penyewa.sql):
--   c001 → pesanan RESTO B (untuk uji lintas penyewa),
--   c002 → pesanan resto A yang totalnya BELUM dihitung (uji pagar K-1).
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status,
                            subtotal, pajak, service, total, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000c001', '22222222-2222-2222-2222-222222222222',
        'b1b1b1b1-0000-0000-0000-000000000001', 93, current_date, 'dinein', 'dikirim',
        0, 0, 0, 0, 'bayar-pesanan-c'),
       ('00000000-0000-0000-0000-00000000c002', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 94, current_date, 'dinein', 'draf',
        0, 0, 0, 0, 'bayar-pesanan-tanpa-total');
update public.pesanan set subtotal = 20000, total = 20000
 where id = '00000000-0000-0000-0000-00000000c001';

-- Pesanan uji resto A: eeee…0010 — subtotal 54.000, pajak 5.400, service 2.700,
-- total 62.100, status 'dikirim', belum ada pembayaran di berkas uji ini.

-- 1. Tanpa identitas: pintu tertutup.
select uji.klaim(null);
select uji.harap_gagal_sebab(
  $$select public.bayar_pesanan('eeee0000-0000-0000-0000-000000000010', null, 1000)$$,
  'harus masuk dulu',
  'tanpa identitas bayar_pesanan ditolak');

-- 2. Peran yang tidak boleh mencatat uang. PENTING: RPC ini SECURITY DEFINER, jadi
--    kebijakan RLS `pembayaran_tambah` TIDAK menjaganya — pagar peran ditegakkan di
--    dalam fungsi (temuan saat uji ini ditulis: tanpa pagar itu dapur lolos).
select uji.klaim('90000000-0000-0000-0000-000000000006');   -- dapur
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.bayar_pesanan('eeee0000-0000-0000-0000-000000000010',
        (select id from public.metode_bayar
          where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai'),
        1000, 1000, null, 'bayar-dapur')$$,
  'tidak berwenang mencatat uang',
  'dapur tidak boleh mencatat uang lewat RPC');
reset role;

select uji.klaim('90000000-0000-0000-0000-000000000005');   -- pelayan
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.bayar_pesanan('eeee0000-0000-0000-0000-000000000010',
        (select id from public.metode_bayar
          where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai'),
        1000, 1000, null, 'bayar-pelayan')$$,
  'tidak berwenang mencatat uang',
  'pelayan tidak boleh mencatat uang lewat RPC');
reset role;

-- Kasir cabang Pusat mulai bekerja.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- 3. Jumlah tidak sah.
select uji.harap_gagal_sebab(
  $$select public.bayar_pesanan('eeee0000-0000-0000-0000-000000000010', null, 0)$$,
  'lebih besar dari nol',
  'jumlah nol ditolak');
select uji.harap_gagal_sebab(
  $$select public.bayar_pesanan('eeee0000-0000-0000-0000-000000000010', null, -5000)$$,
  'lebih besar dari nol',
  'jumlah negatif ditolak');

-- 4. Metode tidak dikenal / tidak aktif.
select uji.harap_gagal_sebab(
  $$select public.bayar_pesanan('eeee0000-0000-0000-0000-000000000010',
        'ffffffff-0000-0000-0000-000000000000', 1000)$$,
  'tidak ada di resto ini',
  'metode bayar asing ditolak');

-- 5. Tunai: uang diterima wajib & tidak boleh lebih kecil dari jumlah.
select uji.harap_gagal_sebab(
  $$select public.bayar_pesanan('eeee0000-0000-0000-0000-000000000010',
        (select id from public.metode_bayar
          where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai'),
        30000, null, null, 'bayar-tunai-tanpa-diterima')$$,
  'wajib menyebut uang yang diterima',
  'tunai tanpa uang diterima ditolak');
select uji.harap_gagal_sebab(
  $$select public.bayar_pesanan('eeee0000-0000-0000-0000-000000000010',
        (select id from public.metode_bayar
          where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai'),
        30000, 20000, null, 'bayar-tunai-kurang')$$,
  'Uang diterima \(20000\) lebih kecil',
  'uang diterima lebih kecil dari jumlah ditolak');

-- 6. Pembayaran SEBAGIAN (30.000 dari 62.100) dengan uang lebih: kembalian = 20.000
--    dihitung peladen, dan pesanan BELUM lunas.
select uji.sama(
  (select (public.bayar_pesanan('eeee0000-0000-0000-0000-000000000010',
        (select id from public.metode_bayar
          where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai'),
        30000, 50000, null, 'bayar-sebagian-1') ->> 'berhasil')::boolean),
  true, 'balasan RPC memakai amplop TECH_SPEC §5 (berhasil/kode/pesan)');
select uji.sama(
  (select (public.bayar_pesanan('eeee0000-0000-0000-0000-000000000010',
        (select id from public.metode_bayar
          where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai'),
        30000, 50000, null, 'bayar-sebagian-1') ->> 'kembalian')::integer),
  20000, 'kembalian dihitung peladen: 50.000 − 30.000 = 20.000');
select uji.sama(
  (select pb.kembalian from public.pembayaran pb
    where pb.pesanan_id = 'eeee0000-0000-0000-0000-000000000010' and pb.kunci_idempoten = 'bayar-sebagian-1'),
  20000, 'kembalian yang TERSIMPAN di baris pembayaran = 20.000 (balasan RPC bukan karangan)');
select uji.sama(
  (select (public.total_dibayar('eeee0000-0000-0000-0000-000000000010'))::integer),
  30000, 'total dibayar 30.000 setelah pembayaran sebagian');
select uji.sama(
  (select p.status from public.pesanan p where p.id = 'eeee0000-0000-0000-0000-000000000010'),
  'dikirim', 'pesanan belum lunas saat uang belum tertutup');
select uji.sama(
  (select p.dibayar_pada is null from public.pesanan p where p.id = 'eeee0000-0000-0000-0000-000000000010'),
  true, 'stempel dibayar_pada belum diisi saat belum lunas');

-- 7. DOBEL TEKAN: kunci idempoten sama → uang tidak bertambah, baris tidak dobel.
select uji.sama(
  (select (public.bayar_pesanan('eeee0000-0000-0000-0000-000000000010',
        (select id from public.metode_bayar
          where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai'),
        30000, 50000, null, 'bayar-sebagian-1') ->> 'dobel')::boolean),
  true, 'ulangan kunci yang sama ditandai dobel');
select uji.sama(
  (select (public.total_dibayar('eeee0000-0000-0000-0000-000000000010'))::integer),
  30000, 'dobel tekan tidak menambah uang');
select uji.sama(
  (select count(*) from public.pembayaran where pesanan_id = 'eeee0000-0000-0000-0000-000000000010'),
  1::bigint, 'dobel tekan tidak membuat baris kedua');

-- 8. Non-tunai tanpa referensi ditolak; dengan referensi sah (metode berbeda).
select uji.harap_gagal_sebab(
  $$select public.bayar_pesanan('eeee0000-0000-0000-0000-000000000010',
        (select id from public.metode_bayar
          where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'QRIS'),
        1000, null, '   ', 'bayar-qris-tanpa-referensi')$$,
  'wajib menyebut nomor referensi',
  'non-tunai tanpa referensi ditolak (spasi saja tidak dihitung)');

-- 9. Melebihi total ditolak walau uang diterima besar (sisa tagihan 32.100).
select uji.harap_gagal_sebab(
  $$select public.bayar_pesanan('eeee0000-0000-0000-0000-000000000010',
        (select id from public.metode_bayar
          where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai'),
        40000, 100000, null, 'bayar-lebih')$$,
  'BY-301',
  'pembayaran melebihi total pesanan ditolak oleh pintu RPC (bukan penjaga lapisan bawah)');

-- 10. Pembayaran PENUTUP lewat QRIS (32.100) → pesanan LUNAS + stempel waktu.
select uji.sama(
  (select (public.bayar_pesanan('eeee0000-0000-0000-0000-000000000010',
        (select id from public.metode_bayar
          where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'QRIS'),
        32100, null, 'QRIS-8899-0011', 'bayar-penutup') ->> 'lunas')::boolean),
  true, 'pembayaran penutup menandai lunas di balasan RPC');
select uji.sama(
  (select p.status from public.pesanan p where p.id = 'eeee0000-0000-0000-0000-000000000010'),
  'lunas', 'status pesanan menjadi lunas tepat saat total tertutup');
select uji.sama(
  (select p.dibayar_pada is not null from public.pesanan p where p.id = 'eeee0000-0000-0000-0000-000000000010'),
  true, 'stempel dibayar_pada terisi saat lunas');
select uji.sama(
  (select pb.referensi from public.pembayaran pb
    where pb.pesanan_id = 'eeee0000-0000-0000-0000-000000000010' and pb.kunci_idempoten = 'bayar-penutup'),
  'QRIS-8899-0011', 'referensi non-tunai tercatat apa adanya');
select uji.sama(
  (select pb.kasir_id from public.pembayaran pb
    where pb.pesanan_id = 'eeee0000-0000-0000-0000-000000000010' and pb.kunci_idempoten = 'bayar-penutup'),
  '90000000-0000-0000-0000-000000000004', 'kasir pencatat diisi sistem dari identitas masuk');

-- 11. Sesudah lunas pesanan beku bagi perangkat (pagar 0022 tetap bekerja).
select uji.harap_gagal_sebab(
  $$insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
    values ('eeee0000-0000-0000-0000-000000000010', 'beef0000-0000-0000-0000-000000000001',
            'Nasi Goreng', 27000, 1, 27000)$$,
  'BY-201',
  'pesanan lunas beku: tambah baris sesudah bayar ditolak');

-- 12a. Perangkat tidak bisa menulis jejak audit sendiri (hanya jalur peladen).
select uji.harap_gagal_sebab(
  $$insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas)
    values ('11111111-1111-1111-1111-111111111111',
            '90000000-0000-0000-0000-000000000004', 'bayar_pesanan', 'pembayaran')$$,
  'row-level security policy|permission denied',
  'kasir tidak boleh menulis baris audit sendiri');

-- 12b. Pesanan yang totalnya belum dihitung tidak bisa dibayar (K-1, migrasi 0015).
select uji.harap_gagal_sebab(
  $$select public.bayar_pesanan('00000000-0000-0000-0000-00000000c002',
        (select id from public.metode_bayar
          where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai'),
        1000, 1000, null, 'bayar-tanpa-total')$$,
  'belum dihitung',
  'pesanan tanpa total ditolak (uang tidak boleh mendahului hitung_total)');
reset role;

-- 13. Jejak audit: tertulis untuk SETIAP pembayaran baru (dobel tekan tidak menambah
--     jejak) dan rantai hash tetap utuh. Dibaca sebagai owner pusat karena kebijakan
--     `catatan_audit_pilih` hanya membuka audit bagi pemegang izin kelola_pegawai.
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner pusat
set local role authenticated;
select uji.sama(
  (select count(*) from public.catatan_audit
    where aksi = 'bayar_pesanan' and pelaku_id = '90000000-0000-0000-0000-000000000004'),
  2::bigint, 'dua pembayaran baru = dua baris audit (dobel tekan tidak menambah jejak)');
select uji.sama(
  (select count(*) from public.catatan_audit
    where aksi = 'bayar_pesanan' and (nilai_baru ->> 'lunas')::boolean
      and (nilai_baru ->> 'jumlah')::integer = 32100),
  1::bigint, 'tepat satu baris audit menandai pembayaran penutup 32.100 (lunas)');
select uji.sama(
  (select count(*) from public.catatan_audit
    where aksi = 'bayar_pesanan' and not (nilai_baru ->> 'lunas')::boolean
      and (nilai_baru ->> 'jumlah')::integer = 30000),
  1::bigint, 'pembayaran sebagian tercatat di audit sebagai belum lunas');
select uji.sama(
  (select (nilai_baru ->> 'kembalian')::integer from public.catatan_audit
    where aksi = 'bayar_pesanan' and (nilai_baru ->> 'jumlah')::integer = 30000),
  20000, 'jejak audit menyimpan kembalian yang sama dengan baris pembayaran');
select uji.sama(
  (select r.valid from public.verifikasi_rantai_audit('11111111-1111-1111-1111-111111111111') r),
  true, 'rantai hash audit tetap utuh setelah bayar_pesanan menulis jejak');
reset role;

-- 14. Pesanan resto lain: "tidak ditemukan" (tidak membocorkan keberadaannya) dan
--     uangnya tidak tersentuh.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.bayar_pesanan('00000000-0000-0000-0000-00000000c001',
        (select id from public.metode_bayar
          where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai'),
        20000, 20000, null, 'bayar-lintas-resto')$$,
  'Pesanan tidak ditemukan',
  'pesanan resto lain dilaporkan tidak ditemukan (bukan bocor)');
reset role;
select uji.sama(
  (select count(*) from public.pembayaran where pesanan_id = '00000000-0000-0000-0000-00000000c001'),
  0::bigint, 'tidak ada uang tercatat pada pesanan resto lain');
