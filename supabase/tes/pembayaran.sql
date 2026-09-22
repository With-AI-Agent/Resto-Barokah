-- ============================================================================
-- UJI: pembayaran, metode bayar, diskon, pembatalan (T1-10)
-- Membuktikan pagar-pagar uang yang paling penting:
--   * angka uang pesanan tidak bisa dikarang dari perangkat (kasir ditolak,
--     fungsi peladen boleh);
--   * satu pembayaran = satu baris tercatat (tidak dobel, tidak diubah/dihapus);
--   * tunai wajib menyebut uang diterima & kembalian dihitung database;
--     bukan tunai wajib menyebut referensi;
--   * pembayaran tidak boleh melebihi total pesanan;
--   * diskon melebihi batas izin → ditolak; diskon kedua ditolak kecuali resto
--     mengizinkan tumpuk diskon;
--   * pembatalan tanpa alasan → ditolak; tahap harus sesuai; setelah dapur
--     mulai wajib disetujui pengguna berizin; nilai kerugian dari salinan harga.
-- ============================================================================

-- Pesanan uji: eeee…0010 (cabang Pusat, subtotal 54.000, total 62.100, sudah dikirim ke dapur).

-- 1. Sebelum masuk: tidak ada uang yang terlihat.
select uji.klaim(null);
set local role anon;
select uji.sama((select count(*) from public.pembayaran), 0::bigint, 'anon tidak melihat pembayaran');
select uji.sama((select count(*) from public.diskon_transaksi), 0::bigint, 'anon tidak melihat diskon');
select uji.sama((select count(*) from public.pembatalan), 0::bigint, 'anon tidak melihat pembatalan');
select uji.sama((select count(*) from public.metode_bayar), 0::bigint, 'anon tidak melihat metode bayar');
reset role;
select uji.klaim(null);

-- 2. Metode bayar bawaan tersedia per resto, dan hanya owner/admin yang mengubahnya.
select uji.sama(
  (select count(*) from public.metode_bayar where penyewa_id = '11111111-1111-1111-1111-111111111111'),
  4::bigint,
  'resto punya 4 metode bayar bawaan'
);
select uji.sama(
  (select count(*) from public.metode_bayar where penyewa_id = '22222222-2222-2222-2222-222222222222'),
  4::bigint,
  'resto kedua juga punya metode bayar bawaan (terpasang otomatis)'
);

select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir Pusat
set local role authenticated;
select uji.sama((select count(*) from public.metode_bayar), 4::bigint, 'kasir melihat metode bayar restonya');
select uji.harap_gagal_sebab($$insert into public.metode_bayar (penyewa_id, nama, jenis) values ('11111111-1111-1111-1111-111111111111', 'Metode Kasir', 'tunai')$$, 'row-level security policy for table "metode_bayar"', 'kasir tidak boleh menambah metode bayar');

-- 3. TUNai: uang diterima wajib, kembalian dihitung database.
select uji.harap_gagal_sebab($$insert into public.pembayaran (pesanan_id, metode_id, metode_nama_saat_itu, jenis_saat_itu, jumlah, kunci_idempoten)
      values ('eeee0000-0000-0000-0000-000000000010', null, 'Tunai', 'tunai', 50000, 'bayar-tanpa-diterima')$$, 'Pembayaran tunai wajib menyebut uang yang diterima', 'pembayaran tunai tanpa uang diterima ditolak');
select uji.harap_gagal_sebab($$insert into public.pembayaran (pesanan_id, metode_id, metode_nama_saat_itu, jenis_saat_itu, jumlah, diterima, kunci_idempoten)
      values ('eeee0000-0000-0000-0000-000000000010', null, 'Tunai', 'tunai', 50000, 40000, 'bayar-kurang')$$, 'Uang diterima \(', 'uang diterima lebih kecil dari jumlah bayar ditolak');
