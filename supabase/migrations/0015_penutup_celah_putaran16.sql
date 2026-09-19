-- ============================================================================
-- 0015 — PENUTUP CELAH PUTARAN16 (temuan independen 2026-09-19) — bagian 1: K-1
-- ============================================================================
-- Berkas migrasi BARU, sesuai aturan `docs/DECISIONS_LOG.md` 2026-09-19: berkas
-- `0001`–`0014` sudah disebar ke proyek Supabase nyata dan DIBEKUKAN; setiap
-- perbaikan berikutnya ditulis sebagai berkas baru bernomor 0015 ke atas.
--
-- BAGIAN 1 — K-1 (temuan review PR-01, tingkat paling berbahaya):
--   "Penanda transaksi `resto.pembatalan_*` bisa dipalsukan kasir → void sesudah
--    dapur tanpa PIN & tanpa jejak."
--
-- KENAPA BISA TERJADI (probe nyata `docs/uji/audit/probe-2026-09-19/pr01-penanda-palsu.sql`):
--   Penjaga `picu_item_jaga()` (0014 bagian 3) menerima bukti "pembatalan ini resmi" dari
--   **pengaturan transaksi** `current_setting('resto.pembatalan_pesanan')`. Pengaturan itu
--   ditulis oleh pemicu resmi (`picu_pembatalan_jejak`), TETAPI PostgreSQL mengizinkan
--   SIAPA PUN menulis pengaturan berawalan bebas lewat `set_config(...)`.
--   Akibatnya kasir cukup menjalankan tiga baris:
--       select set_config('resto.pembatalan_pesanan', '<id pesanan>', true);
--       update public.pesanan_item set status = 'batal' where pesanan_id = '<id pesanan>';
--   → item sesudah dapur dibatalkan TANPA PIN atasan dan TANPA satu pun baris `pembatalan`.
--
-- KEPUTUSAN PERBAIKAN (bukan tambalan):
--   1. Penanda transaksi TIDAK LAGI DIPERCAYA di mana pun. Bukti harus berbentuk DATA
--      di tabel (`public.pembatalan`), yang hanya bisa lahir lewat jalur resmi: penjaga
--      0013 memaksa tahap cocok + izin `void_sesudah_dapur` + kupon PIN yang terikat
--      pesanan & sekali pakai.
--   2. Pembatalan item / pengecilan jumlah SESUDAH DAPUR dari perangkat **selalu ditolak**.
--      Jalur sahnya adalah: perangkat menulis baris `pembatalan` resmi; pemicu
--      `picu_pembatalan_jejak` (SECURITY DEFINER, berjalan sebagai pemilik tabel) yang
--      mengubah baris item. Jadi pekerjaan kasir tidak berkurang — hanya jalur pintasnya ditutup.
--      (Bukti jalur sah ini sudah ada: `supabase/tes/item_penjaga.sql` §5 dan
--       `supabase/tes/persetujuan_void.sql`.)
--   3. Pemicu resmi berhenti menulis penanda itu (baris mati) supaya tidak ada lagi
--      kode yang tampak "mempercayai" pengaturan yang bisa dipalsukan.
--
-- CATATAN KEJUJURAN: perbaikan ini TIDAK menyentuh temuan lain (K-2…K-4). Berkas ini
-- akan bertambah bagian demi bagian pada batch-batch berikutnya, dan setiap bagian
-- wajib punya uji regresi yang bisa MERAH (dibuktikan `alat/uji-mutasi-0015.py`).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Penjaga item: bukti pembatalan tidak lagi datang dari pengaturan transaksi
-- ----------------------------------------------------------------------------
create or replace function public.picu_item_jaga()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_pesanan record;
  v_peran   text;
