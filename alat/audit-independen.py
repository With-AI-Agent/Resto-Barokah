#!/usr/bin/env python3
"""alat/audit-independen.py — mekanisme audit independen Resto Barokah.

Empat mode (rincian aturan: docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md):

  --paket AUD-2 --tugas T1-01..T1-10   menyiapkan paket audit untuk sesi auditor independen
  --periksa-laporan <berkas>           memvalidasi laporan auditor terhadap kontrak (anti-teater)
  --kalibrasi-siapkan [--cacat N]      menanam cacat pada salinan HEAD + menulis kunci jawaban
  --kalibrasi-nilai <laporan> --kunci <berkas>   menilai tingkat deteksi auditor
  --uji-diri                           membuktikan pemeriksa laporan bisa GAGAL & bisa LOLOS

Prinsip: mesin menolak laporan yang malas, tidak konsisten, atau tanpa bukti — supaya "BERSIH"
berarti sesuatu, bukan sekadar keyakinan. Semua keluaran bahasa Indonesia.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import pathlib
import re
import shutil
import subprocess
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent
ROADMAP = AKAR / "docs" / "ROADMAP.md"
KATALOG = AKAR / "alat" / "kalibrasi-cacat.json"
DIR_PAKET = AKAR / "docs" / "uji" / "paket-audit"
DIR_CONTOH = AKAR / "alat" / "contoh-laporan"

SKILL_WAJIB = [
    ("skills/security-review/SKILL.md", "L1 · L6 — daftar periksa keamanan"),
    ("skills/systematic-debugging/SKILL.md", "L4 — akar masalah, bukan gejala"),
    ("skills/verification-before-completion/SKILL.md", "semua klaim wajib bukti segar"),
    ("skills/verification-loop/SKILL.md", "urutan periksa: bangun → tipe → uji"),
    ("skills/test-driven-development/SKILL.md", "L4 — mutu uji"),
    ("skills/prd-taskmaster/SKILL.md", "L3 — jejak syarat → tugas → uji"),
    ("skills/supabase/SKILL.md", "L1 · L2 — jebakan Supabase (RLS, Auth, paket gratis)"),
    ("skills/supabase-postgres-best-practices/SKILL.md", "L1 · L2 — RLS, fungsi, indeks"),
    ("skills/ui-ux-pro-max/SKILL.md", "L5 — layar, tombol, 7 keadaan"),
]

PERINTAH_BUKTI = [
    "node alat/uji-sql.mjs --daftar        # uji SQL (RLS, uang, PIN, katalog…) + daftar tabel & policy",
    "python3 _sistem/validate_system.py    # struktur & rujukan dokumen",
    "python3 alat/periksa-roadmap.py       # kelengkapan ROADMAP (7 atribut, entitas §4, RPC §5)",
    "python3 alat/periksa-fondasi-independen.py   # pemeriksa kedua (tulisan terpisah)",
    "python3 alat/periksa-fungsi-pin.py    # PIN tidak pernah disimpan/dilog",
    "cd aplikasi && npm test               # uji unit & komponen (vitest)",
    "cd aplikasi && npm run typecheck && npm run lint",
    "git log --oneline -20 && git status --short",
]

GRUP_SEMUA: list[tuple[str, str, str]] = [
    ("aplikasi/src", "kode aplikasi (layar, komponen, lib, uji)", "aplikasi/src/"),
    ("aplikasi/alat", "perkakas pemeriksa aplikasi", "aplikasi/alat/"),
    ("aplikasi (konfigurasi)", "package.json, tsconfig, vite, index.html", "aplikasi/"),
    ("supabase/migrations", "migrasi database", "supabase/migrations/"),
    ("supabase/tes", "uji SQL", "supabase/tes/"),
    ("supabase/functions", "Edge Functions", "supabase/functions/"),
    ("alat", "perkakas repo (uji SQL, pemeriksa, mekanisme audit)", "alat/"),
    ("_sistem", "mesin kerja agent (validator, template)", "_sistem/"),
    ("docs (fondasi)", "PRD, TECH_SPEC, ROADMAP, KEAMANAN, SPESIFIKASI_UI, dll", "docs/"),
    ("docs/uji", "protokol & laporan uji/audit", "docs/uji/"),
    ("docs/teknis", "catatan teknis & Buku Insiden", "docs/teknis/"),
    ("docs/ops", "panduan operasional", "docs/ops/"),
    ("docs/desain", "catatan desain", "docs/desain/"),
    ("prototipe", "prototipe desain (acuan visual)", "prototipe/"),
    ("_log-sesi", "log sesi kerja", "_log-sesi/"),
    ("berkas pengguna di akar", "PANDUAN_*, PROMPT_*, START_DI_SINI, PROFIL_PENGGUNA, AGENT_SYSTEM, STATUS, PROJECT_STATE, dll", "AKAR"),
    (".github/workflows", "alur CI", ".github/"),
]
DIKECUALIKAN: list[tuple[str, str]] = [
    ("skills/", "kumpulan skill pihak ketiga (vendored) — bukan kode proyek; dipakai, tidak diubah"),
    ("_salinan-meta/", "arsip provenance sistem"),
    ("_Notes.md", "catatan pribadi pemilik (tidak ikut template)"),
]

LENSA = {
    "L1": ("Ancaman & Akses", "Bisakah orang tanpa hak masuk/naik peran? Sesi/perangkat yang dicabut masih bisa dipakai? "
                              "Ada fungsi istimewa (security definer) yang bisa dipanggil siapa saja? Ada jalur membaca data penyewa lain?"),
    "L2": ("Uang & Jejak", "Bisakah angka uang dibuat/ubah/hapus dari klien? Pembayaran dobel? Void tanpa jejak? Diskon lewat batas? "
                           "Kas tanpa shift? Apakah jejak audit benar-benar tak bisa diubah dan bisa mendeteksi penghapusan?"),
    "L3": ("Kesepakatan Dokumen", "Setiap janji PRD/TECH_SPEC punya kode DAN uji? Setiap klaim 'Bukti' di ROADMAP bisa direproduksi hari ini? "
                                  "Ada syarat tanpa uji (orphan requirement) atau uji tanpa syarat (orphan test)?"),
    "L4": ("Mutu Uji", "Ada uji yang lulus karena sebab yang salah? Negatif-test yang bisa ditolak banyak sebab? Uji tanpa pemeriksaan? "
                       "Gerbang yang belum pernah dibuktikan bisa MERAH? Ada pemeriksa yang tumpul (selalu hijau)?"),
    "L5": ("Lapangan & UI", "Alur nyata di tablet kasir bisa selesai? Tujuh keadaan tertangani? Ada tombol tanpa fungsi atau aksi tanpa tombol? "
                            "Pesan galat bahasa manusia + kode? Target sentuh & kontras? Printer/offline?"),
    "L6": ("Privasi & Kepatuhan", "Data pelanggan seminimal mungkin? Persetujuan sebelum simpan? Anonimisasi tanpa menghapus catatan keuangan? "
                                  "Jalur kebocoran 3×24 jam siap? Rahasia tidak pernah masuk repo/log?"),
}
LENSA_MINIMUM = {"AUD-2": ["L1", "L3", "L4"], "AUD-3": ["L1", "L2", "L3", "L4", "L5", "L6"]}
SERANGAN_MIN = {"AUD-2": 5, "AUD-3": 12}


# ----------------------------------------------------------------- utilitas
def jalankan(perintah: list[str], cwd: pathlib.Path | None = None) -> tuple[int, str]:
    p = subprocess.run(perintah, cwd=str(cwd or AKAR), capture_output=True, text=True)
    return p.returncode, (p.stdout + p.stderr).strip()


def baca_tugas_roadmap() -> dict[str, str]:
    """id tugas -> seluruh isi blok tugas (untuk mengambil File: & Bukti:)."""
    teks = ROADMAP.read_text(encoding="utf-8")
    pola = re.compile(r"^- \[[ x]\] (T\d+-\d+) — .*$", re.M)
    hasil: dict[str, str] = {}
    for m in pola.finditer(teks):
        mulai = m.start()
        n = pola.search(teks, m.end())
        akhir = n.start() if n else len(teks)
        hasil[m.group(1)] = teks[mulai:akhir]
    return hasil


def berkas_terlacak() -> list[str]:
    _, keluaran = jalankan(["git", "ls-files"])
    return [b for b in keluaran.splitlines() if b.strip()]


def kelompokkan_berkas() -> tuple[dict[str, list[str]], dict[str, int]]:
    """Kelompokkan berkas terlacak ke grup proyek; kembalikan (grup->berkas, jumlah yang dikecualikan)."""
    grup: dict[str, list[str]] = {nama: [] for nama, _, _ in GRUP_SEMUA}
    dikecualikan: dict[str, int] = {nama: 0 for nama, _ in DIKECUALIKAN}
    for b in berkas_terlacak():
        if any(b == nama.rstrip("/") or b.startswith(nama) for nama, _ in DIKECUALIKAN):
            for nama, _ in DIKECUALIKAN:
                if b == nama.rstrip("/") or b.startswith(nama):
                    dikecualikan[nama] += 1
                    break
            continue
        cocok = False
        # prefiks terpanjang menang: docs/uji harus masuk grupnya sendiri, bukan "docs/"
        grup_urut = sorted(GRUP_SEMUA, key=lambda x: -len(x[2]))
        for nama, _, prefiks in grup_urut:
            if prefiks == "AKAR":
                if "/" not in b:
                    grup[nama].append(b)
                    cocok = True
                    break
            elif b.startswith(prefiks):
                grup[nama].append(b)
                cocok = True
                break
        if not cocok:
            grup["aplikasi (konfigurasi)"].append(b) if b.startswith("aplikasi/") else grup["_sistem"].append(b)
    return grup, dikecualikan


def pisah_rentang(spes: str) -> list[str]:
    """'T1-01..T1-10' -> ['T1-01'..'T1-10']; 'T1-23,T1-24' juga boleh."""
    if ".." in spes:
        a, b = spes.split("..")
        fa, na = a.strip().split("-")
        fb, nb = b.strip().split("-")
        if fa != fb:
            raise SystemExit(f"Rentang harus dalam fase yang sama: {spes}")
        return [f"{fa}-{i:02d}" for i in range(int(na), int(nb) + 1)]
    return [x.strip() for x in spes.split(",") if x.strip()]


# --------------------------------------------------------------- mode: paket
def mode_paket(tingkat: str, tugas_spec: str | None, fase: str | None, semua: bool = False) -> int:
    semua = baca_tugas_roadmap()
    if not semua:
        print("GAGAL: tidak bisa membaca tugas dari docs/ROADMAP.md")
        return 1
    if tugas_spec:
        ids = pisah_rentang(tugas_spec)
    elif semua:
        # audit menyeluruh = SELURUH tugas (bukan sampel)
        ids = sorted(semua.keys(), key=lambda x: (int(x[1:].split("-")[0]), int(x.split("-")[1])))
    elif fase:
        ids = sorted([t for t in semua if t.startswith(f"T{fase}-")])
    else:
        # bawaan: 10 tugas terakhir yang sudah [x]
        teks = ROADMAP.read_text(encoding="utf-8")
        selesai = re.findall(r"^- \[x\] (T\d+-\d+) —", teks, re.M)
        ids = selesai[-10:]
    ids = [t for t in ids if t in semua]
    if not ids:
        print(f"GAGAL: tidak ada tugas yang cocok ({tugas_spec or fase})")
        return 1

    berkas: list[str] = []
    klaim: list[tuple[str, str]] = []
    for t in ids:
        isi = semua[t]
        for f in re.findall(r"`([^`]+\.(?:sql|ts|tsx|py|mjs|yml|json|md))`", isi):
            if f not in berkas and ("/" in f):
                berkas.append(f)
        for m in re.finditer(r"\*\*Bukti[^*]*:\*\*(.+?)(?=\n  - \*\*|\Z)", isi, re.S):
            isi_klaim = " ".join(m.group(1).split())
            if len(isi_klaim) >= 40:
                klaim.append((t, isi_klaim[:320]))

    _, sha_all = jalankan(["git", "rev-parse", "HEAD"])
    sha = sha_all.strip()
    tanggal = dt.date.today().isoformat()
    DIR_PAKET.mkdir(parents=True, exist_ok=True)
    keluar = DIR_PAKET / f"{tingkat}-{tanggal}.md"

    # pre-flight: mesin mana yang benar-benar bisa jalan sekarang (bukti harus bisa direproduksi auditor)
    siap: list[str] = []
    if (AKAR / "alat" / "node_modules" / "@electric-sql").exists():
        siap.append("UJI SQL (PGlite) — `node alat/uji-sql.mjs`")
    else:
        siap.append("⚠️ UJI SQL TIDAK SIAP — jalankan `npm ci --prefix alat` lebih dulu (kalau tidak, bukti SQL tidak bisa direproduksi)")
    if (AKAR / "aplikasi" / "node_modules").exists():
        siap.append("uji unit/komponen — `cd aplikasi && npm test`")
    else:
        siap.append("⚠️ uji aplikasi TIDAK SIAP — jalankan `npm ci --prefix aplikasi` lebih dulu")
    siap.append("pemeriksa Python — selalu siap")

    lensa = LENSA_MINIMUM[tingkat]
    grup, dikecualikan = kelompokkan_berkas()
    total_proyek = sum(len(v) for v in grup.values())
    blok_menyeluruh = ""
    if semua:
        baris_grup = "\n".join(
            f"| {nama} | {ket} | {len(v)} | {', '.join('`'+x+'`' for x in v[:2])}{' …' if len(v) > 2 else ''} |"
            for nama, ket, _ in GRUP_SEMUA for v in [grup[nama]]
        )
        baris_kecuali = "\n".join(f"- `{nama}` ({n} berkas) — {alasan}" for nama, alasan in DIKECUALIKAN for n in [dikecualikan[nama]])
        blok_menyeluruh = f"""
