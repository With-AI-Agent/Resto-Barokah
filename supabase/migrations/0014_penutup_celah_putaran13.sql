-- ============================================================================
-- 0014 — PENUTUP CELAH REVIEW PUTARAN13 & AUDIT AUD-3 (2026-09-18)
--
-- Seluruh celah di bawah DIBUKTIKAN dulu dengan probe sendiri (bukan hanya
-- membaca laporan peninjau), lalu ditutup di sini. Migrasi lama dibekukan —
-- perbaikan selalu lewat migrasi baru (aturan repo).
--
-- Celah yang ditutup, plus bukti probe sebelum perbaikan:
--   1. hitung_total() TIDAK PERNAH ADA  → pesanan lahir total=0, kasir dilarang
--      membetulkan, pembayaran yang benar ditolak ⇒ ALUR UANG BUNTU.
--      Probe: [1] buat=total 0 · [2] 2 item=54.000 · [3] betulkan=DITOLAK
--      · [4] bayar 59.400=DITOLAK.  (temuan audit F-01, K-1)
--   2. Dapur (izin ubah_stok) bisa UPDATE pesanan_item.subtotal → nilai kerugian
--      pembatalan palsu. Probe: dapur UPDATE subtotal=1 → DITERIMA.
--      (temuan review-1 PR-01, K-1)
--   3. Item pesanan bisa di-set `batal` / qty dikecilkan tanpa satu baris
--      `pembatalan`, tanpa PIN — termasuk setelah dapur mulai.
--      Probe: dapur & kasir set batal/qty → DITERIMA, pembatalan=0 baris.
--      (temuan audit F-02 & review-2 PR-05, K-1/K-3)
--   4. Pembatalan SAH tidak pernah mengubah status pesanan → pembayaran setelah
--      batal tetap diterima. Probe: pembatalan sah → status tetap 'dikirim';
--      BAYAR 10.000 (tunai) → DITERIMA.  (temuan review-1 PR-03, K-1)
--   5. Diskon bisa ditumpuk sampai 100% subtotal begitu owner menyalakan
--      `tumpuk_diskon` (cap bawaan 100% = bukan cap). Probe: 20 baris @2.700
--      = 54.000 = 100% subtotal, 0 baris ditolak.  (temuan audit F-03, K-2)
--   6. Jejak pesanan dikarang klien: kasir bisa menulis kasir_id=owner,
--      tanggal mundur 30 hari, nomor pilihan sendiri. Probe → DITERIMA.
--      (temuan audit F-04 & review-2 PR-03, K-2)
--   7. `diskon_transaksi.disetujui_oleh` distempel kasir tanpa bukti PIN.
--      Probe: kasir menulis disetujui_oleh=OWNER → DITERIMA. (review-2 PR-04)
--   8. Pembayaran tanpa `metode_id` menerima label metode karangan.
--      Probe: nama='Transfer BCA (karangan)', jenis='tunai' → TERSIMPAN.
--      (temuan review-2 PR-06, K-3)
--   9. INSERT langsung ke `stok_pergerakan` menerima arah bertentangan:
--      jenis='keluar' + jumlah=+7 → saldo NAIK.  (temuan review-2 PR-02, K-3)
--  10. Policy `meja_ubah_status` memberi UPDATE seluruh baris (nama & aktif
--      ikut berubah) dan meja yang sedang dipakai bisa DIHAPUS (meja_id → NULL).
--      Probe keduanya → DITERIMA.  (temuan audit F-08 & F-09, K-3)
--  11. Varian & tambahan diterima sebagai jsonb tetapi tidak pernah dihargai,
--      sementara harga yang benar DITOLAK pemicu harga jujur. (audit F-05, K-2)
--      → keputusan harga varian ditunda ke T1-12/T1-19; yang ditutup di sini
--        adalah jejaknya: varian/tambahan yang tidak bisa dihargai DITOLAK
--        tegas, bukan disimpan diam-diam sebagai tagihan kurang.
-- ============================================================================

