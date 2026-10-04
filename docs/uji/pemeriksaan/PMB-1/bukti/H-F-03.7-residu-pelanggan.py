#!/usr/bin/env python3
"""Buktikan apa yang tersimpan sesudah batas pendaftaran voucher menolak.

Jalankan dari akar repo: `python3 docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.7-residu-pelanggan.py`.
Skrip hanya menyisipkan assertion ke salinan sementara berkas uji resmi; source
repo tidak disentuh. Keluaran penuh ditulis ke H-F-03.7-residu-pelanggan.txt.
"""
from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
from pathlib import Path

AKAR = Path(__file__).resolve().parents[5]
BUKTI = AKAR / "docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.7-residu-pelanggan.txt"
PENANDA = "-- Kampanye baru milik kasus 21-26 (hitungan batas per kampanye)."
ASSERTION = """-- Hakim: permintaan yang ditolak cap tidak semestinya diam-diam membuat data pelanggan?
reset role;
select uji.harap(
  (select count(*) = 1 from public.pelanggan
    where penyewa_id = '11111111-1111-1111-1111-111111111111'
      and nama = 'Tamu Keempat Sah'
      and telepon = '081300000020'
      and persetujuan_privasi),
  'probe hakim: pelanggan dari permintaan voucher yang ditolak tetap tersimpan dengan persetujuan_privasi=true'
);
select uji.harap(
  not exists (select 1 from public.voucher v join public.pelanggan p on p.id=v.pelanggan_id
    where p.penyewa_id='11111111-1111-1111-1111-111111111111'
      and p.telepon='081300000020'
      and v.kampanye_id='c3000000-0000-0000-0000-000000000038'),
  'probe hakim: baris pelanggan tidak mendapat voucher'
);
set local role authenticated;
select uji.klaim('90000000-0000-0000-0000-000000000004');

"""


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="h-f-03.7-residu-") as direktori:
        pohon = Path(direktori)
        (pohon / "alat/sql").mkdir(parents=True)
        (pohon / "supabase").mkdir()
        shutil.copy2(AKAR / "alat/uji-sql.mjs", pohon / "alat/uji-sql.mjs")
        os.symlink(AKAR / "alat/node_modules", pohon / "alat/node_modules")
        shutil.copy2(AKAR / "alat/sql/data-uji.sql", pohon / "alat/sql/data-uji.sql")
        shutil.copytree(AKAR / "supabase/migrations", pohon / "supabase/migrations")
        shutil.copytree(AKAR / "supabase/tes", pohon / "supabase/tes")

        uji = pohon / "supabase/tes/voucher_kasir_wajib_identitas.sql"
        sql = uji.read_text(encoding="utf-8")
        if sql.count(PENANDA) != 1:
            raise RuntimeError("penanda sesudah kasus 20 tidak unik / hilang")
        uji.write_text(sql.replace(PENANDA, ASSERTION + PENANDA, 1), encoding="utf-8")

        hasil = subprocess.run(
            ["node", str(pohon / "alat/uji-sql.mjs"), "supabase/tes/voucher_kasir_wajib_identitas.sql"],
            cwd=pohon,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=180,
        )
        BUKTI.write_text(
            "$ node alat/uji-sql.mjs (salinan uji: assertion residu sesudah kasus 20)\n"
            f"EXIT={hasil.returncode}\n{hasil.stdout}",
            encoding="utf-8",
        )
        print("EXIT", hasil.returncode)
        print("\n".join(hasil.stdout.splitlines()[-18:]))
        print("Bukti:", BUKTI.relative_to(AKAR))
        if hasil.returncode != 0:
            raise SystemExit(hasil.returncode)


if __name__ == "__main__":
    main()
