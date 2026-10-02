-- Probe HAKIM H-F-03.5 (2026-10-02) — skenario kerugian ASLI PMB1-F-038 sesudah 0093 + 0095.
-- Buku Besar PMB1-F-038 (kolom Bukti): "kasir bisa membuat pelanggan fiktif, memakai vouchernya pada tamu
-- yang bayar penuh, dan mengantongi selisih (kas tetap cocok)".
-- PERTANYAAN : masih bisakah kasir menerbitkan voucher untuk pelanggan KARANGAN lalu memakainya sendiri
--              dengan PIN-nya sendiri? (Kunci unik hanya menyamakan nomor yang SAMA; nomor yang berbeda,
--              bahkan beda satu angka atau hanya "1", tidak dihalangi apa pun di server.)
-- CARA BACA  : konvensi PMB — HIJAU (LULUS) = celah HIDUP.
-- KONTROL    : negatif = (a) tanpa e-mail dan tanpa nomor ditolak IDENTITAS_WAJIB (pagar kosong bekerja);
--                        (b) pakai_voucher dengan PIN SALAH ditolak (PIN tidak rusak) — jadi celahnya bukan PIN
--                            yang bocor, melainkan bahwa PIN kasir sendiri adalah satu-satunya persetujuan.
--              positif = kasir yang sama memakai voucher dengan PIN benar dan diskon tercatat.
-- KURSI      : kasir Rina (90000000-0000-0000-0000-000000000004), RPC asli daftar_voucher dan pakai_voucher.
-- Runner selalu ROLLBACK. Tidak menyentuh produksi. Pola penyiapan PIN/izin mengikuti supabase/tes/kasir_voucher.sql.

insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000004', crypt('1234', gen_salt('bf', 8)))
on conflict (pengguna_id) do update set pin_hash = crypt('1234', gen_salt('bf', 8));

insert into public.izin (pengguna_id, kode_izin, boleh)
values ('90000000-0000-0000-0000-000000000004', 'pakai_voucher', true)
on conflict (pengguna_id, kode_izin) do update set boleh = true;

update public.pengaturan
   set tumpuk_diskon = false, batas_maks_potongan_persen = 100, batas_maks_potongan_nominal = null
 where penyewa_id = '11111111-1111-1111-1111-111111111111';

insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, min_belanja, mulai, selesai, kuota, aktif
) values (
  'c3000000-0000-0000-0000-000000000701',
  '11111111-1111-1111-1111-111111111111',
  'Kampanye karangan probe H-F-03.5', 'FIKTIF5', 'nominal', 15000, 40000,
  now() - interval '1 hour', now() + interval '1 day', 100, true
);

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- KONTROL NEGATIF (a): tanpa e-mail dan tanpa nomor -> ditolak
select uji.harap_gagal_sebab(
  $$select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000701',
       'Tamu Tanpa Identitas', null, null, null, true, 'kasir', 'hp-probe', '10.7.0.0')$$,
  'IDENTITAS_WAJIB',
  'kontrol negatif (a): tanpa e-mail dan tanpa nomor ditolak'
);

-- CELAH: lima "pelanggan" karangan dengan nomor berbeda — termasuk "1" dan "22" — semuanya diterbitkan voucher
do $$
declare
  v jsonb;
  v_telp text;
  v_n int := 0;
  v_nomor text[] := array['1', '22', '0811-0000-0002', '0811-0000-0003', '0811-0000-0004'];
begin
  foreach v_telp in array v_nomor loop
    v_n := v_n + 1;
    v := public.daftar_voucher(
      '11111111-1111-1111-1111-111111111111',
      'c3000000-0000-0000-0000-000000000701',
      'Tamu Karangan ' || v_n, null, v_telp, null, true, 'kasir', 'hp-probe', ('10.7.0.' || v_n)
    );
    perform uji.harap((v->>'berhasil')::boolean,
      'CELAH: nomor karangan [' || v_telp || '] diterima dan voucher terbit');
  end loop;
end $$;

select uji.harap(
  (select count(*) from public.voucher
    where kampanye_id = 'c3000000-0000-0000-0000-000000000701') = 5,
  'akibat: lima voucher terbit untuk lima pelanggan karangan oleh kasir yang sama'
);

-- KONTROL NEGATIF (b): PIN SALAH ditolak dengan kode PIN_SALAH (bukan karena voucher tak ketemu)
select uji.sama(
  (select hasil->>'kode'
     from (select public.pakai_voucher(
             'eeee0000-0000-0000-0000-000000000010',
             (select v.kode from public.voucher v
                join public.pelanggan p on p.id = v.pelanggan_id
               where p.nama = 'Tamu Karangan 1'),
             '9999') as hasil) s),
  'PIN_SALAH',
  'kontrol negatif (b): pakai_voucher dengan PIN salah ditolak dengan kode PIN_SALAH'
);

-- CELAH: kasir yang SAMA memakai voucher karangan itu dengan PIN-nya SENDIRI -> berhasil, diskon tercatat
select uji.harap(
  (select (hasil->>'berhasil')::boolean
     from (select public.pakai_voucher(
             'eeee0000-0000-0000-0000-000000000010',
             (select v.kode from public.voucher v
                join public.pelanggan p on p.id = v.pelanggan_id
               where p.nama = 'Tamu Karangan 1'),
             '1234') as hasil) s),
  'CELAH: kasir memakai voucher pelanggan karangan "1" dengan PIN-nya sendiri dan BERHASIL'
);
select uji.harap(
  (select coalesce(sum(dt.nilai), 0) from public.diskon_transaksi dt
    where dt.pesanan_id = 'eeee0000-0000-0000-0000-000000000010' and dt.jenis = 'voucher') = 15000,
  'akibat: diskon voucher 15000 tercatat pada pesanan tamu yang sebenarnya membayar penuh'
);
