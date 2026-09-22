#!/usr/bin/env python3
"""uji-mutasi-0028.py — bukti pagar "pemulihan perangkat darurat" (T1-36) BENAR-BENAR bekerja.

Menguji migrasi `supabase/migrations/0028_pemulihan_perangkat.sql` (T1-36; ART-11, KEAMANAN §4b).
Uji utamanya: `supabase/tes/pemulihan.sql`.

Mutasi yang WAJIB MERAH (semuanya harus gagal karena ASERSI, bukan karena salinan rusak):
  1. Pemeriksaan peran owner_pusat pada buat_kode_pemulihan dihapus → non-owner bisa buat kode
  2. Pemeriksaan masa tenggang 30 menit pada selesaikan_pemulihan dilepas → aktif sebelum 30 menit
  3. Pemeriksaan kode pemulihan cocok dilepas → kode salah diterima
  4. Pemeriksaan kode belum terpakai dilepas → kode bisa dipakai berulang kali

Jalankan:  python3 alat/uji-mutasi-0028.py            (±1 menit)
           python3 alat/uji-mutasi-0028.py --uji-diri
"""
from __future__ import annotations

import pathlib
import shutil
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from klasifikasi_mutasi import HIJAU, MERAH_PAGAR, RUSAK, klasifikasi  # noqa: E402

