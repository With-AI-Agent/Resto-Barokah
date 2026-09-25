-- ============================================================================
-- supabase/tes/kampanye_aturan.sql (T8-11)
--
-- Target Pengujian:
--   1. Validasi pencegahan aturan mustahil di level database.
--   2. Fungsi format aturan bahasa manusia yang ramah awam.
--   3. Hak akses admin / pemilik pada RPC simpan_kampanye_voucher.
--   4. Pembuatan dan pembaruan kampanye voucher.
--   5. Pengambilan daftar kampanye dengan statistik klaim dan serapan.
--   6. Perubahan status aktif/nonaktif kampanye.
-- ============================================================================

begin;

-- Skenario 1: Uji format rupiah dan aturan kalimat manusia
do $$
declare
  v_kalimat text;
begin
  assert public.format_rupiah(50000) = 'Rp50.000', 'format_rupiah 50000 salah';
  assert public.format_rupiah(0) = 'Rp0', 'format_rupiah 0 salah';
  assert public.format_rupiah(1250000) = 'Rp1.250.000', 'format_rupiah 1250000 salah';

  -- Format aturan persen dengan plafon
  v_kalimat := public.format_aturan_kampanye(
    'persen', 20, 50000, 15000, '2026-12-31 23:59:59+07'::timestamptz, 100, '[]'::jsonb
  );
  assert v_kalimat ilike '%Diskon 20% (maksimal Rp15.000)%', 'Format persen dengan plafon salah';
  assert v_kalimat ilike '%dengan belanja minimal Rp50.000%', 'Format min belanja salah';
  assert v_kalimat ilike '%di semua cabang%', 'Format cabang salah';
  assert v_kalimat ilike '%Kuota: 100 voucher%', 'Format kuota salah';

  -- Format aturan nominal
  v_kalimat := public.format_aturan_kampanye(
    'nominal', 25000, 75000, null, '2026-12-31 23:59:59+07'::timestamptz, 50, '[{"id":"cab-1"}]'::jsonb
  );
  assert v_kalimat ilike '%Potongan langsung Rp25.000%', 'Format nominal salah';
  assert v_kalimat ilike '%di 1 cabang terpilih%', 'Format cabang spesifik salah';
end;
$$;

-- Skenario 2: Pencegahan aturan mustahil via Trigger picu_validasi_aturan_kampanye
do $$
declare
  v_penyewa uuid;
  v_salah boolean;
begin
  select id into v_penyewa from public.penyewa limit 1;

  -- 2a. Persen > 100% wajib ditolak
  v_salah := false;
  begin
    insert into public.kampanye_voucher (
      penyewa_id, nama, kode_kampanye, jenis, nilai, mulai, selesai, kuota, anggaran_maks
    ) values (
      v_penyewa, 'Promo Mustahil', 'MUSTAHIL150', 'persen', 150, now(), now() + interval '7 days', 50, 1000000
    );
  exception when others then
    v_salah := true;
  end;
  assert v_salah, 'Aturan persen > 100% lolos tanpa penolakan!';

  -- 2b. Nilai nominal <= 0 wajib ditolak
  v_salah := false;
  begin
    insert into public.kampanye_voucher (
      penyewa_id, nama, kode_kampanye, jenis, nilai, mulai, selesai, kuota, anggaran_maks
    ) values (
      v_penyewa, 'Promo Nol', 'NOL0', 'nominal', 0, now(), now() + interval '7 days', 50, 1000000
    );
  exception when others then
    v_salah := true;
  end;
  assert v_salah, 'Aturan nominal 0 lolos tanpa penolakan!';

  -- 2c. Tanggal selesai <= tanggal mulai wajib ditolak
  v_salah := false;
  begin
    insert into public.kampanye_voucher (
      penyewa_id, nama, kode_kampanye, jenis, nilai, mulai, selesai, kuota, anggaran_maks
    ) values (
      v_penyewa, 'Promo Mundur', 'MUNDUR', 'nominal', 10000, now(), now() - interval '1 days', 50, 1000000
    );
  exception when others then
    v_salah := true;
  end;
  assert v_salah, 'Aturan selesai <= mulai lolos tanpa penolakan!';

  -- 2d. Kuota <= 0 wajib ditolak
  v_salah := false;
  begin
    insert into public.kampanye_voucher (
      penyewa_id, nama, kode_kampanye, jenis, nilai, mulai, selesai, kuota, anggaran_maks
    ) values (
      v_penyewa, 'Promo Tanpa Kuota', 'KUOTANOL', 'nominal', 10000, now(), now() + interval '7 days', 0, 1000000
    );
  exception when others then
    v_salah := true;
  end;
  assert v_salah, 'Aturan kuota 0 lolos tanpa penolakan!';

  -- 2e. Anggaran lebih kecil dari nilai voucher nominal tunggal wajib ditolak
  v_salah := false;
  begin
    insert into public.kampanye_voucher (
      penyewa_id, nama, kode_kampanye, jenis, nilai, mulai, selesai, kuota, anggaran_maks
    ) values (
      v_penyewa, 'Promo Anggaran Kurang', 'ANGGARANKURANG', 'nominal', 50000, now(), now() + interval '7 days', 10, 20000
    );
  exception when others then
    v_salah := true;
  end;
  assert v_salah, 'Aturan anggaran < nilai nominal lolos tanpa penolakan!';

  -- 2f. Plafon potongan pada nominal otomatis di-null-kan oleh trigger
  declare
    v_maks_cek numeric;
  begin
    insert into public.kampanye_voucher (
      penyewa_id, nama, kode_kampanye, jenis, nilai, maks_potongan, mulai, selesai, kuota, anggaran_maks
    ) values (
      v_penyewa, 'Promo Nominal Plafon', 'NOMPLAFON', 'nominal', 10000, 5000, now(), now() + interval '7 days', 10, 100000
    ) returning maks_potongan into v_maks_cek;
    assert v_maks_cek is null, 'Plafon potongan untuk nominal tidak dinullkan oleh trigger!';
  end;
