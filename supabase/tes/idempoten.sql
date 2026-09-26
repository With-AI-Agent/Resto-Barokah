-- ============================================================================
-- UJI: KUNCI IDEMPOTEN MENYELURUH DI SEMUA PENULISAN (T10-02 / ART-8)
--
-- TECH_SPEC §9 ART-8:
-- "Semua penulisan dari antrean offline wajib membawa kunci_idempoten; peladen
-- menolak duplikat dengan anggun (balasan rekaman yang sudah ada, idempoten)."
--
-- Membuktikan secara matematis & deterministik:
--   1. simpan_pesanan (3x panggil dengan kunci sama → 1 pesanan, data identik)
--   2. bayar_pesanan (3x panggil dengan kunci sama → 1 pembayaran, uang tidak dobel)
--   3. pakai_voucher (3x panggil dengan kunci sama → 1 pemakaian, diskon tidak dobel)
--   4. buka_shift (3x panggil dengan kunci sama → 1 shift dibuka)
--   5. tutup_shift (3x panggil dengan kunci sama → 1 rekonsiliasi tutup)
--   6. kas_pergerakan (3x panggil dengan kunci sama → 1 baris kas)
--   7. set_stok (3x panggil dengan kunci sama → delta stok diterapkan tepat 1 kali)
--   8. opname_stok (3x panggil dengan kunci sama → hitungan fisik tercatat 1 kali)
-- ============================================================================

-- Data Uji Persiapan
select uji.klaim(null);

-- ---------------------------------------------------------------------------
-- 1. UJI IDEMPOTENSI: simpan_pesanan
-- ---------------------------------------------------------------------------
-- Rina (kasir cabang A1)
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

do $$
declare
  v_res1 jsonb;
  v_res2 jsonb;
  v_res3 jsonb;
  v_id1  uuid;
  v_id2  uuid;
  v_id3  uuid;
  v_items jsonb;
  v_cabang uuid := 'a1a1a1a1-0000-0000-0000-000000000001'::uuid;
  v_kunci text := 'idempoten-pesanan-xyz-001';
begin
  v_items := jsonb_build_array(
    jsonb_build_object(
      'id', 'beef0000-0000-0000-0000-000000000001',
      'qty', 2,
      'harga', 27000,
      'catatan', 'Pedas sedang'
    )
  );

  -- Panggilan 1 (pembuatan pertama)
  v_res1 := public.simpan_pesanan(
    p_cabang_id       := v_cabang,
    p_meja_id         := null,
    p_tipe            := 'takeaway',
    p_shift_id        := null,
    p_catatan         := 'Pesanan tamu A',
    p_items           := v_items,
    p_kunci_idempoten := v_kunci
  );
  v_id1 := (v_res1->'data'->>'pesanan_id')::uuid;

  -- Panggilan 2 (jaringan tersendat, kirim ulang dengan kunci sama)
  v_res2 := public.simpan_pesanan(
    p_cabang_id       := v_cabang,
    p_meja_id         := null,
    p_tipe            := 'takeaway',
    p_shift_id        := null,
    p_catatan         := 'Pesanan tamu A',
    p_items           := v_items,
    p_kunci_idempoten := v_kunci
  );
  v_id2 := (v_res2->'data'->>'pesanan_id')::uuid;

  -- Panggilan 3 (kirim ulang ketiga)
  v_res3 := public.simpan_pesanan(
    p_cabang_id       := v_cabang,
    p_meja_id         := null,
    p_tipe            := 'takeaway',
    p_shift_id        := null,
    p_catatan         := 'Pesanan tamu A',
    p_items           := v_items,
    p_kunci_idempoten := v_kunci
  );
  v_id3 := (v_res3->'data'->>'pesanan_id')::uuid;

  perform uji.harap(v_res1->>'kode' = 'SUKSES', 'simpan_pesanan pertama menghasilkan SUKSES');
  perform uji.harap(v_res2->>'kode' = 'IDEMPOTEN', 'simpan_pesanan kedua menghasilkan IDEMPOTEN');
  perform uji.harap(v_res3->>'kode' = 'IDEMPOTEN', 'simpan_pesanan ketiga menghasilkan IDEMPOTEN');
  perform uji.harap(v_id1 = v_id2 and v_id2 = v_id3, 'Semua ID pesanan identik (tidak membuat pesanan baru)');
  perform uji.sama((v_res2->'data'->>'idempoten')::text, 'true', 'Flag idempoten bernilai true pada balasan kedua');
