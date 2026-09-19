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
    # F-13 audit 2026-09-18: berkas di akar `supabase/` (mis. README.md) dulu TIDAK
    # punya grup — ia jatuh ke grup cadangan dan ikut terhitung sebagai `_sistem`
    # (klaim 16 vs nyata 15). Grup ini menutupnya.
    ("supabase (akar)", "berkas di akar supabase/ (README cara memasang migrasi)", "supabase/"),
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
    ("belum berggrup", "BERKAS YANG TIDAK COCOK GRUP MANA PUN — paket TIDAK dibuat selama ada isinya", "TIDAK_ADA"),
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
            if prefiks == "TIDAK_ADA":
                continue
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
            # F-13: dulu berkas yang tidak cocok grup apa pun DIAM-DIAM dimasukkan ke
            # `_sistem`/`aplikasi (konfigurasi)`, sehingga jumlah grup meleset tanpa suara.
            # Sekarang ada grup jujur "belum berggrup" — dan `mode_paket` MENOLAK membuat
            # paket selama grup itu tidak kosong.
            grup["belum berggrup"].append(b)
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
    # CATATAN PENTING (cacat nyata 2026-09-18): dulu baris pertama fungsi ini menimpa
    # parameter `semua` dengan daftar tugas (`semua = baca_tugas_roadmap()`), sehingga
    # (a) `--fase` selalu mengambil SELURUH tugas (cakupan melebar tanpa disadari) dan
    # (b) mode selalu dicap "menyeluruh". Nama dipisah: `daftar_tugas` (isi ROADMAP)
    # vs `menyeluruh` (pilihan cakupan dari pengguna).
    daftar_tugas = baca_tugas_roadmap()
    menyeluruh = bool(semua)
    if not daftar_tugas:
        print("GAGAL: tidak bisa membaca tugas dari docs/ROADMAP.md")
        return 1
    if tugas_spec:
        ids = pisah_rentang(tugas_spec)
    elif menyeluruh:
        # audit menyeluruh = SELURUH tugas (bukan sampel)
        ids = sorted(daftar_tugas.keys(), key=lambda x: (int(x[1:].split("-")[0]), int(x.split("-")[1])))
    elif fase:
        ids = sorted([t for t in daftar_tugas if t.startswith(f"T{fase}-")],
                     key=lambda x: (int(x[1:].split("-")[0]), int(x.split("-")[1])))
    else:
        # bawaan: 10 tugas terakhir yang sudah [x]
        teks = ROADMAP.read_text(encoding="utf-8")
        selesai = re.findall(r"^- \[x\] (T\d+-\d+) —", teks, re.M)
        ids = selesai[-10:]
    ids = [t for t in ids if t in daftar_tugas]
    if not ids:
        print(f"GAGAL: tidak ada tugas yang cocok ({tugas_spec or fase})")
        return 1
    # Nama lingkup dipakai di kepala paket & di perintah penamaan berkas laporan.
    lingkup = "menyeluruh" if menyeluruh else ("terarah" if not tugas_spec and not fase else "terarah")

    berkas: list[str] = []          # ADA di pohon sekarang → wajib diperiksa auditor
    berkas_rencana: list[tuple[str, str]] = []   # (berkas, tugas) → BELUM ada, jangan dicari
    klaim: list[tuple[str, str]] = []
    teks_roadmap = ROADMAP.read_text(encoding="utf-8")
    tugas_selesai = set(re.findall(r"^- \[x\] (T\d+-\d+) —", teks_roadmap, re.M))
    for t in ids:
        isi = daftar_tugas[t]
        for f in re.findall(r"`([^`]+\.(?:sql|ts|tsx|py|mjs|yml|json|md))`", isi):
            if "/" not in f:
                continue
            # F-12 audit 2026-09-18: dulu SEMUA jalur dari SEMUA tugas masuk daftar
            # "artefak yang harus diperiksa (minimal)" — termasuk berkas tugas `[ ]`
            # yang belum dikerjakan. 267 dari 354 jalur (75%) tidak ada di commit yang
            # diaudit, jadi auditor diarahkan mencari bukti yang tidak pernah ada.
            # Sekarang: yang ada → bagian 1; yang belum ada → bagian "direncanakan".
            if (AKAR / f).exists():
                if f not in berkas:
                    berkas.append(f)
            elif t in tugas_selesai:
                # tugas SUDAH [x] tetapi berkasnya tidak ada = cacat dokumen, tetap tampilkan
                berkas_rencana.append((f, t + " (sudah [x] — berkasnya TIDAK ADA: laporkan!)"))
            elif (f, t) not in berkas_rencana:
                berkas_rencana.append((f, t))
        for m in re.finditer(r"\*\*Bukti[^*]*:\*\*(.+?)(?=\n  - \*\*|\Z)", isi, re.S):
            isi_klaim = " ".join(m.group(1).split())
            if len(isi_klaim) >= 40:
                klaim.append((t, isi_klaim[:320]))

    # Celah keterlacakan F-12: ada berkas uji & pemeriksa NYATA yang tidak disebut
    # ROADMAP mana pun. Untuk audit menyeluruh, semuanya masuk daftar minimum.
    if menyeluruh:
        for f in sorted((AKAR / "supabase" / "tes").glob("*.sql")):
            rel = str(f.relative_to(AKAR))
            if rel not in berkas:
                berkas.append(rel)
        for f in sorted((AKAR / "alat").glob("*.py")):
            rel = str(f.relative_to(AKAR))
            if rel not in berkas:
                berkas.append(rel)

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
    if grup["belum berggrup"]:
        print("GAGAL: ada berkas yang tidak masuk grup mana pun — paket TIDAK dibuat.")
        print("  Sebabnya: angka lingkup di paket akan salah (F-13 audit 2026-09-18).")
        for b in grup["belum berggrup"][:20]:
            print(f"    - {b}")
        print("  Perbaikan: tambahkan grup untuk prefiks berkas itu di GRUP_SEMUA, lalu ulangi.")
        return 1
    total_proyek = sum(len(v) for v in grup.values())
    blok_menyeluruh = ""
    if menyeluruh:
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
    if menyeluruh:
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
    # F-12: jalur yang belum ada TIDAK BOLEH tampil sebagai "harus diperiksa".
    baris_rencana = "\n".join(f"| `{b}` | {t} |" for b, t in berkas_rencana) or "| — | (semua berkas yang dirujuk tugas sudah ada) |"
    blok_rencana = f"""
> **Catatan mesin (F-12 audit 2026-09-18):** daftar di atas SUDAH disaring — hanya berkas
> yang **benar-benar ada** di commit ini. Jalur yang baru *direncanakan* ada di bagian 1b.
> Kalau kamu menemukan jalur di bagian 1 yang tidak ada, laporkan sebagai temuan mesin.

## 1b. Direncanakan — berkas yang BELUM ADA (JANGAN diperiksa sebagai bukti)

| Jalur yang dirujuk dokumen | Tugas |
|---|---|
{baris_rencana}

Jangan menghabiskan anggaran mencari berkas di tabel ini; pakai daftarnya hanya untuk menilai
apakah dokumen menjanjikan sesuatu yang belum ada.
"""
    baris_klaim = "\n".join(f"| {i+1} | {t} | {k} |" for i, (t, k) in enumerate(klaim)) or "| 1 | — | (tidak ada klaim Bukti pada tugas terpilih) |"
    baris_lensa = "\n".join(f"- **{k} {LENSA[k][0]}** — {LENSA[k][1]}" for k in lensa)
    baris_skill = "\n".join(f"| `{p}` | {n} |" for p, n in SKILL_WAJIB)

    isi_paket = f"""# PAKET AUDIT INDEPENDEN — {tingkat} — {tanggal}

> Dibuat mesin oleh `alat/audit-independen.py`. Berkas ini **untuk auditor** (sesi baru, model berbeda, hanya-baca).
> Aturan penuh: `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md`.

> **CARA PAKAI — untuk pemilik (3 langkah, mudah):**
> 1. Buka **chat/percakapan BARU** (kalau bisa pilih **model yang berbeda** dari sesi kerja).
> 2. Salin **SELURUH isi berkas ini** ke chat baru itu.
> 3. Susulkan **kalimat pembuka auditor** dari buku induk `PANDUAN_PENGGUNA.md` **Bagian C4** (sama persis dengan
>    `docs/uji/PROMPT_AUDIT_INDEPENDEN.md` bagian B) — satu blok, apa adanya, tidak perlu diubah.
> Setelah auditor selesai, kembali ke sesi kerja dan bilang: **"Laporan audit sudah masuk, periksa."**

- **Tingkat audit:** {tingkat}
- **Commit yang diaudit:** `{sha}` (commit tepat sebelum berkas paket ini dibuat; auditor boleh mencatat commit yang benar-benar ia periksa — tulis apa adanya, jangan dibulatkan ke commit lain)
- **Tugas dalam lingkup:** {", ".join(ids)}
- **Lensa wajib:** {", ".join(lensa)}
- **Mode cakupan:** {lingkup}
- **Minimum laporan:** ≥{len(grup) if menyeluruh else 6} artefak diperiksa · ≥5 klaim dibantah · ≥{SERANGAN_MIN[tingkat]} serangan dijalankan · masing-masing temuan punya perintah bukti
- **Perintah validasi laporan (wajib hijau):** periksa dengan alat `alat/audit-independen.py --periksa-laporan` (berkas laporan ditulis di folder docs/uji/audit/). Bila repo yang kamu pakai adalah klon dangkal, alat akan memberi CATATAN (bukan menolak) untuk SHA yang riwayatnya tidak ada.

## 0a. LANGKAH 0 (WAJIB) — pastikan kamu memeriksa commit yang benar

Paket ini menargetkan commit **`{sha}`**. **Cabang/base apa pun yang Lee pilih tidak masalah** — yang menentukan adalah commit-nya.

```
# (a) di repo ini, satu perintah memeriksa semuanya:
python3 alat/audit-independen.py --verifikasi-lingkup

# (b) atau manual:
git rev-parse HEAD                 # commit yang sedang kamu lihat
git cat-file -e {sha}            # apakah commit target ada di repo ini?
```

- **Sama** (`HEAD` = `{sha}`) → langsung lanjut.
- **Berbeda tetapi commit target ada** → pindah hanya-baca lalu lanjut (aman, tidak mengubah apa pun):
  `git fetch origin && git checkout --detach {sha}`
- **Commit target tidak ada** → coba `git fetch origin` sekali lagi. Kalau tetap tidak ada, **JANGAN mengaudit commit lain**:
  tulis di bagian "Yang tidak bisa saya verifikasi" dan hentikan (minta Lee membuka sesi dari sumber yang benar).
- Tulis di kepala laporan: `- **Commit yang diaudit:** <commit yang benar-benar kamu periksa>`.

## 0c. Setelah laporan selesai — kirim ke sesi kerja (wajib)

Beri nama berkas dengan **penanda sesimu** di belakang supaya dua sesi auditor tidak bertabrakan
(kejadian nyata 2026-09-17: dua sesi memilih nama yang sama sehingga laporan pertama nyaris tertimpa):

```
docs/uji/audit/LAPORAN_{tingkat}_{tanggal}_{lingkup}__<penanda-sesi>.md
```
`<penanda-sesi>` = potongan nama cabang sesimu, mis. `01a0aeb4` (lihat `git branch --show-current`).

Laporan harus menjadi **berkas di Git**, bukan hanya teks di chat:

```
git add docs/uji/audit/ && git commit -m "laporan audit {tingkat} <lingkup>" && git push -u origin HEAD
```

Hanya berkas laporan yang di-commit. Bila push tidak bisa, tulis "belum ter-push" di laporan + beri tahu Lee di chat.

## ATURAN INDEPENDENSI (tidak bisa ditawar)

1. Kamu **hanya-baca**: SATU-SATUNYA berkas yang boleh kamu buat adalah laporan (§6 format laporan). Selain berkas itu,
   jangan mengubah/memperbaiki apa pun (temuan ditulis, bukan dibetulkan).
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

{blok_rencana}
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
- **Commit yang diaudit:** `{sha}` (commit tepat sebelum berkas paket ini dibuat; auditor boleh mencatat commit yang benar-benar ia periksa — tulis apa adanya, jangan dibulatkan ke commit lain)
- **Paket audit:** `{keluar.relative_to(AKAR)}`
- **Mode cakupan:** {lingkup}
- **Verdict:** BERSIH | BERSIH-DENGAN-CATATAN | TIDAK-BERSIH

## 1. Cakupan
{"Cakupan menyeluruh: X dari Y berkas (ganti angka sesuai kenyataan) — WAJIB untuk mode menyeluruh" if menyeluruh else ""}
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
Saya hanya-baca. SATU-SATUNYA berkas yang saya buat adalah laporan ini; tidak ada berkas lain yang saya ubah.
Bukti: perintah `git status --short` yang saya jalankan menampilkan hanya berkas laporan ini.

## 8. Temuan di luar cakupan (WAJIB — boleh "tidak ada")
| # | Temuan | Mengapa di luar cakupan | Bukti | Syarat dilanjutkan ke audit lain |
|---|---|---|---|---|
```

**Aturan penulisan laporan (ditegakkan, bukan imbauan):**
- **Ambang minimum adalah LANTAI, bukan target.** Jangan berhenti setelah mencapai angka minimum, dan jangan
  menambah baris demi memenuhi syarat. Kalau kamu menemukan 30 hal, tulis 30.
- **Semua temuan wajib dilaporkan — termasuk yang di luar cakupan/lingkup tugas.** Cakupan menentukan sedalam apa
  sesuatu **wajib** diperiksa, bukan apa yang **boleh** kamu laporkan. Temuan yang tidak masuk lensa/cakupan tetap
  masuk **bagian 8** dengan buktinya, supaya tidak hilang.
- **Jangan menyusun laporan agar lolos pemeriksa.** Format sudah lengkap di paket ini; kamu tidak perlu membaca
  kode alat pemeriksa (`alat/audit-independen.py`) untuk menyesuaikannya. Jalankan pemeriksa **sekali di akhir**;
  bila ditolak, perbaiki **kelengkapan format**, bukan menambah temuan yang tidak kamu yakini.

## 7. Kalibrasi cacat tanaman (khusus AUD-3)

Bahan kalibrasi ada **di dalam repo ini** (folder yang disebut §0b di atas) dan berisi **cacat yang sengaja ditanam**;
kunci jawabannya disimpan **di luar repo** dan tidak boleh kamu cari. Isi `## 5. Kalibrasi cacat tanaman` dengan daftar
cacat yang kamu temukan (`berkas` + kelas + bukti), `Ditemukan: X dari Y`, dan jumlah temuan palsu.
**Kalibrasi ini menentukan apakah verdict BERSIH-mu boleh dipercaya.** Cacat di folder bahan **tidak** dihitung sebagai temuan proyek.
"""
    keluar.write_text(isi_paket, encoding="utf-8")
    print(f"PAKET AUDIT dibuat: {keluar.relative_to(AKAR)}")

    # Berkas siap-tempel: kalimat pembuka auditor (diambil dari sumber kanonik, bukan disalin tangan)
    # + seluruh paket. Tujuannya menghapus kegagalan praktis "pemilik hanya menempel separuh".
    sumber_prompt = AKAR / "docs" / "uji" / "PROMPT_AUDIT_INDEPENDEN.md"
    if sumber_prompt.is_file():
        kanonik = sumber_prompt.read_text(encoding="utf-8").split("## B.")[-1]
        m = re.search(r"```\n(.*?)\n```", kanonik, re.DOTALL)
        if m:
            siap = (
                "> BERKAS SIAP-TEMPEL — salin SELURUH isi berkas ini ke chat/percakapan BARU (idealnya model berbeda).\n"
                "> Dibuat mesin oleh `alat/audit-independen.py`; kalimat pembuka diambil apa adanya dari sumber kanonik.\n\n"
                "===== MULAI SALIN DARI SINI =====\n\n"
                + m.group(1).strip()
                + "\n\n===== SAMBUNGAN: PAKET AUDIT =====\n\n"
                + isi_paket
            )
            keluar_siap = keluar.with_name(keluar.stem + "-SIAP-TEMPEL.md")
            keluar_siap.write_text(siap, encoding="utf-8")
            print(f"SIAP-TEMPEL    : {keluar_siap.relative_to(AKAR)}   (pemilik cukup menyalin berkas ini)")
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


