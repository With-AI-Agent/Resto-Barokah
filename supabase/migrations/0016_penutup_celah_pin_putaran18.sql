-- ============================================================================
-- 0016 — PENUTUP CELAH PIN PUTARAN 18 (temuan audit I: F-13, F-14, F-15, F-16)
-- ============================================================================
-- Empat cacat mekanisme PIN ditutup di sini. Semuanya DUGAAN di laporan audit,
-- lalu DIBUKTIKAN lewat pembacaan kode + uji SQL baru (lihat berkas uji yang
-- disebut per bagian). Aturan rumah: 0001–0015 BEKU; perbaikan lewat migrasi
-- baru dengan `create or replace` (definisi TERAKHIR = berlaku).
--
--   1. F-15 — pemanggil NONAKTIF (tenant NULL) bisa melewati penjaga tenant
--      verifikasi_pin, karena perbandingan `<>` dengan NULL = unknown.
--   2. F-16 — kupon diskon lahir dari "PIN benar tetapi TIDAK berizin", sebab
--      picu_diskon_setuju_jujur tidak mengecek ulang izin saat kupon dipakai.
--   3. F-14 — raise pada jalur "PIN lama salah" & "hierarki peran" di simpan_pin
--      menggulung balik catatan percobaan, sehingga pembatas tebakan tak pernah
--      menyala untuk dua jalur itu.
--   4. F-13 — peran_lebih_tinggi dapat dipanggil authenticated dengan dua UUID
--      bebas lintas resto (oracle metadata peran).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- BAGIAN 1 — F-15: pemanggil nonaktif/tenant-NULL ditolak SEBELUM cek kredensial
-- ----------------------------------------------------------------------------
-- BUKTI CACAT: penjaga tenant memakai `v_penyewa_target <> public.penyewa_saya()`.
-- Untuk akun yang dinonaktifkan (JWT masih sah), penyewa_saya() = NULL (menyaring
-- p.aktif), sehingga perbandingan bernilai unknown dan penjaga TIDAK berbunyi —
-- PIN pegawai resto lain masih diuji. Uji: supabase/tes/pin.sql (blok F-15).
create or replace function public.verifikasi_pin(
  p_pengguna_id uuid,
  p_pin         text,
  p_aksi        text default null,
  p_perangkat   text default 'tidak-diketahui',
  p_pesanan_id  uuid default null
)
returns table (berhasil boolean, sisa_percobaan integer, pesan text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  BATAS_AKUN       constant integer := 5;    -- 5 kali gagal per pasangan (pencoba → akun)
  BATAS_PERANGKAT  constant integer := 12;   -- 12 kali gagal per perangkat (melintasi akun)
  JENDELA_MENIT    constant integer := 15;
  v_saya       uuid := auth.uid();
  v_perangkat  text := coalesce(nullif(p_perangkat, ''), 'tidak-diketahui');
  v_hash       text;
  v_penyewa_target uuid;
  v_aktif_target   boolean;
  v_gagal_akun integer;
  v_gagal_alat integer;
  v_berhasil   boolean;
begin
  if v_saya is null then
    return query select false, 0, 'Anda harus masuk dulu untuk memakai PIN.';
    return;
  end if;

  -- F-15 (2026-09-20): akun nonaktif / tanpa resto mendapat jawaban netral
  -- SEBELUM kredensial disentuh. Tanpa ini, `<> NULL` membuat penjaga tenant
  -- lolos diam-diam dan PIN resto lain tetap bisa diuji oleh akun mati.
  if public.penyewa_saya() is null then
    return query select false, 0, 'PIN tidak dikenali.';
    return;
  end if;

  if p_pin is null or p_pin !~ '^\d{6}$' then
    return query select false, 0, 'PIN harus tepat 6 angka.';
    return;
  end if;

  -- PR-07 (2026-09-20): aksi berkupon WAJIB menyebut pesanan yang disetujui.
  -- Tanpa ini lahir baris `berhasil=true` tanpa ikatan pesanan yang tidak akan
  -- pernah cocok dengan saringan kupon konsumen (void 0013 / diskon 0016) —
  -- "tulis bisa, pakai mustahil". Edge Function sudah menolak di batas (I F-02);
  -- ini lapis keduanya di database. Percobaan tetap dicatat (berhasil=false)
  -- supaya pemanggil yang berulang kali melanggar ikut terkena pembatas.
  if p_aksi in ('void_sesudah_dapur', 'beri_diskon') and p_pesanan_id is null then
    insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, pemanggil_id, pesanan_id)
    values (v_saya, v_perangkat, false, p_aksi, v_saya, null);
    return query select false, 0,
      format('Aksi %s wajib menyebut pesanan yang disetujui.', p_aksi);
    return;
  end if;

  select p.penyewa_id, p.aktif, k.pin_hash
    into v_penyewa_target, v_aktif_target, v_hash
    from public.pengguna p
    left join public.kredensial_pin k on k.pengguna_id = p.id
   where p.id = p_pengguna_id;

  if v_penyewa_target is null or v_penyewa_target <> public.penyewa_saya() or not coalesce(v_aktif_target, false) then
    -- Jangan membocorkan apakah pegawai itu ada: jawab seperti PIN salah.
    insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, pemanggil_id, pesanan_id)
    values (v_saya, v_perangkat, false, p_aksi, v_saya, p_pesanan_id);
    return query select false, 0, 'PIN tidak dikenali.';
    return;
  end if;

  -- TEMUAN PR-13: yang dibatasi adalah PERCOBAAN ORANG ITU terhadap akun itu;
  -- korban tetap bisa memakai PIN-nya sendiri, penyerang tertahan.
  select count(*) into v_gagal_akun
    from public.percobaan_pin pp
   where pp.pengguna_id = p_pengguna_id
     and pp.pemanggil_id = v_saya
     and not pp.berhasil
     and pp.waktu > now() - make_interval(mins => JENDELA_MENIT);

  select count(*) into v_gagal_alat
    from public.percobaan_pin pp
   where pp.perangkat = v_perangkat
     and pp.pemanggil_id = v_saya
     and not pp.berhasil
     and pp.waktu > now() - make_interval(mins => JENDELA_MENIT);

  if v_gagal_akun >= BATAS_AKUN or v_gagal_alat >= BATAS_PERANGKAT then
    insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, pemanggil_id, pesanan_id)
    values (p_pengguna_id, v_perangkat, false, p_aksi, v_saya, p_pesanan_id);
    return query select false, 0,
      format('PIN terkunci sementara karena terlalu banyak percobaan salah dari perangkat/akun Anda. Coba lagi setelah %s menit.', JENDELA_MENIT);
    return;
  end if;

  v_berhasil := v_hash is not null and crypt(p_pin, v_hash) = v_hash;

  insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, pemanggil_id, pesanan_id)
  values (p_pengguna_id, v_perangkat, v_berhasil, p_aksi, v_saya, p_pesanan_id);

  if not v_berhasil then
    return query select false, greatest(BATAS_AKUN - v_gagal_akun - 1, 0),
      'PIN salah.';
    return;
  end if;

  if p_aksi is not null and not public.boleh_untuk(p_pengguna_id, p_aksi) then
    -- F-16 (2026-09-20): baris berhasil=true di atas adalah CATATAN jujur bahwa
    -- rahasia cocok, BUKAN stempel otorisasi. Konsumen kupon (picu_diskon_setuju_jujur
    -- versi 0016) wajib mengecek ulang izin — lihat BAGIAN 2.
    return query select false, BATAS_AKUN,
      format('PIN benar, tetapi pegawai itu tidak berizin: %s.', p_aksi);
    return;
  end if;

  return query select true, BATAS_AKUN, 'PIN diterima.';
