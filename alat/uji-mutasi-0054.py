#!/usr/bin/env python3
"""
UJI MUTASI 0054 — membuktikan ketajaman pagar T7-11 di `0054_transaksi_tengah_malam.sql`:
"Transaksi lewat tengah malam masuk tanggal transaksi (bukan tanggal tutup kas),
nomor pesanan mengikuti hari operasional lokal resto, dan laporan memotong batas hari
menurut zona waktu penyewa (ART-9 & PRD M8)".

Mutasi yang wajib membuat `supabase/tes/tengah_malam.sql` MERAH:
  1. Pagar validasi tanggal pesanan baru dicabut (klien bebas memundurkan/memajukan tanggal)
  2. Penentuan tanggal lokal pesanan dikembalikan ke UTC current_date
  3. Penomoran pesanan harian dirusak (memakai UTC current_date, bukan tanggal hari operasional)
  4. Helper zona_waktu_cabang dirusak (selalu mengembalikan 'UTC' alih-alih zona resto)
  5. Pelepasan pesanan.tanggal default dibatalkan (membiarkan tanggal pesanan diisi default UTC peladen)
  6. Pemotongan batas hari pembayaran pada laporan_harian dikembalikan ke pemotongan UTC

Verifikasi: python3 alat/uji-mutasi-0054.py
            python3 alat/uji-mutasi-0054.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0054_transaksi_tengah_malam.sql")
BERKAS_UJI = ["supabase/tes/tengah_malam.sql"]


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
        "pagar validasi tanggal pesanan baru dicabut (klien bebas mengirim tanggal sembarang)",
        """    if new.tanggal is not null and new.tanggal <> v_tanggal_lokal then
      raise exception 'Tanggal pesanan baru harus hari ini — tanggal mundur hanya boleh diisi peladen.';
    end if;""",
        "    -- (mutasi) validasi tanggal pesanan baru dicabut",
    ),
    (
        "penentuan tanggal lokal pesanan dikembalikan ke UTC current_date",
        """  v_tanggal_lokal := public.tanggal_lokal_cabang(new.cabang_id, coalesce(new.dibuat_pada, now()));""",
        """  v_tanggal_lokal := current_date; -- (mutasi) dipaksa tanggal UTC peladen""",
    ),
    (
        "penomoran pesanan harian dirusak (memakai UTC current_date, bukan tanggal hari operasional)",
        """    new.nomor := public.nomor_pesanan_berikutnya(new.cabang_id, new.tanggal);""",
        """    new.nomor := public.nomor_pesanan_berikutnya(new.cabang_id, current_date); -- (mutasi) nomor mengikuti UTC""",
    ),
    (
        "helper zona_waktu_cabang dirusak (selalu mengembalikan 'UTC' alih-alih zona resto)",
        """  select coalesce(p.zona_waktu, 'Asia/Jakarta')""",
        """  select 'UTC'::text""",
    ),
    (
        "pelepasan pesanan.tanggal default dibatalkan (membiarkan tanggal pesanan diisi default UTC)",
        """alter table public.pesanan alter column tanggal drop default;""",
        """-- alter table public.pesanan alter column tanggal drop default;""",
    ),
    (
        "pemotongan batas hari pembayaran pada laporan_harian dikembalikan ke pemotongan UTC",
        """    and ((pb.waktu at time zone v_zona)::date = v_tanggal);""",
        """    and (pb.waktu::date = v_tanggal); -- (mutasi) pemotongan tanggal berbasis UTC""",
    ),
]


def uji_diri():
    print("[0054 Uji-Diri] Memeriksa kondisi awal (tanpa mutasi)...")
    sukses, log = jalankan_uji()
    if not sukses:
        print("[0054 Uji-Diri] GAGAL: kondisi awal sudah merah!", file=sys.stderr)
        print(log, file=sys.stderr)
        return False
    print("[0054 Uji-Diri] OK: kondisi awal hijau (tes lolos).")
    return True


def uji_mutasi():
    with open(MIGRASI, "r", encoding="utf-8") as f:
        isi_asli = f.read()

    semua_lolos = True
    for i, (nama, asli, mutasi) in enumerate(DAFTAR_MUTASI, 1):
        if asli not in isi_asli:
            print(f"[{i}/{len(DAFTAR_MUTASI)}] GAGAL CARI: snippet tidak ditemukan di {MIGRASI}")
            print(f"Snippet:\n{asli}")
            semua_lolos = False
            continue

        isi_mutasi = isi_asli.replace(asli, mutasi, 1)
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(isi_mutasi)

        try:
            sukses, log = jalankan_uji()
            if sukses:
                print(f"[{i}/{len(DAFTAR_MUTASI)}] GAGAL TUMPUL: {nama} — tes tetap HIJAU padahal seharusnya MERAH!")
                semua_lolos = False
            else:
                print(f"[{i}/{len(DAFTAR_MUTASI)}] OK (MERAH): {nama}")
        finally:
            with open(MIGRASI, "w", encoding="utf-8") as f:
                f.write(isi_asli)

    return semua_lolos


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--uji-diri":
        if not uji_diri():
            sys.exit(1)
        sys.exit(0)

    if not uji_diri():
        sys.exit(1)

    print("\n[0054] Menjalankan uji mutasi pagar transaksi tengah malam...")
    if not uji_mutasi():
        print("\n[0054] Uji mutasi GAGAL!", file=sys.stderr)
        sys.exit(1)
    print("\n[0054] Seluruh 6 mutasi berhasil dibuktikan MERAH!")
