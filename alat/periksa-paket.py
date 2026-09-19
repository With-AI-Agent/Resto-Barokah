#!/usr/bin/env python3
"""periksa-paket.py — penjaga INVARIAN paket audit & paket review PR.

Kenapa ada (dua temuan audit AUD-3 2026-09-18 yang tidak lolos apa pun):

* **F-11** — paket menuliskan commit yang diaudit, tetapi tidak ada satu pun pemeriksa
  yang memastikan commit itu benar-benar induk dari commit yang memuat berkas paket.
  Akibatnya, paket yang ter-commit di commit X bisa menyuruh auditor `git checkout`
  ke commit Y — auditor memeriksa pohon yang BERBEDA dari yang dimaksud, semuanya
  tetap hijau, dan verifikasi penutupan temuan membandingkan dua pohon berbeda.
* **F-12** — bagian "1. Artefak yang harus diperiksa (minimal)" memuat 267 dari 354
  jalur (75%) yang **tidak ada** di commit yang diaudit (jalur tugas yang belum
  dikerjakan). Auditor diarahkan mencari bukti yang tidak pernah ada, lalu bisa
  menyimpulkan "sudah ada" hanya dari NAMA berkas.

Dua aturan yang diperiksa di sini:

1. **Invariant commit:** SHA yang ditulis paket == induk langsung dari commit yang
   menambahkan/mengubah berkas paket itu di pohon HEAD. (Cara paket dibuat: tulis
   paket pada tip X → commit paket → commit itu berinduk X. Jadi invariannya selalu
   bisa dipenuhi; kalau tidak, berarti paket disegarkan setelah tip bergerak.)
2. **Artefak nyata:** setiap jalur di tabel bagian 1 harus ada di pohon commit yang
   diaudit (`git cat-file -e <sha>:<jalur>`).

Dipakai CI (lihat .github/workflows/ci.yml) dan bisa dijalankan manual:
  python3 alat/periksa-paket.py
  python3 alat/periksa-paket.py --uji-diri     # bukti pemeriksa ini bisa MENOLAK
                                              # (termasuk aturan berkas SIAP-TEMPEL: cacat nyata 2026-09-19)
"""
from __future__ import annotations

import pathlib
import re
import subprocess
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent
FOLDER_PAKET = AKAR / "docs" / "uji" / "paket-audit"
FOLDER_REVIEW = AKAR / "docs" / "uji" / "review-pr"

# Paket yang dibuat SEBELUM perbaikan F-12 (2026-09-18). Aturan 2 dilewati untuk
# berkas ini (isinya memang memuat jalur masa depan) — tetapi ATURAN 1 tetap berlaku.
# Paket yang dibuat setelah tanggal itu tidak punya pengecualian apa pun.
# Paket audit yang dibuat SEBELUM perbaikan berkas siap-tempel (2026-09-19). Berkas ini
# sudah di-commit dan TIDAK boleh disunting (aturan F-11), jadi aturan baru tidak berlaku surut
# untuk mereka; yang diperiksa adalah paket-paket sesudahnya.
LEGACY_SIAP_TEMPEL_SEBELUM = {
    "AUD-2-2026-09-17-SIAP-TEMPEL.md",
    "AUD-3-2026-09-17-SIAP-TEMPEL.md",
    "AUD-3-2026-09-18-SIAP-TEMPEL.md",
    "AUD-3-2026-09-19-SIAP-TEMPEL.md",
}

LEGACY_TANPA_ATURAN_ARTEFAK = {
    "AUD-2-2026-09-17.md",
    "AUD-2-2026-09-17-SIAP-TEMPEL.md",
    "AUD-3-2026-09-17.md",
    "AUD-3-2026-09-17-SIAP-TEMPEL.md",
    "AUD-3-2026-09-18.md",
    "AUD-3-2026-09-18-SIAP-TEMPEL.md",
    "PKT-2026-09-17-pr-01-putaran5.md",
    "PKT-2026-09-17-pr-01-putaran5-SIAP-TEMPEL.md",
    "PKT-2026-09-17-pr-01-putaran6.md",
    "PKT-2026-09-17-pr-01-putaran6-SIAP-TEMPEL.md",
    "PKT-2026-09-17-pr-01-putaran8.md",
    "PKT-2026-09-17-pr-01-putaran8-SIAP-TEMPEL.md",
    "PKT-2026-09-17-pr-01-putaran10.md",
    "PKT-2026-09-17-pr-01-putaran10-SIAP-TEMPEL.md",
    "PKT-2026-09-17-pr-01-putaran11.md",
    "PKT-2026-09-17-pr-01-putaran11-SIAP-TEMPEL.md",
    "PKT-2026-09-18-pr-01-putaran13.md",
    "PKT-2026-09-18-pr-01-putaran13-SIAP-TEMPEL.md",
}


