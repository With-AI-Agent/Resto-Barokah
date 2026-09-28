-- G3 A-F02: jangan menganggap auth.uid() NULL sebagai bukti jalur peladen.
--
-- Di dalam SECURITY DEFINER, auth.uid() tetap mencerminkan pemanggil. Sesi
-- `authenticated` tanpa klaim sub dapat memiliki uid NULL, tetapi tetap dapat
-- memanggil RPC. Jalur peladen hanya mendapat pengecualian bila dua sinyal sesi
-- cocok: role PostgreSQL aktif = service_role DAN klaim JWT role = service_role.
-- Klaim role dibaca dari request.jwt.claims yang dipasang oleh lapisan autentikasi;
-- sinyal role aktif mencegah klaim service_role saja pada sesi authenticated.
-- Akses SQL superuser langsung tetap berada di luar batas kepercayaan API dan dapat
-- memalsukan sesi apa pun; itu bukan jalur browser/PostgREST.

create or replace function public.jalur_peladen_terverifikasi()
returns boolean
language sql
stable
set search_path = public, pg_temp
as $$
  select current_setting('role', true) = 'service_role'
     and coalesce(
           (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role'),
           ''
         ) = 'service_role'
$$;

revoke all on function public.jalur_peladen_terverifikasi() from public, anon, authenticated;
grant execute on function public.jalur_peladen_terverifikasi() to service_role;

comment on function public.jalur_peladen_terverifikasi() is
  'True hanya bila role sesi aktif dan klaim JWT sama-sama service_role; auth.uid NULL saja bukan bukti jalur peladen.';

-- ---------------------------------------------------------------------------
-- total_dibayar: RPC definer tetap melewati RLS, tetapi hanya mengembalikan
-- angka lintas penyewa untuk jalur peladen yang terverifikasi.
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
     and (
       public.pesanan_sepenyewa(pb.pesanan_id)
       or public.jalur_peladen_terverifikasi()
     )
$$;

revoke all on function public.total_dibayar(uuid) from public;
grant execute on function public.total_dibayar(uuid) to authenticated, service_role;

comment on function public.total_dibayar(uuid) is
  'Jumlah uang pembayaran. Klien hanya melihat pesanan sepenyewa; jalur tanpa identitas harus memiliki role sesi dan klaim JWT service_role yang cocok.';

-- ---------------------------------------------------------------------------
-- hitung_total: definisi efektif yang sama dengan 0015, dengan pagar identitas
-- diperketat. Semua aturan uang tetap satu fungsi; hanya pembeda akses yang berubah.
create or replace function public.hitung_total(p_pesanan_id uuid)
returns bigint
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_pesanan        record;
  v_subtotal       bigint;
  v_diskon         bigint;
  v_dasar          bigint;
  v_pajak          bigint;
  v_service        bigint;
  v_persen_pajak   numeric;
  v_persen_service numeric;
  v_pembulatan     text;
  v_langkah        bigint;
  v_total          bigint;
begin
  -- Kunci baris pesanan lebih dulu (anti saling-menimpa).
  select p.id, p.penyewa_id, p.subtotal, p.pajak, p.service, p.total_diskon, p.total, p.status
    into v_pesanan
    from public.pesanan p
   where p.id = p_pesanan_id
     for update;

  if v_pesanan.id is null then
    raise exception 'Pesanan tidak ditemukan.';
  end if;

    -- auth.uid() NULL bukan tanda kepercayaan. Hanya role+klaim service_role
  -- atau pemicu database yang sedang aktif (pg_trigger_depth() > 0) yang boleh
  -- melewati pagar penyewa untuk pekerjaan peladen.
  if pg_trigger_depth() = 0
     and not public.jalur_peladen_terverifikasi()
     and not public.pesanan_sepenyewa(p_pesanan_id) then
    raise exception 'Pesanan itu bukan milik resto Anda.';
  end if;

  -- Pesanan lunas/batal tidak boleh dihitung ulang dari perangkat. Pemicu resmi
  -- tetap boleh menghitung ulang ketika pg_trigger_depth() > 0.
  if auth.uid() is not null and pg_trigger_depth() = 0 and v_pesanan.status in ('lunas', 'batal') then
    raise exception 'Pesanan yang sudah % tidak boleh dihitung ulang dari perangkat — angka uang yang sudah tercatat hanya bisa dikoreksi lewat pembatalan/void resmi (berikut persetujuan PIN atasan bila dapur sudah mulai).', v_pesanan.status;
  end if;

  select coalesce(sum(pi.subtotal), 0) into v_subtotal
    from public.pesanan_item pi
   where pi.pesanan_id = p_pesanan_id
     and pi.status <> 'batal';

  select p.pajak_pb1_persen, p.service_persen, p.pembulatan
    into v_persen_pajak, v_persen_service, v_pembulatan
    from public.pengaturan p
   where p.penyewa_id = v_pesanan.penyewa_id;

  select coalesce(sum(d.nilai), 0) into v_diskon
    from public.diskon_transaksi d
   where d.pesanan_id = p_pesanan_id;

  v_dasar := greatest(v_subtotal - v_diskon, 0);
  v_pajak   := coalesce(round(v_dasar * coalesce(v_persen_pajak, 0) / 100), 0);
  v_service := coalesce(round(v_dasar * coalesce(v_persen_service, 0) / 100), 0);
  v_total := greatest(v_dasar + v_pajak + v_service, 0);

  v_langkah := case
                 when coalesce(v_pembulatan, 'none') = 'none' then 0
                 else v_pembulatan::bigint
               end;
  if v_langkah > 0 then
    v_total := (v_total / v_langkah) * v_langkah;
  end if;

  update public.pesanan p
     set subtotal     = v_subtotal::integer,
         pajak        = v_pajak::integer,
         service      = v_service::integer,
         total_diskon = least(v_diskon, v_subtotal)::integer,
         total        = v_total::integer
   where p.id = p_pesanan_id;

  return v_total;
end
$$;

revoke all on function public.hitung_total(uuid) from public;
grant execute on function public.hitung_total(uuid) to authenticated, service_role;

comment on function public.hitung_total(uuid) is
  'Satu-satunya penulis angka uang pesanan. Guard penyewa menolak identitas NULL kecuali role sesi + klaim JWT service_role cocok; pemicu resmi tetap berjalan.';