def _kenali_cabang_asal(teks: str, folder: str = "docs/uji/audit/") -> dict:
    """Cari cabang auditor yang isinya persis laporan ini → bukti berkas-tunggal dari cabang itu.

    Kenapa ada: pemeriksaan "repo bersih" di meja kerja SESI KERJA bisa menolak laporan sah
    (draf kerja sesi itu sendiri, atau berkas laporan yang baru ditarik). Bukti dari cabang auditor
    tidak bisa dikotori sesi kerja — jadi ia yang dipakai bila tersedia (cacat mekanisme #10).
    """
    _, refs = jalankan(["git", "for-each-ref", "--format=%(refname:short)", "refs/remotes/origin/"])
    for ref in [r.strip() for r in refs.splitlines() if r.strip()]:
        _, berkas = jalankan(["git", "ls-tree", "-r", "--name-only", ref, "--", folder])
        for jalur in [b.strip() for b in berkas.splitlines() if b.strip().lower().endswith(".md")]:
            _, isi = jalankan(["git", "show", f"{ref}:{jalur}"])
            if isi.strip() and isi == teks:
                bukti = _bukti_cabang_laporan(ref, folder)
                if bukti:
                    bukti["berkas"] = jalur
                    return bukti
    return {}


def _kontrak_target_memuat(sha: str, penanda: str, berkas_alat: str = "alat/audit-independen.py") -> bool | None:
    """Apakah kontrak di commit TARGET sudah memuat penanda ini? True/False/None (tak bisa dipastikan)."""
    if not sha:
        return None
    rc, _ = jalankan(["git", "cat-file", "-e", f"{sha}:{berkas_alat}"])
    if rc != 0:
        return None
    _, isi = jalankan(["git", "show", f"{sha}:{berkas_alat}"])
    return penanda in isi


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
              "## 7. Pernyataan tidak mengubah apa pun", "## 8. Temuan di luar cakupan"]
    for b in bagian:
        if b not in teks:
            if b == "## 8. Temuan di luar cakupan":
                # Kontrak §8 baru berlaku sejak 2026-09-17. Laporan atas commit yang LEBIH TUA dinilai
                # dengan kontrak yang berlaku saat itu — bukan pelanggaran (cacat mekanisme #10).
                status8 = _kontrak_target_memuat(sha, b) if sha else None
                if status8 is False:
                    catatan.append("bagian 8 tidak ada, tetapi kontrak §8 belum berlaku di commit yang diaudit "
                                   "— dinilai dengan kontrak lama (bukan pelanggaran)")
                else:
                    gagal.append(f"bagian wajib hilang: {b}")
                continue
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
    bagian7 = teks.split("## 7. Pernyataan tidak mengubah apa pun")[-1].split("## 8.")[0]
    if "tidak mengubah" not in bagian7.lower():
        gagal.append("bagian 7 wajib memuat pernyataan 'tidak mengubah apa pun'")
    if not re.search(r"laporan|satu-satunya berkas", bagian7, re.I):
        gagal.append("bagian 7 wajib menyebut bahwa laporan INI adalah satu-satunya berkas yang dibuat auditor "
                     "(tanpa itu, aturan 'repo harus bersih' bertabrakan dengan kewajiban menulis laporan)")

    # bagian 8: temuan di luar cakupan (boleh kosong, tetapi wajib ada — permintaan Lee 2026-09-17)
    bagian8 = teks.split("## 8. Temuan di luar cakupan")[-1] if "## 8. Temuan di luar cakupan" in teks else ""
    if bagian8:
        isi8 = [b for b in bagian8.splitlines() if b.strip() and not b.strip().startswith(("|", "#", "-"))]
        baris8 = _tabel_baris(teks, "## 8. Temuan di luar cakupan")
        angka["luar_cakupan"] = len(baris8)
        if not baris8 and not re.search(r"tidak ada", bagian8, re.I):
            gagal.append("bagian 8 kosong: tulis temuan di luar cakupan, atau tulis 'tidak ada'")

    # lantai vs target (anti-teater): laporkan bila angka persis di ambang minimum
    if angka.get("artefak") is not None and angka["artefak"] in (6, 17):
        catatan.append(f"cakupan persis di ambang minimum ({angka['artefak']}) — pastikan tidak ada penambahan demi syarat; "
                       "ambang = lantai, bukan target")
    if angka.get("klaim") == 5:
        catatan.append("klaim dibantah persis 5 (ambang minimum) — periksa apakah ini kebetulan atau berhenti di ambang")
    if angka.get("serangan") is not None and angka["serangan"] == SERANGAN_MIN.get(tingkat or "", 5):
        catatan.append(f"serangan persis {angka['serangan']} (ambang minimum) — periksa apakah auditor berhenti di ambang")
    if cek_git:
        bukti = _kenali_cabang_asal(teks)
        if bukti:
            tanda = ("hanya menambah berkas laporan" if bukti["hanya_laporan"]
                     else "MENYENTUH BERKAS DI LUAR FOLDER LAPORAN")
            catatan.append(f"bukti cabang {bukti['cabang']}@{bukti['commit'][:8]}: {tanda} "
                           f"({', '.join(bukti['perubahan'][:4]) or '-'}) — cek kebersihan meja kerja dilewati, "
                           "bukti dari cabang auditor lebih kuat")
            if not bukti["hanya_laporan"]:
                gagal.append(f"cabang laporan {bukti['cabang']} menyentuh berkas di luar folder laporan "
                             f"({', '.join(bukti['perubahan'][:4])}) — auditor wajib hanya-baca")
        else:
            _, status = jalankan(["git", "status", "--porcelain"])
            diabaikan: list[str] = []
            kotor: list[str] = []
            for baris_status in status.splitlines():
                j = baris_status[3:].strip().strip('"')
                if j.startswith(("docs/uji/audit/", "docs/uji/review-pr/")):
                    diabaikan.append(j)  # saluran pengiriman laporan (termasuk berkas laporan ini sendiri)
                else:
                    kotor.append(j)
            if diabaikan:
                catatan.append("saat cek kebersihan, berkas saluran laporan diabaikan: "
                               + ", ".join(diabaikan[:4]) + (" …" if len(diabaikan) > 4 else ""))
            if kotor:
                gagal.append("repo TIDAK bersih saat laporan diperiksa — auditor wajib hanya-baca "
                             f"(contoh: {', '.join(kotor[:3])})")

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
    if "luar_cakupan" in angka:
        print(f"  di luar cakupan   : {angka['luar_cakupan']} temuan")
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
def _nama_cabang_ringkas(cabang: str) -> str:
    """`origin/arena/01a0aeb4-resto-barokah` → `01a0aeb4` (dipakai sebagai penanda asal laporan)."""
    n = cabang.replace("origin/", "").replace("arena/", "").replace("-resto-barokah", "")
    return n[:16] or "tanpa-nama"


