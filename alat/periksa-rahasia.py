#!/usr/bin/env python3
"""periksa-rahasia.py — penjaga RAHASIA & lembar kunci pemilik.

Kenapa ada: Lee menyiapkan lembar isian kunci (`docs/ops/DAFTAR_KUNCI_PEMILIK.local.md`).
Lembar itu berguna, tetapi juga pintu masuk kelas cacat paling mahal: **kunci rahasia
ikut ter-commit**. Pemeriksa ini menjaga dua hal sekaligus:

 1. **Berkas rahasia tidak pernah masuk Git.** Pola `*.local.md` dan `.env*` wajib ada di
    `.gitignore`, dan tidak boleh ada berkas rahasia yang terlacak (`git ls-files`).
    Formulir kosongnya (`docs/ops/DAFTAR_KUNCI_PEMILIK.template.md`) wajib ada — formulir inilah
    yang ikut Git, berkas kerja terisi yang tidak ikut Git.
 2. **Tidak ada kunci bertekanan tinggi di berkas yang terlacak** — JWT panjang, kunci
    privat, token penyedia (Supabase/Resend/OpenAI/AWS). Ini bukan pengganti pemeriksa
    rahasia penuh (itu tugas `T1-30`), tetapi penjaga minimum yang bekerja hari ini.

Mode `--uji-diri`: salin repo, masukkan kunci palsu / hapus aturan abaikan, pastikan MENOLAK.
"""
from __future__ import annotations

import pathlib
import re
import subprocess
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(AKAR / "alat"))

# Pola disusun dari potongan supaya berkas pemeriksa ini sendiri tidak ikut "ketangkap"
# saat pemeriksa memindai berkasnya sendiri.
POLA_RAHASIA = [
    ("JWT panjang (kunci layanan)", re.compile(r"eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.")),
    ("kunci privat", re.compile("-----BEGIN " + r"[A-Z ]*PRIVATE KEY-----")),
    ("token Supabase (sbp_)", re.compile(r"sbp_" + r"[a-f0-9]{20,}")),
    ("kunci rahasia Supabase baru (sb_secret_)", re.compile(r"\bsb_secret_[A-Za-z0-9_-]{16,}")),
    ("token OpenAI/Resend (sk- / sk-proj-)", re.compile(r"\bsk-(?:proj-)?[A-Za-z0-9_-]{20,}")),
    ("token Resend (re_)", re.compile(r"\bre_" + r"[A-Za-z0-9]{20,}")),
    ("kunci AWS", re.compile(r"\bAKIA" + r"[0-9A-Z]{16}\b")),
    ("kunci Brevo (xkeysib-)", re.compile(r"\bxkeysib-[a-zA-Z0-9]{64}\b")),
    ("kunci rahasia Google OAuth (GOCSPX-)", re.compile(r"\bGOCSPX-[A-Za-z0-9_-]{28}\b")),
    ("token akses GitHub (ghp_)", re.compile(r"\bgh[pousr]_[A-Za-z0-9]{36,}\b")),
]
BERKAS_RAHASIA_POLA = ("*.local.md", "*.local", ".env", ".env.*")
FORMULIR = "docs/ops/DAFTAR_KUNCI_PEMILIK.template.md"  # ikut Git; berkas kerja terisinya tidak
BERKAS_DIABAIKAN = {"alat/periksa-rahasia.py"}  # pemeriksa sendiri (polanya ada di kodenya)


def berkas_terlacak(akar: pathlib.Path) -> list[str]:
    keluaran = subprocess.run(["git", "-C", str(akar), "ls-files"], capture_output=True, text=True).stdout
    return [b for b in keluaran.splitlines() if b.strip()]


