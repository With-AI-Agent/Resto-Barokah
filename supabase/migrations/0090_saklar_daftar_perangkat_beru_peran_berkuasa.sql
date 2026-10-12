-- ============================================================================
-- MIGRASI 0090 — PMB1-F-036 (K-1): peran berkuasa tidak boleh mendaftarkan
--                       perangkat asing sendiri (SAKLAR, bawaan MATI)
-- ============================================================================
-- Baseline yang dilanggar: `docs/KEAMANAN.md` §4 (baris 42 & 53-57) dan `docs/PRD.md`
-- M12 — peran berkuasa wajib TOTP/kunci, perangkat hanya sah bila DICATAT dan
-- disetujui; `supabase/tes/perangkat_registrasi.sql` masih menguji pendaftaran mandiri
-- dari UUID baru sebagai perilaku yang DISAHKAN hari ini.
-- Asumsi yang dibantah: PMB1-A-043, PMB1-A-002.
--
-- Cacat (bukti `bukti/F-03-hakim-owner-perangkat.sql` bagian A, dijaga ulang sebagai uji
-- di `supabase/tes/daftar_perangkat_beru_peran_berkuasa.sql`): `verifikasi_pin_perangkat`
-- (0087 langkah 6) mendaftarkan perangkat BARU untuk `owner_pusat`/`pemilik_platform`
-- (dan akun `@resto.test`) tanpa persetujuan siapa pun — UUID perangkat dikirim sendiri
-- oleh pemanggil. Siapa pun yang tahu email + PIN owner (repo ini publik, PIN akun
-- percontohan tertulis di migrasi) bisa membuat perangkatnya sah sendiri.
--
-- KEPUTUSAN LEE (B, 2026-09-30, `docs/teknis/REKAM_PESAN_PEMILIK.md` §31): SIAPKAN
-- kode + uji lokal SAJA. Saklar dipasang MATI secara bawaan; migrasi ini belum
-- dipasang ke produksi (itu keputusan Lee), PIN/akun percontohan tidak diubah, dan
-- perilaku lama persis bisa dipulihkan dengan menyalakan saklarnya.
--
-- Yang TIDAK berubah:
--   * staf biasa pada penyewa tanpa perangkat aktif (v_jumlah_alat = 0) tetap boleh
--     mendaftarkan perangkat pertama seperti sebelumnya — cara masuk kasir tidak berubah;
--   * perangkat yang SUDAH terdaftar tetap masuk tanpa hambatan baru;
--   * hak eksekusi RPC (anon/authenticated/service_role) tetap sama.
--
-- RUJUKAN: `kartu/K-F-03.md` §1 (PMB1-F-036), `kartu/H-F-03.md`, `kartu/H-F-03.2.md`,
-- `bukti/F-03-hakim-owner-perangkat.sql`; asumsi PMB1-A-043.

-- 1. Saklar penyewa (bawaan MATI — tidak perlu operator).
alter table public.pengaturan
  add column if not exists izin_daftar_perangkat_bebas_peran_berkuasa boolean not null default false;

comment on column public.pengaturan.izin_daftar_perangkat_bebas_peran_berkuasa is
  'Saklar keputusan Lee B (2026-09-30, PMB1-F-036): bila true, owner_pusat/pemilik_platform/akun @resto.test boleh mendaftarkan perangkat baru dirinya sendiri lewat verifikasi_pin_perangkat. Bawaan false = perangkat baru peran berkuasa harus didaftarkan/disetujui dari perangkat lain yang sudah sah.';

-- 2. Fungsi berlaku ditulis ulang dengan pagar saklar (migrasi lama tidak diubah).

