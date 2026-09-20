#!/usr/bin/env python3
"""periksa-migrasi-beku.py — penjaga: migrasi yang SUDAH dijalankan di proyek nyata tidak boleh disunting.

Latar (2026-09-19, diperbarui 2026-09-20): 16 berkas migrasi `0001`–`0016` sudah **disebar ke proyek Supabase milik pemilik**
(run `35435248540`: `link` → `db push --dry-run` → `db push` → `migration list`). Database nyata hanya
berubah karena PENYEBARAN berkas migrasi; menyunting berkas lama tidak mengubah database nyata, tetapi
mengubah hasil uji lokal — persis kelas cacat "bukti tidak mewakili kenyataan".

Karena itu berkas lama **dibekukan** (sidik SHA-256 di `BEKU`) dan setiap perubahan skema WAJIB ditulis
sebagai berkas BARU bernomor `0017` ke atas — termasuk seluruh perbaikan temuan audit.

Yang diperiksa:
  1. setiap berkas beku ADA dan sidiknya SAMA (satu bit berubah = merah);
  2. tidak ada berkas migrasi BARU bernomor ≤ nomor tertinggi yang sudah beku;
  3. tidak ada nomor migrasi kembar.

Cara pakai:
  python3 alat/periksa-migrasi-beku.py            # periksa sungguhan (dipakai CI)
  python3 alat/periksa-migrasi-beku.py --uji-diri # buktikan penjaga bisa MENOLAK yang rusak
"""
from __future__ import annotations

import hashlib
import pathlib
import re
import shutil
import sys
import tempfile

AKAR = pathlib.Path(__file__).resolve().parent.parent
DIR_MIGRASI = "supabase/migrations"
POLA_NOMOR = re.compile(r"^(\d{4})_[a-z0-9_]+\.sql$")

# Sidik SHA-256 berkas migrasi yang sudah dijalankan di proyek pemilik (2026-09-19).
# Menambah baris di sini TIDAK boleh tanpa penyebaran ulang yang sungguhan: daftar ini adalah
# catatan "apa yang sudah ada di database nyata", bukan daftar keinginan.
BEKU: dict[str, str] = {
    "0001_penyewa_cabang.sql": "65f4f747b4fcb7538fa08eaea310af0f144c77ffb9a9def5f63a303a0793a22e",
    "0002_pengguna_izin_pengaturan.sql": "ad36790fdd153f51d9a0d866316251afce3f2578af1b43c6e60285502bd8760c",
    "0003_helper_identitas.sql": "7b030ab5072b8275203e1bf628ed21e2e56bb8239b11c722c8c286d385e9405e",
    "0004_pola_rls.sql": "a2a01c5ed600ff51189c12b8a7ba35789c6efa297e25550ef9266410c9bef6df",
    "0005_izin_berjenjang.sql": "a9ca40f51a578b791d1e2686222331c438a305e65f4599df2b02cfc353176808",
    "0006_pin.sql": "c33fe7637b7c852135c14858ba63fdfcadba2adc5aa054628556de6fd1186ad3",
    "0007_katalog.sql": "859b2d7a1ffe09876d12b85c88ef60ab03953b21854f3dd201efa3401ce8f8bb",
    "0008_meja.sql": "c36698ea0da5b1e684f8c63e44f341ff42332e4b37c1ec6534d1da42e7783716",
    "0009_pesanan.sql": "760515c55617c66d9b24574dae9634147419b0ead64a9475ed010d114abbebbe",
    "0010_pembayaran.sql": "db59e606fa07ee6e9be427856e8ddf445db88ff4e9e1b5f33aca9f3285aaec86",
    "0011_peran_tunggal.sql": "41fa4e0a7a7c0f7ba25d5ec8c3541a5f195250f9fec0a2c5a8168da542653430",
    "0012_penutup_celah_review.sql": "693f2ca751a29f7f39a33b1b8b686a40523fe1473d1dd555513c6cbc8df284ff",
    "0013_penutup_celah_putaran11.sql": "1ed79b5a94191ac2fe516ba725014838276ec186372fa4c7788f71cd8f27d8cc",
    "0014_penutup_celah_putaran13.sql": "c043ac4b02407a981b1db13fec4cf2cc16fbc5012dfa0814f68f8c17cece1af7",
    "0015_penutup_celah_putaran16.sql": "2cd29875b5ee671960e3662f3ab7cc9eb3088d781b83e973b719a67def2fd25b",
    "0016_penutup_celah_pin_putaran18.sql": "c2b79fe33b34db7ad43720fd6227af4923dbc66384c1ca0403febc60ba434bb8",
}

