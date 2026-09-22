-- A-F04: cegah deadlock saat satu transaksi menyentuh beberapa baris rincian
-- pada pesanan berbeda dengan urutan yang berlawanan.
--
-- Urutan UUID pada 0022 hanya mengurutkan parent dalam SATU pemanggilan trigger.
-- Dua UPDATE berurutan masih dapat mengunci item/parent pertama masing-masing,
-- lalu saling menunggu pada item kedua. Kunci advisory per penyewa diambil
-- sebelum baris rincian disentuh; semua perubahan rincian satu penyewa akhirnya
-- memakai urutan global yang sama. Penyewa berbeda tidak saling mengunci.

create or replace function public.kunci_lingkup_rincian(
  p_lama uuid,
  p_baru uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
begin
  -- Ambil semua penyewa yang mungkin disentuh (pindah antar-pesanan pun aman)
  -- dalam urutan UUID. `hashtextextended` menghasilkan satu kunci advisory
  -- transaksi; kunci dilepas otomatis saat transaksi selesai/rollback.
  for v_penyewa in
    select distinct p.penyewa_id
      from public.pesanan p
     where p.id = any(array[p_lama, p_baru])
     order by p.penyewa_id
  loop
    perform pg_advisory_xact_lock(
      hashtextextended('resto-barokah:rincian:' || v_penyewa::text, 0)
    );
  end loop;
end
$$;

revoke all on function public.kunci_lingkup_rincian(uuid, uuid) from public, anon, authenticated;
grant execute on function public.kunci_lingkup_rincian(uuid, uuid) to service_role;

comment on function public.kunci_lingkup_rincian(uuid, uuid) is
  'Kunci advisory per penyewa sebelum perubahan rincian pesanan; mencegah dua transaksi mengunci item/parent berbeda dalam urutan silang (A-F04).';

-- BEFORE STATEMENT diperlukan: BEFORE ROW baru berjalan setelah PostgreSQL
-- memperoleh kunci tuple yang hendak diubah. Kunci global ini diambil sebelum
-- tuple mana pun disentuh, sehingga dua UPDATE multi-baris tidak bisa saling
-- menunggu. Ia sengaja konservatif (serialisasi perubahan rincian lintas
-- penyewa); correctness didahulukan, dan optimasi per-penyewa dapat diputuskan
-- setelah workload nyata tersedia.
create or replace function public.kunci_rincian_global_sebelum()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform pg_advisory_xact_lock(
    hashtextextended('resto-barokah:rincian:global', 0)
  );
  return null;
end
$$;

revoke all on function public.kunci_rincian_global_sebelum() from public, anon, authenticated;
grant execute on function public.kunci_rincian_global_sebelum() to service_role;

create trigger rincian_kunci_global_sebelum
  before insert or update or delete on public.pesanan_item
  for each statement execute function public.kunci_rincian_global_sebelum();

comment on function public.kunci_rincian_global_sebelum() is
  'Kunci advisory transaksi global sebelum tuple pesanan_item disentuh; mencegah deadlock multi-baris pada urutan item silang (A-F04).';

-- Salinan definisi efektif 0022; migrasi beku tidak diubah.
create or replace function public.picu_rincian_beku_setelah_bayar()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_lama uuid;
  v_baru uuid;
  v_id uuid;
begin
  if tg_op <> 'INSERT' then v_lama := old.pesanan_id; end if;
  if tg_op <> 'DELETE' then v_baru := new.pesanan_id; end if;

  -- Kunci lingkup global sebelum row-lock/UPDATE rincian. Ini lapisan yang
  -- tidak dapat dicapai hanya dengan ORDER BY parent di satu trigger row.
  perform public.kunci_lingkup_rincian(v_lama, v_baru);

  -- Urutan UUID tetap menghindari kunci silang pada pemindahan antar-pesanan.
  for v_id in select distinct x from unnest(array[v_lama, v_baru]) as t(x)
               where x is not null order by x loop
    if auth.uid() is not null and not public.pesanan_sepenyewa(v_id) then
      raise exception 'Pesanan itu bukan milik resto/cabang Anda.';
    end if;
    perform 1 from public.pesanan p where p.id = v_id for update;
    if exists (select 1 from public.pembayaran pb where pb.pesanan_id = v_id) then
      -- Hanya progres dapur murni, bukan batal/ubah qty/harga/identitas.
      if tg_table_name = 'pesanan_item' and tg_op = 'UPDATE' then
        if (to_jsonb(new) - 'status') = (to_jsonb(old) - 'status')
           and ((old.status = 'baru' and new.status = 'dimasak')
             or (old.status = 'dimasak' and new.status = 'siap')) then
          continue;
        end if;
      end if;
      raise exception 'BY-201: Pembayaran sudah tercatat. Isi, diskon, dan pembatalan pesanan terkunci; jangan ubah pesanan ini.';
    end if;
  end loop;
  return case when tg_op = 'DELETE' then old else new end;
end
$$;

revoke all on function public.picu_rincian_beku_setelah_bayar() from public, anon, authenticated;
grant execute on function public.picu_rincian_beku_setelah_bayar() to service_role;
