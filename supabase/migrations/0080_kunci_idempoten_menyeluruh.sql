-- ============================================================================
-- 0080 — KUNCI IDEMPOTEN MENYELURUH DI SEMUA PENULISAN (T10-02 / ART-8)
--
-- TECH_SPEC §9 ART-8 & §13 K4:
-- "Semua penulisan dari antrean offline wajib membawa kunci_idempoten; peladen
-- menolak duplikat dengan anggun (balasan rekaman yang sudah ada, idempoten)."
--
-- Lingkup penulisan:
--   1. PESANAN: RPC `simpan_pesanan` menerima p_kunci_idempoten.
--   2. PEMBAYARAN: RPC `bayar_pesanan` (0060) telah menerima p_kunci_idempoten.
--   3. VOUCHER: RPC `pakai_voucher` (0067) telah menerima p_kunci_idempoten.
--   4. SHIFT KAS:
--      - Kolom `kunci_idempoten` pada tabel `shift_kas` (indeks unik parsial).
--      - Kolom `kunci_idempoten_tutup` pada tabel `shift_kas` (indeks unik parsial).
--      - RPC `buka_shift` (overload 4 argumen ber-kunci idempoten).
--      - RPC `tutup_shift` (overload 5 argumen ber-kunci idempoten).
--      - RPC `kas_pergerakan` (0047) & `koreksi_modal_shift` (0050) telah idempoten.
--   5. STOK:
--      - Kolom `kunci_idempoten` pada tabel `stok_pergerakan` (indeks unik parsial).
--      - RPC `set_stok` (overload 4 argumen ber-kunci idempoten).
--      - RPC `opname_stok` (overload 4 argumen ber-kunci idempoten).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Penambahan kolom kunci idempoten pada tabel shift_kas & stok_pergerakan
-- ---------------------------------------------------------------------------
alter table public.shift_kas
  add column if not exists kunci_idempoten text,
  add column if not exists kunci_idempoten_tutup text;

create unique index if not exists shift_kas_kunci_idempoten_unik
  on public.shift_kas (kunci_idempoten)
  where kunci_idempoten is not null;

create unique index if not exists shift_kas_kunci_tutup_unik
  on public.shift_kas (kunci_idempoten_tutup)
  where kunci_idempoten_tutup is not null;

alter table public.stok_pergerakan
  add column if not exists kunci_idempoten text;

create unique index if not exists stok_pergerakan_kunci_idempoten_unik
  on public.stok_pergerakan (kunci_idempoten)
  where kunci_idempoten is not null;

