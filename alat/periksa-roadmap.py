#!/usr/bin/env python3
"""periksa-roadmap.py — pemeriksa otomatis docs/ROADMAP.md (Resto Barokah).

Tujuan: memastikan daftar tugas BENAR-BENAR lengkap dan tidak ada tugas yang cacat,
tanpa mengandalkan ingatan agent. Dijalankan sebelum fase baru dimulai dan di CI.

    python3 alat/periksa-roadmap.py

Yang diperiksa:
  1. Setiap tugas punya 7 atribut wajib (Tujuan, Ref, File, DoD, Kompleksitas, Risiko & mitigasi, Verifikasi).
  2. Semua fitur Must Have M1–M12 disebut minimal sekali di kolom Ref.
  3. Semua entitas data model (TECH_SPEC §4) punya jejak di ROADMAP.
  4. Semua RPC inti (TECH_SPEC §5) punya jejak.
  5. Semua Area Berisiko Tinggi ART-1…ART-10 muncul bersama lambang ⚠️.
  6. Semua tanda ❓ memakai ID yang benar-benar ada di docs/TERTANGGUH.md.
  7. Hal kecil (README, .env.example, favicon, error, memuat/kosong, a11y, responsif) & integrasi
     (Supabase, Google, Resend, Cloudflare, pg_cron) punya tugasnya.
  8. JAMINAN TUNTAS K3 (keputusan Lee 2026-09-29, docs/uji/pemeriksaan/USULAN_JAMINAN_TUNTAS.md):
     setiap tugas bercentang `[x]` WAJIB punya baris `- **Bukti:**` yang menunjuk ≥1 berkas uji/penjaga
     yang ADA di repo (mis. `x.test.ts`, `supabase/tes/x.sql`, `alat/periksa-x.py`) ATAU baris Buku Uji
     Pemilik `U-nn` yang kolom Hasil-nya sudah diisi Lee `OK`. Centang lama (sebelum aturan) boleh memakai
     penanda transisi `⏳ BUKTI-BELUM` HANYA bila ID-nya terdaftar di BUKTI_BELUM_BASELINE.txt (daftar beku
     yang hanya boleh MENYUSUT — diputuskan satu per satu oleh sensus klaim Tahap 2 PMB). Tugas yang memuat
     `Dibuka kembali:` tidak boleh memakai penanda transisi: kalau dicentang lagi, buktinya harus nyata.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ROADMAP = ROOT / "docs" / "ROADMAP.md"
TERTANGGUH = ROOT / "docs" / "TERTANGGUH.md"

ATRIBUT = ["**Tujuan:**", "**Ref:**", "**File:**", "**DoD", "**Kompleksitas:**",
           "**Risiko & mitigasi:**", "**Verifikasi:**"]

# --- K3 Jaminan Tuntas: bukti pada centang [x] ---------------------------------------------------------
BUKU_UJI = ROOT / "docs" / "uji" / "BUKU_UJI_PEMILIK.md"
BASELINE_BUKTI_BELUM = ROOT / "docs" / "uji" / "pemeriksaan" / "PMB-1" / "BUKTI_BELUM_BASELINE.txt"
PENANDA_TRANSISI = "⏳ BUKTI-BELUM"
RE_BARIS_BUKTI = re.compile(r"^\s*- \*\*Bukti:\*\*(.*)$")
RE_DIBUKA_KEMBALI = re.compile(r"\*\*Dibuka kembali:\*\*\s*(PMB1-F-\d{3})")
# berkas yang dihitung sebagai BUKTI MESIN: uji komponen, uji SQL, penjaga/uji di alat/, validator sistem
RE_BUKTI_MESIN = re.compile(
    r"(?:\.test\.tsx?$)|(?:^supabase/tes/[^\s]+\.sql$)|(?:^alat/(?:uji|periksa|susun)[\w.-]*\.(?:py|mjs|sh)$)|"
    r"(?:^aplikasi/alat/(?:uji|periksa)[\w.-]*\.(?:py|sh|mjs)$)|(?:^_sistem/validate_system\.py$)|(?:^prototipe/uji-[\w.-]+\.py$)"
)
RE_JALUR = re.compile(r"`([^`]+)`")
RE_U = re.compile(r"\bU-(\d{2,3})\b")


def baris_uji_lee_ok(teks_buku: str) -> set[str]:
    """ID baris Buku Uji Pemilik (`U-nn`) yang kolom Hasil-nya diisi Lee `OK` (tanda tangan manusia)."""
    ok: set[str] = set()
    for baris in teks_buku.splitlines():
        if not baris.startswith("| U-"):
            continue
        sel = [s.strip() for s in baris.strip().strip("|").split("|")]
        if len(sel) >= 5 and re.match(r"^U-\d{2,3}$", sel[0]) and re.match(r"^OK\b", sel[4], re.I):
            ok.add(sel[0])
    return ok


def jalur_bukti_mesin(teks: str, akar: Path) -> list[str]:
    """Jalur ber-backtick dalam teks yang (a) berpola berkas uji/penjaga dan (b) benar-benar ada di repo."""
    hasil: list[str] = []
    for tok in RE_JALUR.findall(teks):
        for kata in tok.split():
            kata = kata.strip("'\",;()")
            if "/" in kata and RE_BUKTI_MESIN.search(kata) and (akar / kata).is_file() and kata not in hasil:
                hasil.append(kata)
    return hasil


def klasifikasi_bukti(tid: str, isi: str, akar: Path, u_ok: set[str], baseline: set[str]) -> tuple[str, str]:
    """Nilai baris Bukti sebuah tugas [x] → (kelas, keterangan).

    kelas: 'sah' | 'transisi' | 'tanpa-baris' | 'transisi-tak-sah' | 'kosong'
    """
    baris = [m.group(1).strip() for l in isi.splitlines() if (m := RE_BARIS_BUKTI.match(l))]
    if not baris:
        return "tanpa-baris", "tidak ada baris `- **Bukti:**`"
    b = " ".join(baris)
    if PENANDA_TRANSISI in b:
        if RE_DIBUKA_KEMBALI.search(isi):
            return "transisi-tak-sah", "tugas 'Dibuka kembali' tidak boleh memakai penanda transisi"
        if tid not in baseline:
            return "transisi-tak-sah", f"{tid} tidak terdaftar di {BASELINE_BUKTI_BELUM.name} (daftar beku, hanya boleh menyusut)"
        return "transisi", ""
    mesin = jalur_bukti_mesin(b, akar)
    lee = sorted(u for u in {f"U-{n}" for n in RE_U.findall(b)} if u in u_ok)
    if mesin or lee:
        return "sah", ", ".join(mesin + lee)
    return "kosong", "baris Bukti tidak menunjuk berkas uji/penjaga yang ada di repo maupun baris U-nn yang sudah Lee isi OK"


def baca_baseline(akar: Path) -> set[str]:
    p = akar / BASELINE_BUKTI_BELUM.relative_to(ROOT)
    if not p.is_file():
        return set()
    return {l.split()[0] for l in p.read_text(encoding="utf-8").splitlines() if l.strip() and not l.startswith("#")}


def baseline_membesar(akar: Path) -> list[str]:
    """Daftar beku hanya boleh MENYUSUT: ID yang tidak ada di versi tercommit sebelumnya → ditolak."""
    import subprocess
    rel = str(BASELINE_BUKTI_BELUM.relative_to(ROOT))
    try:
        sama = subprocess.run(["git", "diff", "--quiet", "HEAD", "--", rel], cwd=akar, capture_output=True).returncode == 0
        lama = subprocess.run(["git", "show", f"{'HEAD~1' if sama else 'HEAD'}:{rel}"], cwd=akar, capture_output=True, text=True)
    except (OSError, ValueError):
        return []
    if lama.returncode != 0:
        return []
    ids_lama = {l.split()[0] for l in lama.stdout.splitlines() if l.strip() and not l.startswith("#")}
    return sorted(baca_baseline(akar) - ids_lama)


def periksa_bukti(teks: str, akar: Path, u_ok: set[str], baseline: set[str]) -> tuple[list[str], dict[str, int]]:
    """K3: setiap tugas [x] wajib punya Bukti sah, atau penanda transisi yang terdaftar di baseline."""
    gagal: list[str] = []
    hitung = {"sah": 0, "transisi": 0, "cacat": 0, "dibuka_kembali_terbuka": 0}
    for tid, isi in blok_tugas(teks, semua_status=True):
        centang = isi.startswith("[x]")
        badan = isi.split("\n", 1)[1] if "\n" in isi else ""
        if not centang:
            if RE_DIBUKA_KEMBALI.search(badan):
                hitung["dibuka_kembali_terbuka"] += 1
            continue
        kelas, ket = klasifikasi_bukti(tid, badan, akar, u_ok, baseline)
        if kelas == "sah":
            hitung["sah"] += 1
        elif kelas == "transisi":
            hitung["transisi"] += 1
        else:
            hitung["cacat"] += 1
            gagal.append(f"{tid}: centang [x] tanpa bukti sah — {ket}")
    return gagal, hitung

FITUR = [f"M{i}" for i in range(1, 13)]

TEK_SPEC = ROOT / "docs" / "TECH_SPEC.md"


def nama_entitas() -> list[str]:
    """Nama tabel diambil LANGSUNG dari dokumen terkunci `TECH_SPEC.md` §4 (bukan daftar tangan yang bisa basi).

    Dasar perubahan (temuan review independen W3-03): daftar tangan lama memuat nama pendek
    (`kategori`, `stok`) yang bukan nama tabel resmi, sehingga gerbangnya hijau palsu.
    """
    if not TEK_SPEC.is_file():
        return []
    return sorted(set(re.findall(r"^\|\s*`([a-z_]+)`\s*\|", TEK_SPEC.read_text(encoding="utf-8"), re.M)))


def nama_rpc() -> list[str]:
    """Nama RPC diambil dari `rpc/nama` di `TECH_SPEC.md` §5."""
    if not TEK_SPEC.is_file():
        return []
    return sorted(set(re.findall(r"`rpc/([a-z_]+)`", TEK_SPEC.read_text(encoding="utf-8"))))


ART = [f"ART-{i}" for i in range(1, 11)]

HAL_KECIL = {"README": "README", ".env.example": ".env.example", "favicon": "favicon",
             "halaman error": "TidakPunyaAkses", "keadaan memuat/kosong/gagal": "Keadaan",
             "a11y": "a11y", "responsif": "responsif"}

INTEGRASI = {"Supabase": "Supabase", "Google": "Google", "Resend": "Resend",
             "Cloudflare": "Cloudflare", "pg_cron": "pg_cron"}


def blok_tugas(teks: str, semua_status: bool = False) -> list[tuple[str, str]]:
    """Pisahkan ROADMAP menjadi blok per tugas → [(id, isi_blok)].

    semua_status=True: baris pertama isi_blok diawali kotak centang (`[x] judul` / `[ ] judul`) dan ID fase
    berhuruf (T1B-01) ikut dikenali — dipakai pemeriksa Bukti (K3) & penyusun DAFTAR_TUNGGU_LEE.
    """
    hasil: list[tuple[str, str]] = []
    sekarang_id, sekarang_isi = None, []
    pola = r"^- (\[[ x]\]) (T\d+[A-Z]?-\d+) — (.+)$" if semua_status else r"^- (\[[ x]\]) (T\d+-\d+) — (.+)$"
    for baris in teks.splitlines():
        m = re.match(pola, baris)
        if m:
            if sekarang_id:
                hasil.append((sekarang_id, "\n".join(sekarang_isi)))
            sekarang_id = m.group(2)
            sekarang_isi = [f"{m.group(1)} {m.group(3)}"] if semua_status else [m.group(3)]
        elif sekarang_id is not None:
            if baris.startswith("## ") or baris.strip() == "---":
                hasil.append((sekarang_id, "\n".join(sekarang_isi)))
                sekarang_id, sekarang_isi = None, []
            else:
                sekarang_isi.append(baris)
    if sekarang_id:
        hasil.append((sekarang_id, "\n".join(sekarang_isi)))
    return hasil


def periksa_tunggu(tugas: str, tunggu: str) -> list[str]:
    """Nol butir terbuka sah; setiap butir terbuka wajib punya penanda pada TUGAS.

    Jangan hitung contoh format T-000 atau riwayat di luar blok tugas sebagai penanda.
    Penanda ke butir selesai juga ditolak, supaya dua pemeriksa tidak bertentangan.
    """
    semua = set(re.findall(r"^\|\s*(T-\d{3})\s*\|", tunggu, re.M)) - {"T-000"}
    terbuka = set(re.findall(r"^\|\s*(T-\d{3})\s*\|[^\n]*\[ \] terbuka", tunggu, re.M)) - {"T-000"}
    tanda = set(re.findall(r"❓\s*(T-\d{3})", tugas))
    return ([f"RUJUKAN MATI: ❓ {t} tidak ada di docs/TERTANGGUH.md" for t in sorted(tanda - semua)]
            + [f"❓ {t} basi: butir sudah selesai" for t in sorted(tanda & (semua - terbuka))]
            + [f"{t} masih terbuka tetapi tidak ditandai ❓ pada tugas" for t in sorted(terbuka - tanda)])


POLA_HARAPAN_FILE = re.compile(
    r"\(rencana|belum ada|belum dibuat|akan dibuat|menyusul|dijadwalkan|pindah ke|menggantikan|"
    r"tidak dibuat|disatukan|dilebur|terbuka di|diimplementasikan|tidak di-commit|pengganti|"
    r"nama lama|nomor rencana|L F-|T\d+-\d+",
    re.I
)


def periksa_jalur_file(teks: str, akar: Path = ROOT) -> list[str]:
    """Pastikan setiap berkas yang dirujuk di `File:` untuk tugas `[x]` benar-benar ada di repo.

    Kecuali bila baris tersebut menandai bahwa berkas memang rencana, dipindah, disatukan,
    atau ditangguhkan (POLA_HARAPAN_FILE). Temuan audit L F-08.
    """
    gagal = []
    lines = teks.splitlines()
    cur_tid = None
    cur_checked = False
    cur_lines = []

    def _evaluasi():
        if cur_tid and cur_checked:
            for l in cur_lines:
                if not l.strip().startswith("- **File:**"):
                    continue
                tokens = re.findall(r"`([^`]+)`(?:\s*\(([^)]+)\))?", l)
                for tok, note in tokens:
                    tok = tok.strip()
                    if "/" not in tok or "*" in tok:
                        continue
                    if note and POLA_HARAPAN_FILE.search(note):
                        continue
                    if POLA_HARAPAN_FILE.search(l) and any(k in l for k in (tok.split("/")[-1], tok)):
                        continue
                    if not (akar / tok).exists():
                        gagal.append(f"{cur_tid}: berkas `{tok}` pada File: tidak ada di repo (tandai rencana bila memang belum ada)")

    for line in lines:
        m = re.match(r"^- \[([ x])\] (T\d+-\d+) — (.+)$", line)
        if m:
            _evaluasi()
            cur_tid = m.group(2)
            cur_checked = (m.group(1) == "x")
            cur_lines = [line]
        elif cur_tid:
            if line.startswith("## ") or line.strip() == "---":
                _evaluasi()
                cur_tid = None
                cur_lines = []
            else:
                cur_lines.append(line)
    _evaluasi()
    return gagal


def uji_diri() -> int:
    from bantu_uji_diri import laporkan
    buka = "| T-026 | 2026-09-21 | uji | [ ] terbuka |"
    tutup = "| T-025 | 2026-09-21 | selesai |"
    kasus = [
        ("kosong sah", "", "", False),
        ("semua selesai sah", "", tutup, False),
        ("terbuka bertanda sah", "❓ T-026", buka, False),
        ("terbuka tak bertanda ditolak", "", buka, True),
        ("ID palsu ditolak", "❓ T-999", buka, True),
        ("penanda basi ditolak", "❓ T-025", tutup, True),
        ("contoh format bukan butir nyata", "", "`| T-000 | contoh | [ ] terbuka |`", False),
        ("butir kedua tanpa penanda ditolak", "❓ T-026", buka + "\n| T-027 | x | [ ] terbuka |", True),
    ]
    hasil = []
    for nama, tugas, tunggu, ditolak in kasus:
        err = periksa_tunggu(tugas, tunggu)
        hasil.append((nama, bool(err) == ditolak, "; ".join(err) or "bersih"))
    # Bukti penanda di judul fase/riwayat tidak menggantikan penanda tugas.
    contoh = "## Fase ❓ T-026\n- [ ] T2-01 — tugas\n  - isi\n---\nriwayat ❓ T-026"
    err = periksa_tunggu("\n".join(isi for _, isi in blok_tugas(contoh)), buka)
    hasil.append(("penanda hanya di luar tugas ditolak", bool(err), str(err)))

    # Uji verifikasi rujukan File: tugas [x] (L F-08)
    teks_uji_file_ok = "- [x] T99-01 — tugas\n  - **File:** `alat/periksa-roadmap.py`\n"
    teks_uji_file_hilang = "- [x] T99-02 — tugas\n  - **File:** `alat/tidak-pernah-ada-12345.py`\n"
    teks_uji_file_rencana = "- [x] T99-03 — tugas\n  - **File:** `alat/tidak-pernah-ada-12345.py` (rencana)\n"
    teks_uji_file_belum = "- [ ] T99-04 — tugas belum selesai\n  - **File:** `alat/tidak-pernah-ada-12345.py`\n"

    hasil.append(("file [x] nyata sah", len(periksa_jalur_file(teks_uji_file_ok, ROOT)) == 0, ""))
    hasil.append(("file [x] hilang ditolak", len(periksa_jalur_file(teks_uji_file_hilang, ROOT)) == 1, ""))
    hasil.append(("file [x] hilang ditandai rencana sah", len(periksa_jalur_file(teks_uji_file_rencana, ROOT)) == 0, ""))
    hasil.append(("file [ ] belum selesai dilewati", len(periksa_jalur_file(teks_uji_file_belum, ROOT)) == 0, ""))

    # Uji K3 Jaminan Tuntas: centang [x] wajib berbukti (keputusan Lee 2026-09-29)
    u_ok = {"U-02"}
    base = {"T98-05"}
    def _k3(blok: str) -> tuple[list[str], dict[str, int]]:
        return periksa_bukti(blok, ROOT, u_ok, base)
    k3 = [
        ("[x] tanpa baris Bukti ditolak", "- [x] T98-01 — a\n  - **Verifikasi:** uji manual\n", True),
        ("[x] Bukti berkas uji nyata sah", "- [x] T98-02 — a\n  - **Bukti:** `alat/periksa-roadmap.py` --uji-diri hijau\n", False),
        ("[x] Bukti berkas uji karangan ditolak", "- [x] T98-03 — a\n  - **Bukti:** `alat/uji-tidak-ada-999.py`\n", True),
        ("[x] Bukti berkas bukan uji (kode aplikasi) ditolak", "- [x] T98-04 — a\n  - **Bukti:** `alat/periksa-roadmap.py.bak` `docs/ROADMAP.md`\n", True),
        ("[x] transisi BUKTI-BELUM terdaftar baseline sah", "- [x] T98-05 — a\n  - **Bukti:** ⏳ BUKTI-BELUM — uji manual tanpa catatan\n", False),
        ("[x] transisi BUKTI-BELUM di luar baseline ditolak", "- [x] T98-06 — a\n  - **Bukti:** ⏳ BUKTI-BELUM — coba-coba\n", True),
        ("[x] Dibuka kembali + transisi ditolak", "- [x] T98-05 — a\n  - **Dibuka kembali:** PMB1-F-130 (2026-09-30)\n  - **Bukti:** ⏳ BUKTI-BELUM\n", True),
        ("[x] Bukti U-nn yang Lee isi OK sah", "- [x] T98-07 — a\n  - **Bukti:** Buku Uji Pemilik U-02 (Lee: OK 2026-09-30)\n", False),
        ("[x] Bukti U-nn belum diisi Lee ditolak", "- [x] T98-08 — a\n  - **Bukti:** Buku Uji Pemilik U-03\n", True),
        ("[ ] tanpa Bukti dilewati", "- [ ] T98-09 — a\n  - **Verifikasi:** nanti\n", False),
        ("ID fase berhuruf ikut diperiksa", "- [x] T1B-99 — a\n  - **Verifikasi:** uji manual\n", True),
    ]
    for nama, blok, ditolak in k3:
        err, _ = _k3(blok)
        hasil.append((nama, bool(err) == ditolak, "; ".join(err) or "bersih"))
    _, hit = _k3("- [ ] T98-10 — a\n  - **Dibuka kembali:** PMB1-F-131 (2026-09-30) — bukti wajib: `supabase/tes/pindah_meja.sql`\n")
    hasil.append(("tugas Dibuka kembali yang masih [ ] dihitung", hit["dibuka_kembali_terbuka"] == 1, str(hit)))
    baris_ok = baris_uji_lee_ok("| ID | a | b | c | Hasil | Cat |\n| U-01 | x | y | z | OK 2026-09-30 | - |\n| U-02 | x | y | z |  | - |\n| U-03 | x | y | z | GAGAL | - |")
    hasil.append(("pembaca tanda tangan Lee di Buku Uji (hanya OK)", baris_ok == {"U-01"}, str(baris_ok)))

    return laporkan("periksa-roadmap", hasil)


def main() -> int:
    if not ROADMAP.is_file():
        print("GAGAL: docs/ROADMAP.md tidak ada")
        return 1
    teks = ROADMAP.read_text(encoding="utf-8")
    tugas = blok_tugas(teks)
    gagal: list[str] = []
    catatan: list[str] = []

    if len(tugas) < 100:
        gagal.append(f"jumlah tugas mencurigakan: {len(tugas)} (harusnya ratusan)")

    for tid, isi in tugas:
        kurang = [a for a in ATRIBUT if a not in isi]
        if kurang:
            gagal.append(f"{tid}: atribut hilang → {', '.join(kurang)}")
        if "⚠️" in isi and "DECISIONS_LOG" not in isi:
            gagal.append(f"{tid}: bertanda ⚠️ tetapi tidak menyebut DECISIONS_LOG")

    isi_tugas = "\n".join(isi for _, isi in tugas)
    for m in FITUR:
        if not re.search(rf"\b{m}\b", teks):
            gagal.append(f"fitur wajib {m} tidak punya tugas")
    for e in nama_entitas():
        if e not in isi_tugas:
            gagal.append(f"entitas '{e}' (TECH_SPEC §4) tidak disebut di blok tugas mana pun")
    for r in nama_rpc():
        if r not in isi_tugas:
            gagal.append(f"RPC '{r}' (TECH_SPEC §5) tidak disebut di blok tugas mana pun")
    for a in ART:
        if not re.search(rf"{a}\b", teks):
            gagal.append(f"Area Berisiko Tinggi {a} tidak disinggung")
        elif f"{a} " not in teks and f"{a}(" not in teks and f"{a}/" not in teks and f"({a})" not in teks:
            catatan.append(f"{a} disinggung tanpa konteks jelas — periksa manual")
    tugas_berisiko = sum(1 for _, isi in tugas if "⚠️" in isi)
    if tugas_berisiko < 20:
        gagal.append(f"hanya {tugas_berisiko} tugas bertanda ⚠️ — Area Berisiko seharusnya tersebar di banyak tugas")

    tunggu = TERTANGGUH.read_text(encoding="utf-8") if TERTANGGUH.is_file() else ""
    ids_tertangguh = set(re.findall(r"^\|\s*(T-\d{3})\s*\|", tunggu, re.M))
    tanda_tanya = set(re.findall(r"❓\s*(T-\d{3})", isi_tugas))
    gagal.extend(periksa_tunggu(isi_tugas, tunggu))
    if not TERTANGGUH.is_file():
        gagal.append("docs/TERTANGGUH.md tidak ada")

    kesalahan_file = periksa_jalur_file(teks, ROOT)
    if kesalahan_file:
        gagal.extend(kesalahan_file)

    # K3 Jaminan Tuntas: centang [x] wajib berbukti
    u_ok = baris_uji_lee_ok(BUKU_UJI.read_text(encoding="utf-8")) if BUKU_UJI.is_file() else set()
    baseline = baca_baseline(ROOT)
    gagal_bukti, hitung_bukti = periksa_bukti(teks, ROOT, u_ok, baseline)
    gagal.extend(gagal_bukti)
    for tid in baseline_membesar(ROOT):
        gagal.append(f"BUKTI_BELUM_BASELINE.txt bertambah {tid} — daftar beku hanya boleh menyusut (sensus Tahap 2), bukan bertambah")

    for label, pola in HAL_KECIL.items():
        if pola not in teks:
            gagal.append(f"hal kecil terlewat: {label}")
    for label, pola in INTEGRASI.items():
        if pola not in teks:
            gagal.append(f"integrasi terlewat: {label}")

    # ringkasan
    per_fase: dict[str, int] = {}
    for tid, _ in tugas:
        f = tid.split("-")[0]
        per_fase[f] = per_fase.get(f, 0) + 1
    print("PERIKSA ROADMAP — Resto Barokah")
    print(f"  Tugas        : {len(tugas)}  ({', '.join(f'{k}:{v}' for k, v in sorted(per_fase.items()))})")
    print(f"  Atribut 7x   : {'lengkap' if not any('atribut hilang' in g for g in gagal) else 'ADA YANG KURANG'}")
    print(f"  Fitur M1-M12 : {'lengkap' if not any('fitur wajib' in g for g in gagal) else 'ADA YANG KURANG'}")
    print(f"  ⚠️ DECISIONS : {tugas_berisiko} tugas bertanda (dihitung per blok tugas, bukan kemunculan lambang)")
    print(f"  Entitas §4   : {len(nama_entitas())} tabel resmi TECH_SPEC — semuanya wajib disebut di blok tugas")
    print(f"  RPC §5       : {len(nama_rpc())} nama resmi TECH_SPEC — semuanya wajib disebut di blok tugas")
    print(f"  ❓ tertangguh : {len(tanda_tanya)} rujukan" + (" (semua sah)" if tanda_tanya <= ids_tertangguh else " (ADA YANG MATI)"))
    print(f"  Bukti [x]    : {hitung_bukti['sah']} sah · {hitung_bukti['transisi']} ⏳ BUKTI-BELUM (transisi, baseline {len(baseline)}) · "
          f"{hitung_bukti['cacat']} cacat · tugas 'Dibuka kembali' masih [ ]: {hitung_bukti['dibuka_kembali_terbuka']}")
    if catatan:
        print("  Catatan      : " + "; ".join(catatan))
    if gagal:
        print(f"\nGAGAL ({len(gagal)} temuan):")
        for g in gagal:
            print(f"  - {g}")
        return 1
    print("\nHASIL: LOLOS — semua pemeriksaan roadmap terpenuhi.")
    return 0


if __name__ == "__main__":
    sys.exit(uji_diri() if "--uji-diri" in sys.argv else main())
