#!/usr/bin/env python3
"""periksa-kunci-kalibrasi.py — penjaga BAHAN & KUNCI kalibrasi cacat tanaman.

Kenapa ada (temuan audit D F-05, 2026-09-19, K-2): berkas `pr-bahan-*.diff` adalah diff dari
migrasi **NYATA** ke versi cacat. Selama berkas itu ada di dalam repo, siapa pun yang bisa membaca
repo — termasuk peninjau yang sedang dikalibrasi — bisa melihat persis baris mana yang ditanami
cacat. Akibatnya skor "Ditemukan: X dari Y" bisa dipalsukan dan ambang lulus kalibrasi kehilangan
makna. PROTOKOL_AUDIT_INDEPENDEN §7 sudah mewajibkan kunci di luar repo; pemeriksa ini yang
menegakkannya, karena janji di dokumen saja pernah bocor.

Empat aturan:

  A. **Tidak ada bahan/kunci di dalam repo** — pola `pr-bahan-*.diff` dan berkas `*KUNCI*.md`,
     baik terlacak Git maupun liar di pohon kerja (berkas liar sama bocornya: tinggal satu
     `git add -A` untuk ikut terkirim).
  B. **Cara pakai menyatakan aturannya** — `docs/uji/kalibrasi/CARA-PAKAI.md` wajib memuat
     penanda bahwa bahan/kunci review PR hidup di luar repo.
  C. **Alat penyiap tidak menulis ke repo** — `alat/review-pr.py` wajib memakai `KAL_DIR_LUAR`
     dan tidak boleh menulis bahan ke folder repo.
  D. **Paket tidak menunjuk bahan yang sudah pensiun** — paket review yang lahir sesudah bahan
     dikeluarkan (2026-09-19) tidak boleh menyuruh peninjau membuka jalur bahan di dalam repo.

Mode `--uji-diri`: salin pohon, langgar tiap aturan satu per satu, pastikan MENOLAK.
"""
from __future__ import annotations

import fnmatch
import pathlib
import re
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(AKAR / "alat"))

CARA_PAKAI = "docs/uji/kalibrasi/CARA-PAKAI.md"
ALAT_SIAP = "alat/review-pr.py"
PROTOKOL = "docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md"
FOLDER_PAKET = "docs/uji/review-pr"
TANGGAL_PENSIUN = "2026-09-19"  # hari bahan lama dikeluarkan dari repo (audit D F-05)
PENANDA_PENSIUN = "dikeluarkan dari repo"
DIABAIKAN = {".git", "node_modules", "dist", "build", "coverage", "__pycache__", ".vite"}

POLA_BAHAN = ("pr-bahan-*.diff",)
POLA_KUNCI = ("*KUNCI*.md",)


def berkas_bocor(akar: pathlib.Path) -> list[str]:
    """Berkas bahan/kunci KALIBRASI yang berada DI DALAM repo (terlacak maupun liar).

    Catatan: pola `*KUNCI*.md` hanya berlaku di dalam `docs/uji/kalibrasi/`. Formulir pemilik
    `docs/ops/DAFTAR_KUNCI_PEMILIK.template.md` justru WAJIB ikut repo (dijaga `periksa-rahasia.py`)
    — bukan kunci kalibrasi. Pola `pr-bahan-*.diff` berlaku di mana pun: tidak ada alasan sah
    menyimpannya di dalam repo.
    """
    hasil: list[str] = []
    folder_kal = akar / "docs" / "uji" / "kalibrasi"
    for p in akar.rglob("*"):
        if not p.is_file() or DIABAIKAN & set(p.parts):
            continue
        if any(fnmatch.fnmatch(p.name, pola) for pola in POLA_BAHAN):
            hasil.append(str(p.relative_to(akar)))
        elif folder_kal in p.parents and any(fnmatch.fnmatch(p.name, pola) for pola in POLA_KUNCI):
            hasil.append(str(p.relative_to(akar)))
    return sorted(hasil)