end;
$$;

reset role;

select uji.sama(
  (select count(*) from public.pesanan where kunci_idempoten = 'idempoten-pesanan-xyz-001'),
  1::bigint,
  'Tepat satu baris pesanan tercatat di database walau dipanggil 3 kali'
);

-- ---------------------------------------------------------------------------
-- 2. UJI IDEMPOTENSI: bayar_pesanan
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

do $$
declare
  v_pesanan_id uuid;
  v_metode_id  uuid;
  v_kunci      text := 'idempoten-bayar-xyz-002';
  v_res1       jsonb;
  v_res2       jsonb;
  v_res3       jsonb;
begin
  select id into v_pesanan_id from public.pesanan where kunci_idempoten = 'idempoten-pesanan-xyz-001';
  select id into v_metode_id from public.metode_bayar where nama = 'Tunai' limit 1;

  -- Buka shift untuk kasir Rina
  perform public.buka_shift(50000, 'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 'Shift bayar', 'kunci-shift-bayar-01');

  declare
    v_total_pesanan integer;
  begin
    select total into v_total_pesanan from public.pesanan where id = v_pesanan_id;

    -- Panggilan 1 bayar
    v_res1 := public.bayar_pesanan(
      p_pesanan_id      := v_pesanan_id,
      p_metode_id       := v_metode_id,
      p_jumlah          := v_total_pesanan,
      p_diterima        := v_total_pesanan,
      p_referensi       := 'TUNAI-01',
      p_kunci_idempoten := v_kunci
    );

    -- Panggilan 2 bayar (kunci sama)
    v_res2 := public.bayar_pesanan(
      p_pesanan_id      := v_pesanan_id,
      p_metode_id       := v_metode_id,
      p_jumlah          := v_total_pesanan,
      p_diterima        := v_total_pesanan,
      p_referensi       := 'TUNAI-01',
      p_kunci_idempoten := v_kunci
    );

    -- Panggilan 3 bayar (kunci sama)
    v_res3 := public.bayar_pesanan(
      p_pesanan_id      := v_pesanan_id,
      p_metode_id       := v_metode_id,
      p_jumlah          := v_total_pesanan,
      p_diterima        := v_total_pesanan,
      p_referensi       := 'TUNAI-01',
      p_kunci_idempoten := v_kunci
    );
  end;

    perform uji.harap(v_res1->>'kode' = 'BY-200' and (v_res1->>'lunas')::boolean = true, 'bayar_pesanan pertama melunasi pesanan');
    perform uji.harap(v_res2->>'kode' = 'BY-200' and (v_res2->>'dobel')::boolean = true, 'bayar_pesanan kedua terdeteksi IDEMPOTEN (dobel: true)');
    perform uji.harap(v_res3->>'kode' = 'BY-200' and (v_res3->>'dobel')::boolean = true, 'bayar_pesanan ketiga terdeteksi IDEMPOTEN (dobel: true)');
end;
$$;

reset role;

select uji.sama(
  (select count(*) from public.pembayaran where kunci_idempoten = 'idempoten-bayar-xyz-002'),
  1::bigint,
  'Tepat satu baris pembayaran tercatat (uang tidak digandakan)'
);

-- ---------------------------------------------------------------------------
-- 2b. UJI IDEMPOTENSI: pakai_voucher
-- ---------------------------------------------------------------------------
-- Siapkan PIN kasir dan izin pakai_voucher
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000004', crypt('1234', gen_salt('bf', 8)))
on conflict (pengguna_id) do update set pin_hash = crypt('1234', gen_salt('bf', 8));

insert into public.izin (pengguna_id, kode_izin, boleh)
values ('90000000-0000-0000-0000-000000000004', 'pakai_voucher', true)
on conflict (pengguna_id, kode_izin) do update set boleh = true;

insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, maks_potongan, min_belanja, kuota, mulai, selesai, aktif
) values (
  'c0000000-0000-0000-0000-000000000099',
  '11111111-1111-1111-1111-111111111111',
  'Promo Idempoten',
  'IDEMPOTEN-KAMP',
  'nominal',
  10000,
  null,
  20000,
  10,
  now() - interval '1 day',
  now() + interval '7 days',
  true
);

