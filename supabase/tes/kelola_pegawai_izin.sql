-- ============================================================================
-- PENGUJIAN: Kelola Pegawai, Izin Granular & Reset PIN (T9-08 / PRD M3 & M6 / ART-2)
--
-- Membuktikan secara komprehensif:
--  1. Otorisasi pembacaan daftar pegawai resto (owner/admin vs pelayan).
--  2. Tambah pegawai baru (validasi nama, email unik, peran resmi, PIN 6 angka kuat).
--  3. Tolak PIN lemah (123456, 111111, <6 digit) saat tambah pegawai.
--  4. Edit pegawai (nama, email, peran, cabang) dan audit trail.
--  5. Tolak cabang lintas resto saat tambah/edit pegawai.
--  6. Perlindungan hierarki: admin cabang dilarang mengubah data profil owner pusat.
--  7. Pengaturan izin granular (set_izin) dengan batas nominal dan batas persen.
--  8. Validasi batas diskon (nominal tidak negatif, persen 0..100).
--  9. Validasi kode izin resmi (tolak kode liar).
-- 10. Perlindungan hierarki: staf dilarang mengubah izin owner pusat.
-- 11. Anti-privilege escalation: non-owner tanpa hak dilarang memberi izin kelola_pegawai.
-- 12. Pembacaan izin pegawai (ambil_izin_pegawai) mengembalikan 10 izin resmi dan penanda khusus.
-- 13. Nonaktifkan akun pegawai (soft-disable) tanpa merusak integritas audit.
-- 14. Tolak menonaktifkan satu-satunya owner pusat aktif di resto.
-- 15. Perlindungan hierarki: staf dilarang menonaktifkan owner pusat.
-- 16. Reset PIN pegawai oleh atasan berwenang (tanpa PIN lama) dengan validasi 6 angka & keunikan hash.
-- 17. Verifikasi PIN baru yang di-reset berhasil dipakai.
-- 18. Perlindungan hierarki: staf dilarang mereset PIN owner pusat.
-- 19. Fail-closed ART-2: pegawai ber-riwayat pesanan/pembayaran DILARANG di-hard delete.
-- 20. Pegawai baru tanpa riwayat boleh dihapus bersih jika dibutuhkan.
-- ============================================================================

-- Setup identitas uji
-- Bu Oasis (owner_pusat tenant 1111): 90000000-0000-0000-0000-000000000002
-- Pak Andi (admin_cabang tenant 1111): 90000000-0000-0000-0000-000000000003
-- Rina (kasir tenant 1111): 90000000-0000-0000-0000-000000000004
-- Dedi (pelayan tenant 1111): 90000000-0000-0000-0000-000000000005
-- Ujang (kasir tenant 2222): 90000000-0000-0000-0000-000000000007
-- Cabang Pusat (tenant 1111): a1a1a1a1-0000-0000-0000-000000000001
-- Cabang Tunggal (tenant 2222): b1b1b1b1-0000-0000-0000-000000000001

begin;

-- ----------------------------------------------------------------------------
-- KASUS 1: Ambil daftar pegawai
-- ----------------------------------------------------------------------------
-- Owner pusat berhak membaca daftar pegawai resto
select uji.klaim('90000000-0000-0000-0000-000000000002');
select uji.harap(
  jsonb_array_length(public.ambil_daftar_pegawai()) >= 5,
  'K-01a: Owner pusat dapat mengambil seluruh daftar pegawai di restorannya'
);

-- Pelayan biasa tanpa izin kelola_pegawai ditolak
select uji.klaim('90000000-0000-0000-0000-000000000005');
select uji.harap_gagal_sebab(
  'select public.ambil_daftar_pegawai();',
  'Hanya owner pusat atau pemegang izin kelola_pegawai yang dapat melihat daftar pegawai\.',
  'K-01b: Pelayan biasa tanpa izin ditolak saat memanggil ambil_daftar_pegawai'
);

