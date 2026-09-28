-- PR-07 (review putaran16): kupon persetujuan WAJIB terikat pesanan.
-- Cacat lama: verifikasi_pin(aksi berkupon, pesanan NULL) menjawab berhasil=true dan
-- menulis baris kupon yang tidak akan pernah cocok dengan saringan konsumen
-- (void 0013 / diskon 0016 menuntut kupon terikat pesanan ini) — "tulis bisa, pakai
-- mustahil". Edge sudah menolak di batas (I F-02); 0016 menambah lapis database.
-- Probe lama: docs/uji/audit/probe-2026-09-19/pr07-kupon-tanpa-pesanan.sql (kini GAGAL).

-- Prasyarat: owner memasang PIN.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(public.simpan_pin('738294', null, null, 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789'), 'PIN tersimpan.', 'prasyarat: owner memasang PIN');
reset role;

-- Kasir memverifikasi PIN owner untuk aksi berkupon TANPA pesanan → DITOLAK.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294',
                         'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789', null)).berhasil,
  false, 'PR-07: kupon void TANPA pesanan tidak lahir lagi');
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294',
                         'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789', null)).pesan like 'Aksi void_sesudah_dapur wajib menyebut pesanan%',
  true, 'PR-07: pesan menyebut kontrak pesanan');
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294',
                         'beri_diskon', 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789', null)).berhasil,
  false, 'PR-07: kupon diskon TANPA pesanan tidak lahir lagi');

-- Kontrol: dengan pesanan, PIN yang sama tetap diterima (jalur sah tidak mati).
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789', 'eeee0000-0000-0000-0000-000000000010')).berhasil,
  true, 'kontrol: kupon DENGAN pesanan tetap lahir');

-- Percobaan yang melanggar kontrak tetap tercatat (jejak + ikut pembatas).
reset role;
select uji.sama(
  (select count(*)::int from public.percobaan_pin
    where perangkat = 'hp-kasir' and not berhasil),
  3, 'PR-07: tiga pelanggaran kontrak tercatat sebagai percobaan gagal');
select uji.klaim(null);
