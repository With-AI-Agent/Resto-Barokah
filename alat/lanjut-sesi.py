#!/usr/bin/env python3
"""lanjut-sesi.py — MENYIAPKAN & MEMERIKSA "lanjut di sesi baru" tanpa kehilangan konteks.

Masalah yang diselesaikan (permintaan Lee 2026-09-18: *"aku mau lanjut di sesi baru…
pastikan mekanismenya ada dan sempurna"*):

* Sesi baru di platform ini **selalu dimulai dari basis `main`**, sedangkan pekerjaan
  hidup di cabang sesi (`arena/…`). Sesi baru yang tidak diberi tahu akan melihat repo
  yang **123 commit tertinggal** dan bisa mengulang pekerjaan yang sudah selesai.
* Keadaan kerja tersimpan di banyak berkas (`PROJECT_STATE.md`, `STATUS.md`,
  `_log-sesi/`, `docs/TERTANGGUH.md`, laporan uji). Tanpa satu berkas penunjuk, agent
  baru harus menebak; tanpa pemeriksa, berkas penunjuk itu bisa **basi diam-diam**
  (inilah kelas cacat yang sama dengan temuan audit F-11/F-12/F-14).

Dua berkas yang dihasilkan/dijaga:

1. `docs/ops/SIAP-LANJUT.md` — handoff untuk **agent** baru: cabang, commit, keadaan CI,
   butir tertangguh, dan rencana berikutnya (bagian rencana DIPERTAHANKAN apa adanya saat
   disegarkan, supaya tulisan agent tidak hilang).
2. `docs/ops/SIAP-TEMPEL-SESI-BARU.md` — untuk **Lee**: satu berkas yang cukup disalin
   seluruhnya ke chat baru (berisi Prompt Pembuka Universal yang identik dengan sumber
   kanonik + arahan lanjut proyek: cara menyusul cabang kerja, apa yang dibaca, aturannya).

Cara pakai:
    python3 alat/lanjut-sesi.py                 # periksa kesiapan lanjut (lokal: penuh)
    python3 alat/lanjut-sesi.py --siapkan       # segarkan kedua berkas di atas
    python3 alat/lanjut-sesi.py --di-ci         # di CI: isi saja (riwayat Git dangkal)
    python3 alat/lanjut-sesi.py --uji-diri      # buktikan pemeriksa bisa MENOLAK

Aturan kesegaran (ditegakkan di komputer, bukan di CI): berkas handoff wajib diperbarui
di **commit terakhir** setiap batch, dan `Commit keadaan kerja` di dalamnya wajib sama
dengan induk commit itu. Jadi handoff tidak bisa ketinggalan satu batch pun.
"""
from __future__ import annotations

import datetime as _dt
import pathlib
import re
import subprocess
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent
SIAP = AKAR / "docs" / "ops" / "SIAP-LANJUT.md"
TEMPEL = AKAR / "docs" / "ops" / "SIAP-TEMPEL-SESI-BARU.md"
PROMPT_KANONIK = AKAR / "PROMPT_ENTRI_UNIVERSAL.md"
TERTANGGUH = AKAR / "docs" / "TERTANGGUH.md"
PROJECT_STATE = AKAR / "PROJECT_STATE.md"

# Cabang kerja yang memuat pekerjaan terakhir. Ditulis di berkas siap-tempel supaya sesi
# baru tahu harus menyusul ke mana — bukan ditebak dari ingatan.
CABANG_KERJA = "arena/01a0a8a2-resto-barokah"


def jalankan(perintah: list[str], cwd: pathlib.Path | None = None) -> tuple[int, str]:
    hasil = subprocess.run(perintah, cwd=cwd or AKAR, capture_output=True, text=True)
    return hasil.returncode, (hasil.stdout + hasil.stderr).strip()


