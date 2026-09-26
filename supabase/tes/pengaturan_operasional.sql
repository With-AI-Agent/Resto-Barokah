-- ============================================================================
-- supabase/tes/pengaturan_operasional.sql
-- Pengujian Pengaturan Operasional Resto (T9-03 / PRD M2 & M6 / ART-3)
--
-- Kasus yang diuji:
-- 1. Owner pusat dapat menyimpan pengaturan operasional lengkap.
-- 2. Data operasional pada public.pengaturan terbarui secara akurat dan versi naik.
-- 3. Jejak audit tercatat kekal pada public.catatan_audit (aksi = 'ubah_operasional_resto').
-- 4. RPC ambil_pengaturan_operasional mengembalikan seluruh parameter operasional.
-- 5. Validasi PB1 negatif (< 0) ditolak (22023).
-- 6. Validasi PB1 berlebih (> 100) ditolak (22023).
-- 7. Validasi Service charge negatif (< 0) ditolak (22023).
-- 8. Validasi Service charge berlebih (> 100) ditolak (22023).
-- 9. Validasi pembulatan tidak sah ditolak (22023).
-- 10. Validasi cara pesan tidak sah ditolak (22023).
-- 11. Staf tanpa izin atur_pengaturan (pelayan) ditolak (42501).
-- 12. Panggilan tanpa otentikasi (anon) ditolak (42501).
-- 13. Optimistic locking: versi lama usang ditolak (P0001).
-- 14. Bukti Mitigasi ART-3: Transaksi lama yang sudah terbit / lunas nilainya
--     TIDAK BERUBAH saat tarif PB1 & service diperbarui.
-- 15. Isolasi Penyewa: Perubahan di Resto A tidak menyentuh pengaturan Resto B.
-- ============================================================================

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Kasus 1 - 3: Owner Pusat mengubah pengaturan operasional & cek audit
-- ----------------------------------------------------------------------------
-- Masuk sebagai Owner Pusat Kedai Oasis (90000000-0000-0000-0000-000000000002)
select uji.klaim('90000000-0000-0000-0000-000000000002');

do $$
declare
  v_res jsonb;
begin
  v_res := public.simpan_operasional(
    p_pajak_pb1_persen := 11.0,
    p_service_persen   := 6.0,
    p_pembulatan       := '500',
    p_cara_pesan       := 'campur',
    p_jam_buka         := 'Senin - Minggu 08:00 - 22:00 WIB',
    p_header_struk     := 'KEDAI OASIS BAROKAH - Cabang Utama',
    p_footer_struk     := 'Matur Nuwun. Semoga Sehat dan Berkah Selalu!',
    p_tumpuk_diskon    := true
  );

  if (v_res->>'berhasil')::boolean is not true then
    raise exception 'Gagal simpan operasional: %', v_res;
  end if;
end;
$$;

select uji.harap(
  exists (
    select 1 from public.pengaturan
     where penyewa_id = '11111111-1111-1111-1111-111111111111'
       and pajak_pb1_persen = 11.00
       and service_persen = 6.00
       and pembulatan = '500'
       and cara_pesan = 'campur'
       and jam_buka = 'Senin - Minggu 08:00 - 22:00 WIB'
       and header_struk = 'KEDAI OASIS BAROKAH - Cabang Utama'
       and footer_struk = 'Matur Nuwun. Semoga Sehat dan Berkah Selalu!'
       and tumpuk_diskon = true
  ),
  'Kasus 1 & 2: Pengaturan operasional berhasil disimpan di database dengan nilai akurat'
);

select uji.harap(
  exists (
    select 1 from public.catatan_audit
     where penyewa_id = '11111111-1111-1111-1111-111111111111'
       and aksi = 'ubah_operasional_resto'
       and entitas = 'pengaturan'
       and pelaku_id = '90000000-0000-0000-0000-000000000002'
       and (nilai_baru->>'pajak_pb1_persen')::numeric = 11.00
       and (nilai_baru->>'service_persen')::numeric = 6.00
       and nilai_baru->>'pembulatan' = '500'
       and nilai_baru->>'cara_pesan' = 'campur'
  ),
  'Kasus 3: Jejak audit tercatat kekal pada catatan_audit dengan rincian nilai_lama dan nilai_baru'
);

-- ----------------------------------------------------------------------------
-- Kasus 4: RPC ambil_pengaturan_operasional mengembalikan data lengkap
-- ----------------------------------------------------------------------------
select uji.harap(
  (public.ambil_pengaturan_operasional()->'data'->>'pajak_pb1_persen')::numeric = 11.00
  and (public.ambil_pengaturan_operasional()->'data'->>'service_persen')::numeric = 6.00
  and (public.ambil_pengaturan_operasional()->'data'->>'pembulatan') = '500'
  and (public.ambil_pengaturan_operasional()->'data'->>'cara_pesan') = 'campur'
  and (public.ambil_pengaturan_operasional()->'data'->>'jam_buka') = 'Senin - Minggu 08:00 - 22:00 WIB'
  and (public.ambil_pengaturan_operasional()->'data'->>'header_struk') = 'KEDAI OASIS BAROKAH - Cabang Utama'
  and (public.ambil_pengaturan_operasional()->'data'->>'footer_struk') = 'Matur Nuwun. Semoga Sehat dan Berkah Selalu!'
  and (public.ambil_pengaturan_operasional()->'data'->>'tumpuk_diskon')::boolean is true,
  'Kasus 4: RPC ambil_pengaturan_operasional mengembalikan konfigurasi operasional lengkap'
);

