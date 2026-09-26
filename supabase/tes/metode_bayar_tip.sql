-- ============================================================================
-- supabase/tes/metode_bayar_tip.sql — Uji Metode Pembayaran & Tip (T9-07)
-- ============================================================================

-- Gunakan akun Owner Pusat Kedai Oasis
select uji.klaim('90000000-0000-0000-0000-000000000002');

-- ----------------------------------------------------------------------------
-- Kasus 1: Ambil data awal pengaturan pembayaran
-- ----------------------------------------------------------------------------
do $$
declare
  v_res jsonb;
  v_metode jsonb;
  v_aturan_tip jsonb;
begin
  v_res := public.ambil_pengaturan_pembayaran();
  v_metode := v_res->'metode_bayar';
  v_aturan_tip := v_res->'aturan_tip';

  if jsonb_array_length(v_metode) < 4 then
    raise exception 'Minimal 4 metode bayar bawaan harus ada';
  end if;

  if (v_aturan_tip->>'izinkan_tip')::boolean <> false then
    raise exception 'Bawaan izinkan_tip harus bernilai false';
  end if;
end;
$$;

select uji.harap(true, 'T907-01: Berhasil mengambil pengaturan pembayaran awal');

-- ----------------------------------------------------------------------------
-- Kasus 2: Tambah metode pembayaran baru yang sah (GoPay)
-- ----------------------------------------------------------------------------
do $$
declare
  v_res jsonb;
  v_id uuid;
begin
  v_res := public.simpan_metode_bayar(
    null,
    'GoPay',
    'non_tunai',
    true,
    true,
    5
  );

  v_id := (v_res->>'id')::uuid;
  if v_id is null then
    raise exception 'ID metode baru tidak boleh null';
  end if;

  if not exists (select 1 from public.metode_bayar where id = v_id and nama = 'GoPay') then
    raise exception 'Metode bayar GoPay gagal tersimpan di tabel';
  end if;
end;
$$;

select uji.harap(true, 'T907-02: Berhasil menambahkan metode bayar baru');

-- ----------------------------------------------------------------------------
-- Kasus 3: Validasi nama metode minimal 2 karakter
-- ----------------------------------------------------------------------------
do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    perform public.simpan_metode_bayar(null, ' X ', 'non_tunai', true, true, 6);
  exception
    when sqlstate 'P0001' then
      if sqlerrm like '%minimal 2 karakter%' then
        v_tertangkap := true;
      end if;
  end;

  if not v_tertangkap then
    raise exception using errcode = '40001', message = 'Nama 1 karakter seharusnya ditolak';
  end if;
end;
$$;

select uji.harap(true, 'T907-03: Menolak nama metode bayar kurang dari 2 karakter');

-- ----------------------------------------------------------------------------
-- Kasus 4: Validasi tunai tidak boleh butuh referensi
-- ----------------------------------------------------------------------------
do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    perform public.simpan_metode_bayar(null, 'Tunai Khusus', 'tunai', true, true, 6);
  exception
    when sqlstate 'P0001' then
      if sqlerrm like '%tidak boleh mewajibkan nomor referensi%' then
        v_tertangkap := true;
      end if;
  end;

  if not v_tertangkap then
    raise exception using errcode = '40001', message = 'Tunai dengan referensi seharusnya ditolak';
  end if;
end;
$$;

select uji.harap(true, 'T907-04: Menolak metode tunai yang meminta nomor referensi');

-- ----------------------------------------------------------------------------
-- Kasus 5: Validasi non-tunai wajib butuh referensi
-- ----------------------------------------------------------------------------
do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    perform public.simpan_metode_bayar(null, 'ShopeePay', 'non_tunai', false, true, 6);
  exception
    when sqlstate 'P0001' then
      if sqlerrm like '%wajib mengaktifkan nomor referensi%' then
        v_tertangkap := true;
      end if;
  end;

  if not v_tertangkap then
    raise exception using errcode = '40001', message = 'Non-tunai tanpa referensi seharusnya ditolak';
  end if;
end;
$$;

select uji.harap(true, 'T907-05: Menolak metode non-tunai tanpa kewajiban referensi');

