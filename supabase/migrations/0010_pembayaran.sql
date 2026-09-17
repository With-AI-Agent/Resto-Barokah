-- ============================================================================
-- 0010 — Uang masuk & pembatalan: pembayaran, metode bayar, diskon, pembatalan
--
-- Empat pagar yang dipasang di sini (semuanya menyangkut uang, jadi dijaga
-- database — bukan hanya oleh layar):
--
--   1. ANGKA UANG TIDAK BOLEH DIKARANG KLIEN. Kolom uang pesanan
--      (subtotal/pajak/service/total_diskon/total) hanya boleh diisi bukan-nol
--      oleh fungsi peladen (penanda sesi `app.uang_dari_peladen`). Kasir tetap
--      bisa membuat pesanan (angkanya nol dulu) dan menambah/mengubah baris;
--      angka uang diisi `hitung_total()` (T1-15).
--   2. SATU PEMBAYARAN = SATU BARIS TERCATAT. `kunci_idempoten` unik per pesanan
--      (tidak bisa dobel saat koneksi putus), jumlah wajib > 0, uang tunai wajib
--      menyebut uang diterima, bukan tunai wajib menyebut referensi, dan
--      total pembayaran tidak boleh melebihi total pesanan. Baris pembayaran
--      TIDAK bisa diubah/dihapus — koreksi lewat pembatalan (berjejak).
--   3. DISKON TIDAK BOLEH MELEBIHI BATAS. Batas diambil dari gerbang izin yang
--      sama (`boleh('beri_diskon', nominal, persen)`) — jadi batas kasir
--      (25.000 / 5%) dan admin (50.000 / 10%) berlaku di sini, bukan disalin
--      ulang. Diskon kedua hanya boleh bila pengaturan resto mengizinkan
--      tumpuk diskon; diskon tidak boleh melebihi subtotal.
--   4. PEMBATALAN WAJIB BERALASAN & SESUAI TAHAP. Alasan wajib, tahap harus
--      cocok dengan keadaan pesanan (sudah dikirim ke dapur atau belum), dan
--      pembatalan SETELAH dapur mulai wajib disetujui pengguna berizin.
--      Nilai kerugian dihitung dari SALINAN HARGA di baris pesanan.
-- ============================================================================

-- -------------------------------------------------------------- metode_bayar
create table if not exists public.metode_bayar (
  id             uuid primary key default gen_random_uuid(),
  penyewa_id     uuid not null references public.penyewa (id) on delete cascade,
  nama           text not null,
  jenis          text not null check (jenis in ('tunai', 'non_tunai')),
  butuh_referensi boolean not null default false,
  aktif          boolean not null default true,
  urutan         integer not null default 0,
  unique (penyewa_id, nama),
  -- tunai tidak perlu nomor referensi; selain tunai hampir selalu perlu
  check (jenis = 'tunai' or butuh_referensi)
);

comment on table public.metode_bayar is
  'Metode bayar per resto (Tunai, QRIS, Transfer, Kartu…). Tambah metode tanpa koding: cukup satu baris di sini.';

alter table public.metode_bayar enable row level security;

-- metode bawaan untuk resto baru (agar resto tidak pernah kehabisan cara bayar)
create or replace function public.pasang_metode_bayar_bawaan(p_penyewa_id uuid)
returns void
language sql
security definer
set search_path = public, pg_temp
as $$
  insert into public.metode_bayar (penyewa_id, nama, jenis, butuh_referensi, urutan)
  values
    (p_penyewa_id, 'Tunai',   'tunai',     false, 1),
    (p_penyewa_id, 'QRIS',    'non_tunai', true,  2),
    (p_penyewa_id, 'Transfer', 'non_tunai', true,  3),
    (p_penyewa_id, 'Kartu',   'non_tunai', true,  4)
  on conflict (penyewa_id, nama) do nothing
$$;

create or replace function public.picu_metode_bayar_bawaan()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.pasang_metode_bayar_bawaan(new.id);
  return new;
end
$$;

drop trigger if exists penyewa_pasang_metode_bayar on public.penyewa;
create trigger penyewa_pasang_metode_bayar
  after insert on public.penyewa
  for each row execute function public.picu_metode_bayar_bawaan();

