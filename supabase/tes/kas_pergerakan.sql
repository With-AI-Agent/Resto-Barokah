-- ===========================================================================
-- Uji SQL: Kas Pergerakan (T7-03 — Uang Masuk, Keluar, Setoran, dan Koreksi)
-- Memastikan PRD M7, TECH_SPEC §4.3, §5, §9 ART-6:
-- 1. Kas masuk, kas keluar, dan setoran dapat dicatat pada shift terbuka.
-- 2. Jumlah wajib > 0 dan alasan wajib diisi (bukan spasi kosong).
-- 3. Jenis di luar ('masuk', 'keluar', 'setoran', 'koreksi') ditolak.
-- 4. Shift tertutup menolak kas masuk/keluar/setoran baru.
-- 5. Koreksi diizinkan pada shift tertutup (append-only ledger).
-- 6. Integrasi dengan tutup_shift: uang_seharusnya mencakup kas_pergerakan.
-- 7. Idempotency key mencegah dobel pencatatan.
-- 8. Baris kas_pergerakan kebal dari UPDATE dan DELETE (kekal).
-- 9. Jejak audit kriptografis tercatat di catatan_audit.
-- 10. Peran tanpa wewenang (mis. pelayan) ditolak.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Kasus 1: Kas masuk (tambah modal / receh kembalian) pada shift terbuka
-- ---------------------------------------------------------------------------
-- Rina (kasir A1): 90000000-0000-0000-0000-000000000004, cabang: a1a1a1a1-0000-0000-0000-000000000001
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- Buka shift baru untuk Rina
select public.buka_shift(
  p_modal_awal := 100000,
  p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001',
  p_catatan := 'Shift Pagi Kasir 1'
);

-- Catat uang masuk
select public.kas_pergerakan(
  p_jenis := 'masuk',
  p_jumlah := 50000,
  p_alasan := 'Tambah uang kembalian pecahan 2000 dan 5000 dari bank',
  p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001',
  p_kunci_idempoten := 'kunci-uji-kas-masuk-001'
);

-- Verifikasi data tercatat di tabel
select uji.sama(
  (select count(*)::integer from public.kas_pergerakan where kunci_idempoten = 'kunci-uji-kas-masuk-001'),
  1,
  'Kas masuk berhasil dicatat ke tabel kas_pergerakan'
);

select uji.sama(
  (select jumlah from public.kas_pergerakan where kunci_idempoten = 'kunci-uji-kas-masuk-001'),
  50000,
  'Nominal kas masuk sesuai'
);

-- ---------------------------------------------------------------------------
-- Kasus 2: Kas keluar (belanja operasional mendadak) pada shift terbuka
-- ---------------------------------------------------------------------------
select public.kas_pergerakan(
  p_jenis := 'keluar',
  p_jumlah := 35000,
  p_alasan := 'Beli es batu kristal 2 kantong',
  p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001',
  p_kunci_idempoten := 'kunci-uji-kas-keluar-001'
);

select uji.sama(
  (select jumlah from public.kas_pergerakan where kunci_idempoten = 'kunci-uji-kas-keluar-001'),
  35000,
  'Nominal kas keluar operasional sesuai'
);

-- ---------------------------------------------------------------------------
-- Kasus 3: Setoran tunai (ambil uang dari laci kas disetor ke brankas)
-- ---------------------------------------------------------------------------
select public.kas_pergerakan(
  p_jenis := 'setoran',
  p_jumlah := 40000,
  p_alasan := 'Setoran berkala ke brankas owner',
  p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001',
  p_kunci_idempoten := 'kunci-uji-kas-setoran-001'
);

select uji.sama(
  (select jenis from public.kas_pergerakan where kunci_idempoten = 'kunci-uji-kas-setoran-001'),
  'setoran',
  'Jenis setoran tercatat dengan benar'
);

-- ---------------------------------------------------------------------------
-- Kasus 4: Penolakan jumlah uang 0 atau negatif
-- ---------------------------------------------------------------------------
select uji.harap_gagal_sebab(
  $$
    select public.kas_pergerakan(
      p_jenis := 'masuk',
      p_jumlah := 0,
      p_alasan := 'Uang nol',
      p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001'
    );
  $$,
  'lebih besar dari 0',
  'Penolakan jumlah uang 0'
);

