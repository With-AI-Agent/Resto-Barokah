#!/usr/bin/env python3
"""uji-mutasi-0016.py — bukti pagar penutup celah PIN putaran18 BENAR-BENAR bekerja.

Menguji migrasi `supabase/migrations/0016_penutup_celah_pin_putaran18.sql`:
  * bagian 1 — I F-15: pemanggil nonaktif (tenant NULL) melewati penjaga tenant
                 (uji: `supabase/tes/pin.sql` blok F-15)
  * bagian 2 — I F-16: "PIN benar tetapi tidak berizin" menjadi stempel diskon
                 (uji: `supabase/tes/diskon_setuju.sql` blok F-16)
  * bagian 3 — I F-14: raise jalur PIN-lama/hierarki menggulung balik catatan
                 percobaan sehingga pembatas tebakan tak pernah menyala
                 (uji: `supabase/tes/kredensial_pin.sql` blok F-14,
                       `supabase/tes/pin_hierarki.sql`)
  * bagian 4 — I F-13: oracle metadata peran lintas penyewa (pagar tenant sebagai
                 defence-in-depth di atas pinning F-11 yang DIPERTAHANKAN)
                 (uji: `supabase/tes/isolasi_lintas_penyewa.sql` blok F-13,
                       `supabase/tes/pin_helper_pribadi.sql`)

Penilaian merah memakai `alat/klasifikasi_mutasi.py` (pelajaran audit I F-04):
hanya merah yang berasal dari asersi berkas uji yang dihitung bukti; salinan
rusak = BUKAN BUKTI dan membuat harness GAGAL.

Jalankan:  python3 alat/uji-mutasi-0016.py            (±1-2 menit)
           python3 alat/uji-mutasi-0016.py --uji-diri
"""
from __future__ import annotations

import pathlib
import shutil
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from klasifikasi_mutasi import HIJAU, MERAH_PAGAR, RUSAK, klasifikasi  # noqa: E402

