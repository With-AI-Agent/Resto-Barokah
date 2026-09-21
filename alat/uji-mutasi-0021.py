#!/usr/bin/env python3
"""uji-mutasi-0021.py — bukti kunci serialisasi jalur uang (F F-12) BENAR-BENAR dijaga.

Pagar yang dibuktikan: dua `for update` pada baris pesanan — di `hitung_total`
(`supabase/migrations/0015_penutup_celah_putaran16.sql` §6, BEKU di pohon nyata)
dan di `picu_diskon_awal_pesanan` (`supabase/migrations/0021_kunci_diskon.sql`,
pemicu BEFORE pertama). Detektor kedua mutasi = `supabase/tes/uang_kunci.sql`
(pemeriksaan sifat via katalog + asap perilaku). Harness hanya mengubah SALINAN
sementara (pola dua-berkas mengikuti `alat/uji-mutasi-0012.py`).

Mutasi yang WAJIB MERAH (keduanya harus gagal karena ASERSI, bukan salinan rusak):
  A. kunci `hitung_total` (§6) dilepas → sifat-1 GAGAL.
     (Bukti kunci hitung-ulang adalah penahan beban, bukan hiasan.)
  B. kunci `picu_diskon_awal_pesanan` (0021) dilepas → sifat-2 GAGAL.
     (Bukti kunci jalur cap adalah penahan beban — keputusan cap dibuat sesudah
     kunci, bukan sebelumnya.)

Penilaian merah memakai `alat/klasifikasi_mutasi.py` (pelajaran audit I F-04):
hanya merah ber-token asersi (`HARAPAN TIDAK TERPENUHI`) yang dihitung bukti;
salinan rusak = BUKAN BUKTI dan membuat harness GAGAL.

Jalankan:  python3 alat/uji-mutasi-0021.py            (±1 menit)
           python3 alat/uji-mutasi-0021.py --uji-diri
"""
from __future__ import annotations

import pathlib
import shutil
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from klasifikasi_mutasi import HIJAU, MERAH_PAGAR, RUSAK, klasifikasi  # noqa: E402

AKAR = pathlib.Path(__file__).resolve().parent.parent
KERJA = pathlib.Path("/tmp/mutasi-0021-rb")
MIG15 = "supabase/migrations/0015_penutup_celah_putaran16.sql"
MIG21 = "supabase/migrations/0021_kunci_diskon.sql"
DETEKTOR = "supabase/tes/uang_kunci.sql"

hasil: list[tuple[str, bool, str]] = []


def segarkan_salinan() -> None:
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


def jalankan_uji(uji: str) -> tuple[int, str]:
    r = subprocess.run(["node", "alat/uji-sql.mjs", uji], cwd=KERJA,
                       capture_output=True, text=True, timeout=600)
    return r.returncode, r.stdout + r.stderr


def semua_hijau() -> tuple[bool, str]:
    kode, keluar = jalankan_uji(DETEKTOR)
    if kode != 0:
        return False, keluar[-1200:]
    return True, ""


def mutasi(nama: str, berkas_rel: str, ubah, uji: str) -> tuple[str, bool, str]:
    berkas = KERJA / berkas_rel
    asli = berkas.read_text(encoding="utf-8")
    try:
        baru = ubah(asli)
        if baru == asli:
            return nama, False, "mutasi tidak mengubah apa pun (pola tidak ditemukan/tidak unik)"
        berkas.write_text(baru, encoding="utf-8")
        kode, keluar = jalankan_uji(uji)
        jenis, sebab = klasifikasi(kode, keluar)
        lulus = jenis == MERAH_PAGAR
        catatan = {
            MERAH_PAGAR: f"MERAH (pagar bekerja) — {sebab}",
            HIJAU: "HIJAU — pagar TUMPUL",
        }.get(jenis, f"BUKAN BUKTI — {sebab}")
        if not lulus:
            catatan += "\n      " + "\n      ".join(keluar.strip().splitlines()[-6:])
        return nama, lulus, catatan
    finally:
        berkas.write_text(asli, encoding="utf-8")


def lepas_kunci(blok_utuh: str, blok_tanpa_kunci: str):
    def ubah(t: str) -> str:
        if t.count(blok_utuh) != 1:
            return t
        return t.replace(blok_utuh, blok_tanpa_kunci, 1)
    return ubah


