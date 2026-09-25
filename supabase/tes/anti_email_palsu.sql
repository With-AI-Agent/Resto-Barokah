-- ============================================================================
-- anti_email_palsu.sql — Uji normalisasi Gmail, saringan email sekali-pakai,
-- dan pengaman 1 voucher per identitas per kampanye (T8-07, ART-5, ART-10).
-- ============================================================================

begin;

-- A. Uji Fungsi public.normalisasi_email
select uji.harap(
  public.normalisasi_email('budi.santoso@kedai-oasis.id') = 'budi.santoso@kedai-oasis.id',
  'T8-07 normalisasi: domain non-Gmail dipertahankan titiknya dan di-lowercase'
);

select uji.harap(
  public.normalisasi_email('B.u.D.i.Santoso@gmail.com') = 'budisantoso@gmail.com',
  'T8-07 normalisasi: titik pada Gmail dihapus bersih'
);

select uji.harap(
  public.normalisasi_email('budisantoso+promo123@gmail.com') = 'budisantoso@gmail.com',
  'T8-07 normalisasi: alias plus (+) pada Gmail dihapus bersih'
);

select uji.harap(
  public.normalisasi_email('b.u.d.i.santoso+diskon.kedai@googlemail.com') = 'budisantoso@gmail.com',
  'T8-07 normalisasi: domain googlemail.com disatukan ke gmail.com dan dibersihkan titik & plus'
);

select uji.harap(
  public.normalisasi_email('   ') is null,
  'T8-07 normalisasi: email kosong menghasilkan null'
);

select uji.harap(
  public.normalisasi_email('budi@@gmail.com') is null,
  'T8-07 normalisasi: format email salah menghasilkan null'
);

-- B. Uji Fungsi public.apakah_email_sekali_pakai
select uji.harap(
  public.apakah_email_sekali_pakai('budi@10minutemail.com') = true,
  'T8-07 disposable: 10minutemail terdeteksi sebagai email sekali-pakai'
);

select uji.harap(
  public.apakah_email_sekali_pakai('ani@tempmail.com') = true,
  'T8-07 disposable: tempmail terdeteksi sebagai email sekali-pakai'
);

select uji.harap(
  public.apakah_email_sekali_pakai('user@mailinator.com') = true,
  'T8-07 disposable: mailinator terdeteksi sebagai email sekali-pakai'
);

select uji.harap(
  public.apakah_email_sekali_pakai('budi@gmail.com') = false,
  'T8-07 disposable: gmail.com bukan email sekali-pakai'
);

-- C. Uji Tabel pelanggan & Trigger Validasi
-- Siapkan data tenant uji
insert into public.penyewa (id, nama, slug)
values ('e0000000-0000-0000-0000-000000000077', 'Resto Barokah Uji', 'resto-barokah-uji')
on conflict (id) do nothing;

-- 1. Penolakan tanpa persetujuan privasi UU PDP (T-011)
select uji.harap_gagal_sebab(
  $$
  insert into public.pelanggan (
    penyewa_id, nama, email, cara_masuk, persetujuan_privasi
  ) values (
    'e0000000-0000-0000-0000-000000000077',
    'Rian Anggoro',
    'rian@gmail.com',
    'email',
    false
  )
  $$,
  'Persetujuan pemrosesan data pribadi \(UU PDP\) wajib diberikan',
  'T8-07 privasi: pendaftaran tanpa persetujuan privasi UU PDP ditolak database (T-011)'
);

-- 2. Penolakan email sekali-pakai di tabel pelanggan
select uji.harap_gagal_sebab(
  $$
  insert into public.pelanggan (
    penyewa_id, nama, email, cara_masuk, persetujuan_privasi
  ) values (
    'e0000000-0000-0000-0000-000000000077',
    'Pelanggan Palsu',
    'palsu@trashmail.com',
    'email',
    true
  )
  $$,
  'Email sekali-pakai tidak diizinkan',
  'T8-07 saringan: email sekali-pakai ditolak pemicu database'
);

-- 3. Berhasil mendaftar dengan normalisasi otomatis
insert into public.pelanggan (
  id, penyewa_id, nama, email, cara_masuk, persetujuan_privasi
) values (
  'a1000000-0000-0000-0000-000000000001',
  'e0000000-0000-0000-0000-000000000077',
  'Budi Santoso',
  'b.u.d.i.santoso+promo@gmail.com',
  'email',
  true
);

select uji.harap(
  (select email_normalisasi from public.pelanggan where id = 'a1000000-0000-0000-0000-000000000001') = 'budisantoso@gmail.com',
  'T8-07 normalisasi: kolom email_normalisasi terisi otomatis oleh pemicu'
);

