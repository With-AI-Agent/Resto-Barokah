-- ============================================================================
-- PROBE HAKIM H-F-17.2 — bukti runtime untuk temuan kalibrasi PMB1-F-192, F-193, F-194, F-195, F-197
--
-- Yang dipanggil (artefak SUNGGUHAN, bukan salinan): migrasi 0001–0087 diterapkan penuh oleh runner
--   alat/uji-sql.mjs lalu probe ini memanggil:
--     A. public.ikat_sesi_perangkat(...)            0030:431-508   (umur sesi per peran)      -> PMB1-F-197
--     B. public.verifikasi_pin_perangkat(...)       0087:35-318    (kunci login 5x, bukan 10x) -> PMB1-F-195
--        + tabel yang benar-benar ditulis jalur masuk asli (percobaan_pin vs percobaan_masuk)      -> PMB1-F-196
--     C. tabel pembatalan / pesanan (pemicu BY-201)  0022:41-93     (void sesudah bayar)       -> PMB1-F-192
--     D. katalog kolom hasil migrasi                 0002:91, 0048:28 (bawaan diskon & wajib_shift) -> PMB1-F-193/F-194
--
-- KONTROL NEGATIF (wajib merah): tiap bagian punya versi "mutan" — nilai yang DIKLAIM bahan kalibrasi / pemeriksa
--   (pemilik platform 30 hari; kunci baru setelah 10x; void sesudah bayar boleh; bawaan tiga diskon;
--    jalur masuk asli menulis percobaan_masuk)
--   ditukar ke pernyataan harapan. Skrip pembungkus `H-F-17.2-jalankan.sh` menjalankan mutan itu dan
--   MEWAJIBKAN merah dengan pesan yang memuat nilai nyata. Kalau mutan lolos, probe ini tumpul.
-- KONTROL POSITIF: peran/keadaan pembanding (kasir 12 jam, owner 30 hari, 4x salah belum terkunci,
--   void SEBELUM bayar tetap sah) membuktikan RPC-nya hidup dan probe bisa hijau.
--
-- Jalankan: node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-F-17.2-probe-runtime.sql
-- ============================================================================

-- ---------------------------------------------------------------------------
-- A. PMB1-F-197 — umur maksimum sesi per peran (RPC ikat_sesi_perangkat, dipanggil sungguhan)
--    Bahan (KEAMANAN-cuplikan:17) mengklaim: admin/owner 30 hari · pemilik platform 30 hari.
-- ---------------------------------------------------------------------------
reset role;
select uji.klaim(null);
insert into public.perangkat (id, penyewa_id, cabang_id, nama, peran_diizinkan)
values ('de000000-0000-0000-0000-00000000f17a', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 'hp-h-f17-sesi',
        array['kasir', 'owner_pusat', 'pemilik_platform']::text[]);
insert into public.kredensial_perangkat (perangkat_id, kunci_hash)
values ('de000000-0000-0000-0000-00000000f17a', crypt('kunci-uji-h-f17-sesi-0123456789', gen_salt('bf', 10)));

-- Kursi pemanggil = Owner Pusat A (…002, resto A): perangkat_sah() menuntut pemanggil se-resto dengan perangkat.
-- RPC menerima p_pengguna_id sebagai parameter (tidak dicocokkan ke auth.uid()), jadi cabang peran->umur
-- dapat dilatih untuk tiga peran dari satu kursi. Umur dibaca dari hasil RPC itu sendiri (now() sama dalam satu transaksi).
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
do $uji$
declare
  v_dev   uuid := 'de000000-0000-0000-0000-00000000f17a';
  v_kunci text := 'kunci-uji-h-f17-sesi-0123456789';
  v_res   jsonb;
  v_umur  interval;
begin
  -- KONTROL POSITIF 1: kasir (staf) = 12 jam
  v_res := public.ikat_sesi_perangkat('sess-h-f17-kasir', v_dev, v_kunci, '90000000-0000-0000-0000-000000000004');
  perform uji.harap((v_res->>'berhasil')::boolean, 'A0 RPC hidup untuk kasir: ' || v_res::text);
  v_umur := (v_res->'data'->>'berakhir_pada')::timestamptz - now();
  perform uji.sama(v_umur, interval '12 hours', 'A1 umur sesi kasir');

  -- KONTROL POSITIF 2: owner_pusat = 30 hari (bagian klaim bahan yang BENAR)
  v_res := public.ikat_sesi_perangkat('sess-h-f17-owner', v_dev, v_kunci, '90000000-0000-0000-0000-000000000002');
  perform uji.harap((v_res->>'berhasil')::boolean, 'A2 RPC hidup untuk owner_pusat: ' || v_res::text);
  v_umur := (v_res->'data'->>'berakhir_pada')::timestamptz - now();
  perform uji.sama(v_umur, interval '30 days', 'A3 umur sesi owner_pusat');

  -- UJI UTAMA: pemilik_platform — bahan bilang 30 hari
  v_res := public.ikat_sesi_perangkat('sess-h-f17-platform', v_dev, v_kunci, '90000000-0000-0000-0000-000000000001');
  perform uji.harap((v_res->>'berhasil')::boolean, 'A4 RPC hidup untuk pemilik_platform: ' || v_res::text);
  v_umur := (v_res->'data'->>'berakhir_pada')::timestamptz - now();
  perform uji.sama(v_umur, interval '8 hours', 'F-197 umur sesi pemilik_platform (MUTASI-A: klaim bahan 30 days)');
