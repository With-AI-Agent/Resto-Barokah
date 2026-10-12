-- ============================================================================
-- MIGRASI 0093 — PMB1-F-038 (K-2): pelanggan jalur kasir wajib punya kunci identitas
-- ============================================================================
-- Baseline yang dilanggar: `docs/PRD.md:170` (M10: satu voucher per IDENTITAS per
-- kampanye), aturan bisnis 6 `docs/PRD.md:266`, risiko #4 `docs/PRD.md:289`
-- (penyalahgunaan voucher).
--
-- Cacat (bukti kartu K-F-03 §1; probe hakim: "dua nama/HP sama tanpa email melalui
-- kasir -> dua voucher tersimpan"): batasan 0063 hanya menuntut `didaftarkan_oleh`
-- untuk jalur `kasir` — TIDAK ada kunci identitas:
--   * indeks unik identitas hanya menyentuh `email_normalisasi is not null`;
--   * `telepon` tidak pernah punya kunci unik (`grep telepon.*unique` -> 0);
--   * RPC `daftar_voucher` jalur kasir menerima email DAN telepon kosong.
-- Akibatnya kasir bisa membuat pelanggan fiktif nama-nama baru tanpa jejak identitas,
-- mengambil satu voucher untuk TIAP nama fiktif pada kampanye yang sama, lalu
-- memakainya pada tamu yang membayar penuh (kas tetap cocok, anggaran kampanye bocor).
--
-- Perbaikan (di tabel — lebih kuat daripada menambal RPC saja, berlaku untuk jalur
-- mana pun):
--   1. Kunci unik identitas kedua: (penyewa_id, telepon) bila telepon terisi.
--   2. Pemicu sebelum-INSERT:
--        - nomor HP disimpan hanya sebagai digit (normalisasi), dan
--        - pelanggan jalur `kasir` WAJIB mencantumkan email ATAU nomor HP.
--      (Pembaruan seperti anonimisasi yang mengosongkan kontak tidak disentuh —
--      pemicu hanya di INSERT.)
-- Migrasi lama tidak diubah; berkas berlaku = 0093. Dijaga oleh uji
-- `supabase/tes/voucher_kasir_wajib_identitas.sql`.
--
-- RUJUKAN: `kartu/K-F-03.md` §1 (PMB1-F-038), `kartu/H-F-03.md`, `kartu/H-F-03.2.md`.

-- 1. Kunci unik nomor HP per penyewa (pelengkap kunci email 0063)
create unique index if not exists pelanggan_penyewa_telepon_unik
  on public.pelanggan (penyewa_id, telepon)
  where telepon is not null;

-- 2. Pemicu kunci identitas jalur kasir
create or replace function public.picu_pelanggan_kunci_identitas()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- Nomor HP disimpan sebagai digit saja (spasi/tanda hubung/awalan +62 disatukan
  -- sehingga "0812-3456-7890" dan "081234567890" adalah identitas yang sama).
  if new.telepon is not null then
    new.telepon := nullif(regexp_replace(new.telepon, '\D', '', 'g'), '');
  end if;

  -- Jalur kasir tanpa email dan tanpa nomor HP = identitas tanpa kunci -> tolak.
  if new.cara_masuk = 'kasir'
     and (new.email is null or btrim(new.email) = '')
     and (new.telepon is null or btrim(new.telepon) = '') then
    raise exception 'IDENTITAS_WAJIB: pelanggan yang didaftarkan kasir wajib mencantumkan nomor HP atau email sebagai kunci identitas.';
  end if;

  return new;
end;
$$;

comment on function public.picu_pelanggan_kunci_identitas() is
  'PMB1-F-038: menormalkan nomor HP dan menolak pelanggan jalur kasir tanpa kunci identitas (email atau nomor HP).';

revoke all on function public.picu_pelanggan_kunci_identitas() from anon, authenticated, public;

drop trigger if exists trg_pelanggan_kunci_identitas on public.pelanggan;
create trigger trg_pelanggan_kunci_identitas
  before insert on public.pelanggan
  for each row execute function public.picu_pelanggan_kunci_identitas();
