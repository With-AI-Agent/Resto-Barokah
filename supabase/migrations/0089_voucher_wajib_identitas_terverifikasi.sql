-- ============================================================================
-- MIGRASI 0089 — PMB1-F-031 (K-1): voucher hanya untuk identitas terverifikasi
-- ============================================================================
-- Baseline yang dilanggar: `docs/PRD.md:164-167` (M10) — "Barcode/kode voucher baru
-- terbit SETELAH pelanggan lolos verifikasi Google atau email terverifikasi".
-- Asumsi yang dibantah: PMB1-A-026.
--
-- Cacat (bukti `bukti/F-03-voucher-anon.sql`, dijaga ulang sebagai uji di
-- `supabase/tes/voucher_wajib_identitas_terverifikasi.sql`): fungsi
-- `public.daftar_voucher` tidak pernah membaca `auth.uid()`. Peran `anon` (tanpa sesi)
-- cukup mengirim `p_cara_masuk => 'google'` dan alamat email mana pun, lalu
--   (1) baris `public.pelanggan` baru dibuat dengan `terverifikasi_pada = now()`,
--   (2) satu voucher terbit per alamat (pagar kuota_per_pelanggan tetap bekerja),
--   (3) tidak ada satu pun akun `auth.users` untuk alamat itu.
--
-- Perbaikan: "Lapis 0" baru di awal fungsi (lihat di bawah) — identitas diverifikasi
-- peladen, bukan klaim pemanggil. Migrasi lama tidak diubah; berkas berlaku = 0089.
-- Hak eksekusi peran `anon` juga dicabut (pertahanan lapis kedua; pagar utamanya Lapis 0).
--
-- Catatan: `public.normalisasi_email` dipakai untuk membandingkan alamat sesi dengan
-- alamat yang diklaim, sehingga alias Gmail (titik/tag `+`) dianggap sama seperti pada
-- normalisasi kuota voucher. Klaim atas nama orang lain otomatis ditolak karena
-- dibandingkan dengan alamat sesi, bukan karena membandingkan nama.
--
-- RUJUKAN: `kartu/K-F-03.md` §1 (PMB1-F-031), `kartu/H-F-03.md`, `kartu/H-F-03.2.md`;
-- asumsi PMB1-A-026.

create or replace function public.daftar_voucher(
  p_penyewa_id uuid,
  p_kampanye_id uuid,
  p_nama text,
  p_email text,
  p_telepon text default null,
  p_alamat text default null,
  p_persetujuan_privasi boolean default true,
  p_cara_masuk text default 'email',
  p_perangkat text default null,
  p_ip text default null
)
returns jsonb
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
  v_jumlah_voucher_pelanggan integer := 0;
  v_uid_sesi uuid;
  v_peran_sesi text;
  v_email_sesi text;
  v_kasir_id uuid;
