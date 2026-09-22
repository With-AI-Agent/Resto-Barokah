-- ============================================================================
-- 0015 — PENUTUP CELAH PUTARAN16 (temuan independen 2026-09-19) — bagian 1…5
-- ============================================================================
--   BAGIAN 1 — K-1 : penanda transaksi pembatalan tidak lagi diakui (lihat di bawah)
--   BAGIAN 2 — K-2a: void SATU item TIDAK lagi ikut membatalkan seluruh pesanan
--   BAGIAN 3 — K-2b: diskon tidak bisa lagi ditanam/diubah sesudah pesanan lunas/batal
--   BAGIAN 4 — K-2c: hitungan nomor pesanan tidak bocor antar resto (PR-03)
--   BAGIAN 5 — K-2d: pesan PIN kembar tidak lagi memastikan PIN aktif kolega (PR-04)
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
-- 4. Hitungan nomor pesanan tidak bocor antar resto (temuan K-2 PR-03)
-- ----------------------------------------------------------------------------
-- TEMUAN (probe `pr03-bocor-nomor.sql`): `nomor_pesanan_berikutnya()` adalah SECURITY
-- DEFINER dan bisa dipanggil klien mana pun. Kasir Resto B memanggilnya untuk cabang
-- Resto A → ia membaca berapa pesanan yang sudah dibuat resto A hari itu (kebocoran
-- lintas penyewa). Pola yang sudah dipakai `hitung_total`/`total_dibayar`: periksa
-- `auth.uid()` + keterlihatan cabangnya. Tanpa identitas (penyiapan / service_role)
-- pemeriksaan dilewati seperti biasa.
create or replace function public.nomor_pesanan_berikutnya(p_cabang_id uuid, p_tanggal date)
returns integer
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_nomor integer;
begin
  if auth.uid() is not null and not public.cabang_pantau_saya(p_cabang_id) then
    raise exception 'Cabang itu bukan cabang yang boleh Anda lihat — hitungan nomor pesanan tidak dibagikan antar resto.';
  end if;

  select coalesce(max(p.nomor), 0) + 1 into v_nomor
    from public.pesanan p
   where p.cabang_id = p_cabang_id and p.tanggal = p_tanggal;

  return v_nomor;
end
$$;

revoke all on function public.nomor_pesanan_berikutnya(uuid, date) from public;
grant execute on function public.nomor_pesanan_berikutnya(uuid, date) to authenticated, service_role;

comment on function public.nomor_pesanan_berikutnya(uuid, date) is
  'Nomor pesanan berikutnya untuk satu cabang pada satu tanggal (max+1). Terisolasi lintas resto: pemanggil beridentitas hanya boleh menghitung cabang yang boleh ia pantau (temuan PR-03).';

-- ----------------------------------------------------------------------------
-- 5. Pesan PIN kembar tidak lagi memastikan PIN aktif kolega (temuan K-2 PR-04)
-- ----------------------------------------------------------------------------
-- TEMUAN (probe `pr04-oracle-pin.sql`): jawaban 'PIN itu sudah dipakai pegawai lain di
-- resto ini' MEMBERI TAHU penebak bahwa angka kirimannya adalah PIN aktif kolega —
-- cukup 20 percobaan/15 menit untuk memeriksa daftar tebakan kecil (tanggal lahir,
-- nomor favorit), tanpa pernah menyentuh layar login.
--
-- KEPUTUSAN: pesannya dibuat NETRAL. Pemanggil hanya tahu angkanya tidak bisa dipakai;
-- tidak ada lagi kalimat yang memastikan angka itu milik pegawai lain. Aturannya
-- sendiri (PIN wajib unik antar pegawai satu resto) TIDAK berubah, dan setiap percobaan
-- tetap tercatat di `percobaan_simpan_pin` dengan alasan 'PIN kembar' untuk ditelusuri
-- pemilik. Catatan jujur: sifat ya/tidak pada akhirnya masih bisa dibaca dari
-- berhasil-vs-ditolak, jadi pengendali biaya menebak tetap pembatas 20 percobaan per
-- 15 menit (keputusan T1-23, 2026-09-17) — lihat DECISIONS_LOG.
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
    -- TEMUAN K-2 PR-04 (2026-09-19): pesan lama menyebut "pegawai lain", sehingga jawaban
    -- ini MEMASTIKAN bahwa angka kiriman adalah PIN aktif kolega (oracle). Pesan sekarang
    -- netral: pemanggil hanya tahu angka itu tidak bisa dipakai. Pembatas 20 percobaan
    -- per 15 menit (`percobaan_simpan_pin`) tetap menjadi pengendali biaya menebak.
    return 'PIN itu tidak bisa dipakai — pilih angka lain.';
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

