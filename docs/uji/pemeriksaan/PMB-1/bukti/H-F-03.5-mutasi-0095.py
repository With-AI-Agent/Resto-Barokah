#!/usr/bin/env python3
"""Mutasi HAKIM H-F-03.5 (2026-10-02) — seberapa tajam uji resmi PMB1-F-038 kasus 5-8 terhadap migrasi 0095?

Cara jalan (dari akar repo):  python3 docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.5-mutasi-0095.py

Cara kerja: salinan SEMENTARA pohon Git (git archive HEAD) dibuat di folder sementara; hanya salinan itu yang
dimutasi. Repo asli TIDAK disentuh. Tiap mutan dijalankan terhadap uji resmi
supabase/tes/voucher_kasir_wajib_identitas.sql lewat runner resmi alat/uji-sql.mjs.
  TERTANGKAP = uji resmi GAGAL (uji bergigi)      SELAMAT = uji resmi tetap LULUS (uji buta terhadap mutasi itu)
Mutan M6 (backfill dibuang) juga dijalankan terhadap SELURUH suite untuk memastikan tak ada uji lain yang menjaganya.
"""
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

AKAR = pathlib.Path(__file__).resolve().parents[5]
MIGRASI = "supabase/migrations/0095_penyatuan_awalan_nomor_hp_pelanggan.sql"
UJI = "supabase/tes/voucher_kasir_wajib_identitas.sql"

MUTAN = [
    ("M0 tanpa mutasi (kontrol: berkas asli)", None, None),
    ("M1 buang aturan awalan 62",
     "           when left(v, 2) = '62' and length(v) >= 9 then '0' || substr(v, 3)\n", ""),
    ("M2 buang aturan awalan 8",
     "           when left(v, 1) = '8' and length(v) >= 8 then '0' || v\n", ""),
    ("M3 ambang aturan 62 dari >=9 jadi >=14",
     "left(v, 2) = '62' and length(v) >= 9", "left(v, 2) = '62' and length(v) >= 14"),
    ("M4 ambang aturan 8 dari >=8 jadi >=13",
     "left(v, 1) = '8' and length(v) >= 8", "left(v, 1) = '8' and length(v) >= 13"),
    ("M5 pemicu tidak memanggil normalisasi",
     "  new.telepon := public.normalisasi_telepon_pelanggan(new.telepon);\n", "  null;\n"),
    ("M6 buang BACKFILL (update baris lama)",
     "update public.pelanggan\n   set telepon = public.normalisasi_telepon_pelanggan(telepon)\n where telepon is not null;\n", ""),
    ("M7 salah potong awalan 62 (substr 4)", "'0' || substr(v, 3)", "'0' || substr(v, 4)"),
    ("M8 awalan 8 diberi dua nol", "then '0' || v\n", "then '00' || v\n"),
]


def jalankan(sandi: pathlib.Path, *berkas: str) -> str:
    r = subprocess.run(["node", "alat/uji-sql.mjs", *berkas], cwd=sandi, capture_output=True, text=True)
    return r.stdout + r.stderr


def alasan_gagal(keluaran: str) -> str:
    baris = keluaran.splitlines()
    for i, b in enumerate(baris):
        if b.strip().startswith("GAGAL ") and i + 1 < len(baris):
            return baris[i + 1].strip()[:110]
    return "(alasan tidak terbaca)"


def main() -> int:
    sandi = pathlib.Path(tempfile.mkdtemp(prefix="mutasi0095-"))
    try:
        arsip = subprocess.run(["git", "-C", str(AKAR), "archive", "HEAD"], capture_output=True, check=True)
        subprocess.run(["tar", "-x", "-C", str(sandi)], input=arsip.stdout, check=True)
        (sandi / "alat" / "node_modules").symlink_to(AKAR / "alat" / "node_modules")
        target = sandi / MIGRASI
        asli = target.read_text(encoding="utf-8")
        print(f"MUTASI 0095 — salinan sementara dari HEAD {subprocess.run(['git','-C',str(AKAR),'rev-parse','--short','HEAD'],capture_output=True,text=True).stdout.strip()}")
        print(f"uji yang diukur: {UJI}\n")
        selamat = []
        for nama, a, b in MUTAN:
            if a is not None:
                assert a in asli, f"jangkar mutasi tidak ditemukan: {nama}"
                target.write_text(asli.replace(a, b, 1), encoding="utf-8")
            else:
                target.write_text(asli, encoding="utf-8")
            keluaran = jalankan(sandi, UJI)
            lulus = "uji: 1 LULUS" in keluaran
            if a is not None and lulus:
                selamat.append(nama)
            if a is None:
                status = "LULUS   (kontrol)  " if lulus else "GAGAL   (KONTROL RUSAK)"
            else:
                status = "LULUS   (SELAMAT)  " if lulus else "GAGAL   (TERTANGKAP)"
            catatan = "" if lulus else " <- " + alasan_gagal(keluaran)
            print(f"{nama:46s} -> {status}{catatan}")
        # M6 terhadap SELURUH suite
        a, b = MUTAN[6][1], MUTAN[6][2]
        target.write_text(asli.replace(a, b, 1), encoding="utf-8")
        suite = jalankan(sandi)
        ringkas = [x for x in suite.splitlines() if x.startswith("uji:") or x.startswith("HASIL:")]
        print("\nSUITE PENUH dengan M6 (backfill dibuang):", " | ".join(ringkas))
        target.write_text(asli, encoding="utf-8")
        print(f"\nRINGKAS: mutan yang SELAMAT = {selamat if selamat else 'tidak ada'}")
        return 0
    finally:
        shutil.rmtree(sandi, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
