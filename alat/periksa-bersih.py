#!/usr/bin/env python3
"""periksa-bersih.py — penjaga POHON BERSIH (hanya berkas yang masuk Git).

Kenapa ada: CI memeriksa **salinan bersih** — hanya berkas yang benar-benar masuk Git.
Di komputer sendiri sering ada berkas hasil kerja yang sengaja **tidak** ikut Git
(contoh nyata: berkas kerja lembar kunci `*.local.md`). Kalau dokumen merujuk berkas
semacam itu, di komputer sendiri semuanya hijau — tetapi di CI rujukannya menggantung dan
kiriman GAGAL. Itu benar-benar terjadi 2026-09-17: enam dokumen merujuk berkas kerja
lembar kunci, dan baru ketahuan setelah kiriman masuk CI.

Pemeriksa ini: salin **hanya berkas terlacak `git ls-files`** ke folder sementara, lalu
jalankan pemeriksa dokumen di salinan itu. Jadi cacat kelas "hanya sehat di komputer saya"
tertangkap **sebelum** kirim, bukan sesudah.

Mode `--uji-diri`: salin repo, buat rujukan ke berkas yang tidak ikut Git (harus DITOLAK),
hapus satu pemeriksa yang seharusnya dijalankan (harus DITOLAK juga — bukti gerbang ini
tidak lulus karena kebetulan).
"""
from __future__ import annotations

import pathlib
import shutil
import subprocess
import sys
import tempfile

AKAR = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(AKAR / "alat"))

# Pemeriksa dokumen yang WAJIB hijau di salinan bersih. Sengaja hanya yang membaca dokumen:
# pemeriksa yang butuh `node_modules` atau alat luar tidak dijalankan di sini (sudah
# dijalankan di tempatnya masing-masing).
PEMERIKSA = (
    "_sistem/validate_system.py",
    "alat/periksa-rujukan.py",
    "alat/periksa-panduan.py",
    "alat/periksa-buku-uji.py",
    "alat/periksa-rahasia.py",
)
# Pemeriksa yang perlu indeks Git di salinan (memakai `git ls-files`).
BUTUH_GIT = {"alat/periksa-rahasia.py"}
ABAIKAN_TAMPILAN = ("node_modules", "dist", "build", "__pycache__", ".vite")


def berkas_terlacak(akar: pathlib.Path) -> list[str]:
    keluar = subprocess.run(
        ["git", "-C", str(akar), "ls-files", "-z"], capture_output=True, text=True
    )
    if keluar.returncode != 0:
        return []
    return [b for b in keluar.stdout.split("\0") if b.strip()]


def _daftar_other(akar: pathlib.Path, tambahan: list[str]) -> list[str]:
    keluar = subprocess.run(
        ["git", "-C", str(akar), "ls-files", "--others", "--exclude-standard", "--directory", *tambahan],
        capture_output=True,
        text=True,
    )
    if keluar.returncode != 0:
        return []
    return [b.rstrip("/") for b in keluar.stdout.splitlines() if b.strip()]


def berkas_diabaikan(akar: pathlib.Path) -> list[str]:
    """Berkas yang ada di komputer tetapi sengaja tidak ikut Git (mis. `*.local.md`)."""
    return _daftar_other(akar, ["--ignored"])


def berkas_belum_ditambahkan(akar: pathlib.Path) -> list[str]:
    """Berkas baru yang belum masuk Git sama sekali (belum `git add`) — calon penyebab gerbang gagal."""
    return _daftar_other(akar, [])


def salin_terlacak(akar: pathlib.Path, tujuan: pathlib.Path, terlacak: list[str]) -> None:
    for rel in terlacak:
        asal = akar / rel
        if not asal.is_file():
            continue  # terhapus di ruang kerja; salinan bersih = apa yang ada di indeks
        sasaran = tujuan / rel
        sasaran.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(asal, sasaran)


def jalankan(perintah: list[str], cwd: pathlib.Path) -> tuple[int, str]:
    hasil = subprocess.run(perintah, cwd=str(cwd), capture_output=True, text=True, timeout=300)
    return hasil.returncode, (hasil.stdout + hasil.stderr).strip()


