#!/usr/bin/env python3
"""ci_target.py — memeriksa status CI pada commit TARGET paket audit/review.

Kenapa ada (temuan audit H F-02, K-3, 2026-09-20): protokol sudah mewajibkan "paket hanya boleh
menargetkan commit ber-CI hijau", tetapi **tidak ada yang menegakkannya** — paket AUD-3
2026-09-19 menargetkan commit `4830b5a` yang dua run CI-nya `cancelled` (ditimpa push berikutnya).
Akibatnya auditor memeriksa pohon yang tidak pernah melewati gerbang otomatis, sementara paketnya
tampak "sudah terverifikasi".

Cara kerja: tanya GitHub Actions lewat `gh api` untuk daftar run pada SHA itu, lalu simpulkan
hijau/tidak. Bila `gh` tidak tersedia/gagal (offline, tanpa izin), hasilnya **"tidak bisa diperiksa"**
— bukan "hijau": ketidak-tahuan tidak boleh dibaca sebagai bukti aman.
"""
from __future__ import annotations

import json
import pathlib
import re
import subprocess
import sys

PATH_ALUR_CI = ".github/workflows/ci.yml"


def nama_repo(akar: pathlib.Path) -> str | None:
    """`owner/nama` dari remote origin (untuk panggilan API), atau None bila tidak bisa dibaca."""
    try:
        hasil = subprocess.run(["git", "config", "--get", "remote.origin.url"], cwd=akar,
                               capture_output=True, text=True, timeout=15)
    except (OSError, subprocess.SubprocessError):
        return None
    url = (hasil.stdout or "").strip()
    m = re.search(r"github\.com[:/]+([^/]+)/([^/\s]+?)(?:\.git)?$", url)
    return f"{m.group(1)}/{m.group(2)}" if m else None


def status_ci(sha: str, akar: pathlib.Path, batas_detik: int = 25) -> dict:
    """Status CI untuk satu SHA.

    Kembalikan dict:
      * `bisa`   — True bila GitHub bisa dihubungi & dibaca (kalau False, JANGAN anggap hijau)
      * `hijau`  — True bila ada run `success` pada SHA itu
      * `run`    — id run hijau (bila ada)
      * `rincian`— ringkas untuk laporan/paket, mis. "success (run 123) | cancelled x2"
    """
    # SHA pendek harus diperluas: filter `head_sha` GitHub menuntut SHA penuh.
    if sha and len(sha) < 40:
        try:
            hasil_sha = subprocess.run(["git", "rev-parse", sha], cwd=akar,
                                       capture_output=True, text=True, timeout=15)
            if hasil_sha.returncode == 0:
                sha = hasil_sha.stdout.strip()[:40]
        except (OSError, subprocess.SubprocessError):
            pass
    repo = nama_repo(akar)
    if not repo:
        return {"bisa": False, "hijau": False, "run": None,
                "rincian": "tidak bisa dibaca (remote origin tidak dikenali)"}
    try:
        hasil = subprocess.run(
            ["gh", "api", f"repos/{repo}/actions/runs?head_sha={sha}&per_page=20"],
            cwd=akar, capture_output=True, text=True, timeout=batas_detik,
        )
    except (OSError, subprocess.SubprocessError) as e:
        return {"bisa": False, "hijau": False, "run": None,
                "rincian": f"tidak bisa diperiksa lewat gh ({type(e).__name__})"}
    if hasil.returncode != 0:
        return {"bisa": False, "hijau": False, "run": None,
                "rincian": f"tidak bisa diperiksa lewat gh (kode {hasil.returncode})"}
    try:
        data = json.loads(hasil.stdout or "{}")
    except json.JSONDecodeError:
        return {"bisa": False, "hijau": False, "run": None, "rincian": "jawaban gh tidak terbaca"}
    runs = data.get("workflow_runs", [])
    # Query head_sha juga mengembalikan workflow deploy/release pada SHA yang sama.
    # Hanya `.github/workflows/ci.yml` adalah gerbang CI paket; nama workflow saja
    # tidak cukup karena nama dapat berubah/bertabrakan (B-F08).
    runs_ci = [
        r for r in runs
        if r.get("path") == PATH_ALUR_CI and r.get("head_sha") == sha
    ]
    if not runs_ci:
        return {"bisa": True, "hijau": False, "run": None,
                "rincian": f"TIDAK ADA run CI `{PATH_ALUR_CI}` untuk commit itu"}
    hijau = [r for r in runs_ci if r.get("conclusion") == "success"]
    if hijau:
        return {"bisa": True, "hijau": True, "run": hijau[0]["id"],
                "rincian": f"success (run {hijau[0]['id']}, `{PATH_ALUR_CI}`)"}
    # Run yang masih berjalan belum punya `conclusion` — laporkan statusnya (queued/in_progress)
    # supaya pesannya jelas, bukan "None".
    ringkas = ", ".join(sorted({str(r.get("conclusion") or r.get("status") or "?") for r in runs_ci}))
    return {"bisa": True, "hijau": False, "run": None,
            "rincian": f"BELUM HIJAU — {len(runs_ci)} run CI pada commit itu: {ringkas}"}


