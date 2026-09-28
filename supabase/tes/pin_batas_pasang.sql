-- ============================================================================
-- UJI: pembatas pemasangan PIN (anti-oracle keunikan PIN) — T1-23
--
-- Keunikan PIN ("tidak boleh sama dengan pegawai lain") menjawab ya/tidak.
-- Tanpa pembatas, penyerang yang memegang satu akun sah bisa memakainya sebagai
-- ALAT UKUR: ia tahu PIN-nya sendiri (selalu lolos syarat "PIN lama"), lalu
-- mencoba tiap kemungkinan angka — angka yang dijawab "sudah dipakai" adalah PIN
-- pegawai lain. 1.000.000 kemungkinan jadi bisa ditelusuri.
--
-- Pembatasnya: setiap percobaan pemasangan DICATAT (`percobaan_simpan_pin`) dan
-- dibatasi 20 kali / 15 menit per akun. Diuji PERSIS di sini: percobaan ke-21
-- dikembalikan sebagai pesan "Terlalu banyak…" dan 21 baris tercatat.
--
-- Catatan desain yang diuji tidak langsung: penolakan ini dikembalikan sebagai
-- PESAN (bukan exception) karena exception akan membatalkan baris catatannya
-- sendiri di dalam transaksi yang sama.
-- ============================================================================

-- 0. Pemasangan PIN pertama (jatah ke-1, berhasil).
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner
set local role authenticated;
select uji.sama(public.simpan_pin('274918', null, '90000000-0000-0000-0000-000000000003', 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789'),
                'PIN tersimpan.', 'pemasangan PIN pertama (jatah ke-1)');

-- 1. Jatah ke-2 sampai ke-20: semuanya "PIN kembar" → ditolak & tercatat.
do $$
declare
  v_kembar integer := 0;
  v_lain   integer := 0;
begin
  for i in 1..19 loop
    if public.simpan_pin('274918', null, '90000000-0000-0000-0000-000000000006', 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789')
       like 'PIN itu tidak bisa dipakai%' then
      v_kembar := v_kembar + 1;
    else
      v_lain := v_lain + 1;
    end if;
  end loop;
  perform uji.sama(v_kembar, 19, 'jatah ke-2 sampai ke-20 ditolak sebagai PIN kembar');
  perform uji.sama(v_lain, 0, 'tidak ada jawaban lain di luar dugaan');
end $$;

-- 2. Jatah ke-21: DITOLAK pembatas (bukan lagi karena kembar).
select uji.sama(public.simpan_pin('274918', null, '90000000-0000-0000-0000-000000000006', 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789'),
                'Terlalu banyak percobaan memasang PIN (20 kali / 15 menit). Tunggu sebentar.',
                'percobaan ke-21 dihentikan pembatas anti-oracle');
reset role;
select uji.klaim(null);

-- 3. Catatan lengkap: 21 baris (20 jatah + 1 penolakan pembatas), hanya 1 berhasil.
select uji.sama(
  (select count(*) from public.percobaan_simpan_pin where pengguna_id = '90000000-0000-0000-0000-000000000002'),
  21::bigint,
  'percobaan pemasangan PIN tercatat lengkap (termasuk yang ditolak pembatas)'
);
select uji.sama(
  (select count(*) from public.percobaan_simpan_pin where pengguna_id = '90000000-0000-0000-0000-000000000002' and berhasil),
  1::bigint,
  'hanya pemasangan yang benar-benar berhasil ditandai berhasil'
);
-- 4. Catatan itu tidak bisa dibaca klien.
select uji.sama(has_table_privilege('authenticated', 'public.percobaan_simpan_pin', 'select'), false,
                'peran authenticated tidak punya hak baca percobaan_simpan_pin');
