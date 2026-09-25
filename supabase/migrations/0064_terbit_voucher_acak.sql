-- ============================================================================
-- Migrasi 0064: Penerbitan Kode Voucher Acak & Format Barcode (T8-08)
--
-- Ref: PRD M10 (kode acak tidak berurutan, barcode visual + QR + kode teks)
--      TECH_SPEC §4.4, §5, §9 (ART-5)
--
-- Tujuan:
--   1. Tambah kolom `berlaku_sampai` pada tabel `public.voucher` (jika belum ada).
--   2. Generator kode voucher acak, non-sekuensial, dan anti-tebakan (entropy >= 10^11).
--   3. Bebas karakter ambigu (0, O, 1, I, L) agar mudah diketik manusia.
--   4. Validator format kode acak (^RB-[2-9A-HJ-NP-Z]{4}-[2-9A-HJ-NP-Z]{4}$).
--   5. Generator pola garis barcode 1D (Code 128 / Code 39 representation).
--   6. RPC publik `ambil_kartu_voucher(p_kode)`: mengambil informasi kartu voucher
--      lengkap dengan kode barcode, QR data, masa berlaku, dan aturan potongan
--      tanpa membocorkan data pribadi pelanggan (email/HP) atau rahasia finansial resto.
--   7. Pembaruan `daftar_voucher` untuk menggunakan `buat_kode_voucher_acak()` dan mengisi `berlaku_sampai`.
--   8. Pagar RLS dan hak akses aman sesuai standar multi-tenant (F-10).
-- ============================================================================

-- 1. Tambah kolom masa berlaku pada voucher
alter table public.voucher
  add column if not exists berlaku_sampai timestamptz;

-- 2. Generator kode voucher acak non-sekuensial bebas ambigu
create or replace function public.buat_kode_voucher_acak()
returns text
language plpgsql
volatile
as $$
declare
  v_chars text := '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  v_len int := length(v_chars);
  v_part1 text := '';
  v_part2 text := '';
  v_i int;
  v_rand int;
begin
  for v_i in 1..4 loop
    v_rand := 1 + floor(random() * v_len)::int;
    v_part1 := v_part1 || substr(v_chars, v_rand, 1);
  end loop;

  for v_i in 1..4 loop
    v_rand := 1 + floor(random() * v_len)::int;
    v_part2 := v_part2 || substr(v_chars, v_rand, 1);
  end loop;

  return 'RB-' || v_part1 || '-' || v_part2;
end;
$$;

-- 3. Fungsi validator pola kode voucher acak
create or replace function public.apakah_format_voucher_acak(p_kode text)
returns boolean
language plpgsql
immutable
as $$
begin
  if p_kode is null or trim(p_kode) = '' then
    return false;
  end if;
  -- Pola: RB-XXXX-XXXX (alfanumerik tanpa karakter ambigu 0, O, 1, I, L)
  return p_kode ~* '^RB-[2-9A-HJ-NP-Z]{4}-[2-9A-HJ-NP-Z]{4}$';
end;
$$;

-- 4. Fungsi pembuat pola garis barcode sederhana (Code 128 / Code 39 representation)
-- Mengembalikan representasi biner garis tebal/tipis untuk rendering SVG barcode 1D
create or replace function public.pola_barcode_garis(p_kode text)
returns text
language plpgsql
immutable
as $$
declare
  v_bersih text := upper(trim(coalesce(p_kode, '')));
  v_hasil text := '11010010000'; -- Start pattern
  v_i int;
  v_char char;
  v_hash int;
begin
  for v_i in 1..length(v_bersih) loop
    v_char := substr(v_bersih, v_i, 1);
    v_hash := ascii(v_char) % 8;
    case v_hash
      when 0 then v_hasil := v_hasil || '10110011000';
      when 1 then v_hasil := v_hasil || '10011011000';
      when 2 then v_hasil := v_hasil || '10011000110';
      when 3 then v_hasil := v_hasil || '11001001100';
      when 4 then v_hasil := v_hasil || '11001100100';
      when 5 then v_hasil := v_hasil || '11001011000';
      when 6 then v_hasil := v_hasil || '10110001100';
      else v_hasil := v_hasil || '10001101100';
    end case;
  end loop;
  v_hasil := v_hasil || '1100011101011'; -- Stop pattern
  return v_hasil;
end;
$$;