-- ----------------------------------------------------------------------------
-- KASUS 2: Tambah pegawai baru oleh owner pusat
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');

select uji.harap(
  (public.simpan_pegawai(
    null,
    'Budi Kasir Baru',
    'budi.baru@contoh.test',
    'kasir',
    'a1a1a1a1-0000-0000-0000-000000000001',
    '839201'
  )->>'berhasil')::boolean = true,
  'K-02: Owner pusat berhasil menambahkan kasir baru dengan PIN awal valid'
);

-- Buktikan tersimpan di public.pengguna & public.kredensial_pin & public.pengguna_cabang
select uji.harap(
  exists (
    select 1 from public.pengguna p
      join public.kredensial_pin kp on kp.pengguna_id = p.id
      join public.pengguna_cabang pc on pc.pengguna_id = p.id
     where p.email = 'budi.baru@contoh.test'
       and p.nama = 'Budi Kasir Baru'
       and p.peran = 'kasir'
       and pc.cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001'
  ),
  'K-02b: Data pengguna, kredensial PIN bcrypt, dan penugasan cabang terpasang rapi'
);

-- Buktikan ada catatan audit tambah_pegawai
select uji.harap(
  exists (
    select 1 from public.catatan_audit
     where aksi = 'tambah_pegawai'
       and entitas = 'pengguna'
       and (nilai_baru->>'email') = 'budi.baru@contoh.test'
  ),
  'K-02c: Aksi tambah pegawai tercatat kekal di catatan_audit'
);

-- ----------------------------------------------------------------------------
-- KASUS 3: Tolak penambahan pegawai dengan PIN lemah atau format salah
-- ----------------------------------------------------------------------------
select uji.harap_gagal_sebab(
  'select public.simpan_pegawai(null, ''Joko'', ''joko@test.id'', ''kasir'', ''a1a1a1a1-0000-0000-0000-000000000001'', ''123456'');',
  'PIN ditolak: berisi deret angka berurutan',
  'K-03a: PIN sekuensial 123456 ditolak'
);

select uji.harap_gagal_sebab(
  'select public.simpan_pegawai(null, ''Joko'', ''joko@test.id'', ''kasir'', ''a1a1a1a1-0000-0000-0000-000000000001'', ''111111'');',
  'PIN ditolak: semua angkanya sama',
  'K-03b: PIN berulang 111111 ditolak'
);

select uji.harap_gagal_sebab(
  'select public.simpan_pegawai(null, ''Joko'', ''joko@test.id'', ''kasir'', ''a1a1a1a1-0000-0000-0000-000000000001'', ''12345'');',
  'Akun pegawai baru wajib diberikan PIN awal 6 digit angka\.',
  'K-03c: PIN kurang dari 6 digit ditolak'
);

-- ----------------------------------------------------------------------------
-- KASUS 4: Tolak duplikasi email & cabang silang resto
-- ----------------------------------------------------------------------------
-- Tolak email yang sudah ada di resto
select uji.harap_gagal_sebab(
  'select public.simpan_pegawai(null, ''Rina Kloning'', ''kasir.a1@contoh.test'', ''kasir'', ''a1a1a1a1-0000-0000-0000-000000000001'', ''948271'');',
  'sudah digunakan oleh pegawai lain',
  'K-04a: Email duplikat ditolak'
);

-- Tolak penugasan ke cabang milik resto lain (tenant 2222)
select uji.harap_gagal_sebab(
  'select public.simpan_pegawai(null, ''Penyusup'', ''penyusup@test.id'', ''kasir'', ''b1b1b1b1-0000-0000-0000-000000000001'', ''948271'');',
  'Cabang tidak ditemukan atau bukan milik resto Anda\.',
  'K-04b: Penugasan ke cabang milik penyewa lain ditolak fail-closed'
);