select uji.harap_gagal_sebab($$insert into public.pembayaran (pesanan_id, metode_id, metode_nama_saat_itu, jenis_saat_itu, jumlah, kunci_idempoten)
      values ('eeee0000-0000-0000-0000-000000000010', null, 'QRIS', 'non_tunai', 10000, 'bayar-tanpa-referensi')$$, 'Pembayaran bukan tunai wajib menyebut nomor referensi', 'pembayaran bukan tunai tanpa referensi ditolak');

insert into public.pembayaran (pesanan_id, metode_id, jumlah, diterima, kunci_idempoten)
select 'eeee0000-0000-0000-0000-000000000010', mb.id, 50000, 100000, 'bayar-1'
  from public.metode_bayar mb
 where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'Tunai';

select uji.sama(
  (select pb.kembalian from public.pembayaran pb where pb.kunci_idempoten = 'bayar-1'),
  50000,
  'kembalian dihitung database (100.000 - 50.000)'
);
select uji.sama(
  (select pb.jenis_saat_itu from public.pembayaran pb where pb.kunci_idempoten = 'bayar-1'),
  'tunai',
  'jenis pembayaran diambil dari metode bayar (bukan dikirim perangkat)'
);

-- 4. Tidak boleh dobel (kunci idempoten sama) & tidak boleh melebihi total pesanan.
-- TEMUAN AUDIT A-17/F-06 (2026-09-18): asersi ini dulu memakai metode_id NULL sehingga
-- DITOLAK karena "bukan tunai wajib menyebut nomor referensi" — lulus karena sebab yang
-- salah, dan kunci uniknya bisa DIHAPUS tanpa satu pun uji merah. Sekarang metode diisi
-- sungguhan dan SEBABNYA diperiksa; bukti mutasinya ada di alat/uji-mutasi-0014.py.
-- Nilai pembayaran nol/negatif: yang menahan harus benar-benar CHECK kolomnya
-- (temuan audit A-24/F-07: penjaga seperti ini bisa dihapus tanpa uji merah).
select uji.harap_gagal_sebab(
  $$insert into public.pembayaran (pesanan_id, metode_id, jumlah, diterima, kunci_idempoten)
      select 'eeee0000-0000-0000-0000-000000000010', mb.id, 0, 20000, 'bayar-nol'
        from public.metode_bayar mb
       where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'Tunai'$$,
  'jumlah',
  'pembayaran bernilai nol ditolak KARENA aturan nilai (CHECK kolom jumlah)'
);
-- Bayar kecil lebih dulu (10.000) supaya pemeriksaan "melebihi total" TIDAK menyala,
-- lalu kirim ulang kunci yang sama: yang menahan harus benar-benar KUNCI uniknya.
insert into public.pembayaran (pesanan_id, metode_id, jumlah, diterima, kunci_idempoten)
select 'eeee0000-0000-0000-0000-000000000010', mb.id, 1000, 2000, 'bayar-idem'
  from public.metode_bayar mb
 where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'Tunai';
select uji.harap_gagal_sebab(
  $$insert into public.pembayaran (pesanan_id, metode_id, jumlah, diterima, kunci_idempoten)
      select 'eeee0000-0000-0000-0000-000000000010', mb.id, 1000, 2000, 'bayar-idem'
        from public.metode_bayar mb
       where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'Tunai'$$,
  'duplicate key|kunci_idempoten|sudah pernah',
  'pembayaran dengan kunci idempoten sama ditolak KARENA KUNCI-nya (bukan karena sebab lain)'
);
reset role;
select uji.klaim(null);

-- Uang yang sudah masuk 50.000, total pesanan 62.100 → baris 20.000 berikutnya
-- akan menjadi 70.000, jadi HARUS ditolak.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab($$insert into public.pembayaran (pesanan_id, metode_id, jumlah, diterima, kunci_idempoten)
      select 'eeee0000-0000-0000-0000-000000000010', mb.id, 20000, 30000, 'bayar-3'
        from public.metode_bayar mb
       where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'Tunai'$$, 'Total pembayaran \(', 'total pembayaran tidak boleh melebihi total pesanan');