## 0. LINGKUP MENYELURUH (wajib — audit ini memeriksa SEMUA berkas proyek)

- **Jumlah berkas dalam lingkup:** {total_proyek}
- **Mode cakupan yang wajib kamu tulis di laporan:** `menyeluruh`

**Grup berkas yang wajib kamu sentuh (minimal satu baris bukti per grup):**

| Grup | Isi | Jumlah berkas | Contoh |
|---|---|---|---|
{baris_grup}

**Dikecualikan dari lingkup (dan wajib kamu setujui/tolak dengan alasan):**

{baris_kecuali}

**Kewajiban khusus mode menyeluruh (divalidasi mesin):**
1. Tulis di kepala laporan: `- **Mode cakupan:** menyeluruh`.
2. Tulis ringkasan: `Cakupan menyeluruh: X dari {total_proyek} berkas` (X = berkas yang benar-benar kamu periksa; angka ini diperiksa mesin).
3. Bagian 1 harus memuat **setiap grup** di atas minimal satu baris (dengan bukti perintah/baris).
4. Tambahkan sub-bagian `### 1a. Berkas untuk pengguna` (minimal 3 baris): berkas pengguna di akar (PANDUAN_*, PROMPT_*, START_DI_SINI, PROFIL_PENGGUNA, AGENT_SYSTEM, STATUS, PROJECT_STATE), `docs/PANDUAN_PEMILIK.md`, `docs/uji/PROMPT_AUDIT_INDEPENDEN.md`,
   `docs/teknis/BUKU_INSIDEN.md`, `docs/ops/*`, dan `PANDUAN_PENGGUNA.md` → **periksa dengan cara pengguna**: apakah langkahnya bisa diikuti orang non-teknis, apakah prompt bisa disalin apa adanya dan bekerja, apakah ada langkah yang menyebut berkas/perintah yang tidak ada, apakah isi buku induk lengkap (semua mekanisme & semua prompt ada).