end
$$;

-- ----------------------------------------------------------------------------
-- BAGIAN 2 — F-16: konsumsi kupon diskon mengecek ULANG izin penyetuju
-- ----------------------------------------------------------------------------
-- BUKTI CACAT: versi 0014 menyaring kupon hanya pada berhasil/aksi/pesanan/waktu/
-- belum dipakai. Baris "PIN benar tetapi tidak berizin" (verifikasi_pin menyimpan
-- berhasil=true SEBELUM penolakan izin) lolos saringan itu → dapur yang PIN-nya
-- benar untuk beri_diskon menjadi stempel diskon. Void sudah mengecek ulang izin
-- (0013); diskon kini menyusul. Uji: supabase/tes/diskon_setuju.sql (blok F-16).
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

  -- F-16 (2026-09-20): kecocokan rahasia BUKAN otorisasi. Cek ulang izin aksi
  -- saat kupon dikonsumsi — sama seperti picu_pembatalan_sah untuk void (0013).
  if not public.boleh_untuk(new.disetujui_oleh, 'beri_diskon') then
    raise exception 'Penyetuju diskon tidak berizin untuk aksi beri_diskon.';
  end if;

  update public.percobaan_pin pp set dipakai_pada = now() where pp.id = v_kupon;
  return new;
end
$$;