-- ----------------------------------------------------------------------------
-- Kasus 6: Validasi nama metode kembar ditolak
-- ----------------------------------------------------------------------------
do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    perform public.simpan_metode_bayar(null, 'gopay', 'non_tunai', true, true, 7);
  exception
    when sqlstate 'P0001' then
      if sqlerrm like '%sudah terdaftar%' then
        v_tertangkap := true;
      end if;
  end;

  if not v_tertangkap then
    raise exception using errcode = '40001', message = 'Nama metode kembar seharusnya ditolak';
  end if;
end;
$$;

select uji.harap(true, 'T907-06: Menolak penambahan nama metode bayar kembar');

-- ----------------------------------------------------------------------------
-- Kasus 7: Edit metode pembayaran (ubah nama & urutan)
-- ----------------------------------------------------------------------------
do $$
declare
  v_id uuid;
begin
  select id into v_id from public.metode_bayar
   where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'GoPay';

  perform public.simpan_metode_bayar(
    v_id,
    'GoPay / QRIS Dinamis',
    'non_tunai',
    true,
    true,
    10
  );

  if not exists (
    select 1 from public.metode_bayar
     where id = v_id and nama = 'GoPay / QRIS Dinamis' and urutan = 10
  ) then
    raise exception 'Perubahan metode bayar tidak tersimpan';
  end if;
end;
$$;

select uji.harap(true, 'T907-07: Berhasil mengubah data metode bayar');

-- ----------------------------------------------------------------------------
-- Kasus 8: Simpan urutan banyak metode pembayaran sekaligus (batch)
-- ----------------------------------------------------------------------------
do $$
declare
  v_daftar jsonb;
  v_res jsonb;
  v_id1 uuid;
  v_id2 uuid;
begin
  select id into v_id1 from public.metode_bayar where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai';
  select id into v_id2 from public.metode_bayar where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'QRIS';

  v_daftar := jsonb_build_array(
    jsonb_build_object('id', v_id1, 'urutan', 2),
    jsonb_build_object('id', v_id2, 'urutan', 1)
  );

  v_res := public.simpan_urutan_metode_bayar(v_daftar);
  if (v_res->>'jumlah')::integer <> 2 then
    raise exception 'Jumlah yang diperbarui tidak cocok';
  end if;
end;
$$;

select uji.harap(true, 'T907-08: Berhasil menyimpan urutan metode pembayaran');

-- ----------------------------------------------------------------------------
-- Kasus 9: Fail-closed pemicu: Menolak penonaktifan seluruh metode bayar
-- ----------------------------------------------------------------------------
do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    -- Coba matikan semua metode bayar aktif Kedai Oasis
    update public.metode_bayar
       set aktif = false
     where penyewa_id = '11111111-1111-1111-1111-111111111111';
  exception
    when sqlstate 'P0001' then
      if sqlerrm like '%Minimal harus ada satu metode pembayaran yang aktif%' then
        v_tertangkap := true;
      end if;
  end;

  if not v_tertangkap then
    raise exception using errcode = '40001', message = 'Menonaktifkan semua metode bayar seharusnya ditolak';
  end if;
end;
$$;

select uji.harap(true, 'T907-09: Fail-closed: Mencegah resto tanpa metode pembayaran aktif');

-- ----------------------------------------------------------------------------
-- Kasus 10: Fail-closed pemicu: Menolak hapus metode bayar yang punya transaksi
-- ----------------------------------------------------------------------------
do $$
declare
  v_tertangkap boolean := false;
  v_id_tunai uuid;
  v_pesanan_id uuid := 'ee000000-0000-0000-0000-000000000099';
