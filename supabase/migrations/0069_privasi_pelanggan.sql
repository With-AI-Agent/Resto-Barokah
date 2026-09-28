-- ============================================================================
-- Migrasi 0069: Privasi Pelanggan (Persetujuan & Anonimisasi UU PDP) (T8-15)
--
-- Ref: PRD M10 & M12; TECH_SPEC §9 ART-14; docs/KEAMANAN.md §11; docs/PRIVASI_PELANGGAN.md
--
-- Tujuan & Pagar:
-- 1. Penegasan kolom persetujuan privasi, waktu, dan versi kebijakan (UU No. 27/2022).
-- 2. Penambahan kolom status privasi & audit anonimisasi pada public.pelanggan:
--    - status_privasi: 'aktif' | 'teranonimkan'
--    - dianonimkan_pada: timestamptz
--    - alasan_anonimisasi: text
--    - dianonimkan_oleh: uuid (pengguna yang mengeksekusi)
-- 3. Penyesuaian pemicu & constraint agar mendukung keadaan teranonimkan:
--    - email, telepon, dan alamat dibersihkan (null), nama disamarkan,
--      sementara ID pelanggan, persetujuan awal, dan relasi ke voucher/pesanan TETAP UTUH.
-- 4. RPC atomik public.anonimkan_pelanggan(p_pelanggan_id, p_alasan):
--    - Menghapus kontak pribadi tanpa menghapus catatan finansial (voucher, transaksi).
--    - Memverifikasi otorisasi penyewa dan peran (owner_pusat, admin_cabang, kasir).
--    - Mencatat jejak audit ke public.catatan_audit (tidak dapat dihapus).
--    - Bersifat idempoten jika dipanggil berulang kali.
-- 5. RPC public.cek_privasi_pelanggan(p_pelanggan_id):
--    - Memeriksa status kepatuhan privasi subjek data di bawah isolasi penyewa.
-- ============================================================================

-- 1. Tambah kolom status privasi dan catatan anonimisasi pada tabel pelanggan
alter table public.pelanggan
  add column if not exists status_privasi text not null default 'aktif'
    check (status_privasi in ('aktif', 'teranonimkan')),
  add column if not exists dianonimkan_pada timestamptz,
  add column if not exists alasan_anonimisasi text,
  add column if not exists dianonimkan_oleh uuid references public.pengguna(id);

-- 2. Sesuaikan batasan cara_masuk agar mendukung pelanggan yang dianonimkan
alter table public.pelanggan
  drop constraint if exists pelanggan_cara_masuk_valid;

alter table public.pelanggan
  add constraint pelanggan_cara_masuk_valid check (
    (status_privasi = 'teranonimkan')
    or
    (cara_masuk in ('google', 'email') and email is not null and email_normalisasi is not null and length(trim(email)) > 0)
    or
    (cara_masuk = 'kasir' and didaftarkan_oleh is not null)
  );

-- 3. Perbarui pemicu validasi pelanggan untuk mendukung alur anonimisasi
create or replace function public.picu_pelanggan_validasi_email()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  -- Persetujuan privasi UU PDP wajib bernilai true sejak awal pembuatan data
  if coalesce(new.persetujuan_privasi, false) is not true then
    raise exception 'Persetujuan pemrosesan data pribadi (UU PDP) wajib diberikan.'
      using errcode = '22023';
  end if;

  -- Jika data dalam status teranonimkan, kontak wajib kosong
  if new.status_privasi = 'teranonimkan' then
    new.email := null;
    new.email_normalisasi := null;
    new.telepon := null;
    new.alamat := null;
    if new.dianonimkan_pada is null then
      new.dianonimkan_pada := now();
    end if;
    new.diubah_pada := now();
    return new;
  end if;

  -- Validasi alamat email jika pelanggan masih berstatus aktif
  if new.email is not null and length(trim(new.email)) > 0 then
    new.email := trim(new.email);

    if public.apakah_email_sekali_pakai(new.email) then
      raise exception 'Email sekali-pakai tidak diizinkan. Mohon gunakan email pribadi aktif.'
        using errcode = '22023';
    end if;

    new.email_normalisasi := public.normalisasi_email(new.email);
    if new.email_normalisasi is null then
      raise exception 'Format alamat email tidak sah.'
        using errcode = '22023';
    end if;
  else
    new.email := null;
    new.email_normalisasi := null;
  end if;

  if new.cara_masuk in ('google', 'email') and new.terverifikasi_pada is null then
    new.terverifikasi_pada := now();
  end if;

  new.diubah_pada := now();
  return new;
end;
$$;

revoke all on function public.picu_pelanggan_validasi_email() from public, anon, authenticated;

