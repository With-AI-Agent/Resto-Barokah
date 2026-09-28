#!/usr/bin/env python3
"""
UJI MUTASI 0069 — membuktikan ketajaman privasi pelanggan & anonimisasi UU PDP (T8-15).

Mutasi yang WAJIB membuat `supabase/tes/privasi.sql` MERAH:
  1. Validasi persetujuan privasi UU PDP dimatikan (pelanggan tanpa persetujuan bisa masuk).
  2. Isolasi penyewa dilepas pada `anonimkan_pelanggan` (bisa anonimkan pelanggan penyewa lain).
  3. Otorisasi peran dilepas pada `anonimkan_pelanggan` (peran pelayan/tanpa izin bisa anonimkan).
  4. Pembersihan kontak pribadi dilepas (email/telepon tetap tertinggal saat dianonimkan).
  5. Pencatatan catatan_audit dilepas (anonimisasi berjalan tanpa jejak audit).
  6. Pemeriksaan auth.uid() dilepas (panggilan tanpa login tidak ditolak 42501).

Kontrol positif: salinan utuh hijau.

Verifikasi: python3 alat/uji-mutasi-0069.py
            python3 alat/uji-mutasi-0069.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0069_privasi_pelanggan.sql")
BERKAS_UJI = ["supabase/tes/privasi.sql"]


def jalankan_uji():
    res = subprocess.run(
        ["node", "alat/uji-sql.mjs", *BERKAS_UJI],
        cwd=REPO,
        capture_output=True,
        text=True,
    )
    keluaran = res.stdout + res.stderr
    return (
        f"uji: {len(BERKAS_UJI)} LULUS · 0 GAGAL" in keluaran,
        keluaran,
    )


DAFTAR_MUTASI = [
    (
        "Persetujuan privasi UU PDP dimatikan pada pemicu",
        "  if coalesce(new.persetujuan_privasi, false) is not true then\n    raise exception 'Persetujuan pemrosesan data pribadi (UU PDP) wajib diberikan.'\n      using errcode = '22023';\n  end if;",
        "  -- mutasi: pagar persetujuan dimatikan\n  null;",
    ),
    (
        "Isolasi penyewa dilepas pada anonimkan_pelanggan",
        "  if v_pelanggan.penyewa_id <> v_penyewa_pemanggil then\n    raise exception 'Akses ditolak: pelanggan bukan milik penyewa Anda.' using errcode = '42501';\n  end if;",
        "  -- mutasi: isolasi penyewa dilepas\n  null;",
    ),
    (
        "Otorisasi peran dilepas pada anonimkan_pelanggan",
        "  if v_peran not in ('owner_pusat', 'admin_cabang', 'kasir') then\n    raise exception 'Peran % tidak memiliki wewenang untuk menganonimkan data pelanggan.', coalesce(v_peran, 'tanpa_peran')\n      using errcode = '42501';\n  end if;",
        "  -- mutasi: otorisasi peran dilepas\n  null;",
    ),
    (
        "Penyamaran nama subjek data dilepas saat anonimisasi",
        "    nama = 'Pelanggan Teranonimkan (UU PDP)',",
        "    nama = v_pelanggan.nama,  -- mutasi: nama tidak disamarkan",
    ),
    (
        "Pembersihan kontak pada pemicu data teranonimkan dilepas",
        "  if new.status_privasi = 'teranonimkan' then\n    new.email := null;\n    new.email_normalisasi := null;\n    new.telepon := null;\n    new.alamat := null;",
        "  if new.status_privasi = 'teranonimkan' then\n    -- mutasi: kontak tidak dinolkan pemicu\n    null;",
    ),
    (
        "Pencatatan jejak catatan_audit dilepas",
        "  insert into public.catatan_audit (\n    penyewa_id,\n    pelaku_id,\n    aksi,\n    entitas,\n    entitas_id,\n    nilai_lama,\n    nilai_baru\n  ) values (\n    v_pelanggan.penyewa_id,\n    v_uid,\n    'anonimisasi_pelanggan',",
        "  -- mutasi: audit log diabaikan\n  if false then\n  insert into public.catatan_audit (\n    penyewa_id,\n    pelaku_id,\n    aksi,\n    entitas,\n    entitas_id,\n    nilai_lama,\n    nilai_baru\n  ) values (\n    v_pelanggan.penyewa_id,\n    v_uid,\n    'anonimisasi_pelanggan',",
    ),
    (
        "Pemeriksaan auth.uid() dilepas",
        "  v_uid := auth.uid();\n  if v_uid is null then\n    raise exception 'Tidak diautentikasi.' using errcode = '42501';\n  end if;",
        "  v_uid := coalesce(auth.uid(), '90000000-0000-0000-0000-000000000001'::uuid);",
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0069 (T8-15 — Privasi Pelanggan & Anonimisasi UU PDP)")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli = f.read()

    try:
        lulus, keluaran = jalankan_uji()
        if not lulus:
            print("GAGAL KONTROL AWAL: uji tidak hijau pada salinan utuh!")
            print(keluaran[-1500:])
            return 1
        print("  OK  kontrol: salinan utuh → " + " + ".join(BERKAS_UJI) + " hijau")

        for nomor, (nama, asal, ganti) in enumerate(DAFTAR_MUTASI, start=1):
            hasil = asli.replace(asal, ganti)
            if hasil == asli:
                print(f"  [X] Mutasi {nomor}: teks mutasi TIDAK MENEMPEL pada berkas — periksa jangkar!")
                return 1
            with open(MIGRASI, "w", encoding="utf-8") as f:
                f.write(hasil)
            lulus, keluaran = jalankan_uji()
            if lulus:
                print(f"  [X] Mutasi {nomor}: {nama} LOLOS (pagar tumpul!)")
                print(keluaran[-1500:])
                return 1
            print(f"  [OK] Mutasi {nomor}: {nama} TERBUKTI MERAH")

        print(
            f"\nHASIL: LOLOS — semua {len(DAFTAR_MUTASI)} mutasi WAJIB MERAH benar-benar merah; "
            "pagar Privasi Pelanggan & Anonimisasi UU PDP (T8-15) terbukti tajam."
        )
        return 0
    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli)


def uji_diri():
    print("UJI DIRI penilai mutasi 0069")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli = f.read()
    palsu = asli.replace("jangkar-yang-tidak-akan-ada-xyz", "rusak")
    if palsu != asli:
        print("Uji diri gagal: penggantian tak terduga berhasil!")
        return 1
    print("  OK  uji-diri: mutasi sintetis tak menempel")
    print("UJI DIRI 0069 SELESAI — LOLOS")
    return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--uji-diri":
        sys.exit(uji_diri())
    sys.exit(uji_mutasi())