end
$uji$;
reset role;
select uji.klaim(null);

-- ---------------------------------------------------------------------------
-- B. PMB1-F-195 — kunci login per akun (RPC verifikasi_pin_perangkat, dipanggil sungguhan dari kursi anon)
--    Bahan (KEAMANAN-cuplikan:8) mengklaim: 10x/15 menit per akun. Kode: 5x (0087:130).
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner memasang PIN kasir Rina
select public.simpan_pin('516372', null, '90000000-0000-0000-0000-000000000004',
                         'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789');
select uji.klaim(null);
update public.perangkat
   set aktif = true, status = 'aktif', peran_diizinkan = array['kasir', 'pelayan', 'dapur']::text[]
 where id = 'de000000-0000-0000-0000-000000000003';
delete from public.percobaan_pin;

set local role anon;
do $uji$
declare
  i int;
  v jsonb;
begin
  -- B1 KONTROL NEGATIF: 4 kali salah BELUM mengunci; PIN benar masih masuk.
  for i in 1..4 loop
    v := public.verifikasi_pin_perangkat('kasir.a1@contoh.test', '111222', 'de000000-0000-0000-0000-000000000003');
    perform uji.sama(v->>'kode', 'KREDENSIAL_TIDAK_VALID', 'B1 salah ke-' || i || ' ditolak biasa (belum terkunci)');
  end loop;
  v := public.verifikasi_pin_perangkat('kasir.a1@contoh.test', '516372', 'de000000-0000-0000-0000-000000000003');
  perform uji.sama(v->>'kode', 'LOGIN_SUKSES', 'B1 setelah 4 salah, PIN benar MASIH masuk (RPC hidup, belum terkunci)');
end
$uji$;

reset role;
delete from public.percobaan_pin;
set local role anon;
do $uji$
declare
  i int;
  v jsonb;
begin
  -- B2 UJI UTAMA: 5 kali salah, lalu PIN BENAR ditolak. Kalau batasnya 10x (klaim bahan), PIN benar ini akan MASUK.
  for i in 1..5 loop
    v := public.verifikasi_pin_perangkat('kasir.a1@contoh.test', '111222', 'de000000-0000-0000-0000-000000000003');
    perform uji.sama(v->>'kode', 'KREDENSIAL_TIDAK_VALID', 'B2 salah ke-' || i || ' tercatat sebagai kegagalan');
  end loop;
  v := public.verifikasi_pin_perangkat('kasir.a1@contoh.test', '516372', 'de000000-0000-0000-0000-000000000003');
  perform uji.sama(v->>'kode', 'AKUN_TERKUNCI', 'F-195 PIN BENAR setelah 5 salah (MUTASI-B: klaim bahan 10x = LOGIN_SUKSES)');
  perform uji.harap(v->>'pesan' like '%5 kali percobaan salah%', 'B3 pesan penolakan menyebut 5 kali: ' || (v->>'pesan'));
  -- percobaan kedua SAAT terkunci (PIN salah lagi): tetap terkunci
  v := public.verifikasi_pin_perangkat('kasir.a1@contoh.test', '111222', 'de000000-0000-0000-0000-000000000003');
  perform uji.sama(v->>'kode', 'AKUN_TERKUNCI', 'B3b percobaan salah saat terkunci tetap AKUN_TERKUNCI');
end
$uji$;

-- B4/E: tabel mana yang ditulis jalur masuk asli? (dibaca dari pemilik tabel, RLS tidak menghalangi)
reset role;
select uji.sama((select count(*) from public.percobaan_pin where not berhasil and pengguna_id = '90000000-0000-0000-0000-000000000004'),
                5::bigint, 'B4 catatan gagal = 5: dua percobaan SAAT terkunci TIDAK ditulis (0087:130-135 kembali sebelum INSERT)');
select uji.harap((select count(*) from public.percobaan_pin) >= 5, 'E0 kontrol: percobaan_pin terisi (jalur tulis asli hidup)');
select uji.sama((select count(*) from public.percobaan_masuk), 0::bigint,
                'F-196 tabel percobaan_masuk KOSONG setelah seluruh alur login asli (MUTASI-E: klaim pemeriksa = jalur asli menulis percobaan_masuk)');