-- ----------------------------------------------------------------------------
-- 6. URUTAN HITUNGAN UANG (temuan AUD-3 2026-09-19 F-01 & F-02 — jalur uang)
-- ----------------------------------------------------------------------------
-- TEMUAN (terbukti lewat probe `docs/uji/audit/probe-2026-09-20/aud-3-f01-f02-uang.sql`):
--   1. F-01a — PB1 & service dihitung dari subtotal SEBELUM diskon. Aturan terkunci
--      `docs/TECH_SPEC.md` §329-330 berbunyi: subtotal → diskon → PB1 → service →
--      pembulatan, dan "pajak & service dihitung dari subtotal SETELAH diskon".
--      Kenyataan: belanja 100.000 dengan diskon 20.000 menghasilkan pajak 10.000 dan
--      service 5.000 (seharusnya 8.000 & 4.000) → total 95.000 (seharusnya 92.000).
--   2. F-01b — kolom `pengaturan.pembulatan` (none/100/500/1000) TIDAK PERNAH dibaca
--      mesin, jadi pilihan pemilik (pembulatan ke 100/500/1000) tidak berlaku.
--   3. F-02 — `hitung_total()` bisa dipanggil DARI PERANGKAT untuk pesanan yang sudah
--      `lunas`/`batal`, sehingga angka struk yang sudah dibayar berubah belakangan
--      (probe: total 31.050 → 33.750 hanya karena tarif PB1 di pengaturan naik).
--
-- KEPUTUSAN PERBAIKAN:
--   1. Dasar pajak & service = subtotal SETELAH diskon (`v_dasar`). Diskon tetap
--      dihitung dari subtotal (tidak berubah) dan tetap tidak boleh melebihi subtotal.
--   2. Pembulatan dibaca dari pengaturan dan dilakukan di LANGKAH TERAKHIR, **ke bawah**
--      (ke kelipatan 100/500/1000 terdekat di bawahnya) — dipilih supaya pelanggan tidak
--      pernah dirugikan oleh pembulatan. Catatan jujur: arah pembulatan belum pernah
--      dikunci dokumen mana pun; keputusan ini tercatat di `docs/DECISIONS_LOG.md` dan
--      bisa dibalik dengan satu baris bila pemilik menghendaki arah lain (T1-16 memfinalkan).
--   3. Pesanan `lunas`/`batal` TIDAK boleh dihitung ulang dari perangkat: panggilan
--      beridentitas (auth.uid() terisi) ditolak. Jalur peladen (pemicu & fungsi
--      service_role, auth.uid() kosong) tetap boleh karena justru peladen yang
--      MENETAPKAN status lunas setelah uang diterima.
--   4. Baris pesanan DIKUNCI (`for update`) selama perhitungan supaya dua perubahan
--      bersamaan tidak saling menimpa angka (temuan F-12 yang masih berstatus DUGAAN —
--      penguncian ini pencegahan, sama seperti jalur pembayaran di 0012).
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
  -- Kunci baris pesanan lebih dulu (anti saling-menimpa; lihat keputusan 4 di atas).
  select p.id, p.penyewa_id, p.subtotal, p.pajak, p.service, p.total_diskon, p.total, p.status
    into v_pesanan
    from public.pesanan p
   where p.id = p_pesanan_id
     for update;

  if v_pesanan.id is null then
    raise exception 'Pesanan tidak ditemukan.';
  end if;

  -- Isolasi lintas resto: pemanggil yang MEMBAWA identitas hanya boleh menghitung
  -- pesanan yang boleh ia lihat. (Di dalam SECURITY DEFINER, `peran_peladen()` SELALU
  -- benar — current_user adalah pemilik fungsi — jadi patokannya `auth.uid()`.)
  if auth.uid() is not null and not public.pesanan_sepenyewa(p_pesanan_id) then
    raise exception 'Pesanan itu bukan milik resto Anda.';
  end if;

  -- F-02: uang yang sudah tercatat tidak dihitung ulang dari PANGKILAN LANGSUNG perangkat.
  --
  -- Penting — kenapa `pg_trigger_depth()`: perhitungan ulang yang SAH justru datang dari
  -- pemicu peladen (mis. setelah baris pembatalan resmi menandai item `batal`, atau
  -- setelah pembayaran tercatat). Pada saat itu `auth.uid()` masih terisi milik pekerja
  -- yang bertindak. Menolak semua panggilan ber-identitas akan mematikan jalur sah itu —
  -- dan menandai "sedang dari pemicu" lewat pengaturan transaksi akan mengulang kesalahan
  -- K-1 (nilai yang bisa dipalsukan klien). `pg_trigger_depth()` TIDAK bisa dipalsukan:
  -- nilainya hanya > 0 kalau memang ada pemicu yang sedang berjalan.
  if auth.uid() is not null and pg_trigger_depth() = 0 and v_pesanan.status in ('lunas', 'batal') then
    raise exception 'Pesanan yang sudah % tidak boleh dihitung ulang dari perangkat — angka uang yang sudah tercatat hanya bisa dikoreksi lewat pembatalan/void resmi (berikut persetujuan PIN atasan bila dapur sudah mulai).', v_pesanan.status;
  end if;

  -- Subtotal = jumlah baris yang TIDAK dibatalkan (baris `batal` tidak menagih).
  select coalesce(sum(pi.subtotal), 0) into v_subtotal
    from public.pesanan_item pi
   where pi.pesanan_id = p_pesanan_id
     and pi.status <> 'batal';

  select p.pajak_pb1_persen, p.service_persen, p.pembulatan
    into v_persen_pajak, v_persen_service, v_pembulatan
    from public.pengaturan p
   where p.penyewa_id = v_pesanan.penyewa_id;

  -- Diskon dijumlahkan dari baris diskon; tidak boleh melebihi subtotal (dijaga juga
  -- oleh pemicu diskon 0012) supaya tidak ada "pesanan berhutang".
  select coalesce(sum(d.nilai), 0) into v_diskon
    from public.diskon_transaksi d
   where d.pesanan_id = p_pesanan_id;

  v_dasar := greatest(v_subtotal - v_diskon, 0);

  -- F-01a: PAJAK & SERVICE DARI SUBTOTAL SETELAH DISKON.
  v_pajak   := coalesce(round(v_dasar * coalesce(v_persen_pajak, 0) / 100), 0);
  v_service := coalesce(round(v_dasar * coalesce(v_persen_service, 0) / 100), 0);

  v_total := greatest(v_dasar + v_pajak + v_service, 0);

  -- F-01b: pembulatan mengikuti pengaturan resto, di langkah terakhir, ke BAWAH.
  v_langkah := case
                 when coalesce(v_pembulatan, 'none') = 'none' then 0
                 else v_pembulatan::bigint
               end;
  if v_langkah > 0 then
    v_total := (v_total / v_langkah) * v_langkah;
  end if;

  update public.pesanan p
     set subtotal     = v_subtotal::integer,
         pajak        = v_pajak::integer,
         service      = v_service::integer,
         total_diskon = least(v_diskon, v_subtotal)::integer,
         total        = v_total::integer
   where p.id = p_pesanan_id;

  return v_total;