def periksa(akar: pathlib.Path) -> int:
    errs: list[str] = []
    catatan: list[str] = []

    # A. tidak ada bahan/kunci di dalam repo
    bocor = berkas_bocor(akar)
    for b in bocor:
        errs.append(f"berkas bahan/kunci kalibrasi ada DI DALAM repo: {b} — pindahkan ke luar repo "
                    "(bahan: KAL_DIR_LUAR di alat/review-pr.py; kunci: /tmp)")

    # B. cara pakai menyatakan aturan
    cara = akar / CARA_PAKAI
    if not cara.is_file():
        errs.append(f"{CARA_PAKAI} tidak ada — aturan bahan/kunci kalibrasi tidak terdokumentasi")
    else:
        teks_cara = cara.read_text(encoding="utf-8")
        for penanda in ("pr-bahan", "di luar repo"):
            if penanda not in teks_cara:
                errs.append(f"{CARA_PAKAI} tidak memuat penanda '{penanda}' — aturan bahan di luar repo bisa hilang")

    # C. alat penyiap tidak menulis bahan ke repo
    alat = akar / ALAT_SIAP
    if not alat.is_file():
        errs.append(f"{ALAT_SIAP} tidak ada — penyiap bahan kalibrasi review PR hilang")
    else:
        teks_alat = alat.read_text(encoding="utf-8")
        if "KAL_DIR_LUAR" not in teks_alat:
            errs.append(f"{ALAT_SIAP} tidak memakai KAL_DIR_LUAR — bahan bisa kembali ditulis di dalam repo")
        if re.search(r"FOLDER_KAL\s*/\s*f?[\"']pr-bahan", teks_alat):
            errs.append(f"{ALAT_SIAP} masih menulis bahan ke folder repo (pola FOLDER_KAL / \"pr-bahan…\")")

    # D. paket tidak menunjuk bahan yang sudah pensiun
    folder = akar / FOLDER_PAKET
    if folder.is_dir():
        for paket in sorted(folder.glob("PKT-*.md")):
            tanggal = re.search(r"PKT-(\d{4}-\d{2}-\d{2})", paket.name)
            if not tanggal or tanggal.group(1) < TANGGAL_PENSIUN:
                continue
            isi = paket.read_text(encoding="utf-8")
            if "docs/uji/kalibrasi/pr-bahan-" in isi and PENANDA_PENSIUN not in isi:
                errs.append(f"{paket.relative_to(akar)} menunjuk bahan yang sudah dikeluarkan dari repo — "
                            f"tambahkan catatan '{PENANDA_PENSIUN}' atau perbarui jalurnya")
            catatan.append(f"paket diperiksa: {paket.name}")

    # E. aturan rotasi tertulis di protokol (bahan lama terbaca di riwayat Git → jangan dipakai lagi)
    prot = akar / PROTOKOL
    if prot.is_file():
        teks_prot = prot.read_text(encoding="utf-8")
        if "tidak dipakai lagi" not in teks_prot:
            errs.append(f"{PROTOKOL} tidak memuat aturan rotasi bahan ('tidak dipakai lagi') — "
                        "bahan yang pernah bocor bisa dinilai ulang seolah belum bocor")

    print("PERIKSA KUNCI KALIBRASI — bahan & kunci tidak boleh hidup di dalam repo")
    for e in errs:
        print(f"  X {e}")
    for c in catatan:
        print(f"  · {c}")
    if errs:
        print(f"\nHASIL: GAGAL — {len(errs)} temuan (kunci jawaban kalibrasi berisiko terbaca peninjau).")
        return 1
    print(f"\nHASIL: LOLOS — {len(bocor)} berkas bocor · aturan tertulis · alat penyiap menulis di luar repo · "
          "paket tidak menunjuk bahan pensiun · aturan rotasi ada.")
    return 0