5. Auditor yang **tidak** memeriksa berkas untuk pengguna dianggap **belum menyeluruh** dan laporannya ditolak.
"""
    if semua:
        bahan = sorted((AKAR / "docs" / "uji" / "kalibrasi").glob("bahan-*")) if (AKAR / "docs" / "uji" / "kalibrasi").is_dir() else []
        daftar_bahan = "\n".join(f"- `{b.relative_to(AKAR)}/` ({len(list(b.rglob('*')))} berkas)" for b in bahan) or "- (BELUM ADA bahan kalibrasi — laporkan ke pemilik: AUD-3 tanpa kalibrasi tidak sah)"
        blok_menyeluruh += f"""
## 0b. Kalibrasi cacat tanaman (wajib untuk AUD-3 — jangan dilewati)

Folder bahan kalibrasi **berisi cacat yang disengaja** (defect injection). Tugasmu: temukan cacat itu.

{daftar_bahan}

Aturan main (dikutip dari `docs/uji/kalibrasi/CARA-PAKAI.md`):
1. Kamu **tidak** diberi tahu berapa jumlah cacatnya, di berkas mana, atau kelasnya. Periksa seperti kode/dokumen sungguhan.
2. Cacat di folder `bahan-*/` **tidak dihitung** sebagai temuan proyek — tulis hasilnya terpisah di `## 5. Kalibrasi cacat tanaman`.
3. Format bagian 5: `Ditemukan: X dari Y` (Y = jumlah cacat yang kamu yakini ada), daftar cacat temuanmu (berkas + kelas + bukti), dan jumlah **temuan palsu** (yang kamu klaim cacat padahal bukan).
4. **Dilarang mencari kunci jawaban** (ada di luar repo). Menemukan/memakai kunci = kalibrasi batal dan wajib kamu laporkan.

Ambang lulus (dinilai pembangun setelah laporan masuk): semua cacat K-1/K-2 tertanam ditemukan + ≥70% total + 0 temuan palsu.
"""
    baris_berkas = "\n".join(f"| {i+1} | `{b}` |" for i, b in enumerate(berkas)) or "| 1 | (tidak ada berkas terbaca — periksa manual) |"
    baris_klaim = "\n".join(f"| {i+1} | {t} | {k} |" for i, (t, k) in enumerate(klaim)) or "| 1 | — | (tidak ada klaim Bukti pada tugas terpilih) |"
    baris_lensa = "\n".join(f"- **{k} {LENSA[k][0]}** — {LENSA[k][1]}" for k in lensa)
    baris_skill = "\n".join(f"| `{p}` | {n} |" for p, n in SKILL_WAJIB)

    isi_paket = f"""# PAKET AUDIT INDEPENDEN — {tingkat} — {tanggal}

> Dibuat mesin oleh `alat/audit-independen.py`. Berkas ini **untuk auditor** (sesi baru, model berbeda, hanya-baca).
> Aturan penuh: `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md`.

- **Tingkat audit:** {tingkat}
- **Commit yang diaudit:** `{sha}`
- **Tugas dalam lingkup:** {", ".join(ids)}
- **Lensa wajib:** {", ".join(lensa)}
- **Mode cakupan:** {"menyeluruh" if semua else "terarah"}
- **Minimum laporan:** ≥{len(grup) if semua else 6} artefak diperiksa · ≥5 klaim dibantah · ≥{SERANGAN_MIN[tingkat]} serangan dijalankan · masing-masing temuan punya perintah bukti
- **Perintah validasi laporan (wajib hijau):** periksa dengan alat `alat/audit-independen.py --periksa-laporan` (berkas laporan ditulis di folder docs/uji/audit/). Bila repo yang kamu pakai adalah klon dangkal, alat akan memberi CATATAN (bukan menolak) untuk SHA yang riwayatnya tidak ada.

