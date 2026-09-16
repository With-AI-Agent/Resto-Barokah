#!/usr/bin/env python3
"""Pemeriksa pelengkap Fase 0 untuk T0-04 (komponen & kontras) dan T0-05 (rahasia).

Dijalankan sendiri (dan juga otomatis di CI):
  - komponen dasar wajib ada (DoD T0-04)
  - pemeriksa kontras aplikasi wajib ada & hijau (dijalankan dari sini)
  - berkas .env.example wajib memuat SEMUA nama variabel TECH_SPEC §6 (DoD T0-05)
  - variabel rahasia tidak boleh berawalan VITE_ (biar tidak ikut ke aplikasi)
  - tidak ada kode `service_role` di dalam aplikasi
  - `.env` benar-benar diabaikan Git dan `.env.example` benar-benar ikut Git
    (dibuktikan dengan `git check-ignore`, bukan dibaca dari komentar)
"""
from __future__ import annotations

import re
import subprocess
from pathlib import Path

AKAR_REPO = Path(__file__).resolve().parents[2]
APLIKASI = AKAR_REPO / "aplikasi"
TECH_SPEC = AKAR_REPO / "docs" / "TECH_SPEC.md"

ok: list[str] = []
gagal: list[str] = []

KOMPONEN_WAJIB = [
    "Tombol.tsx",
    "Kartu.tsx",
    "Lencana.tsx",
    "Lapis.tsx",
    "Toast.tsx",
    "Tabel.tsx",
    "KolomIsian.tsx",
    "KeadaanKosong.tsx",
    "KeadaanMemuat.tsx",
    "KeadaanGagal.tsx",
]


def uji_komponen() -> None:
    folder = APLIKASI / "src" / "komponen"
    hilang = [nama for nama in KOMPONEN_WAJIB if not (folder / nama).exists()]
    if hilang:
        gagal.append(f"GAGAL: komponen wajib belum ada: {hilang}")
    else:
        ok.append(f"OK: {len(KOMPONEN_WAJIB)} komponen dasar ada (DoD T0-04)")

    alat = APLIKASI / "alat" / "uji-kontras.py"
    if not alat.exists():
        gagal.append("GAGAL: aplikasi/alat/uji-kontras.py tidak ada (DoD T0-04)")
    else:
        hasil = subprocess.run(
            ["python3", str(alat)], capture_output=True, text=True, cwd=str(AKAR_REPO)
        )
        ringkas = (hasil.stdout.strip().splitlines() or [""])[-1]
        if hasil.returncode == 0:
            ok.append(f"OK: uji kontras aplikasi lulus ({ringkas})")
        else:
            gagal.append(f"GAGAL: uji kontras aplikasi tidak lulus ({ringkas})")

    # aturan ukuran sentuh minimal 44 px wajib ada di CSS (dibaca dari CSS, bukan ditebak)
    css = (APLIKASI / "src" / "gaya" / "token" / "tema.css").read_text(encoding="utf-8")
    def blok(kelas: str) -> str:
        """Ambil isi {...} untuk selektor tepat (mis. '.btn{ ... }')."""
        pos = css.find(kelas + "{")
        if pos < 0:
            return ""
        return css[pos + len(kelas) + 1 : css.find("}", pos)]

    for kelas, minimal in ((".btn", 44), (".input", 44), (".tab", 44)):
        isi = blok(kelas)
        cocok = re.search(r"min-height:\s*(\d+)px", isi) or re.search(r"height:\s*(\d+)px", isi)
        if cocok and int(cocok.group(1)) >= minimal:
            ok.append(f"OK: {kelas} tinggi minimal {cocok.group(1)} px (>= {minimal})")
        else:
            gagal.append(f"GAGAL: {kelas} tidak punya tinggi minimal {minimal} px di token tema")