begin
  select id into v_id_tunai from public.metode_bayar
   where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai';

  -- Buat pesanan & item uji agar total terhitung jujur oleh peladen
  insert into public.pesanan (
    id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten
  ) values (
    v_pesanan_id,
    '11111111-1111-1111-1111-111111111111',
    'a1a1a1a1-0000-0000-0000-000000000001',
    880,
    current_date,
    'dinein',
    'draf',
    'pesanan-riwayat-bayar-01'
  );

  insert into public.pesanan_item (
    pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
  ) values (
    v_pesanan_id,
    'beef0000-0000-0000-0000-000000000001',
    'Nasi Goreng',
    27000,
    1,
    27000
  );

  insert into public.pembayaran (
    pesanan_id, metode_id, metode_nama_saat_itu, jenis_saat_itu, jumlah, diterima, kembalian, kunci_idempoten
  ) values (
    v_pesanan_id,
    v_id_tunai,
    'Tunai',
    'tunai',
    31050,
    50000,
    18950,
    'kunci-bayar-uji-riwayat-01'
  );

  -- Uji 1: Fail-closed pemicu langsung pada tabel saat direct DELETE SQL
  begin
    delete from public.metode_bayar where id = v_id_tunai;
  exception
    when sqlstate 'P0001' then
      if sqlerrm like '%sudah memiliki riwayat transaksi pembayaran%' then
        v_tertangkap := true;
      end if;
  end;

  if not v_tertangkap then
    raise exception using errcode = '40001', message = 'Direct delete metode ber-riwayat seharusnya ditolak oleh pemicu';
  end if;

  -- Uji 2: Validasi proteksi pada fungsi RPC hapus_metode_bayar
  v_tertangkap := false;
  begin
    perform public.hapus_metode_bayar(v_id_tunai);
  exception
    when sqlstate 'P0001' then
      if sqlerrm like '%sudah memiliki riwayat transaksi pembayaran%' then
        v_tertangkap := true;
      end if;
  end;

  if not v_tertangkap then
    raise exception using errcode = '40001', message = 'Hapus metode ber-riwayat seharusnya ditolak';
  end if;
end;
$$;

select uji.harap(true, 'T907-10: Fail-closed: Mencegah hapus metode yang memiliki riwayat pembayaran');

-- ----------------------------------------------------------------------------
-- Kasus 11: Berhasil menghapus metode bayar yang belum memiliki riwayat
-- ----------------------------------------------------------------------------
do $$
declare
  v_id uuid;
begin
  select id into v_id from public.metode_bayar
   where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'GoPay / QRIS Dinamis';

  perform public.hapus_metode_bayar(v_id);

  if exists (select 1 from public.metode_bayar where id = v_id) then
    raise exception 'Metode bayar tanpa riwayat seharusnya terhapus';
  end if;
end;
$$;

select uji.harap(true, 'T907-11: Berhasil menghapus metode bayar tanpa riwayat');

-- ----------------------------------------------------------------------------
-- Kasus 12: Pengguna tanpa izin (kasir) ditolak mengatur metode pembayaran & aturan tip
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Rina (kasir)

do $$
declare
  v_tertangkap boolean := false;
begin
  -- 1. Kasir dilarang simpan_metode_bayar
  begin
    perform public.simpan_metode_bayar(null, 'OVO Kasir', 'non_tunai', true, true, 10);
  exception
    when sqlstate 'P0001' then
      if sqlerrm like '%Hanya owner pusat, pemegang izin atur_pengaturan, atau admin cabang%' then
        v_tertangkap := true;
      end if;
  end;

  if not v_tertangkap then
    raise exception using errcode = '40001', message = 'Kasir seharusnya ditolak menyimpan metode pembayaran';
  end if;

  -- 2. Kasir dilarang simpan_aturan_tip
  v_tertangkap := false;
  begin
    perform public.simpan_aturan_tip(true, 'sukarela');
  exception
    when sqlstate 'P0001' then
      if sqlerrm like '%Hanya owner pusat atau pemegang izin atur_pengaturan%' then
        v_tertangkap := true;
      end if;
  end;

  if not v_tertangkap then
    raise exception using errcode = '40001', message = 'Kasir seharusnya ditolak mengubah aturan tip';
  end if;
end;
$$;

select uji.harap(true, 'T907-12: Kasir tanpa izin ditolak mengatur metode bayar & aturan tip');

-- Kembalikan klaim ke Owner Pusat
select uji.klaim('90000000-0000-0000-0000-000000000002');

-- ----------------------------------------------------------------------------
-- Kasus 13: Simpan aturan tip resto (aktifkan tip, opsi persen & nominal)
-- ----------------------------------------------------------------------------
do $$
declare
  v_res jsonb;
  v_cfg record;