NOMOR_TERTINGGI_BEKU = 16


def _sidik(berkas: pathlib.Path) -> str:
    return hashlib.sha256(berkas.read_bytes()).hexdigest()


def periksa(akar: pathlib.Path = AKAR) -> tuple[int, list[str]]:
    """Kembalikan (kode_keluar, daftar_temuan). 0 = bersih."""
    folder = akar / DIR_MIGRASI
    temuan: list[str] = []
    if not folder.is_dir():
        return 1, [f"folder migrasi tidak ada: {DIR_MIGRASI}"]

    # 1. berkas beku harus ada dan tidak berubah
    for nama, sidik_harap in sorted(BEKU.items()):
        berkas = folder / nama
        if not berkas.is_file():
            temuan.append(
                f"{DIR_MIGRASI}/{nama}: BERKAS BEKU HILANG — migrasi ini sudah dijalankan di proyek nyata, "
                "menghapusnya hanya membuat repo berbeda dari kenyataan"
            )
            continue
        sidik_nyata = _sidik(berkas)
        if sidik_nyata != sidik_harap:
            temuan.append(
                f"{DIR_MIGRASI}/{nama}: BERKAS BEKU DIUBAH (sidik {sidik_nyata[:12]}… ≠ {sidik_harap[:12]}…) — "
                "database nyata sudah memuat versi lama; tulis perbaikan sebagai berkas BARU `0015_…sql`"
            )

    # 2 & 3. berkas baru tidak boleh memakai nomor lama / kembar
    nomor_terlihat: dict[int, str] = {}
    for berkas in sorted(folder.glob("*.sql")):
        cocok = POLA_NOMOR.match(berkas.name)
        if not cocok:
            temuan.append(
                f"{DIR_MIGRASI}/{berkas.name}: nama tidak mengikuti pola `NNNN_nama_kecil.sql` "
                "(nomor 4 angka, huruf kecil, garis bawah)"
            )
            continue
        nomor = int(cocok.group(1))
        if nomor in nomor_terlihat:
            temuan.append(
                f"{DIR_MIGRASI}/{berkas.name}: NOMOR KEMBAR dengan {nomor_terlihat[nomor]} — "
                "urutan penyebaran jadi tak tertebak"
            )
        nomor_terlihat[nomor] = berkas.name
        if berkas.name not in BEKU and nomor <= NOMOR_TERTINGGI_BEKU:
            temuan.append(
                f"{DIR_MIGRASI}/{berkas.name}: nomor {nomor:04d} ≤ {NOMOR_TERTINGGI_BEKU:04d} (sudah beku) — "
                "perubahan skema baru WAJIB memakai nomor di atas yang sudah dijalankan di proyek nyata"
            )

    return (1 if temuan else 0), temuan


def _tulis(akar: pathlib.Path, relatif: str, isi: str) -> None:
    berkas = akar / relatif
    berkas.parent.mkdir(parents=True, exist_ok=True)
    berkas.write_text(isi, encoding="utf-8")