def uji_diri() -> int:
    from bantu_uji_diri import jalankan_pemeriksa, laporkan, salin_pohon

    hasil = []
    with salin_pohon() as tmp:
        kode, keluar = jalankan_pemeriksa(periksa, tmp)
        hasil.append(("salinan utuh", kode == 0, f"kode {kode}"))
        if kode != 0:
            print(keluar[:1200])

        # Mutasi 1: bahan (diff) dikembalikan ke dalam repo → harus GAGAL
        with salin_pohon() as tmp1:
            (tmp1 / "docs/uji/kalibrasi/pr-bahan-2026-09-19.diff").write_text(
                "--- a/x\n+++ b/x\n@@ -1 +1 @@\n-aman\n+cacat\n", encoding="utf-8")
            kode1, _ = jalankan_pemeriksa(periksa, tmp1)
            hasil.append(("mutasi: bahan `pr-bahan-*.diff` ditaruh di dalam repo", kode1 != 0,
                          "ditolak" if kode1 != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 2: lembar kunci ikut ke repo → harus GAGAL
        with salin_pohon() as tmp2:
            (tmp2 / "docs/uji/kalibrasi/KUNCI-PALSU.md").write_text("# kunci\n", encoding="utf-8")
            kode2, _ = jalankan_pemeriksa(periksa, tmp2)
            hasil.append(("mutasi: lembar `*KUNCI*.md` ditaruh di dalam repo", kode2 != 0,
                          "ditolak" if kode2 != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 3: aturan di cara-pakai dihapus → harus GAGAL
        with salin_pohon() as tmp3:
            f = tmp3 / CARA_PAKAI
            f.write_text(f.read_text(encoding="utf-8").replace("di luar repo", "di suatu tempat"),
                         encoding="utf-8")
            kode3, _ = jalankan_pemeriksa(periksa, tmp3)
            hasil.append(("mutasi: kalimat 'di luar repo' dihapus dari cara pakai", kode3 != 0,
                          "ditolak" if kode3 != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 4: alat penyiap kembali menulis bahan ke repo → harus GAGAL
        with salin_pohon() as tmp4:
            f = tmp4 / ALAT_SIAP
            f.write_text(f.read_text(encoding="utf-8").replace(
                "keluar = KAL_DIR_LUAR / f\"pr-bahan-{tanda}.diff\"",
                "keluar = FOLDER_KAL / f\"pr-bahan-{tanda}.diff\""), encoding="utf-8")
            kode4, _ = jalankan_pemeriksa(periksa, tmp4)
            hasil.append(("mutasi: alat penyiap menulis bahan ke folder repo lagi", kode4 != 0,
                          "ditolak" if kode4 != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 6: paket menunjuk bahan pensiun TANPA catatan → harus GAGAL
        with salin_pohon() as tmp6:
            paket = sorted((tmp6 / FOLDER_PAKET).glob("PKT-2026-09-19-*.md"))
            paket = [q for q in paket if "SIAP-TEMPEL" not in q.name][:1]
            if not paket:
                hasil.append(("mutasi: paket menunjuk bahan pensiun", False, "paket 2026-09-19 tidak ada"))
            else:
                f = paket[0]
                f.write_text(f.read_text(encoding="utf-8").replace(PENANDA_PENSIUN, "catatan apa saja"),
                             encoding="utf-8")
                kode6, _ = jalankan_pemeriksa(periksa, tmp6)
                hasil.append(("mutasi: catatan pensiun dihapus dari paket", kode6 != 0,
                              "ditolak" if kode6 != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 5: aturan rotasi dihapus dari protokol → harus GAGAL
        with salin_pohon() as tmp5:
            f = tmp5 / PROTOKOL
            f.write_text(f.read_text(encoding="utf-8").replace("tidak dipakai lagi", "tetap dipakai"),
                         encoding="utf-8")
            kode5, _ = jalankan_pemeriksa(periksa, tmp5)
            hasil.append(("mutasi: aturan rotasi bahan dihapus dari protokol", kode5 != 0,
                          "ditolak" if kode5 != 0 else "DILOLOSKAN (tumpul)"))
    return laporkan("periksa-kunci-kalibrasi", hasil)


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(periksa(AKAR))