## ATURAN INDEPENDENSI (tidak bisa ditawar)

1. Kamu **hanya-baca**: dilarang mengubah/memperbaiki berkas apa pun (temuan ditulis, bukan dibetulkan).
2. Tugasmu **membantah** klaim pembangun di bawah — bukan mempercayainya.
3. Dilarang memuji, dilarang "looks good", dilarang melaporkan soal gaya penulisan sebagai temuan.
4. Setiap calon temuan wajib kamu **uji ulang** di kode sekarang (buka berkas, telusuri pemanggil, jalankan perintah).
   Tidak bisa dibuktikan → tandai **DUGAAN**, bukan TERVERIFIKASI.
5. Istilah tingkat: **K-1** = uang salah/data bocor/tak bisa dipulihkan; **K-2** = janji PRD/ART/KEAMANAN dilanggar atau kontrol wajib hilang;
   **K-3** = tidak konsisten / uji kurang / dokumen basi; **K-4** = kerapian, tidak menghambat.
6. Verdict: `BERSIH` / `BERSIH-DENGAN-CATATAN` / `TIDAK-BERSIH`. **Ada K-1/K-2 TERVERIFIKASI → verdict wajib TIDAK-BERSIH.**

{blok_menyeluruh}
## 1. Artefak yang harus diperiksa (minimal)

| # | Berkas |
|---|---|
{baris_berkas}

## 2. Klaim pembangun yang harus kamu coba bantah

| # | Tugas | Klaim "Bukti" |
|---|---|---|
{baris_klaim}

## 3. Lensa wajib (jalankan semua, satu bagian per lensa)

{baris_lensa}

## 4. Perintah bukti yang disarankan

```
{chr(10).join(PERINTAH_BUKTI)}
```

**Kesiapan mesin saat paket ini dibuat (dicek otomatis):**

{chr(10).join(f"- {s}" for s in siap)}

Bila ada yang bertanda ⚠️, **laporkan sebagai keterbatasan** (bagian 6 laporan) dan jangan menyimpulkan sesuatu
yang tidak bisa kamu uji. Jangan memasang apa pun (kamu hanya-baca) — cukup laporkan.

## 5. Skill yang wajib kamu muat lebih dulu

| Berkas | Kegunaan |
|---|---|
{baris_skill}

Kamu juga **wajib**: (a) memakai `skills/find-skills` atau `skills/agent-skills-hub` bila butuh skill lain;
(b) mencari referensi internet bila menyimpulkan perilaku sistem luar (Supabase/PostgreSQL/OWASP) dan **mencantumkan tautannya**.

## 6. Format laporan (salin apa adanya, isi bagiannya)

```markdown
# LAPORAN AUDIT INDEPENDEN — {tingkat} — {tanggal}

- **Auditor:** <nama sesi/model yang benar-benar dipakai>
- **Tanggal:** {tanggal}
- **Tingkat audit:** {tingkat}
- **Commit yang diaudit:** `{sha}`
- **Paket audit:** `{keluar.relative_to(AKAR)}`
- **Mode cakupan:** {"menyeluruh" if semua else "terarah"}
- **Verdict:** BERSIH | BERSIH-DENGAN-CATATAN | TIDAK-BERSIH

## 1. Cakupan
{"Cakupan menyeluruh: X dari Y berkas (ganti angka sesuai kenyataan) — WAJIB untuk mode menyeluruh" if semua else ""}
| # | Artefak | Diperiksa | Bukti (perintah/baris) |
|---|---|---|---|

## 2. Klaim pembangun yang saya coba falsifikasi
| # | Klaim (lokasi) | Cara uji | Hasil |
|---|---|---|---|

## 3. Serangan yang dijalankan (kill attempts)
| # | Skenario | Cara | Hasil |
|---|---|---|---|

## 4. Temuan
### [F-01] <judul singkat>
- **Tingkat:** K-2
- **Artefak:** `berkas:baris`
- **Klaim yang dilanggar:** …
- **Bukti:** `perintah` → hasil nyata
- **Skenario gagal:** langkah → dampak
- **Dugaan penyebab:** …
- **Cara membuktikan perbaikan:** `perintah yang harus hijau`
- **Status verifikasi:** TERVERIFIKASI

(atau tulis: (tidak ada temuan))

## 5. Kalibrasi cacat tanaman
(wajib untuk AUD-3 — lihat instruksi terpisah dari pembangun)

## 6. Yang tidak bisa saya verifikasi
- …

## 7. Pernyataan tidak mengubah apa pun
Saya hanya-baca dan tidak mengubah berkas apa pun. Bukti: `git status --short` kosong.
```

## 7. Kalibrasi cacat tanaman (khusus AUD-3)

