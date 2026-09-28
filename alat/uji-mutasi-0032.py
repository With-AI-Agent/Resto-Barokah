#!/usr/bin/env python3
"""
UJI MUTASI — membuktikan ketajaman pagar migrasi 0032 (T4-04, Jejak Status Item Dapur):
  1. Pencatatan riwayat dihapus (transisi tidak tercatat)
  2. Anti-dobel RPC dihapus (tanda dobel jadi diubah=true)
  3. Penyaring WHEN "status benar-benar berubah" dihapus (tanda dobel dobel mencatat)
  4. Sinkron pesanan → 'siap' dihapus (pesanan tidak pernah selesai)
  5. Sinkron pesanan → 'dimasak' dihapus (pesanan tertinggal 'dikirim')
  6. Hak ubah riwayat diberikan lewat GRANT (jejak bisa dimutilasi)
  7. Penjaga kunci idempoten dihapus (ulangan lama melompatkan status)

Setiap mutasi WAJIB membuat berkas uji 'status_item.sql' MERAH.

Verifikasi: python3 alat/uji-mutasi-0032.py            (7/7 mutasi wajib MERAH)
            python3 alat/uji-mutasi-0032.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI_0032 = os.path.join(REPO, "supabase", "migrations", "0032_status_item_dapur.sql")


def jalankan_uji():
    res = subprocess.run(
        ["node", "alat/uji-sql.mjs", "supabase/tes/status_item.sql"],
        cwd=REPO,
        capture_output=True,
        text=True
    )
    output = res.stdout + res.stderr
    lulus = "uji: 1 LULUS · 0 GAGAL" in output
    return lulus, output


def uji_mutasi():
    print("UJI MUTASI 0032 (Jejak Status Item Dapur — anti-dobel & riwayat kekal)")
    with open(MIGRASI_0032, "r", encoding="utf-8") as f:
        asli_migrasi = f.read()

    daftar_mutasi = [
        ("Pencatatan riwayat dihapus",
         "  insert into public.pesanan_item_status_riwayat\n"
         "    (pesanan_item_id, pesanan_id, dari, ke, oleh_pengguna_id, kunci_idempoten)\n"
         "  values\n"
         "    (new.id, new.pesanan_id, old.status, new.status, auth.uid(), v_kunci);",
         "  -- mutasi: riwayat tidak ditulis;"),
        ("Anti-dobel RPC (status sudah) dihapus",
         "  if v_status_lama = p_status then\n"
         "    return jsonb_build_object('berhasil', true, 'diubah', false,\n"
         "                              'alasan', 'status sudah ' || p_status);\n"
         "  end if;",
         "  -- mutasi: tanda dobel dibiarkan;"),
        ("Penyaring WHEN status berubah dihapus",
         "  when (old.status is distinct from new.status and new.status in ('dimasak', 'siap'))",
         "  when (new.status in ('dimasak', 'siap'))"),
        ("Sinkron pesanan ke siap dihapus",
         "     where id = new.pesanan_id\n"
         "       and status = 'dimasak'\n"
         "       and not exists (select 1 from public.pesanan_item pi",
         "     where false\n"
         "       and status = 'dimasak'\n"
         "       and not exists (select 1 from public.pesanan_item pi"),
        ("Sinkron pesanan ke dimasak dihapus",
         "     where id = new.pesanan_id and status = 'dikirim';",
         "     where false and status = 'dikirim';"),
        ("Hak ubah riwayat diberikan lewat GRANT (baris terakhir yang menang)",
         "grant select, insert on table public.pesanan_item_status_riwayat to authenticated;",
         "grant select, insert, update on table public.pesanan_item_status_riwayat to authenticated;"),
        ("Penjaga kunci idempoten dihapus",
         "  if p_kunci_idempoten is not null\n"
         "     and exists (select 1 from public.pesanan_item_status_riwayat k\n"
         "                  where k.kunci_idempoten = p_kunci_idempoten) then\n"
         "    return jsonb_build_object('berhasil', true, 'diubah', false,\n"
         "                              'alasan', 'kunci idempoten sudah pernah diproses');\n"
         "  end if;",
         "  -- mutasi: kunci idempoten tidak dijaga;"),
    ]

    try:
        # Kontrol awal: harus hijau
        lulus, out = jalankan_uji()
        if not lulus:
            print("GAGAL KONTROL AWAL: Uji status_item.sql tidak lulus pada salinan utuh!")
            print(out)
            return 1
        print("  OK  kontrol: salinan utuh → uji status_item.sql hijau")

        for i, (nama, asal, ganti) in enumerate(daftar_mutasi, start=1):
            hasil = asli_migrasi.replace(asal, ganti)
            if hasil == asli_migrasi:
                print(f"  [X] Mutasi {i}: teks mutasi TIDAK MENEMPEL pada berkas — periksa jangkar!")
                return 1
            with open(MIGRASI_0032, "w", encoding="utf-8") as f:
                f.write(hasil)
            lulus, out = jalankan_uji()
            if lulus:
                print(f"  [X] Mutasi {i}: {nama} LOLOS (Pagar tumpul!)")
                return 1
            print(f"  [OK] Mutasi {i}: {nama} TERBUKTI MERAH")

        print(f"\nHASIL: LOLOS — seluruh {len(daftar_mutasi)} mutasi wajib MERAH terbukti membuat uji merah.")
        return 0

    finally:
        with open(MIGRASI_0032, "w", encoding="utf-8") as f:
            f.write(asli_migrasi)


def uji_diri():
    print("UJI DIRI penilai mutasi 0032")
    with open(MIGRASI_0032, "r", encoding="utf-8") as f:
        asli_migrasi = f.read()
    # Penilai harus MENOLAK bila jangkar mutasi tidak ditemukan pada berkas.
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
