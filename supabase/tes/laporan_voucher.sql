-- ============================================================================
-- Uji SQL: Laporan Klaim Voucher + Dasar Deteksi Anomali
-- Tugas: T8-13 (PRD M10 & M8 — Laporan klaim voucher & deteksi anomali kecurangan)
-- ============================================================================

begin;

-- Siapkan Kredensial PIN & Izin Kasir Rina (90000000-0000-0000-0000-000000000004)
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000004', crypt('123456', gen_salt('bf', 8)))
on conflict (pengguna_id) do update set pin_hash = crypt('123456', gen_salt('bf', 8));

insert into public.izin (pengguna_id, kode_izin, boleh)
values ('90000000-0000-0000-0000-000000000004', 'pakai_voucher', true)
on conflict (pengguna_id, kode_izin) do update set boleh = true;

-- ---------------------------------------------------------------------------
-- 1. Panggilan Anonim Ditolak
-- ---------------------------------------------------------------------------
select uji.harap_gagal_sebab(
  $$select public.laporan_voucher()$$,
  'Anda harus masuk dulu',
  'Anonim tidak boleh mengakses laporan voucher'
);

select uji.harap_gagal_sebab(
  $$select public.deteksi_anomali_voucher()$$,
  'Anda harus masuk dulu',
  'Anonim tidak boleh mengakses deteksi anomali voucher'
);

-- ---------------------------------------------------------------------------
-- 2. Peran Tanpa Wewenang (Pelayan & Kasir tanpa lihat_laporan) Ditolak
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000005'); -- Joko Pelayan
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.laporan_voucher()$$,
  'tidak berwenang melihat laporan voucher',
  'Pelayan tidak boleh membaca laporan voucher'
);

select uji.harap_gagal_sebab(
  $$select public.deteksi_anomali_voucher()$$,
  'tidak berwenang melihat deteksi anomali',
  'Pelayan tidak boleh mengakses deteksi anomali voucher'
);

select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Rina Kasir
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.laporan_voucher()$$,
  'tidak berwenang melihat laporan voucher',
  'Kasir tanpa izin lihat_laporan tidak boleh membaca laporan voucher'
);

-- ---------------------------------------------------------------------------
-- 3. Validasi Parameter (Owner Bu Oasis)
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Bu Oasis Owner
set local role authenticated;

-- Rentang tanggal terbalik
select uji.harap_gagal_sebab(
  $$select public.laporan_voucher(null, null, current_date, current_date - 1)$$,
  'tidak boleh lebih awal',
  'Tanggal akhir lebih awal dari mulai harus ditolak'
);

-- Rentang tanggal melebihi 90 hari
select uji.harap_gagal_sebab(
  $$select public.laporan_voucher(null, null, current_date - 91, current_date)$$,
  'maksimal 90 hari',
  'Rentang tanggal di atas 90 hari harus ditolak'
);