insert into public.pelanggan (
  id, penyewa_id, nama, email, email_normalisasi, telepon, cara_masuk, persetujuan_privasi
) values (
  '88000000-0000-0000-0000-000000000001',
  '11111111-1111-1111-1111-111111111111',
  'Budi Santoso',
  'budi@oasis.test',
  'budi@oasis.test',
  '081234567890',
  'email',
  true
) on conflict (id) do nothing;

insert into public.voucher (
  id, penyewa_id, kampanye_id, pelanggan_id, kode, status
) values (
  'ba000000-0000-0000-0000-000000000099',
  '11111111-1111-1111-1111-111111111111',
  'c0000000-0000-0000-0000-000000000099',
  '88000000-0000-0000-0000-000000000001',
  'VC-IDEM-01',
  'aktif'
);

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

do $$
declare
  v_pesanan_id uuid := 'eeee0000-0000-0000-0000-000000000010'::uuid;
  v_res1 jsonb;
  v_res2 jsonb;
  v_res3 jsonb;
begin
  v_res1 := public.pakai_voucher(v_pesanan_id, 'VC-IDEM-01', '1234', 'kunci-voucher-01');
  v_res2 := public.pakai_voucher(v_pesanan_id, 'VC-IDEM-01', '1234', 'kunci-voucher-01');
  v_res3 := public.pakai_voucher(v_pesanan_id, 'VC-IDEM-01', '1234', 'kunci-voucher-01');

  perform uji.harap((v_res1->>'berhasil')::boolean = true, 'pakai_voucher pertama berhasil');
  perform uji.harap(v_res2->>'kode' = 'IDEMPOTEN', 'pakai_voucher kedua terdeteksi IDEMPOTEN');
  perform uji.harap(v_res3->>'kode' = 'IDEMPOTEN', 'pakai_voucher ketiga terdeteksi IDEMPOTEN');
end;
$$;

reset role;

select uji.sama(
  (select count(*) from public.diskon_transaksi where voucher_id = 'ba000000-0000-0000-0000-000000000099'),
  1::bigint,
  'Tepat satu baris diskon_transaksi voucher tercatat (diskon tidak digandakan)'
);

-- ---------------------------------------------------------------------------
-- 3. UJI IDEMPOTENSI: buka_shift
-- ---------------------------------------------------------------------------
-- Bu Oasis (owner pusat: 90000000-0000-0000-0000-000000000002)
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

do $$
declare
  v_kunci  text := 'idempoten-buka-shift-003';
  v_cabang uuid := 'a1a1a1a1-0000-0000-0000-000000000001'::uuid;
  v_res1   jsonb;
  v_res2   jsonb;
  v_res3   jsonb;
  v_s1     uuid;
  v_s2     uuid;
  v_s3     uuid;
begin
  -- Panggilan 1 buka shift
  v_res1 := public.buka_shift(
    p_modal_awal      := 125000,
    p_cabang_id       := v_cabang,
    p_catatan         := 'Shift owner pagi',
    p_kunci_idempoten := v_kunci
  );
  v_s1 := (v_res1->>'shift_id')::uuid;

  -- Panggilan 2 buka shift (kunci sama)
  v_res2 := public.buka_shift(
    p_modal_awal      := 125000,
    p_cabang_id       := v_cabang,
    p_catatan         := 'Shift owner pagi',
    p_kunci_idempoten := v_kunci
  );
  v_s2 := (v_res2->>'shift_id')::uuid;

  -- Panggilan 3 buka shift (kunci sama)
  v_res3 := public.buka_shift(
    p_modal_awal      := 125000,
    p_cabang_id       := v_cabang,
    p_catatan         := 'Shift owner pagi',
    p_kunci_idempoten := v_kunci
  );
  v_s3 := (v_res3->>'shift_id')::uuid;

  perform uji.harap((v_res1->>'berhasil')::boolean = true, 'buka_shift pertama berhasil');
  perform uji.harap(v_res2->>'kode' = 'IDEMPOTEN', 'buka_shift kedua terdeteksi IDEMPOTEN');
  perform uji.harap(v_res3->>'kode' = 'IDEMPOTEN', 'buka_shift ketiga terdeteksi IDEMPOTEN');
  perform uji.harap(v_s1 = v_s2 and v_s2 = v_s3, 'ID shift yang dikembalikan identik');
end;
$$;

reset role;

select uji.sama(
  (select count(*) from public.shift_kas where kunci_idempoten = 'idempoten-buka-shift-003'),
  1::bigint,
  'Tepat satu shift terbuka di database walau dipanggil 3 kali'
);