create or replace function public.verifikasi_pin_perangkat(
  p_email           text,
  p_pin             text,
  p_perangkat_id    uuid default null,
  p_perangkat_nama  text default null,
  p_kunci_perangkat text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pengguna       record;
  v_perangkat      record;
  v_kunci_hash     text;
  v_hash           text;
  v_gagal_akun     int;
  v_gagal_alat     int;
  v_cabang_ids     uuid[];
  v_cabang_utama   uuid;
  v_berhasil       boolean;
  v_jumlah_alat    int;
  v_nama_alat      text;
  v_izin_daftar_bebas boolean;
begin
  if p_email is null or trim(p_email) = '' or p_pin is null or trim(p_pin) = '' then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'INPUT_TIDAK_LENGKAP',
      'pesan', 'Email dan PIN wajib diisi.'
    );
  end if;

  -- 1. Validasi format PIN (wajib 6 angka)
  if p_pin !~ '^\d{6}$' then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'FORMAT_PIN_SALAH',
      'pesan', 'PIN harus berupa 6 digit angka.'
    );
  end if;

  -- 2. Validasi perangkat wajib diisi
  if p_perangkat_id is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PERANGKAT_WAJIB',
      'pesan', 'Perangkat kasir/staf wajib terdaftar untuk mengakses sistem.'
    );
  end if;

  -- Periksa keberadaan perangkat
  select id, nama, aktif, penyewa_id, peran_diizinkan
    into v_perangkat
    from public.perangkat
   where id = p_perangkat_id;

  -- Jika perangkat sudah pernah didaftarkan namun dinonaktifkan/dicabut -> tolak
  if v_perangkat.id is not null and not coalesce(v_perangkat.aktif, false) then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PERANGKAT_TIDAK_SAH',
      'pesan', 'Perangkat tidak terdaftar atau telah dicabut.'
    );
  end if;

  -- 3. Cari data pengguna berdasarkan email
  select p.id, p.penyewa_id, p.nama, p.peran, p.aktif
    into v_pengguna
    from public.pengguna p
   where lower(trim(p.email)) = lower(trim(p_email));

  if v_pengguna.id is null or not coalesce(v_pengguna.aktif, false) then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KREDENSIAL_TIDAK_VALID',
      'pesan', 'Email, PIN, atau perangkat tidak cocok.'
    );
  end if;

  -- 4. Pembatasan brute-force (5x per akun / 12x per perangkat per 15 menit)
  select count(*) into v_gagal_akun
    from public.percobaan_pin pp
   where pp.pengguna_id = v_pengguna.id
     and not pp.berhasil
     and pp.waktu > now() - interval '15 minutes';

  select count(*) into v_gagal_alat
    from public.percobaan_pin pp
   where pp.perangkat_id = p_perangkat_id
     and not pp.berhasil
     and pp.waktu > now() - interval '15 minutes';

  if v_gagal_akun >= 5 or v_gagal_alat >= 12 then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'AKUN_TERKUNCI',
      'pesan', 'Akun atau perangkat terkunci sementara karena 5 kali percobaan salah. Tunggu 15 menit.'
    );
  end if;

  -- 5. Periksa kecocokan hash PIN
  select pin_hash into v_hash
    from public.kredensial_pin
   where pengguna_id = v_pengguna.id;

  v_berhasil := v_hash is not null and crypt(p_pin, v_hash) = v_hash;

  if not v_berhasil then
    insert into public.percobaan_pin (
      pengguna_id, perangkat, berhasil, aksi, pemanggil_id, perangkat_id, waktu
    ) values (
      v_pengguna.id,
      coalesce(v_perangkat.nama, coalesce(nullif(trim(p_perangkat_nama), ''), 'Perangkat Baru')),
      false,
      'masuk_pin',
      v_pengguna.id,
      p_perangkat_id,
      now()
    );

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KREDENSIAL_TIDAK_VALID',
      'pesan', 'Email, PIN, atau perangkat tidak cocok.'
    );
  end if;

  -- 6. Pendaftaran mandiri perangkat (self-provisioning) jika belum terdaftar
  if v_perangkat.id is null then
    select count(*) into v_jumlah_alat
      from public.perangkat
     where penyewa_id = v_pengguna.penyewa_id
       and aktif = true;

    if v_pengguna.peran in ('owner_pusat', 'pemilik_platform')
       or lower(trim(p_email)) like '%@resto.test'
       or v_jumlah_alat = 0 then

      -- SAKLAR KEPUTUSAN LEE (B, 2026-09-30) — PMB1-F-036.
      -- Pendaftaran mandiri perangkat oleh PERAN BERKUASA (owner_pusat/pemilik_platform
      -- dan akun percontohan @resto.test) hanya boleh jalan bila saklar
      -- `izin_daftar_perangkat_bebas_peran_berkuasa` menyala. BAWAAN: MATI.
      -- Staf biasa (v_jumlah_alat = 0) TIDAK ikut saklar ini, jadi cara masuk kasir
      -- pada penyewa yang belum punya perangkat sama sekali tetap seperti sekarang.
      if v_pengguna.peran in ('owner_pusat', 'pemilik_platform')
         or lower(trim(p_email)) like '%@resto.test' then
        select coalesce(pg.izin_daftar_perangkat_bebas_peran_berkuasa, false)
          into v_izin_daftar_bebas
          from public.pengaturan pg
         where pg.penyewa_id = v_pengguna.penyewa_id;

        if not coalesce(v_izin_daftar_bebas, false) then
          return jsonb_build_object(
            'berhasil', false,
            'kode', 'PERANGKAT_BELUM_DISETUJUI',
            'pesan', 'Perangkat ini belum terdaftar. Daftarkan dari perangkat lain yang sudah sah, atau nyalakan saklar izin_daftar_perangkat_bebas_peran_berkuasa untuk sementara.'
          );
        end if;
      end if;

      -- Ambil cabang utama yang sah (kolom dibuat_pada)
      select id into v_cabang_utama
        from public.cabang
       where penyewa_id = v_pengguna.penyewa_id
       order by dibuat_pada asc limit 1;

      if v_cabang_utama is null then
        select id into v_cabang_utama
          from public.cabang
         where penyewa_id = v_pengguna.penyewa_id
         limit 1;
      end if;

      if v_cabang_utama is null then
        insert into public.cabang (penyewa_id, nama, aktif, dibuat_pada)
        values (v_pengguna.penyewa_id, 'Cabang Utama', true, now())
        returning id into v_cabang_utama;
      end if;

      -- Susun nama perangkat dan cegah tabrakan unik (penyewa_id, nama)
      v_nama_alat := coalesce(nullif(trim(p_perangkat_nama), ''), 'Perangkat ' || initcap(replace(v_pengguna.peran::text, '_', ' ')));
      if exists (
        select 1 from public.perangkat
         where penyewa_id = v_pengguna.penyewa_id
           and nama = v_nama_alat
           and aktif
           and id <> p_perangkat_id
      ) then
        v_nama_alat := v_nama_alat || ' (' || substr(p_perangkat_id::text, 1, 8) || ')';
      end if;

      insert into public.perangkat (
        id,
        penyewa_id,
        cabang_id,
        nama,
        peran_diizinkan,
        aktif,
        didaftarkan_oleh,
        status
      ) values (
        p_perangkat_id,
        v_pengguna.penyewa_id,
        v_cabang_utama,
        v_nama_alat,
        array['owner_pusat', 'pemilik_platform', 'admin_cabang', 'kasir', 'dapur', 'pelayan']::text[],
        true,
        v_pengguna.id,
        'aktif'
      )
      on conflict (id) do update set
        penyewa_id = excluded.penyewa_id,
        cabang_id = coalesce(excluded.cabang_id, public.perangkat.cabang_id),
        nama = excluded.nama,
        peran_diizinkan = excluded.peran_diizinkan,
        aktif = true,
        status = 'aktif',
        terakhir_aktif = now();

      select id, nama, aktif, penyewa_id, peran_diizinkan
        into v_perangkat
        from public.perangkat
       where id = p_perangkat_id;
    else
      -- Restoran telah beroperasi dan staf biasa mencoba masuk dari perangkat tak dikenal
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'PERANGKAT_TIDAK_SAH',
        'pesan', 'Perangkat tidak terdaftar atau telah dicabut.'
      );
    end if;
  end if;

  -- 7. Validasi relasi tenant & peran terhadap perangkat
  if v_perangkat.penyewa_id <> v_pengguna.penyewa_id then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'RESTO_TIDAK_COCOK',
      'pesan', 'Perangkat tidak terdaftar pada restoran ini.'
    );
  end if;

  if not (v_pengguna.peran::text = any(v_perangkat.peran_diizinkan)) then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PERAN_TIDAK_DIIZINKAN',
      'pesan', 'Peran pengguna tidak diizinkan pada perangkat ini.'
    );
  end if;

  -- 8. Verifikasi kunci token rahasia perangkat bila terdaftar
  if p_kunci_perangkat is not null and exists (
    select 1 from public.kredensial_perangkat kp where kp.perangkat_id = p_perangkat_id
  ) then
    select kp.kunci_hash into v_kunci_hash
      from public.kredensial_perangkat kp
     where kp.perangkat_id = p_perangkat_id;

    if v_kunci_hash is not null and crypt(p_kunci_perangkat, v_kunci_hash) <> v_kunci_hash then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'PERANGKAT_TIDAK_SAH',
        'pesan', 'Kunci token rahasia perangkat tidak cocok.'
      );
    end if;
  end if;

  -- 9. Catat percobaan berhasil dan perbarui status perangkat
  insert into public.percobaan_pin (
    pengguna_id, perangkat, berhasil, aksi, pemanggil_id, perangkat_id, waktu
  ) values (
    v_pengguna.id, v_perangkat.nama, true, 'masuk_pin', v_pengguna.id, p_perangkat_id, now()
  );

  update public.perangkat
     set terakhir_aktif = now()
   where id = v_perangkat.id;

  -- 10. Ambil daftar cabang pengguna
  select coalesce(array_agg(cabang_id), array[]::uuid[])
    into v_cabang_ids
    from public.pengguna_cabang
   where pengguna_id = v_pengguna.id
     and aktif;

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'LOGIN_SUKSES',
    'pesan', 'Login dengan PIN berhasil.',
    'data', jsonb_build_object(
      'pengguna_id', v_pengguna.id,
      'nama', v_pengguna.nama,
      'peran', v_pengguna.peran,
      'penyewa_id', v_pengguna.penyewa_id,
      'cabang_ids', v_cabang_ids,
      'perangkat_id', v_perangkat.id
    )
  );
end;
$$;

comment on function public.verifikasi_pin_perangkat(text, text, uuid, text, text) is
  'Verifikasi PIN staf saat login. Peran berkuasa hanya boleh membuat perangkat baru bila saklar izin_daftar_perangkat_bebas_peran_berkuasa menyala (keputusan Lee B 2026-09-30, PMB1-F-036).';

revoke all on function public.verifikasi_pin_perangkat(text, text, uuid, text, text) from public;
grant execute on function public.verifikasi_pin_perangkat(text, text, uuid, text, text) to anon, authenticated, service_role;
