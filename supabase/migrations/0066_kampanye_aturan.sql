-- ============================================================================
-- Migrasi 0066: Pengaturan Kampanye Voucher oleh Admin (T8-11)
--
-- Ref: PRD M10 (aturan diatur admin) & M2 (hak akses admin/pemilik)
--
-- Tujuan:
--   1. Penjaga integritas aturan kampanye (`picu_validasi_aturan_kampanye`):
--      mencegah aturan mustahil (persen > 100%, nominal <= 0, kuota <= 0,
--      anggaran < nilai voucher, selesai <= mulai, min_belanja negatif).
--   2. Format rupiah dan kalimat aturan bahasa manusia (`format_aturan_kampanye`).
--   3. RPC `simpan_kampanye_voucher` (create / update kampanye voucher aman).
--   4. RPC `ambil_daftar_kampanye` (daftar kampanye dengan statistik klaim & serapan).
--   5. RPC `ubah_status_kampanye` (aktifkan / nonaktifkan kampanye promo).
-- ============================================================================

-- 1. Helper Format Rupiah
create or replace function public.format_rupiah(p_nilai numeric)
returns text
language plpgsql
immutable
leakproof
set search_path = public, pg_temp
as $$
begin
  if p_nilai is null or p_nilai = 0 then
    return 'Rp0';
  end if;
  return 'Rp' || replace(to_char(round(p_nilai), 'FM999,999,999,999'), ',', '.');
end;
$$;

comment on function public.format_rupiah(numeric) is
  'Memformat angka desimal/bulat menjadi string mata uang Rupiah tanpa spasi (mis. Rp50.000).';

-- 2. Pemicu Validasi Integritas Aturan Kampanye (Mencegah Aturan Mustahil)
create or replace function public.picu_validasi_aturan_kampanye()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- 1. Validasi jenis dan nilai diskon
  if new.jenis not in ('persen', 'nominal') then
    raise exception 'Jenis voucher harus persen atau nominal.';
  end if;

  if new.jenis = 'persen' and (new.nilai <= 0 or new.nilai > 100) then
    raise exception 'Diskon persen harus bernilai antara 1%% sampai 100%%.';
  end if;

  if new.jenis = 'nominal' and new.nilai <= 0 then
    raise exception 'Nilai potongan nominal voucher harus lebih besar dari 0.';
  end if;

  -- 2. Validasi masa berlaku
  if new.selesai <= new.mulai then
    raise exception 'Masa berlaku selesai harus sesudah tanggal mulai kampanye.';
  end if;

  -- 3. Validasi kuota dan anggaran
  if new.kuota <= 0 then
    raise exception 'Kuota voucher harus lebih besar dari 0.';
  end if;

  if new.anggaran_maks <= 0 then
    raise exception 'Anggaran maksimal kampanye harus lebih besar dari 0.';
  end if;

  if new.jenis = 'nominal' and new.anggaran_maks < new.nilai then
    raise exception 'Anggaran kampanye tidak boleh lebih kecil dari nilai voucher tunggal.';
  end if;

  -- 4. Validasi minimal belanja dan plafon potongan
  if new.min_belanja < 0 then
    raise exception 'Minimal belanja tidak boleh bernilai negatif.';
  end if;

  if new.jenis = 'nominal' then
    new.maks_potongan := null; -- untuk nominal, plafon maksimal tidak diperlukan
  elsif new.jenis = 'persen' and new.maks_potongan is not null and new.maks_potongan <= 0 then
    raise exception 'Batas maksimal potongan untuk persen harus lebih besar dari 0.';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_validasi_aturan_kampanye on public.kampanye_voucher;
create trigger trg_validasi_aturan_kampanye
  before insert or update on public.kampanye_voucher
  for each row
  execute function public.picu_validasi_aturan_kampanye();

-- 3. Pembangkit Pratinjau Aturan Bahasa Manusia
create or replace function public.format_aturan_kampanye(
  p_jenis text,
  p_nilai numeric,
  p_min_belanja numeric default 0,
  p_maks_potongan numeric default null,
  p_selesai timestamptz default null,
  p_kuota integer default 0,
  p_cabang_berlaku jsonb default '[]'::jsonb
)
returns text
language plpgsql
immutable
set search_path = public, pg_temp
as $$
declare
  v_diskon_teks text;
  v_min_teks    text;
  v_cabang_teks text;
  v_waktu_teks  text;
  v_kuota_teks  text;
  v_jumlah_cbg  integer;
