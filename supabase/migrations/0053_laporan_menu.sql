-- ============================================================================
-- Migrasi 0053: Laporan Menu Terlaris & Diskon / Voucher Terpakai
-- Tugas: T7-09 (PRD M8 & M10 — Menu andalan & biaya promosi)
--
-- Menyediakan:
--  1. View public.laporan_menu_terlaris (security_invoker = true)
--     Rekapitulasi porsi & omzet per menu per cabang per tanggal.
--  2. RPC public.laporan_menu(p_cabang_id, p_tanggal_mulai, p_tanggal_akhir, p_urut_berdasarkan)
--     Peringkat menu terlaris (jumlah & nilai) berbasis nama_saat_itu (kebal perubahan menu),
--     daftar diskon manual (alasan, nilai, kasir pemberi, penyetuju),
--     dan daftar voucher terpakai (kode, nilai, kasir, waktu).
--     Dapat dilihat per cabang atau gabungan seluruh cabang untuk owner.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. View Rekapitulasi Menu Terlaris (security_invoker = true)
-- ---------------------------------------------------------------------------
create or replace view public.laporan_menu_terlaris
with (security_invoker = true) as
select
  p.penyewa_id,
  p.cabang_id,
  c.nama                                          as nama_cabang,
  p.tanggal,
  coalesce(pi.nama_saat_itu, mi.nama, 'Menu')     as nama_menu,
  coalesce(mi.jenis, 'lainnya')                   as jenis,
  km.nama                                         as nama_kategori,
  sum(pi.qty)::integer                            as qty_terjual,
  sum(pi.subtotal)::integer                       as total_omzet
from public.pesanan_item pi
join public.pesanan p on p.id = pi.pesanan_id
join public.cabang c on c.id = p.cabang_id
left join public.menu_item mi on mi.id = pi.menu_item_id
left join public.kategori_menu km on km.id = mi.kategori_id
where p.status = 'lunas'
group by
  p.penyewa_id,
  p.cabang_id,
  c.nama,
  p.tanggal,
  coalesce(pi.nama_saat_itu, mi.nama, 'Menu'),
  coalesce(mi.jenis, 'lainnya'),
  km.nama;

comment on view public.laporan_menu_terlaris is
  'T7-09: Rekapitulasi penjualan per menu per cabang per tanggal. security_invoker = true.';