def uji_diri() -> int:
    """Fixture B-F08: sukses workflow lain tidak boleh menyamarkan CI gagal."""
    sha = "e" * 40
    asli_run = subprocess.run

    kasus = [
        (
            "CI gagal + sebar sukses pada SHA sama → tetap BELUM HIJAU",
            [
                {"id": 2, "path": ".github/workflows/sebar-halaman.yml", "head_sha": sha, "conclusion": "success"},
                {"id": 1, "path": PATH_ALUR_CI, "head_sha": sha, "conclusion": "failure"},
            ],
            False,
        ),
        (
            "CI sukses pada SHA sama → HIJAU",
            [{"id": 3, "path": PATH_ALUR_CI, "head_sha": sha, "conclusion": "success"}],
            True,
        ),
        (
            "sebar sukses tanpa run CI → BELUM HIJAU",
            [{"id": 4, "path": ".github/workflows/sebar-skema.yml", "head_sha": sha, "conclusion": "success"}],
            False,
        ),
    ]
    gagal = 0
    try:
        for nama, runs, harap in kasus:
            def fake_run(cmd, *args, _runs=runs, **kwargs):
                if cmd[:2] == ["git", "config"]:
                    return subprocess.CompletedProcess(cmd, 0, "https://github.com/With-AI-Agent/Resto-Barokah.git\n", "")
                return subprocess.CompletedProcess(cmd, 0, json.dumps({"workflow_runs": _runs}), "")
            subprocess.run = fake_run
            hasil = status_ci(sha, pathlib.Path("."))
            ok = hasil["hijau"] is harap
            gagal += int(not ok)
            print(f"{'OK' if ok else 'GAGAL'} {nama}: hijau={hasil['hijau']} rincian={hasil['rincian']}")
    finally:
        subprocess.run = asli_run
    print(f"HASIL UJI-DIRI CI TARGET: {'LOLOS' if not gagal else 'GAGAL'} — {len(kasus)} kasus, {gagal} tidak sesuai.")
    return int(bool(gagal))


def baris_paket(sha: str, akar: pathlib.Path, izin_pemilik: str | None = None) -> str:
    """Baris bukti CI yang ditulis ke dalam paket (dibaca penjaga `alat/periksa-paket.py`)."""
    st = status_ci(sha, akar)
    if st["hijau"]:
        return f"- **CI commit target:** success (run {st['run']}) — diperiksa mesin terhadap commit `{sha}`"
    if not st["bisa"]:
        baris = (f"- **CI commit target:** TIDAK BISA DIPERIKSA dari mesin ini ({st['rincian']}) — "
                 f"wajib diperiksa pemilik/penjaga sebelum paket diserahkan")
    else:
        baris = f"- **CI commit target:** BELUM-HIJAU ({st['rincian']})"
    # Izin pemilik WAJIB tetap tercetak walau CI tak bisa diperiksa — kalau tidak, pengecualian
    # jadi diam-diam dan penjaga paket tak bisa membedakan paket berizin dari paket lalai.
    if izin_pemilik:
        baris += f"\n- **Izin pemilik untuk commit non-hijau:** {izin_pemilik}"
    return baris


if __name__ == "__main__":
    raise SystemExit(uji_diri() if "--uji-diri" in sys.argv else 0)
