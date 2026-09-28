#!/usr/bin/env python3
"""periksa-audit.py — pemeriksa integritas skema catatan audit & rantai hash (T1-13 & T1-27).

Aturan yang ditegakkan:
 1. Migrasi 0029 memuat trigger penolakan UPDATE dan DELETE pada catatan_audit (T1-13).
 2. Migrasi 0029 memuat trigger penghitungan rantai hash (hash_sebelumnya & hash_baris) (T1-27).
 3. Migrasi 0029 memuat RPC verifikasi_rantai_audit yang mengembalikan keutuhan rantai.
 4. Memiliki mode --uji-diri untuk memastikan validator gagal-tertutup.
"""
from __future__ import annotations

import pathlib
import sys

from bantu_uji_diri import AKAR, laporkan, salin_pohon

MIG = "supabase/migrations/0029_audit_kekal_rantai.sql"
TES = "supabase/tes/audit_rantai.sql"


def periksa(akar: pathlib.Path) -> int:
    errs: list[str] = []
    berkas_mig = akar / MIG
    berkas_tes = akar / TES

    if not berkas_mig.is_file():
        print(f"GAGAL: berkas migrasi {MIG} tidak ditemukan.")
        return 1

    if not berkas_tes.is_file():
        print(f"GAGAL: berkas pengujian {TES} tidak ditemukan.")
        return 1

    teks_mig = berkas_mig.read_text(encoding="utf-8")
    teks_tes = berkas_tes.read_text(encoding="utf-8")

    # 1. Periksa Trigger Pencegah UPDATE/DELETE (T1-13)
    if "cegah_ubah_hapus_audit" not in teks_mig or "before update or delete" not in teks_mig.lower():
        errs.append("Trigger penolakan UPDATE/DELETE tidak ditemukan pada migrasi audit.")

    # 2. Periksa Kolom dan Trigger Rantai Hash (T1-27)
    if "hash_sebelumnya" not in teks_mig or "hash_baris" not in teks_mig:
        errs.append("Kolom hash_sebelumnya atau hash_baris tidak ditemukan.")

    if "hitung_hash_catatan_audit" not in teks_mig:
        errs.append("Trigger hitung_hash_catatan_audit tidak ditemukan pada migrasi audit.")

    # 3. Periksa Fungsi Verifikasi Rantai
    if "verifikasi_rantai_audit" not in teks_mig:
        errs.append("Fungsi verifikasi_rantai_audit tidak ditemukan pada migrasi audit.")

    # 4. Periksa Uji Penolakan UPDATE/DELETE dan Verifikasi Rantai di Berkas Uji
    if "update public.catatan_audit" not in teks_tes:
        errs.append("Uji penolakan UPDATE tidak ditemukan pada berkas uji audit_rantai.sql.")

    if "delete from public.catatan_audit" not in teks_tes:
        errs.append("Uji penolakan DELETE tidak ditemukan pada berkas uji audit_rantai.sql.")

    if "verifikasi_rantai_audit" not in teks_tes:
        errs.append("Uji verifikasi_rantai_audit tidak ditemukan pada berkas uji audit_rantai.sql.")

    if errs:
        print(f"GAGAL: {len(errs)} temuan pada pemeriksaan audit:")
        for e in errs:
            print(f"  [X] {e}")
        return 1

    print("PERIKSA AUDIT — migrasi 0029 & berkas uji audit_rantai.sql lengkap & valid.")
    return 0


def uji_diri() -> int:
    hasil = []
    with salin_pohon() as tmp:
        # 1. Salinan utuh
        kode0 = periksa(tmp)
        hasil.append(("salinan utuh", kode0 == 0, "diterima"))

        # 2. Mutasi: hapus trigger pencegah update/delete
        with salin_pohon() as tmp2:
            f = tmp2 / MIG
            f.write_text(f.read_text().replace("cegah_ubah_hapus_audit", "dummy_fungsi"))
            kode2 = periksa(tmp2)
            hasil.append(("mutasi: trigger tolak update/delete hilang", kode2 != 0, "ditolak" if kode2 != 0 else "LOLOS"))

        # 3. Mutasi: hapus fungsi verifikasi rantai audit
        with salin_pohon() as tmp3:
            f = tmp3 / MIG
            f.write_text(f.read_text().replace("verifikasi_rantai_audit", "dummy_verifikasi"))
            kode3 = periksa(tmp3)
            hasil.append(("mutasi: fungsi verifikasi rantai hilang", kode3 != 0, "ditolak" if kode3 != 0 else "LOLOS"))

    return laporkan("periksa-audit", hasil)


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(periksa(AKAR))