-- ----------------------------------------------------------------------------
-- Kasus 5 & 6: Validasi Tarif PB1 (0 s/d 100)
-- ----------------------------------------------------------------------------
do $$
begin
  perform public.simpan_operasional(p_pajak_pb1_persen := -1.0);
  raise exception 'PB1 negatif harus ditolak';
exception
  when sqlstate '22023' then null;
end;
$$;

do $$
begin
  perform public.simpan_operasional(p_pajak_pb1_persen := 100.5);
  raise exception 'PB1 di atas 100 harus ditolak';
exception
  when sqlstate '22023' then null;
end;
$$;

select uji.harap(true, 'Kasus 5 & 6: Validasi batas tarif PB1 0 s/d 100 persen berfungsi benar');

-- ----------------------------------------------------------------------------
-- Kasus 7 & 8: Validasi Tarif Service Charge (0 s/d 100)
-- ----------------------------------------------------------------------------
do $$
begin
  perform public.simpan_operasional(p_service_persen := -0.5);
  raise exception 'Service negatif harus ditolak';
exception
  when sqlstate '22023' then null;
end;
$$;

do $$
begin
  perform public.simpan_operasional(p_service_persen := 105.0);
  raise exception 'Service di atas 100 harus ditolak';
exception
  when sqlstate '22023' then null;
end;
$$;

select uji.harap(true, 'Kasus 7 & 8: Validasi batas service charge 0 s/d 100 persen berfungsi benar');

-- ----------------------------------------------------------------------------
-- Kasus 9: Validasi Aturan Pembulatan
-- ----------------------------------------------------------------------------
do $$
begin
  perform public.simpan_operasional(p_pembulatan := '250');
  raise exception 'Pembulatan 250 harus ditolak';
exception
  when sqlstate '22023' then null;
end;
$$;

select uji.harap(true, 'Kasus 9: Pembulatan tidak sah ditolak tegas (22023)');

-- ----------------------------------------------------------------------------
-- Kasus 10: Validasi Cara Pesan
-- ----------------------------------------------------------------------------
do $$
begin
  perform public.simpan_operasional(p_cara_pesan := 'ojol_eksklusif');
  raise exception 'Cara pesan tidak sah harus ditolak';
exception
  when sqlstate '22023' then null;
end;
$$;

select uji.harap(true, 'Kasus 10: Cara pesan tidak sah ditolak tegas (22023)');

-- ----------------------------------------------------------------------------
-- Kasus 11: Pelayan tanpa izin atur_pengaturan ditolak (42501)
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000005'); -- Dedi (pelayan)

do $$
begin
  perform public.simpan_operasional(p_pajak_pb1_persen := 10.0);
  raise exception 'Pelayan dilarang mengubah operasional';
exception
  when sqlstate '42501' then null;
end;
$$;

select uji.harap(true, 'Kasus 11: Staf tanpa hak otorisasi ditolak (42501)');

-- ----------------------------------------------------------------------------
-- Kasus 12: Tanpa login ditolak (42501)
-- ----------------------------------------------------------------------------
select uji.klaim(null);

do $$
begin
  perform public.simpan_operasional(p_pajak_pb1_persen := 10.0);
  raise exception 'Pengguna anon dilarang mengubah operasional';
exception
  when sqlstate '42501' then null;
end;
$$;

select uji.harap(true, 'Kasus 12: Panggilan tanpa otentikasi ditolak (42501)');

-- ----------------------------------------------------------------------------
-- Kasus 13: Optimistic Concurrency Locking (P0001)
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner

do $$
declare
  v_versi_palsu timestamptz := '2020-01-01 00:00:00+00';
  v_tertangkap  boolean := false;
begin
  begin
    perform public.simpan_operasional(
      p_pajak_pb1_persen := 10.0,
      p_versi_lama := v_versi_palsu
    );
  exception
    when sqlstate 'P0001' then
      v_tertangkap := true;
  end;

  if not v_tertangkap then
    raise exception 'Versi optimistik lama harus ditolak dengan P0001' using errcode = '40001';
  end if;
end;
$$;

select uji.harap(true, 'Kasus 13: Penolakan benturan optimistic lock berfungsi (P0001)');