select uji.harap_gagal_sebab($$update public.pembayaran set jumlah = 1 where kunci_idempoten = 'bayar-1'$$, 'permission denied for table pembayaran', 'baris pembayaran tidak bisa diubah');
select uji.harap_gagal_sebab($$delete from public.pembayaran where kunci_idempoten = 'bayar-1'$$, 'permission denied for table pembayaran', 'baris pembayaran tidak bisa dihapus');
reset role;
select uji.klaim(null);

-- 5. ANGKA UANG pesanan tidak bisa dikarang dari perangkat.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab($$update public.pesanan set total = 1 where id = 'eeee0000-0000-0000-0000-000000000010'$$, 'Angka uang pesanan hanya boleh diubah oleh fungsi perhitungan peladen \(hitung_total\)', 'kasir tidak boleh mengubah total pesanan langsung');
reset role;
select uji.klaim(null);
select uji.sama(
  (select p.total from public.pesanan p where p.id = 'eeee0000-0000-0000-0000-000000000010'),
  62100,
  'total pesanan tetap 62.100 setelah percobaan ubah dari kasir'
);

-- Jalur SAH: fungsi peladen (SECURITY DEFINER) boleh mengubah angka uang.
create or replace function public._uji_set_total(p_pesanan_id uuid, p_subtotal integer, p_total integer)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  update public.pesanan set subtotal = p_subtotal, total = p_total where id = p_pesanan_id;
end $$;
select public._uji_set_total('eeee0000-0000-0000-0000-000000000010', 54000, 62100);
select uji.sama(
  (select p.total from public.pesanan p where p.id = 'eeee0000-0000-0000-0000-000000000010'),
  62100,
  'fungsi peladen boleh menetapkan angka uang'
);
-- Percobaan mengarang total harus dijalankan SEBAGAI KASIR (kalau dijalankan
-- sebagai pemilik tabel, penjaga memang tidak berlaku — itu jalur peladen).
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab($$insert into public.pesanan (penyewa_id, cabang_id, kunci_idempoten, total) values ('11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001', 'pesanan-total-karangan', 5000)$$, 'Angka uang pesanan hanya boleh diisi oleh fungsi perhitungan peladen \(hitung_total\), bukan', 'pesanan baru dengan total karangan ditolak');
reset role;
select uji.klaim(null);

-- T-025: diskon/void diuji pada pesanan BELUM dibayar, bukan mengubah uang lama.
insert into public.pesanan(id,penyewa_id,cabang_id,nomor,status,kunci_idempoten,dikirim_ke_dapur_pada)
values('eeee0000-0000-0000-0000-000000000023','11111111-1111-1111-1111-111111111111',
 'a1a1a1a1-0000-0000-0000-000000000001',23,'dikirim','kontrol-diskon-void',now());
insert into public.pesanan_item(pesanan_id,menu_item_id,nama_saat_itu,harga_saat_itu,qty)
values('eeee0000-0000-0000-0000-000000000023','beef0000-0000-0000-0000-000000000001','Nasi Goreng',27000,2);

-- 6. DISKON: melebihi batas izin kasir (25.000 / 5%) → ditolak.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab($$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan) values ('eeee0000-0000-0000-0000-000000000023', 'manual', 30000, 30000, 'minta diskon besar')$$, 'Diskon ini melebihi batas izin Anda — minta atasan \(pemilik/admin\) yang memproses', 'diskon melebihi batas nominal kasir ditolak');
select uji.harap_gagal_sebab($$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, persen, nilai, alasan) values ('eeee0000-0000-0000-0000-000000000023', 'manual', 3000, 20, 3000, 'diskon persen besar')$$, 'Diskon ini melebihi batas izin Anda — minta atasan \(pemilik/admin\) yang memproses', 'diskon melebihi batas persen kasir ditolak');
-- CATATAN: dulu di sini tertulis 20.000 — padahal 20.000 dari subtotal 54.000 = 37 %,
-- jauh di atas batas kasir 5 %. Uji ini LULUS karena sebab yang salah (pemeriksaan persen
-- dilewati saat kolom `persen` kosong — temuan audit AUD-3 K-2/B F-06). Sekarang nilainya
-- 2.000 (3,7 %) supaya benar-benar "diskon dalam batas kasir".
insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan)
values ('eeee0000-0000-0000-0000-000000000023', 'manual', 2000, 2000, 'pelanggan langganan');
select uji.sama(
  (select count(*) from public.diskon_transaksi where pesanan_id = 'eeee0000-0000-0000-0000-000000000023'),
  1::bigint,
  'diskon dalam batas kasir berhasil dicatat'
);

