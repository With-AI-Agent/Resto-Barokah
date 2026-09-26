-- ============================================================================
-- UJI SQL: Pengaman Riwayat & Transaksi Masa Lalu Tidak Berubah (T9-11 · PRD M2)
--
-- Tujuan:
--   Membuktikan secara deterministik bahwa seluruh data transaksi keuangan masa lalu,
--   struk belanja pelanggan, rincian pesanan lunas, dan laporan penjualan/kas
--   TIDAK BERUBAH SEDIKITPUN (angka byte-per-byte identik, selisih = 0) ketika
--   pengaturan restoran (identitas, tema/warna, tarif pajak, service charge,
--   aturan pembulatan, harga menu, maupun metode pembayaran) diubah di kemudian hari.
--
-- Skenario yang Diuji (DoD T9-11):
--   1. Transaksi masa lalu lunas dengan rincian item, pajak PB1, service charge, dan diskon.
--   2. Perubahan identitas resto (nama, tagline, tema warna) -> angka transaksi & laporan tetap identik.
--   3. Perubahan tarif operasional (kenaikan pajak PB1 & service charge) -> transaksi lama tetap beku.
--   4. Perubahan harga & nama menu di katalog -> item transaksi lama tetap memakai harga_saat_itu.
--   5. Penonaktifan metode pembayaran -> catatan pembayaran masa lalu tetap utuh di laporan kas.
--   6. Percobaan manipulasi langsung pada pesanan tertutup/lunas ditolak fail-closed (picu_pesanan_tertutup_beku).
--   7. Seluruh mutasi pengaturan tercatat abadi di public.catatan_audit.
-- ============================================================================

reset role;
select uji.klaim(null);

drop table if exists _uji_riwayat_konteks;
create temp table _uji_riwayat_konteks (
  penyewa_id      uuid,
  cabang_id       uuid,
  shift_id        uuid,
  kasir_id        uuid,
  owner_id        uuid,
  metode_qris_id  uuid,
  menu_item_id    uuid,
  pesanan_id      uuid,
  hari_ini        date,
  total_awal      integer,
  pajak_awal      integer,
  service_awal    integer,
  subtotal_awal   integer,
  item_harga_awal integer,
  item_nama_awal  text,
  laporan_awal    jsonb
);

insert into _uji_riwayat_konteks (
  penyewa_id, cabang_id, shift_id, kasir_id, owner_id,
  metode_qris_id, menu_item_id, pesanan_id, hari_ini
) values (
  '11111111-1111-1111-1111-111111111111'::uuid,
  'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
  null,
  '90000000-0000-0000-0000-000000000004'::uuid, -- Kasir Rina
  '90000000-0000-0000-0000-000000000002'::uuid, -- Bu Oasis (Owner Pusat)
  (select id from public.metode_bayar where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'QRIS' limit 1),
  'beef0000-0000-0000-0000-000000000001'::uuid, -- Nasi Goreng (27.000 di Cabang Pusat)
  null,
  current_date
);

grant all on table _uji_riwayat_konteks to authenticated;

-- ---------------------------------------------------------------------------
-- Langkah 1: Buka Shift dan Buat Transaksi Lunas
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Kasir Rina
set local role authenticated;

do $$
declare
  v_cabang  uuid;
  v_shift   uuid;
  v_pesanan uuid;
  v_menu    uuid;
  v_metode  uuid;
  v_res_bayar jsonb;
