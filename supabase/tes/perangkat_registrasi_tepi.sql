-- ============================================================================
-- T-02 — reproduksi penghambat DoD (d): nama perangkat dipakai ulang setelah cabut
-- ============================================================================
-- STATUS: BELUM LULUS pada basis integrator c25d2dc.
-- Migrasi 0018 memasang UNIQUE (penyewa_id, nama), sedangkan cabut_perangkat
-- hanya mengubah aktif=false. Pendaftaran ulang di bawah masih ditolak.
-- Jangan mengganti harapan berhasil menjadi harap_gagal_sebab: itu justru
-- menyembunyikan ketidaksesuaian DoD. Perbaikan produksi di luar lingkup T-02.
-- Skenario (a), (b), (c), (e) belum ditambahkan: pekerja berhenti sesuai AL-16.
-- Runner membungkus seluruh berkas dalam transaksi dan selalu rollback.

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
  -- Pada basis sekarang, perintah ini melempar pelanggaran keunikan nama.
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
end
$$;

reset role;
select uji.klaim(null);
