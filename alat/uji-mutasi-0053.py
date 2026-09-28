#!/usr/bin/env python3
"""
UJI MUTASI 0053 — membuktikan ketajaman pagar T7-09 di `0053_laporan_menu.sql`:
"Laporan menu terlaris (jumlah & nilai) berbasis nama_saat_itu dan rincian diskon manual / voucher terpakai".

Mutasi yang wajib membuat `supabase/tes/laporan_menu.sql` MERAH:
  1. Pagar izin lihat_laporan pada laporan_menu dinonaktifkan
  2. Batas rentang tanggal maksimal 90 hari dinonaktifkan
  3. Pagar wewenang pantau cabang binaan dinonaktifkan
  4. Isolasi penyewa pada verifikasi cabang dinonaktifkan
  5. Penggunaan nama_saat_itu pada peringkat menu dirusak (jatuh ke mi.nama)
  6. Agregasi daftar diskon manual dirusak (dibuat kosong)

Verifikasi: python3 alat/uji-mutasi-0053.py
            python3 alat/uji-mutasi-0053.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0053_laporan_menu.sql")
BERKAS_UJI = ["supabase/tes/laporan_menu.sql"]


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
        "pagar izin lihat_laporan pada laporan_menu dinonaktifkan",
        """  if not public.boleh('lihat_laporan') then
    raise exception 'Anda tidak berwenang melihat laporan menu.';
  end if;""",
        "  -- pagar izin dinonaktifkan",
    ),
    (
        "batas rentang tanggal maksimal 90 hari dinonaktifkan",
        """  if (v_tanggal_akhir - v_tanggal_mulai) > 90 then
    raise exception 'Rentang tanggal laporan menu maksimal 90 hari.';
  end if;""",
        "  -- batas 90 hari dinonaktifkan",
    ),
    (
        "pagar wewenang pantau cabang binaan dinonaktifkan",
        """    if not public.cabang_pantau_saya(p_cabang_id) then
      raise exception 'Cabang di luar wewenang pantauan Anda.';
    end if;""",
        "    -- pagar cabang binaan dinonaktifkan",
    ),
    (
        "isolasi penyewa pada verifikasi cabang dinonaktifkan",
        """    select nama into v_nama_cabang
      from public.cabang
     where id = p_cabang_id
       and penyewa_id = v_penyewa;""",
        """    select nama into v_nama_cabang
      from public.cabang
     where id = p_cabang_id;""",
    ),
    (
        "penggunaan nama_saat_itu pada peringkat menu dirusak (jatuh ke mi.nama)",
        """      coalesce(pi.nama_saat_itu, mi.nama, 'Menu') as nama_menu,""",
        """      coalesce(mi.nama, 'Menu') as nama_menu,""",
    ),
    (
        "agregasi daftar diskon manual dirusak (dibuat kosong)",
        """  into
    v_total_diskon_manual,
    v_diskon_manual_json
  from public.diskon_transaksi dt""",
        """  into
    v_total_diskon_manual,
    v_diskon_manual_json
  from public.diskon_transaksi dt
  where false and """,
    ),
]


def uji_diri():
    print("[0053 Uji-Diri] Memeriksa kondisi awal (tanpa mutasi)...")
    sukses, log = jalankan_uji()
    if not sukses:
        print("[0053 Uji-Diri] GAGAL: kondisi awal sudah merah!", file=sys.stderr)
        print(log, file=sys.stderr)
        return False
    print("[0053 Uji-Diri] OK: kondisi awal hijau (tes lolos).")
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

    print("\n[0053] Menjalankan uji mutasi pagar laporan menu...")
    if not uji_mutasi():
        print("\n[0053] Uji mutasi GAGAL!", file=sys.stderr)
        sys.exit(1)
    print("\n[0053] Seluruh 6 mutasi berhasil dibuktikan MERAH!")
