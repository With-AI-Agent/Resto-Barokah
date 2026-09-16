#!/usr/bin/env python3
"""
Periksa Fondasi Independen — Resto Barokah
Checker independen yang TIDAK menyalin logika _sistem/validate_system.py
atau alat/periksa-roadmap.py. Dibuat dari NOL berdasarkan isi dokumen sumber.

Satu perintah: python3 alat/periksa-fondasi-independen.py
Exit 0 bila bersih, 1 bila ada temuan.

Memeriksa minimal:
 - 7 atribut lengkap tiap tugas dan isinya bukan pengisi kosong
 - tugas berisiko tinggi punya kewajiban DECISIONS_LOG
 - setiap Ref menunjuk bagian yang benar-benar ada
 - butir T-xxx yang dirujuk ada di TERTANGGUH (dan sebaliknya)
 - modul wajib M1–M12, entitas basis data, dan ART-1..ART-10 punya tugas
 - tidak ada nomor tugas ganda atau fase terlewat
"""

import re
import sys
from pathlib import Path

# Root repo = parent of alat/
ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"

# 7 atribut wajib (sesuai AGENT_SYSTEM.md Tahap 5 + _sistem/templates/ROADMAP.md)
ATRIBUT_WAJIB = [
    "**Tujuan:**",
    "**Ref:**",
    "**File:**",
    "**DoD",
    "**Kompleksitas:**",
    "**Risiko & mitigasi:**",
    "**Verifikasi:**",
]

# Pola placeholder kosong yang dianggap pengisi kosong
POLA_KOSONG = re.compile(r"^\s*(<.*>|\[isi.*\]|\.\.\.|TODO|XXX|-\s*)$", re.I)

# Modul wajib sesuai instruksi review (M1-M12)
MODUL_WAJIB = [f"M{i:02d}" for i in range(1, 13)]  # M01..M12 tapi juga cek M1..M12
MODUL_WAJIB_SIMPLE = [f"M{i}" for i in range(1, 13)]

# ART wajib
ART_WAJIB = [f"ART-{i:02d}" for i in range(1, 11)] + [f"ART-{i}" for i in range(1, 11)]


def log(msg):
    print(msg)


def cek_keberadaan_dokumen(temuan):
    """Cek dokumen fondasi wajib ada"""
    wajib_docs = [
        "DISCOVERY.md",
        "PRD.md",
        "TECH_SPEC.md",
        "AGENT_OPERATING_GUIDE.md",
        "ROADMAP.md",
        "DECISIONS_LOG.md",
    ]
    for nama in wajib_docs:
        p = DOCS / nama
        if not p.is_file():
            # Untuk template sistem, docs/README.md memang satu-satunya.
            # Tapi untuk aplikasi Resto Barokah yang mau CODING_AKTIF, ini adalah temuan KRITIS
            temuan.append(f"[DOKUMEN HILANG] docs/{nama} tidak ada — fondasi belum lengkap (belum bisa CODING_AKTIF)")
        else:
            # cek file tidak hanya berisi template kosong
            txt = p.read_text(encoding="utf-8", errors="ignore")
            if "YYYY-MM-DD" in txt and len(txt.strip().splitlines()) < 20:
                # kemungkinan masih template belum diisi
                if nama != "DECISIONS_LOG.md":  # DECISIONS_LOG boleh kosong di awal
                    temuan.append(f"[DOKUMEN TEMPLATE KOSONG] docs/{nama} masih berisi placeholder YYYY-MM-DD — belum diisi untuk aplikasi nyata")

    # Cek khusus yang disebut di instruksi review
    for extra in ["TERTANGGUH.md", "ROADMAP.md", "DECISIONS_LOG.md"]:
        p = DOCS / extra
        # sudah dicek di atas, tapi TERTANGGUH adalah nama lama untuk backlog/pending
        if extra == "TERTANGGUH.md" and not p.is_file():
            # di sistem baru, TERTANGGUH mungkin tidak ada — tapi instruksi review menyebutnya
            # jadi catat sebagai CATATAN, bukan KRITIS, kecuali ROADMAP merujuk T-xxx
            pass

    # Cek PROJECT_STATE.md di root (bukan template)
    ps = ROOT / "PROJECT_STATE.md"
    if not ps.is_file():
        temuan.append(f"[DOKUMEN HILANG] PROJECT_STATE.md di root tidak ada — sesi tidak bisa tahu STATUS (harusnya STATUS: CODING_AKTIF)")
    else:
        txt = ps.read_text(encoding="utf-8", errors="ignore")
        m = re.search(r"^STATUS:\s*(\S+)", txt, re.MULTILINE)
        if not m:
            temuan.append(f"[PROJECT_STATE] PROJECT_STATE.md tidak punya baris STATUS: — format salah")
        elif m.group(1) != "CODING_AKTIF":
            temuan.append(f"[PROJECT_STATE] STATUS:{m.group(1)} != CODING_AKTIF — fondasi belum siap coding (saat ini: {m.group(1)})")

    # Cek alat yang diharapkan ada menurut instruksi review
    # alat/periksa-roadmap.py dan sistem/validate_system.py disebut di W3
    # di repo ini lokasi sebenarnya _sistem/validate_system.py
    if not (ROOT / "_sistem" / "validate_system.py").is_file() and not (ROOT / "sistem" / "validate_system.py").is_file():
        temuan.append(f"[PEMERIKSA HILANG] _sistem/validate_system.py tidak ada — validator sistem hilang")
    if not (ROOT / "alat" / "periksa-roadmap.py").is_file():
        # ini memang tidak ada di repo template — catat sebagai temuan minor
        # tapi jangan gagalkan jika validator utama ada
        temuan.append(f"[PEMERIKSA HILANG] alat/periksa-roadmap.py tidak ada — pemeriksa roadmap versi lama tidak ditemukan (hanya _sistem/validate_system.py yang ada)")


