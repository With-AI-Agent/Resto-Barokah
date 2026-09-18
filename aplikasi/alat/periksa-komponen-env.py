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

    akar_css = blok(":root")

    def token(nama: str) -> str:
        """Nilai token dari blok `:root` (mis. `--tinggi-kendali` -> `48px`)."""
        m = re.search(re.escape(nama) + r"\s*:\s*([^;]+)", akar_css)
        return (m.group(1) if m else "").strip()

    for kelas, minimal in ((".btn", 44), (".input", 44), (".tab", 44)):
        isi = blok(kelas)
        cocok = re.search(r"min-height:\s*([^;]+)", isi) or re.search(r"(?<!-)height:\s*([^;]+)", isi)
        nilai = (cocok.group(1) if cocok else "").strip()
        # Sejak 2026-09-17 tinggi kendali boleh ditulis lewat token
        # (`min-height:var(--tinggi-kendali)`) supaya kerapatan punya SATU sumber angka.
        # Pemeriksa karenanya menyelesaikan var() dulu, bukan menuntut angka mentah.
        m = re.fullmatch(r"var\(\s*(--[a-z0-9-]+)\s*\)", nilai)
        if m:
            nilai = token(m.group(1))
        angka = re.match(r"(\d+)px", nilai)
        if angka and int(angka.group(1)) >= minimal:
            ok.append(f"OK: {kelas} tinggi minimal {angka.group(1)} px (>= {minimal})")
        else:
            gagal.append(f"GAGAL: {kelas} tidak punya tinggi minimal {minimal} px di token tema")


def _urai_token_env(token: str) -> list[str]:
    """Pecah satu token nama variabel menjadi SEMUA nama yang diwakilinya.

    Bentuk gabungan `GOOGLE_CLIENT_ID/SECRET` (cara TECH_SPEC §6 menghemat sel)
    berarti DUA nama: `GOOGLE_CLIENT_ID` dan `GOOGLE_CLIENT_SECRET`.

    Kenapa dipecah tuntas: temuan audit AUD-3 2026-09-18 F-15. Dulu token
    gabungan diekstrak utuh lalu dicocokkan dengan pencarian sebagian
    (`nama in isi`), sehingga `GOOGLE_CLIENT_ID` dianggap "ada" hanya karena
    baris `# GOOGLE_CLIENT_SECRET=` memuat teks yang mirip. Akibatnya menghapus
    baris `# GOOGLE_CLIENT_ID=` TIDAK membuat pemeriksa ini GAGAL — gerbangnya
    hijau tanpa arti untuk satu nama.
    """
    if "/" not in token:
        return [token]
    kepala, *ekor = token.split("/")
    nama = [kepala]
    for bagian in ekor:
        # `GOOGLE_CLIENT_ID` + `SECRET` -> `GOOGLE_CLIENT_SECRET` (ganti ekor terakhir)
        akar = kepala.rsplit("_", 1)[0] if "_" in kepala else kepala
        nama.append(f"{akar}_{bagian}")
    return nama


def nama_env_tech_spec() -> list[str]:
    """Ambil SEMUA nama variabel dari tabel bagian 6 TECH_SPEC (bentuk gabungan dipecah)."""
    teks = TECH_SPEC.read_text(encoding="utf-8")
    awal = teks.find("## 6.")
    akhir = teks.find("## 7.", awal)
    bagian = teks[awal:akhir]
    nama: list[str] = []
    for cocok in re.findall(r"`([A-Z][A-Z0-9_/]{2,})`", bagian):
        for satu in _urai_token_env(cocok):
            if satu not in nama:
                nama.append(satu)
    return sorted(set(nama))


def _dideklarasikan(isi: str, nama: str) -> bool:
    """True bila `nama` punya baris sendiri di berkas contoh (boleh dikomentari `#`).

    Pencocokan lewat AWAL BARIS, bukan pencarian sebagian: `GOOGLE_CLIENT_ID`
    tidak boleh dianggap ada hanya karena `GOOGLE_CLIENT_SECRET` ada (F-15).
    """
    return re.search(rf"^\s*#?\s*{re.escape(nama)}\s*=", isi, re.MULTILINE) is not None


