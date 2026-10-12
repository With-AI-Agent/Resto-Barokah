#!/usr/bin/env python3
"""rantai-bukti-giliran — menjalankan rantai CI yang SAMA dengan GitHub (.github/workflows/ci.yml, job `periksa`) di komputer sendiri,
TANPA berhenti di kegagalan pertama, lalu mencetak ringkasan per langkah. Untuk sesi giliran PMB (Pembangun) dan Perencana sebelum integrasi.

Kenapa ada (pelajaran 2026-09-30, cabang arena/01a0eff7): `bash aplikasi/alat/periksa-semua.sh` memakai `set -e` dan pada cabang giliran ia
MATI di `alat/lanjut-sesi.py` (handoff bukan urusan giliran) — 60 baris pemeriksaan sesudahnya (periksa-bersih, periksa-uji, …) TIDAK
pernah berjalan, tetapi kartu Pembangun menulis "semua pemeriksaan substantif LOLOS". CI lalu MERAH pada `aplikasi/alat/periksa-uji.py`.
Alat ini membaca langkah CI langsung dari ci.yml (tidak ada daftar kedua yang bisa basi), menjalankan setiap perintah satu per satu, dan
tidak pernah menyimpulkan "LOLOS" untuk perintah yang tidak dijalankan.

Pakai:  python3 alat/rantai-bukti-giliran.py [--simpan docs/uji/pemeriksaan/PMB-1/bukti/B-<ID>-rantai.txt] [--cepat [--basis <rev>]] [--pasang]
  --simpan   tulis log lengkap (keluaran tiap perintah) ke berkas itu; ringkasan tetap dicetak ke layar.
  --cepat    lewati `python3 alat/uji-mutasi-NNNN.py` KECUALI 0012, 0014, dan skrip mutasi yang berubah sejak --basis (bawaan: merge-base
             dengan origin/main). Ringkasannya ditandai "RANTAI CEPAT" — BUKAN setara CI penuh; sebelum menyatakan selesai jalankan tanpa --cepat.
  --pasang   ikut menjalankan langkah pemasangan (`npm ci`, `npm ci --prefix alat`); bawaan: dilewati bila node_modules sudah ada.
Langkah yang gagal hanya karena tanpa internet (`npm audit`, `npm run cek:supabase`: "fetch failed"/ENOTFOUND/…) dicatat "tak terbukti" — bukan
GAGAL dan bukan LOLOS; CI GitHub yang memutuskan. Bila pohon kerja kotor saat dijalankan (mis. sisa skrip mutasi yang terputus), ringkasan
menandainya: hasilnya bukan bukti untuk commit terakhir.
Dilewati selalu (butuh rahasia/jaringan GitHub): langkah dengan `env: … secrets.…` (cek Supabase) dan langkah checkout/setup-node.
Kode keluar: 0 semua LOLOS · 1 ada GAGAL · 2 ci.yml tidak terbaca.
"""
from __future__ import annotations

import os
import pathlib
import re
import subprocess
import sys
import time

AKAR = pathlib.Path(__file__).resolve().parent.parent
CI = AKAR / ".github" / "workflows" / "ci.yml"
RE_MUTASI = re.compile(r"python3 alat/uji-mutasi-(\d{4})\.py")
SELALU_MUTASI = {"0012", "0014"}
RE_JARINGAN = re.compile(r"fetch failed|ENOTFOUND|EAI_AGAIN|ECONNREFUSED|ETIMEDOUT|ENETUNREACH|getaddrinfo|network request failed|"
                         r"Could not resolve host|HTTP 0 \(", re.I)


