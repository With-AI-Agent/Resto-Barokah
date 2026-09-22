#!/usr/bin/env python3
"""uji-mutasi-0009.py — bukti sapuan isolasi resto (B F-14) BENAR-BENAR bisa MERAH.

Pagar yang dibuktikan: filter penyewa+cabang di `public.pesanan_sepenyewa` (migrasi
`supabase/migrations/0009_pesanan.sql`) + aturan SETIAP-policy di
`supabase/tes/rls_semua_tabel.sql` (blok 3, 4, 6). Detektor kedua mutasi = berkas uji itu.
Catatan: 0009 BEKU di pohon nyata — harness hanya mengubah SALINAN sementara.

Mutasi yang WAJIB MERAH (semuanya harus gagal karena ASERSI, bukan salinan rusak):
  A. saringan cabang dibuang dari pesanan_sepenyewa → blok 6 (rantai jangkar) GAGAL.
     (Bukti yang dituntut temuan B F-14 apa adanya.)
  B. policy longgar `using (true)` tanpa jangkar ditambahkan ke pesanan → blok 3 GAGAL.
     (Bukti aturan SETIAP-policy, bukan "ada satu" — satu policy longgar menggugurkan
     semua policy ketat karena policy PERMISSIVE digabung OR.)
  D1. tabel baru TANPA RLS ditambahkan → blok 1 GAGAL.
      (Bukti pagar RLS-wajib — separuh Verifikasi T1-22.)
  D2. tabel baru ber-RLS tapi TANPA policy ditambahkan → blok 2 GAGAL.
      (Bukti pagar policy-wajib — separuh Verifikasi T1-22: "menambah tabel tanpa
      policy → CI merah".)

Catatan arsitektur: kasus B, D1, D2 memakai salinan 0009 hanya sebagai KENDARAAN
mutasi (append di ekor) — yang dibuktikan adalah kepekaan sapuan RLS itu sendiri,
bukan pagar internal 0009. Satu harness untuk keempatnya agar buktinya utuh.

Penilaian merah memakai `alat/klasifikasi_mutasi.py` (pelajaran audit I F-04):
hanya merah ber-token asersi (`HARAPAN TIDAK TERPENUHI`) yang dihitung bukti;
salinan rusak = BUKAN BUKTI dan membuat harness GAGAL.

Jalankan:  python3 alat/uji-mutasi-0009.py            (±1 menit)
           python3 alat/uji-mutasi-0009.py --uji-diri
"""
from __future__ import annotations

import pathlib
import shutil
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from klasifikasi_mutasi import HIJAU, MERAH_PAGAR, RUSAK, klasifikasi  # noqa: E402

AKAR = pathlib.Path(__file__).resolve().parent.parent
KERJA = pathlib.Path("/tmp/mutasi-0009-rb")
MIG = "supabase/migrations/0009_pesanan.sql"
DETEKTOR = "supabase/tes/rls_semua_tabel.sql"

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
    print("  OK  kontrol: salinan utuh → sapuan RLS hijau (tanpa positif-palsu)")

    # A) Saringan cabang dibuang dari pesanan_sepenyewa → blok 6 wajib GAGAL.
    #    (Bukti yang dituntut B F-14: "menghapus cabang_pantau_saya dari
    #    pesanan_sepenyewa → rls_semua_tabel.sql harus GAGAL".)
    def buang_saringan_cabang(t: str) -> str:
        lama = "\n       and public.cabang_pantau_saya(p.cabang_id)\n"
        return t.replace(lama, "\n", 1)
    hasil.append(mutasi("saringan cabang dibuang dari pesanan_sepenyewa (blok 6 rantai jangkar)",
                        buang_saringan_cabang, DETEKTOR))

    # B) Policy longgar tanpa jangkar ditambahkan → blok 3 (SETIAP-policy) wajib GAGAL.
    def tambah_policy_longgar(t: str) -> str:
        return (t + "\n-- mutasi F-14/B: policy longgar tanpa jangkar\n"
                "create policy uji_f14_lax_pesanan on public.pesanan "
                "for select to authenticated using (true);\n")
    hasil.append(mutasi("policy longgar using(true) tanpa jangkar (blok 3 SETIAP-policy)",
                        tambah_policy_longgar, DETEKTOR))

    # D1) Tabel baru TANPA RLS → blok 1 wajib GAGAL (pagar RLS-wajib, T1-22).
    def tambah_tabel_tanpa_rls(t: str) -> str:
        return (t + "\n-- mutasi F-14/D1: tabel tanpa RLS\n"
                "create table public.uji_f14_d1_tanpa_rls (id uuid primary key default gen_random_uuid());\n")
    hasil.append(mutasi("tabel baru tanpa RLS (blok 1 pagar RLS-wajib)",
                        tambah_tabel_tanpa_rls, DETEKTOR))

    # D2) Tabel baru ber-RLS tapi TANPA policy → blok 2 wajib GAGAL.
    #     (Bukti harfiah Verifikasi T1-22: "menambah tabel tanpa policy → CI merah".)
    def tambah_tabel_tanpa_policy(t: str) -> str:
        return (t + "\n-- mutasi F-14/D2: tabel ber-RLS tanpa policy\n"
                "create table public.uji_f14_d2_tanpa_policy (id uuid primary key default gen_random_uuid());\n"
                "alter table public.uji_f14_d2_tanpa_policy enable row level security;\n")
    hasil.append(mutasi("tabel baru ber-RLS tanpa policy (blok 2 pagar policy-wajib)",
                        tambah_tabel_tanpa_policy, DETEKTOR))

    hijau_akhir, keluar_akhir = semua_hijau()
    if not hijau_akhir:
        print("KONTROL PENUTUP GAGAL: salinan tidak dipulihkan dengan bersih.\n" + keluar_akhir)
        return 1
    print("  OK  kontrol penutup: salinan dipulihkan → sapuan hijau lagi")

    for nama, lulus, catatan in hasil:
        print(f"  [{'OK' if lulus else 'X '}] {nama}\n        {catatan}")
    merah = sum(1 for _, lulus, _ in hasil if not lulus)
    if merah:
        print(f"\nHASIL: GAGAL — {merah} mutasi tidak sesuai harapan (pagar mungkin tumpul).")
        return 1
    print("\nHASIL: LOLOS — semua mutasi WAJIB MERAH benar-benar merah; sapuan isolasi resto terbukti peka.")
    return 0


