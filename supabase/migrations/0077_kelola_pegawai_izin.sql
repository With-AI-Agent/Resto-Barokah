-- ============================================================================
-- 0077 — Kelola Pegawai: Peran, Izin Berjenjang & Reset PIN (T9-08 / PRD M3 & M6)
--
-- Menuntaskan tata kelola staf resto secara mandiri tanpa koding:
--  1. Pemicu fail-closed:
--     - picu_pengguna_cegah_hapus: cegah hard-delete pegawai yang memiliki riwayat
--       transaksi (pesanan, pembayaran, shift kasir). Wajib soft-disable (aktif = false).
--  2. RPC resmi:
--     - public.set_izin: centang izin per pegawai (10 izin resmi + batas diskon nominal/persen)
--       dengan otorisasi ketat, hierarki perlindungan owner, dan anti-privilege escalation.
--     - public.set_status_pengguna: aktifkan / nonaktifkan pegawai (soft-disable).
--     - public.simpan_pegawai: tambah / edit data pegawai dan cabang penugasan.
--     - public.reset_pin_pegawai: reset PIN 6 angka oleh atasan tanpa butuh PIN lama staf.
--     - public.ambil_daftar_pegawai: daftar seluruh pegawai resto beserta peran & cabang.
--     - public.ambil_izin_pegawai: membaca 10 izin resmi pegawai (efektif vs override).
--  3. Jejak audit kekal di public.catatan_audit untuk setiap aksi.
-- ============================================================================

-- 1. Pemicu Keamanan Fail-Closed: Cegah Hapus Pegawai Ber-riwayat
create or replace function public.picu_pengguna_cegah_hapus()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- Cek riwayat pesanan (sebagai pembuat pesanan / kasir / pelayan)
  if exists (
    select 1 from public.pesanan
     where pelayan_id = old.id or kasir_id = old.id
  ) then
    raise exception 'Pegawai "%" tidak dapat dihapus karena memiliki riwayat transaksi pesanan. Silakan nonaktifkan akun pegawai ini.', old.nama;
  end if;

  -- Cek riwayat pembayaran (sebagai kasir pencatat pembayaran)
  if exists (
    select 1 from public.pembayaran
     where kasir_id = old.id
  ) then
    raise exception 'Pegawai "%" tidak dapat dihapus karena memiliki riwayat pencatatan pembayaran kasir. Silakan nonaktifkan akun pegawai ini.', old.nama;
  end if;

  -- Cek riwayat shift kas
  if exists (
    select 1 from public.shift_kas
     where dibuka_oleh = old.id or ditutup_oleh = old.id
  ) then
    raise exception 'Pegawai "%" tidak dapat dihapus karena memiliki riwayat shift kas. Silakan nonaktifkan akun pegawai ini.', old.nama;
  end if;

  return old;
end;
$$;

drop trigger if exists picu_pengguna_cegah_hapus on public.pengguna;
create trigger picu_pengguna_cegah_hapus
  before delete on public.pengguna
  for each row execute function public.picu_pengguna_cegah_hapus();

comment on function public.picu_pengguna_cegah_hapus() is
  'Pemicu fail-closed: melindungi integritas jejak audit finansial (ART-2). Pegawai yang sudah pernah bertransaksi dilarang di-hard delete.';