def baca_langkah() -> list[dict]:
    """Langkah job `periksa`: {nama, cwd, run:[perintah…], rahasia:bool}. Parser sederhana khusus tata letak ci.yml repo ini."""
    if not CI.is_file():
        return []
    baris = CI.read_text(encoding="utf-8").split("\n")
    langkah: list[dict] = []
    i = 0
    dalam_job = False
    while i < len(baris):
        b = baris[i]
        if re.match(r"^  periksa:\s*$", b):
            dalam_job = True
        elif dalam_job and re.match(r"^  [A-Za-z_-]+:\s*$", b):
            break                                              # job berikutnya
        if dalam_job and re.match(r"^      - name: ", b):
            l = {"nama": b.split("- name: ", 1)[1].strip(), "cwd": "", "run": [], "rahasia": False, "uses": False, "env": {}}
            i += 1
            while i < len(baris) and not re.match(r"^      - name: ", baris[i]) and not re.match(r"^  [A-Za-z_-]+:\s*$", baris[i]):
                s = baris[i]
                if re.match(r"^        uses: ", s):
                    l["uses"] = True
                m = re.match(r"^        working-directory: (.+)$", s)
                if m:
                    l["cwd"] = m.group(1).strip()
                if "secrets." in s:
                    l["rahasia"] = True
                m = re.match(r"^          ([A-Z_][A-Z0-9_]*): (.+)$", s)
                if m and "${{" not in m.group(2):
                    l["env"][m.group(1)] = m.group(2).strip()          # env literal langkah (mis. kunci publik Supabase)
                m = re.match(r"^        run: \|\s*$", s)
                if m:
                    i += 1
                    while i < len(baris) and (baris[i].startswith("          ") or not baris[i].strip()):
                        if baris[i].strip() and not baris[i].strip().startswith("#"):
                            l["run"].append(baris[i].strip())
                        i += 1
                    continue
                m = re.match(r"^        run: (.+)$", s)
                if m:
                    l["run"].append(m.group(1).strip())
                i += 1
            langkah.append(l)
            continue
        i += 1
    return langkah


def berubah_sejak(basis: str) -> set[str]:
    p = subprocess.run(["git", "diff", "--name-only", basis, "HEAD"], cwd=AKAR, capture_output=True, text=True)
    return set(p.stdout.split()) if p.returncode == 0 else set()