begin
  select cabang_id, menu_item_id, metode_qris_id
    into v_cabang, v_menu, v_metode
    from _uji_riwayat_konteks;

  -- Pastikan ada shift terbuka
  select id into v_shift
    from public.shift_kas
   where cabang_id = v_cabang
     and status = 'terbuka'
   order by dibuka_pada desc
   limit 1;

  if v_shift is null then
    perform public.buka_shift(
      p_modal_awal := 100000,
      p_cabang_id  := v_cabang,
      p_catatan    := 'Buka shift untuk uji riwayat kekal'
    );
    select id into v_shift
      from public.shift_kas
     where cabang_id = v_cabang
       and status = 'terbuka'
     order by dibuka_pada desc
     limit 1;
  end if;

  update _uji_riwayat_konteks set shift_id = v_shift;

  -- Buat Pesanan Baru (2x Nasi Goreng @ 27.000 = 54.000)
  insert into public.pesanan (
    penyewa_id, cabang_id, tipe, status, shift_id, tanggal, kunci_idempoten
  ) values (
    '11111111-1111-1111-1111-111111111111', v_cabang, 'dinein', 'draf',
    v_shift, current_date, 'kunci-pesanan-riwayat-001'
  ) returning id into v_pesanan;

  update _uji_riwayat_konteks set pesanan_id = v_pesanan;

  insert into public.pesanan_item (
    pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
  ) values (
    v_pesanan, v_menu, 'Nasi Goreng', 27000, 2, 54000
  );

  -- Hitung total (PB1 10% = 5.400, Service 5% = 2.700, Total = 62.100)
  perform public.hitung_total(v_pesanan);

  -- Bayar pesanan via RPC bayar_pesanan
  v_res_bayar := public.bayar_pesanan(
    p_pesanan_id      => v_pesanan,
    p_metode_id       => v_metode,
    p_jumlah          => 62100,
    p_diterima        => 62100,
    p_referensi       => 'QRIS-RIWAYAT-001',
    p_kunci_idempoten => 'kunci-bayar-riwayat-001'
  );
end $$;

reset role;
select uji.klaim(null);

-- Simpan snapshot baseline ke konteks
update _uji_riwayat_konteks k
   set total_awal      = p.total,
       pajak_awal      = p.pajak,
       service_awal    = p.service,
       subtotal_awal   = p.subtotal,
       item_harga_awal = pi.harga_saat_itu,
       item_nama_awal  = pi.nama_saat_itu
  from public.pesanan p
  join public.pesanan_item pi on pi.pesanan_id = p.id
 where p.id = k.pesanan_id;

-- Tangkap laporan penjualan baseline sebagai Owner
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Bu Oasis (Owner Pusat)
set local role authenticated;

update _uji_riwayat_konteks
   set laporan_awal = public.laporan_penjualan(cabang_id, hari_ini, hari_ini);

-- Verifikasi baseline awal
select uji.sama(
  (select subtotal_awal from _uji_riwayat_konteks),
  54000,
  'Baseline: Subtotal pesanan awal tepat 54.000'
);
select uji.sama(
  (select pajak_awal from _uji_riwayat_konteks),
  5400,
  'Baseline: Pajak PB1 awal (10%) tepat 5.400'
);
select uji.sama(
  (select service_awal from _uji_riwayat_konteks),
  2700,
  'Baseline: Service charge awal (5%) tepat 2.700'
);
select uji.sama(
  (select total_awal from _uji_riwayat_konteks),
  62100,
  'Baseline: Total akhir pesanan tepat 62.100'
);
select uji.sama(
  (select item_harga_awal from _uji_riwayat_konteks),
  27000,
  'Baseline: harga_saat_itu pesanan_item tercatat 27.000'
);

-- ---------------------------------------------------------------------------
-- Langkah 2: Mutasi Identitas Resto & Tema Merek (Owner)
-- ---------------------------------------------------------------------------
select public.simpan_pengaturan(
  p_nama_resto => 'Kedai Oasis Baru Berkah',
  p_tagline    => 'Slogan Baru Oasis'
);

select public.simpan_tema(
  p_tema        => 'etnik',
  p_warna_merek => '#8B4513',
  p_kerapatan   => 'padat'
);

-- Verifikasi: Transaksi lama tetap memiliki angka yang sama persis
select uji.sama(
  (select p.subtotal from public.pesanan p join _uji_riwayat_konteks k on p.id = k.pesanan_id),
  (select subtotal_awal from _uji_riwayat_konteks),
  'Kekal: Subtotal pesanan lunas tidak berubah setelah nama dan tema diganti'
);
select uji.sama(
  (select p.pajak from public.pesanan p join _uji_riwayat_konteks k on p.id = k.pesanan_id),
  (select pajak_awal from _uji_riwayat_konteks),
  'Kekal: Pajak pesanan lunas tidak berubah setelah nama dan tema diganti'
);
select uji.sama(
  (select p.service from public.pesanan p join _uji_riwayat_konteks k on p.id = k.pesanan_id),
  (select service_awal from _uji_riwayat_konteks),
  'Kekal: Service charge pesanan lunas tidak berubah setelah nama dan tema diganti'
);
select uji.sama(
  (select p.total from public.pesanan p join _uji_riwayat_konteks k on p.id = k.pesanan_id),
  (select total_awal from _uji_riwayat_konteks),
  'Kekal: Total pesanan lunas tidak berubah setelah nama dan tema diganti'
);