def nama_env_tech_spec() -> list[str]:
    """Ambil nama variabel dari tabel bagian 6 TECH_SPEC."""
    teks = TECH_SPEC.read_text(encoding="utf-8")
    awal = teks.find("## 6.")
    akhir = teks.find("## 7.", awal)
    bagian = teks[awal:akhir]
    nama: list[str] = []
    for baris in bagian.splitlines():
        if not baris.strip().startswith("|"):
            continue
        sel = [s.strip() for s in baris.strip().strip("|").split("|")]
        for isi in sel:
            for cocok in re.findall(r"`([A-Z][A-Z0-9_]{2,})`", isi):
                if cocok not in nama:
                    nama.append(cocok)
    # satu sel bisa memuat dua nama: `GOOGLE_CLIENT_ID/SECRET` -> tambahkan versi lengkapnya
    for nama_gabung, ekor in re.findall(r"`([A-Z][A-Z0-9_]+)/([A-Z]+)`", bagian):
        akar = nama_gabung.rsplit("_", 1)[0]
        lengkap = f"{akar}_{ekor}"
        if lengkap not in nama:
            nama.append(lengkap)
    return sorted(set(nama))


def uji_env() -> None:
    contoh = APLIKASI / ".env.example"
    if not contoh.exists():
        gagal.append("GAGAL: aplikasi/.env.example tidak ada (DoD T0-05)")
        return
    isi = contoh.read_text(encoding="utf-8")
    aktif = [b for b in isi.splitlines() if b.strip() and not b.strip().startswith("#")]
    nama_aktif = sorted({b.split("=", 1)[0].strip() for b in aktif})

    wajib = nama_env_tech_spec()
    kurang = [n for n in wajib if n not in isi]
    if kurang:
        gagal.append(f"GAGAL: .env.example belum memuat variabel TECH_SPEC §6: {kurang}")
    else:
        ok.append(f"OK: .env.example memuat semua {len(wajib)} nama variabel TECH_SPEC §6")

    klien = {"VITE_SUPABASE_URL", "VITE_SUPABASE_ANON_KEY"}
    asing = [n for n in nama_aktif if n not in klien]
    if asing:
        gagal.append(
            f"GAGAL: .env.example mengaktifkan variabel yang tidak boleh aktif di aplikasi: {asing} "
            "(harus tetap dikomentari)"
        )
    else:
        ok.append(f"OK: hanya {len(klien)} variabel publik yang aktif di .env.example")

    # variabel rahasia tidak boleh berawalan VITE_ (kalau berawalan, ikut ke aplikasi)
    bocor = [n for n in nama_aktif if n.startswith("VITE_") and n not in klien]
    if bocor:
        gagal.append(f"GAGAL: variabel rahasia memakai awalan VITE_ (ikut ke aplikasi): {bocor}")

    # tidak ada kode service_role di dalam aplikasi
    pelanggar = []
    for berkas in (APLIKASI / "src").rglob("*"):
        if berkas.is_file() and berkas.suffix in {".ts", ".tsx", ".css"}:
            isi_berkas = berkas.read_text(encoding="utf-8")
            if "service_role" in isi_berkas and "tidak" not in isi_berkas.lower():
                pelanggar.append(str(berkas.relative_to(AKAR_REPO)))
    if pelanggar:
        gagal.append(f"GAGAL: kode menyebut service_role: {pelanggar}")
    else:
        ok.append("OK: tidak ada kunci service_role di dalam aplikasi")

    # bukti nyata lewat git, bukan dari komentar
    def diabaikan(jalur: str) -> bool | None:
        hasil = subprocess.run(
            ["git", "check-ignore", "-q", jalur], cwd=str(AKAR_REPO), capture_output=True
        )
        if hasil.returncode in (0, 1):
            return hasil.returncode == 0
        return None

    env_diabaikan = diabaikan("aplikasi/.env")
    contoh_diabaikan = diabaikan("aplikasi/.env.example")
    if env_diabaikan is True:
        ok.append("OK: aplikasi/.env benar-benar diabaikan Git")
    else:
        gagal.append("GAGAL: aplikasi/.env TIDAK diabaikan Git (rahasia bisa ikut ke repo)")
    if contoh_diabaikan is False:
        ok.append("OK: aplikasi/.env.example ikut Git (contoh bisa dibaca semua orang)")
    else:
        gagal.append("GAGAL: aplikasi/.env.example justru diabaikan Git")


def main() -> int:
    uji_komponen()
    uji_env()
    for baris in ok:
        print(baris)
    for baris in gagal:
        print(baris)
    print("-" * 60)
    print(f"komponen & rahasia: {len(ok)} OK · {len(gagal)} GAGAL")
    return 1 if gagal else 0


if __name__ == "__main__":
    raise SystemExit(main())
