#!/usr/bin/env python3
"""Uji mutasi H-F-03.8 — hakim ronde 2 PMB1-F-038 (kartu B-F-03.5, migrasi 0099).

Jalankan dari akar repo:
  /home/user/.vpg/bin/python docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.8-mutasi.py
(venv butuh `pgserver` + `psycopg` untuk eksperimen kunci penasihat; eksperimen
 lain hanya memakai `node alat/uji-sql.mjs` + PGlite.)

Semua mutasi hanya pada salinan sementara di /tmp; migrasi/uji repo tidak disentuh.
Pohon "pra-perbaikan" dibangun dari commit basis `3ffd5af` (tip sebelum ronde 2)
lewat `git archive`, jadi eksperimen tidak bergantung ingatan.
Keluaran penuh: H-F-03.8-mutasi.txt.

Eksperimen:
  E0  pohon kerja · 0099 ambang `>=`→`>`                    → uji resmi batas MERAH (kasus 20)
  E1  pohon 3ffd5af · 0098 filter `dipakai_pada` dibuang    → berkas uji resmi tetap LULUS
      (temuan PMB1-F-229: klaim sekali-pakai tidak dijaga uji resmi)
  E2  pohon kerja  · 0098 filter `dipakai_pada` dibuang     → kasus 27 MERAH (pagar baru bekerja)
  E2b pohon kerja  · tanpa mutasi (kontrol)                 → kasus 27 LULUS dengan kode asli
  E3  pohon 3ffd5af · assertion residu pelanggan kasus 20   → LULUS (temuan PMB1-F-230 terbukti)
  E4  pohon kerja  · 0099 hapus DELETE residu               → kasus 27 MERAH; kontrol tanpa mutasi LULUS
  E5  pohon kerja  · 0099 kunci penasihat dinetralkan       → harness H-F-03.7 TERBUKTI lagi (kausalitas kunci)
"""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

AKAR = Path(__file__).resolve().parents[5]
BUKTI = AKAR / "docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.8-mutasi.txt"
BASIS = "3ffd5af"
PENANDA_RESIDU = "-- Kampanye baru milik kasus 21-26 (hitungan batas per kampanye)."
ASSERTION_RESIDU = """-- Hakim H-F-03.8 (ulang probe H-F-03.7 pada pohon pra-perbaikan):
reset role;
select uji.harap(
  (select count(*) = 1 from public.pelanggan
    where penyewa_id = '11111111-1111-1111-1111-111111111111'
      and nama = 'Tamu Keempat Sah'
      and telepon = '081300000020'
      and persetujuan_privasi),
  'probe hakim: pelanggan dari permintaan voucher yang ditolak tetap tersimpan (residu)'
);
set local role authenticated;
select uji.klaim('90000000-0000-0000-0000-000000000004');

"""
GUARD_STEMPEL = "       and pp.dipakai_pada is null\n"
AMBANG_LAMA = "if coalesce(v_sudah_didaftarkan, 0) >= v_batas_daftar then"
KUNCI_MULAI = "    perform pg_advisory_xact_lock("
DELETE_RESIDU = "          delete from public.pelanggan where id = v_pelanggan_id;"


def buang_kunci(pohon: Path) -> None:
    """Komentari seluruh pernyataan `perform pg_advisory_xact_lock(...);` (tetap sintaks sah)."""
    berkas = pohon / "supabase/migrations/0099_kunci_batas_pendaftaran_kasir_dan_residu.sql"
    sql = berkas.read_text(encoding="utf-8")
    i = sql.find(KUNCI_MULAI)
    j = sql.find(");", i)
    assert i > 0 and j > i
    berkas.write_text(
        sql[:i] + "-- MUTAN H-F-03.8: kunci penasihat dibuang\n" + sql[j + 2:],
        encoding="utf-8",
    )


def catat(catatan: list[str], pesan: str) -> None:
    print(pesan)
    catatan.append(pesan + "\n")


