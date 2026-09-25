-- ============================================================================
-- Migrasi 0065: Layar Kasir Cek (Baca Saja) & Pakai (Atomik + PIN) Voucher (T8-09)
--
-- Ref: PRD M10 (aturan voucher) & M3 (izin pakai voucher); TECH_SPEC §9 ART-5
--
-- Tujuan:
--   1. Pembaruan `picu_diskon_batas()` untuk mengizinkan diskon jenis 'voucher'
--      saat `voucher_id` terhubung secara sah ke baris voucher di basis data.
--   2. RPC `public.cek_voucher(p_kode, p_cabang_id, p_subtotal)`:
--      HANYA MEMBACA (read-only) — dilarang mengubah status voucher apa pun.
--   3. RPC `public.pakai_voucher(p_pesanan_id, p_kode, p_pin_kasir, p_kunci_idempoten)`:
--      Pencairan voucher atomik sekali-pakai (ART-5) dengan otorisasi PIN kasir berizin.
--   4. Pencatatan jejak audit di `voucher_percobaan` dan `diskon_transaksi`.
-- ============================================================================

-- 1. Pembaruan Trigger Batas Diskon Transaksi (Mendukung Mesin Voucher T1-20 / T8-09)
create or replace function public.picu_diskon_batas()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pesanan     record;
  v_sudah       integer;      -- total nilai diskon yang sudah ada
  v_jumlah      integer;      -- berapa diskon yang sudah tercatat
  v_tumpuk      boolean;      -- apakah resto mengizinkan tumpuk diskon
  v_cap_persen  numeric;      -- batas maks potongan resto (persen)
  v_cap_nominal integer;      -- batas maks potongan resto (rupiah; null = tanpa batas)
  v_total       integer;      -- total potongan sesudah baris ini
  v_persen      numeric;      -- persen EFEKTIF (dihitung dari uang, bukan dari klien)
  v_kupon       bigint;       -- bukti PIN penyetuju (T5-05) — dibaca, tidak dikonsumsi
  v_boleh       boolean;      -- hasil gerbang izin yang berlaku untuk baris ini
  v_vcr         record;       -- data voucher jika jenis = 'voucher'