def uji_env() -> None:
    contoh = APLIKASI / ".env.example"
    if not contoh.exists():
        gagal.append("GAGAL: aplikasi/.env.example tidak ada (DoD T0-05)")
        return
    isi = contoh.read_text(encoding="utf-8")
    aktif = [b for b in isi.splitlines() if b.strip() and not b.strip().startswith("#")]
    nama_aktif = sorted({b.split("=", 1)[0].strip() for b in aktif})

    wajib = nama_env_tech_spec()
    kurang = [n for n in wajib if not _dideklarasikan(isi, n)]
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


def periksa(akar: Path) -> tuple[int, str]:
    """Jalankan semua pemeriksaan terhadap `akar` (dipakai juga oleh uji-diri).

    Sebelumnya semua fungsi membaca path modul level (AKAR_REPO) sehingga tidak
    bisa diarahkan ke salinan sementara — uji-diri butuh itu.
    """
    global AKAR_REPO, APLIKASI, TECH_SPEC, ok, gagal
    AKAR_REPO, APLIKASI, TECH_SPEC = akar, akar / "aplikasi", akar / "docs" / "TECH_SPEC.md"
    ok, gagal = [], []
    uji_komponen()
    uji_env()
    keluaran = "\n".join(ok + gagal)
    return (1 if gagal else 0), keluaran


def uji_diri() -> int:
    """Bukti pemeriksa ini bisa MENOLAK: setiap pemeriksaan dimutasi di salinan pohon.

    Kenapa ada: temuan audit AUD-3 2026-09-18 F-15 — `GOOGLE_CLIENT_ID` bisa
    dihapus dari `.env.example` tanpa membuat pemeriksa ini GAGAL. Mutasi di
    bawah sekarang mengunci kasus itu supaya tidak kembali.
    """
    import sys

    sys.path.insert(0, str(AKAR_REPO / "alat"))
    from bantu_uji_diri import laporkan, salin_pohon

    hasil = []
    with salin_pohon() as tmp:
        kode, keluar = periksa(tmp)
        hasil.append(("salinan utuh", kode == 0, f"kode {kode}"))
        if kode != 0:
            print(keluar[:1200])

    def mutasi(nama: str, berkas: str, ubah) -> None:
        with salin_pohon() as tmp:
            f = tmp / berkas
            if not f.is_file():
                hasil.append((nama, False, f"{berkas} tidak ada"))
                return
            isi = f.read_text(encoding="utf-8")
            baru = ubah(isi)
            if baru == isi:
                hasil.append((nama, False, "mutasi TIDAK mengubah berkas (pola tidak ketemu)"))
                return
            f.write_text(baru, encoding="utf-8")
            kode, _ = periksa(tmp)
            hasil.append((nama, kode != 0, "ditolak" if kode != 0 else "DILOLOSKAN (tumpul)"))

    # Setiap nama variabel §6 dihapus satu per satu — termasuk yang datang dari sel
    # gabungan `GOOGLE_CLIENT_ID/SECRET` (kasus F-15).
    for nama in ("GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET", "SUPABASE_SERVICE_ROLE_KEY",
                 "CLOUDFLARE_API_TOKEN", "DENYUT_URL"):
        mutasi(f"mutasi: baris {nama} dihapus dari .env.example",
               "aplikasi/.env.example",
               lambda s, n=nama: "\n".join(b for b in s.splitlines() if not b.strip().lstrip("#").strip().startswith(n + "=")))

    mutasi("mutasi: variabel rahasia diberi awalan VITE_ (ikut ke bundel)",
           "aplikasi/.env.example",
           lambda s: s.replace("# RESEND_API_KEY=", "VITE_RESEND_API_KEY=", 1))


    with salin_pohon() as tmp:
        (tmp / "aplikasi/src/komponen/Lencana.tsx").unlink()
        kode, _ = periksa(tmp)
        hasil.append(("mutasi: komponen Lencana dihapus", kode != 0, "ditolak" if kode != 0 else "DILOLOSKAN (tumpul)"))

    return laporkan("periksa-komponen-env", hasil)


def main() -> int:
    if "--uji-diri" in __import__("sys").argv:
        return uji_diri()
    kode, keluaran = periksa(AKAR_REPO)
    print(keluaran)
    print("-" * 60)
    print(f"komponen & rahasia: {len(ok)} OK · {len(gagal)} GAGAL")
    return kode


if __name__ == "__main__":
    raise SystemExit(main())
