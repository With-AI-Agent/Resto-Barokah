-- ============================================================================
-- UJI HAKIM H-F-08 — reproduksi independen PMB1-F-109 (T1-28)
--
-- Pertanyaan: apakah mode dukungan `pemilik_platform` benar-benar HANYA-BACA?
-- DoD ROADMAP T1-28 (docs/ROADMAP.md:454) dan Verifikasi (:457) Compagnie:
--   "dengan mode → tulis ditolak" serta "kedaluwarsa → ditolak lagi".
--
-- Mekanisme yang diuji (dipanggil sungguhan, bukan fungsi pg_temp):
--   public.masuk_mode_dukungan(...)         0031_mode_dukungan_platform.sql:114
--   public.simpan_urutan_metode_bayar(...) 0076_metode_bayar_tip.sql:409
-- 0031 menulis ulang public.penyewa_saya() agar mengembalikan penyewa_id
-- resto SASARAN ketika pemilik_platform punya baris mode_dukungan aktif
-- (0031:52-69). 0076 hanya memakai penyewa_saya() tanpa memeriksa peran_saya().
--
-- Kontrol negatif: pemanggilan yang SAMA dari kursi yang SAMA tanpa mode
-- dukungan harus DITOLAK dengan alasan penyewa tidak ditemukan.
--
-- Jalankan: node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-F-08-mode-dukungan-tulis.sql
-- ============================================================================

-- Data uji: satu metode bayar milik Kedai Oasis (penyewa 1111…), urutan awal 1.
insert into public.metode_bayar (id, penyewa_id, nama, jenis, urutan)
values ('0f0f0f0f-0000-4000-8000-0000000f0808', '11111111-1111-1111-1111-111111111111',
        'TUNAI UJI HAKIM F-08', 'tunai', 1);

-- KONTROL NEGATIF: pemilik_platform TANPA mode dukungan.
-- public.penyewa_saya() = null (tidak punya penyewa sendiri) → RPC melempar.
select uji.klaim('90000000-0000-0000-0000-000000000001');
set local role authenticated;

select uji.harap_gagal_sebab(
  'select public.simpan_urutan_metode_bayar(jsonb_build_array(jsonb_build_object(''id'', ''0f0f0f0f-0000-4000-8000-0000000f0808'', ''urutan'', 99)))',
  'Penyewa tidak ditemukan',
  'Tanpa mode dukungan, pemilik_platform tidak boleh bisa menulis (kontrol)'
);

-- UJI UTAMA: masuk mode dukungan ke resto sasaran, lalu coba tulis.
select uji.harap(
  (public.masuk_mode_dukungan(
     '11111111-1111-1111-1111-111111111111'::uuid,
     'Uji hakim F-08 mode dukungan', 30
   ) ->> 'berhasil')::boolean,
  'Pemilik platform berhasil membuka mode dukungan (langkah prasyarat)'
);

select uji.harap(
  (public.simpan_urutan_metode_bayar(
     jsonb_build_array(jsonb_build_object(
       'id', '0f0f0f0f-0000-4000-8000-0000000f0808'::uuid,
       'urutan', 99))
   ) ->> 'jumlah')::int = 1,
  'BUKTI: pemilik_platform MENULIS data resto sasaran lewat RPC saat mode dukungan aktif'
);

reset role;
select uji.klaim(null);

-- Buktiindependent: baris resto sasaran benar-benar berubah di luar sesi RPC.
select uji.sama(
  (select urutan from public.metode_bayar
    where penyewa_id = '11111111-1111-1111-1111-111111111111'
      and nama = 'TUNAI UJI HAKIM F-08'),
  99,
  'Data resto sasaran (Kedai Oasis) berubah urutan 1 -> 99 oleh pemilik platform'
);

-- Tutup mode dukungan & bersihkan jejak percobaan supaya tidak mengotori uji lain.
select uji.klaim('90000000-0000-0000-0000-000000000001');
set local role authenticated;
select public.keluar_mode_dukungan('11111111-1111-1111-1111-111111111111');
reset role;
select uji.klaim(null);

delete from public.mode_dukungan where penyewa_id = '11111111-1111-1111-1111-111111111111';
delete from public.metode_bayar
 where penyewa_id = '11111111-1111-1111-1111-111111111111'
   and nama = 'TUNAI UJI HAKIM F-08';
