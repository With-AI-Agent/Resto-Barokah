-- ============================================================================
-- MIGRASI 0098 — PMB1-F-038 BAGIAN B, OPSI 1 (keputusan Lee 2026-10-04):
-- pakai voucher wajib persetujuan PIN atasan — DISIAPKAN DI BALIK SAKLAR MATI
-- (pola klaster B: disiapkan sekarang, dipasang Lee sebelum pilot data nyata).
-- ============================================================================
-- Skenario kerugian Bagian B F-038: kasir mendaftarkan pelanggan FIKTIF lewat
-- jalur kasir (yang memang dirancang tanpa Gmail) lalu mencairkan vouchernya
-- pada tamu yang membayar penuh memakai PIN-nya SENDIRI — kas tetap cocok.
-- Migrasi 0097 (opsi 3) membuat serangan MASSAL mahal; migrasi ini menutup
-- pencairan sepihak: bila saklar menyala, setiap pakai voucher butuh orang
-- kedua yang benar-benar menekan PIN-nya untuk pesanan itu.
--
-- Cara kerja:
--   1. `pengaturan.wajib_pin_atasan_pakai_voucher` boolean NOT NULL DEFAULT
--      FALSE (saklar MATI bawaan — produksi & masa percobaan tidak berubah
--      sampai Lee menyalakannya per penyewa).
--   2. `voucher.pakai_disetujui_oleh` — jejak audit siapa yang menyetujui.
--   3. `pakai_voucher` (definisi berlaku terakhir: 0067) ditulis ulang dengan
--      pagar baru SESUDAH PIN kasir + validasi pesanan + rate-limit, SEBELUM
--      cek idempoten. Mekanisme bukti = stempel `percobaan_pin` (aksi
--      'pakai_voucher', terikat pesanan, < 5 menit, sekali pakai) — pola yang
--      SAMA persis dengan persetujuan diskon T5-05 (0016/0041) dan void dapur
--      (0013). Overload lama 6-paramater DI-DROP supaya tidak ada jalan
--      pintas tanpa pagar.
--
-- Cara menyalakan (milik Lee/operator, DASHBOARD):
--   update public.pengaturan set wajib_pin_atasan_pakai_voucher = true
--    where penyewa_id = '<penyewa>';
--
-- Dijaga oleh uji `supabase/tes/pakai_voucher_pin_atasan.sql` (MERAH tanpa
-- 0098, HIJAU dengannya; saklar mati = perilaku lama, saklar menyala = wajib
-- stempel PIN atasan sekali pakai, penyetuju tak berizin ditolak).
-- RUJUKAN: kartu K-F-03, H-F-03.5, H-F-03.6; putusan Lee 2026-10-04 (REKAM §31
-- butir 25 + USULAN_PERAN_PEMBANGUN §10).
-- ============================================================================

-- 1. Saklar (BAWAAN MATI).
alter table public.pengaturan
  add column if not exists wajib_pin_atasan_pakai_voucher boolean not null default false;

comment on column public.pengaturan.wajib_pin_atasan_pakai_voucher is
  'PMB1-F-038 Bagian B opsi 1 (keputusan Lee 2026-10-04): bila TRUE, pakai voucher wajib persetujuan PIN atasan (stempel percobaan_pin sekali pakai, 5 menit). Bawaan FALSE = perilaku lama.';

-- 2. Jejak audit penyetuju pada voucher.
alter table public.voucher
  add column if not exists pakai_disetujui_oleh uuid references public.pengguna (id) on delete set null;

comment on column public.voucher.pakai_disetujui_oleh is
  'Pegawai (atasan) yang PIN-nya terbukti menyetujui pemakaian voucher ini (PMB1-F-038 Bagian B opsi 1); NULL bila saklar mati.';

-- 3. Buang overload lama supaya tidak ada jalan pintas tanpa pagar.
drop function if exists public.pakai_voucher(uuid, text, text, text, text, text);

