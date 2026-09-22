-- G3 A-F01/A-F03: pagar akhir untuk data-modifying CTE.
--
-- Trigger BEFORE/AFTER biasa pada 0022 memakai snapshot yang tidak melihat baris
-- pembayaran dari sibling data-modifying CTE dalam statement yang sama. Constraint
-- trigger INITIALLY IMMEDIATE dijalankan pada akhir statement, setelah seluruh
-- sub-pernyataan CTE selesai, sehingga ia memeriksa keadaan yang benar-benar akan
-- terlihat sesudah statement.
--
-- 0022 tetap dipertahankan sebagai pagar cepat dan pesan BY-201 normal. Migrasi ini
-- menambah lapisan akhir; migrasi beku tidak ditulis ulang.

create or replace function public.picu_beku_akhir_satu_pernyataan()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pesanan_id uuid;
begin
  if tg_table_name = 'pesanan' then
    v_pesanan_id := case when tg_op = 'DELETE' then old.id else new.id end;

    if exists (select 1 from public.pembayaran pb where pb.pesanan_id = v_pesanan_id) then
      if tg_op = 'DELETE' then
        raise exception 'BY-201: Pembayaran sudah tercatat; pesanan tidak boleh dihapus.';
      end if;
      if new.status = 'batal'
         or (to_jsonb(new) - array['status', 'dikirim_ke_dapur_pada', 'dibayar_pada'])
            is distinct from
            (to_jsonb(old) - array['status', 'dikirim_ke_dapur_pada', 'dibayar_pada']) then
        raise exception 'BY-201: Pembayaran sudah tercatat. Isi dan nominal pesanan terkunci; jangan ubah pesanan ini.';
      end if;
    end if;

  elsif tg_table_name = 'pesanan_item' then
    v_pesanan_id := case when tg_op = 'DELETE' then old.pesanan_id else new.pesanan_id end;

    if exists (select 1 from public.pembayaran pb where pb.pesanan_id = v_pesanan_id) then
      if tg_op = 'UPDATE'
         and (to_jsonb(new) - 'status') = (to_jsonb(old) - 'status')
         and ((old.status = 'baru' and new.status = 'dimasak')
           or (old.status = 'dimasak' and new.status = 'siap')) then
        return new;
      end if;
      raise exception 'BY-201: Pembayaran sudah tercatat. Isi, diskon, dan pembatalan pesanan terkunci; jangan ubah pesanan ini.';
    end if;

  elsif tg_table_name = 'diskon_transaksi' then
    v_pesanan_id := case when tg_op = 'DELETE' then old.pesanan_id else new.pesanan_id end;

    if exists (select 1 from public.pembayaran pb where pb.pesanan_id = v_pesanan_id) then
      raise exception 'BY-201: Pembayaran sudah tercatat. Isi, diskon, dan pembatalan pesanan terkunci; jangan ubah pesanan ini.';
    end if;

  elsif tg_table_name = 'pembatalan' then
    v_pesanan_id := case when tg_op = 'DELETE' then old.pesanan_id else new.pesanan_id end;

    if exists (select 1 from public.pembayaran pb where pb.pesanan_id = v_pesanan_id) then
      raise exception 'BY-201: Pembayaran sudah tercatat. Isi, diskon, dan pembatalan pesanan terkunci; jangan ubah pesanan ini.';
    end if;
  end if;

  return case when tg_op = 'DELETE' then old else new end;
end
$$;

revoke all on function public.picu_beku_akhir_satu_pernyataan() from public, anon, authenticated;
grant execute on function public.picu_beku_akhir_satu_pernyataan() to service_role;

create constraint trigger pesanan_beku_akhir_satu_pernyataan
  after insert or update or delete on public.pesanan
  deferrable initially immediate
  for each row execute function public.picu_beku_akhir_satu_pernyataan();

create constraint trigger item_beku_akhir_satu_pernyataan
  after insert or update or delete on public.pesanan_item
  deferrable initially immediate
  for each row execute function public.picu_beku_akhir_satu_pernyataan();

create constraint trigger diskon_beku_akhir_satu_pernyataan
  after insert or update or delete on public.diskon_transaksi
  deferrable initially immediate
  for each row execute function public.picu_beku_akhir_satu_pernyataan();

create constraint trigger pembatalan_beku_akhir_satu_pernyataan
  after insert or update or delete on public.pembatalan
  deferrable initially immediate
  for each row execute function public.picu_beku_akhir_satu_pernyataan();

comment on function public.picu_beku_akhir_satu_pernyataan() is
  'Pagar akhir statement untuk mencegah data-modifying CTE menggabungkan pembayaran pertama dengan perubahan isi/jejak pesanan; dipasang sesudah 0022 tanpa mengubah migrasi beku.';