begin
  select p.id, p.subtotal, p.penyewa_id into v_pesanan
    from public.pesanan p where p.id = new.pesanan_id;
  if v_pesanan.id is null then
    raise exception 'Pesanan tidak ditemukan.';
  end if;

  -- ------------------------------------------------------------------ jenis
  if new.jenis = 'manual' then
    v_persen := coalesce(
      case when coalesce(v_pesanan.subtotal, 0) > 0
           then round(new.nilai::numeric * 100 / v_pesanan.subtotal, 2) end,
      new.persen,
      100);

    v_boleh := public.boleh('beri_diskon', new.nilai, v_persen);

    if not v_boleh and new.disetujui_oleh is not null then
      select pp.id into v_kupon
        from public.percobaan_pin pp
       where pp.pengguna_id = new.disetujui_oleh
         and pp.berhasil
         and pp.aksi = 'beri_diskon'
         and pp.pesanan_id = new.pesanan_id
         and pp.dipakai_pada is null
         and pp.waktu > now() - interval '5 minutes'
       order by pp.waktu
       limit 1;

      if v_kupon is not null then
        select ie.boleh
           and (ie.batas_nominal is null or new.nilai <= ie.batas_nominal)
           and (ie.batas_persen  is null or v_persen  <= ie.batas_persen)
          into v_boleh
          from public.izin_efektif_untuk(new.disetujui_oleh, 'beri_diskon') ie;
        v_boleh := coalesce(v_boleh, false);
      end if;
    end if;

    if not v_boleh then
      raise exception 'Diskon ini melebihi batas izin Anda — minta atasan (pemilik/admin) yang memproses.';
    end if;
  elsif new.jenis = 'voucher' then
    -- Jika voucher_id null (misal insert manual coba-coba tanpa mesin voucher): TOLAK
    if new.voucher_id is null then
      raise exception 'Diskon voucher belum aktif (mesin voucher menunggu T1-12/T1-19/T1-20). Pakai diskon manual dengan persetujuan.';
    end if;

    -- Periksa izin pakai voucher pada pelaku
    if not public.boleh('pakai_voucher') then
      raise exception 'Anda tidak memiliki izin untuk memakai voucher.';
    end if;

    -- Verifikasi bahwa voucher sah terdaftar di penyewa ini dan terhubung ke pesanan ini
    select v.*, kv.nama as nama_kampanye
      into v_vcr
      from public.voucher v
      join public.kampanye_voucher kv on kv.id = v.kampanye_id
     where v.id = new.voucher_id
       and v.penyewa_id = v_pesanan.penyewa_id;

    if v_vcr.id is null then
      raise exception 'Voucher tidak ditemukan atau bukan milik resto ini.';
    end if;

    if v_vcr.status != 'terpakai' or v_vcr.pesanan_id is distinct from new.pesanan_id then
      raise exception 'Voucher belum terpakai secara sah pada pesanan ini.';
    end if;
  elsif new.jenis = 'promo' then
    raise exception 'Diskon promo otomatis belum aktif (menunggu T1-19/T1-20). Pakai diskon manual dengan persetujuan.';
  else
    raise exception 'Jenis diskon tidak dikenal: %.', new.jenis;
  end if;

  -- --------------------------------------------------- tumpuk, nilai, subtotal
  select coalesce(sum(d.nilai), 0)::integer, count(*)
    into v_sudah, v_jumlah
    from public.diskon_transaksi d
   where d.pesanan_id = new.pesanan_id;

  if v_jumlah > 0 then
    select p.tumpuk_diskon into v_tumpuk from public.pengaturan p where p.penyewa_id = v_pesanan.penyewa_id;
    if not coalesce(v_tumpuk, false) then
      raise exception 'Resto ini hanya mengizinkan satu diskon per transaksi.';
    end if;
  end if;

  if new.nilai <= 0 then
    raise exception 'Nilai diskon harus lebih besar dari nol.';
  end if;

  if coalesce(v_pesanan.subtotal, 0) <= 0 then
    raise exception 'Subtotal pesanan belum tercatat — diskon belum boleh dicatat (hitung pesanan dulu).';
  end if;

  v_total := v_sudah + new.nilai;
  if v_total > v_pesanan.subtotal then
    raise exception 'Total diskon (%) melebihi subtotal pesanan (%).', v_total, v_pesanan.subtotal;
  end if;

  select p.batas_maks_potongan_persen, p.batas_maks_potongan_nominal
    into v_cap_persen, v_cap_nominal
    from public.pengaturan p where p.penyewa_id = v_pesanan.penyewa_id;

  if v_cap_persen is not null and v_cap_persen < 100
     and v_total::numeric * 100 > v_pesanan.subtotal::numeric * v_cap_persen then
    raise exception 'Total potongan (%) melebihi batas maks potongan resto (% persen dari subtotal).',
      v_total, v_cap_persen;
  end if;

  if v_cap_nominal is not null and v_total > v_cap_nominal then
    raise exception 'Total potongan (%) melebihi batas maks potongan resto (Rp %).',
      v_total, v_cap_nominal;
  end if;

  if new.pelaku_id is null then
    new.pelaku_id := auth.uid();
  end if;

  if auth.uid() is not null and new.pelaku_id is distinct from auth.uid() then
    raise exception 'Pelaku diskon diisi sistem — tidak boleh menyebut orang lain.';
  end if;

  return new;
end;
$$;