Pembangun menyiapkan salinan berisi **cacat yang sengaja ditanam** dan menyimpan kunci jawabannya di luar repo.
Catatan: di **salinan kalibrasi** `git status` memang **tidak** bersih (itu cacatnya) — aturan "repo bersih" hanya berlaku di repo kerja saat laporannya diperiksa.
Instruksi & jalur salinan akan disampaikan bersama paket ini. Isi bagian 5 laporan dengan daftar cacat yang kamu temukan
(`berkas` + penjelasan singkat) dan jumlah temuan palsu. **Kalibrasi ini menentukan apakah verdict BERSIH-mu boleh dipercaya.**
"""
    keluar.write_text(isi_paket, encoding="utf-8")
    print(f"PAKET AUDIT dibuat: {keluar.relative_to(AKAR)}")
    print(f"  tugas       : {len(ids)} ({', '.join(ids[:3])}{'…' if len(ids) > 3 else ''})")
    print(f"  berkas      : {len(berkas)}")
    print(f"  klaim Bukti : {len(klaim)}")
    return 0


# ------------------------------------------------- mode: periksa laporan
BIDANG_TEMUAN = [
    "Tingkat", "Artefak", "Klaim yang dilanggar", "Bukti", "Skenario gagal",
    "Dugaan penyebab", "Cara membuktikan perbaikan", "Status verifikasi",
]


def _tabel_baris(teks: str, judul: str) -> list[list[str]]:
    """Ambil baris tabel markdown di bawah judul bagian tertentu."""
    m = re.search(rf"^{re.escape(judul)}\s*$", teks, re.M)
    if not m:
        return []
    sisa = teks[m.end():]
    n = re.search(r"^## ", sisa, re.M)
    blok = sisa[: n.start()] if n else sisa
    baris: list[list[str]] = []
    for ln in blok.splitlines():
        ln = ln.strip()
        if not ln.startswith("|"):
            continue
        sel = [s.strip() for s in ln.strip("|").split("|")]
        if all(set(s) <= set("-: ") for s in sel if s):
            continue
        if sel and sel[0].lower().startswith("#"):
            continue
        baris.append(sel)
    return baris


def periksa_laporan(berkas: pathlib.Path, cek_git: bool = True, cek_sha: bool = True) -> tuple[int, list[str], list[str], dict]:
    teks = berkas.read_text(encoding="utf-8")
    gagal: list[str] = []
    catatan: list[str] = []
    angka: dict = {}

    # kepala
    for label in ["**Auditor:**", "**Tanggal:**", "**Tingkat audit:**", "**Commit yang diaudit:**",
                  "**Paket audit:**", "**Verdict:**"]:
        if label not in teks:
            gagal.append(f"kepala laporan tidak lengkap: {label} hilang")

    sha_m = re.search(r"- \*\*Commit yang diaudit:\*\*\s*`?([0-9a-f]{7,40})`?", teks)
    if not sha_m:
        gagal.append("SHA commit yang diaudit tidak ditemukan")
        sha = ""
    else:
        sha = sha_m.group(1)
        if len(sha) != 40:
            gagal.append(f"SHA commit harus 40 digit (tertulis: {sha})")
        if cek_sha:
            rc, _ = jalankan(["git", "cat-file", "-e", f"{sha}^{{commit}}"])
            if rc != 0:
                # Klon dangkal (CI / sesi baru) tidak membawa seluruh riwayat → bukan cacat laporan.
                dangkal = (AKAR / ".git" / "shallow").is_file()
                if dangkal:
                    catatan.append(f"SHA {sha[:8]} tidak bisa diverifikasi di klon dangkal — verifikasi riwayat penuh saat audit sungguhan")
                else:
                    gagal.append(f"SHA {sha} tidak ada di repo ini (audit harus menunjuk commit nyata)")

    verdict_m = re.search(r"- \*\*Verdict:\*\*\s*`?(BERSIH-DENGAN-CATATAN|TIDAK-BERSIH|BERSIH)`?", teks)
    verdict = verdict_m.group(1) if verdict_m else ""
    if not verdict:
        gagal.append("Verdict harus salah satu: BERSIH / BERSIH-DENGAN-CATATAN / TIDAK-BERSIH")

    tingkat_m = re.search(r"- \*\*Tingkat audit:\*\*\s*`?(AUD-[23])`?", teks)
    tingkat = tingkat_m.group(1) if tingkat_m else ""
    if not tingkat:
        gagal.append("Tingkat audit harus AUD-2 atau AUD-3")

    # tujuh bagian
    bagian = ["## 1. Cakupan", "## 2. Klaim pembangun yang saya coba falsifikasi",
              "## 3. Serangan yang dijalankan (kill attempts)", "## 4. Temuan",
              "## 5. Kalibrasi cacat tanaman", "## 6. Yang tidak bisa saya verifikasi",
              "## 7. Pernyataan tidak mengubah apa pun"]
    for b in bagian:
        if b not in teks:
            gagal.append(f"bagian wajib hilang: {b}")

    # cakupan
    cakupan = _tabel_baris(teks, "## 1. Cakupan")
    angka["artefak"] = len(cakupan)
    menyeluruh = bool(re.search(r"- \*\*Mode cakupan:\*\*\s*`?menyeluruh`?", teks))
    angka["menyeluruh"] = menyeluruh
    if len(cakupan) < 6:
        gagal.append(f"cakupan terlalu sedikit: {len(cakupan)} artefak (minimum 6)")

    if menyeluruh:
        # 1. ringkasan jumlah berkas wajib & dibandingkan dengan paket
        ringkas_m = re.search(r"Cakupan menyeluruh:\s*(\d+)\s*dari\s*(\d+)\s*berkas", teks)
        if not ringkas_m:
            gagal.append("mode menyeluruh: wajib memuat 'Cakupan menyeluruh: X dari Y berkas'")
        else:
            x, y = int(ringkas_m.group(1)), int(ringkas_m.group(2))
            angka["cakupan_menyeluruh"] = (x, y)
            paket_m = re.search(r"- \*\*Paket audit:\*\*\s*`?([^`\n]+)`?", teks)
            if paket_m:
                berkas_paket = AKAR / paket_m.group(1).strip()
                if berkas_paket.is_file():
                    isi_paket = berkas_paket.read_text(encoding="utf-8")
                    n_m = re.search(r"- \*\*Jumlah berkas dalam lingkup:\*\*\s*(\d+)", isi_paket)
                    if n_m and int(n_m.group(1)) != y:
                        gagal.append(f"mode menyeluruh: jumlah berkas di laporan ({y}) ≠ paket ({n_m.group(1)})")
                    grup_paket = re.findall(r"^\| ([^|]+?) \| [^|]+ \| (\d+) \|", isi_paket, re.M)
                    teks_cakupan = teks.split("## 1. Cakupan")[-1].split("## 2.")[0]
                    for nama, _jml in grup_paket:
                        nama = nama.strip()
                        if nama and nama not in teks_cakupan:
                            gagal.append(f"mode menyeluruh: grup '{nama}' tidak muncul di tabel cakupan")
                else:
                    catatan.append("paket audit tidak ditemukan — grup berkas tidak bisa dicocokkan")
            if y and x / y < 0.9:
                gagal.append(f"mode menyeluruh: baru {x}/{y} berkas ({x/y*100:.0f}%) — minimum 90%")
        # 2. berkas untuk pengguna wajib diperiksa
        if "### 1a. Berkas untuk pengguna" not in teks:
            gagal.append("mode menyeluruh: wajib ada sub-bagian '### 1a. Berkas untuk pengguna'")
        else:
            baris_pengguna = _tabel_baris(teks, "### 1a. Berkas untuk pengguna")
            angka["berkas_pengguna"] = len(baris_pengguna)
            if len(baris_pengguna) < 3:
                gagal.append(f"mode menyeluruh: berkas untuk pengguna baru {len(baris_pengguna)} baris (minimum 3)")
    for i, baris in enumerate(cakupan, 1):
        if len(baris) < 3 or not baris[-1]:
            gagal.append(f"cakupan baris {i}: kolom bukti kosong")
        elif "`" not in baris[-1] and not re.search(r"\.\w{2,4}:\d+", baris[-1]):
            gagal.append(f"cakupan baris {i}: bukti harus berupa perintah ber-backtick atau berkas:baris")

    # klaim
    klaim = _tabel_baris(teks, "## 2. Klaim pembangun yang saya coba falsifikasi")
    angka["klaim"] = len(klaim)
    if len(klaim) < 5:
        gagal.append(f"klaim yang dibantah terlalu sedikit: {len(klaim)} (minimum 5)")

    # serangan
    serangan = _tabel_baris(teks, "## 3. Serangan yang dijalankan (kill attempts)")
    angka["serangan"] = len(serangan)
    minimum = SERANGAN_MIN.get(tingkat, 5)
    if len(serangan) < minimum:
        gagal.append(f"serangan terlalu sedikit: {len(serangan)} (minimum {minimum} untuk {tingkat or 'AUD-2'})")

    # temuan
    blok_temuan = re.split(r"^### \[F-", teks, flags=re.M)[1:]
    temuan: list[tuple[str, str, str]] = []  # (id, tingkat, status)
    if "(tidak ada temuan)" in teks:
        blok_temuan = []
    angka["temuan"] = len(blok_temuan)
    for blok in blok_temuan:
        kode = blok.split("]", 1)[0]
        for bidang in BIDANG_TEMUAN:
            if f"**{bidang}:**" not in blok:
                gagal.append(f"temuan F-{kode}: bidang '{bidang}' hilang")
        t_m = re.search(r"\*\*Tingkat:\*\*\s*(K-[1-4])", blok)
        s_m = re.search(r"\*\*Status verifikasi:\*\*\s*(TERVERIFIKASI|DUGAAN)", blok)
        if not t_m:
            gagal.append(f"temuan F-{kode}: tingkat harus K-1…K-4")
        if not s_m:
            gagal.append(f"temuan F-{kode}: status verifikasi harus TERVERIFIKASI atau DUGAAN")
        if t_m and s_m:
            temuan.append((f"F-{kode}", t_m.group(1), s_m.group(1)))
        if s_m and s_m.group(1) == "TERVERIFIKASI":
            b_m = re.search(r"\*\*Bukti:\*\*\s*(.+)", blok)
            if not b_m or "`" not in b_m.group(1):
                gagal.append(f"temuan F-{kode}: TERVERIFIKASI wajib punya perintah bukti ber-backtick")
        if t_m and t_m.group(1) in ("K-1", "K-2"):
            sg = re.search(r"\*\*Skenario gagal:\*\*\s*(.+)", blok)
            if not sg or len(sg.group(1).strip()) < 15:
                gagal.append(f"temuan F-{kode}: K-1/K-2 wajib punya skenario gagal yang jelas")

    # konsistensi verdict
    berat_terverifikasi = [t for t in temuan if t[1] in ("K-1", "K-2") and t[2] == "TERVERIFIKASI"]
    if berat_terverifikasi and verdict != "TIDAK-BERSIH":
        gagal.append(f"verdict '{verdict}' tidak konsisten: ada {len(berat_terverifikasi)} temuan K-1/K-2 TERVERIFIKASI")

    # kalibrasi (AUD-3)
    kal = re.search(r"Ditemukan:\s*(\d+)\s*dari\s*(\d+)", teks)
    angka["kalibrasi"] = kal.groups() if kal else None
    if tingkat == "AUD-3":
        if not kal:
            gagal.append("AUD-3 wajib memuat 'Ditemukan: X dari Y' pada bagian 5 (kalibrasi cacat tanaman)")
        else:
            x, y = int(kal.group(1)), int(kal.group(2))
            if verdict == "BERSIH":
                if x != y:
                    gagal.append(f"verdict BERSIH tidak sah: cacat tanaman hanya {x}/{y} ditemukan")
                if re.search(r"[Tt]emuan palsu.*?([1-9]\d*)", teks):
                    gagal.append("verdict BERSIH tidak sah sementara masih ada temuan palsu")
                if y and x / y < 0.7:
                    gagal.append(f"tingkat deteksi {x}/{y} < 70% — auditor belum terkailbrasi")

    # batas jujur
    bagian6 = teks.split("## 6. Yang tidak bisa saya verifikasi")[-1].split("## 7.")[0]
    if not re.search(r"^[-*]\s+\S", bagian6, re.M):
        gagal.append("bagian 6 wajib memuat minimal satu butir (jujur soal batas)")

    # pernyataan hanya-baca
    bagian7 = teks.split("## 7. Pernyataan tidak mengubah apa pun")[-1]
    if "tidak mengubah" not in bagian7.lower():
        gagal.append("bagian 7 wajib memuat pernyataan 'tidak mengubah apa pun'")
    if cek_git:
        _, status = jalankan(["git", "status", "--porcelain"])
        if status.strip():
            gagal.append("repo TIDAK bersih saat laporan diperiksa — auditor wajib hanya-baca (git status kosong)")

    # commit berbeda dari HEAD
    if sha:
        _, head = jalankan(["git", "rev-parse", "HEAD"])
        if head.strip() != sha:
            alasan = re.search(r"- \*\*Alasan commit berbeda:\*\*\s*(.+)", teks)
            if not alasan or len(alasan.group(1).strip()) < 10:
                catatan.append(f"commit diaudit ({sha[:8]}) ≠ HEAD ({head.strip()[:8]}) — wajib ada 'Alasan commit berbeda'")
    return (1 if gagal else 0), gagal, catatan, angka


def mode_periksa_laporan(berkas_str: str, cek_git: bool = True) -> int:
    berkas = AKAR / berkas_str if not pathlib.Path(berkas_str).is_absolute() else pathlib.Path(berkas_str)
    if not berkas.is_file():
        print(f"GAGAL: laporan tidak ada: {berkas}")
        return 1
    kode, gagal, catatan, angka = periksa_laporan(berkas, cek_git=cek_git)
    print(f"PERIKSA LAPORAN AUDIT — {berkas.name}")
    print(f"  artefak diperiksa : {angka.get('artefak')}")
    print(f"  klaim dibantah    : {angka.get('klaim')}")
    print(f"  serangan          : {angka.get('serangan')}")
    print(f"  temuan            : {angka.get('temuan')}")
    if angka.get("menyeluruh"):
        print(f"  mode              : menyeluruh")
        if angka.get("cakupan_menyeluruh"):
            x, y = angka["cakupan_menyeluruh"]
            print(f"  cakupan berkas    : {x}/{y} ({x/y*100:.0f}%)" if y else "  cakupan berkas    : -")
        print(f"  berkas pengguna   : {angka.get('berkas_pengguna', 0)} baris")
    if angka.get("kalibrasi"):
        print(f"  kalibrasi         : {angka['kalibrasi'][0]}/{angka['kalibrasi'][1]} cacat ditemukan")
    for c in catatan:
        print(f"  CATATAN: {c}")
    if kode == 0:
        print("\nHASIL: LOLOS KONTRAK — laporan boleh diakui sebagai hasil audit independen.")
    else:
        print(f"\nHASIL: DITOLAK ({len(gagal)} alasan) — laporan belum memenuhi kontrak:")
        for g in gagal:
            print(f"  - {g}")
    return kode


# ------------------------------------------------------------ mode: kalibrasi
def mode_kalibrasi_siapkan(jumlah: int | None) -> int:
    if not KATALOG.is_file():
        print(f"GAGAL: katalog cacat tidak ada: {KATALOG}")
        return 1
    cacat = json.loads(KATALOG.read_text(encoding="utf-8"))["cacat"]
    if jumlah:
        cacat = cacat[:jumlah]
    tanda = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    salinan = pathlib.Path(f"/tmp/audit-kalibrasi-{tanda}")
    kunci = pathlib.Path(f"/tmp/audit-kalibrasi-{tanda}-KUNCI.md")

    rc, keluaran = jalankan(["git", "worktree", "add", "--detach", str(salinan), "HEAD"])
    if rc != 0:
        print(f"GAGAL menyiapkan salinan: {keluaran}")
        return 1

    # PENTING (temuan audit 2026-09-17): salinan worktree tidak membawa node_modules,
    # sehingga uji SQL (`node alat/uji-sql.mjs`) GAGAL jalan dan auditor kehilangan alat bukti utama.
    # Perbaikan: tautkan folder pustaka (symlink, bukan salinan) supaya uji bisa dijalankan apa adanya.
    tautan: list[str] = []
    for rel in ("alat/node_modules", "aplikasi/node_modules"):
        asal = AKAR / rel
        tujuan = salinan / rel
        if asal.is_dir() and not tujuan.exists():
            tujuan.parent.mkdir(parents=True, exist_ok=True)
            tujuan.symlink_to(asal, target_is_directory=True)
            tautan.append(rel)

    baris_kunci: list[str] = []
    gagal: list[str] = []
    for c in cacat:
        berkas = salinan / c["berkas"]
        if not berkas.is_file():
            gagal.append(f"{c['id']}: berkas tidak ada {c['berkas']}")
            continue
        teks = berkas.read_text(encoding="utf-8")
        if teks.count(c["cari"]) < 1:
            gagal.append(f"{c['id']}: pola tidak ditemukan di {c['berkas']} (katalog basi!)")
            continue
        berkas.write_text(teks.replace(c["cari"], c["ganti"], 1), encoding="utf-8")
        baris_kunci.append(
            f"| {c['id']} | {c['tingkat']} | {c['kelas']} | `{c['berkas']}` | {c['ringkas']} | {c.get('harapan_mesin', '-')} | {c.get('katakunci', [])} |"
        )

    if gagal:
        jalankan(["git", "worktree", "remove", "--force", str(salinan)])
        print("GAGAL menyiapkan kalibrasi:")
        for g in gagal:
            print(f"  - {g}")
        return 1

    kunci.write_text(
        "# KUNCI JAWABAN KALIBRASI CACAT TANAMAN (JANGAN DIBACA AUDITOR)\n\n"
        f"- Salinan untuk auditor: `{salinan}`\n- Dibuat: {tanda}\n- Jumlah cacat: {len(cacat)}\n\n"
        "| ID | Tingkat | Kelas | Berkas | Ringkas | Diharapkan ketangkap mesin? | Katakunci |\n|---|---|---|---|---|---|---|\n"
        + "\n".join(baris_kunci) + "\n",
        encoding="utf-8",
    )
    print("KALIBRASI SIAP")
    print(f"  salinan auditor : {salinan}   (auditor memeriksa ini, bukan repo kerja)")
    print(f"  kunci jawaban   : {kunci}   (JANGAN dibaca auditor; dipakai setelah laporan masuk)")
    print(f"  jumlah cacat    : {len(cacat)}  ({', '.join(c['tingkat'] for c in cacat)})")
    if tautan:
        print(f"  pustaka ditautkan: {', '.join(tautan)} (supaya uji SQL bisa dijalankan auditor)")
    print("  setelah laporan masuk: python3 alat/audit-independen.py --kalibrasi-nilai <laporan> --kunci <kunci>")
    return 0


def mode_kalibrasi_nilai(laporan_str: str, kunci_str: str) -> int:
    laporan = pathlib.Path(laporan_str)
    kunci = pathlib.Path(kunci_str)
    if not laporan.is_file() or not kunci.is_file():
        print("GAGAL: laporan atau kunci tidak ditemukan")
        return 1
    teks = laporan.read_text(encoding="utf-8")
    bagian = teks.split("## 5. Kalibrasi cacat tanaman")[-1].split("## 6.")[0]
    isi_kunci = [l for l in kunci.read_text(encoding="utf-8").splitlines() if l.startswith("| P")]
    total = len(isi_kunci)
    ditemukan: list[str] = []
    per_tingkat: dict[str, list[int]] = {}
    for l in isi_kunci:
        sel = [s.strip() for s in l.strip("|").split("|")]
        pid, tingkat, berkas, katakunci = sel[0], sel[1], sel[3].strip("`"), sel[6]
        kata = [k.strip().strip("'\"") for k in katakunci.strip("[]").split(",") if k.strip()]
        kena = berkas in bagian and any(k.lower() in bagian.lower() for k in kata)
        per_tingkat.setdefault(tingkat, [0, 0])
        per_tingkat[tingkat][1] += 1
        if kena:
            ditemukan.append(pid)
            per_tingkat[tingkat][0] += 1
    # temuan palsu: baris tabel kalibrasi yang TIDAK menunjuk berkas cacat tanaman mana pun
    berkas_kunci = [sel[3].strip("`") for sel in ([s.strip() for s in l.strip("|").split("|")] for l in isi_kunci)]
    baris_tabel = _tabel_baris(teks, "## 5. Kalibrasi cacat tanaman")
    palsu = 0
    for b in baris_tabel:
        gab = " ".join(b)
        if b and b[0].startswith(("P", "X")) and not any(bk in gab for bk in berkas_kunci):
            palsu += 1
    rasio = len(ditemukan) / total if total else 0
    k12 = per_tingkat.get("K-1", [0, 0])[0] + per_tingkat.get("K-2", [0, 0])[0]
    k12_total = per_tingkat.get("K-1", [0, 0])[1] + per_tingkat.get("K-2", [0, 0])[1]
    print("NILAI KALIBRASI AUDITOR")
    print(f"  ditemukan : {len(ditemukan)}/{total}  ({rasio*100:.0f}%)")
    for t in sorted(per_tingkat):
        print(f"    {t}: {per_tingkat[t][0]}/{per_tingkat[t][1]}")
    print(f"  K-1/K-2   : {k12}/{k12_total} (wajib semua)")
    print(f"  temuan palsu: {palsu}")
    lulus = (k12 == k12_total) and rasio >= 0.7 and palsu == 0
    if lulus:
        print("\nHASIL: TERKALIBRASI — auditor terbukti menemukan cacat berat; verdict BERSIH-nya boleh dipercaya.")
    else:
        print("\nHASIL: BELUM TERKALIBRASI — verdict BERSIH tidak boleh dipercaya:")
        if k12 != k12_total:
            print(f"  - ada cacat K-1/K-2 yang tidak ditemukan ({k12}/{k12_total})")
        if rasio < 0.7:
            print(f"  - tingkat deteksi {rasio*100:.0f}% < 70%")
        if palsu:
            print(f"  - ada {palsu} temuan palsu (bukan cacat tanaman, dilaporkan sebagai temuan)")
    return 0 if lulus else 1


# ------------------------------------------------------------- mode: uji diri
def mode_uji_diri() -> int:
    harapan = {
        "laporan-bagus.md": 0,
        "laporan-malas.md": 1,
        "laporan-palsu-bersih.md": 1,
        "laporan-tanpa-kalibrasi.md": 1,
    }
    print("UJI DIRI — pemeriksa laporan audit (harus bisa LOLOS & harus bisa MENOLAK)")
    rusak = 0
    for nama, kode_harap in harapan.items():
        berkas = DIR_CONTOH / nama
        if not berkas.is_file():
            print(f"  GAGAL: contoh hilang: {nama}")
            rusak += 1
            continue
        # cek_sha=False: contoh laporan menunjuk commit historis; CI memakai klon dangkal (fetch-depth 1)
        kode, gagal, _, _ = periksa_laporan(berkas, cek_git=False, cek_sha=False)
        tanda = "OK" if kode == kode_harap else "SALAH"
        if kode != kode_harap:
            rusak += 1
        print(f"  [{tanda}] {nama}: hasil={kode} harapan={kode_harap} alasan={len(gagal)}")
        for g in gagal[:3]:
            print(f"         · {g}")
    # penilai kalibrasi juga wajib teruji (kode yang tidak diuji = kode yang tidak bisa dipercaya)
    kunci = DIR_CONTOH / "kunci-contoh.md"
    kasus_nilai = {
        "kalibrasi-penuh.md": 0,     # semua cacat ditemukan, tanpa temuan palsu → TERKALIBRASI
        "kalibrasi-sebagian.md": 1,  # ada cacat terlewat + temuan palsu → BELUM TERKALIBRASI
    }
    for nama, kode_harap in kasus_nilai.items():
        berkas = DIR_CONTOH / nama
        if not berkas.is_file() or not kunci.is_file():
            print(f"  GAGAL: contoh kalibrasi hilang: {nama} / {kunci.name}")
            rusak += 1
            continue
        kode = mode_kalibrasi_nilai(str(berkas), str(kunci))
        tanda = "OK" if kode == kode_harap else "SALAH"
        if kode != kode_harap:
            rusak += 1
        print(f"  [{tanda}] penilai kalibrasi · {nama}: hasil={kode} harapan={kode_harap}")

    if rusak:
        print(f"\nHASIL: GAGAL — {rusak} contoh berperilaku salah (mekanisme belum bisa dipercaya)")
        return 1
    print("\nHASIL: LOLOS — pemeriksa laporan & penilai kalibrasi terbukti bisa MENOLAK yang buruk dan MENERIMA yang baik.")
    return 0


# -------------------------------------------------------------------- CLI
def main() -> int:
    p = argparse.ArgumentParser(description="Mekanisme audit independen (paket · periksa laporan · kalibrasi · uji diri)")
    p.add_argument("--paket", choices=["AUD-2", "AUD-3"], help="buat paket audit untuk sesi auditor")
    p.add_argument("--tugas", help="rentang tugas, mis. T1-01..T1-10")
    p.add_argument("--fase", help="seluruh tugas satu fase, mis. 1")
    p.add_argument("--semua", action="store_true", help="mode menyeluruh: seluruh berkas proyek masuk lingkup (AUD-3)")
    p.add_argument("--periksa-laporan", dest="periksa", help="validasi laporan auditor")
    p.add_argument("--tanpa-cek-git", action="store_true", help="lewati pemeriksaan repo bersih")
    p.add_argument("--kalibrasi-siapkan", action="store_true", help="tanam cacat pada salinan HEAD")
    p.add_argument("--cacat", type=int, help="batasi jumlah cacat yang ditanam")
    p.add_argument("--kalibrasi-nilai", help="nilai laporan auditor terhadap kunci jawaban")
    p.add_argument("--kunci", help="berkas kunci jawaban")
    p.add_argument("--uji-diri", action="store_true", help="uji pemeriksa laporan")
    a = p.parse_args()

    if a.uji_diri:
        return mode_uji_diri()
    if a.paket:
        return mode_paket(a.paket, a.tugas, a.fase, semua=a.semua)
    if a.periksa:
        return mode_periksa_laporan(a.periksa, cek_git=not a.tanpa_cek_git)
    if a.kalibrasi_siapkan:
        return mode_kalibrasi_siapkan(a.cacat)
    if a.kalibrasi_nilai:
        if not a.kunci:
            print("GAGAL: --kalibrasi-nilai butuh --kunci")
            return 1
        return mode_kalibrasi_nilai(a.kalibrasi_nilai, a.kunci)
    p.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
