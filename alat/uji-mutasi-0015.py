#!/usr/bin/env python3
"""uji-mutasi-0015.py — bukti bahwa pagar penutup celah putaran16 BENAR-BENAR bekerja.

Menguji migrasi `supabase/migrations/0015_penutup_celah_putaran16.sql` (temuan K-1: penanda
pembatalan `resto.pembatalan_pesanan` bisa dipalsukan kasir). Gerbang yang tidak bisa MERAH
dianggap belum terpasang — itu pelajaran mahal proyek ini.

Cara kerjanya: salin repo ke folder sementara, RUSAK satu penjaga (atau kembalikan versi lama
dari migrasi 0014 yang bocor), lalu jalankan berkas uji regresinya
(`supabase/tes/pembatalan_penanda_palsu.sql`). Kalau uji tetap hijau, pagar itu tumpul → alat ini GAGAL.

Kontrol yang wajib lulus lebih dulu:
  (1) salinan TANPA mutasi → uji hijau;
  (2) setelah semua mutasi dipulihkan (salinan dibuat ulang tiap mutasi) → hijau lagi.

Jalankan:  python3 alat/uji-mutasi-0015.py
"""
from __future__ import annotations

import pathlib
import re
import shutil
import subprocess
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent
KERJA = pathlib.Path("/tmp/mutasi-0015-rb")
MIG = "supabase/migrations/0015_penutup_celah_putaran16.sql"
MIG14 = "supabase/migrations/0014_penutup_celah_putaran13.sql"
UJI = "supabase/tes/pembatalan_penanda_palsu.sql"


def segarkan_salinan() -> None:
    """Salinan kerja: seluruh berkas repo (kecuali folder besar) + pustaka uji lewat tautan."""
    if KERJA.exists():
        shutil.rmtree(KERJA)
    KERJA.mkdir(parents=True)
    p1 = subprocess.Popen(
        ["tar", "--exclude=.git", "--exclude=dist", "--exclude=build", "--exclude=coverage",
         "--exclude=__pycache__", "--exclude=.vite", "--exclude=node_modules", "-cf", "-", "."],
        cwd=AKAR, stdout=subprocess.PIPE,
    )
    p2 = subprocess.Popen(["tar", "-xf", "-"], cwd=KERJA, stdin=p1.stdout)
    p1.stdout.close()
    p2.wait()
    p1.wait()
    for paket in ("alat/node_modules", "aplikasi/node_modules"):
        asal = AKAR / paket
        tujuan = KERJA / paket
        if asal.exists() and not tujuan.exists():
            tujuan.parent.mkdir(parents=True, exist_ok=True)
            tujuan.symlink_to(asal)
    if not (KERJA / "alat/node_modules/@electric-sql/pglite").exists():
        print("GAGAL: salinan uji tidak punya pustaka uji (pglite). Jalankan dulu: npm ci --prefix alat")
        sys.exit(2)


def jalankan_uji() -> tuple[int, str]:
    hasil = subprocess.run(
        ["node", "alat/uji-sql.mjs", UJI], cwd=KERJA, capture_output=True, text=True, timeout=600
    )
    return hasil.returncode, hasil.stdout + hasil.stderr


def mutasi(nama: str, ubah, harap_merah: bool = True) -> tuple[str, bool, str]:
    berkas = KERJA / MIG
    asli = berkas.read_text(encoding="utf-8")
    try:
        baru = ubah(asli)
        if baru == asli:
            return nama, False, "mutasi tidak mengubah apa pun (pola tidak ditemukan)"
        berkas.write_text(baru, encoding="utf-8")
        kode, keluar = jalankan_uji()
        lulus = (kode != 0) if harap_merah else (kode == 0)
        catatan = "MERAH (benar)" if kode != 0 else "HIJAU"
        if not lulus:
            catatan += " — pagar TUMPUL\n" + keluar[-600:]
        return nama, lulus, catatan
    finally:
        berkas.write_text(asli, encoding="utf-8")


