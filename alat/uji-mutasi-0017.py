#!/usr/bin/env python3
"""uji-mutasi-0017.py — bukti pagar "pesanan tertutup beku" BENAR-BENAR bekerja.

Menguji migrasi `supabase/migrations/0017_pesanan_tertutup_beku.sql` (temuan AUD-3 H F-07):
pesanan yang sudah `lunas`/`batal` beku total bagi UPDATE dari perangkat; jalur peladen
(pemicu & RPC SECURITY DEFINER) tetap bebas. Uji utamanya:
`supabase/tes/pesanan_tertutup_beku.sql`.

Mutasi yang WAJIB MERAH (semuanya harus gagal karena ASERSI, bukan karena salinan rusak):
  1. seluruh penjaga dihapus            → jejak pesanan lunas/batal bisa dikarang lagi
  2. pembekuan hanya mencakup `lunas`   → pesanan batal bisa ditulis ulang perangkat
  3. beku menyempit ke kolom `status`   → catatan/tipe/shift pesanan lunas bisa dikarang

Penilaian merah memakai `alat/klasifikasi_mutasi.py` (pelajaran audit I F-04):
hanya merah yang berasal dari asersi berkas uji yang dihitung bukti; salinan
rusak = BUKAN BUKTI dan membuat harness GAGAL.

Jalankan:  python3 alat/uji-mutasi-0017.py            (±1 menit)
           python3 alat/uji-mutasi-0017.py --uji-diri
"""
from __future__ import annotations

import pathlib
import shutil
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from klasifikasi_mutasi import HIJAU, MERAH_PAGAR, RUSAK, klasifikasi  # noqa: E402

AKAR = pathlib.Path(__file__).resolve().parent.parent
KERJA = pathlib.Path("/tmp/mutasi-0017-rb")
MIG = "supabase/migrations/0017_pesanan_tertutup_beku.sql"
UJI_UTAMA = "supabase/tes/pesanan_tertutup_beku.sql"
# Kontrol ikut menjalankan alur uang/pembatalan yang memakai jalur peladen pada
# pesanan tertutup — kalau bypass peladen rusak, berkas-berkas ini yang merah dulu.
SEMUA_UJI = (
    UJI_UTAMA,
    "supabase/tes/pembayaran.sql",
    "supabase/tes/gerbang_uang.sql",
    "supabase/tes/diskon_sesudah_lunas.sql",
    "supabase/tes/lifecycle_pesanan.sql",
    "supabase/tes/pembatalan_sekali.sql",
    "supabase/tes/status_pesanan.sql",
    "supabase/tes/pesanan.sql",
)

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
    for uji in SEMUA_UJI:
        kode, keluar = jalankan_uji(uji)
        if kode != 0:
            return False, keluar[-1200:]
    return True, ""


def mutasi(nama: str, ubah, uji: str) -> tuple[str, bool, str]:
    berkas = KERJA / MIG
    asli = berkas.read_text(encoding="utf-8")
    try:
        baru = ubah(asli)
        if baru == asli:
            return nama, False, "mutasi tidak mengubah apa pun (pola tidak ditemukan)"
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


def main() -> int:
    segarkan_salinan()
    hijau, keluar = semua_hijau()
    if not hijau:
        print("KONTROL GAGAL: salinan utuh pun tidak hijau — perbaiki dulu berkas ujinya.\n" + keluar)
        return 1
    print("  OK  kontrol: salinan utuh → uji utama + alur uang/pembatalan hijau")

    # 1) Seluruh penjaga dihapus → jejak pesanan lunas/batal bisa dikarang perangkat lagi.
    def hapus_penjaga(t: str) -> str:
        lama = """  if old.status in ('lunas', 'batal') and new is distinct from old then
    raise exception
      'Pesanan sudah ditutup (status %) — barisnya beku bagi perangkat; koreksi lewat jalur resmi peladen.',
      old.status;
  end if;
"""
        return t.replace(lama, "", 1)
    hasil.append(mutasi("penjaga beku dihapus (H F-07 kembali terbuka)",
                        hapus_penjaga, UJI_UTAMA))

    # 2) Pembekuan hanya mencakup `lunas` → pesanan batal bisa ditulis ulang perangkat.
    def hanya_lunas(t: str) -> str:
        return t.replace("if old.status in ('lunas', 'batal') and new is distinct from old then",
                         "if old.status = 'lunas' and new is distinct from old then", 1)
    hasil.append(mutasi("pesanan batal tidak ikut beku (jejak batal bisa dikarang)",
                        hanya_lunas, UJI_UTAMA))

    # 3) Beku menyempit ke perubahan kolom `status` saja → catatan/tipe/shift bisa dikarang.
    def sempitkan_ke_status(t: str) -> str:
        return t.replace("if old.status in ('lunas', 'batal') and new is distinct from old then",
                         "if old.status in ('lunas', 'batal') and new.status is distinct from old.status then", 1)
    hasil.append(mutasi("beku menyempit ke kolom status saja (jejak non-status bisa dikarang)",
                        sempitkan_ke_status, UJI_UTAMA))

    hijau_akhir, keluar_akhir = semua_hijau()
    if not hijau_akhir:
        print("KONTROL PENUTUP GAGAL: salinan tidak dipulihkan dengan bersih.\n" + keluar_akhir)
        return 1
    print("  OK  kontrol penutup: salinan dipulihkan → semua uji hijau")

    for nama, lulus, catatan in hasil:
        print(f"  [{'OK' if lulus else 'X '}] {nama}\n        {catatan}")
    merah = sum(1 for _, lulus, _ in hasil if not lulus)
    if merah:
        print(f"\nHASIL: GAGAL — {merah} mutasi tidak sesuai harapan (pagar mungkin tumpul).")
        return 1
    print("\nHASIL: LOLOS — semua mutasi WAJIB MERAH benar-benar merah; pagar pesanan-tertutup-beku terbukti bekerja.")
    return 0


