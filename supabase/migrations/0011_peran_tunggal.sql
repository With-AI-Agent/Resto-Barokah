-- ============================================================================
-- 0011 — PERAN TUNGGAL + PIN 6 ANGKA YANG UNIK & KUAT (T1-23 · ART-12)
--
-- Latar: keputusan keamanan 2026-09-17 (docs/KEAMANAN.md §3, ART-12) adalah
-- **satu akun = satu peran** (orang dua fungsi = dua akun) dan PIN 6 angka yang
-- unik antar pegawai serta bukan pola lemah. Dua hal lama jadi bertentangan:
--   * `pengguna_cabang.peran` (peran berbeda per cabang) → DIBONGKAR di sini;
--   * batas PIN 4–6 angka → dinaikkan ke tepat 6 angka.
-- Hasil AUD-0: `docs/uji/DAFTAR_PEKERJAAN_ULANG.md` butir B.1–B.3 (+B.9 fixture).
-- Migrasi 0002 & 0005 sengaja TIDAK disunting; perubahannya lewat berkas ini.
-- ============================================================================

-- =========================================== 1. PERAN PER CABANG DIBONGKAR ===
alter table public.pengguna_cabang drop column if exists peran;

comment on table public.pengguna_cabang is
  'Daftar cabang tempat akun bertugas. PERAN tidak lagi per cabang: satu akun satu peran (pengguna.peran) berlaku di semua cabangnya (ART-12).';

-- Penjaga keanggotaan: akun & cabang wajib satu resto, dan pemilik platform tidak
-- bertugas di cabang. Ini menjaga "peran kedua" tidak terselundup lewat keanggotaan
-- cabang milik resto lain. (Penjaga ini murni integritas data — bukan pemeriksaan
-- peran — jadi definer aman & memang dikehendaki agar bacaannya tidak terpotong RLS.)
create or replace function public.picu_jaga_keanggotaan_cabang()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa_pengguna uuid;
  v_peran_pengguna   text;
  v_penyewa_cabang   uuid;
begin
  select p.penyewa_id, p.peran into v_penyewa_pengguna, v_peran_pengguna
    from public.pengguna p where p.id = new.pengguna_id;
  select c.penyewa_id into v_penyewa_cabang
    from public.cabang c where c.id = new.cabang_id;

  if v_penyewa_pengguna is null or v_penyewa_cabang is null then
    raise exception 'Keanggotaan cabang ditolak: akun atau cabang tidak ada.';
  end if;
  if v_penyewa_pengguna <> v_penyewa_cabang then
    raise exception 'Keanggotaan cabang ditolak: akun dan cabang harus satu resto.';
  end if;
  if v_peran_pengguna = 'pemilik_platform' then
    raise exception 'Pemilik platform tidak bertugas di cabang mana pun.';
  end if;
  return new;
end
$$;

drop trigger if exists pengguna_cabang_jaga_keanggotaan on public.pengguna_cabang;
create trigger pengguna_cabang_jaga_keanggotaan
  before insert or update on public.pengguna_cabang
  for each row execute function public.picu_jaga_keanggotaan_cabang();

-- ============================ 2. MESIN IZIN MEMBACA PERAN AKUN (peran tunggal) ===
-- Sama seperti 0005, hanya sumber perannya berubah:
--   * peran = `pengguna.peran` (peran tunggal, berlaku di semua cabang);
--   * bila cabang disebut, pemanggil tetap harus ANGGOTA cabang itu
--     (kecuali owner pusat yang memang tidak bertugas di cabang).
create or replace function public.izin_efektif(p_aksi text, p_cabang_id uuid default null)
returns table (boleh boolean, batas_nominal integer, batas_persen numeric)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_peran   text;
begin
  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    return query select false, null::integer, null::numeric;   -- pemilik platform / belum masuk / akun nonaktif
    return;
  end if;

  v_peran := public.peran_saya();

  if p_cabang_id is not null and v_peran <> 'owner_pusat' then
    if not exists (
      select 1 from public.pengguna_cabang pc
       where pc.pengguna_id = auth.uid()
         and pc.cabang_id = p_cabang_id
         and pc.aktif
    ) then
      -- Cabang yang bukan tempatnya bertugas = TOLAK (bukan jatuh ke peran se-resto).
      return query select false, null::integer, null::numeric;
      return;
    end if;
  end if;

  if v_peran is null or v_peran = 'pemilik_platform' then
    return query select false, null::integer, null::numeric;
    return;
  end if;

  return query
    select coalesce(k.boleh, false), k.batas_nominal, k.batas_persen
      from (
        select i.boleh, i.batas_nominal, i.batas_persen, 0 as urutan
          from public.izin i
         where i.pengguna_id = auth.uid()
           and i.kode_izin = p_aksi
        union all
        select ip.boleh, ip.batas_nominal, ip.batas_persen, 1 as urutan
          from public.izin_peran ip
         where ip.penyewa_id = v_penyewa
           and ip.peran = v_peran
           and ip.kode_izin = p_aksi
      ) k
     order by k.urutan
     limit 1;

  if not found then
    return query select false, null::integer, null::numeric;      -- izin tak dikenal / belum diatur = TOLAK
  end if;
