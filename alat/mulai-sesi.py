#!/usr/bin/env python3
"""mulai-sesi.py — Bootstrap sesi agent untuk proyek "Resto Barokah".

Jalankan dari mana saja (script mencari sendiri akar repo):

    python3 alat/mulai-sesi.py

Kegunaan: setiap sesi baru bisa memakai MODEL AI yang berbeda dari sesi sebelumnya dan
tidak punya ingatan apa pun. Script ini mencetak KARTU SESI: posisi proyek, keadaan
branch/PR, log sesi terbaru, berkas fondasi yang wajib dibaca, dan DAFTAR SKILL yang
wajib dibaca untuk fase sekarang (semua skill sudah tersimpan lokal di skills/ — tidak
perlu internet, tidak perlu npx).

Aturan pemakaian (lihat docs/AGENT_OPERATING_GUIDE.md § Pemasangan Skill Otomatis):
  1. Agent menjalankan script ini PALING AWAL di setiap sesi.
  2. Agent MEMBACA sungguhan setiap berkas yang tercantum (skill + fondasi).
  3. Agent melaporkan KARTU SESI (terisi lengkap) ke pemilik SEBELUM bekerja.
  4. Kalau ada skill yang kurang untuk fase ini → LAPORKAN, jangan dilewati diam-diam.
"""
from __future__ import annotations

import datetime as _dt
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def baca(rel: str) -> str:
    p = ROOT / rel
    return p.read_text(encoding="utf-8", errors="replace") if p.is_file() else ""


def sh(*args: str) -> str:
    try:
        r = subprocess.run(args, cwd=ROOT, capture_output=True, text=True, timeout=25)
        return (r.stdout or r.stderr).strip()
    except Exception as e:  # noqa: BLE001
        return f"(gagal menjalankan {' '.join(args)}: {e})"


def sh2(*args: str) -> tuple[int, str]:
    """Sama seperti sh(), tapi mengembalikan (kode keluaran, teks) supaya 'kosong' bisa dibedakan dari 'gagal'."""
    try:
        r = subprocess.run(args, cwd=ROOT, capture_output=True, text=True, timeout=25)
        return r.returncode, (r.stdout or r.stderr).strip()
    except Exception as e:  # noqa: BLE001
        return -1, f"(gagal menjalankan {' '.join(args)}: {e})"



# ---------------------------------------------------------------- fase → skill wajib
# Semua path di bawah `skills/`. Cuplikan ini SENGAJA tegas supaya sesi berikutnya tidak
# menebak-nebak skill mana yang relevan.
PHASE_SKILLS = {
    "FONDASI_TAHAP_1": ["product-discovery/discovery-interview-prep", "product-discovery/customer-journey-map",
                        "product-management", "brainstorming", "writing-plans"],
    "FONDASI_TAHAP_2": ["product-management/prd-development", "product-management/prioritization-advisor",
                        "prd-taskmaster", "product-discovery/opportunity-solution-tree"],
    "FONDASI_TAHAP_3": ["supabase", "supabase-postgres-best-practices", "cloudflare", "wrangler",
                        "vercel-react-best-practices", "security-review", "excalidraw-diagram",
                        "ai-agent-skills/skills/best-practices"],
    "FONDASI_TAHAP_4": ["ai-agent-skills/skills/best-practices", "tdd-workflow", "verification-loop",
                        "security-review", "writing-plans"],
    "FONDASI_TAHAP_5": ["product-discovery/roadmap-planning", "product-management/prioritization-advisor",
                        "writing-plans", "prd-taskmaster"],
    "FONDASI_TAHAP_6": ["verification-loop", "verification-before-completion", "security-review",
                        "systematic-debugging"],
    "CODING_AKTIF": ["vercel-react-best-practices", "building-components", "vercel-composition-patterns",
                     "supabase", "supabase-postgres-best-practices", "cloudflare", "wrangler",
                     "tdd-workflow", "test-driven-development", "systematic-debugging",
                     "verification-before-completion", "agent-browser", "security-review",
                     "ai-agent-skills/skills/best-practices"],
    # `desain-antarmuka` = ilmu yang DIPELAJARI DARI INTERNET lalu disimpan sebagai kemampuan
    # (permintaan pemilik 2026-09-17: "jangan hanya disimpan, tapi juga harus digunakan").
    # Wajib dibaca SEBELUM mengubah tampilan; dijaga `aplikasi/alat/periksa-antarmuka.py`.
    "DESAIN": ["desain-antarmuka", "ui-ux-pro-max", "design", "design-system", "ui-styling", "frontend-designer",
               "brand", "banner-design", "web-design-guidelines", "slides"],
    # Siklus baru (TAHAP 0.5 AGENT_SYSTEM.md) = merancang v2: gali kebutuhan ulang, timbang prioritas,
    # tulis roadmap baru. Tanpa baris ini, STATUS `SIKLUS_BARU` tercetak TANPA satu pun skill —
    # kelas cacat yang sama dengan `CODING_DIJEDA_SADAR` (tertangkap uji-diri 2026-09-18).
    "SIKLUS_BARU": ["product-discovery/roadmap-planning", "product-management/prioritization-advisor",
                    "product-discovery/opportunity-solution-tree", "writing-plans", "verification-loop"],
}
SELALU = ["find-skills"]  # untuk mencari skill yang belum terpasang (usulkan dulu, jangan pasang sendiri)