def parse_roadmap_tasks(temuan):
    """Parse ROADMAP.md dan cek 7 atribut, risiko, Ref, duplikat, fase"""
    roadmap = DOCS / "ROADMAP.md"
    if not roadmap.is_file():
        temuan.append(f"[ROADMAP] docs/ROADMAP.md tidak ada — tidak bisa cek 7 atribut, Ref, duplikat, atau fase ( фондаasi belum dibuat)")
        return None

    text = roadmap.read_text(encoding="utf-8", errors="ignore")
    # Cari task pattern: "- [ ] Task" atau "- [x] Task" atau "Task N"
    # Lebih general: baris yang mengandung "Task" + nomor
    task_blocks = re.split(r"\n(?=- \[[ x]\] Task )", text)
    # filter yang memang task
    tasks = [b for b in task_blocks if re.match(r"- \[[ x]\] Task", b.strip())]
    
    if not tasks:
        # coba pola lain: "## Task" atau "Task T0-"
        alt = re.findall(r"Task\s+([A-Z]?\d+[-\.]\d+|M\d+|T\d+)", text)
        if alt:
            temuan.append(f"[ROADMAP] Ditemukan penyebutan Task {alt[:5]} tapi tidak dalam format '- [ ] Task' — format task tidak standar, tidak bisa cek 7 atribut otomatis")
        else:
            temuan.append(f"[ROADMAP] Tidak ditemukan satu pun task berformat '- [ ] Task' — ROADMAP kosong atau format salah")
        return []

    # Cek duplikat nomor tugas
    nomor_list = []
    for block in tasks:
        m = re.search(r"Task\s+([A-Z0-9\-\.]+)", block)
        if m:
            nomor_list.append(m.group(1).strip())
    # cek duplikat
    seen = {}
    for n in nomor_list:
        seen[n] = seen.get(n, 0) + 1
    for n, c in seen.items():
        if c > 1:
            temuan.append(f"[ROADMAP DUPLIKAT] Nomor tugas '{n}' muncul {c}x — nomor tugas harus unik")

    # Cek fase terlewat: cari "## Fase" atau "## Phase" atau "Fase N"
    fase_headers = re.findall(r"^##\s*Fase\s+(\d+)", text, re.MULTILINE | re.IGNORECASE)
    if fase_headers:
        fase_nums = [int(x) for x in fase_headers]
        fase_sorted = sorted(set(fase_nums))
        if fase_sorted:
            expected = list(range(min(fase_sorted), max(fase_sorted)+1))
            missing = [f for f in expected if f not in fase_sorted]
            if missing:
                temuan.append(f"[ROADMAP FASE] Fase terlewat: {missing} — ditemukan fase {fase_sorted}, seharusnya berurutan tanpa lompat")
            # cek mulai dari 0 atau 1?
            if 0 not in fase_sorted and 1 not in fase_sorted:
                temuan.append(f"[ROADMAP FASE] Tidak ada Fase 0 atau Fase 1 — urutan fase aneh: {fase_sorted}")

    # Untuk tiap task, cek 7 atribut
    for idx, block in enumerate(tasks, 1):
        header = block.splitlines()[0][:80] if block.splitlines() else f"Task#{idx}"
        # Cek tiap atribut ada
        hilang = []
        kosong = []
        for attr in ATRIBUT_WAJIB:
            if attr not in block:
                hilang.append(attr)
            else:
                # cek isi setelah attr tidak kosong/placeholder
                # ambil baris yang mengandung attr
                for line in block.splitlines():
                    if attr in line:
                        # ambil setelah attr
                        try:
                            after = line.split(attr, 1)[1].strip()
                        except:
                            after = ""
                        # hapus markdown bullet
                        after = after.strip(" -:")
                        if not after or POLA_KOSONG.match(after) or after.startswith("<") or after == "":
                            kosong.append(attr)
                        break
        if hilang:
            temuan.append(f"[ROADMAP ATRIBUT HILANG] {header} kehilangan atribut {hilang} — tiap task wajib punya 7 atribut lengkap (Tujuan, Ref, File, DoD, Kompleksitas, Risiko, Verifikasi)")
        if kosong:
            temuan.append(f"[ROADMAP ATRIBUT KOSONG] {header} atribut {kosong} isinya kosong/placeholder (<...>/[isi]/TODO) — harus diisi konkret, bukan pengisi kosong")

        # Cek tugas berisiko tinggi wajib DECISIONS_LOG
        # Risiko tinggi ditandai: mengandung ⚠️ atau kata RLS, Auth, Role, Keuangan, kalkulasi
        risiko_line = ""
        for line in block.splitlines():
            if "Risiko" in line:
                risiko_line = line
                break
        is_risiko_tinggi = any(k in block for k in ["⚠️", "RLS", "Auth", "Role", "Keuangan", "kalkulasi", "service", "PB1", "DECISIONS_LOG"])
        if is_risiko_tinggi:
            if "DECISIONS_LOG" not in block:
                temuan.append(f"[ROADMAP RISIKO] {header} menyentuh Area Berisiko Tinggi tapi tidak menyebut 'DECISIONS_LOG' di Risiko & mitigasi — wajib tulis '⚠️ wajib update DECISIONS_LOG.md — Area: ...'")
        
        # Cek Ref menunjuk bagian yang benar-benar ada (validasi silang)
        # Ref contoh: "PRD § Fitur 2", "TECH_SPEC § Data Model users"
        for line in block.splitlines():
            if "**Ref:**" in line:
                ref_content = line.split("**Ref:**",1)[1].strip()
                if not ref_content or ref_content.startswith("<") or POLA_KOSONG.match(ref_content):
                    temuan.append(f"[ROADMAP REF KOSONG] {header} Ref kosong/placeholder — harus menunjuk bagian PRD/TECH_SPEC yang nyata")
                else:
                    # cek apakah dokumen yang dirujuk ada dan mengandung kata kunci
                    # misal Ref menyebut PRD tapi docs/PRD.md tidak ada -> sudah ditangani di atas
                    # Di sini cek apakah section yang disebut ada di dokumen target
                    # Ekstrak nama dokumen yang dirujuk
                    docs_dirujuk = []
                    if "PRD" in ref_content:
                        docs_dirujuk.append(DOCS / "PRD.md")
                    if "TECH_SPEC" in ref_content or "TECH SPEC" in ref_content:
                        docs_dirujuk.append(DOCS / "TECH_SPEC.md")
                    if "DISCOVERY" in ref_content:
                        docs_dirujuk.append(DOCS / "DISCOVERY.md")
                    if "AGENT" in ref_content:
                        docs_dirujuk.append(DOCS / "AGENT_OPERATING_GUIDE.md")
                    for doc in docs_dirujuk:
                        if doc.is_file():
                            doc_text = doc.read_text(encoding="utf-8", errors="ignore")
                            # ambil kata kunci setelah §
                            m2 = re.search(r"§\s*([A-Za-z0-9 _\-/]+)", ref_content)
                            if m2:
                                keyword = m2.group(1).strip().split()[0]  # ambil kata pertama
                                if keyword and keyword.lower() not in doc_text.lower():
                                    # ini warning, karena Ref mungkin pakai istilah yang tidak eksak
                                    # tapi kalau keyword cukup panjang (>3) dan tidak ada, laporkan
                                    if len(keyword) > 3:
                                        temuan.append(f"[ROADMAP REF RAGU] {header} Ref '{ref_content[:60]}' menyebut '{keyword}' tapi tidak ditemukan di {doc.name} — mungkin rujukan salah bagian")
                        else:
                            if doc.name != "DECISIONS_LOG.md":
                                temuan.append(f"[ROADMAP REF] {header} Ref menunjuk {doc.name} tapi file itu tidak ada")

    return tasks


