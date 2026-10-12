-- ============================================================================
-- MIGRASI 0096 — penyatuan gaya penulisan nomor HP pelanggan, ronde 3
-- (PMB1-F-038 bagian A)
-- ============================================================================
-- Putusan HAKIM H-F-03.5 (kartu kartu/H-F-03.5.md, 2026-10-02): normalisasi
-- 0095 menutup bentuk "+62…", "62…", dan "8…" tanpa nol, TETAPI 9 dari 13
-- gaya penulisan yang lazim masih bocor (matriks bukti/H-F-03.5-matriks-
-- varian-nomor.txt): "+62 (0)812…", "+62 0812…", "620812…", "00812…",
-- "0062 812…", "0062-0812…", dan tiga gaya telepon rumah ("+62 (0)21…",
-- "0062 21…", "21…" tanpa nol). Akibatnya satu orang tetap bisa mendapat DUA
-- voucher pada kampanye yang sama. Klaim 0095 "semua bentuk satu identitas"
-- dinyatakan hakim salah; migrasi ini memperbaikinya.
--
-- Aturan normalisasi tunggal (menggantikan isi fungsi 0095; pemicu INSERT
-- dari 0093/0095 otomatis memakai perilaku baru karena memanggil fungsi ini):
--   1. buang semua karakter selain digit;
--   2. buang awalan akses internasional "00" (berulang: 0062…, 00812…);
--   3. awalan kode negara "62" -> diganti "0", dan nol yang ikut tertulis
--      sesudah kode negara ("+62 (0)…", "+62 0812…") dibuang lebih dulu;
--   4. nomor tanpa nol depan (seluler "812…" maupun telepon rumah "21…")
--      diberi nol depan.
-- Hasil: satu nomor = tepat satu bentuk kanonik domestik (0…), apa pun gaya
-- penulisannya. Riset gaya penulisan: PMB1-A-142 (Wikipedia "Telephone
-- numbers in Indonesia" & notasi E.123; akses internasional Indonesia = 00).
--
-- Backfill (merujuk juga temuan PMB1-F-227): baris lama dinormalisasi ulang
-- dengan pengaman tabrakan — baris TERTUA (dibuat_pada lalu id) yang mendapat
-- bentuk kanonik; kembar yang lebih muda dan menabrak kunci unik DIBIARKAN
-- apa adanya (tidak ada penghapusan/penggabungan data tanpa keputusan).
-- Saat ini belum ada data asli di produksi (masa percobaan), jadi backfill
-- hanya berjaga untuk data uji lama.
--
-- Bagian B temuan F-038 (pelanggan fiktif bernomor berbeda-beda) TIDAK
-- disentuh di sini: menunggu keputusan Lee (DAFTAR_TUNGGU_LEE.md).
-- Dijaga oleh uji `supabase/tes/voucher_kasir_wajib_identitas.sql` kasus 9-19.
-- ============================================================================

-- 1. Fungsi normalisasi tunggal — menggantikan isi 0095 (tanda tangan sama,
--    sehingga pemicu picu_pelanggan_kunci_identitas langsung memakai aturan baru)
create or replace function public.normalisasi_telepon_pelanggan(p_telepon text)
returns text
language plpgsql
immutable
as $$
declare
  v text;
begin
  -- (1) digit saja
  v := regexp_replace(coalesce(p_telepon, ''), '\D', '', 'g');
  if v = '' then
    return null;
  end if;

  -- (2) awalan akses internasional "00" (bisa tertulis lebih dari sekali)
  while left(v, 2) = '00' loop
    v := substr(v, 3);
  end loop;
  if v = '' then
    return null;
  end if;

  -- (3) kode negara "62": buang, lalu buang nol yang ikut tertulis
  --     sesudahnya ("+62 (0)812…", "+62 0812…"), lalu beri nol domestik
  if left(v, 2) = '62' then
    v := substr(v, 3);
    while left(v, 1) = '0' loop
      v := substr(v, 2);
    end loop;
    if v = '' then
      return null;
    end if;
    return '0' || v;
  end if;

  -- (4) seluler/telepon rumah tanpa nol depan -> beri nol domestik
  if left(v, 1) between '2' and '9' then
    v := '0' || v;
  end if;

  return nullif(v, '');
end;
$$;

-- 2. Backfill aman: tertua mendapat bentuk kanonik; kembar muda yang
--    menabrak kunci unik dibiarkan apa adanya (tanpa penghapusan data)
do $$
declare
  r record;
begin
  for r in
    select p.id, p.telepon
      from public.pelanggan p
     where p.telepon is not null
     order by p.dibuat_pada, p.id
  loop
    begin
      update public.pelanggan
         set telepon = public.normalisasi_telepon_pelanggan(r.telepon)
       where id = r.id;
    exception when unique_violation then
      -- Kembar lama: baris yang lebih tua sudah memegang bentuk kanonik.
      -- Penggabungan/penghapusan data butuh keputusan — dibiarkan dulu.
      null;
    end;
  end loop;
end;
$$;