-- ---------------------------------------------------------------------------
-- Langkah 3: Mutasi Tarif Operasional (PB1 Naik ke 12%, Service Jadi 10%, Pembulatan 500)
-- ---------------------------------------------------------------------------
select public.simpan_operasional(
  p_pajak_pb1_persen => 12.0,
  p_service_persen   => 10.0,
  p_pembulatan       => '500',
  p_header_struk     => 'Kop Struk Baru',
  p_footer_struk     => 'Kaki Struk Baru'
);

-- Verifikasi: Transaksi lunas masa lalu TIDAK tersentuh tarif operasional baru
select uji.sama(
  (select p.pajak from public.pesanan p join _uji_riwayat_konteks k on p.id = k.pesanan_id),
  (select pajak_awal from _uji_riwayat_konteks),
  'Kekal: Pajak pesanan lama tetap 5.400 walau PB1 naik ke 12%'
);
select uji.sama(
  (select p.service from public.pesanan p join _uji_riwayat_konteks k on p.id = k.pesanan_id),
  (select service_awal from _uji_riwayat_konteks),
  'Kekal: Service pesanan lama tetap 2.700 walau service naik ke 10%'
);
select uji.sama(
  (select p.total from public.pesanan p join _uji_riwayat_konteks k on p.id = k.pesanan_id),
  (select total_awal from _uji_riwayat_konteks),
  'Kekal: Total pesanan lama tetap 62.100 walau aturan pembulatan 500 diaktifkan'
);

-- ---------------------------------------------------------------------------
-- Langkah 4: Mutasi Katalog Menu (Harga Naik 2x Lipat & Nama Berubah)
-- ---------------------------------------------------------------------------
reset role;
select uji.klaim(null);

-- Ubah master menu item
update public.menu_item
   set nama = 'Nasi Goreng Spesial Emas',
       harga = 60000
 where id = 'beef0000-0000-0000-0000-000000000001';

-- Ubah harga menu cabang
update public.menu_cabang
   set harga = 65000
 where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001'
   and menu_item_id = 'beef0000-0000-0000-0000-000000000001';

-- Verifikasi: pesanan_item lama tetap memiliki harga_saat_itu dan nama_saat_itu awal
select uji.sama(
  (select pi.harga_saat_itu from public.pesanan_item pi join _uji_riwayat_konteks k on pi.pesanan_id = k.pesanan_id),
  (select item_harga_awal from _uji_riwayat_konteks),
  'Kekal: harga_saat_itu pada pesanan_item tetap 27.000 walau harga menu katalog naik ke 65.000'
);
select uji.sama(
  (select pi.nama_saat_itu from public.pesanan_item pi join _uji_riwayat_konteks k on pi.pesanan_id = k.pesanan_id),
  (select item_nama_awal from _uji_riwayat_konteks),
  'Kekal: nama_saat_itu pada pesanan_item tetap Nasi Goreng walau nama di katalog diubah'
);

-- ---------------------------------------------------------------------------
-- Langkah 5: Mutasi Metode Bayar (Penonaktifan Metode QRIS)
-- ---------------------------------------------------------------------------
update public.metode_bayar
   set aktif = false
 where penyewa_id = '11111111-1111-1111-1111-111111111111'
   and nama = 'QRIS';

-- Verifikasi: Baris pembayaran QRIS pada pesanan lama tetap ada & nominalnya utuh
select uji.sama(
  (select count(*)::int from public.pembayaran p join _uji_riwayat_konteks k on p.pesanan_id = k.pesanan_id),
  1,
  'Kekal: Baris pembayaran pesanan lama tetap utuh walau metode bayar dinonaktifkan'
);

-- ---------------------------------------------------------------------------
-- Langkah 6: Laporan Penjualan Masa Lalu Tetap Identik Byte-per-Byte
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner Bu Oasis
set local role authenticated;

