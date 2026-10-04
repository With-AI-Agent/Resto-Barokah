#!/usr/bin/env python3
"""Uji mutasi terkalibrasi untuk migrasi 0097 dan 0098.

Jalankan dari akar repo: `python3 docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.7-mutasi.py`.
Empat eksperimen dijalankan pada salinan sementara di /tmp; migrasi dan uji repo
asli hanya dibaca. Hasil lengkap ditulis ke H-F-03.7-mutasi.txt.
"""
from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
from pathlib import Path

AKAR = Path(__file__).resolve().parents[5]
BUKTI = AKAR / "docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.7-mutasi.txt"
PENANDA_KASUS_7 = "-- 7. Stempel SEKALI PAKAI: stempel yang sama tidak bisa dipakai untuk voucher lain."
PROBE_PAKAI_ULANG = """-- Probe hakim: baca stempel dengan role owner (RLS kasir tak melihat catatan owner).
reset role;
select uji.harap(
  (select count(*) = 1 from public.percobaan_pin
    where pengguna_id = '90000000-0000-0000-0000-000000000002'
      and aksi = 'pakai_voucher'
      and pesanan_id = 'eeee0000-0000-0000-0000-000000000211'
      and berhasil and dipakai_pada is not null),
  'probe hakim: stempel atasan untuk pesanan 211 sudah terpakai'
);
update public.pesanan set subtotal = 60000, total = 69000
 where id = 'eeee0000-0000-0000-0000-000000000211';
set local role authenticated;
select uji.klaim('90000000-0000-0000-0000-000000000004');
select uji.sama(
  (public.pakai_voucher('eeee0000-0000-0000-0000-000000000211', 'VC-BA-03', '1234',
                        null, null, null,
                        '90000000-0000-0000-0000-000000000002') ->> 'kode'),
  'PERSETUJUAN_ATASAN_WAJIB',
  'probe hakim: stempel yang sudah dipakai tidak dapat dipakai ulang pada pesanan yang sama'
);

"""


def salin_pohon(akar_tmp: Path, nama: str) -> Path:
    pohon = akar_tmp / nama
    (pohon / "alat" / "sql").mkdir(parents=True)
    (pohon / "supabase").mkdir()
    shutil.copy2(AKAR / "alat/uji-sql.mjs", pohon / "alat/uji-sql.mjs")
    os.symlink(AKAR / "alat/node_modules", pohon / "alat/node_modules")
    shutil.copy2(AKAR / "alat/sql/data-uji.sql", pohon / "alat/sql/data-uji.sql")
    shutil.copytree(AKAR / "supabase/migrations", pohon / "supabase/migrations")
    shutil.copytree(AKAR / "supabase/tes", pohon / "supabase/tes")
    return pohon


def jalankan(catatan: list[str], judul: str, pohon: Path, uji: str, kode_harap: int) -> None:
    hasil = subprocess.run(
        ["node", str(pohon / "alat/uji-sql.mjs"), uji],
        cwd=pohon,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=180,
    )
    catatan.append(
        f"\n===== {judul} =====\n$ node alat/uji-sql.mjs {uji}\n"
        f"EXIT={hasil.returncode}\n{hasil.stdout}"
    )
    if hasil.returncode != kode_harap:
        raise RuntimeError(
            f"{judul}: mengharap exit {kode_harap}, dapat {hasil.returncode}\n"
            f"{hasil.stdout[-1800:]}"
        )


