-- ============================================================================
-- PENGUJIAN: Ringkasan Peringatan Harian ke Owner (T10-13 / M12 / ART-13 / ART-14)
--
-- Referensi:
--   - PRD M12: Hal aneh (void, diskon, selisih kas, percobaan masuk gagal,
--     perubahan perangkat) terlihat tanpa owner membuka aplikasi.
--   - TECH_SPEC §5.1 & §9 ART-13: Rantai audit diperiksa kriptografis dan
--     dilaporkan bila putus.
--   - docs/KEAMANAN.md §9: Peringatan harian ke email owner dan layar aplikasi.
--   - ART-14: Laporan dan rincian anomali bebas dari data pribadi pelanggan.
--   - DoD: Uji SQL membuktikan keakuratan metrik, fail-closed hak akses,
--     isolasi multi-tenant, dan proteksi privasi pelanggan.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- 1. Penyiapan Data Uji Transaksi & Insiden
-- ----------------------------------------------------------------------------
-- Tenant A: 11111111-1111-1111-1111-111111111111 (Barokah Pusat)
-- Cabang A: a1a1a1a1-0000-0000-0000-000000000001
-- Owner A : 90000000-0000-0000-0000-000000000002
-- Kasir A : 90000000-0000-0000-0000-000000000004
-- Pelayan A: 90000000-0000-0000-0000-000000000005
-- Tanggal uji: 2026-09-25

-- (a) Buat 2 pesanan dengan item dan diskon lalu bayar lunas
-- Pesanan 1: Subtotal 110.000, diskon 10.000 -> Total 100.000
insert into public.pesanan (
  id, penyewa_id, cabang_id, nomor, tanggal, status, total, subtotal,
  kasir_id, kunci_idempoten
) values (
  'ee100000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001',
   901, '2026-09-25', 'draf', 0, 0, '90000000-0000-0000-0000-000000000004', 'idem-ringkas-01')
on conflict (id) do nothing;

-- Pesanan 2: Subtotal 55.000, diskon 5.000 -> Total 50.000
insert into public.pesanan (
  id, penyewa_id, cabang_id, nomor, tanggal, status, total, subtotal,
  kasir_id, kunci_idempoten
) values (
  'ee100000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001',
   902, '2026-09-25', 'draf', 0, 0, '90000000-0000-0000-0000-000000000004', 'idem-ringkas-02')
on conflict (id) do nothing;

-- Masukkan item pesanan
insert into public.pesanan_item (
  id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
) values
  ('ee100000-0000-0000-0000-000000000011', 'ee100000-0000-0000-0000-000000000001', 'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng Spesial', 110000, 1, 110000),
  ('ee100000-0000-0000-0000-000000000012', 'ee100000-0000-0000-0000-000000000002', 'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng Spesial', 55000, 1, 55000)
on conflict (id) do nothing;

-- Masukkan diskon sebelum pesanan lunas
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner pusat
set local role authenticated;

insert into public.diskon_transaksi (
  id, pesanan_id, jenis, nominal, nilai, alasan, pelaku_id, waktu
) values
  ('ee100000-0000-0000-0000-000000000021', 'ee100000-0000-0000-0000-000000000001', 'manual', 10000, 10000, 'Diskon Promo Jumat', '90000000-0000-0000-0000-000000000002', '2026-09-25 12:25:00+07'),
  ('ee100000-0000-0000-0000-000000000022', 'ee100000-0000-0000-0000-000000000002', 'manual', 5000, 5000, 'Keluarga pemilik', '90000000-0000-0000-0000-000000000002', '2026-09-25 14:10:00+07')
on conflict (id) do nothing;

reset role;
select uji.klaim(null);

-- Tandai pesanan telah dibayar lunas
update public.pesanan
   set status = 'lunas',
       dibayar_pada = '2026-09-25 12:30:00+07'
 where id = 'ee100000-0000-0000-0000-000000000001';