def baca(p: pathlib.Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace") if p.is_file() else ""


def blok_prompt_kanonik() -> str:
    """Blok kode pertama dari sumber kanonik `PROMPT_ENTRI_UNIVERSAL.md`."""
    m = re.search(r"^```\n(.*?)^```$", baca(PROMPT_KANONIK), re.MULTILINE | re.DOTALL)
    return m.group(1).strip() if m else ""


def butir_tertangguh() -> list[str]:
    teks = baca(TERTANGGUH)
    return re.findall(r"^\|\s*(T-\d{3})\s*\|.*\|\s*\[ \]\s*terbuka\s*\|\s*$", teks, re.M)


def bidang(teks: str, nama: str) -> str | None:
    m = re.search(rf"^- \*\*{re.escape(nama)}:\*\*\s*(.+)$", teks, re.M)
    return m.group(1).strip().strip("`") if m else None


# --------------------------------------------------------------------------- periksa
def periksa(akar: pathlib.Path | None = None, sipl_teks: str | None = None,
            tempe_teks: str | None = None, penuh: bool = True) -> list[str]:
    """Kembalikan daftar masalah. Kosong = siap lanjut.

    `penuh=False` (dipakai `--di-ci`) hanya memeriksa ISI berkas; pemeriksaan kesegaran
    riwayat Git dilewati karena checkout CI dangkal/menggabung.
    """
    akar = akar or AKAR
    masalah: list[str] = []
    sipl = sipl_teks if sipl_teks is not None else baca(akar / "docs" / "ops" / "SIAP-LANJUT.md")
    tempe = tempe_teks if tempe_teks is not None else baca(akar / "docs" / "ops" / "SIAP-TEMPEL-SESI-BARU.md")
    if not sipl:
        return ["docs/ops/SIAP-LANJUT.md BELUM ADA — sesi baru tidak punya penunjuk keadaan. "
                "Jalankan: python3 alat/lanjut-sesi.py --siapkan"]
    if not tempe:
        masalah.append("docs/ops/SIAP-TEMPEL-SESI-BARU.md BELUM ADA — Lee tidak punya berkas untuk "
                       "disalin ke chat baru. Jalankan: python3 alat/lanjut-sesi.py --siapkan")

    # --- isi berkas handoff (selalu diperiksa, juga di CI) ---
    wajib = {
        "cabang": r"^- \*\*Cabang kerja terakhir:\*\*\s*`[^`]+`",
        "commit": r"^- \*\*Commit keadaan kerja:\*\*\s*`[0-9a-f]{40}`",
        "ci": r"^- \*\*CI terakhir:\*\*",
        "ditulis": r"^- \*\*Ditulis:\*\*",
        "rencana": r"^## .*Rencana berikutnya",
    }
    for nama, pola in wajib.items():
        jumlah = len(re.findall(pola, sipl, re.M))
        if jumlah == 0:
            masalah.append(f"docs/ops/SIAP-LANJUT.md: bagian '{nama}' hilang — sesi baru akan menebak")
        elif jumlah > 1:
            # Kejadian nyata 2026-09-18: `--siapkan` sempat MENDUPLIKASI blok header, sehingga
            # dua baris "Commit keadaan kerja" saling bertentangan. Berkas dengan bagian kembar
            # = sesi baru bisa membaca keadaan yang salah; pemeriksa wajib menolaknya.
            masalah.append(f"docs/ops/SIAP-LANJUT.md: bagian '{nama}' muncul {jumlah}x (harus 1) — "
                           "berkas handoff rusak/berulang, jalankan --siapkan lagi")
    cabang_ditulis = bidang(sipl, "Cabang kerja terakhir")
    if cabang_ditulis and cabang_ditulis != CABANG_KERJA:
        masalah.append(f"docs/ops/SIAP-LANJUT.md menunjuk cabang '{cabang_ditulis}', bukan '{CABANG_KERJA}' — "
                       "sesi baru bisa menyusul ke cabang yang salah")
    if re.search(r"CABANG-KERJA-BELUM-DIISI|TODO", sipl):
        masalah.append("docs/ops/SIAP-LANJUT.md masih memuat penanda TODO — belum diisi sungguhan")

    # --- berkas siap-tempel harus memuat prompt kanonik APA ADANYA ---
    kanonik = blok_prompt_kanonik()
    if not kanonik:
        masalah.append("PROMPT_ENTRI_UNIVERSAL.md tidak terbaca — blok prompt kanonik tidak bisa dipastikan")
    elif tempe and kanonik not in tempe:
        masalah.append("docs/ops/SIAP-TEMPEL-SESI-BARU.md TIDAK memuat Prompt Pembuka Universal apa adanya — "
                       "sesi baru akan mulai tanpa aturan orientasi")
    if tempe and "JANGAN MERGE" not in tempe.upper():
        masalah.append("docs/ops/SIAP-TEMPEL-SESI-BARU.md tidak memuat larangan merge — keputusan merge milik Lee")
    if tempe and "refs/remotes/origin/kerja-terakhir" not in tempe:
        masalah.append("docs/ops/SIAP-TEMPEL-SESI-BARU.md tidak memuat perintah menyusul cabang kerja — "
                       "sesi baru bisa bekerja dari main yang tertinggal")
    if tempe and kanonik and tempe.count(kanonik) != 1:
        masalah.append(f"docs/ops/SIAP-TEMPEL-SESI-BARU.md memuat blok Prompt Pembuka {tempe.count(kanonik)}x "
                       "(harus tepat 1) — berkas tempel rusak/berulang")

    # --- butir tertangguh tidak boleh melewati batas yang disetujui Lee ---
    terbuka = butir_tertangguh()
    if len(terbuka) > 12:
        masalah.append(f"butir tertangguh terbuka {len(terbuka)} (> 12) — wajib berhenti & minta keputusan Lee")

    # --- Project State & STATUS harus punya bentuk yang bisa dibaca sesi baru ---
    ps = baca(akar / "PROJECT_STATE.md")
    if not re.search(r"^STATUS:", ps, re.M):
        masalah.append("PROJECT_STATE.md tidak punya baris STATUS: — bootstrap sesi baru akan menebak")
    st = baca(akar / "STATUS.md")
    if len(re.findall(r"\*\*Pekerjaan belum tersimpan:\*\*\s*Tidak ada\s*$", st, re.M)) != 1:
        masalah.append("STATUS.md tidak memuat tepat satu field 'Pekerjaan belum tersimpan: Tidak ada'")

    if not penuh:
        return masalah

    # --- pemeriksaan kesegaran riwayat Git (butuh riwayat penuh) ---
    kode, kotor = jalankan(["git", "status", "--porcelain"], cwd=akar)
    if kode == 0 and kotor:
        masalah.append(f"ruang kerja KOTOR ({len(kotor.splitlines())} berkas belum di-commit) — "
                       "sesi baru akan kehilangan pekerjaan yang belum di-push")
    _, nama_cabang = jalankan(["git", "branch", "--show-current"], cwd=akar)
    nama_cabang = nama_cabang.strip()
    _, sha_head = jalankan(["git", "rev-parse", "HEAD"], cwd=akar)
    sha_head = sha_head.strip()
    # Induk commit dicoba APA ADANYA (klon dangkal bisa membuatnya tidak ada → baru dicatat).
    kode_induk, induk = jalankan(["git", "rev-parse", "HEAD^"], cwd=akar)
    induk = induk.strip() if kode_induk == 0 else ""

    if nama_cabang:
        kode, sisi_luar = jalankan(["git", "rev-parse", f"origin/{nama_cabang}"], cwd=akar)
        if kode == 0 and sisi_luar.strip() != sha_head:
            masalah.append(f"commit lokal ({sha_head[:8]}) belum ter-push ke origin/{nama_cabang} "
                           f"({sisi_luar.strip()[:8]}) — tanpa push, sesi berikutnya tidak bisa melanjutkan")
    else:
        # Detached (mis. pemeriksaan PR): kecocokan cabang tidak bisa diuji, beri catatan.
        print("  [catatan] HEAD detached (salinan pemeriksaan) — uji push dilewati")

    if induk:
        _, tukar = jalankan(["git", "diff-tree", "--no-commit-id", "--name-only", "-r", sha_head, induk], cwd=akar)
        disentuh = set(tukar.split()) if tukar else set()
        for berkas in ("docs/ops/SIAP-LANJUT.md", "PROJECT_STATE.md", "STATUS.md"):
            if berkas not in disentuh:
                masalah.append(f"commit terakhir TIDAK memperbarui {berkas} — handoff basi satu batch "
                               "(jalankan: python3 alat/lanjut-sesi.py --siapkan, lalu commit)")
        ditulis = bidang(sipl, "Commit keadaan kerja")
        if ditulis and ditulis != induk:
            masalah.append(f"handoff menulis commit keadaan {ditulis[:8]}, padahal induk commit terakhir "
                           f"{induk[:8]} — berkas handoff tidak segar")
    else:
        print("  [catatan] riwayat Git dangkal (klon CI) — kesegaran handoff tidak bisa diuji di sini")
    return masalah


# --------------------------------------------------------------------------- siapkan
def _bagian_rencana(sipl_lama: str) -> str:
    """Ambil bagian 'Rencana berikutnya' dari berkas lama (tulisan agent, jangan dihapus).

    Kejadian nyata 2026-09-18: versi pertama fungsi ini mengembalikan heading + seluruh sisa
    berkas, sehingga `--siapkan` yang dijalankan dua kali MENDUPLIKASI blok header (dua baris
    "Commit keadaan kerja" yang saling bertentangan). Sekarang: hanya ambil BADAN rencananya,
    dan buang sisa blok header yang mungkin ikut terbawa.
    """
    m = re.search(r"^## 3\. Rencana berikutnya[^\n]*\n(.*)\Z", sipl_lama, re.M | re.DOTALL)
    if not m:
        return ("## 3. Rencana berikutnya (isi bagian ini sebelum menutup sesi)\n\n"
                "- (belum diisi: tulis tujuan sesi berikutnya, pilihan Lee, dan aturan tetap)")
    badan = m.group(1)
    # Defensif: potong apa pun yang merupakan blok header hasil generator sebelumnya.
    potong = re.search(r"^## 1\. Keadaan sekarang", badan, re.M)
    if potong:
        badan = badan[: potong.start()]
    badan = badan.strip() or "- (belum diisi)"
    if not badan.lstrip().startswith("##"):
        return "## 3. Rencana berikutnya (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)\n\n" + badan
    return badan


def siapkan() -> int:
    kode, sha = jalankan(["git", "rev-parse", "HEAD"])
    if kode != 0:
        print("GAGAL: bukan repositori Git — tidak bisa menulis handoff yang bisa dipercaya.")
        return 1
    sha = sha.strip()
    _, nama_cabang = jalankan(["git", "branch", "--show-current"])
    nama_cabang = nama_cabang.strip() or CABANG_KERJA
    _, pr = jalankan(["gh", "pr", "list", "--state", "open", "--limit", "5",
                      "--json", "number,baseRefName,headRefName",
                      "--jq", '.[] | "PR #\\(.number) (base \\(.baseRefName))"'])
    pr = pr.strip() or "(tidak ada PR terbuka terbaca)"
    _, ci = jalankan(["gh", "run", "list", "--limit", "1", "--json", "conclusion,headSha,databaseId",
                      "--jq", '.[] | "\\(.conclusion) (run \\(.databaseId), commit \\(.headSha[0:8]))"'])
    ci = ci.strip() or "(status CI tidak terbaca dari sini — periksa di GitHub)"
    terbuka = butir_tertangguh()
    hari_ini = _dt.date.today().isoformat()
    sipl_lama = baca(SIAP)
    rencana = _bagian_rencana(sipl_lama)

    isi = f"""# SIAP LANJUT — penunjuk keadaan untuk sesi berikutnya

> Berkas ini DIBUAT MESIN oleh `python3 alat/lanjut-sesi.py --siapkan` dan diperiksa
> `python3 alat/lanjut-sesi.py`. Jangan disunting tangan pada bagian 1–2; bagian 3
> (rencana) justru WAJIB ditulis agent dan akan dipertahankan saat disegarkan.
> Aturan kesegaran: berkas ini wajib ikut ter-commit di commit TERAKHIR setiap batch.

## 1. Keadaan sekarang (dibaca sesi baru lebih dulu)

- **Cabang kerja terakhir:** `{nama_cabang}`
- **Commit keadaan kerja:** `{sha}`
- **PR:** {pr} — **JANGAN MERGE tanpa keputusan Lee**
- **CI terakhir:** {ci}
- **Ditulis:** {hari_ini} (sebelum commit yang memuat berkas ini; jadi commit keadaan di atas
  adalah induk commit ini)
- **Ruang kerja:** bersih & ter-push (dijaga pemeriksa; kalau tidak, berkas ini tidak akan lolos)

## 2. Keadaan proyek & butir tertangguh

- Posisi proyek: lihat `PROJECT_STATE.md` (STATUS + PUTARAN terakhir) dan `STATUS.md`.
- Bukti terakhir yang hijau: `node alat/uji-sql.mjs` · `python3 alat/uji-mutasi-0012.py` ·
  `python3 alat/uji-mutasi-0014.py` · `bash aplikasi/alat/periksa-semua.sh` · CI (lihat baris CI di atas).
- Butir tertangguh terbuka: **{len(terbuka)}** — {", ".join(terbuka) if terbuka else "(tidak ada)"}
  (rincian: `docs/TERTANGGUH.md`; hanya Lee yang boleh menutupnya)

## 2b. Kalau kamu sesi baru: cara menyusul pekerjaan ini

Sesi baru di platform ini mulai dari `main`, sedangkan pekerjaan ada di cabang sesi.
Jalankan (tanpa memindahkan cabang sesimu):

```
git fetch origin {nama_cabang}:refs/remotes/origin/kerja-terakhir
git merge --ff-only origin/kerja-terakhir
python3 alat/mulai-sesi.py      # cetak KARTU SESI, lalu LAPORKAN ke Lee
```

Kalau checkout-mu tidak memuat `supabase/migrations/0014_penutup_celah_putaran13.sql`,
kamu berada di basis yang salah — jangan bekerja dulu, susul cabang di atas.

{rencana}
"""
    # Self-check: berkas handoff TIDAK BOLEH berisi bagian kembar (pernah terjadi, lihat _bagian_rencana).
    for penanda in ("## 1. Keadaan sekarang", "- **Commit keadaan kerja:**", "## 2b. Kalau kamu sesi baru"):
        if isi.count(penanda) != 1:
            print(f"GAGAL: hasil handoff memuat '{penanda}' {isi.count(penanda)}x (harus 1) — "
                  "berkas TIDAK ditulis supaya tidak menyesatkan sesi baru.")
            return 1
    SIAP.parent.mkdir(parents=True, exist_ok=True)
    SIAP.write_text(isi, encoding="utf-8")

    kanonik = blok_prompt_kanonik()
    tempe = f"""> BERKAS SIAP-TEMPEL — salin SELURUH isi berkas ini ke chat BARU (percakapan baru).
> Dibuat mesin oleh `alat/lanjut-sesi.py`; Prompt Pembuka di bawah diambil apa adanya dari
> sumber kanonik (`PROMPT_ENTRI_UNIVERSAL.md`), jadi tidak bisa menyimpang.

===== MULAI SALIN DARI SINI =====

{kanonik}

===== SAMBUNGAN: ARAHAN LANJUT PROYEK (dibuat mesin {hari_ini}) =====

Proyek: **Resto Barokah** — repo `With-AI-Agent/Resto-Barokah`, cabang kerja terakhir
`{nama_cabang}` @ `{sha}`. PR #1 **terbuka** — **JANGAN MERGE**: merge hanya keputusan Lee.

Langkah pertama sesi ini (WAJIB, supaya tidak bekerja dari `main` yang tertinggal ≈123 commit):

```
git fetch origin {nama_cabang}:refs/remotes/origin/kerja-terakhir
git merge --ff-only origin/kerja-terakhir
python3 alat/mulai-sesi.py
```

Lalu baca `docs/ops/SIAP-LANJUT.md` (penunjuk keadaan: cabang, commit, CI, butir tertangguh,
rencana berikutnya) dan `PROJECT_STATE.md`. Laporkan KARTU SESI ke Lee SEBELUM bekerja.

Ringkas keadaan terakhir: putaran13 (review PR #1 + audit AUD-3 2026-09-18) — 27 temuan
diverifikasi nyata dan ditutup migrasi `0014`; suite SQL 41/41, mutasi 16/16 & 17/17 MERAH,
CI hijau. Sisa pekerjaan terdekat dan pilihannya ada di bagian "Rencana berikutnya" pada
`docs/ops/SIAP-LANJUT.md`.

===== SELESAI SALIN =====
"""
    TEMPEL.write_text(tempe, encoding="utf-8")

    print(f"SIAP-LANJUT.md ditulis     : docs/ops/SIAP-LANJUT.md  (commit keadaan {sha[:8]})")
    print(f"SIAP-TEMPEL ditulis        : docs/ops/SIAP-TEMPEL-SESI-BARU.md")
    print(f"Butir tertangguh terbuka   : {len(terbuka)}" + (f" ({', '.join(terbuka)})" if terbuka else ""))
    print("\nLangkah berikutnya (WAJIB, supaya handoff tidak basi):")
    print("  1) tulis bagian '## 3. Rencana berikutnya' di docs/ops/SIAP-LANJUT.md")
    print("  2) perbarui PROJECT_STATE.md + STATUS.md (aturan akhir batch)")
    print("  3) git add -A && git commit && git push")
    print("  4) python3 alat/lanjut-sesi.py   → harus LOLOS")
    return 0


# --------------------------------------------------------------------------- uji-diri
def _repo_uji(tmp: pathlib.Path, sha_ditulis: str | None, segar: bool) -> pathlib.Path:
    """Buat repo Git kecil berisi berkas handoff dengan SHA yang bisa benar/salah.

    Dipakai uji-diri untuk MEMBUKTIKAN pemeriksaan kesegaran riwayat benar-benar bisa MERAH —
    hal yang tidak bisa diuji di salinan pohon biasa (salinan tidak punya riwayat).
    """
    import shutil
    import subprocess as sp

    repo = tmp / "repo"
    (repo / "docs" / "ops").mkdir(parents=True)
    (repo / "docs" / "TERTANGGUH.md").write_text("| ID | Tanggal | Hal |\n|---|---|---|\n", encoding="utf-8")
    (repo / "PROJECT_STATE.md").write_text("STATUS: UJI\nDETAIL: uji\n", encoding="utf-8")
    (repo / "STATUS.md").write_text("- **Pekerjaan belum tersimpan:** Tidak ada\n", encoding="utf-8")
    shutil.copy2(PROMPT_KANONIK, repo / "PROMPT_ENTRI_UNIVERSAL.md")
    shutil.copy2(TEMPEL, repo / "docs" / "ops" / "SIAP-TEMPEL-SESI-BARU.md")
    isi = baca(SIAP).replace(bidang(baca(SIAP), "Commit keadaan kerja") or "", "0" * 40)
    (repo / "docs" / "ops" / "SIAP-LANJUT.md").write_text(isi, encoding="utf-8")
    env = {"GIT_AUTHOR_NAME": "uji", "GIT_AUTHOR_EMAIL": "u@uji", "GIT_COMMITTER_NAME": "uji",
           "GIT_COMMITTER_EMAIL": "u@uji", "PATH": "/usr/bin:/bin"}
    for perintah in (["git", "init", "-q"], ["git", "add", "-A"], ["git", "commit", "-qm", "awal"]):
        sp.run(perintah, cwd=repo, env=env, capture_output=True, check=False)
    _, induk = jalankan(["git", "rev-parse", "HEAD"], cwd=repo)
    sha = sha_ditulis if sha_ditulis is not None else induk.strip()
    isi = isi.replace("0" * 40, sha)
    (repo / "docs" / "ops" / "SIAP-LANJUT.md").write_text(isi, encoding="utf-8")
    # Meniru aturan akhir batch yang sebenarnya: commit terakhir menyentuh ketiga berkas
    # (handoff + PROJECT_STATE + STATUS). Kalau tidak, yang diuji bukan aturannya.
    (repo / "PROJECT_STATE.md").write_text("STATUS: UJI\nDETAIL: uji\nUPDATE TERAKHIR: uji\n", encoding="utf-8")
    (repo / "STATUS.md").write_text("- **Pekerjaan belum tersimpan:** Tidak ada\n- **Waktu pembaruan:** uji\n", encoding="utf-8")
    for perintah in (["git", "add", "-A"], ["git", "commit", "-qm", "segar" if segar else "basi"]):
        sp.run(perintah, cwd=repo, env=env, capture_output=True, check=False)
    return repo

def uji_diri() -> int:
    """Buktikan pemeriksa bisa MENOLAK: setiap bagian handoff dimutasi di salinan teks.

    Kenapa di salinan teks, bukan salinan pohon: pemeriksa ini membaca riwayat Git repo
    nyata (kesegaran handoff), dan salinan sementara tidak memilikinya. Yang diuji di sini
    adalah bagian ISI — yang justru paling mudah basi.
    """
    hasil: list[tuple[str, bool, str]] = []
    sipl = baca(SIAP)
    tempe = baca(TEMPEL)
    if not sipl or not tempe:
        print("LEWAT: berkas handoff belum ada — jalankan --siapkan dulu, lalu uji-diri.")
        return 0

    masalah = periksa(penuh=False)
    hasil.append(("berkas handoff sekarang diterima", not masalah,
                  "lolos" if not masalah else masalah[0][:90]))

    def mutasi(nama: str, baru: str) -> None:
        masalah_m = periksa(sipl_teks=baru, tempe_teks=tempe, penuh=False)
        hasil.append((nama, bool(masalah_m),
                      masalah_m[0][:90] if masalah_m else "DILOLOSKAN (tumpul)"))

    # Kasus kembar (kejadian nyata): bagian yang sama muncul dua kali → WAJIB ditolak.
    hasil.append(("mutasi: bagian 'Commit keadaan kerja' diduplikasi",
                  bool(periksa(sipl_teks=sipl + "\n" + re.search(r"^- \*\*Commit keadaan kerja:\*\*.*$", sipl, re.M).group(0) + "\n",
                               tempe_teks=tempe, penuh=False)),
                  "dua baris commit yang bertentangan harus ditolak"))

    mutasi("mutasi: commit keadaan dihandoff dikosongkan", re.sub(r"^- \*\*Commit keadaan kerja:\*\*.*$",
                                                                  "- **Commit keadaan kerja:** (tidak ada)", sipl, count=1, flags=re.M))
    mutasi("mutasi: cabang dihandoff diubah ke cabang lain",
           sipl.replace(CABANG_KERJA, "arena/cabang-yang-salah", 1))
    mutasi("mutasi: bagian CI dihapus", re.sub(r"^- \*\*CI terakhir:\*\*.*$", "", sipl, count=1, flags=re.M))
    mutasi("mutasi: bagian rencana berikutnya dihapus",
           re.sub(r"^## .*Rencana berikutnya.*$", "## Catatan lain", sipl, count=1, flags=re.M))

    # Ganti SEMUA bentuk (huruf besar/kecil): pemeriksa memakai .upper(), jadi mutasi
    # yang hanya mengganti bentuk huruf besar akan lolos palsu — pernah terjadi.
    tempe_tanpa_larangan = re.sub(r"jangan merge", "silakan merge", tempe, flags=re.I)
    masalah_t = periksa(sipl_teks=sipl, tempe_teks=tempe_tanpa_larangan, penuh=False)
    hasil.append(("mutasi: larangan merge dihapus dari berkas siap-tempel", bool(masalah_t),
                  masalah_t[0][:90] if masalah_t else "DILOLOSKAN (tumpul)"))
    masalah_s = periksa(sipl_teks=sipl, tempe_teks=tempe.replace("refs/remotes/origin/kerja-terakhir", "refs/heads/x"), penuh=False)
    hasil.append(("mutasi: cara menyusul cabang dihapus", bool(masalah_s),
                  masalah_s[0][:90] if masalah_s else "DILOLOSKAN (tumpul)"))
    kanonik = blok_prompt_kanonik()
    masalah_p = periksa(sipl_teks=sipl, tempe_teks=tempe.replace(kanonik, "Lanjutkan saja."), penuh=False)
    hasil.append(("mutasi: Prompt Pembuka Universal tidak lagi apa adanya", bool(masalah_p),
                  masalah_p[0][:90] if masalah_p else "DILOLOSKAN (tumpul)"))

    # --- bukti pemeriksaan kesegaran (butuh riwayat Git nyata) ---
    import tempfile

    with tempfile.TemporaryDirectory(prefix="lanjut-sesi-") as tmp:
        repo_benar = _repo_uji(pathlib.Path(tmp) / "benar", None, True)
        masalah_benar = periksa(akar=repo_benar, penuh=True)
        hasil.append(("repo uji dengan handoff SEGAR diterima", not masalah_benar,
                      "lolos" if not masalah_benar else masalah_benar[0][:90]))
        repo_salah = _repo_uji(pathlib.Path(tmp) / "salah", "1" * 40, False)
        masalah_salah = periksa(akar=repo_salah, penuh=True)
        hasil.append(("repo uji dengan handoff BASI ditolak", bool(masalah_salah),
                      masalah_salah[0][:90] if masalah_salah else "DILOLOSKAN (tumpul)"))

    print("UJI-DIRI lanjut-sesi")
    gagal = 0
    for kasus, sesuai, ringkas in hasil:
        tanda = "OK " if sesuai else "X  "
        if not sesuai:
            gagal += 1
        print(f"  {tanda} {kasus} → {ringkas}")
    if gagal:
        print(f"\nHASIL: GAGAL — {gagal} kasus uji-diri tidak sesuai harapan (pemeriksa mungkin tumpul)")
        return 1
    print("\nHASIL: LOLOS — pemeriksa handoff terbukti bisa MENOLAK handoff cacat.")
    return 0


def main() -> int:
    if "--siapkan" in sys.argv:
        return siapkan()
    if "--uji-diri" in sys.argv:
        return uji_diri()
    penuh = "--di-ci" not in sys.argv
    masalah = periksa(penuh=penuh)
    print("PERIKSA SIAP-LANJUT — handoff sesi baru (cabang, commit, berkas tempel, rencana)")
    for m in masalah:
        print(f"  [X] {m}")
    if not masalah:
        print("  OK  handoff lengkap & segar: sesi baru bisa melanjutkan tanpa kehilangan konteks")
    print("-" * 70)
    if masalah:
        print(f"HASIL: GAGAL — {len(masalah)} masalah pada handoff lanjut-sesi")
        return 1
    print("HASIL: LOLOS" + ("" if penuh else " (mode CI: pemeriksaan kesegaran riwayat dilewati)"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