-- ============================================================================
-- BAGIAN 1 — ANGKA UANG PESANAN DIHITUNG PELADEN (satu rumus, tidak diduplikasi)
-- ============================================================================

-- Rumus terkunci (DECISIONS_LOG/LOG_SESI 2026-09-16): uang = bilangan bulat rupiah
-- dan dihitung di peladen. Mengembalikan total pesanan setelah dihitung.
create or replace function public.hitung_total(p_pesanan_id uuid)
returns bigint
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_pesanan    record;
  v_subtotal   bigint;
  v_pajak      bigint;
  v_service    bigint;
  v_diskon     bigint;
  v_total      bigint;
begin
  select p.id, p.penyewa_id, p.subtotal, p.pajak, p.service, p.total_diskon, p.total
    into v_pesanan
    from public.pesanan p
   where p.id = p_pesanan_id;

  if v_pesanan.id is null then
    raise exception 'Pesanan tidak ditemukan.';
  end if;

  -- Isolasi lintas resto: fungsi SECURITY DEFINER melewati RLS, jadi pemanggil
  -- yang MEMBAWA identitas (perangkat) hanya boleh menghitung pesanan yang boleh
  -- ia lihat. CATATAN PENTING: di dalam fungsi SECURITY DEFINER, current_user
  -- adalah PEMILIK fungsi sehingga `peran_peladen()` SELALU benar di sini —
  -- pemeriksaan "apakah ini peladen?" tidak bisa dipakai (kalau dipakai,
  -- penjaganya buta; kesalahan yang sudah pernah terjadi di 0007/0010).
  -- Karena itu patokannya `auth.uid()` + `pesanan_sepenyewa()`, sama seperti
  -- `total_dibayar` di 0010.
  if auth.uid() is not null and not public.pesanan_sepenyewa(p_pesanan_id) then
    raise exception 'Pesanan itu bukan milik resto Anda.';
  end if;

  -- Subtotal = jumlah baris yang TIDAK dibatalkan. Baris `batal` tidak menagih.
  select coalesce(sum(pi.subtotal), 0) into v_subtotal
    from public.pesanan_item pi
   where pi.pesanan_id = p_pesanan_id
     and pi.status <> 'batal';

  select p.pajak_pb1_persen, p.service_persen
    into v_pajak, v_service
    from public.pengaturan p
   where p.penyewa_id = v_pesanan.penyewa_id;

  v_pajak   := coalesce(round(v_subtotal * coalesce(v_pajak, 0) / 100), 0);
  v_service := coalesce(round(v_subtotal * coalesce(v_service, 0) / 100), 0);

  select coalesce(sum(d.nilai), 0) into v_diskon
    from public.diskon_transaksi d
   where d.pesanan_id = p_pesanan_id;

  -- Tidak boleh negatif: potongan melebihi tagihan dijepit di 0, bukan bikin
  -- "pesanan berhutang" yang lalu ditolak pembayaran karena total <= 0.
  v_total := greatest(v_subtotal + v_pajak + v_service - v_diskon, 0);

  update public.pesanan p
     set subtotal     = v_subtotal::integer,
         pajak        = v_pajak::integer,
         service      = v_service::integer,
         total_diskon = least(v_diskon, v_subtotal + v_pajak + v_service)::integer,
         total        = v_total::integer
   where p.id = p_pesanan_id;

  return v_total;
end
$$;

comment on function public.hitung_total(uuid) is
  'SATU-SATUNYA penulis angka uang pesanan (keputusan terkunci 2026-09-16). Subtotal = jumlah baris non-batal; pajak/service dari pengaturan resto; total_diskon = jumlah diskon_transaksi; total = subtotal+pajak+service−diskon (minimal 0). Dipanggil pemicu item & diskon, boleh dipanggil klien untuk pesanannya sendiri.';

revoke all on function public.hitung_total(uuid) from public;
grant execute on function public.hitung_total(uuid) to authenticated;

-- Pemicu: setiap perubahan baris pesanan / diskon → hitung ulang.
create or replace function public.picu_item_hitung_total()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.hitung_total(coalesce(new.pesanan_id, old.pesanan_id));
  return null;