select public.pasang_metode_bayar_bawaan(id) from public.penyewa;

-- --------------------------------------------------------------- pembayaran
create table if not exists public.pembayaran (
  id                uuid primary key default gen_random_uuid(),
  pesanan_id        uuid not null references public.pesanan (id) on delete cascade,
  metode_id         uuid references public.metode_bayar (id) on delete set null,
  metode_nama_saat_itu text not null,             -- salinan nama: metode boleh diganti namanya
  jenis_saat_itu    text not null check (jenis_saat_itu in ('tunai', 'non_tunai')),
  jumlah            integer not null check (jumlah > 0),
  diterima          integer check (diterima is null or diterima >= 0),
  kembalian         integer check (kembalian is null or kembalian >= 0),
  referensi         text,
  kasir_id          uuid references public.pengguna (id) on delete set null,
  shift_id          uuid,                          -- kunci asing menyusul di T1-11 (shift_kas)
  waktu             timestamptz not null default now(),
  kunci_idempoten   text not null,
  unique (pesanan_id, kunci_idempoten)
);

comment on table public.pembayaran is
  'Satu baris = satu uang masuk tercatat. Tidak pernah diubah/dihapus; koreksi lewat pembatalan. Beberapa baris per pesanan sah (pembayaran terbagi).';

alter table public.pembayaran enable row level security;

create index if not exists pembayaran_pesanan_idx on public.pembayaran (pesanan_id);

-- ------------------------------------------------------------------ diskon
create table if not exists public.diskon_transaksi (
  id              uuid primary key default gen_random_uuid(),
  pesanan_id      uuid not null references public.pesanan (id) on delete cascade,
  jenis           text not null check (jenis in ('voucher', 'manual', 'promo')),
  persen          numeric(5, 2) check (persen is null or (persen >= 0 and persen <= 100)),
  nominal         integer check (nominal is null or nominal >= 0),
  nilai           integer not null check (nilai >= 0),      -- rupiah bulat yang benar-benar dipotong
  alasan          text,
  pelaku_id       uuid references public.pengguna (id) on delete set null,
  disetujui_oleh  uuid references public.pengguna (id) on delete set null,
  voucher_id      uuid,                                     -- kunci asing menyusul di T1-12
  waktu           timestamptz not null default now(),
  check (jenis <> 'manual' or (alasan is not null and length(btrim(alasan)) > 0))
);

comment on table public.diskon_transaksi is
  'Diskon per transaksi (voucher/manual/promo). Diskon manual wajib beralasan dan diperiksa batas izin oleh pemicu.';

alter table public.diskon_transaksi enable row level security;

create index if not exists diskon_transaksi_pesanan_idx on public.diskon_transaksi (pesanan_id);

-- -------------------------------------------------------------- pembatalan
create table if not exists public.pembatalan (
  id               uuid primary key default gen_random_uuid(),
  pesanan_id       uuid not null references public.pesanan (id) on delete cascade,
  pesanan_item_id  uuid references public.pesanan_item (id) on delete set null,
  tahap            text not null check (tahap in ('sebelum_dapur', 'sesudah_dapur')),
  pelaku_id        uuid references public.pengguna (id) on delete set null,
  disetujui_oleh   uuid references public.pengguna (id) on delete set null,
  alasan           text not null,
  nilai_kerugian   integer not null default 0 check (nilai_kerugian >= 0),
  bahan_terbuang   boolean not null default false,
  waktu            timestamptz not null default now(),
  check (length(btrim(alasan)) > 0)
);

comment on table public.pembatalan is
  'Catatan pembatalan tingkat pesanan maupun satu baris item. Wajib beralasan; setelah dapur mulai wajib disetujui pengguna berizin (Aturan Bisnis 7).';

alter table public.pembatalan enable row level security;

create index if not exists pembatalan_pesanan_idx on public.pembatalan (pesanan_id);