-- Diskon KEDUA: ditolak karena resto belum mengizinkan tumpuk diskon.
select uji.harap_gagal_sebab($$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan) values ('eeee0000-0000-0000-0000-000000000023', 'manual', 1000, 1000, 'diskon kedua')$$, 'Resto ini hanya mengizinkan satu diskon per transaksi', 'diskon kedua ditolak saat tumpuk diskon belum diizinkan');
reset role;
select uji.klaim(null);

-- Pemilik restoran mengizinkan tumpuk diskon → diskon kedua boleh.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
update public.pengaturan set tumpuk_diskon = true where penyewa_id = '11111111-1111-1111-1111-111111111111';
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan)
values ('eeee0000-0000-0000-0000-000000000023', 'manual', 1000, 1000, 'tambahan kecil');
select uji.sama(
  (select count(*) from public.diskon_transaksi where pesanan_id = 'eeee0000-0000-0000-0000-000000000023'),
  2::bigint,
  'diskon kedua boleh setelah owner mengizinkan tumpuk diskon'
);

-- Diskon manual tanpa alasan ditolak; diskon melebihi subtotal ditolak.
select uji.harap_gagal_sebab($$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai) values ('eeee0000-0000-0000-0000-000000000023', 'manual', 1000, 1000)$$, 'violates check constraint "diskon_transaksi_check"', 'diskon manual tanpa alasan ditolak');
reset role;
select uji.klaim(null);
-- Diskon yang membuat TOTAL diskon melebihi subtotal: diuji sebagai OWNER
-- (tanpa batas nominal), supaya penolakannya benar-benar dari aturan subtotal,
-- bukan dari batas izin kasir. Diskon yang ada: 20.000 + 1.000 = 21.000;
-- ditambah 40.000 menjadi 61.000 > subtotal 54.000 → harus ditolak.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
-- TEMUAN AUDIT A-17/F-06: asersi lama (40.000) DITOLAK karena "Diskon ini melebihi batas
-- izin Anda" (izinya 20%), bukan karena aturan subtotal — jadi penjaga "total diskon
-- melebihi subtotal" sebenarnya tidak pernah teruji. Di bawah ini dua asersi terpisah:
-- (a) yang benar-benar menguji batas IZIN, dan (b) yang benar-benar menguji aturan SUBTOTAL
-- (tumpuk diskon dinyalakan + cap ditembus lewat BANYAK baris yang masing-masing sah).
select uji.harap_gagal_sebab(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan) values ('eeee0000-0000-0000-0000-000000000023', 'manual', 40000, 40000, 'diskon besar')$$,
  'melebihi batas izin',
  'diskon 40.000 ditolak KARENA batas izin pemakai (20% dari 54.000)'
);
reset role;
select uji.klaim(null);
-- (b) Resto mengizinkan tumpuk diskon & cap 100% (keadaan paling longgar yang sah),
-- lalu owner (batas 100.000 / 20%) menambah diskon bertahap: yang menahan adalah
-- aturan TOTAL DI ATAS SUBTOTAL, bukan izin per baris.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
update public.pengaturan set tumpuk_diskon = true, batas_maks_potongan_persen = 100
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
do $$
declare
  i integer;
  v_pesan text;
begin
  for i in 1..10 loop
    begin
      insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000023', 'manual', 10000, 10000, 'gelombang ' || i);
    exception when others then
      v_pesan := sqlerrm;
      exit;
    end;
  end loop;
  perform uji.harap(
    v_pesan like 'Total diskon%melebihi subtotal%',
    'yang menahan gelombang diskon adalah ATURAN SUBTOTAL, bukan izin per baris (pesan: '
      || coalesce(v_pesan, '(tidak ada yang menahan — penjaga subtotal tumpul!)') || ')'
  );