begin
  v_res := public.simpan_aturan_tip(
    true,
    'persen',
    array[5.0, 10.0, 15.0, 20.0]::numeric(5, 2)[],
    array[5000, 10000, 20000]::integer[]
  );

  select izinkan_tip, cara_hitung_tip into v_cfg
    from public.pengaturan
   where penyewa_id = '11111111-1111-1111-1111-111111111111';

  if not v_cfg.izinkan_tip or v_cfg.cara_hitung_tip <> 'persen' then
    raise exception 'Aturan tip tidak tersimpan di tabel pengaturan';
  end if;
end;
$$;

select uji.harap(true, 'T907-13: Berhasil mengaktifkan dan menyimpan aturan tip');

-- ----------------------------------------------------------------------------
-- Kasus 14: Validasi cara hitung tip tidak sah ditolak
-- ----------------------------------------------------------------------------
do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    perform public.simpan_aturan_tip(true, 'ngasal');
  exception
    when sqlstate 'P0001' then
      if sqlerrm like '%Cara hitung tip tidak valid%' then
        v_tertangkap := true;
      end if;
  end;

  if not v_tertangkap then
    raise exception using errcode = '40001', message = 'Cara hitung tip ngasal seharusnya ditolak';
  end if;
end;
$$;

select uji.harap(true, 'T907-14: Menolak cara hitung tip di luar ketentuan');

-- ----------------------------------------------------------------------------
-- Kasus 15: Pasang tip pada pesanan & periksa perhitungan total (hitung_total)
-- ----------------------------------------------------------------------------
do $$
declare
  v_pesanan_id uuid := 'ee000000-0000-0000-0000-000000000001';
  v_res jsonb;
  v_p record;
  v_expected_total bigint;
begin
  -- Buat pesanan uji baru
  insert into public.pesanan (
    id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten
  ) values (
    v_pesanan_id,
    '11111111-1111-1111-1111-111111111111',
    'a1a1a1a1-0000-0000-0000-000000000001',
    881,
    current_date,
    'dinein',
    'draf',
    'tip-test-idempoten-01'
  );

  -- Tambah item senilai Rp27.000 (harga resmi Nasi Goreng di cabang ini)
  insert into public.pesanan_item (
    pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
  ) values (
    v_pesanan_id,
    'beef0000-0000-0000-0000-000000000001',
    'Nasi Goreng',
    27000,
    1,
    27000
  );

  -- Pasang tip Rp5.000
  v_res := public.pasang_tip_pesanan(v_pesanan_id, 5000);

  select subtotal, pajak, service, tip, total
    into v_p
    from public.pesanan
   where id = v_pesanan_id;

  -- PB1 10% dari 27.000 = 2.700
  -- Service 5% dari 27.000 = 1.350
  -- Dasar = 27.000 + 2.700 + 1.350 = 31.050
  -- Tip = 5.000
  -- Total = 31.050 + 5.000 = 36.050
  if v_p.tip <> 5000 then
    raise exception 'Tip pesanan seharusnya 5000, terbaca %', v_p.tip;
  end if;

  if v_p.total <> (v_p.subtotal + v_p.pajak + v_p.service + v_p.tip) then
    raise exception 'Total pesanan tidak mencakup tip: subtotal %, pajak %, service %, tip %, total %',
      v_p.subtotal, v_p.pajak, v_p.service, v_p.tip, v_p.total;
  end if;
end;
$$;

select uji.harap(true, 'T907-15: Berhasil memasang tip dan hitung_total mencakup tip');

-- ----------------------------------------------------------------------------
-- Kasus 16: Bayar pesanan yang memiliki tip lunas sesuai total
-- ----------------------------------------------------------------------------
do $$
declare
  v_pesanan_id uuid := 'ee000000-0000-0000-0000-000000000001';
  v_metode_id uuid;
  v_total integer;
  v_res jsonb;
begin
  select id into v_metode_id from public.metode_bayar
   where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai';

  select total into v_total from public.pesanan where id = v_pesanan_id;

  v_res := public.bayar_pesanan(
    v_pesanan_id,
    v_metode_id,
    v_total,
    50000, -- diterima
    null,  -- referensi tunai null
    'bayar-tip-kunci-01'
  );

  if (v_res->>'lunas')::boolean <> true then
    raise exception 'Pesanan dengan tip gagal dilunasi oleh bayar_pesanan';
  end if;
end;
$$;

select uji.harap(true, 'T907-16: Pembayaran pesanan ber-tip berhasil dilunasi');