-- ============================ PENJAGA 1: angka uang hanya dari peladen ======
-- "Peran peladen" = sedang berjalan sebagai pemilik tabel (inilah keadaan di dalam
-- fungsi SECURITY DEFINER seperti hitung_total) atau sebagai service_role.
-- Klien yang masuk (authenticated) TIDAK BISA memalsukan keadaan ini — berbeda
-- dari penanda sesi yang bisa dipasang siapa pun yang bisa menjalankan SQL.
-- PENTING: fungsi ini TIDAK boleh SECURITY DEFINER. Di dalam fungsi SECURITY
-- DEFINER, `current_user` menjadi pemilik fungsi (postgres) — jadi pemeriksaan
-- "siapa yang sedang menjalankan perintah ini" akan selalu menjawab "peladen"
-- dan penjaganya jadi buta. Cacat ini tertangkap uji dan diperbaiki.
create or replace function public.peran_peladen()
returns boolean
language sql
stable
set search_path = public, pg_temp
as $$
  select current_user = (
           select pg_get_userbyid(c.relowner)
             from pg_class c
             join pg_namespace n on n.oid = c.relnamespace
            where n.nspname = 'public' and c.relname = 'pesanan'
         )
      or pg_has_role(current_user, 'service_role', 'member')
$$;

comment on function public.peran_peladen() is
  'Benar bila perintah sedang dijalankan oleh fungsi peladen (pemilik tabel) atau service_role. Dipakai penjaga angka uang.';

-- ================================ PEMBANTU: total uang yang sudah dibayar ===
-- ISOLASI LINTAS RESTO (temuan audit AUD-3 K-1, 2026-09-17): fungsi SECURITY DEFINER
-- melewati RLS, jadi tanpa pemeriksaan di sini siapa pun yang masuk bisa membaca angka
-- uang pesanan resto LAIN hanya dengan menebak UUID pesanannya. Pemeriksaan keterlihatan
-- disamakan dengan policy baris `pembayaran` (pesanan_sepenyewa).
--
-- PENTING — jangan pakai peran_peladen() di sini: di dalam fungsi SECURITY DEFINER
-- `current_user` adalah PEMILIK fungsi (postgres), sehingga peran_peladen() akan SELALU
-- menjawab "peladen" dan penjaganya buta (terbukti saat uji: kebocoran tetap terjadi
-- pada percobaan pertama). Yang dipakai adalah identitas PEMANGGIL (auth.uid() dari token,
-- tidak bisa dipalsukan klien): tanpa identitas = jalur peladen (service_role/penyiapan).
create or replace function public.total_dibayar(p_pesanan_id uuid)
returns integer
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(sum(pb.jumlah), 0)::integer
    from public.pembayaran pb
   where pb.pesanan_id = p_pesanan_id
     and (auth.uid() is null or public.pesanan_sepenyewa(pb.pesanan_id))
$$;

comment on function public.total_dibayar(uuid) is
  'Jumlah uang yang sudah tercatat masuk untuk satu pesanan. Dipakai pemicu pembayaran & RPC pembayaran. Mengembalikan 0 bila pesanan itu bukan milik resto/cabang pemanggil (isolasi lintas penyewa, audit AUD-3 K-1).';

create or replace function public.picu_pesanan_jaga_uang()
returns trigger
language plpgsql
as $$
begin
  -- Tanpa pengguna masuk (penyiapan / fungsi peladen yang memakai service_role)
  -- pemeriksaan ini tidak berlaku.
  if auth.uid() is null then
    return new;
  end if;

  if public.peran_peladen() then
    return new;   -- dipanggil oleh fungsi peladen yang berhak menghitung uang
  end if;

  if tg_op = 'INSERT' then
    if coalesce(new.subtotal, 0) <> 0 or coalesce(new.pajak, 0) <> 0
       or coalesce(new.service, 0) <> 0 or coalesce(new.total_diskon, 0) <> 0
       or coalesce(new.total, 0) <> 0 then
      raise exception 'Angka uang pesanan hanya boleh diisi oleh fungsi perhitungan peladen (hitung_total), bukan dikirim dari perangkat.';
    end if;
  else
    if new.subtotal     is distinct from old.subtotal
       or new.pajak       is distinct from old.pajak
       or new.service     is distinct from old.service
       or new.total_diskon is distinct from old.total_diskon
       or new.total       is distinct from old.total then
      raise exception 'Angka uang pesanan hanya boleh diubah oleh fungsi perhitungan peladen (hitung_total).';
    end if;
  end if;
  return new;
end
$$;

