#!/usr/bin/env python3
"""periksa-temuan-audit.py — penjaga DAFTAR TEMUAN AUDIT (docs/uji/AUDIT_RIWAYAT.md §1b).

Kenapa ada: temuan audit pernah tercatat sebagai satu baris gelondongan ("kertas kerja K-3/K-4"),
sehingga beberapa temuan tidak punya status, bukti, atau pemilik penyelesaian. Laporan audit
menyebut 27 temuan (A: 10, B: 17); daftar penutup harus memuat **setiap** temuan satu per satu —
kalau tidak, temuan bisa hilang tanpa ada yang tahu.

Yang diperiksa:
 1. Setiap `[F-xx]` di kedua berkas laporan audit punya baris di tabel §1b (tidak ada yang hilang).
 2. Setiap baris menyebut laporan+nomor temuan yang benar-benar ada (tidak ada temuan karangan).
 3. Status wajib salah satu: `DITUTUP` atau `TERBUKA` (tidak boleh kosong/abu-abu).
 4. Baris `DITUTUP` wajib menunjuk **bukti yang benar-benar ada** di repo (rujukan ber-backtick).
 5. Baris `TERBUKA` wajib menunjuk **tugas ROADMAP yang benar-benar ada** (mis. `T1-24`) —
    temuan tanpa pemilik penyelesaian adalah temuan yang akan terlupakan.

Mode `--uji-diri`: salin repo ke folder sementara, rusak daftarnya, pastikan pemeriksa MENOLAK.
"""
from __future__ import annotations

import pathlib
import re
import sys

from bantu_uji_diri import AKAR, jalankan_pemeriksa, laporkan, salin_pohon

RIWAYAT = "docs/uji/AUDIT_RIWAYAT.md"
LAPORAN = {
    "A": "docs/uji/audit/LAPORAN_AUD-3_2026-09-17_menyeluruh.dari-01a0aeb0.md",
    "B": "docs/uji/audit/LAPORAN_AUD-3_2026-09-17_menyeluruh.md",
}
ROADMAP = "docs/ROADMAP.md"


def temuan_laporan(akar: pathlib.Path) -> dict[str, set[str]]:
    hasil: dict[str, set[str]] = {}
    for nama, rel in LAPORAN.items():
        berkas = akar / rel
        if not berkas.is_file():
            continue
        isi = berkas.read_text(encoding="utf-8")
        hasil[nama] = set(re.findall(r"^### \[(F-\d+)\]", isi, re.MULTILINE))
    return hasil


def baris_daftar(akar: pathlib.Path) -> list[tuple[int, list[str]]]:
    """Ambil baris tabel §1b (daftar temuan). Kembalikan (nomor baris, kolom)."""
    berkas = akar / RIWAYAT
    if not berkas.is_file():
        return []
    baris = berkas.read_text(encoding="utf-8").splitlines()
    mulai = None
    for i, b in enumerate(baris):
        if b.startswith("### 1b"):
            mulai = i
            break
    if mulai is None:
        return []
    hasil: list[tuple[int, list[str]]] = []
    for i in range(mulai + 1, len(baris)):
        b = baris[i]
        if b.startswith("### ") or b.startswith("## ") and not b.startswith("###"):
            break
        if b.startswith("## "):
            break
        if not b.strip().startswith("|"):
            continue
        kolom = [k.strip() for k in b.strip().strip("|").split("|")]
        if len(kolom) < 5 or set(kolom[0]) <= set("-: "):
            continue
        if kolom[0].lower().startswith(("laporan", "temuan")):
            continue
        hasil.append((i + 1, kolom))
    return hasil


def jalur_ada(akar: pathlib.Path, rujukan: list[str]) -> list[str]:
    return [r for r in rujukan if not (akar / r).exists()]


