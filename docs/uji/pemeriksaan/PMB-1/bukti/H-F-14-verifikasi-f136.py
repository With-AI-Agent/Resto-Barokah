#!/usr/bin/env python3
"""bukti/H-F-14-verifikasi-f136.py — reproduksi independen hakim H-F-14 atas perbaikan PMB1-F-136 (commit 3f56abb).

Yang diuji: penjaga `alat/periksa-pemeriksaan.py` (artefak sesungguhnya, di salinan pohon penuh) kini MENOLAK
status berputusan (TERVERIFIKASI/PALSU/PERLU-INFO/DITUTUP/DUPLIKAT) yang kolom Hakim/Tutup-nya tidak menyebut
kartu `H-…` yang benar-benar ada di `kartu/` (baris 196-201: "rujukan_h = set(RE_KARTU_H.findall(...))" →
"if not (rujukan_h & kartu_h)").

Kontrol (mutasi dilakukan pada salinan, bukan repo nyata):
  K0 kontrol positif : salinan utuh → LOLOS (kode 0)
  K1 cacat F-136     : TERVERIFIKASI + kolom Hakim "H-TIDAK-ADA" (kartu tidak ada) → MERAH (kode 1, pesan F-136)
  K2 kontrol negatif : TERVERIFIKASI + kolom Hakim hanya "K-F-09" (kartu K pemeriksa) → MERAH (kode 1)
  K3 kontrol negatif : TERVERIFIKASI + kolom Hakim "H-TIDAK-ADA" tetapi kolom Tutup menyebut "H-F-09" → LOLOS (kode 0)
     (membuktikan kolom Tutup ikut diperiksa sesuai desain commit: "di kolom Hakim/Tutup")
Cara menjalankan: python3 docs/uji/pemeriksaan/PMB-1/bukti/H-F-14-verifikasi-f136.py
"""
from __future__ import annotations

import pathlib
import subprocess
import sys

AKAR = pathlib.Path(__file__).resolve().parents[5]
sys.path.insert(0, str(AKAR / "alat"))
from bantu_uji_diri import salin_pohon  # noqa: E402

BB = "docs/uji/pemeriksaan/PMB-1/BUKU_BESAR_TEMUAN.md"
BARIS_SASARAN = "| PMB1-F-170"  # baris BARU terakhir; mutasi BARU→TERVERIFIKASI = transisi sah


def mutasi(teks: str, hakim: str, tutup: str) -> str:
    keluar = []
    for baris in teks.splitlines():
        if baris.startswith(BARIS_SASARAN):
            sel = [s.strip() for s in baris.strip().strip("|").split("|")]
            sel[7] = "TERVERIFIKASI"  # kolom Status
            sel[8] = hakim            # kolom Hakim
            sel[10] = tutup           # kolom Verifikasi tutup
            baris = "| " + " | ".join(sel) + " |"
        keluar.append(baris)
    return "\n".join(keluar) + "\n"


def jalankan(akar: pathlib.Path) -> tuple[int, str]:
    p = subprocess.run([sys.executable, "alat/periksa-pemeriksaan.py"], cwd=akar,
                       capture_output=True, text=True, timeout=300)
    return p.returncode, p.stdout + p.stderr


def main() -> int:
    hasil: list[tuple[str, bool, str]] = []
    with salin_pohon() as akar:
        asli = (akar / BB).read_text(encoding="utf-8")

        def kasus(nama: str, ubah: str | None, harap_kode: int, cari: str | None) -> None:
            (akar / BB).write_text(asli if ubah is None else ubah, encoding="utf-8")
            kode, keluar = jalankan(akar)
            sesuai = (kode == harap_kode) and (cari is None or cari in keluar)
            ringkas = f"kode={kode} (harap {harap_kode})"
            if cari is not None:
                ringkas += f" · pesan {'ADA' if cari in keluar else 'TIDAK ADA'}: {cari[:40]!r}"
            hasil.append((nama, sesuai, ringkas))

        kasus("K0 kontrol positif: salinan utuh", None, 0, "HASIL: LOLOS")
        kasus("K1 cacat F-136: Hakim 'H-TIDAK-ADA' tanpa kartu",
              mutasi(asli, "arena/bukan-hakim H-TIDAK-ADA — bukan hakim sebenarnya", "—"),
              1, "wajib menyebut kartu hakim yang ADA")
        kasus("K2 kontrol negatif: Hakim hanya kartu K pemeriksa",
              mutasi(asli, "arena/uji K-F-09 §4 — direproduksi sendiri", "—"),
              1, "wajib menyebut kartu hakim yang ADA")
        kasus("K3 kolom Tutup menyebut kartu H yang ada",
              mutasi(asli, "arena/bukan-hakim H-TIDAK-ADA — uji kolom tutup", "arena/01a0eb71-resto-barokah H-F-09 (uji)"),
              0, "HASIL: LOLOS")

    gagal = 0
    print("UJI PROBE H-F-14 — verifikasi perbaikan PMB1-F-136 (3f56abb)")
    for nama, sesuai, ringkas in hasil:
        tanda = "OK " if sesuai else "X  "
        gagal += 0 if sesuai else 1
        print(f"  {tanda} {nama} → {ringkas}")
    if gagal:
        print(f"\nHASIL: GAGAL — {gagal} kasus tidak sesuai harapan (perbaikan F-136 tidak terbukti utuh)")
        return 1
    print("\nHASIL: LOLOS — penjaga menolak yang rusak, menerima yang sah; perbaikan F-136 terbukti.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
