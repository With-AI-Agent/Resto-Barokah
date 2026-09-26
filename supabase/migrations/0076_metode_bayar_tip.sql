-- ============================================================================
-- 0076_metode_bayar_tip.sql — Metode Pembayaran Aktif & Aturan Tip (T9-07 / PRD M2)
--
-- Lingkup:
--   1. Tambah kolom aturan tip pada public.pengaturan:
--      - izinkan_tip (boolean, default false)
--      - cara_hitung_tip ('sukarela' | 'persen' | 'nominal')
--      - pilihan_tip_persen (numeric(5, 2)[])
--      - pilihan_tip_nominal (integer[])
--   2. Tambah kolom tip pada public.pesanan (integer >= 0).
--   3. Tambah kolom diubah_pada pada public.metode_bayar.
--   4. Perbarui public.hitung_total agar memperhitungkan tip sukarela pelanggan.
--   5. Pemicu fail-closed:
--      - picu_metode_bayar_cegah_hapus: cegah hapus metode bayar yang punya riwayat pembayaran.
--      - picu_metode_bayar_minimal_satu_aktif: cegah menonaktifkan semua metode pembayaran.
--   6. Fungsi RPC:
--      - public.simpan_metode_bayar: tambah/edit metode bayar, nama, jenis, referensi, urutan.
--      - public.hapus_metode_bayar: hapus metode bayar (bila belum ada riwayat transaksi).
--      - public.simpan_urutan_metode_bayar: simpan urutan banyak metode bayar.
--      - public.simpan_aturan_tip: simpan konfigurasi tip resto.
--      - public.ambil_pengaturan_pembayaran: ambil data metode bayar & aturan tip.
--      - public.pasang_tip_pesanan: pasang tip pada pesanan.
--   7. Jejak audit kekal di public.catatan_audit.
-- ============================================================================

-- 1. Tambah kolom aturan tip pada public.pengaturan
alter table public.pengaturan
  add column if not exists izinkan_tip boolean not null default false,
  add column if not exists cara_hitung_tip text not null default 'sukarela'
    check (cara_hitung_tip in ('sukarela', 'persen', 'nominal')),
  add column if not exists pilihan_tip_persen numeric(5, 2)[] not null default array[5.0, 10.0, 15.0]::numeric(5, 2)[],
  add column if not exists pilihan_tip_nominal integer[] not null default array[2000, 5000, 10000]::integer[];

-- 2. Tambah kolom tip pada public.pesanan
alter table public.pesanan
  add column if not exists tip integer not null default 0 check (tip >= 0);

-- 3. Tambah kolom diubah_pada pada public.metode_bayar
alter table public.metode_bayar
  add column if not exists diubah_pada timestamptz not null default now();

-- 4. Perbarui public.hitung_total agar memperhitungkan tip pesanan
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
  select p.id, p.penyewa_id, p.subtotal, p.pajak, p.service, p.total_diskon, p.total, p.status, p.tip
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

  -- Tip sukarela ditambahkan ke total akhir pembayaran
  v_total := v_total + coalesce(v_pesanan.tip, 0);

  update public.pesanan p
     set subtotal     = v_subtotal::integer,
         pajak        = v_pajak::integer,
         service      = v_service::integer,
         total_diskon = least(v_diskon, v_subtotal)::integer,
         total        = v_total::integer
   where p.id = p_pesanan_id;

  return v_total;
end;
$$;

revoke all on function public.hitung_total(uuid) from public;
grant execute on function public.hitung_total(uuid) to authenticated, service_role;

-- 5. Pemicu Fail-Closed Proteksi Metode Bayar
create or replace function public.picu_metode_bayar_cegah_hapus()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if exists (
    select 1 from public.pembayaran
     where metode_id = old.id
  ) then
    raise exception 'Metode pembayaran "%" tidak dapat dihapus karena sudah memiliki riwayat transaksi pembayaran. Silakan nonaktifkan metode ini.', old.nama;
  end if;
  return old;
end;
$$;

drop trigger if exists picu_metode_bayar_cegah_hapus on public.metode_bayar;
create trigger picu_metode_bayar_cegah_hapus
  before delete on public.metode_bayar
  for each row execute function public.picu_metode_bayar_cegah_hapus();

create or replace function public.picu_metode_bayar_minimal_satu_aktif()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_aktif_count integer;
  v_penyewa_target uuid;
begin
  v_penyewa_target := coalesce(new.penyewa_id, old.penyewa_id);
  select count(*) into v_aktif_count
    from public.metode_bayar
   where penyewa_id = v_penyewa_target
     and aktif = true;

  if v_aktif_count = 0 then
    raise exception 'Minimal harus ada satu metode pembayaran yang aktif di restoran.';
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists picu_metode_bayar_minimal_satu_aktif on public.metode_bayar;
create trigger picu_metode_bayar_minimal_satu_aktif
  after update or delete on public.metode_bayar
  for each row execute function public.picu_metode_bayar_minimal_satu_aktif();

