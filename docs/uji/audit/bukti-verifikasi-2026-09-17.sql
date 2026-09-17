-- ============================================================================
-- BUKTI VERIFIKASI TEMUAN AUDIT — sesi kerja, 2026-09-17
--
-- Cara pakai:  node alat/uji-sql.mjs docs/uji/audit/bukti-verifikasi-2026-09-17.sql
-- Status: JALAN & LOLOS pada commit sesudah perbaikan K-1 dan K-2a.
--
-- Isi berkas ini: pemeriksaan yang MEMBUKTIKAN temuan auditor AUD-3 benar-benar ada,
-- dijalankan sendiri oleh sesi kerja (bukan mempercayai laporan). Dibagi dua:
--   A. Sudah diperbaiki → pemeriksaan di sini mengunci PERILAKU BENAR
--      (uji regresi permanennya ada di `supabase/tes/gerbang_uang.sql` dan
--       `supabase/tes/isolasi_lintas_penyewa.sql`, dijalankan setiap CI).
--   B. Belum diperbaiki (K-2 sisa: status pesanan & penjaga stok) → pemeriksaan di sini
--      mengunci perilaku buruk yang MASIH berlaku sebagai barang bukti; bagian ini
--      dipindahkan/dibalik begitu perbaikannya mendarat.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- BAGIAN A. TEMUAN K-1 YANG SUDAH DIPERBAIKI (2026-09-17)
-- ---------------------------------------------------------------------------

-- Data uji: pesanan bertotal 0 (resto A) + satu pesanan & pembayaran milik RESTO B.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status,
                            subtotal, pajak, service, total, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000a001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 91, current_date, 'dinein', 'draf',
        0, 0, 0, 0, 'verifikasi-total-nol');
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status,
                            subtotal, pajak, service, total, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000b001', '22222222-2222-2222-2222-222222222222',
        'b1b1b1b1-0000-0000-0000-000000000001', 92, current_date, 'dinein', 'draf',
        0, 0, 0, 0, 'verifikasi-resto-b');
update public.pesanan set subtotal = 777000, total = 777000
 where id = '00000000-0000-0000-0000-00000000b001';
insert into public.pembayaran (id, pesanan_id, metode_nama_saat_itu, jenis_saat_itu, jumlah, diterima, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000b002', '00000000-0000-0000-0000-00000000b001',
        'Tunai', 'tunai', 777000, 777000, 'verifikasi-bayar-resto-b');

-- ---------------------------------------------------------------- sebagai KASIR A
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- [1] K-1: kebocoran uang lintas resto lewat total_dibayar(uuid) — DITUTUP
select uji.sama(public.total_dibayar('00000000-0000-0000-0000-00000000b001'), 0,
                'K-1 tertutup: kasir resto A membaca 0 untuk pesanan RESTO B (dulu 777.000)');

-- [2] K-1: pintu izin pegawai lain tidak lagi bisa dipanggil klien — DITUTUP
select uji.harap_gagal(
  $$select * from public.izin_efektif_untuk('90000000-0000-0000-0000-000000000007', 'beri_diskon')$$,
  'K-1 tertutup: izin_efektif_untuk tidak bisa dipanggil klien');
select uji.harap_gagal(
  $$select public.boleh_untuk('90000000-0000-0000-0000-000000000007', 'beri_diskon')$$,
  'K-1 tertutup: boleh_untuk tidak bisa dipanggil klien');

-- [3] K-1: pembayaran pada pesanan yang totalnya belum dihitung — DITOLAK
select uji.harap_gagal(
  $$insert into public.pembayaran (pesanan_id, metode_id, jumlah, diterima, kunci_idempoten)
      select '00000000-0000-0000-0000-00000000a001', mb.id, 1000000, 1000000, 'verifikasi-lebih-1'
        from public.metode_bayar mb
       where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'Tunai'$$,
  'K-1 tertutup: Rp1.000.000 untuk pesanan bertotal 0 DITOLAK (dulu diterima dua kali)');
select uji.sama(
  (select coalesce(sum(jumlah), 0)::int from public.pembayaran
    where pesanan_id = '00000000-0000-0000-0000-00000000a001'),
  0, 'K-1 tertutup: tidak ada uang tercatat untuk pesanan bertotal 0');