begin
  -- Lapis 0 (BARU — PMB1-F-031): voucher hanya boleh terbit untuk identitas yang
  -- bisa diverifikasi oleh PELADEN.
  --   - cara_masuk 'kasir'   → pemanggil harus staf yang sedang masuk (auth.uid() + peran staf).
  --   - cara_masuk google/email → pemanggil harus punya sesi terverifikasi dan alamat yang
  --     diklaim harus sama dengan alamat pada sesi itu (JWT / auth.users).
  -- Tanpa pagar ini peran anon bisa mengaku "Google" atas alamat mana pun, satu voucher
  -- terbit per alamat, dan `terverifikasi_pada` ditandai padahal tidak ada verifikasi.
  v_uid_sesi := auth.uid();
  v_peran_sesi := public.peran_saya();
  -- Jejak staf pada `voucher_percobaan.kasir_id` hanya diisi bila pemanggil memang staf
  -- (kolom itu mengacu ke `public.pengguna`). Sesi pelanggan menulis null — kalau tidak,
  -- klaim pelanggan yang sah akan gagal karena kunci asing.
  v_kasir_id := case when v_peran_sesi is not null then v_uid_sesi else null end;

  if p_cara_masuk = 'kasir' then
    if v_uid_sesi is null
       or v_peran_sesi is null
       or v_peran_sesi not in ('owner_pusat', 'admin_cabang', 'kasir') then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'PENDAFTARAN_HARUS_OLEH_STAF',
        'pesan', 'Pendaftaran pelanggan lewat kasir hanya bisa dilakukan staf yang sedang masuk.'
      );
    end if;
  else
    if v_uid_sesi is null then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'VERIFIKASI_WAJIB',
        'pesan', 'Verifikasi identitas (Google atau email) wajib selesai sebelum mengambil voucher.'
      );
    end if;

    v_email_sesi := lower(btrim(coalesce(auth.jwt() ->> 'email', '')));
    if v_email_sesi = '' then
      select lower(btrim(u.email)) into v_email_sesi
        from auth.users u
       where u.id = v_uid_sesi;
    end if;

    -- Kedua sisi dinormalisasi (alamat sesi bisa memakai titik/tag `+` yang tidak dipakai
    -- pemanggil, atau sebaliknya) agar "alamat yang sama" tidak salah ditolak.
    if v_email_sesi is null or v_email_sesi = ''
       or public.normalisasi_email(v_email_sesi) is distinct from public.normalisasi_email(p_email) then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'VERIFIKASI_WAJIB',
        'pesan', 'Alamat yang diklaim harus sama dengan alamat yang sudah diverifikasi pada sesi ini.'
      );
    end if;
  end if;
  -- Lapis 8: Batas Percobaan Per Perangkat / IP (Rate Limiting)
  if p_penyewa_id is not null and public.apakah_perangkat_terblokir(p_penyewa_id, p_perangkat, p_ip) then
    insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
    values (p_penyewa_id, 'KLAIM_BARU', 'gagal', 'Terlalu banyak percobaan kode voucher yang gagal.', v_kasir_id, null, p_perangkat, p_ip, 'daftar', now());

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TERLALU_BANYAK_PERCOBAAN',
      'pesan', 'Terlalu banyak percobaan kode voucher yang gagal dari perangkat ini. Mohon tunggu 15 menit.'
    );
  end if;

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

  -- 3. Lapis 9 & 10: Validasi, Anti-Disposable, dan Normalisasi Email Gmail
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
      case when p_cara_masuk = 'kasir' then v_kasir_id else null end
    ) returning id into v_pelanggan_id;
  end if;

  -- Lapis 1: Satu Voucher Per Identitas Per Kampanye (kuota_per_pelanggan)
  select count(1) into v_jumlah_voucher_pelanggan
    from public.voucher
   where kampanye_id = p_kampanye_id
     and pelanggan_id = v_pelanggan_id;

  if v_jumlah_voucher_pelanggan >= coalesce(v_kmp.kuota_per_pelanggan, 1) then
    select kode, status into v_ada
      from public.voucher
     where kampanye_id = p_kampanye_id
       and pelanggan_id = v_pelanggan_id
     limit 1;

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

  -- Lapis 7: Terbitkan Kode Acak Tidak Berurutan (T8-08)
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

  -- Lapis 8: Log Percobaan Sukses
  insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
  values (p_penyewa_id, v_kode_voucher, 'sukses', 'Klaim voucher berhasil diterbitkan.', v_kasir_id, null, p_perangkat, p_ip, 'daftar', now());

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

comment on function public.daftar_voucher(uuid, uuid, text, text, text, text, boolean, text, text, text) is
  'Menerbitkan kode voucher untuk identitas yang sudah diverifikasi peladen (PMB1-F-031 — M10 PRD baris 164). Cara kasir hanya untuk staf yang sedang masuk.';

-- Pertahanan lapis kedua: peran anon tidak diberi hak eksekusi sama sekali.
-- Grant lama ke peran `anon` (0063/0067) harus dicabut sendiri-sendiri: `revoke ... from
-- public` saja TIDAK menghapus grant eksplisit yang sudah diberikan ke `anon`.
revoke all on function public.daftar_voucher(uuid, uuid, text, text, text, text, boolean, text, text, text) from public;
revoke all on function public.daftar_voucher(uuid, uuid, text, text, text, text, boolean, text, text, text) from anon;
grant execute on function public.daftar_voucher(uuid, uuid, text, text, text, text, boolean, text, text, text) to authenticated, service_role;
