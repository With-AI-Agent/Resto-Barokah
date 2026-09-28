-- ============================================================================
-- supabase/tes/privasi.sql
-- Pengujian Privasi Pelanggan, Persetujuan & Anonimisasi UU PDP (T8-15)
-- Ref: PRD M10 & M12; TECH_SPEC §9 ART-14; docs/KEAMANAN.md §11; docs/PRIVASI_PELANGGAN.md
--
-- Kasus yang diuji:
-- 1. Pelanggan tanpa persetujuan privasi ditolak database (UU PDP Pasal 20).
-- 2. Pendaftaran pelanggan dengan persetujuan berhasil mencatat waktu dan versi kebijakan.
-- 3. Pelanggan memiliki transaksi keuangan dan voucher aktif.
-- 4. Percobaan anonimisasi oleh peran di luar wewenang atau beda penyewa ditolak.
-- 5. Fungsi anonimkan_pelanggan() menghapus kontak pribadi (nama disamarkan, email/telepon/alamat null).
-- 6. Catatan transaksi keuangan, voucher, dan diskon TETAP UTUH tanpa ada baris yang hilang.
-- 7. Jejak audit anonimisasi tercatat di catatan_audit dengan aman.
-- 8. Pemanggilan anonimisasi bersifat idempoten bila diulang.
-- 9. RPC cek_privasi_pelanggan mematuhi isolasi penyewa.
-- ============================================================================

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Penyiapan Data Uji
-- ----------------------------------------------------------------------------
do $$
declare
  v_penyewa uuid := '11111111-1111-1111-1111-111111111111';
  v_cabang  uuid := 'a1a1a1a1-0000-0000-0000-000000000001';
  v_kasir   uuid := '90000000-0000-0000-0000-000000000004';
  v_kampanye uuid := 'ca010000-0000-0000-0000-000000000001';
begin
  -- Pastikan kampanye voucher aktif tersedia
  insert into public.kampanye_voucher (
    id, penyewa_id, nama, kode_kampanye, jenis, nilai, min_belanja, maks_potongan,
    mulai, selesai, kuota, anggaran_maks, cabang_berlaku, aktif
  ) values (
    v_kampanye, v_penyewa, 'Promo Privasi Ramah', 'PRIVASI-RAMAH', 'nominal', 15000, 40000, null,
    now() - interval '1 day', now() + interval '30 days', 50, 5000000, '[]'::jsonb, true
  ) on conflict (penyewa_id, kode_kampanye) do nothing;

  -- Pastikan kasir memiliki izin pakai_voucher
  insert into public.izin (pengguna_id, kode_izin, boleh)
  values (v_kasir, 'pakai_voucher', true)
  on conflict (pengguna_id, kode_izin) do update set boleh = true;
end;
$$;

-- ----------------------------------------------------------------------------
-- Kasus 1: Pelanggan tanpa persetujuan privasi DITOLAK database
-- ----------------------------------------------------------------------------
select uji.harap_gagal_sebab(
  $$
  insert into public.pelanggan (
    id, penyewa_id, nama, email, telepon, cara_masuk, persetujuan_privasi
  ) values (
    'bb010000-0000-0000-0000-000000000001',
    '11111111-1111-1111-1111-111111111111',
    'Budi Tanpa Izin',
    'budi.tanpa.izin@gmail.com',
    '081234567891',
    'email',
    false
  );
  $$,
  'Persetujuan pemrosesan data pribadi',
  'Kasus 1: Pendaftaran tanpa persetujuan privasi ditolak database'
);

-- ----------------------------------------------------------------------------
-- Kasus 2: Pelanggan dengan persetujuan privasi berhasil tersimpan
-- ----------------------------------------------------------------------------
insert into public.pelanggan (
  id, penyewa_id, nama, email, telepon, alamat, cara_masuk, persetujuan_privasi, persetujuan_privasi_versi
) values (
  'bb010000-0000-0000-0000-000000000002',
  '11111111-1111-1111-1111-111111111111',
  'Siti Nurhaliza',
  'siti.nurhaliza.pdp@gmail.com',
  '081298765432',
  'Jl. Sukajadi No. 45, Bandung',
  'email',
  true,
  'v1.0'
);

select uji.harap(
  exists (
    select 1 from public.pelanggan
    where id = 'bb010000-0000-0000-0000-000000000002'
      and status_privasi = 'aktif'
      and persetujuan_privasi = true
      and persetujuan_privasi_versi = 'v1.0'
      and persetujuan_privasi_pada is not null
      and email_normalisasi = 'sitinurhalizapdp@gmail.com'
  ),
  'Kasus 2: Pelanggan tersimpan lengkap dengan persetujuan, waktu, dan versi kebijakan'
);