end $$;
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- Dapur tidak berizin memberi diskon. Beri keanggotaan cabang uji agar
-- satu-satunya sebab penolakan = IZIN, bukan pagar isolasi baru 0022.
reset role;
select uji.klaim(null);
insert into public.pengguna_cabang(pengguna_id,cabang_id)
values('90000000-0000-0000-0000-000000000006','a1a1a1a1-0000-0000-0000-000000000001');
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.harap_gagal_sebab($$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan) values ('eeee0000-0000-0000-0000-000000000023', 'manual', 1000, 1000, 'coba-coba dapur')$$, 'Diskon ini melebihi batas izin Anda — minta atasan \(pemilik/admin\) yang memproses', 'dapur tidak boleh memberi diskon');
reset role;
select uji.klaim(null);

-- 7. PEMBATALAN: tanpa alasan → ditolak; tahap harus sesuai keadaan pesanan.
-- TEMUAN AUDIT A-17/F-06 (2026-09-18): asersi ini dulu lulus karena "Persetujuan belum
-- terbukti … PIN-nya sendiri" — sebab yang DIAKUI di komentarnya tidak pernah teruji,
-- dan CHECK alasan bisa dihapus tanpa satu pun uji merah. Urutan sekarang dijaga:
-- (a) TANPA bukti PIN → ditolak karena persetujuan (yang memang aturannya lebih dulu);
-- (b) DENGAN bukti PIN sah → yang menahan benar-benar CHECK alasan.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$insert into public.pembatalan (pesanan_id, tahap, disetujui_oleh, alasan) values ('eeee0000-0000-0000-0000-000000000023', 'sesudah_dapur', '90000000-0000-0000-0000-000000000002', '   ')$$,
  'Persetujuan belum terbukti',
  'pembatalan tanpa bukti PIN ditolak KARENA persetujuan belum terbukti (urutan aturan)'
);
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner: memasukkan PIN untuk aksi ini
set local role authenticated;
select uji.sama(public.simpan_pin('738294', null, null, 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789'), 'PIN tersimpan.', 'owner memasang PIN untuk uji alasan');
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789', 'eeee0000-0000-0000-0000-000000000023')).berhasil,
  true, 'kontrol: bukti PIN void tersedia untuk pesanan ini'
);
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$insert into public.pembatalan (pesanan_id, tahap, disetujui_oleh, alasan) values ('eeee0000-0000-0000-0000-000000000023', 'sesudah_dapur', '90000000-0000-0000-0000-000000000002', '   ')$$,
  'alasan',
  'pembatalan dengan alasan kosong ditolak KARENA aturan alasan (bukan karena sebab lain)'
);
-- Kontrol positif: alasan yang benar dengan bukti PIN yang sama → DITERIMA.
insert into public.pembatalan (pesanan_id, tahap, disetujui_oleh, alasan, bahan_terbuang)
values ('eeee0000-0000-0000-0000-000000000023', 'sesudah_dapur', '90000000-0000-0000-0000-000000000002',
        'void sesudah dapur dengan bukti PIN', true);
select uji.sama(
  (select count(*) from public.pembatalan b
    where b.pesanan_id = 'eeee0000-0000-0000-0000-000000000023' and b.alasan = 'void sesudah dapur dengan bukti PIN'),
  1::bigint, 'pembatalan sah dengan alasan benar DITERIMA (jalur sah tetap terbuka)'
);
-- Pasangan positifnya: kalimat yang sama dengan alasan benar → diterima.
-- SEJAK AUDIT AUD-3 K-2 (A F-03): persetujuan harus TERBUKTI — penyetuju memasukkan
-- PIN-nya sendiri untuk aksi void_sesudah_dapur (bukan sekadar namanya ditulis).
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner (penyetuju)
reset role;
-- Sejak AUD-3 F-05 (2026-09-20) satu target hanya boleh dibatalkan SEKALI, jadi blok ini
-- memakai pesanan BARU (eeee…0012) — pesanan eeee…0010 sudah ditutup di atas.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status,
                            subtotal, pajak, service, total, kunci_idempoten)