def _bukti_cabang_laporan(ref: str, folder: str) -> dict:
    """Bukti dari cabang laporan itu sendiri: berkas apa yang ditambah/diubah relatif titik pisah.

    Kenapa ada: pemeriksaan "repo bersih" lewat `git status` sesi kerja menolak laporan yang SAH
    (berkas laporan yang baru ditarik ikut terbaca kotor) — cacat mekanisme #10, ditemukan 2026-09-17.
    Bukti dari cabang jauh lebih kuat: yang diperiksa adalah isi cabang auditor, bukan meja kerja kita.
    """
    dasar = ""
    for kandidat in ("origin/main", "origin/HEAD", "HEAD"):
        rc, kel = jalankan(["git", "merge-base", kandidat, ref])
        if rc == 0 and kel.strip():
            dasar = kel.strip()
            break
    if not dasar:
        return {}
    rc, kel = jalankan(["git", "diff", "--name-only", dasar, ref])
    if rc != 0:
        return {}
    _, sha = jalankan(["git", "rev-parse", ref])
    berkas = [b.strip() for b in kel.splitlines() if b.strip()]
    return {"cabang": ref.replace("origin/", ""), "commit": sha.strip(), "dasar": dasar,
            "perubahan": berkas, "hanya_laporan": bool(berkas) and all(b.startswith(folder) for b in berkas)}


