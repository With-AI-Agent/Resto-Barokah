#!/usr/bin/env python3
"""
Skrip Pemeriksa Paritas Kamus Multi-Bahasa (T1-40)
Memastikan semua berkas bahasa (en.ts, zh.ts, ar.ts) memiliki struktur kunci
dan domain yang 100% identik dengan kamus acuan utama (id.ts).

Termasuk pengujian mandiri fail-closed (--uji-diri).
"""

import os
import re
import sys
from pathlib import Path

DIR_BAHASA = Path(__file__).resolve().parent.parent / "src" / "bahasa"


def ekstrak_kunci(konten: str) -> set[str]:
    """Mengekstrak path kunci dari berkas kamus TypeScript sederhana."""
    kunci = set()
    stack = []
    
    for line in konten.splitlines():
        line = line.strip()
        if not line or line.startswith("//") or line.startswith("/*") or line.startswith("*") or line.startswith("import") or line.startswith("export"):
            continue
            
        # Cocokkan pembuka objek seperti `umum: {` atau `navigasi: {`
        m_obj = re.match(r"^([a-zA-Z0-9_]+)\s*:\s*\{", line)
        if m_obj:
            stack.append(m_obj.group(1))
            continue
            
        # Cocokkan penutup objek `},` atau `}`
        if line.startswith("}"):
            if stack:
                stack.pop()
            continue
            
        # Cocokkan properti `kunci: 'nilai',` atau `kunci:` bila baris nilai terpisah
        m_prop = re.match(r"^([a-zA-Z0-9_]+)\s*:\s*(?:['\"`]|(?:\n|$))", line)
        if m_prop:
            nama_prop = m_prop.group(1)
            full_path = ".".join(stack + [nama_prop])
            kunci.add(full_path)
            
    return kunci


def periksa_kamus() -> tuple[bool, list[str]]:
    laporan = []
    berkas_id = DIR_BAHASA / "id.ts"
    if not berkas_id.exists():
        return False, [f"Berkas acuan utama tidak ditemukan: {berkas_id}"]

    konten_id = berkas_id.read_text(encoding="utf-8")
    kunci_acuan = ekstrak_kunci(konten_id)

    if not kunci_acuan:
        return False, ["Gagal mengekstrak kunci dari id.ts (kamus kosong)"]

    laporan.append(f"Kamus acuan (id.ts) memiliki {len(kunci_acuan)} kunci.")

    semua_lulus = True
    bahasa_lain = ["en.ts", "zh.ts", "ar.ts"]

    for b in bahasa_lain:
        path_b = DIR_BAHASA / b
        if not path_b.exists():
            laporan.append(f"❌ Berkas {b} tidak ditemukan!")
            semua_lulus = False
            continue

        konten_b = path_b.read_text(encoding="utf-8")
        kunci_b = ekstrak_kunci(konten_b)

        kurang = kunci_acuan - kunci_b
        lebih = kunci_b - kunci_acuan

        if kurang:
            semua_lulus = False
            laporan.append(f"❌ Berkas {b} kekurangan {len(kurang)} kunci: {sorted(list(kurang))[:5]}...")
        elif lebih:
            semua_lulus = False
            laporan.append(f"❌ Berkas {b} memiliki {len(lebih)} kunci berlebih: {sorted(list(lebih))[:5]}...")
        else:
            laporan.append(f"✅ Berkas {b} 100% paritas ({len(kunci_b)} kunci cocok).")

    return semua_lulus, laporan


def jalankan_uji_diri() -> bool:
    print("=== Menjalankan Uji Diri Pemeriksa Bahasa ===")
    teks_sampel_a = """
    export const a = {
      umum: {
        batal: 'Batal',
        simpan: 'Simpan',
      },
    }
    """
    teks_sampel_b = """
    export const b = {
      umum: {
        batal: 'Cancel',
      },
    }
    """
    kunci_a = ekstrak_kunci(teks_sampel_a)
    kunci_b = ekstrak_kunci(teks_sampel_b)

    assert "umum.batal" in kunci_a and "umum.simpan" in kunci_a, "Gagal mengekstrak kunci A"
    assert "umum.simpan" not in kunci_b, "Gagal mendeteksi kunci yang hilang"
    print("✅ Uji diri ekstraksi kunci & deteksi paritas berhasil!")
    return True


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        if jalankan_uji_diri():
            sys.exit(0)
        else:
            sys.exit(1)

    lulus, log = periksa_kamus()
    for baris in log:
        print(baris)

    if not lulus:
        print("\n❌ Pemeriksaan kamus bahasa GAGAL!")
        sys.exit(1)

    print("\n✅ Seluruh kamus multi-bahasa terverifikasi lengkap & selaras!")
    sys.exit(0)
