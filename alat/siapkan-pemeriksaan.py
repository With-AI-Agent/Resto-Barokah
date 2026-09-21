#!/usr/bin/env python3
"""SIAPKAN PEMERIKSAAN — satu kalimat sederhana dari Lee → paket siap + prompt PENDEK.

Permintaan Lee 2026-09-20 (terkunci di docs/DECISIONS_LOG.md): mekanisme audit/review/
pemeriksaan harus mudah dipicu. Lee cukup bilang (contoh):
  · "siapkan pemeriksaan independen menyeluruh"        → paket audit AUD-3 seluruh proyek
  · "siapkan pemeriksaan menyeluruh di bidang keamanan" → paket audit AUD-3 lingkup keamanan
  · "siapkan review PR"                                 → paket review PR berikutnya
  · "jalankan pemeriksaan fondasi"                      → pemeriksa fondasi jalan LANGSUNG (tanpa sesi baru)

Setelah paket jadi (dan di-commit + push), alat ini mencetak PROMPT PENDEK (±5 baris)
yang cukup Lee tempel ke sesi baru: prompt pendek itu menunjuk SATU URL berkas
SIAP-TEMPEL di GitHub (repo publik) — isi lengkapnya (kategori, kriteria, commit target,
aturan main) tetap di berkas paket yang terjaga mesin (`alat/periksa-paket.py`).

Laporan balik: sesi independen menulis laporan ke foldernya sendiri (sesuai paket) lalu
push ke cabangnya; sesi kerja menariknya dengan `--ambil-laporan` alat terkait
(idempoten). Jalur tempel manual tetap ada sebagai cadangan bila sesi independen
tidak punya akses push.

Jalankan:  python3 alat/siapkan-pemeriksaan.py --frasa "<kalimat Lee>"
           python3 alat/siapkan-pemeriksaan.py --prompt-pendek [BERKAS-SIAP-TEMPEL]
           python3 alat/siapkan-pemeriksaan.py --uji-diri
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
import pathlib

AKAR = pathlib.Path(__file__).resolve().parent.parent
REPO_PUBLIK = "With-AI-Agent/Resto-Barokah"  # dari `git remote get-url origin`
FOLDER_PAKET = ("docs/uji/paket-audit/", "docs/uji/review-pr/")

# ------------------------------------------------------------------ frasa → jenis
JENIS = ("menyeluruh", "keamanan", "review-pr", "fondasi")


def kenali_frasa(teks: str) -> str | None:
    """Petakan kalimat sederhana Lee ke jenis pemeriksaan. Urutan penting:
    kata paling spesifik diperiksa lebih dulu."""
    t = teks.lower()
    if "review" in t and ("pr" in t or "pull" in t):
        return "review-pr"
    if "fondasi" in t or "foundation" in t:
        return "fondasi"
    if "keamanan" in t or "security" in t:
        return "keamanan"
    if any(k in t for k in ("menyeluruh", "audit", "pemeriksaan", "periksa independen")):
        return "menyeluruh"
    return None


# ------------------------------------------------------------------ utilitas git
def git(*args: str) -> tuple[int, str]:
    p = subprocess.run(["git", *args], cwd=AKAR, capture_output=True, text=True)
    return p.returncode, (p.stdout or p.stderr).strip()


def commit_memuat(rel: str, ref: str = "HEAD") -> bool:
    """True bila berkas itu ada di commit `ref` (bukan hanya di direktori kerja)."""
    kode, _ = git("cat-file", "-e", f"{ref}:{rel}")
    return kode == 0


def head_sudah_didorong() -> tuple[bool, str]:
    """True bila HEAD sudah ada di cabang remote yang sama (URL publik bisa dibuka).

    Bertanya LANGSUNG ke remote (`ls-remote`) — rujukan remote-tracking lokal bisa basi
    (kejadian nyata 2026-09-20: push sukses tetapi `origin/...` lokal tidak ter-update,
    sehingga prompt pendek ditolak padahal URL-nya hidup)."""
    _, cabang = git("branch", "--show-current")
    if not cabang:
        return False, "HEAD tidak berada di cabang mana pun"
    _, sha_head = git("rev-parse", "HEAD")
    kode, keluar = git("ls-remote", "origin", f"refs/heads/{cabang}")
    if kode != 0:
        return False, f"tidak bisa bertanya ke remote: {keluar[:120]}"
    sha_remote = keluar.split()[0] if keluar.split() else ""
    if sha_remote == sha_head.strip():
        return True, cabang
    # remote di belakang HEAD? terima juga bila HEAD sudah termuat di remote-tracking
    kode2, _ = git("merge-base", "--is-ancestor", "HEAD", f"origin/{cabang}")
    if kode2 == 0:
        return True, cabang
    return False, f"HEAD belum di-push ke origin/{cabang}"


def commit_target_paket(isi: str) -> str | None:
    m = re.search(r"\*\*Commit yang diaudit:\*\*\s*`([0-9a-f]{7,40})`", isi)
    if not m:
        m = re.search(r"\*\*Commit target:\*\*\s*`?([0-9a-f]{7,40})", isi)
    return m.group(1) if m else None


# ------------------------------------------------------------------ prompt pendek
def bangun_prompt_pendek(rel_paket: str, sha_paket: str, sha_target: str | None,
                         isi_paket: str = "") -> str:
    """Buat PROMPT PENDEK (yang ditempel Lee ke sesi baru). Isinya hanya penunjuk:
    satu URL + identitas paket + kewajiban laporan. SEMUA detail tetap di berkas paket."""
    url = f"https://raw.githubusercontent.com/{REPO_PUBLIK}/{sha_paket}/{rel_paket}"
    apakah = "PENINJAU REVIEW PR INDEPENDEN" if "/review-pr/" in rel_paket else "AUDITOR INDEPENDEN"
    target = sha_target or "(tertulis di dalam paket)"
    nama_paket = pathlib.Path(rel_paket).name
    return (
        f"Kamu {apakah} untuk proyek Resto Barokah (repo publik; kamu hanya-baca).\n"
        f"1. Ambil paket lengkapmu — aturan main, lingkup, kriteria, dan commit target ada di dalamnya:\n"
        f"   {url}\n"
        f"2. Ikuti paket itu PERSIS dari langkah 0 sampai laporan selesai; jangan mengarang mekanisme lain.\n"
        f"3. Identitas: paket `{nama_paket}` · commit yang diaudit `{target}`.\n"
        f"4. Setelah selesai: tulis HANYA berkas laporan (nama & folder sesuai paket), commit, dan push\n"
        f"   ke cabang sesimu sendiri. Bila tidak bisa push: tulis \"belum ter-push\" di laporan dan beri tahu Lee."
    )


def mode_prompt_pendek(arg_berkas: str | None, lewat_cek_push: bool = False) -> int:
    if arg_berkas:
        kandidat = [AKAR / arg_berkas]
    else:
        berkas = []
        for folder in FOLDER_PAKET:
            berkas += sorted((AKAR / folder).glob("*SIAP-TEMPEL.md"))
        if not berkas:
            print("GAGAL: belum ada berkas *-SIAP-TEMPEL.md — buat paketnya dulu (--frasa …).")
            return 1
        kandidat = [max(berkas, key=lambda p: p.stat().st_mtime)]
    p = kandidat[0]
    if not p.is_file():
        print(f"GAGAL: berkas tidak ada: {p}")
        return 1
    rel = str(p.relative_to(AKAR))
    if not commit_memuat(rel):
        print(f"GAGAL: {rel} belum masuk commit HEAD — commit + push dulu, baru cetak prompt pendek.")
        print("       (URL prompt pendek harus bisa dibuka sesi baru; berkas yang belum di-push tidak bisa.)")
        return 1
    if not lewat_cek_push:
        ok, sebab = head_sudah_didorong()
        if not ok:
            print(f"GAGAL: {sebab} — push dulu supaya URL paket bisa dibuka dari luar.")
            return 1
    _, sha_head = git("rev-parse", "HEAD")
    isi = p.read_text(encoding="utf-8")
    prompt = bangun_prompt_pendek(rel, sha_head.strip(), commit_target_paket(isi), isi)
    print("PROMPT PENDEK — salin blok ini apa adanya ke chat/percakapan BARU:")
    print("===== MULAI SALIN DARI SINI =====")
    print(prompt)
    print("===== SELESAI SALIN =====")
    print("\nSetelah sesi independen selesai dan laporannya ter-push, kembali ke sesi kerja dan bilang:")
    print('  "Laporan audit sudah masuk, periksa."  (atau "Laporan review sudah masuk, periksa.")')
    return 0


# ------------------------------------------------------------------ siapkan paket
def jalankan_alat(perintah: list[str]) -> int:
    p = subprocess.run(perintah, cwd=AKAR)
    return p.returncode


def mode_siapkan(jenis: str, pr: int | None, izin_ci: str | None) -> int:
    if jenis == "fondasi":
        print("Pemeriksaan fondasi berjalan LANGSUNG (tidak perlu sesi baru):")
        return jalankan_alat(["python3", "alat/periksa-fondasi-independen.py"])
    if jenis == "review-pr":
        perintah = ["python3", "alat/review-pr.py", "--siapkan"]
        if pr:
            perintah += ["--pr", str(pr)]
    else:  # menyeluruh / keamanan
        perintah = ["python3", "alat/audit-independen.py", "--paket", "AUD-3", "--semua"]
        if jenis == "keamanan":
            perintah += ["--bidang", "keamanan"]
    if izin_ci:
        perintah += ["--izinkan-ci-belum-hijau", izin_ci]
    kode = jalankan_alat(perintah)
    if kode != 0:
        return kode
    print("\nLANGKAH BERIKUTNYA (sesi kerja, berurutan):")
    print("  1. commit + push berkas paket yang baru dibuat (URL prompt pendek butuh berkas itu di GitHub);")
    print("  2. jalankan: python3 alat/siapkan-pemeriksaan.py --prompt-pendek")
    print("  3. tempel prompt pendek yang dicetak ke sesi baru (model berbeda bila bisa).")
    return 0


# ------------------------------------------------------------------ uji diri
def uji_diri() -> int:
    hasil: list[tuple[str, bool, str]] = []

    def catat(nama: str, ok: bool, kenapa: str = "") -> None:
        hasil.append((nama, ok, kenapa))

    # 1) peta frasa → jenis (kata Lee yang sebenarnya)
    kasus_frasa = [
        ("siapkan pemeriksaan independen menyeluruh", "menyeluruh"),
        ("Siapkan pemeriksaan menyeluruh di bidang keamanan aplikasi ini", "keamanan"),
        ("siapkan review PR", "review-pr"),
        ("jalankan pemeriksaan fondasi", "fondasi"),
        ("siapkan audit menyeluruh", "menyeluruh"),
    ]
    for teks, harap in kasus_frasa:
        dapat = kenali_frasa(teks)
        catat(f"frasa {teks!r} → {harap}", dapat == harap, f"dapat {dapat!r}")
    # frasa tak dikenal wajib DITOLAK (bukan diam-diam jadi audit)
    catat("frasa asing ditolak", kenali_frasa("siapkan kopi") is None)

    # 2) prompt pendek benar-benar PENDEK dan menunjuk URL + identitas
    contoh = bangun_prompt_pendek(
        "docs/uji/paket-audit/AUD-3-2026-09-20-abc1234-SIAP-TEMPEL.md",
        "f" * 40, "a" * 40)
    catat("prompt memuat URL paket", "raw.githubusercontent.com/With-AI-Agent/Resto-Barokah/" + "f" * 40 in contoh)
    catat("prompt memuat commit target", "a" * 40 in contoh)
    catat("prompt ≤ 10 baris", len(contoh.splitlines()) <= 10, f"{len(contoh.splitlines())} baris")
    review = bangun_prompt_pendek("docs/uji/review-pr/PKT-x-SIAP-TEMPEL.md", "f" * 40, None)
    catat("paket review → peran peninjau", "PENINJAU REVIEW" in review)
    catat("paket audit → peran auditor", "AUDITOR INDEPENDEN" in contoh)

    # 3) prompt-pendek MENOLAK berkas yang belum masuk commit HEAD
    palsu = AKAR / "docs" / "uji" / "paket-audit" / "AUD-3-UJI-DIRI-BELUM-COMMIT-SIAP-TEMPEL.md"
    palsu.write_text("uji", encoding="utf-8")
    try:
        import io
        import contextlib
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            kode = mode_prompt_pendek(str(palsu.relative_to(AKAR)), lewat_cek_push=True)
        catat("berkas belum di-commit → ditolak", kode != 0)
    finally:
        palsu.unlink(missing_ok=True)

    # 4) jalur nyata: SIAP-TEMPEL yang BENAR-BENAR ada di HEAD → prompt tercetak
    nyata = sorted((AKAR / "docs" / "uji" / "paket-audit").glob("*SIAP-TEMPEL.md"))
    nyata = [p for p in nyata if commit_memuat(str(p.relative_to(AKAR)))]
    if nyata:
        import io
        import contextlib
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            kode = mode_prompt_pendek(str(nyata[-1].relative_to(AKAR)), lewat_cek_push=True)
        keluar = buf.getvalue()
        catat("berkas nyata di HEAD → prompt tercetak", kode == 0 and "MULAI SALIN" in keluar)
    else:
        catat("berkas nyata di HEAD → prompt tercetak", False, "tidak ada SIAP-TEMPEL terlacak")

    gagal = [h for h in hasil if not h[1]]
    for nama, ok, kenapa in hasil:
        print(f"  [{'OK ' if ok else 'GGL'}] {nama}" + (f" — {kenapa}" if kenapa and not ok else ""))
    print(f"\nHASIL UJI-DIRI: {len(hasil) - len(gagal)}/{len(hasil)} kasus LOLOS")
    return 1 if gagal else 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--frasa", help='kalimat sederhana Lee, mis. "siapkan pemeriksaan menyeluruh"')
    ap.add_argument("--jenis", choices=JENIS, help="jenis pemeriksaan (alternatif --frasa)")
    ap.add_argument("--pr", type=int, help="nomor PR GitHub (untuk jenis review-pr)")
    ap.add_argument("--prompt-pendek", nargs="?", const="", default=None,
                    help="cetak prompt pendek untuk paket SIAP-TEMPEL (default: yang terbaru)")
    ap.add_argument("--izinkan-ci-belum-hijau", help="alasan izin pemilik (diteruskan ke pembuat paket)")
    ap.add_argument("--uji-diri", action="store_true")
    a = ap.parse_args()

    if a.uji_diri:
        return uji_diri()
    if a.prompt_pendek is not None:
        return mode_prompt_pendek(a.prompt_pendek or None)
    jenis = a.jenis or (kenali_frasa(a.frasa) if a.frasa else None)
    if not jenis:
        print("GAGAL: jenis pemeriksaan tidak dikenali.")
        print(f"  Contoh frasa: \"siapkan pemeriksaan independen menyeluruh\" · \"…di bidang keamanan\" ·")
        print(f"  \"siapkan review PR\" · \"jalankan pemeriksaan fondasi\". Jenis sah: {', '.join(JENIS)}.")
        return 1
    return mode_siapkan(jenis, a.pr, a.izinkan_ci_belum_hijau)


if __name__ == "__main__":
    sys.exit(main())