def salin_pohon(akar_tmp: Path, nama: str, basis: str | None = None) -> Path:
    """Salin pohon minimal untuk `uji-sql.mjs`; basis=None = pohon kerja, selain itu `git archive <commit>`."""
    pohon = akar_tmp / nama
    (pohon / "alat" / "sql").mkdir(parents=True)
    (pohon / "supabase").mkdir()
    shutil.copy2(AKAR / "alat/uji-sql.mjs", pohon / "alat/uji-sql.mjs")
    os.symlink(AKAR / "alat/node_modules", pohon / "alat/node_modules")
    shutil.copy2(AKAR / "alat/sql/data-uji.sql", pohon / "alat/sql/data-uji.sql")
    if basis is None:
        shutil.copytree(AKAR / "supabase/migrations", pohon / "supabase/migrations")
        shutil.copytree(AKAR / "supabase/tes", pohon / "supabase/tes")
    else:
        arsip = subprocess.run(
            ["git", "archive", basis, "supabase/migrations", "supabase/tes"],
            cwd=AKAR, text=True, stdout=subprocess.PIPE, check=True,
        )
        subprocess.run(["tar", "-x", "-C", str(pohon)], input=arsip.stdout.encode(), check=True)
    return pohon


def jalankan_uji_sql(catatan: list[str], judul: str, pohon: Path, uji: str, kode_harap: int,
                     label_harap: str | None = None) -> None:
    hasil = subprocess.run(
        ["node", str(pohon / "alat/uji-sql.mjs"), uji],
        cwd=pohon, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=600,
    )
    baris_gagal = [b for b in hasil.stdout.splitlines() if "GAGAL" in b or "HARAPAN TIDAK TERPENUHI" in b]
    catatan.append(
        f"\n===== {judul} =====\n$ node alat/uji-sql.mjs {uji}\nEXIT={hasil.returncode}\n"
        + "\n".join(baris_gagal[-8:] or hasil.stdout.splitlines()[-6:])
        + "\n"
    )
    if hasil.returncode != kode_harap:
        raise RuntimeError(f"{judul}: mengharap exit {kode_harap}, dapat {hasil.returncode}\n{hasil.stdout[-1800:]}")
    if label_harap is not None and not any(label_harap in b for b in baris_gagal):
        raise RuntimeError(f"{judul}: kegagalan tidak memuat label {label_harap!r}\n{hasil.stdout[-1800:]}")


def jalankan_harness(catatan: list[str], judul: str, pohon: Path, kode_harap: int) -> None:
    harness = pohon / "docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.7-konkurensi.py"
    hasil = subprocess.run(
        [sys.executable, str(harness)],
        cwd=pohon, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=600,
    )
    ekor = "\n".join(hasil.stdout.splitlines()[-4:])
    catatan.append(f"\n===== {judul} =====\nEXIT={hasil.returncode}\n{ekor}\n")
    if hasil.returncode != kode_harap:
        raise RuntimeError(f"{judul}: mengharap exit {kode_harap}, dapat {hasil.returncode}\n{hasil.stdout[-1800:]}")


def siapkan_harness(pohon: Path) -> None:
    tujuan = pohon / "docs/uji/pemeriksaan/PMB-1/bukti"
    tujuan.mkdir(parents=True)
    shutil.copy2(AKAR / "docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.7-konkurensi.py", tujuan / "H-F-03.7-konkurensi.py")
    shutil.copy2(AKAR / "alat/uji-konkuren.py", pohon / "alat/uji-konkuren.py")


def mutasi(pohon: Path, rel: str, lama: str, baru: str, jumlah: int = 1) -> None:
    berkas = pohon / rel
    sql = berkas.read_text(encoding="utf-8")
    assert sql.count(lama) == jumlah, f"penanda tidak pas di {rel}: {sql.count(lama)} != {jumlah}"
    berkas.write_text(sql.replace(lama, baru, jumlah), encoding="utf-8")


