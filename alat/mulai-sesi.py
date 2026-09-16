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
    "FONDASI_TAHAP_1": ["product-discovery/discovery-interview-prep", "product-discovery/journey-map",
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
    "DESAIN": ["ui-ux-pro-max", "design", "design-system", "ui-styling", "frontend-designer",
               "brand", "banner-design", "web-design-guidelines", "slides"],
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


def skill_untuk(status: str) -> list[str]:
    for kunci, daftar in PHASE_SKILLS.items():
        if kunci in status.upper():
            return daftar + SELALU
    return SELALU


def main() -> int:
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
    daftar_skill = skill_untuk(status)

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
    print(f"  Tersedia total: {len(skills)} berkas SKILL.md di skills/ (lokal, tanpa internet)")
    ada, kurang = 0, []
    for s in daftar_skill:
        p = ROOT / "skills" / s / "SKILL.md"
        if p.is_file():
            ada += 1
            print(f"  [ ] skills/{s}/SKILL.md — {judul_skill(p)}")
        else:
            kurang.append(s)
            print(f"  [!] skills/{s}/SKILL.md — TIDAK ADA (laporkan, jangan dilewati)")
    print(f"  → Jumlah: {ada} berkas siap dibaca" + (f", {len(kurang)} perlu dilaporkan" if kurang else ""))
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


if __name__ == "__main__":
    sys.exit(main())
