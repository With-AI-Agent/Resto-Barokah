-- PMB F-11 ulangan: artefak nyata simpan_pin, bukan fungsi tiruan.
-- Jalankan: node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/F-11.2-kontrak-rpc.sql
-- LULUS = kontradiksi dokumen terulang; bukan berarti kontrak aplikasi benar.
-- Runner memasang semua migrasi + fixture, lalu rollback setiap berkas.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

do $$
declare
  jawaban text;
  penolakan text;
begin
  jawaban := public.simpan_pin('274918', null,
    '90000000-0000-0000-0000-000000000003',
    'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789');
  perform uji.sama(jawaban, 'PIN tersimpan.', 'jalur sukses RPC sungguhan');
  perform uji.sama(jsonb_typeof(to_jsonb(jawaban)), 'string',
    'kontrak :470 text, bukan objek seragam :23');
  -- Kontrol negatif: PIN sama tidak boleh berhasil dipasang ke pegawai lain.
  penolakan := public.simpan_pin('274918', null,
    '90000000-0000-0000-0000-000000000006',
    'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789');
  perform uji.harap(penolakan like 'PIN itu tidak bisa dipakai%',
    'PIN kembar wajib ditolak dengan sebab yang sesuai');
  perform uji.harap(not (to_jsonb(jawaban) ?& array['berhasil','kode','pesan','data']),
    'jawaban sukses tidak memenuhi empat bidang kontrak');
end $$;

-- Pemeriksaan kontrak benar-benar MERAH pada artefak nyata; merah yang diharapkan
-- ditangkap helper dengan sebab spesifik. Bukan penolakan izin/FK yang disalahartikan.
select uji.harap_gagal_sebab(
  $q$ select uji.harap(
    to_jsonb(public.simpan_pin('274918', null,
      '90000000-0000-0000-0000-000000000006',
      'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789'))
      ?& array['berhasil','kode','pesan','data'],
    'F11_KONTRAK_EMPAT_BIDANG') $q$,
  'HARAPAN TIDAK TERPENUHI: F11_KONTRAK_EMPAT_BIDANG',
  'assert kontrak atas jawaban RPC harus merah pada baseline');
reset role;
select uji.klaim(null);