def periksa(akar: pathlib.Path) -> int:
    errs: list[str] = []
    temuan = temuan_laporan(akar)
    if not temuan:
        print("GAGAL: berkas laporan audit tidak ditemukan")
        return 1
    roadmap = (akar / ROADMAP).read_text(encoding="utf-8") if (akar / ROADMAP).is_file() else ""
    tugas_roadmap = set(re.findall(r"T\d+-\d+", roadmap))

    baris = baris_daftar(akar)
    if not baris:
        print(f"GAGAL: tabel daftar temuan (§1b) tidak ditemukan di {RIWAYAT}")
        return 1

    tercatat: dict[str, set[str]] = {nama: set() for nama in temuan}
    tertutup = terbuka = 0
    for no, kolom in baris:
        laporan_temuan, tingkat, ringkas, status, bukti = kolom[0], kolom[1], kolom[2], kolom[3], " ".join(kolom[4:])
        # 2. rujukan laporan+nomor wajib benar
        rujukan = re.findall(r"\b([AB])\s*(F-\d+)", laporan_temuan)
        if not rujukan:
            errs.append(f"baris {no}: kolom 'Laporan' tidak menyebut satu pun temuan (mis. 'A F-01'): {laporan_temuan[:60]}")
        for nama, fid in rujukan:
            if fid not in temuan.get(nama, set()):
                errs.append(f"baris {no}: temuan {nama} {fid} tidak ada di laporan {nama} — rujukan salah")
            else:
                tercatat[nama].add(fid)
        # 3. status wajib jelas
        if "DITUTUP" not in status and "TERBUKA" not in status:
            errs.append(f"baris {no}: status tidak jelas ('{status[:40]}') — wajib memuat DITUTUP atau TERBUKA")
        # 4/5. bukti atau pemilik penyelesaian
        if "DITUTUP" in status:
            tertutup += 1
            rujukan_berkas = [r for r in re.findall(r"`([^`\n]+)`", bukti)
                              if "/" in r and not r.startswith(("http", "python", "node", "git "))]
            if not rujukan_berkas:
                errs.append(f"baris {no} ({laporan_temuan}): DITUTUP tanpa rujukan bukti ber-backtick")
            hilang = jalur_ada(akar, rujukan_berkas)
            for h in hilang:
                errs.append(f"baris {no} ({laporan_temuan}): bukti penutup menunjuk berkas yang TIDAK ADA: {h}")
        if "TERBUKA" in status:
            terbuka += 1
            tugas = set(re.findall(r"T\d+-\d+", bukti))
            if not tugas:
                errs.append(f"baris {no} ({laporan_temuan}): TERBUKA tanpa tugas ROADMAP — temuan tanpa pemilik akan terlupakan")
            for t in sorted(tugas - tugas_roadmap):
                errs.append(f"baris {no} ({laporan_temuan}): tugas '{t}' tidak ada di ROADMAP.md")

    # 1. tidak ada temuan yang hilang
    for nama, ids in temuan.items():
        for fid in sorted(ids):
            if fid not in tercatat.get(nama, set()):
                errs.append(f"temuan {nama} {fid} BELUM punya baris di daftar §1b — temuan tidak boleh hilang")

    total = sum(len(v) for v in temuan.values())
    print(f"PERIKSA TEMUAN AUDIT — laporan A: {len(temuan.get('A', set()))} temuan · laporan B: {len(temuan.get('B', set()))} temuan "
          f"· daftar §1b: {len(baris)} baris ({tertutup} ditutup · {terbuka} terbuka)")
    if errs:
        print(f"\nHASIL: GAGAL — {len(errs)} temuan")
        for e in errs:
            print(f"  [X] {e}")
        return 1
    print(f"\nHASIL: LOLOS — {total} temuan terlacak semua, tiap DITUTUP punya bukti hidup, tiap TERBUKA punya tugas.")
    return 0


def uji_diri() -> int:
    hasil = []
    with salin_pohon() as tmp:
        kode, keluar = jalankan_pemeriksa(periksa, tmp)
        hasil.append(("salinan utuh", kode == 0, f"kode {kode}"))
        if kode != 0:
            print(keluar[:2000])

        # Mutasi 1: satu baris daftar dihapus → harus GAGAL
        with salin_pohon() as tmp2:
            berkas = tmp2 / RIWAYAT
            isi = berkas.read_text(encoding="utf-8").splitlines()
            idx = next((i for i, b in enumerate(isi) if re.match(r"\|\s*[AB]\s*F-\d+", b)), None)
            if idx is None:
                hasil.append(("mutasi hapus baris", False, "tidak menemukan baris daftar untuk dihapus"))
            else:
                del isi[idx]
                berkas.write_text("\n".join(isi) + "\n", encoding="utf-8")
                kode2, keluar2 = jalankan_pemeriksa(periksa, tmp2)
                hasil.append(("mutasi: satu temuan dihapus dari daftar", kode2 != 0,
                              "ditolak" if kode2 != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 2: bukti penutup diarahkan ke berkas yang tidak ada → harus GAGAL
        with salin_pohon() as tmp3:
            berkas = tmp3 / RIWAYAT
            isi = berkas.read_text(encoding="utf-8")
            baris = isi.splitlines()
            idx = next((i for i, b in enumerate(baris) if "DITUTUP" in b and "`supabase/tes/" in b), None)
            if idx is None:
                hasil.append(("mutasi bukti palsu", False, "tidak menemukan baris DITUTUP ber-bukti untuk dimutasi"))
            else:
                baris[idx] = re.sub(r"`supabase/tes/[^`]+`", "`supabase/tes/tidak-ada.sql`", baris[idx], count=1)
                berkas.write_text("\n".join(baris) + "\n", encoding="utf-8")
                kode3, _ = jalankan_pemeriksa(periksa, tmp3)
                hasil.append(("mutasi: bukti penutup menunjuk berkas palsu", kode3 != 0,
                              "ditolak" if kode3 != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 3: temuan terbuka kehilangan tugas ROADMAP → harus GAGAL
        with salin_pohon() as tmp4:
            berkas = tmp4 / RIWAYAT
            baris = berkas.read_text(encoding="utf-8").splitlines()
            # hanya baris tabel — kalimat pengantar juga memuat kata "TERBUKA"
            idx = next((i for i, b in enumerate(baris) if b.strip().startswith("|") and "TERBUKA" in b), None)
            if idx is None:
                hasil.append(("mutasi tugas hilang", False, "tidak menemukan baris TERBUKA"))
            else:
                baris[idx] = re.sub(r"T\d+-\d+", "T9-99", baris[idx])
                berkas.write_text("\n".join(baris) + "\n", encoding="utf-8")
                kode4, _ = jalankan_pemeriksa(periksa, tmp4)
                hasil.append(("mutasi: temuan terbuka menunjuk tugas palsu", kode4 != 0,
                              "ditolak" if kode4 != 0 else "DILOLOSKAN (tumpul)"))
    return laporkan("periksa-temuan-audit", hasil)


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(periksa(AKAR))
