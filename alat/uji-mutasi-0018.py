#!/usr/bin/env python3
"""uji-mutasi-0018.py — bukti pagar "pesanan tertutup beku" BENAR-BENAR bekerja.

Menguji migrasi `supabase/migrations/0018_perangkat_terdaftar.sql` (T1-24; menutup
K F-03 + catatan F-11): verifikasi PIN wajib perangkat terdaftar (id + kunci),
lapis 12x/15 menit di-key pada perangkat_id. Uji utamanya:
`supabase/tes/percobaan_pin_perangkat.sql` & `supabase/tes/perangkat_registrasi.sql`.

Mutasi yang WAJIB MERAH (semuanya harus gagal karena ASERSI, bukan karena salinan rusak):
  1. verifikasi perangkat dihapus dari verifikasi_pin → perangkat karangan dilayani lagi
  2. pemeriksaan kunci di perangkat_sah dilepas       → kunci salah diterima
  3. pagar cabang di daftarkan_perangkat dihapus      → perangkat lintas resto terdaftar

Penilaian merah memakai `alat/klasifikasi_mutasi.py` (pelajaran audit I F-04):
hanya merah yang berasal dari asersi berkas uji yang dihitung bukti; salinan
rusak = BUKAN BUKTI dan membuat harness GAGAL.

Jalankan:  python3 alat/uji-mutasi-0018.py            (±1 menit)
           python3 alat/uji-mutasi-0018.py --uji-diri
"""
from __future__ import annotations

import pathlib
import shutil
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from klasifikasi_mutasi import HIJAU, MERAH_PAGAR, RUSAK, klasifikasi  # noqa: E402