-- ---------------------------------------------------------------------------
-- 2. RPC simpan_pesanan (pintu tunggal pembuatan pesanan dengan kunci idempoten)
-- ---------------------------------------------------------------------------
create or replace function public.simpan_pesanan(
  p_cabang_id       uuid,
  p_meja_id         uuid    default null,
  p_tipe            text    default 'dinein',
  p_shift_id        uuid    default null,
  p_catatan         text    default null,
  p_items           jsonb   default '[]'::jsonb,
  p_kunci_idempoten text    default null,
  p_pesanan_id      uuid    default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pengguna_id   uuid;
  v_penyewa_id    uuid;
  v_kunci         text;
  v_id            uuid;
  v_nomor         integer;
  v_status        text;
  v_total         integer;
  v_subtotal      integer;
  v_item          jsonb;
  v_menu_item_id  uuid;
  v_qty           integer;
  v_nama_menu     text;
  v_harga_menu    integer;
  v_catatan_item  text;
  v_varian        text;
  v_pilihan_opsi  text[];
begin
  v_pengguna_id := auth.uid();
  if v_pengguna_id is null then
    raise exception 'Hanya pengguna terautentikasi yang dapat menyimpan pesanan.'
      using errcode = '42501';
  end if;

  v_penyewa_id := public.penyewa_saya();
  if v_penyewa_id is null then
    raise exception 'Pengguna tidak terhubung dengan penyewa aktif.'
      using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.cabang c
     where c.id = p_cabang_id
       and c.penyewa_id = v_penyewa_id
  ) then
    raise exception 'Cabang tidak ditemukan atau bukan milik penyewa.'
      using errcode = 'P0002';
  end if;

  v_kunci := coalesce(nullif(btrim(p_kunci_idempoten), ''), 'pos-' || gen_random_uuid()::text);

  -- 1. Idempotency Check
  select p.id, p.nomor, p.status, p.total, p.subtotal
    into v_id, v_nomor, v_status, v_total, v_subtotal
    from public.pesanan p
   where p.cabang_id = p_cabang_id
     and p.kunci_idempoten = v_kunci;

  if found then
    return jsonb_build_object(
      'berhasil', true,
      'kode', 'IDEMPOTEN',
      'pesan', 'Pesanan sudah tersimpan sebelumnya (idempoten).',
      'data', jsonb_build_object(
        'pesanan_id', v_id,
        'nomor', v_nomor,
        'status', v_status,
        'total', v_total,
        'subtotal', v_subtotal,
        'idempoten', true
      )
    );
  end if;

  -- 2. Insert Pesanan Baru
  v_id := coalesce(p_pesanan_id, gen_random_uuid());

  insert into public.pesanan (
    id, penyewa_id, cabang_id, tipe, meja_id, shift_id, catatan,
    kunci_idempoten, kasir_id, status
  ) values (
    v_id, v_penyewa_id, p_cabang_id, coalesce(p_tipe, 'dinein'),
    p_meja_id, p_shift_id, p_catatan, v_kunci, v_pengguna_id, 'draf'
  );

  -- 3. Insert Items bila ada
  if p_items is not null and jsonb_typeof(p_items) = 'array' then
    for v_item in select * from jsonb_array_elements(p_items) loop
      v_menu_item_id := (v_item->>'id')::uuid;
      v_qty := coalesce((v_item->>'qty')::integer, 1);
      v_catatan_item := v_item->>'catatan';
      v_varian := v_item->>'varian';

      select m.nama, public.harga_berlaku(m.id, p_cabang_id)
        into v_nama_menu, v_harga_menu
        from public.menu_item m
       where m.id = v_menu_item_id
         and m.penyewa_id = v_penyewa_id;

      if found and v_nama_menu is not null then
        -- Gunakan nama varian jika dicantumkan
        if v_varian is not null and btrim(v_varian) <> '' then
          v_nama_menu := v_nama_menu || ' (' || v_varian || ')';
        end if;

        -- Jika ada harga_kustom dari varian yang sah di payload
        if (v_item->>'harga') is not null then
          v_harga_menu := (v_item->>'harga')::integer;
        end if;

        insert into public.pesanan_item (
          pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu,
          qty, subtotal, catatan, varian
        ) values (
          v_id, v_menu_item_id, v_nama_menu, v_harga_menu,
          v_qty, (v_harga_menu * v_qty), v_catatan_item,
          case when (v_item->'varian') is not null and jsonb_typeof(v_item->'varian') = 'object' then v_item->'varian' else null end
        );
      end if;
    end loop;
  end if;

  -- 4. Hitung total peladen (ART-3)
  perform public.hitung_total(v_id);

  select p.nomor, p.status, p.total, p.subtotal
    into v_nomor, v_status, v_total, v_subtotal
    from public.pesanan p
   where p.id = v_id;

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SUKSES',
    'pesan', 'Pesanan berhasil disimpan.',
    'data', jsonb_build_object(
      'pesanan_id', v_id,
      'nomor', v_nomor,
      'status', v_status,
      'total', v_total,
      'subtotal', v_subtotal,
      'idempoten', false
    )
  );
end;
$$;

comment on function public.simpan_pesanan is
  'RPC T10-02: pintu tunggal pembuatan pesanan kasir dengan kunci idempoten (ART-8). Menjamin satu keranjang tidak pernah tersimpan ganda saat koneksi luring tersinkron ulang.';