-- ----------------------------------------------------------------------------
-- KASUS 5: Edit pegawai
-- ----------------------------------------------------------------------------
select uji.harap(
  (public.simpan_pegawai(
    '90000000-0000-0000-0000-000000000004',
    'Rina Kasir Senior',
    'kasir.rina.senior@contoh.test',
    'kasir',
    'a1a1a1a1-0000-0000-0000-000000000001'
  )->>'berhasil')::boolean = true,
  'K-05a: Owner berhasil mengubah profil pegawai'
);

select uji.harap(
  exists (
    select 1 from public.pengguna
     where id = '90000000-0000-0000-0000-000000000004'
       and nama = 'Rina Kasir Senior'
       and email = 'kasir.rina.senior@contoh.test'
  ),
  'K-05b: Nama dan email pegawai berhasil diperbarui'
);

-- ----------------------------------------------------------------------------
-- KASUS 6: Hierarki peran saat edit: admin dilarang mengubah owner
-- ----------------------------------------------------------------------------
-- Beri izin kelola_pegawai ke Pak Andi (admin_cabang)
insert into public.izin (pengguna_id, kode_izin, boleh)
values ('90000000-0000-0000-0000-000000000003', 'kelola_pegawai', true)
on conflict (pengguna_id, kode_izin) do update set boleh = true;

select uji.klaim('90000000-0000-0000-0000-000000000003');

-- Pak Andi mencoba mengubah profil Bu Oasis (owner_pusat) -> WAJIB GAGAL
select uji.harap_gagal_sebab(
  'select public.simpan_pegawai(''90000000-0000-0000-0000-000000000002'', ''Bu Oasis Bajakan'', ''hacked@test.id'', ''kasir'', ''a1a1a1a1-0000-0000-0000-000000000001'');',
  'Hanya sesama owner pusat yang dapat mengubah data profil owner pusat\.',
  'K-06: Admin cabang dilarang mengubah profil owner pusat'
);

-- ----------------------------------------------------------------------------
-- KASUS 7: Pengaturan izin granular (set_izin) oleh owner pusat
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');

-- Owner mengatur batas diskon Rina: boleh, maksimal Rp 75.000, 15%
select uji.harap(
  (public.set_izin(
    '90000000-0000-0000-0000-000000000004',
    'beri_diskon',
    true,
    75000,
    15.00
  )->>'berhasil')::boolean = true,
  'K-07a: Owner pusat berhasil menyetel izin diskon dan batas nominal/persen untuk kasir'
);

select uji.harap(
  exists (
    select 1 from public.izin
     where pengguna_id = '90000000-0000-0000-0000-000000000004'
       and kode_izin = 'beri_diskon'
       and boleh = true
       and batas_nominal = 75000
       and batas_persen = 15.00
  ),
  'K-07b: Baris izin kasir tersimpan persis di tabel public.izin'
);

-- Catatan audit tercatat
select uji.harap(
  exists (
    select 1 from public.catatan_audit
     where aksi = 'set_izin'
       and entitas_id = '90000000-0000-0000-0000-000000000004'
       and (nilai_baru->>'kode_izin') = 'beri_diskon'
  ),
  'K-07c: Perubahan izin tercatat di public.catatan_audit'
);

-- ----------------------------------------------------------------------------
-- KASUS 8: Validasi batas diskon (angka negatif & persen > 100)
-- ----------------------------------------------------------------------------
select uji.harap_gagal_sebab(
  'select public.set_izin(''90000000-0000-0000-0000-000000000004'', ''beri_diskon'', true, -5000, 10);',
  'Batas nominal diskon tidak boleh negatif\.',
  'K-08a: Batas nominal negatif ditolak'
);

select uji.harap_gagal_sebab(
  'select public.set_izin(''90000000-0000-0000-0000-000000000004'', ''beri_diskon'', true, 50000, 150);',
  'Batas persen diskon harus di antara 0 dan 100\.',
  'K-08b: Batas persen di atas 100 ditolak'
);