-- [4] K-2a: rahasia PIN tidak lagi di tabel yang bisa dibaca klien — DITUTUP
select uji.sama(
  (select count(*) from information_schema.columns
    where table_schema = 'public' and table_name = 'pengguna' and column_name = 'pin_hash'),
  0::bigint, 'K-2a tertutup: kolom pin_hash TIDAK ada lagi di public.pengguna (pindah ke kredensial_pin)');
select uji.sama(has_table_privilege('authenticated', 'public.kredensial_pin', 'select'), false,
                'K-2a tertutup: peran authenticated tidak punya hak baca kredensial_pin');
select uji.harap_gagal($$select pin_hash from public.kredensial_pin$$,
                       'K-2a tertutup: kasir tidak bisa membaca kredensial_pin');

-- [5] K-2a: ganti PIN sendiri WAJIB PIN lama — DITUTUP.
-- Pemasangan PIN PERTAMA memang boleh tanpa PIN lama (memang belum punya), jadi yang diuji
-- adalah penggantian: owner memasang PIN awal dulu, baru kasir mencoba menggantinya.
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner
set local role authenticated;
select uji.sama(public.simpan_pin('2468', null, '90000000-0000-0000-0000-000000000004'),
                'PIN tersimpan.', 'kontrol: owner memasang PIN awal kasir');
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir
set local role authenticated;
select uji.harap_gagal(
  $$select public.simpan_pin('8888', null, '90000000-0000-0000-0000-000000000004')$$,
  'K-2a tertutup: simpan_pin tanpa PIN lama untuk DIRI SENDIRI ditolak');
select uji.sama(public.simpan_pin('8888', '2468', '90000000-0000-0000-0000-000000000004'),
                'PIN tersimpan.', 'kontrol: ganti PIN tetap bisa bila PIN lama benar');

-- [6] K-2a: jejak pelaku diisi sistem, tidak bisa dikarang — DITUTUP
select uji.harap_gagal(
  $$insert into public.pembayaran (pesanan_id, metode_id, jumlah, diterima, kasir_id, kunci_idempoten)
      select 'eeee0000-0000-0000-0000-000000000010', mb.id, 1000, 1000,
             '90000000-0000-0000-0000-000000000002', 'verifikasi-atribusi'
        from public.metode_bayar mb
       where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'Tunai'$$,
  'K-2a tertutup: kasir tidak bisa menuliskan nama OWNER sebagai kasir pembayaran');

-- [7] K-2a: batas PERSEN diskon dihitung dari uang — DITUTUP
select uji.harap_gagal(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'manual', null, 20000, 20000, 'uji persen kosong')$$,
  'K-2a tertutup: diskon 37 persen ditolak walau kolom persen dikosongkan');

reset role;
select uji.klaim(null);

-- ---------------------------------------------------------------------------
-- BAGIAN B. TEMUAN K-2 YANG BELUM DIPERBAIKI (barang bukti, jangan dibalik dulu)
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------- sebagai KASIR A
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- [8] K-2: status pesanan bisa dipindahkan klien (lunas tanpa uang)
select uji.sama(
  (select status from public.pesanan where id = '00000000-0000-0000-0000-00000000a001'),
  'draf', 'mulai dari draf');
update public.pesanan set status = 'lunas' where id = '00000000-0000-0000-0000-00000000a001';
select uji.sama(
  (select status from public.pesanan where id = '00000000-0000-0000-0000-00000000a001'),
  'lunas', 'K-2 MASIH TERBUKA: kasir memindahkan status pesanan sendiri menjadi lunas');

reset role;
select uji.klaim(null);

-- [9] K-2: penjaga stok dilewati dengan peubah sesi yang bisa dipasang klien
select uji.klaim('90000000-0000-0000-0000-000000000006');   -- dapur (izin ubah_stok)
set local role authenticated;
select uji.sama((select count(*) from public.stok_bahan where id = 'beef1000-0000-0000-0000-000000000001'),
                1::bigint, 'kontrol: dapur melihat baris stoknya');
select uji.harap_gagal(
  $$update public.stok_bahan set jumlah = 999 where id = 'beef1000-0000-0000-0000-000000000001'$$,
  'kontrol: ubah stok langsung DITOLAK tanpa penanda buku besar');
select set_config('app.stok_dari_buku_besar', '1', true);
update public.stok_bahan set jumlah = 999 where id = 'beef1000-0000-0000-0000-000000000001';
select uji.sama(
  (select jumlah::int from public.stok_bahan where id = 'beef1000-0000-0000-0000-000000000001'),
  999, 'K-2 MASIH TERBUKA: penjaga stok dilewati dengan set_config klien');
reset role;
