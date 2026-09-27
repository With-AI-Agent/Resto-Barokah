#!/usr/bin/env python3
"""
UJI MUTASI PENGAMAN CADANGAN & PEMULIHAN (T10-10 / TECH_SPEC §8 & §10)

Membuktikan secara deterministik bahwa seluruh pagar kegagalan-tertutup (fail-closed)
pada mekanisme cadangan, enkripsi AES-256, dan pemulihan bencana bekerja dengan benar:
bila proteksi dirusak, proses WAJIB GAGAL (MERAH).
"""

import os
import pathlib
import subprocess
import sys
import tempfile

AKAR = pathlib.Path(__file__).resolve().parents[1]
CADANGAN_SH = AKAR / "alat" / "cadangan.sh"
EKSEKUSI_MJS = AKAR / "alat" / "eksekusi-cadangan.mjs"


def jalankan_perintah(cmd: list[str], env: dict | None = None) -> tuple[int, str]:
    lingkungan = os.environ.copy()
    if env:
        lingkungan.update(env)
    res = subprocess.run(
        cmd,
        cwd=AKAR,
        capture_output=True,
        text=True,
        env=lingkungan,
    )
    return res.returncode, res.stdout + res.stderr


def main() -> int:
    print("=" * 70)
    print("UJI MUTASI PAGAR FAIL-CLOSED CADANGAN & PEMULIHAN (T10-10)")
    print("=" * 70)

    kasus_uji: list[tuple[str, bool, str]] = []

    # 0. Uji Kontrol (Salinan Sehat)
    print("[0] Menjalankan uji kontrol (alur sehat)...")
    kode, log = jalankan_perintah(
        ["bash", str(CADANGAN_SH), "uji-pemulihan"],
        {"KUNCI_ENKRIPSI_CADANGAN": "kunci-rahasia-cadangan-restoran-barokah-2026-aman"}
    )
    kontrol_lulus = (kode == 0) and ("PEMULIHAN BENCANA BERHASIL 100%" in log)
    kasus_uji.append(("KONTROL: alur cadangan & pemulihan sehat diterima", kontrol_lulus, log))
    if not kontrol_lulus:
        print(f"KONTROL GAGAL:\n{log}")
        return 1
    print("    KONTROL HIJAU: Alur normal berhasil 100%.\n")

    with tempfile.TemporaryDirectory(prefix="resto-mutasi-cadangan-") as tmp:
        tmp_p = pathlib.Path(tmp)
        dump_asli = tmp_p / "dump_asli.sql"
        dump_gz = tmp_p / "dump_asli.sql.gz"
        dump_enc = tmp_p / "dump_asli.sql.gz.enc"

        # Buat artefak awal
        kunci_sah = "kunci-rahasia-cadangan-restoran-barokah-2026-aman"
        jalankan_perintah(["node", str(EKSEKUSI_MJS), "--dump", str(dump_asli)])
        subprocess.run(["gzip", "-9", "-c", str(dump_asli)], stdout=open(dump_gz, "wb"))
        jalankan_perintah(
            ["bash", str(CADANGAN_SH), "enkripsi", str(dump_gz), str(dump_enc)],
            {"KUNCI_ENKRIPSI_CADANGAN": kunci_sah}
        )

        # Mutasi 1: Enkripsi tanpa kunci (KUNCI_ENKRIPSI_CADANGAN kosong)
        print("[Mutasi 1] Enkripsi tanpa menyetel kunci rahasia...")
        env_kosong = {"KUNCI_ENKRIPSI_CADANGAN": ""}
        kode_m1, log_m1 = jalankan_perintah(
            ["bash", str(CADANGAN_SH), "enkripsi", str(dump_gz), str(tmp_p / "m1.enc")],
            env_kosong
        )
        lulus_m1 = (kode_m1 != 0) and ("belum disetel" in log_m1 or "GALAT" in log_m1)
        kasus_uji.append(("MUTASI 1: Enkripsi tanpa kunci ditolak fail-closed", lulus_m1, log_m1))

        # Mutasi 2: Kunci enkripsi terlalu pendek (< 16 karakter)
        print("[Mutasi 2] Enkripsi dengan kunci lemah/pendek (< 16 karakter)...")
        env_pendek = {"KUNCI_ENKRIPSI_CADANGAN": "kunci123"}
        kode_m2, log_m2 = jalankan_perintah(
            ["bash", str(CADANGAN_SH), "enkripsi", str(dump_gz), str(tmp_p / "m2.enc")],
            env_pendek
        )
        lulus_m2 = (kode_m2 != 0) and ("terlalu pendek" in log_m2)
        kasus_uji.append(("MUTASI 2: Kunci enkripsi < 16 karakter ditolak", lulus_m2, log_m2))

        # Mutasi 3: Dekripsi dengan kunci yang salah
        print("[Mutasi 3] Dekripsi menggunakan kunci yang salah...")
        env_salah = {"KUNCI_ENKRIPSI_CADANGAN": "kunci-salah-yang-tidak-cocok-sama-sekali"}
        kode_m3, log_m3 = jalankan_perintah(
            ["bash", str(CADANGAN_SH), "dekripsi", str(dump_enc), str(tmp_p / "m3.sql.gz")],
            env_salah
        )
        lulus_m3 = (kode_m3 != 0)
        kasus_uji.append(("MUTASI 3: Dekripsi dengan kunci salah gagal fail-closed", lulus_m3, log_m3))

        # Mutasi 4: Dekripsi ciphertext yang dirusak/korup (tampered payload)
        print("[Mutasi 4] Dekripsi ciphertext yang dirusak/korup...")
        enc_rusak = tmp_p / "dump_rusak.enc"
        data_enc = dump_enc.read_bytes()
        # Rusak byte di tengah ciphertext
        data_rusak = data_enc[:50] + b"\x00\xff\x00\xff" + data_enc[54:]
        enc_rusak.write_bytes(data_rusak)
        kode_m4, log_m4 = jalankan_perintah(
            ["bash", str(CADANGAN_SH), "dekripsi", str(enc_rusak), str(tmp_p / "m4.sql.gz")],
            {"KUNCI_ENKRIPSI_CADANGAN": kunci_sah}
        )
        lulus_m4 = (kode_m4 != 0)
        kasus_uji.append(("MUTASI 4: Ciphertext rusak/tampered ditolak fail-closed", lulus_m4, log_m4))

        # Mutasi 5: Pemulihan dari berkas SQL yang sintaksnya cacat
        print("[Mutasi 5] Pemulihan dari berkas SQL cacat...")
        sql_cacat = tmp_p / "cacat.sql"
        sql_cacat.write_text("CREATE TABLE rusak (id int; INCOMPLETE SYNTAX ERROR !!!", encoding="utf-8")
        kode_m5, log_m5 = jalankan_perintah(
            ["node", str(EKSEKUSI_MJS), "--pulihkan", str(sql_cacat)]
        )
        lulus_m5 = (kode_m5 != 0)
        kasus_uji.append(("MUTASI 5: Pemulihan berkas SQL korup ditolak fail-closed", lulus_m5, log_m5))

        # Mutasi 6: Pemulihan kehilangan tabel penting (misal tabel penyewa dihapus dari dump)
        print("[Mutasi 6] Pemulihan kehilangan data tabel inti (penyewa dihapus)...")
        isi_asli = dump_asli.read_text(encoding="utf-8")
        # Hapus baris create table penyewa dan insert penyewa
        isi_tanpa_penyewa = isi_asli.replace("INSERT INTO public.\"penyewa\"", "-- DIHAPUS")
        sql_tanpa_penyewa = tmp_p / "tanpa_penyewa.sql"
        sql_tanpa_penyewa.write_text(isi_tanpa_penyewa, encoding="utf-8")
        kode_m6, log_m6 = jalankan_perintah(
            ["node", str(EKSEKUSI_MJS), "--pulihkan", str(sql_tanpa_penyewa)]
        )
        # Integritas relasional harus gagal karena tabel penyewa tidak memiliki baris
        lulus_m6 = (kode_m6 != 0)
        kasus_uji.append(("MUTASI 6: Pemulihan tanpa data penyewa gagal integritas", lulus_m6, log_m6))

    print("\nHASIL UJI MUTASI CADANGAN & PEMULIHAN:")
    semua_lulus = True
    for nama, lulus, log_err in kasus_uji:
        status = "OK (LULUS MERAH)" if lulus else "GAGAL (LOLOS)"
        print(f"  [{status}] {nama}")
        if not lulus:
            semua_lulus = False
            print(f"    Detail kegagalan:\n{log_err[:400]}")

    print("-" * 70)
    if semua_lulus:
        print(f"HASIL: 100% LOLOS — Seluruh {len(kasus_uji)} skenario mutasi fail-closed tertangkap.")
        return 0
    else:
        print("HASIL: GAGAL — Sebagian mutasi tidak tertangkap.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
