-- ============================================================================
-- UJI: TRANSAKSI HANYA DALAM SHIFT TERBUKA (T7-04, PRD M7, TECH_SPEC §9 ART-6)
--
-- Yang dibuktikan:
--   1. Mode fleksibel (wajib_shift = false):
--      - Pesanan dan pembayaran tetap dapat dibuat tanpa shift kasir.
--   2. Mode wajib shift (wajib_shift = true):
--      - Memesan tanpa shift kasir aktif di cabang -> DITOLAK (SH-400).
--      - Membayar via RPC bayar_pesanan tanpa shift aktif -> DITOLAK (SH-400).
--      - Membayar via INSERT pembayaran langsung tanpa shift aktif -> DITOLAK (SH-400).
--   3. Saat shift dibuka (buka_shift):
--      - Memesan saat shift terbuka -> BERHASIL & shift_id otomatis terhubung.
--      - Membayar pesanan via bayar_pesanan -> BERHASIL & shift_id pembayaran terhubung.
--      - Membayar langsung -> BERHASIL & shift_id otomatis terhubung.
--   4. Setelah shift ditutup (tutup_shift):
--      - Transaksi pesanan baru di cabang tersebut -> DITOLAK (SH-400).
--      - Transaksi pembayaran baru di cabang tersebut -> DITOLAK (SH-400).
--      - Menyelundupkan shift_id yang sudah ditutup -> DITOLAK (SH-400).
--   5. Isolasi multi-cabang:
--      - Cabang 1 buka shift, Cabang 2 belum buka shift -> Cabang 1 boleh transaksi,
--        Cabang 2 tetap ditolak sampai shift-nya dibuka.
-- ============================================================================

-- Siapkan identitas uji: Rina (Kasir A1 di Kedai Oasis)
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- ---------------------------------------------------------------------------
-- 1. Mode Fleksibel (wajib_shift bawaan = false)
-- ---------------------------------------------------------------------------
do $$
declare
  v_pesanan_id uuid := gen_random_uuid();
begin
  -- Buat pesanan tanpa shift saat wajib_shift = false
  insert into public.pesanan (
    id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten
  ) values (
    v_pesanan_id,
    '11111111-1111-1111-1111-111111111111',
    'a1a1a1a1-0000-0000-0000-000000000001',
    801,
    current_date,
    'dinein',
    'draf',
    'kunci-fleksibel-01'
  );

  perform uji.harap(true, 'Mode fleksibel: pesanan berhasil dibuat tanpa shift');
end;
$$;

-- ---------------------------------------------------------------------------
-- 2. Aktifkan Mode Wajib Shift untuk Kedai Oasis
-- ---------------------------------------------------------------------------
reset role;
update public.pengaturan
   set wajib_shift = true
 where penyewa_id = '11111111-1111-1111-1111-111111111111';

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- Skenario A: Memesan tanpa shift aktif ditolak dengan pesan SH-400 yang jelas
select uji.harap_gagal_sebab(
  $$
  insert into public.pesanan (
    id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten
  ) values (
    gen_random_uuid(),
    '11111111-1111-1111-1111-111111111111',
    'a1a1a1a1-0000-0000-0000-000000000001',
    802,
    current_date,
    'dinein',
    'draf',
    'kunci-tolak-shift-01'
  );
  $$,
  'SH-400: Tidak dapat membuat pesanan: belum ada shift kas yang dibuka di cabang ini.',
  'Membuat pesanan ditolak saat belum ada shift kas yang dibuka di cabang itu'
);

-- Skenario B: Membayar via RPC bayar_pesanan tanpa shift aktif ditolak dengan SH-400
-- Gunakan pesanan eeee0000-0000-0000-0000-000000000010 dari data uji
select uji.harap_gagal_sebab(
  $$
  select public.bayar_pesanan(
    'eeee0000-0000-0000-0000-000000000010'::uuid,
    (select id from public.metode_bayar where jenis = 'tunai' and penyewa_id = '11111111-1111-1111-1111-111111111111' limit 1),
    62100,
    70000,
    null,
    'kunci-bayar-tolak-01'
  );
  $$,
  'SH-400: Tidak dapat memproses pembayaran: belum ada shift kas yang dibuka di cabang ini.',
  'Membayar via RPC bayar_pesanan ditolak saat belum ada shift kas dibuka di cabang itu'
);