def main() -> int:
    segarkan_salinan()

    kode, keluar = jalankan_uji()
    if kode != 0:
        print("KONTROL GAGAL: salinan utuh pun tidak hijau — perbaiki dulu berkas ujinya.\n" + keluar[-1500:])
        return 1
    print("  OK  kontrol: salinan utuh → uji hijau")

    hasil: list[tuple[str, bool, str]] = []

    def blok_penolakan(teks: str) -> str:
        m = re.search(r"  -- 3\) Pembatalan item.*?\n  end if;\n", teks, re.S)
        if not m:
            raise AssertionError("blok penolakan pembatalan tidak ditemukan")
        return m.group(0)

    # 1) Pagar penolakan DIHAPUS seluruhnya → uji wajib MERAH.
    def hapus_pagar(t: str) -> str:
        return t.replace(blok_penolakan(t), "")

    hasil.append(mutasi("pagar penolakan pembatalan item dihapus", hapus_pagar))

    # 2) Pagar dikembalikan ke bentuk LAMA yang bocor (percaya `current_setting`) → wajib MERAH.
    def kembalikan_bocor(t: str) -> str:
        lama = """  if tg_op = 'UPDATE'
     and (new.status = 'batal' or new.qty < old.qty) then
    if v_pesanan.dikirim_ke_dapur_pada is not null
       or coalesce(v_pesanan.status, '') in ('dimasak', 'siap', 'lunas') then
      v_jejak := coalesce(current_setting('resto.pembatalan_pesanan', true), '');
      if v_jejak is distinct from v_pesanan.id::text then
        raise exception 'Pembatalan item setelah dapur mulai wajib lewat baris pembatalan resmi (alasan + persetujuan PIN atasan).';
      end if;
    end if;
  end if;
"""
        return t.replace(blok_penolakan(t), lama).replace(
            "  v_peran   text;\nbegin", "  v_peran   text;\n  v_jejak   text;\nbegin", 1
        )

    hasil.append(mutasi("pagar dikembalikan ke versi lama yang mempercayai penanda (K-1)", kembalikan_bocor))

    # 3) Pemicu item dilepas → tidak ada penjaga sama sekali → wajib MERAH.
    def lepas_pemicu(t: str) -> str:
        # Pemicu 0014 masih terpasang dari migrasi sebelumnya, jadi "menghapus baris di 0015"
        # saja TIDAK cukup melepas penjaganya — mutasi ini harus benar-benar MELEPAS pemicunya
        # (drop tanpa create ulang), persis seperti keadaan "penjaga dicabut dari tabel".
        return t.replace(
            "drop trigger if exists item_jaga on public.pesanan_item;\n"
            "create trigger item_jaga\n  before insert or update on public.pesanan_item\n"
            "  for each row execute function public.picu_item_jaga();\n",
            "drop trigger if exists item_jaga on public.pesanan_item;\n",
            1,
        )

    hasil.append(mutasi("pemicu penjaga item dilepas dari tabel", lepas_pemicu))

    # 4) Pengecualian diam-diam untuk kasir → wajib MERAH (serangan diuji dari kursi kasir).
    def kecualikan_kasir(t: str) -> str:
        return t.replace(
            "  if tg_op = 'UPDATE'\n     and (new.status = 'batal' or new.qty < old.qty) then",
            "  if tg_op = 'UPDATE'\n     and (new.status = 'batal' or new.qty < old.qty)\n     and v_peran <> 'kasir' then",
            1,
        )

    hasil.append(mutasi("pagar diberi pengecualian diam-diam untuk peran kasir", kecualikan_kasir))

    # 5) Pemicu resmi menulis ULANG penanda yang bisa dipalsukan (kembalinya jebakan lama) → RED.
    def tulis_ulang_penanda(t: str) -> str:
        return t.replace(
            "begin\n  -- CATATAN K-1 (2026-09-19): baris `perform set_config('resto.pembatalan_pesanan', …)`",
            "begin\n  perform set_config('resto.pembatalan_pesanan', new.pesanan_id::text, true);\n"
            "  -- CATATAN K-1 (2026-09-19): baris `perform set_config('resto.pembatalan_pesanan', …)`",
            1,
        )

    # Catatan jujur: mutasi ini SENDIRI tidak cukup memerahkan uji (penanda tidak lagi dibaca);
    # yang diuji adalah bahwa mengembalikan penanda WAJIB disertai kembalinya pagar lama — kalau
    # tidak, uji tetap hijau = tidak ada yang terluka. Karena itu harapannya: HIJAU.
    hasil.append(mutasi("pemicu resmi menulis ulang penanda lama (tanpa pagar lama)", tulis_ulang_penanda, harap_merah=False))

    # 6) Versi 0014 (yang bocor) dipakai ulang untuk fungsi penjaganya → wajib MERAH.
    def pakai_versi_0014(t: str) -> str:
        lama14 = (KERJA / MIG14).read_text(encoding="utf-8")
        m = re.search(r"create or replace function public\.picu_item_jaga\(\).*?\n\$\$;\n", lama14, re.S)
        if not m:
            raise AssertionError("fungsi picu_item_jaga versi 0014 tidak ditemukan")
        m15 = re.search(r"create or replace function public\.picu_item_jaga\(\).*?\n\$\$;\n", t, re.S)
        if not m15:
            raise AssertionError("fungsi picu_item_jaga versi 0015 tidak ditemukan")
        return t[: m15.start()] + m.group(0) + t[m15.end():]

    hasil.append(mutasi("fungsi penjaga dikembalikan ke versi 0014 (yang bocor)", pakai_versi_0014))

    # Kontrol penutup: setelah semua mutasi dipulihkan, uji wajib hijau lagi.
    kode_akhir, keluar_akhir = jalankan_uji()
    hasil.append(("kontrol penutup: salinan dipulihkan → uji hijau", kode_akhir == 0, "HIJAU" if kode_akhir == 0 else "MERAH"))

    print("\nUJI MUTASI — penutup celah putaran16 (0015, temuan K-1)")
    merah = 0
    for nama, lulus, catatan in hasil:
        if not lulus:
            merah += 1
        print(f"  {'OK  ' if lulus else 'X   '}{nama}: {catatan}")
    if merah:
        print(f"\nHASIL: GAGAL — {merah} mutasi tidak sesuai harapan (pagar mungkin tumpul).")
        return 1
    print("\nHASIL: LOLOS — semua mutasi WAJIB MERAH benar-benar merah; pagar K-1 terbukti bekerja.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