begin
  if p_jenis = 'persen' then
    if p_maks_potongan is not null and p_maks_potongan > 0 then
      v_diskon_teks := format('Diskon %s%% (maksimal %s)', p_nilai, public.format_rupiah(p_maks_potongan));
    else
      v_diskon_teks := format('Diskon %s%%', p_nilai);
    end if;
  else
    v_diskon_teks := format('Potongan langsung %s', public.format_rupiah(p_nilai));
  end if;

  if coalesce(p_min_belanja, 0) > 0 then
    v_min_teks := format('dengan belanja minimal %s', public.format_rupiah(p_min_belanja));
  else
    v_min_teks := 'tanpa syarat minimum belanja';
  end if;

  v_jumlah_cbg := case when p_cabang_berlaku is not null and jsonb_typeof(p_cabang_berlaku) = 'array'
                       then jsonb_array_length(p_cabang_berlaku)
                       else 0 end;
  if v_jumlah_cbg = 0 then
    v_cabang_teks := 'di semua cabang';
  else
    v_cabang_teks := format('di %s cabang terpilih', v_jumlah_cbg);
  end if;

  if p_selesai is not null then
    v_waktu_teks := format('berlaku hingga %s', to_char(p_selesai, 'DD-Mon-YYYY'));
  else
    v_waktu_teks := 'tanpa batas waktu';
  end if;

  v_kuota_teks := format('Kuota: %s voucher', coalesce(p_kuota, 0));

  return format('%s %s, %s, %s. %s.', v_diskon_teks, v_min_teks, v_cabang_teks, v_waktu_teks, v_kuota_teks);
end;
$$;

comment on function public.format_aturan_kampanye(text, numeric, numeric, numeric, timestamptz, integer, jsonb) is
  'Menyusun kalimat pratinjau aturan kampanye dalam bahasa Indonesia yang ramah awam.';

