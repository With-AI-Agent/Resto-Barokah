#!/usr/bin/env python3
"""uji-mutasi-0012.py — bukti bahwa pagar penutup celah review PR BENAR-BENAR bekerja.

Mencakup dua migrasi penutup celah:
  * `0012` — temuan review putaran8 (diskon, harga, PIN, stok, izin, jejak)
  * `0013` — temuan review putaran11 (voucher gagal-aman, status awal pesanan, nilai kerugian)


Cara kerjanya: salin repo ke folder sementara, MATIKAN satu penjaga di migrasi 0012,
lalu jalankan uji yang seharusnya menangkapnya. Kalau uji tetap hijau, pagar itu
tumpul (dan alat ini GAGAL). Prinsipnya dari pelajaran mahal: gerbang yang tidak bisa
MERAH dianggap belum terpasang.

Catatan kejujuran: beberapa penjaga sengaja BERTUMPUK (mis. "subtotal belum ada" dan
"diskon tidak boleh melebihi subtotal"). Mematikan satu saja tidak mengubah perilaku —
itu bukan pagar tumpul, melainkan pertahanan berlapis; untuk itu ada mutasi GABUNGAN
yang mematikan keduanya sekaligus.

Kontrol: (1) salinan tanpa mutasi WAJIB hijau lebih dulu; (2) setelah semua mutasi
dipulihkan, semua uji WAJIB hijau lagi. Kalau kontrol gagal, hasil mutasinya tidak sah.

Jalankan:  python3 alat/uji-mutasi-0012.py
"""
import pathlib, subprocess, sys, shutil

AKAR = pathlib.Path(__file__).resolve().parent.parent
KERJA = pathlib.Path("/tmp/mutasi-0012-rb")

def segarkan_salinan() -> None:
    """Salinan kerja: seluruh berkas repo (kecuali folder besar) + pustaka uji lewat tautan."""
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

MIG = KERJA / "supabase/migrations/0012_penutup_celah_review.sql"
MIG13 = KERJA / "supabase/migrations/0013_penutup_celah_putaran11.sql"


# PENTING: migrasi dibaca dari SALINAN KERJA, bukan repo asli. Kalau menunjuk
# AKAR, mutasinya dikenakan pada berkas repo sementara uji dijalankan di salinan →
# semua mutasi terbaca "hijau" padahal tidak pernah berefek (kesalahan nyata 2026-09-18).
FOLDER_MIGRASI = KERJA / "supabase" / "migrations"


def migrasi_terbaru_dulu() -> list[pathlib.Path]:
    """Semua migrasi, terbaru dulu (0014 → 0013 → … → 0001)."""
    return sorted(FOLDER_MIGRASI.glob("*.sql"), reverse=True)


def berkas_berlaku(cari: str) -> pathlib.Path | None:
    """Migrasi TERBARU yang memuat pola itu PERSIS SATU KALI = definisi yang berlaku.

    Kenapa harus "terbaru dulu": migrasi berikutnya boleh menulis ulang isi suatu
    pemicu fungsi (`create or replace`). Kalau pola dimutasi di berkas LAMA, definisi
    yang berlaku TIDAK berubah dan mutasinya jadi hijau palsu — persis kejadian nyata
    setelah 0014 menulis ulang `picu_item_jaga`/`picu_stok_arah_jujur` (M1/M5/M8
    sempat terbaca "pagar tumpul" padahal penjaganya masih ada di 0014).

    Pola yang muncul >1 kali di migrasi terbaru yang memuatnya = ambigu → None
    (mutasi DILEWATI dan dilaporkan, tidak pernah dicap hijau).
    """
    for berkas in migrasi_terbaru_dulu():
        jumlah = berkas.read_text(encoding="utf-8").count(cari)
        if jumlah == 1:
            return berkas
        if jumlah > 1:
            return None
    return None


def jalankan(uji):
    r = subprocess.run(["node", "alat/uji-sql.mjs", uji], cwd=KERJA, capture_output=True, text=True)
    return r.returncode, (r.stdout + r.stderr)