AKAR = pathlib.Path(__file__).resolve().parent.parent
KERJA = pathlib.Path("/tmp/mutasi-0028-rb")
MIG = "supabase/migrations/0028_pemulihan_perangkat.sql"
UJI_PEMULIHAN = "supabase/tes/pemulihan.sql"
SEMUA_UJI = (
    UJI_PEMULIHAN,
    "supabase/tes/perangkat_registrasi.sql",
    "supabase/tes/percobaan_pin_perangkat.sql",
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
    print("  OK  kontrol: salinan utuh → uji pemulihan + perangkat hijau")

    # 1) Pemeriksaan peran owner_pusat pada buat_kode_pemulihan dihapus
    def hapus_peran_owner_buat(t: str) -> str:
        lama = """  if v_penyewa is null or v_peran <> 'owner_pusat' then
    raise exception 'Hanya owner_pusat yang berhak membuat atau memperbarui kode pemulihan darurat.';
  end if;"""
        return t.replace(lama, "-- mutasi: izin owner dihapus\n", 1)
    hasil.append(mutasi("peran owner pada buat_kode_pemulihan dihapus (non-owner diizinkan)",
                        hapus_peran_owner_buat, UJI_PEMULIHAN))

    # 2) Pemeriksaan masa tenggang 30 menit pada selesaikan_pemulihan dilepas
    def lepas_masa_tenggang(t: str) -> str:
        lama = """  if now() < v_aktif_setelah then
    raise exception 'Masa tenggang 30 menit belum berakhir. Perangkat darurat baru dapat diaktifkan setelah %.', v_aktif_setelah;
  end if;"""
        return t.replace(lama, "-- mutasi: masa tenggang dilepas\n", 1)
    hasil.append(mutasi("masa tenggang 30 menit dilepas (aktif sebelum waktunya)",
                        lepas_masa_tenggang, UJI_PEMULIHAN))

    # 3) Pemeriksaan kecocokan kode dilepas
    def lepas_cek_kode(t: str) -> str:
        lama = """  if not v_cocok then
    -- Catat kegagalan audit
    insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas, nilai_baru)
    values (
      v_penyewa,
      v_saya,
      'gagal_pulihkan_perangkat',
      'pemulihan_perangkat',
      jsonb_build_object('alasan', 'Kode pemulihan salah atau telah terpakai')
    );
    raise exception 'Kode pemulihan darurat tidak valid atau sudah pernah dipakai.';
  end if;"""
        return t.replace(lama, "-- mutasi: kode salah diterima\n", 1)
    hasil.append(mutasi("verifikasi kode pemulihan dilepas (kode salah diterima)",
                        lepas_cek_kode, UJI_PEMULIHAN))

    # 4) Pemeriksaan kode belum terpakai dilepas
    def lepas_kode_terpakai(t: str) -> str:
        lama = """     where penyewa_id = v_penyewa
       and not terpakai"""
        baru = """     where penyewa_id = v_penyewa"""
        return t.replace(lama, baru, 1)
    hasil.append(mutasi("pengecekan kode belum terpakai dilepas (kode dipakai ulang)",
                        lepas_kode_terpakai, UJI_PEMULIHAN))

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
    print("\nHASIL: LOLOS — semua mutasi WAJIB MERAH benar-benar merah; pagar pemulihan perangkat terbukti bekerja.")
    return 0


def uji_diri() -> int:
    import tempfile
    print("UJI DIRI — penilai mutasi 0028 (harus bisa MENOLAK salinan rusak & MENERIMA asersi pagar)")
    kasus = [
        ("lingkungan: pustaka uji tidak ditemukan", 1,
         "node:internal/modules/cjs/loader\nError: Cannot find module '@electric-sql/pglite'\n"
         "ERR_MODULE_NOT_FOUND\n", RUSAK),
        ("migrasi tidak bisa diterapkan", 1,
         "  GAGAL 0028_pemulihan_perangkat.sql\n        syntax error at or near \"end\"\n\n"
         "HASIL: GAGAL — migrasi tidak bisa diterapkan; uji dihentikan.\n", RUSAK),
        ("asersi pengaman benar-benar gagal (bukti pagar bekerja)", 1,
         "  GAGAL supabase/tes/pemulihan.sql\n        HARAPAN TIDAK TERPENUHI: "
         "perintah tidak ditolak\n\n" + "-" * 70 + "\nuji: 2 LULUS · 1 GAGAL\nHASIL: GAGAL\n",
         MERAH_PAGAR),
        ("kontrol hijau", 0,
         "  LULUS supabase/tes/pemulihan.sql\n\n" + "-" * 70 + "\nuji: 1 LULUS · 0 GAGAL\nHASIL: LOLOS\n", HIJAU),
    ]
    rusak = 0
    for nama, kode, keluaran, harap in kasus:
        jenis, sebab = klasifikasi(kode, keluaran)
        ok = jenis == harap
        rusak += 0 if ok else 1
        print(f"  [{'OK' if ok else 'X '}] {nama}: jenis={jenis} harap={harap} ({sebab[:70]})")

    asli_jalankan, asli_kerja = globals()["jalankan_uji"], globals()["KERJA"]
    try:
        with tempfile.TemporaryDirectory(prefix="uji-diri-mutasi-0028-") as tmp:
            salinan = pathlib.Path(tmp)
            (salinan / MIG).parent.mkdir(parents=True, exist_ok=True)
            (salinan / MIG).write_text("-- salinan uji\n", encoding="utf-8")
            globals()["KERJA"] = salinan
            globals()["jalankan_uji"] = lambda uji=None: (1, "Error: Cannot find module 'x'\n")
            _, lulus, catatan = mutasi("(uji) salinan rusak", lambda t: t + "\n-- mutasi\n", UJI_PEMULIHAN)
            ok = (not lulus) and "BUKAN BUKTI" in catatan
            rusak += 0 if ok else 1
            print(f"  [{'OK' if ok else 'X '}] mutasi() menolak salinan rusak sebagai bukti: {catatan.strip()[:80]}")
            globals()["jalankan_uji"] = lambda uji=None: (
                1, "  GAGAL supabase/tes/x.sql\n        HARAPAN TIDAK TERPENUHI: pagar tidak bekerja\n"
                   + "-" * 70 + "\nuji: 1 LULUS · 1 GAGAL\nHASIL: GAGAL\n")
            _, lulus2, catatan2 = mutasi("(uji) asersi pagar", lambda t: t + "\n-- mutasi\n", UJI_PEMULIHAN)
            ok2 = lulus2 and "pagar bekerja" in catatan2
            rusak += 0 if ok2 else 1
            print(f"  [{'OK' if ok else 'X '}] mutasi() menerima asersi pagar sebagai bukti: {catatan2.strip()[:80]}")
    finally:
        globals()["jalankan_uji"], globals()["KERJA"] = asli_jalankan, asli_kerja

    if rusak:
        print(f"\nHASIL: GAGAL — {rusak} kasus berperilaku salah (penilai mutasi belum bisa dipercaya)")
        return 1
    print("\nHASIL: LOLOS — penilai mutasi 0028 menolak salinan rusak, menerima asersi pagar.")
    return 0


if __name__ == "__main__":
    sys.exit(uji_diri() if "--uji-diri" in sys.argv else main())
