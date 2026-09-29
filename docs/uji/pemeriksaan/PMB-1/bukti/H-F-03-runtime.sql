-- HAKIM 2026-09-29: probe cacat lokal, hijau = cacat masih ada; runner rollback.
-- Tidak memanggil produksi; kriptografi runner tiruan, bukan pengujian kekuatan bcrypt.
insert into public.kredensial_pin(pengguna_id,pin_hash) values
 ('90000000-0000-0000-0000-000000000002',crypt('839201',gen_salt('bf',8))),
 ('90000000-0000-0000-0000-000000000004',crypt('516372',gen_salt('bf',8)))
on conflict(pengguna_id) do update set pin_hash=excluded.pin_hash;
select uji.klaim(null);
set local role anon;
select uji.sama(public.verifikasi_pin_perangkat('owner.a@contoh.test','839201','ea900000-0000-0000-0000-000000000001','Hakim Owner')->>'kode','LOGIN_SUKSES','PMB1-F-036 owner asli tanpa sandi/TOTP/kunci perangkat diterima');
select uji.harap_gagal_sebab($$select public.verifikasi_pin_perangkat('kasir.a1@contoh.test','999999','ea900000-0000-0000-0000-000000000002','Hakim Asing')$$,'percobaan_pin_perangkat_id_fkey','PMB1-F-039 PIN salah perangkat asing justru gagal FK, bukan kode yang diklaim pemeriksa');
select uji.sama(public.verifikasi_pin_perangkat('kasir.a1@contoh.test','516372','ea900000-0000-0000-0000-000000000002','Hakim Asing')->>'kode','PERANGKAT_TIDAK_SAH','PMB1-F-039 perangkat asing PIN benar memberi jawaban berbeda');
-- Kontrol key salah vs key hilang pada perangkat TERDAFTAR yang punya hash key.
select uji.sama(public.verifikasi_pin_perangkat('kasir.a1@contoh.test','516372','de000000-0000-0000-0000-000000000003','Hakim','kunci-salah')->>'kode','PERANGKAT_TIDAK_SAH','PMB1-F-052 key salah ditolak');
select uji.sama(public.verifikasi_pin_perangkat('kasir.a1@contoh.test','516372','de000000-0000-0000-0000-000000000003','Hakim',null)->>'kode','LOGIN_SUKSES','PMB1-F-052 key null diterima pada perangkat yang sama');
reset role;
select uji.harap(exists(select 1 from public.perangkat where id='ea900000-0000-0000-0000-000000000001' and 'owner_pusat'=any(peran_diizinkan)), 'PMB1-F-036 perangkat baru tersimpan dengan peran owner');
select uji.harap(exists(select 1 from public.kredensial_perangkat where perangkat_id='de000000-0000-0000-0000-000000000003'), 'PMB1-F-052 kontrol perangkat memang mempunyai hash kunci');

insert into public.kampanye_voucher(id,penyewa_id,nama,kode_kampanye,jenis,nilai,min_belanja,mulai,selesai,kuota,aktif) values
 ('ea900000-0000-0000-0000-000000000038','11111111-1111-1111-1111-111111111111','Hakim kasir','HAKIM038','nominal',1000,10000,now()-interval '1 hour',now()+interval '1 day',10,true);
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(public.daftar_voucher('11111111-1111-1111-1111-111111111111','ea900000-0000-0000-0000-000000000038','Orang Sama',null,'08123456789',null,true,'kasir')->>'kode','SUKSES','PMB1-F-038 klaim pertama kasir');
select uji.sama(public.daftar_voucher('11111111-1111-1111-1111-111111111111','ea900000-0000-0000-0000-000000000038','Orang Sama',null,'08123456789',null,true,'kasir')->>'kode','SUKSES','PMB1-F-038 identitas sama mendapat voucher kedua');
select public.buka_shift(p_modal_awal:=100000,p_cabang_id:='a1a1a1a1-0000-0000-0000-000000000001'::uuid);
select public.kas_pergerakan(p_jenis:='keluar',p_jumlah:=300000,p_alasan:='Probe pengeluaran melebihi modal');
select public.tutup_shift(0,null);
reset role;
select uji.harap((select count(*) from public.voucher where kampanye_id='ea900000-0000-0000-0000-000000000038')=2,'PMB1-F-038 dua voucher sungguh tersimpan');
select uji.harap(exists(select 1 from public.shift_kas where dibuka_oleh='90000000-0000-0000-0000-000000000004' and status='ditutup' and uang_seharusnya=0 and selisih=0 and alasan_selisih is null),'PMB1-F-046 modal 100000 keluar 300000 tutup fisik 0 tanpa alasan');
-- PMB1-F-040: ini memerlukan pemilik tabel yang bisa menonaktifkan pemicu,
-- BUKAN eksploit role anon/authenticated. Kontrol: UPDATE biasa ditolak.
insert into public.catatan_audit(id,penyewa_id,aksi,entitas) values
 ('ea900000-0000-0000-0000-000000000040','11111111-1111-1111-1111-111111111111','hakim.asli','uji');
select uji.harap_gagal_sebab($$update public.catatan_audit set aksi='hakim.palsu' where id='ea900000-0000-0000-0000-000000000040'$$,'permanen','PMB1-F-040 pemicu memang menolak UPDATE biasa');
alter table public.catatan_audit disable trigger user;
update public.catatan_audit set aksi='hakim.palsu' where id='ea900000-0000-0000-0000-000000000040';
update public.catatan_audit r set hash_baris=encode(sha256((r.id::text || ':' || r.penyewa_id::text || ':' || coalesce(r.pelaku_id::text,'sistem') || ':' || r.aksi || ':' || r.entitas || ':' || coalesce(r.entitas_id::text,'') || ':' || coalesce(r.nilai_lama::text,'') || ':' || coalesce(r.nilai_baru::text,'') || ':' || to_char(r.waktu at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') || ':' || r.hash_sebelumnya)::bytea),'hex') where r.id='ea900000-0000-0000-0000-000000000040';
alter table public.catatan_audit enable trigger user;
select uji.harap((select valid from public.verifikasi_rantai_audit('11111111-1111-1111-1111-111111111111')),'PMB1-F-040 audit diubah+hitung hash ulang masih dinilai valid');