DAFTAR = [
    ("M1 diskon 'promo' dibuka lagi (tanpa cabang izin)",
     "raise exception 'Diskon promo otomatis belum aktif (menunggu T1-19/T1-20). Pakai diskon manual dengan persetujuan.';",
     "perform 1;", "supabase/tes/diskon_cap.sql"),
    ("M2 cap total resto tidak dibaca",
     "if v_cap_persen is not null and v_cap_persen < 100", "if false and v_cap_persen < 100",
     "supabase/tes/diskon_cap.sql"),
    ("M3a diskon boleh ditanam saat subtotal 0",
     "if coalesce(v_pesanan.subtotal, 0) <= 0 then", "if false then",
     "supabase/tes/diskon_cap.sql"),
    ("M3b diskon boleh melebihi subtotal (penjaga kedua ikut dimatikan)",
     "if v_total > v_pesanan.subtotal then", "if false then",
     "supabase/tes/diskon_cap.sql"),
    # Penjaga "harga jujur" yang diuji `harga_item.sql` ada di 0012 (`picu_item_harga_jujur`).
    # Pola serupa juga muncul di 0014 (syarat beku pasca-dapur) — karena itu berkasnya
    # DITULIS EKSPLISIT, bukan diserahkan ke pencarian "terbaru dulu" (kesalahan nyata
    # 2026-09-18: mutasinya mengenai berkas lain lalu terbaca hijau palsu).
    ("M4 harga item bebas diisi klien",
     "if not public.boleh('ubah_harga') then", "if false then",
     "supabase/tes/harga_item.sql", "0012_penutup_celah_review.sql"),
    # Penjaga subtotal yang BERLAKU sekarang ada di 0014 (0014 menulis ulang pemicu item).
    ("M5 subtotal dari klien dipercaya",
     "  new.subtotal := new.harga_saat_itu * new.qty;",
     "  new.subtotal := coalesce(new.subtotal, new.harga_saat_itu * new.qty);",
     "supabase/tes/harga_item.sql", "0014_penutup_celah_putaran13.sql"),
    ("M6 bukti PIN boleh dipakai berulang",
     "       and pp.dipakai_pada is null", "       and (pp.dipakai_pada is null or true)",
     "supabase/tes/persetujuan_void.sql"),
    ("M7 pelaku pengaturan boleh dikarang",
     "       and new.diubah_oleh is distinct from old.diubah_oleh then", "       and false then",
     "supabase/tes/jejak_pengaturan.sql"),
    # Sejak 0014, arah stok juga dinormalkan pemicu baris (`picu_stok_arah_jujur`) untuk
    # SEMUA jalur tulis, sehingga mengubah perhitungan di RPC 0012 saja tidak lagi mengubah
    # perilaku (pertahanan berlapis). Mutasinya karena itu menyasar pemicu 0014 — lapisan
    # yang benar-benar menahan hari ini.
    ("M8 keluar menambah stok lagi (pemicu baris 0014)",
     "    new.jumlah := -abs(new.jumlah);", "    new.jumlah := new.jumlah;",
     "supabase/tes/stok_arah.sql", "0014_penutup_celah_putaran13.sql"),
    ("M9 pemeriksaan keanggotaan cabang dimatikan (izin orang lain)",
     "  if p_cabang_id is not null and v_peran <> 'owner_pusat' then",
     "  if false then",
     "supabase/tes/izin_efektif_untuk.sql"),
    ("M9b keanggotaan cabang NONAKTIF tetap dianggap berizin",
     "         and pc.cabang_id = p_cabang_id\n         and pc.aktif",
     "         and pc.cabang_id = p_cabang_id",
     "supabase/tes/izin_efektif_untuk.sql"),
    ("M10 pembatas PIN kembali menghitung atas nama korban",
     "   where pp.pengguna_id = p_pengguna_id\n     and pp.pemanggil_id = v_saya\n     and not pp.berhasil",
     "   where pp.pengguna_id = p_pengguna_id\n     and not pp.berhasil",
     "supabase/tes/pin_kunci_silang.sql"),
    ("M11 akun nonaktif tetap dapat cabang",
     "and p.aktif   -- akun nonaktif kehilangan akses", "", "supabase/tes/cabang_sesi.sql"),
]

DAFTAR13 = [
    ("M12 diskon 'voucher' dibuka lagi (mesin voucher belum ada)",
     "raise exception 'Diskon voucher belum aktif (mesin voucher menunggu T1-12/T1-19/T1-20). Pakai diskon manual dengan persetujuan.';",
     "perform 1;",
     "supabase/tes/diskon_voucher.sql"),
    ("M13 pesanan boleh LAHIR berstatus lain (penjaga status awal dimatikan)",
     "if new.status is distinct from 'draf' then",
     "if false then",
     "supabase/tes/pesanan_status_awal.sql"),
    ("M13b penjaga status awal kembali `security definer` (current_user = pemilik → selalu dianggap peladen)",
     "language plpgsql\n-- SENGAJA BUKAN `security definer`",
     "language plpgsql\nsecurity definer\n-- SENGAJA BUKAN `security definer`",
     "supabase/tes/pesanan_status_awal.sql"),
    ("M14 nilai kerugian boleh dikarang klien lagi",
     """  if new.nilai_kerugian <> 0 and new.nilai_kerugian is distinct from coalesce(v_nilai, 0) then
    raise exception 'Nilai kerugian dihitung peladen dari salinan harga (%); angka kiriman (%) tidak boleh dikarang.',
      coalesce(v_nilai, 0), new.nilai_kerugian;
  end if;""",
     "  if false then\n    raise exception 'x';\n  end if;",
     "supabase/tes/nilai_kerugian.sql"),
]

