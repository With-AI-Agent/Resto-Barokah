-- PROBE SAYA — PR-14: hak akses fungsi 0014
select uji.sama(has_function_privilege('service_role','public.hitung_total(uuid)','execute'), false,
                'PR-14 NYATA: service_role TIDAK boleh memanggil hitung_total');
select uji.sama(has_function_privilege('service_role','public.nomor_pesanan_berikutnya(uuid,date)','execute'), false,
                'PR-14 NYATA: service_role TIDAK boleh memanggil nomor_pesanan_berikutnya');
select uji.sama(has_function_privilege('anon','public.peringkat_peran(text)','execute'), true,
                'PR-14 NYATA: anon BISA memanggil peringkat_peran');