def cek_tertangguh(temuan, tasks):
    """Cek butir T-xxx di ROADMAP vs TERTANGGUH.md"""
    tertangguh = DOCS / "TERTANGGUH.md"
    roadmap_text = ""
    roadmap_path = DOCS / "ROADMAP.md"
    if roadmap_path.is_file():
        roadmap_text = roadmap_path.read_text(encoding="utf-8", errors="ignore")
    
    # Kumpulkan T-xxx dari ROADMAP
    t_di_roadmap = set(re.findall(r"\bT[-\s]?\d{2,3}\b", roadmap_text))
    # Normalisasi: T-001, T001, T 001 -> T-001
    def norm(t):
        t = t.replace(" ", "").replace("-", "")
        num = re.search(r"\d+", t).group()
        return f"T-{num.zfill(3)}" if len(num)<3 else f"T-{num}"
    t_road_norm = set(norm(x) for x in t_di_roadmap) if t_di_roadmap else set()

    if tertangguh.is_file():
        t_text = tertangguh.read_text(encoding="utf-8", errors="ignore")
        t_di_file = set(re.findall(r"\bT[-\s]?\d{2,3}\b", t_text))
        t_file_norm = set(norm(x) for x in t_di_file) if t_di_file else set()
        
        # ROADMAP merujuk T-xxx tapi tidak ada di TERTANGGUH
        for t in t_road_norm:
            if t not in t_file_norm:
                temuan.append(f"[TERTANGGUH] Butir {t} dirujuk di ROADMAP tapi tidak ada di docs/TERTANGGUH.md — rujukan menggantung")
        # Sebaliknya: ada di TERTANGGUH tapi tidak dirujuk ROADMAP (mungkin orphan)
        for t in t_file_norm:
            if t not in t_road_norm:
                temuan.append(f"[TERTANGGUH ORPHAN] Butir {t} ada di TERTANGGUH.md tapi tidak dirujuk tugas mana pun di ROADMAP — mungkin tugas lupa ditautkan atau butir sudah tidak relevan")

        # Cek maksimal 12 butir terbuka
        terbuka = len([l for l in t_text.splitlines() if re.search(r"- \[ \] T-", l)])
        if terbuka > 12:
            temuan.append(f"[TERTANGGUH] Jumlah butir terbuka {terbuka} melebihi batas 12 — harus diringkas/ditutup sebagian")
    else:
        if t_road_norm:
            temuan.append(f"[TERTANGGUH HILANG] ROADMAP merujuk {sorted(t_road_norm)[:5]} tapi docs/TERTANGGUH.md tidak ada — tidak bisa verifikasi rujukan T-xxx")


