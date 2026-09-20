-- ============================================================================
-- UJI: status pesanan hanya berpindah lewat jalur resmi (bukan dikarang klien)
-- Temuan audit AUD-3 K-2 (A F-03 / B F-02, 2026-09-17): policy `pesanan_ubah`
-- mengizinkan kasir/pelayan meng-UPDATE baris pesanan, dan TIDAK ADA penjaga
-- yang mengatur perpindahan status — kasir bisa memindahkan pesanan menjadi
-- `lunas` tanpa satu rupiah pun masuk, atau melompat ke `dimasak` seenaknya.
-- Aturan yang dikunci (TECH_SPEC §4.3):
--   draf → dikirim              : owner/admin/kasir/pelayan
--   dikirim → dimasak → siap    : owner/admin/dapur
--   → lunas                     : HANYA peladen (setelah uangnya benar-benar masuk)
--   → batal                     : HANYA lewat jalur pembatalan (pemicu peladen)
--   tanda `dikirim_ke_dapur_pada` hanya boleh DIISI saat mengirim, tidak boleh dihapus.
-- ============================================================================

-- Kasir membuat pesanan baru (draf) seperti di aplikasi.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
insert into public.pesanan (penyewa_id, cabang_id, tanggal, tipe, kunci_idempoten)
values ('11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001',
        current_date, 'dinein', 'status-pesanan-uji');
select uji.sama(
  (select p.status from public.pesanan p where p.kunci_idempoten = 'status-pesanan-uji'),
  'draf', 'pesanan baru mulai dari draf'
);

-- 1. LUNAS tanpa uang → DITOLAK.
select uji.harap_gagal_sebab($$update public.pesanan set status = 'lunas' where kunci_idempoten = 'status-pesanan-uji'$$, 'Perpindahan status pesanan draf → lunas tidak diizinkan dari perangkat — status itu hanya', 'klien TIDAK boleh memindahkan status pesanan menjadi lunas');

-- 2. Melompat ke dimasak (belum dikirim) → DITOLAK.
select uji.harap_gagal_sebab($$update public.pesanan set status = 'dimasak' where kunci_idempoten = 'status-pesanan-uji'$$, 'Perpindahan status pesanan draf → dimasak tidak diizinkan dari perangkat — status itu hany', 'klien tidak boleh melompati urutan status (draf → dimasak)');

-- 3. Jalur resmi: kirim ke dapur (draf → dikirim) → DITERIMA, tanda waktunya terisi.
select uji.harap_gagal_sebab($$update public.pesanan set status = 'dikirim' where kunci_idempoten = 'status-pesanan-uji'$$, 'Mengirim pesanan ke dapur wajib menyertakan waktu kirim \(dikirim_ke_dapur_pada\)', 'mengirim pesanan WAJIB menyertakan waktu kirim ke dapur');
update public.pesanan set status = 'dikirim', dikirim_ke_dapur_pada = now()
 where kunci_idempoten = 'status-pesanan-uji';
select uji.sama(
  (select p.status from public.pesanan p where p.kunci_idempoten = 'status-pesanan-uji'),
  'dikirim', 'kasir boleh mengirim pesanan ke dapur (draf → dikirim)'
);

-- 4. Tanda kirim ke dapur TIDAK boleh dihapus (kalau boleh, pembatalan bisa
--    "diturunkan" jadi sebelum dapur dan lolos tanpa persetujuan PIN).
select uji.harap_gagal_sebab($$update public.pesanan set dikirim_ke_dapur_pada = null where kunci_idempoten = 'status-pesanan-uji'$$, 'Tanda kirim ke dapur tidak boleh diubah atau dihapus', 'tanda kirim ke dapur tidak boleh dihapus klien');
reset role;
select uji.klaim(null);

-- 5. Peran yang memang bukan penggerak dapur TIDAK boleh memajukan status.
select uji.klaim('90000000-0000-0000-0000-000000000005');   -- pelayan (cabang Pusat)
set local role authenticated;
select uji.harap_gagal_sebab($$update public.pesanan set status = 'dimasak' where kunci_idempoten = 'status-pesanan-uji'$$, 'Peran pelayan tidak boleh memajukan status dapur', 'pelayan tidak boleh memajukan status dapur');
reset role;
select uji.klaim(null);

-- 6. Owner (berwenang di seluruh restonya) boleh memajukan status.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.harap_gagal_sebab($$update public.pesanan set status = 'draf' where kunci_idempoten = 'status-pesanan-uji'$$, 'Perpindahan status pesanan dikirim → draf tidak diizinkan dari perangkat — status itu hany', 'status tidak boleh mundur');
update public.pesanan set status = 'dimasak' where kunci_idempoten = 'status-pesanan-uji';
update public.pesanan set status = 'siap' where kunci_idempoten = 'status-pesanan-uji';
select uji.sama(
  (select p.status from public.pesanan p where p.kunci_idempoten = 'status-pesanan-uji'),
  'siap', 'owner boleh memajukan dikirim → dimasak → siap'
);
reset role;
select uji.klaim(null);

-- 7. Jalur peladen tetap boleh menetapkan lunas (nanti dipakai fungsi pembayaran/T1-15).
update public.pesanan set status = 'lunas' where kunci_idempoten = 'status-pesanan-uji';
select uji.sama(
  (select p.status from public.pesanan p where p.kunci_idempoten = 'status-pesanan-uji'),
  'lunas', 'jalur peladen (pemilik tabel) tetap boleh menetapkan lunas'
);
