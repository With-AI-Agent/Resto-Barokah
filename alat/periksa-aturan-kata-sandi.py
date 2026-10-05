#!/usr/bin/env python3
"""periksa-aturan-kata-sandi.py — penjaga keselarasan aturan kata sandi dokumen vs konfigurasi.

Kenapa ada (temuan PMB1-F-071, kartu K-F-06, K-2): docs/KEAMANAN.md menyebut
TIGA KALI aturan "kata sandi minimal 12 karakter + pola umum dilarang + TOTP"
sebagai kompensasi sah diterimanya risiko HIBP, tetapi satu-satunya artefak di
repo yang bisa menegakkan aturan itu — supabase/config.toml — justru mencatat
minimum 8 tanpa aturan komposisi. Pemeriksa ini mengunci keselarasan itu:

  A. supabase/config.toml [auth] minimum_password_length >= 12;
  B. password_requirements tidak kosong dan memuat minimal tiga kelas karakter
     (huruf kecil, huruf besar, angka) dalam format kelas dipisah koma GoTrue;
  C. docs/KEAMANAN.md masih menyatakan kompensasi "12 karakter" — bila janji
     dokumen berubah, konfigurasi harus ikut dibahas (pemeriksa menyala).

Batas jujur: berkas ini mengawal stack lokal (Supabase CLI). Konfigurasi proyek
produksi Supabase hidup di luar repo (temuan L-01/L-04) dan tidak bisa dikawal
dari sini.

Jalankan:
  python3 alat/periksa-aturan-kata-sandi.py            # periksa sungguhan (dipakai CI)
  python3 alat/periksa-aturan-kata-sandi.py --uji-diri # buktikan penjaga bisa MENOLAK yang rusak
"""
from __future__ import annotations

import pathlib
import re
import sys
import tempfile
import tomllib

AKAR = pathlib.Path(__file__).resolve().parents[1]
CONFIG = "supabase/config.toml"
KEAMANAN = "docs/KEAMANAN.md"
MIN_PANJANG = 12
POLA_KELAS = {"huruf_kecil": re.compile(r"[a-z]"), "huruf_besar": re.compile(r"[A-Z]"), "angka": re.compile(r"[0-9]")}


def baca_config(path_config: pathlib.Path) -> dict:
    with path_config.open("rb") as f:
        return tomllib.load(f)


def kelas_terpenuhi(password_requirements: str) -> set[str]:
    """Kelas karakter (dari format kelas dipisah koma GoTrue) yang terwakili."""
    terpenuhi: set[str] = set()
    for nama, pola in POLA_KELAS.items():
        if pola.search(password_requirements):
            terpenuhi.add(nama)
    return terpenuhi


def periksa(akar: pathlib.Path) -> list[str]:
    """Kembalikan daftar pelanggaran (kosong = LOLOS)."""
    salah: list[str] = []

    path_config = akar / CONFIG
    if not path_config.exists():
        return [f"{CONFIG} tidak ditemukan"]
    try:
        cfg = baca_config(path_config)
    except Exception as exc:  # noqa: BLE001 — laporan ramah lebih penting daripada jejak
        return [f"{CONFIG} tidak bisa dibaca sebagai TOML: {exc}"]

    auth = cfg.get("auth", {})

    panjang = auth.get("minimum_password_length")
    if not isinstance(panjang, int) or panjang < MIN_PANJANG:
        salah.append(
            f"Aturan A: {CONFIG} [auth] minimum_password_length = {panjang!r}, "
            f"padahal KEAMANAN.md menjanjikan >= {MIN_PANJANG} (PMB1-F-071)."
        )

    syarat = auth.get("password_requirements", "")
    kelas = kelas_terpenuhi(syarat)
    if not syarat.strip():
        salah.append(
            f"Aturan B: {CONFIG} [auth] password_requirements kosong — "
            "tidak ada aturan komposisi sama sekali."
        )
    elif len(kelas) < 3:
        salah.append(
            f"Aturan B: {CONFIG} [auth] password_requirements baru memenuhi kelas {sorted(kelas)}; "
            "wajib memuat huruf kecil, huruf besar, dan angka (format kelas dipisah koma)."
        )

    path_keamanan = akar / KEAMANAN
    if path_keamanan.exists():
        teks = path_keamanan.read_text(encoding="utf-8")
        if not re.search(r"(minimal|minimum|\u2265|>=)\s*12\s*karakter|kata sandi \(\u226512\)|\u226512", teks):
            salah.append(
                f"Aturan C: {KEAMANAN} tidak lagi menyebut kompensasi 12 karakter — "
                "perubahan janji dokumen harus disengaja dan diselaraskan dengan konfigurasi."
            )

    return salah