# Mutasi tunggal yang hasilnya HIJAU memang diharapkan hijau (pertahanan berlapis) —
# dilaporkan apa adanya, tidak dihitung ke dalam "mutasi wajib MERAH".
BERTUMPUK = {"M3a", "M3b", "M5", "M8"}

berkas_uji = sorted({d[3] for d in DAFTAR})
print("KONTROL POSITIF (tanpa mutasi harus hijau)")
for uji in berkas_uji:
    kode, keluar = jalankan(uji)
    print(f"  {'OK  ' if kode == 0 else 'X   '}{uji.split('/')[-1]}: kode {kode}")
    if kode != 0:
        print("\n".join(keluar.splitlines()[-8:]))
        print("HARNESS BERHENTI: kontrol positif merah → penilaian mutasi tidak sah.")
        sys.exit(2)

# Mutasi GABUNGAN: dua penjaga yang saling menutupi (satu saja tidak mengubah perilaku,
# jadi keduanya dimatikan sekaligus — kalau perilakunya tetap benar, berarti penjaga
# ganda memang bekerja; kalau berubah, terbukti keduanya yang menahan).
GABUNGAN = [
    # M5k: subtotal dihitung di DUA tempat — pemicu item 0014 dan pemicu harga 0012.
    # Mematikan satu saja tidak mengubah perilaku, jadi keduanya dimatikan sekaligus.
    ("M5k subtotal dari klien dipercaya (pemicu 0014 DAN 0012 dimatikan)",
     [("0014_penutup_celah_putaran13.sql",
       "  new.subtotal := new.harga_saat_itu * new.qty;",
       "  new.subtotal := coalesce(new.subtotal, new.harga_saat_itu * new.qty);"),
      ("0012_penutup_celah_review.sql",
       "    new.subtotal := new.harga_saat_itu * new.qty;",
       "    new.subtotal := coalesce(new.subtotal, new.harga_saat_itu * new.qty);")],
     "supabase/tes/harga_item.sql"),
    # M8k: arah stok dinormalkan RPC 0012 dan (sejak 0014) juga pemicu baris 0014.
    ("M8k keluar menambah stok lagi (RPC 0012 DAN pemicu 0014 dimatikan)",
     [("0014_penutup_celah_putaran13.sql",
       "    new.jumlah := -abs(new.jumlah);",
       "    new.jumlah := new.jumlah;"),
      ("0012_penutup_celah_review.sql",
       "    v_jumlah := -abs(p_jumlah);",
       "    v_jumlah := p_jumlah;")],
     "supabase/tes/stok_arah.sql"),
    # Tiga penjaga sekarang menahan "diskon ditanam saat subtotal 0": (a) subtotal belum ada,
    # (b) total melebihi subtotal, dan (c) CAP BAWAAN baru 50% dari 0014 (cap 50% × subtotal 0
    # = 0, jadi potongan sekecil apa pun melewatinya). Ketiganya dimatikan sekaligus supaya
    # yang diuji benar-benar perilaku tanpa penjaga — bukan kebetulan tertahan cap.
    ("M3k diskon boleh ditanam pada subtotal 0 (tiga penjaga dimatikan sekaligus)",
     [("if coalesce(v_pesanan.subtotal, 0) <= 0 then", "if false then"),
      ("if v_total > v_pesanan.subtotal then", "if false then"),
      ("if v_cap_persen is not null and v_cap_persen < 100", "if false and v_cap_persen < 100")],
     "supabase/tes/diskon_cap.sql"),
]

hasil = []
dilewati: list = []


