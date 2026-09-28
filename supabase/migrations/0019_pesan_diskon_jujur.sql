-- ============================================================================
-- 0019 · pesan diskon yang JUJUR — menutup temuan audit AUD-3 D F-10 (K-4, 2026-09-18)
-- ----------------------------------------------------------------------------
-- Pesan penolakan diskon dulu berbunyi "Minta persetujuan atasan (PIN)." — padahal
-- alur persetujuan-diskon-berbasis-PIN TIDAK ADA (kupon tidak menaikkan batas pemanggil;
-- `approve_diskon` baru direncanakan di T1-30/T1-40). Pesan yang menunjuk alur fiktif
-- membuat kasir menunggu sesuatu yang tidak pernah datang. Jalan yang NYATA hari ini:
-- atasan (pemilik/admin) yang punya izin `beri_diskon` memproses diskonnya sendiri —
-- itulah yang sekarang dikatakan pesan. Logika pemicu TIDAK berubah (hanya teks pesan);
-- definisi disalin utuh dari 0013 (definisi berlaku terakhir) agar `create or replace`
-- tidak membawa pulang perilaku lama dari 0010/0012.
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
    if not public.boleh('beri_diskon', new.nilai, v_persen) then
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
  'Menjaga diskon: jenis yang mesinnya belum ada (promo, voucher) DITOLAK gagal-aman, batas izin per baris, SATU diskon bila tidak tumpuk, dan TOTAL potongan tidak melebihi subtotal maupun cap resto (persen/nominal).';
