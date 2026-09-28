-- ============================================================================
-- 0005 — Izin berjenjang: kamus izin, izin bawaan per peran, dan gerbang boleh()
--
-- ART-2: "Sumber kebenaran izin: tabel izin (+ pengguna_cabang). Jangan menebak
-- dari peran saja." Karena itu izin disimpan di DUA tingkat:
--   * `izin`        (dari 0002) = centang KHUSUS per pegawai  → menang bila ada
--   * `izin_peran`  (baru)      = bawaan per PERAN per resto → dipakai bila
--                                 pegawai itu tidak dicentang khusus
-- Hasil akhirnya dihitung SATU fungsi: `izin_efektif(aksi, cabang)`, dan semua
-- RPC memakai gerbang `boleh(...)`. Tidak ada rumus izin kedua di tempat lain.
--
-- Bila pegawai tidak punya centang khusus DAN perannya tidak punya bawaan →
-- TOLAK (deny by default). Pegawai yang dinonaktifkan tidak boleh apa pun.
-- ============================================================================

-- ---------------------------------------------------- kamus kode izin resmi
create table if not exists public.izin_kode (
  kode_izin  text primary key,
  keterangan text not null,
  kelompok   text not null check (kelompok in (
               'harga', 'diskon', 'void', 'laporan', 'pegawai', 'pengaturan',
               'voucher', 'kas', 'stok'
             ))
);

comment on table public.izin_kode is
  'Daftar resmi 10 kode izin (TECH_SPEC §4.1). Menambah izin baru = migrasi baru + baris di sini + uji.';

alter table public.izin_kode enable row level security;

insert into public.izin_kode (kode_izin, keterangan, kelompok) values
  ('ubah_harga',         'Mengubah harga menu pada saat transaksi',                    'harga'),
  ('beri_diskon',        'Memberi diskon (dibatasi nominal dan persen)',               'diskon'),
  ('void_sebelum_dapur', 'Membatalkan pesanan SEBELUM dapur mulai memasak',            'void'),
  ('void_sesudah_dapur', 'Membatalkan/menyetujui pembatalan SESUDAH dapur mulai',      'void'),
  ('lihat_laporan',      'Melihat laporan penjualan, kas, dan laba',                   'laporan'),
  ('kelola_pegawai',     'Menambah/mengubah pegawai, peran, dan centang izin',         'pegawai'),
  ('atur_pengaturan',    'Mengubah pengaturan resto (pajak, service, pembulatan, tema)', 'pengaturan'),
  ('pakai_voucher',      'Memakai/mencairkan voucher pelanggan',                        'voucher'),
  ('tutup_kas',          'Menutup shift kasir',                                        'kas'),
  ('ubah_stok',          'Mengubah stok bahan dan penanda menu habis',                 'stok')
on conflict (kode_izin) do nothing;

-- Kunci `izin` ke kamus resmi (tabel 0002 sudah punya CHECK; ini pengikat tambahan
-- supaya kode izin yang tidak dikenal ditolak di tingkat kunci asing).
alter table public.izin
  drop constraint if exists izin_kode_izin_fkey;
alter table public.izin
  add constraint izin_kode_izin_fkey foreign key (kode_izin)
    references public.izin_kode (kode_izin) on update cascade;