-- 4. Penolakan pendaftaran duplikat dengan variasi Gmail yang sama
select uji.harap_gagal_sebab(
  $$
  insert into public.pelanggan (
    penyewa_id, nama, email, cara_masuk, persetujuan_privasi
  ) values (
    'e0000000-0000-0000-0000-000000000077',
    'Budi Santoso Klon',
    'budisantoso@gmail.com',
    'email',
    true
  )
  $$,
  'pelanggan_penyewa_email_normalisasi_unik',
  'T8-07 unik: pendaftaran dengan email normalisasi yang sama ditolak indeks unik penyewa'
);

-- D. Uji Kampanye & Voucher (1 identitas = 1 voucher per kampanye)
insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, min_belanja, mulai, selesai, kuota, aktif
) values (
  'c1000000-0000-0000-0000-000000000001',
  'e0000000-0000-0000-0000-000000000077',
  'Promo Grand Opening',
  'OPENING20',
  'nominal',
  20000,
  50000,
  now() - interval '1 hour',
  now() + interval '7 days',
  10,
  true
);

-- Terbitkan voucher pertama
insert into public.voucher (
  penyewa_id, kampanye_id, pelanggan_id, kode, status
) values (
  'e0000000-0000-0000-0000-000000000077',
  'c1000000-0000-0000-0000-000000000001',
  'a1000000-0000-0000-0000-000000000001',
  'BRK-OPEN01',
  'aktif'
);

-- Mencoba memasukkan voucher kedua untuk pelanggan & kampanye yang sama -> harus ditolak
select uji.harap_gagal_sebab(
  $$
  insert into public.voucher (
    penyewa_id, kampanye_id, pelanggan_id, kode, status
  ) values (
    'e0000000-0000-0000-0000-000000000077',
    'c1000000-0000-0000-0000-000000000001',
    'a1000000-0000-0000-0000-000000000001',
    'BRK-OPEN02',
    'aktif'
  )
  $$,
  'voucher_kampanye_id_pelanggan_id_key',
  'T8-07 integritas: satu identitas dilarang memiliki >1 voucher untuk kampanye yang sama'
);

-- E. Uji RPC daftar_voucher
-- 1. Klaim pertama pelanggan baru -> SUKSES
select uji.harap(
  (
    select (hasil->>'berhasil')::boolean
    from public.daftar_voucher(
      'e0000000-0000-0000-0000-000000000077',
      'c1000000-0000-0000-0000-000000000001',
      'Siti Nurhaliza',
      'siti.nurhaliza@kedai.co.id',
      '081299998888',
      'Jl. Sudirman 45',
      true,
      'email'
    ) as hasil
  ) = true,
  'T8-07 RPC: daftar_voucher berhasil menerbitkan voucher untuk pelanggan baru'
);

-- 2. Klaim kedua dari orang yang sama (memakai variasi dot/tag) -> DITOLAK
select uji.harap(
  (
    select hasil->>'kode'
    from public.daftar_voucher(
      'e0000000-0000-0000-0000-000000000077',
      'c1000000-0000-0000-0000-000000000001',
      'Budi Santoso Lagi',
      'b.u.d.i.santoso+klaimlagi@gmail.com',
      '0811111111',
      null,
      true,
      'email'
    ) as hasil
  ) = 'VOUCHER_SUDAH_DIKLAIM',
  'T8-07 RPC: klaim kedua dengan variasi alias Gmail ditolak (VOUCHER_SUDAH_DIKLAIM)'
);

-- 3. Klaim dengan email sekali-pakai -> DITOLAK
select uji.harap(
  (
    select hasil->>'kode'
    from public.daftar_voucher(
      'e0000000-0000-0000-0000-000000000077',
      'c1000000-0000-0000-0000-000000000001',
      'Penyusup',
      'bot@tempmail.com',
      null,
      null,
      true,
      'email'
    ) as hasil
  ) = 'EMAIL_SEKALI_PAKAI',
  'T8-07 RPC: klaim dengan email sekali-pakai ditolak (EMAIL_SEKALI_PAKAI)'
);

-- 4. Klaim tanpa persetujuan privasi -> DITOLAK
select uji.harap(
  (
    select hasil->>'kode'
    from public.daftar_voucher(
      'e0000000-0000-0000-0000-000000000077',
      'c1000000-0000-0000-0000-000000000001',
      'Ahmad',
      'ahmad@gmail.com',
      null,
      null,
      false,
      'email'
    ) as hasil
  ) = 'PRIVASI_WAJIB',
  'T8-07 RPC: klaim tanpa persetujuan privasi ditolak (PRIVASI_WAJIB)'
);

rollback;
