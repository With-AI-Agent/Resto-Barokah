-- ============================================================================
-- UJI: KUNCI PIN TIDAK BISA DIJATUHKAN ORANG LAIN (anti penolakan layanan)
-- Menutup temuan review PR putaran8 PR-13: pembatas percobaan menghitung kegagalan
-- atas nama KORBAN, sehingga pegawai mana pun bisa menebak 5 kali atas nama owner
-- dan mengunci PIN owner 15 menit — persetujuan void & diskon resto berhenti,
-- sementara jejaknya menuduh owner "terlalu banyak percobaan salah".
-- Sekarang yang dibatasi = percobaan PER PENCOBA (pemanggil) terhadap akun itu.
-- ============================================================================

-- Siapkan: owner memasang PIN.
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner
set local role authenticated;
select uji.sama(public.simpan_pin('738294', null, null, 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789'), 'PIN tersimpan.', 'owner memasang PIN');

-- 1. Kasir menebak PIN owner 5 kali dari perangkat TERDAFTAR miliknya (sejak T1-24
--    memutar nama perangkat tak berguna lagi — perangkat asing langsung ditolak).
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir (penyerang)
set local role authenticated;
-- Sejak PR-07 (0016) aksi berkupon wajib menyebut pesanan — penyerang nyata pun
-- melewati jalur itu, jadi tebakannya diberi pesanan agar sampai ke pencocokan PIN.
-- (Jebakan LATERAL: subselect yang tidak menyebut `i` hanya dijalankan SEKALI —
--  karena itu tebakan berulang dipakai loop eksplisit, bukan generate_series.)
do $$
declare
  v_ok  boolean;
  v_n   integer := 0;
begin
  for i in 1..5 loop
    select r.berhasil into v_ok
      from public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '111111',
                                 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000003',
                                 'kunci-uji-hp-kasir-0123456789',
                                 'eeee0000-0000-0000-0000-000000000010') r;
    perform uji.harap(v_ok = false, 'tebakan ke-' || i || ' salah');
    v_n := v_n + 1;
  end loop;
  perform uji.harap(v_n = 5, 'lima tebakan benar-benar dijalankan');
end $$;

-- 2. Penyerang sendiri sekarang terkunci (batas berlaku untuk PENCOBA).
select uji.harap(
  (select r.pesan from public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '111111', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789', 'eeee0000-0000-0000-0000-000000000010') r) like '%terkunci%',
  'penyerang yang sudah 5 kali salah terkunci dari akun itu'
);

-- 3. INTI PERBAIKAN: owner TETAP bisa memakai PIN-nya sendiri (dulu ikut terkunci).
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner (korban)
set local role authenticated;
select uji.sama(
  (select r.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789', 'eeee0000-0000-0000-0000-000000000010') r),
  true, 'PIN owner yang BENAR tetap diterima walau pegawai lain mencoba menguncinya'
);

-- 4. Pertahanan lama tetap hidup: tebakan SALAH dari pemakai yang sama tetap dibatasi
--    (penyerang tidak mendapat jatah tambahan dengan memutar nama perangkat).
select uji.sama(
  (select count(*) from public.percobaan_pin p
    where p.pengguna_id = '90000000-0000-0000-0000-000000000002'
      and p.pemanggil_id = '90000000-0000-0000-0000-000000000004'
      and not p.berhasil),
  6::bigint, 'enam percobaan gagal penyerang tercatat (termasuk yang ditolak karena terkunci)'
);

-- 5. Percobaan dari orang KETIGA tidak memakai jatah penyerang maupun korban.
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000005');   -- pelayan (pencoba ketiga)
set local role authenticated;
select uji.sama(
  (select r.sisa_percobaan from public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '999999', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000004', 'kunci-uji-hp-pelayan-0123456789', 'eeee0000-0000-0000-0000-000000000010') r),
  4, 'pencoba ketiga punya jatahnya sendiri (4 sisa setelah satu kali salah)'
);

-- 6. Kupon persetujuan terikat pesanan: persetujuan owner hanya sah untuk pesanan itu.
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(
  (select r.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789', 'eeee0000-0000-0000-0000-000000000010') r),
  true, 'persetujuan PIN tercatat untuk pesanan tertentu'
);
select uji.sama(
  (select p.pesanan_id from public.percobaan_pin p
    where p.pengguna_id = '90000000-0000-0000-0000-000000000002' and p.berhasil
      and p.pesanan_id is not null
    order by p.waktu desc limit 1),
  'eeee0000-0000-0000-0000-000000000010'::uuid,
  'kupon persetujuan menyimpan pesanan yang disetujui'
);

reset role;
select uji.klaim(null);