-- 2. RPC `public.cek_voucher`: HANYA MEMBACA (Read-Only)
create or replace function public.cek_voucher(
  p_kode text,
  p_cabang_id uuid default null,
  p_subtotal numeric default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_kode text := upper(trim(coalesce(p_kode, '')));
  v_penyewa_id uuid := public.penyewa_saya();
  v_voucher record;
  v_kampanye record;
  v_pelanggan record;
  v_estimasi_potongan numeric := 0;
  v_sekarang timestamptz := now();
  v_berlaku_sampai timestamptz;
begin
  if v_kode = '' then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KODE_KOSONG',
      'pesan', 'Kode voucher tidak boleh kosong.'
    );
  end if;

  select v.*
    into v_voucher
    from public.voucher v
   where v.kode = v_kode
     and (v_penyewa_id is null or v.penyewa_id = v_penyewa_id);

  if v_voucher.id is null then
    insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, waktu)
    values (coalesce(v_penyewa_id, '00000000-0000-0000-0000-000000000000'::uuid), v_kode, 'gagal', 'Voucher tidak ditemukan.', auth.uid(), p_cabang_id, now());

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'VOUCHER_TIDAK_DITEMUKAN',
      'pesan', 'Voucher dengan kode tersebut tidak ditemukan.'
    );
  end if;

  select * into v_kampanye
    from public.kampanye_voucher
   where id = v_voucher.kampanye_id;

  select * into v_pelanggan
    from public.pelanggan
   where id = v_voucher.pelanggan_id;

  v_berlaku_sampai := coalesce(v_voucher.berlaku_sampai, v_kampanye.selesai);

  -- A. Periksa Status Voucher
  if v_voucher.status = 'terpakai' then
    insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, waktu)
    values (v_voucher.penyewa_id, v_kode, 'gagal', 'Voucher sudah terpakai.', auth.uid(), p_cabang_id, now());

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'VOUCHER_SUDAH_TERPAKAI',
      'pesan', 'Voucher ini sudah pernah digunakan pada ' || to_char(v_voucher.terpakai_pada at time zone 'Asia/Jakarta', 'DD/MM/YYYY HH24:MI') || '.'
    );
  end if;

  if v_voucher.status = 'dibatalkan' then
    insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, waktu)
    values (v_voucher.penyewa_id, v_kode, 'gagal', 'Voucher dibatalkan.', auth.uid(), p_cabang_id, now());

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'VOUCHER_DIBATALKAN',
      'pesan', 'Voucher ini telah dibatalkan oleh pihak resto.'
    );
  end if;

  if v_voucher.status = 'kedaluwarsa' or (v_berlaku_sampai is not null and v_sekarang > v_berlaku_sampai) then
    insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, waktu)
    values (v_voucher.penyewa_id, v_kode, 'gagal', 'Voucher kedaluwarsa.', auth.uid(), p_cabang_id, now());

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'VOUCHER_KEDALUWARSA',
      'pesan', 'Masa berlaku voucher telah berakhir pada ' || to_char(v_berlaku_sampai at time zone 'Asia/Jakarta', 'DD/MM/YYYY HH24:MI') || '.'
    );
  end if;

  -- B. Periksa Kampanye
  if not coalesce(v_kampanye.aktif, true) or v_sekarang < v_kampanye.mulai or v_sekarang > v_kampanye.selesai then
    insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, waktu)
    values (v_voucher.penyewa_id, v_kode, 'gagal', 'Kampanye tidak aktif atau berakhir.', auth.uid(), p_cabang_id, now());

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KAMPANYE_BERAKHIR',
      'pesan', 'Kampanye promo untuk voucher ini sudah tidak aktif.'
    );
  end if;

  -- C. Periksa Batasan Cabang
  if p_cabang_id is not null and v_kampanye.cabang_berlaku is not null
     and jsonb_typeof(v_kampanye.cabang_berlaku) = 'array'
     and jsonb_array_length(v_kampanye.cabang_berlaku) > 0 then
    if not (v_kampanye.cabang_berlaku @> jsonb_build_array(p_cabang_id::text)) then
      insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, waktu)
      values (v_voucher.penyewa_id, v_kode, 'gagal', 'Cabang tidak berlaku.', auth.uid(), p_cabang_id, now());

      return jsonb_build_object(
        'berhasil', false,
        'kode', 'CABANG_TIDAK_BERLAKU',
        'pesan', 'Voucher ini tidak dapat digunakan di cabang ini.'
      );
    end if;
  end if;

  -- D. Hitung Estimasi Potongan
  if p_subtotal is not null then
    if p_subtotal < v_kampanye.min_belanja then
      insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, waktu)
      values (v_voucher.penyewa_id, v_kode, 'gagal', 'Subtotal belum memenuhi min belanja.', auth.uid(), p_cabang_id, now());

      return jsonb_build_object(
        'berhasil', false,
        'kode', 'SUBTOTAL_KURANG',
        'pesan', 'Total belanja belum memenuhi syarat minimum Rp ' || to_char(v_kampanye.min_belanja, 'FM999,999,999') || ' (saat ini Rp ' || to_char(p_subtotal, 'FM999,999,999') || ').',
        'data', jsonb_build_object(
          'min_belanja', v_kampanye.min_belanja,
          'subtotal_sekarang', p_subtotal
        )
      );
    end if;

    if v_kampanye.jenis = 'persen' then
      v_estimasi_potongan := floor((p_subtotal * v_kampanye.nilai) / 100);
      if v_kampanye.maks_potongan is not null and v_estimasi_potongan > v_kampanye.maks_potongan then
        v_estimasi_potongan := v_kampanye.maks_potongan;
      end if;
    else
      v_estimasi_potongan := v_kampanye.nilai;
      if v_estimasi_potongan > p_subtotal then
        v_estimasi_potongan := p_subtotal;
      end if;
    end if;
  else
    if v_kampanye.jenis = 'nominal' then
      v_estimasi_potongan := v_kampanye.nilai;
    end if;
  end if;

  insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, kasir_id, cabang_id, waktu)
  values (v_voucher.penyewa_id, v_kode, 'cek_sah', auth.uid(), p_cabang_id, now());

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SUKSES',
    'pesan', 'Voucher sah dan siap digunakan.',
    'data', jsonb_build_object(
      'voucher_id', v_voucher.id,
      'kode_voucher', v_voucher.kode,
      'status', v_voucher.status,
      'nama_kampanye', v_kampanye.nama,
      'jenis', v_kampanye.jenis,
      'nilai', v_kampanye.nilai,
      'min_belanja', v_kampanye.min_belanja,
      'maks_potongan', v_kampanye.maks_potongan,
      'estimasi_potongan', v_estimasi_potongan,
      'nama_pelanggan', v_pelanggan.nama,
      'berlaku_sampai', v_berlaku_sampai
    )
  );
