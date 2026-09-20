#!/usr/bin/env python3
"""review-pr.py — mekanisme REVIEW PR INDEPENDEN untuk proyek Resto Barokah.

Permintaan Lee 2026-09-17: ia tidak bisa menilai *Files changed* di GitHub, jadi butuh
mekanisme review PR yang bisa dipercaya tanpa ia membaca kode. Riset industri 2026
(diringkas di docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md §7): reviewer AI = pemberi
laporan + klasifikasi risiko, BUKAN pemberi approve; keputusan merge tetap manusia;
kedalaman review mengikuti risiko; gerbang harus berbasis bukti pada commit yang akan masuk.

Perintah:
  --siapkan [--pr N | --dasar <ref> --kepala <ref>]   bangun paket review (+ berkas SIAP-TEMPEL)
  --periksa-laporan <berkas>                          validasi laporan peninjau (anti-teater)
  --kartu-keputusan <berkas>                          cetak kartu keputusan 7 baris untuk Lee
  --kesiapan                                          apakah commit sekarang sudah punya paket review?
  --kalibrasi-pr-siapkan                              buat bahan kalibrasi (diff berisi cacat sengaja)
  --uji-diri                                          buktikan pemeriksa bisa MENOLAK laporan buruk
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import pathlib
import random
import re
import subprocess
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent
# KATALOG CACAT (temuan audit H F-01, 2026-09-20): katalog memuat pasangan cari/ganti = KUNCI
# JAWABAN kalibrasi. Selama ia ada DI DALAM repo, peninjau yang sedang dikalibrasi — yang memang
# membaca repo — bisa mencocokkan diff yang disematkan ke paket dengan isi katalog, lalu menulis
# "Ditemukan: X dari X" tanpa benar-benar mengulas. Jalur review PR karena itu HANYA membaca
# katalog dari LUAR repo (`KALIBRASI_DIR`, baku `/home/user/.kalibrasi`); bila tidak ada, alat
# MENOLAK berjalan (gagal-tertutup) daripada membuat bahan yang bisa dicocokkan.
KAL_DIR = pathlib.Path(os.environ.get("KALIBRASI_DIR", str(pathlib.Path.home() / ".kalibrasi")))
KATALOG = KAL_DIR / "kalibrasi-cacat.json"
KATALOG_REPO = AKAR / "alat" / "kalibrasi-cacat.json"
FOLDER = AKAR / "docs" / "uji" / "review-pr"
FOLDER_KAL = AKAR / "docs" / "uji" / "kalibrasi"
# F-05 (audit 2026-09-19, K-2): bahan kalibrasi review PR TIDAK PERNAH ditulis di dalam repo.
# Diff terhadap migrasi NYATA = kunci jawaban: siapa pun yang bisa membaca repo (termasuk peninjau
# yang sedang dikalibrasi) tahu persis baris mana yang ditanami cacat, sehingga skor "Ditemukan X
# dari Y" bisa dipalsukan. Bahan + kunci hidup di luar repo (`KAL_DIR_LUAR`); yang masuk ke paket
# adalah ISI bahannya (disematkan), bukan jalurnya. Riwayat Git tetap menyimpan bahan lama — karena
# itu PROTOKOL_AUDIT_INDEPENDEN §7 mewajibkan rotasi bahan yang pernah bocor.
KAL_DIR_LUAR = pathlib.Path(os.environ.get("KALIBRASI_PR_DIR", "/tmp/kalibrasi-pr"))
PROMPT_KANONIK = AKAR / "docs" / "uji" / "PROMPT_REVIEW_PR_INDEPENDEN.md"

# ---------- jalur risiko (PROTOKOL §3) ----------
POLA_MERAH = (
    r"^supabase/migrations/", r"^supabase/functions/", r"^supabase/tes/",
    r"^docs/KEAMANAN\.md$", r"^docs/uji/PROTOKOL", r"^docs/uji/PROMPT_AUDIT",
    r"^\.github/", r"^aplikasi/alat/periksa", r"^alat/audit-independen\.py$",
    r"^alat/review-pr\.py$", r"^alat/periksa-", r"^_sistem/validate_system\.py$",
)
POLA_KUNING = (
    r"^aplikasi/src/", r"^aplikasi/", r"^alat/", r"^docs/PRD\.md$", r"^docs/TECH_SPEC\.md$",
    r"^docs/ROADMAP\.md$", r"^docs/SPESIFIKASI_UI\.md$", r"^docs/DECISIONS_LOG\.md$",
    r"^_sistem/", r"^docs/PANDUAN_PEMILIK\.md$",
)
JALUR_URUT = ("Merah", "Kuning", "Hijau")

MIN_ARTEFAK = 5
MIN_KLAIM = 5
MIN_GERBANG = 5


def jalankan(perintah: list[str], cwd: pathlib.Path | None = None) -> tuple[int, str]:
    p = subprocess.run(perintah, cwd=str(cwd or AKAR), capture_output=True, text=True)
    return p.returncode, (p.stdout + p.stderr).strip()


def jalur_risiko(berkas: str) -> str:
    for pola in POLA_MERAH:
        if re.search(pola, berkas):
            return "Merah"
    for pola in POLA_KUNING:
        if re.search(pola, berkas):
            return "Kuning"
    return "Hijau"


def sha_ringkas(ref: str) -> str:
    _, keluaran = jalankan(["git", "rev-parse", ref])
    return keluaran.strip()


def perubahan(dasar: str, kepala: str) -> list[tuple[str, str]]:
    _, keluaran = jalankan(["git", "diff", "--name-status", f"{dasar}...{kepala}"])
    hasil: list[tuple[str, str]] = []
    for baris in keluaran.splitlines():
        bagian = baris.split("\t")
        if len(bagian) >= 2:
            hasil.append((bagian[0].strip(), bagian[-1].strip()))
    return hasil


def statistik(dasar: str, kepala: str) -> tuple[int, int]:
    _, keluaran = jalankan(["git", "diff", "--shortstat", f"{dasar}...{kepala}"])
    tambah = int(re.search(r"(\d+) insertion", keluaran).group(1)) if "insertion" in keluaran else 0
    kurang = int(re.search(r"(\d+) deletion", keluaran).group(1)) if "deletion" in keluaran else 0
    return tambah, kurang


def _baris_bukti(teks: str) -> list[str]:
    """Baris yang bisa disebut BUKTI: isi blok kode, atau baris berisi perintah ber-backtick
    disertai jejak hasil (panah/status kata). Dipakai menilai kedalaman Jalur Merah tanpa
    memaksa satu gaya penulisan tertentu (fence, indentasi, atau tabel semuanya dihitung)."""
    hasil: list[str] = []
    dalam_blok = False
    for ln in teks.splitlines():
        telanjang = ln.strip()
        if telanjang.startswith("```") or telanjang.startswith("~~~"):
            dalam_blok = not dalam_blok
            continue
        if dalam_blok or ln.startswith("    "):
            hasil.append(ln)
            continue
        if "`" in ln and re.search(r"(→|->|\bhasil\b|rc=|LULUS|GAGAL|MERAH|HIJAU|exit=|tidak ada|nol\b)", ln):
            hasil.append(ln)
    return hasil


def pesan_commit(dasar: str, kepala: str) -> list[str]:
    _, keluaran = jalankan(["git", "log", "--no-merges", "--format=%s%n%b%n---", f"{dasar}..{kepala}"])
    blok = [b.strip() for b in keluaran.split("---") if b.strip()]
    return blok


def tugas_roadmap_berubah(dasar: str, kepala: str) -> list[str]:
    rc, keluaran = jalankan(["git", "diff", f"{dasar}...{kepala}", "--", "docs/ROADMAP.md"])
    if rc != 0 or not keluaran:
        return []
    id_tugas = sorted(set(re.findall(r"^[+-]\s*(- \[[ x]\]\s+T\d+-\d+)", keluaran, re.M)))
    return id_tugas


def klaim_dari_commit(dasar: str, kepala: str) -> list[str]:
    """Klaim diambil HANYA dari butir daftar pada pesan commit (judul + baris "- ...").

    Dua cacat yang ditemukan review RV-2 putaran8 (PR-01b/PR-05/PR-17):
      * bug operator (`not b or b.startswith("- ") and len(b) > 12`) membuat baris acak —
        termasuk baris kosong dan kalimat sambungan — ikut jadi "klaim" (7 butir kosong);
      * butir yang terlalu pendek ("- uji", "- fix") tidak layak disebut klaim.
    Sekarang: baris kosong dibuang, butir harus berawalan "- " atau "* " dan panjang ≥ 16.
    """
    klaim: list[str] = []
    for blok in pesan_commit(dasar, kepala):
        for baris in blok.splitlines():
            b = baris.strip()
            butir = b.startswith("- ") or b.startswith("* ")
            if not butir or len(b) < 16:
                continue
            klaim.append(b[2:].strip())
    # klaim khas yang wajib dibantah pada perubahan berisiko
    bawaan = [
        "Uji otomatis membuktikan perilaku baru/bebas regresi pada commit ini (bukan commit sebelumnya).",
        "Tidak ada gerbang keamanan/CI yang dilemahkan (ambang diturunkan, uji dimatikan, revoke/hak dicabut dihapus).",
        "Perubahan pada jalur uang/keamanan/data pelanggan tidak bisa dilewati lewat pemanggilan langsung (RPC/API).",
        "Dokumen yang menyatakan perilaku (fondasi, buku induk, panduan Lee) sudah ikut diperbarui — tidak ada klaim basi.",
        "Setiap berkas baru benar-benar dipakai (tidak ada berkas mati / rujukan menggantung).",
    ]
    gabung = klaim[:8] + bawaan
    # buang duplikat, batasi
    lihat: list[str] = []
    for k in gabung:
        if k not in lihat:
            lihat.append(k)
    return lihat[:12]


def prompt_kanonik() -> str:
    if not PROMPT_KANONIK.is_file():
        return ""
    bagian = PROMPT_KANONIK.read_text(encoding="utf-8").split("## B.")[-1]
    m = re.search(r"```\n(.*?)\n```", bagian, re.DOTALL)
    return m.group(1).strip() if m else ""


def bahan_kalibrasi_terbaru() -> pathlib.Path | None:
    """Bahan kalibrasi TERBARU — selalu dari LUAR repo (F-05)."""
    if not KAL_DIR_LUAR.is_dir():
        return None
    kandidat = sorted(KAL_DIR_LUAR.glob("pr-bahan-*.diff"))
    return kandidat[-1] if kandidat else None


def bahan_bocor_di_repo() -> list[pathlib.Path]:
    """Berkas bahan/kunci yang (salah) berada di dalam repo — temuan audit D F-05.

    Diperiksa di pohon kerja, bukan hanya `git ls-files`: berkas liar yang belum ter-commit
    sama bocornya (dan tinggal satu `git add -A` untuk ikut terkirim).
    """
    if not FOLDER_KAL.is_dir():
        return []
    bocor = list(FOLDER_KAL.glob("pr-bahan-*.diff"))
    bocor += [p for p in FOLDER_KAL.rglob("*") if p.is_file() and "KUNCI" in p.name]
    return sorted(bocor)


# ---------------------------------------------------------------- --siapkan
def siapkan(dasar: str, kepala: str, nama: str | None) -> int:
    sha = sha_ringkas(kepala)
    if not sha:
        print(f"GAGAL: tidak bisa membaca commit '{kepala}'"); return 1
    ubah = perubahan(dasar, kepala)
    if not ubah:
        print(f"TIDAK ADA PERUBAHAN antara {dasar} dan {kepala} — tidak ada yang perlu direview."); return 1
    tambah, kurang = statistik(dasar, kepala)
    per_jalur: dict[str, list[str]] = {j: [] for j in JALUR_URUT}
    for kode, berkas in ubah:
        per_jalur[jalur_risiko(berkas)].append(f"{kode} `{berkas}`")
    jalur_dominan = next((j for j in JALUR_URUT if per_jalur[j]), "Hijau")

    # ringkasan per tujuan (dari judul commit)
    semua_commit = [b.splitlines()[0].strip() for b in pesan_commit(dasar, kepala)]
    # PR-18: dulu paket hanya memuat 12 judul untuk PR berisi puluhan commit → peninjau mengira
    # PR-nya kecil. Sekarang SELURUH judul ditulis (dengan jumlahnya), bukan contoh terpotong.
    tujuan = semua_commit
    tugas = tugas_roadmap_berubah(dasar, kepala)
    klaim = klaim_dari_commit(dasar, kepala)
    bocor = bahan_bocor_di_repo()
    if bocor:
        print("GAGAL: bahan/kunci kalibrasi ada DI DALAM repo (kunci jawaban bocor — audit D F-05):")
        for b in bocor:
            print(f"  - {b.relative_to(AKAR)}")
        print("  Keluarkan dari repo: git rm <berkas itu> — bahan baru disiapkan di luar repo (KAL_DIR_LUAR).")
        return 1
    kal = bahan_kalibrasi_terbaru()
    # Penjaga integritas bahan kalibrasi (temuan review RV-2 putaran8 PR-04/PR-06): bahan yang
    # tidak bisa dipasang di commit yang direview = paket bohong — peninjau tidak akan pernah
    # bisa menjalankan RV-3. Karena itu paket MENOLAK dibuat, bukan sekadar memberi catatan.
    if kal is not None:
        kerja_cek = pathlib.Path("/tmp/cek-bahan-kalibrasi")
        jalankan(["git", "worktree", "remove", "--force", str(kerja_cek)])
        if jalankan(["git", "worktree", "add", "--detach", str(kerja_cek), kepala])[0] != 0:
            print("GAGAL: tidak bisa menyiapkan salinan untuk memeriksa bahan kalibrasi"); return 1
        cek = jalankan(["git", "apply", "--check", str(kal.resolve())], cwd=kerja_cek)
        jalankan(["git", "worktree", "remove", "--force", str(kerja_cek)])
        if cek[0] != 0:
            print(f"GAGAL: bahan kalibrasi {kal.name} tidak bisa dipasang di commit {sha[:8]} —")
            print(f"       paket TIDAK dibuat. Perbaiki dengan: python3 alat/review-pr.py --kalibrasi-pr-siapkan")
            print(f"       ({cek[1].splitlines()[0] if cek[1] else 'git apply menolak'})")
            return 1

    lensa = {
        "Merah": "L1 (ancaman & akses) + L2 (uang & jejak) + L4 (mutu uji) — WAJIB ketiganya",
        "Kuning": "L3 (kesepakatan dokumen) + L4 (mutu uji)",
        "Hijau": "L3 (kesepakatan dokumen) saja",
    }[jalur_dominan]

    tabel_risiko = "\n".join(
        f"| {j} | {len(per_jalur[j])} | {', '.join(per_jalur[j][:4])}{' …' if len(per_jalur[j]) > 4 else ''} |"
        for j in JALUR_URUT
    )
    klaim_md = "\n".join(f"{i+1}. {k}" for i, k in enumerate(klaim))
    if tujuan:
        tujuan_md = (f"**{len(tujuan)} commit** dalam rentang ini (seluruhnya, bukan contoh):\n"
                     + "\n".join(f"- {t}" for t in tujuan))
    else:
        tujuan_md = "- (judul commit tidak terbaca)"
    tugas_md = ", ".join(tugas) if tugas else "—"

    gerbang_merah = ""
    if jalur_dominan == "Merah":
        gerbang_merah = """
