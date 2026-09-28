-- ============================================================================
-- Migrasi 0052: Laporan Penjualan Dasar (Kategori, Metode Bayar, Tren Harian)
-- Tugas: T7-08 (PRD M8 — Dari mana uang datang)
--
-- Menyediakan:
--  1. View public.laporan_penjualan_harian (security_invoker = true)
--     Rekapitulasi penjualan per cabang per tanggal.
--  2. RPC public.laporan_penjualan(p_cabang_id, p_tanggal_mulai, p_tanggal_akhir)
--     Menghitung omzet per kategori menu, jenis menu, rincian metode bayar,
--     dan tren harian lengkap dalam rentang tanggal (maks 90 hari).
--     Dapat dilihat per cabang atau agregasi seluruh cabang untuk owner.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. View Rekapitulasi Penjualan Harian (security_invoker = true)
-- ---------------------------------------------------------------------------
create or replace view public.laporan_penjualan_harian
with (security_invoker = true) as
select
  p.penyewa_id,
  p.cabang_id,
  c.nama                                  as nama_cabang,
  p.tanggal,
  count(distinct p.id)::integer           as jumlah_transaksi,
  coalesce(sum(p.subtotal), 0)::integer   as total_subtotal,
  coalesce(sum(p.pajak), 0)::integer      as total_pajak,
  coalesce(sum(p.service), 0)::integer    as total_service,
  coalesce(sum(coalesce(p.total_diskon, 0)), 0)::integer as total_diskon,
  coalesce(sum(p.total), 0)::integer      as total_omzet
from public.pesanan p
join public.cabang c on c.id = p.cabang_id
where p.status = 'lunas'
group by p.penyewa_id, p.cabang_id, c.nama, p.tanggal;

comment on view public.laporan_penjualan_harian is
  'T7-08: Rekapitulasi omzet penjualan lunas per cabang per tanggal. security_invoker = true.';