end
$$;

drop trigger if exists item_hitung_total on public.pesanan_item;
create trigger item_hitung_total
  after insert or update or delete on public.pesanan_item
  for each row execute function public.picu_item_hitung_total();

create or replace function public.picu_diskon_hitung_total()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.hitung_total(coalesce(new.pesanan_id, old.pesanan_id));
  return null;
end
$$;

drop trigger if exists diskon_hitung_total on public.diskon_transaksi;
create trigger diskon_hitung_total
  after insert or update or delete on public.diskon_transaksi
  for each row execute function public.picu_diskon_hitung_total();

-- ============================================================================
-- BAGIAN 2 — BARIS PESANAN: subtotal ditentukan peladen & pembatalan berjejak
-- ============================================================================
create or replace function public.picu_item_jaga() 
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_pesanan record;
  v_peran   text;
  v_tahap   text;
  v_jejak   text;
begin
  -- 1) Subtotal SELALU dihitung ulang peladen dari salinan harga × jumlah.
  --    Sebelumnya klien (termasuk dapur) boleh menulis angka apa pun, dan angka
  --    itu dipakai menghitung `nilai_kerugian` pembatalan — jadi kerugian bisa
  --    dipalsukan dari perangkat (temuan review-1 PR-01, K-1).
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

  -- 2b) Pesanan yang sudah lunas/batal TIDAK boleh diubah lagi. Tanpa ini, kasir bisa
  --     menambah/mengubah item pada pesanan yang sudah dibayar atau dibatalkan — angka
  --     yang sudah disepakati dengan pelanggan berubah setelah uang berpindah.
  if coalesce(v_pesanan.status, '') in ('lunas', 'batal') then
    raise exception 'Pesanan yang sudah % tidak boleh diubah lagi.', v_pesanan.status;
  end if;

  -- 2c) Salinan harga & nama BEKU setelah dapur mulai: mengubahnya butuh izin
  --     `ubah_harga`. Sebelum ini kasir bisa menyelaraskan harga lama dengan harga
  --     menu hari ini (harga yang berubah setelah pesanan dibuat) sehingga riwayat
  --     yang sudah terjadi ikut berubah.
  if tg_op = 'UPDATE'
     and (new.harga_saat_itu is distinct from old.harga_saat_itu
          or new.nama_saat_itu is distinct from old.nama_saat_itu)
     and (v_pesanan.dikirim_ke_dapur_pada is not null
          or coalesce(v_pesanan.status, '') in ('dimasak', 'siap'))
     and not public.boleh('ubah_harga') then
    raise exception 'Harga/nama yang sudah tercatat beku setelah dapur mulai — mengubahnya perlu izin ubah harga.';
  end if;

  -- 3) Pembatalan item / pengecilan jumlah setelah dapur mulai WAJIB berjejak:
  --    harus ada baris `pembatalan` untuk pesanan ini pada transaksi yang sama
  --    (baris itu sendiri sudah dijaga 0013: tahap cocok + PIN atasan bukti).
  if tg_op = 'UPDATE'
     and (new.status = 'batal' or new.qty < old.qty) then
    if v_pesanan.dikirim_ke_dapur_pada is not null
       or coalesce(v_pesanan.status, '') in ('dimasak', 'siap', 'lunas') then
      v_jejak := coalesce(current_setting('resto.pembatalan_pesanan', true), '');
      if v_jejak is distinct from v_pesanan.id::text then
        raise exception 'Pembatalan item setelah dapur mulai wajib lewat baris pembatalan resmi (alasan + persetujuan PIN atasan).';
      end if;
    end if;
  end if;

  return new;
end
$$;

drop trigger if exists item_jaga on public.pesanan_item;
create trigger item_jaga
  before insert or update on public.pesanan_item
  for each row execute function public.picu_item_jaga();

