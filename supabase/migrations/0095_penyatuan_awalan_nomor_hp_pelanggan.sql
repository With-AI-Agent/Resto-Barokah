-- ============================================================================
-- MIGRASI 0095 — penyatuan awalan nomor HP pelanggan (PMB1-F-038 ronde 2)
-- ============================================================================
-- Temuan: PMB1-F-038 (K-2, potongan F-03). Perbaikan pertama (0093) membangun
-- kunci unik (penyewa_id, telepon) + pemicu yang menghapus karakter non-digit,
-- tetapi TIDAK menyatukan awalan negara: "+62 812-3456-7890" tersimpan sebagai
-- "628123456789" sedangkan "0812-3456-7890" tersimpan sebagai "081234567890"
-- -> DUA nilai berbeda, kunci unik lolos, dan satu orang mendapat DUA voucher
-- pada kampanye yang sama (PRD M10 baris 170: satu voucher per identitas).
-- Komentar 0093 baris 44-45 mengklaim "+62 disatukan" — klaim itu salah sampai
-- migrasi ini; HAKIM H-F-03.4 (kartu kartu/H-F-03.4.md, probe
-- bukti/H-F-03.4-probe-plus62.sql) membuktikan celahnya pada 2026-10-02.
--
-- Perbaikan (tetap di tabel — prinsip 0093: pagar berlaku untuk jalur apa pun,
-- bukan hanya RPC daftar_voucher):
--   1. Normalisasi tunggal sebelum INSERT:
--        a. buang semua karakter non-digit;
--        b. awalan "62" (panjang >= 9 digit) -> diganti awalan "0";
--        c. awalan "8" tanpa nol (panjang >= 8 digit) -> diberi awalan "0".
--      sehingga 0812…, +62 812…, 62812…, dan 812… menjadi identitas yang sama.
--   2. Backfill baris lama dengan aturan yang sama supaya kunci unik juga
--      merapatkan data yang telanjur lahir sebelum migrasi ini.
--   3. Pemicu tetap BEFORE INSERT saja (keputusan 0093: pembaruan seperti
--      anonimisasi yang mengosongkan kontak tidak disentuh).
--
-- Tidak ada perubahan produksi yang membutuhkan tindakan Lee: normalisasi hanya
-- menyamakan penulisan nomor; akun percontohan & cara masuk tidak tersentuh.
-- Dijaga oleh uji `supabase/tes/voucher_kasir_wajib_identitas.sql` kasus 5-8.
-- ============================================================================

-- 1. Fungsi normalisasi tunggal (dipakai pemicu dan backfill)
create or replace function public.normalisasi_telepon_pelanggan(p_telepon text)
returns text
language sql
immutable
as $$
  select case
           when v is null or v = '' then null
           when left(v, 2) = '62' and length(v) >= 9 then '0' || substr(v, 3)
           when left(v, 1) = '8' and length(v) >= 8 then '0' || v
           else v
         end
    from (select regexp_replace(coalesce(p_telepon, ''), '\D', '', 'g') as v) s
$$;

-- 2. Backfill baris lama dengan aturan yang sama
update public.pelanggan
   set telepon = public.normalisasi_telepon_pelanggan(telepon)
 where telepon is not null;

-- 3. Pemicu diperbarui: normalisasi memakai fungsi tunggal, kunci identitas
--    jalur kasir (IDENTITAS_WAJIB) tetap seperti 0093
create or replace function public.picu_pelanggan_kunci_identitas()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  -- Nomor HP disimpan tersatukan: digit saja, awalan negara 62 dan nomor tanpa
  -- nol di depan disamakan menjadi bentuk 0… ("+62 812-3456-7890",
  -- "628123456789", dan "0812-3456-7890" adalah identitas yang sama).
  new.telepon := public.normalisasi_telepon_pelanggan(new.telepon);

  -- Jalur kasir tanpa email dan tanpa nomor HP = identitas tanpa kunci -> tolak.
  if new.cara_masuk = 'kasir'
     and (new.email is null or btrim(new.email) = '')
     and (new.telepon is null or btrim(new.telepon) = '') then
    raise exception 'IDENTITAS_WAJIB: pelanggan yang didaftarkan kasir wajib mencantumkan nomor HP atau email sebagai kunci identitas.';
  end if;

  return new;
end;
$$;
