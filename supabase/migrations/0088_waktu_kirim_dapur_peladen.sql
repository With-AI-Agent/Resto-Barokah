-- ============================================================================
-- 0088 — Waktu kirim ke dapur memakai jam peladen (PMB1-F-132, PMB-1 potongan F-09)
-- Masalah: `dikirim_ke_dapur_pada` diisi `new Date()` perangkat kasir/pelayan (aplikasi/src/App.tsx)
-- dan antrean dapur diurutkan menurut kolom itu → jam HP yang meleset merusak urutan FIFO dapur.
-- Perbaikan: pemicu penjaga status (0009) MENIMPA nilai kiriman perangkat dengan now() peladen pada
-- perpindahan draf → dikirim. Kontrak lain tidak berubah (peran, wajib-isi, tanda tidak bisa diubah).
-- Fungsi tetap BUKAN security definer (lihat catatan di 0009).
-- Uji: supabase/tes/waktu_kirim_dapur_peladen.sql
-- ============================================================================

create or replace function public.picu_pesanan_jaga_status()
returns trigger
language plpgsql
as $$
declare
  v_peran text;
begin
  if auth.uid() is null or public.peran_peladen() then
    return new;   -- jalur peladen / penyiapan
  end if;

  if new.status is distinct from old.status then
    v_peran := public.peran_saya();
    if old.status = 'draf' and new.status = 'dikirim' then
      if v_peran not in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan') then
        raise exception 'Peran % tidak boleh mengirim pesanan ke dapur.', v_peran;
      end if;
      if new.dikirim_ke_dapur_pada is null then
        raise exception 'Mengirim pesanan ke dapur wajib menyertakan waktu kirim (dikirim_ke_dapur_pada).';
      end if;
      -- PMB1-F-132: antrean dapur (FIFO) memakai kolom ini → jam PELADEN, bukan jam perangkat yang bisa meleset.
      new.dikirim_ke_dapur_pada := now();
    elsif old.status in ('dikirim', 'dimasak') and new.status in ('dimasak', 'siap')
          and old.status <> new.status then
      if v_peran not in ('owner_pusat', 'admin_cabang', 'dapur') then
        raise exception 'Peran % tidak boleh memajukan status dapur.', v_peran;
      end if;
    else
      raise exception 'Perpindahan status pesanan % → % tidak diizinkan dari perangkat — status itu hanya boleh ditetapkan peladen (mis. setelah pembayaran sah atau lewat pembatalan).', old.status, new.status;
    end if;
  end if;

  -- Tanda "sudah dikirim ke dapur" menentukan tahap pembatalan (sebelum/sesudah dapur).
  -- Kalau klien boleh menghapusnya, pembatalan sesudah dapur bisa "diturunkan" jadi
  -- sebelum dapur dan lolos tanpa persetujuan PIN.
  if old.dikirim_ke_dapur_pada is not null
     and new.dikirim_ke_dapur_pada is distinct from old.dikirim_ke_dapur_pada then
    raise exception 'Tanda kirim ke dapur tidak boleh diubah atau dihapus.';
  end if;
  return new;
end
$$;