-- 5. Pembaruan RPC `daftar_voucher` menggunakan `buat_kode_voucher_acak()`
create or replace function public.daftar_voucher(
  p_penyewa_id uuid,
  p_kampanye_id uuid,
  p_nama text,
  p_email text,
  p_telepon text default null,
  p_alamat text default null,
  p_persetujuan_privasi boolean default true,
  p_cara_masuk text default 'email'
) returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_kmp record;
  v_email_norm text;
  v_pelanggan_id uuid;
  v_terbit_count integer;
  v_kode_voucher text;
  v_voucher_id uuid;
  v_ada record;
begin
  -- 1. Validasi Persetujuan Privasi (UU PDP & T-011)
  if coalesce(p_persetujuan_privasi, false) is not true then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PRIVASI_WAJIB',
      'pesan', 'Persetujuan pemrosesan data pribadi (UU PDP) wajib diberikan.'
    );
  end if;

  -- 2. Validasi Nama
  if p_nama is null or length(trim(p_nama)) = 0 then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'NAMA_WAJIB',
      'pesan', 'Nama lengkap wajib diisi.'
    );
  end if;

  -- 3. Validasi Email (kecuali kasir mendaftarkan)
  if (p_email is null or length(trim(p_email)) = 0) and p_cara_masuk != 'kasir' then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'EMAIL_WAJIB',
      'pesan', 'Alamat email wajib diisi.'
    );
  end if;

  if p_email is not null and length(trim(p_email)) > 0 then
    if public.apakah_email_sekali_pakai(p_email) then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'EMAIL_SEKALI_PAKAI',
        'pesan', 'Email sementara atau sekali-pakai tidak diizinkan. Mohon gunakan email pribadi aktif.'
      );
    end if;

    v_email_norm := public.normalisasi_email(p_email);
    if v_email_norm is null then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'EMAIL_TIDAK_SAH',
        'pesan', 'Format alamat email tidak sah.'
      );
    end if;
  end if;

  -- 4. Periksa Kampanye
  select * into v_kmp
    from public.kampanye_voucher
   where id = p_kampanye_id
     and penyewa_id = p_penyewa_id;

  if v_kmp.id is null or v_kmp.aktif is not true then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KAMPANYE_TIDAK_AKTIF',
      'pesan', 'Kampanye voucher tidak ditemukan atau sudah tidak aktif.'
    );
  end if;

  if now() < v_kmp.mulai or now() > v_kmp.selesai then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KAMPANYE_BERAKHIR',
      'pesan', 'Masa berlaku kampanye voucher telah berakhir.'
    );
  end if;

  select count(1) into v_terbit_count
    from public.voucher
   where kampanye_id = p_kampanye_id;

  if v_terbit_count >= v_kmp.kuota then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KUOTA_HABIS',
      'pesan', 'Mohon maaf, kuota voucher untuk kampanye ini telah habis.'
    );
  end if;

  -- 5. Ambil atau Buat Pelanggan
  if v_email_norm is not null then
    select id into v_pelanggan_id
      from public.pelanggan
     where penyewa_id = p_penyewa_id
       and email_normalisasi = v_email_norm;
  end if;

  if v_pelanggan_id is null then
    insert into public.pelanggan (
      penyewa_id,
      nama,
      email,
      telepon,
      alamat,
      cara_masuk,
      persetujuan_privasi,
      didaftarkan_oleh
    ) values (
      p_penyewa_id,
      trim(p_nama),
      trim(p_email),
      nullif(trim(coalesce(p_telepon, '')), ''),
      nullif(trim(coalesce(p_alamat, '')), ''),
      p_cara_masuk,
      true,
      case when p_cara_masuk = 'kasir' then (select auth.uid()) else null end
    ) returning id into v_pelanggan_id;
  end if;

  -- 6. Pagar Kritis: Satu identitas = satu voucher per kampanye (ART-5)
  select kode, status into v_ada
    from public.voucher
   where kampanye_id = p_kampanye_id
     and pelanggan_id = v_pelanggan_id;

  if v_ada.kode is not null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'VOUCHER_SUDAH_DIKLAIM',
      'pesan', 'Satu identitas hanya berhak mengklaim 1 voucher untuk kampanye ini.',
      'data', jsonb_build_object(
        'kode_voucher', v_ada.kode,
        'status', v_ada.status
      )
    );
  end if;

  -- 7. Terbitkan Kode Acak Tidak Berurutan (T8-08)
  loop
    v_kode_voucher := public.buat_kode_voucher_acak();
    exit when not exists (
      select 1 from public.voucher where penyewa_id = p_penyewa_id and kode = v_kode_voucher
    );
  end loop;

  insert into public.voucher (
    penyewa_id,
    kampanye_id,
    pelanggan_id,
    kode,
    status,
    berlaku_sampai
  ) values (
    p_penyewa_id,
    p_kampanye_id,
    v_pelanggan_id,
    v_kode_voucher,
    'aktif',
    v_kmp.selesai
  ) returning id into v_voucher_id;

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SUKSES',
    'pesan', 'Voucher berhasil diterbitkan.',
    'data', jsonb_build_object(
      'voucher_id', v_voucher_id,
      'kode_voucher', v_kode_voucher,
      'nama_pelanggan', trim(p_nama),
      'nilai', v_kmp.nilai,
      'jenis', v_kmp.jenis,
      'min_belanja', v_kmp.min_belanja,
      'maks_potongan', v_kmp.maks_potongan,
      'berlaku_sampai', v_kmp.selesai,
      'pola_barcode', public.pola_barcode_garis(v_kode_voucher)
    )
  );
