-- ============================================================================
-- UJI: stempel lifecycle pesanan hanya lahir dari jalur peladen
-- Temuan AUD-3 2026-09-19 F-06 (K-2), dibuktikan nyata lewat probe sesi kerja:
-- docs/uji/audit/probe-2026-09-20/aud-3-f03-f05-f06-uang.sql
-- ============================================================================
-- Aturan yang dijaga: `dibayar_pada`, `dibatalkan_pada`, dan `alasan_batal` adalah JEJAK
-- KEJADIAN. Perangkat kasir tidak boleh mengarangnya lewat UPDATE biasa — kalau boleh,
-- laporan membaca "pernah dibayar" / "pernah dibatalkan" untuk kejadian yang tidak terjadi,
-- dan bukti pembatalan (baris `pembatalan` ber-PIN bila sesudah dapur) bisa dilewati.
-- Jalur peladen (pemicu pembayaran/pembatalan, RPC SECURITY DEFINER) tetap bebas.
-- ============================================================================

select uji.klaim(null);   -- pemilik tabel: menyiapkan pesanan uji
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('e6000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 994, current_date, 'dinein', 'draf', 'uji-lifecycle-1');

-- 1. Kasir mengarang stempel bayar → DITOLAK.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$update public.pesanan set dibayar_pada = now()
     where id = 'e6000000-0000-0000-0000-000000000001'$$,
  'dibayar_pada',
  'F-06: kasir tidak boleh menstempel "sudah dibayar" tanpa pembayaran'
);
-- 2. Kasir mengarang stempel batal & alasan → DITOLAK.
select uji.harap_gagal_sebab(
  $$update public.pesanan set dibatalkan_pada = now(), alasan_batal = 'dibatalkan tanpa jejak'
     where id = 'e6000000-0000-0000-0000-000000000001'$$,
  'Stempel pembatalan',
  'F-06: kasir tidak boleh mengarang stempel pembatalan'
);
select uji.harap_gagal_sebab(
  $$update public.pesanan set alasan_batal = 'alasan karangan'
     where id = 'e6000000-0000-0000-0000-000000000001'$$,
  'Stempel pembatalan',
  'F-06: alasan batal juga tidak boleh dikarang'
);
select uji.sama(
  (select (p.status, p.dibayar_pada is null, p.dibatalkan_pada is null, p.alasan_batal is null)
     from public.pesanan p where p.id = 'e6000000-0000-0000-0000-000000000001'),
  ('draf'::text, true, true, true),
  'tak satu pun stempel karangan yang tertulis'
);
-- 4. Jalur SAH yang tetap boleh dari perangkat: mengirim pesanan ke dapur (status + waktu kirim).
insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('e6000000-0000-0000-0000-000000000001', 'beef0000-0000-0000-0000-000000000001',
        'Nasi Goreng', 27000, 1, 27000);
update public.pesanan set status = 'dikirim', dikirim_ke_dapur_pada = now()
 where id = 'e6000000-0000-0000-0000-000000000001';
select uji.sama(
  (select p.status from public.pesanan p where p.id = 'e6000000-0000-0000-0000-000000000001'),
  'dikirim', 'kasir tetap boleh mengirim pesanan ke dapur (status + waktu kirim sah)'
);
reset role;

-- 3b. Pesanan yang stempelnya SUDAH diisi peladen: mengubah atau menghapusnya pun ditolak.
select uji.klaim(null);   -- pemilik tabel (peran peladen)
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('e6000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 995, current_date, 'dinein', 'draf', 'uji-lifecycle-2');
update public.pesanan set dibayar_pada = now() - interval '1 hour'
 where id = 'e6000000-0000-0000-0000-000000000002';
select uji.sama(
  (select p.dibayar_pada is not null from public.pesanan p where p.id = 'e6000000-0000-0000-0000-000000000002'),
  true, 'kontrol: stempel peladen terisi (peran pemilik tabel = jalur peladen)'
);
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir
set local role authenticated;
select uji.harap_gagal_sebab(
  $$update public.pesanan set dibayar_pada = null
     where id = 'e6000000-0000-0000-0000-000000000002'$$,
  'dibayar_pada',
  'F-06: menghapus stempel pembayaran pun ditolak (bukan hanya mengisi)'
);
select uji.harap_gagal_sebab(
  $$update public.pesanan set dibayar_pada = now()
     where id = 'e6000000-0000-0000-0000-000000000002'$$,
  'dibayar_pada',
  'F-06: menggeser waktu bayar juga ditolak'
);
select uji.sama(
  (select p.dibayar_pada is not null from public.pesanan p where p.id = 'e6000000-0000-0000-0000-000000000002'),
  true, 'stempel peladen tetap utuh setelah dua percobaan ditolak'
);
reset role;
select uji.klaim(null);

-- 5. Jalur PELADEN tetap menulis stempel: pembatalan resmi mengisi `dibatalkan_pada` &
--    `alasan_batal` lewat pemicu (perangkat hanya menulis baris `pembatalan`, bukan stempelnya).
select uji.klaim(null);   -- pemilik tabel: pesanan ketiga yang belum dikirim ke dapur
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('e6000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 996, current_date, 'dinein', 'draf', 'uji-lifecycle-3');
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('e6000000-0000-0000-0000-000000000301', 'e6000000-0000-0000-0000-000000000003',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 1, 27000);
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
insert into public.pembatalan (pesanan_id, tahap, alasan)
values ('e6000000-0000-0000-0000-000000000003', 'sebelum_dapur', 'pelanggan membatalkan');
reset role;
select uji.klaim(null);
select uji.sama(
  (select (p.status, p.dibatalkan_pada is not null, p.alasan_batal)
     from public.pesanan p where p.id = 'e6000000-0000-0000-0000-000000000003'),
  ('batal'::text, true, 'pelanggan membatalkan'::text),
  'kontrol: stempel pembatalan terisi oleh jalur peladen (pemicu pembatalan), bukan perangkat'
);
-- 6. Jalur peladen juga boleh memperbaiki stempel (mis. RPC pembayaran nanti) — dijaga
--    blok 3b di atas: peran pemilik tabel menulis stempel, perangkat tetap tidak bisa.
select uji.sama(
  (select p.dibayar_pada is not null from public.pesanan p where p.id = 'e6000000-0000-0000-0000-000000000002'),
  true, 'kontrol penutup: stempel peladen tetap utuh'
);
