-- PROBE SAYA — PR-04: pesan kembar memastikan PIN aktif kolega (oracle)
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(public.simpan_pin('482619', null), 'PIN tersimpan.', 'owner memasang PIN-nya');
reset role; select uji.klaim(null);
select uji.klaim('90000000-0000-0000-0000-000000000005');   -- Dedi (pelayan) belum punya PIN
set local role authenticated;
select uji.sama(public.simpan_pin('482619', null),
                'PIN itu sudah dipakai pegawai lain di resto ini — pilih angka lain.',
                'PR-04 NYATA: jawaban KEMBAR memastikan 482619 = PIN aktif owner');
select uji.sama(public.simpan_pin('957031', null), 'PIN tersimpan.',
                'kontrol: angka yang belum dipakai dijawab tersimpan (jawaban berbeda)');
reset role; select uji.klaim(null);