def main(argv: list[str]) -> int:
    simpan = pathlib.Path(argv[argv.index("--simpan") + 1]) if "--simpan" in argv else None
    cepat = "--cepat" in argv
    pasang = "--pasang" in argv
    basis = argv[argv.index("--basis") + 1] if "--basis" in argv else ""
    if cepat and not basis:
        mb = subprocess.run(["git", "merge-base", "HEAD", "origin/main"], cwd=AKAR, capture_output=True, text=True)
        basis = mb.stdout.strip() if mb.returncode == 0 else "HEAD~20"
    berubah = berubah_sejak(basis) if cepat else set()
    langkah = baca_langkah()
    if not langkah:
        print("ci.yml tidak terbaca / job periksa tidak ditemukan")
        return 2
    log: list[str] = [f"RANTAI BUKTI GILIRAN — {time.strftime('%Y-%m-%d %H:%M:%S %z')} — sumber langkah: .github/workflows/ci.yml job periksa"
                      + (f" — MODE CEPAT (basis {basis[:12]})" if cepat else " — MODE PENUH (setara CI)")]
    kotor = subprocess.run(["git", "status", "--porcelain", "--untracked-files=no"], cwd=AKAR, capture_output=True, text=True).stdout.strip()
    if kotor:
        # Skrip mutasi (alat/uji-mutasi-*.py) mengubah berkas migrasi lalu memulihkannya; bila dihentikan di tengah, mutasinya TERTINGGAL
        # dan uji berikutnya merah tanpa sebab yang nyata (dialami Perencana 2026-09-30). Karena itu peringatkan sebelum apa pun berjalan.
        peringatan = ("PERINGATAN: pohon kerja punya perubahan yang belum di-commit — hasil rantai ini BUKAN bukti untuk commit terakhir; "
                      "kalau ini sisa skrip mutasi yang terputus, pulihkan dulu (git checkout -- <berkas>):\n" + kotor)
        print(peringatan, flush=True)
        log.append(peringatan)
    hasil: list[tuple[str, str, str, float]] = []      # (status, nama, perintah, detik)
    for l in langkah:
        if l["uses"] and not l["run"]:
            hasil.append(("LEWAT", l["nama"], "(langkah GitHub Actions: checkout/setup)", 0.0)); continue
        if l["rahasia"]:
            hasil.append(("LEWAT", l["nama"], "(butuh rahasia CI — tidak bisa dibuktikan lokal)", 0.0)); continue
        for cmd in l["run"]:
            if cmd.startswith("npm ci") and not pasang:
                nm = AKAR / (l["cwd"] or ".") / "node_modules" if "--prefix" not in cmd else AKAR / "alat" / "node_modules"
                if nm.is_dir():
                    hasil.append(("LEWAT", l["nama"], f"{cmd} (node_modules sudah ada; --pasang untuk memaksa)", 0.0)); continue
            m = RE_MUTASI.search(cmd)
            if cepat and m and m.group(1) not in SELALU_MUTASI and f"alat/uji-mutasi-{m.group(1)}.py" not in berubah:
                hasil.append(("LEWAT", l["nama"], f"{cmd} (mode cepat: skrip tidak berubah sejak basis)", 0.0)); continue
            cwd = AKAR / l["cwd"] if l["cwd"] else AKAR
            mulai = time.time()
            print(f"… {cmd}" + (f"   [di {l['cwd']}]" if l["cwd"] else ""), flush=True)
            p = subprocess.run(["bash", "-o", "pipefail", "-c", cmd], cwd=cwd, capture_output=True, text=True, errors="replace",
                               env={**os.environ, **l["env"]})
            detik = time.time() - mulai
            status = "LOLOS" if p.returncode == 0 else "GAGAL"
            if status == "GAGAL" and RE_JARINGAN.search(p.stdout + p.stderr):
                status = "JARINGAN"                        # gagal karena tanpa internet (npm audit / cek Supabase) — bukan bukti merah, bukan bukti hijau
            hasil.append((status, l["nama"], cmd, detik))
            log.append(f"\n===== {status} rc={p.returncode} ({detik:.0f} s) — {l['nama']} — {cmd}\n{p.stdout}{p.stderr}")
            print(f"   {status} ({detik:.0f} s)" + (f"\n{(p.stdout + p.stderr)[-1200:]}" if status == "GAGAL" else ""), flush=True)
    gagal = [h for h in hasil if h[0] == "GAGAL"]
    lolos = [h for h in hasil if h[0] == "LOLOS"]
    lewat = [h for h in hasil if h[0] == "LEWAT"]
    jaringan = [h for h in hasil if h[0] == "JARINGAN"]
    ring = [f"\nRINGKASAN {'RANTAI CEPAT (BUKAN setara CI penuh)' if cepat else 'RANTAI PENUH'}: {len(lolos)} LOLOS · {len(gagal)} GAGAL · "
            f"{len(jaringan)} tak terbukti (tanpa internet) · {len(lewat)} dilewati"]
    for st, nama, cmd, _ in gagal:
        ring.append(f"  × GAGAL — {nama}: {cmd}")
    for st, nama, cmd, _ in jaringan:
        ring.append(f"  ? tak terbukti (butuh internet; CI GitHub yang memutuskan) — {nama}: {cmd}")
    for st, nama, cmd, _ in lewat:
        ring.append(f"  · dilewati — {cmd}")
    ring.append(f"RANTAI: {'GAGAL — jangan menyatakan selesai; perbaiki lalu ulangi' if gagal else 'LOLOS'}" + (" (cepat)" if cepat else "")
                + (" — POHON KERJA KOTOR saat dijalankan (lihat peringatan di atas)" if kotor else ""))
    print("\n".join(ring))
    if simpan is not None:
        simpan.parent.mkdir(parents=True, exist_ok=True)
        simpan.write_text("\n".join(log + ring) + "\n", encoding="utf-8")
        print(f"log lengkap: {simpan}")
    return 1 if gagal else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