def _riwayat_berkas(ref: str, folder: str) -> list[tuple[str, str]]:
    """[(commit, jalur)] untuk SEMUA versi berkas laporan di riwayat cabang, terbaru dulu.

    Kenapa ada (cacat mekanisme #12, 2026-09-17): dua sesi auditor bisa push ke CABANG YANG SAMA
    dengan nama berkas yang sama — versi lama lalu hanya hidup di riwayat commit, bukan di ujung cabang.
    Menelusuri ujung cabang saja membuat laporan itu hilang tanpa jejak.
    """
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


def mode_ambil_laporan() -> int:
    """Ambil laporan audit dari cabang sesi auditor (arena/*) — jalur pulang laporan (§5c protokol).

    Kenapa ada (pertanyaan Lee 2026-09-17): sesi auditor bekerja di ruang kerja sendiri; sesi kerja
    tidak bisa melihat berkasnya. Satu-satunya jembatan: auditor push laporannya ke cabang sesinya,
    lalu sesi kerja menariknya dari GitHub.
    """
    print("Mencari laporan audit di cabang sesi lain (arena/*)…")
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

    tujuan = AKAR / "docs" / "uji" / "audit"
    tujuan.mkdir(parents=True, exist_ok=True)
    sudah_ada = {f.read_text(encoding="utf-8") for f in tujuan.glob("*.md") if f.is_file()}
    ditemukan: list[tuple[str, str, str]] = []  # (cabang, berkas, status)
    bukti: list[str] = []
    for ref in daftar:
        cabang_nama = ref.replace("origin/", "")
        versi_laporan = _riwayat_berkas(ref, "docs/uji/audit/")
        b_cabang = _bukti_cabang_laporan(ref, "docs/uji/audit/") if versi_laporan else {}
        if b_cabang:
            tanda = "hanya menambah berkas laporan" if b_cabang["hanya_laporan"] else "MENYENTUH BERKAS DI LUAR FOLDER LAPORAN"
            bukti.append(f"  · [{cabang_nama}@{b_cabang['commit'][:8]}] {tanda}: {', '.join(b_cabang['perubahan'][:4]) or '-'}")
        for sha_v, jalur in versi_laporan:
            _, isi = jalankan(["git", "show", f"{sha_v}:{jalur}"])
            if not isi.strip() or isi in sudah_ada:
                continue
            nama = pathlib.Path(jalur).name
            target = tujuan / nama
            if not target.is_file():
                target.write_text(isi, encoding="utf-8")
                sudah_ada.add(isi)
                ditemukan.append((cabang_nama, str(target.relative_to(AKAR)), "baru"))
                continue
            # CACAT MEKANISME #9 & #12 (ditemukan 2026-09-17): dua sesi bisa memakai nama berkas yang
            # SAMA — bahkan di dalam satu cabang (versi lama hanya hidup di riwayat commit).
            # Tidak ada laporan yang boleh ditimpa: simpan terpisah dengan penanda cabang/commit.
            ringkas = _nama_cabang_ringkas(cabang_nama)
            for kandidat in (f"{target.stem}.dari-{ringkas}{target.suffix}",
                             f"{target.stem}.dari-{ringkas}-{sha_v[:8]}{target.suffix}"):
                pendamping = target.with_name(kandidat)
                if pendamping.is_file() and pendamping.read_text(encoding="utf-8") == isi:
                    break
                if not pendamping.is_file():
                    pendamping.write_text(isi, encoding="utf-8")
                    sudah_ada.add(isi)
                    status = ("nama sama dari sesi lain — disimpan terpisah: " + pendamping.name if kandidat.count("-") == 1
                              else f"versi lama (commit {sha_v[:8]}) yang tertimpa — diselamatkan: {pendamping.name}")
                    ditemukan.append((cabang_nama, str(pendamping.relative_to(AKAR)), status))
                    break
    print()
    if not ditemukan:
        print("TIDAK ADA laporan baru di cabang arena/*.")
        print("  • Pastikan tiap sesi auditor sudah: tulis laporan → `git add docs/uji/audit/` → commit → push.")
        print("  • Kalau auditor tidak bisa push: minta ia menempelkan laporan di chat, lalu simpan sebagai berkas di")
        print("    docs/uji/audit/ (agent boleh membuatkan berkasnya).")
        return 1
    print(f"DITEMUKAN {len(ditemukan)} laporan:")
    for cabang_nama, jalur, status in ditemukan:
        print(f"  · [{cabang_nama}] {jalur} — {status}")
    if bukti:
        print("\nBukti dari cabangnya sendiri (aturan berkas-tunggal, diperiksa dari GitHub):")
        for b in bukti:
            print(b)
    print("\nLangkah berikutnya (wajib berurutan):")
    for _, jalur, _ in ditemukan:
        print(f"  python3 alat/audit-independen.py --periksa-laporan {jalur}")
    print("  python3 alat/audit-independen.py --kalibrasi-nilai <laporan> --kunci <kunci-di-luar-repo>")
    return 0