end;
$$;

-- Skenario 3: Uji Hak Akses & RPC simpan_kampanye_voucher
do $$
declare
  v_admin   uuid;
  v_kasir   uuid;
  v_res     jsonb;
  v_kmp_id  uuid;
begin
  -- Cari admin resto (owner_pusat) dan kasir
  select id into v_admin from public.pengguna where peran = 'owner_pusat' limit 1;
  select id into v_kasir from public.pengguna where peran = 'kasir' limit 1;

  -- 3a. Kasir mencoba simpan kampanye -> DITOLAK
  perform uji.klaim('90000000-0000-0000-0000-000000000004');
  v_res := public.simpan_kampanye_voucher(
    p_nama := 'Promo Liar Kasir',
    p_kode_kampanye := 'LIAR10',
    p_jenis := 'persen',
    p_nilai := 10,
    p_selesai := now() + interval '7 days'
  );
  assert (v_res->>'berhasil')::boolean = false, 'Kasir berhasil membuat kampanye!';
  assert v_res->>'kode' = 'TIDAK_PUNYA_IZIN', 'Kode penolakan kasir bukan TIDAK_PUNYA_IZIN, tapi: ' || coalesce(v_res->>'kode', 'null') || ' pesan: ' || coalesce(v_res->>'pesan', 'null');

  -- 3b. Admin membuat kampanye baru -> BERHASIL
  perform uji.klaim('90000000-0000-0000-0000-000000000002');
  v_res := public.simpan_kampanye_voucher(
    p_nama := 'Diskon Spesial Admin 20%',
    p_kode_kampanye := 'SPESIAL20',
    p_jenis := 'persen',
    p_nilai := 20,
    p_min_belanja := 50000,
    p_maks_potongan := 20000,
    p_mulai := now(),
    p_selesai := now() + interval '14 days',
    p_kuota := 100,
    p_anggaran_maks := 2000000,
    p_cabang_berlaku := '[]'::jsonb,
    p_aktif := true
  );

  assert (v_res->>'berhasil')::boolean = true, 'Admin gagal membuat kampanye valid: ' || coalesce(v_res->>'pesan', '');
  v_kmp_id := (v_res->'data'->>'id')::uuid;
  assert v_kmp_id is not null, 'ID kampanye baru tidak dikembalikan';

  -- 3c. Admin memperbarui kampanye yang ada (ubah kuota dan nama) -> BERHASIL
  v_res := public.simpan_kampanye_voucher(
    p_id := v_kmp_id,
    p_nama := 'Diskon Spesial Akhir Pekan 20%',
    p_kode_kampanye := 'SPESIAL20',
    p_jenis := 'persen',
    p_nilai := 20,
    p_min_belanja := 60000,
    p_maks_potongan := 25000,
    p_mulai := now(),
    p_selesai := now() + interval '14 days',
    p_kuota := 150,
    p_anggaran_maks := 3750000,
    p_cabang_berlaku := '[]'::jsonb,
    p_aktif := true
  );
  assert (v_res->>'berhasil')::boolean = true, 'Admin gagal memperbarui kampanye';
  assert v_res->'data'->>'nama' = 'Diskon Spesial Akhir Pekan 20%', 'Nama kampanye tidak terbarui';

  -- 3d. Coba insert kode duplikat -> DITOLAK
  v_res := public.simpan_kampanye_voucher(
    p_nama := 'Promo Kloning',
    p_kode_kampanye := 'SPESIAL20',
    p_jenis := 'nominal',
    p_nilai := 10000,
    p_selesai := now() + interval '5 days'
  );
  assert (v_res->>'berhasil')::boolean = false, 'Kode duplikat diloloskan!';
  assert v_res->>'kode' = 'KODE_KAMPANYE_SUDAH_ADA', 'Kode galat bukan KODE_KAMPANYE_SUDAH_ADA';

  -- Skenario 4: Ambil daftar kampanye dengan statistik
  v_res := public.ambil_daftar_kampanye('semua');
  assert (v_res->>'berhasil')::boolean = true, 'Gagal mengambil daftar kampanye';
  assert jsonb_array_length(v_res->'data') >= 1, 'Daftar kampanye kosong';

  -- Skenario 5: Ubah status kampanye (Nonaktifkan & Aktifkan kembali)
  v_res := public.ubah_status_kampanye(v_kmp_id, false);
  assert (v_res->>'berhasil')::boolean = true, 'Gagal menonaktifkan kampanye';
  assert (v_res->'data'->>'aktif')::boolean = false, 'Status aktif tidak menjadi false';

  v_res := public.ubah_status_kampanye(v_kmp_id, true);
  assert (v_res->>'berhasil')::boolean = true, 'Gagal mengaktifkan kembali kampanye';
  assert (v_res->'data'->>'aktif')::boolean = true, 'Status aktif tidak kembali true';
end;
$$;

rollback;