-- --------------------------------------------- izin bawaan per peran/resto
create table if not exists public.izin_peran (
  penyewa_id    uuid not null references public.penyewa (id) on delete cascade,
  peran         text not null check (peran in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan', 'dapur')),
  kode_izin     text not null references public.izin_kode (kode_izin) on update cascade,
  boleh         boolean not null default false,
  batas_nominal integer check (batas_nominal is null or batas_nominal >= 0),
  batas_persen  numeric(5, 2) check (batas_persen is null or (batas_persen >= 0 and batas_persen <= 100)),
  primary key (penyewa_id, peran, kode_izin)
);

comment on table public.izin_peran is
  'Izin bawaan tiap peran, per resto. Dipakai bila pegawai tidak punya centang khusus di tabel izin.';

alter table public.izin_peran enable row level security;

-- ------------------------------------- pemasangan izin bawaan (resto baru)
create or replace function public.pasang_izin_peran_bawaan(p_penyewa_id uuid)
returns void
language sql
security definer
set search_path = public, pg_temp
as $$
  insert into public.izin_peran (penyewa_id, peran, kode_izin, boleh, batas_nominal, batas_persen)
  select p_penyewa_id, b.peran, b.kode_izin, b.boleh, b.batas_nominal, b.batas_persen
    from (values
      -- Owner pusat: boleh semuanya.
      ('owner_pusat', 'ubah_harga',         true,  null,   null),
      ('owner_pusat', 'beri_diskon',        true,  null,   null),
      ('owner_pusat', 'void_sebelum_dapur', true,  null,   null),
      ('owner_pusat', 'void_sesudah_dapur', true,  null,   null),
      ('owner_pusat', 'lihat_laporan',      true,  null,   null),
      ('owner_pusat', 'kelola_pegawai',     true,  null,   null),
      ('owner_pusat', 'atur_pengaturan',    true,  null,   null),
      ('owner_pusat', 'pakai_voucher',      true,  null,   null),
      ('owner_pusat', 'tutup_kas',          true,  null,   null),
      ('owner_pusat', 'ubah_stok',          true,  null,   null),
      -- Admin cabang: mengurus operasi harian; pengaturan & laporan penuh bukan miliknya.
      ('admin_cabang', 'ubah_harga',         true,  null,   null),
      ('admin_cabang', 'beri_diskon',        true,  50000,  10),
      ('admin_cabang', 'void_sebelum_dapur', true,  null,   null),
      ('admin_cabang', 'void_sesudah_dapur', true,  null,   null),
      ('admin_cabang', 'lihat_laporan',      true,  null,   null),
      ('admin_cabang', 'kelola_pegawai',     true,  null,   null),
      ('admin_cabang', 'atur_pengaturan',    false, null,   null),
      ('admin_cabang', 'pakai_voucher',      true,  null,   null),
      ('admin_cabang', 'tutup_kas',          true,  null,   null),
      ('admin_cabang', 'ubah_stok',          true,  null,   null),
      -- Kasir: jual, diskon kecil, batal sebelum dapur, tutup kas.
      ('kasir', 'ubah_harga',         false, null,   null),
      ('kasir', 'beri_diskon',        true,  25000,  5),
      ('kasir', 'void_sebelum_dapur', true,  null,   null),
      ('kasir', 'void_sesudah_dapur', false, null,   null),
      ('kasir', 'lihat_laporan',      false, null,   null),
      ('kasir', 'kelola_pegawai',     false, null,   null),
      ('kasir', 'atur_pengaturan',    false, null,   null),
      ('kasir', 'pakai_voucher',      true,  null,   null),
      ('kasir', 'tutup_kas',          true,  null,   null),
      ('kasir', 'ubah_stok',          false, null,   null),
      -- Pelayan: melayani & memakai voucher.
      ('pelayan', 'ubah_harga',         false, null, null),
      ('pelayan', 'beri_diskon',        false, null, null),
      ('pelayan', 'void_sebelum_dapur', false, null, null),
      ('pelayan', 'void_sesudah_dapur', false, null, null),
      ('pelayan', 'lihat_laporan',      false, null, null),
      ('pelayan', 'kelola_pegawai',     false, null, null),
      ('pelayan', 'atur_pengaturan',    false, null, null),
      ('pelayan', 'pakai_voucher',      true,  null, null),
      ('pelayan', 'tutup_kas',          false, null, null),
      ('pelayan', 'ubah_stok',          false, null, null),
      -- Dapur: hanya stok.
      ('dapur', 'ubah_harga',         false, null, null),
      ('dapur', 'beri_diskon',        false, null, null),
      ('dapur', 'void_sebelum_dapur', false, null, null),
      ('dapur', 'void_sesudah_dapur', false, null, null),
      ('dapur', 'lihat_laporan',      false, null, null),
      ('dapur', 'kelola_pegawai',     false, null, null),
      ('dapur', 'atur_pengaturan',    false, null, null),
      ('dapur', 'pakai_voucher',      false, null, null),
      ('dapur', 'tutup_kas',          false, null, null),
      ('dapur', 'ubah_stok',          true,  null, null)
    ) as b(peran, kode_izin, boleh, batas_nominal, batas_persen)
  on conflict (penyewa_id, peran, kode_izin) do nothing
$$;

comment on function public.pasang_izin_peran_bawaan(uuid) is
  'Memasang 50 baris izin bawaan (5 peran × 10 izin) untuk satu resto. Dipakai saat resto baru dibuat dan untuk resto yang sudah ada.';

-- Resto baru otomatis mendapat izin bawaan (tidak pernah kosong = tidak "semua tertutup").
create or replace function public.picu_izin_peran_bawaan()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.pasang_izin_peran_bawaan(new.id);
  return new;
end
$$;

drop trigger if exists penyewa_pasang_izin_bawaan on public.penyewa;
create trigger penyewa_pasang_izin_bawaan
  after insert on public.penyewa
  for each row execute function public.picu_izin_peran_bawaan();

-- Resto yang sudah ada sebelum migrasi ini.
select public.pasang_izin_peran_bawaan(id) from public.penyewa;

-- ================================================== gerbang tunggal: boleh()
-- Peran yang dipakai = peran DI CABANG itu bila cabang diberikan (pegawai
-- merangkap cabang bisa beda peran per cabang), kalau tidak → peran se-resto.
-- Cabang yang bukan milik pengguna = TOLAK, bukan jatuh ke peran se-resto.
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

  if p_cabang_id is not null then
    select pc.peran
      into v_peran
      from public.pengguna_cabang pc
     where pc.pengguna_id = auth.uid()
       and pc.cabang_id = p_cabang_id
       and pc.aktif
     limit 1;
    if not found then
      -- pengguna.peran 'owner_pusat' tidak bertugas di cabang; kalau dia memang
      -- owner pusat resto ini, aksinya tetap dinilai dengan peran itu.
      if public.peran_saya() = 'owner_pusat' then
        v_peran := 'owner_pusat';
      else
        return query select false, null::integer, null::numeric;   -- cabang bukan miliknya
        return;
      end if;
    end if;
  else
    v_peran := public.peran_saya();
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
  'Izin yang benar-benar berlaku: centang khusus pegawai menang atas bawaan peran; tidak ada keduanya = tolak.';

-- Gerbang tindakan: boleh(aksi) · boleh(aksi, nominal) · boleh(aksi, nominal, persen)
create or replace function public.boleh(p_aksi text, p_cabang_id uuid default null)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select ie.boleh
    from public.izin_efektif(p_aksi, p_cabang_id) ie
$$;

create or replace function public.boleh(p_aksi text, p_nominal integer, p_cabang_id uuid default null)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select ie.boleh
     and (ie.batas_nominal is null or p_nominal <= ie.batas_nominal)
    from public.izin_efektif(p_aksi, p_cabang_id) ie
$$;

create or replace function public.boleh(p_aksi text, p_nominal integer, p_persen numeric, p_cabang_id uuid default null)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select ie.boleh
     and (ie.batas_nominal is null or p_nominal <= ie.batas_nominal)
     and (ie.batas_persen  is null or p_persen  <= ie.batas_persen)
    from public.izin_efektif(p_aksi, p_cabang_id) ie
$$;

comment on function public.boleh(text, uuid) is
  'Gerbang tunggal izin tindakan. Semua RPC wajib memeriksa lewat fungsi ini — bukan menyimpulkan sendiri dari peran.';

-- ==================================================== kebijakan tabel baru
create policy izin_kode_pilih on public.izin_kode
  for select to authenticated
  using (true);

create policy izin_peran_pilih on public.izin_peran
  for select to authenticated
  using (penyewa_id = public.penyewa_saya());

create policy izin_peran_ubah on public.izin_peran
  for update to authenticated
  using (penyewa_id = public.penyewa_saya() and public.peran_saya() = 'owner_pusat')
  with check (penyewa_id = public.penyewa_saya());

create policy izin_peran_tambah on public.izin_peran
  for insert to authenticated
  with check (penyewa_id = public.penyewa_saya() and public.peran_saya() = 'owner_pusat');

-- ================================================================== hak akses
grant select on public.izin_kode to anon, authenticated;
grant select on public.izin_peran to anon, authenticated;
grant insert, update on public.izin_peran to authenticated;
grant select, insert, update, delete on public.izin_kode to service_role;
grant select, insert, update, delete on public.izin_peran to service_role;

revoke all on function public.izin_efektif(text, uuid) from public;
revoke all on function public.boleh(text, uuid) from public;
revoke all on function public.boleh(text, integer, uuid) from public;
revoke all on function public.boleh(text, integer, numeric, uuid) from public;
revoke all on function public.pasang_izin_peran_bawaan(uuid) from public;

grant execute on function public.izin_efektif(text, uuid) to authenticated, service_role;
grant execute on function public.boleh(text, uuid) to authenticated, service_role;
grant execute on function public.boleh(text, integer, uuid) to authenticated, service_role;
grant execute on function public.boleh(text, integer, numeric, uuid) to authenticated, service_role;
grant execute on function public.pasang_izin_peran_bawaan(uuid) to service_role;
