-- T-025(a), keputusan Lee 2026-09-21: LARANG ubah/void setelah uang pertama
-- tercatat, termasuk pembayaran sebagian. Tidak ada jalur pengembalian baru.
-- Tambahan (bukan menulis ulang migrasi beku): pemicu paling awal pada rincian
-- mengunci pesanan yang SAMA dengan picu_pembayaran_jujur sebelum memeriksa uang.
-- ID lama DAN baru diperiksa (anti pindah baris untuk menghindari pagar).
-- Tidak ada bypass auth.uid() null / peran_peladen / penanda sesi: jalur
-- SECURITY DEFINER dan service_role pun tunduk pada keputusan uang ini.
-- Batas: progres masak tanpa perubahan isi tetap diperbolehkan; izin/status
-- tetap diperiksa pemicu lama. Ini bukan izin membuka kembali pesanan lunas.

create function public.picu_rincian_beku_setelah_bayar()
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
-- Trigger-only: EXECUTE klien tidak diperlukan, bukan RPC publik.
grant execute on function public.picu_rincian_beku_setelah_bayar() to service_role;

create trigger aaa_item_beku_setelah_bayar
before insert or update or delete on public.pesanan_item
for each row execute function public.picu_rincian_beku_setelah_bayar();
create trigger aaa_diskon_beku_setelah_bayar
before insert or update or delete on public.diskon_transaksi
for each row execute function public.picu_rincian_beku_setelah_bayar();
create trigger aaa_pembatalan_beku_setelah_bayar
before insert or update or delete on public.pembatalan
for each row execute function public.picu_rincian_beku_setelah_bayar();

-- Sabuk kedua: hitung_total (atau fungsi peladen lain) tidak boleh menulis ulang
-- nominal sesudah bayar. UPDATE pesanan sudah memegang kunci baris yang sama.
-- Lifecycle sah (kirim/masak/siap/lunas + stempel pembayaran) tetap milik penjaga
-- status/jejak yang sudah ada. DELETE dan batal dilarang meskipun lewat peladen.
create function public.picu_pesanan_beku_setelah_bayar()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if exists (select 1 from public.pembayaran pb where pb.pesanan_id = old.id) then
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
  return case when tg_op = 'DELETE' then old else new end;
end
$$;
revoke all on function public.picu_pesanan_beku_setelah_bayar() from public, anon, authenticated;
grant execute on function public.picu_pesanan_beku_setelah_bayar() to service_role;

-- Sesudah penjaga klien lama: penolakan izin/uang langsung tetap memberi sebab
-- semula; jalur definer yang dulu bebas tetap terkena sabuk ini.
create trigger zzz_pesanan_beku_setelah_bayar
before update or delete on public.pesanan
for each row execute function public.picu_pesanan_beku_setelah_bayar();

-- Progres masak murni tidak mengubah tagihan. Jangan menerapkan tarif pajak baru
-- pada struk berbayar hanya karena dapur menekan "siap". Fungsi ini memang sudah
-- definer sejak 0014; hanya jalur status-murni yang tidak menghitung ulang.
create or replace function public.picu_item_hitung_total()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'UPDATE' then
    if (to_jsonb(new) - 'status') = (to_jsonb(old) - 'status')
       and ((old.status = 'baru' and new.status = 'dimasak')
         or (old.status = 'dimasak' and new.status = 'siap')) then
      return null;
    end if;
  end if;
  perform public.hitung_total(coalesce(new.pesanan_id, old.pesanan_id));
  return null;
end
$$;
revoke all on function public.picu_item_hitung_total() from public, anon, authenticated;
grant execute on function public.picu_item_hitung_total() to service_role;