-- 4. `pakai_voucher` ditulis ulang dengan pagar saklar (parameter baru di ujung;
--    semua panggilan lama tetap sah).
create or replace function public.pakai_voucher(
  p_pesanan_id uuid,
  p_kode text,
  p_pin_kasir text,
  p_kunci_idempoten text default null,
  p_perangkat text default null,
  p_ip text default null,
  p_disetujui_oleh uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_kode text := upper(trim(coalesce(p_kode, '')));
  v_saya uuid := auth.uid();
  v_pesanan record;
  v_voucher record;
  v_kampanye record;
  v_pelanggan record;
  v_kasir record;
  v_potongan integer := 0;
  v_diskon_sudah record;
  v_tumpuk boolean;
  v_pemakaian_hari_ini integer;
  v_tgl_lokal date;
  v_total_anggaran_terpakai numeric;
  v_wajib_atasan boolean;
  v_kupon bigint;
  v_penyetuju uuid := null;
begin
  if v_saya is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TIDAK_TERAUTENTIKASI',
      'pesan', 'Anda harus masuk sebagai kasir untuk menggunakan voucher.'
    );
  end if;

  -- 1. Izin kasir
  if not public.boleh('pakai_voucher') then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TIDAK_BERIZIN',
      'pesan', 'Anda tidak memiliki izin untuk memakai voucher.'
    );
  end if;

  -- 2. Verifikasi PIN Kasir
  select p.*, k.pin_hash
    into v_kasir
    from public.pengguna p
    left join public.kredensial_pin k on k.pengguna_id = p.id
   where p.id = v_saya;

  if v_kasir.id is null or not coalesce(v_kasir.aktif, false) or v_kasir.pin_hash is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KASIR_TIDAK_VALID',
      'pesan', 'Akun kasir tidak aktif atau belum memiliki PIN.'
    );
  end if;

  if p_pin_kasir is null or p_pin_kasir = '' or crypt(p_pin_kasir, v_kasir.pin_hash) is distinct from v_kasir.pin_hash then
    insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, pesanan_id)
    values (v_saya, coalesce(p_perangkat, 'kasir'), false, 'pakai_voucher', p_pesanan_id);

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PIN_SALAH',
      'pesan', 'PIN kasir tidak sah. Mohon periksa kembali PIN Anda.'
    );
  end if;

  insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, pesanan_id)
  values (v_saya, coalesce(p_perangkat, 'kasir'), true, 'pakai_voucher', p_pesanan_id);

  -- 3. Verifikasi Pesanan
  select * into v_pesanan
    from public.pesanan
   where id = p_pesanan_id;

  if v_pesanan.id is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PESANAN_TIDAK_DITEMUKAN',
      'pesan', 'Pesanan tidak ditemukan.'
    );
  end if;

  if v_pesanan.status in ('lunas', 'batal') then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PESANAN_SUDAH_SELESAI',
      'pesan', 'Pesanan sudah berstatus ' || v_pesanan.status || '; voucher tidak dapat ditambahkan.'
    );
  end if;

  if coalesce(v_pesanan.subtotal, 0) <= 0 then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'SUBTOTAL_KOSONG',
      'pesan', 'Pesanan belum memiliki item atau subtotal masih 0.'
    );
  end if;

  -- Lapis 8: Batas Percobaan Per Perangkat / IP (Rate Limiting Brute Force Protection)
  if public.apakah_perangkat_terblokir(v_pesanan.penyewa_id, p_perangkat, p_ip) then
    insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
    values (v_pesanan.penyewa_id, v_kode, 'gagal', 'Terlalu banyak percobaan kode voucher yang gagal.', v_saya, v_pesanan.cabang_id, p_perangkat, p_ip, 'pakai', now());

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TERLALU_BANYAK_PERCOBAAN',
      'pesan', 'Terlalu banyak percobaan kode voucher yang gagal dari perangkat ini. Mohon tunggu 15 menit.'
    );
  end if;

  -- Lapis BARU (PMB1-F-038 Bagian B, OPSI 1 — keputusan Lee 2026-10-04):
  -- PERSETUJUAN PIN ATASAN UNTUK PAKAI VOUCHER, DI BALIK SAKLAR MATI (klaster B).
  -- Saklar `pengaturan.wajib_pin_atasan_pakai_voucher` bawaan FALSE: perilaku
  -- lama PERSIS. Bila menyala: kasir tidak bisa mencairkan voucher sendirian —
  -- harus ada bukti orang KEDUA yang benar-benar menekan PIN-nya untuk pesanan
  -- ini (stempel `percobaan_pin` aksi 'pakai_voucher': terikat pesanan, belum
  -- dipakai, berumur < 5 menit — pola yang sama dengan persetujuan diskon T5-05
  -- di 0016/0041). Penyetuju tidak boleh kasir yang sama dan harus berizin
  -- `pakai_voucher`. Menutup skenario kerugian Bagian B: kasir mengarang
  -- pelanggan lalu mencairkan vouchernya dengan PIN-nya sendiri.
  select coalesce(pg.wajib_pin_atasan_pakai_voucher, false)
    into v_wajib_atasan
    from public.pengaturan pg
   where pg.penyewa_id = v_pesanan.penyewa_id;

  if coalesce(v_wajib_atasan, false) then
    if p_disetujui_oleh is null or p_disetujui_oleh = v_saya then
      insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
      values (v_pesanan.penyewa_id, v_kode, 'gagal', 'Pakai voucher wajib persetujuan atasan.', v_saya, v_pesanan.cabang_id, p_perangkat, p_ip, 'pakai', now());

      return jsonb_build_object(
        'berhasil', false,
        'kode', 'PERSETUJUAN_ATASAN_WAJIB',
        'pesan', 'Pakai voucher di resto ini wajib persetujuan atasan. Minta atasan menekan PIN-nya untuk pesanan ini.'
      );
    end if;

    -- F-16 pola 0016: kecocokan rahasia BUKAN otorisasi — cek ulang izin penyetuju.
    if not public.boleh_untuk(p_disetujui_oleh, 'pakai_voucher') then
      insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
      values (v_pesanan.penyewa_id, v_kode, 'gagal', 'Penyetuju tidak berizin pakai_voucher.', v_saya, v_pesanan.cabang_id, p_perangkat, p_ip, 'pakai', now());

      return jsonb_build_object(
        'berhasil', false,
        'kode', 'PERSETUJUAN_ATASAN_WAJIB',
        'pesan', 'Pegawai yang dimintai persetujuan tidak berizin memakai voucher.'
      );
    end if;

    -- Bukti harus TERIKAT pesanan ini, oleh orang itu, untuk aksi ini, belum dipakai.
    select pp.id into v_kupon
      from public.percobaan_pin pp
     where pp.pengguna_id = p_disetujui_oleh
       and pp.berhasil
       and pp.aksi = 'pakai_voucher'
       and pp.pesanan_id = p_pesanan_id
       and pp.dipakai_pada is null
       and pp.waktu > now() - interval '5 minutes'
     order by pp.waktu
     limit 1
     for update;

    if v_kupon is null then
      insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
      values (v_pesanan.penyewa_id, v_kode, 'gagal', 'Persetujuan atasan belum terbukti (PIN untuk pesanan ini tidak ada/kedaluwarsa).', v_saya, v_pesanan.cabang_id, p_perangkat, p_ip, 'pakai', now());

      return jsonb_build_object(
        'berhasil', false,
        'kode', 'PERSETUJUAN_ATASAN_WAJIB',
        'pesan', 'Persetujuan belum terbukti: atasan harus menekan PIN-nya sendiri untuk pesanan ini (maksimal 5 menit lalu).'
      );
    end if;

    update public.percobaan_pin pp set dipakai_pada = now() where pp.id = v_kupon;
    v_penyetuju := p_disetujui_oleh;
  end if;

  -- 4. Idempoten: Cek apakah voucher ini sudah tercatat pada pesanan ini
  select dt.* into v_diskon_sudah
    from public.diskon_transaksi dt
    join public.voucher v on v.id = dt.voucher_id
   where dt.pesanan_id = p_pesanan_id
     and v.kode = v_kode;

  if v_diskon_sudah.id is not null then
    return jsonb_build_object(
      'berhasil', true,
      'kode', 'IDEMPOTEN',
      'pesan', 'Voucher sudah diterapkan pada pesanan ini.',
      'data', jsonb_build_object(
        'diskon_id', v_diskon_sudah.id,
        'nilai_potongan', v_diskon_sudah.nilai,
        'kode_voucher', v_kode
      )
    );
  end if;

  -- 5. Cek Pengaturan Tumpuk Diskon
  select p.tumpuk_diskon into v_tumpuk
    from public.pengaturan p
   where p.penyewa_id = v_pesanan.penyewa_id;

  if not coalesce(v_tumpuk, false) and exists (
    select 1 from public.diskon_transaksi where pesanan_id = p_pesanan_id
  ) then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TUMPUK_DISKON_DILARANG',
      'pesan', 'Resto ini hanya mengizinkan satu diskon per transaksi.'
    );
  end if;

  -- Lapis 6: Kunci Atomik Sekali Pakai (ART-5)
  update public.voucher
     set status = 'terpakai',
         terpakai_pada = now(),
         terpakai_di_cabang = v_pesanan.cabang_id,
         terpakai_oleh = v_saya,
         pakai_disetujui_oleh = v_penyetuju,
         pesanan_id = p_pesanan_id
   where kode = v_kode
     and penyewa_id = v_pesanan.penyewa_id
     and status = 'aktif'
     and (berlaku_sampai is null or berlaku_sampai >= now())
  returning * into v_voucher;

  if v_voucher.id is null then
    select * into v_voucher from public.voucher where kode = v_kode and penyewa_id = v_pesanan.penyewa_id;
    insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
    values (v_pesanan.penyewa_id, v_kode, 'gagal', 'Voucher tidak dapat dipakai.', v_saya, v_pesanan.cabang_id, p_perangkat, p_ip, 'pakai', now());

    if v_voucher.id is null then
      return jsonb_build_object('berhasil', false, 'kode', 'VOUCHER_TIDAK_DITEMUKAN', 'pesan', 'Voucher tidak ditemukan.');
    elsif v_voucher.status = 'terpakai' then
      return jsonb_build_object('berhasil', false, 'kode', 'VOUCHER_SUDAH_TERPAKAI', 'pesan', 'Voucher ini sudah pernah digunakan.');
    elsif v_voucher.status = 'dibatalkan' then
      return jsonb_build_object('berhasil', false, 'kode', 'VOUCHER_DIBATALKAN', 'pesan', 'Voucher ini telah dibatalkan.');
    else
      return jsonb_build_object('berhasil', false, 'kode', 'VOUCHER_KEDALUWARSA', 'pesan', 'Masa berlaku voucher telah berakhir.');
    end if;
  end if;

  select * into v_kampanye from public.kampanye_voucher where id = v_voucher.kampanye_id;
  select * into v_pelanggan from public.pelanggan where id = v_voucher.pelanggan_id;

  -- Cabang Berlaku
  if v_kampanye.cabang_berlaku is not null
     and jsonb_typeof(v_kampanye.cabang_berlaku) = 'array'
     and jsonb_array_length(v_kampanye.cabang_berlaku) > 0 then
    if not (v_kampanye.cabang_berlaku @> jsonb_build_array(v_pesanan.cabang_id::text)) then
      update public.voucher set status = 'aktif', terpakai_pada = null, terpakai_di_cabang = null, terpakai_oleh = null, pakai_disetujui_oleh = null, pesanan_id = null where id = v_voucher.id;
      insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
      values (v_pesanan.penyewa_id, v_kode, 'gagal', 'Cabang tidak berlaku.', v_saya, v_pesanan.cabang_id, p_perangkat, p_ip, 'pakai', now());

      return jsonb_build_object('berhasil', false, 'kode', 'CABANG_TIDAK_BERLAKU', 'pesan', 'Voucher ini tidak berlaku di cabang ini.');
    end if;
  end if;

  -- Lapis 2: Batas Voucher Per Outlet Per Hari (kuota_harian_cabang)
  if v_kampanye.kuota_harian_cabang is not null and v_kampanye.kuota_harian_cabang > 0 then
    v_tgl_lokal := public.tanggal_lokal_cabang(v_pesanan.cabang_id, now());
    select count(*)
      into v_pemakaian_hari_ini
      from public.voucher
     where kampanye_id = v_kampanye.id
       and terpakai_di_cabang = v_pesanan.cabang_id
       and status = 'terpakai'
       and id <> v_voucher.id
       and public.tanggal_lokal_cabang(terpakai_di_cabang, terpakai_pada) = v_tgl_lokal;

    if v_pemakaian_hari_ini >= v_kampanye.kuota_harian_cabang then
      update public.voucher set status = 'aktif', terpakai_pada = null, terpakai_di_cabang = null, terpakai_oleh = null, pakai_disetujui_oleh = null, pesanan_id = null where id = v_voucher.id;
      insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
      values (v_pesanan.penyewa_id, v_kode, 'gagal', 'Kuota harian cabang habis.', v_saya, v_pesanan.cabang_id, p_perangkat, p_ip, 'pakai', now());

      return jsonb_build_object('berhasil', false, 'kode', 'KUOTA_HARIAN_CABANG_HABIS', 'pesan', 'Kuota harian voucher kampanye ini untuk cabang ini sudah habis hari ini.');
    end if;
  end if;

  -- Lapis 3: Wajib Belanja Minimum (min_belanja)
  if v_pesanan.subtotal < v_kampanye.min_belanja then
    update public.voucher set status = 'aktif', terpakai_pada = null, terpakai_di_cabang = null, terpakai_oleh = null, pakai_disetujui_oleh = null, pesanan_id = null where id = v_voucher.id;
    insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
    values (v_pesanan.penyewa_id, v_kode, 'gagal', 'Subtotal kurang dari minimum belanja.', v_saya, v_pesanan.cabang_id, p_perangkat, p_ip, 'pakai', now());

    return jsonb_build_object('berhasil', false, 'kode', 'SUBTOTAL_KURANG', 'pesan', 'Subtotal pesanan belum memenuhi minimum belanja Rp ' || public.format_rupiah(v_kampanye.min_belanja) || '.');
  end if;

  -- Lapis 4: Hitung Nilai Potongan Diskon (Plafon maks_potongan)
  if v_kampanye.jenis = 'persen' then
    v_potongan := floor((v_pesanan.subtotal * v_kampanye.nilai) / 100)::integer;
    if v_kampanye.maks_potongan is not null and v_potongan > v_kampanye.maks_potongan then
      v_potongan := v_kampanye.maks_potongan::integer;
    end if;
  else
    v_potongan := v_kampanye.nilai::integer;
  end if;

  if v_potongan > v_pesanan.subtotal then
    v_potongan := v_pesanan.subtotal::integer;
  end if;

  -- Lapis 5: Anggaran Kampanye Tidak Bisa Dilampaui (anggaran_maks)
  if v_kampanye.anggaran_maks is not null and v_kampanye.anggaran_maks > 0 then
    select coalesce(sum(dt.nilai), 0)
      into v_total_anggaran_terpakai
      from public.diskon_transaksi dt
      join public.voucher v on v.id = dt.voucher_id
     where v.kampanye_id = v_kampanye.id;

    if v_total_anggaran_terpakai + v_potongan > v_kampanye.anggaran_maks then
      update public.voucher set status = 'aktif', terpakai_pada = null, terpakai_di_cabang = null, terpakai_oleh = null, pakai_disetujui_oleh = null, pesanan_id = null where id = v_voucher.id;
      insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
      values (v_pesanan.penyewa_id, v_kode, 'gagal', 'Anggaran kampanye habis.', v_saya, v_pesanan.cabang_id, p_perangkat, p_ip, 'pakai', now());

      return jsonb_build_object('berhasil', false, 'kode', 'ANGGARAN_KAMPANYE_HABIS', 'pesan', 'Anggaran promo kampanye ini sudah mencapai batas maksimal.');
    end if;
  end if;

  -- Rekam Diskon Transaksi
  insert into public.diskon_transaksi (
    pesanan_id,
    jenis,
    persen,
    nominal,
    nilai,
    alasan,
    pelaku_id,
    voucher_id
  ) values (
    p_pesanan_id,
    'voucher',
    case when v_kampanye.jenis = 'persen' then v_kampanye.nilai else null end,
    case when v_kampanye.jenis = 'nominal' then v_kampanye.nilai else null end,
    v_potongan,
    'Voucher: ' || v_kampanye.nama || ' (' || v_kode || ')',
    v_saya,
    v_voucher.id
  );

  -- Lapis 8: Catat Percobaan Sukses
  insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
  values (v_pesanan.penyewa_id, v_kode, 'pakai_berhasil', 'Pemakaian voucher berhasil.', v_saya, v_pesanan.cabang_id, p_perangkat, p_ip, 'pakai', now());

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SUKSES',
    'pesan', 'Voucher berhasil digunakan.',
    'data', jsonb_build_object(
      'voucher_id', v_voucher.id,
      'kode_voucher', v_kode,
      'nilai_potongan', v_potongan,
      'nama_kampanye', v_kampanye.nama,
      'nama_pelanggan', v_pelanggan.nama
    )
  );
end;
$$;


revoke all on function public.pakai_voucher(uuid, text, text, text, text, text, uuid) from public, anon;
grant execute on function public.pakai_voucher(uuid, text, text, text, text, text, uuid) to authenticated, service_role;
