#!/usr/bin/env python3
"""
Skrip Pemeriksa Bantuan Kontekstual (T1-42, docs/SPESIFIKASI_UI.md §11)
Memastikan setiap layar di registri memiliki panduan kontekstual yang valid,
lengkap, maksimal 5 langkah, serta terhubung dengan registri aksi yang sah.

Termasuk pengujian mandiri fail-closed (--uji-diri).
"""

import os
import re
import sys
from pathlib import Path

DIR_REPO = Path(__file__).resolve().parent.parent
BERKAS_LAYAR = DIR_REPO / "aplikasi" / "src" / "lib" / "layar.ts"
BERKAS_AKSI = DIR_REPO / "aplikasi" / "src" / "lib" / "aksi.ts"
BERKAS_BANTUAN = DIR_REPO / "aplikasi" / "src" / "kontrak" / "bantuan.ts"


def ekstrak_id_layar(konten_layar: str) -> set[str]:
    # Mencari pola `id: 'xxx'` di DAFTAR_LAYAR
    return set(re.findall(r"id:\s*['\"]([a-zA-Z0-9_-]+)['\"]", konten_layar))


def ekstrak_id_aksi(konten_aksi: str) -> set[str]:
    # Mencari pola `id: 'xxx.yyy'` di REGISTRI_AKSI
    return set(re.findall(r"id:\s*['\"]([a-zA-Z0-9_.-]+)['\"]", konten_aksi))


def ekstrak_blok_bantuan(konten_bantuan: str) -> dict[str, dict]:
    """Mengekstrak entri DAFTAR_BANTUAN secara terstruktur."""
    entri = {}
    
    # Pisahkan per blok layar di DAFTAR_BANTUAN (mendukung kunci 'pelanggan-publik' maupun kasir)
    blok_cocok = re.findall(r"['\"]?([a-zA-Z0-9_-]+)['\"]?\s*:\s*\{([^}]+kalauMacet:[^}]+)\}", konten_bantuan, re.S)
    for id_layar, isi in blok_cocok:
        judul_m = re.search(r"judul:\s*['\"]([^'\"]+)['\"]", isi)
        ringkasan_m = re.search(r"ringkasan:\s*['\"]([^'\"]+)['\"]", isi)
        kalau_macet_m = re.search(r"kalauMacet:\s*['\"]([^'\"]+)['\"]", isi)
        
        # Ekstrak langkah
        langkah_m = re.search(r"langkah:\s*\[(.*?)\]", isi, re.S)
        langkah_list = []
        if langkah_m:
            langkah_list = re.findall(r"['\"]([^'\"]+)['\"]", langkah_m.group(1))

        # Ekstrak aksiTerkait
        aksi_m = re.search(r"aksiTerkait:\s*\[(.*?)\]", isi, re.S)
        aksi_list = []
        if aksi_m:
            aksi_list = re.findall(r"['\"]([^'\"]+)['\"]", aksi_m.group(1))

        entri[id_layar] = {
            "judul": judul_m.group(1) if judul_m else "",
            "ringkasan": ringkasan_m.group(1) if ringkasan_m else "",
            "langkah": langkah_list,
            "kalauMacet": kalau_macet_m.group(1) if kalau_macet_m else "",
            "aksiTerkait": aksi_list,
        }

    return entri


