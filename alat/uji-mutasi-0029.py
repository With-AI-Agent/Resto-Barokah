#!/usr/bin/env python3
"""uji-mutasi-0029.py — bukti pagar "audit kekal & rantai hash" (T1-13 & T1-27) BENAR-BENAR bekerja.

Menguji migrasi `supabase/migrations/0029_audit_kekal_rantai.sql` (T1-13, T1-27).
Uji utamanya: `supabase/tes/audit_rantai.sql` & `supabase/tes/catatan_audit.sql`.

Mutasi yang WAJIB MERAH:
  1. Trigger cegah_ubah_hapus_audit dilepas → UPDATE catatan_audit diizinkan
  2. Trigger hitung_hash dilepas → hash_sebelumnya / hash_baris tidak terisi
  3. Validasi hash_sebelumnya pada verifikasi_rantai_audit dilepas → rantai putus lolos

Jalankan:  python3 alat/uji-mutasi-0029.py
           python3 alat/uji-mutasi-0029.py --uji-diri
"""
from __future__ import annotations

import pathlib
import shutil
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from klasifikasi_mutasi import HIJAU, MERAH_PAGAR, RUSAK, klasifikasi  # noqa: E402

AKAR = pathlib.Path(__file__).resolve().parent.parent
KERJA = pathlib.Path("/tmp/mutasi-0029-rb")
MIG = "supabase/migrations/0029_audit_kekal_rantai.sql"
# Definisi `verifikasi_rantai_audit` yang berlaku sejak 0040 (lihat catatan di mutasi 3).
MIG_VERIFIKASI = "supabase/migrations/0040_urutan_rantai_audit.sql"
UJI_RANTAI = "supabase/tes/audit_rantai.sql"
SEMUA_UJI = (
    UJI_RANTAI,
    "supabase/tes/catatan_audit.sql",
    "supabase/tes/pemulihan.sql",
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


def mutasi(nama: str, ubah, uji: str, migrasi: str = MIG) -> tuple[str, bool, str]:
    berkas = KERJA / migrasi
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
    print("  OK  kontrol: salinan utuh → uji audit rantai + catatan audit hijau")

    # 1) Trigger cegah_ubah_hapus dilepas → UPDATE/DELETE diizinkan
    def lepas_trigger_cegah(t: str) -> str:
        lama = """drop trigger if exists catatan_audit_cegah_ubah_hapus on public.catatan_audit;
create trigger catatan_audit_cegah_ubah_hapus
  before update or delete on public.catatan_audit
  for each row execute function public.cegah_ubah_hapus_audit();"""
        return t.replace(lama, "-- mutasi: trigger cegah ubah hapus dihapus\n", 1)
    hasil.append(mutasi("trigger penolakan UPDATE/DELETE dilepas (T1-13)",
                        lepas_trigger_cegah, UJI_RANTAI))

    # 2) Trigger hitung_hash dilepas → hash tidak terisi
    def lepas_trigger_hash(t: str) -> str:
        lama = """drop trigger if exists catatan_audit_hitung_hash on public.catatan_audit;
create trigger catatan_audit_hitung_hash
  before insert on public.catatan_audit
  for each row execute function public.hitung_hash_catatan_audit();"""
        return t.replace(lama, "-- mutasi: trigger hitung hash dihapus\n", 1)
    hasil.append(mutasi("trigger hitung rantai hash dilepas (T1-27)",
                        lepas_trigger_hash, UJI_RANTAI))

    # 3) Validasi hash_sebelumnya dilepas pada verifikasi_rantai_audit
    def lepas_validasi_rantai(t: str) -> str:
        lama = """    if r.hash_sebelumnya <> v_prev_hash then
      return query select false, v_hitung, r.id,
        format('Tautan rantai terputus pada baris ke-%s (ID: %s). Hash sebelumnya tidak cocok.', v_hitung, r.id);
      return;
    end if;"""
        return t.replace(lama, "-- mutasi: validasi tautan hash dilepas\n", 1)
    # Sejak migrasi 0040 fungsi `verifikasi_rantai_audit` DIDEFINISIKAN ULANG (urutannya
    # pindah ke kolom `urutan`). Mutasi harus mengenai definisi yang BERLAKU — kalau
    # tetap menyunting 0029, 0040 menimpanya dan mutasi jadi tidak berpengaruh (CI
    # membuktikan ini: langkah 0029 HIJAU padahal pagar sengaja ditumpulkan).
    hasil.append(mutasi("validasi tautan hash dilepas pada verifikasi_rantai_audit",
                        lepas_validasi_rantai, UJI_RANTAI, migrasi=MIG_VERIFIKASI))

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
    print("\nHASIL: LOLOS — semua mutasi WAJIB MERAH benar-benar merah; pagar audit kekal & rantai hash terbukti bekerja.")
    return 0


def uji_diri() -> int:
    import tempfile
    print("UJI DIRI — penilai mutasi 0029 (harus bisa MENOLAK salinan rusak & MENERIMA asersi pagar)")
    kasus = [
        ("lingkungan: pustaka uji tidak ditemukan", 1,
         "node:internal/modules/cjs/loader\nError: Cannot find module '@electric-sql/pglite'\n"
         "ERR_MODULE_NOT_FOUND\n", RUSAK),
        ("migrasi tidak bisa diterapkan", 1,
         "  GAGAL 0029_audit_kekal_rantai.sql\n        syntax error at or near \"end\"\n\n"
         "HASIL: GAGAL — migrasi tidak bisa diterapkan; uji dihentikan.\n", RUSAK),
        ("asersi pengaman benar-benar gagal (bukti pagar bekerja)", 1,
         "  GAGAL supabase/tes/audit_rantai.sql\n        HARAPAN TIDAK TERPENUHI: "
         "perintah tidak ditolak\n\n" + "-" * 70 + "\nuji: 2 LULUS · 1 GAGAL\nHASIL: GAGAL\n",
         MERAH_PAGAR),
        ("kontrol hijau", 0,
         "  LULUS supabase/tes/audit_rantai.sql\n\n" + "-" * 70 + "\nuji: 1 LULUS · 0 GAGAL\nHASIL: LOLOS\n", HIJAU),
    ]
    rusak = 0
    for nama, kode, keluaran, harap in kasus:
        jenis, sebab = klasifikasi(kode, keluaran)
        ok = jenis == harap
        rusak += 0 if ok else 1
        print(f"  [{'OK' if ok else 'X '}] {nama}: jenis={jenis} harap={harap} ({sebab[:70]})")

    asli_jalankan, asli_kerja = globals()["jalankan_uji"], globals()["KERJA"]
    try:
        with tempfile.TemporaryDirectory(prefix="uji-diri-mutasi-0029-") as tmp:
            salinan = pathlib.Path(tmp)
            (salinan / MIG).parent.mkdir(parents=True, exist_ok=True)
            (salinan / MIG).write_text("-- salinan uji\n", encoding="utf-8")
            globals()["KERJA"] = salinan
            globals()["jalankan_uji"] = lambda uji=None: (1, "Error: Cannot find module 'x'\n")
            _, lulus, catatan = mutasi("(uji) salinan rusak", lambda t: t + "\n-- mutasi\n", UJI_RANTAI)
            ok = (not lulus) and "BUKAN BUKTI" in catatan
            rusak += 0 if ok else 1
            print(f"  [{'OK' if ok else 'X '}] mutasi() menolak salinan rusak sebagai bukti: {catatan.strip()[:80]}")
            globals()["jalankan_uji"] = lambda uji=None: (
                1, "  GAGAL supabase/tes/x.sql\n        HARAPAN TIDAK TERPENUHI: pagar tidak bekerja\n"
                   + "-" * 70 + "\nuji: 1 LULUS · 1 GAGAL\nHASIL: GAGAL\n")
            _, lulus2, catatan2 = mutasi("(uji) asersi pagar", lambda t: t + "\n-- mutasi\n", UJI_RANTAI)
            ok2 = lulus2 and "pagar bekerja" in catatan2
            rusak += 0 if ok2 else 1
            print(f"  [{'OK' if ok else 'X '}] mutasi() menerima asersi pagar sebagai bukti: {catatan2.strip()[:80]}")
    finally:
        globals()["jalankan_uji"], globals()["KERJA"] = asli_jalankan, asli_kerja

    if rusak:
        print(f"\nHASIL: GAGAL — {rusak} kasus berperilaku salah (penilai mutasi belum bisa dipercaya)")
        return 1
    print("\nHASIL: LOLOS — penilai mutasi 0029 menolak salinan rusak, menerima asersi pagar.")
    return 0


if __name__ == "__main__":
    sys.exit(uji_diri() if "--uji-diri" in sys.argv else main())