drop trigger if exists pesanan_jaga_uang on public.pesanan;
create trigger pesanan_jaga_uang
  before insert or update on public.pesanan
  for each row execute function public.picu_pesanan_jaga_uang();

-- ================================ PENJAGA 2: pembayaran jujur & tidak dobel ==
create or replace function public.picu_pembayaran_jujur()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pesanan  record;
  v_metode   record;
  v_sebelum  integer;
begin
  select p.id, p.status, p.total, p.penyewa_id
    into v_pesanan
    from public.pesanan p
   where p.id = new.pesanan_id;

  if v_pesanan.id is null then
    raise exception 'Pesanan tidak ditemukan.';
  end if;
  if v_pesanan.status = 'batal' then
    raise exception 'Pesanan ini sudah dibatalkan — uang tidak boleh dicatat lagi.';
  end if;

  if new.metode_id is not null then
    select m.nama, m.jenis, m.butuh_referensi
      into v_metode
      from public.metode_bayar m
     where m.id = new.metode_id
       and m.penyewa_id = v_pesanan.penyewa_id;
    if v_metode.nama is null then
      raise exception 'Metode bayar itu tidak ada di resto ini.';
    end if;
    new.metode_nama_saat_itu := v_metode.nama;
    new.jenis_saat_itu := v_metode.jenis;
  end if;

  if new.jenis_saat_itu = 'tunai' then
    if new.diterima is null then
      raise exception 'Pembayaran tunai wajib menyebut uang yang diterima.';
    end if;
    if new.diterima < new.jumlah then
      raise exception 'Uang diterima (%) lebih kecil dari jumlah bayar (%).', new.diterima, new.jumlah;
    end if;
    new.kembalian := new.diterima - new.jumlah;
  else
    if new.referensi is null or length(btrim(new.referensi)) = 0 then
      raise exception 'Pembayaran bukan tunai wajib menyebut nomor referensi.';
    end if;
    new.diterima := null;
    new.kembalian := null;
  end if;

  if new.kasir_id is null then
    new.kasir_id := auth.uid();
  end if;
  -- Jejak pelaku TIDAK boleh dikarang klien (temuan audit AUD-3 K-2, 2026-09-17):
  -- sebelumnya kasir bisa menuliskan nama owner sebagai kasir pembayaran, dan karena
  -- barisnya append-only kesalahan atribusi itu permanen.
  if auth.uid() is not null and new.kasir_id is distinct from auth.uid() then
    raise exception 'Nama kasir diisi sistem — tidak boleh menyebut orang lain.';
  end if;

  -- Total pesanan WAJIB sudah dihitung sebelum uang boleh dicatat (temuan audit AUD-3 K-1,
  -- 2026-09-17). Sebelumnya pemeriksaan dilewati saat total masih 0 — dan karena hitung_total
  -- (T1-15) belum ada, semua pesanan bertotal 0 sehingga berapa pun uangnya diterima tanpa
  -- penjaga, sementara baris uang tidak bisa diubah/dihapus (tidak ada jalan pemulihan).
  -- Menolak di sini membuat uang tidak pernah tercatat di atas angka yang belum pasti.
  if coalesce(v_pesanan.total, 0) <= 0 then
    raise exception 'Total pesanan belum dihitung — pembayaran belum boleh dicatat.';
  end if;

  v_sebelum := public.total_dibayar(new.pesanan_id) + new.jumlah;
  if v_sebelum > v_pesanan.total then
    raise exception 'Total pembayaran (%) melebihi total pesanan (%).', v_sebelum, v_pesanan.total;
  end if;

  return new;
end
$$;

drop trigger if exists pembayaran_jujur on public.pembayaran;
create trigger pembayaran_jujur
  before insert on public.pembayaran
  for each row execute function public.picu_pembayaran_jujur();

-- ================================ PENJAGA 3: diskon tidak melebihi batas ====
create or replace function public.picu_diskon_batas()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pesanan   record;
  v_sudah     integer;      -- total nilai diskon yang sudah ada
  v_jumlah    integer;      -- berapa diskon yang sudah tercatat
  v_tumpuk    boolean;      -- apakah resto mengizinkan tumpuk diskon
  v_persen    numeric;      -- persen EFEKTIF (dihitung dari uang, bukan dari klien)