-- Cabang fiktif
select uji.harap_gagal_sebab(
  $$select public.laporan_voucher('ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid)$$,
  'Cabang tidak ditemukan',
  'Cabang fiktif harus ditolak'
);

-- Kampanye fiktif
select uji.harap_gagal_sebab(
  $$select public.laporan_voucher(null, 'ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid)$$,
  'Kampanye voucher tidak ditemukan',
  'Kampanye fiktif harus ditolak'
);

-- ---------------------------------------------------------------------------
-- 4. Setup Data Uji Kampanye, Pelanggan, dan Voucher
-- ---------------------------------------------------------------------------
reset role;
select uji.klaim(null);

-- Buat 2 Kampanye
insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, min_belanja, maks_potongan,
  mulai, selesai, kuota, anggaran_maks, aktif
) values
(
  'e1e1e1e1-0000-0000-0000-000000000001',
  '11111111-1111-1111-1111-111111111111',
  'Promo Makan Murah 20%',
  'MURAH20',
  'persen',
  20,
  50000,
  20000,
  now() - interval '10 days',
  now() + interval '30 days',
  50,
  500000,
  true
),
(
  'e1e1e1e1-0000-0000-0000-000000000002',
  '11111111-1111-1111-1111-111111111111',
  'Potongan Langsung Rp10rb',
  'POTONG10K',
  'nominal',
  10000,
  30000,
  null,
  now() - interval '10 days',
  now() + interval '30 days',
  5, -- Kuota sedikit agar mudah memicu anomali serapan >= 80% (4/5 = 80%)
  100000,
  true
);

-- Buat Pelanggan Uji
-- Pelanggan A (Budi Pelanggan: 4 klaim lintas kampanye -> anomali > 3 klaim)
insert into public.pelanggan (
  id, penyewa_id, nama, email, email_normalisasi, telepon, cara_masuk, persetujuan_privasi
) values
(
  'c1c1c1c1-0000-0000-0000-000000000001',
  '11111111-1111-1111-1111-111111111111',
  'Pelanggan Setia A',
  'pelanggan.a@gmail.com',
  'pelanggan.a@gmail.com',
  '08111111111',
  'google',
  true
),
(
  'c1c1c1c1-0000-0000-0000-000000000002',
  '11111111-1111-1111-1111-111111111111',
  'Pelanggan Biasa B',
  'pelanggan.b@gmail.com',
  'pelanggan.b@gmail.com',
  '08222222222',
  'email',
  true
);

-- Buat Voucher untuk Pelanggan A pada Kampanye 1
insert into public.voucher (
  id, penyewa_id, kampanye_id, pelanggan_id, kode, status, dibuat_pada
) values (
  'd1d1d1d1-0000-0000-0000-000000000001',
  '11111111-1111-1111-1111-111111111111',
  'e1e1e1e1-0000-0000-0000-000000000001',
  'c1c1c1c1-0000-0000-0000-000000000001',
  'RB-TEST-0001',
  'aktif',
  now() - interval '2 days'
);

-- Buat Voucher untuk Pelanggan A pada Kampanye 2
insert into public.voucher (
  id, penyewa_id, kampanye_id, pelanggan_id, kode, status, dibuat_pada
) values (
  'd1d1d1d1-0000-0000-0000-000000000002',
  '11111111-1111-1111-1111-111111111111',
  'e1e1e1e1-0000-0000-0000-000000000002',
  'c1c1c1c1-0000-0000-0000-000000000001',
  'RB-TEST-0002',
  'aktif',
  now() - interval '1 day'
);

-- Buat 2 Voucher lagi untuk Pelanggan A (total 4 klaim untuk menguji deteksi anomali >3 klaim)
-- Kita buat kampanye 3 & 4
insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, min_belanja, maks_potongan,
  mulai, selesai, kuota, anggaran_maks, aktif
) values
(
  'e1e1e1e1-0000-0000-0000-000000000003',
  '11111111-1111-1111-1111-111111111111',
  'Promo Kopi Sore',
  'KOPISORE',
  'nominal',
  5000,
  20000,
  null,
  now() - interval '5 days',
  now() + interval '30 days',
  100,
  500000,
  true
),
(
  'e1e1e1e1-0000-0000-0000-000000000004',
  '11111111-1111-1111-1111-111111111111',
  'Promo Sarapan Pagi',
  'PAGICERIA',
  'nominal',
  8000,
  25000,
  null,
  now() - interval '5 days',
  now() + interval '30 days',
  100,
  500000,
  true
);

insert into public.voucher (id, penyewa_id, kampanye_id, pelanggan_id, kode, status, dibuat_pada)
values
(
  'd1d1d1d1-0000-0000-0000-000000000003',
  '11111111-1111-1111-1111-111111111111',
  'e1e1e1e1-0000-0000-0000-000000000003',
  'c1c1c1c1-0000-0000-0000-000000000001',
  'RB-TEST-0003',
  'aktif',
  now() - interval '3 hours'
),
(
  'd1d1d1d1-0000-0000-0000-000000000004',
  '11111111-1111-1111-1111-111111111111',
  'e1e1e1e1-0000-0000-0000-000000000004',
  'c1c1c1c1-0000-0000-0000-000000000001',
  'RB-TEST-0004',
  'aktif',
  now() - interval '1 hour'
);