update public.pesanan
   set status = 'lunas',
       dibayar_pada = '2026-09-25 14:15:00+07'
 where id = 'ee100000-0000-0000-0000-000000000002';

-- (b) Buat 1 pesanan yang dibatalkan dengan nilai kerugian Rp 35.000
insert into public.pesanan (
  id, penyewa_id, cabang_id, nomor, tanggal, status, total, subtotal,
  kasir_id, kunci_idempoten
) values
  ('ee100000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001',
   903, '2026-09-25', 'draf', 0, 35000, '90000000-0000-0000-0000-000000000004', 'idem-ringkas-03')
on conflict (id) do nothing;

select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner Pusat A
set local role authenticated;

insert into public.pembatalan (
  id, pesanan_id, tahap, pelaku_id, alasan, nilai_kerugian, waktu
) values (
  'ee100000-0000-0000-0000-000000000010',
  'ee100000-0000-0000-0000-000000000003',
  'sebelum_dapur',
  '90000000-0000-0000-0000-000000000002',
  'Salah input meja dan makanan batal diproses',
  35000,
  '2026-09-25 15:05:00+07'
) on conflict (id) do nothing;

reset role;
select uji.klaim(null);

-- (c) Diskon telah dicatat sebelum pelunasan pesanan (total Rp 15.000)

-- (d) Buat 1 shift kasir dengan selisih Rp 20.000
insert into public.shift_kas (
  id, penyewa_id, cabang_id, dibuka_oleh, ditutup_oleh, dibuka_pada, ditutup_pada,
  modal_awal, uang_seharusnya, uang_fisik, selisih, alasan_selisih, status
) values (
  'ee100000-0000-0000-0000-000000000030',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  '90000000-0000-0000-0000-000000000004',
  '90000000-0000-0000-0000-000000000004',
  '2026-09-25 08:00:00+07',
  '2026-09-25 17:00:00+07',
  200000,
  350000,
  330000,
  -20000,
  'Kembalian salah berikan pelanggan terburu-buru',
  'ditutup'
) on conflict (id) do nothing;

-- (e) Buat percobaan login & PIN gagal
insert into public.percobaan_masuk (
  id, penyewa_id, pengguna_id, berhasil, sebab, waktu
) values (
  'ee100000-0000-0000-0000-000000000041',
  '11111111-1111-1111-1111-111111111111',
  '90000000-0000-0000-0000-000000000004',
  false,
  'Kata sandi salah 3 kali',
  '2026-09-25 07:55:00+07'
) on conflict (id) do nothing;

insert into public.percobaan_pin (
  id, pengguna_id, perangkat, berhasil, aksi, waktu
) values (
  99901,
  '90000000-0000-0000-0000-000000000004',
  'Tablet Kasir 1',
  false,
  'masuk_shift',
  '2026-09-25 07:58:00+07'
) on conflict (id) do nothing;

-- (f) Buat catatan audit perubahan perangkat
insert into public.catatan_audit (
  id, penyewa_id, pelaku_id, aksi, entitas, entitas_id, waktu
) values (
  'ee100000-0000-0000-0000-000000000051',
  '11111111-1111-1111-1111-111111111111',
  '90000000-0000-0000-0000-000000000002',
  'daftar_perangkat',
  'perangkat',
  'de000000-0000-0000-0000-000000000003',
  '2026-09-25 09:00:00+07'
) on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- 2. Uji Eksekusi RPC public.hasilkan_ringkasan_harian
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Masuk sebagai Owner Pusat A

do $$
declare
  v_res jsonb;