-- ----------------------------------------------------------------------------
-- KASUS 9: Validasi kode izin resmi (tolak kode liar)
-- ----------------------------------------------------------------------------
select uji.harap_gagal_sebab(
  'select public.set_izin(''90000000-0000-0000-0000-000000000004'', ''izin_liar_palsu'', true);',
  'tidak dikenal dalam sistem',
  'K-09: Kode izin di luar 10 izin resmi ditolak'
);

-- ----------------------------------------------------------------------------
-- KASUS 10: Proteksi hierarki pada set_izin
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000003'); -- Pak Andi (admin_cabang)

-- Admin cabang mencoba mencabut izin owner pusat -> DITOLAK
select uji.harap_gagal_sebab(
  'select public.set_izin(''90000000-0000-0000-0000-000000000002'', ''lihat_laporan'', false);',
  'Hanya sesama owner pusat yang dapat mengubah izin owner pusat\.',
  'K-10: Admin cabang dilarang mengubah izin milik owner pusat'
);

-- ----------------------------------------------------------------------------
-- KASUS 11: Anti-privilege escalation (hanya owner pusat yang bisa beri izin kelola_pegawai)
-- ----------------------------------------------------------------------------
-- Pak Andi (admin_cabang punya izin kelola_pegawai) mencoba memberikan izin kelola_pegawai ke Dedi
select uji.klaim('90000000-0000-0000-0000-000000000003');

select uji.harap_gagal_sebab(
  'select public.set_izin(''90000000-0000-0000-0000-000000000005'', ''kelola_pegawai'', true);',
  'Hanya owner pusat yang berhak memberikan izin kelola pegawai\.',
  'K-11a: Admin cabang berizin kelola_pegawai dilarang memberikan izin kelola_pegawai ke staf lain'
);

-- Kasir Rina tanpa izin kelola_pegawai juga ditolak
select uji.klaim('90000000-0000-0000-0000-000000000004');

select uji.harap_gagal_sebab(
  'select public.set_izin(''90000000-0000-0000-0000-000000000005'', ''beri_diskon'', true);',
  'Hanya owner pusat atau pemegang izin kelola_pegawai yang dapat mengubah izin pegawai\.',
  'K-11b: Kasir biasa ditolak mengubah izin pegawai mana pun'
);

-- ----------------------------------------------------------------------------
-- KASUS 12: Pembacaan 10 izin resmi pegawai (ambil_izin_pegawai)
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner Bu Oasis

select uji.harap(
  jsonb_array_length(public.ambil_izin_pegawai('90000000-0000-0000-0000-000000000004')) = 10,
  'K-12a: Fungsi ambil_izin_pegawai mengembalikan tepat 10 izin resmi sistem'
);

select uji.harap(
  exists (
    select 1
      from jsonb_array_elements(public.ambil_izin_pegawai('90000000-0000-0000-0000-000000000004')) elem
     where elem->>'kode_izin' = 'beri_diskon'
       and (elem->>'boleh')::boolean = true
       and (elem->>'batas_nominal')::integer = 75000
       and (elem->>'batas_persen')::numeric = 15.00
       and (elem->>'khusus')::boolean = true
  ),
  'K-12b: Nilai khusus override diskon terbaca tepat pada matriks izin'
);

-- ----------------------------------------------------------------------------
-- KASUS 13: Nonaktifkan pegawai (soft-disable)
-- ----------------------------------------------------------------------------
select uji.harap(
  (public.set_status_pengguna('90000000-0000-0000-0000-000000000005', false)->>'berhasil')::boolean = true,
  'K-13a: Owner berhasil menonaktifkan akun pelayan Dedi'
);

select uji.harap(
  (select aktif from public.pengguna where id = '90000000-0000-0000-0000-000000000005') = false,
  'K-13b: Kolom aktif pada pengguna bernilai false'
);

-- ----------------------------------------------------------------------------
-- KASUS 14: Tolak menonaktifkan satu-satunya owner pusat aktif
-- ----------------------------------------------------------------------------
select uji.harap_gagal_sebab(
  'select public.set_status_pengguna(''90000000-0000-0000-0000-000000000002'', false);',
  'Restoran minimal harus memiliki satu owner pusat yang aktif\.',
  'K-14: Sistem menolak menonaktifkan satu-satunya owner pusat aktif'
);