-- ---------------------------------------------------------------------------
-- 4. UJI IDEMPOTENSI: tutup_shift
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

do $$
declare
  v_shift_id uuid;
  v_kunci    text := 'idempoten-tutup-shift-004';
  v_res1     jsonb;
  v_res2     jsonb;
  v_res3     jsonb;
begin
  select id into v_shift_id from public.shift_kas where kunci_idempoten = 'idempoten-buka-shift-003';

  -- Panggilan 1 tutup shift
  v_res1 := public.tutup_shift(
    p_uang_fisik      := 125000,
    p_alasan_selisih  := null,
    p_shift_id        := v_shift_id,
    p_catatan         := 'Tutup shift owner',
    p_kunci_idempoten := v_kunci
  );

  -- Panggilan 2 tutup shift (kunci sama)
  v_res2 := public.tutup_shift(
    p_uang_fisik      := 125000,
    p_alasan_selisih  := null,
    p_shift_id        := v_shift_id,
    p_catatan         := 'Tutup shift owner',
    p_kunci_idempoten := v_kunci
  );

  -- Panggilan 3 tutup shift (kunci sama)
  v_res3 := public.tutup_shift(
    p_uang_fisik      := 125000,
    p_alasan_selisih  := null,
    p_shift_id        := v_shift_id,
    p_catatan         := 'Tutup shift owner',
    p_kunci_idempoten := v_kunci
  );

  perform uji.harap((v_res1->>'berhasil')::boolean = true, 'tutup_shift pertama berhasil');
  perform uji.harap(v_res2->>'kode' = 'IDEMPOTEN', 'tutup_shift kedua terdeteksi IDEMPOTEN');
  perform uji.harap(v_res3->>'kode' = 'IDEMPOTEN', 'tutup_shift ketiga terdeteksi IDEMPOTEN');
  perform uji.sama((v_res2->'data'->>'idempoten')::text, 'true', 'Flag idempoten bernilai true pada tutup shift kedua');
end;
$$;

reset role;

select uji.sama(
  (select count(*) from public.shift_kas where kunci_idempoten_tutup = 'idempoten-tutup-shift-004'),
  1::bigint,
  'Tepat satu rekonsiliasi penutupan shift tercatat'
);

-- ---------------------------------------------------------------------------
-- 5. UJI IDEMPOTENSI: kas_pergerakan
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

do $$
declare
  v_kunci text := 'idempoten-kas-pergerakan-005';
  v_res1  jsonb;
  v_res2  jsonb;
  v_res3  jsonb;
begin
  -- Panggilan 1 kas masuk
  v_res1 := public.kas_pergerakan(
    p_jenis           := 'masuk',
    p_jumlah          := 25000,
    p_alasan          := 'Tambah uang kembalian receh',
    p_shift_id        := null,
    p_cabang_id       := 'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
    p_kunci_idempoten := v_kunci
  );

  -- Panggilan 2 kas masuk (kunci sama)
  v_res2 := public.kas_pergerakan(
    p_jenis           := 'masuk',
    p_jumlah          := 25000,
    p_alasan          := 'Tambah uang kembalian receh',
    p_shift_id        := null,
    p_cabang_id       := 'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
    p_kunci_idempoten := v_kunci
  );

  -- Panggilan 3 kas masuk (kunci sama)
  v_res3 := public.kas_pergerakan(
    p_jenis           := 'masuk',
    p_jumlah          := 25000,
    p_alasan          := 'Tambah uang kembalian receh',
    p_shift_id        := null,
    p_cabang_id       := 'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
    p_kunci_idempoten := v_kunci
  );

  perform uji.harap((v_res1->>'berhasil')::boolean = true, 'kas_pergerakan pertama berhasil');
  perform uji.harap(v_res2->>'kode' = 'KP-200', 'kas_pergerakan kedua terdeteksi IDEMPOTEN (KP-200)');
  perform uji.harap(v_res3->>'kode' = 'KP-200', 'kas_pergerakan ketiga terdeteksi IDEMPOTEN (KP-200)');
end;
$$;

reset role;

select uji.sama(
  (select count(*) from public.kas_pergerakan where kunci_idempoten = 'idempoten-kas-pergerakan-005'),
  1::bigint,
  'Tepat satu baris kas pergerakan tercatat (saldo kas fisik tidak bocor)'
);

