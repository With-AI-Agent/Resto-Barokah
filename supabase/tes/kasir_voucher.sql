-- ============================================================================
-- UJI T8-09 — LAYAR KASIR: CEK (BACA SAJA) & PAKAI (ATOMIK + PIN) VOUCHER ⚠️
-- ----------------------------------------------------------------------------
-- Target DoD:
--   1. Tombol Cek tidak mengubah apa pun (baca saja, dibuktikan uji).
--   2. Pakai wajib PIN kasir/atasan berizin.
--   3. Hasil jelas (berhasil + rincian potongan / gagal + sebab spesifik).
--   4. Potongan dihitung dari aturan kampanye.
--   5. Uji vitest + uji SQL pakai voucher lolos 100%.
-- ============================================================================

-- Persiapan Akun & Kredensial PIN Kasir
-- Kasir Rina: 90000000-0000-0000-0000-000000000004 di cabang a1a1a1a1-...-0001
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000004', crypt('1234', gen_salt('bf', 8)))
on conflict (pengguna_id) do update set pin_hash = crypt('1234', gen_salt('bf', 8));

-- Pastikan izin pakai_voucher tersedia untuk peran kasir
insert into public.izin (pengguna_id, kode_izin, boleh)
values ('90000000-0000-0000-0000-000000000004', 'pakai_voucher', true)
on conflict (pengguna_id, kode_izin) do update set boleh = true;

-- Pastikan pengaturan resto: tumpuk_diskon default false (PRD M10 ART-5)
update public.pengaturan
   set tumpuk_diskon = false,
       batas_maks_potongan_persen = 100,
       batas_maks_potongan_nominal = null
 where penyewa_id = '11111111-1111-1111-1111-111111111111';

-- Buat Kampanye Uji: Diskon 20% maks 20.000, min belanja 50.000
insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, maks_potongan, min_belanja, kuota, mulai, selesai, aktif
) values (
  'c0000000-0000-0000-0000-000000000001',
  '11111111-1111-1111-1111-111111111111',
  'Promo Makan Hemat 20%',
  'HEMAT20',
  'persen',
  20,
  20000,
  50000,
  100,
  now() - interval '1 day',
  now() + interval '7 days',
  true
) on conflict (id) do nothing;

-- Buat Kampanye Nominal: Diskon 15.000, min belanja 40.000
insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, maks_potongan, min_belanja, kuota, mulai, selesai, aktif
) values (
  'c0000000-0000-0000-0000-000000000002',
  '11111111-1111-1111-1111-111111111111',
  'Voucher Potongan 15K',
  'DISKON15K',
  'nominal',
  15000,
  null,
  40000,
  50,
  now() - interval '1 day',
  now() + interval '7 days',
  true
) on conflict (id) do nothing;

-- Kampanye Kedaluwarsa
insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, maks_potongan, min_belanja, kuota, mulai, selesai, aktif
) values (
  'c0000000-0000-0000-0000-000000000003',
  '11111111-1111-1111-1111-111111111111',
  'Promo Masa Lalu',
  'MASALALU',
  'nominal',
  10000,
  null,
  20000,
  10,
  now() - interval '10 days',
  now() - interval '1 day',
  true
) on conflict (id) do nothing;

-- Buat Pelanggan Uji
insert into public.pelanggan (
  id, penyewa_id, nama, email, email_normalisasi, telepon, cara_masuk, persetujuan_privasi
) values (
  '88000000-0000-0000-0000-000000000001',
  '11111111-1111-1111-1111-111111111111',
  'Budi Santoso',
  'budi@contoh.id',
  'budi@contoh.id',
  '081234567890',
  'email',
  true
) on conflict (id) do nothing;

-- Voucher Uji 1: Aktif persen HEMAT20
insert into public.voucher (
  id, penyewa_id, kampanye_id, pelanggan_id, kode, status, berlaku_sampai
) values (
  '77000000-0000-0000-0000-000000000001',
  '11111111-1111-1111-1111-111111111111',
  'c0000000-0000-0000-0000-000000000001',
  '88000000-0000-0000-0000-000000000001',
  'VC-HEMAT-01',
  'aktif',
  now() + interval '3 days'
) on conflict (id) do nothing;

