-- Probe HAKIM H-F-03.5 (2026-10-02) — jalur UBAH (UPDATE) nomor HP pelanggan sesudah migrasi 0095.
-- Header 0095 (baris 23-24) mengakui pemicu hanya BEFORE INSERT; kolom Perbaikan PMB1-F-038 menulis
-- "satu nomor = satu identitas pada jalur apa pun". Probe ini mengukur selisih keduanya.
-- CARA BACA  : konvensi PMB — HIJAU (LULUS) = celah HIDUP: admin_cabang boleh mengubah nomor, nilai tersimpan
--              MENTAH (tanda plus dan spasi utuh) dan kunci unik tidak menangkap kesamaannya dengan nomor lain.
-- KONTROL    : negatif = jalur INSERT dengan bentuk mentah yang sama DINORMALISASI pemicu (pagar insert hidup);
--              positif = pelanggan lain tidak ikut berubah (UPDATE tepat sasaran).
-- KURSI      : admin_cabang Pak Andi (90000000-0000-0000-0000-000000000003), kebijakan RLS pelanggan_ubah asli.
-- Runner selalu ROLLBACK. Tidak menyentuh produksi.

-- Data awal disisipkan sebagai pemilik tabel (pemicu INSERT tetap menyala).
insert into public.pelanggan (penyewa_id, nama, cara_masuk, didaftarkan_oleh, persetujuan_privasi, telepon)
values
  ('11111111-1111-1111-1111-111111111111', 'UBAH-A', 'kasir', '90000000-0000-0000-0000-000000000004', true, '0812-3456-7890'),
  ('11111111-1111-1111-1111-111111111111', 'UBAH-B', 'kasir', '90000000-0000-0000-0000-000000000004', true, '0813-9999-8888'),
  ('11111111-1111-1111-1111-111111111111', 'UBAH-C', 'kasir', '90000000-0000-0000-0000-000000000004', true, '+62 856-1111-2222');

-- KONTROL NEGATIF: jalur INSERT menormalkan bentuk mentah (+62 856-1111-2222 -> 085611112222)
select uji.harap(
  (select telepon from public.pelanggan where nama = 'UBAH-C') = '085611112222',
  'kontrol negatif: INSERT dengan +62 856-1111-2222 tersimpan ternormalisasi 085611112222'
);

select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;

do $$
declare
  v_baris int;
begin
  update public.pelanggan set telepon = '+62 812-3456-7890' where nama = 'UBAH-B';
  get diagnostics v_baris = row_count;
  perform uji.harap(v_baris = 1, 'admin_cabang berhasil mengubah satu baris pelanggan');
end $$;

-- CELAH: nilai tersimpan MENTAH; dan UBAH-B kini memegang nomor yang sama dengan UBAH-A tanpa ditolak
select uji.harap(
  (select telepon from public.pelanggan where nama = 'UBAH-B') = '+62 812-3456-7890',
  'CELAH: UPDATE oleh admin menyimpan nomor mentah "+62 812-3456-7890" (tidak dinormalisasi)'
);
select uji.harap(
  (select count(*) from public.pelanggan
    where nama in ('UBAH-A', 'UBAH-B')
      and regexp_replace(telepon, '\D', '', 'g') in ('081234567890', '6281234567890')) = 2,
  'CELAH: dua pelanggan kini memegang nomor yang sama (0812-3456-7890 = +62 812-3456-7890) tanpa ditolak kunci unik'
);

-- KONTROL POSITIF: UBAH-A tidak ikut berubah
select uji.harap(
  (select telepon from public.pelanggan where nama = 'UBAH-A') = '081234567890',
  'kontrol positif: UBAH-A tetap 081234567890'
);
