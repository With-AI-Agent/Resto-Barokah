#!/usr/bin/env python3
"""uji-mutasi-0014.py — bukti bahwa penutup celah putaran13/audit 2026-09-18 BEKERJA.

Mencakup migrasi `0014_penutup_celah_putaran13.sql` (temuan review PR putaran13 #1 & #2
dan audit AUD-3 2026-09-18) PLUS tiga penjaga lama yang terbukti bisa dihapus tanpa satu
pun uji merah (audit F-06/F-07: kunci idempoten pembayaran, CHECK alasan pembatalan,
CHECK jumlah > 0 pembayaran).

Cara kerjanya sama dengan `uji-mutasi-0012.py`: salin repo ke folder sementara, MATIKAN
satu penjaga, lalu jalankan uji yang seharusnya menangkapnya. Kalau uji tetap hijau,
pagar itu tumpul (dan alat ini GAGAL). Alat ini juga bukti bahwa asersi `harap_gagal_sebab`
yang baru benar-benar menuntut SEBAB penolakan yang tepat — bukan sekadar "ada yang gagal".

Jalankan:  python3 alat/uji-mutasi-0014.py
"""
import pathlib, subprocess, sys, shutil

AKAR = pathlib.Path(__file__).resolve().parent.parent
KERJA = pathlib.Path("/tmp/mutasi-0014-rb")


def segarkan_salinan() -> None:
    if KERJA.exists():
        shutil.rmtree(KERJA)
    KERJA.mkdir(parents=True)
    p1 = subprocess.Popen(["tar", "--exclude=.git", "--exclude=dist", "--exclude=build",
                           "--exclude=coverage", "--exclude=__pycache__", "--exclude=.vite",
                           "--exclude=node_modules", "-cf", "-", "."],
                          cwd=AKAR, stdout=subprocess.PIPE)
    p2 = subprocess.Popen(["tar", "-xf", "-"], cwd=KERJA, stdin=p1.stdout)
    p1.stdout.close()
    p2.wait(); p1.wait()
    for paket in ("alat/node_modules", "aplikasi/node_modules"):
        asal = AKAR / paket
        tujuan = KERJA / paket
        if asal.exists() and not tujuan.exists():
            tujuan.parent.mkdir(parents=True, exist_ok=True)
            tujuan.symlink_to(asal)
    if not (KERJA / "alat/node_modules/@electric-sql/pglite").exists():
        print("GAGAL: salinan uji tidak punya pustaka uji (pglite). Jalankan dulu: npm ci --prefix alat")
        sys.exit(2)


segarkan_salinan()

MIG14 = KERJA / "supabase/migrations/0014_penutup_celah_putaran13.sql"
MIG10 = KERJA / "supabase/migrations/0010_pembayaran.sql"
MIG12 = KERJA / "supabase/migrations/0012_penutup_celah_review.sql"


# PENTING: migrasi dibaca dari SALINAN KERJA, bukan repo asli. Kalau menunjuk
# AKAR, mutasinya dikenakan pada berkas repo sementara uji dijalankan di salinan →
# semua mutasi terbaca "hijau" padahal tidak pernah berefek (kesalahan nyata 2026-09-18).
FOLDER_MIGRASI = KERJA / "supabase" / "migrations"


def migrasi_terbaru_dulu() -> list[pathlib.Path]:
    """Semua migrasi, terbaru dulu (0014 → 0013 → … → 0001)."""
    return sorted(FOLDER_MIGRASI.glob("*.sql"), reverse=True)


