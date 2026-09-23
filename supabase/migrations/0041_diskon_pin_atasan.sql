-- ============================================================================
-- 0041 · T5-05 — persetujuan PIN atasan MENAIKKAN batas diskon (sampai batas atasan)
-- ----------------------------------------------------------------------------
-- CACAT YANG DITUTUP (ditemukan 2026-09-23 saat mengerjakan T5-05):
-- `picu_diskon_batas()` (definisi berlaku terakhir: 0019) memeriksa
-- `public.boleh('beri_diskon', ...)` — izin PEMANGGIL. Sementara itu
-- `picu_diskon_setuju_jujur()` (0016) sudah membuktikan bahwa atasan benar-benar
-- menekan PIN-nya untuk pesanan itu. Dua pemicu itu tidak pernah berbicara:
-- bukti persetujuan ada, tetapi batas yang dipakai tetap batas kasir.
--
-- Akibat nyatanya di lapangan: diskon di atas batas kasir DITOLAK walaupun
-- pemilik sudah berdiri di sebelah mesin dan memasukkan PIN-nya. Alur yang
-- dijanjikan PRD M3 ("di atas batas → PIN atasan") tidak pernah bisa dijalankan;
-- satu-satunya jalan adalah atasan logout-login di tengah antrean — persis
-- keadaan yang membuat orang menyerah dan kembali ke kertas.
--
-- PERBAIKAN: bila baris diskon membawa `disetujui_oleh`, batas yang diperiksa
-- adalah batas PENYETUJU, bukan batas pengetik. Syaratnya ketat — bukti PIN
-- untuk aksi `beri_diskon`, terikat pesanan yang sama, belum dipakai, berumur
-- di bawah 5 menit, dan penyetuju benar-benar berizin. Itu syarat yang SAMA
-- persis dengan yang dipakai 0016 saat mengonsumsi kupon, supaya tidak ada
-- celah di antara "batas dinaikkan" dan "kupon dikonsumsi".
--
-- YANG SENGAJA TIDAK BERUBAH:
--  * Kupon TIDAK dikonsumsi di sini. Pemicu `diskon_batas` berjalan SEBELUM
--    `diskon_setuju_jujur` (urutan pemicu PostgreSQL = alfabetis nama), jadi di
--    sini kupon hanya DIBACA; yang menandai `dipakai_pada` tetap 0016 — satu
--    tempat saja, supaya sifat sekali-pakai tidak bisa bocor lewat dua jalur.
--  * Tanpa stempel `disetujui_oleh`, perilaku lama berlaku apa adanya: batas
--    kasir, pesan lama.
--  * Semua pagar sesudahnya (satu-diskon, cap resto kumulatif, tidak melebihi
--    subtotal, pelaku tidak boleh dikarang) tetap utuh — persetujuan atasan
--    menaikkan batas PRIBADI, bukan membatalkan aturan resto.
--
-- Uji: supabase/tes/diskon_pin_atasan.sql · bukti mutasi: alat/uji-mutasi-0041.py
-- ============================================================================

create or replace function public.picu_diskon_batas()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pesanan     record;
  v_sudah       integer;      -- total nilai diskon yang sudah ada
  v_jumlah      integer;      -- berapa diskon yang sudah tercatat
  v_tumpuk      boolean;      -- apakah resto mengizinkan tumpuk diskon
  v_cap_persen  numeric;      -- batas maks potongan resto (persen)
  v_cap_nominal integer;      -- batas maks potongan resto (rupiah; null = tanpa batas)
  v_total       integer;      -- total potongan sesudah baris ini
  v_persen      numeric;      -- persen EFEKTIF (dihitung dari uang, bukan dari klien)
  v_kupon       bigint;       -- bukti PIN penyetuju (T5-05) — dibaca, tidak dikonsumsi
  v_boleh       boolean;      -- hasil gerbang izin yang berlaku untuk baris ini