def main() -> int:
    segarkan_salinan()
    hijau, keluar = semua_hijau()
    if not hijau:
        print("KONTROL GAGAL: salinan utuh pun tidak hijau — perbaiki dulu berkas ujinya.\n" + keluar)
        return 1
    print("  OK  kontrol: salinan utuh → uji kunci serialisasi hijau (tanpa positif-palsu)")

    # A) Kunci hitung_total (§6, 0015) dilepas → sifat-1 wajib GAGAL.
    hasil.append(mutasi("kunci hitung_total dilepas (sifat-1)", MIG15,
                        lepas_kunci("   where p.id = p_pesanan_id\n     for update;",
                                    "   where p.id = p_pesanan_id;"),
                        DETEKTOR))

    # B) Kunci picu_diskon_awal_pesanan (0021) dilepas → sifat-2 wajib GAGAL.
    hasil.append(mutasi("kunci picu_diskon_awal_pesanan dilepas (sifat-2)", MIG21,
                        lepas_kunci("  select p.status into v_status\n"
                                    "    from public.pesanan p where p.id = v_pesanan_id\n"
                                    "     for update;",
                                    "  select p.status into v_status\n"
                                    "    from public.pesanan p where p.id = v_pesanan_id;"),
                        DETEKTOR))

    hijau_akhir, keluar_akhir = semua_hijau()
    if not hijau_akhir:
        print("KONTROL PENUTUP GAGAL: salinan tidak dipulihkan dengan bersih.\n" + keluar_akhir)
        return 1
    print("  OK  kontrol penutup: salinan dipulihkan → uji hijau lagi")

    for nama, lulus, catatan in hasil:
        print(f"  [{'OK' if lulus else 'X '}] {nama}\n        {catatan}")
    merah = sum(1 for _, lulus, _ in hasil if not lulus)
    if merah:
        print(f"\nHASIL: GAGAL — {merah} mutasi tidak sesuai harapan (pagar mungkin tumpul).")
        return 1
    print("\nHASIL: LOLOS — semua mutasi WAJIB MERAH benar-benar merah; kunci serialisasi jalur uang terbukti dijaga.")
    return 0


def uji_diri() -> int:
    import tempfile
    print("UJI DIRI — penilai mutasi 0021 (harus bisa MENOLAK salinan rusak & MENERIMA asersi pagar)")
    kasus = [
        ("lingkungan: pustaka uji tidak ditemukan", 1,
         "node:internal/modules/cjs/loader\nError: Cannot find module '@electric-sql/pglite'\n"
         "ERR_MODULE_NOT_FOUND\n", RUSAK),
        ("migrasi tidak bisa diterapkan", 1,
         "  GAGAL 0021_kunci_diskon.sql\n        syntax error at or near \"end\"\n\n"
         "HASIL: GAGAL — migrasi tidak bisa diterapkan; uji dihentikan.\n", RUSAK),
        ("asersi pengaman benar-benar gagal (bukti pagar bekerja)", 1,
         "  GAGAL supabase/tes/uang_kunci.sql\n        HARAPAN TIDAK TERPENUHI: "
         "F-12: hitung_total mengambil kunci baris pesanan\n\n" + "-" * 70 + "\nuji: 0 LULUS · 1 GAGAL\nHASIL: GAGAL\n",
         MERAH_PAGAR),
        ("kontrol hijau", 0,
         "  LULUS supabase/tes/uang_kunci.sql\n\n" + "-" * 70 + "\nuji: 1 LULUS · 0 GAGAL\nHASIL: LOLOS\n", HIJAU),
    ]
    rusak = 0
    for nama, kode, keluaran, harap in kasus:
        jenis, sebab = klasifikasi(kode, keluaran)
        ok = jenis == harap
        rusak += 0 if ok else 1
        print(f"  [{'OK' if ok else 'X '}] {nama}: jenis={jenis} harap={harap} ({sebab[:70]})")

    asli_jalankan, asli_kerja = globals()["jalankan_uji"], globals()["KERJA"]
    try:
        with tempfile.TemporaryDirectory(prefix="uji-diri-mutasi-0021-") as tmp:
            salinan = pathlib.Path(tmp)
            (salinan / MIG21).parent.mkdir(parents=True, exist_ok=True)
            (salinan / MIG21).write_text("-- salinan uji\n", encoding="utf-8")
            globals()["KERJA"] = salinan
            globals()["jalankan_uji"] = lambda uji=None: (1, "Error: Cannot find module 'x'\n")
            _, lulus, catatan = mutasi("(uji) salinan rusak", MIG21, lambda t: t + "\n-- mutasi\n", DETEKTOR)
            ok = (not lulus) and "BUKAN BUKTI" in catatan
            rusak += 0 if ok else 1
            print(f"  [{'OK' if ok else 'X '}] mutasi() menolak salinan rusak sebagai bukti: {catatan.strip()[:80]}")
            globals()["jalankan_uji"] = lambda uji=None: (
                1, "  GAGAL supabase/tes/x.sql\n        HARAPAN TIDAK TERPENUHI: pagar tidak bekerja\n"
                   + "-" * 70 + "\nuji: 1 LULUS · 1 GAGAL\nHASIL: GAGAL\n")
            _, lulus2, catatan2 = mutasi("(uji) asersi pagar", MIG21, lambda t: t + "\n-- mutasi\n", DETEKTOR)
            ok2 = lulus2 and "pagar bekerja" in catatan2
            rusak += 0 if ok2 else 1
            print(f"  [{'OK' if ok2 else 'X '}] mutasi() menerima asersi pagar sebagai bukti: {catatan2.strip()[:80]}")
    finally:
        globals()["jalankan_uji"], globals()["KERJA"] = asli_jalankan, asli_kerja

    if rusak:
        print(f"\nHASIL: GAGAL — {rusak} kasus berperilaku salah (penilai mutasi belum bisa dipercaya)")
        return 1
    print("\nHASIL: LOLOS — penilai mutasi 0021 menolak salinan rusak, menerima asersi pagar.")
    return 0


if __name__ == "__main__":
    sys.exit(uji_diri() if "--uji-diri" in sys.argv else main())