-- Voucher Uji 2: Aktif nominal DISKON15K
insert into public.voucher (
  id, penyewa_id, kampanye_id, pelanggan_id, kode, status, berlaku_sampai
) values (
  '77000000-0000-0000-0000-000000000002',
  '11111111-1111-1111-1111-111111111111',
  'c0000000-0000-0000-0000-000000000002',
  '88000000-0000-0000-0000-000000000001',
  'VC-NOM15-02',
  'aktif',
  now() + interval '3 days'
) on conflict (id) do nothing;

-- Voucher Uji 3: Kedaluwarsa
insert into public.voucher (
  id, penyewa_id, kampanye_id, pelanggan_id, kode, status, berlaku_sampai
) values (
  '77000000-0000-0000-0000-000000000003',
  '11111111-1111-1111-1111-111111111111',
  'c0000000-0000-0000-0000-000000000003',
  '88000000-0000-0000-0000-000000000001',
  'VC-EXPIRE-03',
  'kedaluwarsa',
  now() - interval '1 day'
) on conflict (id) do nothing;

-- ============================================================================
-- BAGIAN 1: CEK VOUCHER (BACA SAJA — MEMBUKTIKAN STATUS TIDAK BERUBAH)
-- ============================================================================

-- Simulasikan kasir login
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- 1.1 Cek kode fiktif yang tidak ada
select uji.sama(
  (public.cek_voucher('KODE-FIKTIF-999', 'a1a1a1a1-0000-0000-0000-000000000001', 60000)->>'berhasil')::boolean,
  false,
  '1.1 Cek kode fiktif mengembalikan berhasil = false'
);
select uji.sama(
  public.cek_voucher('KODE-FIKTIF-999', 'a1a1a1a1-0000-0000-0000-000000000001', 60000)->>'kode',
  'VOUCHER_TIDAK_DITEMUKAN',
  '1.1 Kode galat VOUCHER_TIDAK_DITEMUKAN'
);

-- 1.2 Cek voucher sah: Status di DB HARUS TETAP 'aktif' (baca saja)
select uji.sama(
  (public.cek_voucher('VC-HEMAT-01', 'a1a1a1a1-0000-0000-0000-000000000001', 100000)->>'berhasil')::boolean,
  true,
  '1.2 Cek voucher sah mengembalikan berhasil = true'
);

-- 1.3 Perhitungan estimasi potongan persen (20% dari 100.000 = 20.000)
select uji.sama(
  (public.cek_voucher('VC-HEMAT-01', 'a1a1a1a1-0000-0000-0000-000000000001', 100000)->'data'->>'estimasi_potongan')::numeric,
  20000::numeric,
  '1.3 Estimasi potongan persen dihitung tepat dari subtotal dan batas maks'
);

-- 1.4 Estimasi potongan terpotong plafon maks (20% dari 200.000 = 40.000 -> dipotong ke maks 20.000)
select uji.sama(
  (public.cek_voucher('VC-HEMAT-01', 'a1a1a1a1-0000-0000-0000-000000000001', 200000)->'data'->>'estimasi_potongan')::numeric,
  20000::numeric,
  '1.4 Estimasi potongan persen dibatasi batas maks potongan kampanye'
);

-- 1.5 Cek dengan subtotal kurang dari minimum belanja
select uji.sama(
  (public.cek_voucher('VC-HEMAT-01', 'a1a1a1a1-0000-0000-0000-000000000001', 30000)->>'berhasil')::boolean,
  false,
  '1.5 Subtotal kurang dari minimum belanja ditolak saat cek'
);
select uji.sama(
  public.cek_voucher('VC-HEMAT-01', 'a1a1a1a1-0000-0000-0000-000000000001', 30000)->>'kode',
  'SUBTOTAL_KURANG',
  '1.5 Kode galat SUBTOTAL_KURANG'
);

-- 1.6 BUKTI KUAT BACA SAJA: Baris voucher di database sama sekali tidak berubah!
select uji.sama(
  (select v.status from public.voucher v where v.kode = 'VC-HEMAT-01'),
  'aktif',
  '1.6 BUKTI BACA SAJA: status voucher di tabel tetap aktif setelah operasi cek'
);
select uji.sama(
  (select v.terpakai_pada is null from public.voucher v where v.kode = 'VC-HEMAT-01'),
  true,
  '1.6 BUKTI BACA SAJA: terpakai_pada tetap null'
);