revoke all on table public.laporan_menu_terlaris from public, anon;
grant select on table public.laporan_menu_terlaris to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 2. RPC public.laporan_menu
-- ---------------------------------------------------------------------------
create or replace function public.laporan_menu(
  p_cabang_id         uuid default null,
  p_tanggal_mulai     date default null,
  p_tanggal_akhir     date default null,
  p_urut_berdasarkan  text default 'nilai'
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa               uuid;
  v_tanggal_akhir         date;
  v_tanggal_mulai         date;
  v_nama_cabang           text := 'Semua Cabang';
  v_total_porsi           integer := 0;
  v_total_omzet_menu      integer := 0;
  v_total_diskon_manual   integer := 0;
  v_total_voucher         integer := 0;
  v_menu_json             jsonb := '[]'::jsonb;
  v_diskon_manual_json    jsonb := '[]'::jsonb;
  v_voucher_json          jsonb := '[]'::jsonb;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Identitas penyewa Anda tidak ditemukan.';
  end if;

  -- Wajib izin lihat_laporan (owner_pusat, admin_cabang)
  if not public.boleh('lihat_laporan') then
    raise exception 'Anda tidak berwenang melihat laporan menu.';
  end if;

  -- Tentukan rentang tanggal default (7 hari terakhir)
  v_tanggal_akhir := coalesce(p_tanggal_akhir, current_date);
  v_tanggal_mulai := coalesce(p_tanggal_mulai, v_tanggal_akhir - 6);

  -- Validasi urutan rentang tanggal
  if v_tanggal_akhir < v_tanggal_mulai then
    raise exception 'Tanggal akhir tidak boleh lebih awal dari tanggal mulai.';
  end if;

  -- Validasi batas maksimal rentang tanggal (maks 90 hari)
  if (v_tanggal_akhir - v_tanggal_mulai) > 90 then
    raise exception 'Rentang tanggal laporan menu maksimal 90 hari.';
  end if;

  -- Verifikasi cabang jika ditentukan
  if p_cabang_id is not null then
    select nama into v_nama_cabang
      from public.cabang
     where id = p_cabang_id
       and penyewa_id = v_penyewa;

    if v_nama_cabang is null then
      raise exception 'Cabang tidak ditemukan.';
    end if;

    if not public.cabang_pantau_saya(p_cabang_id) then
      raise exception 'Cabang di luar wewenang pantauan Anda.';
    end if;
  else
    -- Bila p_cabang_id null dan bukan owner_pusat, pengguna hanya boleh melihat cabangnya sendiri
    if public.peran_saya() <> 'owner_pusat' then
      select c.id, c.nama into p_cabang_id, v_nama_cabang
        from public.cabang c
       where c.penyewa_id = v_penyewa
         and public.cabang_pantau_saya(c.id)
       limit 1;

      if p_cabang_id is null then
        raise exception 'Cabang tidak ditemukan.';
      end if;
    end if;
  end if;

  -- 1. Hitung Total Akumulasi Menu Terjual
  select
    coalesce(sum(pi.qty), 0)::integer,
    coalesce(sum(pi.subtotal), 0)::integer
  into
    v_total_porsi,
    v_total_omzet_menu
  from public.pesanan_item pi
  join public.pesanan p on p.id = pi.pesanan_id
  where p.penyewa_id = v_penyewa
    and p.status = 'lunas'
    and p.tanggal between v_tanggal_mulai and v_tanggal_akhir
    and (p_cabang_id is null or p.cabang_id = p_cabang_id);

  -- 2. Peringkat Menu Terlaris (menggunakan nama_saat_itu agar kebal perubahan katalog)
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'menu_item_id', m.menu_item_id,
      'nama_menu', m.nama_menu,
      'kategori_nama', m.kategori_nama,
      'jenis', m.jenis,
      'qty_terjual', m.qty_terjual,
      'total_omzet', m.total_omzet,
      'rata_harga', case when m.qty_terjual > 0 then round(m.total_omzet::numeric / m.qty_terjual) else 0 end,
      'persentase', case
        when v_total_omzet_menu > 0 then round((m.total_omzet::numeric * 100.0 / v_total_omzet_menu), 1)
        else 0
      end
    )
  ), '[]'::jsonb) into v_menu_json
  from (
    select
      pi.menu_item_id,
      coalesce(pi.nama_saat_itu, mi.nama, 'Menu') as nama_menu,
      coalesce(km.nama, 'Tanpa Kategori') as kategori_nama,
      coalesce(mi.jenis, 'lainnya') as jenis,
      sum(pi.qty)::integer as qty_terjual,
      sum(pi.subtotal)::integer as total_omzet
    from public.pesanan_item pi
    join public.pesanan p on p.id = pi.pesanan_id
    left join public.menu_item mi on mi.id = pi.menu_item_id
    left join public.kategori_menu km on km.id = mi.kategori_id
    where p.penyewa_id = v_penyewa
      and p.status = 'lunas'
      and p.tanggal between v_tanggal_mulai and v_tanggal_akhir
      and (p_cabang_id is null or p.cabang_id = p_cabang_id)
    group by pi.menu_item_id, coalesce(pi.nama_saat_itu, mi.nama, 'Menu'), km.nama, mi.jenis
    order by
      case when p_urut_berdasarkan = 'jumlah' then sum(pi.qty) else sum(pi.subtotal) end desc,
      coalesce(pi.nama_saat_itu, mi.nama, 'Menu') asc
  ) m;

  -- 3. Daftar Diskon Manual Terpakai (beserta nama kasir & penyetuju atasan)
  select
    coalesce(sum(dt.nilai), 0)::integer,
    coalesce(jsonb_agg(
      jsonb_build_object(
        'id', dt.id,
        'pesanan_id', dt.pesanan_id,
        'nomor_pesanan', p.nomor,
        'tanggal', to_char(p.tanggal, 'YYYY-MM-DD'),
        'waktu', to_char(dt.waktu, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        'persen', dt.persen,
        'nominal', dt.nominal,
        'nilai', dt.nilai,
        'alasan', dt.alasan,
        'pelaku_id', dt.pelaku_id,
        'kasir_nama', pk.nama,
        'penyetuju_id', dt.disetujui_oleh,
        'penyetuju_nama', pa.nama
      ) order by dt.waktu desc
    ), '[]'::jsonb)
  into
    v_total_diskon_manual,
    v_diskon_manual_json
  from public.diskon_transaksi dt
  join public.pesanan p on p.id = dt.pesanan_id
  left join public.pengguna pk on pk.id = dt.pelaku_id
  left join public.pengguna pa on pa.id = dt.disetujui_oleh
  where p.penyewa_id = v_penyewa
    and p.status = 'lunas'
    and dt.jenis = 'manual'
    and p.tanggal between v_tanggal_mulai and v_tanggal_akhir
    and (p_cabang_id is null or p.cabang_id = p_cabang_id);

  -- 4. Daftar Voucher / Promo Terpakai
  select
    coalesce(sum(dt.nilai), 0)::integer,
    coalesce(jsonb_agg(
      jsonb_build_object(
        'id', dt.id,
        'pesanan_id', dt.pesanan_id,
        'nomor_pesanan', p.nomor,
        'tanggal', to_char(p.tanggal, 'YYYY-MM-DD'),
        'waktu', to_char(dt.waktu, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        'kode_voucher', coalesce(dt.alasan, 'PROMO'),
        'nilai', dt.nilai,
        'pelaku_id', dt.pelaku_id,
        'kasir_nama', pk.nama,
        'penyetuju_id', dt.disetujui_oleh,
        'penyetuju_nama', pa.nama
      ) order by dt.waktu desc
    ), '[]'::jsonb)
  into
    v_total_voucher,
    v_voucher_json
  from public.diskon_transaksi dt
  join public.pesanan p on p.id = dt.pesanan_id
  left join public.pengguna pk on pk.id = dt.pelaku_id
  left join public.pengguna pa on pa.id = dt.disetujui_oleh
  where p.penyewa_id = v_penyewa
    and p.status = 'lunas'
    and dt.jenis in ('voucher', 'promo')
    and p.tanggal between v_tanggal_mulai and v_tanggal_akhir
    and (p_cabang_id is null or p.cabang_id = p_cabang_id);

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'LPM-200',
    'pesan', 'Laporan menu & promosi berhasil dimuat.',
    'data', jsonb_build_object(
      'rentang', jsonb_build_object(
        'tanggal_mulai', to_char(v_tanggal_mulai, 'YYYY-MM-DD'),
        'tanggal_akhir', to_char(v_tanggal_akhir, 'YYYY-MM-DD'),
        'jumlah_hari', (v_tanggal_akhir - v_tanggal_mulai + 1)
      ),
      'cabang', jsonb_build_object(
        'id', p_cabang_id,
        'nama', v_nama_cabang
      ),
      'ringkasan', jsonb_build_object(
        'total_porsi', v_total_porsi,
        'total_omzet_menu', v_total_omzet_menu,
        'total_diskon_manual', v_total_diskon_manual,
        'total_voucher', v_total_voucher,
        'total_biaya_promosi', (v_total_diskon_manual + v_total_voucher)
      ),
      'peringkat_menu', v_menu_json,
      'diskon_manual', v_diskon_manual_json,
      'voucher_terpakai', v_voucher_json
    )
  );
end;
$$;

comment on function public.laporan_menu(uuid, date, date, text) is
  'T7-09: Laporan menu terlaris (jumlah & nilai) dan rincian diskon manual / voucher terpakai.';

revoke all on function public.laporan_menu(uuid, date, date, text) from public, anon;
grant execute on function public.laporan_menu(uuid, date, date, text) to authenticated, service_role;