-- 2. RPC: set_izin (Centang izin per pegawai & batas diskon)
create or replace function public.set_izin(
  p_pengguna_id   uuid,
  p_kode_izin     text,
  p_boleh         boolean,
  p_batas_nominal integer default null,
  p_batas_persen  numeric default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa      uuid;
  v_peran_saya   text;
  v_target       record;
  v_nilai_lama   jsonb := null;
  v_nilai_baru   jsonb;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  v_peran_saya := coalesce(public.peran_saya(), '');
  if v_peran_saya <> 'owner_pusat' and not public.boleh('kelola_pegawai') then
    raise exception 'Hanya owner pusat atau pemegang izin kelola_pegawai yang dapat mengubah izin pegawai.';
  end if;

  -- Cek keberadaan pegawai target se-penyewa
  select id, penyewa_id, peran, nama into v_target
    from public.pengguna
   where id = p_pengguna_id
     and penyewa_id = v_penyewa;

  if v_target.id is null then
    raise exception 'Pegawai tidak ditemukan atau bukan bagian dari restoran Anda.';
  end if;

  -- Pagar hierarki: staf berizin dilarang mengubah izin owner_pusat
  if v_target.peran = 'owner_pusat' and v_peran_saya <> 'owner_pusat' then
    raise exception 'Hanya sesama owner pusat yang dapat mengubah izin owner pusat.';
  end if;

  -- Pagar eskalasi hak istimewa (privilege escalation)
  if p_kode_izin = 'kelola_pegawai' and p_boleh = true and v_peran_saya <> 'owner_pusat' then
    raise exception 'Hanya owner pusat yang berhak memberikan izin kelola pegawai.';
  end if;

  -- Validasi kode izin resmi
  if not exists (select 1 from public.izin_kode where kode_izin = p_kode_izin) then
    raise exception 'Kode izin "%" tidak dikenal dalam sistem.', p_kode_izin;
  end if;

  -- Validasi batas angka
  if p_batas_nominal is not null and p_batas_nominal < 0 then
    raise exception 'Batas nominal diskon tidak boleh negatif.';
  end if;

  if p_batas_persen is not null and (p_batas_persen < 0 or p_batas_persen > 100) then
    raise exception 'Batas persen diskon harus di antara 0 dan 100.';
  end if;

  -- Ambil nilai lama jika ada
  select jsonb_build_object(
    'boleh', boleh,
    'batas_nominal', batas_nominal,
    'batas_persen', batas_persen
  ) into v_nilai_lama
    from public.izin
   where pengguna_id = p_pengguna_id
     and kode_izin = p_kode_izin;

  -- Simpan / perbarui override izin pegawai
  insert into public.izin (
    pengguna_id,
    kode_izin,
    boleh,
    batas_nominal,
    batas_persen,
    diubah_oleh,
    diubah_pada
  ) values (
    p_pengguna_id,
    p_kode_izin,
    p_boleh,
    p_batas_nominal,
    p_batas_persen,
    auth.uid(),
    now()
  )
  on conflict (pengguna_id, kode_izin) do update set
    boleh         = excluded.boleh,
    batas_nominal = excluded.batas_nominal,
    batas_persen  = excluded.batas_persen,
    diubah_oleh   = auth.uid(),
    diubah_pada   = now();

  v_nilai_baru := jsonb_build_object(
    'kode_izin', p_kode_izin,
    'boleh', p_boleh,
    'batas_nominal', p_batas_nominal,
    'batas_persen', p_batas_persen
  );

  -- Jejak audit kekal
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_lama,
    nilai_baru
  ) values (
    v_penyewa,
    auth.uid(),
    'set_izin',
    'izin',
    p_pengguna_id,
    v_nilai_lama,
    v_nilai_baru
  );

  return jsonb_build_object(
    'berhasil', true,
    'pesan', 'Izin berhasil disimpan.'
  );
end;
$$;

comment on function public.set_izin(uuid, text, boolean, integer, numeric) is
  'Mengatur centang izin spesifik per pegawai (10 izin resmi + batas diskon nominal/persen) dengan jejak audit kekal.';

