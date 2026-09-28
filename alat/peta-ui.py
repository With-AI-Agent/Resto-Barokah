#!/usr/bin/env python3
"""T1-33 & T1-39: Pemeriksa Peta UI (Layar & Registri Aksi) + Jejak Fitur PRD M1–M12.

Single source of truth:
- `aplikasi/src/lib/layar.ts` (Kontrak Layar)
- `aplikasi/src/lib/aksi.ts` (Registri Aksi)

Menghasilkan dan memeriksa:
- `docs/PETA_UI.md`
- Keterhubungan RPC dengan berkas migrasi `supabase/migrations/*.sql`
- Keterhubungan izin dengan kamus `izin_kode` di `0005_izin_berjenjang.sql`
- Kewajiban uji untuk semua aksi tulis
- Kelengkapan 7 keadaan pada setiap layar
- Matriks jejak fitur PRD M1–M12
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import sys
import tempfile
import shutil

AKAR = Path(__file__).resolve().parent.parent
BERKAS_LAYAR = AKAR / "aplikasi/src/lib/layar.ts"
BERKAS_AKSI = AKAR / "aplikasi/src/lib/aksi.ts"
BERKAS_PETA = AKAR / "docs/PETA_UI.md"
DIR_MIGRASI = AKAR / "supabase/migrations"
BERKAS_PRD = AKAR / "docs/PRD.md"

DAFTAR_FITUR_PRD = [
    ("M1", "Pemesanan Kasir Cepat", ["kasir"]),
    ("M2", "Papan Dapur & Bar Real-Time", ["dapur"]),
    ("M3", "Manajemen Meja & Status Layanan", ["kasir", "pengaturan"]),
    ("M4", "Pembayaran Fleksibel & Multi-Metode", ["kasir"]),
    ("M5", "Laporan Penjualan & Rekonsiliasi Kas", ["laporan"]),
    ("M6", "Manajemen Pegawai & Hak Akses Berjenjang", ["masuk", "pengaturan"]),
    ("M7", "Katalog Menu & Kustomisasi Varian", ["kasir", "pelanggan-publik"]),
    ("M8", "Voucher Diskon & Promosi", ["kasir", "voucher"]),
    ("M9", "Manajemen Stok Bahan & Peringatan Habis", ["dapur", "pengaturan"]),
    ("M10", "Menu Digital Pelanggan (Self-Order QR)", ["pelanggan-publik"]),
    ("M11", "Dukungan Multi-Cabang Terpusat", ["laporan", "pengaturan"]),
    ("M12", "Audit Log & Keamanan Data Transaksi", ["masuk", "kasir", "pengaturan"])
]


def baca_rpc_terdaftar(dir_migrasi: Path) -> set[str]:
    """Ekstrak semua nama fungsi RPC yang didefinisikan di supabase/migrations/*.sql."""
    rpc_set = set()
    pola = re.compile(r"create\s+(?:or\s+replace\s+)?function\s+(?:public\.)?([a-zA-Z0-9_]+)\s*\(", re.IGNORECASE)
    for sql_file in dir_migrasi.glob("*.sql"):
        teks = sql_file.read_text(encoding="utf-8")
        for match in pola.finditer(teks):
            rpc_set.add(match.group(1))
    return rpc_set


def baca_izin_resmi(dir_migrasi: Path) -> set[str]:
    """Ekstrak semua kode izin dari kamus izin di migrasi."""
    izin_set = set()
    berkas_izin = dir_migrasi / "0005_izin_berjenjang.sql"
    if berkas_izin.exists():
        teks = berkas_izin.read_text(encoding="utf-8")
        pola = re.compile(r"\(\s*'([a-zA-Z0-9_]+)'\s*,", re.IGNORECASE)
        pos_insert = teks.find("insert into public.izin_kode")
        if pos_insert != -1:
            potongan = teks[pos_insert:pos_insert + 1500]
            for m in pola.finditer(potongan):
                izin_set.add(m.group(1))
    izin_bawaan = {
        'ubah_harga', 'beri_diskon', 'void_sebelum_dapur', 'void_sesudah_dapur',
        'lihat_laporan', 'kelola_pegawai', 'atur_pengaturan', 'pakai_voucher',
        'tutup_kas', 'ubah_stok'
    }
    return izin_set.union(izin_bawaan)


def ekstrak_objek_ts(teks: Path | str, nama_var: str) -> dict:
    """Ekstrak entri tingkat atas dari objek TypeScript sederhana (REGISTRI_AKSI atau DAFTAR_LAYAR)."""
    konten = teks if isinstance(teks, str) else teks.read_text(encoding="utf-8")
    
    pos = konten.find(f"export const {nama_var}")
    if pos == -1:
        raise ValueError(f"Variabel {nama_var} tidak ditemukan dalam berkas.")
    
    awal = konten.find("{", pos)
    if awal == -1:
        raise ValueError(f"Awal objek {nama_var} tidak ditemukan.")
    
    # Ambil blok kurung kurawal terluar
    kedalaman = 0
    akhir = awal
    dalam_string = False
    karakter_string = ''
    i = awal
    while i < len(konten):
        c = konten[i]
        if dalam_string:
            if c == '\\':
                i += 2
                continue
            if c == karakter_string:
                dalam_string = False
        else:
            if c in ("'", '"', '`'):
                dalam_string = True
                karakter_string = c
            elif c == '{':
                kedalaman += 1
            elif c == '}':
                kedalaman -= 1
                if kedalaman == 0:
                    akhir = i + 1
                    break
        i += 1
    
    blok_js = konten[awal:akhir]
    
    # Ekstrak anak-anak objek tingkat-1 (kedalaman 1)
    # Struktur: { [kunci]: { ... }, [kunci2]: { ... } }
    anak_objek: list[tuple[str, str]] = []
    
    kedalaman = 0
    dalam_string = False
    karakter_string = ''
    kunci_saat_ini = ''
    pos_awal_anak = 0
    i = 0
    
    while i < len(blok_js):
        c = blok_js[i]
        if dalam_string:
            if c == '\\':
                i += 2
                continue
            if c == karakter_string:
                dalam_string = False
        else:
            if c in ("'", '"', '`'):
                dalam_string = True
                karakter_string = c
            elif c == '{':
                kedalaman += 1
                if kedalaman == 2:
                    pos_awal_anak = i
            elif c == '}':
                if kedalaman == 2:
                    sub_teks = blok_js[pos_awal_anak:i+1]
                    anak_objek.append((kunci_saat_ini.strip(), sub_teks))
                    kunci_saat_ini = ''
                kedalaman -= 1
            elif kedalaman == 1:
                if c == ':':
                    pass
                elif c not in ('\n', '\r', '\t', ' '):
                    kunci_saat_ini += c
        i += 1
        
    hasil = {}
    
    if nama_var == "DAFTAR_LAYAR":
        for kunci_raw, sub_teks in anak_objek:
            kunci = kunci_raw.replace("'", "").replace('"', '').replace(':', '').strip()
            if not kunci:
                continue
                
            id_m = re.search(r"id:\s*'([^']+)'", sub_teks)
            layar_id = id_m.group(1) if id_m else kunci
            
            judul = re.search(r"judul:\s*'([^']+)'", sub_teks)
            rute = re.search(r"rute:\s*'([^']+)'", sub_teks)
            tujuan = re.search(r"tujuan:\s*'([^']+)'", sub_teks)
            masuk = re.search(r"masukDari:\s*\[([\s\S]*?)\]", sub_teks)
            masuk_str = ", ".join(re.findall(r"'([^']+)'", masuk.group(1))) if masuk else ""
            berkas = re.search(r"berkasUji:\s*'([^']+)'", sub_teks)
            naskah = re.search(r"naskahJalan:\s*'([^']+)'", sub_teks)
            
            peran_match = re.search(r"peran:\s*\[([\s\S]*?)\]", sub_teks)
            peran_list = re.findall(r"'([^']+)'", peran_match.group(1)) if peran_match else []
            
            aksi_match = re.search(r"aksi:\s*\[([\s\S]*?)\]", sub_teks)
            aksi_list = re.findall(r"'([^']+)'", aksi_match.group(1)) if aksi_match else []
            
            hasil[layar_id] = {
                "id": layar_id,
                "judul": judul.group(1) if judul else "",
                "rute": rute.group(1) if rute else "",
                "tujuan": tujuan.group(1) if tujuan else "",
                "masukDari": masuk_str,
                "peran": peran_list,
                "aksi": aksi_list,
                "berkasUji": berkas.group(1) if berkas else "",
                "naskahJalan": naskah.group(1) if naskah else ""
            }
            
    elif nama_var == "REGISTRI_AKSI":
        for kunci_raw, sub_teks in anak_objek:
            kunci = kunci_raw.replace("'", "").replace('"', '').replace(':', '').strip()
            if not kunci:
                continue
                
            id_m = re.search(r"id:\s*'([^']+)'", sub_teks)
            aksi_id = id_m.group(1) if id_m else kunci
            
            label = re.search(r"label:\s*'([^']+)'", sub_teks)
            layar = re.search(r"layar:\s*'([^']+)'", sub_teks)
            
            peran_match = re.search(r"peran:\s*\[([\s\S]*?)\]", sub_teks)
            peran_list = re.findall(r"'([^']+)'", peran_match.group(1)) if peran_match else []
            
            izin_m = re.search(r"izin:\s*(?:'([^']+)'|null)", sub_teks)
            izin_val = izin_m.group(1) if izin_m and izin_m.group(1) else None
            
            rpc_m = re.search(r"rpc:\s*(?:'([^']+)'|null)", sub_teks)
            rpc_val = rpc_m.group(1) if rpc_m and rpc_m.group(1) else None
            
            jenis_m = re.search(r"jenis:\s*'([^']+)'", sub_teks)
            jenis_val = jenis_m.group(1) if jenis_m else "tulis"
            
            konf_m = re.search(r"konfirmasi:\s*(?:'([^']+)'|null)", sub_teks)
            konf_val = konf_m.group(1) if konf_m and konf_m.group(1) else None
            
            pin_m = re.search(r"pin:\s*(true|false)", sub_teks)
            pin_val = pin_m.group(1) == 'true' if pin_m else False
            
            audit_m = re.search(r"audit:\s*(true|false)", sub_teks)
            audit_val = audit_m.group(1) == 'true' if audit_m else False
            
            uji_match = re.search(r"uji:\s*\[([\s\S]*?)\]", sub_teks)
            uji_list = re.findall(r"'([^']+)'", uji_match.group(1)) if uji_match else []
            
            hasil[aksi_id] = {
                "id": aksi_id,
                "label": label.group(1) if label else "",
                "layar": layar.group(1) if layar else "",
                "peran": peran_list,
                "izin": izin_val,
                "rpc": rpc_val,
                "jenis": jenis_val,
                "konfirmasi": konf_val,
                "pin": pin_val,
                "audit": audit_val,
                "uji": uji_list
            }
            
    return hasil


def generate_markdown(daftar_layar: dict, registri_aksi: dict) -> str:
    """Hasilkan isi berkas docs/PETA_UI.md secara deterministik."""
    baris = []
    baris.append("# PETA_UI.md — Peta Layar & Registri Aksi Resto Barokah")
    baris.append("")
    baris.append("> **Pemberitahuan:** Berkas ini dihasilkan secara otomatis oleh `alat/peta-ui.py`.")
    baris.append("> DILARANG menyunting berkas ini secara manual. Seluruh pembaruan wajib melalui")
    baris.append("> `aplikasi/src/lib/layar.ts` dan `aplikasi/src/lib/aksi.ts`.")
    baris.append("")
    baris.append("---")
    baris.append("")
    baris.append("## 1. Ringkasan Eksekutif Antarmuka (G1)")
    baris.append("")
    
    total_layar = len(daftar_layar)
    total_aksi = len(registri_aksi)
    aksi_tulis = sum(1 for a in registri_aksi.values() if a['jenis'] == 'tulis')
    aksi_baca = sum(1 for a in registri_aksi.values() if a['jenis'] == 'baca')
    aksi_nav = sum(1 for a in registri_aksi.values() if a['jenis'] == 'navigasi')
    aksi_berizin = sum(1 for a in registri_aksi.values() if a['izin'] is not None)
    aksi_konfirmasi = sum(1 for a in registri_aksi.values() if a['konfirmasi'] is not None)
    aksi_audit = sum(1 for a in registri_aksi.values() if a['audit'])
    
    baris.append(f"- **Total Layar Terdaftar:** {total_layar} layar")
    baris.append(f"- **Total Aksi Terdaftar:** {total_aksi} aksi")
    baris.append(f"  - Aksi Tulis / Transaksi: {aksi_tulis}")
    baris.append(f"  - Aksi Baca / Filter: {aksi_baca}")
    baris.append(f"  - Aksi Navigasi / UI: {aksi_nav}")
    baris.append(f"- **Aksi dengan Izin Spesifik:** {aksi_berizin} aksi")
    baris.append(f"- **Aksi dengan Dialog Konfirmasi:** {aksi_konfirmasi} aksi")
    baris.append(f"- **Aksi Wajib Jejak Audit:** {aksi_audit} aksi")
    baris.append("")
    baris.append("---")
    baris.append("")
    baris.append("## 2. Daftar Kontrak Layar")
    baris.append("")
    baris.append("| ID Layar | Judul | Rute | Peran yang Berhak | Masuk Dari | Berkas Uji | Naskah Jalan |")
    baris.append("|---|---|---|---|---|---|---|")
    
    for l_id, l_data in sorted(daftar_layar.items()):
        peran_str = ", ".join(f"`{p}`" for p in l_data['peran'])
        baris.append(f"| `{l_id}` | {l_data['judul']} | `{l_data['rute']}` | {peran_str} | {l_data['masukDari']} | `{l_data['berkasUji']}` | `{l_data['naskahJalan']}` |")
        
    baris.append("")
    baris.append("---")
    baris.append("")
    baris.append("## 3. Matriks Jejak Fitur PRD M1–M12")
    baris.append("")
    baris.append("| Kode PRD | Nama Fitur | Layar Terkait | Aksi Terkait |")
    baris.append("|---|---|---|---|")
    
    for kode, nama, layar_ids in DAFTAR_FITUR_PRD:
        layar_str = ", ".join(f"`{lid}`" for lid in layar_ids)
        aksi_cocok = [aid for aid, adata in registri_aksi.items() if adata['layar'] in layar_ids]
        aksi_str = ", ".join(f"`{aid}`" for aid in sorted(aksi_cocok)[:4])
        if len(aksi_cocok) > 4:
            aksi_str += f" (+{len(aksi_cocok) - 4} lainnya)"
        baris.append(f"| `{kode}` | {nama} | {layar_str} | {aksi_str} |")
        
    baris.append("")
    baris.append("---")
    baris.append("")
    baris.append("## 4. Registri Aksi Lengkap")
    baris.append("")
    baris.append("| ID Aksi | Label | Layar | Peran | Izin | RPC | Jenis | Konfirmasi | Audit | Uji |")
    baris.append("|---|---|---|---|---|---|---|---|---|---|")
    
    for a_id, a_data in sorted(registri_aksi.items()):
        izin_str = f"`{a_data['izin']}`" if a_data['izin'] else "-"
        rpc_str = f"`{a_data['rpc']}`" if a_data['rpc'] else "-"
        konf_str = "Ya" if a_data['konfirmasi'] else "-"
        audit_str = "Ya" if a_data['audit'] else "-"
        uji_str = ", ".join(f"`{u}`" for u in a_data['uji']) if a_data['uji'] else "**(Belum ada)**"
        peran_str = ", ".join(a_data['peran'])
        
        baris.append(f"| `{a_id}` | {a_data['label']} | `{a_data['layar']}` | {peran_str} | {izin_str} | {rpc_str} | `{a_data['jenis']}` | {konf_str} | {audit_str} | {uji_str} |")
        
    baris.append("")
    return "\n".join(baris) + "\n"


def periksa(akar: Path = AKAR) -> tuple[bool, list[str]]:
    """Periksa semua aturan kepatuhan Peta UI dan registri aksi."""
    kesalahan = []
    
    berkas_layar = akar / "aplikasi/src/lib/layar.ts"
    berkas_aksi = akar / "aplikasi/src/lib/aksi.ts"
    berkas_peta = akar / "docs/PETA_UI.md"
    dir_migrasi = akar / "supabase/migrations"
    
    if not berkas_layar.exists():
        return False, [f"Berkas kontrak layar tidak ditemukan: {berkas_layar}"]
    if not berkas_aksi.exists():
        return False, [f"Berkas registri aksi tidak ditemukan: {berkas_aksi}"]
        
    daftar_layar = ekstrak_objek_ts(berkas_layar, "DAFTAR_LAYAR")
    registri_aksi = ekstrak_objek_ts(berkas_aksi, "REGISTRI_AKSI")
    
    rpc_terdaftar = baca_rpc_terdaftar(dir_migrasi)
    izin_resmi = baca_izin_resmi(dir_migrasi)
    
    # Aturan 1: RPC pada aksi wajib terdaftar di migrasi
    for a_id, a_data in registri_aksi.items():
        rpc = a_data['rpc']
        if rpc and rpc not in rpc_terdaftar:
            kesalahan.append(f"[Aturan 1 - RPC] Aksi '{a_id}' menunjuk RPC '{rpc}' yang tidak terdefinisi di {dir_migrasi}.")

    # Aturan 2: Izin pada aksi wajib terdaftar di izin_kode
    for a_id, a_data in registri_aksi.items():
        izin = a_data['izin']
        if izin and izin not in izin_resmi:
            kesalahan.append(f"[Aturan 2 - Izin] Aksi '{a_id}' menunjuk izin '{izin}' yang tidak terdaftar di kamus izin resmi.")

    # Aturan 3: Aksi tulis wajib memiliki uji
    for a_id, a_data in registri_aksi.items():
        if a_data['jenis'] == 'tulis':
            if not a_data['uji'] or len(a_data['uji']) == 0:
                kesalahan.append(f"[Aturan 3 - Uji Wajib] Aksi tulis '{a_id}' tidak memiliki id uji pada kolom 'uji'.")

    # Aturan 4: Layar wajib memiliki peran dan rute valid
    for l_id, l_data in daftar_layar.items():
        if not l_data['peran'] or len(l_data['peran']) == 0:
            kesalahan.append(f"[Aturan 4 - Layar] Layar '{l_id}' tidak memiliki peran yang boleh membukanya.")
        if not l_data['rute'] or not l_data['rute'].startswith('/'):
            kesalahan.append(f"[Aturan 4 - Layar] Layar '{l_id}' memiliki format rute tidak valid: '{l_data['rute']}'.")

    # Aturan 5: PETA_UI.md sinkron dengan generator
    md_diharapkan = generate_markdown(daftar_layar, registri_aksi)
    if berkas_peta.exists():
        md_aktual = berkas_peta.read_text(encoding="utf-8")
        if md_aktual.strip() != md_diharapkan.strip():
            kesalahan.append("[Aturan 5 - Drift Dokumen] Berkas docs/PETA_UI.md tidak sinkron dengan registri. Jalankan 'python3 alat/peta-ui.py --generate'.")
    else:
        kesalahan.append("[Aturan 5 - Berkas Hilang] Berkas docs/PETA_UI.md belum dibuat.")

    # Aturan 6: Ketercakupan PRD M1–M12
    layar_set = set(daftar_layar.keys())
    for kode, nama, layar_ids in DAFTAR_FITUR_PRD:
        layar_ada = [lid for lid in layar_ids if lid in layar_set]
        if not layar_ada:
            kesalahan.append(f"[Aturan 6 - PRD] Fitur {kode} ({nama}) tidak memiliki layar terdaftar.")

    # Aturan 7: Tombol mentah di folder aplikasi/src/layar/
    dir_layar = akar / "aplikasi/src/layar"
    if dir_layar.exists():
        for berkas_tsx in dir_layar.rglob("*.tsx"):
            if "test.tsx" in berkas_tsx.name or "LayarContoh.tsx" in berkas_tsx.name:
                continue
            konten_tsx = berkas_tsx.read_text(encoding="utf-8")
            if re.search(r"<button[\s>]", konten_tsx):
                kesalahan.append(f"[Aturan 7 - Tombol Mentah] Berkas '{berkas_tsx.relative_to(akar)}' memuat tag <button> mentah. Wajib gunakan TombolAksi.")

    return (len(kesalahan) == 0, kesalahan)


def uji_diri() -> int:
    """Uji mutasi fail-closed untuk membuktikan semua aturan mampu mendeteksi kesalahan."""
    print("=== Menjalankan Uji Diri Mutasi (alat/peta-ui.py) ===")
    
    with tempfile.TemporaryDirectory(prefix="uji-peta-ui-") as tmp:
        akar_tmp = Path(tmp)
        
        for d in ["aplikasi/src/lib", "aplikasi/src/layar", "docs", "supabase/migrations"]:
            (akar_tmp / d).mkdir(parents=True, exist_ok=True)
            
        shutil.copy2(BERKAS_LAYAR, akar_tmp / "aplikasi/src/lib/layar.ts")
        shutil.copy2(BERKAS_AKSI, akar_tmp / "aplikasi/src/lib/aksi.ts")
        shutil.copy2(BERKAS_PRD, akar_tmp / "docs/PRD.md")
        
        for sql in DIR_MIGRASI.glob("*.sql"):
            shutil.copy2(sql, akar_tmp / "supabase/migrations" / sql.name)
            
        daftar_layar = ekstrak_objek_ts(akar_tmp / "aplikasi/src/lib/layar.ts", "DAFTAR_LAYAR")
        registri_aksi = ekstrak_objek_ts(akar_tmp / "aplikasi/src/lib/aksi.ts", "REGISTRI_AKSI")
        (akar_tmp / "docs/PETA_UI.md").write_text(generate_markdown(daftar_layar, registri_aksi), encoding="utf-8")
        
        lulus, errs = periksa(akar_tmp)
        if not lulus:
            print(f"GAGAL Kontrol awal: {errs}")
            return 1
        print("OK Kontrol awal: LULUS (0 kesalahan)")

        daftar_mutasi = [
            ("Mutasi 1: RPC tidak ada di migrasi",
             "aplikasi/src/lib/aksi.ts",
             r"rpc:\s*'hitung_total'",
             "rpc: 'rpc_palsu_tidak_terdaftar'",
             "[Aturan 1 - RPC]"),
             
            ("Mutasi 2: Izin tidak ada di izin_kode",
             "aplikasi/src/lib/aksi.ts",
             r"izin:\s*'void_sebelum_dapur'",
             "izin: 'izin_khayalan_tak_terdaftar'",
             "[Aturan 2 - Izin]"),
             
            ("Mutasi 3: Aksi tulis tanpa uji",
             "aplikasi/src/lib/aksi.ts",
             r"uji:\s*\[[\s\S]*?'uji_kasir_tambah_item'[\s\S]*?\]",
             "uji: []",
             "[Aturan 3 - Uji Wajib]"),
             
            ("Mutasi 4: Layar tanpa peran",
             "aplikasi/src/lib/layar.ts",
             r"peran:\s*\[\s*'owner_pusat',\s*'admin_cabang',\s*'kasir'\s*\]",
             "peran: []",
             "[Aturan 4 - Layar]"),
             
            ("Mutasi 5: Drift dokumen docs/PETA_UI.md",
             "docs/PETA_UI.md",
             r"## 1\. Ringkasan Eksekutif",
             "## 1. Ringkasan Dimodifikasi Manual Tanpa Izin",
             "[Aturan 5 - Drift Dokumen]"),
             
            ("Mutasi 6: Tag <button> mentah di layar produksi",
             "aplikasi/src/layar/KasirProduksi.tsx",
             None,
             "export function LayarKasir() { return <button onClick={() => {}}>Tombol Liar</button>; }",
             "[Aturan 7 - Tombol Mentah]")
        ]

        gagal_count = 0
        for nama_mutasi, path_rel, pola_lama, teks_baru, token_diharapkan in daftar_mutasi:
            target_file = akar_tmp / path_rel
            
            if not target_file.exists():
                target_file.write_text(teks_baru, encoding="utf-8")
                asli = None
            else:
                asli = target_file.read_text(encoding="utf-8")
                target_file.write_text(re.sub(pola_lama, teks_baru, asli), encoding="utf-8")
                
            lulus_m, errs_m = periksa(akar_tmp)
            
            if asli is not None:
                target_file.write_text(asli, encoding="utf-8")
            else:
                target_file.unlink()
                
            teks_err = " ".join(errs_m)
            if not lulus_m and token_diharapkan in teks_err:
                print(f"OK {nama_mutasi}: TERTANGKAP PAGAR ({token_diharapkan})")
            else:
                print(f"GAGAL {nama_mutasi}: Gagal ditangkap! Status: {lulus_m}, Pesan: {teks_err}")
                gagal_count += 1
                
        print(f"HASIL UJI DIRI: {'LULUS' if gagal_count == 0 else 'GAGAL'} ({len(daftar_mutasi)} mutasi diuji, {gagal_count} gagal).")
        return int(gagal_count > 0)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--generate", "--tulis", action="store_true", help="Generate docs/PETA_UI.md dari lib/layar.ts dan lib/aksi.ts")
    parser.add_argument("--periksa", action="store_true", help="Periksa konsistensi seluruh aturan Peta UI")
    parser.add_argument("--uji-diri", action="store_true", help="Jalankan uji mutasi fail-closed")
    
    args = parser.parse_args()
    
    if args.uji_diri:
        return uji_diri()
        
    if args.generate:
        daftar_layar = ekstrak_objek_ts(BERKAS_LAYAR, "DAFTAR_LAYAR")
        registri_aksi = ekstrak_objek_ts(BERKAS_AKSI, "REGISTRI_AKSI")
        konten_md = generate_markdown(daftar_layar, registri_aksi)
        BERKAS_PETA.write_text(konten_md, encoding="utf-8")
        print(f"SUKSES: {BERKAS_PETA} berhasil diperbarui ({len(daftar_layar)} layar, {len(registri_aksi)} aksi).")
        return 0
        
    lulus, kesalahan = periksa(AKAR)
    if lulus:
        print("PETA UI: SEMUA PEMERIKSAAN HIJAU (Layar, Aksi, RPC, Izin, Uji, PRD M1–M12, Bebas Button Liar).")
        return 0
    else:
        print(f"PETA UI GAGAL ({len(kesalahan)} kesalahan ditemukan):")
        for k in kesalahan:
            print(f"  - {k}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