FONDASI_WAJIB = ["AGENT_SYSTEM.md", "PROFIL_PENGGUNA.md", "PROJECT_STATE.md", "STATUS.md",
                 "docs/DISCOVERY.md", "docs/PRD.md", "docs/TECH_SPEC.md",
                 "docs/AGENT_OPERATING_GUIDE.md", "docs/TERTANGGUH.md"]
FONDASI_CODING = ["docs/ROADMAP.md", "docs/DECISIONS_LOG.md", "prototipe/README.md"]


def butir_tertangguh(path: Path) -> list[tuple[str, str, str]]:
    """Ambil butir terbuka dari docs/TERTANGGUH.md → [(ID, judul singkat, tenggat)]."""
    if not path.is_file():
        return []
    hasil = []
    for baris in path.read_text(encoding="utf-8", errors="replace").splitlines():
        m = re.match(r"^\|\s*(T-\d{3})\s*\|(.+)\|\s*$", baris)
        if not m:
            continue
        sel = [x.strip() for x in m.group(2).split("|")]
        if len(sel) < 7 or "terbuka" not in sel[-1].lower():
            continue
        judul = re.sub(r"[*`]", "", sel[1])[:60]
        hasil.append((m.group(1), judul, sel[4]))
    return hasil



def judul_skill(path: Path) -> str:
    for baris in path.read_text(encoding="utf-8", errors="replace").splitlines():
        b = baris.strip()
        if b.startswith("#"):
            return b.lstrip("# ").strip()[:72]
    return "(tanpa judul)"


# Nilai STATUS yang tertulis di AGENT_SYSTEM.md (tabel cabang PROJECT_STATE).
STATUS_KANONIK = ("FONDASI_TAHAP_1_DISCOVERY", "FONDASI_TAHAP_2_PRD", "FONDASI_TAHAP_3_TECH_SPEC",
                  "FONDASI_TAHAP_4_AGENT_GUIDE", "FONDASI_TAHAP_5_ROADMAP", "FONDASI_TAHAP_6_CROSS_CHECK",
                  "CODING_AKTIF", "SIKLUS_BARU")

# STATUS nyata boleh bernama lebih rinci dari tabel di atas — contoh yang benar-benar
# terjadi 2026-09-18: `CODING_DIJEDA_SADAR` (coding aktif, tapi dijeda atas permintaan
# pemilik). Dulu pemetaannya `kunci in status`, sehingga STATUS seperti itu TIDAK cocok ke
# baris mana pun dan KARTU SESI hanya mencetak 1 skill (find-skills) — sesi coding jadi
# berjalan tanpa daftar skill wajib. Yang menentukan skill adalah **keluarga fase**, bukan
# nama persisnya; kalau namanya menyimpang, cetak catatan (bukan diam-diam mengurangi skill).
KELUARGA_FASE = (
    ("DESAIN", ("DESAIN",)),
    ("CODING_AKTIF", ("CODING",)),
    ("SIKLUS_BARU", ("SIKLUS",)),
    ("FONDASI_TAHAP_6", ("TAHAP_6", "CROSS_CHECK")),
    ("FONDASI_TAHAP_5", ("TAHAP_5", "ROADMAP")),
    ("FONDASI_TAHAP_4", ("TAHAP_4", "AGENT_GUIDE", "OPERATING")),
    ("FONDASI_TAHAP_3", ("TAHAP_3", "TECH_SPEC")),
    ("FONDASI_TAHAP_2", ("TAHAP_2", "PRD")),
    ("FONDASI_TAHAP_1", ("TAHAP_1", "DISCOVERY")),
)


