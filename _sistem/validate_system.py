#!/usr/bin/env python3
"""Validator struktur Sistem Building Aplikasi — self-contained (stdlib only).

Dijalankan dari root sistem manapun:
    python3 _sistem/validate_system.py          (cwd = folder sistem)
    python3 sistem/sistem-building-aplikasi/_sistem/validate_system.py   (cwd = root repo meta)

Mengexit 0 bila struktur sistem ini konsisten; 1 + daftar temuan bila tidak.
Aturan yang ditegakkan DI SINI adalah aturan sistem ini sendiri — supaya folder ini tetap bisa diverifikasi saat berdiri sendiri (prinsip folder-mandiri; provenance aturan: sistem regresi meta di repo induk).
"""
import re
import sys
from pathlib import Path

SYS_DIR = Path(__file__).resolve().parent.parent

REQUIRED = [
    "START_DI_SINI.md",
    "SYSTEM_MANIFEST.md",
    "STATUS.md",
    "PANDUAN_PENGGUNA.md",
    "PROMPT_ENTRI_UNIVERSAL.md",
    "10_LOG_SESI.md",
    "AGENT_SYSTEM.md",
    "ACCEPTANCE_TESTS.md",
    "PROFIL_PENGGUNA.md",
]

def check_file_exists(errs):
    for rel in REQUIRED:
        if not (SYS_DIR / rel).is_file():
            errs.append(f"berkas wajib hilang: {rel}")

def check_status_fields(errs):
    """Field deterministik checkpoint (pola kontrak warisan W-03): tepat satu kemuncilan nilai exact, plus Waktu pembaruan bertanggal."""
    for status in sorted(SYS_DIR.rglob("STATUS.md")):
        text = status.read_text(encoding="utf-8")
        n = len(re.findall(r"\*\*Pekerjaan belum tersimpan:\*\*\s*Tidak ada\s*$", text, re.MULTILINE))
        if n != 1:
            errs.append(f"{status.relative_to(SYS_DIR)}: field 'Pekerjaan belum tersimpan: Tidak ada' harus muncul tepat 1x (exact, akhir baris); ditemukan {n}")
        if not re.search(r"\*\*Waktu pembaruan:\*\*\s*\d{4}-\d{2}-\d{2}\s+—\s+\S", text):
            errs.append(f"{status.relative_to(SYS_DIR)}: field 'Waktu pembaruan' harus ada, format 'YYYY-MM-DD — <peristiwa>'")

def check_manifest(errs):
    m = SYS_DIR / "SYSTEM_MANIFEST.md"
    if not m.is_file():
        return
    text = m.read_text(encoding="utf-8")
    if "Dipakai via lmarena" not in text:
        errs.append("SYSTEM_MANIFEST.md tanpa bagian 'Dipakai via lmarena?' (fakta platform)")
    for w in range(1, 10):
        if f"W-0{w}" not in text:
            errs.append(f"SYSTEM_MANIFEST.md tidak menyebut butir Warisan W-0{w}")
    if not re.search(r"^- \*\*Tahap:\*\* `?(kerangka|siap-pakai)`?", text, re.MULTILINE):
        errs.append("SYSTEM_MANIFEST.md: field 'Tahap' wajib terbaca (kerangka|siap-pakai)")
    if not re.search(r"^- \*\*Versi:\*\* `?0\.", text, re.MULTILINE):
        errs.append("SYSTEM_MANIFEST.md: baris Versi tidak ada atau tidak bisa di-parse")

def check_no_meta_operational_refs(errs):
    """Dokumen AKTIF sistem (bukan 00_RENCANA_KERANGKA = riwayat) tidak boleh merujuk _meta/ atau tools/ dengan backtick tanpa salinan berlabel."""
    for doc in sorted(SYS_DIR.rglob("*.md")):
        # AGENT_SYSTEM.md is legacy instruction; its refs to /docs and PROJECT_STATE are internal, not _meta — exempt
        # but check anyway
        if doc.name.startswith("00_RENCANA"):
            continue
        rel = doc.relative_to(SYS_DIR)
        text = doc.read_text(encoding="utf-8")
        for ref in re.findall(r"`((?:_meta|tools)/[^`\s]+)`", text):
            salinan = list((SYS_DIR / "_salinan-meta").glob(Path(ref).name)) if (SYS_DIR / "_salinan-meta").is_dir() else []
            if not salinan:
                errs.append(f"{rel}: rujukan ber-backtick `{ref}` butuh salinan berlabel di _salinan-meta/ (atau tulis tanpa backtick sebagai provenance)")

