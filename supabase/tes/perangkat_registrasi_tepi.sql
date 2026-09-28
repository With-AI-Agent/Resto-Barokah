-- ============================================================================
-- UJI: perangkat TERDAFTAR — kasus tepi pendaftaran (T-02, dipanen integrator)
-- ============================================================================
-- Yang dibuktikan berkas ini (DoD T-02):
--   (a) nama kembar sesama perangkat AKTIF satu resto → DITOLAK.
--   (b) nama sama di DUA resto berbeda → DITERIMA (diuji level-constraint:
--       fixture hanya punya admin di resto A; tidak ada admin resto B).
--   (c) pendaftaran ke cabang NONAKTIF → DITOLAK (cabang nonaktif otomatis
--       keluar dari cabang_ids_saya; pesan = penjaga keanggotaan).
--   (d) nama boleh dipakai ulang sesudah perangkat lama DICABUT (indeks unik
--       parsial perangkat_nama_aktif_unik; bukti awal oleh pekerja T-02).
--   (e) kunci tepat 16 karakter DITERIMA; 15 karakter DITOLAK.
-- Bagian (c) sengaja TERAKHIR: menonaktifkan cabang A1 sesaat (di-rollback
-- otomatis oleh runner). Kontrol positif (c) = pendaftaran ke A1 saat aktif
-- di bagian (a)/(d)/(e) di atas.
-- ============================================================================

-- (e) Batas panjang kunci: 15 karakter ditolak, tepat 16 karakter diterima.
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.daftarkan_perangkat('hp-tepi-pendek', 'abcde12345abcde', 'a1a1a1a1-0000-0000-0000-000000000001')$$,
  'minimal 16 karakter',
  'kunci 15 karakter ditolak'
);
select uji.harap(
  (select public.daftarkan_perangkat('hp-tepi-pas16', 'abcde12345abcdef',
                                     'a1a1a1a1-0000-0000-0000-000000000001')) is not null,
  'kunci tepat 16 karakter diterima'
);

-- (a) Nama kembar sesama perangkat AKTIF satu resto → DITOLAK.
select uji.harap(
  (select public.daftarkan_perangkat('hp-tepi-kembar', 'twin000000000001',
                                     'a1a1a1a1-0000-0000-0000-000000000001')) is not null,
  'perangkat pertama bernama hp-tepi-kembar terdaftar'
);
select uji.harap_gagal_sebab(
  $$select public.daftarkan_perangkat('hp-tepi-kembar', 'twin000000000002', 'a1a1a1a1-0000-0000-0000-000000000001')$$,
  'perangkat_nama_aktif_unik',
  'nama kembar sesama aktif satu resto ditolak'
);
reset role;

-- (d) Nama boleh dipakai ulang sesudah perangkat lama DICABUT
--     (bukti awal pekerja T-02; dilengkapi: perangkat lama tetap ditolak).
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;

do $$
declare
  v_lama uuid;
  v_baru uuid;
begin
  perform uji.sama(
    public.simpan_pin('317259', null, null,
      'de000000-0000-0000-0000-000000000002', 'kunci-uji-hp-admin-0123456789'),
    'PIN tersimpan.', 'prasyarat: admin memiliki PIN yang sah'
  );
  v_lama := public.daftarkan_perangkat(
    'hp-tepi-daftar-ulang', 'kunci-lama-tepi-0123456789',
    'a1a1a1a1-0000-0000-0000-000000000001'
  );
  perform uji.harap(v_lama is not null, 'pendaftaran pertama menghasilkan id');
  perform uji.sama(
    (select r.pesan from public.verifikasi_pin(
      '90000000-0000-0000-0000-000000000003', '317259', null,
      v_lama, 'kunci-lama-tepi-0123456789') r),
    'PIN diterima.', 'prasyarat: perangkat lama sah sebelum dicabut'
  );
  perform uji.harap(public.cabut_perangkat(v_lama), 'pencabutan berhasil');
  perform uji.harap(
    (select not pr.aktif from public.perangkat pr where pr.id = v_lama),
    'perangkat lama benar-benar nonaktif setelah dicabut'
  );

  -- Harapan DoD (d): berhasil tanpa menghapus/mengganti nama baris lama.
  v_baru := public.daftarkan_perangkat(
    'hp-tepi-daftar-ulang', 'kunci-baru-tepi-0123456789',
    'a1a1a1a1-0000-0000-0000-000000000001'
  );
  perform uji.harap(v_baru is not null and v_baru <> v_lama,
    'daftar ulang nama sama menghasilkan perangkat baru');
  perform uji.sama(
    (select r.pesan from public.verifikasi_pin(
      '90000000-0000-0000-0000-000000000003', '317259', null,
      v_baru, 'kunci-baru-tepi-0123456789') r),
    'PIN diterima.', 'perangkat baru sah dipakai setelah daftar ulang'
  );
  perform uji.sama(
    (select r.pesan from public.verifikasi_pin(
      '90000000-0000-0000-0000-000000000003', '317259', null,
      v_lama, 'kunci-lama-tepi-0123456789') r),
    'Perangkat tidak dikenali.', 'perangkat lama yang dicabut tetap ditolak'
  );
end
$$;

reset role;

-- (b) Nama sama di dua resto berbeda → DITERIMA (level-constraint: tidak ada
--     admin resto B di fixture, sehingga tidak bisa lewat RPC).
select uji.klaim(null);
insert into public.perangkat (penyewa_id, cabang_id, nama, didaftarkan_oleh)
values ('11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001',
        'hp-satu-nama', '90000000-0000-0000-0000-000000000003');
insert into public.perangkat (penyewa_id, cabang_id, nama)
values ('22222222-2222-2222-2222-222222222222', 'b1b1b1b1-0000-0000-0000-000000000001',
        'hp-satu-nama');
select uji.sama(
  (select count(*) from public.perangkat pr where pr.nama = 'hp-satu-nama' and pr.aktif)::bigint,
  2::bigint,
  'nama sama boleh hidup di dua resto berbeda'
);
select uji.harap_gagal_sebab(
  $$insert into public.perangkat (penyewa_id, cabang_id, nama)
    values ('11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001', 'hp-satu-nama')$$,
  'perangkat_nama_aktif_unik',
  'kontrol: kembaran aktif se-resto tetap ditolak di level constraint'
);

-- (c) TERAKHIR: pendaftaran ke cabang NONAKTIF → DITOLAK.
update public.cabang set aktif = false
 where id = 'a1a1a1a1-0000-0000-0000-000000000001';
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.daftarkan_perangkat('hp-tepi-nonaktif', 'nonaktif00000001', 'a1a1a1a1-0000-0000-0000-000000000001')$$,
  'cabang yang Anda kelola',
  'pendaftaran ke cabang nonaktif ditolak'
);
reset role;
select uji.klaim(null);