def main() -> None:
    catatan = [
        "UJI MUTASI H-F-03.7 — semua mutasi hanya pada salinan sementara di /tmp; migrasi/uji repo tidak disentuh.",
        "M1: ambang 0097 >= diubah menjadi >; M2: filter dipakai_pada dibuang dari 0098.",
        "Probe tambahan memakai PESANAN YANG SAMA setelah stempel sukses dikonsumsi. Probe melihat row percobaan sebagai owner (RLS staf menyembunyikan baris owner), memulihkan subtotal fixture sebagai owner, lalu mengulang dengan voucher lain.",
    ]
    with tempfile.TemporaryDirectory(prefix="h-f-03.7-mutasi-") as direktori:
        sementara = Path(direktori)

        # M1 — menggeser batas satu pelanggan: kasus resmi 20 harus menangkap.
        pohon = salin_pohon(sementara, "mutan-0097")
        migrasi = pohon / "supabase/migrations/0097_batas_daftar_pelanggan_kasir_per_kampanye.sql"
        sql = migrasi.read_text(encoding="utf-8")
        lama = "if coalesce(v_sudah_didaftarkan, 0) >= v_batas_daftar then"
        assert sql.count(lama) == 1
        migrasi.write_text(
            sql.replace(lama, "if coalesce(v_sudah_didaftarkan, 0) > v_batas_daftar then", 1),
            encoding="utf-8",
        )
        jalankan(
            catatan,
            "M1 0097: >= menjadi >; uji resmi batas harus MERAH (kasus 20)",
            pohon,
            "supabase/tes/voucher_kasir_wajib_identitas.sql",
            1,
        )

        # Mutu aktual 0098 — probe penggunaan ulang pada pesanan yang sama harus lolos.
        pohon = salin_pohon(sementara, "aktual-0098-probe-tambahan")
        uji = pohon / "supabase/tes/pakai_voucher_pin_atasan.sql"
        sql = uji.read_text(encoding="utf-8")
        assert sql.count(PENANDA_KASUS_7) == 1
        uji.write_text(sql.replace(PENANDA_KASUS_7, PROBE_PAKAI_ULANG + PENANDA_KASUS_7, 1), encoding="utf-8")
        jalankan(
            catatan,
            "0098 aktual + probe penggunaan ulang pada pesanan yang sama: LULUS",
            pohon,
            "supabase/tes/pakai_voucher_pin_atasan.sql",
            0,
        )

        # M2 — mutasi guard hilang; uji asli masih hijau, menunjukkan celah cakupan.
        pohon = salin_pohon(sementara, "mutan-0098-uji-asli")
        migrasi = pohon / "supabase/migrations/0098_wajib_pin_atasan_pakai_voucher.sql"
        sql = migrasi.read_text(encoding="utf-8")
        lama = "       and pp.dipakai_pada is null\n"
        assert sql.count(lama) == 1
        migrasi.write_text(
            sql.replace(lama, "       -- MUTAN: tidak memeriksa stempel yang sudah dipakai\n", 1),
            encoding="utf-8",
        )
        jalankan(
            catatan,
            "M2 0098: hapus dipakai_pada guard, berkas uji resmi tetap LULUS (cacat cakupan)",
            pohon,
            "supabase/tes/pakai_voucher_pin_atasan.sql",
            0,
        )

        # M2 dengan probe hakim tambahan — penghapusan guard harus menjadi merah.
        pohon = salin_pohon(sementara, "mutan-0098-probe-tambahan")
        migrasi = pohon / "supabase/migrations/0098_wajib_pin_atasan_pakai_voucher.sql"
        sql = migrasi.read_text(encoding="utf-8")
        assert sql.count(lama) == 1
        migrasi.write_text(
            sql.replace(lama, "       -- MUTAN: tidak memeriksa stempel yang sudah dipakai\n", 1),
            encoding="utf-8",
        )
        uji = pohon / "supabase/tes/pakai_voucher_pin_atasan.sql"
        sql = uji.read_text(encoding="utf-8")
        assert sql.count(PENANDA_KASUS_7) == 1
        uji.write_text(sql.replace(PENANDA_KASUS_7, PROBE_PAKAI_ULANG + PENANDA_KASUS_7, 1), encoding="utf-8")
        jalankan(
            catatan,
            "M2 0098: hapus dipakai_pada guard, probe penggunaan ulang tambahan MERAH",
            pohon,
            "supabase/tes/pakai_voucher_pin_atasan.sql",
            1,
        )

    BUKTI.write_text("\n".join(catatan).rstrip("\n") + "\n", encoding="utf-8")
    print(
        "HASIL MUTASI: 0097 off-by-one tertangkap; 0098 aktual lolos probe same-order; "
        "mutan 0098 tertangkap probe tambahan, tetapi lolos seluruh uji resmi yang dikirim."
    )
    print(f"Bukti lengkap: {BUKTI.relative_to(AKAR)} ({BUKTI.stat().st_size} byte)")
    for bagian in catatan[3:]:
        print("\n".join(bagian.splitlines()[-12:]))


if __name__ == "__main__":
    main()