select uji.harap_gagal_sebab(
  $$
    select public.kas_pergerakan(
      p_jenis := 'keluar',
      p_jumlah := -15000,
      p_alasan := 'Uang negatif',
      p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001'
    );
  $$,
  'lebih besar dari 0',
  'Penolakan jumlah uang negatif'
);

-- ---------------------------------------------------------------------------
-- Kasus 5: Penolakan alasan kosong atau hanya spasi
-- ---------------------------------------------------------------------------
select uji.harap_gagal_sebab(
  $$
    select public.kas_pergerakan(
      p_jenis := 'keluar',
      p_jumlah := 10000,
      p_alasan := '   ',
      p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001'
    );
  $$,
  'Alasan pergerakan kas wajib diisi',
  'Penolakan alasan kosong'
);

-- ---------------------------------------------------------------------------
-- Kasus 6: Penolakan jenis pergerakan kas tidak sah
-- ---------------------------------------------------------------------------
select uji.harap_gagal_sebab(
  $$
    select public.kas_pergerakan(
      p_jenis := 'pinjam_bos',
      p_jumlah := 10000,
      p_alasan := 'Jenis ngawur',
      p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001'
    );
  $$,
  'Jenis pergerakan kas tidak sah',
  'Penolakan jenis tidak valid'
);

-- ---------------------------------------------------------------------------
-- Kasus 7: Integrasi ke tutup_shift (uang seharusnya memperhitungkan pergerakan kas)
-- Modal awal: 100.000
-- Kas masuk:   50.000
-- Kas keluar:  35.000
-- Setoran:     40.000
-- Uang seharusnya = 100.000 + 50.000 - (35.000 + 40.000) = 75.000
-- ---------------------------------------------------------------------------
select uji.sama(
  (
    select (res->'data'->>'uang_seharusnya')::integer
      from (select public.tutup_shift(p_uang_fisik := 75000) as res) sub
  ),
  75000,
  'Tutup shift menghitung uang_seharusnya secara akurat dengan kas masuk dan keluar'
);

-- ---------------------------------------------------------------------------
-- Kasus 8: Penolakan kas operasional (masuk/keluar/setoran) pada shift yang sudah ditutup
-- ---------------------------------------------------------------------------
select uji.harap_gagal_sebab(
  $$
    select public.kas_pergerakan(
      p_jenis := 'keluar',
      p_jumlah := 10000,
      p_alasan := 'Beli plastik setelah tutup kas',
      p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001'
    );
  $$,
  'Tidak ada shift kas terbuka',
  'Penolakan pergerakan kas bila tidak ada shift terbuka'
);

-- Ambil ID shift yang baru saja ditutup
do $$
declare
  v_shift_tutup uuid;
begin
  select id into v_shift_tutup
    from public.shift_kas
   where dibuka_oleh = '90000000-0000-0000-0000-000000000004'
     and status = 'ditutup'
   order by ditutup_pada desc
   limit 1;

  -- Mencoba memasukkan keluar secara eksplisit ke shift tertutup
  begin
    perform public.kas_pergerakan(
      p_jenis := 'keluar',
      p_jumlah := 10000,
      p_alasan := 'Beli gula',
      p_shift_id := v_shift_tutup
    );
    raise exception 'Seharusnya gagal memasukkan kas keluar ke shift tertutup';
  exception when others then
    if sqlerrm not like '%Uang tidak dapat keluar/masuk di shift tertutup%' then
      raise exception 'Pesan error tidak sesuai: %', sqlerrm;
    end if;
  end;
end;
$$;

-- ---------------------------------------------------------------------------
-- Kasus 9: Koreksi pasca-tutup kas (ART-6: baris kas_pergerakan baru bertanda koreksi)
-- ---------------------------------------------------------------------------
do $$
declare
  v_shift_tutup uuid;
  v_hasil jsonb;