begin
  select p.id, p.subtotal, p.penyewa_id into v_pesanan
    from public.pesanan p where p.id = new.pesanan_id;
  if v_pesanan.id is null then
    raise exception 'Pesanan tidak ditemukan.';
  end if;

  if new.jenis = 'manual' then
    -- Persen EFEKTIF dihitung dari UANG (nilai diskon / subtotal pesanan), bukan dari kolom
    -- `persen` kiriman klien — temuan audit AUD-3 K-2 (B F-06): dengan `coalesce(new.persen, 0)`,
    -- mengosongkan kolom `persen` membuat batas persen tidak diperiksa sama sekali.
    -- Bila subtotal belum dihitung (0), pakai persen kiriman; bila itu pun kosong → anggap 100%
    -- (paling ketat: hanya pemegang izin penuh yang lolos).
    v_persen := coalesce(
      case when coalesce(v_pesanan.subtotal, 0) > 0
           then round(new.nilai::numeric * 100 / v_pesanan.subtotal, 2) end,
      new.persen,
      100);
    if not public.boleh('beri_diskon', new.nilai, v_persen) then
      raise exception 'Diskon ini melebihi batas izin Anda. Minta persetujuan atasan (PIN).';
    end if;
  elsif new.jenis = 'voucher' then
    if not public.boleh('pakai_voucher') then
      raise exception 'Anda tidak berizin memakai voucher.';
    end if;
  end if;

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

  if coalesce(v_pesanan.subtotal, 0) > 0 and v_sudah + new.nilai > v_pesanan.subtotal then
    raise exception 'Total diskon (%) melebihi subtotal pesanan (%).', v_sudah + new.nilai, v_pesanan.subtotal;
  end if;

  if new.pelaku_id is null then
    new.pelaku_id := auth.uid();
  end if;
  -- Jejak pelaku tidak boleh dikarang klien (temuan audit AUD-3 K-2, 2026-09-17).
  if auth.uid() is not null and new.pelaku_id is distinct from auth.uid() then
    raise exception 'Pelaku diskon diisi sistem — tidak boleh menyebut orang lain.';
  end if;
  return new;
end
$$;

drop trigger if exists diskon_batas on public.diskon_transaksi;
create trigger diskon_batas
  before insert on public.diskon_transaksi
  for each row execute function public.picu_diskon_batas();

-- ================================ PENJAGA 4: pembatalan beralasan & bertahap =
create or replace function public.picu_pembatalan_sah()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pesanan record;
  v_item    record;
  v_nilai   integer;
  v_tahap   text;
  v_status  text;
begin
  select p.id, p.dikirim_ke_dapur_pada, p.subtotal
    into v_pesanan
    from public.pesanan p where p.id = new.pesanan_id;
  if v_pesanan.id is null then
    raise exception 'Pesanan tidak ditemukan.';
  end if;

  -- "Dapur sudah mulai" ditentukan dari DUA tanda: waktu kirim ke dapur DAN status
  -- pesanan. Memakai satu tanda saja rapuh: kalau salah satu lupa diisi (mis. RPC
  -- memajukan status tanpa mencatat waktunya), pembatalan bisa lolos tanpa PIN.
  v_tahap := case
               when v_pesanan.dikirim_ke_dapur_pada is not null then 'sesudah_dapur'
               else 'sebelum_dapur'
             end;
  if v_tahap = 'sebelum_dapur' then
    select p.status into v_status from public.pesanan p where p.id = new.pesanan_id;
    if v_status in ('dimasak', 'siap', 'lunas') then
      v_tahap := 'sesudah_dapur';
    end if;
  end if;
  if new.tahap <> v_tahap then
    raise exception 'Tahap pembatalan tidak sesuai keadaan pesanan (seharusnya %).', v_tahap;
  end if;

  -- Setelah dapur mulai: wajib disetujui pengguna berizin (PIN atasan).
  if new.tahap = 'sesudah_dapur' then
    if new.disetujui_oleh is null then
      raise exception 'Pembatalan setelah dapur mulai wajib disetujui pengguna berizin (PIN).';
    end if;
    if not public.boleh_untuk(new.disetujui_oleh, 'void_sesudah_dapur') then
      raise exception 'Penyetuju itu tidak berizin menyetujui pembatalan setelah dapur mulai.';
    end if;
  else
    if not public.boleh('void_sebelum_dapur') then
      raise exception 'Anda tidak berizin membatalkan pesanan sebelum dapur mulai.';
    end if;
  end if;

  -- Nilai kerugian dari SALINAN HARGA (bukan harga menu sekarang).
  if new.pesanan_item_id is not null then
    select pi.pesanan_id, pi.subtotal into v_item
      from public.pesanan_item pi where pi.id = new.pesanan_item_id;
    if v_item.pesanan_id is null or v_item.pesanan_id <> new.pesanan_id then
      raise exception 'Baris item itu bukan milik pesanan ini.';
    end if;
    v_nilai := coalesce(v_item.subtotal, 0);
  else
    v_nilai := coalesce(
      nullif(v_pesanan.subtotal, 0),
      (select coalesce(sum(pi.subtotal), 0)::integer from public.pesanan_item pi where pi.pesanan_id = new.pesanan_id)
    );
  end if;

  if new.nilai_kerugian = 0 then
    new.nilai_kerugian := coalesce(v_nilai, 0);
  end if;

  if new.pelaku_id is null then
    new.pelaku_id := auth.uid();
  end if;
  -- Jejak pelaku tidak boleh dikarang klien (temuan audit AUD-3 K-2, 2026-09-17).
  if auth.uid() is not null and new.pelaku_id is distinct from auth.uid() then
    raise exception 'Pelaku pembatalan diisi sistem — tidak boleh menyebut orang lain.';
  end if;
  return new;