**Tambahan wajib Jalur Merah:**
- Jalankan minimal satu **uji mutasi** pada gerbang yang menyentuh perubahan ini (sengaja rusak → gerbang MERAH → pulihkan → LOLOS) dan tempel hasilnya.
- Untuk perubahan izin/RLS: jalankan `node alat/uji-sql.mjs` dan tunjukkan uji izin/RLS yang relevan **GAGAL saat dilonggarkan**.
- Tulis **rencana pemulihan** (bila perubahan ini salah, apa yang dilakukan agar aman) dan **sisa risiko** dalam bahasa sederhana.
"""

    kalibrasi_md = "- (tidak disiapkan untuk paket ini)"
    if kal:
        # F-05: yang disematkan adalah ISI bahan; berkas bahannya sendiri hidup di luar repo.
        isi_bahan = kal.read_text(encoding="utf-8").rstrip("\n")
        kalibrasi_md = (
            "- Bahan kalibrasi: **disematkan di bawah** — berkas bahannya sendiri (pola `pr-bahan-*.diff`) "
            "hidup DI LUAR repo sejak 2026-09-19 (audit D F-05: diff terhadap migrasi nyata = kunci jawaban "
            "bila ikut masuk repo).\n"
            "- Cara pakai: simpan blok `diff` di bawah sebagai `/tmp/pr-bahan.diff`, salin repo ke folder "
            "sementara (`cp -r` ke /tmp), lalu `git apply /tmp/pr-bahan.diff` di salinan itu — jangan "
            "mengubah repo ini.\n"
            "- Tulis hasilnya di bagian kalibrasi laporan (`Ditemukan: X dari Y` + jumlah temuan palsu). "
            "Kamu tidak diberi tahu jumlah/kelas cacatnya, dan **dilarang mencari kunci jawaban**.\n\n"
            "```diff\n" + isi_bahan + "\n```")

    isi = f"""# PAKET REVIEW PR INDEPENDEN — {nama or sha[:8]} — {dt.date.today().isoformat()}