begin
  v_res := public.hasilkan_ringkasan_harian(
    '11111111-1111-1111-1111-111111111111'::uuid,
    '2026-09-25'::date
  );

  -- Asersi omzet & transaksi (115.000 + 57.500 = 172.500 termasuk pajak & service)
  perform uji.harap(
    (v_res->>'omzet')::bigint = 172500,
    'Omzet harian terhitung akurat Rp 172.500 (termasuk pajak & service)'
  );

  perform uji.harap(
    (v_res->>'transaksi_count')::int = 2,
    'Jumlah transaksi lunas terhitung akurat (2 transaksi)'
  );

  -- Asersi void & nilai kerugian
  perform uji.harap(
    (v_res->>'void_count')::int >= 1,
    'Jumlah transaksi void/batal terhitung minimal 1'
  );

  perform uji.harap(
    (v_res->>'void_nominal')::bigint = 35000,
    'Total nominal kerugian void terhitung akurat Rp 35.000'
  );

  -- Asersi diskon
  perform uji.harap(
    (v_res->>'diskon_count')::int = 2,
    'Jumlah diskon terhitung akurat (2 potongan)'
  );

  perform uji.harap(
    (v_res->>'diskon_nominal')::bigint = 15000,
    'Total potongan diskon terhitung akurat Rp 15.000'
  );

  -- Asersi selisih kas fisik
  perform uji.harap(
    (v_res->>'selisih_kas_count')::int = 1,
    'Jumlah shift berselisih kas terhitung akurat (1 shift)'
  );

  perform uji.harap(
    (v_res->>'selisih_kas_nominal')::bigint = 20000,
    'Total absolut selisih kas fisik terhitung akurat Rp 20.000'
  );

  -- Asersi gagal login/PIN & perubahan perangkat
  perform uji.harap(
    (v_res->>'percobaan_gagal_count')::int >= 2,
    'Percobaan masuk/PIN gagal terakumulasi akurat minimal 2 kali'
  );

  perform uji.harap(
    (v_res->>'perubahan_perangkat_count')::int >= 1,
    'Perubahan perangkat terhitung minimal 1 kejadian'
  );

  -- Asersi verifikasi rantai audit berantai hash (ART-13)
  perform uji.harap(
    (v_res->>'rantai_audit_valid')::boolean = true,
    'Status rantai audit valid dan kriptografis hash terverifikasi utuh'
  );

  -- Asersi privasi pelanggan (ART-14): tidak ada email atau nomor telepon pelanggan dalam rincian
  perform uji.harap(
    (v_res->>'rincian_peringatan')::text not like '%@gmail.com%' and
    (v_res->>'rincian_peringatan')::text not like '%0812%' and
    (v_res->>'rincian_peringatan')::text not like '%telepon%',
    'Rincian anomali bebas dari data pribadi pelanggan (UU PDP & ART-14)'
  );
end $$;

-- ----------------------------------------------------------------------------
-- 3. Uji Hak Akses & RLS: RPC public.ambil_ringkasan_harian
-- ----------------------------------------------------------------------------
-- Kasir biasa tanpa izin lihat_laporan DITOLAK
select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Kasir A

select uji.harap_gagal_sebab(
  $$ select * from public.ambil_ringkasan_harian('2026-09-01'::date, '2026-09-30'::date) $$,
  'Tidak berwenang melihat laporan peringatan',
  'Kasir biasa tanpa izin lihat_laporan ditolak melihat ringkasan harian'
);

-- Owner Pusat dapat melihat ringkasan restonya
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner Pusat A

select uji.harap(
  exists (
    select 1 from public.ambil_ringkasan_harian('2026-09-01'::date, '2026-09-30'::date)
     where tanggal = '2026-09-25' and omzet = 172500
  ),
  'Owner Pusat berhasil mengambil ringkasan harian tanggal 2026-09-25'
);

-- Isolasi Multi-Tenant: Owner Resto B (22222222...) tidak boleh melihat data Resto A
insert into auth.users (id, email)
values ('90000000-0000-0000-0000-000000000088', 'owner.b@contoh.test')
on conflict (id) do nothing;