def mode_verifikasi_lingkup(berkas_paket: str | None) -> int:
    """Pastikan repo ini memuat commit yang diminta paket audit.

    Kenapa ada (pertanyaan Lee 2026-09-17): sesi auditor bisa dibuka dari base branch mana pun.
    Supaya mekanisme ini TIDAK bergantung pada pilihan cabang Lee, commit target ditulis di paket
    dan diperiksa lewat perintah ini — hasilnya langkah pasti, bukan tebakan.
    """
    _, lokal = jalankan(["git", "rev-parse", "HEAD"])
    lokal = lokal.strip()
    if not lokal:
        print("GAGAL: bukan repo git / HEAD tidak terbaca"); return 1

    if berkas_paket:
        berkas = pathlib.Path(berkas_paket)
    else:
        folder = AKAR / "docs" / "uji" / "paket-audit"
        kandidat = sorted(folder.glob("*.md")) if folder.is_dir() else []
        berkas = kandidat[-1] if kandidat else None
    if berkas is None:
        print("CATATAN: tidak ada paket audit. Pakai: --verifikasi-lingkup <berkas paket>"); return 1
    if not berkas.is_absolute():
        berkas = AKAR / berkas
    if not berkas.is_file():
        print(f"GAGAL: paket tidak ada: {berkas}"); return 1
    m = re.search(r"- \*\*Commit yang diaudit:\*\*\s*`?([0-9a-f]{7,40})`?", berkas.read_text(encoding="utf-8"))
    if not m:
        print(f"GAGAL: paket {berkas.name} tidak menyebut commit yang diaudit"); return 1
    target = m.group(1)

    print(f"Paket audit   : {berkas.relative_to(AKAR)}")
    print(f"Commit target : {target}")
    print(f"Commit lokal  : {lokal}")

    if lokal.startswith(target[:12]) or target.startswith(lokal[:12]):
        print("\nHASIL: COCOK — kamu berada tepat di commit yang diminta paket. Lanjutkan audit.")
        return 0
    rc, _ = jalankan(["git", "cat-file", "-e", f"{target}^{{commit}}"])
    if rc == 0:
        print("\nHASIL: BEDA COMMIT, tetapi target tersedia di repo ini. Lanjutkan hanya-baca:")
        print(f"          git fetch origin && git checkout --detach {target}")
        return 2
    print("\nTarget belum ada di repo ini. Mencoba mengambil dari origin…")
    jalankan(["git", "fetch", "origin"])
    rc2, _ = jalankan(["git", "cat-file", "-e", f"{target}^{{commit}}"])
    if rc2 == 0:
        print("HASIL: target berhasil diambil. Pindah hanya-baca lalu lanjut:")
        print(f"        git checkout --detach {target}")
        return 2
    print("\nHASIL: TARGET TIDAK ADA di repo ini setelah fetch.")
    print("        JANGAN mengaudit commit lain. Laporkan ke Lee: minta sesi dibuka dari cabang yang")
    print(f"        memuat commit {target} (cabang sesi kerja, atau main bila sudah di-merge).")
    return 3


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
def _uji_jalur_pulang_laporan() -> tuple[bool, str]:
    """Uji terpisah (mock, tanpa git) untuk --ambil-laporan: pastikan jalur pulang laporan bekerja.

    Dipakai oleh --uji-diri. Tanpa uji ini, mekanisme "auditor push laporan → sesi kerja menariknya"
    hanya keyakinan — dan justru itu cacat yang ditutup 2026-09-17.
    """
    contoh = "# LAPORAN AUDIT INDEPENDEN — uji-coba\n\n- **Verdict:** BERSIH\n"
    contoh2 = "# LAPORAN AUDIT INDEPENDEN — uji-coba (sesi kedua)\n\n- **Verdict:** TIDAK-BERSIH\n"
    contoh3 = "# LAPORAN AUDIT INDEPENDEN — uji-coba (versi tertimpa)\n\n- **Verdict:** BERSIH\n"
    asli = globals()["jalankan"]

    sha1, sha2b, sha2a = "1" * 40, "2" * 40, "3" * 40

    def palsu(perintah: list[str], cwd=None):  # noqa: ANN001
        if perintah[:2] == ["git", "fetch"]:
            return 0, ""
        if perintah[:2] == ["git", "for-each-ref"]:
            # DUA sesi, nama berkas SAMA → meniru cacat mekanisme #9 (2026-09-17)
            return 0, "origin/arena/uji-coba\norigin/arena/uji-coba-2\n"
        if perintah[:2] == ["git", "log"]:
            # Cabang kedua membawa DUA versi berkas yang sama (sesi ketiga menimpa sesi kedua)
            # → meniru cacat mekanisme #12 (versi lama hanya hidup di riwayat commit).
            if perintah[4] == "origin/arena/uji-coba-2":
                return 0, f"{sha2b}\ndocs/uji/audit/LAPORAN_UJI_COBA.md\n{sha2a}\ndocs/uji/audit/LAPORAN_UJI_COBA.md\n"
            return 0, f"{sha1}\ndocs/uji/audit/LAPORAN_UJI_COBA.md\n"
        if perintah[:2] == ["git", "show"]:
            arg = perintah[2]
            if arg.startswith(f"{sha2a}:"):
                return 0, contoh3
            if arg.startswith(f"{sha2b}:"):
                return 0, contoh2
            return 0, contoh
        return asli(perintah, cwd)

    target = AKAR / "docs" / "uji" / "audit" / "LAPORAN_UJI_COBA.md"
    pendamping = AKAR / "docs" / "uji" / "audit" / "LAPORAN_UJI_COBA.dari-uji-coba-2.md"
    tertimpa = AKAR / "docs" / "uji" / "audit" / f"LAPORAN_UJI_COBA.dari-uji-coba-2-{('3' * 40)[:8]}.md"
    try:
        globals()["jalankan"] = palsu
        import contextlib, io
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            kode = mode_ambil_laporan()
        keluaran = buf.getvalue()
        ok = (kode == 0 and target.is_file() and pendamping.is_file() and tertimpa.is_file()
              and target.read_text(encoding="utf-8") == contoh          # laporan sesi 1 tidak tertimpa
              and pendamping.read_text(encoding="utf-8") == contoh2      # laporan sesi 2 tersimpan terpisah
              and tertimpa.read_text(encoding="utf-8") == contoh3        # versi lama di riwayat tetap diselamatkan
              and "DITEMUKAN 3 laporan" in keluaran)
        pesan = ("laporan ditarik dari cabang sesi auditor; nama sama antar sesi & versi tertimpa di dalam satu "
                 "cabang tidak ada yang hilang"
                 if ok else f"gagal: kode={kode}, ada={target.is_file()}/{pendamping.is_file()}/{tertimpa.is_file()}")
        return ok, pesan
    finally:
        globals()["jalankan"] = asli
        for f in (target, pendamping, tertimpa):
            if f.is_file():
                f.unlink()