-- 6. Fungsi RPC Resmi
-- 6a. Simpan Metode Bayar (tambah / edit)
create or replace function public.simpan_metode_bayar(
  p_id uuid,
  p_nama text,
  p_jenis text,
  p_butuh_referensi boolean,
  p_aktif boolean,
  p_urutan integer default 0
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_peran text;
  v_id uuid;
  v_nama_bersih text;
  v_nilai_lama jsonb := null;
  v_nilai_baru jsonb;
  v_metode_ada record;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  v_peran := coalesce(public.peran_saya(), '');
  if v_peran <> 'owner_pusat' and not public.boleh('atur_pengaturan') then
    if v_peran <> 'admin_cabang' then
      raise exception 'Hanya owner pusat, pemegang izin atur_pengaturan, atau admin cabang yang dapat mengatur metode pembayaran.';
    end if;
  end if;

  v_nama_bersih := btrim(coalesce(p_nama, ''));
  if v_nama_bersih is null or length(v_nama_bersih) < 2 then
    raise exception 'Nama metode pembayaran minimal 2 karakter.';
  end if;

  if p_jenis not in ('tunai', 'non_tunai') then
    raise exception 'Jenis metode pembayaran harus "tunai" atau "non_tunai".';
  end if;

  if p_jenis = 'tunai' and p_butuh_referensi = true then
    raise exception 'Metode pembayaran tunai tidak boleh mewajibkan nomor referensi.';
  end if;

  if p_jenis = 'non_tunai' and p_butuh_referensi = false then
    raise exception 'Metode pembayaran non-tunai wajib mengaktifkan nomor referensi.';
  end if;

  if p_id is not null then
    -- Mode Edit
    select id, nama, jenis, butuh_referensi, aktif, urutan
      into v_metode_ada
      from public.metode_bayar
     where id = p_id and penyewa_id = v_penyewa
       for update;

    if v_metode_ada.id is null then
      raise exception 'Metode pembayaran tidak ditemukan pada restoran Anda.';
    end if;

    -- Validasi keunikan nama bila berubah
    if lower(v_metode_ada.nama) <> lower(v_nama_bersih) then
      if exists (
        select 1 from public.metode_bayar
         where penyewa_id = v_penyewa
           and lower(nama) = lower(v_nama_bersih)
           and id <> p_id
      ) then
        raise exception 'Metode pembayaran dengan nama "%" sudah terdaftar.', v_nama_bersih;
      end if;
    end if;

    v_nilai_lama := to_jsonb(v_metode_ada);

    update public.metode_bayar
       set nama            = v_nama_bersih,
           jenis           = p_jenis,
           butuh_referensi = p_butuh_referensi,
           aktif           = coalesce(p_aktif, true),
           urutan          = coalesce(p_urutan, 0),
           diubah_pada     = now()
     where id = p_id;

    v_id := p_id;
  else
    -- Mode Tambah Baru
    if exists (
      select 1 from public.metode_bayar
       where penyewa_id = v_penyewa
         and lower(nama) = lower(v_nama_bersih)
    ) then
      raise exception 'Metode pembayaran dengan nama "%" sudah terdaftar.', v_nama_bersih;
    end if;

    v_id := gen_random_uuid();
    insert into public.metode_bayar (
      id, penyewa_id, nama, jenis, butuh_referensi, aktif, urutan, diubah_pada
    ) values (
      v_id, v_penyewa, v_nama_bersih, p_jenis, p_butuh_referensi, coalesce(p_aktif, true), coalesce(p_urutan, 0), now()
    );
  end if;

  select jsonb_build_object(
    'id', m.id,
    'nama', m.nama,
    'jenis', m.jenis,
    'butuh_referensi', m.butuh_referensi,
    'aktif', m.aktif,
    'urutan', m.urutan
  ) into v_nilai_baru
    from public.metode_bayar m
   where m.id = v_id;

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
    case when p_id is not null then 'ubah_metode_bayar' else 'tambah_metode_bayar' end,
    'metode_bayar',
    v_id,
    v_nilai_lama,
    v_nilai_baru
  );

  return jsonb_build_object(
    'berhasil', true,
    'id', v_id,
    'pesan', 'Metode pembayaran berhasil disimpan.'
  );
end;
$$;

