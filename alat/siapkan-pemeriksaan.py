#!/usr/bin/env python3
"""SIAPKAN PEMERIKSAAN — satu kalimat sederhana dari Lee → paket siap + prompt PENDEK.

Permintaan Lee 2026-09-20 (terkunci di docs/DECISIONS_LOG.md): mekanisme audit/review/
pemeriksaan harus mudah dipicu. Lee cukup bilang (contoh):
  · "siapkan pemeriksaan independen menyeluruh"        → paket audit AUD-3 seluruh proyek
  · "siapkan pemeriksaan menyeluruh di bidang keamanan" → paket audit AUD-3 lingkup keamanan
  · "siapkan review PR"                                 → paket review PR berikutnya
  · "jalankan pemeriksaan fondasi"                      → pemeriksa fondasi jalan LANGSUNG (tanpa sesi baru)

Setelah paket jadi (dan di-commit + push), alat ini mencetak PROMPT PENDEK (±5 baris)
yang cukup Lee tempel ke sesi baru: locator repo + cabang sumber + SHA paket + path
SIAP-TEMPEL melalui git/gh terautentikasi (publik maupun privat) — isi lengkapnya (kategori, kriteria, commit target,
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
IDENTITAS_REPO = "With-AI-Agent/Resto-Barokah"  # dari `git remote get-url origin`
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
    """True bila HEAD sudah ada di cabang remote yang sama (commit tersedia bagi akses repo yang sah).

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
    # Ref cache bukan bukti remote terkini: hanya gunakan objek tip yang dijawab server.
    kode2, _ = git("merge-base", "--is-ancestor", "HEAD", sha_remote)
    if kode2 == 0:
        return True, cabang
    return False, f"HEAD belum terverifikasi tersedia pada origin/{cabang}"


def commit_target_paket(isi: str) -> str | None:
    m = re.search(r"\*\*Commit yang diaudit:\*\*\s*`([0-9a-f]{7,40})`", isi)
    if not m:
        m = re.search(r"\*\*Commit (?:target|yang direview):\*\*\s*`?([0-9a-f]{7,40})", isi)
    return m.group(1) if m else None


# ------------------------------------------------------------------ prompt pendek
def bangun_prompt_pendek(rel_paket: str, sha_paket: str, sha_target: str | None,
                         isi_paket: str = "", cabang_sumber: str = "") -> str:
    """Penunjuk pendek ke paket UTUH, bukan ringkasan pengganti konteks/aturan.

    Sumber paket dan sasaran audit berbeda: URL dikunci ke commit yang memuat
    paket, sedangkan commit target dibaca dari isi paket yang sudah diterbitkan.
    """
    if not re.fullmatch(r"[0-9a-f]{40}", sha_paket):
        raise ValueError("commit paket harus SHA penuh, bukan cabang bergerak")
    if not sha_target or not re.fullmatch(r"[0-9a-f]{40}", sha_target):
        raise ValueError("commit target tidak terbaca — jangan mengarang sasaran")
    if not re.fullmatch(r"[A-Za-z0-9_./-]+", cabang_sumber):
        raise ValueError("cabang sumber paket tidak terbaca")
    if not re.fullmatch(r"docs/uji/[A-Za-z0-9_./-]+\.md", rel_paket) or ".." in rel_paket.split("/"):
        raise ValueError("path paket tidak sah")
    apakah = "PENINJAU REVIEW PR INDEPENDEN" if "/review-pr/" in rel_paket else "AUDITOR INDEPENDEN"
    if "/maraton/" in rel_paket:
        tugas = re.search(r"T-\d+", pathlib.PurePosixPath(rel_paket).name)
        if not tugas:
            raise ValueError("paket maraton wajib punya ID tugas")
        apakah = f"PEMERIKSA MARATON {tugas.group()} (bantah-balik, laporan-saja)"
    return (
        f"Kamu {apakah} Resto Barokah. Baca SELURUH paket dan langsung jalankan semua tahapnya.\n"
        f"Repo: {IDENTITAS_REPO}. Cabang sumber paket: {cabang_sumber}.\n"
        f"Commit PAKET: {sha_paket}. Path: {rel_paket}. Commit TARGET pemeriksaan (berbeda): {sha_target}.\n"
        f"Gunakan git/gh terautentikasi (termasuk repo privat), mis. git show <SHA_PAKET>:<PATH>; jangan andalkan web/raw URL. Jika paket/sasaran tidak terbaca atau tidak cocok, berhenti dan laporkan; jangan menebak atau meminta token.\n"
        f"Jangan ubah kode; tulis HANYA laporan. Tanpa meminta Lee lagi, commit dan push otomatis melalui alat/kirim-laporan.py dari SHA PAKET ke cabang SESIMU SENDIRI. Cabang/working tree bisa dipakai bersama: draf UUID + snapshot, commit terisolasi, retry fast-forward; jangan merge/rebase/reset/force-push/menimpa atau push cabang sumber/main.\n"
        f"Wajib verifikasi remote; bukti akhir: repo, cabang tujuan, path laporan, commit SHA, remote_tip dan SHA-256. Chat/lokal saja bukan selesai. Jika TERBLOKIR, pertahankan laporan dan nyatakan BELUM TERVERIFIKASI, jangan klaim selesai."
    )


