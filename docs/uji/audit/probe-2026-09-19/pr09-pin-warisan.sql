-- PROBE SAYA (versi 2) — PR-09: PIN warisan 4 angka buntu
insert into public.kredensial_pin (pengguna_id, pin_hash)
select '90000000-0000-0000-0000-000000000005',
       '$tiruan$2$garam123$' || encode(sha256(sha256(('garam123' || '1234')::bytea)), 'hex');
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;
select uji.sama((public.verifikasi_pin('90000000-0000-0000-0000-000000000005','1234')).pesan,
                'PIN harus tepat 6 angka.',
                'PR-09 NYATA: PIN warisan 4 angka tak bisa diverifikasi sama sekali');
select uji.harap_gagal_sebab($$select public.simpan_pin('482619','1234')$$, 'PIN lama salah',
                'PR-09 NYATA: naik kelas 4→6 angka ditolak walau PIN lama benar');
reset role; select uji.klaim(null);