begin
  select id into v_shift_tutup
    from public.shift_kas
   where dibuka_oleh = '90000000-0000-0000-0000-000000000004'
     and status = 'ditutup'
   order by ditutup_pada desc
   limit 1;

  -- Koreksi diperbolehkan di shift yang sudah ditutup
  select public.kas_pergerakan(
    p_jenis := 'koreksi',
    p_jumlah := 5000,
    p_alasan := 'Ditemukan uang receh 5000 terselip di bawah laci kas setelah shift ditutup',
    p_shift_id := v_shift_tutup,
    p_kunci_idempoten := 'kunci-uji-koreksi-001'
  ) into v_hasil;

  if (v_hasil->>'berhasil')::boolean is not true then
    raise exception 'Koreksi seharusnya berhasil dicatat.';
  end if;
end;
$$;

select uji.sama(
  (select jenis from public.kas_pergerakan where kunci_idempoten = 'kunci-uji-koreksi-001'),
  'koreksi',
  'Baris pergerakan kas koreksi berhasil dicatat pada shift tertutup'
);

-- ---------------------------------------------------------------------------
-- Kasus 10: Idempotency key mencegah dobel pencatatan
-- ---------------------------------------------------------------------------
select uji.sama(
  (
    select (res->>'pesan')
      from (
        select public.kas_pergerakan(
          p_jenis := 'koreksi',
          p_jumlah := 5000,
          p_alasan := 'Ditemukan uang receh 5000 terselip di bawah laci kas setelah shift ditutup',
          p_kunci_idempoten := 'kunci-uji-koreksi-001'
        ) as res
      ) sub
  ),
  'Pergerakan kas sudah tercatat sebelumnya (idempoten).',
  'Kunci idempoten mengembalikan data yang sudah ada tanpa menduplikasi baris'
);

select uji.sama(
  (select count(*)::integer from public.kas_pergerakan where kunci_idempoten = 'kunci-uji-koreksi-001'),
  1,
  'Hanya ada 1 baris untuk kunci idempoten yang sama'
);

-- ---------------------------------------------------------------------------
-- Kasus 11: Baris kas_pergerakan kebal dari UPDATE dan DELETE (kekal)
-- ---------------------------------------------------------------------------
select uji.harap_gagal_sebab(
  $$
    update public.kas_pergerakan
       set jumlah = 999999
     where kunci_idempoten = 'kunci-uji-koreksi-001';
  $$,
  'permission denied|keuangan kekal',
  'Penolakan UPDATE pada tabel kas_pergerakan oleh authenticated'
);

reset role;
select uji.harap_gagal_sebab(
  $$
    update public.kas_pergerakan
       set jumlah = 999999
     where kunci_idempoten = 'kunci-uji-koreksi-001';
  $$,
  'keuangan kekal',
  'Pemicu menolak UPDATE langsung bahkan dari superuser'
);

select uji.harap_gagal_sebab(
  $$
    delete from public.kas_pergerakan
     where kunci_idempoten = 'kunci-uji-koreksi-001';
  $$,
  'keuangan kekal',
  'Pemicu menolak DELETE langsung bahkan dari superuser'
);

-- ---------------------------------------------------------------------------
-- Kasus 12: Jejak audit kriptografis tercatat di catatan_audit
-- ---------------------------------------------------------------------------
select uji.sama(
  (
    select count(*)::integer
      from public.catatan_audit
     where entitas = 'kas_pergerakan'
       and aksi in ('kas_pergerakan_masuk', 'kas_pergerakan_keluar', 'kas_pergerakan_setoran', 'kas_pergerakan_koreksi')
  ),
  4,
  'Empat pergerakan kas tercatat rapi di catatan_audit'
);

-- ---------------------------------------------------------------------------
-- Kasus 13: Peran tanpa izin (mis. pelayan) ditolak
-- ---------------------------------------------------------------------------
-- Buka shift baru untuk Rina supaya ada shift aktif di cabang A1
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select public.buka_shift(
  p_modal_awal := 50000,
  p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001'
);

-- Dedi (pelayan A): 90000000-0000-0000-0000-000000000005
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$
    select public.kas_pergerakan(
      p_jenis := 'keluar',
      p_jumlah := 10000,
      p_alasan := 'Pelayan coba ambil uang',
      p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001'
    );
  $$,
  'tidak berwenang',
  'Pelayan ditolak saat memanggil kas_pergerakan'
);