-- ---------------------------------------------------------------------------
-- 6. UJI IDEMPOTENSI: set_stok
-- ---------------------------------------------------------------------------
-- Sari (dapur / atur stok)
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;

do $$
declare
  v_bahan_id uuid := 'beef1000-0000-0000-0000-000000000001'::uuid;
  v_kunci    text := 'idempoten-set-stok-006';
  v_saldo_awal numeric;
  v_saldo_akhir numeric;
  v_res1     jsonb;
  v_res2     jsonb;
  v_res3     jsonb;
begin
  select jumlah into v_saldo_awal from public.stok_bahan where id = v_bahan_id;

  -- Panggilan 1 set stok (+10 kg beras)
  v_res1 := public.set_stok(
    p_stok_bahan_id   := v_bahan_id,
    p_jumlah          := 10,
    p_alasan          := 'Pemasukan beras distributor',
    p_kunci_idempoten := v_kunci
  );

  -- Panggilan 2 set stok (kunci sama)
  v_res2 := public.set_stok(
    p_stok_bahan_id   := v_bahan_id,
    p_jumlah          := 10,
    p_alasan          := 'Pemasukan beras distributor',
    p_kunci_idempoten := v_kunci
  );

  -- Panggilan 3 set stok (kunci sama)
  v_res3 := public.set_stok(
    p_stok_bahan_id   := v_bahan_id,
    p_jumlah          := 10,
    p_alasan          := 'Pemasukan beras distributor',
    p_kunci_idempoten := v_kunci
  );

  select jumlah into v_saldo_akhir from public.stok_bahan where id = v_bahan_id;

  perform uji.harap((v_res1->>'berhasil')::boolean = true, 'set_stok pertama berhasil');
  perform uji.harap(v_res2->>'kode' = 'IDEMPOTEN', 'set_stok kedua terdeteksi IDEMPOTEN');
  perform uji.harap(v_res3->>'kode' = 'IDEMPOTEN', 'set_stok ketiga terdeteksi IDEMPOTEN');
  perform uji.harap(v_saldo_akhir = (v_saldo_awal + 10), 'Delta stok hanya ditambah 1 kali (+10, bukan +30)');
end;
$$;

reset role;

select uji.sama(
  (select count(*) from public.stok_pergerakan where kunci_idempoten = 'idempoten-set-stok-006'),
  1::bigint,
  'Tepat satu baris pergerakan stok tercatat'
);

-- ---------------------------------------------------------------------------
-- 7. UJI IDEMPOTENSI: opname_stok
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;

do $$
declare
  v_bahan_id uuid := 'beef1000-0000-0000-0000-000000000001'::uuid;
  v_kunci    text := 'idempoten-opname-stok-007';
  v_res1     jsonb;
  v_res2     jsonb;
  v_res3     jsonb;
begin
  -- Panggilan 1 opname fisik (stok dihitung riil = 60)
  v_res1 := public.opname_stok(
    p_stok_bahan_id   := v_bahan_id,
    p_jumlah_fisik    := 60,
    p_alasan          := 'Opname stok malam',
    p_kunci_idempoten := v_kunci
  );

  -- Panggilan 2 opname (kunci sama)
  v_res2 := public.opname_stok(
    p_stok_bahan_id   := v_bahan_id,
    p_jumlah_fisik    := 60,
    p_alasan          := 'Opname stok malam',
    p_kunci_idempoten := v_kunci
  );

  -- Panggilan 3 opname (kunci sama)
  v_res3 := public.opname_stok(
    p_stok_bahan_id   := v_bahan_id,
    p_jumlah_fisik    := 60,
    p_alasan          := 'Opname stok malam',
    p_kunci_idempoten := v_kunci
  );

  perform uji.harap((v_res1->>'berhasil')::boolean = true, 'opname_stok pertama berhasil');
  perform uji.harap(v_res2->>'kode' = 'IDEMPOTEN', 'opname_stok kedua terdeteksi IDEMPOTEN');
  perform uji.harap(v_res3->>'kode' = 'IDEMPOTEN', 'opname_stok ketiga terdeteksi IDEMPOTEN');
end;
$$;

reset role;

select uji.sama(
  (select count(*) from public.stok_pergerakan where kunci_idempoten = 'idempoten-opname-stok-007'),
  1::bigint,
  'Tepat satu catatan opname fisik tersimpan'
);