AKAR = pathlib.Path(__file__).resolve().parent.parent
KERJA = pathlib.Path("/tmp/mutasi-0016-rb")
MIG = "supabase/migrations/0016_penutup_celah_pin_putaran18.sql"
UJI_F15 = "supabase/tes/pin.sql"
UJI_F16 = "supabase/tes/diskon_setuju.sql"
UJI_F14 = "supabase/tes/kredensial_pin.sql"
UJI_HIER = "supabase/tes/pin_hierarki.sql"
UJI_F13 = "supabase/tes/isolasi_lintas_penyewa.sql"
UJI_F11 = "supabase/tes/pin_helper_pribadi.sql"
UJI_PR07 = "supabase/tes/kupon_wajib_pesanan.sql"
UJI_PR09 = "supabase/tes/pin_warisan.sql"
UJI_PR08 = "supabase/tes/saldo_awal_stok.sql"
UJI_PR14 = "supabase/tes/hak_fungsi.sql"
UJI_PR15 = "supabase/tes/meja_riwayat.sql"
SEMUA_UJI = (UJI_F15, UJI_F16, UJI_F14, UJI_HIER, UJI_F13, UJI_F11,
             UJI_PR07, UJI_PR09, UJI_PR08, UJI_PR14, UJI_PR15)

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
    print("  OK  kontrol: salinan utuh → SEMUA uji F-13…F-16 hijau")

    # 1) F-15: pagar pemanggil nonaktif dihapus → akun mati lolos verifikasi.
    def hapus_pagar_f15(t: str) -> str:
        lama = """  if public.penyewa_saya() is null then
    return query select false, 0, 'PIN tidak dikenali.';
    return;
  end if;
"""
        return t.replace(lama, "", 1)
    hasil.append(mutasi("pagar pemanggil nonaktif dihapus (I F-15 kembali terbuka)",
                        hapus_pagar_f15, UJI_F15))

    # 2) F-16: cek ulang izin saat konsumsi kupon dihapus → stempel tak berizin lolos.
    def hapus_recheck_f16(t: str) -> str:
        lama = """  if not public.boleh_untuk(new.disetujui_oleh, 'beri_diskon') then
    raise exception 'Penyetuju diskon tidak berizin untuk aksi beri_diskon.';
  end if;
"""
        return t.replace(lama, "", 1)
    hasil.append(mutasi("cek ulang izin konsumsi kupon diskon dihapus (I F-16 kembali terbuka)",
                        hapus_recheck_f16, UJI_F16))

    # 3) F-14: jalur PIN-lama-salah dibuat menerima (seolah tersimpan) →
    #    pembatas tebakan tidak berarti; uji pesan wajib MERAH.
    def terima_pin_lama_salah(t: str) -> str:
        lama = "      return format('PIN lama salah. %s', v_periksa.pesan);"
        return t.replace(lama, "      return 'PIN tersimpan.';", 1)
    hasil.append(mutasi("PIN lama salah malah diterima (catatan percobaan percuma, I F-14)",
                        terima_pin_lama_salah, UJI_F14))

    # 4) F-14 hierarki: penolakan hierarki dibuat menerima → rebutan PIN hidup lagi.
    def terima_hierarki(t: str) -> str:
        lama = "      return 'Peran Anda tidak lebih tinggi dari pegawai itu — PIN-nya hanya boleh diganti oleh atasan atau dirinya sendiri.';"
        return t.replace(lama, "      return 'PIN tersimpan.';", 1)
    hasil.append(mutasi("penolakan hierarki peran dibuat menerima (rebutan PIN hidup lagi)",
                        terima_hierarki, UJI_HIER))

    # 5) F-13: pagar tenant helper hierarki dihapus → oracle lintas penyewa.
    def hapus_pagar_f13(t: str) -> str:
        lama = """  if public.penyewa_saya() is not null
     and (not public.sepenyewa(p_pemanggil) or not public.sepenyewa(p_target)) then
    return false;
  end if;
"""
        return t.replace(lama, "", 1)
    hasil.append(mutasi("pagar tenant helper hierarki dihapus (oracle lintas penyewa, I F-13)",
                        hapus_pagar_f13, UJI_F13))

    # 6) F-11 dipertahankan: pemakuan identitas dilepas → helper mengaku atas nama orang lain.
    def lepas_pinning_f11(t: str) -> str:
        lama = """  if auth.uid() is not null and p_pemanggil is distinct from auth.uid() then
    return false;
  end if;
"""
        return t.replace(lama, "", 1)
    hasil.append(mutasi("pemakuan identitas pemanggil dilepas (F-11 mundur lewat 0016)",
                        lepas_pinning_f11, UJI_F11))

    hijau_akhir, keluar_akhir = semua_hijau()
    # 7) PR-07: pagar "aksi berkupon wajib menyebut pesanan" dihapus → kupon
    #    tanpa ikatan pesanan lahir lagi ("tulis bisa, pakai mustahil").
    def hapus_pagar_kupon_pesanan(t: str) -> str:
        lama = """  if p_aksi in ('void_sesudah_dapur', 'beri_diskon') and p_pesanan_id is null then
    insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, pemanggil_id, pesanan_id)
    values (v_saya, v_perangkat, false, p_aksi, v_saya, null);
    return query select false, 0,
      format('Aksi %s wajib menyebut pesanan yang disetujui.', p_aksi);
    return;
  end if;
"""
        return t.replace(lama, "", 1)
    hasil.append(mutasi("kupon tanpa pesanan dibiarkan lahir lagi (PR-07 kembali terbuka)",
                        hapus_pagar_kupon_pesanan, UJI_PR07))

    # 8) PR-09: cabang PIN warisan 4 angka dimatikan → naik kelas swadaya buntu lagi.
    def matikan_jalur_warisan(t: str) -> str:
        return t.replace("    if p_pin_lama ~ '^\\d{4}$' then", "    if false then", 1)
    hasil.append(mutasi("jalur naik kelas PIN warisan 4 angka dimatikan (PR-09 kembali terbuka)",
                        matikan_jalur_warisan, UJI_PR09))

    # 9) PR-08: penjaga saldo awal dilepas → saldo bisa muncul dari ketiadaan lagi.
    def lepas_penjaga_saldo_awal(t: str) -> str:
        lama = """  if coalesce(new.jumlah, 0) <> 0 then
    raise exception 'Saldo awal tidak boleh ditulis langsung — buat bahan dengan saldo 0 lalu catat saldonya lewat pergerakan stok (jenis opname/masuk) supaya buku besarnya lengkap.';
  end if;
"""
        return t.replace(lama, "", 1)
    hasil.append(mutasi("saldo awal stok tanpa buku besar dibiarkan lagi (PR-08 kembali terbuka)",
                        lepas_penjaga_saldo_awal, UJI_PR08))

    # 10) PR-14: koreksi hak fungsi dibatalkan → service_role mati lagi & anon
    #     bisa membaca peta hierarki lagi.
    def batalkan_koreksi_hak(t: str) -> str:
        lama = """grant execute on function public.hitung_total(uuid) to service_role;

revoke all on function public.peringkat_peran(text) from public;
grant execute on function public.peringkat_peran(text) to authenticated, service_role;
"""
        return t.replace(lama, "", 1)
    hasil.append(mutasi("koreksi hak fungsi dibatalkan (PR-14 kembali terbuka)",
                        batalkan_koreksi_hak, UJI_PR14))

    # 11) PR-15: penjaga riwayat meja dikembalikan ke versi 0014 (hanya pesanan
    #     aktif yang dilindungi) → meja ber-riwayat lunas bisa dihapus lagi.
    def kembalikan_penjaga_meja_0014(t: str) -> str:
        lama = """    select count(*) into v_pesanan
      from public.pesanan p
     where p.meja_id = old.id;"""
        return t.replace(lama, """    select count(*) into v_pesanan
      from public.pesanan p
     where p.meja_id = old.id and p.status not in ('lunas', 'batal');""", 1)
    hasil.append(mutasi("penjaga riwayat meja dikembalikan ke versi 0014 (PR-15 kembali terbuka)",
                        kembalikan_penjaga_meja_0014, UJI_PR15))

    hasil.append(("kontrol penutup: salinan dipulihkan → semua uji hijau", hijau_akhir,
                  "HIJAU" if hijau_akhir else "MERAH\n" + keluar_akhir))

    print("\nUJI MUTASI — penutup celah PIN putaran18 (0016: I F-13…F-16)")
    merah = 0
    for nama, lulus, catatan in hasil:
        if not lulus:
            merah += 1
        print(f"  {'OK  ' if lulus else 'X   '}{nama}: {catatan}")
    if merah:
        print(f"\nHASIL: GAGAL — {merah} mutasi tidak sesuai harapan (pagar mungkin tumpul).")
        return 1
    print("\nHASIL: LOLOS — semua mutasi WAJIB MERAH benar-benar merah; pagar PIN putaran18 terbukti bekerja.")
    return 0


