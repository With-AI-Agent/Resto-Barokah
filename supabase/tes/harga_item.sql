-- ============================================================================
-- UJI: HARGA BARIS PESANAN tidak bisa dikarang klien
-- Menutup temuan review PR putaran8 PR-03: `pesanan_item.harga_saat_itu` dan
-- `subtotal` bebas diisi klien, dan izin `ubah_harga` tidak pernah ditegakkan di
-- mana pun — kasir bisa menjual menu Rp27.000 seharga Rp1, dan karena salinan
-- harga beku, angka karangan itu masuk struk & laporan tanpa bisa dikoreksi.
-- ============================================================================

-- Pesanan uji: subtotal 54.000 (kasir, batas diskon 25.000/5%).
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir Rina
set local role authenticated;

-- Kontrol: kasir memang TIDAK berizin ubah harga, dan harga berlaku Nasi Goreng = 27.000.
select uji.sama((select public.boleh('ubah_harga')), false, 'kontrol: kasir tidak berizin ubah_harga');
select uji.sama(
  public.harga_berlaku('beef0000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000001'),
  27000, 'kontrol: harga Nasi Goreng di Pusat = 27.000'
);

-- 1. Harga karangan (Rp1 untuk menu Rp27.000) → DITOLAK.
select uji.harap_gagal_sebab($$insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty)
      values ('eeee0000-0000-0000-0000-000000000010', 'beef0000-0000-0000-0000-000000000001',
              'Nasi Goreng', 1, 5)$$, 'Harga menu ini Rp27000 — mencatat harga lain \(Rp1\) perlu izin ubah harga', 'harga Rp1 untuk menu Rp27.000 DITOLAK (izin ubah_harga tidak dimiliki kasir)');

-- 2. Harga jujur → DITERIMA, dan `subtotal` dihitung peladen walau klien mengirim angka ngawur.
insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal, catatan)
values ('eeee0000-0000-0000-0000-000000000010', 'beef0000-0000-0000-0000-000000000001',
        'Nasi Goreng', 27000, 2, 5, 'uji harga jujur');
select uji.sama(
  (select pi.subtotal from public.pesanan_item pi where pi.catatan = 'uji harga jujur'),
  54000, 'subtotal dihitung peladen (27.000 x 2), angka kiriman klien (5) diabaikan'
);

-- 3. Harga negatif / nol / qty nol → DITOLAK.
select uji.harap_gagal_sebab($$insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty)
      values ('eeee0000-0000-0000-0000-000000000010', 'beef0000-0000-0000-0000-000000000001',
              'Nasi Goreng', 0, 1)$$, 'Harga saat itu wajib diisi dan harus lebih dari nol', 'harga 0 ditolak');
select uji.harap_gagal_sebab($$insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty)
      values ('eeee0000-0000-0000-0000-000000000010', 'beef0000-0000-0000-0000-000000000001',
              'Nasi Goreng', 27000, 0)$$, 'Jumlah item harus lebih dari nol', 'qty 0 ditolak');
select uji.harap_gagal_sebab($$insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty)
      values ('eeee0000-0000-0000-0000-000000000010', 'beef0000-0000-0000-0000-000000000002',
              'Es Teh', 27000, 1)$$, 'Harga menu ini Rp8000 — mencatat harga lain \(Rp27000\) perlu izin ubah harga', 'harga yang bukan harga menu itu ditolak');

-- 4. Pemegang izin `ubah_harga` (admin cabang) BOLEH mencatat harga lain —
--    jalur sah untuk promo manual, dan hanya untuk dia.
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000003');   -- admin cabang (punya ubah_harga)
set local role authenticated;
select uji.sama((select public.boleh('ubah_harga')), true, 'kontrol: admin cabang berizin ubah_harga');
insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty)
values ('eeee0000-0000-0000-0000-000000000010', 'beef0000-0000-0000-0000-000000000001',
        'Nasi Goreng (promo manual)', 20000, 1);
select uji.sama(
  (select pi.harga_saat_itu from public.pesanan_item pi
    where pi.pesanan_id = 'eeee0000-0000-0000-0000-000000000010' and pi.harga_saat_itu = 20000),
  20000, 'admin cabang boleh mencatat harga promo (izin ubah_harga)'
);

-- 5. Salinan beku tetap tidak bisa ditulis ulang (aturan lama tidak dilemahkan).
select uji.harap_gagal_sebab($$update public.pesanan_item set harga_saat_itu = 1
     where pesanan_id = 'eeee0000-0000-0000-0000-000000000010' and harga_saat_itu = 20000$$, 'Nama & harga yang sudah tercatat tidak boleh diubah\. Batalkan item itu lalu tambahkan bari', 'harga yang sudah tercatat tetap tidak bisa diubah');

reset role;
select uji.klaim(null);