-- 3. RPC: set_status_pengguna (Aktifkan / nonaktifkan pegawai)
create or replace function public.set_status_pengguna(
  p_pengguna_id uuid,
  p_aktif       boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa    uuid;
  v_peran_saya text;
  v_target     record;
  v_nilai_lama jsonb;
  v_nilai_baru jsonb;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  v_peran_saya := coalesce(public.peran_saya(), '');
  if v_peran_saya <> 'owner_pusat' and not public.boleh('kelola_pegawai') then
    raise exception 'Hanya owner pusat atau pemegang izin kelola_pegawai yang dapat mengubah status pegawai.';
  end if;

  select id, nama, peran, aktif into v_target
    from public.pengguna
   where id = p_pengguna_id
     and penyewa_id = v_penyewa
     for update;

  if v_target.id is null then
    raise exception 'Pegawai tidak ditemukan atau bukan bagian dari restoran Anda.';
  end if;

  -- Pagar hierarki: staf dilarang menonaktifkan owner_pusat
  if v_target.peran = 'owner_pusat' and v_peran_saya <> 'owner_pusat' then
    raise exception 'Hanya sesama owner pusat yang dapat mengubah status keaktifan owner pusat.';
  end if;

  -- Pagar: tidak boleh menonaktifkan satu-satunya owner pusat aktif
  if v_target.peran = 'owner_pusat' and p_aktif = false then
    if (
      select count(*)
        from public.pengguna
       where penyewa_id = v_penyewa
         and peran = 'owner_pusat'
         and aktif = true
         and id <> p_pengguna_id
    ) = 0 then
      raise exception 'Restoran minimal harus memiliki satu owner pusat yang aktif.';
    end if;
  end if;

  v_nilai_lama := jsonb_build_object('aktif', v_target.aktif);
  v_nilai_baru := jsonb_build_object('aktif', p_aktif);

  update public.pengguna
     set aktif = p_aktif
   where id = p_pengguna_id;

  update public.pengguna_cabang
     set aktif = p_aktif
   where pengguna_id = p_pengguna_id;

  -- Jejak audit kekal
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_lama,
    nilai_baru
  ) values (
    v_penyewa,
    auth.uid(),
    'set_status_pengguna',
    'pengguna',
    p_pengguna_id,
    v_nilai_lama,
    v_nilai_baru
  );

  return jsonb_build_object(
    'berhasil', true,
    'pesan', format('Pegawai "%s" berhasil %s.', v_target.nama, case when p_aktif then 'diaktifkan' else 'dinonaktifkan' end)
  );
end;
$$;

comment on function public.set_status_pengguna(uuid, boolean) is
  'Mengaktifkan atau menonaktifkan pegawai tanpa menghapus data masa lalu demi integritas jejak audit (ART-2).';

-- 4. RPC: reset_pin_pegawai (Atur ulang PIN oleh atasan tanpa butuh PIN lama)
create or replace function public.reset_pin_pegawai(
  p_pengguna_id uuid,
  p_pin_baru    text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa    uuid;
  v_peran_saya text;
  v_target     record;
  v_lemah      text;
  v_hash       text;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  v_peran_saya := coalesce(public.peran_saya(), '');
  if v_peran_saya <> 'owner_pusat' and not public.boleh('kelola_pegawai') then
    raise exception 'Hanya owner pusat atau pemegang izin kelola_pegawai yang dapat mereset PIN pegawai.';
  end if;

  select id, nama, peran into v_target
    from public.pengguna
   where id = p_pengguna_id
     and penyewa_id = v_penyewa;

  if v_target.id is null then
    raise exception 'Pegawai tidak ditemukan atau bukan bagian dari restoran Anda.';
  end if;

  -- Pagar hierarki: staf dilarang mereset PIN owner_pusat
  if v_target.peran = 'owner_pusat' and v_peran_saya <> 'owner_pusat' then
    raise exception 'Hanya sesama owner pusat yang dapat mereset PIN owner pusat.';
  end if;

  -- Validasi PIN 6 digit
  if p_pin_baru is null or p_pin_baru !~ '^[0-9]{6}$' then
    raise exception 'PIN baru harus berupa 6 digit angka.';
  end if;

  v_lemah := public.pin_lemah(p_pin_baru);
  if v_lemah is not null then
    raise exception 'PIN ditolak: %.', v_lemah;
  end if;

  -- Enkripsi hash bcrypt
  v_hash := crypt(p_pin_baru, gen_salt('bf', 10));

  insert into public.kredensial_pin (pengguna_id, pin_hash, diubah_pada)
  values (p_pengguna_id, v_hash, now())
  on conflict (pengguna_id) do update set
    pin_hash = excluded.pin_hash,
    diubah_pada = now();

  update public.pengguna
     set pin_diubah_pada = now()
   where id = p_pengguna_id;

  -- Jejak audit kekal
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_lama,
    nilai_baru
  ) values (
    v_penyewa,
    auth.uid(),
    'reset_pin_pegawai',
    'kredensial_pin',
    p_pengguna_id,
    null,
    jsonb_build_object('target_nama', v_target.nama, 'target_peran', v_target.peran)
  );

  return jsonb_build_object(
    'berhasil', true,
    'pesan', format('PIN untuk pegawai "%s" berhasil diatur ulang.', v_target.nama)
  );