end
$$;

comment on function public.hitung_total(uuid) is
  'SATU-SATUNYA penulis angka uang pesanan. Subtotal = jumlah baris non-batal; pajak & service dihitung dari subtotal SETELAH diskon (TECH_SPEC §329-330); pembulatan di langkah terakhir mengikuti pengaturan resto (ke bawah); pesanan lunas/batal tidak boleh dihitung ulang dari perangkat (temuan AUD-3 F-01/F-02).';

revoke all on function public.hitung_total(uuid) from public;
grant execute on function public.hitung_total(uuid) to authenticated;

-- ----------------------------------------------------------------------------
-- 7. Hak akses fungsi yang diperbarui (tetap sama seperti sebelumnya)
-- ----------------------------------------------------------------------------
grant execute on function public.picu_item_jaga() to authenticated, service_role;
grant execute on function public.picu_pembatalan_jejak() to authenticated, service_role;
grant execute on function public.picu_diskon_awal_pesanan() to authenticated, service_role;
grant execute on function public.simpan_pin(text, text, uuid, text) to authenticated, service_role;


-- ============================================================================
-- BAGIAN 8 — K-2 audit AUD-3 2026-09-19 (laporan __01a0bbd2): tiga cacat yang
--           DIBUKTIKAN NYATA lewat probe sendiri
--           (docs/uji/audit/probe-2026-09-20/aud-3-f03-f05-f06-uang.sql)
-- ============================================================================
-- Ringkas: (F-03) metode bayar nonaktif masih bisa dipakai kasir; (F-05) baris `pembatalan`
-- tidak idempoten — kiriman ulang menggandakan dampak & laporan kerugian; (F-06) stempel
-- lifecycle pesanan (dibayar_pada / dibatalkan_pada / alasan_batal) bisa dikarang lewat
-- UPDATE biasa dari perangkat.
--
-- Ketiganya diperbaiki dengan MENAMBAH pemeriksaan pada pemicu yang sudah ada (bukan pemicu
-- baru di jalur uang): definisi terakhir masing-masing fungsi ada di 0012/0013/0014 yang
-- BEKU, jadi versi barunya hidup di sini. Pemicunya sendiri tidak berubah.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 8a. F-03: hanya metode bayar AKTIF yang boleh mencatat uang
-- ---------------------------------------------------------------------------
create or replace function public.picu_pembayaran_jujur()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pesanan  record;
  v_metode   record;
  v_sebelum  integer;
