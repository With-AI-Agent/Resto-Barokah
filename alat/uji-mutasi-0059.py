#!/usr/bin/env python3
"""
==============================================================================
Uji mutasi pagar catat_percobaan_masuk tenant (N F-05 audit 2026-09-24)
------------------------------------------------------------------------------
Bukti hidup untuk `supabase/migrations/0059_catat_percobaan_masuk_tenant.sql`.

Mutasi yang diuji (3 mutasi, masing-masing harus MERAH = gagal):
  1. Cek `p_penyewa_id <> v_penyewa_saya` DIHILANGKAN.
  2. Cek `p_penyewa_id is null` DIHILANGKAN.
  3. Bypass total (langsung insert tanpa validasi).

Jalankan:
  python3 alat/uji-mutasi-0059.py            # uji semua mutasi
  python3 alat/uji-mutasi-0059.py --uji-diri # uji kontrol positif saja
==============================================================================
"""
from __future__ import annotations
import os
import subprocess
import sys
import tempfile
from pathlib import Path

NAMA_PANGGAR = "0059_catat_percobaan_masuk_tenant"
PENJAGA_MIGRASI = [
    "0001_penyewa_cabang.sql",
    "0002_pengguna_izin_pengaturan.sql",
    "0003_helper_identitas.sql",
    "0006_pin.sql",
    "0018_perangkat_terdaftar.sql",
    "0030_sesi_dan_persetujuan_perangkat.sql",
    f"{NAMA_PANGGAR}.sql",
]


def _js_untuk(mutasi_sql: str = "") -> str:
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
f"const semua = {repr(PENJAGA_MIGRASI)};\n"
"for (const f of semua) {\n"
"  const sql = fs.readFileSync('/home/user/Resto-Barokah/supabase/migrations/' + f, 'utf-8');\n"
"  try { await db.exec(sql); }\n"
"  catch (e) { console.log('MIG_FAIL ' + f + ':' + e.message.split('\\n')[0]); process.exit(2); }\n"
"}\n"
"await db.exec(`insert into public.penyewa (id, nama, slug) values\n"
"  ('11111111-1111-1111-1111-111111111111', 'penyewa-uji', 'penyewa-uji-1'),\n"
"  ('99999999-9999-9999-9999-999999999999', 'penyewa-lintas', 'penyewa-lintas-1')\n"
"  on conflict do nothing;\n"
"  insert into auth.users (id, email) values\n"
"  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'kasir-uji@uji.local')\n"
"  on conflict do nothing;\n"
"  insert into public.pengguna (id, penyewa_id, nama, email, peran, aktif) values\n"
"  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',\n"
"   '11111111-1111-1111-1111-111111111111', 'Kasir Uji',\n"
"   'kasir-uji@uji.local', 'kasir', true) on conflict do nothing;\n"
"  insert into public.kredensial_pin (pengguna_id, pin_hash) values\n"
"  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '$tiruan$10$abc')\n"
"  on conflict do nothing;`);\n"
f"{mutasi_sql}"
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
        ringkas = []
        for baris in out.split("\n"):
            if baris.startswith("KONTROL:") or baris.startswith("MIG_FAIL") \
               or baris.startswith("HASIL:") or baris.startswith("error:") \
               or baris.startswith("Error"):
                ringkas.append(baris)
        return "\n".join(ringkas) if ringkas else out[:500]
    finally:
        os.unlink(nama)


