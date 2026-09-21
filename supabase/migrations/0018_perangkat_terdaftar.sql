-- ============================================================================
-- MIGRASI 0018 — perangkat TERDAFTAR: identitas perangkat terverifikasi (T1-24)
-- ============================================================================
-- Temuan yang ditutup: AUD-3 K F-03 (K-2) + catatan temuan F-11 (§1b) + tugas T1-24.
--   Lapis kedua pembatas PIN (12×/15 menit, melintasi akun) selama ini di-key pada
--   NAMA PERANGKAT KIRIMAN KLIEN — penyerang yang memutar nama perangkat mendapat
--   jatah 12× baru setiap nama. Lapis pertama (5×/akun) tetap bekerja, tetapi lapis
--   lintas-akun bisa dilewati. Obat permanen sesuai ROADMAP T1-24: perangkat
--   TERDAFTAR dengan identitas terverifikasi, dan `verifikasi_pin` MENOLAK perangkat
--   yang tidak terdaftar.
--
-- Rancangan (mengikuti pola yang sudah terkunci di repo):
--   * Kunci perangkat disimpan HANYA sebagai hash bcrypt, di tabel TERPISAH
--     `kredensial_perangkat` tanpa grant klien — pola persis `kredensial_pin` (0006,
--     K-3): kolom hash tidak pernah menempel pada tabel yang bisa dibaca klien.
--   * `perangkat_sah(perangkat_id, kunci)` = pemeriksa internal; hak execute klien
--     DICABUT supaya tidak menjadi oracle (pola F-11 `peran_lebih_tinggi`, 0015).
--   * Jawaban penolakan perangkat SERAGAM: 'Perangkat tidak dikenali.' — tidak
--     membocorkan apakah id ada, nonaktif, atau kuncinya salah (pola 'PIN tidak
--     dikenali.' di DECISIONS_LOG [Keamanan]).
--   * Nama perangkat yang DICATAT di `percobaan_pin` kini berasal dari tabel (bukan
--     kiriman klien); lapis kedua pembatas di-key pada `perangkat_id` (uuid).
--   * Kontrak PIN TIDAK berubah: penolakan = PESAN (bukan raise), jawaban seragam,
--     baris `berhasil=true` tetap catatan jujur bukan stempel otorisasi (F-16).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- BAGIAN 1 — tabel perangkat + kredensialnya (pola kredensial_pin 0006)
-- ---------------------------------------------------------------------------
create table if not exists public.perangkat (
  id               uuid primary key default gen_random_uuid(),
  penyewa_id       uuid not null references public.penyewa (id) on delete cascade,
  cabang_id        uuid not null references public.cabang (id) on delete restrict,
  nama             text not null,
  aktif            boolean not null default true,
  didaftarkan_oleh uuid references public.pengguna (id) on delete set null,
  didaftarkan_pada timestamptz not null default now(),
  unique (penyewa_id, nama)
);

comment on table public.perangkat is
  'Perangkat kasir/pegawai yang TERDAFTAR (T1-24). Identitasnya (id + kunci) dipakai verifikasi_pin; nama di sini — bukan kiriman klien — yang masuk catatan percobaan.';

-- Hash kunci perangkat TIDAK menempel pada tabel perangkat (pola K-3 kredensial_pin).
create table if not exists public.kredensial_perangkat (
  perangkat_id uuid primary key references public.perangkat (id) on delete cascade,
  kunci_hash   text not null check (kunci_hash ~ '^\$[a-z0-9]+\$'),
  diubah_pada  timestamptz not null default now()
);

comment on table public.kredensial_perangkat is
  'Hash bcrypt kunci perangkat. Tanpa grant klien — hanya jalur peladen (RPC SECURITY DEFINER) yang menyentuh, sama seperti kredensial_pin.';

revoke all on table public.perangkat from public, anon, authenticated;
revoke all on table public.kredensial_perangkat from public, anon, authenticated;

alter table public.kredensial_perangkat enable row level security;
-- Policy resmi yang MENOLAK semua (pola kredensial_pin_tolak_semua 0006): hak sudah
-- dicabut, policy ini menjaga aturan "setiap tabel wajib punya policy" dan menegaskan
-- klien tidak punya jalan membaca kunci perangkat.
drop policy if exists kredensial_perangkat_tolak_semua on public.kredensial_perangkat;
create policy kredensial_perangkat_tolak_semua on public.kredensial_perangkat
  for select to authenticated, anon using (false);
grant select on table public.perangkat to authenticated;   -- daftar perangkat (tanpa hash) untuk layar kelola
alter table public.perangkat enable row level security;

drop policy if exists perangkat_pilih on public.perangkat;
create policy perangkat_pilih on public.perangkat
  for select to authenticated
  using (penyewa_id = public.penyewa_saya() and public.boleh('kelola_pegawai'));

-- Catatan percobaan kini mengikat perangkat TERDAFTAR (null = percobaan dari
-- perangkat tak dikenal — tetap tercatat, tidak menghitung jatah perangkat).
alter table public.percobaan_pin
  add column if not exists perangkat_id uuid references public.perangkat (id) on delete set null;
create index if not exists percobaan_pin_perangkat_id_waktu_idx
  on public.percobaan_pin (perangkat_id, waktu desc);

-- ---------------------------------------------------------------------------
-- BAGIAN 2 — perangkat_sah(): pemeriksa internal, BUKAN oracle klien
-- ---------------------------------------------------------------------------
create or replace function public.perangkat_sah(p_perangkat_id uuid, p_kunci text)
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select pr.id
    from public.perangkat pr
    join public.kredensial_perangkat kp on kp.perangkat_id = pr.id
   where pr.id = p_perangkat_id
     and pr.aktif
     and pr.penyewa_id = public.penyewa_saya()
     and p_kunci is not null
     and crypt(p_kunci, kp.kunci_hash) = kp.kunci_hash
$$;

comment on function public.perangkat_sah(uuid, text) is
  'Mengembalikan id perangkat bila id+kunci cocok, perangkat aktif, dan se-resto dengan pemanggil; selain itu NULL — tanpa membedakan sebab (anti-oracle). Hak execute klien DICABUT (pola F-11).';

revoke all on function public.perangkat_sah(uuid, text) from public, anon, authenticated;
grant execute on function public.perangkat_sah(uuid, text) to service_role;

-- ---------------------------------------------------------------------------
-- BAGIAN 3 — daftarkan_perangkat / cabut_perangkat (layar kelola pegawai)
-- ---------------------------------------------------------------------------
create or replace function public.daftarkan_perangkat(
  p_nama      text,
  p_kunci     text,
  p_cabang_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_saya uuid := auth.uid();
  v_id   uuid;
begin
  if v_saya is null then
    raise exception 'Anda harus masuk dulu untuk mendaftarkan perangkat.';
  end if;
  if not public.boleh('kelola_pegawai') then
    raise exception 'Hanya pemegang izin kelola_pegawai yang boleh mendaftarkan perangkat.';
  end if;
  if p_nama is null or length(trim(p_nama)) = 0 then
    raise exception 'Nama perangkat wajib diisi.';
  end if;
  if p_kunci is null or length(p_kunci) < 16 then
    raise exception 'Kunci perangkat minimal 16 karakter (dibangkitkan aplikasi, bukan dipilih manusia).';
  end if;
  if p_cabang_id is null or not (p_cabang_id in (select public.cabang_ids_saya())) then
    raise exception 'Perangkat hanya bisa didaftarkan untuk cabang yang Anda kelola.';
  end if;

  insert into public.perangkat (penyewa_id, cabang_id, nama, didaftarkan_oleh)
  values (public.penyewa_saya(), p_cabang_id, trim(p_nama), v_saya)
  returning id into v_id;

  insert into public.kredensial_perangkat (perangkat_id, kunci_hash)
  values (v_id, crypt(p_kunci, gen_salt('bf', 10)));

  return v_id;
end
$$;

comment on function public.daftarkan_perangkat(text, text, uuid) is
  'Mendaftarkan perangkat untuk cabang yang dikelola (izin kelola_pegawai). Kunci disimpan sebagai hash bcrypt; kuncinya sendiri hanya dipegang aplikasi di perangkat itu.';

create or replace function public.cabut_perangkat(p_perangkat_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_saya uuid := auth.uid();
  v_ada  boolean;
begin
  if v_saya is null then
    raise exception 'Anda harus masuk dulu untuk mencabut perangkat.';
  end if;
  if not public.boleh('kelola_pegawai') then
    raise exception 'Hanya pemegang izin kelola_pegawai yang boleh mencabut perangkat.';
  end if;

  update public.perangkat pr
     set aktif = false
   where pr.id = p_perangkat_id
     and pr.penyewa_id = public.penyewa_saya()
  returning true into v_ada;

  return coalesce(v_ada, false);
end
$$;

comment on function public.cabut_perangkat(uuid) is
  'Menonaktifkan perangkat (hilang/dipensiunkan). Percobaan PIN dari perangkat nonaktif ditolak seragam: Perangkat tidak dikenali.';

revoke all on function public.daftarkan_perangkat(text, text, uuid) from public;
revoke all on function public.cabut_perangkat(uuid) from public;
grant execute on function public.daftarkan_perangkat(text, text, uuid) to authenticated, service_role;
grant execute on function public.cabut_perangkat(uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- BAGIAN 4 — verifikasi_pin: perangkat terverifikasi DULU, baru kredensial
-- ---------------------------------------------------------------------------
-- Semua yang dijamin 0016 dipertahankan (F-15, PR-07, PR-13, F-16, pesan bukan
-- raise). Perubahan T1-24:
--   * parameter `p_perangkat text` DIGANTI `p_perangkat_id uuid` + `p_perangkat_kunci text`;
--   * perangkat tak terdaftar/nonaktif/kunci salah → 'Perangkat tidak dikenali.'
--     dan percobaan dicatat (perangkat 'tak-terdaftar');
--   * nama yang dicatat berasal dari tabel perangkat;
--   * lapis kedua pembatas (12×/15 menit) di-key pada perangkat_id.
create or replace function public.verifikasi_pin(
  p_pengguna_id      uuid,
  p_pin              text,
  p_aksi             text default null,
  p_perangkat_id     uuid default null,
  p_perangkat_kunci  text default null,
  p_pesanan_id       uuid default null
)
returns table (berhasil boolean, sisa_percobaan integer, pesan text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  BATAS_AKUN       constant integer := 5;    -- 5 kali gagal per pasangan (pencoba → akun)
  BATAS_PERANGKAT  constant integer := 12;   -- 12 kali gagal per perangkat (melintasi akun)
  JENDELA_MENIT    constant integer := 15;
  v_saya       uuid := auth.uid();
  v_perangkat_id uuid;
  v_perangkat  text;
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

  -- F-15 (2026-09-20): akun nonaktif / tanpa resto mendapat jawaban netral
  -- SEBELUM kredensial disentuh.
  if public.penyewa_saya() is null then
    return query select false, 0, 'PIN tidak dikenali.';
    return;
  end if;

  -- T1-24 (2026-09-21): identitas perangkat diverifikasi DULU. Nama kiriman klien
  -- tidak dipakai lagi — memutar nama tidak lagi menambah jatah 12×.
  v_perangkat_id := public.perangkat_sah(p_perangkat_id, p_perangkat_kunci);
  if v_perangkat_id is null then
    insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, pemanggil_id, pesanan_id, perangkat_id)
    values (v_saya, 'tak-terdaftar', false, p_aksi, v_saya, p_pesanan_id, null);
    return query select false, 0, 'Perangkat tidak dikenali.';
    return;
  end if;
  select pr.nama into v_perangkat from public.perangkat pr where pr.id = v_perangkat_id;

  if p_pin is null or p_pin !~ '^\d{6}$' then
    return query select false, 0, 'PIN harus tepat 6 angka.';
    return;
  end if;

  -- PR-07 (2026-09-20): aksi berkupon WAJIB menyebut pesanan yang disetujui.
  if p_aksi in ('void_sesudah_dapur', 'beri_diskon') and p_pesanan_id is null then
    insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, pemanggil_id, pesanan_id, perangkat_id)
    values (v_saya, v_perangkat, false, p_aksi, v_saya, null, v_perangkat_id);
    return query select false, 0,
      format('Aksi %s wajib menyebut pesanan yang disetujui.', p_aksi);
    return;
  end if;

  select p.penyewa_id, p.aktif, k.pin_hash
    into v_penyewa_target, v_aktif_target, v_hash
    from public.pengguna p
    left join public.kredensial_pin k on k.pengguna_id = p.id
   where p.id = p_pengguna_id;

  if v_penyewa_target is null or v_penyewa_target <> public.penyewa_saya() or not coalesce(v_aktif_target, false) then
    -- Jangan membocorkan apakah pegawai itu ada: jawab seperti PIN salah.
    insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, pemanggil_id, pesanan_id, perangkat_id)
    values (v_saya, v_perangkat, false, p_aksi, v_saya, p_pesanan_id, v_perangkat_id);
    return query select false, 0, 'PIN tidak dikenali.';
    return;
  end if;

  -- PR-13: yang dibatasi adalah PERCOBAAN ORANG ITU terhadap akun itu.
  select count(*) into v_gagal_akun
    from public.percobaan_pin pp
   where pp.pengguna_id = p_pengguna_id
     and pp.pemanggil_id = v_saya
     and not pp.berhasil
     and pp.waktu > now() - make_interval(mins => JENDELA_MENIT);

  -- T1-24: lapis perangkat kini di-key pada identitas TERDAFTAR (bukan nama).
  select count(*) into v_gagal_alat
    from public.percobaan_pin pp
   where pp.perangkat_id = v_perangkat_id
     and pp.pemanggil_id = v_saya
     and not pp.berhasil
     and pp.waktu > now() - make_interval(mins => JENDELA_MENIT);

  if v_gagal_akun >= BATAS_AKUN or v_gagal_alat >= BATAS_PERANGKAT then
    insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, pemanggil_id, pesanan_id, perangkat_id)
    values (p_pengguna_id, v_perangkat, false, p_aksi, v_saya, p_pesanan_id, v_perangkat_id);
    return query select false, 0,
      format('PIN terkunci sementara karena terlalu banyak percobaan salah dari perangkat/akun Anda. Coba lagi setelah %s menit.', JENDELA_MENIT);
    return;
  end if;

  v_berhasil := v_hash is not null and crypt(p_pin, v_hash) = v_hash;

  insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, pemanggil_id, pesanan_id, perangkat_id)
  values (p_pengguna_id, v_perangkat, v_berhasil, p_aksi, v_saya, p_pesanan_id, v_perangkat_id);

  if not v_berhasil then
    return query select false, greatest(BATAS_AKUN - v_gagal_akun - 1, 0),
      'PIN salah.';
    return;
  end if;

  if p_aksi is not null and not public.boleh_untuk(p_pengguna_id, p_aksi) then
    -- F-16: baris berhasil=true di atas CATATAN jujur, bukan stempel otorisasi.
    return query select false, BATAS_AKUN,
      format('PIN benar, tetapi pegawai itu tidak berizin: %s.', p_aksi);
    return;
  end if;

  return query select true, BATAS_AKUN, 'PIN diterima.';
