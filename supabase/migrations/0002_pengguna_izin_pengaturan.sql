-- ============================================================================
-- 0002 — Pengguna, pengguna_cabang, izin, pengaturan
-- Peran & izin berjenjang (TECH_SPEC §4.1 & §9 ART-2); pengaturan per penyewa.
--
-- Prinsip yang dikunci di sini:
--   * `pengguna.id` = id Auth (tautan ke auth.users). Peran resmi hidup di kolom
--     `peran`; siapa boleh apa tetap diperiksa dari tabel `izin`, bukan ditebak
--     dari peran saja (ART-2).
--   * Pegawai merangkap cabang: satu baris `pengguna_cabang` per cabang, dan
--     perannya bisa berbeda per cabang (mis. kasir di cabang 1, pelayan di cabang 2).
--   * Pengaturan disimpan PER PENYEWA (bukan per cabang) sesuai TECH_SPEC §4.1.
--   * Semua nominal uang = bilangan bulat rupiah (TECH_SPEC §9 ART-3).
-- ============================================================================

-- ---------------------------------------------------------------- pengguna
create table if not exists public.pengguna (
  id             uuid primary key references auth.users (id) on delete cascade,
  penyewa_id     uuid references public.penyewa (id) on delete cascade,
  nama           text not null check (length(btrim(nama)) between 1 and 120),
  email          text not null check (position('@' in email) > 1),
  peran          text not null check (
                   peran in ('pemilik_platform', 'owner_pusat', 'admin_cabang', 'kasir', 'pelayan', 'dapur')
                 ),
  pin_hash       text,
  aktif          boolean not null default true,
  terakhir_masuk timestamptz,
  dibuat_pada    timestamptz not null default now(),
  -- Pemilik Platform berdiri di atas semua penyewa (penyewa_id kosong);
  -- peran lain WAJIB punya penyewa. Ini yang mencegah akun "menggantung".
  constraint pengguna_penyewa_sesuai_peran check (
    (peran = 'pemilik_platform' and penyewa_id is null)
    or (peran <> 'pemilik_platform' and penyewa_id is not null)
  )
);

comment on table public.pengguna is
  'Pegawai & pemilik. id = id Auth. Peran resmi = kolom peran; izin rinci = tabel izin (ART-2).';

-- Satu email hanya boleh sekali per penyewa (beda penyewa boleh sama).
create unique index if not exists pengguna_email_per_penyewa_idx
  on public.pengguna (penyewa_id, lower(email))
  where penyewa_id is not null;

create unique index if not exists pengguna_email_platform_idx
  on public.pengguna (lower(email))
  where penyewa_id is null;

create index if not exists pengguna_penyewa_idx on public.pengguna (penyewa_id);

-- -------------------------------------------------------- pengguna_cabang
create table if not exists public.pengguna_cabang (
  pengguna_id uuid not null references public.pengguna (id) on delete cascade,
  cabang_id   uuid not null references public.cabang (id) on delete cascade,
  peran       text not null check (
                peran in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan', 'dapur')
              ),
  aktif       boolean not null default true,
  dibuat_pada timestamptz not null default now(),
  primary key (pengguna_id, cabang_id)
);

comment on table public.pengguna_cabang is
  'Pegawai bisa merangkap beberapa cabang, dan perannya bisa berbeda per cabang (ART-2).';

create index if not exists pengguna_cabang_cabang_idx on public.pengguna_cabang (cabang_id);

-- ------------------------------------------------------------------- izin
create table if not exists public.izin (
  pengguna_id   uuid not null references public.pengguna (id) on delete cascade,
  kode_izin     text not null check (kode_izin in (
                  'ubah_harga', 'beri_diskon', 'void_sebelum_dapur', 'void_sesudah_dapur',
                  'lihat_laporan', 'kelola_pegawai', 'atur_pengaturan', 'pakai_voucher',
                  'tutup_kas', 'ubah_stok'
                )),
  boleh         boolean not null default false,
  batas_nominal integer check (batas_nominal is null or batas_nominal >= 0),          -- rupiah bulat; null = tanpa batas khusus
  batas_persen  numeric(5, 2) check (batas_persen is null or (batas_persen >= 0 and batas_persen <= 100)),
  diubah_oleh   uuid references public.pengguna (id) on delete set null,
  diubah_pada   timestamptz not null default now(),
  primary key (pengguna_id, kode_izin)
);

comment on table public.izin is
  'Centang izin per pegawai (M3/ART-2). Sumber kebenaran tindakan sensitif: ubah harga, diskon+batas, void pra/pasca dapur, laporan, pegawai, pengaturan, voucher, tutup kas, stok.';

-- -------------------------------------------------------------- pengaturan
create table if not exists public.pengaturan (
  penyewa_id                 uuid primary key references public.penyewa (id) on delete cascade,
  pajak_pb1_persen           numeric(5, 2) not null default 10 check (pajak_pb1_persen between 0 and 100),
  service_persen             numeric(5, 2) not null default 5 check (service_persen between 0 and 100),
  pembulatan                 text not null default 'none' check (pembulatan in ('none', '100', '500', '1000')),
  tumpuk_diskon              boolean not null default false,
  batas_maks_potongan_persen numeric(5, 2) not null default 100 check (batas_maks_potongan_persen between 0 and 100),
  batas_maks_potongan_nominal integer check (batas_maks_potongan_nominal is null or batas_maks_potongan_nominal >= 0), -- null = tanpa batas
  header_struk               text not null default '',
  footer_struk               text not null default '',
  cara_pesan                 text not null default 'kasir' check (cara_pesan in ('kasir', 'mandiri', 'meja', 'campur')),
  jam_buka                   text,
  diubah_oleh                uuid references public.pengguna (id) on delete set null,
  diubah_pada                timestamptz not null default now()
);

comment on table public.pengaturan is
  'Pengaturan per penyewa (bukan per cabang): pajak PB1, service, pembulatan, tumpuk diskon, batas potongan, struk, cara pesan (Aturan Bisnis 1 & 2).';

-- ------------------------------------------------------------ kunci RLS
alter table public.pengguna enable row level security;
alter table public.pengguna_cabang enable row level security;
alter table public.izin enable row level security;
alter table public.pengaturan enable row level security;

grant select, insert, update, delete on public.pengguna to service_role;
grant select, insert, update, delete on public.pengguna_cabang to service_role;
grant select, insert, update, delete on public.izin to service_role;
grant select, insert, update, delete on public.pengaturan to service_role;

grant select on public.pengguna to anon, authenticated;
grant select on public.pengguna_cabang to anon, authenticated;
grant select on public.izin to anon, authenticated;
-- pengaturan boleh diubah langsung oleh owner pusat (policy di 0004), jadi UPDATE ikut diberikan.
grant select, update on public.pengaturan to anon, authenticated;