-- ----------------------------------------------------------------------------
-- BAGIAN 3 — F-14: catatan percobaan simpan_pin tidak boleh ikut tergulung balik
-- ----------------------------------------------------------------------------
-- BUKTI CACAT: jalur "PIN lama salah" dan "hierarki peran" memakai RAISE sesudah
-- insert catatan → seluruh transaksi RPC abort → catatan percobaan hilang →
-- pembatas tebakan (5/15 menit & 20/15 menit) tidak pernah menyala untuk dua
-- jalur itu. Pola perbaikannya sama dengan yang sudah dipakai jalur "melebihi
-- batas": kembalikan PESAN, bukan exception, supaya catatan bertahan.
-- Uji: supabase/tes/kredensial_pin.sql (blok F-14).
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

    -- HIERARKI PERAN (putaran13 #2 PR-01): PIN orang lain hanya boleh diubah oleh
    -- peran yang LEBIH TINGGI. F-14 (2026-09-20): penolakan dikembalikan sebagai
    -- PESAN supaya catatan percobaan bertahan dan pembatas bisa menyala.
    if not public.peran_lebih_tinggi(v_saya, v_target) then
      insert into public.percobaan_simpan_pin (pengguna_id, target_id, perangkat, berhasil, alasan)
      values (v_saya, v_target, v_perangkat, false, 'hierarki peran');
      return 'Peran Anda tidak lebih tinggi dari pegawai itu — PIN-nya hanya boleh diganti oleh atasan atau dirinya sendiri.';
    end if;
  end if;

  -- Ganti PIN sendiri WAJIB memakai PIN lama (kecuali belum pernah punya PIN).
  -- F-14 (2026-09-20): kegagalan dikembalikan sebagai PESAN (bukan raise) supaya
  -- catatan percobaan PIN-lama-salah di verifikasi_pin TIDAK tergulung balik —
  -- tanpa ini tebakan PIN lama lewat simpan_pin tidak pernah terhitung.
  if v_target = v_saya then
    if p_pin_lama ~ '^\d{4}$' then
      -- PR-09 (2026-09-20): PIN warisan 4 angka (dipasang sebelum aturan 6 angka)
      -- dulu BUNTU: verifikasi_pin menuntut 6 angka sehingga PIN lama 4 angka
      -- selalu "salah", dan pemiliknya tak bisa naik kelas swadaya. Sekarang
      -- PIN 4 angka diterima HANYA sebagai PIN lama untuk naik ke 6 angka —
      -- dicocokkan langsung ke hash, dengan pembatas tebakan & catatan yang sama.
      select count(*) into v_probe
        from public.percobaan_pin pp
       where pp.pengguna_id = v_target
         and pp.pemanggil_id = v_saya
         and not pp.berhasil
         and pp.waktu > now() - make_interval(mins => JENDELA_MENIT);
      if v_probe >= 5 then
        insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, pemanggil_id)
        values (v_target, v_perangkat, false, v_saya);
        return format('PIN lama salah. Coba lagi setelah %s menit (terlalu banyak percobaan).', JENDELA_MENIT);
      end if;
      select k.pin_hash into v_hash from public.kredensial_pin k where k.pengguna_id = v_target;
      if v_hash is not null and crypt(p_pin_lama, v_hash) <> v_hash then
        insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, pemanggil_id)
        values (v_target, v_perangkat, false, v_saya);
        return 'PIN lama salah. PIN warisan 4 angka hanya bisa dipakai untuk naik ke PIN 6 angka.';
      end if;
      -- cocok (atau memang belum pernah punya PIN): lanjut menyimpan PIN baru.
    else
      select * into v_periksa
        from public.verifikasi_pin(v_target, coalesce(p_pin_lama, ''), null, v_perangkat);
      if exists (select 1 from public.kredensial_pin k where k.pengguna_id = v_target)
         and not v_periksa.berhasil then
        return format('PIN lama salah. %s', v_periksa.pesan);
      end if;
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
-- BAGIAN 4 — F-13: peran_lebih_tinggi dipagari penyewa & pemanggil aktif
-- ----------------------------------------------------------------------------
-- BUKTI CACAT: versi 0014 = security definer + grant authenticated + dua UUID
-- bebas → akun authenticated mana pun bisa membandingkan peringkat peran dua
-- pegawai RESTO LAIN (oracle metadata peran). Pagar: pemanggil wajib aktif &
-- sepenyewa dengan KEDUA argumen; bila tidak, jawab false (netral, tanpa
-- membedakan alasan supaya tidak jadi saluran bocoran baru).
-- Uji: supabase/tes/isolasi_lintas_penyewa.sql (blok F-13).
create or replace function public.peran_lebih_tinggi(p_pemanggil uuid, p_target uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  -- Lapis 2 (F-11, DIPERTAHANKAN dari 0015): identitas pemanggil dipakukan ke
  -- auth.uid(); tanpa identitas (peladen) pemeriksaan dilewati seperti jalur peladen lain.
  if auth.uid() is not null and p_pemanggil is distinct from auth.uid() then
    return false;
  end if;
  -- Lapis 3 (I F-13, 2026-09-20): defence-in-depth — walau kelak hak panggil
  -- dilonggarkan, perbandingan lintas penyewa tetap netral: pemanggil wajib
  -- aktif & sepenyewa dengan KEDUA argumen; jawab false tanpa membedakan alasan.
  if public.penyewa_saya() is not null
     and (not public.sepenyewa(p_pemanggil) or not public.sepenyewa(p_target)) then
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
  'Benar bila peran pemanggil lebih tinggi dari peran target (hierarki PIN). Dipakai simpan_pin supaya bawahan tidak bisa merebut PIN atasan. Sejak 0016: hanya bermakna di dalam penyewa pemanggil sendiri (F-13).';

-- ----------------------------------------------------------------------------
-- BAGIAN 5 — PR-08 (review putaran16): saldo awal stok wajib lewat buku besar
-- ----------------------------------------------------------------------------
-- BUKTI CACAT: `insert into stok_bahan (... jumlah 500)` menciptakan saldo dari
-- ketiadaan — nol baris di `stok_pergerakan` (buku besar yang jadi satu-satunya
-- asal-usul angka stok). Penjaga lama hanya menolak UPDATE jumlah di luar buku
-- besar (0007 pemicu 3); INSERT lolos. Kini INSERT dengan jumlah bukan-nol
-- DITOLAK: bahan dibuat dengan saldo 0, lalu saldo awal dicatat sebagai baris
-- buku besar (jenis 'opname'/'masuk') yang otomatis menjumlah ke saldo (0007
-- pemicu 2) — jejak asal-usul, pelaku, dan waktunya ada. Uji: supabase/tes/saldo_awal_stok.sql.
create or replace function public.picu_stok_saldo_awal()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if coalesce(new.jumlah, 0) <> 0 then
    raise exception 'Saldo awal tidak boleh ditulis langsung — buat bahan dengan saldo 0 lalu catat saldonya lewat pergerakan stok (jenis opname/masuk) supaya buku besarnya lengkap.';
  end if;
  return new;
end
$$;

drop trigger if exists stok_bahan_saldo_awal on public.stok_bahan;
create trigger stok_bahan_saldo_awal
  before insert on public.stok_bahan
  for each row execute function public.picu_stok_saldo_awal();

-- ----------------------------------------------------------------------------
-- BAGIAN 6 — PR-14 (review putaran16): hak fungsi dikoreksi dua arah
-- ----------------------------------------------------------------------------
-- BUKTI CACAT: (a) `revoke all ... from public` di 0014 ikut mencabut hak
-- `service_role` (peran peladen) pada `hitung_total` — jalur resmi peladen ikut
-- mati, padahal `nomor_pesanan_berikutnya` & `peran_lebih_tinggi` sudah
-- dipulihkan di 0015; (b) `peringkat_peran` lahir tanpa revoke sehingga ANON
-- bisa memanggilnya — peta hierarki peran resto tidak perlu dibaca publik.
-- Uji: supabase/tes/hak_fungsi.sql.
grant execute on function public.hitung_total(uuid) to service_role;

revoke all on function public.peringkat_peran(text) from public;
grant execute on function public.peringkat_peran(text) to authenticated, service_role;

-- ----------------------------------------------------------------------------
-- BAGIAN 7 — PR-15 (review putaran16): hapus meja tidak memutus riwayat pesanan
-- ----------------------------------------------------------------------------
-- BUKTI CACAT: `pesanan.meja_id` memakai `on delete set null`, dan penjaga 0014
-- hanya menolak hapus bila masih ada pesanan AKTIF — meja dengan riwayat pesanan
-- lunas/batal bisa dihapus sehingga laporan kehilangan "meja mana". Sejak 0016:
-- meja yang punya riwayat pesanan TIDAK bisa dihapus sama sekali; jalurnya adalah
-- nonaktifkan (aktif = false). Definisi 0014 disalin utuh selain cabang DELETE
-- (0014 beku; yang berlaku = create or replace terakhir).
-- Uji: supabase/tes/meja_riwayat.sql + probe lama pr15-meja-terputus.sql (kini GAGAL).
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
    -- PR-15 (2026-09-20): SEMUA riwayat dihitung, bukan hanya pesanan aktif —
    -- pesanan lunas/batal justru bukti yang tidak boleh kehilangan mejanya.
    select count(*) into v_pesanan
      from public.pesanan p
     where p.meja_id = old.id;
    if v_pesanan > 0 then
      raise exception 'Meja ini punya % pesanan dalam riwayat (termasuk yang sudah lunas/batal) — tidak boleh dihapus supaya riwayat "meja mana" tidak putus; nonaktifkan saja (aktif = false).', v_pesanan;
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