def serah_memuat_prompt(teks: str, prompt: str) -> bool:
    """Periksa DRAF respons, bukan mengklaim bisa melihat chat yang sudah terkirim.

    URL saja / uraian 'prompt sudah siap' tidak cukup. Wajib satu blok siap salin
    berisi cetakan persis, tidak diparafrase sampai instruksi penting hilang.
    """
    blok = re.findall(r"^```[^\n]*\n(.*?)^```[ \t]*$", teks, re.M | re.S)
    return any(isi.strip() == prompt.strip() for isi in blok)


def mode_prompt_pendek(arg_berkas: str | None, lewat_cek_push: bool = False,
                       draf_serah: str | None = None) -> int:
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
        print("       (locator paket harus menunjuk objek remote yang sudah diterbitkan; berkas yang belum di-push tidak bisa.)")
        return 1
    if not lewat_cek_push:
        ok, sebab = head_sudah_didorong()
        if not ok:
            print(f"GAGAL: {sebab} — push dulu supaya paket tersedia di remote bagi sesi berizin.")
            return 1
    _, sha_head = git("rev-parse", "HEAD")
    # Jangan membaca draf lokal yang belum masuk URL immutable di atas.
    kode, isi = git("show", f"HEAD:{rel}")
    if kode != 0:
        print("GAGAL: paket tidak dapat dibaca dari commit HEAD.")
        return 1
    pagar = ("alat/kirim-laporan.py", "Tanpa meminta Lee lagi", "verifikasi remote", "BELUM TERVERIFIKASI")
    if not all(t in isi for t in pagar) or "git add docs/uji/" in isi:
        print("GAGAL: paket lama/belum memiliki kontrak pengiriman aman. Jangan edit paket beku atau mengulang audit aktif; buat paket BARU hanya saat penyerahan baru diminta.")
        return 1
    if not all(commit_memuat(f"alat/{f}") for f in ("kirim-laporan.py", "kirim_laporan.py")):
        print("GAGAL: SHA paket belum memuat alat pengirim; terbitkan alat bersama paket dulu.")
        return 1
    _, cabang = git("branch", "--show-current")
    try:
        prompt = bangun_prompt_pendek(rel, sha_head.strip(), commit_target_paket(isi), isi,
                                     cabang_sumber=cabang.strip())
    except ValueError as e:
        print(f"GAGAL: {e}")
        return 1
    if draf_serah:
        try:
            teks = pathlib.Path(draf_serah).read_text(encoding="utf-8")
        except (OSError, UnicodeError) as e:
            print(f"GAGAL: draf respons tidak dapat dibaca: {e}")
            return 1
        if not serah_memuat_prompt(teks, prompt):
            print("GAGAL: draf wajib memuat prompt pendek utuh dalam blok siap salin; tautan saja tidak cukup.")
            return 1
        print("LOLOS: draf memuat prompt pendek siap-tempel. Agent tetap wajib mengirim blok itu DI CHAT.")
        return 0
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
    print("  3. AGENT wajib menampilkan cetakannya dalam blok siap-tempel DI CHAT; tautan saja tidak cukup.")
    print("  4. sebelum mengirim respons, periksa draf: --prompt-pendek <paket> --periksa-serah <draf-respons>.")
    return 0