def check_pegangan(errs):
    pu = SYS_DIR / "PANDUAN_PENGGUNA.md"
    pe = SYS_DIR / "PROMPT_ENTRI_UNIVERSAL.md"
    if pu.is_file() and pe.is_file():
        pu_text = pu.read_text(encoding="utf-8")
        pe_text = pe.read_text(encoding="utf-8")
        # extract first code fence block from each
        def first_block(t):
            m = re.search(r"```\n(.*?)\n```", t, re.DOTALL)
            return m.group(1).strip() if m else ""
        b1 = first_block(pu_text)
        b2 = first_block(pe_text)
        if b1 and b2 and b1 != b2:
            errs.append("PANDUAN_PENGGUNA.md dan PROMPT_ENTRI_UNIVERSAL.md: blok prompt harus identik (cek 2-file)")
        if "PROMPT_ENTRI_UNIVERSAL" not in pu_text:
            errs.append("PANDUAN_PENGGUNA.md: tidak menyebut PROMPT_ENTRI_UNIVERSAL")
        if "Prompt Penutup" not in pu_text:
            errs.append("PANDUAN_PENGGUNA.md: tidak ada Prompt Penutup")


# ---- cek run klinik ke-2 (2026-09-16): anti-dokumen-pengganti-hidup + anti-klaim-basi ----

# Dokumen yang diperlakukan sebagai ARSIP/catatan (bukan dokumen aktif):
ARSIP_DOCS = ("PANDUAN_PEMAKAIAN.md", "REKAM-KLINIK.md", "_Notes.md")
# Penanda wajib di kepala berkas arsip supaya tidak dibaca sebagai aturan berlaku.
PENANDA_ARSIP = {
    "PANDUAN_PEMAKAIAN.md": "SUDAH DIGANTIKAN",
    "REKAM-KLINIK.md": "ARSIP PERAWATAN SISTEM",
    "_Notes.md": "CATATAN PRIBADI PEMILIK",
}
# Area di luar folder sistem yang isinya TIDAK ikut keluar (provenance tanpa backtick).
AREA_LUAR = ("_meta/", "tools/", "_cadangan-claude/", "Input-Pengguna/")
# Dokumen aktif yang kena cek area luar + klaim jumlah direktori skills/.
DOK_AKTIF = ("AGENT_SYSTEM.md", "SYSTEM_MANIFEST.md", "STATUS.md", "PANDUAN_PENGGUNA.md",
             "PROMPT_ENTRI_UNIVERSAL.md", "START_DI_SINI.md", "10_LOG_SESI.md",
             "ACCEPTANCE_TESTS.md", "PROFIL_PENGGUNA.md", "skills/README.md")
ATRIBUT_ROADMAP = ("**Tujuan:**", "**Ref:**", "**File:**", "**DoD", "**Kompleksitas:**",
                   "**Risiko & mitigasi:**", "**Verifikasi:**")


def check_penanda_arsip(errs):
    """Berkas yang digantikan/catatan pribadi WAJIB berpenanda arsip di kepalanya.

    Akar masalah run klinik ke-2 (cacat K-1 / butir katalog Klinik C-07): dokumen yang
    sudah digantikan tetap hidup tanpa penanda, dan isinya bertentangan dengan dokumen
    yang berlaku — pemilik mengikuti dokumen lama dan tersesat di pemakaian pertama.
    """
    for nama, penanda in PENANDA_ARSIP.items():
        p = SYS_DIR / nama
        if not p.is_file():
            continue
        kepala = "\n".join(p.read_text(encoding="utf-8").splitlines()[:12])
        if penanda not in kepala:
            errs.append(f"{nama}: berkas arsip/digantikan wajib memuat penanda '{penanda}' di 12 baris pertama")


def check_tidak_adaklaim_satu_berkas(errs):
    """Tidak boleh ada dokumen aktif yang MENYURUH copy hanya AGENT_SYSTEM.md (cacat K-1).

    Baris yang membantah/mengoreksi klaim lama (memuat penanda sanggahan) dikecualikan —
    koreksi justru wajib menyebut klaim salah itu supaya tidak terulang.
    """
    pola = re.compile(r"(masuk|dimasukk?an|di-copy|copy)[^.\n]{0,60}hanya[^.\n]{0,20}`?AGENT_SYSTEM\.md`?", re.I)
    sanggahan = ("tidak berlaku", "sudah digantikan", "DIGANTIKAN", "salah", "arsip", "ARSIP",
                 "bukan hanya", "SELURUH", "sebut", "menyebut", "pernah")
    for rel in DOK_AKTIF:
        p = SYS_DIR / rel
        if not p.is_file():
            continue
        for i, baris in enumerate(p.read_text(encoding="utf-8").splitlines(), 1):
            if pola.search(baris) and not any(s in baris for s in sanggahan):
                errs.append(f"{rel}:{i}: klaim 'hanya AGENT_SYSTEM.md yang masuk repo' — yang benar SELURUH isi folder (lihat PANDUAN_PENGGUNA.md § Cara Pakai Sebagai Template)")