-- Jejak transaksi: baris `pembatalan` yang SAH menandai transaksi ini, dan
-- sekaligus menutup temuan review-1 PR-03: pesanan yang dibatalkan TIDAK boleh
-- tetap berstatus hidup — dulu pembayaran setelah pembatalan tetap diterima.
-- PENTING: penanda ini TIDAK boleh bertahan lintas permintaan. Pakai
-- `set_config(..., true)` (transaction-local) supaya tidak bocor ke transaksi
-- berikutnya di koneksi yang sama.
create or replace function public.picu_pembatalan_jejak()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform set_config('resto.pembatalan_pesanan', new.pesanan_id::text, true);

  update public.pesanan p
     set status          = 'batal',
         dibatalkan_pada = now(),
         alasan_batal    = new.alasan
   where p.id = new.pesanan_id
     and p.status <> 'batal';

  -- Item yang batal lewat pembatalan pesanan penuh ikut ditandai supaya angka
  -- kerugian & tagihan tidak menghitung baris yang dibatalkan.
  if new.pesanan_item_id is not null then
    update public.pesanan_item pi
       set status = 'batal'
     where pi.id = new.pesanan_item_id;
  end if;

  return new;
end
$$;

drop trigger if exists pembatalan_jejak on public.pembatalan;
create trigger pembatalan_jejak
  after insert on public.pembatalan
  for each row execute function public.picu_pembatalan_jejak();

-- ============================================================================
-- BAGIAN 3 — DISKON: cap bawaan 100% = "tanpa batas" (bukan cap)
-- ============================================================================
-- Penjaga kumulatif sudah ada di pemicu 0013 (`picu_diskon_batas` memeriksa TOTAL
-- potongan terhadap subtotal dan terhadap cap resto) — yang bocor BUKAN
-- penjaganya, melainkan NILAI BAWAANNYA: `batas_maks_potongan_persen = 100`
-- membuat "cap" itu selalu lolos, sehingga dengan `tumpuk_diskon = true` kasir
-- bisa memecah diskon menjadi 20 baris @2.700 sampai 100% subtotal tanpa satu
-- pun baris melanggar batas izinnya (temuan audit F-03, K-2 — probe pembangun:
-- 20 baris diterima, 0 ditolak, total potongan = 100% subtotal).
--
-- Bawaan baru yang jujur: 50% (audit menyarankan 50; nilai ini bisa diubah
-- pemilik di pengaturan — untuk resto baru, 50% adalah titik awal yang punya
-- arti). Di atas itu tetap butuh persetujuan atasan lewat izin `beri_diskon`.
alter table public.pengaturan
  alter column batas_maks_potongan_persen set default 50;

-- ============================================================================
-- BAGIAN 4 — STAMP PERSETUJUAN DISKON TIDAK BOLEH DIKARANG
-- ============================================================================
create or replace function public.picu_diskon_setuju_jujur()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_kupon bigint;
begin
  if new.disetujui_oleh is null then
    return new;
  end if;

  -- Bukti harus TERIKAT pesanan ini, oleh orang itu, untuk aksi ini, dan belum dipakai.
  select pp.id into v_kupon
    from public.percobaan_pin pp
   where pp.pengguna_id = new.disetujui_oleh
     and pp.berhasil
     and pp.aksi = 'beri_diskon'
     and pp.pesanan_id = new.pesanan_id
     and pp.dipakai_pada is null
     and pp.waktu > now() - interval '5 minutes'
   order by pp.waktu
   limit 1
   for update;

  if v_kupon is null then
    raise exception 'Persetujuan diskon belum terbukti: penyetuju harus memasukkan PIN-nya sendiri untuk diskon di pesanan ini (temuan review putaran13 PR-04).';
  end if;

  update public.percobaan_pin pp set dipakai_pada = now() where pp.id = v_kupon;
  return new;
end
$$;

drop trigger if exists diskon_setuju_jujur on public.diskon_transaksi;
create trigger diskon_setuju_jujur
  before insert on public.diskon_transaksi
  for each row execute function public.picu_diskon_setuju_jujur();