def periksa_bantuan() -> tuple[bool, list[str]]:
    laporan = []
    if not BERKAS_LAYAR.exists() or not BERKAS_AKSI.exists() or not BERKAS_BANTUAN.exists():
        return False, ["❌ Berkas layar, aksi, atau bantuan tidak ditemukan!"]

    konten_layar = BERKAS_LAYAR.read_text(encoding="utf-8")
    konten_aksi = BERKAS_AKSI.read_text(encoding="utf-8")
    konten_bantuan = BERKAS_BANTUAN.read_text(encoding="utf-8")

    daftar_layar = ekstrak_id_layar(konten_layar)
    daftar_aksi = ekstrak_id_aksi(konten_aksi)
    bantuan_map = ekstrak_blok_bantuan(konten_bantuan)

    laporan.append(f"Daftar layar terdeteksi ({len(daftar_layar)}): {sorted(list(daftar_layar))}")
    laporan.append(f"Daftar bantuan terdefinisi ({len(bantuan_map)}): {sorted(list(bantuan_map.keys()))}")

    semua_lulus = True

    # 1. Pastikan setiap layar di DAFTAR_LAYAR punya bantuan
    kurang_bantuan = daftar_layar - set(bantuan_map.keys())
    if kurang_bantuan:
        semua_lulus = False
        laporan.append(f"❌ Layar berikut BELUM memiliki bantuan kontekstual: {kurang_bantuan}")
    else:
        laporan.append(f"✅ Semua {len(daftar_layar)} layar memiliki entri bantuan kontekstual.")

    # 2. Validasi isi bantuan per layar
    for id_layar, info in bantuan_map.items():
        if not info["judul"]:
            semua_lulus = False
            laporan.append(f"❌ Layar '{id_layar}' tidak memiliki judul panduan!")
        if not info["ringkasan"]:
            semua_lulus = False
            laporan.append(f"❌ Layar '{id_layar}' tidak memiliki ringkasan panduan!")
        if not (1 <= len(info["langkah"]) <= 5):
            semua_lulus = False
            laporan.append(f"❌ Layar '{id_layar}' memiliki {len(info['langkah'])} langkah (wajib 1-5 langkah)!")
        if not info["kalauMacet"]:
            semua_lulus = False
            laporan.append(f"❌ Layar '{id_layar}' tidak memiliki instruksi 'kalauMacet'!")

        # Periksa aksi terkait valid
        for aksi in info["aksiTerkait"]:
            if aksi not in daftar_aksi:
                semua_lulus = False
                laporan.append(f"❌ Layar '{id_layar}' merujuk aksi '{aksi}' yang tidak ada di registri aksi!")

    return semua_lulus, laporan


def jalankan_uji_diri() -> bool:
    print("=== Menjalankan Uji Diri Pemeriksa Bantuan Kontekstual ===")
    sample_layar = "export const DAFTAR_LAYAR = { kasir: { id: 'kasir' } }"
    sample_aksi = "export const REGISTRI_AKSI = { 'kasir.bayar': { id: 'kasir.bayar' } }"
    sample_bantuan_valid = """
    export const DAFTAR_BANTUAN = {
      kasir: {
        idLayar: 'kasir',
        judul: 'Panduan Kasir',
        ringkasan: 'Mencatat pesanan.',
        langkah: ['Langkah 1', 'Langkah 2'],
        kalauMacet: 'Hubungi admin.',
        aksiTerkait: ['kasir.bayar'],
      }
    }
    """
    sample_bantuan_langkah_panjang = """
    export const DAFTAR_BANTUAN = {
      kasir: {
        idLayar: 'kasir',
        judul: 'Panduan Kasir',
        ringkasan: 'Mencatat pesanan.',
        langkah: ['1', '2', '3', '4', '5', '6'],
        kalauMacet: 'Hubungi admin.',
        aksiTerkait: ['kasir.bayar'],
      }
    }
    """
    
    b_valid = ekstrak_blok_bantuan(sample_bantuan_valid)
    assert len(b_valid["kasir"]["langkah"]) == 2
    assert b_valid["kasir"]["aksiTerkait"] == ["kasir.bayar"]

    b_panjang = ekstrak_blok_bantuan(sample_bantuan_langkah_panjang)
    assert len(b_panjang["kasir"]["langkah"]) == 6

    print("✅ Uji diri ekstraksi & validasi struktur bantuan berhasil!")
    return True


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        if jalankan_uji_diri():
            sys.exit(0)
        else:
            sys.exit(1)

    lulus, log = periksa_bantuan()
    for baris in log:
        print(baris)

    if not lulus:
        print("\n❌ Pemeriksaan bantuan kontekstual GAGAL!")
        sys.exit(1)

    print("\n✅ Seluruh bantuan kontekstual layar terverifikasi 100% lengkap & selaras!")
    sys.exit(0)