-- 6b. Hapus Metode Bayar
create or replace function public.hapus_metode_bayar(p_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_peran text;
  v_metode record;
  v_nilai_lama jsonb;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  v_peran := coalesce(public.peran_saya(), '');
  if v_peran <> 'owner_pusat' and not public.boleh('atur_pengaturan') then
    raise exception 'Hanya owner pusat atau pemegang izin atur_pengaturan yang dapat menghapus metode pembayaran.';
  end if;

  select id, nama, jenis, butuh_referensi, aktif, urutan
    into v_metode
    from public.metode_bayar
   where id = p_id and penyewa_id = v_penyewa
     for update;

  if v_metode.id is null then
    raise exception 'Metode pembayaran tidak ditemukan pada restoran Anda.';
  end if;

  -- Cek riwayat pembayaran (fail-closed proteksi)
  if exists (
    select 1 from public.pembayaran
     where metode_id = p_id
  ) then
    raise exception 'Metode pembayaran "%" tidak dapat dihapus karena sudah memiliki riwayat transaksi pembayaran. Silakan nonaktifkan metode ini.', v_metode.nama;
  end if;

  v_nilai_lama := to_jsonb(v_metode);

  delete from public.metode_bayar
   where id = p_id;

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
    'hapus_metode_bayar',
    'metode_bayar',
    p_id,
    v_nilai_lama,
    null
  );

  return jsonb_build_object(
    'berhasil', true,
    'pesan', 'Metode pembayaran berhasil dihapus.'
  );
end;
$$;

-- 6c. Simpan Urutan Metode Bayar
create or replace function public.simpan_urutan_metode_bayar(p_daftar jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_item jsonb;
  v_id uuid;
  v_urutan integer;
  v_jumlah integer := 0;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  if jsonb_typeof(p_daftar) <> 'array' then
    raise exception 'Daftar urutan metode pembayaran harus berupa array JSON.';
  end if;

  for v_item in select * from jsonb_array_elements(p_daftar)
  loop
    v_id := (v_item->>'id')::uuid;
    v_urutan := coalesce((v_item->>'urutan')::integer, 0);

    update public.metode_bayar
       set urutan = v_urutan,
           diubah_pada = now()
     where id = v_id
       and penyewa_id = v_penyewa;

    if found then
      v_jumlah := v_jumlah + 1;
    end if;
  end loop;

  return jsonb_build_object(
    'berhasil', true,
    'jumlah', v_jumlah
  );
end;
$$;

-- 6d. Simpan Aturan Tip Resto
create or replace function public.simpan_aturan_tip(
  p_izinkan_tip boolean,
  p_cara_hitung_tip text default 'sukarela',
  p_pilihan_persen numeric[] default array[5.0, 10.0, 15.0]::numeric[],
  p_pilihan_nominal integer[] default array[2000, 5000, 10000]::integer[]
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_peran text;
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

  v_peran := coalesce(public.peran_saya(), '');
  if v_peran <> 'owner_pusat' and not public.boleh('atur_pengaturan') then
    raise exception 'Hanya owner pusat atau pemegang izin atur_pengaturan yang dapat mengubah aturan tip.';
  end if;

  if p_cara_hitung_tip not in ('sukarela', 'persen', 'nominal') then
    raise exception 'Cara hitung tip tidak valid (harus: "sukarela", "persen", atau "nominal").';
  end if;

  select jsonb_build_object(
    'izinkan_tip', izinkan_tip,
    'cara_hitung_tip', cara_hitung_tip,
    'pilihan_tip_persen', pilihan_tip_persen,
    'pilihan_tip_nominal', pilihan_tip_nominal
  ) into v_nilai_lama
    from public.pengaturan
   where penyewa_id = v_penyewa
     for update;

  update public.pengaturan
     set izinkan_tip         = coalesce(p_izinkan_tip, false),
         cara_hitung_tip     = coalesce(p_cara_hitung_tip, 'sukarela'),
         pilihan_tip_persen  = coalesce(p_pilihan_persen, array[5.0, 10.0, 15.0]::numeric(5, 2)[]),
         pilihan_tip_nominal = coalesce(p_pilihan_nominal, array[2000, 5000, 10000]::integer[]),
         diubah_oleh         = auth.uid(),
         diubah_pada         = now()
   where penyewa_id = v_penyewa;

  v_nilai_baru := jsonb_build_object(
    'izinkan_tip', coalesce(p_izinkan_tip, false),
    'cara_hitung_tip', coalesce(p_cara_hitung_tip, 'sukarela'),
    'pilihan_tip_persen', coalesce(p_pilihan_persen, array[5.0, 10.0, 15.0]::numeric(5, 2)[]),
    'pilihan_tip_nominal', coalesce(p_pilihan_nominal, array[2000, 5000, 10000]::integer[])
  );

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
    'ubah_aturan_tip',
    'pengaturan',
    v_penyewa,
    v_nilai_lama,
    v_nilai_baru
  );

  return jsonb_build_object(
    'berhasil', true,
    'pesan', 'Aturan tip berhasil disimpan.'
  );
end;
$$;

-- 6e. Ambil Pengaturan Pembayaran (Daftar Metode & Aturan Tip)
create or replace function public.ambil_pengaturan_pembayaran()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_daftar_metode jsonb;
  v_aturan_tip jsonb;
begin
  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', mb.id,
      'nama', mb.nama,
      'jenis', mb.jenis,
      'butuh_referensi', mb.butuh_referensi,
      'aktif', mb.aktif,
      'urutan', mb.urutan
    ) order by mb.urutan asc, mb.nama asc
  ), '[]'::jsonb) into v_daftar_metode
    from public.metode_bayar mb
   where mb.penyewa_id = v_penyewa;

  select jsonb_build_object(
    'izinkan_tip', coalesce(p.izinkan_tip, false),
    'cara_hitung_tip', coalesce(p.cara_hitung_tip, 'sukarela'),
    'pilihan_tip_persen', coalesce(to_jsonb(p.pilihan_tip_persen), '[5, 10, 15]'::jsonb),
    'pilihan_tip_nominal', coalesce(to_jsonb(p.pilihan_tip_nominal), '[2000, 5000, 10000]'::jsonb)
  ) into v_aturan_tip
    from public.pengaturan p
   where p.penyewa_id = v_penyewa;

  return jsonb_build_object(
    'metode_bayar', v_daftar_metode,
    'aturan_tip', coalesce(v_aturan_tip, '{}'::jsonb)
  );