end
$$;

comment on function public.izin_efektif(text, uuid) is
  'Izin yang benar-benar berlaku: peran TUNGGAL dari pengguna.peran (berlaku di semua cabangnya); centang khusus pegawai menang atas bawaan peran; tidak ada keduanya = tolak.';

revoke all on function public.izin_efektif(text, uuid) from public;
grant execute on function public.izin_efektif(text, uuid) to authenticated, service_role;

-- ==================== 2b. CATATAN PEMASANGAN PIN (dasar pembatas anti-oracle) ===
-- Uji keunikan PIN menjawab "apakah angka ini dipakai orang lain?" — jawaban itu
-- bisa dipakai penyerang untuk menebak PIN kolega (ia tahu PIN-nya sendiri, jadi
-- selalu lolos syarat PIN lama). Karena itu setiap percobaan pemasangan DICATAT
-- di sini (bukan di `percobaan_pin`, yang artinya percobaan *verifikasi*) dan
-- dibatasi 20 kali / 15 menit per akun. Tabel ini tidak bisa dibaca klien.
create table if not exists public.percobaan_simpan_pin (
  id          uuid primary key default gen_random_uuid(),
  pengguna_id uuid not null references public.pengguna (id) on delete cascade,
  perangkat   text not null default 'tidak-diketahui',
  berhasil    boolean not null,
  alasan      text,
  waktu       timestamptz not null default now()
);

create index if not exists percobaan_simpan_pin_pengguna_waktu_idx
  on public.percobaan_simpan_pin (pengguna_id, waktu desc);

alter table public.percobaan_simpan_pin enable row level security;
revoke all on public.percobaan_simpan_pin from public, anon, authenticated;

-- Policy resmi "menolak semua" (pola sama seperti kredensial_pin): deny by default
-- saja tidak cukup — policy-lah yang membuka akses secara sadar, dan di sini
-- tidak ada yang dibuka untuk klien.
create policy percobaan_simpan_pin_tolak_semua on public.percobaan_simpan_pin
  for select using (false);

comment on table public.percobaan_simpan_pin is
  'Catatan setiap percobaan pemasangan PIN (termasuk pemeriksaan keunikan). Dasar pembatas anti-oracle 20 percobaan/15 menit. Hanya ditulis lewat simpan_pin (SECURITY DEFINER).';

-- ================================ 3. PIN 6 ANGKA: BUKAN POLA LEMAH & WAJIB UNIK ==
-- Daftar pola lemah (dokumentasi: DECISIONS_LOG «PIN 6 angka»):
--   1. semua digit sama                      (111111)
--   2. berisi deret naik/turun berurutan     (123456, 654321, 456789)
--   3. blok berulang 2/3 digit               (121212, 123123)
--   4. pasangan berurutan aabbcc             (112233, 334455)
--   5. berbentuk tanggal ddmmyy              (010190)
create or replace function public.pin_lemah(p_pin text)
returns text
language plpgsql
immutable
as $$
declare
  v_a integer;
  v_b integer;
  v_c integer;