begin
  -- 1) Subtotal SELALU dihitung ulang peladen dari salinan harga × jumlah.
  new.subtotal := new.harga_saat_itu * new.qty;

  if auth.uid() is null or public.peran_peladen() then
    return new;   -- penyiapan / fungsi peladen
  end if;

  select p.id, p.dikirim_ke_dapur_pada, p.status
    into v_pesanan
    from public.pesanan p
   where p.id = coalesce(new.pesanan_id, old.pesanan_id);

  v_peran := public.peran_saya();

  -- 2) Dapur hanya boleh memajukan STATUS MASAK. Dapur tidak menjual: mengubah
  --    jumlah/harga/komposisi pesanan bukan kewenangannya (temuan review-2 PR-05).
  if tg_op = 'UPDATE' and v_peran = 'dapur' then
    if new.qty is distinct from old.qty
       or new.harga_saat_itu is distinct from old.harga_saat_itu
       or new.nama_saat_itu is distinct from old.nama_saat_itu
       or new.varian is distinct from old.varian
       or new.tambahan is distinct from old.tambahan
       or new.catatan is distinct from old.catatan
       or new.pesanan_id is distinct from old.pesanan_id then
      raise exception 'Dapur hanya boleh memajukan status masak — isi pesanan (jumlah, harga, catatan) tidak boleh diubah dapur.';
    end if;
  end if;

  -- 2b) Pesanan yang sudah lunas/batal TIDAK boleh diubah lagi.
  if coalesce(v_pesanan.status, '') in ('lunas', 'batal') then
    raise exception 'Pesanan yang sudah % tidak boleh diubah lagi.', v_pesanan.status;
  end if;

  -- 2c) Salinan harga & nama BEKU setelah dapur mulai: mengubahnya butuh izin `ubah_harga`.
  if tg_op = 'UPDATE'
     and (new.harga_saat_itu is distinct from old.harga_saat_itu
          or new.nama_saat_itu is distinct from old.nama_saat_itu)
     and (v_pesanan.dikirim_ke_dapur_pada is not null
          or coalesce(v_pesanan.status, '') in ('dimasak', 'siap'))
     and not public.boleh('ubah_harga') then
    raise exception 'Harga/nama yang sudah tercatat beku setelah dapur mulai — mengubahnya perlu izin ubah harga.';
  end if;

  -- 3) Pembatalan item / pengecilan jumlah SESUDAH DAPUR — dari perangkat SELALU ditolak.
  --    TEMUAN K-1 (review PR-01, 2026-09-19): dulu di sini ada pemeriksaan
  --    `current_setting('resto.pembatalan_pesanan')`. Pengaturan transaksi bisa ditulis
  --    SIAPA PUN lewat `set_config` — jadi kasir bisa mengarang "izin pembatalan" sendiri.
  --    Sekarang tidak ada lagi nilai yang bisa dipalsukan: bukti sah satu-satunya adalah
  --    baris `public.pembatalan` yang lahir lewat jalur resmi (0013: tahap + PIN atasan +
  --    kupon sekali pakai), dan baris item diubah oleh pemicu resmi itu sendiri
  --    (SECURITY DEFINER → berjalan sebagai pemilik tabel, tidak lewat cabang ini).
  if tg_op = 'UPDATE'
     and (new.status = 'batal' or new.qty < old.qty) then
    if v_pesanan.dikirim_ke_dapur_pada is not null
       or coalesce(v_pesanan.status, '') in ('dimasak', 'siap', 'lunas') then
      raise exception 'Pembatalan item setelah dapur mulai wajib lewat baris pembatalan resmi (alasan + persetujuan PIN atasan). Penanda transaksi tidak lagi diakui.';
    end if;
  end if;

  return new;
end
$$;

comment on function public.picu_item_jaga() is
  'Menjaga baris pesanan_item: subtotal dihitung peladen, dapur hanya memajukan status masak, isi yang sudah dibekukan tidak diubah sembarangan, dan pembatalan item setelah dapur mulai hanya boleh lewat baris `pembatalan` resmi (bukti berbentuk DATA, bukan pengaturan transaksi yang bisa dipalsukan — temuan K-1).';

drop trigger if exists item_jaga on public.pesanan_item;
create trigger item_jaga
  before insert or update on public.pesanan_item
  for each row execute function public.picu_item_jaga();

-- ----------------------------------------------------------------------------
-- 2. Pemicu resmi berhenti menulis penanda yang bisa dipalsukan
-- ----------------------------------------------------------------------------
create or replace function public.picu_pembatalan_jejak()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- CATATAN K-1 (2026-09-19): baris `perform set_config('resto.pembatalan_pesanan', …)`
  -- DIHAPUS. Penanda itu dulu dipakai penjaga item sebagai bukti "pembatalan ini resmi",
  -- padahal klien bisa menulisnya sendiri. Sekarang bukti satu-satunya adalah baris
  -- `pembatalan` yang sedang diproses pemicu ini — tidak ada nilai yang bisa dipalsukan.

  update public.pesanan p
     set status          = 'batal',
         dibatalkan_pada = now(),
         alasan_batal    = new.alasan
   where p.id = new.pesanan_id
     and p.status <> 'batal';

  -- Item yang batal lewat pembatalan resmi ikut ditandai supaya angka kerugian &
  -- tagihan tidak menghitung baris yang dibatalkan.
  if new.pesanan_item_id is not null then
    update public.pesanan_item pi
       set status = 'batal'
     where pi.id = new.pesanan_item_id;
  end if;

  return new;
end
$$;

comment on function public.picu_pembatalan_jejak() is
  'Setelah baris pembatalan resmi masuk: menutup pesanan (status batal) dan menandai item yang dibatalkan. Tanpa penanda transaksi apa pun — bukti pembatalan adalah baris tabelnya sendiri (perbaikan K-1 2026-09-19).';

drop trigger if exists pembatalan_jejak on public.pembatalan;
create trigger pembatalan_jejak
  after insert on public.pembatalan
  for each row execute function public.picu_pembatalan_jejak();

-- ----------------------------------------------------------------------------
-- 3. Hak akses fungsi yang diperbarui (tetap sama seperti sebelumnya)
-- ----------------------------------------------------------------------------
grant execute on function public.picu_item_jaga() to authenticated, service_role;
grant execute on function public.picu_pembatalan_jejak() to authenticated, service_role;