def main() -> int:
    catatan = [
        "UJI MUTASI H-F-03.8 — hakim ronde 2 F-038 (objek kartu B-F-03.5: migrasi 0099 + kasus 27).",
        "Semua mutasi pada salinan /tmp; pohon pra-perbaikan dari `git archive 3ffd5af`.",
        f"Pohon kerja = tip giliran ini; PGlite untuk uji SQL; pgserver (PostgreSQL sementara) untuk harness konkurensi.",
    ]
    with tempfile.TemporaryDirectory(prefix="h-f-03.8-mutasi-") as direktori:
        tmp = Path(direktori)

        # E0 — ambang 0099 digeser; uji resmi batas harus menangkap (kasus 20).
        pohon = salin_pohon(tmp, "mutan-0099-ambang")
        mutasi(pohon, "supabase/migrations/0099_kunci_batas_pendaftaran_kasir_dan_residu.sql",
               AMBANG_LAMA, "if coalesce(v_sudah_didaftarkan, 0) > v_batas_daftar then")
        jalankan_uji_sql(catatan, "E0 0099 ambang >=→>: uji resmi batas MERAH (kasus 20 menangkap)",
                         pohon, "supabase/tes/voucher_kasir_wajib_identitas.sql", 1)

        # E1 — pohon pra-perbaikan: guard stempel dibuang, berkas uji resmi lama tetap LULUS (temuan F-229).
        pohon = salin_pohon(tmp, "basis-mutan-0098", BASIS)
        mutasi(pohon, "supabase/migrations/0098_wajib_pin_atasan_pakai_voucher.sql",
               GUARD_STEMPEL, "       -- MUTAN H-F-03.8: pemeriksaan stempel terpakai dibuang\n")
        jalankan_uji_sql(catatan, "E1 pohon 3ffd5af + mutan 0098: berkas uji resmi tetap LULUS (temuan F-229 terbukti)",
                         pohon, "supabase/tes/pakai_voucher_pin_atasan.sql", 0)

        # E2 — pohon kerja: guard stempel dibuang, kasus 27 baru harus MERAH.
        pohon = salin_pohon(tmp, "kini-mutan-0098")
        mutasi(pohon, "supabase/migrations/0098_wajib_pin_atasan_pakai_voucher.sql",
               GUARD_STEMPEL, "       -- MUTAN H-F-03.8: pemeriksaan stempel terpakai dibuang\n")
        jalankan_uji_sql(catatan, "E2 pohon kerja + mutan 0098: kasus 27 MERAH (pagar F-229 bekerja)",
                         pohon, "supabase/tes/pakai_voucher_pin_atasan.sql", 1, label_harap="F-229:")

        # E2b — kontrol: pohon kerja tanpa mutasi harus LULUS.
        pohon = salin_pohon(tmp, "kini-kontrol")
        jalankan_uji_sql(catatan, "E2b pohon kerja tanpa mutasi (kontrol): kasus 27 LULUS",
                         pohon, "supabase/tes/pakai_voucher_pin_atasan.sql", 0)

        # E3 — pohon pra-perbaikan: residu pelanggan sesudah tolakan batas terbukti ada (temuan F-230).
        pohon = salin_pohon(tmp, "basis-residu", BASIS)
        mutasi(pohon, "supabase/tes/voucher_kasir_wajib_identitas.sql",
               PENANDA_RESIDU, ASSERTION_RESIDU + PENANDA_RESIDU)
        jalankan_uji_sql(catatan, "E3 pohon 3ffd5af + assertion residu: LULUS (temuan F-230 terbukti)",
                         pohon, "supabase/tes/voucher_kasir_wajib_identitas.sql", 0)

        # E4 — pohon kerja: DELETE residu dibuang dari 0099, kasus 27 harus MERAH; kontrol LULUS.
        pohon = salin_pohon(tmp, "kini-mutan-0099-tanpa-delete")
        mutasi(pohon, "supabase/migrations/0099_kunci_batas_pendaftaran_kasir_dan_residu.sql",
               DELETE_RESIDU, "          -- MUTAN H-F-03.8: penghapusan residu dibuang")
        jalankan_uji_sql(catatan, "E4 pohon kerja + mutan 0099 tanpa DELETE residu: kasus 27 MERAH (pagar F-230 bekerja)",
                         pohon, "supabase/tes/voucher_kasir_wajib_identitas.sql", 1, label_harap="F-230:")
        pohon = salin_pohon(tmp, "kini-kontrol-voucher")
        jalankan_uji_sql(catatan, "E4b pohon kerja tanpa mutasi (kontrol): berkas voucher LULUS penuh",
                         pohon, "supabase/tes/voucher_kasir_wajib_identitas.sql", 0)

        # E5 — pohon kerja: kunci penasihat dinetralkan; harness H-F-03.7 harus TERBUKTI lagi (exit 0).
        pohon = salin_pohon(tmp, "kini-mutan-0099-tanpa-kunci")
        buang_kunci(pohon)
        siapkan_harness(pohon)
        jalankan_harness(catatan, "E5 pohon kerja + mutan 0099 tanpa kunci: harness TERBUKTI (kausalitas kunci)",
                         pohon, 0)

    catatan.append("\nSEMUA EKSPERIMEN SESUAI HARAPAN.")
    BUKTI.write_text("\n".join(catatan) + "\n", encoding="utf-8")
    print(f"\nKeluaran penuh: {BUKTI}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