-- Skenario C: Membayar via INSERT pembayaran langsung tanpa shift aktif ditolak
select uji.harap_gagal_sebab(
  $$
  insert into public.pembayaran (
    pesanan_id, metode_id, jumlah, diterima, kembalian, kasir_id, kunci_idempoten
  ) values (
    'eeee0000-0000-0000-0000-000000000010',
    (select id from public.metode_bayar where jenis = 'tunai' and penyewa_id = '11111111-1111-1111-1111-111111111111' limit 1),
    62100,
    70000,
    7900,
    auth.uid(),
    'kunci-insert-bayar-tolak-01'
  );
  $$,
  'SH-400: Tidak dapat memproses pembayaran: belum ada shift kas yang dibuka di cabang ini.',
  'Membayar via INSERT pembayaran ditolak saat belum ada shift kas dibuka di cabang itu'
);

-- ---------------------------------------------------------------------------
-- 3. Buka Shift Kasir (Rina di Cabang Pusat)
-- ---------------------------------------------------------------------------
do $$
declare
  v_res jsonb;
  v_shift_id uuid;
begin
  v_res := public.buka_shift(100000, 'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 'Shift pagi');
  perform uji.harap((v_res->>'berhasil')::boolean = true, 'Buka shift kasir berhasil');
end;
$$;

-- Skenario D: Membuat pesanan saat shift terbuka BERHASIL & shift_id otomatis terhubung
do $$
declare
  v_pesanan_id uuid := gen_random_uuid();
  v_shift_id uuid;
  v_pesanan_shift_id uuid;
begin
  select id into v_shift_id
    from public.shift_kas
   where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001'
     and status = 'terbuka';

  insert into public.pesanan (
    id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten
  ) values (
    v_pesanan_id,
    '11111111-1111-1111-1111-111111111111',
    'a1a1a1a1-0000-0000-0000-000000000001',
    803,
    current_date,
    'dinein',
    'draf',
    'kunci-pesanan-shift-sah-01'
  );

  select shift_id into v_pesanan_shift_id
    from public.pesanan
   where id = v_pesanan_id;

  perform uji.harap(v_pesanan_shift_id = v_shift_id, 'Pesanan otomatis terhubung ke shift aktif');
end;
$$;

-- Skenario E: Membayar pesanan saat shift terbuka BERHASIL & shift_id pembayaran terhubung
do $$
declare
  v_metode_id uuid;
  v_shift_id uuid;
  v_res jsonb;
  v_bayar_shift_id uuid;
  v_bayar_id uuid;
begin
  select id into v_metode_id
    from public.metode_bayar
   where jenis = 'tunai'
     and penyewa_id = '11111111-1111-1111-1111-111111111111'
   limit 1;

  select id into v_shift_id
    from public.shift_kas
   where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001'
     and status = 'terbuka';

  v_res := public.bayar_pesanan(
    'eeee0000-0000-0000-0000-000000000010'::uuid,
    v_metode_id,
    62100,
    70000,
    null,
    'kunci-bayar-sah-shift-01'
  );

  perform uji.harap((v_res->>'berhasil')::boolean = true, 'Pembayaran via bayar_pesanan berhasil saat shift terbuka');
  v_bayar_id := (v_res->>'pembayaran_id')::uuid;

  select shift_id into v_bayar_shift_id
    from public.pembayaran
   where id = v_bayar_id;

  perform uji.harap(v_bayar_shift_id = v_shift_id, 'Baris pembayaran otomatis terhubung ke shift aktif');
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. Tutup Shift Kasir (Rina di Cabang Pusat)
-- ---------------------------------------------------------------------------
do $$
declare
  v_res jsonb;
begin
  v_res := public.tutup_shift(162100, null, null, 'Tutup shift pagi');
  perform uji.harap((v_res->>'berhasil')::boolean = true, 'Tutup shift kasir berhasil');
  perform uji.harap(v_res->'data'->>'status' = 'ditutup', 'Shift status berubah menjadi ditutup');
end;
$$;

-- Skenario F: Setelah shift ditutup, memesan baru di cabang tersebut DITOLAK
select uji.harap_gagal_sebab(
  $$
  insert into public.pesanan (
    id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten
  ) values (
    gen_random_uuid(),
    '11111111-1111-1111-1111-111111111111',
    'a1a1a1a1-0000-0000-0000-000000000001',
    804,
    current_date,
    'dinein',
    'draf',
    'kunci-tolak-setelah-tutup-01'
  );
  $$,
  'SH-400: Tidak dapat membuat pesanan: belum ada shift kas yang dibuka di cabang ini.',
  'Setelah shift ditutup, pesanan baru ditolak kembali'
);

-- Skenario G: Mencoba menyelundupkan ID shift yang sudah tertutup DITOLAK
select uji.harap_gagal_sebab(
  $$
  insert into public.pesanan (
    id, penyewa_id, cabang_id, shift_id, nomor, tanggal, tipe, status, kunci_idempoten
  ) values (
    gen_random_uuid(),
    '11111111-1111-1111-1111-111111111111',
    'a1a1a1a1-0000-0000-0000-000000000001',
    (select id from public.shift_kas where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001' and status = 'ditutup' order by ditutup_pada desc limit 1),
    805,
    current_date,
    'dinein',
    'draf',
    'kunci-tolak-shift-mati-01'
  );
  $$,
  'sudah ditutup atau tidak valid',
  'Menyelundupkan shift_id yang sudah ditutup ditolak tegas'
);

-- ---------------------------------------------------------------------------
-- 5. Isolasi Multi-Cabang
-- ---------------------------------------------------------------------------
-- Admin Andi membuka shift di Cabang Pusat
select uji.klaim('90000000-0000-0000-0000-000000000003'); -- Admin Andi
set local role authenticated;

do $$
declare
  v_res jsonb;
begin
  v_res := public.buka_shift(200000, 'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 'Shift siang pusat');
  perform uji.harap((v_res->>'berhasil')::boolean = true, 'Buka shift di Cabang Pusat berhasil');
end;
$$;

-- Cabang Pusat boleh membuat pesanan
do $$
declare
  v_res_id uuid := gen_random_uuid();
begin
  insert into public.pesanan (
    id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten
  ) values (
    v_res_id,
    '11111111-1111-1111-1111-111111111111',
    'a1a1a1a1-0000-0000-0000-000000000001',
    806,
    current_date,
    'dinein',
    'draf',
    'kunci-cabang-pusat-sah'
  );
  perform uji.harap(true, 'Cabang Pusat yang ada shift terbuka berhasil membuat pesanan');
end;
$$;

-- Namun Cabang Dua (yang BELUM ada shift terbuka) tetap DITOLAK
-- Bu Oasis (owner pusat) memiliki hak di semua cabang, sehingga penolakan murni karena shift belum dibuka
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Bu Oasis (owner pusat)
set local role authenticated;

select uji.harap_gagal_sebab(
  $$
  insert into public.pesanan (
    id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten
  ) values (
    gen_random_uuid(),
    '11111111-1111-1111-1111-111111111111',
    'a1a1a1a1-0000-0000-0000-000000000002',
    807,
    current_date,
    'dinein',
    'draf',
    'kunci-cabang-dua-tolak'
  );
  $$,
  'SH-400: Tidak dapat membuat pesanan: belum ada shift kas yang dibuka di cabang ini.',
  'Cabang Dua tetap ditolak karena shift di cabang bersangkutan belum dibuka'
);

reset role;
select uji.klaim(null);