end;
$$;

-- 3. RPC `public.pakai_voucher`: Atomik Sekali Pakai + PIN Kasir (ART-5)
create or replace function public.pakai_voucher(
  p_pesanan_id uuid,
  p_kode text,
  p_pin_kasir text,
  p_kunci_idempoten text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_kode text := upper(trim(coalesce(p_kode, '')));
  v_saya uuid := auth.uid();
  v_pesanan record;
  v_voucher record;
  v_kampanye record;
  v_pelanggan record;
  v_kasir record;
  v_potongan integer := 0;
  v_diskon_sudah record;
  v_tumpuk boolean;
begin
  if v_saya is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TIDAK_TERAUTENTIKASI',
      'pesan', 'Anda harus masuk sebagai kasir untuk menggunakan voucher.'
    );
  end if;

  -- 1. Izin kasir
  if not public.boleh('pakai_voucher') then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TIDAK_BERIZIN',
      'pesan', 'Anda tidak memiliki izin untuk memakai voucher.'
    );
  end if;

  -- 2. Verifikasi PIN Kasir
  select p.*, k.pin_hash
    into v_kasir
    from public.pengguna p
    left join public.kredensial_pin k on k.pengguna_id = p.id
   where p.id = v_saya;

  if v_kasir.id is null or not coalesce(v_kasir.aktif, false) or v_kasir.pin_hash is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KASIR_TIDAK_VALID',
      'pesan', 'Akun kasir tidak aktif atau belum memiliki PIN.'
    );
  end if;

  if p_pin_kasir is null or p_pin_kasir = '' or crypt(p_pin_kasir, v_kasir.pin_hash) is distinct from v_kasir.pin_hash then
    insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, pesanan_id)
    values (v_saya, 'kasir', false, 'pakai_voucher', p_pesanan_id);

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PIN_SALAH',
      'pesan', 'PIN kasir tidak sah. Mohon periksa kembali PIN Anda.'
    );
  end if;

  insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, pesanan_id)
  values (v_saya, 'kasir', true, 'pakai_voucher', p_pesanan_id);

  -- 3. Verifikasi Pesanan
  select * into v_pesanan
    from public.pesanan
   where id = p_pesanan_id;

  if v_pesanan.id is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PESANAN_TIDAK_DITEMUKAN',
      'pesan', 'Pesanan tidak ditemukan.'
    );
  end if;

  if v_pesanan.status in ('lunas', 'batal') then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PESANAN_SUDAH_SELESAI',
      'pesan', 'Pesanan sudah berstatus ' || v_pesanan.status || '; voucher tidak dapat ditambahkan.'
    );
  end if;

  if coalesce(v_pesanan.subtotal, 0) <= 0 then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'SUBTOTAL_KOSONG',
      'pesan', 'Pesanan belum memiliki item atau subtotal masih 0.'
    );
  end if;

  -- 4. Idempoten: Cek apakah voucher ini sudah tercatat pada pesanan ini
  select dt.* into v_diskon_sudah
    from public.diskon_transaksi dt
    join public.voucher v on v.id = dt.voucher_id
   where dt.pesanan_id = p_pesanan_id
     and v.kode = v_kode;

  if v_diskon_sudah.id is not null then
    return jsonb_build_object(
      'berhasil', true,
      'kode', 'IDEMPOTEN',
      'pesan', 'Voucher sudah diterapkan pada pesanan ini.',
      'data', jsonb_build_object(
        'diskon_id', v_diskon_sudah.id,
        'nilai_potongan', v_diskon_sudah.nilai,
        'kode_voucher', v_kode
      )
    );
  end if;

  -- 5. Cek Pengaturan Tumpuk Diskon
  select p.tumpuk_diskon into v_tumpuk
    from public.pengaturan p
   where p.penyewa_id = v_pesanan.penyewa_id;

  if not coalesce(v_tumpuk, false) and exists (
    select 1 from public.diskon_transaksi where pesanan_id = p_pesanan_id
  ) then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TUMPUK_DISKON_DILARANG',
      'pesan', 'Resto ini hanya mengizinkan satu diskon per transaksi.'
    );
  end if;

  -- 6. Verifikasi & Kunci Voucher Atomik (ART-5)
  update public.voucher
     set status = 'terpakai',
         terpakai_pada = now(),
         terpakai_di_cabang = v_pesanan.cabang_id,
         terpakai_oleh = v_saya,
         pesanan_id = p_pesanan_id
   where kode = v_kode
     and penyewa_id = v_pesanan.penyewa_id
     and status = 'aktif'
     and (berlaku_sampai is null or berlaku_sampai >= now())
  returning * into v_voucher;

  if v_voucher.id is null then
    select * into v_voucher from public.voucher where kode = v_kode and penyewa_id = v_pesanan.penyewa_id;
    if v_voucher.id is null then
      return jsonb_build_object('berhasil', false, 'kode', 'VOUCHER_TIDAK_DITEMUKAN', 'pesan', 'Voucher tidak ditemukan.');
    elsif v_voucher.status = 'terpakai' then
      return jsonb_build_object('berhasil', false, 'kode', 'VOUCHER_SUDAH_TERPAKAI', 'pesan', 'Voucher ini sudah pernah digunakan.');
    elsif v_voucher.status = 'dibatalkan' then
      return jsonb_build_object('berhasil', false, 'kode', 'VOUCHER_DIBATALKAN', 'pesan', 'Voucher ini telah dibatalkan.');
    else
      return jsonb_build_object('berhasil', false, 'kode', 'VOUCHER_KEDALUWARSA', 'pesan', 'Masa berlaku voucher telah berakhir.');
    end if;
  end if;

  select * into v_kampanye from public.kampanye_voucher where id = v_voucher.kampanye_id;
  select * into v_pelanggan from public.pelanggan where id = v_voucher.pelanggan_id;

  -- 7. Cek Cabang Berlaku
  if v_kampanye.cabang_berlaku is not null
     and jsonb_typeof(v_kampanye.cabang_berlaku) = 'array'
     and jsonb_array_length(v_kampanye.cabang_berlaku) > 0 then
    if not (v_kampanye.cabang_berlaku @> jsonb_build_array(v_pesanan.cabang_id::text)) then
      update public.voucher set status = 'aktif', terpakai_pada = null, terpakai_di_cabang = null, terpakai_oleh = null, pesanan_id = null where id = v_voucher.id;
      return jsonb_build_object('berhasil', false, 'kode', 'CABANG_TIDAK_BERLAKU', 'pesan', 'Voucher ini tidak berlaku di cabang ini.');
    end if;
  end if;

  -- 8. Cek Minimal Belanja
  if v_pesanan.subtotal < v_kampanye.min_belanja then
    update public.voucher set status = 'aktif', terpakai_pada = null, terpakai_di_cabang = null, terpakai_oleh = null, pesanan_id = null where id = v_voucher.id;
    return jsonb_build_object('berhasil', false, 'kode', 'SUBTOTAL_KURANG', 'pesan', 'Subtotal pesanan belum memenuhi minimum belanja Rp ' || v_kampanye.min_belanja || '.');
  end if;

  -- 9. Hitung Nilai Potongan Diskon
  if v_kampanye.jenis = 'persen' then
    v_potongan := floor((v_pesanan.subtotal * v_kampanye.nilai) / 100)::integer;
    if v_kampanye.maks_potongan is not null and v_potongan > v_kampanye.maks_potongan then
      v_potongan := v_kampanye.maks_potongan::integer;
    end if;
  else
    v_potongan := v_kampanye.nilai::integer;
  end if;

  if v_potongan > v_pesanan.subtotal then
    v_potongan := v_pesanan.subtotal::integer;
  end if;

  -- 10. Rekam Diskon Transaksi (Trigger picu_diskon_batas & hitung_total akan berjalan)
  insert into public.diskon_transaksi (
    pesanan_id,
    jenis,
    persen,
    nominal,
    nilai,
    alasan,
    pelaku_id,
    voucher_id
  ) values (
    p_pesanan_id,
    'voucher',
    case when v_kampanye.jenis = 'persen' then v_kampanye.nilai else null end,
    case when v_kampanye.jenis = 'nominal' then v_kampanye.nilai else null end,
    v_potongan,
    'Voucher: ' || v_kampanye.nama || ' (' || v_kode || ')',
    v_saya,
    v_voucher.id
  );

  insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, kasir_id, cabang_id, waktu)
  values (v_pesanan.penyewa_id, v_kode, 'pakai_berhasil', v_saya, v_pesanan.cabang_id, now());

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SUKSES',
    'pesan', 'Voucher berhasil digunakan.',
    'data', jsonb_build_object(
      'voucher_id', v_voucher.id,
      'kode_voucher', v_kode,
      'nilai_potongan', v_potongan,
      'nama_kampanye', v_kampanye.nama,
      'nama_pelanggan', v_pelanggan.nama
    )
  );
end;
$$;

-- Izin fungsi (SECURITY DEFINER wajib cabut public, batasi akses)
revoke all on function public.cek_voucher(text, uuid, numeric) from public, anon;
grant execute on function public.cek_voucher(text, uuid, numeric) to authenticated, anon, service_role;

revoke all on function public.pakai_voucher(uuid, text, text, text) from public, anon;
grant execute on function public.pakai_voucher(uuid, text, text, text) to authenticated, service_role;

-- Izin tabel voucher & pelanggan untuk authenticated & service_role
grant select, insert, update on public.pelanggan to authenticated;
grant select, insert, update on public.kampanye_voucher to authenticated;
grant select, update on public.voucher to authenticated;
grant select, insert on public.voucher_percobaan to authenticated;

grant select, insert, update, delete on public.pelanggan, public.kampanye_voucher, public.voucher, public.voucher_percobaan to service_role;