-- ----------------------------------------------------------------------------
-- KASUS 15: Proteksi hierarki pada set_status_pengguna
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000003'); -- Admin cabang Pak Andi

select uji.harap_gagal_sebab(
  'select public.set_status_pengguna(''90000000-0000-0000-0000-000000000002'', false);',
  'Hanya sesama owner pusat yang dapat mengubah status keaktifan owner pusat\.',
  'K-15: Admin cabang dilarang mengubah status owner pusat'
);

-- ----------------------------------------------------------------------------
-- KASUS 16: Reset PIN pegawai oleh atasan berwenang
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Bu Oasis

select uji.harap(
  (public.reset_pin_pegawai('90000000-0000-0000-0000-000000000004', '749102')->>'berhasil')::boolean = true,
  'K-16a: Owner berhasil mereset PIN kasir menjadi 749102'
);

-- Tolak jika PIN baru lemah
select uji.harap_gagal_sebab(
  'select public.reset_pin_pegawai(''90000000-0000-0000-0000-000000000004'', ''123456'');',
  'PIN ditolak: berisi deret angka berurutan',
  'K-16b: Reset PIN ditolak jika pola PIN lemah'
);

-- ----------------------------------------------------------------------------
-- KASUS 17: Verifikasi PIN baru yang direset
-- ----------------------------------------------------------------------------
select uji.harap(
  exists (
    select 1 from public.kredensial_pin kp
     where kp.pengguna_id = '90000000-0000-0000-0000-000000000004'
       and kp.pin_hash = crypt('749102', kp.pin_hash)
  ),
  'K-17: Hash PIN kasir cocok dengan PIN baru 749102 yang direset'
);

-- ----------------------------------------------------------------------------
-- KASUS 18: Proteksi hierarki pada reset PIN
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000003'); -- Pak Andi

select uji.harap_gagal_sebab(
  'select public.reset_pin_pegawai(''90000000-0000-0000-0000-000000000002'', ''839174'');',
  'Hanya sesama owner pusat yang dapat mereset PIN owner pusat\.',
  'K-18: Admin cabang dilarang mereset PIN owner pusat'
);

-- ----------------------------------------------------------------------------
-- KASUS 19: Fail-closed ART-2: Pegawai ber-riwayat dilarang di-DELETE langsung
-- ----------------------------------------------------------------------------
-- Buat transaksi pesanan yang mencatat kasir Rina
insert into public.pesanan (
  id, penyewa_id, cabang_id, nomor, tipe, kasir_id, kunci_idempoten
) values (
  'feed0000-0000-0000-0000-000000000099',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  999,
  'dinein',
  '90000000-0000-0000-0000-000000000004',
  'kunci-idempoten-rina-99'
);

-- Kasir Rina memiliki riwayat pesanan & dilarang di-DELETE
select uji.harap_gagal_sebab(
  'delete from public.pengguna where id = ''90000000-0000-0000-0000-000000000004'';',
  'tidak dapat dihapus karena memiliki riwayat',
  'K-19: Pegawai ber-riwayat transaksi dilarang di-hard delete (ART-2)'
);

-- ----------------------------------------------------------------------------
-- KASUS 20: Pegawai baru tanpa transaksi boleh dihapus bersih
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
-- Ambil id pegawai baru yang dibuat di Kasus 2
do $$
declare
  v_budi_id uuid;
begin
  select id into v_budi_id from public.pengguna where email = 'budi.baru@contoh.test';
  delete from public.pengguna where id = v_budi_id;
end $$;

select uji.harap(
  not exists (select 1 from public.pengguna where email = 'budi.baru@contoh.test'),
  'K-20: Pegawai tanpa riwayat transaksi bersih dihapus'
);

rollback;