begin
  -- KUNCI BARIS PESANAN (temuan review PR putaran8, PR-16, 2026-09-17): tanpa `for update`,
  -- dua pembayaran bersamaan sama-sama membaca `total_dibayar()` yang belum memuat baris
  -- pihak lain sehingga keduanya lolos batas lebih bayar. Dengan mengunci barisnya, pembayaran
  -- kedua menunggu sampai yang pertama ter-commit dan melihat angka yang benar.
  select p.id, p.status, p.total, p.penyewa_id
    into v_pesanan
    from public.pesanan p
   where p.id = new.pesanan_id
   for update;

  if v_pesanan.id is null then
    raise exception 'Pesanan tidak ditemukan.';
  end if;
  if v_pesanan.status = 'batal' then
    raise exception 'Pesanan ini sudah dibatalkan — uang tidak boleh dicatat lagi.';
  end if;

  if new.metode_id is not null then
    select m.nama, m.jenis, m.butuh_referensi, m.aktif
      into v_metode
      from public.metode_bayar m
     where m.id = new.metode_id
       and m.penyewa_id = v_pesanan.penyewa_id;
    if v_metode.nama is null then
      raise exception 'Metode bayar itu tidak ada di resto ini.';
    end if;
    -- TEMUAN AUD-3 F-03 (K-2): dulu "baris metodenya ada" disamakan dengan "metode boleh
    -- dipakai", sehingga metode yang sudah DINONAKTIFKAN pemilik masih bisa dipakai kasir
    -- (uang tercatat dengan metode yang sudah dimatikan). Sekarang status aktifnya diperiksa.
    if not v_metode.aktif then
      raise exception 'Metode bayar itu sudah dinonaktifkan pemilik resto — pilih metode yang masih aktif.';
    end if;
    new.metode_nama_saat_itu := v_metode.nama;
    new.jenis_saat_itu := v_metode.jenis;
  end if;

  if new.jenis_saat_itu = 'tunai' then
    if new.diterima is null then
      raise exception 'Pembayaran tunai wajib menyebut uang yang diterima.';
    end if;
    if new.diterima < new.jumlah then
      raise exception 'Uang diterima (%) lebih kecil dari jumlah bayar (%).', new.diterima, new.jumlah;
    end if;
    new.kembalian := new.diterima - new.jumlah;
  else
    if new.referensi is null or length(btrim(new.referensi)) = 0 then
      raise exception 'Pembayaran bukan tunai wajib menyebut nomor referensi.';
    end if;
    new.diterima := null;
    new.kembalian := null;
  end if;

  if new.kasir_id is null then
    new.kasir_id := auth.uid();
  end if;
  -- Jejak pelaku TIDAK boleh dikarang klien (temuan audit AUD-3 K-2, 2026-09-17):
  -- sebelumnya kasir bisa menuliskan nama owner sebagai kasir pembayaran, dan karena
  -- barisnya append-only kesalahan atribusi itu permanen.
  if auth.uid() is not null and new.kasir_id is distinct from auth.uid() then
    raise exception 'Nama kasir diisi sistem — tidak boleh menyebut orang lain.';
  end if;

  -- Total pesanan WAJIB sudah dihitung sebelum uang boleh dicatat (temuan audit AUD-3 K-1,
  -- 2026-09-17). Sebelumnya pemeriksaan dilewati saat total masih 0 — dan karena hitung_total
  -- (T1-15) belum ada, semua pesanan bertotal 0 sehingga berapa pun uangnya diterima tanpa
  -- penjaga, sementara baris uang tidak bisa diubah/dihapus (tidak ada jalan pemulihan).
  -- Menolak di sini membuat uang tidak pernah tercatat di atas angka yang belum pasti.
  if coalesce(v_pesanan.total, 0) <= 0 then
    raise exception 'Total pesanan belum dihitung — pembayaran belum boleh dicatat.';
  end if;

  v_sebelum := public.total_dibayar(new.pesanan_id) + new.jumlah;
  if v_sebelum > v_pesanan.total then
    raise exception 'Total pembayaran (%) melebihi total pesanan (%).', v_sebelum, v_pesanan.total;
  end if;

  return new;
end
$$;

comment on function public.picu_pembayaran_jujur() is
  'Menjaga pembayaran: metode bayar wajib ADA & AKTIF di resto ini (temuan AUD-3 F-03), referensi sesuai jenis, kembalian dihitung peladen, pelaku = pemanggil, total pesanan wajib sudah dihitung, tidak melebihi total, dan baris pesanan DIKUNCI.';

-- ---------------------------------------------------------------------------
-- 8b. F-05: satu target pembatalan = satu jejak (idempoten terhadap kiriman ulang)
-- ---------------------------------------------------------------------------
create or replace function public.picu_pembatalan_sah()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  JENDELA_SETUJU_MENIT constant integer := 5;   -- bukti persetujuan PIN dianggap sah selama ini
  v_pesanan record;
  v_item    record;
  v_nilai   integer;
  v_tahap   text;
  v_status  text;
  v_kupon   bigint;   -- percobaan_pin.id = bigserial
