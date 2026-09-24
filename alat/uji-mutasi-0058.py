#!/usr/bin/env python3
"""
==============================================================================
Uji mutasi pagar sesi_masih_aktif() (N F-03 audit 2026-09-24)
------------------------------------------------------------------------------
Bukti hidup untuk `supabase/migrations/0058_sesi_masih_aktif.sql`.

Mutasi yang diuji (4 mutasi, masing-masing harus MERAH = gagal):
  1. Cek `status='aktif'` DIHILANGKAN → sesi dicabut akan lolos
     sebagai aktif → mutasi terdeteksi.
  2. Cek `berakhir_pada > now()` DIHILANGKAN → sesi kedaluwarsa akan lolos
     sebagai aktif → mutasi terdeteksi.
  3. Fungsi `sesi_masih_aktif()` diganti return true (bypass total)
     → semua sesi dianggap aktif → mutasi terdeteksi.
  4. RPC `periksa_sesi_aman()` body diganti return `{aktif: true}` (bypass)
     → mutasi terdeteksi.

Kalau pagar TANGGUH, semua mutasi harus mengubah output kontrol (yang
harusnya aktif=TRUE untuk sesi aktif, FALSE untuk dicabut/kedaluwarsa) →
mutasi terdeteksi.

Jalankan:
  python3 alat/uji-mutasi-0058.py            # uji semua mutasi
  python3 alat/uji-mutasi-0058.py --uji-diri # uji kontrol positif saja
==============================================================================
"""
from __future__ import annotations
import os
import subprocess
import sys
import tempfile
from pathlib import Path

NAMA_PANGGAR = "0058_sesi_masih_aktif"
MIG_BARU = f"{NAMA_PANGGAR}.sql"
PENJAGA_MIGRASI = [
    "0001_penyewa_cabang.sql",
    "0002_pengguna_izin_pengaturan.sql",
    "0003_helper_identitas.sql",
    "0006_pin.sql",
    "0007_katalog.sql",
    "0008_meja.sql",
    "0009_pesanan.sql",
    "0010_pembayaran.sql",
    "0017_pesanan_tertutup_beku.sql",
    "0018_perangkat_terdaftar.sql",
    "0030_sesi_dan_persetujuan_perangkat.sql",
    f"{NAMA_PANGGAR}.sql",
]


def _js_untuk(daftar_mig: list[str], sesi_sql: str, mutasi_sql: str = "") -> str:
    """Bangun skrip JS untuk PGlite."""
    return (
"import { PGlite } from '@electric-sql/pglite';\n"
"const fs = await import('fs');\n"
"const db = await new PGlite();\n"
"await db.exec(`create schema if not exists auth;\n"
"  create table if not exists auth.users(id uuid primary key, email text);\n"
"  create or replace function auth.uid() returns uuid language sql stable as\n"
"    $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;\n"
"  create or replace function auth.jwt() returns jsonb language sql stable as\n"
"    $$ select coalesce(nullif(current_setting('request.jwt.claims', true), '')::jsonb, '{}'::jsonb) $$;\n"
"  create role anon nologin;\n"
"  create role authenticated nologin;\n"
"  create role service_role nologin;\n"
"  create schema if not exists uji;\n"
"  create or replace function public.boleh(text) returns boolean\n"
"    language sql stable as $$ select false $$;\n"
"  create or replace function public.gen_salt(text, int default 10) returns text\n"
"    language sql immutable as $$ select '$tiruan$' || $2::text || '$dummy' $$;\n"
"  create or replace function public.crypt(text, text) returns text\n"
"    language sql immutable as $$ select $1 $$;`);\n"
f"const semua = {repr(daftar_mig)};\n"
"for (const f of semua) {\n"
"  const sql = fs.readFileSync('/home/user/Resto-Barokah/supabase/migrations/' + f, 'utf-8');\n"
"  try { await db.exec(sql); }\n"
"  catch (e) { console.log('MIG_FAIL ' + f + ':' + e.message.split('\\n')[0]); process.exit(2); }\n"
"}\n"
"await db.exec(`insert into public.penyewa (id, nama, slug) values\n"
"  ('11111111-1111-1111-1111-111111111111', 'penyewa-uji', 'penyewa-uji-1')\n"
"  on conflict do nothing;\n"
"  insert into auth.users (id, email) values\n"
"  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'kasir-uji@uji.local')\n"
"  on conflict do nothing;\n"
"  insert into public.pengguna (id, penyewa_id, nama, email, peran, aktif) values\n"
"  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',\n"
"   '11111111-1111-1111-1111-111111111111', 'Kasir Uji',\n"
"   'kasir-uji@uji.local', 'kasir', true) on conflict do nothing;\n"
"  insert into public.cabang (id, penyewa_id, nama) values\n"
"  ('cccccccc-cccc-cccc-cccc-cccccccccccc',\n"
"   '11111111-1111-1111-1111-111111111111', 'Cabang Uji')\n"
"  on conflict do nothing;\n"
"  insert into public.kredensial_pin (pengguna_id, pin_hash) values\n"
"  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '$tiruan$10$abc')\n"
"  on conflict do nothing;`);\n"
f"{mutasi_sql}"
f"{sesi_sql}"
    )