-- 4. RPC Atomik: Anonimkan Data Pelanggan (UU PDP)
create or replace function public.anonimkan_pelanggan(
  p_pelanggan_id uuid,
  p_alasan text default 'permintaan_subjek_data_uu_pdp'
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pelanggan public.pelanggan%rowtype;
  v_penyewa_pemanggil uuid;
  v_peran text;
  v_uid uuid;
  v_jumlah_voucher int;
  v_pesanan_terkait int;
  v_alasan_bersih text;
begin
  -- 1. Identifikasi pemanggil
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Tidak diautentikasi.' using errcode = '42501';
  end if;

  v_penyewa_pemanggil := (select public.penyewa_saya());
  v_peran := (select public.peran_saya());

  -- 2. Dapatkan data pelanggan target dengan kunci baris (FOR UPDATE)
  select * into v_pelanggan
  from public.pelanggan
  where id = p_pelanggan_id
  for update;

  if not found then
    raise exception 'Pelanggan tidak ditemukan.' using errcode = 'P0002';
  end if;

  -- 3. Isolasi penyewa: hanya boleh memproses pelanggan di resto pemanggil
  if v_pelanggan.penyewa_id <> v_penyewa_pemanggil then
    raise exception 'Akses ditolak: pelanggan bukan milik penyewa Anda.' using errcode = '42501';
  end if;

  -- 4. Otorisasi peran: peran berwenang owner_pusat, admin_cabang, atau kasir
  if v_peran not in ('owner_pusat', 'admin_cabang', 'kasir') then
    raise exception 'Peran % tidak memiliki wewenang untuk menganonimkan data pelanggan.', coalesce(v_peran, 'tanpa_peran')
      using errcode = '42501';
  end if;

  v_alasan_bersih := coalesce(nullif(trim(p_alasan), ''), 'permintaan_subjek_data_uu_pdp');

  -- 5. Penanganan Idempoten: bila sudah teranonimkan sebelumnya
  if v_pelanggan.status_privasi = 'teranonimkan' then
    select count(*) into v_jumlah_voucher
    from public.voucher
    where pelanggan_id = v_pelanggan.id;

    select count(distinct pesanan_id) into v_pesanan_terkait
    from public.voucher
    where pelanggan_id = v_pelanggan.id and pesanan_id is not null;

    return jsonb_build_object(
      'sukses', true,
      'idempoten', true,
      'pelanggan_id', v_pelanggan.id,
      'status_privasi', 'teranonimkan',
      'dianonimkan_pada', v_pelanggan.dianonimkan_pada,
      'voucher_tetap_utuh', v_jumlah_voucher,
      'pesanan_tetap_utuh', v_pesanan_terkait,
      'pesan', 'Data pelanggan sudah dalam keadaan teranonimkan sebelumnya.'
    );
  end if;

  -- 6. Verifikasi keutuhan finansial: hitung voucher & pesanan terkait sebelum pembersihan
  select count(*) into v_jumlah_voucher
  from public.voucher
  where pelanggan_id = v_pelanggan.id;

  select count(distinct pesanan_id) into v_pesanan_terkait
  from public.voucher
  where pelanggan_id = v_pelanggan.id and pesanan_id is not null;

  -- 7. Bersihkan data kontak pribadi pada tabel pelanggan
  update public.pelanggan
  set
    nama = 'Pelanggan Teranonimkan (UU PDP)',
    email = null,
    email_normalisasi = null,
    telepon = null,
    alamat = null,
    status_privasi = 'teranonimkan',
    dianonimkan_pada = now(),
    alasan_anonimisasi = v_alasan_bersih,
    dianonimkan_oleh = v_uid,
    diubah_pada = now()
  where id = v_pelanggan.id;

  -- 8. Catat jejak audit kekal
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_lama,
    nilai_baru
  ) values (
    v_pelanggan.penyewa_id,
    v_uid,
    'anonimisasi_pelanggan',
    'pelanggan',
    v_pelanggan.id,
    jsonb_build_object(
      'status_privasi', v_pelanggan.status_privasi,
      'memiliki_email', v_pelanggan.email is not null,
      'memiliki_telepon', v_pelanggan.telepon is not null
    ),
    jsonb_build_object(
      'status_privasi', 'teranonimkan',
      'dianonimkan_pada', now(),
      'kontak_dihapus', true,
      'alasan', v_alasan_bersih
    )
  );

  return jsonb_build_object(
    'sukses', true,
    'idempoten', false,
    'pelanggan_id', v_pelanggan.id,
    'status_privasi', 'teranonimkan',
    'dianonimkan_pada', now(),
    'voucher_tetap_utuh', v_jumlah_voucher,
    'pesanan_tetap_utuh', v_pesanan_terkait,
    'pesan', 'Data pribadi pelanggan berhasil dianonimkan sesuai UU PDP. Catatan transaksi dan voucher tetap utuh.'
  );
end;
$$;

comment on function public.anonimkan_pelanggan(uuid, text) is
  'Menghapus kontak pribadi pelanggan atas permintaan hak subjek data (UU PDP) tanpa menghapus catatan transaksi dan voucher.';

revoke all on function public.anonimkan_pelanggan(uuid, text) from public;
grant execute on function public.anonimkan_pelanggan(uuid, text) to authenticated;

-- 5. RPC Pengecekan Status Privasi Pelanggan
create or replace function public.cek_privasi_pelanggan(p_pelanggan_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_res jsonb;
  v_penyewa uuid;
begin
  if auth.uid() is null then
    raise exception 'Tidak diautentikasi.' using errcode = '42501';
  end if;

  v_penyewa := (select public.penyewa_saya());

  select jsonb_build_object(
    'id', p.id,
    'penyewa_id', p.penyewa_id,
    'status_privasi', p.status_privasi,
    'persetujuan_privasi', p.persetujuan_privasi,
    'persetujuan_privasi_versi', p.persetujuan_privasi_versi,
    'persetujuan_privasi_pada', p.persetujuan_privasi_pada,
    'dianonimkan_pada', p.dianonimkan_pada,
    'alasan_anonimisasi', p.alasan_anonimisasi
  ) into v_res
  from public.pelanggan p
  where p.id = p_pelanggan_id
    and p.penyewa_id = v_penyewa;

  if v_res is null then
    raise exception 'Pelanggan tidak ditemukan atau di luar wewenang.' using errcode = 'P0002';
  end if;

  return v_res;
end;
$$;

comment on function public.cek_privasi_pelanggan(uuid) is
  'Memeriksa status persetujuan dan riwayat anonimisasi data pelanggan di bawah isolasi penyewa.';

revoke all on function public.cek_privasi_pelanggan(uuid) from public;
grant execute on function public.cek_privasi_pelanggan(uuid) to authenticated;
