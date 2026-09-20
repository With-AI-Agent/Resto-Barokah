-- ============================================================================
-- UJI: BARIS PESANAN TIDAK BISA DIPALSUKAN DARI PERANGKAT
-- Menutup temuan review putaran13 #1 PR-01 (K-1: dapur menulis `subtotal=1` →
-- nilai kerugian pembatalan palsu) dan PR-05 review putaran13 #2 (dapur mengubah
-- qty pesanan) serta audit F-02 (item `batal` tanpa satu baris pembatalan).
-- ============================================================================

-- Pesanan contoh di Cabang Dua (tempat dapur bertugas) sebagai PELADEN.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000f002','11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000002', 41, current_date, 'dinein', 'dikirim', 'item-penjaga');
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('00000000-0000-0000-0000-00000000f102','00000000-0000-0000-0000-00000000f002',
        'beef0000-0000-0000-0000-000000000001','Nasi Goreng',27000,2,54000);
update public.pesanan set dikirim_ke_dapur_pada = now() - interval '3 minutes'
 where id = '00000000-0000-0000-0000-00000000f002';

-- 1. DAPUR: subtotal kiriman diabaikan (dihitung ulang peladen dari harga × jumlah).
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
update public.pesanan_item set subtotal = 1
 where id = '00000000-0000-0000-0000-00000000f102';
reset role;
select uji.sama(
  (select pi.subtotal from public.pesanan_item pi where pi.id = '00000000-0000-0000-0000-00000000f102'),
  54000, 'subtotal TIDAK mengikuti angka klien (1) — peladen menulis 27.000 × 2 = 54.000'
);

-- 2. DAPUR: tidak boleh mengubah isi pesanan (qty).
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.harap_gagal_sebab($$update public.pesanan_item set qty = 1 where id = '00000000-0000-0000-0000-00000000f102'$$, 'Dapur hanya boleh memajukan status masak — isi pesanan \(jumlah, harga, catatan\) tidak bole', 'dapur TIDAK boleh mengecilkan jumlah pesanan (dapur tidak menjual)');
-- Dinaikkan pun tidak boleh: arah apa pun tetap mengubah ISI transaksi yang bukan
-- kewenangan dapur. (Uji ini juga pembeda penting untuk bukti mutasi: mengecilkan qty
-- ditahan DUA penjaga — aturan dapur dan aturan jejak pembatalan — sedangkan menaikkan
-- qty hanya bisa ditahan oleh aturan dapur.)
select uji.harap_gagal_sebab($$update public.pesanan_item set qty = 3 where id = '00000000-0000-0000-0000-00000000f102'$$, 'Dapur hanya boleh memajukan status masak — isi pesanan \(jumlah, harga, catatan\) tidak bole', 'dapur TIDAK boleh menaikkan jumlah pesanan');

-- 3. DAPUR: pekerjaannya (memajukan status masak) tetap boleh.
update public.pesanan_item set status = 'dimasak' where id = '00000000-0000-0000-0000-00000000f102';
select uji.sama(
  (select pi.status from public.pesanan_item pi where pi.id = '00000000-0000-0000-0000-00000000f102'),
  'dimasak', 'dapur tetap bisa memajukan status masak (penjaga tidak menutup pekerjaannya)'
);
reset role;
select uji.klaim(null);

-- 4. KASIR: membatalkan item setelah dapur mulai TANPA baris pembatalan → DITOLAK.
select uji.klaim('90000000-0000-0000-0000-000000000005');   -- Dedi (pelayan) bertugas di Cabang Dua
set local role authenticated;
select uji.harap_gagal_sebab($$update public.pesanan_item set status = 'batal' where id = '00000000-0000-0000-0000-00000000f102'$$, 'Pembatalan item setelah dapur mulai wajib lewat baris pembatalan resmi \(alasan \+ persetuju', 'item dibatalkan setelah dapur mulai WAJIB lewat baris pembatalan resmi (alasan + PIN)');
select uji.harap_gagal_sebab($$update public.pesanan_item set qty = 1 where id = '00000000-0000-0000-0000-00000000f102'$$, 'Pembatalan item setelah dapur mulai wajib lewat baris pembatalan resmi \(alasan \+ persetuju', 'mengecilkan qty setelah dapur mulai juga wajib berjejak');
reset role;
select uji.klaim(null);

-- 5. Dengan baris pembatalan yang SAH (kupon PIN), pembatalan item boleh.
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner (berizin void) memasang PIN
set local role authenticated;
select public.simpan_pin('738294', null, null, 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789');
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000006', 'kunci-uji-hp-atasan-0123456789', '00000000-0000-0000-0000-00000000f002')).berhasil,
  true, 'kontrol: PIN owner diverifikasi untuk aksi void pesanan ini'
);
insert into public.pembatalan (pesanan_id, pesanan_item_id, tahap, disetujui_oleh, alasan, bahan_terbuang)
values ('00000000-0000-0000-0000-00000000f002', '00000000-0000-0000-0000-00000000f102',
        'sesudah_dapur', '90000000-0000-0000-0000-000000000002', 'probe: salah masak', true);
select uji.sama(
  (select pi.status from public.pesanan_item pi where pi.id = '00000000-0000-0000-0000-00000000f102'),
  'batal', 'item berstatus batal SETELAH ada baris pembatalan sah'
);
select uji.sama(
  (select p.status from public.pesanan p where p.id = '00000000-0000-0000-0000-00000000f002'),
  'batal', 'pesanan yang dibatalkan TIDAK tinggal berstatus hidup (temuan review #1 PR-03)'
);
reset role;
select uji.klaim(null);