-- 1.7 Cek voucher kedaluwarsa ditolak
select uji.sama(
  (public.cek_voucher('VC-EXPIRE-03', 'a1a1a1a1-0000-0000-0000-000000000001', 50000)->>'berhasil')::boolean,
  false,
  '1.7 Cek voucher kedaluwarsa mengembalikan false'
);
select uji.sama(
  public.cek_voucher('VC-EXPIRE-03', 'a1a1a1a1-0000-0000-0000-000000000001', 50000)->>'kode',
  'VOUCHER_KEDALUWARSA',
  '1.7 Kode galat VOUCHER_KEDALUWARSA'
);

-- ============================================================================
-- BAGIAN 2: PAKAI VOUCHER (ATOMIK + PIN KASIR + ATURAN KAMPANYE)
-- ============================================================================

-- Siapkan pesanan uji
-- Pesanan 1: eeee0000-0000-0000-0000-000000000010 subtotal 54.000
-- 2.1 Pakai voucher dengan PIN SALAH wajib ditolak
select uji.sama(
  (public.pakai_voucher('eeee0000-0000-0000-0000-000000000010', 'VC-NOM15-02', '9999')->>'berhasil')::boolean,
  false,
  '2.1 Pakai voucher dengan PIN salah mengembalikan berhasil = false'
);
select uji.sama(
  public.pakai_voucher('eeee0000-0000-0000-0000-000000000010', 'VC-NOM15-02', '9999')->>'kode',
  'PIN_SALAH',
  '2.1 Kode galat PIN_SALAH'
);

-- Bukti percobaan PIN gagal tercatat di audit percobaan_pin
select uji.sama(
  (select count(*) > 0 from public.percobaan_pin pp where pp.pengguna_id = '90000000-0000-0000-0000-000000000004' and not pp.berhasil and pp.aksi = 'pakai_voucher'),
  true,
  '2.1 Percobaan PIN kasir salah tercatat di audit percobaan_pin'
);

-- Voucher di database tidak terkonsumsi akibat PIN salah
select uji.sama(
  (select v.status from public.voucher v where v.kode = 'VC-NOM15-02'),
  'aktif',
  '2.1 Voucher tetap berstatus aktif setelah percobaan PIN salah'
);

-- 2.2 Pakai voucher nominal dengan PIN BENAR ('1234')
select uji.sama(
  (public.pakai_voucher('eeee0000-0000-0000-0000-000000000010', 'VC-NOM15-02', '1234')->>'berhasil')::boolean,
  true,
  '2.2 Pakai voucher nominal dengan PIN benar berhasil'
);

-- 2.3 Bukti voucher sekarang berstatus 'terpakai' dan terhubung ke pesanan
select uji.sama(
  (select v.status from public.voucher v where v.kode = 'VC-NOM15-02'),
  'terpakai',
  '2.3 Status voucher berubah menjadi terpakai'
);
select uji.sama(
  (select v.pesanan_id from public.voucher v where v.kode = 'VC-NOM15-02'),
  'eeee0000-0000-0000-0000-000000000010'::uuid,
  '2.3 Voucher terikat ke id pesanan yang bersangkutan'
);

-- 2.4 Bukti baris diskon_transaksi tercipta dan terisi lengkap
select uji.sama(
  (select count(*)::bigint from public.diskon_transaksi dt where dt.pesanan_id = 'eeee0000-0000-0000-0000-000000000010' and dt.jenis = 'voucher'),
  1::bigint,
  '2.4 Baris diskon_transaksi jenis voucher tercipta'
);
select uji.sama(
  (select dt.nilai from public.diskon_transaksi dt where dt.pesanan_id = 'eeee0000-0000-0000-0000-000000000010' and dt.jenis = 'voucher'),
  15000,
  '2.4 Nilai potongan diskon sesuai nominal kampanye (15.000)'
);