-- ============================================================================
-- BAGIAN 5 — PEMBAYARAN: metode wajib dari daftar resto (label tidak dikarang)
-- ============================================================================
create or replace function public.picu_pembayaran_metode_wajib()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null or public.peran_peladen() then
    return new;
  end if;
  if new.metode_id is null then
    raise exception 'Metode bayar wajib dipilih dari daftar resto — label metode tidak boleh dikarang dari perangkat (temuan review putaran13 PR-06).';
  end if;
  return new;
end
$$;

drop trigger if exists pembayaran_metode_wajib on public.pembayaran;
create trigger pembayaran_metode_wajib
  before insert or update on public.pembayaran
  for each row execute function public.picu_pembayaran_metode_wajib();

-- ============================================================================
-- BAGIAN 6 — STOK: arah ditentukan JENIS walau INSERT langsung (bukan lewat RPC)
-- ============================================================================
create or replace function public.picu_stok_arah_jujur()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.jenis = 'masuk' then
    new.jumlah := abs(new.jumlah);
  elsif new.jenis = 'keluar' then
    new.jumlah := -abs(new.jumlah);
  else
    if new.jumlah = 0 then
      raise exception 'Pergerakan stok % tidak boleh nol.', new.jenis;
    end if;
  end if;
  return new;
end
$$;

drop trigger if exists stok_arah_jujur on public.stok_pergerakan;
create trigger stok_arah_jujur
  before insert on public.stok_pergerakan
  for each row execute function public.picu_stok_arah_jujur();


-- Nomor pesanan dihitung di peladen. Fungsi SECURITY DEFINER supaya penghitungan
-- tidak bergantung pada baris mana yang kebetulan terlihat pemanggil lewat RLS
-- (kalau bergantung, dua kasir bisa mendapat nomor yang sama dan pesanan gagal
-- karena kunci unik — kegagalan yang membingungkan).
create or replace function public.nomor_pesanan_berikutnya(p_cabang_id uuid, p_tanggal date)
returns integer
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(max(p.nomor), 0) + 1
    from public.pesanan p
   where p.cabang_id = p_cabang_id and p.tanggal = p_tanggal
$$;

revoke all on function public.nomor_pesanan_berikutnya(uuid, date) from public;
grant execute on function public.nomor_pesanan_berikutnya(uuid, date) to authenticated;

-- ============================================================================
-- BAGIAN 7 — JEJAK PESANAN: pelaku, tanggal, dan nomor tidak dikarang klien
-- ============================================================================
create or replace function public.picu_pesanan_jejak_jujur()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_nomor_seharusnya integer;
  v_pelayan_valid   boolean;
begin
  if auth.uid() is null or public.peran_peladen() then
    return new;   -- penyiapan / fungsi peladen
  end if;

  if tg_op = 'INSERT' then
    -- Pelaku: kasir_id diisi sistem, bukan dipilih perangkat.
    if new.kasir_id is not null and new.kasir_id is distinct from auth.uid() then
      raise exception 'Nama kasir diisi sistem — tidak boleh menyebut orang lain.';
    end if;
    new.kasir_id := auth.uid();

    -- Waktu: pesanan baru selalu hari ini (dulu tanggal bisa dimundurkan 30 hari
    -- untuk menyelipkan penjualan ke hari yang sudah ditutup — audit F-04).
    if new.tanggal is not null and new.tanggal <> current_date then
      raise exception 'Tanggal pesanan baru harus hari ini — tanggal mundur hanya boleh diisi peladen.';
    end if;
    new.tanggal := coalesce(new.tanggal, current_date);

    -- Nomor: SELALU dibuat sistem (berurutan per cabang per hari). Angka yang
    -- dikirim klien DIIABAIKAN — dulu klien bisa memilih nomornya sendiri sehingga
    -- dua struk bisa "bernomor sama" di hari berbeda (temuan audit F-04).
    new.nomor := public.nomor_pesanan_berikutnya(new.cabang_id, new.tanggal);
  else
    -- Pelaku & waktu tidak boleh dipindah setelah baris lahir.
    if new.kasir_id is distinct from old.kasir_id then
      raise exception 'Jejak kasir pesanan tidak boleh diubah.';
    end if;
    if new.tanggal is distinct from old.tanggal then
      raise exception 'Tanggal pesanan tidak boleh diubah.';
    end if;
    if new.nomor is distinct from old.nomor then
      raise exception 'Nomor pesanan tidak boleh diubah.';
    end if;
  end if;

  -- Pelayan: hanya pegawai cabang itu yang boleh disebut.
  if new.pelayan_id is not null then
    select exists (
      select 1 from public.pengguna_cabang pc
       where pc.pengguna_id = new.pelayan_id
         and pc.cabang_id = new.cabang_id
    ) into v_pelayan_valid;
    if not v_pelayan_valid then
      raise exception 'Pelayan yang disebut harus pegawai di cabang pesanan itu.';
    end if;
  end if;

  return new;