end
$$;

drop trigger if exists pembatalan_sah on public.pembatalan;
create trigger pembatalan_sah
  before insert on public.pembatalan
  for each row execute function public.picu_pembatalan_sah();

-- ===================================== KEBIJAKAN (RLS) =====================
create policy metode_bayar_pilih on public.metode_bayar
  for select to authenticated using (penyewa_id = public.penyewa_saya());

create policy metode_bayar_ubah on public.metode_bayar
  for all to authenticated
  using (penyewa_id = public.penyewa_saya() and public.peran_saya() in ('owner_pusat', 'admin_cabang'))
  with check (penyewa_id = public.penyewa_saya() and public.peran_saya() in ('owner_pusat', 'admin_cabang'));

create policy pembayaran_pilih on public.pembayaran
  for select to authenticated using (public.pesanan_sepenyewa(pesanan_id));

create policy pembayaran_tambah on public.pembayaran
  for insert to authenticated
  with check (
    public.pesanan_sepenyewa(pesanan_id)
    and public.peran_saya() in ('owner_pusat', 'admin_cabang', 'kasir')
  );

create policy diskon_transaksi_pilih on public.diskon_transaksi
  for select to authenticated using (public.pesanan_sepenyewa(pesanan_id));

create policy diskon_transaksi_tambah on public.diskon_transaksi
  for insert to authenticated
  with check (
    public.pesanan_sepenyewa(pesanan_id)
    and public.peran_saya() in ('owner_pusat', 'admin_cabang', 'kasir')
  );

create policy pembatalan_pilih on public.pembatalan
  for select to authenticated using (public.pesanan_sepenyewa(pesanan_id));

create policy pembatalan_tambah on public.pembatalan
  for insert to authenticated
  with check (
    public.pesanan_sepenyewa(pesanan_id)
    and public.peran_saya() in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan')
  );

-- =================================== HAK TINGKAT TABEL =====================
grant select on public.metode_bayar, public.pembayaran, public.diskon_transaksi, public.pembatalan to anon;
grant select, insert on public.pembayaran, public.diskon_transaksi, public.pembatalan to authenticated;
grant select, insert, update, delete on public.metode_bayar to authenticated;
grant select, insert, update, delete on public.metode_bayar, public.pembayaran,
     public.diskon_transaksi, public.pembatalan to service_role;

revoke all on function public.peran_peladen() from public;
grant execute on function public.peran_peladen() to authenticated, service_role;

revoke all on function public.total_dibayar(uuid) from public;
grant execute on function public.total_dibayar(uuid) to authenticated, service_role;
revoke all on function public.pasang_metode_bayar_bawaan(uuid) from public;
grant execute on function public.pasang_metode_bayar_bawaan(uuid) to service_role;