def skill_terpilih(rel: str) -> tuple[list[Path], str]:
    """(daftar SKILL.md yang harus dibaca, keterangan untuk kartu).

    Kenapa perlu: `skills/product-management/` dan `skills/product-discovery/` adalah
    DIREKTORI INDUK — tidak ada `SKILL.md` di akarnya, isinya sub-skill (lihat
    AGENT_SYSTEM.md §"Catatan path & 6 direktori agregat": "jangan menyimpulkan skill tidak
    ada hanya karena SKILL.md tidak ada di akar direktori"). Kartu lama menyebut induk begitu
    `TIDAK ADA (laporkan)` — laporan palsu yang bisa membuat sesi melewatkan skill.
    """
    akar = ROOT / "skills" / rel
    langsung = akar / "SKILL.md"
    if langsung.is_file():
        return [langsung], judul_skill(langsung)
    anak = sorted(p for p in akar.rglob("SKILL.md")) if akar.is_dir() else []
    if anak:
        nama = ", ".join(p.parent.name for p in anak[:6])
        lagi = f" (+{len(anak) - 6} lagi)" if len(anak) > 6 else ""
        return anak, f"direktori induk — baca yang relevan dari: {nama}{lagi}"
    return [], "TIDAK ADA di repo — LAPORKAN, jangan dilewati diam-diam"


def fase_untuk(status: str) -> tuple[str, list[str], list[str]]:
    """(kunci fase, daftar skill wajib, catatan) untuk STATUS PROJECT_STATE.

    Catatan TIDAK pernah kosong diam-diam: kalau nama STATUS menyimpang dari tabel
    AGENT_SYSTEM.md, itu dilaporkan di kartu supaya sesi baru bisa memeriksa sendiri.
    """
    catatan: list[str] = []
    s = (status or "").strip().upper()
    if not s or "TIDAK TERBACA" in s:
        return "", list(SELALU), ["STATUS tidak terbaca dari `PROJECT_STATE.md` — "
                                  "daftar skill TIDAK bisa dipastikan, periksa berkas itu dulu"]
    kunci = next((k for k in PHASE_SKILLS if k in s), None)
    if kunci is None:
        pendek = (status.strip()[:60] + "…") if len(status.strip()) > 60 else status.strip()
        for k, penanda in KELUARGA_FASE:
            if any(p in s for p in penanda):
                kunci = k
                catatan.append(f"STATUS `{pendek}` bukan salah satu nilai kanonik AGENT_SYSTEM.md — "
                               f"skill diambil dari keluarga fase **{k}** (bukan dikosongkan)")
                break
    if kunci is None:
        pendek = (status.strip()[:60] + "…") if len(status.strip()) > 60 else status.strip()
        return "", list(SELALU), [f"STATUS `{pendek}` tidak cocok ke fase mana pun di "
                                  f"`PHASE_SKILLS` — hanya skill wajib-selalu yang tercetak; "
                                  f"LAPORKAN ini dan pilih skill manual untuk pekerjaanmu"]
    return kunci, list(PHASE_SKILLS[kunci]) + list(SELALU), catatan


def skill_untuk(status: str) -> list[str]:
    return fase_untuk(status)[1]