def berkas_berlaku(cari: str) -> pathlib.Path | None:
    """Migrasi TERBARU yang memuat pola itu = berkas tempat definisi yang berlaku hidup.

    Kenapa harus "terbaru dulu": migrasi berikutnya boleh menulis ulang isi suatu
    pemicu fungsi (`create or replace`). Kalau pola dimutasi di berkas LAMA, definisi
    yang berlaku TIDAK berubah dan mutasinya jadi hijau palsu — persis kejadian nyata
    setelah 0014 menulis ulang `picu_item_jaga`/`picu_stok_arah_jujur` (M1/M5/M8
    sempat terbaca "pagar tumpul" padahal penjaganya masih ada di 0014).

    Pola boleh muncul LEBIH DARI SEKALI di berkas itu (berkas penutup menulis ulang fungsi
    yang sama, mis. `picu_item_jaga` di bagian 1 dan bagian 9 migrasi 0015) dan yang
    BERLAKU adalah kemunculan TERAKHIR → mutasinya memakai `ganti_terakhir()`.
    """
    for berkas in migrasi_terbaru_dulu():
        if cari in berkas.read_text(encoding="utf-8"):
            return berkas
    return None


def ganti_terakhir(isi: str, cari: str, ganti: str) -> tuple[str, int]:
    """Ganti kemunculan TERAKHIR `cari`; kembalikan (isi baru, jumlah kemunculan).

    Definisi yang berlaku = `create or replace` TERAKHIR di berkas itu. Mengganti
    kemunculan pertama membuat mutasinya tumpul (definisi terakhir menimpa kembali).
    """
    jumlah = isi.count(cari)
    if jumlah == 0:
        return isi, 0
    awal = isi.rindex(cari)
    return isi[:awal] + ganti + isi[awal + len(cari):], jumlah


def jalankan(uji):
    r = subprocess.run(["node", "alat/uji-sql.mjs", uji], cwd=KERJA, capture_output=True, text=True)
    return r.returncode, (r.stdout + r.stderr)