begin
  select p.id, p.dikirim_ke_dapur_pada, p.subtotal, p.status
    into v_pesanan
    from public.pesanan p where p.id = new.pesanan_id;
  if v_pesanan.id is null then
    raise exception 'Pesanan tidak ditemukan.';
  end if;

  -- TEMUAN AUD-3 F-05 (K-2): dulu tabel `pembatalan` tidak punya kunci idempotensi, sehingga
  -- kiriman ULANG baris yang sama (klik ganda kasir atau antrean perangkat offline) diterima
  -- sebagai kejadian KEDUA — laporan kerugian menghitung satu aksi dua kali. Sekarang satu
  -- target hanya boleh dibatalkan SEKALI: target yang sudah `batal` menolak baris baru.
  if new.pesanan_item_id is not null then
    if (select pi.status from public.pesanan_item pi where pi.id = new.pesanan_item_id) = 'batal' then
      raise exception 'Item ini sudah dibatalkan — kiriman ulang tidak dicatat lagi (satu aksi = satu jejak).';
    end if;
  elsif v_pesanan.status = 'batal' then
    raise exception 'Pesanan ini sudah dibatalkan — kiriman ulang tidak dicatat lagi (satu aksi = satu jejak).';
  end if;

  -- "Dapur sudah mulai" ditentukan dari DUA tanda: waktu kirim ke dapur DAN status
  -- pesanan. Memakai satu tanda saja rapuh: kalau salah satu lupa diisi (mis. RPC
  -- memajukan status tanpa mencatat waktunya), pembatalan bisa lolos tanpa PIN.
  v_tahap := case
               when v_pesanan.dikirim_ke_dapur_pada is not null then 'sesudah_dapur'
               else 'sebelum_dapur'
             end;
  if v_tahap = 'sebelum_dapur' then
    select p.status into v_status from public.pesanan p where p.id = new.pesanan_id;
    if v_status in ('dimasak', 'siap', 'lunas') then
      v_tahap := 'sesudah_dapur';
    end if;
  end if;
  if new.tahap <> v_tahap then
    raise exception 'Tahap pembatalan tidak sesuai keadaan pesanan (seharusnya %).', v_tahap;
  end if;

  -- Setelah dapur mulai: wajib disetujui pengguna berizin (PIN atasan).
  if new.tahap = 'sesudah_dapur' then
    if new.disetujui_oleh is null then
      raise exception 'Pembatalan setelah dapur mulai wajib disetujui pengguna berizin (PIN).';
    end if;
    if not public.boleh_untuk(new.disetujui_oleh, 'void_sesudah_dapur') then
      raise exception 'Penyetuju itu tidak berizin menyetujui pembatalan setelah dapur mulai.';
    end if;
    -- KUPON SEKALI PAKAI (temuan review PR putaran8, PR-04, 2026-09-17):
    -- sebelumnya bukti persetujuan hanya berarti "ada catatan PIN yang cocok" — sehingga
    -- SATU persetujuan PIN bisa dipakai membatalkan banyak pesanan selama 5 menit.
    -- Sekarang bukti harus TERIKAT pesanan ini dan BELUM DIPAKAI; begitu dipakai, ditandai.
    select pp.id into v_kupon
      from public.percobaan_pin pp
     where pp.pengguna_id = new.disetujui_oleh
       and pp.berhasil
       and pp.aksi = 'void_sesudah_dapur'
       and pp.pesanan_id = new.pesanan_id
       and pp.dipakai_pada is null
       and pp.waktu > now() - make_interval(mins => JENDELA_SETUJU_MENIT)
     order by pp.waktu
     limit 1
     for update;
    if v_kupon is null then
      raise exception 'Persetujuan belum terbukti untuk pesanan ini: penyetuju harus memasukkan PIN-nya sendiri untuk pesanan ini (maksimal % menit lalu).', JENDELA_SETUJU_MENIT;
    end if;
    update public.percobaan_pin set dipakai_pada = now() where id = v_kupon;
  else
    if not public.boleh('void_sebelum_dapur') then
      raise exception 'Anda tidak berizin membatalkan pesanan sebelum dapur mulai.';
    end if;
  end if;

  -- Nilai kerugian dari SALINAN HARGA (bukan harga menu sekarang).
  if new.pesanan_item_id is not null then
    select pi.pesanan_id, pi.subtotal into v_item
      from public.pesanan_item pi where pi.id = new.pesanan_item_id;
    if v_item.pesanan_id is null or v_item.pesanan_id <> new.pesanan_id then
      raise exception 'Baris item itu bukan milik pesanan ini.';
    end if;
    v_nilai := coalesce(v_item.subtotal, 0);
  else
    v_nilai := coalesce(
      nullif(v_pesanan.subtotal, 0),
      (select coalesce(sum(pi.subtotal), 0)::integer from public.pesanan_item pi where pi.pesanan_id = new.pesanan_id)
    );
  end if;

  -- TEMUAN review putaran11 PR-03 (K-3): dulu nilai non-nol kiriman klien diterima APA ADANYA,
  -- sehingga kasir bisa menulis kerugian 1 rupiah untuk pesanan 54.000 (laporan kerugian
  -- under-report) atau angka besar sesukanya — kolomnya append-only, jadi angka karangan itu
  -- bertahan selamanya sebagai "jejak resmi". Sekarang nilai kerugian DIPAKSA sama dengan
  -- hitungan peladen dari SALINAN HARGA; kiriman klien hanya boleh 0 (minta diisi peladen)
  -- atau sama dengan hasil hitung. Selisih sedikit pun = penolakan.
  if new.nilai_kerugian <> 0 and new.nilai_kerugian is distinct from coalesce(v_nilai, 0) then
    raise exception 'Nilai kerugian dihitung peladen dari salinan harga (%); angka kiriman (%) tidak boleh dikarang.',
      coalesce(v_nilai, 0), new.nilai_kerugian;
  end if;
  new.nilai_kerugian := coalesce(v_nilai, 0);

  if new.pelaku_id is null then
    new.pelaku_id := auth.uid();
  end if;
  -- Jejak pelaku tidak boleh dikarang klien (temuan audit AUD-3 K-2, 2026-09-17).
  if auth.uid() is not null and new.pelaku_id is distinct from auth.uid() then
    raise exception 'Pelaku pembatalan diisi sistem — tidak boleh menyebut orang lain.';
  end if;
  return new;