end;
$$;

comment on function public.reset_pin_pegawai(uuid, text) is
  'Mereset PIN 6 digit pegawai oleh atasan berwenang lengkap dengan validasi kekuatan PIN dan jejak audit.';

-- 5. RPC: simpan_pegawai (Tambah / Edit Pegawai Lengkap)
create or replace function public.simpan_pegawai(
  p_id        uuid,
  p_nama      text,
  p_email     text,
  p_peran     text,
  p_cabang_id uuid,
  p_pin       text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa    uuid;
  v_peran_saya text;
  v_id         uuid;
  v_nama       text;
  v_email      text;
  v_target     record;
  v_nilai_lama jsonb := null;
  v_nilai_baru jsonb;
  v_hash       text;
  v_lemah      text;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  v_peran_saya := coalesce(public.peran_saya(), '');
  if v_peran_saya <> 'owner_pusat' and not public.boleh('kelola_pegawai') then
    raise exception 'Hanya owner pusat atau pemegang izin kelola_pegawai yang dapat mengelola data pegawai.';
  end if;

  v_nama := btrim(coalesce(p_nama, ''));
  if length(v_nama) < 1 or length(v_nama) > 120 then
    raise exception 'Nama pegawai harus di antara 1 dan 120 karakter.';
  end if;

  v_email := lower(btrim(coalesce(p_email, '')));
  if v_email !~ '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$' then
    raise exception 'Format alamat email tidak valid.';
  end if;

  if p_peran not in ('admin_cabang', 'kasir', 'pelayan', 'dapur') then
    raise exception 'Peran pegawai tidak valid (pilih: "admin_cabang", "kasir", "pelayan", atau "dapur").';
  end if;

  -- Pastikan cabang target adalah milik penyewa yang sama
  if not exists (select 1 from public.cabang where id = p_cabang_id and penyewa_id = v_penyewa) then
    raise exception 'Cabang tidak ditemukan atau bukan milik resto Anda.';
  end if;

  if p_id is not null then
    -- MODE EDIT
    select id, nama, email, peran into v_target
      from public.pengguna
     where id = p_id
       and penyewa_id = v_penyewa
       for update;

    if v_target.id is null then
      raise exception 'Pegawai tidak ditemukan atau bukan milik resto Anda.';
    end if;

    if v_target.peran = 'owner_pusat' and v_peran_saya <> 'owner_pusat' then
      raise exception 'Hanya sesama owner pusat yang dapat mengubah data profil owner pusat.';
    end if;

    -- Periksa keunikan email jika berubah
    if v_target.email <> v_email then
      if exists (
        select 1 from public.pengguna
         where penyewa_id = v_penyewa
           and lower(email) = v_email
           and id <> p_id
      ) then
        raise exception 'Alamat email "%" sudah digunakan oleh pegawai lain.', v_email;
      end if;
    end if;

    v_nilai_lama := jsonb_build_object(
      'nama', v_target.nama,
      'email', v_target.email,
      'peran', v_target.peran
    );

    update public.pengguna
       set nama  = v_nama,
           email = v_email,
           peran = p_peran
     where id = p_id;

    -- Perbarui penugasan cabang utama
    insert into public.pengguna_cabang (pengguna_id, cabang_id, aktif)
    values (p_id, p_cabang_id, true)
    on conflict (pengguna_id, cabang_id) do update set
      aktif = true;

    v_id := p_id;
    v_nilai_baru := jsonb_build_object(
      'nama', v_nama,
      'email', v_email,
      'peran', p_peran,
      'cabang_id', p_cabang_id
    );

    -- Jejak audit edit
    insert into public.catatan_audit (
      penyewa_id,
      pelaku_id,
      aksi,
      entitas,
      entitas_id,
      nilai_lama,
      nilai_baru
    ) values (
      v_penyewa,
      auth.uid(),
      'ubah_pegawai',
      'pengguna',
      v_id,
      v_nilai_lama,
      v_nilai_baru
    );

  else
    -- MODE TAMBAH BARU
    -- Periksa keunikan email
    if exists (
      select 1 from public.pengguna
       where penyewa_id = v_penyewa
         and lower(email) = v_email
    ) then
      raise exception 'Alamat email "%" sudah digunakan oleh pegawai lain.', v_email;
    end if;

    -- Validasi PIN wajib untuk akun pegawai baru
    if p_pin is null or p_pin !~ '^[0-9]{6}$' then
      raise exception 'Akun pegawai baru wajib diberikan PIN awal 6 digit angka.';
    end if;

    v_lemah := public.pin_lemah(p_pin);
    if v_lemah is not null then
      raise exception 'PIN ditolak: %.', v_lemah;
    end if;

    v_id := gen_random_uuid();

    -- Buat akun di auth.users (mock/supa)
    if not exists (select 1 from auth.users where id = v_id) then
      insert into auth.users (id, email) values (v_id, v_email);
    end if;

    -- Buat baris pengguna
    insert into public.pengguna (
      id,
      penyewa_id,
      nama,
      email,
      peran,
      aktif,
      pin_diubah_pada
    ) values (
      v_id,
      v_penyewa,
      v_nama,
      v_email,
      p_peran,
      true,
      now()
    );

    -- Pasang hash PIN bcrypt
    v_hash := crypt(p_pin, gen_salt('bf', 10));
    insert into public.kredensial_pin (pengguna_id, pin_hash, diubah_pada)
    values (v_id, v_hash, now());

    -- Pasang penugasan cabang
    insert into public.pengguna_cabang (pengguna_id, cabang_id, aktif)
    values (v_id, p_cabang_id, true);

    v_nilai_baru := jsonb_build_object(
      'nama', v_nama,
      'email', v_email,
      'peran', p_peran,
      'cabang_id', p_cabang_id
    );

    -- Jejak audit tambah
    insert into public.catatan_audit (
      penyewa_id,
      pelaku_id,
      aksi,
      entitas,
      entitas_id,
      nilai_lama,
      nilai_baru
    ) values (
      v_penyewa,
      auth.uid(),
      'tambah_pegawai',
      'pengguna',
      v_id,
      null,
      v_nilai_baru
    );
  end if;

  return jsonb_build_object(
    'berhasil', true,
    'id', v_id,
    'pesan', format('Pegawai "%s" berhasil disimpan.', v_nama)
  );
end;
$$;

comment on function public.simpan_pegawai(uuid, text, text, text, uuid, text) is
  'Menambah atau mengubah data profil pegawai, cabang penugasan, dan enkripsi PIN awal.';

-- 6. RPC: ambil_daftar_pegawai
create or replace function public.ambil_daftar_pegawai()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa    uuid;
  v_peran_saya text;
  v_hasil      jsonb;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  v_peran_saya := coalesce(public.peran_saya(), '');
  if v_peran_saya <> 'owner_pusat' and not public.boleh('kelola_pegawai') then
    raise exception 'Hanya owner pusat atau pemegang izin kelola_pegawai yang dapat melihat daftar pegawai.';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', p.id,
        'nama', p.nama,
        'email', p.email,
        'peran', p.peran,
        'aktif', p.aktif,
        'cabang_id', c.id,
        'cabang_nama', coalesce(c.nama, '-'),
        'terakhir_masuk', p.terakhir_masuk,
        'dibuat_pada', p.dibuat_pada
      ) order by
          case p.peran
            when 'owner_pusat' then 1
            when 'admin_cabang' then 2
            when 'kasir' then 3
            when 'pelayan' then 4
            when 'dapur' then 5
            else 6
          end,
          p.nama asc
    ),
    '[]'::jsonb
  ) into v_hasil
  from public.pengguna p
  left join public.pengguna_cabang pc on pc.pengguna_id = p.id and pc.aktif
  left join public.cabang c on c.id = pc.cabang_id
  where p.penyewa_id = v_penyewa;

  return v_hasil;