def uji_diri() -> int:
    import tempfile
    print("UJI DIRI — penilai mutasi 0017 (harus bisa MENOLAK salinan rusak & MENERIMA asersi pagar)")
    kasus = [
        ("lingkungan: pustaka uji tidak ditemukan", 1,
         "node:internal/modules/cjs/loader\nError: Cannot find module '@electric-sql/pglite'\n"
         "ERR_MODULE_NOT_FOUND\n", RUSAK),
        ("migrasi tidak bisa diterapkan", 1,
         "  GAGAL 0017_pesanan_tertutup_beku.sql\n        syntax error at or near \"end\"\n\n"
         "HASIL: GAGAL — migrasi tidak bisa diterapkan; uji dihentikan.\n", RUSAK),
        ("asersi pengaman benar-benar gagal (bukti pagar bekerja)", 1,
         "  GAGAL supabase/tes/pesanan_tertutup_beku.sql\n        HARAPAN TIDAK TERPENUHI: "
         "perintah tidak ditolak\n\n" + "-" * 70 + "\nuji: 5 LULUS · 1 GAGAL\nHASIL: GAGAL\n",
         MERAH_PAGAR),
        ("kontrol hijau", 0,
         "  LULUS supabase/tes/pesanan_tertutup_beku.sql\n\n" + "-" * 70 + "\nuji: 1 LULUS · 0 GAGAL\nHASIL: LOLOS\n", HIJAU),
    ]
    rusak = 0
    for nama, kode, keluaran, harap in kasus:
        jenis, sebab = klasifikasi(kode, keluaran)
        ok = jenis == harap
        rusak += 0 if ok else 1
        print(f"  [{'OK' if ok else 'X '}] {nama}: jenis={jenis} harap={harap} ({sebab[:70]})")

    asli_jalankan, asli_kerja = globals()["jalankan_uji"], globals()["KERJA"]
    try:
        with tempfile.TemporaryDirectory(prefix="uji-diri-mutasi-0017-") as tmp:
            salinan = pathlib.Path(tmp)
            (salinan / MIG).parent.mkdir(parents=True, exist_ok=True)
            (salinan / MIG).write_text("-- salinan uji\n", encoding="utf-8")
            globals()["KERJA"] = salinan
            globals()["jalankan_uji"] = lambda uji=None: (1, "Error: Cannot find module 'x'\n")
            _, lulus, catatan = mutasi("(uji) salinan rusak", lambda t: t + "\n-- mutasi\n", UJI_UTAMA)
            ok = (not lulus) and "BUKAN BUKTI" in catatan
            rusak += 0 if ok else 1
            print(f"  [{'OK' if ok else 'X '}] mutasi() menolak salinan rusak sebagai bukti: {catatan.strip()[:80]}")
            globals()["jalankan_uji"] = lambda uji=None: (
                1, "  GAGAL supabase/tes/x.sql\n        HARAPAN TIDAK TERPENUHI: pagar tidak bekerja\n"
                   + "-" * 70 + "\nuji: 1 LULUS · 1 GAGAL\nHASIL: GAGAL\n")
            _, lulus2, catatan2 = mutasi("(uji) asersi pagar", lambda t: t + "\n-- mutasi\n", UJI_UTAMA)
            ok2 = lulus2 and "pagar bekerja" in catatan2
            rusak += 0 if ok2 else 1
            print(f"  [{'OK' if ok else 'X '}] mutasi() menerima asersi pagar sebagai bukti: {catatan2.strip()[:80]}")
    finally:
        globals()["jalankan_uji"], globals()["KERJA"] = asli_jalankan, asli_kerja

    if rusak:
        print(f"\nHASIL: GAGAL — {rusak} kasus berperilaku salah (penilai mutasi belum bisa dipercaya)")
        return 1
    print("\nHASIL: LOLOS — penilai mutasi 0017 menolak salinan rusak, menerima asersi pagar.")
    return 0


if __name__ == "__main__":
    sys.exit(uji_diri() if "--uji-diri" in sys.argv else main())