def check_area_luar_tanpa_backtick(errs):
    """Rujukan ber-backtick ke BERKAS di area luar folder = dependensi yang putus saat folder di-copy.

    Sebutan area berbentuk direktori (mis. `tools/`) TIDAK ditegakkan — sama seperti norma
    alat meta check_selfcontained: itu sebutan area, bukan janji satu berkas ikut.
    """
    for rel in DOK_AKTIF:
        p = SYS_DIR / rel
        if not p.is_file():
            continue
        text = p.read_text(encoding="utf-8")
        pola = r"`((?:%s)[^`\s]+)`" % "|".join(re.escape(a) for a in AREA_LUAR)
        for ref in re.findall(pola, text):
            if ref.endswith("/"):
                continue  # sebutan area, bukan berkas
            errs.append(f"{rel}: rujukan ber-backtick `{ref}` ke berkas di area luar folder — tulis sebagai provenance tanpa backtick (area itu tidak ikut saat folder di-copy jadi repo standalone)")


# Anchor klaim jumlah direktori skills/ — dibandingkan dengan hitungan NYATA tiap run,
# jadi tidak bisa basi (bukan bukti volatil ala C-04). Anchor yang hilang = temuan,
# supaya penyuntingan kalimat tidak diam-diam mematikan cek ini.
ANCHOR_DIR_SKILLS = (
    ("skills/README.md", r"^# Skills .*\((?:maksimal[^)]*?)?(\d+) dirs"),
    ("AGENT_SYSTEM.md", r"total (\d+) dirs"),
    ("SYSTEM_MANIFEST.md", r"(\d+) direktori, [\d.]+ berkas"),
)


def check_klaim_jumlah_dir_skills(errs):
    sk = SYS_DIR / "skills"
    if not sk.is_dir():
        return
    nyata = sum(1 for p in sk.iterdir() if p.is_dir())
    for rel, pola in ANCHOR_DIR_SKILLS:
        p = SYS_DIR / rel
        if not p.is_file():
            errs.append(f"{rel}: berkas anchor klaim jumlah direktori skills/ tidak ada")
            continue
        text = p.read_text(encoding="utf-8")
        m = re.search(pola, text, re.MULTILINE)
        if not m:
            errs.append(f"{rel}: anchor klaim jumlah direktori skills/ tidak ditemukan (pola {pola!r}) — jangan hapus angkanya, segarkan")
        elif int(m.group(1)) != nyata:
            errs.append(f"{rel}: klaim {m.group(1)} direktori skills/ != nyata {nyata} — segarkan (ukur: find skills -mindepth 1 -maxdepth 1 -type d | wc -l)")


def check_template_roadmap_7_atribut(errs):
    """Template ROADMAP wajib mencontohkan 7 atribut task (bukan bentuk singkat yang dilarang)."""
    p = SYS_DIR / "_sistem" / "templates" / "ROADMAP.md"
    if not p.is_file():
        return
    text = p.read_text(encoding="utf-8")
    hilang = [a for a in ATRIBUT_ROADMAP if a not in text]
    if hilang:
        errs.append(f"_sistem/templates/ROADMAP.md: atribut task hilang {hilang} — AGENT_SYSTEM.md Tahap 5 mewajibkan 7 atribut dan melarang bentuk singkat")




# ---- cek run klinik ke-2 putaran 2 (review PR #63): angka korpus & 7 atribut di aturan agent ----

# Dokumen KEADAAN (bukan transkrip): dilarang mengutip angka yang dihitung dari korpus dokumen.
# Dasar: _meta/00_CARA_KERJA_META.md § "Bukti numerik permanen (C5)" + _meta/ACCEPTANCE_TESTS.md AT-16
# ("dilarang dikutip dalam sel Bukti, termasuk jika ditemani atau dipin ke SHA").
# REKAM-KLINIK.md & ACCEPTANCE_TEST_LOG.md SENGAJA dikecualikan: keduanya transkrip append-only —
# baris riwayat yang sudah ter-merge tidak boleh ditulis ulang, jadi kepatuhan di sana dijaga
# oleh kebijakan penulisan (entri baru tanpa angka korpus), bukan oleh cek ini.
DOK_KEADAAN = ("AGENT_SYSTEM.md", "SYSTEM_MANIFEST.md", "STATUS.md", "PANDUAN_PENGGUNA.md",
               "PROMPT_ENTRI_UNIVERSAL.md", "START_DI_SINI.md", "10_LOG_SESI.md",
               "ACCEPTANCE_TESTS.md", "PROFIL_PENGGUNA.md", "docs/README.md", "skills/README.md")
