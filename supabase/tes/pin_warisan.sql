-- PR-09 (review putaran16): PIN warisan 4 angka tidak boleh buntu.
-- Cacat lama: PIN 4 angka (dipasang sebelum aturan 6 angka) tidak bisa diverifikasi
-- (format ditolak) DAN tidak bisa dipakai sebagai PIN lama untuk naik kelas —
-- pemilik akun terkunci dari PIN-nya sendiri tanpa jalur swadaya. Sejak 0016:
-- PIN 4 angka diterima HANYA sebagai p_pin_lama di simpan_pin, dengan pembatas
-- tebakan & catatan percobaan yang sama seperti jalur biasa.
-- Probe lama: docs/uji/audit/probe-2026-09-19/pr09-pin-warisan.sql (kini GAGAL).

-- Tanam hash warisan 4 angka ('1234') untuk pelayan, meniru data lama.
reset role;
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000005', crypt('1234', gen_salt('bf', 10)))
on conflict (pengguna_id) do update set pin_hash = excluded.pin_hash;

-- 1) PIN 4 angka tetap TIDAK bisa dipakai masuk (aturan 6 angka tidak dilonggarkan).
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000005', '1234', null, 'de000000-0000-0000-0000-000000000004', 'kunci-uji-hp-pelayan-0123456789')).pesan,
  'PIN harus tepat 6 angka.',
  'PR-09: PIN 4 angka tetap ditolak untuk verifikasi masuk');

-- 2) Naik kelas swadaya: PIN lama 4 angka benar → PIN 6 angka tersimpan.
select uji.sama(public.simpan_pin('482619', '1234', null, 'de000000-0000-0000-0000-000000000004', 'kunci-uji-hp-pelayan-0123456789'), 'PIN tersimpan.',
                'PR-09: naik kelas 4→6 angka berhasil dengan PIN lama yang benar');
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000005', '482619', null, 'de000000-0000-0000-0000-000000000004', 'kunci-uji-hp-pelayan-0123456789')).berhasil,
  true, 'PR-09: PIN baru 6 angka langsung bisa diverifikasi');

-- 3) PIN lama 4 angka SALAH → pesan penolakan, dan percobaannya tercatat.
reset role;
update public.kredensial_pin set pin_hash = crypt('1234', gen_salt('bf', 10))
 where pengguna_id = '90000000-0000-0000-0000-000000000005';
delete from public.percobaan_pin where pengguna_id = '90000000-0000-0000-0000-000000000005';
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;
select uji.sama(public.simpan_pin('482619', '9999', null, 'de000000-0000-0000-0000-000000000004', 'kunci-uji-hp-pelayan-0123456789'),
                'PIN lama salah. PIN warisan 4 angka hanya bisa dipakai untuk naik ke PIN 6 angka.',
                'PR-09: PIN lama 4 angka salah ditolak dengan pesan (bukan exception)');
reset role;
select uji.sama(
  (select count(*)::int from public.percobaan_pin
    where pengguna_id = '90000000-0000-0000-0000-000000000005' and not berhasil),
  1, 'PR-09: tebakan PIN lama yang salah TERCATAT (pembatas bisa menyala)');

-- 4) Pembatas tebakan menyala: 5 gagal → jawaban kunci sementara.
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;
select public.simpan_pin('482619', '9999', null, 'de000000-0000-0000-0000-000000000004', 'kunci-uji-hp-pelayan-0123456789');
select public.simpan_pin('482619', '9999', null, 'de000000-0000-0000-0000-000000000004', 'kunci-uji-hp-pelayan-0123456789');
select public.simpan_pin('482619', '9999', null, 'de000000-0000-0000-0000-000000000004', 'kunci-uji-hp-pelayan-0123456789');
select public.simpan_pin('482619', '9999', null, 'de000000-0000-0000-0000-000000000004', 'kunci-uji-hp-pelayan-0123456789');
select uji.sama(public.simpan_pin('482619', '1234', null, 'de000000-0000-0000-0000-000000000004', 'kunci-uji-hp-pelayan-0123456789') like 'PIN lama salah. Coba lagi setelah %',
                true, 'PR-09: setelah 5 gagal, PIN lama yang BENAR pun menunggu jeda 15 menit');
reset role;
select uji.klaim(null);