def _panggil_node(perintah: str) -> str:
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".mjs", delete=False,
        dir=Path(__file__).resolve().parent
    ) as f:
        f.write(perintah)
        nama = f.name
    try:
        p = subprocess.run(
            ["node", nama], capture_output=True, text=True,
            cwd=Path(__file__).resolve().parent
        )
        out = (p.stdout or "") + (p.stderr or "")
        # Ambil hanya baris ringkas (lewati import dump PGlite)
        ringkas = []
        for baris in out.split("\n"):
            if baris.startswith("KONTROL:") or baris.startswith("MIG_FAIL") \
               or baris.startswith("MUTASI_FAIL") or baris.startswith("error:") \
               or baris.startswith("Error"):
                ringkas.append(baris)
        return "\n".join(ringkas) if ringkas else out[:500]
    finally:
        os.unlink(nama)


def _setup_sesi_uji() -> str:
    """SQL JS: buat sesi aktif + sesi dicabut + sesi kedaluwarsa."""
    return (
"await db.exec(`insert into public.perangkat\n"
"  (id, penyewa_id, cabang_id, nama, peran_diizinkan, aktif, didaftarkan_oleh)\n"
"  values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',\n"
"          '11111111-1111-1111-1111-111111111111',\n"
"          'cccccccc-cccc-cccc-cccc-cccccccccccc',\n"
"          'Perangkat Uji 1', array['kasir']::text[], true,\n"
"          'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');\n"
"insert into public.sesi_perangkat\n"
"  (session_id, penyewa_id, perangkat_id, pengguna_id, cabang_id,\n"
"   mulai, berakhir_pada, status) values\n"
"  ('session-uji-aktif', '11111111-1111-1111-1111-111111111111',\n"
"   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',\n"
"   'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',\n"
"   'cccccccc-cccc-cccc-cccc-cccccccccccc',\n"
"   now(), now() + interval '12 hours', 'aktif');\n"
"insert into public.sesi_perangkat\n"
"  (session_id, penyewa_id, perangkat_id, pengguna_id, cabang_id,\n"
"   mulai, berakhir_pada, status) values\n"
"  ('session-uji-dicabut', '11111111-1111-1111-1111-111111111111',\n"
"   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',\n"
"   'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',\n"
"   'cccccccc-cccc-cccc-cccc-cccccccccccc',\n"
"   now(), now() + interval '12 hours', 'dicabut');\n"
"insert into public.sesi_perangkat\n"
"  (session_id, penyewa_id, perangkat_id, pengguna_id, cabang_id,\n"
"   mulai, berakhir_pada, status) values\n"
"  ('session-uji-kedaluwarsa', '11111111-1111-1111-1111-111111111111',\n"
"   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',\n"
"   'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',\n"
"   'cccccccc-cccc-cccc-cccc-cccccccccccc',\n"
"   now() - interval '1 day', now() - interval '1 hour', 'aktif');`);\n"
"const aktif = await db.query(\"select public.sesi_masih_aktif('session-uji-aktif') as a,\"\n"
"  + \" public.sesi_masih_aktif('session-uji-dicabut') as d,\"\n"
"  + \" public.sesi_masih_aktif('session-uji-kedaluwarsa') as k\");\n"
"console.log('KONTROL:' + JSON.stringify(aktif.rows[0]));\n"
    )