end
$$;

comment on function public.picu_pembatalan_sah() is
  'Menjaga pembatalan: alasan wajib, tahap (sebelum/sesudah dapur) menentukan izin, persetujuan PIN terikat pesanan & sekali pakai, nilai kerugian dihitung peladen dari salinan harga, dan SATU target hanya boleh dibatalkan sekali (kiriman ulang ditolak — temuan AUD-3 F-05).';

-- ---------------------------------------------------------------------------
-- 8c. F-06: stempel lifecycle pesanan hanya dari jalur peladen
-- ---------------------------------------------------------------------------
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

    -- TEMUAN AUD-3 F-06 (K-2): dulu penjaga "stempel kejadian hanya dari peladen" hanya
    -- dipasang pada INSERT, sehingga kasir bisa MENGARANG jejak lewat UPDATE biasa:
    -- `update pesanan set dibayar_pada = now(), alasan_batal = '…'` pada pesanan yang masih
    -- draf — laporan lalu membaca "pernah dibayar/dibatalkan" untuk kejadian yang tidak ada.
    -- Jalur peladen (pemicu pembayaran/pembatalan, RPC SECURITY DEFINER) tetap boleh: ia
    -- berjalan sebagai pemilik tabel, bukan sebagai perangkat kasir.
    if new.dibayar_pada is distinct from old.dibayar_pada then
      raise exception 'Stempel pembayaran (dibayar_pada) hanya diisi jalur peladen setelah pembayaran sah.';
    end if;
    if new.dibatalkan_pada is distinct from old.dibatalkan_pada
       or new.alasan_batal is distinct from old.alasan_batal then
      raise exception 'Stempel pembatalan hanya diisi jalur peladen setelah pembatalan resmi (baris pembatalan ber-PIN bila sesudah dapur).';
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

comment on function public.picu_pesanan_jejak_jujur() is
  'Menjaga jejak pesanan: kasir/tanggal/nomor diisi sistem, pelayan se-cabang, dan stempel lifecycle (dibayar_pada, dibatalkan_pada, alasan_batal) TIDAK bisa dikarang perangkat lewat UPDATE biasa (temuan AUD-3 F-06).';

-- ---------------------------------------------------------------------------
-- 8d. Hak akses fungsi yang diperbarui (tetap sama seperti sebelumnya)
-- ---------------------------------------------------------------------------
grant execute on function public.picu_pembayaran_jujur() to authenticated, service_role;
grant execute on function public.picu_pembatalan_sah() to authenticated, service_role;
grant execute on function public.picu_pesanan_jejak_jujur() to authenticated, service_role;


-- ============================================================================
-- BAGIAN 9 — K-2 audit AUD-3 2026-09-19 F-04: state machine status item
--           (dibuktikan nyata lewat probe
--            docs/uji/audit/probe-2026-09-20/aud-3-f04-status-item.sql)
-- ============================================================================
-- Aturan terkunci TECH_SPEC ART-4: baru → dimasak → siap; pembatalan wajib beralasan &
-- tercatat (PRD Aturan Bisnis 7 & 11). Sebelum ini perangkat bisa: (a) memasukkan item
-- yang LAHIR `siap` (melewati semua pemeriksaan "dapur sudah mulai?"), (b) melompat
-- `baru → siap`, (c) menurunkan status yang sudah maju, (d) membatalkan item hanya dengan
-- mengubah status — tanpa alasan, tanpa baris `pembatalan`, tanpa nilai kerugian.
--
-- Definisi `picu_item_jaga` yang berlaku ada di berkas ini bagian 1; berkas `0009`–`0014`
-- BEKU, jadi versi lengkapnya hidup di sini. Pemicu `item_jaga` sendiri tidak berubah.
-- ============================================================================
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

  -- 4) STATE MACHINE STATUS ITEM (temuan AUD-3 F-04, K-2).
  --    Aturan terkunci (TECH_SPEC ART-4): status item hanya MAJU satu langkah
  --    baru → dimasak → siap. Sebelum perbaikan ini perangkat bisa melompat (baru → siap),
  --    menurunkan status yang sudah maju, atau MEMBATALKAN item cukup dengan mengubah
  --    statusnya — tanpa alasan, tanpa baris `pembatalan`, tanpa nilai kerugian. Item yang
  --    lahir `siap` juga melewati seluruh pemeriksaan "sudah mulai dimasak?".
  --    Penanda `batal` BUKAN transisi biasa: satu-satunya jalur sah adalah baris
  --    `pembatalan` resmi (ditulis di sini adalah pelanggaran aturan bisnis 7).
  if tg_op = 'INSERT' then
    if new.status is distinct from 'baru' then
      raise exception 'Item baru selalu mulai dari status baru (diminta %). Pembatalan punya jalurnya sendiri: baris pembatalan beralasan.', new.status;
    end if;
  elsif new.status is distinct from old.status then
    if new.status = 'batal' then
      raise exception 'Pembatalan item WAJIB lewat baris pembatalan resmi (alasan + persetujuan PIN bila dapur sudah mulai) — bukan dengan mengubah status baris item.';
    end if;
    if not (old.status = 'baru' and new.status = 'dimasak')
       and not (old.status = 'dimasak' and new.status = 'siap') then
      raise exception 'Status item hanya maju satu langkah: baru → dimasak → siap (dari % ke %).', old.status, new.status;
    end if;
  end if;

  return new;