begin
  select p.id, p.subtotal, p.penyewa_id into v_pesanan
    from public.pesanan p where p.id = new.pesanan_id;
  if v_pesanan.id is null then
    raise exception 'Pesanan tidak ditemukan.';
  end if;

  -- ------------------------------------------------------------------ jenis
  if new.jenis = 'manual' then
    -- Persen EFEKTIF dihitung dari UANG (nilai diskon / subtotal pesanan), bukan dari kolom
    -- `persen` kiriman klien — temuan audit AUD-3 K-2 (B F-06).
    v_persen := coalesce(
      case when coalesce(v_pesanan.subtotal, 0) > 0
           then round(new.nilai::numeric * 100 / v_pesanan.subtotal, 2) end,
      new.persen,
      100);

    -- T5-05: batas SIAPA yang berlaku? Bawaannya batas pengetik.
    v_boleh := public.boleh('beri_diskon', new.nilai, v_persen);

    if not v_boleh and new.disetujui_oleh is not null then
      -- Ada klaim persetujuan. Klaim saja tidak cukup — bukti PIN-nya harus ada,
      -- dengan syarat yang sama persis seperti konsumsi kupon di 0016.
      select pp.id into v_kupon
        from public.percobaan_pin pp
       where pp.pengguna_id = new.disetujui_oleh
         and pp.berhasil
         and pp.aksi = 'beri_diskon'
         and pp.pesanan_id = new.pesanan_id
         and pp.dipakai_pada is null
         and pp.waktu > now() - interval '5 minutes'
       order by pp.waktu
       limit 1;

      -- Kecocokan rahasia BUKAN otorisasi (pelajaran F-16): penyetuju tetap harus
      -- berizin, dan batasnya sendiri tetap berlaku. PIN atasan menaikkan batas
      -- SAMPAI batas atasan — bukan menjadikannya tanpa batas.
      if v_kupon is not null then
        select ie.boleh
           and (ie.batas_nominal is null or new.nilai <= ie.batas_nominal)
           and (ie.batas_persen  is null or v_persen  <= ie.batas_persen)
          into v_boleh
          from public.izin_efektif_untuk(new.disetujui_oleh, 'beri_diskon') ie;
        v_boleh := coalesce(v_boleh, false);
      end if;
    end if;

    if not v_boleh then
      raise exception 'Diskon ini melebihi batas izin Anda — minta atasan (pemilik/admin) yang memproses.';
    end if;
  elsif new.jenis = 'voucher' then
    -- TEMUAN review putaran11 PR-01 (K-2): enum mengizinkan 'voucher', kolom `voucher_id`
    -- masih TANPA kunci asing (menyusul di T1-12) dan tabel `voucher` BELUM ada. Dengan hanya
    -- memeriksa izin `pakai_voucher` (bawaan kasir = true), kasir bisa mencatat diskon
    -- "voucher" sebesar 100% subtotal tanpa voucher apa pun — batas 25.000/5% untuk diskon
    -- manual dilewati hanya dengan menulis jenis lain. Prinsip yang sama seperti 'promo':
    -- jenis yang mesinnya BELUM ada = DITUTUP (gagal-aman), bukan dibiarkan tanpa aturan.
    -- T1-19/T1-20 WAJIB mengganti cabang ini dengan pemeriksaan voucher sungguhan
    -- (voucher_id wajib ada, milik resto ini, belum dipakai, nilainya sama dengan diskon).
    raise exception 'Diskon voucher belum aktif (mesin voucher menunggu T1-12/T1-19/T1-20). Pakai diskon manual dengan persetujuan.';
  elsif new.jenis = 'promo' then
    -- TEMUAN PR-01: enum mengizinkan 'promo', tetapi mesinnya (T1-19/T1-20) belum ada —
    -- dan cabang `if` yang tidak ditulis berarti TIDAK ADA pemeriksaan sama sekali:
    -- kasir bisa mencatat diskon 100% subtotal dengan jenis ini. Selama mesinnya belum
    -- ada, jalur ini DITUTUP (gagal-aman), bukan dibiarkan tanpa aturan.
    raise exception 'Diskon promo otomatis belum aktif (menunggu T1-19/T1-20). Pakai diskon manual dengan persetujuan.';
  else
    raise exception 'Jenis diskon tidak dikenal: %.', new.jenis;
  end if;

  -- --------------------------------------------------- tumpuk, nilai, subtotal
  select coalesce(sum(d.nilai), 0)::integer, count(*)
    into v_sudah, v_jumlah
    from public.diskon_transaksi d
   where d.pesanan_id = new.pesanan_id;

  if v_jumlah > 0 then
    select p.tumpuk_diskon into v_tumpuk from public.pengaturan p where p.penyewa_id = v_pesanan.penyewa_id;
    if not coalesce(v_tumpuk, false) then
      raise exception 'Resto ini hanya mengizinkan satu diskon per transaksi.';
    end if;
  end if;

  if new.nilai <= 0 then
    raise exception 'Nilai diskon harus lebih besar dari nol.';
  end if;

  -- TEMUAN (laporan C, PR-01): dulu pemeriksaan dilewati saat subtotal 0, sehingga kasir
  -- bisa MENANAM diskon 25.000 di pesanan kosong lebih dulu; karena barisnya append-only
  -- (tidak bisa dihapus klien), potongan itu menempel sampai pesanan diisi. Sekarang:
  -- subtotal wajib sudah tercatat sebelum diskon boleh dicatat.
  if coalesce(v_pesanan.subtotal, 0) <= 0 then
    raise exception 'Subtotal pesanan belum tercatat — diskon belum boleh dicatat (hitung pesanan dulu).';
  end if;

  v_total := v_sudah + new.nilai;
  if v_total > v_pesanan.subtotal then
    raise exception 'Total diskon (%) melebihi subtotal pesanan (%).', v_total, v_pesanan.subtotal;
  end if;

  -- TEMUAN PR-02: kolom cap tingkat resto didefinisikan sejak 0002 tetapi TIDAK PERNAH
  -- dibaca satu baris pun. Akibatnya owner bisa memasang cap 10%/Rp5.000, menyalakan
  -- tumpuk diskon, lalu kasir memecah diskon besar menjadi banyak baris kecil — tiap
  -- baris lolos pemeriksaan per-baris, totalnya 100% subtotal. Cap sekarang diperiksa
  -- pada TOTAL (kumulatif), bukan per baris.
  select p.batas_maks_potongan_persen, p.batas_maks_potongan_nominal
    into v_cap_persen, v_cap_nominal
    from public.pengaturan p where p.penyewa_id = v_pesanan.penyewa_id;
  if v_cap_persen is not null and v_cap_persen < 100
     and v_total::numeric * 100 > v_pesanan.subtotal::numeric * v_cap_persen then
    raise exception 'Total potongan (%) melebihi batas maks potongan resto (% persen dari subtotal).',
      v_total, trim(to_char(v_cap_persen, 'FM999990.99'));
  end if;
  if v_cap_nominal is not null and v_total > v_cap_nominal then
    raise exception 'Total potongan (%) melebihi batas maks potongan resto (%).', v_total, v_cap_nominal;
  end if;

  if new.pelaku_id is null then
    new.pelaku_id := auth.uid();
  end if;
  -- Jejak pelaku tidak boleh dikarang klien (temuan audit AUD-3 K-2, 2026-09-17).
  if auth.uid() is not null and new.pelaku_id is distinct from auth.uid() then
    raise exception 'Pelaku diskon diisi sistem — tidak boleh menyebut orang lain.';
  end if;
  return new;
end
$$;

comment on function public.picu_diskon_batas() is
  'Menjaga diskon: jenis yang mesinnya belum ada (promo, voucher) DITOLAK gagal-aman; batas izin per baris memakai batas PENYETUJU bila ada bukti PIN atasan yang sah untuk pesanan itu (T5-05), selain itu batas pengetik; SATU diskon bila tidak tumpuk; dan TOTAL potongan tidak melebihi subtotal maupun cap resto (persen/nominal).';