-- Buat 3 voucher tambahan di Kampanye 2 untuk mencapai 4/5 kuota (80% serapan kuota -> anomali kuota menipis)
insert into public.pelanggan (id, penyewa_id, nama, email, email_normalisasi, telepon, cara_masuk, persetujuan_privasi)
values
('c1c1c1c1-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'Tamu C', 'tamu.c@gmail.com', 'tamu.c@gmail.com', null, 'google', true),
('c1c1c1c1-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', 'Tamu D', 'tamu.d@gmail.com', 'tamu.d@gmail.com', null, 'google', true),
('c1c1c1c1-0000-0000-0000-000000000005', '11111111-1111-1111-1111-111111111111', 'Tamu E', 'tamu.e@gmail.com', 'tamu.e@gmail.com', null, 'google', true);

insert into public.voucher (id, penyewa_id, kampanye_id, pelanggan_id, kode, status, dibuat_pada)
values
('d1d1d1d1-0000-0000-0000-000000000005', '11111111-1111-1111-1111-111111111111', 'e1e1e1e1-0000-0000-0000-000000000002', 'c1c1c1c1-0000-0000-0000-000000000003', 'RB-TEST-0005', 'aktif', now()),
('d1d1d1d1-0000-0000-0000-000000000006', '11111111-1111-1111-1111-111111111111', 'e1e1e1e1-0000-0000-0000-000000000002', 'c1c1c1c1-0000-0000-0000-000000000004', 'RB-TEST-0006', 'aktif', now()),
('d1d1d1d1-0000-0000-0000-000000000007', '11111111-1111-1111-1111-111111111111', 'e1e1e1e1-0000-0000-0000-000000000002', 'c1c1c1c1-0000-0000-0000-000000000005', 'RB-TEST-0007', 'aktif', now());

-- Buat 2 Pesanan untuk Simulasi Pakai Voucher
insert into public.pesanan (
  id, penyewa_id, cabang_id, nomor, tipe, status, tanggal, kunci_idempoten, dibuat_pada
) values
(
  'b1b1b1b1-0000-0000-0000-000000000001',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  101,
  'dinein',
  'draf',
  current_date,
  'kunci-order-lap-vcr-1',
  now()
),
(
  'b1b1b1b1-0000-0000-0000-000000000002',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  102,
  'dinein',
  'draf',
  current_date,
  'kunci-order-lap-vcr-2',
  now()
) on conflict (id) do nothing;

insert into public.pesanan_item (
  id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
) values
(
  'b1b1b1b1-0000-0000-0000-000000000101',
  'b1b1b1b1-0000-0000-0000-000000000001',
  'beef0000-0000-0000-0000-000000000001',
  'Menu Lezat A',
  50000,
  2,
  100000
),
(
  'b1b1b1b1-0000-0000-0000-000000000102',
  'b1b1b1b1-0000-0000-0000-000000000002',
  'beef0000-0000-0000-0000-000000000001',
  'Menu Lezat B',
  50000,
  1,
  50000
) on conflict (id) do nothing;

-- Klaim Kasir Rina untuk memakai Voucher 1 dan Voucher 2 secara sah
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select public.pakai_voucher('b1b1b1b1-0000-0000-0000-000000000001', 'RB-TEST-0001', '123456', 'kunci-pakai-vcr-1');
select public.pakai_voucher('b1b1b1b1-0000-0000-0000-000000000002', 'RB-TEST-0002', '123456', 'kunci-pakai-vcr-2');

-- Reset role untuk mensimulasikan pemakaian kilat dan melunaskan pesanan
reset role;
select uji.klaim(null);

-- Simulasikan pemakaian kilat pada voucher 2: selisih waktu 60 detik (< 120 detik)
update public.voucher
   set dibuat_pada = now() - interval '10 minutes',
       terpakai_pada = now() - interval '9 minutes'
 where id = 'd1d1d1d1-0000-0000-0000-000000000002';

update public.pesanan
   set status = 'lunas'
 where id in ('b1b1b1b1-0000-0000-0000-000000000001', 'b1b1b1b1-0000-0000-0000-000000000002');

-- Simulasikan Brute-Force Percobaan Gagal (5 kali gagal dari IP 192.168.1.99)
insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, ip_pengakses, perangkat, aksi, waktu)
values
('11111111-1111-1111-1111-111111111111', 'RB-PALSU-01', 'gagal', 'Voucher tidak ditemukan.', '192.168.1.99', 'Tablet-Penyerang', 'cek', now() - interval '5 minutes'),
('11111111-1111-1111-1111-111111111111', 'RB-PALSU-02', 'gagal', 'Voucher tidak ditemukan.', '192.168.1.99', 'Tablet-Penyerang', 'cek', now() - interval '4 minutes'),
('11111111-1111-1111-1111-111111111111', 'RB-PALSU-03', 'gagal', 'Voucher tidak ditemukan.', '192.168.1.99', 'Tablet-Penyerang', 'cek', now() - interval '3 minutes'),
('11111111-1111-1111-1111-111111111111', 'RB-PALSU-04', 'gagal', 'Voucher tidak ditemukan.', '192.168.1.99', 'Tablet-Penyerang', 'cek', now() - interval '2 minutes'),
('11111111-1111-1111-1111-111111111111', 'RB-PALSU-05', 'gagal', 'Voucher tidak ditemukan.', '192.168.1.99', 'Tablet-Penyerang', 'cek', now() - interval '1 minute');

-- ---------------------------------------------------------------------------
-- 5. Uji RPC public.laporan_voucher (Hasil Lengkap)
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Bu Oasis Owner
set local role authenticated;

do $$
declare
  v_res jsonb;
  v_ringkasan jsonb;
  v_anomali jsonb;
  v_identitas jsonb;
  v_per_kampanye jsonb;
  v_per_cabang jsonb;
  v_ada_klaim_lebih boolean := false;
  v_ada_brute boolean := false;
  v_ada_kilat boolean := false;
  v_ada_anggaran boolean := false;
  v_elem jsonb;