end
$$;

drop trigger if exists pesanan_jejak_jujur on public.pesanan;
create trigger pesanan_jejak_jujur
  before insert or update on public.pesanan
  for each row execute function public.picu_pesanan_jejak_jujur();

-- ============================================================================
-- BAGIAN 8 — MEJA: perubahan status tidak membawa nama/aktif; meja terpakai
--            tidak bisa dihapus (jejak "di meja mana" hilang permanen)
-- ============================================================================
create or replace function public.picu_meja_jaga()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_peran     text;
  v_pesanan   integer;
begin
  if auth.uid() is null or public.peran_peladen() then
    return coalesce(new, old);
  end if;

  if tg_op = 'DELETE' then
    select count(*) into v_pesanan
      from public.pesanan p
     where p.meja_id = old.id and p.status not in ('lunas', 'batal');
    if v_pesanan > 0 then
      raise exception 'Meja ini sedang dipakai % pesanan aktif — tidak boleh dihapus.', v_pesanan;
    end if;
    return old;
  end if;

  -- UPDATE: kasir & pelayan boleh menyentuh STATUS saja (policy `meja_ubah_status`
  -- memberi UPDATE seluruh baris — nama & aktif ikut berubah. Audit F-08, K-3).
  v_peran := public.peran_saya();
  if v_peran not in ('owner_pusat', 'admin_cabang') then
    if new.nama is distinct from old.nama
       or new.area is distinct from old.area
       or new.aktif is distinct from old.aktif
       or new.cabang_id is distinct from old.cabang_id then
      raise exception 'Peran % hanya boleh mengubah STATUS meja — nama/area/aktif adalah data induk cabang.', v_peran;
    end if;
  end if;
  return new;
end
$$;

drop trigger if exists meja_jaga on public.meja;
create trigger meja_jaga
  before update or delete on public.meja
  for each row execute function public.picu_meja_jaga();

-- ============================================================================
-- BAGIAN 9 — VARIAN & TAMBAHAN: jangan simpan tagihan yang tidak bisa dihargai
-- ============================================================================
create or replace function public.picu_item_varian_berharga()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null or public.peran_peladen() then
    return new;   -- penyiapan data uji
  end if;

  -- `varian` & `tambahan` ada di skema, tetapi belum ada satu pun perhitungan
  -- harga yang membacanya (audit F-05, K-2). Menyimpannya berarti menagih harga
  -- dasar untuk barang yang lebih mahal — kerugian tersebar kecil-kecil.
  -- Selama mesin harga varian (T1-12/T1-19) belum ada, jalur ini DITUTUP
  -- gagal-aman: lebih baik kasir mencatat varian sebagai CATATAN dengan harga
  -- yang benar (ber-izin `ubah_harga`) daripada tagihan diam-diam kurang.
  if new.varian is not null or new.tambahan is not null then
    if not public.boleh('ubah_harga') then
      raise exception 'Varian/tambahan belum bisa dihargai otomatis (menyusul T1-12). Catat sebagai catatan dengan harga yang benar — perlu izin ubah harga.';
    end if;
  end if;
  return new;
end
$$;

drop trigger if exists item_varian_berharga on public.pesanan_item;
create trigger item_varian_berharga
  before insert or update on public.pesanan_item
  for each row execute function public.picu_item_varian_berharga();