def uji_diri() -> int:
    import tempfile
    print("UJI DIRI — penilai mutasi 0016 (harus bisa MENOLAK salinan rusak & MENERIMA asersi pagar)")
    kasus = [
        ("lingkungan: pustaka uji tidak ditemukan", 1,
         "node:internal/modules/cjs/loader\nError: Cannot find module '@electric-sql/pglite'\n"
         "ERR_MODULE_NOT_FOUND\n", RUSAK),
        ("migrasi tidak bisa diterapkan", 1,
         "  GAGAL 0016_penutup_celah_pin_putaran18.sql\n        syntax error at or near \"end\"\n\n"
         "HASIL: GAGAL — migrasi tidak bisa diterapkan; uji dihentikan.\n", RUSAK),
        ("asersi pengaman benar-benar gagal (bukti pagar bekerja)", 1,
         "  GAGAL supabase/tes/pin.sql\n        HARAPAN TIDAK TERPENUHI: F-15: pemanggil nonaktif "
         "tidak bisa verifikasi PIN siapa pun\n\n" + "-" * 70 + "\nuji: 10 LULUS · 1 GAGAL\nHASIL: GAGAL\n",
         MERAH_PAGAR),
        ("kontrol hijau", 0,
         "  LULUS supabase/tes/pin.sql\n\n" + "-" * 70 + "\nuji: 11 LULUS · 0 GAGAL\nHASIL: LOLOS\n", HIJAU),
    ]
    rusak = 0
    for nama, kode, keluaran, harap in kasus:
        jenis, sebab = klasifikasi(kode, keluaran)
        ok = jenis == harap
        rusak += 0 if ok else 1
        print(f"  [{'OK' if ok else 'X '}] {nama}: jenis={jenis} harap={harap} ({sebab[:70]})")

    asli_jalankan, asli_kerja = globals()["jalankan_uji"], globals()["KERJA"]
    try:
        with tempfile.TemporaryDirectory(prefix="uji-diri-mutasi-0016-") as tmp:
            salinan = pathlib.Path(tmp)
            (salinan / MIG).parent.mkdir(parents=True, exist_ok=True)
            (salinan / MIG).write_text("-- salinan uji\n", encoding="utf-8")
            globals()["KERJA"] = salinan
            globals()["jalankan_uji"] = lambda uji=None: (1, "Error: Cannot find module 'x'\n")
            _, lulus, catatan = mutasi("(uji) salinan rusak", lambda t: t + "\n-- mutasi\n", UJI_F15)
            ok = (not lulus) and "BUKAN BUKTI" in catatan
            rusak += 0 if ok else 1
            print(f"  [{'OK' if ok else 'X '}] mutasi() menolak salinan rusak sebagai bukti: {catatan.strip()[:80]}")
            globals()["jalankan_uji"] = lambda uji=None: (
                1, "  GAGAL supabase/tes/x.sql\n        HARAPAN TIDAK TERPENUHI: pagar tidak bekerja\n"
                   + "-" * 70 + "\nuji: 1 LULUS · 1 GAGAL\nHASIL: GAGAL\n")
            _, lulus2, catatan2 = mutasi("(uji) asersi pagar", lambda t: t + "\n-- mutasi\n", UJI_F15)
            ok2 = lulus2 and "pagar bekerja" in catatan2
            rusak += 0 if ok2 else 1
            print(f"  [{'OK' if ok2 else 'X '}] mutasi() menerima asersi pagar sebagai bukti: {catatan2.strip()[:80]}")
    finally:
        globals()["jalankan_uji"], globals()["KERJA"] = asli_jalankan, asli_kerja

    if rusak:
        print(f"\nHASIL: GAGAL — {rusak} kasus berperilaku salah (penilai mutasi belum bisa dipercaya)")
        return 1
    print("\nHASIL: LOLOS — penilai mutasi 0016 menolak salinan rusak, menerima asersi pagar.")
    return 0


if __name__ == "__main__":
    sys.exit(uji_diri() if "--uji-diri" in sys.argv else main())