end;
$$;

comment on function public.ambil_daftar_pegawai() is
  'Mengambil daftar seluruh pegawai resto pemanggil terurut berdasarkan peran dan nama.';

-- 7. RPC: ambil_izin_pegawai
create or replace function public.ambil_izin_pegawai(p_pengguna_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa    uuid;
  v_peran_saya text;
  v_target     record;
  v_hasil      jsonb;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  v_peran_saya := coalesce(public.peran_saya(), '');
  if v_peran_saya <> 'owner_pusat' and not public.boleh('kelola_pegawai') and auth.uid() <> p_pengguna_id then
    raise exception 'Hanya owner pusat, pemegang izin kelola_pegawai, atau staf bersangkutan yang dapat melihat rincian izin.';
  end if;

  select id, nama, peran into v_target
    from public.pengguna
   where id = p_pengguna_id
     and penyewa_id = v_penyewa;

  if v_target.id is null then
    raise exception 'Pegawai tidak ditemukan atau bukan milik resto Anda.';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'kode_izin', k.kode_izin,
        'keterangan', k.keterangan,
        'kelompok', k.kelompok,
        'boleh', coalesce(i.boleh, ip.boleh, false),
        'batas_nominal', coalesce(i.batas_nominal, ip.batas_nominal),
        'batas_persen', coalesce(i.batas_persen, ip.batas_persen),
        'khusus', (i.pengguna_id is not null)
      ) order by
          case k.kelompok
            when 'harga' then 1
            when 'diskon' then 2
            when 'void' then 3
            when 'laporan' then 4
            when 'kas' then 5
            when 'stok' then 6
            when 'voucher' then 7
            when 'pegawai' then 8
            when 'pengaturan' then 9
            else 10
          end,
          k.kode_izin asc
    ),
    '[]'::jsonb
  ) into v_hasil
  from public.izin_kode k
  left join public.izin_peran ip
    on ip.penyewa_id = v_penyewa
   and ip.peran = v_target.peran
   and ip.kode_izin = k.kode_izin
  left join public.izin i
    on i.pengguna_id = p_pengguna_id
   and i.kode_izin = k.kode_izin;

  return v_hasil;
