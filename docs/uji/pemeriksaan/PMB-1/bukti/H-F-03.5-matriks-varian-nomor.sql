-- Matriks HAKIM H-F-03.5 (2026-10-02) — PMB1-F-038 sesudah 0095: bentuk penulisan mana yang DITOLAK dan mana yang BOCOR.
-- BERKAS INI SENGAJA BERAKHIR GAGAL: runner hanya mencetak baris pertama pesan galat, jadi matriks
-- dikirim lewat `raise exception` di ujung. Yang dibaca adalah isi pesannya, bukan kata GAGAL.
--   bocor  = daftar_voucher menerbitkan voucher untuk nomor yang SAMA dengan nomor dasar (celah hidup)
--   ditolak = RPC menolak (kontrol negatif: bukti pagar 0095 bekerja untuk bentuk yang dicakupnya)
-- Tiap varian diuji TERPISAH terhadap nomor dasar yang sama: efeknya dibatalkan dengan
-- `raise exception 'ULANG_KE_SEMULA'` di blok bersarang, sehingga varian tidak saling bertabrakan.
-- Kontrol positif: dua nomor dasar (HP dan telepon rumah) diterima sebelum varian diuji.
-- Kursi: kasir Rina lewat RPC asli public.daftar_voucher. Runner selalu ROLLBACK.

insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, min_belanja, mulai, selesai, kuota, aktif
) values (
  'c3000000-0000-0000-0000-000000000502',
  '11111111-1111-1111-1111-111111111111',
  'Matriks varian H-F-03.5', 'MATRIX5', 'nominal', 20000, 50000,
  now() - interval '1 hour', now() + interval '1 day', 100, true
);

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.harap(
  (select (hasil->>'berhasil')::boolean
     from public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000502',
       'Orang Pertama', null, '0812-3456-7890', null, true, 'kasir', 'hp-matriks', '10.5.0.1'
     ) as hasil),
  'kontrol positif: nomor HP dasar 0812-3456-7890 diterima'
);
select uji.harap(
  (select (hasil->>'berhasil')::boolean
     from public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000502',
       'Orang Telepon Rumah', null, '021-5790-1234', null, true, 'kasir', 'hp-matriks', '10.5.0.2'
     ) as hasil),
  'kontrol positif: telepon rumah dasar 021-5790-1234 diterima'
);

do $$
declare
  v_varian text;
  v_bocor text := '';
  v_tolak text := '';
  v_n int := 0;
  v_ok boolean;
  v_err text;
begin
  foreach v_varian in array array[
    '+62 812-3456-7890',
    '62 812 3456 7890',
    '812 3456 7890',
    '+62 (0)812-3456-7890',
    '+62 0812 3456 7890',
    '620812 3456 7890',
    '0062 812 3456 7890',
    '0062-0812-3456-7890',
    '00812 3456 7890',
    '+62 21 5790 1234',
    '+62 (0)21 5790 1234',
    '0062 21 5790 1234',
    '21 5790 1234'
  ] loop
    v_n := v_n + 1;
    v_ok := null; v_err := null;
    begin
      select (hasil->>'berhasil')::boolean into v_ok
        from public.daftar_voucher(
          '11111111-1111-1111-1111-111111111111',
          'c3000000-0000-0000-0000-000000000502',
          'Varian ' || v_n, null, v_varian, null, true, 'kasir', 'hp-matriks', ('10.5.1.' || v_n)
        ) as hasil;
      raise exception 'ULANG_KE_SEMULA';
    exception when others then
      if sqlerrm <> 'ULANG_KE_SEMULA' then v_err := left(sqlerrm, 45); end if;
    end;
    if v_ok is true then
      v_bocor := v_bocor || '[' || v_varian || '] ';
    else
      v_tolak := v_tolak || '[' || v_varian || ' -> ' || coalesce(v_err, 'rpc berhasil=false') || '] ';
    end if;
  end loop;
  raise exception 'HASIL bocor(voucher kedua terbit)= % ;; ditolak= %', v_bocor, v_tolak;
end $$;