> Dibuat mesin oleh `alat/review-pr.py`. Berkas ini **untuk peninjau** (sesi baru, model berbeda, hanya-baca).
> Aturan penuh: `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md`.

> **CARA PAKAI — untuk Lee (3 langkah):**
> 1. Buka **chat/percakapan BARU** (kalau bisa pilih **model yang berbeda** dari sesi kerja).
> 2. Salin **SELURUH isi berkas `-SIAP-TEMPEL.md`** (berkas kembar paket ini) ke chat baru itu.
> 3. Setelah peninjau selesai, kembali ke sesi kerja dan bilang: **"Laporan review sudah masuk, periksa."**

- **PR / cabang:** `{nama or '(tanpa nama)'}`
- **Dasar (base):** `{dasar}` → **Kepala (head):** `{kepala}`
- **Commit yang direview:** `{sha}`
- **Perubahan:** {len(ubah)} berkas · +{tambah} / −{kurang} baris
- **Jalur risiko (mesin):** **{jalur_dominan}** — kedalaman review yang diwajibkan: **{lensa}**
- **Tugas ROADMAP yang berubah:** {tugas_md}

## ATURAN INDEPENDENSI (tidak bisa ditawar)
1. Kamu **hanya-baca**: SATU-SATUNYA berkas yang boleh kamu buat adalah laporan (§6 format laporan). Selain berkas itu,
   jangan mengubah/memperbaiki apa pun (temuan ditulis, bukan dibetulkan).
2. Kamu **bukan** sesi penulis PR. Tugasmu **membantah** klaim di bawah, bukan mempercayainya.
3. Dilarang memuji, dilarang "looks good", dilarang melaporkan soal gaya penulisan sebagai temuan.
4. Setiap calon temuan wajib diuji ulang di kode sekarang (buka berkas, jalankan perintah). Tidak bisa dibuktikan → **DUGAAN**.
4b. **Temuan tentang gerbang/CI WAJIB dibuktikan dengan MENJALANKAN perintahnya dan menempelkan keluaran mentahnya**
   (termasuk kode keluar). Membaca potongan kode TIDAK cukup untuk menyimpulkan sebuah langkah "tidak mengerjakan apa pun".
   Pelajaran nyata (putaran11, temuan PR-01): peninjau menyimpulkan `node alat/uji-sql.mjs --daftar` "tidak menjalankan
   28 berkas uji" hanya dari membaca `if (hanyaDaftar) {{ … }}`; padahal opsi itu HANYA menambah cetakan daftar dan seluruh
   uji tetap dijalankan. Temuan itu terbantah (uji yang sengaja dirusak → `uji: 27 LULUS · 1 GAGAL`, exit 1). Temuan
   semacam ini dicatat sebagai **temuan palsu** dan menurunkan nilai kalibrasi sesi peninjau.
5. Periksa **commit yang dimaksud** (paket menyebut sha-nya). Kalau commit itu tidak ada di repo yang kamu buka,
   jalankan `git fetch origin` lalu periksa sha itu; kalau tetap tidak bisa → **BERHENTI** dan laporkan ke Lee,
   jangan mereview commit lain.

## 0b. Setelah laporan selesai — kirim ke sesi kerja (wajib)

Beri nama berkas dengan **penanda sesimu** di belakang (mis. `__01a0aeb4`) supaya dua sesi peninjau tidak
bertabrakan; penarik laporan menyimpan nama bentrok secara terpisah, tidak menimpa.

```
git add docs/uji/review-pr/ && git commit -m "laporan review PR <nama>" && git push -u origin HEAD
```

Hanya berkas laporan yang di-commit. Bila push tidak bisa, tulis "belum ter-push" + beri tahu Lee di chat.

## 1. Ringkasan perubahan per tujuan (dari judul commit)
{tujuan_md}

## 2. Berkas per jalur risiko
| Jalur | Jumlah | Contoh berkas |
|---|---|---|
{tabel_risiko}

## 3. Klaim yang wajib kamu bantah
{klaim_md}

## 4. Pemeriksaan gerbang yang wajib dijalankan (tempel hasil nyatanya)
1. `bash aplikasi/alat/periksa-semua.sh` — seluruh pemeriksa repo + aplikasi (harus LOLOS).
2. `node alat/uji-sql.mjs` — uji database nyata di dalam Node (harus 10 LULUS · 0 GAGAL atau lebih).
3. `git diff {dasar}...{kepala}` — baca diff sungguhan; cari hal yang **tidak** ada di deskripsi.
4. Pemeriksa dokumen: `python3 _sistem/validate_system.py` + `python3 alat/periksa-roadmap.py` + `python3 alat/periksa-panduan.py`.
5. `python3 alat/audit-independen.py --uji-diri` + `python3 alat/review-pr.py --uji-diri` (mekanisme tidak boleh tumpul).
{gerbang_merah}
## 5. Bahan kalibrasi cacat tanaman
{kalibrasi_md}

## 6. Format laporan (PERSIS — ditolak mesin bila kurang)
Tulis ke `docs/uji/review-pr/LAPORAN_<tanggal>_<nama-pr>.md`:

```
# LAPORAN REVIEW PR INDEPENDEN — <nama> — <tanggal>

- **Paket review:** `docs/uji/review-pr/<berkas paket>.md`
- **Commit yang direview:** `<sha>`
- **Tingkat risiko:** Merah | Kuning | Hijau
- **Verdict:** BERSIH | BERSIH-DENGAN-CATATAN | TIDAK-BERSIH

## 1. Cakupan diff
| # | Berkas | Jalur risiko | Diperiksa | Bukti (perintah/baris) |
|---|---|---|---|---|

## 2. Klaim yang dibantah
| # | Klaim | Cara membantah | Hasil nyata |
|---|---|---|---|

## 3. Pemeriksaan gerbang
| # | Perintah | Hasil nyata (ringkas) |
|---|---|---|

## 4. Temuan
### [PR-01] Judul temuan
- **Tingkat:** K-1
- **Artefak:** berkas:baris
- **Klaim yang dilanggar:** …
- **Bukti:** perintah → hasil nyata
- **Skenario gagal:** …
- **Dugaan penyebab:** …
- **Cara membuktikan perbaikan:** perintah yang harus hijau
- **Status verifikasi:** TERVERIFIKASI

## 5. Kalibrasi cacat tanaman
Ditemukan: X dari Y · temuan palsu: n · daftar cacat yang saya temukan: …

## 6. Yang tidak bisa saya verifikasi
- …

## 7. Pernyataan tidak mengubah apa pun
Saya hanya-baca, bukan sesi penulis PR. SATU-SATUNYA berkas yang saya buat adalah laporan ini; tidak ada berkas lain
yang saya ubah. Bukti: `git status --short` menampilkan hanya berkas laporan ini.

## 8. Temuan di luar cakupan diff (WAJIB — boleh "tidak ada")
| # | Temuan | Mengapa di luar cakupan diff | Bukti | Saran ditindaklanjuti |
|---|---|---|---|---|
```