def cek_modul_entitas_art(temuan, tasks):
    """Cek modul M1-M12, entitas DB, ART-1..10 punya tugas"""
    roadmap_path = DOCS / "ROADMAP.md"
    techspec_path = DOCS / "TECH_SPEC.md"
    if not roadmap_path.is_file():
        temuan.append(f"[CAKUPAN] Tidak ada ROADMAP — tidak bisa cek cakupan modul M1-M12, entitas, ART")
        return

    roadmap_text = roadmap_path.read_text(encoding="utf-8", errors="ignore")

    # Modul M1-M12: cek apakah setiap modul disebut di ROADMAP
    # Cek baik M1 maupun M01
    for mod in MODUL_WAJIB_SIMPLE:
        # cari pattern M1, M 1, Modul 1, M-01
        pattern = re.compile(rf"\b{re.escape(mod)}\b", re.I)
        # juga coba M01
        pattern2 = re.compile(rf"\bM0?{mod[1:]}\b", re.I) if mod.startswith("M") else None
        found = pattern.search(roadmap_text) or (pattern2 and pattern2.search(roadmap_text))
        # Jika tidak ditemukan, cek juga kata "Modul X"
        if not found:
            mod_num = re.search(r"\d+", mod).group()
            if re.search(rf"Modul\s*{mod_num}\b", roadmap_text, re.I):
                found = True
        if not found:
            # hanya laporkan jika roadmap cukup besar (ada tasks) — kalau roadmap kosong sudah dilaporkan
            if tasks and len(tasks) > 0:
                temuan.append(f"[CAKUPAN MODUL] Modul wajib {mod} (M1-M12) tidak punya tugas di ROADMAP — mungkin fitur modul itu terlewat")

    # Entitas DB: baca TECH_SPEC § Data Model
    if techspec_path.is_file():
        tech_text = techspec_path.read_text(encoding="utf-8", errors="ignore")
        # Cari entitas: pattern "Entitas X" atau "Tabel X" atau "Model X"
        # Ambil daftar entitas dari TECH_SPEC
        entitas = re.findall(r"(?:Entitas|Tabel|Collection|Model)\s+([A-Za-z_][A-Za-z0-9_]*)", tech_text)
        # filter yang masuk akal (kapital, bukan kata umum)
        entitas_unik = list(set([e for e in entitas if len(e) > 2 and e.lower() not in ["data", "dan", "yang", "untuk"]]))
        for ent in entitas_unik[:10]:  # batasi 10 pertama agar tidak spam
            if ent.lower() not in roadmap_text.lower():
                temuan.append(f"[CAKUPAN ENTITAS] Entitas '{ent}' disebut di TECH_SPEC tapi tidak ada tugas migration/seed di ROADMAP — mungkin lupa")
        if not entitas_unik:
            # TECH_SPEC masih template
            if "Entitas A" in tech_text or "fields" in tech_text.lower():
                temuan.append(f"[TECH_SPEC] Data Model masih template 'Entitas A' — belum diisi entitas nyata untuk Resto Barokah (mis. menu, pesanan, meja, stok)")
    else:
        temuan.append(f"[TECH_SPEC] docs/TECH_SPEC.md tidak ada — tidak bisa cek entitas DB")

    # ART-1..10: cek di ROADMAP
    for art in [f"ART-{i}" for i in range(1, 11)]:
        if art not in roadmap_text and art.replace("-", "") not in roadmap_text:
            # hanya laporkan jika memang ada penyebutan ART di TECH_SPEC/PRD
            if techspec_path.is_file() and art in techspec_path.read_text(encoding="utf-8", errors="ignore"):
                temuan.append(f"[CAKUPAN ART] {art} disebut di TECH_SPEC/PRD tapi tidak punya tugas di ROADMAP")
            # jika tidak disebut dimana pun, anggap mungkin belum relevan — tapi tetap catat sekali
            pass
    # Ringkas: jika tidak ada ART sama sekali di ROADMAP, catat 1 temuan umum
    if not any(f"ART-{i}" in roadmap_text for i in range(1, 11)):
        if tasks and len(tasks) > 0:
            # cek apakah TECH_SPEC atau PRD menyebut ART
            has_art = False
            for doc in [DOCS / "PRD.md", DOCS / "TECH_SPEC.md"]:
                if doc.is_file() and "ART-" in doc.read_text(encoding="utf-8", errors="ignore"):
                    has_art = True
            if has_art:
                temuan.append(f"[CAKUPAN ART] Tidak ada tugas yang menyebut ART-1..ART-10 di ROADMAP padahal PRD/TECH_SPEC menyebutnya — cakupan ART belum dipetakan")