end;
$$;

comment on function public.ambil_izin_pegawai(uuid) is
  'Membaca konfigurasi 10 izin resmi untuk pegawai target (nilai bawaan peran vs override centang khusus).';

-- 8. Hak Eksekusi Fungsi RPC & Pemicu
revoke all on function public.set_izin(uuid, text, boolean, integer, numeric) from public;
grant execute on function public.set_izin(uuid, text, boolean, integer, numeric) to authenticated;

revoke all on function public.set_status_pengguna(uuid, boolean) from public;
grant execute on function public.set_status_pengguna(uuid, boolean) to authenticated;

revoke all on function public.reset_pin_pegawai(uuid, text) from public;
grant execute on function public.reset_pin_pegawai(uuid, text) to authenticated;

revoke all on function public.simpan_pegawai(uuid, text, text, text, uuid, text) from public;
grant execute on function public.simpan_pegawai(uuid, text, text, text, uuid, text) to authenticated;

revoke all on function public.ambil_daftar_pegawai() from public;
grant execute on function public.ambil_daftar_pegawai() to authenticated;

revoke all on function public.ambil_izin_pegawai(uuid) from public;
grant execute on function public.ambil_izin_pegawai(uuid) to authenticated;

revoke all on function public.picu_pengguna_cegah_hapus() from public;
grant execute on function public.picu_pengguna_cegah_hapus() to service_role;