end
$$;

comment on function public.verifikasi_pin(uuid, text, text, uuid, text, uuid) is
  'Verifikasi PIN dengan perangkat TERDAFTAR (T1-24): id+kunci perangkat diverifikasi lebih dulu (perangkat_sah), penolakan perangkat seragam "Perangkat tidak dikenali.", lapis lintas-akun di-key pada perangkat_id. Kontrak 0016 dipertahankan: penolakan = PESAN, jawaban seragam, berhasil=true bukan stempel otorisasi.';

revoke all on function public.verifikasi_pin(uuid, text, text, uuid, text, uuid) from public;
grant execute on function public.verifikasi_pin(uuid, text, text, uuid, text, uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- BAGIAN 5 — simpan_pin & ganti_pin ikut memakai perangkat terverifikasi
-- ---------------------------------------------------------------------------
create or replace function public.simpan_pin(
  p_pin_baru         text,
  p_pin_lama         text default null,
  p_pengguna_id      uuid default null,
  p_perangkat_id     uuid default null,
  p_perangkat_kunci  text default null
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
  v_perangkat_id uuid;
  v_perangkat text;
  v_hash      text;
  v_periksa   record;
  v_alasan    text;
  v_penyewa   uuid;
  v_probe     integer;
begin
  if v_saya is null then
    raise exception 'Anda harus masuk dulu untuk menyimpan PIN.';
  end if;

  -- T1-24: menyimpan/mengganti PIN juga wajib dari perangkat terdaftar.
  v_perangkat_id := public.perangkat_sah(p_perangkat_id, p_perangkat_kunci);
  if v_perangkat_id is null then
    insert into public.percobaan_simpan_pin (pengguna_id, target_id, perangkat, berhasil, alasan)
    values (v_saya, v_target, 'tak-terdaftar', false, 'perangkat tidak dikenal');
    return 'Perangkat tidak dikenali.';
  end if;
  select pr.nama into v_perangkat from public.perangkat pr where pr.id = v_perangkat_id;

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

    -- HIERARKI PERAN (putaran13 #2 PR-01); F-14: penolakan sebagai PESAN.
    if not public.peran_lebih_tinggi(v_saya, v_target) then
      insert into public.percobaan_simpan_pin (pengguna_id, target_id, perangkat, berhasil, alasan)
      values (v_saya, v_target, v_perangkat, false, 'hierarki peran');
      return 'Peran Anda tidak lebih tinggi dari pegawai itu — PIN-nya hanya boleh diganti oleh atasan atau dirinya sendiri.';
    end if;
  end if;

  -- Ganti PIN sendiri WAJIB PIN lama (kecuali belum pernah punya PIN); F-14: PESAN.
  if v_target = v_saya then
    if p_pin_lama ~ '^\d{4}$' then
      -- PR-09: PIN warisan 4 angka hanya untuk naik ke 6 angka, dengan pembatas.
      select count(*) into v_probe
        from public.percobaan_pin pp
       where pp.pengguna_id = v_target
         and pp.pemanggil_id = v_saya
         and not pp.berhasil
         and pp.waktu > now() - make_interval(mins => JENDELA_MENIT);
      if v_probe >= 5 then
        insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, pemanggil_id, perangkat_id)
        values (v_target, v_perangkat, false, v_saya, v_perangkat_id);
        return format('PIN lama salah. Coba lagi setelah %s menit (terlalu banyak percobaan).', JENDELA_MENIT);
      end if;
      select k.pin_hash into v_hash from public.kredensial_pin k where k.pengguna_id = v_target;
      if v_hash is not null and crypt(p_pin_lama, v_hash) <> v_hash then
        insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, pemanggil_id, perangkat_id)
        values (v_target, v_perangkat, false, v_saya, v_perangkat_id);
        return 'PIN lama salah. PIN warisan 4 angka hanya bisa dipakai untuk naik ke PIN 6 angka.';
      end if;
      -- cocok (atau memang belum pernah punya PIN): lanjut menyimpan PIN baru.
    else
      select * into v_periksa
        from public.verifikasi_pin(v_target, coalesce(p_pin_lama, ''), null, v_perangkat_id, p_perangkat_kunci);
      if exists (select 1 from public.kredensial_pin k where k.pengguna_id = v_target)
         and not v_periksa.berhasil then
        return format('PIN lama salah. %s', v_periksa.pesan);
      end if;
    end if;
  end if;

  -- ---- keunikan PIN antar pegawai satu resto (dengan pembatas anti-oracle) ----
  select count(*) into v_probe
    from public.percobaan_simpan_pin ps
   where ps.pengguna_id = v_saya
     and ps.waktu > now() - make_interval(mins => JENDELA_MENIT);

  if v_probe >= BATAS_KEMBAR then
    insert into public.percobaan_simpan_pin (pengguna_id, target_id, perangkat, berhasil, alasan)
    values (v_saya, v_target, v_perangkat, false, 'melebihi batas');
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
    insert into public.percobaan_simpan_pin (pengguna_id, target_id, perangkat, berhasil, alasan)
    values (v_saya, v_target, v_perangkat, false, 'PIN kembar');
    return 'PIN itu tidak bisa dipakai — pilih angka lain.';
  end if;

  insert into public.percobaan_simpan_pin (pengguna_id, target_id, perangkat, berhasil)
  values (v_saya, v_target, v_perangkat, true);

  v_hash := crypt(p_pin_baru, gen_salt('bf', 10));

  insert into public.kredensial_pin (pengguna_id, pin_hash, diubah_pada)
  values (v_target, v_hash, now())
  on conflict (pengguna_id) do update
     set pin_hash = excluded.pin_hash, diubah_pada = now();

  update public.pengguna set pin_diubah_pada = now() where id = v_target;

  return 'PIN tersimpan.';
end
$$;

comment on function public.simpan_pin(text, text, uuid, uuid, text) is
  'Menyimpan PIN (sendiri/pegawai) dari perangkat TERDAFTAR (T1-24). Kontrak 0016 dipertahankan: penolakan = PESAN (catatan tidak tergulung balik), hierarki peran, PIN kembar ditolak, PIN warisan 4 angka hanya sebagai PIN lama.';

revoke all on function public.simpan_pin(text, text, uuid, uuid, text) from public;
grant execute on function public.simpan_pin(text, text, uuid, uuid, text) to authenticated, service_role;

create or replace function public.ganti_pin(
  p_pin_lama        text,
  p_pin_baru        text,
  p_perangkat_id    uuid default null,
  p_perangkat_kunci text default null
)
returns text
language sql
security definer
set search_path = public, pg_temp
as $$
  select public.simpan_pin(p_pin_baru, p_pin_lama, null, p_perangkat_id, p_perangkat_kunci)
$$;

comment on function public.ganti_pin(text, text, uuid, text) is
  'Ganti PIN sendiri — pembungkus simpan_pin dengan perangkat terverifikasi (T1-24).';

revoke all on function public.ganti_pin(text, text, uuid, text) from public;
grant execute on function public.ganti_pin(text, text, uuid, text) to authenticated, service_role;

-- Tanda tangan LAMA (p_perangkat text) dicabut supaya tidak ada jalur yang
-- memakai nama kiriman klien lagi.
drop function if exists public.verifikasi_pin(uuid, text, text, text, uuid);
drop function if exists public.simpan_pin(text, text, uuid, text);
drop function if exists public.ganti_pin(text, text, text);