-- ============================================================================
-- BAGIAN 10 — PIN: ATASAN TIDAK BOLEH DIREBUT BAWAHANNYA (review putaran13 #2 PR-01)
-- ============================================================================
-- Urutan peran resmi (TECH_SPEC §4.1). Angka = tinggi kedudukan; hanya peran
-- dengan angka LEBIH BESAR yang boleh mengganti PIN peran di bawahnya.
create or replace function public.peringkat_peran(p_peran text)
returns integer
language sql
immutable
as $$
  select case p_peran
           when 'pemilik_platform' then 60
           when 'owner_pusat'      then 50
           when 'admin_cabang'     then 40
           when 'kasir'            then 30
           when 'pelayan'          then 20
           when 'dapur'            then 10
           else 0
         end
$$;

create or replace function public.peran_lebih_tinggi(p_pemanggil uuid, p_target uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(
    (select public.peringkat_peran(pp.peran) > public.peringkat_peran(pt.peran)
       from public.pengguna pp, public.pengguna pt
      where pp.id = p_pemanggil and pt.id = p_target),
    false)
$$;

comment on function public.peran_lebih_tinggi(uuid, uuid) is
  'Benar bila peran pemanggil lebih tinggi dari peran target (hierarki PIN). Dipakai simpan_pin supaya bawahan tidak bisa merebut PIN atasan.';

revoke all on function public.peran_lebih_tinggi(uuid, uuid) from public;
grant execute on function public.peran_lebih_tinggi(uuid, uuid) to authenticated;

-- Versi simpan_pin yang berlaku (salinan 0011 + pemeriksaan hierarki + catatan
-- `target_id`). Migrasi lama dibekukan, jadi penggantinya hidup di sini.
create or replace function public.simpan_pin(
  p_pin_baru    text,
  p_pin_lama    text default null,
  p_pengguna_id uuid default null,
  p_perangkat   text default 'tidak-diketahui'
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  BATAS_KEMBAR  constant integer := 20;   -- pemeriksaan keunikan per 15 menit per akun
  JENDELA_MENIT constant integer := 15;
  v_saya      uuid := auth.uid();
  v_target    uuid := coalesce(p_pengguna_id, auth.uid());
  v_perangkat text := coalesce(nullif(p_perangkat, ''), 'tidak-diketahui');
  v_hash      text;
  v_periksa   record;
  v_alasan    text;
  v_penyewa   uuid;
  v_probe     integer;
begin
  if v_saya is null then
    raise exception 'Anda harus masuk dulu untuk menyimpan PIN.';
  end if;

  v_alasan := public.pin_lemah(p_pin_baru);
  if v_alasan is not null then
    raise exception 'PIN ditolak: %.', v_alasan;
  end if;

  if v_target <> v_saya then
    if not public.sepenyewa(v_target) then
      raise exception 'Pegawai itu bukan bagian dari resto Anda.';
    end if;
    if not public.boleh('kelola_pegawai') then
      raise exception 'Anda tidak berizin mengubah PIN pegawai lain.';
    end if;

    -- HIERARKI PERAN (temuan review putaran13 #2 PR-01, K-2): izin `kelola_pegawai`
    -- dimaknai "boleh mengatur PIN siapa pun sedekai". Akibatnya admin cabang bisa
    -- DIAM-DIAM MENGGANTI PIN OWNER (tanpa PIN lama, tanpa pemberitahuan), lalu
    -- memakai PIN hasil rebutan itu untuk menerbitkan kupon persetujuan void atas
    -- nama owner. Bukti sebelum perbaikan: admin simpan_pin(target=owner) -> 'PIN
    -- tersimpan.'; verifikasi_pin(owner, '849273', void_sesudah_dapur) -> berhasil.
    -- Aturan: PIN orang lain hanya boleh diubah oleh peran yang LEBIH TINGGI.
    if not public.peran_lebih_tinggi(v_saya, v_target) then
      insert into public.percobaan_simpan_pin (pengguna_id, target_id, perangkat, berhasil, alasan)
      values (v_saya, v_target, v_perangkat, false, 'hierarki peran');
      raise exception 'Peran Anda tidak lebih tinggi dari pegawai itu — PIN-nya hanya boleh diganti oleh atasan atau dirinya sendiri.';
    end if;
  end if;

  -- Ganti PIN sendiri WAJIB memakai PIN lama (kecuali belum pernah punya PIN).
  if v_target = v_saya then
    select * into v_periksa
      from public.verifikasi_pin(v_target, coalesce(p_pin_lama, ''), null, v_perangkat);
    if exists (select 1 from public.kredensial_pin k where k.pengguna_id = v_target)
       and not v_periksa.berhasil then
      raise exception 'PIN lama salah. %', v_periksa.pesan;
    end if;
  end if;

  -- ---- keunikan PIN antar pegawai satu resto (dengan pembatas anti-oracle) ----
  select count(*) into v_probe
    from public.percobaan_simpan_pin ps
   where ps.pengguna_id = v_saya
     and ps.waktu > now() - make_interval(mins => JENDELA_MENIT);

  if v_probe >= BATAS_KEMBAR then
    insert into public.percobaan_simpan_pin (pengguna_id, target_id, perangkat, berhasil, alasan)
    values (v_saya, v_target, v_perangkat, false, 'melebihi batas');
    -- Dikembalikan sebagai PESAN, bukan exception: exception akan membatalkan
    -- baris catatan ini sendiri (savepoint blok penanganan error), sehingga
    -- pembatasnya tidak akan pernah menyala. Lihat catatan "CARA MENOLAK" di bawah.
    return format('Terlalu banyak percobaan memasang PIN (%s kali / %s menit). Tunggu sebentar.', BATAS_KEMBAR, JENDELA_MENIT);
  end if;

  select p.penyewa_id into v_penyewa from public.pengguna p where p.id = v_target;

  if exists (
    select 1
      from public.kredensial_pin k
      join public.pengguna p on p.id = k.pengguna_id
     where p.id <> v_target
       and p.penyewa_id = v_penyewa
       and k.pin_hash is not null
       and crypt(p_pin_baru, k.pin_hash) = k.pin_hash
  ) then
    insert into public.percobaan_simpan_pin (pengguna_id, target_id, perangkat, berhasil, alasan)
    values (v_saya, v_target, v_perangkat, false, 'PIN kembar');
    return 'PIN itu sudah dipakai pegawai lain di resto ini — pilih angka lain.';
  end if;

  insert into public.percobaan_simpan_pin (pengguna_id, target_id, perangkat, berhasil)
  values (v_saya, v_target, v_perangkat, true);

  v_hash := crypt(p_pin_baru, gen_salt('bf', 10));

  insert into public.kredensial_pin (pengguna_id, pin_hash, diubah_pada)
  values (v_target, v_hash, now())
  on conflict (pengguna_id) do update
     set pin_hash = excluded.pin_hash, diubah_pada = now();

  update public.pengguna set pin_diubah_pada = now() where id = v_target;

  return 'PIN tersimpan.';
end
$$;

-- Korban berhak MELIHAT bahwa PIN-nya diganti orang lain (audit: "tidak ada
-- jejak yang bisa dibaca korban"). Kolom `target_id` + policy baru: setiap
-- pengguna boleh membaca baris catatan yang menyangkut DIRINYA sendiri.
alter table public.percobaan_simpan_pin
  add column if not exists target_id uuid references public.pengguna (id) on delete set null;

create index if not exists percobaan_simpan_pin_target_idx
  on public.percobaan_simpan_pin (target_id, waktu desc);

grant select (id, pengguna_id, target_id, perangkat, berhasil, alasan, waktu)
  on public.percobaan_simpan_pin to authenticated;

drop policy if exists percobaan_simpan_pin_korban on public.percobaan_simpan_pin;
create policy percobaan_simpan_pin_korban on public.percobaan_simpan_pin
  for select to authenticated
  using (target_id = auth.uid());