values ('eeee0000-0000-0000-0000-000000000012', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 12, current_date, 'dinein', 'dikirim',
        27000, 2700, 1350, 31050, 'keranjang-uji-uang-3');
update public.pesanan set dikirim_ke_dapur_pada = now() - interval '5 minutes'
 where id = 'eeee0000-0000-0000-0000-000000000012';
insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('eeee0000-0000-0000-0000-000000000012', 'beef0000-0000-0000-0000-000000000001',
        'Nasi Goreng', 27000, 1, 27000);
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner (penyetuju)
set local role authenticated;
-- PIN owner sudah dipasang di blok sebelumnya (uji alasan) — tidak dipasang ulang,
-- supaya blok ini juga menguji hal yang sama tanpa bergantung urutan.
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000006', 'kunci-uji-hp-atasan-0123456789', 'eeee0000-0000-0000-0000-000000000012')).berhasil,
  true, 'PIN owner masih berlaku untuk aksi void pesanan ini'
);
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000006', 'kunci-uji-hp-atasan-0123456789', 'eeee0000-0000-0000-0000-000000000012')).berhasil,
  true, 'PIN penyetuju diverifikasi untuk aksi & pesanan void_sesudah_dapur'
);
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kembali sebagai kasir
set local role authenticated;
insert into public.pembatalan (pesanan_id, tahap, disetujui_oleh, alasan)
values ('eeee0000-0000-0000-0000-000000000012', 'sesudah_dapur', '90000000-0000-0000-0000-000000000002', 'alasan benar sebagai pembanding');
select uji.sama(
  (select count(*) from public.pembatalan where alasan = 'alasan benar sebagai pembanding'),
  1::bigint,
  'pembatalan dengan alasan benar diterima (pembanding)'
);

-- Dua penolakan tahap & satu penolakan izin memakai pesanan KETIGA (eeee…0013) yang masih
-- hidup, supaya yang menolak benar-benar aturan yang dimaksud (bukan aturan idempotensi).
reset role;
select uji.klaim(null);
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status,
                            subtotal, pajak, service, total, kunci_idempoten)
values ('eeee0000-0000-0000-0000-000000000013', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 13, current_date, 'dinein', 'dikirim',
        27000, 2700, 1350, 31050, 'keranjang-uji-uang-4');
update public.pesanan set dikirim_ke_dapur_pada = now() - interval '5 minutes'
 where id = 'eeee0000-0000-0000-0000-000000000013';
insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('eeee0000-0000-0000-0000-000000000013', 'beef0000-0000-0000-0000-000000000001',
        'Nasi Goreng', 27000, 1, 27000);
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab($$insert into public.pembatalan (pesanan_id, tahap, alasan) values ('eeee0000-0000-0000-0000-000000000013', 'sebelum_dapur', 'salah input')$$, 'Tahap pembatalan tidak sesuai keadaan pesanan \(seharusnya sesudah_dapur\)', 'tahap sebelum_dapur ditolak bila pesanan sudah dikirim ke dapur');
select uji.harap_gagal_sebab($$insert into public.pembatalan (pesanan_id, tahap, alasan) values ('eeee0000-0000-0000-0000-000000000013', 'sesudah_dapur', 'salah input')$$, 'Pembatalan setelah dapur mulai wajib disetujui pengguna berizin \(PIN\)', 'pembatalan setelah dapur mulai tanpa penyetuju ditolak');
select uji.harap_gagal_sebab($$insert into public.pembatalan (pesanan_id, tahap, disetujui_oleh, alasan) values ('eeee0000-0000-0000-0000-000000000013', 'sesudah_dapur', '90000000-0000-0000-0000-000000000006', 'minta dapur menyetujui')$$, 'Penyetuju itu tidak berizin menyetujui pembatalan setelah dapur mulai', 'penyetuju tanpa izin void sesudah dapur ditolak');