-- 4. RPC Simpan Kampanye Voucher (Admin / Pemilik)
create or replace function public.simpan_kampanye_voucher(
  p_id uuid default null,
  p_nama text default '',
  p_kode_kampanye text default '',
  p_jenis text default 'persen',
  p_nilai numeric default 10,
  p_min_belanja numeric default 0,
  p_maks_potongan numeric default null,
  p_mulai timestamptz default now(),
  p_selesai timestamptz default null,
  p_kuota integer default 100,
  p_anggaran_maks numeric default 10000000,
  p_cabang_berlaku jsonb default '[]'::jsonb,
  p_aktif boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa_id  uuid;
  v_nama        text;
  v_kode        text;
  v_id          uuid;
  v_kmp         record;
begin
  -- 1. Otorisasi
  if auth.uid() is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TIDAK_TERAUTENTIKASI',
      'pesan', 'Operasi membutuhkan sesi login aktif.'
    );
  end if;

  if not public.boleh('atur_pengaturan') and coalesce(public.peran_saya(), '') not in ('owner_pusat', 'admin_cabang') then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TIDAK_PUNYA_IZIN',
      'pesan', 'Hanya admin atau pemilik resto yang dapat mengatur kampanye voucher.'
    );
  end if;

  v_penyewa_id := public.penyewa_saya();
  if v_penyewa_id is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PENYEWA_TIDAK_DITEMUKAN',
      'pesan', 'Identitas penyewa resto tidak ditemukan.'
    );
  end if;

  -- 2. Sanitasi & Validasi Awal
  v_nama := trim(p_nama);
  v_kode := upper(trim(p_kode_kampanye));

  if v_nama is null or length(v_nama) = 0 then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'NAMA_KOSONG',
      'pesan', 'Nama kampanye voucher tidak boleh kosong.'
    );
  end if;

  if v_kode is null or length(v_kode) < 3 then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KODE_TIDAK_SAH',
      'pesan', 'Kode kampanye minimal 3 karakter huruf/angka.'
    );
  end if;

  if p_jenis not in ('persen', 'nominal') then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'JENIS_TIDAK_SAH',
      'pesan', 'Jenis promo harus bernilai persen atau nominal.'
    );
  end if;

  if p_jenis = 'persen' and (p_nilai <= 0 or p_nilai > 100) then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'NILAI_PERSEN_TIDAK_SAH',
      'pesan', 'Diskon persen harus antara 1% sampai 100%.'
    );
  end if;

  if p_jenis = 'nominal' and p_nilai <= 0 then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'NILAI_NOMINAL_TIDAK_SAH',
      'pesan', 'Nilai potongan nominal harus lebih besar dari Rp0.'
    );
  end if;

  if p_selesai is null or p_selesai <= coalesce(p_mulai, now()) then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PERIODE_TIDAK_SAH',
      'pesan', 'Tanggal selesai promo harus sesudah tanggal mulai.'
    );
  end if;

  if p_kuota <= 0 then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KUOTA_TIDAK_SAH',
      'pesan', 'Kuota voucher harus lebih besar dari 0.'
    );
  end if;

  if p_anggaran_maks <= 0 then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'ANGGARAN_TIDAK_SAH',
      'pesan', 'Anggaran maksimal kampanye harus lebih besar dari Rp0.'
    );
  end if;

  if p_jenis = 'nominal' and p_anggaran_maks < p_nilai then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'ANGGARAN_KURANG',
      'pesan', 'Anggaran kampanye tidak boleh lebih kecil dari nilai voucher tunggal.'
    );
  end if;

  -- 3. Eksekusi INSERT atau UPDATE
  if p_id is not null then
    -- Periksa kepemilikan kampanye
    select * into v_kmp
      from public.kampanye_voucher
     where id = p_id
       and penyewa_id = v_penyewa_id;

    if v_kmp.id is null then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'KAMPANYE_TIDAK_DITEMUKAN',
        'pesan', 'Kampanye yang akan diubah tidak ditemukan.'
      );
    end if;

    update public.kampanye_voucher
       set nama            = v_nama,
           kode_kampanye   = v_kode,
           jenis           = p_jenis,
           nilai           = p_nilai,
           min_belanja     = coalesce(p_min_belanja, 0),
           maks_potongan   = case when p_jenis = 'persen' then p_maks_potongan else null end,
           mulai           = coalesce(p_mulai, now()),
           selesai         = p_selesai,
           kuota           = p_kuota,
           anggaran_maks   = p_anggaran_maks,
           cabang_berlaku  = coalesce(p_cabang_berlaku, '[]'::jsonb),
           aktif           = p_aktif
     where id = p_id
       and penyewa_id = v_penyewa_id
    returning id into v_id;

    return jsonb_build_object(
      'berhasil', true,
      'kode', 'SUKSES',
      'pesan', 'Kampanye voucher berhasil diperbarui.',
      'data', jsonb_build_object(
        'id', v_id,
        'nama', v_nama,
        'kode_kampanye', v_kode,
        'pratinjau', public.format_aturan_kampanye(
          p_jenis, p_nilai, p_min_belanja, p_maks_potongan, p_selesai, p_kuota, p_cabang_berlaku
        )
      )
    );
  else
    -- Cek keunikan kode kampanye di resto penyewa
    if exists (
      select 1 from public.kampanye_voucher
       where penyewa_id = v_penyewa_id
         and kode_kampanye = v_kode
    ) then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'KODE_KAMPANYE_SUDAH_ADA',
        'pesan', 'Kode kampanye sudah pernah digunakan. Pilih kode unik lain.'
      );
    end if;

    insert into public.kampanye_voucher (
      penyewa_id, nama, kode_kampanye, jenis, nilai,
      min_belanja, maks_potongan, mulai, selesai,
      kuota, anggaran_maks, cabang_berlaku, aktif
    ) values (
      v_penyewa_id, v_nama, v_kode, p_jenis, p_nilai,
      coalesce(p_min_belanja, 0),
      case when p_jenis = 'persen' then p_maks_potongan else null end,
      coalesce(p_mulai, now()), p_selesai,
      p_kuota, p_anggaran_maks,
      coalesce(p_cabang_berlaku, '[]'::jsonb), p_aktif
    )
    returning id into v_id;

    return jsonb_build_object(
      'berhasil', true,
      'kode', 'SUKSES',
      'pesan', 'Kampanye voucher baru berhasil dibuat.',
      'data', jsonb_build_object(
        'id', v_id,
        'nama', v_nama,
        'kode_kampanye', v_kode,
        'pratinjau', public.format_aturan_kampanye(
          p_jenis, p_nilai, p_min_belanja, p_maks_potongan, p_selesai, p_kuota, p_cabang_berlaku
        )
      )
    );
  end if;
end;
$$;