def jalankan(perintah: list[str]) -> tuple[int, str]:
    hasil = subprocess.run(perintah, cwd=AKAR, capture_output=True, text=True)
    return hasil.returncode, (hasil.stdout + hasil.stderr).strip()


# ---- Aturan 3 (ditambahkan 2026-09-19) ----------------------------------------
# Setiap paket review PR yang terbit SEJAK tanggal di bawah ini WAJIB punya barisnya
# di `docs/uji/REVIEW_PR_RIWAYAT.md`.
#
# Kenapa: paket putaran13, putaran14, dan putaran15 terbit tanpa satu pun baris di
# riwayat itu (ditemukan 2026-09-19 saat menyiapkan putaran verifikasi). Akibatnya
# riwayat tampak "berhenti di putaran11" padahal review sudah berjalan tiga putaran
# lagi — pembaca/peninjau berikutnya bisa menyimpulkan paket itu tidak pernah ada,
# dan itu bahan temuan palsu. Tidak ada pemeriksa yang bisa MERAH untuk kelas ini.
RIWAYAT_REVIEW = AKAR / "docs" / "uji" / "REVIEW_PR_RIWAYAT.md"
SEJAK_RIWAYAT_WAJIB = "2026-09-19"  # paket bertanggal >= ini wajib tercatat
POLA_PAKET_REVIEW = re.compile(r"^PKT-(\d{4}-\d{2}-\d{2})-pr-01-putaran(\d+)(?:-SIAP-TEMPEL)?\.md$")


def periksa_riwayat(daftar: list[str]) -> list[str]:
    """Pastikan paket review baru tercatat di `docs/uji/REVIEW_PR_RIWAYAT.md`."""
    pesan: list[str] = []
    teks = RIWAYAT_REVIEW.read_text(encoding="utf-8") if RIWAYAT_REVIEW.is_file() else ""
    sudah: set[str] = set()
    for jalur in daftar:
        cocok = POLA_PAKET_REVIEW.match(pathlib.Path(jalur).name)
        if not cocok:
            continue
        tanggal, putaran = cocok.group(1), cocok.group(2)
        if tanggal < SEJAK_RIWAYAT_WAJIB or putaran in sudah:
            continue
        sudah.add(putaran)
        if f"putaran{putaran}" not in teks:
            pesan.append(
                f"paket review putaran{putaran} ({jalur}) tidak punya baris di "
                f"docs/uji/REVIEW_PR_RIWAYAT.md — setiap paket review wajib tercatat "
                f"(commit, jalur risiko, status laporan) supaya riwayat tidak bolong"
            )
    return pesan


def paket_terlacak() -> tuple[list[str], list[str]]:
    """(berkas yang diperiksa, berkas yang dilewati beserta alasannya).

    LAPORAN_* di docs/uji/review-pr adalah laporan REVIEWER (bukan paket) — di dalamnya
    `Commit yang direview` menunjuk ujung rentang PR, bukan induk commit berkasnya, jadi
    invariannya berbeda dan sengaja tidak diperiksa di sini.
    """
    _, keluaran = jalankan(["git", "ls-files", "docs/uji/paket-audit", "docs/uji/review-pr"])
    diperiksa: list[str] = []
    dilewati: list[str] = []
    for b in keluaran.splitlines():
        if not b.endswith(".md"):
            continue
        if pathlib.Path(b).name.startswith("LAPORAN_"):
            dilewati.append(b)
        else:
            diperiksa.append(b)
    return diperiksa, dilewati


def isi_pada(ref: str, jalur: str) -> str | None:
    kode, keluaran = jalankan(["git", "show", f"{ref}:{jalur}"])
    return keluaran if kode == 0 else None