def periksa(akar: pathlib.Path) -> int:
    errs: list[str] = []
    catatan: list[str] = []

    # 1. aturan abaikan
    gi = akar / ".gitignore"
    isi_gi = gi.read_text(encoding="utf-8") if gi.is_file() else ""
    if not isi_gi:
        errs.append(".gitignore tidak ada — berkas rahasia bisa ikut ter-commit")
    for pola in ("*.local", ".env"):
        if pola not in isi_gi:
            errs.append(f"pola '{pola}' tidak ada di .gitignore")
    if "*.local.md" not in isi_gi:
        errs.append("pola '*.local.md' tidak ada di .gitignore — lembar kunci pemilik bisa ikut ter-commit")

    # 1b. formulir kosong wajib ada — tanpa formulir, tidak ada tempat menyalin yang aman
    if not (akar / FORMULIR).is_file():
        errs.append(
            f"formulir {FORMULIR} tidak ada — formulir kosong ini yang ikut Git "
            "(berkas kerja terisi yang tidak ikut Git dibuat dengan menyalinnya)"
        )

    # 2. berkas rahasia tidak boleh terlacak
    terlacak = berkas_terlacak(akar)
    for b in terlacak:
        nama = b.split("/")[-1]
        if nama.endswith(".local.md") or nama.endswith(".local") or nama == ".env" or nama.startswith(".env."):
            if nama != ".env.example":
                errs.append(f"berkas rahasia TERLACAK Git: {b} — keluarkan dari Git (git rm --cached) dan pastikan .gitignore benar")

    # 3. kunci bertekanan tinggi di berkas terlacak
    for b in terlacak:
        if b in BERKAS_DIABAIKAN:
            continue
        jalur = akar / b
        if not jalur.is_file():
            continue
        try:
            isi = jalur.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            catatan.append(f"dilewati (bukan teks): {b}")
            continue
        for nama, pola in POLA_RAHASIA:
            m = pola.search(isi)
            if m:
                errs.append(f"{b}: terlihat {nama} — RAHASIA tidak boleh masuk repo (potongan: {m.group(0)[:12]}…)")

    print(f"PERIKSA RAHASIA — {len(terlacak)} berkas terlacak diperiksa · {len(POLA_RAHASIA)} pola kunci · aturan abaikan: {'ada' if isi_gi else 'TIDAK ADA'}")
    for c in catatan:
        print(f"  [catatan] {c}")
    if errs:
        print(f"\nHASIL: GAGAL — {len(errs)} temuan")
        for e in errs:
            print(f"  [X] {e}")
        return 1
    print("\nHASIL: LOLOS — tidak ada kunci rahasia di berkas terlacak; lembar kunci pemilik diabaikan Git.")
    return 0


def siapkan_git_salinan(tmp: pathlib.Path) -> None:
    """Salinan uji tidak membawa .git, jadi indeksnya disiapkan supaya 'terlacak' bermakna."""
    subprocess.run(["git", "-C", str(tmp), "init", "-q"], capture_output=True)
    subprocess.run(["git", "-C", str(tmp), "config", "user.email", "uji@lokal"], capture_output=True)
    subprocess.run(["git", "-C", str(tmp), "config", "user.name", "uji"], capture_output=True)
    subprocess.run(["git", "-C", str(tmp), "add", "-A"], capture_output=True)