AKAR = pathlib.Path(__file__).resolve().parent.parent
KERJA = pathlib.Path("/tmp/mutasi-0018-rb")
MIG = "supabase/migrations/0018_perangkat_terdaftar.sql"
UJI_ROTASI = "supabase/tes/percobaan_pin_perangkat.sql"
UJI_DAFTAR = "supabase/tes/perangkat_registrasi.sql"
# Kontrol ikut menjalankan alur uang/pembatalan yang memakai jalur peladen pada
# pesanan tertutup — kalau bypass peladen rusak, berkas-berkas ini yang merah dulu.
SEMUA_UJI = (
    UJI_ROTASI,
    UJI_DAFTAR,
    "supabase/tes/pin.sql",
    "supabase/tes/kredensial_pin.sql",
    "supabase/tes/pin_kunci_silang.sql",
    "supabase/tes/pin_hierarki.sql",
    "supabase/tes/kupon_wajib_pesanan.sql",
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

    # 1) Verifikasi perangkat dihapus dari verifikasi_pin → perangkat karangan dilayani lagi.
    def hapus_verifikasi_perangkat(t: str) -> str:
        lama = """  v_perangkat_id := public.perangkat_sah(p_perangkat_id, p_perangkat_kunci);
  if v_perangkat_id is null then
    insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, pemanggil_id, pesanan_id, perangkat_id)
    values (v_saya, 'tak-terdaftar', false, p_aksi, v_saya, p_pesanan_id, null);
    return query select false, 0, 'Perangkat tidak dikenali.';
    return;
  end if;
  select pr.nama into v_perangkat from public.perangkat pr where pr.id = v_perangkat_id;
"""
        baru = """  -- mutasi: perangkat tak terdaftar TIDAK ditolak, hanya dibiarkan null
  v_perangkat_id := (select pr.id from public.perangkat pr where pr.id = p_perangkat_id);
  v_perangkat := coalesce((select pr.nama from public.perangkat pr where pr.id = p_perangkat_id), 'tidak-diketahui');
"""
        return t.replace(lama, baru, 1)
    hasil.append(mutasi("verifikasi perangkat dihapus (K F-03 kembali terbuka)",
                        hapus_verifikasi_perangkat, UJI_ROTASI))

    # 2) Pemeriksaan kunci dilepas → kunci salah diterima (identitas bisa ditiru).
    def lepas_cek_kunci(t: str) -> str:
        return t.replace("and crypt(p_kunci, kp.kunci_hash) = kp.kunci_hash",
                         "and true", 1)
    hasil.append(mutasi("cek kunci perangkat dilepas (kunci salah diterima)",
                        lepas_cek_kunci, UJI_ROTASI))

    # 3) Pagar cabang di daftarkan_perangkat dihapus → perangkat lintas resto terdaftar.
    def hapus_pagar_cabang(t: str) -> str:
        lama = """  if p_cabang_id is null or not (p_cabang_id in (select public.cabang_ids_saya())) then
    raise exception 'Perangkat hanya bisa didaftarkan untuk cabang yang Anda kelola.';
  end if;
"""
        return t.replace(lama, "", 1)
    hasil.append(mutasi("pagar cabang pendaftaran dihapus (lintas resto terdaftar)",
                        hapus_pagar_cabang, UJI_DAFTAR))

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
    print("\nHASIL: LOLOS — semua mutasi WAJIB MERAH benar-benar merah; pagar perangkat-terdaftar terbukti bekerja.")
    return 0


def uji_diri() -> int:
    import tempfile
    print("UJI DIRI — penilai mutasi 0018 (harus bisa MENOLAK salinan rusak & MENERIMA asersi pagar)")
    kasus = [
        ("lingkungan: pustaka uji tidak ditemukan", 1,
         "node:internal/modules/cjs/loader\nError: Cannot find module '@electric-sql/pglite'\n"
         "ERR_MODULE_NOT_FOUND\n", RUSAK),
        ("migrasi tidak bisa diterapkan", 1,
         "  GAGAL 0018_perangkat_terdaftar.sql\n        syntax error at or near \"end\"\n\n"
         "HASIL: GAGAL — migrasi tidak bisa diterapkan; uji dihentikan.\n", RUSAK),
        ("asersi pengaman benar-benar gagal (bukti pagar bekerja)", 1,
         "  GAGAL supabase/tes/percobaan_pin_perangkat.sql\n        HARAPAN TIDAK TERPENUHI: "
         "perintah tidak ditolak\n\n" + "-" * 70 + "\nuji: 5 LULUS · 1 GAGAL\nHASIL: GAGAL\n",
         MERAH_PAGAR),
        ("kontrol hijau", 0,
         "  LULUS supabase/tes/percobaan_pin_perangkat.sql\n\n" + "-" * 70 + "\nuji: 1 LULUS · 0 GAGAL\nHASIL: LOLOS\n", HIJAU),
    ]
    rusak = 0
    for nama, kode, keluaran, harap in kasus:
        jenis, sebab = klasifikasi(kode, keluaran)
        ok = jenis == harap
        rusak += 0 if ok else 1
        print(f"  [{'OK' if ok else 'X '}] {nama}: jenis={jenis} harap={harap} ({sebab[:70]})")

    asli_jalankan, asli_kerja = globals()["jalankan_uji"], globals()["KERJA"]
    try:
        with tempfile.TemporaryDirectory(prefix="uji-diri-mutasi-0018-") as tmp:
            salinan = pathlib.Path(tmp)
            (salinan / MIG).parent.mkdir(parents=True, exist_ok=True)
            (salinan / MIG).write_text("-- salinan uji\n", encoding="utf-8")
            globals()["KERJA"] = salinan
            globals()["jalankan_uji"] = lambda uji=None: (1, "Error: Cannot find module 'x'\n")
            _, lulus, catatan = mutasi("(uji) salinan rusak", lambda t: t + "\n-- mutasi\n", UJI_ROTASI)
            ok = (not lulus) and "BUKAN BUKTI" in catatan
            rusak += 0 if ok else 1
            print(f"  [{'OK' if ok else 'X '}] mutasi() menolak salinan rusak sebagai bukti: {catatan.strip()[:80]}")
            globals()["jalankan_uji"] = lambda uji=None: (
                1, "  GAGAL supabase/tes/x.sql\n        HARAPAN TIDAK TERPENUHI: pagar tidak bekerja\n"
                   + "-" * 70 + "\nuji: 1 LULUS · 1 GAGAL\nHASIL: GAGAL\n")
            _, lulus2, catatan2 = mutasi("(uji) asersi pagar", lambda t: t + "\n-- mutasi\n", UJI_ROTASI)
            ok2 = lulus2 and "pagar bekerja" in catatan2
            rusak += 0 if ok2 else 1
            print(f"  [{'OK' if ok else 'X '}] mutasi() menerima asersi pagar sebagai bukti: {catatan2.strip()[:80]}")
    finally:
        globals()["jalankan_uji"], globals()["KERJA"] = asli_jalankan, asli_kerja

    if rusak:
        print(f"\nHASIL: GAGAL — {rusak} kasus berperilaku salah (penilai mutasi belum bisa dipercaya)")
        return 1
    print("\nHASIL: LOLOS — penilai mutasi 0018 menolak salinan rusak, menerima asersi pagar.")
    return 0


if __name__ == "__main__":
    sys.exit(uji_diri() if "--uji-diri" in sys.argv else main())