def sha_diklaim(isi: str) -> str | None:
    m = re.search(r"\*\*Commit yang (?:diaudit|direview):\*\*\s*`([0-9a-f]{40})`", isi)
    return m.group(1) if m else None


def induk_dari_commit_terakhir(ref: str, jalur: str) -> tuple[str | None, str | None]:
    """(commit yang MENAMBAH paket ≤ ref, induknya) — dipakai uji-diri & pesan lama."""
    return _induk_commit(ref, jalur, tambah_saja=True)


def _induk_commit(ref: str, jalur: str, tambah_saja: bool) -> tuple[str | None, str | None]:
    perintah = ["git", "log"]
    if tambah_saja:
        perintah += ["--diff-filter=A"]
    perintah += ["-1", "--format=%H", ref, "--", jalur]
    kode, commit = jalankan(perintah)
    if kode != 0 or not commit.strip():
        return None, None
    commit = commit.strip().splitlines()[0]
    _, induk = jalankan(["git", "log", "-1", "--format=%P", commit])
    return commit, (induk.strip().split()[0] if induk.strip() else None)


def paket_ditulis_sah(ref: str, jalur: str, sha: str) -> bool | None:
    """Apakah paket ini pernah DITULIS tepat sesudah commit `sha` (isinya pun menargetkan `sha`)?

    Kenapa cara ini (pelajaran 2026-09-19): berkas paket sah ditulis lebih dari sekali dalam
    riwayatnya — paket dibuat, lalu disegarkan untuk commit berikutnya, lalu kadang disunting
    SESUDAHNYA untuk hal lain (mis. catatan provenance saat bahan kalibrasi dikeluarkan dari repo).
    Aturan lama ("commit yang TERAKHIR mengubah paket harus berinduk target") jadi rapuh: satu
    suntingan sah membuat 22 paket lama dituduh melanggar F-11 (palsu, tertangkap sapuan lokal &
    CI). Aturan "hanya commit penambah" menolak 13 paket lama. Yang benar: **ada** commit dalam
    riwayat yang menulis paket ini tepat sesudah commit target, dan isi paket saat itu menargetkan
    commit yang sama dengan isi sekarang — jadi target tidak bisa dipalsukan belakangan.

    Mengembalikan None bila riwayat tidak bisa dibaca (mis. klon dangkal) — pemanggil melewatkan.
    """
    kode, kel = jalankan(["git", "log", "--format=%H %P", ref, "--", jalur])
    if kode != 0:
        return None
    for baris in kel.splitlines():
        bagian = baris.split()
        if len(bagian) < 2 or bagian[1] != sha:
            continue
        isi = isi_pada(bagian[0], jalur)
        if isi and sha_diklaim(isi) == sha:
            return True
    return False


def jalur_bagian_1(isi: str) -> list[str]:
    """Ambil jalur berkas dari tabel '## 1. Artefak yang harus diperiksa'."""
    m = re.search(r"^## 1\. Artefak yang harus diperiksa.*?$", isi, re.M)
    if not m:
        return []
    sisa = isi[m.end():]
    akhir = re.search(r"^## ", sisa, re.M)
    bagian = sisa[: akhir.start()] if akhir else sisa
    jalur: list[str] = []
    for baris in bagian.splitlines():
        if not baris.strip().startswith("|"):
            continue
        for tok in re.findall(r"`([^`]+)`", baris):
            tok = tok.strip()
            if "/" in tok and " " not in tok and not tok.startswith("git "):
                jalur.append(tok)
    return jalur


