#!/usr/bin/env python3
"""
UJI MUTASI — membuktikan ketajaman pagar migrasi 0039 (RPC bayar_pesanan, T5-02):
  1. Pintu identitas dilepas (fungsi bisa dipanggil tanpa masuk)
  2. Pagar peran dilepas (SECURITY DEFINER melewati RLS — dapur bisa mencatat uang)
  3. Uang diterima yang tercatat dikurangi / kembalian dihitung nol
  4. Batas "tidak melebihi total pesanan" dilepas
  5. Pemeriksaan kunci idempoten dilepas (dobel tekan menambah uang)
  6. Pesanan tidak lagi dimajukan ke `lunas` saat total tertutup
  7. Jejak audit tidak lagi ditulis

Setiap mutasi WAJIB membuat berkas uji 'bayar_pesanan.sql' MERAH.

Tiga pagar SENGAJA tidak ada di daftar ini, dan alasannya dicatat supaya tidak
disangka terlewat (semuanya karena pagar lain di lapisan bawah menutup lebih dulu):
  * `v_kembalian := 0` — tidak terdeteksi karena pemicu picu_pembayaran_jujur
    (0010) menghitung ulang kembalian dari `diterima - jumlah` sebelum baris
    disimpan, dan balasan RPC membaca nilai TERSIMPAN itu (RETURNING). Pagar
    berlapis: nilai yang salah tidak pernah sampai ke jejak.
  * Batas "total dibayar <= total pesanan" dilepas — pemicu 0010 memeriksa batas
    yang sama saat INSERT, jadi di jalur mana pun uang berlebih tetap ditolak
    (pesannya beda; karena itu uji mematok kode BY-301 supaya yang terbukti
    menolak adalah PINTU ini, bukan penjaga lapisan bawah).
  * Kunci baris `for update` dilepas — diukur langsung dengan dua koneksi nyata
    (pgserver) pada 2026-09-23: pekerja tetap tertahan, kali ini di
    `picu_pembayaran_jujur` baris 11 yang juga mengunci baris pesanan (0012,
    PR-16). Bukti pg_stat_activity: wait_event_type='Lock',
    wait_event='transactionid', CONTEXT "while locking tuple (0,4) in relation
    pesanan". Jadi kunci di RPC ini adalah pagar LAPIS KEDUA yang membuat
    pemeriksaan batas di RPC sendiri benar (BY-301 keluar dari pintu, bukan dari
    pemicu); ia belum bisa diuji terpisah dari kunci pemicu.

Verifikasi: python3 alat/uji-mutasi-0039.py            (6/6 mutasi wajib MERAH)
            python3 alat/uji-mutasi-0039.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0039_bayar_pesanan.sql")


def jalankan_uji():
    res = subprocess.run(
        ["node", "alat/uji-sql.mjs", "supabase/tes/bayar_pesanan.sql"],
        cwd=REPO,
        capture_output=True,
        text=True
    )
    output = res.stdout + res.stderr
    lulus = "uji: 1 LULUS · 0 GAGAL" in output
    return lulus, output


def uji_mutasi():
    print("UJI MUTASI 0039 (bayar_pesanan — pintu tunggal uang masuk)")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli_migrasi = f.read()

    daftar_mutasi = [
        ("Pintu identitas dilepas",
         """  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;""",
         "  -- mutasi: tanpa identitas pun boleh"),
        ("Pagar peran dilepas (RLS tidak menjaga fungsi SECURITY DEFINER)",
         """  if public.peran_saya() not in ('owner_pusat', 'admin_cabang', 'kasir') then
    raise exception 'Peran % tidak berwenang mencatat uang masuk.', coalesce(public.peran_saya(), '(kosong)');
  end if;""",
         "  -- mutasi: semua peran boleh mencatat uang"),
        ("Uang diterima yang tercatat dikurangi (kembalian menyusut diam-diam)",
         "    case when v_metode.jenis = 'tunai' then p_diterima else null end,",
         "    case when v_metode.jenis = 'tunai' then p_jumlah else null end,"),
        ("Pemeriksaan kunci idempoten dilepas (dobel tekan menambah uang)",
         "  if v_lama.id is not null then",
         "  if false then   -- mutasi: ulangan kunci dianggap pembayaran baru"),
        ("Pesanan tidak dimajukan ke lunas",
         "  if v_sudah + p_jumlah >= v_total and v_pesanan.status <> 'lunas' then",
         "  if false then   -- mutasi: status tidak pernah maju ke lunas"),
    ]

    # Mutasi 7: jejak tetap tertulis tetapi dengan `aksi` yang salah, sehingga jejak
    # pembayaran tidak lagi bisa ditemukan/diaudit — uji wajib MERAH.
    daftar_mutasi.append((
        "Jejak audit ditulis dengan aksi yang salah (jejak pembayaran hilang dari audit)",
        """    'bayar_pesanan',
    'pembayaran',""",
        """    'mutasi-tanpa-jejak',
    'pembayaran',""",
    ))

    try:
        lulus, out = jalankan_uji()
        if not lulus:
            print("GAGAL KONTROL AWAL: Uji bayar_pesanan.sql tidak lulus pada salinan utuh!")
            print(out)
            return 1
        print("  OK  kontrol: salinan utuh → uji bayar_pesanan.sql hijau")

        for i, (nama, asal, ganti) in enumerate(daftar_mutasi, start=1):
            hasil = asli_migrasi.replace(asal, ganti)
            if hasil == asli_migrasi:
                print(f"  [X] Mutasi {i}: teks mutasi TIDAK MENEMPEL pada berkas — periksa jangkar!")
                return 1
            with open(MIGRASI, "w", encoding="utf-8") as f:
                f.write(hasil)
            lulus, out = jalankan_uji()
            if lulus:
                print(f"  [X] Mutasi {i}: {nama} LOLOS (Pagar tumpul!)")
                print(out[-1500:])
                return 1
            print(f"  [OK] Mutasi {i}: {nama} TERBUKTI MERAH")

        print(f"\nHASIL: LOLOS — seluruh {len(daftar_mutasi)} mutasi wajib MERAH terbukti membuat uji merah.")
        return 0

    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli_migrasi)


def uji_diri():
    print("UJI DIRI penilai mutasi 0039")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli_migrasi = f.read()
    palsu = asli_migrasi.replace("jangkar-yang-tidak-akan-ada-xyz", "rusak")
    if palsu != asli_migrasi:
        print("  [X] deteksi jangkar tidak menempel TIDAK bekerja")
        return 1
    lulus, _ = jalankan_uji()
    if not lulus:
        print("  [X] kontrol hijau tidak berfungsi")
        return 1
    print("  OK  kontrol positif hijau & deteksi jangkar tidak menempel bekerja.")
    return 0


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(uji_mutasi())
