-- ============================================================================
-- BUKTI VERIFIKASI TEMUAN AUDIT — sesi kerja, 2026-09-17
--
-- Cara pakai:  node alat/uji-sql.mjs docs/uji/audit/bukti-verifikasi-2026-09-17.sql
-- Status: JALAN & LOLOS pada commit 417b658 (SEBELUM perbaikan).
--
-- Isi berkas ini: 9 pemeriksaan yang MEMBUKTIKAN cacat K-1/K-2 yang dilaporkan
-- auditor AUD-3 (02 laporan) benar-benar ada — dijalankan sendiri oleh sesi kerja,
-- bukan mempercayai laporan begitu saja.
--
-- PENTING: berkas ini MENGUNCI PERILAKU BURUK yang berlaku hari ini. Sesudah cacat
-- diperbaiki, berkas ini WAJIB pindah ke `supabase/tes/` dengan harapan dibalik
-- (ditolak/0 baris). Selama belum dipindah, ia berfungsi sebagai barang bukti.
-- ============================================================================

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
insert into public.pembayaran (id, pesanan_id, metode_nama_saat_itu, jenis_saat_itu, jumlah, diterima, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000b002', '00000000-0000-0000-0000-00000000b001',
        'Tunai', 'tunai', 777000, 777000, 'verifikasi-bayar-resto-b');

-- ---------------------------------------------------------------- sebagai KASIR A
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- [1] F-04/F-03 (K-1, dua laporan): hak kolom pin_hash terbuka bagi peran terautentikasi
select uji.sama(has_column_privilege('authenticated', 'public.pengguna', 'pin_hash', 'select'),
                true, 'K-2: peran authenticated PUNYA hak baca kolom pin_hash');

-- [2] F-01/F-07 (K-2): ganti PIN sendiri TANPA PIN lama, lewat p_pengguna_id = uuid sendiri
select uji.sama(public.simpan_pin('8888', null, '90000000-0000-0000-0000-000000000004', 'hp-uji'),
                'PIN tersimpan.',
                'K-2: simpan_pin tanpa PIN lama untuk DIRI SENDIRI diterima (cacat)');

-- [3] K-1: kebocoran uang lintas resto lewat total_dibayar(uuid) SECURITY DEFINER
select uji.harap((select public.total_dibayar('00000000-0000-0000-0000-00000000b001')) > 0,
                 'K-1: kasir resto A membaca total pembayaran pesanan RESTO B (bocor)');

-- [4] K-1: kebocoran izin & batas diskon lintas resto lewat izin_efektif_untuk
select uji.harap((select count(*) from public.izin_efektif_untuk('90000000-0000-0000-0000-000000000007', 'beri_diskon', null)) = 1,
                 'K-1: kasir resto A membaca izin/batas diskon pengguna RESTO B (bocor)');

-- [5] K-1: pembayaran melebihi total diterima saat total masih 0
select uji.harap((select count(*) from public.pembayaran where pesanan_id = '00000000-0000-0000-0000-00000000a001') = 0, 'mulai dari nol');
insert into public.pembayaran (pesanan_id, metode_nama_saat_itu, jenis_saat_itu, jumlah, diterima, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000a001', 'Tunai', 'tunai', 1000000, 1000000, 'verifikasi-lebih-1');
insert into public.pembayaran (pesanan_id, metode_nama_saat_itu, jenis_saat_itu, jumlah, diterima, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000a001', 'Tunai', 'tunai', 1000000, 1000000, 'verifikasi-lebih-2');
select uji.sama((select coalesce(sum(jumlah), 0)::int from public.pembayaran where pesanan_id = '00000000-0000-0000-0000-00000000a001'),
                2000000, 'K-1: 2.000.000 DITERIMA untuk pesanan bertotal 0 (cacat)');

-- [6] K-2: atribusi pelaku bisa dipalsukan klien (kasir_id diisi nama owner)
select uji.sama((select kasir_id from public.pembayaran where kunci_idempoten = 'verifikasi-lebih-1'),
                '90000000-0000-0000-0000-000000000004'::uuid, 'kontrol: kasir_id terisi otomatis');
insert into public.pembayaran (pesanan_id, metode_nama_saat_itu, jenis_saat_itu, jumlah, diterima, kasir_id, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000a001', 'Tunai', 'tunai', 1000, 1000, '90000000-0000-0000-0000-000000000002', 'verifikasi-atribusi');
select uji.sama((select kasir_id from public.pembayaran where kunci_idempoten = 'verifikasi-atribusi'),
                '90000000-0000-0000-0000-000000000002'::uuid,
                'K-2: kasir menuliskan nama OWNER sebagai kasir pembayaran (cacat, jejak palsu)');

-- [7] K-2 (B F-06): batas PERSEN diskon dilewati dengan mengosongkan kolom persen.
-- Kontrol: batas kasir = 25.000 nominal / 5 persen. Diskon 20.000 pada pesanan subtotal 54.000 = 37% → harus DITOLAK.
select uji.sama((select batas_persen from public.izin_efektif_untuk('90000000-0000-0000-0000-000000000004', 'beri_diskon', 'a1a1a1a1-0000-0000-0000-000000000001')),
                5::numeric, 'kontrol: batas kasir 25.000 / 5 persen');
select uji.harap_gagal(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'manual', 37, 20000, 20000, 'uji batas persen')$$,
  'kontrol: diskon 37 persen DITOLAK bila kolom persen diisi jujur');
insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
  values ('eeee0000-0000-0000-0000-000000000010', 'manual', null, 20000, 20000, 'uji batas persen kosong');
select uji.sama(
  (select nilai from public.diskon_transaksi where pesanan_id = 'eeee0000-0000-0000-0000-000000000010' and nilai = 20000),
  20000, 'K-2: diskon 37 persen DITERIMA saat kolom persen dikosongkan (cacat)');

-- [8] K-2: status pesanan bisa dipindahkan klien (lunas tanpa uang)
select uji.sama((select status from public.pesanan where id = '00000000-0000-0000-0000-00000000a001'), 'draf', 'mulai dari draf');
update public.pesanan set status = 'lunas' where id = '00000000-0000-0000-0000-00000000a001';
select uji.sama((select status from public.pesanan where id = '00000000-0000-0000-0000-00000000a001'),
                'lunas', 'K-2: kasir memindahkan status pesanan sendiri menjadi lunas (cacat)');

-- [9] K-2 (A F-06): penjaga stok dilewati dengan peubah sesi yang bisa dipasang klien
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000006');   -- dapur (izin ubah_stok)
set local role authenticated;
select uji.sama((select count(*) from public.stok_bahan where id = 'beef1000-0000-0000-0000-000000000001'),
                1::bigint, 'kontrol: dapur melihat baris stoknya');
select uji.harap_gagal($$update public.stok_bahan set jumlah = 999 where id = 'beef1000-0000-0000-0000-000000000001'$$,
                       'kontrol: ubah stok langsung DITOLAK tanpa penanda buku besar');
select set_config('app.stok_dari_buku_besar', '1', true);
update public.stok_bahan set jumlah = 999 where id = 'beef1000-0000-0000-0000-000000000001';
select uji.sama((select jumlah::int from public.stok_bahan where id = 'beef1000-0000-0000-0000-000000000001'),
                999, 'K-2: penjaga stok dilewati dengan set_config klien (cacat)');
reset role;