def periksa_paket(ref: str, jalur: str, isi: str | None = None,
                  abaikan_pengecualian: bool = False) -> tuple[list[str], list[str]]:
    """Kembalikan (masalah, catatan) untuk satu berkas paket pada `ref`."""
    masalah: list[str] = []
    catatan: list[str] = []
    isi = isi if isi is not None else isi_pada(ref, jalur)
    if isi is None:
        return [f"{jalur}: tidak bisa dibaca pada {ref}"], catatan

    sha = sha_diklaim(isi)
    if not sha:
        masalah.append(f"{jalur}: tidak menulis '**Commit yang diaudit/direview:** <sha 40 digit>'")
    else:
        _, induk_terakhir = _induk_commit(ref, jalur, tambah_saja=False)
        sah = paket_ditulis_sah(ref, jalur, sha)
        if sah is False:
            masalah.append(
                f"{jalur}: F-11 — tidak ada commit dalam riwayat yang menulis paket ini tepat sesudah "
                f"commit target {sha[:8]} (penulis terakhir berinduk "
                f"{induk_terakhir[:8] if induk_terakhir else '?'}). Auditor akan memeriksa pohon yang "
                "berbeda dari yang dimaksud."
            )
        kode, _ = jalankan(["git", "cat-file", "-e", f"{sha}^{{commit}}"])
        if kode != 0:
            masalah.append(f"{jalur}: commit {sha[:8]} yang ditulis paket TIDAK ADA di repo ini")

    nama = pathlib.Path(jalur).name
    # ATURAN BARU (2026-09-19, cacat nyata): berkas `<paket>-SIAP-TEMPEL.md` adalah SATU-SATUNYA
    # yang disalin Lee ke chat auditor. Dua cacat nyata pernah terjadi: (a) kalimat pembukanya
    # masih memuat baris kosong `<<< TEMPEL ISI … >>>` sehingga auditor berhenti di langkah 1;
    # (b) tidak ada petunjuk cara MENGAMBIL BAHAN, padahal sesi auditor baru bercabang dari `main`
    # yang hanya memuat kerangka — auditor lalu melaporkan "audit TERBLOKIR" (kejadian nyata
    # 2026-09-19, sesi `arena/01a0b9f2`). Karena itu berkas siap-tempel diperiksa mesin.
    if (nama.endswith("-SIAP-TEMPEL.md") and "/paket-audit/" in jalur
            and nama not in LEGACY_SIAP_TEMPEL_SEBELUM):
        if "<<<" in isi:
            masalah.append(
                f"{jalur}: masih memuat penanda kosong `<<< … >>>` — berkas siap-tempel harus utuh; "
                "auditor akan berhenti karena menyangka paketnya belum diisi"
            )
        if "SAMBUNGAN: PAKET AUDIT" not in isi:
            masalah.append(f"{jalur}: tidak memuat bagian 'SAMBUNGAN: PAKET AUDIT' (paketnya tidak ikut tersalin)")
        if "git fetch origin" not in isi or "git checkout --detach" not in isi:
            masalah.append(
                f"{jalur}: tidak memuat cara MENGAMBIL BAHAN (`git fetch origin …` + `git checkout --detach …`); "
                "sesi auditor baru bercabang dari `main` dan tanpa perintah ini ia tidak bisa melihat kode proyek"
            )
        if "protokol" in isi and "PROTOKOL_AUDIT_INDEPENDEN.md" not in isi:
            masalah.append(f"{jalur}: menyebut protokol tanpa menunjuk berkasnya")

    if nama in LEGACY_TANPA_ATURAN_ARTEFAK and not abaikan_pengecualian:
        catatan.append(f"{jalur}: aturan artefak dilewati (paket lama sebelum perbaikan F-12)")
        return masalah, catatan
    if nama.startswith("PKT-"):
        # Paket review PR: tidak punya daftar artefak minimum, cukup invarian commit.
        catatan.append(f"{jalur}: paket review — hanya invarian commit yang diperiksa")
        return masalah, catatan
    if not sha:
        return masalah, catatan
    jalur_1 = jalur_bagian_1(isi)
    if not jalur_1:
        masalah.append(f"{jalur}: bagian 1 (artefak minimum) tidak memuat satu pun jalur berkas")
        return masalah, catatan
    hilang = []
    for j in sorted(set(jalur_1)):
        kode, _ = jalankan(["git", "cat-file", "-e", f"{sha}:{j}"])
        if kode != 0:
            hilang.append(j)
    if hilang:
        masalah.append(
            f"{jalur}: F-12 — {len(hilang)} dari {len(set(jalur_1))} jalur di bagian 1 TIDAK ADA "
            f"di commit {sha[:8]}: {', '.join(hilang[:5])}{' …' if len(hilang) > 5 else ''}"
        )
    else:
        catatan.append(f"{jalur}: bagian 1 bersih ({len(set(jalur_1))} jalur, semuanya ada di {sha[:8]})")
    return masalah, catatan