POLA_ANGKA_KORPUS = (
    re.compile(r"\b[1-9]\d*\s*(?:docs|refs?\b|rujukan|path references|active documents|dokumen aktif)", re.I),
    re.compile(r"\b\d+\s*(?:→|->)\s*\d+\s*baris\b"),
)
KUNCI_7_ATRIBUT = ("Tujuan", "Ref", "File", "DoD", "Kompleksitas", "Risiko & mitigasi", "Verifikasi")


def check_no_volatile_corpus_numbers(errs):
    """Angka korpus (jumlah dokumen aktif / rujukan path / transisi jumlah baris) dilarang di
    dokumen keadaan.

    Alasan: angka itu berubah tiap kali ada dokumen atau entri log baru — run klinik ke-2
    membuktikannya sendiri (hitungan nyata 339 → 361 antar-commit, sementara draf bukti sempat
    mengutip 354 dan 360 yang tidak cocok commit mana pun; temuan reviewer R-1/R-2 PR #63).
    Yang boleh dikutip = verdict (PASS, 0 warning, 0 unresolved) + perintah reproduksi, dan angka
    yang stabil terhadap penulisan dokumen (jumlah berkas wajib, jumlah direktori skills/).
    Total byte eksak sebuah folder yang isinya kita sunting juga termasuk volatil (R-3).
    """
    for rel in DOK_KEADAAN:
        p = SYS_DIR / rel
        if not p.is_file():
            continue
        for i, baris in enumerate(p.read_text(encoding="utf-8").splitlines(), 1):
            for pola in POLA_ANGKA_KORPUS:
                m = pola.search(baris)
                if m:
                    errs.append(f"{rel}:{i}: angka korpus '{m.group(0).strip()}' dilarang di dokumen keadaan (C5/AT-16: berubah tiap penulisan dokumen/log) — tulis verdict + perintah ukur, bukan angkanya")


def check_7_atribut_di_aturan_agent(errs):
    """Kalimat aturan + contoh format task di AGENT_SYSTEM.md Tahap 5 wajib memuat 7 atribut
    yang sama dengan _sistem/templates/ROADMAP.md.

    Review PR #63 (putaran 1) menemukan contoh inline di AGENT_SYSTEM.md hanya memuat 6 atribut
    (tanpa Tujuan) dan kalimat aturannya pun hanya menyebut 6 — berkas itu bertentangan dengan
    butir 3-nya sendiri ("WAJIB punya 7 atribut lengkap"). Keluarga cacat C-07.
    """
    p = SYS_DIR / "AGENT_SYSTEM.md"
    if not p.is_file():
        return
    text = p.read_text(encoding="utf-8")
    kalimat = [b for b in text.splitlines() if b.startswith("Setiap task **harus** punya")]
    if not kalimat:
        errs.append("AGENT_SYSTEM.md: kalimat aturan 'Setiap task **harus** punya' tidak ditemukan — jangan hapus aturan 7 atribut Tahap 5")
    else:
        hilang = [a for a in KUNCI_7_ATRIBUT if a.lower() not in kalimat[0].lower()]
        if hilang:
            errs.append(f"AGENT_SYSTEM.md: kalimat aturan task belum menyebut atribut {hilang} — wajib 7, sama dengan _sistem/templates/ROADMAP.md")
    # Contoh format task = blok berpagar yang memuat "## Fase 1:" — semua 7 label wajib ada DI DALAMNYA
    # (menghitung kemunculan di seluruh berkas terbukti terlalu lemah: satu contoh bisa dihapus
    # tanpa mengurangi jumlah kemunculan di bawah ambang).
    label_wajib = ("**Tujuan:**", "**Ref:**", "**File:**", "**DoD:**", "**Kompleksitas:**",
                   "**Risiko & mitigasi:**", "**Verifikasi:**")
    blok = [b for b in re.split(r"```", text) if "## Fase 1:" in b]
    if not blok:
        errs.append("AGENT_SYSTEM.md: contoh format ROADMAP (blok berpagar berisi '## Fase 1:') tidak ditemukan — jangan hapus contohnya")
    else:
        # per TASK, bukan per blok: satu task contoh yang kehilangan atribut tetap cacat walau
        # task contoh lain memuatnya (pembaca menyalin bentuk task yang di depannya).
        for tugas in re.split(r"\n(?=- \[ \] Task )", blok[0]):
            if not tugas.startswith("- [ ] Task"):
                continue
            hilang = [a for a in label_wajib if a not in tugas]
            if hilang:
                errs.append(f"AGENT_SYSTEM.md: contoh '{tugas.splitlines()[0][:45]}' kehilangan atribut {hilang} — tiap task contoh wajib memuat 7 atribut, sama dengan _sistem/templates/ROADMAP.md")