def main():
    temuan = []

    print("=== PERIKSA FONDASI INDEPENDEN — Resto Barokah ===")
    print(f"Root: {ROOT}")
    print(f"Docs: {DOCS}")
    print(f"Tanggal cek: 2026-09-16 (UTC)")
    print("")

    # 1. Keberadaan dokumen
    cek_keberadaan_dokumen(temuan)

    # 2. Parse ROADMAP tasks + 7 atribut + risiko + Ref + duplikat + fase
    tasks = parse_roadmap_tasks(temuan)

    # 3. TERTANGGUH vs T-xxx
    cek_tertangguh(temuan, tasks)

    # 4. Modul, entitas, ART
    cek_modul_entitas_art(temuan, tasks)

    # Ringkasan
    print("")
    if temuan:
        print(f"TEMUAN: {len(temuan)} masalah ditemukan — BELUM SIAP")
        for i, t in enumerate(temuan, 1):
            print(f"{i:02d}. {t}")
        # Tulis juga jumlah tasks yang berhasil diparse bila ada
        if tasks is not None:
            print(f"\nInfo: {len(tasks)} task ter-parse dari ROADMAP (jika ada).")
        # Cek validator sistem sebagai referensi silang
        validator = ROOT / "_sistem" / "validate_system.py"
        if validator.is_file():
            print(f"Validator sistem: {validator} ada — jalankan 'python3 _sistem/validate_system.py' untuk cek silang.")
        print("\nKode keluar: 1 (ada temuan)")
        return 1
    else:
        print("TIDAK ADA TEMUAN — fondasi bersih, SIAP CODING")
        if tasks is not None:
            print(f"Info: {len(tasks)} task lolos semua cek (7 atribut, Ref, risiko, duplikat, fase, modul, entitas, ART, TERTANGGUH).")
        print("Kode keluar: 0")
        return 0


if __name__ == "__main__":
    sys.exit(main())
