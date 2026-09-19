-- ============================================================================
-- 0015 — PENUTUP CELAH PUTARAN16 (temuan independen 2026-09-19) — bagian 1…3
-- ============================================================================
--   BAGIAN 1 — K-1 : penanda transaksi pembatalan tidak lagi diakui (lihat di bawah)
--   BAGIAN 2 — K-2a: void SATU item TIDAK lagi ikut membatalkan seluruh pesanan
--   BAGIAN 3 — K-2b: diskon tidak bisa lagi ditanam/diubah sesudah pesanan lunas/batal
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
-- 2. Pemicu resmi: batal SATU item ≠ batal SELURUH pesanan (temuan PR-02)
-- ----------------------------------------------------------------------------
-- DULU (0014): setiap baris `pembatalan` — termasuk pembatalan SATU item — langsung
-- menulis `pesanan.status = 'batal'`. Akibatnya (probe `pr02-void-satu-item.sql`):
-- pesanan 3 item tetap dibatalkan seluruhnya padahal satu item sudah hidup lagi, dan
-- pembayaran sisa ditolak ("pesanan sudah batal") → pelanggan tidak bisa membayar
-- item yang benar-benar ia terima, dan laporan kerugian membaca pesanan sebagai batal.
--
-- SEKARANG: status `batal` HANYA bila pembatalan itu menutup SELURUH pesanan —
--   (a) pembatalan tingkat pesanan (tanpa `pesanan_item_id`), atau
--   (b) pembatalan item yang menghabiskan item hidup terakhir.
-- Selain itu pesanan tetap hidup, dan angka uangnya dihitung ulang otomatis oleh
-- pemicu `item_hitung_total` (0014) karena baris item ikut ditandai `batal`.
create or replace function public.picu_pembatalan_jejak()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_sisa_item integer;
begin
  -- CATATAN K-1 (2026-09-19): baris `perform set_config('resto.pembatalan_pesanan', …)`
  -- DIHAPUS. Penanda itu dulu dipakai penjaga item sebagai bukti "pembatalan ini resmi",
  -- padahal klien bisa menulisnya sendiri. Sekarang bukti satu-satunya adalah baris
  -- `pembatalan` yang sedang diproses pemicu ini — tidak ada nilai yang bisa dipalsukan.

  -- Item yang dibatalkan ditandai lebih dulu; pesanan penuh? ditentukan SESUDAH ini.
  if new.pesanan_item_id is not null then
    update public.pesanan_item pi
       set status = 'batal'
     where pi.id = new.pesanan_item_id;
  end if;

  -- Masih adakah item hidup (selain baris yang baru saja dibatalkan)?
  select count(*) into v_sisa_item
    from public.pesanan_item pi
   where pi.pesanan_id = new.pesanan_id
     and pi.status <> 'batal';

  -- Pesanan ditutup HANYA kalau tidak ada item hidup lagi, atau kalau yang dibatalkan
  -- memang seluruh pesanan (bukan satu item).
  if new.pesanan_item_id is null or v_sisa_item = 0 then
    update public.pesanan p
       set status          = 'batal',
           dibatalkan_pada = now(),
           alasan_batal    = new.alasan
     where p.id = new.pesanan_id
       and p.status <> 'batal';

    -- Pesanan yang DITUTUP tidak boleh meninggalkan baris yang tampak masih terutang:
    -- seluruh item hidup ikut ditandai batal. (Dulu pembatalan tingkat pesanan hanya
    -- menutup pesanannya, itemnya tetap `baru` — keadaan setengah jalan yang sama
    -- keluarganya dengan temuan PR-02.)
    update public.pesanan_item pi
       set status = 'batal'
     where pi.pesanan_id = new.pesanan_id
       and pi.status <> 'batal';
  end if;

  return new;
end
$$;

comment on function public.picu_pembatalan_jejak() is
  'Setelah baris pembatalan resmi masuk: menandai item yang dibatalkan, dan menutup pesanan (status batal) HANYA bila tidak ada item hidup tersisa atau pembatalannya memang tingkat pesanan. Tanpa penanda transaksi apa pun — bukti pembatalan adalah baris tabelnya sendiri (perbaikan K-1 & K-2a).';

