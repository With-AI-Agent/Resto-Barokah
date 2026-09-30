#!/usr/bin/env python3
"""periksa-push — bukti bahwa hasil giliran benar-benar ADA di GitHub (arahan Lee 2026-09-30).

Lee (2026-09-30): "hasilnya harus masuk github supaya agen di sesi lain bisa liat dan bisa integrasikan." Sesi lain (Perencana, Hakim,
integrasi `alat/pmb-integrasi.py`) hanya melihat apa yang ada di `origin`; commit lokal yang belum ter-push sama dengan tidak ada.

Alat ini bertanya langsung ke remote (`git ls-remote`, bukan `origin/<cabang>` lokal yang bisa basi) lalu membandingkannya dengan HEAD:
  • TER-PUSH  — tip origin == HEAD dan pohon kerja bersih → cetak baris siap tempel:  `- **Ter-push sampai:** `<sha>``
  • BELUM     — HEAD mendahului origin (ada commit lokal), pohon kotor, atau cabang belum pernah di-push → kode keluar 1 + perintah perbaikan
Pakai:  python3 alat/periksa-push.py [--cabang <nama>] [--diam]
Kode keluar: 0 ter-push · 1 belum ter-push / pohon kotor · 2 tidak bisa bertanya ke origin (jaringan/izin) — jangan dianggap ter-push.
Di CI (GITHUB_ACTIONS=true) alat ini tidak bermakna (checkout = origin) → keluar 0 tanpa bertanya.
"""
from __future__ import annotations

import os
import pathlib
import subprocess
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent


def git(*args: str) -> tuple[int, str]:
    p = subprocess.run(["git", *args], cwd=AKAR, capture_output=True, text=True)
    return p.returncode, (p.stdout + p.stderr).strip()


def main(argv: list[str]) -> int:
    diam = "--diam" in argv
    if os.environ.get("GITHUB_ACTIONS") == "true":
        print("periksa-push: dijalankan di CI (checkout = origin) — tidak ada yang diperiksa.")
        return 0
    cabang = argv[argv.index("--cabang") + 1] if "--cabang" in argv else git("rev-parse", "--abbrev-ref", "HEAD")[1]
    if cabang in ("", "HEAD"):
        print("BELUM: HEAD terlepas (detached) — tidak ada cabang yang bisa di-push. `git switch <cabangmu>` dulu.")
        return 1
    _, head = git("rev-parse", "HEAD")
    _, kotor = git("status", "--porcelain")
    kode, ls = git("ls-remote", "origin", f"refs/heads/{cabang}")
    if kode != 0:
        print(f"TIDAK BISA BERTANYA ke origin ({ls.splitlines()[0] if ls else 'tanpa pesan'}) — jangan menganggap ter-push; ulangi saat GitHub tersambung.")
        return 2
    tip = ls.split()[0] if ls else ""
    masalah: list[str] = []
    if not tip:
        masalah.append(f"cabang `{cabang}` belum pernah ada di origin → `git push -u origin {cabang}`")
    elif tip != head:
        kode_anc, _ = git("merge-base", "--is-ancestor", tip, head)
        if kode_anc == 0:
            n = git("rev-list", "--count", f"{tip}..{head}")[1]
            masalah.append(f"HEAD `{head[:7]}` mendahului origin `{tip[:7]}` sebanyak {n} commit → `git push origin {cabang}`")
        else:
            masalah.append(f"origin `{tip[:7]}` bukan leluhur HEAD `{head[:7]}` (cabang bercabang — ada pihak lain yang push?) → "
                           f"`git fetch origin {cabang}` lalu selesaikan tanpa force-push")
    if kotor:
        masalah.append(f"pohon kerja belum bersih ({len(kotor.splitlines())} berkas) → commit dulu, baru push")
    if masalah:
        print(f"BELUM TER-PUSH — {cabang}:")
        for m in masalah:
            print("  ×", m)
        return 1
    if not diam:
        print(f"TER-PUSH sampai {head[:7]} — origin/{cabang} == HEAD, pohon bersih (dipastikan ls-remote).")
        print("Tempel ke kartu B / laporan akhir giliran:")
    print(f"- **Ter-push sampai:** `{head[:7]}`")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