-- ----------------------------------------------------------------------------
-- Kasus 17: Fail-closed: Pasang tip pada pesanan yang sudah lunas ditolak
-- ----------------------------------------------------------------------------
do $$
declare
  v_tertangkap boolean := false;
  v_pesanan_id uuid := 'ee000000-0000-0000-0000-000000000001';
begin
  begin
    perform public.pasang_tip_pesanan(v_pesanan_id, 10000);
  exception
    when sqlstate 'P0001' then
      if sqlerrm like '%tidak dapat diubah pada pesanan yang sudah lunas%' then
        v_tertangkap := true;
      end if;
  end;

  if not v_tertangkap then
    raise exception using errcode = '40001', message = 'Ubah tip pada pesanan lunas seharusnya ditolak';
  end if;
end;
$$;

select uji.harap(true, 'T907-17: Menolak pengubahan tip pada pesanan yang sudah lunas');

-- ----------------------------------------------------------------------------
-- Kasus 18: Fail-closed: Pasang tip saat fitur tip dinonaktifkan ditolak
-- ----------------------------------------------------------------------------
do $$
declare
  v_tertangkap boolean := false;
  v_pesanan_id uuid := 'ee000000-0000-0000-0000-000000000002';
begin
  -- Nonaktifkan tip di pengaturan
  perform public.simpan_aturan_tip(false, 'sukarela');

  -- Buat pesanan baru
  insert into public.pesanan (
    id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten
  ) values (
    v_pesanan_id,
    '11111111-1111-1111-1111-111111111111',
    'a1a1a1a1-0000-0000-0000-000000000001',
    882,
    current_date,
    'dinein',
    'draf',
    'tip-test-idempoten-02'
  );

  begin
    perform public.pasang_tip_pesanan(v_pesanan_id, 3000);
  exception
    when sqlstate 'P0001' then
      if sqlerrm like '%tidak mengaktifkan fitur penerimaan tip%' then
        v_tertangkap := true;
      end if;
  end;

  if not v_tertangkap then
    raise exception using errcode = '40001', message = 'Pasang tip saat nonaktif seharusnya ditolak';
  end if;
end;
$$;

select uji.harap(true, 'T907-18: Fail-closed: Menolak tip saat fitur tip restoran dinonaktifkan');

-- ----------------------------------------------------------------------------
-- Kasus 19: Validasi tip bernilai negatif ditolak
-- ----------------------------------------------------------------------------
do $$
declare
  v_tertangkap boolean := false;
  v_pesanan_id uuid := 'ee000000-0000-0000-0000-000000000002';
begin
  begin
    perform public.pasang_tip_pesanan(v_pesanan_id, -5000);
  exception
    when sqlstate 'P0001' then
      if sqlerrm like '%tidak boleh negatif%' then
        v_tertangkap := true;
      end if;
  end;

  if not v_tertangkap then
    raise exception using errcode = '40001', message = 'Tip negatif seharusnya ditolak';
  end if;
end;
$$;

select uji.harap(true, 'T907-19: Menolak input tip bernilai negatif');

-- ----------------------------------------------------------------------------
-- Kasus 20: Verifikasi jejak audit tercatat di public.catatan_audit
-- ----------------------------------------------------------------------------
do $$
declare
  v_audit_metode integer;
  v_audit_tip integer;
begin
  select count(*) into v_audit_metode
    from public.catatan_audit
   where penyewa_id = '11111111-1111-1111-1111-111111111111'
     and aksi in ('tambah_metode_bayar', 'ubah_metode_bayar', 'hapus_metode_bayar');

  if v_audit_metode < 2 then
    raise exception 'Catatan audit perubahan metode bayar tidak ditemukan (ditemukan %)', v_audit_metode;
  end if;

  select count(*) into v_audit_tip
    from public.catatan_audit
   where penyewa_id = '11111111-1111-1111-1111-111111111111'
     and aksi in ('ubah_aturan_tip', 'pasang_tip');

  if v_audit_tip < 2 then
    raise exception 'Catatan audit aturan tip dan pasang tip tidak ditemukan (ditemukan %)', v_audit_tip;
  end if;
end;
$$;

select uji.harap(true, 'T907-20: Jejak audit tercatat lengkap di public.catatan_audit');