def kartu(akar: Path | None = None) -> int:
    """Cetak KARTU SESI. `akar` dipakai mode --uji-diri supaya bisa dijalankan di salinan."""
    global ROOT
    if akar is not None:
        ROOT = Path(akar)
    hari_ini = _dt.date.today().isoformat()
    ps = baca("PROJECT_STATE.md")
    st = baca("STATUS.md")

    m_status = re.search(r"^STATUS:\s*(.+)$", ps, re.M)
    status = m_status.group(1).strip() if m_status else "(tidak terbaca)"
    m_detail = re.search(r"^DETAIL:\s*(.+)$", ps, re.M)
    detail = (m_detail.group(1).strip() if m_detail else "")[:300]
    m_update = re.search(r"^UPDATE TERAKHIR:\s*(.+)$", ps, re.M)
    update = m_update.group(1).strip() if m_update else "(tidak ada)"

    bersih = len(re.findall(r"\*\*Pekerjaan belum tersimpan:\*\*\s*Tidak ada\s*$", st, re.M))
    waktu = re.search(r"\*\*Waktu pembaruan:\*\*\s*(\d{4}-\d{2}-\d{2}\s+—\s+[^\n]+)", st)
    waktu_teks = (waktu.group(1)[:150] + "…") if waktu else "(tidak terbaca)"

    branch = sh("git", "branch", "--show-current") or "(tidak terbaca)"
    commit = sh("git", "log", "--oneline", "-1")
    kotor = sh("git", "status", "--short")
    kode_pr, teks_pr = sh2("gh", "pr", "list", "--state", "all", "--limit", "5")
    pr = teks_pr if teks_pr else ("(tidak ada PR)")

    # Jarak terhadap basis (main): berapa commit sesi ini yang belum masuk main.
    basis, jarak = "main", "(tidak terbaca)"
    for kandidat in ("main", "origin/main"):
        kode, _ = sh2("git", "rev-parse", "--verify", kandidat)
        if kode == 0:
            basis = kandidat
            jarak = sh("git", "rev-list", "--count", f"{kandidat}..HEAD")
            break

    log_files = sorted((ROOT / "_log-sesi").glob("LOG_SESI_*.md")) if (ROOT / "_log-sesi").is_dir() else []
    log_baru = log_files[-1] if log_files else None
    keadaan_log = "(tidak ada log sesi)"
    if log_baru is not None:
        teks = log_baru.read_text(encoding="utf-8", errors="replace")
        mk = re.search(r"\*\*Keadaan:\*\*\s*`?([A-Z\- ]+)`?", teks)
        keadaan_log = mk.group(1).strip() if mk else "(tidak terbaca)"

    skills = sorted(p for p in (ROOT / "skills").rglob("SKILL.md"))
    kunci_fase, daftar_skill, catatan_fase = fase_untuk(status)

    print("=" * 78)
    print(f"KARTU SESI — Resto Barokah — {hari_ini}")
    print("=" * 78)
    print("POSISI PROYEK")
    print(f"  STATUS           : {status}")
    print(f"  UPDATE TERAKHIR  : {update}")
    print(f"  DETAIL (potongan): {detail}")
    print(f"  STATUS.md        : field deterministik {'OK (1x)' if bersih == 1 else 'BERMASALAH (' + str(bersih) + 'x)'}"
          + f" · {waktu_teks}")
    print()
    print("BRANCH & PR (fakta platform lmarena)")
    print(f"  Branch aktif     : {branch}  (dibuat otomatis platform; JANGAN pindah branch)")
    print(f"  Basis branch     : {basis} · {jarak} commit sesi ini belum masuk {basis} (PR tanpa auto-merge)")
    print(f"  Commit terakhir  : {commit or '(kosong)'}")
    print(f"  Working tree     : {'BERSIH' if not kotor else 'KOTOR — ' + str(len(kotor.splitlines())) + ' berkas belum di-commit'}")
    print(f"  PR (terakhir 5)  : {pr}")
    print(f"  LOG_SESI terbaru : {log_baru.name if log_baru else '(tidak ada)'} — keadaan: {keadaan_log}")
    print()
    print("SKILL WAJIB UNTUK FASE INI — BACA SUNGGUHAN SEBELUM BEKERJA")
    print(f"  Fase terdeteksi  : {kunci_fase or '(tidak ada — lihat catatan di bawah)'}"
          + (f" · {len(daftar_skill)} skill" if daftar_skill else ""))
    for c in catatan_fase:
        print(f"  [catatan] {c}")
    print(f"  Tersedia total: {len(skills)} berkas SKILL.md di skills/ (lokal, tanpa internet)")
    ada, kurang, berkas_siap = 0, [], 0
    for s in daftar_skill:
        daftar_berkas, ket = skill_terpilih(s)
        if daftar_berkas:
            ada += 1
            berkas_siap += len(daftar_berkas)
            if len(daftar_berkas) == 1:
                print(f"  [ ] skills/{s}/SKILL.md — {ket}")
            else:
                print(f"  [ ] skills/{s} → {len(daftar_berkas)} berkas — {ket}")
        else:
            kurang.append(s)
            print(f"  [!] skills/{s}/SKILL.md — {ket}")
    print(f"  → Jumlah: {berkas_siap} berkas siap dibaca (dari {ada} entri wajib)"
          + (f", {len(kurang)} perlu dilaporkan" if kurang else ""))
    print()
    # Handoff lanjut-sesi: baris ini membuat sesi baru tahu apakah punya penunjuk keadaan
    # yang segar, atau justru sedang berada di basis yang tertinggal (temuan nyata: sesi baru
    # selalu mulai dari `main`, sedangkan pekerjaan hidup di cabang sesi).
    sipl = ROOT / "docs" / "ops" / "SIAP-LANJUT.md"
    print("HANDOFF LANJUT-SESI (agar sesi baru tidak kehilangan konteks)")
    if not sipl.is_file():
        print("  [!] docs/ops/SIAP-LANJUT.md TIDAK ADA — jalankan `python3 alat/lanjut-sesi.py --siapkan`")
    else:
        teks_sipl = sipl.read_text(encoding="utf-8", errors="replace")
        mc = re.search(r"Commit keadaan kerja:\*\*\s*`([0-9a-f]{40})`", teks_sipl)
        mcb = re.search(r"Cabang kerja terakhir:\*\*\s*`([^`]+)`", teks_sipl)
        sha_sipl = mc.group(1) if mc else "(tidak terbaca)"
        cabang_sipl = mcb.group(1) if mcb else "(tidak terbaca)"
        _, gap = sh2("git", "rev-list", "--count", f"{sha_sipl}..HEAD")
        print(f"  Berkas handoff : docs/ops/SIAP-LANJUT.md (cabang {cabang_sipl})")
        print(f"  Commit keadaan : {sha_sipl[:8]}" + (f" · {gap} commit di atasnya" if gap.isdigit() else ""))
        if sha_sipl != "(tidak terbaca)" and sha_sipl not in commit:
            print("  [catatan] normal: commit keadaan handoff = INDUK commit terakhir (handoff ditulis sebelum "
                  "commit penutup batch ini); ujung cabangmu sudah benar bila commit terakhirnya menyentuh "
                  "docs/ops/SIAP-LANJUT.md")
    print()
    print("BERKAS FONDASI WAJIB DIBACA FASE INI")
    for rel in FONDASI_WAJIB + (FONDASI_CODING if "CODING" in status.upper() else []):
        tanda = "ADA  " if (ROOT / rel).is_file() else "TIDAK"
        print(f"  [{tanda}] {rel}")
    print()
    tunggu = butir_tertangguh(ROOT / "docs" / "TERTANGGUH.md")
    print("DAFTAR TUNGGU (docs/TERTANGGUH.md) — WAJIB DIBACA & DILAPORKAN")
    if tunggu:
        print(f"  Terbuka: {len(tunggu)} butir" + (" — MELAMPAUI BATAS 12: WAJIB BERHENTI & MINTA KEPUTUSAN PEMILIK" if len(tunggu) > 12 else ""))
        for tid, judul, tenggat in tunggu:
            print(f"  [ ] {tid} — {judul} (tenggat: {tenggat})")
    else:
        print("  (tidak ada butir terbuka / berkas belum ada — bila fase coding, laporkan sebagai temuan)")
    print()
    print("KARTU SESI YANG WAJIB DILAPORKAN KE PEMILIK (salin, isi bagian dalam <...>)")
    print("  ---------------------------------------------------------------")
    print(f"  KARTU SESI {hari_ini}")
    print("  - Model sesi ini        : <sebutkan; jangan asumsikan sama dengan sesi sebelumnya>")
    print(f"  - STATUS proyek         : {status}")
    print(f"  - Branch / commit       : {branch} @ {commit}")
    print("  - Working tree          : BERSIH/KOTOR (+ jumlah berkas)")
    print("  - LOG_SESI sebelumnya   : " + (f"{log_baru.name} ({keadaan_log})" if log_baru else "(tidak ada)"))
    print(f"  - Skill terpasang       : <jumlah> berkas dari <jumlah> skill (daftar di atas)")
    print(f"  - Tertangguh dibaca     : {len(tunggu)} butir terbuka" + (f" (ID: {', '.join(t[0] for t in tunggu)})" if tunggu else "") + " — <bukti sudah dibaca>")
    print("  - Fondasi yang dibaca   : <daftar berkas yang benar-benar dibaca>")
    print("  - Posisi sekarang       : <1 baris: sedang di tahap/fase apa>")
    print("  - Rencana sesi ini      : <1-2 baris>")
    print("  - Yang dibutuhkan darimu: <kalau ada>")
    print("  ---------------------------------------------------------------")
    print()
    print("LANGKAH SELANJUTNYA (urutan wajib): 1) baca skill di atas 2) baca fondasi yang ADA")
    print("3) laporkan KARTU SESI 4) tunggu konfirmasi tujuan 5) kerja 6) tutup dengan")
    print("PROJECT_STATE + STATUS + LOG_SESI + COMMIT & PUSH (tanpa push, sesi berikutnya buta).")
    return 0