-- ----------------------------------------------------------------------------
-- Kasus 3: Buat data finansial & voucher untuk pelanggan Siti
-- ----------------------------------------------------------------------------
insert into public.voucher (
  id, penyewa_id, kampanye_id, pelanggan_id, kode, status, berlaku_sampai
) values (
  'cc010000-0000-0000-0000-000000000001',
  '11111111-1111-1111-1111-111111111111',
  'ca010000-0000-0000-0000-000000000001',
  'bb010000-0000-0000-0000-000000000002',
  'RB-SITI-V001',
  'aktif',
  now() + interval '14 days'
);

-- Buat pesanan dengan voucher
insert into public.pesanan (
  id, penyewa_id, cabang_id, tipe, status, kunci_idempoten
) values (
  'ce010000-0000-0000-0000-000000000001',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  'dinein',
  'draf',
  'kunci-pesanan-privasi-siti-01'
);

insert into public.pesanan_item (
  id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
) values (
  'cf010000-0000-0000-0000-000000000001',
  'ce010000-0000-0000-0000-000000000001',
  'beef0000-0000-0000-0000-000000000001',
  'Nasi Goreng Spesial',
  50000,
  1,
  50000
);

-- Tautkan voucher ke pesanan
update public.voucher
set
  status = 'terpakai',
  terpakai_pada = now(),
  terpakai_di_cabang = 'a1a1a1a1-0000-0000-0000-000000000001',
  terpakai_oleh = '90000000-0000-0000-0000-000000000004',
  pesanan_id = 'ce010000-0000-0000-0000-000000000001'
where id = 'cc010000-0000-0000-0000-000000000001';

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

insert into public.diskon_transaksi (
  id, pesanan_id, jenis, nominal, nilai, alasan, pelaku_id, voucher_id
) values (
  'cd010000-0000-0000-0000-000000000001',
  'ce010000-0000-0000-0000-000000000001',
  'voucher',
  15000,
  15000,
  'Voucher Promo Privasi Ramah RB-SITI-V001',
  '90000000-0000-0000-0000-000000000004',
  'cc010000-0000-0000-0000-000000000001'
);

reset role;
select uji.klaim(null);

select uji.harap(
  exists (
    select 1 from public.voucher
    where id = 'cc010000-0000-0000-0000-000000000001'
      and pelanggan_id = 'bb010000-0000-0000-0000-000000000002'
      and status = 'terpakai'
  ),
  'Kasus 3: Data transaksi finansial voucher terhubung ke pelanggan'
);

-- ----------------------------------------------------------------------------
-- Kasus 4: Otorisasi & Isolasi Anonimisasi
-- ----------------------------------------------------------------------------
-- Pelayan (90000000-0000-0000-0000-000000000005) mencoba menganonimkan -> ditolak
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$
  select public.anonimkan_pelanggan('bb010000-0000-0000-0000-000000000002', 'minta anonim');
  $$,
  'tidak memiliki wewenang',
  'Kasus 4a: Peran pelayan ditolak saat memanggil anonimkan_pelanggan'
);

reset role;
select uji.klaim(null);

-- Pengguna penyewa lain (90000000-0000-0000-0000-000000000007, Ujang di Resto Sebelah) -> ditolak
select uji.klaim('90000000-0000-0000-0000-000000000007');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$
  select public.anonimkan_pelanggan('bb010000-0000-0000-0000-000000000002', 'minta anonim');
  $$,
  'bukan milik penyewa Anda',
  'Kasus 4b: Penyewa lain ditolak saat memanggil anonimkan_pelanggan (isolasi tenant)'
);

reset role;
select uji.klaim(null);

-- Pengguna authenticated tanpa uid (auth.uid() null) -> ditolak
select uji.klaim(null);
set local role authenticated;

select uji.harap_gagal_sebab(
  $$
  select public.anonimkan_pelanggan('bb010000-0000-0000-0000-000000000002', 'minta anonim');
  $$,
  'Tidak diautentikasi',
  'Kasus 4c: Authenticated tanpa auth.uid() ditolak saat memanggil anonimkan_pelanggan'
);

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Kasus 5 & 6: Eksekusi Anonimkan Pelanggan (Kasir berwenang)
-- ----------------------------------------------------------------------------
-- Kasir Kedai Oasis (90000000-0000-0000-0000-000000000004)
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

do $$
declare
  v_hasil jsonb;
begin
  v_hasil := public.anonimkan_pelanggan(
    'bb010000-0000-0000-0000-000000000002',
    'Permintaan penghapusan data via meja kasir (UU PDP Pasal 8)'
  );

  if (v_hasil->>'sukses')::boolean is not true then
    raise exception 'Gagal mengeksekusi anonimkan_pelanggan: %', v_hasil;
  end if;
end;
$$;

reset role;
select uji.klaim(null);