end;
$$;

-- 6f. Pasang Tip pada Pesanan
create or replace function public.pasang_tip_pesanan(
  p_pesanan_id uuid,
  p_tip integer
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_pesanan record;
  v_izinkan_tip boolean;
  v_total_baru bigint;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  if p_tip is null or p_tip < 0 then
    raise exception 'Nilai tip tidak boleh negatif.';
  end if;

  select id, penyewa_id, status, tip
    into v_pesanan
    from public.pesanan
   where id = p_pesanan_id
     and penyewa_id = v_penyewa
     for update;

  if v_pesanan.id is null then
    raise exception 'Pesanan tidak ditemukan.';
  end if;

  if v_pesanan.status in ('lunas', 'batal') then
    raise exception 'Tip tidak dapat diubah pada pesanan yang sudah %.', v_pesanan.status;
  end if;

  select coalesce(izinkan_tip, false) into v_izinkan_tip
    from public.pengaturan
   where penyewa_id = v_penyewa;

  if not v_izinkan_tip and p_tip > 0 then
    raise exception 'Restoran tidak mengaktifkan fitur penerimaan tip.';
  end if;

  update public.pesanan
     set tip = p_tip
   where id = p_pesanan_id;

  v_total_baru := public.hitung_total(p_pesanan_id);

  if p_tip > 0 then
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
      'pasang_tip',
      'pesanan',
      p_pesanan_id,
      jsonb_build_object('tip_lama', v_pesanan.tip),
      jsonb_build_object('tip_baru', p_tip, 'total_baru', v_total_baru)
    );
  end if;

  return jsonb_build_object(
    'berhasil', true,
    'pesanan_id', p_pesanan_id,
    'tip', p_tip,
    'total', v_total_baru
  );
end;
$$;

-- 7. Hak Akses & Keamanan (ACL)
revoke all on function public.simpan_metode_bayar(uuid, text, text, boolean, boolean, integer) from public;
grant execute on function public.simpan_metode_bayar(uuid, text, text, boolean, boolean, integer) to authenticated;

revoke all on function public.hapus_metode_bayar(uuid) from public;
grant execute on function public.hapus_metode_bayar(uuid) to authenticated;

revoke all on function public.simpan_urutan_metode_bayar(jsonb) from public;
grant execute on function public.simpan_urutan_metode_bayar(jsonb) to authenticated;

revoke all on function public.simpan_aturan_tip(boolean, text, numeric[], integer[]) from public;
grant execute on function public.simpan_aturan_tip(boolean, text, numeric[], integer[]) to authenticated;

revoke all on function public.ambil_pengaturan_pembayaran() from public;
grant execute on function public.ambil_pengaturan_pembayaran() to authenticated;

revoke all on function public.pasang_tip_pesanan(uuid, integer) from public;
grant execute on function public.pasang_tip_pesanan(uuid, integer) to authenticated;

revoke all on function public.picu_metode_bayar_cegah_hapus() from public;
grant execute on function public.picu_metode_bayar_cegah_hapus() to service_role;

revoke all on function public.picu_metode_bayar_minimal_satu_aktif() from public;
grant execute on function public.picu_metode_bayar_minimal_satu_aktif() to service_role;