drop trigger if exists pembatalan_jejak on public.pembatalan;
create trigger pembatalan_jejak
  after insert on public.pembatalan
  for each row execute function public.picu_pembatalan_jejak();

-- ----------------------------------------------------------------------------
-- 3. Diskon tidak bisa lagi ditanam sesudah uang tercatat (temuan audit D F-01)
-- ----------------------------------------------------------------------------
-- TEMUAN (probe `audit-f01-diskon-sesudah-lunas.sql`): pesanan sudah `lunas` (uang
-- sudah diterima & tercatat), lalu kasir menyisipkan baris `diskon_transaksi`. Pemicu
-- `diskon_hitung_total` (0014) menghitung ulang angka uang → `pesanan.total` BERUBAH
-- sesudah lunas. Artinya: struk yang sudah dibayar bisa "diubah" belakangan, dan
-- selisih kas tidak punya penjelasan resmi.
--
-- KEPUTUSAN: baris diskon TIDAK BOLEH ditambah/diubah/dihapus pada pesanan yang sudah
-- `lunas` atau `batal`. Jalur sah untuk memperbaiki uang sesudah tercatat adalah
-- PEMBATALAN/void resmi (baris `pembatalan`, berikut PIN atasan bila dapur sudah mulai)
-- — bukan menulis ulang tagihan lama. Ini penjaga BARU, tidak mengubah `picu_diskon_batas`
-- (0012) yang tetap mengurus jenis/batas/cap diskon.
-- CATATAN NAMA (penting): pemicu ini bernama `diskon_awal_…` supaya berjalan SEBELUM
-- pemicu nilai `diskon_batas` (PostgreSQL menjalankan pemicu sebaris menurut abjad nama).
-- Pada pesanan yang sudah tutup, penolakan harus berbunyi tentang STATUS pesanan, bukan
-- tentang nilai/tipe diskon — penolakan akibat nilai (mis. subtotal 0 pada pesanan batal)
-- tidak boleh menyamarkan alasan sebenarnya.
create or replace function public.picu_diskon_awal_pesanan()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pesanan_id uuid;
  v_status     text;
begin
  -- Baris yang dihapus tidak punya NEW; ambil id dari sisi yang tersedia.
  if tg_op = 'DELETE' then
    v_pesanan_id := old.pesanan_id;
  else
    v_pesanan_id := new.pesanan_id;
  end if;

  select p.status into v_status
    from public.pesanan p where p.id = v_pesanan_id;

  if v_status in ('lunas', 'batal') then
    raise exception 'Pesanan yang sudah % tidak boleh lagi ditambah/diubah/dihapus diskonnya — uang sudah tercatat. Jalur sah: pembatalan/void resmi (berikut persetujuan PIN atasan bila dapur sudah mulai).', v_status;
  end if;

  return case when tg_op = 'DELETE' then old else new end;
end
$$;

comment on function public.picu_diskon_awal_pesanan() is
  'Menahan perubahan diskon (tambah/ubah/hapus) pada pesanan yang sudah lunas atau batal — tagihan yang sudah dibayar tidak boleh ditulis ulang; perbaikannya lewat pembatalan/void resmi (temuan audit F-01).';

drop trigger if exists diskon_awal_pesanan on public.diskon_transaksi;
create trigger diskon_awal_pesanan
  before insert or update or delete on public.diskon_transaksi
  for each row execute function public.picu_diskon_awal_pesanan();

-- ----------------------------------------------------------------------------
-- 4. Hak akses fungsi yang diperbarui (tetap sama seperti sebelumnya)
-- ----------------------------------------------------------------------------
grant execute on function public.picu_item_jaga() to authenticated, service_role;
grant execute on function public.picu_pembatalan_jejak() to authenticated, service_role;
grant execute on function public.picu_diskon_awal_pesanan() to authenticated, service_role;