def periksa(akar: pathlib.Path) -> int:
    terlacak = berkas_terlacak(akar)
    if not terlacak:
        print("PERIKSA POHON BERSIH: GAGAL — tidak ada berkas terlacak (bukan repo Git? gagal-tertutup)")
        return 1

    diabaikan = berkas_diabaikan(akar)
    belum_ditambahkan = berkas_belum_ditambahkan(akar)
    tampil = [b for b in diabaikan if not any(a in b for a in ABAIKAN_TAMPILAN)]

    gagal: list[str] = []
    with tempfile.TemporaryDirectory(prefix="pohon-bersih-") as tmp:
        tmpdir = pathlib.Path(tmp)
        salin_terlacak(akar, tmpdir, terlacak)
        if any(p in BUTUH_GIT for p in PEMERIKSA):
            subprocess.run(["git", "-C", str(tmpdir), "init", "-q"], capture_output=True)
            subprocess.run(["git", "-C", str(tmpdir), "config", "user.email", "bersih@lokal"], capture_output=True)
            subprocess.run(["git", "-C", str(tmpdir), "config", "user.name", "bersih"], capture_output=True)
            subprocess.run(["git", "-C", str(tmpdir), "add", "-A"], capture_output=True)

        print(f"PERIKSA POHON BERSIH — {len(terlacak)} berkas terlacak disalin · {len(PEMERIKSA)} pemeriksa dokumen")
        for nama in PEMERIKSA:
            jalur = tmpdir / nama
            if not jalur.is_file():
                gagal.append(f"{nama} TIDAK ADA di salinan bersih — gerbang tidak lengkap")
                print(f"  [X] {nama}: berkas pemeriksa tidak ada")
                continue
            kode, keluar = jalankan([sys.executable, nama], tmpdir)
            if kode != 0:
                gagal.append(nama)
                print(f"  [X] {nama}: MENOLAK (kode {kode})")
                for baris in keluar.splitlines()[-6:]:
                    print(f"        {baris}")
            else:
                print(f"  [OK] {nama}")

    print(
        f"  catatan: berkas ada di komputermu tetapi TIDAK ikut Git: {len(tampil)}"
        + (f" (contoh: {', '.join(tampil[:5])})" if tampil else "")
    )
    if belum_ditambahkan:
        print(
            f"  catatan: berkas baru yang BELUM masuk Git (belum `git add`): {len(belum_ditambahkan)}"
            + (f" (contoh: {', '.join(belum_ditambahkan[:5])})" if belum_ditambahkan else "")
        )
    if gagal:
        print(f"\nHASIL: GAGAL — {len(gagal)} pemeriksa menolak di pohon bersih: {', '.join(gagal)}")
        print("Perbaiki rujukan/berkas yang hanya ada di komputer sendiri (mis. berkas `*.local.md`),")
        print("atau masukkan berkas yang seharusnya ikut Git.")
        return 1
    print("\nHASIL: LOLOS — semua pemeriksa dokumen hijau di pohon bersih (hanya berkas terlacak Git).")
    return 0


def _siapkan_git(tmp: pathlib.Path) -> None:
    subprocess.run(["git", "-C", str(tmp), "init", "-q"], capture_output=True)
    subprocess.run(["git", "-C", str(tmp), "config", "user.email", "uji@lokal"], capture_output=True)
    subprocess.run(["git", "-C", str(tmp), "config", "user.name", "uji"], capture_output=True)
    subprocess.run(["git", "-C", str(tmp), "add", "-A"], capture_output=True)


def uji_diri() -> int:
    from bantu_uji_diri import jalankan_pemeriksa, laporkan, salin_pohon

    hasil: list[tuple[str, bool, str]] = []
    with salin_pohon() as tmp:
        _siapkan_git(tmp)
        kode, keluar = jalankan_pemeriksa(periksa, tmp)
        hasil.append(("salinan utuh", kode == 0, f"kode {kode}"))
        if kode != 0:
            print(keluar[:1200])

        # Mutasi 1: dokumen pengikat merujuk berkas yang ada di komputer tetapi TIDAK ikut Git.
        with salin_pohon() as tmp2:
            (tmp2 / "docs" / "ops" / "UJI.local.md").write_text("berkas uji\n", encoding="utf-8")
            f = tmp2 / "docs" / "teknis" / "REKAM_PESAN_PEMILIK.md"
            f.write_text(
                f.read_text(encoding="utf-8") + "\nRujukan uji: `docs/ops/UJI.local.md`\n", encoding="utf-8"
            )
            _siapkan_git(tmp2)
            kode2, _ = jalankan_pemeriksa(periksa, tmp2)
            hasil.append(
                ("mutasi: rujukan ke berkas yang tidak ikut Git", kode2 != 0, "ditolak" if kode2 != 0 else "DILOLOSKAN (tumpul)")
            )

        # Mutasi 2: satu pemeriksa dokumen dihapus → gerbang harus GAGAL (bukan lulus diam-diam).
        with salin_pohon() as tmp3:
            (tmp3 / "alat" / "periksa-rujukan.py").unlink()
            _siapkan_git(tmp3)
            kode3, _ = jalankan_pemeriksa(periksa, tmp3)
            hasil.append(
                ("mutasi: pemeriksa dokumen dihapus", kode3 != 0, "ditolak" if kode3 != 0 else "DILOLOSKAN (tumpul)")
            )
    return laporkan("periksa-bersih", hasil)


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(periksa(AKAR))