def _skrip_uji_full() -> str:
    skrip = ""
    # service_role + tenant A → OK
    skrip += (
"await db.exec(\"select set_config('request.jwt.claim.role','service_role',false)\");\n"
"try {\n"
"  await db.query(\"select public.catat_percobaan_masuk(\"\n"
"    + \"'11111111-1111-1111-1111-111111111111'::uuid, null, null, false, 'kontrol-service-role')\");\n"
"  console.log('KONTROL:SR:OK');\n"
"} catch (e) { console.log('KONTROL:SR:GAGAL:' + e.message.split('\\n')[0]); }\n"
    )
    # authenticated + tenant A cocok → OK
    skrip += (
"await db.exec(\"select set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',false)\");\n"
"await db.exec(\"select set_config('request.jwt.claim.role','authenticated',false)\");\n"
"try {\n"
"  await db.query(\"select public.catat_percobaan_masuk(\"\n"
"    + \"'11111111-1111-1111-1111-111111111111'::uuid, null, null, true, 'kontrol-auth-cocok')\");\n"
"  console.log('KONTROL:AUTH_COCOK:OK');\n"
"} catch (e) { console.log('KONTROL:AUTH_COCOK:GAGAL:' + e.message.split('\\n')[0]); }\n"
    )
    # authenticated + tenant B (lintas) → GAGAL
    skrip += (
"await db.exec(\"select set_config('request.jwt.claim.role','authenticated',false)\");\n"
"try {\n"
"  await db.query(\"select public.catat_percobaan_masuk(\"\n"
"    + \"'99999999-9999-9999-9999-999999999999'::uuid, null, null, false, 'kontrol-auth-lintas')\");\n"
"  console.log('KONTROL:AUTH_LINTAS:OK');\n"
"} catch (e) { console.log('KONTROL:AUTH_LINTAS:GAGAL:' + e.message.split('\\n')[0]); }\n"
    )
    # authenticated + tenant null → GAGAL
    skrip += (
"await db.exec(\"select set_config('request.jwt.claim.role','authenticated',false)\");\n"
"try {\n"
"  await db.query(\"select public.catat_percobaan_masuk(\"\n"
"    + \"null::uuid, null, null, false, 'kontrol-auth-null')\");\n"
"  console.log('KONTROL:AUTH_NULL:OK');\n"
"} catch (e) { console.log('KONTROL:AUTH_NULL:GAGAL:' + e.message.split('\\n')[0]); }\n"
    )
    return skrip


