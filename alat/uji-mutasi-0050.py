#!/usr/bin/env python3
"""
UJI MUTASI 0050 — membuktikan ketajaman pagar T7-06 di `0050_koreksi_modal.sql`:
"koreksi modal awal dengan izin atasan (hanya-tambah, wajib PIN atasan & alasan, kekal)".

Mutasi yang wajib membuat `supabase/tes/koreksi_modal.sql` MERAH:
  1. Pagar alasan wajib ditiadakan
  2. Pagar modal baru tidak boleh sama dinonaktifkan
  3. Pagar verifikasi kupon PIN atasan dinonaktifkan
  4. Pagar konsumsi kupon dinonaktifkan (kupon tidak dihanguskan)
  5. Pagar pemicu tabel riwayat kekal dinonaktifkan
  6. Pagar shift tertutup dinonaktifkan

Verifikasi: python3 alat/uji-mutasi-0050.py
            python3 alat/uji-mutasi-0050.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0050_koreksi_modal.sql")
BERKAS_UJI = ["supabase/tes/koreksi_modal.sql"]


def jalankan_uji():
    res = subprocess.run(
        ["node", "alat/uji-sql.mjs", *BERKAS_UJI],
        cwd=REPO,
        capture_output=True,
        text=True,
    )
    keluaran = res.stdout + res.stderr
    return f"uji: {len(BERKAS_UJI)} LULUS · 0 GAGAL" in keluaran, keluaran


DAFTAR_MUTASI = [
    (
        "pagar alasan wajib ditiadakan",
        """  if p_alasan is null or btrim(p_alasan) = '' then
    raise exception 'Alasan koreksi modal awal wajib diisi.';
  end if;""",
        "  null;",
    ),
    (
        "pagar modal baru tidak boleh sama dinonaktifkan",
        """  if p_modal_awal_baru = v_shift.modal_awal then
    raise exception 'Modal awal baru tidak boleh sama dengan modal awal saat ini (%).', v_shift.modal_awal;
  end if;""",
        "  null;",
    ),
    (
        "pagar verifikasi kupon PIN atasan dinonaktifkan",
        """  if v_kupon is null then
    raise exception 'Persetujuan belum terbukti: atasan harus memasukkan PIN untuk koreksi modal shift (maksimal 5 menit lalu).';
  end if;""",
        "  null;",
    ),
    (
        "pagar konsumsi kupon dinonaktifkan (kupon tidak dihanguskan)",
        """  -- Konsumsi kupon (sekali pakai)
  update public.percobaan_pin
     set dipakai_pada = now()
   where id = v_kupon;""",
        "  null;",
    ),
    (
        "pagar pemicu tabel riwayat kekal dinonaktifkan",
        """create or replace function public.picu_koreksi_modal_kekal()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  raise exception 'Riwayat koreksi modal awal adalah jejak audit kekal; tidak dapat diubah atau dihapus.';
end;
$$;""",
        """create or replace function public.picu_koreksi_modal_kekal()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  return coalesce(new, old);
end;
$$;""",
    ),
    (
        "pagar shift tertutup dinonaktifkan",
        """  -- Pagar status: hanya shift terbuka yang boleh dikoreksi modal awalnya
  if v_shift.status <> 'terbuka' then
    raise exception 'Shift kas sudah ditutup — koreksi modal awal hanya dapat dilakukan saat shift masih terbuka.';
  end if;""",
        "  null;",
    ),
]


def uji_diri():
    print(f"Memeriksa {len(DAFTAR_MUTASI)} mutasi terdaftar...")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        isi_asli = f.read()

    for idx, (nama, asli, mutasi) in enumerate(DAFTAR_MUTASI, 1):
        if asli not in isi_asli:
            print(f"❌ Mutasi {idx} '{nama}' TIDAK DITEMUKAN di berkas migrasi!")
            return False
        print(f"  OK {idx}. {nama}")
    print("Semua mutasi valid secara sintaks target.")
    return True


def main():
    if "--uji-diri" in sys.argv:
        if not uji_diri():
            sys.exit(1)
        sys.exit(0)

    with open(MIGRASI, "r", encoding="utf-8") as f:
        isi_asli = f.read()

    print(f"=== UJI MUTASI 0050: {len(DAFTAR_MUTASI)} skenario ===")

    # Pastikan baseline hijau
    lulus, log = jalankan_uji()
    if not lulus:
        print("❌ Baseline GAGAL sebelum mutasi diterapkan!")
        print(log)
        sys.exit(1)
    print("✓ Baseline HIJAU (semua uji lulus)")

    semua_merah = True

    try:
        for idx, (nama, asli, mutasi) in enumerate(DAFTAR_MUTASI, 1):
            if asli not in isi_asli:
                print(f"❌ Mutasi {idx} '{nama}': teks asli tidak ditemukan di migrasi.")
                semua_merah = False
                continue

            isi_mutasi = isi_asli.replace(asli, mutasi, 1)
            with open(MIGRASI, "w", encoding="utf-8") as f:
                f.write(isi_mutasi)

            lulus, _ = jalankan_uji()
            if lulus:
                print(f"❌ Mutasi {idx} '{nama}' tetap HIJAU (pagar tumpul!)")
                semua_merah = False
            else:
                print(f"✓ Mutasi {idx} '{nama}' terbukti MERAH (pagar tajam)")

            with open(MIGRASI, "w", encoding="utf-8") as f:
                f.write(isi_asli)

    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(isi_asli)

    if not semua_merah:
        print("\n❌ Sebagian mutasi tidak terbukti merah. Perbaiki tes atau pagar!")
        sys.exit(1)

    print("\n✅ SEMUA MUTASI TERBUKTI MERAH. Pagar 0050 terverifikasi tajam.")


if __name__ == "__main__":
    main()