def _muat_dari_teks(teks: str, nama: str):
    """Muat salinan sumber modul ini (boleh sudah dimutasi) supaya uji-diri menguji LOGIKA,
    bukan ingatan tentang logika."""
    import importlib.util
    import tempfile

    arah = Path(tempfile.mkdtemp(prefix="uji-diri-mulai-sesi-"))
    berkas = arah / f"{nama}.py"
    berkas.write_text(teks, encoding="utf-8")
    spec = importlib.util.spec_from_file_location(nama, berkas)
    modul = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(modul)
    return modul


def uji_diri() -> int:
    """Buktikan pemetaan STATUS → skill memang peka: rusak pemetaannya, pastikan hasilnya berubah.

    Standar proyek (PROTOKOL_AUDIT_INDEPENDEN §8): pemeriksa yang tidak bisa MERAH dianggap
    belum terpasang. Kelas cacat yang ditutup di sini nyata dan pernah terjadi: STATUS
    `CODING_DIJEDA_SADAR` (2026-09-18) tidak cocok ke satu pun baris pemetaan lama, sehingga
    KARTU SESI hanya mencetak 1 skill dan sesi coding bisa lewat tanpa daftar skill wajib.
    """
    from bantu_uji_diri import laporkan

    sumber = Path(__file__).resolve().read_text(encoding="utf-8")
    asli = _muat_dari_teks(sumber, "mulai_sesi_asli")
    hasil: list[tuple[str, bool, str]] = []

    def cek(nama: str, sesuai: bool, ringkas: str) -> None:
        hasil.append((nama, sesuai, ringkas))

    # --- kasus dasar (modul asli harus berperilaku benar) ---
    k, d, c = asli.fase_untuk("CODING_DIJEDA_SADAR (audit selesai; jangan lanjut)")
    cek("status jeda → keluarga fase CODING_AKTIF + skill coding lengkap",
        k == "CODING_AKTIF" and all(s in d for s in ("supabase-postgres-best-practices", "security-review",
                                                      "tdd-workflow", "find-skills")) and bool(c),
        f"fase={k} · {len(d)} skill · {len(c)} catatan")
    k2, d2, c2 = asli.fase_untuk("FONDASI_TAHAP_2_PRD")
    cek("tahap PRD → skill product-management, tanpa catatan",
        k2 == "FONDASI_TAHAP_2" and "product-management/prd-development" in d2 and not c2,
        f"fase={k2} · {len(d2)} skill · {len(c2)} catatan")
    k3, d3, c3 = asli.fase_untuk("(tidak terbaca)")
    cek("STATUS tak terbaca → hanya skill wajib-selalu + catatan keras",
        k3 == "" and d3 == asli.SELALU and bool(c3), f"{len(d3)} skill + catatan")
    for s in asli.STATUS_KANONIK:
        k, d, _ = asli.fase_untuk(s)
        cek(f"STATUS kanonik `{s}` tidak kehilangan daftar skill",
            bool(k) and len(d) > len(asli.SELALU), f"fase={k or '(kosong)'} · {len(d)} skill")
    # semua skill yang dijanjikan daftar wajib benar-benar ada di `skills/`
    # (diecek terhadap repo ASLI — modul yang dimuat dari folder sementara punya ROOT sendiri)
    REPO = Path(__file__).resolve().parents[1]
    asli.ROOT = REPO
    hilang = [x for daftar in asli.PHASE_SKILLS.values() for x in daftar
              if not asli.skill_terpilih(x)[0]]
    cek("semua skill wajib ada di repo (tidak melapor palsu)", not hilang,
        "semua ada" if not hilang else f"TIDAK ADA: {', '.join(hilang)}")
    # direktori induk (product-management, product-discovery) wajib diakui, bukan disebut hilang
    induk, ket_induk = asli.skill_terpilih("product-management")
    cek("direktori induk SKILL.md tidak dilaporkan palsu sebagai 'TIDAK ADA'",
        len(induk) > 1 and "induk" in ket_induk, f"{len(induk)} sub-skill dikenali")
    cek("skill yang benar-benar hilang tetap dilaporkan",
        not asli.skill_terpilih("skill-yang-tidak-ada-xyz")[0]
        and "TIDAK ADA" in asli.skill_terpilih("skill-yang-tidak-ada-xyz")[1],
        "dilaporkan sebagai TIDAK ADA")

    # --- mutasi: pemetaan yang dirusak HARUS mengubah hasil (kalau tidak, pengujiannya tumpul) ---
    def uji_mutasi(nama: str, teks: str, harapkan_berbeda: bool) -> None:
        modul = _muat_dari_teks(teks, "mulai_sesi_mutan")
        sama = [(modul.fase_untuk(s)[:2]) == asli.fase_untuk(s)[:2]
                for s in ("CODING_DIJEDA_SADAR", "CODING_AKTIF", "FONDASI_TAHAP_2_PRD")]
        identik = all(sama)
        cek(f"mutasi: {nama}", identik != harapkan_berbeda,
            "terdeteksi" if identik != harapkan_berbeda else "TIDAK terdeteksi (tumpul)")

    uji_mutasi("keluarga CODING dihapus dari pemetaan",
               sumber.replace('    ("CODING_AKTIF", ("CODING",)),\n', '', 1), True)
    uji_mutasi("daftar skill CODING dikosongkan",
               sumber.replace('    "CODING_AKTIF": ["vercel-react-best-practices"',
                              '    "CODING_AKTIF": [], "_unused": ["vercel-react-best-practices"', 1), True)
    uji_mutasi("skill wajib-selalu (find-skills) tidak lagi ditambahkan",
               sumber.replace("return kunci, list(PHASE_SKILLS[kunci]) + list(SELALU), catatan",
                              "return kunci, list(PHASE_SKILLS[kunci]), catatan", 1), True)
    # Mutasi 4: hapus seluruh jalan keluar "keluarga fase" (penanda CODING/SIKLUS/DESAIN) —
    # STATUS yang namanya menyimpang harus kembali tanpa skill, dan itu harus TERDETEKSI.
    teks_keluarga = sumber
    for penanda in ('    ("CODING_AKTIF", ("CODING",)),\n',
                    '    ("SIKLUS_BARU", ("SIKLUS",)),\n',
                    '    ("DESAIN", ("DESAIN",)),\n'):
        teks_keluarga = teks_keluarga.replace(penanda, '')
    uji_mutasi("jalan keluar keluarga fase dihapus (STATUS menyimpang → tanpa skill)",
               teks_keluarga, True)

    def uji_mutasi_skill(nama: str, teks: str) -> None:
        """Mutasi yang menyerang `skill_terpilih` (penguraian direktori induk)."""
        modul = _muat_dari_teks(teks, "mulai_sesi_mutan")
        modul.ROOT = REPO

        def hilang_dari(m):
            return [x for daftar in m.PHASE_SKILLS.values() for x in daftar if not m.skill_terpilih(x)[0]]

        berubah = hilang_dari(asli) != hilang_dari(modul)
        cek(f"mutasi: {nama}", berubah, "terdeteksi" if berubah else "TIDAK terdeteksi (tumpul)")

    uji_mutasi_skill("penyelesaian direktori induk dihapus (sub-skill dianggap tidak ada)",
                     sumber.replace('    anak = sorted(p for p in akar.rglob("SKILL.md")) if akar.is_dir() else []',
                                    '    anak = []', 1))

    return laporkan("PEMETAAN STATUS → SKILL (alat/mulai-sesi.py)", hasil)


def main() -> int:
    if "--uji-diri" in sys.argv:
        return uji_diri()
    return kartu()


if __name__ == "__main__":
    sys.exit(main())