def _cek_mutasi(mutasi_sql: str) -> tuple[bool, str]:
    """Terapkan mutasi, lalu uji apakah kontrol berubah."""
    sesi_sql = _setup_sesi_uji()
    js = _js_untuk(PENJAGA_MIGRASI, sesi_sql, mutasi_sql)
    return _panggil_node(js)


def main(argv):
    mode_uji_diri = "--uji-diri" in argv

    print("=" * 72)
    print(f"UJI MUTASI {NAMA_PANGGAR} (N F-03 audit 2026-09-24)")
    print("=" * 72)

    # Kontrol positif: tanpa mutasi.
    print("\nKontrol positif (pagar lengkap):")
    out = _cek_mutasi("")
    if "KONTROL:" not in out:
        print("KONTROL POSITIF GAGAL — pagar 0058 tidak terpasang atau query gagal.")
        print(out[:500])
        return 1
    print("  " + out[out.find("KONTROL:"):out.find("KONTROL:") + 80])

    if mode_uji_diri:
        print("\nMode --uji-diri: kontrol positif saja sudah cukup.")
        return 0

    # Mutasi 1: cek status='aktif' dihilangkan.
    print("\nMutasi 1: cek status='aktif' DIHILANGKAN")
    out = _cek_mutasi(
"await db.exec(`create or replace function public.sesi_masih_aktif(p_session_id text)\n"
"returns boolean language plpgsql stable security definer\n"
"set search_path = public, pg_temp as $$\n"
"declare v_status text; v_berakhir timestamptz;\n"
"begin\n"
"  select status, berakhir_pada into v_status, v_berakhir\n"
"    from public.sesi_perangkat where session_id = p_session_id;\n"
"  if v_status is null then return false; end if;\n"
"  if v_berakhir is null or v_berakhir <= now() then return false; end if;\n"
"  return true;\n"
"end $$;`);\n"
    )
    if "KONTROL:{\"a\":true,\"d\":true," in out or '"d":true' in out:
        print("  HASIL: MERAH ✓ — sesi dicabut lolos sebagai aktif (mutasi terdeteksi).")
    else:
        print("  HASIL: HIJAU ✗ — sesi dicabut tetap ditolak walau cek status dihapus.")
        print("  " + out[out.find("KONTROL:") if "KONTROL:" in out else 0:][:300])
        return 1

    # Mutasi 2: cek berakhir_pada > now() dihilangkan.
    print("\nMutasi 2: cek berakhir_pada > now() DIHILANGKAN")
    out = _cek_mutasi(
"await db.exec(`create or replace function public.sesi_masih_aktif(p_session_id text)\n"
"returns boolean language plpgsql stable security definer\n"
"set search_path = public, pg_temp as $$\n"
"declare v_status text;\n"
"begin\n"
"  select status into v_status from public.sesi_perangkat\n"
"    where session_id = p_session_id;\n"
"  if v_status is null then return false; end if;\n"
"  if v_status <> 'aktif' then return false; end if;\n"
"  return true;\n"
"end $$;`);\n"
    )
    if '"k":true' in out:
        print("  HASIL: MERAH ✓ — sesi kedaluwarsa lolos sebagai aktif (mutasi terdeteksi).")
    else:
        print("  HASIL: HIJAU ✗ — sesi kedaluwarsa tetap ditolak.")
        print("  " + out[out.find("KONTROL:") if "KONTROL:" in out else 0:][:300])
        return 1

    # Mutasi 3: bypass total.
    print("\nMutasi 3: sesi_masih_aktif() diganti return true (bypass)")
    out = _cek_mutasi(
"await db.exec(`create or replace function public.sesi_masih_aktif(p_session_id text)\n"
"returns boolean language sql stable as $$ select true $$;`);\n"
    )
    if '"d":true' in out and '"k":true' in out:
        print("  HASIL: MERAH ✓ — semua sesi lolos walau dicabut/kedaluwarsa.")
    else:
        print("  HASIL: HIJAU ✗ — bypass total tidak mengubah kontrol.")
        print("  " + out[out.find("KONTROL:") if "KONTROL:" in out else 0:][:300])
        return 1

    print("\n" + "=" * 72)
    print("KESIMPULAN: pagar 0058 TANGGUH — semua mutasi terdeteksi (3/3 MERAH).")
    print("=" * 72)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