def main(argv):
    mode_uji_diri = "--uji-diri" in argv
    print("=" * 72)
    print(f"UJI MUTASI {NAMA_PANGGAR} (N F-05 audit 2026-09-24)")
    print("=" * 72)

    print("\nKontrol positif (pagar lengkap):")
    out = _panggil_node(_js_untuk("") + _skrip_uji_full())
    print("  " + "\n  ".join(out.split("\n")))

    if "KONTROL:SR:OK" not in out or "KONTROL:AUTH_COCOK:OK" not in out \
       or "KONTROL:AUTH_LINTAS:GAGAL" not in out \
       or "KONTROL:AUTH_NULL:GAGAL" not in out:
        print("\nKONTROL POSITIF GAGAL — pagar 0059 tidak berperilaku benar.")
        return 1

    if mode_uji_diri:
        print("\nMode --uji-diri: kontrol positif saja sudah cukup.")
        return 0

    # Mutasi 1: cek lintas tenant dihilangkan
    print("\nMutasi 1: cek p_penyewa_id <> v_penyewa_saya DIHILANGKAN")
    out = _panggil_node(_js_untuk(
"await db.exec(`create or replace function public.catat_percobaan_masuk(\n"
"  p_penyewa_id uuid, p_pengguna_id uuid default null,\n"
"  p_perangkat_id uuid default null, p_berhasil boolean default false,\n"
"  p_sebab text default null) returns void language plpgsql\n"
"  security definer set search_path = public, pg_temp as $$\n"
"declare v_role text := current_setting('request.jwt.claim.role', true);\n"
"begin\n"
"  if v_role = 'service_role' then\n"
"    insert into public.percobaan_masuk (penyewa_id, pengguna_id, perangkat_id, berhasil, sebab, waktu)\n"
"      values (p_penyewa_id, p_pengguna_id, p_perangkat_id, p_berhasil, p_sebab, now());\n"
"    return;\n"
"  end if;\n"
"  if p_penyewa_id is null then raise exception 'p_penyewa_id wajib diisi'; end if;\n"
"  insert into public.percobaan_masuk (penyewa_id, pengguna_id, perangkat_id, berhasil, sebab, waktu)\n"
"    values (p_penyewa_id, p_pengguna_id, p_perangkat_id, p_berhasil, p_sebab, now());\n"
"end $$;`);\n"
    ) + _skrip_uji_full())
    if "KONTROL:AUTH_LINTAS:OK" in out:
        print("  HASIL: MERAH ✓ — lintas tenant lolos saat cek dihapus.")
    else:
        print("  HASIL: HIJAU ✗ — lintas tenant masih ditolak walau cek dihapus.")
        return 1

    # Mutasi 2: cek null dihilangkan
    print("\nMutasi 2: cek p_penyewa_id is null DIHILANGKAN")
    out = _panggil_node(_js_untuk(
"await db.exec(`create or replace function public.catat_percobaan_masuk(\n"
"  p_penyewa_id uuid, p_pengguna_id uuid default null,\n"
"  p_perangkat_id uuid default null, p_berhasil boolean default false,\n"
"  p_sebab text default null) returns void language plpgsql\n"
"  security definer set search_path = public, pg_temp as $$\n"
"declare v_role text := current_setting('request.jwt.claim.role', true);\n"
"declare v_penyewa_saya uuid := public.penyewa_saya();\n"
"begin\n"
"  if v_role = 'service_role' then\n"
"    insert into public.percobaan_masuk (penyewa_id, pengguna_id, perangkat_id, berhasil, sebab, waktu)\n"
"      values (p_penyewa_id, p_pengguna_id, p_perangkat_id, p_berhasil, p_sebab, now());\n"
"    return;\n"
"  end if;\n"
"  if v_penyewa_saya is not null and p_penyewa_id <> v_penyewa_saya then\n"
"    raise exception 'lintas-tenant';\n"
"  end if;\n"
"  insert into public.percobaan_masuk (penyewa_id, pengguna_id, perangkat_id, berhasil, sebab, waktu)\n"
"    values (p_penyewa_id, p_pengguna_id, p_perangkat_id, p_berhasil, p_sebab, now());\n"
"end $$;`);\n"
    ) + _skrip_uji_full())
    if "KONTROL:AUTH_NULL:OK" in out:
        print("  HASIL: MERAH ✓ — null tenant lolos saat cek null dihapus.")
    else:
        print("  HASIL: HIJAU ✗ — null tenant masih ditolak walau cek dihapus.")
        return 1

    # Mutasi 3: bypass total
    print("\nMutasi 3: bypass total (langsung insert tanpa validasi)")
    out = _panggil_node(_js_untuk(
"await db.exec(`create or replace function public.catat_percobaan_masuk(\n"
"  p_penyewa_id uuid, p_pengguna_id uuid default null,\n"
"  p_perangkat_id uuid default null, p_berhasil boolean default false,\n"
"  p_sebab text default null) returns void language plpgsql\n"
"  security definer set search_path = public, pg_temp as $$\n"
"begin\n"
"  insert into public.percobaan_masuk (penyewa_id, pengguna_id, perangkat_id, berhasil, sebab, waktu)\n"
"    values (p_penyewa_id, p_pengguna_id, p_perangkat_id, p_berhasil, p_sebab, now());\n"
"end $$;`);\n"
    ) + _skrip_uji_full())
    if "KONTROL:AUTH_LINTAS:OK" in out and "KONTROL:AUTH_NULL:OK" in out:
        print("  HASIL: MERAH ✓ — bypass: lintas+null tenant keduanya lolos.")
    else:
        print("  HASIL: HIJAU ✗ — bypass tidak membuat lintas/null lolos.")
        return 1

    print("\n" + "=" * 72)
    print("KESIMPULAN: pagar 0059 TANGGUH — semua mutasi terdeteksi (3/3 MERAH).")
    print("=" * 72)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