# ---- cek ke-8 (2026-09-16, putaran 3): scan rujukan AT-08 ditanam jadi gerbang permanen ----
# Rujukan ber-backtick dengan prefix INTERNAL wajib nyata ada di dalam folder ini: saat folder
# di-copy jadi repo standalone (AT-08), rujukan yang menggantung mengarahkan pembaca ke berkas
# yang tidak ada. Sebelumnya kelas ini HANYA tertangkap saat AT-08 dijalankan manual, dan sudah
# tiga kali lolos dari prose penulis sendiri di run ini — terakhir: teks koreksi di
# ACCEPTANCE_TEST_LOG.md mengutip log sesi level repo meta dengan backtick (AT-08 menangkapnya,
# validator tidak). Menanamnya di sini membuat gerbang menyala tiap `validate_system`.
PREFIX_INTERNAL = ("_sistem/", "skills/", "docs/", "_log-sesi/", "_salinan-meta/")
# Cakupan pindai = dokumen aktif + dokumen bukti/arsip milik folder ini. Vendor TIDAK dipindai
# (kecuali README kita sendiri): rujukan di dalam skill adalah urusan internal skill itu, bukan
# janji terhadap tata letak folder ini — memindainya hanya menghasilkan positif palsu.
DOK_SCAN_RUJUKAN = DOK_AKTIF + ("ACCEPTANCE_TEST_LOG.md", "PANDUAN_PEMAKAIAN.md", "REKAM-KLINIK.md",
                                "docs/README.md", "_sistem/templates/ROADMAP.md",
                                "_sistem/templates/AGENT_OPERATING_GUIDE.md")
# Token yang jelas bukan path (pola/placeholder/perintah), bukan janji satu berkas ada.
TOKEN_BUKAN_PATH = ("*", "<", ">", "{", "}", "|", "$", "=", "%", "..")


def check_no_dangling_internal_refs(errs):
    """Rujukan ber-backtick berprefix internal wajib ADA di dalam folder (scan AT-08, versi gerbang)."""
    for rel in DOK_SCAN_RUJUKAN:
        p = SYS_DIR / rel
        if not p.is_file():
            continue
        for i, baris in enumerate(p.read_text(encoding="utf-8").splitlines(), 1):
            for tok in re.findall(r"`([^`\s]+)`", baris):
                if not tok.startswith(PREFIX_INTERNAL):
                    continue
                if any(c in tok for c in TOKEN_BUKAN_PATH):
                    continue
                target = SYS_DIR / tok.rstrip("/")
                ada = target.is_dir() if tok.endswith("/") else target.exists()
                if not ada:
                    errs.append(
                        f"{rel}:{i}: rujukan ber-backtick `{tok}` tidak ada di dalam folder — di repo "
                        "standalone (AT-08) ini jadi rujukan menggantung; perbaiki path-nya atau tulis "
                        "sebagai provenance tanpa backtick (berkas level repo meta tidak ikut ter-copy)")


def main():
    errs = []
    check_file_exists(errs)
    check_status_fields(errs)
    check_manifest(errs)
    check_no_meta_operational_refs(errs)
    check_pegangan(errs)
    check_penanda_arsip(errs)
    check_tidak_adaklaim_satu_berkas(errs)
    check_area_luar_tanpa_backtick(errs)
    check_klaim_jumlah_dir_skills(errs)
    check_template_roadmap_7_atribut(errs)
    check_no_volatile_corpus_numbers(errs)
    check_7_atribut_di_aturan_agent(errs)
    check_no_dangling_internal_refs(errs)
    if errs:
        print("SYSTEM-BUILDING-APLIKASI VALIDATOR: GAGAL")
        for e in errs:
            print(f"- {e}")
        return 1
    print("SYSTEM-BUILDING-APLIKASI VALIDATOR: PASS")
    return 0

if __name__ == "__main__":
    sys.exit(main())