def jalankan_daftar(judul: str, mig: pathlib.Path, daftar: list) -> None:
    print(f"\n{judul}")
    for entri in daftar:
        nama, cari, ganti, uji = entri[:4]
        # Unsur ke-5 (kalau ada) = nama berkas eksplisit. Dipakai bila pola yang sama
        # ada di lebih dari satu migrasi dan yang BERLAKU bukan yang terbaru (mis. penjaga
        # "harga jujur" tetap di 0012 sementara pola serupa muncul di pemicu 0014).
        hint = entri[4] if len(entri) > 4 else None
        berkas = (KERJA / "supabase/migrations" / hint) if hint else berkas_berlaku(cari)
        if berkas is None:
            print(f"  LEWAT {nama}: pola tidak ada / tidak unik di migrasi mana pun — mutasi tidak bisa dijalankan")
            dilewati.append(nama)
            continue
        asli = berkas.read_text(encoding="utf-8")
        if asli.count(cari) != 1:
            print(f"  LEWAT {nama}: pola tidak unik di {berkas.name} ({asli.count(cari)})")
            hasil.append(False)
            continue
        berkas.write_text(asli.replace(cari, ganti), encoding="utf-8")
        kode, keluar = jalankan(uji)
        berkas.write_text(asli, encoding="utf-8")
        sakti = "ERR_MODULE_NOT_FOUND" in keluar or "SyntaxError" in keluar
        merah = kode != 0 and not sakti
        if sakti:
            print(f"  X   {nama}: salinan rusak (bukan bukti) — {keluar.splitlines()[-1] if keluar.splitlines() else ''}")
            hasil.append(False)
            continue
        if nama.startswith(tuple(BERTUMPUK)):
            print(f"  INFO {nama}: {'MERAH' if merah else 'HIJAU (sesuai dugaan: penjaga kembarnya masih menahan)'}"
                  f" ({uji.split('/')[-1]})")
            continue
        print(f"  {'OK  ' if merah else 'X   '}{nama}: {'MERAH' if merah else 'HIJAU (pagar tumpul)'} ({uji.split('/')[-1]})")
        if not merah:
            print("      " + "\n      ".join(keluar.splitlines()[-6:]))
        hasil.append(merah)


jalankan_daftar("UJI MUTASI — penutup celah review putaran8 (0012)", MIG, DAFTAR)
jalankan_daftar("UJI MUTASI — penutup celah review putaran11 (0013)", MIG13, DAFTAR13)

for nama, pasangan, uji in GABUNGAN:
    # Kalau unsur pertama sudah menyebut BERKAS (3 unsur), tidak perlu mencari berkas;
    # kalau hanya (cari, ganti), berkasnya dicari dari migrasi terbaru yang memuatnya.
    if len(pasangan[0]) == 3:
        berkas = KERJA / "supabase/migrations" / pasangan[0][0]
    else:
        berkas = berkas_berlaku(pasangan[0][0])
    if berkas is None or not berkas.is_file():
        print(f"  LEWAT {nama}: pola tidak ada / tidak unik di migrasi mana pun")
        dilewati.append(nama)
        continue
    asli = berkas.read_text(encoding="utf-8")
    isi = asli
    ok = True
    disimpan: list = []
    for unsur in pasangan:
        if len(unsur) == 3:
            berkas_g = KERJA / "supabase/migrations" / unsur[0]
            cari, ganti = unsur[1], unsur[2]
        else:
            berkas_g, cari, ganti = berkas, unsur[0], unsur[1]
        isi_g = berkas_g.read_text(encoding="utf-8")
        if isi_g.count(cari) != 1:
            ok = False
            break
        disimpan.append((berkas_g, isi_g))
        berkas_g.write_text(isi_g.replace(cari, ganti), encoding="utf-8")
    if not ok:
        print(f"  LEWAT {nama}: ada pola yang tidak unik")
        for f, isi_g in disimpan:
            f.write_text(isi_g, encoding="utf-8")
        hasil.append(False)
        continue
    kode, keluar = jalankan(uji)
    for f, isi_g in disimpan:
        f.write_text(isi_g, encoding="utf-8")
    merah = kode != 0 and "ERR_MODULE_NOT_FOUND" not in keluar
    print(f"  {'OK  ' if merah else 'X   '}{nama}: {'MERAH' if merah else 'HIJAU (pagar tumpul)'} ({uji.split('/')[-1]})")
    if not merah:
        print("      " + "\n      ".join(keluar.splitlines()[-6:]))
    hasil.append(merah)

# KONTROL PENUTUP: semua pulih → semua uji hijau lagi
print("\nKONTROL PENUTUP (setelah dipulihkan harus hijau)")
pulih = True
for uji in berkas_uji:
    kode, _ = jalankan(uji)
    if kode != 0:
        pulih = False
        print(f"  X   {uji.split('/')[-1]}: kode {kode}")
print(f"  {'OK  ' if pulih else 'X   '}semua uji hijau lagi setelah pemulihan")
if dilewati:
    print("PERHATIAN: " + str(len(dilewati)) + " mutasi DILEWATI (pola tidak bisa dimutasi): " + ", ".join(dilewati))
print(f"\nRINGKASAN: {sum(hasil)}/{len(hasil)} mutasi WAJIB terbukti MERAH "
      f"(+ {len(BERTUMPUK)} mutasi tunggal pada penjaga bertumpuk: hijau = sesuai dugaan; "
      f"lapisan itu dibuktikan lewat mutasi gabungan M3k/M5k/M8k)")
sys.exit(0 if (all(hasil) and pulih and not dilewati) else 1)
