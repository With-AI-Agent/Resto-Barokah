#!/usr/bin/env python3
"""
UJI MUTASI 0051 — membuktikan ketajaman pagar T7-07 di `0051_laporan_kas.sql`:
"Laporan kas harian & per shift (omzet kategori, metode bayar, uang seharusnya/fisik/selisih, pembatalan, multi-tenant)".

Mutasi yang wajib membuat `supabase/tes/laporan_kas.sql` MERAH:
  1. Pagar izin lihat_laporan pada laporan_shift dinonaktifkan
  2. Isolasi penyewa pada laporan_shift dinonaktifkan
  3. Pagar izin lihat_laporan pada laporan_harian dinonaktifkan
  4. Isolasi penyewa pada laporan_harian dinonaktifkan
  5. Perhitungan uang_seharusnya pada laporan_shift dirusak (tanpa penjualan tunai)
  6. Perhitungan omzet minuman pada laporan_shift dirusak (dibuat 0)

Verifikasi: python3 alat/uji-mutasi-0051.py
            python3 alat/uji-mutasi-0051.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# JEBAKAN "fungsi ditulis ulang" (lihat DECISIONS_LOG [Mutu gerbang/2026-09-24]):
# fungsi `public.laporan_harian` ditulis ulang di `0054_transaksi_tengah_malam.sql` (T7-11)
# untuk pemotongan batas hari berbasis zona waktu cabang (ART-9). Mutasi laporan_harian
# harus menyasar berkas yang berlaku saat runtime (0054).
MIGRASI_51 = os.path.join(REPO, "supabase", "migrations", "0051_laporan_kas.sql")
MIGRASI_54 = os.path.join(REPO, "supabase", "migrations", "0054_transaksi_tengah_malam.sql")
BERKAS_UJI = ["supabase/tes/laporan_kas.sql"]


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
        "pagar izin lihat_laporan pada laporan_shift dinonaktifkan",
        """  if not (
    public.boleh('lihat_laporan') or
    (v_shift.dibuka_oleh = auth.uid() or v_shift.ditutup_oleh = auth.uid())
  ) then
    raise exception 'Anda tidak berwenang melihat laporan shift ini.';
  end if;""",
        "  null;",
        MIGRASI_51,
    ),
    (
        "isolasi penyewa pada laporan_shift dinonaktifkan",
        """  where s.id = p_shift_id
    and s.penyewa_id = v_penyewa;""",
        """  where s.id = p_shift_id;""",
        MIGRASI_51,
    ),
    (
        "pagar izin lihat_laporan pada laporan_harian dinonaktifkan",
        """  if not public.boleh('lihat_laporan') then
    raise exception 'Anda tidak berwenang melihat laporan harian.';
  end if;""",
        "  null;",
        MIGRASI_54,
    ),
    (
        "isolasi penyewa pada laporan_harian dinonaktifkan",
        """         and c.penyewa_id = v_penyewa""",
        """         -- isolasi penyewa dicabut""",
        MIGRASI_54,
    ),
    (
        "perhitungan uang_seharusnya pada laporan_shift dirusak (tanpa penjualan tunai)",
        """    v_uang_seharusnya := v_shift.modal_awal + v_penjualan_tunai + v_kas_masuk - v_kas_keluar - v_setoran;""",
        """    v_uang_seharusnya := v_shift.modal_awal + v_kas_masuk - v_kas_keluar - v_setoran;""",
        MIGRASI_51,
    ),
    (
        "perhitungan omzet minuman pada laporan_shift dirusak (dibuat 0)",
        """    coalesce(sum(case when coalesce(mi.jenis, 'lainnya') = 'minuman' then pi.subtotal else 0 end), 0),""",
        """    0,""",
        MIGRASI_51,
    ),
]


def uji_diri():
    print("[0051 Uji-Diri] Memeriksa kondisi awal (tanpa mutasi)...")
    sukses, log = jalankan_uji()
    if not sukses:
        print("[0051 Uji-Diri] GAGAL: kondisi awal sudah merah!", file=sys.stderr)
        print(log, file=sys.stderr)
        return False
    print("[0051 Uji-Diri] OK: kondisi awal hijau (tes lolos).")
    return True


def uji_mutasi():
    semua_lolos = True
    for i, (nama, asli, mutasi, berkas_target) in enumerate(DAFTAR_MUTASI, 1):
        with open(berkas_target, "r", encoding="utf-8") as f:
            isi_asli = f.read()

        if asli not in isi_asli:
            print(f"[{i}/{len(DAFTAR_MUTASI)}] GAGAL CARI: snippet tidak ditemukan di {berkas_target}")
            print(f"Snippet:\n{asli}")
            semua_lolos = False
            continue

        isi_mutasi = isi_asli.replace(asli, mutasi, 1)
        with open(berkas_target, "w", encoding="utf-8") as f:
            f.write(isi_mutasi)

        try:
            sukses, log = jalankan_uji()
            if sukses:
                print(f"[{i}/{len(DAFTAR_MUTASI)}] GAGAL TUMPUL: {nama} — tes tetap HIJAU padahal seharusnya MERAH!")
                semua_lolos = False
            else:
                print(f"[{i}/{len(DAFTAR_MUTASI)}] OK (MERAH): {nama}")
        finally:
            with open(berkas_target, "w", encoding="utf-8") as f:
                f.write(isi_asli)

    return semua_lolos


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--uji-diri":
        if not uji_diri():
            sys.exit(1)
        sys.exit(0)

    if not uji_diri():
        sys.exit(1)

    print("\n[0051] Menjalankan uji mutasi pagar laporan kas...")
    if not uji_mutasi():
        print("\n[0051] Uji mutasi GAGAL!", file=sys.stderr)
        sys.exit(1)
    print("\n[0051] Seluruh 6 mutasi berhasil dibuktikan MERAH!")