revoke all on function public.simpan_pesanan from public, anon;
grant execute on function public.simpan_pesanan to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 3. RPC buka_shift (overload ber-kunci idempoten 4 argumen)
-- ---------------------------------------------------------------------------
create or replace function public.buka_shift(
  p_modal_awal      integer,
  p_cabang_id       uuid,
  p_catatan         text,
  p_kunci_idempoten text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_kunci       text;
  v_shift_id    uuid;
  v_cab         uuid;
  v_modal       integer;
  v_waktu       timestamptz;
  v_status      text;
  v_res         jsonb;
begin
  v_kunci := nullif(btrim(p_kunci_idempoten), '');

  -- 1. Idempotency Check
  if v_kunci is not null then
    select s.id, s.cabang_id, s.modal_awal, s.dibuka_pada, s.status
      into v_shift_id, v_cab, v_modal, v_waktu, v_status
      from public.shift_kas s
     where s.kunci_idempoten = v_kunci;

    if found then
      return jsonb_build_object(
        'berhasil', true,
        'kode', 'IDEMPOTEN',
        'pesan', 'Shift kasir sudah terbuka sebelumnya dengan kunci yang sama (idempoten).',
        'shift_id', v_shift_id,
        'cabang_id', v_cab,
        'modal_awal', v_modal,
        'dibuka_pada', v_waktu,
        'status', v_status,
        'idempoten', true
      );
    end if;
  end if;

  -- 2. Delegasikan ke logika inti buka_shift(3 argumen)
  v_res := public.buka_shift(p_modal_awal, p_cabang_id, p_catatan);

  -- 3. Rekam kunci jika berhasil
  if (v_res->>'berhasil')::boolean is true and v_kunci is not null then
    update public.shift_kas
       set kunci_idempoten = v_kunci
     where id = (v_res->>'shift_id')::uuid;
  end if;

  return v_res || jsonb_build_object('idempoten', false);
end;
$$;

comment on function public.buka_shift(integer, uuid, text, text) is
  'RPC T10-02: pembukaan shift kasir dengan dukungan kunci idempoten (ART-8). Mencegah pembukaan shift ganda saat kasir menekan tombol berulang kali saat jaringan tersendat.';

revoke all on function public.buka_shift(integer, uuid, text, text) from public, anon;
grant execute on function public.buka_shift(integer, uuid, text, text) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 4. RPC tutup_shift (overload ber-kunci idempoten 5 argumen)
-- ---------------------------------------------------------------------------
create or replace function public.tutup_shift(
  p_uang_fisik      integer,
  p_alasan_selisih  text,
  p_shift_id        uuid,
  p_catatan         text,
  p_kunci_idempoten text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_kunci           text;
  v_shift_id        uuid;
  v_cab             uuid;
  v_modal           integer;
  v_seharusnya      integer;
  v_fisik           integer;
  v_selisih         integer;
  v_alasan          text;
  v_status          text;
  v_ditutup_pada    timestamptz;
  v_res             jsonb;
begin
  v_kunci := nullif(btrim(p_kunci_idempoten), '');

  -- 1. Idempotency Check
  if v_kunci is not null then
    select s.id, s.cabang_id, s.modal_awal, s.uang_seharusnya, s.uang_fisik,
           s.selisih, s.alasan_selisih, s.status, s.ditutup_pada
      into v_shift_id, v_cab, v_modal, v_seharusnya, v_fisik,
           v_selisih, v_alasan, v_status, v_ditutup_pada
      from public.shift_kas s
     where s.kunci_idempoten_tutup = v_kunci;

    if found then
      return jsonb_build_object(
        'berhasil', true,
        'kode', 'IDEMPOTEN',
        'pesan', 'Shift kasir sudah ditutup sebelumnya dengan kunci yang sama (idempoten).',
        'data', jsonb_build_object(
          'shift_id', v_shift_id,
          'cabang_id', v_cab,
          'modal_awal', v_modal,
          'uang_seharusnya', v_seharusnya,
          'uang_fisik', v_fisik,
          'selisih', v_selisih,
          'alasan_selisih', v_alasan,
          'status', v_status,
          'ditutup_pada', v_ditutup_pada,
          'idempoten', true
        ),
        'idempoten', true
      );
    end if;
  end if;

  -- Pasang kunci idempoten pada shift saat masih berstatus terbuka
  if v_kunci is not null then
    if p_shift_id is not null then
      update public.shift_kas
         set kunci_idempoten_tutup = v_kunci
       where id = p_shift_id
         and status = 'terbuka';
    else
      update public.shift_kas
         set kunci_idempoten_tutup = v_kunci
       where id = (
         select id from public.shift_kas
          where penyewa_id = public.penyewa_saya()
            and dibuka_oleh = auth.uid()
            and status = 'terbuka'
          order by dibuka_pada desc
          limit 1
       );
    end if;
  end if;

  -- 2. Delegasikan ke logika inti tutup_shift(4 argumen)
  v_res := public.tutup_shift(p_uang_fisik, p_alasan_selisih, p_shift_id, p_catatan);

  return v_res || jsonb_build_object('idempoten', false);
end;
$$;

comment on function public.tutup_shift(integer, text, uuid, text, text) is
  'RPC T10-02: penutupan shift kasir dengan dukungan kunci idempoten (ART-8).';

revoke all on function public.tutup_shift(integer, text, uuid, text, text) from public, anon;
grant execute on function public.tutup_shift(integer, text, uuid, text, text) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 5. RPC set_stok (overload ber-kunci idempoten 4 argumen)
-- ---------------------------------------------------------------------------
create or replace function public.set_stok(
  p_stok_bahan_id   uuid,
  p_jumlah          numeric,
  p_alasan          text,
  p_kunci_idempoten text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_kunci           text;
  v_ada_id          bigint;
  v_ada_jumlah      numeric;
  v_saldo_sekarang  numeric;
  v_res             jsonb;
begin
  v_kunci := nullif(btrim(p_kunci_idempoten), '');

  -- 1. Idempotency Check
  if v_kunci is not null then
    select p.id, p.jumlah
      into v_ada_id, v_ada_jumlah
      from public.stok_pergerakan p
     where p.kunci_idempoten = v_kunci;

    if found then
      select b.jumlah into v_saldo_sekarang
        from public.stok_bahan b
       where b.id = p_stok_bahan_id;

      return jsonb_build_object(
        'berhasil', true,
        'kode', 'IDEMPOTEN',
        'pesan', 'Pergerakan stok sudah tercatat sebelumnya (idempoten).',
        'pergerakan_id', v_ada_id,
        'stok_bahan_id', p_stok_bahan_id,
        'delta', v_ada_jumlah,
        'jumlah_baru', v_saldo_sekarang,
        'idempoten', true
      );
    end if;
  end if;

  -- 2. Delegasikan ke logika inti set_stok(3 argumen)
  v_res := public.set_stok(p_stok_bahan_id, p_jumlah, p_alasan);

  -- 3. Rekam kunci idempoten pada pergerakan stok jika ada
  if v_kunci is not null then
    update public.stok_pergerakan
       set kunci_idempoten = v_kunci
     where id = currval('public.stok_pergerakan_id_seq');
  end if;

  return v_res || jsonb_build_object('berhasil', true, 'idempoten', false);
end;
$$;

comment on function public.set_stok(uuid, numeric, text, text) is
  'RPC T10-02: penyesuaian stok bahan dengan dukungan kunci idempoten (ART-8).';

revoke all on function public.set_stok(uuid, numeric, text, text) from public, anon;
grant execute on function public.set_stok(uuid, numeric, text, text) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 6. RPC opname_stok (overload ber-kunci idempoten 4 argumen)
-- ---------------------------------------------------------------------------
create or replace function public.opname_stok(
  p_stok_bahan_id   uuid,
  p_jumlah_fisik    numeric,
  p_alasan          text,
  p_kunci_idempoten text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_kunci           text;
  v_ada_id          bigint;
  v_ada_selisih     numeric;
  v_saldo_sekarang  numeric;
  v_res             jsonb;
begin
  v_kunci := nullif(btrim(p_kunci_idempoten), '');

  -- 1. Idempotency Check
  if v_kunci is not null then
    select p.id, p.jumlah
      into v_ada_id, v_ada_selisih
      from public.stok_pergerakan p
     where p.kunci_idempoten = v_kunci;

    if found then
      select b.jumlah into v_saldo_sekarang
        from public.stok_bahan b
       where b.id = p_stok_bahan_id;

      return jsonb_build_object(
        'berhasil', true,
        'kode', 'IDEMPOTEN',
        'pesan', 'Opname stok sudah tercatat sebelumnya (idempoten).',
        'pergerakan_id', v_ada_id,
        'stok_bahan_id', p_stok_bahan_id,
        'jumlah_fisik', v_saldo_sekarang,
        'selisih', v_ada_selisih,
        'idempoten', true
      );
    end if;
  end if;

  -- 2. Delegasikan ke logika inti opname_stok(3 argumen)
  v_res := public.opname_stok(p_stok_bahan_id, p_jumlah_fisik, p_alasan);

  -- 3. Rekam kunci idempoten pada pergerakan stok jika ada
  if v_kunci is not null then
    update public.stok_pergerakan
       set kunci_idempoten = v_kunci
     where id = currval('public.stok_pergerakan_id_seq');
  end if;

  return v_res || jsonb_build_object('berhasil', true, 'idempoten', false);
end;
$$;

comment on function public.opname_stok(uuid, numeric, text, text) is
  'RPC T10-02: opname hitung fisik stok bahan dengan dukungan kunci idempoten (ART-8).';

revoke all on function public.opname_stok(uuid, numeric, text, text) from public, anon;
grant execute on function public.opname_stok(uuid, numeric, text, text) to authenticated, service_role;