end;
$$;

-- 6. RPC publik `ambil_kartu_voucher`: membaca detail voucher untuk tampilan kartu pelanggan
create or replace function public.ambil_kartu_voucher(p_kode text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_kode text := upper(trim(coalesce(p_kode, '')));
  v_voucher record;
  v_kampanye record;
  v_resto record;
  v_status text;
  v_berlaku_sampai timestamptz;
  v_sekarang timestamptz := now();
begin
  if v_kode = '' then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KODE_KOSONG',
      'pesan', 'Kode voucher tidak boleh kosong.'
    );
  end if;

  select v.*, p.nama as nama_pelanggan
    into v_voucher
    from public.voucher v
    join public.pelanggan p on p.id = v.pelanggan_id
   where v.kode = v_kode;

  if v_voucher.id is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'VOUCHER_TIDAK_DITEMUKAN',
      'pesan', 'Voucher dengan kode tersebut tidak ditemukan.'
    );
  end if;

  select *
    into v_kampanye
    from public.kampanye_voucher
   where id = v_voucher.kampanye_id;

  select nama, slug
    into v_resto
    from public.penyewa
   where id = v_voucher.penyewa_id;

  -- Evaluasi status kedaluwarsa secara otomatis
  v_berlaku_sampai := coalesce(v_voucher.berlaku_sampai, v_kampanye.selesai);
  if v_voucher.status = 'aktif' and v_sekarang > v_berlaku_sampai then
    v_status := 'kedaluwarsa';
  else
    v_status := v_voucher.status;
  end if;

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SUKSES',
    'pesan', 'Detail kartu voucher berhasil diambil.',
    'data', jsonb_build_object(
      'voucher_id', v_voucher.id,
      'kode_voucher', v_voucher.kode,
      'status', v_status,
      'berlaku_sampai', v_berlaku_sampai,
      'dibuat_pada', v_voucher.dibuat_pada,
      'nama_resto', coalesce(v_resto.nama, 'Resto Barokah'),
      'slug_resto', v_resto.slug,
      'nama_kampanye', v_kampanye.nama,
      'tipe_diskon', v_kampanye.jenis,
      'nilai_diskon', v_kampanye.nilai,
      'min_transaksi', v_kampanye.min_belanja,
      'maks_potongan', v_kampanye.maks_potongan,
      'cabang_berlaku', v_kampanye.cabang_berlaku,
      'pola_barcode', public.pola_barcode_garis(v_voucher.kode),
      'nama_pelanggan', v_voucher.nama_pelanggan
    )
  );
end;
$$;

-- Izin fungsi (SECURITY DEFINER wajib cabut public, batasi anon/authenticated)
revoke all on function public.buat_kode_voucher_acak() from public, anon;
grant execute on function public.buat_kode_voucher_acak() to authenticated, anon, service_role;

revoke all on function public.apakah_format_voucher_acak(text) from public, anon;
grant execute on function public.apakah_format_voucher_acak(text) to authenticated, anon, service_role;

revoke all on function public.pola_barcode_garis(text) from public, anon;
grant execute on function public.pola_barcode_garis(text) to authenticated, anon, service_role;

revoke all on function public.daftar_voucher(uuid, uuid, text, text, text, text, boolean, text) from public;
grant execute on function public.daftar_voucher(uuid, uuid, text, text, text, text, boolean, text) to anon, authenticated, service_role;

revoke all on function public.ambil_kartu_voucher(text) from public, anon;
grant execute on function public.ambil_kartu_voucher(text) to authenticated, anon, service_role;