def _uji_pembuat_paket() -> tuple[bool, str]:
    """Buktikan PEMBUAT PAKET AUDIT benar-benar bisa jalan & cakupannya tidak melebar.

    Kenapa ada (cacat nyata 2026-09-18): `--paket AUD-3 --semua` MATI dengan
    `NameError: name 'lingkup' is not defined`, dan parameter cakupan `semua` ditimpa
    daftar tugas sehingga `--fase` diam-diam mengambil SELURUH tugas. Dua-duanya kelas
    cacat "alat yang tidak pernah dijalankan setelah disunting" — pemilik menyalin
    paket audit, tetapi paketnya tidak pernah bisa dibuat. Uji ini menjalankan pembuat
    paket di SALINAN pohon untuk dua mode (menyeluruh & per fase) dan memeriksa isinya.
    """
    import subprocess
    import tempfile

    def jalankan(akar_tmp, argumen):
        r = subprocess.run([sys.executable, str(akar_tmp / "alat" / "audit-independen.py"), *argumen],
                           capture_output=True, text=True, cwd=str(akar_tmp))
        return r.returncode, r.stdout + r.stderr

    with tempfile.TemporaryDirectory(prefix="paket-audit-uji-") as tmp:
        tujuan = pathlib.Path(tmp) / "repo"
        shutil.copytree(AKAR, tujuan, ignore=shutil.ignore_patterns(
            ".git", "node_modules", "dist", "build", "coverage", "__pycache__", ".pytest_cache"))
        kode, keluar = jalankan(tujuan, ["--paket", "AUD-3", "--semua"])
        if kode != 0:
            return False, f"paket menyeluruh GAGAL dibuat (kode {kode}): {keluar.strip().splitlines()[-1:]}"
        paket = sorted((tujuan / "docs" / "uji" / "paket-audit").glob("AUD-3-*.md"))
        isi = paket[-1].read_text(encoding="utf-8") if paket else ""
        if "- **Mode cakupan:** menyeluruh" not in isi:
            return False, "paket menyeluruh tidak mencantumkan mode cakupan `menyeluruh`"

        kode2, keluar2 = jalankan(tujuan, ["--paket", "AUD-2", "--fase", "1"])
        if kode2 != 0:
            return False, f"paket per fase GAGAL dibuat (kode {kode2})"
        paket2 = sorted((tujuan / "docs" / "uji" / "paket-audit").glob("AUD-2-*.md"))
        isi2 = paket2[-1].read_text(encoding="utf-8") if paket2 else ""
        m = re.search(r"- \*\*Tugas dalam lingkup:\*\* (.+)", isi2)
        ids = [x.strip() for x in m.group(1).split(",")] if m else []
        if not ids or any(not x.startswith("T1-") for x in ids):
            return False, f"cakupan `--fase 1` melenceng (berisi tugas di luar fase 1): {ids[:6]}"
        if "- **Mode cakupan:** terarah" not in isi2:
            return False, "paket per fase tidak mencantumkan mode cakupan `terarah`"
    return True, "paket menyeluruh & per fase bisa dibuat, cakupannya sesuai permintaan"


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

    ok_paket, pesan_paket = _uji_pembuat_paket()
    print(f"  [{'OK' if ok_paket else 'X '}] pembuat paket audit (--paket/--fase): {pesan_paket}")
    if not ok_paket:
        rusak += 1

    ok_pulang, pesan_pulang = _uji_jalur_pulang_laporan()
    print(f"  [{'OK' if ok_pulang else 'X '}] jalur pulang laporan (--ambil-laporan): {pesan_pulang}")
    if not ok_pulang:
        rusak += 1

    if rusak:
        print(f"\nHASIL: GAGAL — {rusak} contoh berperilaku salah (mekanisme belum bisa dipercaya)")
        return 1
    print("\nHASIL: LOLOS — pemeriksa laporan & penilai kalibrasi terbukti bisa MENOLAK yang buruk dan MENERIMA yang baik, "
          "dan jalur pulang laporan (auditor → sesi kerja) terbukti bekerja.")
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
    p.add_argument("--ambil-laporan", action="store_true", help="ambil laporan audit dari cabang sesi auditor (arena/*)")
    p.add_argument("--verifikasi-lingkup", nargs="?", const="", metavar="PAKET",
                   help="pastikan repo ini memuat commit yang diminta paket audit (bebas base branch)")
    a = p.parse_args()

    if a.ambil_laporan:
        return mode_ambil_laporan()
    if a.verifikasi_lingkup is not None:
        return mode_verifikasi_lingkup(a.verifikasi_lingkup or None)
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