end
$$;

comment on function public.picu_item_jaga() is
  'Menjaga baris pesanan_item: subtotal dihitung peladen, status item hanya maju satu langkah (baru → dimasak → siap) dan TIDAK boleh lahir/lompat/ mundur, pembatalan item hanya lewat baris pembatalan resmi, dapur hanya memajukan status masak, isi yang sudah dibekukan tidak diubah sembarangan (temuan K-1 & AUD-3 F-04).';

-- ---------------------------------------------------------------------------
-- 9b. Hak akses fungsi yang diperbarui (tetap sama seperti sebelumnya)
-- ---------------------------------------------------------------------------
grant execute on function public.picu_item_jaga() to authenticated, service_role;


-- ============================================================================
-- BAGIAN 10 — K-2 audit AUD-3 2026-09-19 F-11: helper hierarki PIN bukan oracle publik
--            (dibuktikan nyata lewat probe
--             docs/uji/audit/probe-2026-09-20/aud-3-f11-helper-pin.sql)
-- ============================================================================
-- TEMUAN: `peran_lebih_tinggi(p_pemanggil, p_target)` adalah SECURITY DEFINER, diberi
-- execute ke `authenticated`, dan menerima DUA UUID bebas tanpa membandingkan
-- `p_pemanggil` dengan `auth.uid()`. Akibatnya perangkat kasir bisa memetakan hierarki
-- peran siapa pun (termasuk lintas resto) lewat satu SELECT, dan setiap jalur baru yang
-- memakai helper ini tanpa pembungkus identitas akan menerima jawaban ATAS NAMA ORANG LAIN.
--
-- DUA lapis perbaikan (sesuai anjuran laporan: "menolak/menetapkan pemanggil dari
-- auth.uid() atau tidak callable klien"):
--   1. **Tidak callable klien** — hak execute dicabut dari `public` & `authenticated`.
--      Pemakai sebenarnya adalah `simpan_pin` (SECURITY DEFINER) yang berjalan sebagai
--      pemilik tabel, jadi pencabutan ini tidak menutup jalur sahnya.
--   2. **Identitas dipakukan** — bila ada pemanggil ber-JWT, `p_pemanggil` WAJIB dirinya
--      sendiri; selain itu jawabannya `false` (menolak, bukan menjawab atas nama orang lain).
-- ============================================================================
create or replace function public.peran_lebih_tinggi(p_pemanggil uuid, p_target uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  -- Lapis 2: identitas pemanggil dipakukan. Tanpa identitas (penyiapan / service_role)
  -- pemeriksaan dilewati seperti jalur peladen lain di proyek ini.
  if auth.uid() is not null and p_pemanggil is distinct from auth.uid() then
    return false;
  end if;
  return coalesce(
    (select public.peringkat_peran(pp.peran) > public.peringkat_peran(pt.peran)
       from public.pengguna pp
       join public.pengguna pt on pt.id = p_target
      where pp.id = p_pemanggil),
    false);
end
$$;

comment on function public.peran_lebih_tinggi(uuid, uuid) is
  'Benar bila peran pemanggil lebih tinggi dari peran target (hierarki PIN). Dipakai simpan_pin supaya bawahan tidak bisa merebut PIN atasan. Sejak AUD-3 F-11: TIDAK callable klien dan identitas pemanggil dipakukan ke auth.uid() (dulu bisa dipakai sebagai oracle hierarki dari perangkat).';

-- Lapis 1: cabut hak klien. `simpan_pin` tetap bisa memanggilnya karena berjalan sebagai
-- pemilik tabel (SECURITY DEFINER).
revoke all on function public.peran_lebih_tinggi(uuid, uuid) from public;
revoke all on function public.peran_lebih_tinggi(uuid, uuid) from authenticated;
grant execute on function public.peran_lebih_tinggi(uuid, uuid) to service_role;


-- ---------------------------------------------------------------------------
-- 10b. F-13 (tetap TERBUKA — mitigasi): nomor pesanan diambil dengan KUNCI serialisasi
-- ---------------------------------------------------------------------------
-- TEMUAN (DUGAAN): `max(nomor) + 1` tanpa serialisasi eksplisit. Batas nyata yang sudah ada:
-- kolom `nomor` UNIK per (cabang, tanggal), jadi nomor kembar tidak mungkin tersimpan —
-- yang bisa terjadi hanyalah INSERT kedua GAGAL karena bentrok, bukan data salah.
--
-- Mitigasi yang ditambahkan di sini: kunci advisory transaksi per (cabang, tanggal) supaya
-- dua perangkat yang mengirim bersamaan tidak membaca `max()` yang sama. Kunci dilepas
-- otomatis saat transaksi selesai. Fungsi ini menjadi VOLATILE karena mengunci.
--
-- Catatan jujur: uji concurrency yang diminta laporan (dua koneksi bersamaan) BELUM bisa
-- dijalankan di lingkungan uji proyek (PGlite = satu koneksi), jadi temuan ini TIDAK dicap
-- DITUTUP. Yang bisa dibuktikan mesin: sifat "serialisasi dipasang" (fungsi volatile +
-- pemanggilan kunci) — kalau ada yang mengembalikannya ke STABLE tanpa kunci, uji merah.
create or replace function public.nomor_pesanan_berikutnya(p_cabang_id uuid, p_tanggal date)
returns integer
language plpgsql
volatile    -- mengunci (advisory) — bukan STABLE lagi; lihat catatan F-13 di atas
security definer
set search_path = public, pg_temp
as $$
declare
  v_nomor integer;
begin
  if auth.uid() is not null and not public.cabang_pantau_saya(p_cabang_id) then
    raise exception 'Cabang itu bukan cabang yang boleh Anda lihat — hitungan nomor pesanan tidak dibagikan antar resto.';
  end if;

  -- Serialisasi pengambilan nomor (F-13): kunci dilepas otomatis di akhir transaksi.
  perform pg_advisory_xact_lock(hashtextextended(p_cabang_id::text || ':' || p_tanggal::text, 0));

  select coalesce(max(p.nomor), 0) + 1 into v_nomor
    from public.pesanan p
   where p.cabang_id = p_cabang_id and p.tanggal = p_tanggal;

  return v_nomor;
end
$$;

comment on function public.nomor_pesanan_berikutnya(uuid, date) is
  'Nomor pesanan berikutnya untuk satu cabang pada satu tanggal (max+1) DI BAWAH kunci advisory per (cabang, tanggal) supaya dua pengiriman bersamaan tidak membaca nomor yang sama (mitigasi AUD-3 F-13; uji concurrency nyata menyusul). Terisolasi lintas resto: pemanggil beridentitas hanya boleh menghitung cabang yang boleh ia pantau (temuan PR-03).';

revoke all on function public.nomor_pesanan_berikutnya(uuid, date) from public;
grant execute on function public.nomor_pesanan_berikutnya(uuid, date) to authenticated, service_role;


-- ============================================================================
-- BAGIAN 11 — K-2 audit AUD-3 2026-09-19 F-10: izin per-pegawai hanya se-cabang
--            (dibuktikan nyata lewat probe
--             docs/uji/audit/probe-2026-09-20/aud-3-f10-admin-cabang-izin.sql)
-- ============================================================================
-- TEMUAN: tiga sumber tidak sepakat. Kontrak (docs/TECH_SPEC.md §294, docs/PRD.md:174,
-- docs/DISCOVERY.md:53) berkata "admin_cabang … HANYA cabangnya"; policy `izin_pilih`
-- (0004) memakai `sepenyewa(pengguna_id)` = SELURUH penyewa; uji `rls_pengguna.sql` malah
-- mengunci perilaku yang bocor itu (8 baris). Akibat nyata: layar centang izin (M3) milik
-- admin Cabang Pusat menampilkan izin pegawai Cabang Dua.
--
-- Aturan yang ditetapkan (mengikuti kontrak, bukan uji lama): izin pegawai terlihat oleh
-- pemiliknya, oleh owner pusat se-restonya, dan oleh admin cabang HANYA untuk pegawai yang
-- bertugas di cabang yang sedang ia pakai — sama seperti policy `pengguna_pilih` supaya
-- satu aturan dipakai di mana pun (satu sumber kebenaran, bukan dua tafsir).
-- Catatan: sampai bagian ini belum ada RPC penulis `public.izin`, jadi tidak ada jalur tulis
-- yang perlu diselaraskan — yang diperbaiki adalah lingkup BACA.
drop policy if exists izin_pilih on public.izin;
create policy izin_pilih on public.izin
  for select to authenticated
  using (
    pengguna_id = auth.uid()
    or (public.sepenyewa(pengguna_id) and public.peran_saya() = 'owner_pusat')
    or (
      public.sepenyewa(pengguna_id)
      and public.peran_saya() = 'admin_cabang'
      and exists (
        select 1
          from public.pengguna_cabang pc
         where pc.pengguna_id = public.izin.pengguna_id
           and pc.cabang_id = public.cabang_saya()
      )
    )
  );

comment on policy izin_pilih on public.izin is
  'Izin pegawai: milik sendiri · owner pusat se-resto · admin cabang HANYA pegawai di cabang yang sedang ia pakai (temuan AUD-3 F-10; diselaraskan dengan pengguna_pilih).';