DAFTAR = [
    # --- penutup 0014 (putaran13 + audit 2026-09-18) ---
    ("M14-1 hitung_total tidak lagi dipanggil saat item berubah (alur uang buntu lagi)",
     "after insert or update or delete on public.pesanan_item",
     "after delete on public.pesanan_item",
     "supabase/tes/uang_peladen.sql"),
    ("M14-2 subtotal dari klien dipercaya lagi (dapur bisa memalsukan kerugian)",
     "  new.subtotal := new.harga_saat_itu * new.qty;",
     "  new.subtotal := coalesce(new.subtotal, new.harga_saat_itu * new.qty);",
     "supabase/tes/item_penjaga.sql"),
    ("M14-3 dapur boleh mengubah jumlah pesanan lagi",
     "  if tg_op = 'UPDATE' and v_peran = 'dapur' then",
     "  if false then",
     "supabase/tes/item_penjaga.sql"),
    ("M14-4 pembatalan tidak lagi menyetel status pesanan jadi batal",
     "     and p.status <> 'batal';",
     "     and false;",
     "supabase/tes/item_penjaga.sql"),
    ("M14-5 hierarki PIN dimatikan (bawahan bisa merebut PIN atasan lagi)",
     "    if not public.peran_lebih_tinggi(v_saya, v_target) then",
     "    if false then",
     "supabase/tes/pin_hierarki.sql"),
    ("M14-6 kasir_id tidak lagi dipaksa dari pengguna yang masuk",
     "    new.kasir_id := auth.uid();",
     "    new.kasir_id := coalesce(new.kasir_id, auth.uid());",
     "supabase/tes/jejak_pesanan.sql"),
    ("M14-7 tanggal pesanan mundur boleh lagi",
     "    if new.tanggal is not null and new.tanggal <> current_date then",
     "    if false then",
     "supabase/tes/jejak_pesanan.sql"),
    ("M14-8 metode bayar tidak lagi wajib (label boleh dikarang)",
     "  if new.metode_id is null then",
     "  if false then",
     "supabase/tes/pembayaran_metode.sql"),
    ("M14-9 arah stok pada INSERT langsung tidak dinormalkan lagi",
     "  if new.jenis = 'masuk' then\n    new.jumlah := abs(new.jumlah);",
     "  if false then\n    new.jumlah := abs(new.jumlah);",
     "supabase/tes/stok_insert_langsung.sql"),
    ("M14-10 kasir/pelayan boleh mengubah nama & aktif meja lagi",
     "  if v_peran not in ('owner_pusat', 'admin_cabang') then",
     "  if false then",
     "supabase/tes/meja_penjaga.sql"),
    ("M14-11 meja yang sedang dipakai boleh dihapus lagi",
     "    if v_pesanan > 0 then",
     "    if false then",
     "supabase/tes/meja_penjaga.sql"),
    # Pola lama ("  if v_kupon is null then") dipakai DUA penjaga berbeda (kupon diskon di 0014
    # dan kupon void di 0012/0013/0015) → sejak 0015 menulis ulang penjaga void, polanya
    # ambigu dan mutasinya bisa menyasar penjaga yang salah. Sekarang polanya khas penjaga
    # kupon DISKON (pesannya menyebut diskon).
    ("M14-12 stempel 'disetujui' pada diskon boleh dikarang lagi",
     "  if v_kupon is null then\n    raise exception 'Persetujuan diskon belum terbukti",
     "  if false then\n    raise exception 'Persetujuan diskon belum terbukti",
     "supabase/tes/diskon_setuju.sql"),
    ("M14-13 cap bawaan diskon kembali 100% (bukan batas)",
     "  alter column batas_maks_potongan_persen set default 50;",
     "  alter column batas_maks_potongan_persen set default 100;",
     "supabase/tes/diskon_cap_bawaan.sql"),
    ("M14-14 varian tanpa harga boleh direkam lagi",
     "    if not public.boleh('ubah_harga') then\n      raise exception 'Varian/tambahan belum bisa dihargai otomatis",
     "    if false then\n      raise exception 'Varian/tambahan belum bisa dihargai otomatis",
     "supabase/tes/varian_gagal_aman.sql"),
    # --- penjaga LAMA yang terbukti bisa dihapus tanpa uji merah (audit F-06/F-07) ---
    ("M14-15 kunci idempoten pembayaran dihapus (dobel pembayaran tidak terdeteksi)",
     "  unique (pesanan_id, kunci_idempoten)",
     "  check (true)  -- mutasi: kunci idempoten dibuang",
     "supabase/tes/pembayaran.sql"),
    ("M14-16 CHECK alasan pembatalan dihapus (void tanpa alasan lolos)",
     "  check (length(btrim(alasan)) > 0)",
     "  check (true)  -- mutasi: alasan wajib dibuang",
     "supabase/tes/pembayaran.sql"),
    ("M14-17 CHECK jumlah pembayaran > 0 dihapus (pembayaran nol/negatif lolos)",
     "  jumlah            integer not null check (jumlah > 0),",
     "  jumlah            integer not null check (true),  -- mutasi",
     "supabase/tes/pembayaran.sql"),
]

# Mutasi yang MEMANG tertahan lapisan lain (bukan pagar tumpul) — dilaporkan apa adanya,
# tidak dihitung ke dalam "mutasi wajib MERAH". Buktinya ada di mutasi GABUNGAN di bawah.
BERTUMPUK = {"M14-6"}

# Mutasi GABUNGAN: dua lapis penjaga yang saling menutupi. Satu lapis saja tidak
# mengubah perilaku akhir (nilai tetap benar), jadi keduanya dimatikan sekaligus —
# kalau nilai akhirnya tetap benar, berarti penjaganya memang berlapis.
GABUNGAN = [
    ("M14-6b kasir_id tidak dipaksa DAN larangan menyebut orang lain dimatikan",
     [("    if new.kasir_id is not null and new.kasir_id is distinct from auth.uid() then",
       "    if false then"),
      ("    new.kasir_id := auth.uid();",
       "    new.kasir_id := coalesce(new.kasir_id, auth.uid());")],
     "supabase/tes/jejak_pesanan.sql"),
]

berkas_uji = sorted({d[3] for d in DAFTAR})
print("KONTROL POSITIF (tanpa mutasi harus hijau)")
for uji in berkas_uji:
    kode, keluar = jalankan(uji)
    print(f"  {'OK  ' if kode == 0 else 'X   '}{uji.split('/')[-1]}: kode {kode}")
    if kode != 0:
        print("\n".join(keluar.splitlines()[-8:]))
        print("HARNESS BERHENTI: kontrol positif merah → penilaian mutasi tidak sah.")
        sys.exit(2)