-- Disetujui owner (punya izin) → diterima, dan nilai kerugian dihitung dari salinan harga.
-- Sejak penutup celah (0012) bukti persetujuan = KUPON SEKALI PAKAI.
-- SEJAK AUDIT AUD-3 F-05 (K-2, 2026-09-20): SATU target hanya boleh dibatalkan SEKALI —
-- kiriman ulang baris pembatalan ditolak (klik ganda / antrean offline dulu menggandakan
-- dampak & laporan kerugian). Karena pesanan eeee…0010 sudah dibatalkan di atas, uji ini
-- memakai pesanan BARU untuk membuktikan nilai kerugian dari salinan subtotal.
reset role;
select uji.klaim(null);   -- kembali ke peran pemilik tabel supaya angka uji boleh diisi apa adanya
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status,
                            subtotal, pajak, service, total, kunci_idempoten)
values ('eeee0000-0000-0000-0000-000000000011', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 11, current_date, 'dinein', 'dikirim',
        54000, 5400, 2700, 62100, 'keranjang-uji-uang-2');
update public.pesanan set dikirim_ke_dapur_pada = now() - interval '5 minutes'
 where id = 'eeee0000-0000-0000-0000-000000000011';
insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('eeee0000-0000-0000-0000-000000000011', 'beef0000-0000-0000-0000-000000000001',
        'Nasi Goreng', 27000, 2, 54000);

reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner (penyetuju)
set local role authenticated;
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000006', 'kunci-uji-hp-atasan-0123456789', 'eeee0000-0000-0000-0000-000000000011')).berhasil,
  true, 'kontrol: persetujuan bukti PIN untuk pesanan baru'
);
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kembali sebagai kasir
set local role authenticated;
insert into public.pembatalan (pesanan_id, tahap, disetujui_oleh, alasan, bahan_terbuang)
values ('eeee0000-0000-0000-0000-000000000011', 'sesudah_dapur', '90000000-0000-0000-0000-000000000002', 'pelanggan membatalkan, makanan sudah dimasak', true);
select uji.sama(
  (select pb.nilai_kerugian from public.pembatalan pb where pb.pesanan_id = 'eeee0000-0000-0000-0000-000000000011' limit 1),
  54000,
  'nilai kerugian dihitung dari salinan subtotal pesanan (54.000)'
);
-- TEMUAN AUD-3 F-05: kiriman ULANG baris pembatalan yang sama WAJIB ditolak (idempoten).
select uji.harap_gagal_sebab(
  $$insert into public.pembatalan (pesanan_id, tahap, disetujui_oleh, alasan, bahan_terbuang)
      values ('eeee0000-0000-0000-0000-000000000011', 'sesudah_dapur', '90000000-0000-0000-0000-000000000002', 'pelanggan membatalkan, makanan sudah dimasak', true)$$,
  'sudah dibatalkan',
  'kiriman ulang pembatalan ditolak (satu aksi = satu jejak)'
);
select uji.sama(
  (select count(*) from public.pembatalan pb where pb.pesanan_id = 'eeee0000-0000-0000-0000-000000000011'),
  1::bigint,
  'tetap SATU jejak pembatalan untuk satu aksi'
);
reset role;
select uji.klaim(null);

-- 8. Isolasi antar resto untuk seluruh tabel uang.
select uji.klaim('90000000-0000-0000-0000-000000000007');   -- kasir resto B
set local role authenticated;
select uji.sama((select count(*) from public.pembayaran), 0::bigint, 'resto lain tidak melihat pembayaran');
select uji.sama((select count(*) from public.diskon_transaksi), 0::bigint, 'resto lain tidak melihat diskon');
select uji.sama((select count(*) from public.pembatalan), 0::bigint, 'resto lain tidak melihat pembatalan');
select uji.sama((select count(*) from public.metode_bayar), 4::bigint, 'resto lain hanya melihat metode bayarnya sendiri');
reset role;
select uji.klaim(null);
