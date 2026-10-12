-- ============================================================================
-- PROBE HAKIM F-06 (2026-09-29) — reproduksi independen PMB1-F-082
-- (probe milik pemeriksa: bukti/F-06-persetujuan-perangkat-bypass.sql)
--
-- ATURAN BACA HASIL: berkas ini LULUS = CACATNYA NYATA (konvensi probe PMB).
-- Kalau suatu hari RPC-nya benar (menolak login tanpa baris persetujuan),
-- berkas ini WAJIB menjadi MERAH.
--
-- Yang diuji: RPC public.verifikasi_pin_perangkat (definisi berlaku di 0087)
-- TIDAK sekali pun membaca tabel public.persetujuan_perangkat, padahal
-- docs/KEAMANAN.md §4 mewajibkan persetujuan pemilik untuk pasangan
-- (pegawai x perangkat) baru.
--
-- Beda dari probe pemeriksa: perangkat yang dipakai BERBEDA
-- (hp-atasan de...006, bukan hp-kasir de...003) dan tabel
-- persetujuan_perangkat dikosongkan untuk SELURUH penyewa (bukan hanya satu
-- pasangan) supaya tidak ada satu pun baris persetujuan yang menyelamatkan.
--
-- Catatan urutan: penyiapan (PIN, update perangkat, delete persetujuan)
-- dijalankan sebagai pemilik tabel (tanpa set role), sama seperti berkas
-- data uji; hanya PEMANGGILAN RPC login yang duduk di kursi anon.
-- ============================================================================

-- --- penyiapan sebagai pemilik tabel -------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');

-- Owner memasang PIN 731904 untuk kasir Rina (pengguna 90000000-...-004)
select public.simpan_pin(
  '731904',
  null,
  '90000000-0000-0000-0000-000000000004',
  'de000000-0000-0000-0000-000000000001',
  'kunci-uji-hp-owner-0123456789'
);

-- Pastikan perangkat hp-atasan (de...006) aktif & mengizinkan peran kasir
update public.perangkat
   set aktif = true,
       status = 'aktif',
       peran_diizinkan = array['kasir', 'pelayan', 'dapur', 'admin_cabang', 'owner_pusat']::text[]
 where id = 'de000000-0000-0000-0000-000000000006';

-- Kosongkan SELURUH persetujuan_perangkat penyewa A (bukan hanya pasangan Rina)
delete from public.persetujuan_perangkat
 where penyewa_id = '11111111-1111-1111-1111-111111111111';

-- --- pemanggilan RPC dari kursi anon (seperti klien, auth.ts:176) --------
select uji.klaim(null);
set local role anon;

select uji.sama(
  (public.verifikasi_pin_perangkat(
    'kasir.a1@contoh.test',
    '731904',
    'de000000-0000-0000-0000-000000000006'::uuid,
    'HP Atasan',
    'kunci-uji-hp-atasan-0123456789'
  )->>'berhasil')::boolean,
  true,
  'CACAT NYATA: kasir masuk di perangkat terdaftar TANPA baris persetujuan_perangkat'
);

-- Kembali ke kursi pemilik tabel dulu: peran anon tidak punya hak baca
-- tabel persetujuan_perangkat, jadi hitungannya wajib dibaca dari kursi pemilik.
reset role;
select uji.klaim(null);

-- Bukti pendukung: sesudah login, tabel persetujuan_perangkat tetap kosong
select uji.sama(
  (select count(*) from public.persetujuan_perangkat)::text,
  '0',
  'CACAT NYATA: tidak ada satu pun baris persetujuan_perangkat yang dibuat/dibutuhkan'
);