begin
  if p_pin is null or p_pin !~ '^\d{6}$' then
    return 'harus tepat 6 angka';
  end if;

  if p_pin ~ '^(\d)\1{5}$' then
    return 'semua angkanya sama';
  end if;

  if p_pin ~ '(0123|1234|2345|3456|4567|5678|6789)' then
    return 'berisi deret angka berurutan';
  end if;
  if p_pin ~ '(9876|8765|7654|6543|5432|4321|3210)' then
    return 'berisi deret angka berurutan';
  end if;

  if p_pin ~ '^(\d\d)\1{2}$' or p_pin ~ '^(\d\d\d)\1$' then
    return 'pola berulang';
  end if;

  if p_pin ~ '^(\d)\1(\d)\2(\d)\3$' then
    v_a := substr(p_pin, 1, 1)::int;
    v_b := substr(p_pin, 3, 1)::int;
    v_c := substr(p_pin, 5, 1)::int;
    if (v_b = v_a + 1 and v_c = v_b + 1) or (v_b = v_a - 1 and v_c = v_b - 1) then
      return 'pasangan angka berurutan';
    end if;
  end if;

  if p_pin ~ '^(0[1-9]|[12]\d|3[01])(0[1-9]|1[0-2])\d\d$' then
    return 'berbentuk tanggal';
  end if;

  return null;    -- null = tidak lemah
end
$$;

comment on function public.pin_lemah(text) is
  'Mengembalikan alasan bila PIN termasuk pola lemah (bukan angka 6 digit, semua sama, deret, blok berulang, pasangan berurutan, atau berbentuk tanggal); null = tidak lemah.';

revoke all on function public.pin_lemah(text) from public;
grant execute on function public.pin_lemah(text) to authenticated, service_role;

-- CARA MENOLAK (penting, ditemukan saat pengujian pembatas ini):
--   Kegagalan yang WAJIB tercatat dikembalikan sebagai **pesan** (return), bukan
--   `raise exception`. Di PostgreSQL, blok penanganan error memakai savepoint, dan
--   exception yang keluar (atau ditangkap pemanggil) membatalkan tulisan di dalam
--   transaksi yang sama — akibatnya baris catatan pembatas ikut hilang dan
--   pembatasnya tidak pernah menyala. Karena itu kontrak `simpan_pin` adalah:
--     * 'PIN tersimpan.'                     → berhasil
--     * pesan lain (diawali 'PIN itu sudah dipakai…' / 'Terlalu banyak…')
--                                            → DITOLAK, dan penolakan itu TERCATAT
--     * exception                            → kesalahan pemakaian/izin (format PIN,
--                                              tanpa izin, PIN lama salah) — tidak
--                                              perlu catatan pembatas
--   Aplikasi (layar) memeriksa teks yang dikembalikan, bukan hanya menunggu error.