def uji_diri() -> int:
    """Buktikan penjaga MENOLAK pohon rusak dan MENERIMA pohon utuh."""
    kasus: list[tuple[str, bool]] = []
    with tempfile.TemporaryDirectory(prefix="migrasi-beku-") as tmp:
        salinan = pathlib.Path(tmp) / "repo"
        sumber = AKAR / DIR_MIGRASI
        _tulis(salinan, f"{DIR_MIGRASI}/.jaga", "")
        for berkas in sumber.glob("*.sql"):
            shutil.copy2(berkas, salinan / DIR_MIGRASI / berkas.name)

        kode, pesan = periksa(salinan)
        kasus.append(("salinan utuh → diterima", kode == 0))

        def mutasi(nama: str, ubah, harap_ditolak: bool = True) -> None:
            asli = {b.name: b.read_text(encoding="utf-8") for b in (salinan / DIR_MIGRASI).glob("*.sql")}
            ubah()
            kode_m, _ = periksa(salinan)
            kasus.append(
                (f"mutasi: {nama} → {'ditolak' if harap_ditolak else 'diterima'}", (kode_m != 0) == harap_ditolak)
            )
            # Pulihkan UTUH: tulis ulang semua berkas asli (termasuk yang sempat dihapus) dan buang
            # berkas tambahan — kalau tidak, mutasi berikutnya dinilai dari pohon yang sudah rusak.
            for nama_berkas, teks in asli.items():
                _tulis(salinan, f"{DIR_MIGRASI}/{nama_berkas}", teks)
            for b in (salinan / DIR_MIGRASI).glob("*.sql"):
                if b.name not in asli:
                    b.unlink()

        def ubah_0001() -> None:
            berkas = salinan / DIR_MIGRASI / "0001_penyewa_cabang.sql"
            berkas.write_text(berkas.read_text(encoding="utf-8").replace("create", "CREATE", 1), encoding="utf-8")

        def hapus_0003() -> None:
            (salinan / DIR_MIGRASI / "0003_helper_identitas.sql").unlink()

        def tambah_0005() -> None:
            _tulis(salinan, f"{DIR_MIGRASI}/0005_tambahan_belakangan.sql", "select 1;\n")

        def tambah_0017() -> None:
            _tulis(salinan, f"{DIR_MIGRASI}/0017_uji_diri.sql", "select 1;\n")

        def kembar_0016() -> None:
            _tulis(salinan, f"{DIR_MIGRASI}/0016_satu.sql", "select 1;\n")
            _tulis(salinan, f"{DIR_MIGRASI}/0016_dua.sql", "select 2;\n")

        mutasi("berkas beku disunting", ubah_0001)
        mutasi("berkas beku dihapus", hapus_0003)
        mutasi("berkas baru bernomor lama (0005)", tambah_0005)
        mutasi("nomor migrasi kembar (0016 ×2)", kembar_0016)
        mutasi("berkas baru bernomor benar (0017)", tambah_0017, harap_ditolak=False)

    merah = 0
    print("UJI-DIRI PERIKSA MIGRASI BEKU")
    for nama, lulus in kasus:
        if not lulus:
            merah += 1
        print(f"  {'OK ' if lulus else 'X  '} {nama}")
    if merah:
        print(f"\nHASIL: GAGAL — {merah} kasus uji-diri tidak sesuai harapan (penjaga mungkin tumpul)")
        return 1
    print("\nHASIL: LOLOS — penjaga terbukti bisa MENOLAK yang rusak dan MENERIMA yang utuh.")
    return 0


def main() -> int:
    if "--uji-diri" in sys.argv:
        return uji_diri()
    kode, temuan = periksa()
    if kode != 0:
        print(f"PERIKSA MIGRASI BEKU — GAGAL ({len(temuan)} temuan)")
        for t in temuan:
            print(f"  [X] {t}")
        print("\nHASIL: GAGAL — berkas migrasi yang hidup di proyek nyata wajib utuh & tidak disunting.")
        return 1
    print(
        f"PERIKSA MIGRASI BEKU — {len(BEKU)} berkas migrasi beku utuh; "
        f"berkas baru wajib bernomor ≥ {NOMOR_TERTINGGI_BEKU + 1:04d}."
    )
    print("\nHASIL: LOLOS — repo masih cocok dengan database nyata (bukti: jalankan dengan --uji-diri).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