def uji_diri() -> int:
    import tempfile
    print("UJI DIRI — penilai mutasi 0009 (harus bisa MENOLAK salinan rusak & MENERIMA asersi pagar)")
    kasus = [
        ("lingkungan: pustaka uji tidak ditemukan", 1,
         "node:internal/modules/cjs/loader\nError: Cannot find module '@electric-sql/pglite'\n"
         "ERR_MODULE_NOT_FOUND\n", RUSAK),
        ("migrasi tidak bisa diterapkan", 1,
         "  GAGAL 0009_pesanan.sql\n        syntax error at or near \"end\"\n\n"
         "HASIL: GAGAL — migrasi tidak bisa diterapkan; uji dihentikan.\n", RUSAK),
        ("asersi pengaman benar-benar gagal (bukti pagar bekerja)", 1,
         "  GAGAL supabase/tes/rls_semua_tabel.sql\n        HARAPAN TIDAK TERPENUHI: "
         "Fungsi public.pesanan_sepenyewa kehilangan sebutan\n\n" + "-" * 70 + "\nuji: 0 LULUS · 1 GAGAL\nHASIL: GAGAL\n",
         MERAH_PAGAR),
        ("kontrol hijau", 0,
         "  LULUS supabase/tes/rls_semua_tabel.sql\n\n" + "-" * 70 + "\nuji: 1 LULUS · 0 GAGAL\nHASIL: LOLOS\n", HIJAU),
    ]
    rusak = 0
    for nama, kode, keluaran, harap in kasus:
        jenis, sebab = klasifikasi(kode, keluaran)
        ok = jenis == harap
        rusak += 0 if ok else 1
        print(f"  [{'OK' if ok else 'X '}] {nama}: jenis={jenis} harap={harap} ({sebab[:70]})")

    asli_jalankan, asli_kerja = globals()["jalankan_uji"], globals()["KERJA"]
    try:
        with tempfile.TemporaryDirectory(prefix="uji-diri-mutasi-0009-") as tmp:
            salinan = pathlib.Path(tmp)
            (salinan / MIG).parent.mkdir(parents=True, exist_ok=True)
            (salinan / MIG).write_text("-- salinan uji\n", encoding="utf-8")
            globals()["KERJA"] = salinan
            globals()["jalankan_uji"] = lambda uji=None: (1, "Error: Cannot find module 'x'\n")
            _, lulus, catatan = mutasi("(uji) salinan rusak", lambda t: t + "\n-- mutasi\n", DETEKTOR)
            ok = (not lulus) and "BUKAN BUKTI" in catatan
            rusak += 0 if ok else 1
            print(f"  [{'OK' if ok else 'X '}] mutasi() menolak salinan rusak sebagai bukti: {catatan.strip()[:80]}")
            globals()["jalankan_uji"] = lambda uji=None: (
                1, "  GAGAL supabase/tes/x.sql\n        HARAPAN TIDAK TERPENUHI: pagar tidak bekerja\n"
                   + "-" * 70 + "\nuji: 1 LULUS · 1 GAGAL\nHASIL: GAGAL\n")
            _, lulus2, catatan2 = mutasi("(uji) asersi pagar", lambda t: t + "\n-- mutasi\n", DETEKTOR)
            ok2 = lulus2 and "pagar bekerja" in catatan2
            rusak += 0 if ok2 else 1
            print(f"  [{'OK' if ok2 else 'X '}] mutasi() menerima asersi pagar sebagai bukti: {catatan2.strip()[:80]}")
    finally:
        globals()["jalankan_uji"], globals()["KERJA"] = asli_jalankan, asli_kerja

    if rusak:
        print(f"\nHASIL: GAGAL — {rusak} kasus berperilaku salah (penilai mutasi belum bisa dipercaya)")
        return 1
    print("\nHASIL: LOLOS — penilai mutasi 0009 menolak salinan rusak, menerima asersi pagar.")
    return 0


if __name__ == "__main__":
    sys.exit(uji_diri() if "--uji-diri" in sys.argv else main())
