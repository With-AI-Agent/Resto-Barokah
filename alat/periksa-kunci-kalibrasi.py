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
  D. **Pensiun berkas berjejak, paket baru menyematkan** — (D1) `docs/uji/BERKAS_PENSIUN.md`
     wajib ada, memuat jalur yang sengaja dikeluarkan (mis. kunci kalibrasi, izin Lee 2026-09-19),
     jujur menyebut nasib isinya di riwayat Git, dan tiap jalur di sana **tidak boleh** muncul lagi
     di repo; (D2) paket review yang lahir SESUDAH tanggal pensiun wajib **menyematkan** isi bahan,
     bukan menunjuk jalur berkas di dalam repo. Paket tanggal pensiun itu sendiri (barang bukti)
     tidak disunting — rujukan lamanya dilindungi daftar pensiun.

Mode `--uji-diri`: salin pohon, langgar tiap aturan satu per satu, pastikan MENOLAK.
"""
from __future__ import annotations

import fnmatch
import os
import pathlib
import re
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(AKAR / "alat"))

CARA_PAKAI = "docs/uji/kalibrasi/CARA-PAKAI.md"
ALAT_SIAP = "alat/review-pr.py"
ALAT_AUDIT = "alat/audit-independen.py"
PROTOKOL = "docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md"
FOLDER_PAKET = "docs/uji/review-pr"
TANGGAL_PENSIUN = "2026-09-19"  # hari bahan lama dikeluarkan (audit D F-05); paket SESUDAH tanggal ini wajib menyematkan bahan
REGISTRI_PENSIUN = "docs/uji/BERKAS_PENSIUN.md"
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


def paket_pasca_pensiun(akar: pathlib.Path) -> list[pathlib.Path]:
    """Paket review yang lahir SESUDAH bahan dikeluarkan (aturan D2 berlaku untuk ini).

    Paket tanggal pensiun itu sendiri (mis. putaran16) = barang bukti yang tidak boleh disunting:
    rujukan lamanya ke bahan yang pensiun dilindungi `docs/uji/BERKAS_PENSIUN.md`, bukan diedit.
    

    Dipakai BAIK oleh aturan D maupun oleh mutasi uji-diri — supaya kasus uji tidak pernah
    menguji paket yang berbeda dari yang diperiksa aturan (pelajaran 2026-09-19: mutasi pertama
    tidak sengaja menyentuh paket lama `PKT-2026-09-17-…` dan hasilnya "tumpul" palsu).
    """
    folder = akar / "docs" / "uji" / "review-pr"
    if not folder.is_dir():
        return []
    hasil = []
    for paket in sorted(folder.glob("PKT-*.md")):
        tanggal = re.search(r"PKT-(\d{4}-\d{2}-\d{2})", paket.name)
        if tanggal and tanggal.group(1) > TANGGAL_PENSIUN:
            hasil.append(paket)
    return hasil


def periksa(akar: pathlib.Path) -> int:
    errs: list[str] = []
    catatan: list[str] = []

    # A. tidak ada bahan/kunci di dalam repo
    bocor = berkas_bocor(akar)
    for b in bocor:
        errs.append(f"berkas bahan/kunci kalibrasi ada DI DALAM repo: {b} — pindahkan ke luar repo "
                    "(bahan: KAL_DIR_LUAR di alat/review-pr.py; kunci: /tmp)")

    # A2. KATALOG cacat (pasangan cari/ganti = kunci jawaban) tidak boleh ada di repo.
    #     Kenapa: temuan audit H F-01 (K-2, 2026-09-20) — selama katalog ada di repo, auditor yang
    #     membaca repo bisa mencocokkan cacat yang ditanam lalu menulis skor kalibrasi sempurna
    #     tanpa mengulas. Keputusan Lee 2026-09-20: katalog DIPINDAH ke luar repo.
    katalog_di_repo = akar / "alat" / "kalibrasi-cacat.json"
    if katalog_di_repo.is_file():
        errs.append("katalog cacat ada DI DALAM repo (alat/kalibrasi-cacat.json) — kunci jawaban "
                    "kalibrasi bisa dicocokkan auditor; pindahkan ke luar repo (KALIBRASI_DIR)")
    katalog_luar = pathlib.Path(os.environ.get("KALIBRASI_DIR", str(pathlib.Path.home() / ".kalibrasi"))) / "kalibrasi-cacat.json"
    if not katalog_luar.is_file():
        catatan.append(f"katalog cacat tidak ada di luar repo ({katalog_luar}) — jalur kalibrasi tidak bisa dijalankan "
                       "di ruang kerja ini (di klon baru memang wajar)")

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

    # D1. daftar pensiun hidup & jujur
    daftar = akar / REGISTRI_PENSIUN
    if not daftar.is_file():
        errs.append(f"{REGISTRI_PENSIUN} tidak ada — berkas yang dikeluarkan dari repo kehilangan jejak "
                    "(siapa memutuskan, kapan, kenapa)")
    else:
        isi_daftar = daftar.read_text(encoding="utf-8")
        baris_daftar = [b for b in isi_daftar.splitlines()
                        if b.strip().startswith("|") and "---" not in b and "Berkas" not in b]
        jalur_pensiun: list[str] = []
        for baris in baris_daftar:
            kolom = [k.strip() for k in baris.strip().strip("|").split("|")]
            if not kolom:
                continue
            m = re.search(r"`([^`]+)`", kolom[1] if len(kolom) > 1 else "")
            if m:
                jalur_pensiun.append(m.group(1))
        if not jalur_pensiun:
            errs.append(f"{REGISTRI_PENSIUN} tidak memuat satu pun jalur pensiun — daftar kosong tidak menjaga apa pun")
        for jalur in jalur_pensiun:
            if (akar / jalur).exists():
                errs.append(f"berkas pensiun muncul LAGI di repo: {jalur} — dikembalikan tanpa keputusan Lee")
        for penanda in ("riwayat Git", "Lee"):
            if penanda not in isi_daftar:
                errs.append(f"{REGISTRI_PENSIUN} tidak menyebut '{penanda}' — bekas pensiun wajib jujur "
                            "(nasib isi di riwayat + siapa yang memutuskan)")
        catatan.append(f"berkas pensiun terdaftar: {len(jalur_pensiun)}")

    # D2. paket BARU wajib menyematkan isi bahan, bukan menunjuk jalur di repo
    for paket in paket_pasca_pensiun(akar):
        isi = paket.read_text(encoding="utf-8")
        if "pr-bahan-" in isi and "disematkan" not in isi:
            errs.append(f"{paket.relative_to(akar)} menyebut bahan kalibrasi tanpa bukti disematkan — "
                        "paket baru wajib MENYEMATKAN isi bahan (bahan tidak lagi hidup di repo)")
        jalur_repo = re.search(r"docs/uji/kalibrasi/pr-bahan-\d{4}-\d{2}-\d{2}\.diff", isi)
        if jalur_repo:
            errs.append(f"{paket.relative_to(akar)} menunjuk jalur bahan DI DALAM repo "
                        f"({jalur_repo.group(0)}) — paket baru wajib menyematkan isinya")
        catatan.append(f"paket diperiksa: {paket.name}")

    # E. aturan rotasi tertulis di protokol (bahan lama terbaca di riwayat Git → jangan dipakai lagi)
    prot = akar / PROTOKOL
    if prot.is_file():
        teks_prot = prot.read_text(encoding="utf-8")
        if "tidak dipakai lagi" not in teks_prot:
            errs.append(f"{PROTOKOL} tidak memuat aturan rotasi bahan ('tidak dipakai lagi') — "
                        "bahan yang pernah bocor bisa dinilai ulang seolah belum bocor")

    # F. Salinan kalibrasi (jalur mesin) tidak boleh membawa RIWAYAT GIT maupun katalog.
    #    Audit H F-01 (2026-09-20): dulu salinan dibuat `git worktree add` + katalog ikut tersalin,
    #    sehingga auditor bisa melihat baris cacat lewat `git diff` atau mencocokkannya dengan
    #    katalog — kalibrasi jadi bisa dipalsukan.
    alat_audit = akar / ALAT_AUDIT
    if not alat_audit.is_file():
        errs.append(f"{ALAT_AUDIT} tidak ada — penyiap kalibrasi jalur mesin hilang")
    else:
        teks_audit = alat_audit.read_text(encoding="utf-8")
        if "pastikan_salinan_bersih(" not in teks_audit:
            errs.append(f"{ALAT_AUDIT} tidak memanggil `pastikan_salinan_bersih(` — tidak ada yang "
                        "memeriksa salinan auditor bebas kunci (audit H F-01)")
        if 'git archive HEAD' not in teks_audit:
            errs.append(f"{ALAT_AUDIT} tidak membuat salinan lewat 'git archive HEAD' — kalau memakai "
                        "worktree, riwayat Git ikut terbawa dan `git diff` memperlihatkan cacat tanam")
        if re.search(r'"worktree",\s*"add"', teks_audit):
            errs.append(f"{ALAT_AUDIT} kembali memakai perintah `git worktree add` untuk salinan kalibrasi")
        if 'rglob("kalibrasi-cacat.json")' not in teks_audit:
            errs.append(f"{ALAT_AUDIT} tidak mengeluarkan katalog cacat dari salinan auditor")

    # G. Jalur review PR HANYA membaca katalog dari LUAR repo (audit H F-01).
    if alat.is_file():
        teks_g = alat.read_text(encoding="utf-8")
        if 'KATALOG = KAL_DIR / "kalibrasi-cacat.json"' not in teks_g:
            errs.append(f"{ALAT_SIAP} tidak menetapkan katalog dari LUAR repo "
                        "(`KATALOG = KAL_DIR / \"kalibrasi-cacat.json\"`) — kunci jawaban bisa kembali dibaca peninjau")
        if re.search(r'^KATALOG = AKAR / "alat" / "kalibrasi-cacat\.json"', teks_g, re.MULTILINE):
            errs.append(f"{ALAT_SIAP} masih membaca katalog DARI DALAM repo")

    print("PERIKSA KUNCI KALIBRASI — bahan & kunci tidak boleh hidup di dalam repo")
    for e in errs:
        print(f"  X {e}")
    for c in catatan:
        print(f"  · {c}")
    if errs:
        print(f"\nHASIL: GAGAL — {len(errs)} temuan (kunci jawaban kalibrasi berisiko terbaca peninjau).")
        return 1
    print(f"\nHASIL: LOLOS — {len(bocor)} berkas bocor · aturan tertulis · alat penyiap menulis di luar repo · "
          "daftar pensiun berjejak & tanpa kebangkitan · paket baru menyematkan bahan · aturan rotasi ada.")
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

        # Mutasi 6: daftar pensiun dihapus → harus GAGAL
        with salin_pohon() as tmp6:
            (tmp6 / REGISTRI_PENSIUN).unlink()
            kode6, _ = jalankan_pemeriksa(periksa, tmp6)
            hasil.append(("mutasi: daftar pensiun dihapus", kode6 != 0,
                          "ditolak" if kode6 != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 7: berkas yang dipensiunkan dihidupkan lagi → harus GAGAL
        with salin_pohon() as tmp7:
            daftar = tmp7 / REGISTRI_PENSIUN
            isi = daftar.read_text(encoding="utf-8")
            m = re.search(r"\| 1 \| `([^`]+)`", isi)
            if not m:
                hasil.append(("mutasi: berkas pensiun dihidupkan lagi", False, "baris daftar tidak terbaca"))
            else:
                target = tmp7 / m.group(1)
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("isi lama dikembalikan\n", encoding="utf-8")
                kode7, _ = jalankan_pemeriksa(periksa, tmp7)
                hasil.append(("mutasi: berkas yang dipensiunkan muncul lagi di repo", kode7 != 0,
                              "ditolak" if kode7 != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 8: paket BARU menunjuk jalur bahan di dalam repo → harus GAGAL
        with salin_pohon() as tmp8:
            (tmp8 / FOLDER_PAKET / "PKT-2099-01-01-uji.md").write_text(
                "# paket uji\n- Bahan kalibrasi: `docs/uji/kalibrasi/pr-bahan-2099-01-01.diff`\n",
                encoding="utf-8")
            kode8, _ = jalankan_pemeriksa(periksa, tmp8)
            hasil.append(("mutasi: paket baru menunjuk jalur bahan di repo", kode8 != 0,
                          "ditolak" if kode8 != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 9: paket BARU menyebut bahan tanpa menyematkannya → harus GAGAL
        with salin_pohon() as tmp9:
            (tmp9 / FOLDER_PAKET / "PKT-2099-01-02-uji.md").write_text(
                "# paket uji\n- Bahan kalibrasi pr-bahan-2099-01-02.diff disiapkan.\n", encoding="utf-8")
            kode9, _ = jalankan_pemeriksa(periksa, tmp9)
            hasil.append(("mutasi: paket baru tanpa kata 'disematkan'", kode9 != 0,
                          "ditolak" if kode9 != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 10: pemanggilan pemeriksa salinan bersih dihapus → harus GAGAL
        with salin_pohon() as tmp10:
            f = tmp10 / ALAT_AUDIT
            f.write_text(f.read_text(encoding="utf-8").replace("pastikan_salinan_bersih(", "lewati_pemeriksaan("),
                         encoding="utf-8")
            kode10, _ = jalankan_pemeriksa(periksa, tmp10)
            hasil.append(("mutasi: pemeriksa salinan kalibrasi bersih dihapus", kode10 != 0,
                          "ditolak" if kode10 != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 11: salinan kalibrasi dibuat dengan worktree lagi (riwayat ikut) → harus GAGAL
        with salin_pohon() as tmp11:
            f = tmp11 / ALAT_AUDIT
            f.write_text(f.read_text(encoding="utf-8").replace(
                '["git", "init", "-q", str(salinan)]', '["git", "worktree", "add", str(salinan)]'),
                encoding="utf-8")
            kode11, _ = jalankan_pemeriksa(periksa, tmp11)
            hasil.append(("mutasi: salinan kalibrasi kembali memakai worktree", kode11 != 0,
                          "ditolak" if kode11 != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 12: katalog dibaca lagi dari dalam repo (jalur review PR) → harus GAGAL
        with salin_pohon() as tmp12:
            f = tmp12 / ALAT_SIAP
            f.write_text(f.read_text(encoding="utf-8").replace(
                'KATALOG = KAL_DIR / "kalibrasi-cacat.json"',
                'KATALOG = AKAR / "alat" / "kalibrasi-cacat.json"'), encoding="utf-8")
            kode12, _ = jalankan_pemeriksa(periksa, tmp12)
            hasil.append(("mutasi: jalur review PR membaca katalog dari repo", kode12 != 0,
                          "ditolak" if kode12 != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 13: katalog cacat dikembalikan ke dalam repo → harus GAGAL
        with salin_pohon() as tmp13:
            (tmp13 / "alat" / "kalibrasi-cacat.json").write_text('{"cacat": []}\n', encoding="utf-8")
            kode13, _ = jalankan_pemeriksa(periksa, tmp13)
            hasil.append(("mutasi: katalog cacat dikembalikan ke dalam repo", kode13 != 0,
                          "ditolak" if kode13 != 0 else "DILOLOSKAN (tumpul)"))

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
