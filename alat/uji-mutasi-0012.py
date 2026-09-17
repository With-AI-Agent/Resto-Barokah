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


def berkas_berlaku(cari: str) -> pathlib.Path | None:
    """Berkas migrasi tempat pola itu BERLAKU = migrasi terakhir yang memuatnya.

    Urutan pencarian: `0013` (terbaru) dulu, lalu `0012`. Kalau pola tidak ada di keduanya
    atau muncul lebih dari sekali di satu berkas, kembalikan None (mutasi dilewati, bukan
    dilaporkan hijau).
    """
    for berkas in (MIG13, MIG):
        isi = berkas.read_text(encoding="utf-8")
        if isi.count(cari) == 1:
            return berkas
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
    ("M4 harga item bebas diisi klien",
     "if not public.boleh('ubah_harga') then", "if false then",
     "supabase/tes/harga_item.sql"),
    ("M5 subtotal dari klien dipercaya",
     "    new.subtotal := new.harga_saat_itu * new.qty;",
     "    new.subtotal := coalesce(new.subtotal, new.harga_saat_itu * new.qty);",
     "supabase/tes/harga_item.sql"),
    ("M6 bukti PIN boleh dipakai berulang",
     "       and pp.dipakai_pada is null", "       and (pp.dipakai_pada is null or true)",
     "supabase/tes/persetujuan_void.sql"),
    ("M7 pelaku pengaturan boleh dikarang",
     "       and new.diubah_oleh is distinct from old.diubah_oleh then", "       and false then",
     "supabase/tes/jejak_pengaturan.sql"),
    ("M8 keluar menambah stok lagi",
     "    v_jumlah := -abs(p_jumlah);", "    v_jumlah := p_jumlah;",
     "supabase/tes/stok_arah.sql"),
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
BERTUMPUK = {"M3a", "M3b"}

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
    ("M3k diskon boleh ditanam pada subtotal 0 (dua penjaga dimatikan sekaligus)",
     [("if coalesce(v_pesanan.subtotal, 0) <= 0 then", "if false then"),
      ("if v_total > v_pesanan.subtotal then", "if false then")],
     "supabase/tes/diskon_cap.sql"),
]

hasil = []


def jalankan_daftar(judul: str, mig: pathlib.Path, daftar: list) -> None:
    print(f"\n{judul}")
    for nama, cari, ganti, uji in daftar:
        berkas = berkas_berlaku(cari) or mig
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
    berkas = berkas_berlaku(pasangan[0][0]) or MIG
    asli = berkas.read_text(encoding="utf-8")
    isi = asli
    ok = True
    for cari, ganti in pasangan:
        if isi.count(cari) != 1:
            ok = False
            break
        isi = isi.replace(cari, ganti)
    if not ok:
        print(f"  LEWAT {nama}: pola tidak unik di {berkas.name}")
        hasil.append(False)
        continue
    berkas.write_text(isi, encoding="utf-8")
    kode, keluar = jalankan(uji)
    berkas.write_text(asli, encoding="utf-8")
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
print(f"\nRINGKASAN: {sum(hasil)}/{len(hasil)} mutasi WAJIB terbukti MERAH "
      f"(+ {len(BERTUMPUK)} mutasi tunggal pada penjaga bertumpuk: hijau = sesuai dugaan; "
      f"lapisan itu dibuktikan lewat mutasi gabungan M3k)")
sys.exit(0 if (all(hasil) and pulih) else 1)