insert into public.pengguna (id, penyewa_id, nama, email, peran)
values ('90000000-0000-0000-0000-000000000088', '22222222-2222-2222-2222-222222222222', 'Pak Bandung', 'owner.b@contoh.test', 'owner_pusat')
on conflict (id) do nothing;

select uji.klaim('90000000-0000-0000-0000-000000000088'); -- Owner Resto B
set local role authenticated;

select uji.harap(
  (select count(*) from public.ringkasan_harian where penyewa_id = '11111111-1111-1111-1111-111111111111') = 0,
  'RLS fail-closed: Owner Resto B tidak melihat ringkasan Resto A'
);

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- 4. Uji RPC public.simpan_pengaturan_peringatan
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner Pusat A

-- (a) Simpan konfigurasi sah
select uji.harap(
  (public.simpan_pengaturan_peringatan('owner.barokah@resto.test', true, '22:30')->>'berhasil')::boolean = true,
  'Owner berhasil menyimpan pengaturan notifikasi email peringatan'
);

select uji.harap(
  exists (
    select 1 from public.pengaturan
     where penyewa_id = '11111111-1111-1111-1111-111111111111'
       and email_peringatan = 'owner.barokah@resto.test'
       and kirim_email_peringatan = true
       and jam_ringkasan = '22:30'
  ),
  'Nilai pengaturan email & jam ringkasan terperbarui di database'
);

-- (b) Jam tidak valid ditolak
select uji.harap_gagal_sebab(
  $$ select public.simpan_pengaturan_peringatan('owner@resto.test', true, '25:99') $$,
  'Format jam ringkasan tidak valid',
  'Format jam ringkasan di luar batas 24 jam ditolak'
);

-- (c) Email format tidak valid ditolak
select uji.harap_gagal_sebab(
  $$ select public.simpan_pengaturan_peringatan('bukan-email-valid', true, '23:00') $$,
  'Format alamat email',
  'Format alamat email yang tidak valid ditolak'
);

-- (d) Kasir biasa dilarang mengubah setelan notifikasi
select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Kasir A

select uji.harap_gagal_sebab(
  $$ select public.simpan_pengaturan_peringatan('hacker@kasir.test', false, '12:00') $$,
  'Hanya owner atau pengguna dengan izin atur_pengaturan',
  'Kasir biasa dilarang mengubah pengaturan notifikasi peringatan'
);

-- ----------------------------------------------------------------------------
-- 5. Uji RPC public.set_status_email_ringkasan
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner Pusat A

do $$
declare
  v_ringkasan_id uuid;
begin
  select id into v_ringkasan_id
    from public.ringkasan_harian
   where penyewa_id = '11111111-1111-1111-1111-111111111111'
     and tanggal = '2026-09-25';

  -- Perbarui status menjadi terkirim
  perform public.set_status_email_ringkasan(v_ringkasan_id, 'terkirim');

  perform uji.harap(
    exists (
      select 1 from public.ringkasan_harian
       where id = v_ringkasan_id
         and status_email = 'terkirim'
         and dikirim_pada is not null
    ),
    'Status email ringkasan berhasil diperbarui menjadi terkirim beserta waktu pengiriman'
  );
end $$;

-- Status tidak sah ditolak
select uji.harap_gagal_sebab(
  $$ select public.set_status_email_ringkasan('11111111-1111-1111-1111-111111111111'::uuid, 'status_palsu') $$,
  'Status email tidak valid',
  'Status pengiriman email di luar whitelist ditolak'
);

-- ----------------------------------------------------------------------------
-- 6. Verifikasi Jejak Audit Tercatat (ART-13)
-- ----------------------------------------------------------------------------
select uji.harap(
  exists (
    select 1 from public.catatan_audit
     where penyewa_id = '11111111-1111-1111-1111-111111111111'
       and aksi in ('ringkasan_harian', 'simpan_pengaturan_peringatan')
  ),
  'Aktivitas ringkasan harian dan konfigurasi tercatat di catatan_audit'
);

rollback;