-- 2.5 Idempoten: Memanggil ulang pakai_voucher pada pesanan yang sama
select uji.sama(
  (public.pakai_voucher('eeee0000-0000-0000-0000-000000000010', 'VC-NOM15-02', '1234')->>'berhasil')::boolean,
  true,
  '2.5 Panggilan ulang pakai_voucher idempoten (berhasil)'
);
select uji.sama(
  public.pakai_voucher('eeee0000-0000-0000-0000-000000000010', 'VC-NOM15-02', '1234')->>'kode',
  'IDEMPOTEN',
  '2.5 Kode hasil IDEMPOTEN'
);

-- Pastikan diskon TIDAK digandakan (tetap hanya 1 baris di diskon_transaksi)
select uji.sama(
  (select count(*)::bigint from public.diskon_transaksi dt where dt.pesanan_id = 'eeee0000-0000-0000-0000-000000000010'),
  1::bigint,
  '2.5 Idempoten menjamin baris diskon tidak dobel'
);

-- ============================================================================
-- BAGIAN 3: ATOMIK & ANTI-DOBEL KLAIM (ART-5)
-- ============================================================================

-- Buat pesanan kedua untuk pengujian dobel klaim
reset role;
select uji.klaim(null);
insert into public.pesanan (
  id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten
) values (
  'eeee0000-0000-0000-0000-000000000099',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  99,
  current_date,
  'dinein',
  'draf',
  'kunci-pesanan-uji-99'
) on conflict (id) do nothing;

insert into public.pesanan_item (
  id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
) values (
  'eeee0000-0000-0000-0000-000000000199',
  'eeee0000-0000-0000-0000-000000000099',
  'beef0000-0000-0000-0000-000000000001',
  'Nasi Goreng Spesial',
  80000,
  1,
  80000
) on conflict (id) do nothing;

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- 3.1 Voucher yang sudah terpakai di pesanan 1 DITOLAK saat dipakai di pesanan 2
select uji.sama(
  (public.pakai_voucher('eeee0000-0000-0000-0000-000000000099', 'VC-NOM15-02', '1234')->>'berhasil')::boolean,
  false,
  '3.1 ART-5: Voucher terpakai ditolak saat dicoba pada transaksi lain'
);
select uji.sama(
  public.pakai_voucher('eeee0000-0000-0000-0000-000000000099', 'VC-NOM15-02', '1234')->>'kode',
  'VOUCHER_SUDAH_TERPAKAI',
  '3.1 Kode galat VOUCHER_SUDAH_TERPAKAI'
);

-- 3.2 Aturan larangan tumpuk diskon: pesanan 1 sudah memiliki diskon voucher VC-NOM15-02,
--     mencoba menambahkan voucher kedua VC-HEMAT-01 harus ditolak!
select uji.sama(
  (public.pakai_voucher('eeee0000-0000-0000-0000-000000000010', 'VC-HEMAT-01', '1234')->>'berhasil')::boolean,
  false,
  '3.2 Penolakan tumpuk diskon jika resto melarang multi-diskon'
);
select uji.sama(
  public.pakai_voucher('eeee0000-0000-0000-0000-000000000010', 'VC-HEMAT-01', '1234')->>'kode',
  'TUMPUK_DISKON_DILARANG',
  '3.2 Kode galat TUMPUK_DISKON_DILARANG'
);

-- 3.3 Pesanan kedua dapat menggunakan VC-HEMAT-01 dengan potongan persen presisi
select uji.sama(
  (public.pakai_voucher('eeee0000-0000-0000-0000-000000000099', 'VC-HEMAT-01', '1234')->>'berhasil')::boolean,
  true,
  '3.3 Pesanan 2 berhasil menggunakan voucher persen VC-HEMAT-01'
);

-- 20% dari 80.000 = 16.000 (tidak melebihi plafon maks 20.000)
select uji.sama(
  (select dt.nilai from public.diskon_transaksi dt where dt.pesanan_id = 'eeee0000-0000-0000-0000-000000000099' and dt.jenis = 'voucher'),
  16000,
  '3.3 Nilai diskon persen dihitung presisi (20% dari 80.000 = 16.000)'
);

-- Reset klaim & peran
reset role;
select uji.klaim(null);