-- 5. RPC Ambil Daftar Kampanye (Statistik Lengkap)
create or replace function public.ambil_daftar_kampanye(
  p_status text default 'semua'
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa_id uuid;
  v_hasil      jsonb;
begin
  if auth.uid() is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TIDAK_TERAUTENTIKASI',
      'pesan', 'Operasi membutuhkan sesi login aktif.'
    );
  end if;

  v_penyewa_id := public.penyewa_saya();
  if v_penyewa_id is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PENYEWA_TIDAK_DITEMUKAN',
      'pesan', 'Identitas penyewa resto tidak ditemukan.'
    );
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', kv.id,
        'nama', kv.nama,
        'kode_kampanye', kv.kode_kampanye,
        'jenis', kv.jenis,
        'nilai', kv.nilai,
        'min_belanja', kv.min_belanja,
        'maks_potongan', kv.maks_potongan,
        'mulai', kv.mulai,
        'selesai', kv.selesai,
        'kuota', kv.kuota,
        'anggaran_maks', kv.anggaran_maks,
        'cabang_berlaku', kv.cabang_berlaku,
        'aktif', kv.aktif,
        'dibuat_pada', kv.dibuat_pada,
        'jumlah_terbit', coalesce(stat.jumlah_terbit, 0),
        'jumlah_terpakai', coalesce(stat.jumlah_terpakai, 0),
        'sisa_kuota', greatest(0, kv.kuota - coalesce(stat.jumlah_terbit, 0)),
        'status_waktu', case
          when now() < kv.mulai then 'akan_datang'
          when now() > kv.selesai then 'berakhir'
          else 'berjalan'
        end,
        'pratinjau_aturan', public.format_aturan_kampanye(
          kv.jenis, kv.nilai, kv.min_belanja, kv.maks_potongan,
          kv.selesai, kv.kuota, kv.cabang_berlaku
        )
      )
      order by kv.dibuat_pada desc
    ),
    '[]'::jsonb
  ) into v_hasil
  from public.kampanye_voucher kv
  left join lateral (
    select
      count(1) filter (where v.id is not null) as jumlah_terbit,
      count(1) filter (where v.status = 'terpakai') as jumlah_terpakai
    from public.voucher v
    where v.kampanye_id = kv.id
  ) stat on true
  where kv.penyewa_id = v_penyewa_id
    and (
      p_status = 'semua'
      or (p_status = 'aktif' and kv.aktif = true and now() between kv.mulai and kv.selesai)
      or (p_status = 'nonaktif' and kv.aktif = false)
      or (p_status = 'berakhir' and now() > kv.selesai)
    );

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SUKSES',
    'data', v_hasil
  );
end;
$$;

-- 6. RPC Ubah Status Aktif Kampanye (Toggle Aktif / Nonaktif)
create or replace function public.ubah_status_kampanye(
  p_kampanye_id uuid,
  p_aktif boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa_id uuid;
  v_id         uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TIDAK_TERAUTENTIKASI',
      'pesan', 'Operasi membutuhkan sesi login aktif.'
    );
  end if;

  if not public.boleh('atur_pengaturan') and coalesce(public.peran_saya(), '') not in ('owner_pusat', 'admin_cabang') then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TIDAK_PUNYA_IZIN',
      'pesan', 'Hanya admin atau pemilik resto yang dapat mengubah status kampanye.'
    );
  end if;

  v_penyewa_id := public.penyewa_saya();

  update public.kampanye_voucher
     set aktif = p_aktif
   where id = p_kampanye_id
     and penyewa_id = v_penyewa_id
  returning id into v_id;

  if v_id is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KAMPANYE_TIDAK_DITEMUKAN',
      'pesan', 'Kampanye tidak ditemukan atau bukan milik resto ini.'
    );
  end if;

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SUKSES',
    'pesan', case when p_aktif then 'Kampanye berhasil diaktifkan.' else 'Kampanye berhasil dinonaktifkan.' end,
    'data', jsonb_build_object('id', v_id, 'aktif', p_aktif)
  );
end;
$$;

-- 7. Hak Akses Eksekusi Fungsi
revoke all on function public.format_rupiah(numeric) from public;
revoke all on function public.picu_validasi_aturan_kampanye() from public;
revoke all on function public.format_aturan_kampanye(text, numeric, numeric, numeric, timestamptz, integer, jsonb) from public;
revoke all on function public.simpan_kampanye_voucher(uuid, text, text, text, numeric, numeric, numeric, timestamptz, timestamptz, integer, numeric, jsonb, boolean) from public;
revoke all on function public.ambil_daftar_kampanye(text) from public;
revoke all on function public.ubah_status_kampanye(uuid, boolean) from public;

grant execute on function public.format_rupiah(numeric) to authenticated, anon, service_role;
grant execute on function public.format_aturan_kampanye(text, numeric, numeric, numeric, timestamptz, integer, jsonb) to authenticated, anon, service_role;
grant execute on function public.simpan_kampanye_voucher(uuid, text, text, text, numeric, numeric, numeric, timestamptz, timestamptz, integer, numeric, jsonb, boolean) to authenticated, service_role;
grant execute on function public.ambil_daftar_kampanye(text) to authenticated, service_role;
grant execute on function public.ubah_status_kampanye(uuid, boolean) to authenticated, service_role;