begin
  v_res := public.laporan_voucher(null, null, current_date - 10, current_date + 1);

  -- Pastikan struktur dasar lengkap
  if v_res is null or not (v_res ? 'ringkasan' and v_res ? 'per_kampanye' and v_res ? 'anomali' and v_res ? 'identitas_klaim_berulang') then
    raise exception 'Format laporan voucher tidak lengkap: %', v_res;
  end if;

  v_ringkasan := v_res->'ringkasan';
  -- Total terpakai harus 2
  if (v_ringkasan->>'total_terpakai')::integer <> 2 then
    raise exception 'Total voucher terpakai salah: % (harus 2)', v_ringkasan->>'total_terpakai';
  end if;

  -- Total potongan harus 30.000 (20.000 + 10.000)
  if (v_ringkasan->>'total_potongan')::integer <> 30000 then
    raise exception 'Total nilai potongan salah: % (harus 30000)', v_ringkasan->>'total_potongan';
  end if;

  -- Rata-rata potongan harus 15.000
  if (v_ringkasan->>'rata_rata_potongan')::integer <> 15000 then
    raise exception 'Rata-rata potongan salah: % (harus 15000)', v_ringkasan->>'rata_rata_potongan';
  end if;

  -- Uji Identitas Klaim Berulang (Pelanggan A memiliki 4 klaim)
  v_identitas := v_res->'identitas_klaim_berulang';
  if jsonb_array_length(v_identitas) < 1 then
    raise exception 'Identitas klaim berulang kosong padahal Pelanggan A punya 4 klaim.';
  end if;

  if (v_identitas->0->>'jumlah_klaim')::integer <> 4 then
    raise exception 'Jumlah klaim Pelanggan A salah: % (harus 4)', v_identitas->0->>'jumlah_klaim';
  end if;

  -- Uji Deteksi 4 Jenis Anomali
  v_anomali := v_res->'anomali';
  for v_elem in select * from jsonb_array_elements(v_anomali) loop
    if v_elem->>'jenis' = 'klaim_berulang_berlebih' then
      v_ada_klaim_lebih := true;
    elsif v_elem->>'jenis' = 'brute_force_percobaan' then
      v_ada_brute := true;
    elsif v_elem->>'jenis' = 'pemakaian_kilat' then
      v_ada_kilat := true;
    elsif v_elem->>'jenis' = 'anggaran_kuota_menipis' then
      v_ada_anggaran := true;
    end if;
  end loop;

  if not v_ada_klaim_lebih then
    raise exception 'Anomali klaim_berulang_berlebih tidak terdeteksi.';
  end if;

  if not v_ada_brute then
    raise exception 'Anomali brute_force_percobaan tidak terdeteksi.';
  end if;

  if not v_ada_kilat then
    raise exception 'Anomali pemakaian_kilat tidak terdeteksi.';
  end if;

  if not v_ada_anggaran then
    raise exception 'Anomali anggaran_kuota_menipis tidak terdeteksi.';
  end if;

  -- Uji per_cabang
  v_per_cabang := v_res->'per_cabang';
  if jsonb_array_length(v_per_cabang) < 1 then
    raise exception 'Rincian per cabang kosong.';
  end if;

  -- Uji per_kampanye
  v_per_kampanye := v_res->'per_kampanye';
  if jsonb_array_length(v_per_kampanye) < 2 then
    raise exception 'Rincian per kampanye kurang dari 2.';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 6. Uji RPC mandiri public.deteksi_anomali_voucher
-- ---------------------------------------------------------------------------
do $$
declare
  v_anomali jsonb;
begin
  v_anomali := public.deteksi_anomali_voucher(null, 3);
  if jsonb_array_length(v_anomali) < 4 then
    raise exception 'deteksi_anomali_voucher mandiri harus mendeteksi setidaknya 4 anomali: %', v_anomali;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 7. Uji View public.laporan_voucher_ringkasan
-- ---------------------------------------------------------------------------
do $$
declare
  v_count integer;
  v_potongan integer;
begin
  select count(*), coalesce(sum(total_potongan), 0)
    into v_count, v_potongan
    from public.laporan_voucher_ringkasan
   where penyewa_id = '11111111-1111-1111-1111-111111111111';

  if v_count < 1 then
    raise exception 'View laporan_voucher_ringkasan tidak menghasilkan data.';
  end if;

  if v_potongan <> 30000 then
    raise exception 'Total potongan pada view laporan_voucher_ringkasan salah: % (harus 30000)', v_potongan;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 8. Uji Hak Akses Admin Cabang (Pak Andi)
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000003'); -- Pak Andi Admin Cabang
set local role authenticated;

do $$
declare
  v_res jsonb;
begin
  v_res := public.laporan_voucher('a1a1a1a1-0000-0000-0000-000000000001');
  if v_res is null then
    raise exception 'Admin cabang gagal mengakses laporan cabangnya.';
  end if;
end;
$$;

rollback;