-- Periksa hasil pembersihan kontak (Kasus 5)
select uji.harap(
  exists (
    select 1 from public.pelanggan
    where id = 'bb010000-0000-0000-0000-000000000002'
      and status_privasi = 'teranonimkan'
      and email is null
      and email_normalisasi is null
      and telepon is null
      and alamat is null
      and nama = 'Pelanggan Teranonimkan (UU PDP)'
      and dianonimkan_pada is not null
      and alasan_anonimisasi = 'Permintaan penghapusan data via meja kasir (UU PDP Pasal 8)'
  ),
  'Kasus 5: Kontak pelanggan (email, no HP, alamat) terhapus dan nama disamarkan'
);

-- Periksa keutuhan catatan keuangan (Kasus 6: voucher & diskon transaksi tidak boleh hilang)
select uji.harap(
  exists (
    select 1 from public.voucher
    where id = 'cc010000-0000-0000-0000-000000000001'
      and pelanggan_id = 'bb010000-0000-0000-0000-000000000002'
      and status = 'terpakai'
  ),
  'Kasus 6a: Catatan voucher tetap utuh dan tertaut ke ID pelanggan yang dianonimkan'
);

select uji.harap(
  exists (
    select 1 from public.diskon_transaksi
    where id = 'cd010000-0000-0000-0000-000000000001'
      and pesanan_id = 'ce010000-0000-0000-0000-000000000001'
      and nominal = 15000
  ),
  'Kasus 6b: Catatan diskon transaksi pesanan tetap utuh tanpa perubahan nilai'
);

-- ----------------------------------------------------------------------------
-- Kasus 7: Jejak Audit Kekal Anonimisasi
-- ----------------------------------------------------------------------------
select uji.harap(
  exists (
    select 1 from public.catatan_audit
    where aksi = 'anonimisasi_pelanggan'
      and entitas = 'pelanggan'
      and entitas_id = 'bb010000-0000-0000-0000-000000000002'
      and (nilai_baru->>'alasan') = 'Permintaan penghapusan data via meja kasir (UU PDP Pasal 8)'
  ),
  'Kasus 7: Jejak audit anonimisasi tersimpan permanen di catatan_audit'
);

-- ----------------------------------------------------------------------------
-- Kasus 8: Idempotensi Anonimisasi
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

do $$
declare
  v_hasil jsonb;
begin
  v_hasil := public.anonimkan_pelanggan(
    'bb010000-0000-0000-0000-000000000002',
    'Panggilan ulang kedua'
  );

  if (v_hasil->>'sukses')::boolean is not true or (v_hasil->>'idempoten')::boolean is not true then
    raise exception 'Panggilan idempoten gagal: %', v_hasil;
  end if;
end;
$$;

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Kasus 9: RPC cek_privasi_pelanggan mematuhi isolasi tenant
-- ----------------------------------------------------------------------------
-- Admin Kedai Oasis (90000000-0000-0000-0000-000000000002) membaca pelanggan Siti -> sukses
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.harap(
  (public.cek_privasi_pelanggan('bb010000-0000-0000-0000-000000000002')->>'status_privasi') = 'teranonimkan',
  'Kasus 9a: Admin penyewa berhasil mengecek status privasi pelanggan'
);

reset role;
select uji.klaim(null);

-- Admin/Kasir Resto Sebelah (90000000-0000-0000-0000-000000000007) membaca pelanggan Siti -> ditolak
select uji.klaim('90000000-0000-0000-0000-000000000007');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$
  select public.cek_privasi_pelanggan('bb010000-0000-0000-0000-000000000002');
  $$,
  'di luar wewenang',
  'Kasus 9b: Pengecekan privasi pelanggan penyewa lain ditolak (isolasi tenant)'
);

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Kasus 10: Pemicu picu_pelanggan_validasi_email otomatis membersihkan kontak
-- saat status_privasi diubah menjadi 'teranonimkan'
-- ----------------------------------------------------------------------------
insert into public.pelanggan (
  id, penyewa_id, nama, email, telepon, cara_masuk, persetujuan_privasi
) values (
  'bb010000-0000-0000-0000-000000000099',
  '11111111-1111-1111-1111-111111111111',
  'Pelanggan Uji Pemicu',
  'pemicu.privasi@gmail.com',
  '081299998888',
  'email',
  true
);

update public.pelanggan
set status_privasi = 'teranonimkan'
where id = 'bb010000-0000-0000-0000-000000000099';

select uji.harap(
  exists (
    select 1 from public.pelanggan
    where id = 'bb010000-0000-0000-0000-000000000099'
      and status_privasi = 'teranonimkan'
      and email is null
      and telepon is null
      and dianonimkan_pada is not null
  ),
  'Kasus 10: Pemicu otomatis mengosongkan email dan telepon saat status_privasi teranonimkan'
);