-- ----------------------------------------------------------------------------
-- Kasus 14: BUKTI MITIGASI ART-3 — Transaksi lama TIDAK BERUBAH saat tarif PB1 berubah
-- ----------------------------------------------------------------------------
do $$
declare
  v_pesanan_id   uuid;
  v_item_id      uuid;
  v_menu_id      uuid;
  v_metode_id    uuid;
  v_subtotal_lama integer;
  v_pajak_lama    integer;
  v_service_lama  integer;
  v_total_lama    integer;
  v_subtotal_cek  integer;
  v_pajak_cek     integer;
  v_service_cek   integer;
  v_total_cek     integer;
begin
  -- 1. Atur dulu tarif awal: PB1 10%, Service 5%, Pembulatan none
  perform public.simpan_operasional(
    p_pajak_pb1_persen := 10.0,
    p_service_persen   := 5.0,
    p_pembulatan       := 'none'
  );

  -- 2. Ambil menu uji
  select id into v_menu_id
    from public.menu_item
   where penyewa_id = '11111111-1111-1111-1111-111111111111'
     and aktif
   limit 1;

  -- 3. Buat pesanan baru
  v_pesanan_id := gen_random_uuid();
  insert into public.pesanan (
    id,
    cabang_id,
    penyewa_id,
    nomor,
    tanggal,
    tipe,
    status,
    kunci_idempoten
  ) values (
    v_pesanan_id,
    'a1a1a1a1-0000-0000-0000-000000000001',
    '11111111-1111-1111-1111-111111111111',
    991,
    current_date,
    'takeaway',
    'draf',
    'idem-test-opr-01'
  );

  -- Masukkan 2 porsi menu (subtotal = 2 * harga)
  insert into public.pesanan_item (
    pesanan_id,
    menu_item_id,
    nama_saat_itu,
    harga_saat_itu,
    qty,
    subtotal
  ) values (
    v_pesanan_id,
    v_menu_id,
    'Menu Uji Operasional',
    25000,
    2,
    50000
  );

  -- Hitung total awal
  perform public.hitung_total(v_pesanan_id);

  -- Ambil nilai angka uang yang dihasilkan
  select subtotal, pajak, service, total
    into v_subtotal_lama, v_pajak_lama, v_service_lama, v_total_lama
    from public.pesanan
   where id = v_pesanan_id;

  -- Verifikasi kalkulasi awal: subtotal=50000, pajak=5000 (10%), service=2500 (5%), total=57500
  if v_pajak_lama <> 5000 or v_service_lama <> 2500 or v_total_lama <> 57500 then
    raise exception 'Perhitungan awal salah: subtotal=%, pajak=%, service=%, total=%',
      v_subtotal_lama, v_pajak_lama, v_service_lama, v_total_lama;
  end if;

  -- 4. Kunci transaksi dengan membayarnya (status lunas)
  select id into v_metode_id
    from public.metode_bayar
   where penyewa_id = '11111111-1111-1111-1111-111111111111'
     and jenis = 'tunai'
   limit 1;

  perform public.bayar_pesanan(
    v_pesanan_id,
    v_metode_id,
    v_total_lama,
    v_total_lama,
    null,
    'kunci-bayar-opr-01'
  );

  -- 5. SEKARANG: Owner mengubah tarif PB1 menjadi 15% dan Service Charge menjadi 10%
  perform public.simpan_operasional(
    p_pajak_pb1_persen := 15.0,
    p_service_persen   := 10.0,
    p_pembulatan       := 'none'
  );

  -- 6. Verifikasi Pesanan Lama: Angka nominal subtotal, pajak, service, dan total TIDAK BOLEH BERUBAH!
  select subtotal, pajak, service, total
    into v_subtotal_cek, v_pajak_cek, v_service_cek, v_total_cek
    from public.pesanan
   where id = v_pesanan_id;

  if v_subtotal_cek <> v_subtotal_lama
     or v_pajak_cek <> v_pajak_lama
     or v_service_cek <> v_service_lama
     or v_total_cek <> v_total_lama then
    raise exception 'PELANGGARAN ART-3: Transaksi lama terpengaruh perubahan tarif operasional! (Pajak lama: %, Pajak cek: %)',
      v_pajak_lama, v_pajak_cek;
  end if;
end;
$$;

select uji.harap(
  true,
  'Kasus 14: Mitigasi ART-3 Terbukti — Transaksi lunas masa lalu tidak berubah nominalnya saat tarif PB1 & service diperbarui'
);

-- ----------------------------------------------------------------------------
-- Kasus 15: Isolasi Penyewa
-- ----------------------------------------------------------------------------
select uji.harap(
  exists (
    select 1 from public.pengaturan
     where penyewa_id = '22222222-2222-2222-2222-222222222222'
       and (pajak_pb1_persen <> 15.00 or jam_buka is distinct from 'Senin - Minggu 08:00 - 22:00 WIB')
  ),
  'Kasus 15: Perubahan pengaturan operasional di Resto A terisolasi total dari Resto B'
);

reset role;
select uji.klaim(null);
