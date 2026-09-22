-- PR-14 (review putaran16): hak execute fungsi dikoreksi DUA ARAH.
-- (a) `revoke all ... from public` di 0014 ikut mematikan jalur peladen:
--     service_role kehilangan execute pada hitung_total (nomor_pesanan_berikutnya
--     & peran_lebih_tinggi sudah dipulihkan 0015; hitung_total menyusul di 0016).
-- (b) `peringkat_peran` lahir tanpa revoke sehingga ANON bisa memanggilnya —
--     peta hierarki peran tidak perlu terbaca publik; kini hanya authenticated
--     & service_role.
-- Probe lama: docs/uji/audit/probe-2026-09-19/pr14-hak-fungsi.sql (kini GAGAL).

-- (a) jalur peladen hidup.
select uji.sama(has_function_privilege('service_role', 'public.hitung_total(uuid)', 'execute'),
                true, 'PR-14: service_role boleh memanggil hitung_total (jalur peladen)');
select uji.sama(has_function_privilege('service_role', 'public.nomor_pesanan_berikutnya(uuid,date)', 'execute'),
                true, 'PR-14: service_role boleh memanggil nomor_pesanan_berikutnya');
select uji.sama(has_function_privilege('service_role', 'public.peran_lebih_tinggi(uuid,uuid)', 'execute'),
                true, 'PR-14: service_role boleh memanggil peran_lebih_tinggi (dipakai 0016)');

-- (b) anon tidak membaca peta hierarki; klien sah tetap bisa.
select uji.sama(has_function_privilege('anon', 'public.peringkat_peran(text)', 'execute'),
                false, 'PR-14: anon TIDAK bisa memanggil peringkat_peran');
select uji.sama(has_function_privilege('authenticated', 'public.peringkat_peran(text)', 'execute'),
                true, 'kontrol: authenticated tetap bisa (dipakai logika PIN)');

-- F-11 tidak regress: helper hierarki tetap tertutup bagi klien.
select uji.sama(has_function_privilege('authenticated', 'public.peran_lebih_tinggi(uuid,uuid)', 'execute'),
                false, 'F-11 tetap: authenticated TIDAK bisa memanggil peran_lebih_tinggi');