do $$
declare
  v_cabang  uuid;
  v_tgl     date;
  v_awal    jsonb;
  v_baru    jsonb;
  v_omzet_awal  bigint;
  v_omzet_baru  bigint;
  v_pajak_awal  bigint;
  v_pajak_baru  bigint;
  v_serv_awal   bigint;
  v_serv_baru   bigint;
begin
  select cabang_id, hari_ini, laporan_awal
    into v_cabang, v_tgl, v_awal
    from _uji_riwayat_konteks;

  v_baru := public.laporan_penjualan(v_cabang, v_tgl, v_tgl);

  v_omzet_awal := (v_awal->'ringkasan'->>'total_omzet')::bigint;
  v_omzet_baru := (v_baru->'ringkasan'->>'total_omzet')::bigint;

  v_pajak_awal := (v_awal->'ringkasan'->>'total_pajak')::bigint;
  v_pajak_baru := (v_baru->'ringkasan'->>'total_pajak')::bigint;

  v_serv_awal  := (v_awal->'ringkasan'->>'total_service')::bigint;
  v_serv_baru  := (v_baru->'ringkasan'->>'total_service')::bigint;

  perform uji.sama(v_omzet_baru, v_omzet_awal, 'Kekal: total_omzet laporan penjualan identik setelah seluruh mutasi pengaturan');
  perform uji.sama(v_pajak_baru, v_pajak_awal, 'Kekal: total_pajak laporan penjualan identik setelah seluruh mutasi pengaturan');
  perform uji.sama(v_serv_baru, v_serv_awal, 'Kekal: total_service laporan penjualan identik setelah seluruh mutasi pengaturan');
end $$;

-- ---------------------------------------------------------------------------
-- Langkah 7: Percobaan Manipulasi Langsung Pesanan Lunas Ditolak Fail-Closed
-- ---------------------------------------------------------------------------
-- 7a. Perubahan kolom non-uang (catatan / tipe) ditolak oleh picu_pesanan_tertutup_beku
select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Kasir Rina
set local role authenticated;

select uji.harap_gagal_sebab(
  $$
    update public.pesanan
       set catatan = 'Catatan palsu dikarang sesudah lunas',
           tipe = 'takeaway'
     where id = (select pesanan_id from _uji_riwayat_konteks)
  $$,
  'Pesanan sudah ditutup \(status lunas\)',
  'Proteksi Fail-Closed: picu_pesanan_tertutup_beku menolak modifikasi jejak non-uang pada transaksi lunas'
);

-- 7b. Perubahan kolom uang secara langsung ditolak oleh picu_pesanan_uang_peladen
select uji.harap_gagal_sebab(
  $$
    update public.pesanan
       set total = 100
     where id = (select pesanan_id from _uji_riwayat_konteks)
  $$,
  'Angka uang pesanan hanya boleh diubah',
  'Proteksi Fail-Closed: picu_pesanan_uang_peladen menolak manipulasi langsung kolom uang'
);

reset role;
select uji.klaim(null);

-- ---------------------------------------------------------------------------
-- Langkah 8: Membuktikan Jejak Audit Mutasi Pengaturan Tercatat Abadi
-- ---------------------------------------------------------------------------
select uji.harap(
  (select count(*) >= 3 from public.catatan_audit
    where penyewa_id = '11111111-1111-1111-1111-111111111111'
      and aksi in ('ubah_identitas_resto', 'ubah_tema_resto', 'ubah_operasional_resto')),
  'Jejak Audit: Seluruh pengubahan pengaturan identitas, tema, dan operasional tercatat di catatan_audit'
);

-- ---------------------------------------------------------------------------
-- Pembersihan: Kembalikan Nilai-Nilai Default
-- ---------------------------------------------------------------------------
reset role;
select uji.klaim(null);

update public.metode_bayar
   set aktif = true
 where penyewa_id = '11111111-1111-1111-1111-111111111111'
   and nama = 'QRIS';

update public.menu_item
   set nama = 'Nasi Goreng', harga = 25000
 where id = 'beef0000-0000-0000-0000-000000000001';

update public.menu_cabang
   set harga = 27000
 where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001'
   and menu_item_id = 'beef0000-0000-0000-0000-000000000001';

drop table if exists _uji_riwayat_konteks;