-- ---------------------------------------------------------------------------
-- C. PMB1-F-192 — void sesudah pembayaran pertama, dari KURSI OWNER (bahan: "void masih diperbolehkan dengan PIN owner + alasan")
--    Artefak: pemicu BY-201 (0022) pada public.pembatalan dan public.pesanan.
-- ---------------------------------------------------------------------------
reset role;
select uji.klaim(null);
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, kunci_idempoten)
values ('b5220000-0000-0000-0000-00000000f171', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 9171, 'h-f17-bayar-1'),
       ('b5220000-0000-0000-0000-00000000f172', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 9172, 'h-f17-bayar-2');
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty)
values ('b5220000-0000-0000-0000-00000000f181', 'b5220000-0000-0000-0000-00000000f171',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 2),
       ('b5220000-0000-0000-0000-00000000f182', 'b5220000-0000-0000-0000-00000000f172',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 2);

-- kasir Rina menerima pembayaran pertama SEBAGIAN (Rp1) pada pesanan 1
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
insert into public.pembayaran(pesanan_id, metode_id, jumlah, diterima, kunci_idempoten)
select 'b5220000-0000-0000-0000-00000000f171', id, 1, 1, 'h-f17-bayar-pertama'
  from public.metode_bayar where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai';
reset role;
select uji.klaim(null);
select uji.sama((select status from public.pesanan where id = 'b5220000-0000-0000-0000-00000000f171'), 'draf',
                'C0 kontrol: baru bayar Rp1, pesanan belum lunas');

-- OWNER (Bu Oasis, …002) mencoba void pesanan yang sudah menerima uang — dengan alasan, dan dirinya sebagai penyetuju
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$insert into public.pembatalan(pesanan_id, tahap, pelaku_id, disetujui_oleh, alasan)
    values ('b5220000-0000-0000-0000-00000000f171', 'sesudah_dapur',
            '90000000-0000-0000-0000-000000000002', '90000000-0000-0000-0000-000000000002',
            'void owner + PIN sesudah bayar')$$,
  'BY-201',
  'F-192 owner void tahap sesudah_dapur SESUDAH bayar (MUTASI-C: klaim bahan = boleh)');
select uji.harap_gagal_sebab(
  $$insert into public.pembatalan(pesanan_id, tahap, pelaku_id, disetujui_oleh, alasan)
    values ('b5220000-0000-0000-0000-00000000f171', 'sebelum_dapur',
            '90000000-0000-0000-0000-000000000002', '90000000-0000-0000-0000-000000000002',
            'void owner sebelum_dapur sesudah bayar')$$,
  'BY-201',
  'F-192 owner void tahap sebelum_dapur SESUDAH bayar');
reset role;
select uji.klaim(null);
select uji.harap_gagal_sebab(
  $$update public.pesanan set status = 'batal' where id = 'b5220000-0000-0000-0000-00000000f171'$$,
  'BY-201',
  'F-192 status pesanan berbayar tidak bisa dijadikan batal walau lewat jalur pemilik tabel');
select uji.sama((select count(*) from public.pembatalan where pesanan_id = 'b5220000-0000-0000-0000-00000000f171'),
                0::bigint, 'C1 tidak ada jejak void palsu pada pesanan berbayar');

-- KONTROL POSITIF: pesanan 2 BELUM ada pembayaran -> owner boleh void (aturan T-025 hanya mengunci sesudah uang masuk)
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
insert into public.pembatalan(pesanan_id, tahap, pelaku_id, disetujui_oleh, alasan)
values ('b5220000-0000-0000-0000-00000000f172', 'sebelum_dapur',
        '90000000-0000-0000-0000-000000000002', '90000000-0000-0000-0000-000000000002',
        'kontrol positif: void owner SEBELUM bayar');
reset role;
select uji.klaim(null);
select uji.sama((select status from public.pesanan where id = 'b5220000-0000-0000-0000-00000000f172'), 'batal',
                'C2 KONTROL POSITIF: void owner sebelum bayar tetap sah (probe hidup)');

-- ---------------------------------------------------------------------------
-- D. PMB1-F-193 / F-194 — bawaan skema hasil migrasi (katalog database)
--    F-193: bahan bilang bawaan "sampai tiga diskon" -> kolom tumpuk_diskon bawaan false (SATU diskon)
--    F-194: bahan bilang bawaan wajib_shift false/fleksibel (bagian ini BENAR; yang bertentangan = teks T7-04)
-- ---------------------------------------------------------------------------
select uji.sama(
  (select c.column_default from information_schema.columns c
    where c.table_schema = 'public' and c.table_name = 'pengaturan' and c.column_name = 'tumpuk_diskon'),
  'false', 'F-193 bawaan kolom pengaturan.tumpuk_diskon (MUTASI-D: klaim bahan = bawaan tumpuk true)');
select uji.sama(
  (select c.column_default from information_schema.columns c
    where c.table_schema = 'public' and c.table_name = 'pengaturan' and c.column_name = 'wajib_shift'),
  'false', 'F-194 bawaan kolom pengaturan.wajib_shift = false (fleksibel) — sesuai PRD-cuplikan:23');