revoke all on table public.laporan_penjualan_harian from public, anon;
grant select on table public.laporan_penjualan_harian to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 2. RPC public.laporan_penjualan
-- ---------------------------------------------------------------------------
create or replace function public.laporan_penjualan(
  p_cabang_id      uuid default null,
  p_tanggal_mulai  date default null,
  p_tanggal_akhir  date default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa            uuid;
  v_tanggal_akhir      date;
  v_tanggal_mulai      date;
  v_nama_cabang        text := 'Semua Cabang';
  v_total_omzet        integer := 0;
  v_total_subtotal     integer := 0;
  v_total_pajak        integer := 0;
  v_total_service      integer := 0;
  v_total_diskon       integer := 0;
  v_total_transaksi    integer := 0;
  v_rata_rata          integer := 0;
  v_omzet_makanan      integer := 0;
  v_omzet_minuman      integer := 0;
  v_omzet_lainnya      integer := 0;
  v_kategori_json      jsonb := '[]'::jsonb;
  v_metode_json        jsonb := '[]'::jsonb;
  v_tren_json          jsonb := '[]'::jsonb;
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
    raise exception 'Anda tidak berwenang melihat laporan penjualan.';
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
    raise exception 'Rentang tanggal laporan penjualan maksimal 90 hari.';
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
      -- Ambil cabang tunggal yang dipantau
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

  -- 1. Hitung Ringkasan Penjualan Lunas
  select
    coalesce(count(distinct p.id), 0),
    coalesce(sum(p.subtotal), 0),
    coalesce(sum(p.pajak), 0),
    coalesce(sum(p.service), 0),
    coalesce(sum(coalesce(p.total_diskon, 0)), 0),
    coalesce(sum(p.total), 0)
  into
    v_total_transaksi,
    v_total_subtotal,
    v_total_pajak,
    v_total_service,
    v_total_diskon,
    v_total_omzet
  from public.pesanan p
  where p.penyewa_id = v_penyewa
    and p.status = 'lunas'
    and p.tanggal between v_tanggal_mulai and v_tanggal_akhir
    and (p_cabang_id is null or p.cabang_id = p_cabang_id);

  if v_total_transaksi > 0 then
    v_rata_rata := round(v_total_omzet::numeric / v_total_transaksi);
  else
    v_rata_rata := 0;
  end if;

  -- 2. Hitung Omzet Berdasarkan Jenis Menu (makanan, minuman, lainnya)
  select
    coalesce(sum(case when coalesce(mi.jenis, 'lainnya') = 'makanan' then pi.subtotal else 0 end), 0),
    coalesce(sum(case when coalesce(mi.jenis, 'lainnya') = 'minuman' then pi.subtotal else 0 end), 0),
    coalesce(sum(case when coalesce(mi.jenis, 'lainnya') not in ('makanan', 'minuman') then pi.subtotal else 0 end), 0)
  into
    v_omzet_makanan,
    v_omzet_minuman,
    v_omzet_lainnya
  from public.pesanan_item pi
  join public.pesanan p on p.id = pi.pesanan_id
  left join public.menu_item mi on mi.id = pi.menu_item_id
  where p.penyewa_id = v_penyewa
    and p.status = 'lunas'
    and p.tanggal between v_tanggal_mulai and v_tanggal_akhir
    and (p_cabang_id is null or p.cabang_id = p_cabang_id);

  -- 3. Hitung Omzet per Kategori Menu
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'kategori_id', t.kategori_id,
      'kategori_nama', t.kategori_nama,
      'qty_terjual', t.qty_terjual,
      'total_omzet', t.total_omzet,
      'persentase', case
        when v_total_subtotal > 0 then round((t.total_omzet::numeric * 100.0 / v_total_subtotal), 1)
        else 0
      end
    ) order by t.total_omzet desc, t.kategori_nama asc
  ), '[]'::jsonb) into v_kategori_json
  from (
    select
      km.id as kategori_id,
      coalesce(km.nama, 'Tanpa Kategori') as kategori_nama,
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
    group by km.id, km.nama
  ) t;

  -- 4. Hitung Rincian per Metode Bayar
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'metode_id', t.metode_id,
      'metode_nama', t.metode_nama,
      'jenis', t.jenis,
      'jumlah_transaksi', t.jumlah_transaksi,
      'total_nominal', t.total_nominal,
      'persentase', case
        when v_total_omzet > 0 then round((t.total_nominal::numeric * 100.0 / v_total_omzet), 1)
        else 0
      end
    ) order by t.total_nominal desc, t.metode_nama asc
  ), '[]'::jsonb) into v_metode_json
  from (
    select
      pb.metode_id,
      pb.metode_nama_saat_itu as metode_nama,
      pb.jenis_saat_itu as jenis,
      count(pb.id)::integer as jumlah_transaksi,
      sum(pb.jumlah)::integer as total_nominal
    from public.pembayaran pb
    join public.pesanan p on p.id = pb.pesanan_id
    where p.penyewa_id = v_penyewa
      and p.status = 'lunas'
      and p.tanggal between v_tanggal_mulai and v_tanggal_akhir
      and (p_cabang_id is null or p.cabang_id = p_cabang_id)
    group by pb.metode_id, pb.metode_nama_saat_itu, pb.jenis_saat_itu
  ) t;

  -- 5. Hitung Tren Penjualan Harian
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'tanggal', to_char(t.tgl, 'YYYY-MM-DD'),
      'jumlah_transaksi', coalesce(tr.jumlah_transaksi, 0),
      'omzet_makanan', coalesce(tr.omzet_makanan, 0),
      'omzet_minuman', coalesce(tr.omzet_minuman, 0),
      'omzet_lainnya', coalesce(tr.omzet_lainnya, 0),
      'total_diskon', coalesce(tr.total_diskon, 0),
      'total_omzet', coalesce(tr.total_omzet, 0)
    ) order by t.tgl asc
  ), '[]'::jsonb) into v_tren_json
  from (
    select generate_series(v_tanggal_mulai::timestamp, v_tanggal_akhir::timestamp, '1 day'::interval)::date as tgl
  ) t
  left join (
    select
      p.tanggal,
      count(distinct p.id)::integer as jumlah_transaksi,
      coalesce(sum(case when mi.jenis = 'makanan' then pi.subtotal else 0 end), 0)::integer as omzet_makanan,
      coalesce(sum(case when mi.jenis = 'minuman' then pi.subtotal else 0 end), 0)::integer as omzet_minuman,
      coalesce(sum(case when coalesce(mi.jenis, 'lainnya') not in ('makanan', 'minuman') then pi.subtotal else 0 end), 0)::integer as omzet_lainnya,
      coalesce(p_agg.total_diskon, 0)::integer as total_diskon,
      coalesce(p_agg.total_omzet, 0)::integer as total_omzet
    from public.pesanan p
    left join (
      select
        tanggal,
        sum(coalesce(total_diskon, 0)) as total_diskon,
        sum(total) as total_omzet
      from public.pesanan
      where penyewa_id = v_penyewa
        and status = 'lunas'
        and tanggal between v_tanggal_mulai and v_tanggal_akhir
        and (p_cabang_id is null or cabang_id = p_cabang_id)
      group by tanggal
    ) p_agg on p_agg.tanggal = p.tanggal
    left join public.pesanan_item pi on pi.pesanan_id = p.id
    left join public.menu_item mi on mi.id = pi.menu_item_id
    where p.penyewa_id = v_penyewa
      and p.status = 'lunas'
      and p.tanggal between v_tanggal_mulai and v_tanggal_akhir
      and (p_cabang_id is null or p.cabang_id = p_cabang_id)
    group by p.tanggal, p_agg.total_diskon, p_agg.total_omzet
  ) tr on tr.tanggal = t.tgl;

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'LPJ-200',
    'pesan', 'Laporan penjualan berhasil dimuat.',
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
        'total_omzet', v_total_omzet,
        'total_subtotal', v_total_subtotal,
        'total_pajak', v_total_pajak,
        'total_service', v_total_service,
        'total_diskon', v_total_diskon,
        'total_transaksi', v_total_transaksi,
        'rata_rata_transaksi', v_rata_rata
      ),
      'jenis_menu', jsonb_build_object(
        'omzet_makanan', v_omzet_makanan,
        'omzet_minuman', v_omzet_minuman,
        'omzet_lainnya', v_omzet_lainnya
      ),
      'per_kategori', v_kategori_json,
      'per_metode', v_metode_json,
      'tren_harian', v_tren_json
    )
  );
end;
$$;

comment on function public.laporan_penjualan(uuid, date, date) is
  'T7-08: Laporan penjualan dasar komprehensif (omzet kategori, metode bayar, tren harian).';

revoke all on function public.laporan_penjualan(uuid, date, date) from public, anon;
grant execute on function public.laporan_penjualan(uuid, date, date) to authenticated, service_role;