# ------------------------------------------------------------------ uji diri
def uji_diri() -> int:
    global AKAR
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
        "f" * 40, "a" * 40, cabang_sumber="arena/sumber-uji")
    catat("locator privat lengkap", "Repo: With-AI-Agent/Resto-Barokah" in contoh and "Commit PAKET: " + "f" * 40 in contoh and "Path: docs/uji/" in contoh)
    catat("prompt memuat commit target", "a" * 40 in contoh)
    catat("paket lengkap wajib dibaca", "Baca SELURUH paket" in contoh)
    catat("sasaran gagal-tertutup", "berhenti dan laporkan" in contoh and "jangan menebak" in contoh)
    catat("larangan merge dan push main", "jangan merge" in contoh and "main" in contoh)
    catat("bukti serah-terima GitHub", "bukti akhir: repo, cabang tujuan, path laporan, commit SHA" in contoh)
    catat("pengiriman otomatis tanpa pengingat", "Tanpa meminta Lee lagi" in contoh and "kirim-laporan.py" in contoh)
    catat("working tree bersama tidak diasumsikan unik", "working tree bisa dipakai bersama" in contoh)
    catat("bukti remote dan hambatan jujur", "verifikasi remote" in contoh and "BELUM TERVERIFIKASI" in contoh)
    catat("prompt ≤ 10 baris", len(contoh.splitlines()) <= 10, f"{len(contoh.splitlines())} baris")
    review = bangun_prompt_pendek("docs/uji/review-pr/PKT-x-SIAP-TEMPEL.md", "f" * 40, "a" * 40, cabang_sumber="arena/sumber-review")
    maraton = bangun_prompt_pendek("docs/uji/maraton/G3-T-04-SIAP-TEMPEL.md", "f" * 40, "a" * 40, cabang_sumber="arena/sumber-uji")
    catat("maraton punya peran/ID dan otomatis kirim", "PEMERIKSA MARATON T-04" in maraton and "Tanpa meminta Lee lagi" in maraton)
    catat("paket review → peran peninjau", "PENINJAU REVIEW" in review)
    catat("paket audit → peran auditor", "AUDITOR INDEPENDEN" in contoh)

    catat("cabang sumber eksplisit", "Cabang sumber paket: arena/sumber-uji" in contoh)
    catat("review juga berkonteks dan wajib push", "arena/sumber-review" in review and "commit dan push" in review)
    for nama, teks, harap in [
        ("blok lengkap diterima", "Untuk Lee:\n```text\n" + contoh + "\n```\n", True),
        ("tautan saja ditolak", contoh.splitlines()[1], False),
        ("janji tanpa prompt ditolak", "Prompt pendek sudah siap di berkas.", False),
        ("prompt tanpa blok ditolak", contoh, False),
        ("kewajiban push dihapus ditolak", "```\n" + contoh.replace("commit dan push", "simpan") + "\n```", False),
        ("commit sasaran diganti ditolak", "```\n" + contoh.replace("a" * 40, "b" * 40) + "\n```", False),
        ("cabang sumber diganti ditolak", "```\n" + contoh.replace("arena/sumber-uji", "main") + "\n```", False),
    ]:
        catat(nama, serah_memuat_prompt(teks, contoh) == harap)
    for nama, paket_sha, target_sha, sumber in [
        ("URL bergerak ditolak", "main", "a" * 40, "arena/uji"),
        ("target hilang ditolak", "f" * 40, None, "arena/uji"),
        ("target pendek ditolak", "f" * 40, "a" * 7, "arena/uji"),
        ("cabang hilang ditolak", "f" * 40, "a" * 40, ""),
    ]:
        try:
            bangun_prompt_pendek("paket.md", paket_sha, target_sha, cabang_sumber=sumber)
        except ValueError:
            catat(nama, True)
        else:
            catat(nama, False)

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

    # 4) Real committed fixture, not the frozen active AUD-2 packet. The latter
    # must NOT be silently republished with contradictory old delivery instructions.
    import tempfile
    from unittest.mock import patch
    from kontrak_laporan import blok_pengiriman
    lama = AKAR
    with tempfile.TemporaryDirectory(prefix="serah-prompt-") as tmp:
        try:
            AKAR = pathlib.Path(tmp)
            git("init", "--initial-branch", "arena/01a0c2c1-resto-barokah")
            git("config", "user.name", "Uji")
            git("config", "user.email", "uji@example.test")
            rel = "docs/uji/paket-audit/UJI-SIAP-TEMPEL.md"
            file = AKAR / rel
            file.parent.mkdir(parents=True)
            isi_commit = "- **Commit yang diaudit:** `" + "a"*40 + "`\n" + blok_pengiriman("audit", "arena/sumber-uji")
            file.write_text(isi_commit)
            (AKAR / "alat").mkdir()
            for nama in ("kirim-laporan.py", "kirim_laporan.py"):
                (AKAR / "alat" / nama).write_bytes((lama / "alat" / nama).read_bytes())
            git("add", "."); git("commit", "-m", "fixture paket terbit")
            with contextlib.redirect_stdout(io.StringIO()):
                kode = mode_prompt_pendek(rel, lewat_cek_push=True)
            catat("paket committed baru → prompt tercetak", kode == 0)
            _, sha = git("rev-parse", "HEAD")
            _, cabang = git("branch", "--show-current")
            prompt = bangun_prompt_pendek(rel, sha.strip(), commit_target_paket(isi_commit), cabang_sumber=cabang.strip())
            draf = AKAR / "respons.md"
            for nama, isi_draf, harap in [
                ("jalur draf lengkap diterima", "```text\n" + prompt + "\n```\n", 0),
                ("jalur draf locator saja ditolak", prompt.splitlines()[1], 1),
            ]:
                draf.write_text(isi_draf, encoding="utf-8")
                with contextlib.redirect_stdout(io.StringIO()):
                    kode = mode_prompt_pendek(rel, lewat_cek_push=True, draf_serah=str(draf))
                catat(nama, kode == harap)
            with contextlib.redirect_stdout(io.StringIO()):
                kode = mode_prompt_pendek(rel, lewat_cek_push=True, draf_serah=str(draf.with_name("hilang.md")))
            catat("jalur draf hilang ditolak", kode == 1)
            with patch.object(pathlib.Path, "read_text", side_effect=AssertionError("jangan baca paket lokal")):
                with contextlib.redirect_stdout(io.StringIO()):
                    kode = mode_prompt_pendek(rel, lewat_cek_push=True)
            catat("metadata diambil dari paket committed, bukan draf lokal", kode == 0)
            file.write_text("- **Commit yang diaudit:** `" + "a"*40 + "`\ngit add docs/uji/audit/")
            git("add", rel); git("commit", "-m", "fixture instruksi lama")
            with contextlib.redirect_stdout(io.StringIO()):
                kode = mode_prompt_pendek(rel, lewat_cek_push=True)
            catat("paket lama tidak diterbitkan ulang diam-diam", kode == 1)
        finally:
            AKAR = lama

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
    ap.add_argument("--periksa-serah", metavar="DRAF_RESPONS",
                    help="periksa blok prompt dalam draf chat; wajib --prompt-pendek dengan jalur paket eksplisit")
    ap.add_argument("--uji-diri", action="store_true")
    a = ap.parse_args()

    if a.uji_diri:
        return uji_diri()
    if a.periksa_serah and not a.prompt_pendek:
        ap.error("--periksa-serah memerlukan --prompt-pendek <jalur-paket-eksplisit>")
    if a.prompt_pendek is not None:
        return mode_prompt_pendek(a.prompt_pendek or None, draf_serah=a.periksa_serah)
    jenis = a.jenis or (kenali_frasa(a.frasa) if a.frasa else None)
    if not jenis:
        print("GAGAL: jenis pemeriksaan tidak dikenali.")
        print(f"  Contoh frasa: \"siapkan pemeriksaan independen menyeluruh\" · \"…di bidang keamanan\" ·")
        print(f"  \"siapkan review PR\" · \"jalankan pemeriksaan fondasi\". Jenis sah: {', '.join(JENIS)}.")
        return 1
    return mode_siapkan(jenis, a.pr, a.izinkan_ci_belum_hijau)


if __name__ == "__main__":
    sys.exit(main())