def uji_diri() -> int:
    from bantu_uji_diri import jalankan_pemeriksa, laporkan, salin_pohon

    hasil = []
    with salin_pohon() as tmp:
        siapkan_git_salinan(tmp)
        kode, keluar = jalankan_pemeriksa(periksa, tmp)
        hasil.append(("salinan utuh", kode == 0, f"kode {kode}"))
        if kode != 0:
            print(keluar[:1200])

        # Mutasi 1: kunci palsu disisipkan ke berkas terlacak → harus GAGAL
        with salin_pohon() as tmp2:
            siapkan_git_salinan(tmp2)
            f = tmp2 / "PANDUAN_PENGGUNA.md"
            f.write_text(f.read_text(encoding="utf-8") + "\nKunci uji: " + "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9" + ".abcdefghijklmnop.qrstuvwxyz\n", encoding="utf-8")
            kode2, _ = jalankan_pemeriksa(periksa, tmp2)
            hasil.append(("mutasi: kunci palsu disisipkan ke berkas terlacak", kode2 != 0,
                          "ditolak" if kode2 != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 1b: format secret key Supabase baru → harus GAGAL; publishable
        # sengaja tidak diuji sebagai rahasia karena memang boleh berada di klien.
        with salin_pohon() as tmp_secret:
            siapkan_git_salinan(tmp_secret)
            f = tmp_secret / "PANDUAN_PENGGUNA.md"
            f.write_text(f.read_text(encoding="utf-8") + "\nFixture sintetis: " + "sb_secret_" + "A" * 40 + "\n", encoding="utf-8")
            kode_secret, _ = jalankan_pemeriksa(periksa, tmp_secret)
            hasil.append(("mutasi: format kunci Supabase baru sb_secret_ disisipkan", kode_secret != 0,
                          "ditolak" if kode_secret != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 1c: kunci Brevo sintetis → harus GAGAL
        with salin_pohon() as tmp_brevo:
            siapkan_git_salinan(tmp_brevo)
            f = tmp_brevo / "PANDUAN_PENGGUNA.md"
            f.write_text(f.read_text(encoding="utf-8") + "\nKunci Brevo: " + "xkeysib-" + "a" * 64 + "\n", encoding="utf-8")
            kode_brevo, _ = jalankan_pemeriksa(periksa, tmp_brevo)
            hasil.append(("mutasi: kunci Brevo xkeysib- disisipkan", kode_brevo != 0,
                          "ditolak" if kode_brevo != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 1d: kunci Google OAuth sintetis → harus GAGAL
        with salin_pohon() as tmp_google:
            siapkan_git_salinan(tmp_google)
            f = tmp_google / "PANDUAN_PENGGUNA.md"
            f.write_text(f.read_text(encoding="utf-8") + "\nGoogle Secret: " + "GOCSPX-" + "A" * 28 + "\n", encoding="utf-8")
            kode_google, _ = jalankan_pemeriksa(periksa, tmp_google)
            hasil.append(("mutasi: kunci Google OAuth GOCSPX- disisipkan", kode_google != 0,
                          "ditolak" if kode_google != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 1e: token OpenAI modern sk-proj- sintetis → harus GAGAL
        with salin_pohon() as tmp_openai:
            siapkan_git_salinan(tmp_openai)
            f = tmp_openai / "PANDUAN_PENGGUNA.md"
            f.write_text(f.read_text(encoding="utf-8") + "\nOpenAI Project Key: " + "sk-proj-" + "aB1_-" * 10 + "\n", encoding="utf-8")
            kode_openai, _ = jalankan_pemeriksa(periksa, tmp_openai)
            hasil.append(("mutasi: token OpenAI modern sk-proj- disisipkan", kode_openai != 0,
                          "ditolak" if kode_openai != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 2: aturan abaikan dihapus → harus GAGAL
        with salin_pohon() as tmp3:
            siapkan_git_salinan(tmp3)
            gi = tmp3 / ".gitignore"
            gi.write_text(gi.read_text(encoding="utf-8").replace("*.local.md\n", ""), encoding="utf-8")
            kode3, _ = jalankan_pemeriksa(periksa, tmp3)
            hasil.append(("mutasi: pola '*.local.md' dihapus dari .gitignore", kode3 != 0,
                          "ditolak" if kode3 != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 3: formulir kosong dihapus → harus GAGAL
        with salin_pohon() as tmp4:
            (tmp4 / FORMULIR).unlink()
            siapkan_git_salinan(tmp4)
            kode4, _ = jalankan_pemeriksa(periksa, tmp4)
            hasil.append((f"mutasi: formulir {FORMULIR.split('/')[-1]} dihapus", kode4 != 0,
                          "ditolak" if kode4 != 0 else "DILOLOSKAN (tumpul)"))
    return laporkan("periksa-rahasia", hasil)


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(periksa(AKAR))
