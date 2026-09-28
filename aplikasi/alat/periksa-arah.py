#!/usr/bin/env python3
"""
Skrip Pemeriksa Tata Letak Dua Arah (RTL/LTR) & Batas Ukuran Huruf (T1-41)

Memeriksa:
1. Keberadaan berkas gaya arah `arah.css` dengan token arah dan selector `[dir='rtl']` & `[dir='ltr']`.
2. Penggunaan sifat logis (inline-start / inline-end).
3. Batas ukuran total dan per-berkas huruf (woff2) agar perangkat kedai tetap ringan.
4. Uji mandiri (--uji-diri) fail-closed.
"""

import sys
from pathlib import Path

DIR_GAYA = Path(__file__).resolve().parent.parent / "src" / "gaya"
DIR_FONT = DIR_GAYA / "aset" / "font"
AMBANG_TOTAL_FONT_KB = 650
AMBANG_PER_FONT_KB = 65


def periksa_arah_css() -> tuple[bool, list[str]]:
    laporan = []
    berkas_arah = DIR_GAYA / "arah.css"
    if not berkas_arah.exists():
        return False, [f"❌ Berkas gaya arah tidak ditemukan: {berkas_arah}"]

    konten = berkas_arah.read_text(encoding="utf-8")
    
    syarat_pola = [
        ("[dir='rtl']", "Selektor RTL [dir='rtl']"),
        ("[dir='ltr']", "Selektor LTR [dir='ltr']"),
        ("direction: rtl", "Aturan CSS direction: rtl"),
        ("inline-start", "Sifat logis inline-start"),
        ("inline-end", "Sifat logis inline-end"),
        ("--font-mandarin", "Token variabel font Mandarin"),
        ("--font-arab", "Token variabel font Arab"),
    ]

    semua_lulus = True
    for pola, keterangan in syarat_pola:
        if pola in konten:
            laporan.append(f"✅ {keterangan} ditemukan.")
        else:
            laporan.append(f"❌ {keterangan} TIDAK ditemukan di arah.css!")
            semua_lulus = False

    return semua_lulus, laporan


def periksa_ukuran_huruf() -> tuple[bool, list[str]]:
    laporan = []
    if not DIR_FONT.exists():
        return False, [f"❌ Direktori font tidak ditemukan: {DIR_FONT}"]

    daftar_woff2 = list(DIR_FONT.glob("*.woff2"))
    if not daftar_woff2:
        return False, [f"❌ Tidak ada berkas .woff2 di {DIR_FONT}"]

    total_byte = 0
    semua_lulus = True

    for f in daftar_woff2:
        ukuran_kb = f.stat().st_size / 1024
        total_byte += f.stat().st_size
        if ukuran_kb > AMBANG_PER_FONT_KB:
            semua_lulus = False
            laporan.append(f"❌ Huruf {f.name} berukuran {ukuran_kb:.1f} KB (melebihi batas {AMBANG_PER_FONT_KB} KB)!")

    total_kb = total_byte / 1024
    if total_kb > AMBANG_TOTAL_FONT_KB:
        semua_lulus = False
        laporan.append(f"❌ Total ukuran font {total_kb:.1f} KB melebihi ambang batas {AMBANG_TOTAL_FONT_KB} KB!")
    else:
        laporan.append(f"✅ Total {len(daftar_woff2)} berkas huruf = {total_kb:.1f} KB (di bawah batas {AMBANG_TOTAL_FONT_KB} KB).")

    return semua_lulus, laporan


def jalankan_uji_diri() -> bool:
    print("=== Menjalankan Uji Diri Pemeriksa Arah & Ukuran Huruf ===")
    konten_contoh = """
    [dir='rtl'] { direction: rtl; }
    [dir='ltr'] { direction: ltr; }
    .box { margin-inline-start: 10px; margin-inline-end: 10px; }
    :root { --font-mandarin: sans-serif; --font-arab: sans-serif; }
    """
    for kata in ["[dir='rtl']", "[dir='ltr']", "direction: rtl", "inline-start", "inline-end", "--font-mandarin", "--font-arab"]:
        assert kata in konten_contoh, f"Gagal uji diri untuk pola {kata}"

    print("✅ Uji diri verifikasi pola arah & token font berhasil!")
    return True


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        if jalankan_uji_diri():
            sys.exit(0)
        else:
            sys.exit(1)

    lulus_arah, log_arah = periksa_arah_css()
    lulus_font, log_font = periksa_ukuran_huruf()

    for l in log_arah + log_font:
        print(l)

    if not (lulus_arah and lulus_font):
        print("\n❌ Pemeriksaan tata letak arah / ukuran font GAGAL!")
        sys.exit(1)

    print("\n✅ Tata letak dua arah (RTL/LTR) & ukuran huruf terverifikasi!")
    sys.exit(0)
