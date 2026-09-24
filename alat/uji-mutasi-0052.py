#!/usr/bin/env python3
"""
UJI MUTASI 0052 — membuktikan ketajaman pagar T7-08 di `0052_laporan_penjualan.sql`:
"Laporan penjualan dasar (omzet per kategori, jenis menu, metode bayar, tren harian, batas 90 hari, wewenang cabang & multi-tenant)".

Mutasi yang wajib membuat `supabase/tes/laporan_penjualan.sql` MERAH:
  1. Pagar izin lihat_laporan pada laporan_penjualan dinonaktifkan
  2. Batas rentang tanggal maksimal 90 hari dinonaktifkan
  3. Pagar wewenang pantau cabang binaan dinonaktifkan
  4. Isolasi penyewa pada verifikasi cabang dinonaktifkan
  5. Perhitungan omzet jenis makanan dirusak (dibuat 0)
  6. Agregasi rincian per metode bayar dirusak (dibuat kosong)

Verifikasi: python3 alat/uji-mutasi-0052.py
            python3 alat/uji-mutasi-0052.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0052_laporan_penjualan.sql")
BERKAS_UJI = ["supabase/tes/laporan_penjualan.sql"]


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
        "pagar izin lihat_laporan pada laporan_penjualan dinonaktifkan",
        """  if not public.boleh('lihat_laporan') then
    raise exception 'Anda tidak berwenang melihat laporan penjualan.';
  end if;""",
        "  null;",
    ),
    (
        "batas rentang tanggal maksimal 90 hari dinonaktifkan",
        """  if (v_tanggal_akhir - v_tanggal_mulai) > 90 then
    raise exception 'Rentang tanggal laporan penjualan maksimal 90 hari.';
  end if;""",
        "  null;",
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
        "perhitungan omzet jenis makanan dirusak (dibuat 0)",
        """    coalesce(sum(case when coalesce(mi.jenis, 'lainnya') = 'makanan' then pi.subtotal else 0 end), 0),""",
        """    0,""",
    ),
    (
        "agregasi rincian per metode bayar dirusak (dibuat kosong)",
        """  select coalesce(jsonb_agg(
    jsonb_build_object(
      'metode_id', t.metode_id,
      'metode_nama', t.metode_nama,
      'jenis', t.jenis,
      'jumlah_transaksi', t.jumlah_transaksi,
      'total_nominal', t.total_nominal,
      'persentase', case
        when v_total_omzet > 0 then round((t.total_nominal::numeric * 100.0 / v_total_omzet), 1)
        else 0
      end
    ) order by t.total_nominal desc, t.metode_nama asc
  ), '[]'::jsonb) into v_metode_json""",
        """  v_metode_json := '[]'::jsonb;""",
    ),
]


def uji_diri():
    print("[0052 Uji-Diri] Memeriksa kondisi awal (tanpa mutasi)...")
    sukses, log = jalankan_uji()
    if not sukses:
        print("[0052 Uji-Diri] GAGAL: kondisi awal sudah merah!", file=sys.stderr)
        print(log, file=sys.stderr)
        return False
    print("[0052 Uji-Diri] OK: kondisi awal hijau (tes lolos).")
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

    print("\n[0052] Menjalankan uji mutasi pagar laporan penjualan...")
    if not uji_mutasi():
        print("\n[0052] Uji mutasi GAGAL!", file=sys.stderr)
        sys.exit(1)
    print("\n[0052] Seluruh 6 mutasi berhasil dibuktikan MERAH!")