**Aturan penulisan laporan (ditegakkan, bukan imbauan):**
- **Ambang minimum adalah LANTAI, bukan target** — jangan berhenti di angka minimum, jangan menambah baris demi syarat.
- **Semua temuan wajib dilaporkan**, termasuk yang kamu temukan **di luar diff** (berkas lain, dokumen, mekanisme) → bagian 8.
  Cakupan menentukan sedalam apa sesuatu **wajib** diperiksa, bukan apa yang **boleh** dilaporkan.
- **Jangan menyusun laporan agar lolos pemeriksa**; format sudah lengkap di paket ini. Jalankan pemeriksa **sekali di akhir**;
  bila ditolak, perbaiki kelengkapan format — bukan menambah temuan yang tidak kamu yakini.
"""

    FOLDER.mkdir(parents=True, exist_ok=True)
    tanda = dt.date.today().isoformat()
    slug = re.sub(r"[^a-z0-9]+", "-", (nama or sha[:8]).lower()).strip("-") or sha[:8]
    keluar = FOLDER / f"PKT-{tanda}-{slug}.md"
    keluar.write_text(isi, encoding="utf-8")
    siap = keluar.with_name(keluar.stem + "-SIAP-TEMPEL.md")
    siap.write_text(
        "> BERKAS SIAP-TEMPEL — salin SELURUH isi berkas ini ke chat/percakapan BARU (idealnya model berbeda).\n"
        "> Dibuat mesin oleh `alat/review-pr.py`; kalimat pembuka diambil apa adanya dari sumber kanonik.\n\n"
        "===== MULAI SALIN DARI SINI =====\n\n" + prompt_kanonik() + "\n\n===== SAMBUNGAN: PAKET REVIEW =====\n\n" + isi,
        encoding="utf-8")
    print(f"PAKET REVIEW dibuat : {keluar.relative_to(AKAR)}")
    print(f"SIAP-TEMPEL         : {siap.relative_to(AKAR)}   (Lee cukup menyalin berkas ini)")
    print(f"  cabang           : {nama or '-'}")
    print(f"  commit direview  : {sha}")
    print(f"  jalur risiko     : {jalur_dominan} ({len(ubah)} berkas, +{tambah}/−{kurang})")
    print(f"  berkalibrasi     : {'ya' if kal else 'belum (RV-3 belum disiapkan)'}")
    return 0


# ---------------------------------------------------------------- --periksa-laporan
def _riwayat_berkas(ref: str, folder: str) -> list[tuple[str, str]]:
    """[(commit, jalur)] semua versi berkas di riwayat cabang, terbaru dulu (cacat mekanisme #12)."""
    _, log = jalankan(["git", "log", "--format=%H", "--name-only", ref, "--", folder])
    hasil: list[tuple[str, str]] = []
    sha = ""
    for baris in log.splitlines():
        b = baris.strip()
        if not b:
            continue
        if re.fullmatch(r"[0-9a-f]{40}", b):
            sha = b
        elif b.lower().endswith(".md"):
            hasil.append((sha, b))
    return hasil


def _nama_cabang_ringkas(cabang: str) -> str:
    """`origin/arena/01a0aeb4-resto-barokah` → `01a0aeb4` (penanda asal laporan)."""
    n = cabang.replace("origin/", "").replace("arena/", "").replace("-resto-barokah", "")
    return n[:16] or "tanpa-nama"


def _kontrak_target_memuat(sha: str, berkas_alat: str = "alat/review-pr.py") -> bool | None:
    """Apakah kontrak di commit TARGET sudah memuat bagian 8? True/False/None (tak bisa dipastikan)."""
    if not sha:
        return None
    rc, _ = jalankan(["git", "cat-file", "-e", f"{sha}:{berkas_alat}"])
    if rc != 0:
        return None
    _, isi = jalankan(["git", "show", f"{sha}:{berkas_alat}"])
    return "## 8. Temuan di luar cakupan diff" in isi


def periksa_laporan(berkas: pathlib.Path, cek_sha: bool = True) -> tuple[int, list[str], list[str], dict]:
    gagal: list[str] = []
    catatan: list[str] = []
    angka: dict = {}
    if not berkas.is_file():
        return 1, [f"laporan tidak ada: {berkas}"], [], {}
    teks = berkas.read_text(encoding="utf-8")

    def _tabel(judul: str) -> list[list[str]]:
        m = re.search(rf"^{re.escape(judul)}\s*$", teks, re.M)
        if not m:
            return []
        sisa = teks[m.end():]
        n = re.search(r"^## ", sisa, re.M)
        blok = sisa[: n.start()] if n else sisa
        baris = []
        for ln in blok.splitlines():
            ln = ln.strip()
            if not ln.startswith("|"):
                continue
            sel = [s.strip() for s in ln.strip("|").split("|")]
            if all(set(s) <= set("-: ") for s in sel if s):
                # baris pemisah markdown: baris TEPAT SEBELUMNYA adalah kepala kolom,
                # bukan data → buang supaya ambang minimum tidak dihitung dari kepala
                # (temuan review RV-2 putaran8 PR-14: satu berkas "cukup" karena kepalanya ikut dihitung).
                if baris:
                    baris.pop()
                continue
            baris.append(sel)
        return baris

    # 1. bagian wajib
    for bagian in ("## 1. Cakupan diff", "## 2. Klaim yang dibantah", "## 3. Pemeriksaan gerbang",
                   "## 4. Temuan", "## 5. Kalibrasi cacat tanaman", "## 6. Yang tidak bisa saya verifikasi",
                   "## 7. Pernyataan tidak mengubah apa pun", "## 8. Temuan di luar cakupan diff"):
        if bagian not in teks:
            if bagian == "## 8. Temuan di luar cakupan diff":
                # kontrak §8 baru berlaku sejak 2026-09-17 → laporan atas paket lama dinilai kontrak lama
                m8 = re.search(r"- \*\*Commit yang direview:\*\*\s*`?([0-9a-f]{7,40})`?", teks)
                status8 = _kontrak_target_memuat(m8.group(1)) if m8 else None
                if status8 is False:
                    catatan.append("bagian 8 tidak ada, tetapi kontrak §8 belum berlaku di commit yang direview "
                                   "— dinilai dengan kontrak lama (bukan pelanggaran)")
                else:
                    gagal.append(f"bagian wajib hilang: '{bagian}'")
                continue
            gagal.append(f"bagian wajib hilang: '{bagian}'")

    sha_m = re.search(r"- \*\*Commit yang direview:\*\*\s*`?([0-9a-f]{7,40})`?", teks)
    if not sha_m:
        gagal.append("tidak ada baris '- **Commit yang direview:** <sha>'")
    elif cek_sha:
        sha = sha_m.group(1)
        rc, _ = jalankan(["git", "cat-file", "-e", f"{sha}^{{commit}}"])
        if rc != 0:
            if (AKAR / ".git" / "shallow").is_file():
                catatan.append(f"SHA {sha[:8]} tidak bisa diverifikasi di klon dangkal — verifikasi saat review sungguhan")
            else:
                gagal.append(f"SHA {sha} tidak ada di repo ini (review harus menunjuk commit nyata)")

    # 2. cakupan & kedalaman
    cakupan = _tabel("## 1. Cakupan diff")
    angka["artefak"] = len(cakupan)
    if len(cakupan) < MIN_ARTEFAK:
        gagal.append(f"cakupan terlalu sedikit: {len(cakupan)} berkas (minimum {MIN_ARTEFAK})")
    klaim = _tabel("## 2. Klaim yang dibantah")
    angka["klaim"] = len(klaim)
    if len(klaim) < MIN_KLAIM:
        gagal.append(f"klaim dibantah terlalu sedikit: {len(klaim)} (minimum {MIN_KLAIM})")
    gerbang = _tabel("## 3. Pemeriksaan gerbang")
    angka["gerbang"] = len(gerbang)
    if len(gerbang) < MIN_GERBANG:
        gagal.append(f"pemeriksaan gerbang terlalu sedikit: {len(gerbang)} (minimum {MIN_GERBANG})")

    # 3. temuan + 8 bidang
    judul_temuan = re.findall(r"^### \[PR-\d+\] (.+)$", teks, re.M)
    angka["temuan"] = len(judul_temuan)
    for bidang in ("**Tingkat:**", "**Artefak:**", "**Klaim yang dilanggar:**", "**Bukti:**",
                   "**Skenario gagal:**", "**Dugaan penyebab:**", "**Cara membuktikan perbaikan:**", "**Status verifikasi:**"):
        if judul_temuan and bidang not in teks:
            gagal.append(f"temuan ada tetapi bidang wajib '{bidang}' hilang")
    if judul_temuan and "perintah" not in teks.lower() and "```" not in teks:
        gagal.append("temuan tanpa perintah bukti (blok kode/keluaran perintah)")

    # 4. verdict & konsistensi
    v_m = re.search(r"- \*\*Verdict:\*\*\s*`?(BERSIH-DENGAN-CATATAN|TIDAK-BERSIH|BERSIH)`?", teks)
    r_m = re.search(r"- \*\*Tingkat risiko:\*\*\s*`?(Merah|Kuning|Hijau)`?", teks)
    if not v_m:
        gagal.append("tidak ada baris '- **Verdict:** BERSIH|BERSIH-DENGAN-CATATAN|TIDAK-BERSIH'")
    if not r_m:
        gagal.append("tidak ada baris '- **Tingkat risiko:** Merah|Kuning|Hijau'")
    if v_m:
        angka["verdict"] = v_m.group(1)
    if r_m:
        angka["risiko"] = r_m.group(1)
    berat = re.findall(r"- \*\*Tingkat:\*\*\s*(K-[12])\b", teks)
    terverifikasi = len(re.findall(r"- \*\*Status verifikasi:\*\*\s*TERVERIFIKASI", teks))
    # Hitung temuan BERAT (K-1/K-2) yang TERVERIFIKASI — dihitung PER TEMUAN, bukan dengan
    # regex melintasi temuan: versi lama menghitung temuan K-3 terverifikasi sebagai "berat"
    # (temuan review RV-2 putaran8 PR-09), sehingga aturan verdict bisa salah menuduh.
    blok_temuan = re.split(r"^### \[PR-\d+\]", teks, flags=re.M)[1:]
    berat_terverifikasi = 0
    for blok in blok_temuan:
        tingkat_b = re.search(r"- \*\*Tingkat:\*\*\s*(K-\d)", blok)
        if tingkat_b and tingkat_b.group(1) in ("K-1", "K-2") and re.search(r"- \*\*Status verifikasi:\*\*\s*TERVERIFIKASI", blok):
            berat_terverifikasi += 1
    angka["berat_terverifikasi"] = berat_terverifikasi
    if berat and terverifikasi == 0:
        gagal.append("ada temuan K-1/K-2 tetapi tidak ada yang berstatus TERVERIFIKASI")
    if angka.get("berat_terverifikasi", 0) > 0 and v_m and v_m.group(1) != "TIDAK-BERSIH":
        gagal.append(
            f"verdict {v_m.group(1)} padahal ada temuan K-1/K-2 TERVERIFIKASI — wajib TIDAK-BERSIH "
            "(temuan review RV-2 putaran8 PR-09: dulu 'BERSIH-DENGAN-CATATAN' masih diterima)"
        )

    # 5. kedalaman sesuai jalur (PROTOKOL §3)
    if r_m and r_m.group(1) == "Merah":
        # PR-14b: dulu cukup ADA kata di mana pun (termasuk prosa). Sekarang kata kuncinya harus
        # muncul di BARIS BUKTI — baris yang memuat perintah/keluaran nyata (blok kode, atau baris
        # dengan perintah ber-backtick disertai hasil). Peninjau tetap bebas memakai tabel/inline
        # (ketiga laporan nyata memakainya) — yang ditutup hanyalah klaim kosong tanpa bukti.
        baris_bukti = _baris_bukti(teks)
        isi_bukti = "\n".join(baris_bukti).lower()
        if len(baris_bukti) < 8:
            gagal.append(f"jalur Merah hanya memuat {len(baris_bukti)} baris bukti (minimum 8) — kedalaman tidak terbukti")
        if "mutasi" not in isi_bukti:
            gagal.append("jalur Merah tanpa bukti uji mutasi DI DALAM blok bukti (§3 protokol)")
        if not re.search(r"(rls|policy|izin|hak|grant)", isi_bukti):
            gagal.append("jalur Merah tanpa pemeriksaan izin/RLS di dalam blok bukti")
        # Rencana pemulihan = NIAT, bukan bukti kerja → boleh berupa prosa (laporan nyata menulisnya
        # sebagai paragraf), jadi diperiksa di seluruh teks, tidak dipaksa ada di baris bukti.
        if not re.search(r"(pemulihan|rollback|dikembalikan|revert|jangan merge)", teks, re.I):
            gagal.append("jalur Merah tanpa rencana pemulihan / sisa risiko")
        if not re.search(r"(l1|l2|l4|lensa)", teks, re.I):
            gagal.append("jalur Merah tanpa menyebut lensa yang diwajibkan (L1/L2/L4)")

    # 6. kalibrasi: wajib bila paket benar-benar mengirim berkas bahan kalibrasi
    paket_m = re.search(r"- \*\*Paket review:\*\*\s*`?([^`\n]+)`?", teks)
    if paket_m:
        berkas_paket = AKAR / paket_m.group(1).strip()
        if not berkas_paket.is_file():
            # PR-14: dulu berkas paket yang tidak ada membuat seluruh pemeriksaan kalibrasi
            # DIAM-DIAM dilewati (gagal terbuka). Sekarang: wajib ada.
            gagal.append(f"berkas paket review tidak ada: {paket_m.group(1).strip()}")
        else:
            isi_paket = berkas_paket.read_text(encoding="utf-8")
            # Bahan kalibrasi WAJIB dinilai bila paket mengirimkannya ATAU bila ada bahan kalibrasi
            # terbaru di repo yang menargetkan commit yang direview (dulu cukup satu kata kunci).
            # Hanya penanda KUAT yang dihitung: jalur berkas bahan kalibrasi (bukan sekadar kata
            # "kalibrasi" — baris "tidak disiapkan" pun memuat kata itu, temuan uji-diri).
            wajib_kalibrasi = "pr-bahan-" in isi_paket or "docs/uji/kalibrasi/" in isi_paket
            if wajib_kalibrasi:
                m_kal = re.search(r"Ditemukan:\s*(\d+)\s*dari\s*(\d+)", teks)
                angka["kalibrasi"] = (int(m_kal.group(1)), int(m_kal.group(2))) if m_kal else (0, 0)
                if not m_kal:
                    gagal.append("ada bahan kalibrasi untuk commit ini tetapi laporan tidak menulis 'Ditemukan: X dari Y'")
                if not re.search(r"temuan palsu", teks, re.I):
                    gagal.append("laporan kalibrasi tanpa jumlah temuan palsu")
                if m_kal:
                    ditemukan, total = int(m_kal.group(1)), int(m_kal.group(2))
                    if total <= 0:
                        gagal.append("laporan kalibrasi menulis total cacat 0 — tidak masuk akal")
                    elif ditemukan < total and v_m and v_m.group(1) != "TIDAK-BERSIH":
                        gagal.append(
                            f"kalibrasi tidak penuh ({ditemukan}/{total}) tetapi verdict bukan TIDAK-BERSIH — "
                            "kemampuan menemukan cacat terbukti belum memadai (PR-14)"
                        )
                    x, y = ditemukan, total
                    if y and x / y < 0.7:
                        catatan.append(f"tingkat deteksi kalibrasi {x}/{y} < 70% — verdict BERSIH tidak boleh dipercaya")

    # 7. pernyataan
    if "tidak mengubah" not in teks.lower():
        gagal.append("tidak ada pernyataan 'tidak mengubah' (bagian 7)")
    if "penulis" not in teks.lower():
        gagal.append("bagian 7 tidak menyatakan peninjau bukan sesi penulis PR")
    if len(_tabel("## 6. Yang tidak bisa saya verifikasi")) < 1 and "- " not in teks.split("## 6.")[-1].split("## 7.")[0]:
        gagal.append("bagian 6 kosong — minimal 1 butir jujur soal batas verifikasi")

    # bagian 8: temuan di luar diff (boleh kosong, wajib ada)
    if "## 8. Temuan di luar cakupan diff" in teks:
        bagian8 = teks.split("## 8. Temuan di luar cakupan diff")[-1]
        baris8 = _tabel("## 8. Temuan di luar cakupan diff")
        angka["luar_cakupan"] = len(baris8)
        if not baris8 and not re.search(r"tidak ada", bagian8, re.I):
            gagal.append("bagian 8 kosong: tulis temuan di luar cakupan diff, atau tulis 'tidak ada'")

    # pernyataan bagian 7 harus menyebut laporan sebagai satu-satunya berkas
    bagian7 = teks.split("## 7. Pernyataan tidak mengubah apa pun")[-1].split("## 8.")[0]
    if not re.search(r"laporan|satu-satunya berkas", bagian7, re.I):
        gagal.append("bagian 7 wajib menyebut laporan ini adalah satu-satunya berkas yang dibuat peninjau")

    # lantai vs target (anti-teater)
    if angka.get("artefak") == MIN_ARTEFAK:
        catatan.append(f"cakupan persis di ambang minimum ({MIN_ARTEFAK}) — ambang = lantai, bukan target")
    if angka.get("klaim") == MIN_KLAIM:
        catatan.append("klaim dibantah persis di ambang minimum — periksa apakah peninjau berhenti di ambang")
    if angka.get("gerbang") == MIN_GERBANG:
        catatan.append("pemeriksaan gerbang persis di ambang minimum — periksa apakah peninjau berhenti di ambang")

    return (1 if gagal else 0), gagal, catatan, angka


# ---------------------------------------------------------------- --kartu-keputusan
def kartu_keputusan(berkas: pathlib.Path) -> int:
    kode, gagal, catatan, angka = periksa_laporan(berkas)
    if kode != 0:
        print("GAGAL: laporan belum lolos kontrak — perbaiki dulu:")
        for g in gagal:
            print(f"  [X] {g}")
        return 1
    teks = berkas.read_text(encoding="utf-8")
    k1 = len(re.findall(r"- \*\*Tingkat:\*\*\s*K-1", teks))
    k2 = len(re.findall(r"- \*\*Tingkat:\*\*\s*K-2", teks))
    k3 = len(re.findall(r"- \*\*Tingkat:\*\*\s*K-3", teks))
    rekom = "JANGAN MERGE DULU" if (angka.get("berat_terverifikasi", 0) or
                                    (angka.get("kalibrasi", (1, 1))[0] / max(angka.get("kalibrasi", (1, 1))[1], 1)) < 0.7) \
        else "BOLEH MERGE"
    if angka.get("verdict") == "TIDAK-BERSIH":
        rekom = "JANGAN MERGE DULU"
    print("KARTU KEPUTUSAN (untuk Lee)")
    print(f"  Commit        : {angka.get('sha', '-')}")
    print(f"  Jalur risiko  : {angka.get('risiko', '-')}")
    print(f"  Hasil peninjau: {angka.get('verdict', '-')} · K-1: {k1} · K-2: {k2} · K-3: {k3}")
    print(f"  Cakupan       : {angka.get('artefak', 0)} berkas · {angka.get('klaim', 0)} klaim dibantah · {angka.get('gerbang', 0)} gerbang dijalankan")
    if angka.get("kalibrasi"):
        print(f"  Kalibrasi     : {angka['kalibrasi'][0]}/{angka['kalibrasi'][1]} cacat ditemukan")
    if "luar_cakupan" in angka:
        print(f"  Luar cakupan  : {angka['luar_cakupan']} temuan")
    for c in catatan:
        print(f"  [catatan] {c}")
    print(f"  REKOMENDASI   : {rekom}")
    return 0 if rekom == "BOLEH MERGE" else 2


# ---------------------------------------------------------------- --kesiapan
# Berkas yang boleh berubah setelah commit target tanpa membatalkan paket review:
# paket/laporan/kalibrasi itu sendiri (dibuat SETELAH paket ditulis — ayam-dan-telur).
BERKAS_NETRAL = ("docs/uji/review-pr/", "docs/uji/paket-audit/", "docs/uji/kalibrasi/", "docs/uji/audit/",
                 # buku besar mekanisme ini sendiri: mengisi baris riwayat (verdict/commit yang dinilai)
                 # adalah tindakan yang WAJAR sesudah paket dibuat — bukan perubahan kode/klaim
                 "docs/uji/REVIEW_PR_RIWAYAT.md", "docs/uji/AUDIT_RIWAYAT.md")


def _selisih_hanya_netral(target: str) -> bool:
    rc, keluaran = jalankan(["git", "diff", "--name-only", f"{target}..HEAD"])
    if rc != 0:
        return False
    berkas = [b for b in keluaran.splitlines() if b.strip()]
    return bool(berkas) and all(b.startswith(BERKAS_NETRAL) for b in berkas)


def ambil_laporan() -> int:
    """Tarik laporan review PR dari cabang sesi peninjau (arena/*) — jalur pulang laporan."""
    print("Mencari laporan review PR di cabang sesi lain (arena/*)…")
    rc, keluaran = jalankan(["git", "fetch", "origin",
                             "+refs/heads/arena/*:refs/remotes/origin/arena/*", "--prune"])
    if rc != 0:
        print(f"GAGAL mengambil cabang: {keluaran}")
        return 1
    _, cabang = jalankan(["git", "for-each-ref", "--format=%(refname:short)", "refs/remotes/origin/arena/"])
    daftar = [c.strip() for c in cabang.splitlines() if c.strip()]
    if not daftar:
        print("CATATAN: tidak ada cabang arena/* di GitHub.")
        return 1
    FOLDER.mkdir(parents=True, exist_ok=True)
    sudah_ada = {f.read_text(encoding='utf-8') for f in FOLDER.glob('*.md') if f.is_file()}
    ditemukan: list[tuple[str, str, str]] = []
    for ref in daftar:
        # cacat mekanisme #12: versi lama bisa hanya hidup di RIWAYAT commit (nama berkas sama, satu cabang)
        for sha_v, jalur in _riwayat_berkas(ref, "docs/uji/review-pr/"):
            if not ("LAPORAN" in jalur.upper() and jalur.lower().endswith(".md")):
                continue
            _, isi = jalankan(["git", "show", f"{sha_v}:{jalur}"])
            if not isi.strip() or isi in sudah_ada:
                continue
            nama = pathlib.Path(jalur).name
            target = FOLDER / nama
            if not target.is_file():
                target.write_text(isi, encoding="utf-8")
                sudah_ada.add(isi)
                ditemukan.append((ref.replace("origin/", ""), str(target.relative_to(AKAR)), "baru"))
                continue
            ringkas = _nama_cabang_ringkas(ref)
            for kandidat in (f"{target.stem}.dari-{ringkas}{target.suffix}",
                             f"{target.stem}.dari-{ringkas}-{sha_v[:8]}{target.suffix}"):
                pendamping = target.with_name(kandidat)
                if pendamping.is_file() and pendamping.read_text(encoding="utf-8") == isi:
                    break
                if not pendamping.is_file():
                    pendamping.write_text(isi, encoding="utf-8")
                    sudah_ada.add(isi)
                    ditemukan.append((ref.replace("origin/", ""), str(pendamping.relative_to(AKAR)),
                                      "nama sama / versi tertimpa — disimpan terpisah"))
                    break
    print()
    if not ditemukan:
        print("TIDAK ADA laporan review baru di cabang arena/*.")
        print("  • Pastikan peninjau sudah: tulis laporan → `git add docs/uji/review-pr/` → commit → push.")
        print("  • Kalau tidak bisa push: minta ia menempelkan laporan di chat; agent membuatkan berkasnya.")
        return 1
    print(f"DITEMUKAN {len(ditemukan)} laporan:")
    for cabang_nama, jalur, status in ditemukan:
        print(f"  · [{cabang_nama}] {jalur} — {status}")
    print("\nLangkah berikutnya:")
    for _, jalur, _ in ditemukan:
        print(f"  python3 alat/review-pr.py --periksa-laporan {jalur}")
        print(f"  python3 alat/review-pr.py --kartu-keputusan {jalur}")
    return 0


def kesiapan() -> int:
    sha = sha_ringkas("HEAD")
    if not FOLDER.is_dir():
        print(f"BELUM: belum ada paket review di {FOLDER.relative_to(AKAR)}/")
        print("       Jalankan: python3 alat/review-pr.py --siapkan")
        return 1
    cocok: list[str] = []
    netral: list[str] = []
    for paket in sorted(FOLDER.glob("PKT-*.md")):
        isi = paket.read_text(encoding="utf-8")
        m = re.search(r"- \*\*Commit yang direview:\*\*\s*`?([0-9a-f]{7,40})`?", isi)
        if not m:
            continue
        target = m.group(1)
        if sha.startswith(target[:12]):
            cocok.append(paket.name)
        elif _selisih_hanya_netral(target):
            # commit target ada di riwayat, dan perubahan setelahnya hanya berkas paket/laporan →
            # paket masih berlaku (mis. commit yang menambahkan paket itu sendiri).
            cocok.append(f"{paket.name} (target {target[:8]} + hanya berkas paket)")
            netral.append(target[:8])
    if cocok:
        print(f"SIAP: commit {sha[:8]} punya paket review berlaku: {', '.join(cocok)}")
        if netral:
            print("       (paket menunjuk commit sebelum berkas paket ditulis — itu normal)")
        return 0
    print(f"BELUM: commit sekarang ({sha[:8]}) belum punya paket review.")
    print("       Jalankan: python3 alat/review-pr.py --siapkan   (lalu minta Lee membuka sesi peninjau)")
    return 1


# ---------------------------------------------------------------- --kalibrasi-pr-siapkan
def kalibrasi_pr_siapkan(jumlah: int | None) -> int:
    if not KATALOG.is_file():
        print(f"GAGAL: katalog cacat TIDAK ADA di luar repo: {KATALOG}")
        print("       Jalur review PR sengaja HANYA membaca katalog dari luar repo: katalog di")
        print("       dalam repo = kunci jawaban yang bisa dibaca peninjau (temuan audit H F-01).")
        if KATALOG_REPO.is_file():
            print(f"       Katalog yang SEKARANG ada di dalam repo: {KATALOG_REPO.relative_to(AKAR)}")
            print(f"       Pindahkan (butuh keputusan Lee): mv {KATALOG_REPO.relative_to(AKAR)} {KATALOG}")
        print("       Setelah dipindah: python3 alat/review-pr.py --kalibrasi-pr-siapkan")
        return 1
    bocor = bahan_bocor_di_repo()
    if bocor:
        print("GAGAL: bahan/kunci kalibrasi ada DI DALAM repo (kunci jawaban bocor — audit D F-05):")
        for b in bocor:
            print(f"  - {b.relative_to(AKAR)}")
        print("  Keluarkan dari repo: git rm <berkas itu>. Bahan baru ditulis di luar repo.")
        return 1
    cacat = json.loads(KATALOG.read_text(encoding="utf-8"))["cacat"]
    # Pilih campuran: utamakan K-1/K-2, TETAPI diacak dengan benih tanggal.
    # Alasan (temuan luar-cakupan review putaran8 #3 + audit H F-01 2026-09-20): pilihan cacat
    # diacak dengan benih tanggal supaya tiap putaran berbeda, DAN katalognya kini dibaca dari
    # luar repo — peninjau tidak bisa lagi mencocokkan diff paket dengan daftar jawaban.
    berat = [c for c in cacat if c["tingkat"] in ("K-1", "K-2")]
    ringan = [c for c in cacat if c["tingkat"] not in ("K-1", "K-2")]
    benih = int(dt.date.today().strftime("%Y%m%d"))
    acak = random.Random(benih)
    acak.shuffle(berat)
    acak.shuffle(ringan)
    campuran = berat + ringan
    cacat = campuran[: (jumlah or 4)]
    tanda = dt.date.today().isoformat()
    kerja = pathlib.Path(f"/tmp/kalibrasi-pr-{dt.datetime.now().strftime('%Y%m%d-%H%M%S')}")
    rc, keluaran = jalankan(["git", "worktree", "add", "--detach", str(kerja), "HEAD"])
    if rc != 0:
        print(f"GAGAL menyiapkan worktree: {keluaran}"); return 1
    baris_kunci = []
    gagal = []
    for c in cacat:
        berkas = kerja / c["berkas"]
        if not berkas.is_file():
            gagal.append(f"{c['id']}: berkas tidak ada {c['berkas']}"); continue
        teks = berkas.read_text(encoding="utf-8")
        if c["cari"] not in teks:
            gagal.append(f"{c['id']}: pola tidak ditemukan (katalog basi!)"); continue
        berkas.write_text(teks.replace(c["cari"], c["ganti"], 1), encoding="utf-8")
        baris_kunci.append(f"| {c['id']} | {c['tingkat']} | {c['kelas']} | `{c['berkas']}` | {c['ringkas']} |")
    if gagal:
        jalankan(["git", "worktree", "remove", "--force", str(kerja)])
        print("GAGAL menyiapkan kalibrasi PR:"); [print(f"  - {g}") for g in gagal]; return 1
    # PENTING (dua cacat yang ditemukan review RV-2 putaran8, PR-04 & PR-06): penanda
    # "-- SENGAJA (kalibrasi)" TIDAK boleh ikut ke bahan (peninjau tinggal mencari kata itu),
    # dan kalau baris dibuang SESUDAH diff dibuat, hitungan hunk jadi rusak → `git apply` gagal.
    # Perbaikan: rapikan ISI BERKAS dulu, baru minta `git diff` — diff-nya selalu sah.
    for c in cacat:
        berkas = kerja / c["berkas"]
        teks = berkas.read_text(encoding="utf-8")
        berkas.write_text(re.sub(r"\s*--\s*SENGAJA[^\n]*", "", teks), encoding="utf-8")
    # PENTING: jangan lewat `jalankan()` — pembungkus itu `.strip()` hasilnya, dan `strip()`
    # membuang baris konteks terakhir (baris kosong) sehingga hunk kurang satu baris →
    # "corrupt patch" (temuan review RV-2 putaran8 PR-06). Ambil stdout apa adanya.
    diff = subprocess.run(["git", "diff"], cwd=str(kerja), capture_output=True, text=True).stdout

    # Penjaga: bahan wajib benar-benar bisa dipasang di commit ini. Caranya: di worktree yang
    # SUDAH bermutasi, `git apply --check --reverse` hanya berhasil bila patch-nya persis kebalikan
    # dari yang terpasang — jadi hitungan hunk & konteksnya sah. Kalau gagal, alat MENOLAK memberi
    # bahan (dulu menghasilkan bahan korup yang membuat RV-3 tidak bisa dijalankan — PR-04/PR-06).
    berkas_uji_pasang = pathlib.Path("/tmp/periksa-bahan-kalibrasi.diff")
    berkas_uji_pasang.write_text(diff, encoding="utf-8")
    cek = jalankan(["git", "apply", "--check", "--reverse", str(berkas_uji_pasang)], cwd=kerja)
    if cek[0] != 0:
        print("GAGAL: bahan kalibrasi tidak bisa dipasang-balik di commit ini (katalog cacat tidak cocok):")
        print(f"  {cek[1].strip()}")
        jalankan(["git", "worktree", "remove", "--force", str(kerja)])
        return 1
    # F-05: bahan ditulis DI LUAR repo. Dif terhadap migrasi nyata = kunci jawaban; menyimpannya
    # di repo membuat peninjau bisa membaca letak semua cacat (dan riwayat Git menyimpannya
    # selamanya). Isi bahan disematkan ke paket oleh `--siapkan`.
    KAL_DIR_LUAR.mkdir(parents=True, exist_ok=True)
    keluar = KAL_DIR_LUAR / f"pr-bahan-{tanda}.diff"
    keluar.write_text(diff, encoding="utf-8")
    kunci = pathlib.Path(f"/tmp/KUNCI-KALIBRASI-PR-{tanda}.md")
    kunci.write_text(
        "# KUNCI JAWABAN KALIBRASI REVIEW PR (JANGAN DIBACA PENINJAU)\n\n"
        f"- Bahan: `{keluar}` (LUAR repo) · Dibuat: {dt.datetime.now().isoformat(timespec='minutes')}\n"
        f"- Jumlah cacat: {len(cacat)}\n\n| ID | Tingkat | Kelas | Berkas | Ringkas |\n|---|---|---|---|---|\n"
        + "\n".join(baris_kunci) + "\n", encoding="utf-8")
    jalankan(["git", "worktree", "remove", "--force", str(kerja)])
    print("KALIBRASI REVIEW PR SIAP")
    print(f"  bahan (LUAR repo)       : {keluar}")
    print(f"  kunci jawaban (LUAR)    : {kunci}")
    print(f"  jumlah cacat            : {len(cacat)}")
    print("  Langkah berikut: jalankan `--siapkan` ulang supaya paket MENYEMATKAN isi bahan itu")
    print("  lalu minta Lee membuka sesi peninjau. Setelah laporan masuk, nilai X dari Y vs kunci ini.")
    return 0


# ---------------------------------------------------------------- --uji-diri
def uji_diri() -> int:
    contoh = AKAR / "alat" / "contoh-laporan-review"
    if not contoh.is_dir():
        print(f"GAGAL: folder contoh tidak ada: {contoh}"); return 1
    harapan = {
        "bagus.md": (0, "laporan lengkap & konsisten"),
        "buruk-tanpa-bukti.md": (1, "temuan tanpa bukti + verdict terlalu tinggi"),
        "buruk-klaim-kurang.md": (1, "klaim dibantah & gerbang terlalu sedikit"),
        # Tiga contoh ini lahir dari temuan review RV-2 putaran8 (PR-09 & PR-14):
        # gate-nya dulu tumpul, jadi tiap perbaikan wajib punya contoh yang HARUS ditolak.
        "buruk-verdict-longgar.md": (1, "verdict bukan TIDAK-BERSIH padahal ada K-1/K-2 TERVERIFIKASI"),
        "buruk-kedalaman-kata.md": (1, "jalur Merah hanya cocok kata di prosa, tanpa blok bukti"),
        "buruk-paket-hilang.md": (1, "paket review yang dirujuk tidak ada (kalibrasi tak bisa dicocokkan)"),
    }
    lulus = 0
    for nama, (harus, alasan) in harapan.items():
        berkas = contoh / nama
        if not berkas.is_file():
            print(f"  [X] contoh hilang: {nama}"); continue
        kode, gagal, catatan, _ = periksa_laporan(berkas, cek_sha=False)
        tanda = "OK " if kode == harus else "SALAH"
        if kode == harus:
            lulus += 1
        print(f"  [{tanda}] {nama}: hasil={kode} harapan={harus} ({alasan})")
        if kode != harus and gagal:
            print(f"        alasan penolakan: {gagal[0]}")
    if lulus == len(harapan):
        print("\nHASIL: LOLOS — pemeriksa laporan review PR terbukti bisa MENOLAK yang buruk dan MENERIMA yang baik.")
        return 0
    print(f"\nHASIL: GAGAL — {lulus}/{len(harapan)} contoh berperilaku benar.")
    return 1


# ---------------------------------------------------------------- main
def main() -> int:
    p = argparse.ArgumentParser(description="Review PR independen (RV-1…RV-3)")
    p.add_argument("--siapkan", action="store_true", help="bangun paket review untuk PR/kepala sekarang")
    p.add_argument("--pr", help="nomor PR GitHub (dasar & kepala dibaca dari PR)")
    p.add_argument("--dasar", default="main", help="ref dasar (default: main)")
    p.add_argument("--kepala", default="HEAD", help="ref kepala (default: HEAD)")
    p.add_argument("--nama", help="nama pendek untuk berkas paket (mis. pr-01-fase1b)")
    p.add_argument("--periksa-laporan", help="validasi laporan peninjau")
    p.add_argument("--kartu-keputusan", help="cetak kartu keputusan untuk Lee dari laporan peninjau")
    p.add_argument("--kesiapan", action="store_true", help="cek apakah commit sekarang sudah punya paket review")
    p.add_argument("--ambil-laporan", action="store_true", help="tarik laporan review dari cabang sesi peninjau (arena/*)")
    p.add_argument("--kalibrasi-pr-siapkan", action="store_true", help="buat bahan kalibrasi review (diff dengan cacat sengaja)")
    p.add_argument("--jumlah", type=int, default=None, help="jumlah cacat kalibrasi (default 4)")
    p.add_argument("--uji-diri", action="store_true", help="uji pemeriksa laporan dengan contoh baik & buruk")
    a = p.parse_args()

    if a.uji_diri:
        return uji_diri()
    if a.kalibrasi_pr_siapkan:
        return kalibrasi_pr_siapkan(a.jumlah)
    if a.ambil_laporan:
        return ambil_laporan()
    if a.kesiapan:
        return kesiapan()
    if a.periksa_laporan:
        berkas = pathlib.Path(a.periksa_laporan)
        kode, gagal, catatan, angka = periksa_laporan(berkas)
        print(f"PERIKSA LAPORAN REVIEW — {berkas}")
        for c in catatan:
            print(f"  [catatan] {c}")
        if kode == 0:
            print(f"  verdict          : {angka.get('verdict')}")
            print(f"  jalur risiko     : {angka.get('risiko')}")
            print(f"  cakupan/klaim    : {angka.get('artefak')} berkas / {angka.get('klaim')} klaim / {angka.get('gerbang')} gerbang")
            print(f"  temuan           : {angka.get('temuan', 0)}")
            print("\nHASIL: LOLOS — laporan memenuhi kontrak review PR.")
            return 0
        print(f"\nHASIL: GAGAL — {len(gagal)} temuan")
        for g in gagal:
            print(f"  [X] {g}")
        return 1
    if a.kartu_keputusan:
        return kartu_keputusan(pathlib.Path(a.kartu_keputusan))
    if a.siapkan:
        dasar, kepala, nama = a.dasar, a.kepala, a.nama
        if a.pr:
            rc, keluaran = jalankan(["gh", "pr", "view", a.pr, "--json",
                                     "baseRefName,headRefName,number,title,headRefOid"])
            if rc == 0:
                data = json.loads(keluaran)
                dasar = f"origin/{data['baseRefName']}"
                kepala = f"origin/{data['headRefName']}"
                nama = nama or f"pr-{data['number']}"
                # Ref pelacak lokal bisa KETINGGALAN dari GitHub → paket pernah mengikat commit basi
                # (ditemukan 2026-09-17: paket pr-01-putaran6 menunjuk a003d2d padahal kepala PR ec875b9).
                # Karena itu: segarkan ref-nya dulu, lalu WAJIB sama dengan kepala PR menurut GitHub.
                jalankan(["git", "fetch", "--quiet", "origin",
                          f"refs/heads/{data['baseRefName']}:refs/remotes/origin/{data['baseRefName']}",
                          f"refs/heads/{data['headRefName']}:refs/remotes/origin/{data['headRefName']}"])
                sha_gh = (data.get("headRefOid") or "")[:40]
                sha_lokal = (sha_ringkas(kepala) or "")[:40]
                if sha_gh and sha_gh != sha_lokal:
                    print(f"GAGAL: kepala PR di GitHub ({sha_gh[:8]}) masih BEDA dari ref lokal ({sha_lokal[:8]}) "
                          f"setelah fetch — paket TIDAK dibuat supaya peninjau tidak menilai commit basi.")
                    print("       Periksa: git fetch origin && git rev-parse origin/" + data["headRefName"])
                    return 1
            else:
                print(f"CATATAN: tidak bisa membaca PR {a.pr} via gh — memakai dasar/kepala dari argumen")
        return siapkan(dasar, kepala, nama)
    p.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