hasil = []
dilewati: list = []
print("\nUJI MUTASI — penutup celah putaran13 & audit 2026-09-18 (0014 + penjaga lama)")
for nama, cari, ganti, uji in DAFTAR:
    berkas = berkas_berlaku(cari)
    if berkas is None:
        print(f"  LEWAT {nama}: pola tidak unik / tidak ditemukan")
        hasil.append(False)
        continue
    asli = berkas.read_text(encoding="utf-8")
    baru_isi, jumlah = ganti_terakhir(asli, cari, ganti)
    if jumlah == 0:
        print(f"  LEWAT {nama}: pola tidak ada di {berkas.name}")
        hasil.append(False)
        continue
    if jumlah > 1:
        print(f"  (catatan) pola muncul {jumlah}× di {berkas.name} — yang dimutasi kemunculan TERAKHIR")
    berkas.write_text(baru_isi, encoding="utf-8")
    kode, keluar = jalankan(uji)
    berkas.write_text(asli, encoding="utf-8")
    sakti = "ERR_MODULE_NOT_FOUND" in keluar or "SyntaxError" in keluar or "tidak bisa diterapkan" in keluar
    merah = kode != 0 and not sakti
    if sakti:
        print(f"  X   {nama}: salinan rusak (bukan bukti) — {keluar.splitlines()[-1] if keluar.splitlines() else ''}")
        hasil.append(False)
        continue
    if nama.startswith(tuple(BERTUMPUK)):
        print(f"  INFO {nama}: {'MERAH' if merah else 'HIJAU (sesuai dugaan: lapisan kedua masih menahan; buktinya di M14-6b)'}"
              f" ({uji.split('/')[-1]})")
        continue
    print(f"  {'OK  ' if merah else 'X   '}{nama}: {'MERAH' if merah else 'HIJAU (pagar tumpul!)'} ({uji.split('/')[-1]})")
    if not merah:
        print("      " + "\n      ".join(keluar.splitlines()[-6:]))
    hasil.append(merah)

print("\nUJI MUTASI GABUNGAN (lapisan penjaga yang saling menutupi)")
for nama, pasangan, uji in GABUNGAN:
    berkas = berkas_berlaku(pasangan[0][0]) or MIG14
    asli = berkas.read_text(encoding="utf-8")
    isi = asli
    ok = True
    for cari, ganti in pasangan:
        isi, jumlah = ganti_terakhir(isi, cari, ganti)
        if jumlah == 0:
            ok = False
            break
    if not ok:
        print(f"  LEWAT {nama}: pola tidak unik")
        hasil.append(False)
        continue
    berkas.write_text(isi, encoding="utf-8")
    kode, keluar = jalankan(uji)
    berkas.write_text(asli, encoding="utf-8")
    merah = kode != 0 and "ERR_MODULE_NOT_FOUND" not in keluar and "SyntaxError" not in keluar
    print(f"  {'OK  ' if merah else 'X   '}{nama}: {'MERAH' if merah else 'HIJAU (pagar tumpul!)'} ({uji.split('/')[-1]})")
    if not merah:
        print("      " + "\n      ".join(keluar.splitlines()[-6:]))
    hasil.append(merah)

print("\nPEMULIHAN (semua mutasi dipulihkan → seluruh berkas uji harus hijau lagi)")
for uji in berkas_uji:
    kode, _ = jalankan(uji)
    print(f"  {'OK  ' if kode == 0 else 'X   '}{uji.split('/')[-1]}: kode {kode}")
    if kode != 0:
        print("HARNESS BERHENTI: pemulihan gagal.")
        sys.exit(2)

print(f"\nRINGKASAN: {sum(hasil)}/{len(hasil)} mutasi WAJIB terbukti MERAH")
sys.exit(0 if all(hasil) else 1)