def uji_diri() -> int:
    """Buktikan penjaga MENOLAK konfigurasi rusak dan MELULUSKAN yang benar."""
    with tempfile.TemporaryDirectory() as tmp:
        akar_uji = pathlib.Path(tmp)
        (akar_uji / "supabase").mkdir()
        (akar_uji / "docs").mkdir()

        baik = (
            "[auth]\n"
            "minimum_password_length = 12\n"
            'password_requirements = "abcdefghijklmnopqrstuvwxyz,ABCDEFGHIJKLMNOPQRSTUVWXYZ,0123456789"\n'
        )
        (akar_uji / CONFIG).write_text(baik, encoding="utf-8")
        (akar_uji / KEAMANAN).write_text(
            "Kompensasi untuk kata sandi: minimum 12 karakter + pola umum dilarang + TOTP wajib.\n",
            encoding="utf-8",
        )

        gagal = 0

        # Kontrol: konfigurasi selaras harus LOLOS.
        if periksa(akar_uji):
            print("UJI-DIRI GAGAL: konfigurasi selaras justru ditolak")
            gagal += 1

        # Mutasi 1: panjang diturunkan ke 8 (keadaan asli sebelum PMB1-F-071).
        (akar_uji / CONFIG).write_text(
            baik.replace("minimum_password_length = 12", "minimum_password_length = 8"),
            encoding="utf-8",
        )
        pelanggaran = periksa(akar_uji)
        if not any("Aturan A" in p for p in pelanggaran):
            print("UJI-DIRI GAGAL: minimum 8 karakter justru diluluskan")
            gagal += 1

        # Mutasi 2: aturan komposisi dikosongkan.
        (akar_uji / CONFIG).write_text(
            baik.replace('password_requirements = "abcdefghijklmnopqrstuvwxyz,ABCDEFGHIJKLMNOPQRSTUVWXYZ,0123456789"',
                         'password_requirements = ""'),
            encoding="utf-8",
        )
        pelanggaran = periksa(akar_uji)
        if not any("Aturan B" in p for p in pelanggaran):
            print("UJI-DIRI GAGAL: password_requirements kosong justru diluluskan")
            gagal += 1

        # Mutasi 3: janji 12 karakter hilang dari dokumen.
        (akar_uji / CONFIG).write_text(baik, encoding="utf-8")
        (akar_uji / KEAMANAN).write_text("Tidak ada janji panjang kata sandi di sini.\n", encoding="utf-8")
        pelanggaran = periksa(akar_uji)
        if not any("Aturan C" in p for p in pelanggaran):
            print("UJI-DIRI GAGAL: dokumen tanpa janji 12 karakter justru diluluskan")
            gagal += 1

        if gagal:
            print(f"HASIL: GAGAL ({gagal} uji-diri tidak berperilaku semestinya)")
            return 1
        print("HASIL: LOLOS — uji-diri membuktikan penjaga menolak panjang <12, komposisi kosong, dan janji dokumen yang hilang.")
        return 0


def main() -> int:
    if "--uji-diri" in sys.argv:
        return uji_diri()
    salah = periksa(AKAR)
    if salah:
        for pesan in salah:
            print("  " + pesan)
        print("HASIL: GAGAL — aturan kata sandi dokumen vs konfigurasi tidak selaras (PMB1-F-071).")
        return 1
    print(
        f"HASIL: LOLOS — {CONFIG} selaras dengan janji >= {MIN_PANJANG} karakter + komposisi 3 kelas "
        f"di {KEAMANAN} (PMB1-F-071). Catatan: produksi Supabase hidup di luar repo (L-01/L-04)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