def periksa(ref: str = "HEAD", berkas: list[str] | None = None) -> int:
    daftar, dilewati = (berkas, []) if berkas is not None else paket_terlacak()
    if not daftar:
        print("TIDAK ADA paket terlacak di docs/uji/paket-audit atau docs/uji/review-pr")
        return 0
    masalah: list[str] = []
    catatan: list[str] = []
    for jalur in daftar:
        m, c = periksa_paket(ref, jalur)
        masalah += m
        catatan += c
    masalah += periksa_riwayat(daftar)
    for c in catatan:
        print(f"  [catatan] {c}")
    if dilewati:
        print(f"  [catatan] {len(dilewati)} laporan reviewer dilewati (invariannya berbeda: menunjuk ujung rentang PR)")
    for m in masalah:
        print(f"  [X] {m}")
    print("-" * 70)
    print(f"PERIKSA PAKET — {len(daftar)} paket terlacak (ref {ref})")
    if masalah:
        print(f"HASIL: GAGAL — {len(masalah)} pelanggaran invarian paket (F-11/F-12 + riwayat)")
        return 1
    print("HASIL: LOLOS — setiap paket menunjuk induk commit-nya sendiri, artefaknya nyata, dan paket review baru tercatat di riwayat.")
    return 0


def uji_diri() -> int:
    """Buktikan pemeriksa ini bisa MENOLAK, memakai paket nyata dari riwayat repo.

    Kasus 1 (harus GAGAL): paket AUD-3 2026-09-18 pada commit `d1f11d7` — versi itu
    memuat 267 jalur yang tidak ada di commit yang diaudit (temuan audit F-12 nyata).
    Kasus 2 (harus LOLOS): pohon sekarang.
    """
    hasil: list[tuple[str, bool, str]] = []

    kode, _ = jalankan(["git", "cat-file", "-e", "d1f11d7f32bdb78b14b6ed4d935946c515c656df^{commit}"])
    if kode != 0:
        print("LEWAT: commit sejarah d1f11d7 tidak ada di repo ini (klon dangkal?)")
        return 0
    isi_lama = isi_pada("d1f11d7", "docs/uji/paket-audit/AUD-3-2026-09-18.md")
    if isi_lama is None:
        print("LEWAT: versi paket di d1f11d7 tidak bisa dibaca")
        return 0
    masalah, _ = periksa_paket("d1f11d7", "docs/uji/paket-audit/AUD-3-2026-09-18.md", isi=isi_lama,
                               abaikan_pengecualian=True)
    hasil.append(("paket lama d1f11d7 (267 jalur hantu) ditolak", bool(masalah),
                  masalah[0][:90] if masalah else "DILOLOSKAN (tumpul)"))

    # Mutasi ringan: ubah SHA di salinan paket sekarang → aturan 1 harus menolak.
    sekarang = paket_terlacak()[0]
    if sekarang:
        jalur = sekarang[0]
        isi = isi_pada("HEAD", jalur) or ""
        m_sha = sha_diklaim(isi)
        if m_sha:
            palsu = isi.replace(m_sha, "0" * 40, 1)
            masalah_palsu, _ = periksa_paket("HEAD", jalur, isi=palsu, abaikan_pengecualian=True)
            hasil.append(("mutasi: SHA di paket diganti SHA palsu", bool(masalah_palsu),
                          masalah_palsu[0][:90] if masalah_palsu else "DILOLOSKAN (tumpul)"))
            # Mutasi: jalur hantu ditambahkan ke bagian 1 → aturan 2 harus menolak.
            m = re.search(r"^## 1\. Artefak yang harus diperiksa.*?$", isi, re.M)
            if m:
                hantu = isi[: m.end()] + "\n\n| 999 | `supabase/tes/uji-hantu-yang-tidak-ada.sql` |\n" + isi[m.end():]
                masalah_hantu, _ = periksa_paket("HEAD", jalur, isi=hantu, abaikan_pengecualian=True)
                masalah_hantu = [x for x in masalah_hantu if "F-12" in x] or masalah_hantu
                hasil.append(("mutasi: jalur hantu ditambahkan ke bagian 1", bool(masalah_hantu),
                              masalah_hantu[0][:90] if masalah_hantu else "DILOLOSKAN (tumpul)"))

    # Aturan 4 (siap-tempel): buktikan bisa MENOLAK placeholder & petunjuk-ambil-bahan yang hilang.
    siap_tempel = [j for j in sekarang
                   if j.endswith("-SIAP-TEMPEL.md") and "/paket-audit/" in j
                   and pathlib.Path(j).name not in LEGACY_SIAP_TEMPEL_SEBELUM]
    if siap_tempel:
        jalur_st = siap_tempel[-1]
        isi_st = isi_pada("HEAD", jalur_st) or ""
        if "<<<" not in isi_st and "git fetch origin" in isi_st:
            m_ph = isi_st.replace("— paket lengkapnya ada di bagian", "<<< TEMPEL ISI docs/uji/paket-audit/… DI SINI >>>\n— paket lengkapnya ada di bagian", 1)
            masalah_ph, _ = periksa_paket("HEAD", jalur_st, isi=m_ph, abaikan_pengecualian=True)
            masalah_ph = [x for x in masalah_ph if "penanda kosong" in x] or masalah_ph
            hasil.append(("mutasi: penanda kosong <<< dimasukkan lagi ke berkas siap-tempel", bool(masalah_ph),
                          masalah_ph[0][:90] if masalah_ph else "DILOLOSKAN (tumpul)"))
            m_fetch = isi_st.replace("git fetch origin", "git ambil origin", 1)
            masalah_fetch, _ = periksa_paket("HEAD", jalur_st, isi=m_fetch, abaikan_pengecualian=True)
            masalah_fetch = [x for x in masalah_fetch if "MENGAMBIL BAHAN" in x] or masalah_fetch
            hasil.append(("mutasi: petunjuk mengambil bahan dihapus dari berkas siap-tempel", bool(masalah_fetch),
                          masalah_fetch[0][:90] if masalah_fetch else "DILOLOSKAN (tumpul)"))
        else:
            print("LEWAT: berkas siap-tempel belum memuat penanda/ambil-bahan (cek urutan kerja)")

    masalah_pohon: list[str] = []
    for jalur in sekarang:
        m, _ = periksa_paket("HEAD", jalur)
        masalah_pohon += m
    hasil.append(("pohon sekarang diterima", not masalah_pohon,
                  "lolos" if not masalah_pohon else masalah_pohon[0][:90]))

    # Aturan 3: paket review baru tanpa baris riwayat wajib DITOLAK; yang tercatat diterima.
    masalah_riwayat = periksa_riwayat(["docs/uji/review-pr/PKT-2026-09-19-pr-01-putaran99.md"])
    hasil.append(("mutasi: paket review baru tanpa baris riwayat ditolak", bool(masalah_riwayat),
                  masalah_riwayat[0][:90] if masalah_riwayat else "DILOLOSKAN (tumpul)"))
    kontrol_riwayat = periksa_riwayat(["docs/uji/review-pr/PKT-2026-09-19-pr-01-putaran16.md"])
    hasil.append(("kontrol: paket review yang TERCATAT di riwayat diterima", not kontrol_riwayat,
                  "diterima" if not kontrol_riwayat else kontrol_riwayat[0][:90]))

    print("UJI-DIRI periksa-paket")
    gagal = 0
    for kasus, sesuai, ringkas in hasil:
        tanda = "OK " if sesuai else "X  "
        if not sesuai:
            gagal += 1
        print(f"  {tanda} {kasus} → {ringkas}")
    if gagal:
        print(f"\nHASIL: GAGAL — {gagal} kasus uji-diri tidak sesuai harapan (pemeriksa mungkin tumpul)")
        return 1
    print("\nHASIL: LOLOS — pemeriksa terbukti bisa MENOLAK paket cacat dan MENERIMA yang utuh.")
    return 0


def main() -> int:
    if "--uji-diri" in sys.argv:
        return uji_diri()
    ref = "HEAD"
    berkas = None
    if "--ref" in sys.argv:
        ref = sys.argv[sys.argv.index("--ref") + 1]
    if "--berkas" in sys.argv:
        berkas = sys.argv[sys.argv.index("--berkas") + 1:]
    return periksa(ref, berkas)


if __name__ == "__main__":
    raise SystemExit(main())