-- ================================================== SIMPAN / GANTI PIN =======
-- Perubahan dari 0006: (a) wajib tepat 6 angka, (b) pola lemah ditolak,
-- (c) PIN wajib UNIK antar pegawai satu resto, dan (d) permintaan keunikan
-- dibatasi supaya tidak menjadi alat menebak PIN pegawai lain.
--
-- (d) itu penting: uji keunikan = "apakah PIN ini dipakai orang lain?" — jawabannya
-- bisa dipakai penyerang sebagai ORACLE untuk memastikan PIN koleganya (dia tahu
-- PIN-nya sendiri, jadi tiap percobaan lolos syarat PIN lama). Karena itu setiap
-- percobaan pemasangan DICATAT di `percobaan_simpan_pin` (tabel terpisah, tak bisa
-- dibaca klien) dan dibatasi 20 kali / 15 menit per akun.
create or replace function public.simpan_pin(
  p_pin_baru    text,
  p_pin_lama    text default null,
  p_pengguna_id uuid default null,
  p_perangkat   text default 'tidak-diketahui'
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  BATAS_KEMBAR  constant integer := 20;   -- pemeriksaan keunikan per 15 menit per akun
  JENDELA_MENIT constant integer := 15;
  v_saya      uuid := auth.uid();
  v_target    uuid := coalesce(p_pengguna_id, auth.uid());
  v_perangkat text := coalesce(nullif(p_perangkat, ''), 'tidak-diketahui');
  v_hash      text;
  v_periksa   record;
  v_alasan    text;
  v_penyewa   uuid;
  v_probe     integer;
begin
  if v_saya is null then
    raise exception 'Anda harus masuk dulu untuk menyimpan PIN.';
  end if;

  v_alasan := public.pin_lemah(p_pin_baru);
  if v_alasan is not null then
    raise exception 'PIN ditolak: %.', v_alasan;
  end if;

  if v_target <> v_saya then
    if not public.sepenyewa(v_target) then
      raise exception 'Pegawai itu bukan bagian dari resto Anda.';
    end if;
    if not public.boleh('kelola_pegawai') then
      raise exception 'Anda tidak berizin mengubah PIN pegawai lain.';
    end if;
  end if;

  -- Ganti PIN sendiri WAJIB memakai PIN lama (kecuali belum pernah punya PIN).
  if v_target = v_saya then
    select * into v_periksa
      from public.verifikasi_pin(v_target, coalesce(p_pin_lama, ''), null, v_perangkat);
    if exists (select 1 from public.kredensial_pin k where k.pengguna_id = v_target)
       and not v_periksa.berhasil then
      raise exception 'PIN lama salah. %', v_periksa.pesan;
    end if;
  end if;

  -- ---- keunikan PIN antar pegawai satu resto (dengan pembatas anti-oracle) ----
  select count(*) into v_probe
    from public.percobaan_simpan_pin ps
   where ps.pengguna_id = v_saya
     and ps.waktu > now() - make_interval(mins => JENDELA_MENIT);

  if v_probe >= BATAS_KEMBAR then
    insert into public.percobaan_simpan_pin (pengguna_id, perangkat, berhasil, alasan)
    values (v_saya, v_perangkat, false, 'melebihi batas');
    -- Dikembalikan sebagai PESAN, bukan exception: exception akan membatalkan
    -- baris catatan ini sendiri (savepoint blok penanganan error), sehingga
    -- pembatasnya tidak akan pernah menyala. Lihat catatan "CARA MENOLAK" di bawah.
    return format('Terlalu banyak percobaan memasang PIN (%s kali / %s menit). Tunggu sebentar.', BATAS_KEMBAR, JENDELA_MENIT);
  end if;

  select p.penyewa_id into v_penyewa from public.pengguna p where p.id = v_target;

  if exists (
    select 1
      from public.kredensial_pin k
      join public.pengguna p on p.id = k.pengguna_id
     where p.id <> v_target
       and p.penyewa_id = v_penyewa
       and k.pin_hash is not null
       and crypt(p_pin_baru, k.pin_hash) = k.pin_hash
  ) then
    insert into public.percobaan_simpan_pin (pengguna_id, perangkat, berhasil, alasan)
    values (v_saya, v_perangkat, false, 'PIN kembar');
    return 'PIN itu sudah dipakai pegawai lain di resto ini — pilih angka lain.';
  end if;

  insert into public.percobaan_simpan_pin (pengguna_id, perangkat, berhasil)
  values (v_saya, v_perangkat, true);

  v_hash := crypt(p_pin_baru, gen_salt('bf', 10));

  insert into public.kredensial_pin (pengguna_id, pin_hash, diubah_pada)
  values (v_target, v_hash, now())
  on conflict (pengguna_id) do update
     set pin_hash = excluded.pin_hash, diubah_pada = now();

  update public.pengguna set pin_diubah_pada = now() where id = v_target;

  return 'PIN tersimpan.';
end
$$;

comment on function public.simpan_pin(text, text, uuid, text) is
  'Menyimpan/mengganti PIN: wajib 6 angka, bukan pola lemah, dan unik antar pegawai satu resto. PIN sendiri butuh PIN lama; mengubah PIN pegawai lain butuh izin kelola_pegawai. Penolakan karena PIN kembar / melebihi batas 20 percobaan/15 menit dikembalikan sebagai PESAN (bukan error) supaya catatannya tersimpan.';

-- ======================================================== VERIFIKASI PIN =====
-- Sama seperti 0006 (termasuk pembatasan dua lapis & bukti `aksi` dari K-2b),
-- dengan SATU perubahan: format wajib tepat 6 angka. Catatan pemasangan PIN
-- dipisah ke tabelnya sendiri, jadi penghitung di sini tidak perlu disaring.
create or replace function public.verifikasi_pin(
  p_pengguna_id uuid,
  p_pin         text,
  p_aksi        text default null,
  p_perangkat   text default 'tidak-diketahui'
)
returns table (berhasil boolean, sisa_percobaan integer, pesan text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  BATAS_AKUN       constant integer := 5;    -- 5 kali gagal per akun
  BATAS_PERANGKAT  constant integer := 12;   -- 12 kali gagal per perangkat (melintasi akun)
  JENDELA_MENIT    constant integer := 15;
  v_saya       uuid := auth.uid();
  v_perangkat  text := coalesce(nullif(p_perangkat, ''), 'tidak-diketahui');
  v_hash       text;
  v_penyewa_target uuid;
  v_aktif_target   boolean;
  v_gagal_akun integer;
  v_gagal_alat integer;
  v_berhasil   boolean;
begin
  if v_saya is null then
    return query select false, 0, 'Anda harus masuk dulu untuk memakai PIN.';
    return;
  end if;

  if p_pin is null or p_pin !~ '^\d{6}$' then
    return query select false, 0, 'PIN harus tepat 6 angka.';
    return;
  end if;

  select p.penyewa_id, p.aktif, k.pin_hash
    into v_penyewa_target, v_aktif_target, v_hash
    from public.pengguna p
    left join public.kredensial_pin k on k.pengguna_id = p.id
   where p.id = p_pengguna_id;

  if v_penyewa_target is null or v_penyewa_target <> public.penyewa_saya() or not coalesce(v_aktif_target, false) then
    -- Jangan membocorkan apakah pegawai itu ada: jawab seperti PIN salah.
    insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi)
    values (v_saya, v_perangkat, false, p_aksi);
    return query select false, 0, 'PIN tidak dikenali.';
    return;
  end if;

  select count(*) into v_gagal_akun
    from public.percobaan_pin pp
   where pp.pengguna_id = p_pengguna_id
     and not pp.berhasil
     and pp.waktu > now() - make_interval(mins => JENDELA_MENIT);

  select count(*) into v_gagal_alat
    from public.percobaan_pin pp
   where pp.perangkat = v_perangkat
     and not pp.berhasil
     and pp.waktu > now() - make_interval(mins => JENDELA_MENIT);

  if v_gagal_akun >= BATAS_AKUN or v_gagal_alat >= BATAS_PERANGKAT then
    insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi)
    values (p_pengguna_id, v_perangkat, false, p_aksi);
    return query select false, 0,
      format('PIN terkunci sementara karena terlalu banyak percobaan salah. Coba lagi setelah %s menit.', JENDELA_MENIT);
    return;
  end if;

  v_berhasil := v_hash is not null and crypt(p_pin, v_hash) = v_hash;

  insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi)
  values (p_pengguna_id, v_perangkat, v_berhasil, p_aksi);

  if not v_berhasil then
    return query select false, greatest(BATAS_AKUN - v_gagal_akun - 1, 0),
      'PIN salah.';
    return;
  end if;

  if p_aksi is not null and not public.boleh_untuk(p_pengguna_id, p_aksi) then
    return query select false, BATAS_AKUN,
      format('PIN benar, tetapi pegawai itu tidak berizin: %s.', p_aksi);
    return;
  end if;

  return query select true, BATAS_AKUN, 'PIN diterima.';
end
$$;

comment on function public.verifikasi_pin(uuid, text, text, text) is
  'Memeriksa PIN pegawai (6 angka): mencatat percobaan, membatasi 5 gagal/akun & 12 gagal/perangkat per 15 menit, dan (bila diminta) memeriksa izin aksi pegawai itu. Tidak pernah mengembalikan hash.';

revoke all on function public.simpan_pin(text, text, uuid, text) from public;
revoke all on function public.ganti_pin(text, text, text) from public;
revoke all on function public.verifikasi_pin(uuid, text, text, text) from public;
grant execute on function public.simpan_pin(text, text, uuid, text) to authenticated, service_role;
grant execute on function public.ganti_pin(text, text, text) to authenticated, service_role;
grant execute on function public.verifikasi_pin(uuid, text, text, text) to authenticated, service_role;
