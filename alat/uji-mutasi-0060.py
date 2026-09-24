#!/usr/bin/env python3
"""
Uji mutasi pagar pembayaran_hanya_rpc (M F-01 audit 2026-09-24)
3 mutasi pada tabel terisolasi `pembayaran_iso`:
  1. Drop trigger.
  2. Badan diganti tidak raise.
  3. ALTER TABLE ... DISABLE TRIGGER USER.
"""
from __future__ import annotations
import os, subprocess, sys, tempfile
from pathlib import Path

NAMA_PANGGAR = "0060_pembayaran_hanya_rpc"


def _js_untuk(mutasi_sql: str = "") -> str:
    return (
"import { PGlite } from '@electric-sql/pglite';\n"
"const db = await new PGlite();\n"
"await db.exec(`create role anon nologin;\n"
"  create role authenticated nologin;\n"
"  create role service_role nologin;\n"
"  create table public.pembayaran_iso (\n"
"    id uuid primary key default gen_random_uuid(),\n"
"    penyewa_id uuid, pesanan_id uuid, metode text,\n"
"    jumlah integer, dicatat_oleh uuid, waktu timestamptz default now()\n"
"  );\n"
"  create or replace function public.cegah_pembayaran_langsung()\n"
"  returns trigger language plpgsql as $$\n"
"  begin\n"
"    if current_user = session_user then\n"
"      raise exception using\n"
"        errcode = 'insufficient_privilege',\n"
"        message = 'INSERT langsung ke public.pembayaran ditolak — gunakan RPC bayar_pesanan (T5-02).';\n"
"    end if;\n"
"    return new;\n"
"  end $$;\n"
"  create trigger aa_pembayaran_cegah_insert_langsung\n"
"    before insert on public.pembayaran_iso\n"
"    for each row execute function public.cegah_pembayaran_langsung();`);\n"
f"{mutasi_sql}"
    )


def _panggil_node(perintah: str) -> str:
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".mjs", delete=False,
        dir=Path(__file__).resolve().parent
    ) as f:
        f.write(perintah); nama = f.name
    try:
        p = subprocess.run(["node", nama], capture_output=True, text=True,
                            cwd=Path(__file__).resolve().parent)
        out = (p.stdout or "") + (p.stderr or "")
        ringkas = []
        for b in out.split("\n"):
            if b.startswith("KONTROL:") or b.startswith("HASIL:") or b.startswith("error:"):
                ringkas.append(b)
        return "\n".join(ringkas) if ringkas else out[:500]
    finally:
        os.unlink(nama)


def _uji_insert_langsung() -> str:
    return (
"try {\n"
"  await db.exec('set local role authenticated');\n"
"  await db.exec(\"insert into public.pembayaran_iso (penyewa_id, pesanan_id, metode, jumlah) values ('11111111-1111-1111-1111-111111111111'::uuid, '11111111-1111-1111-1111-111111111112'::uuid, 'tunai', 10000)\");\n"
"  console.log('KONTROL:INSERT:OK');\n"
"  await db.exec('reset role');\n"
"} catch (e) {\n"
"  console.log('KONTROL:INSERT:GAGAL:' + e.message.split('\\n')[0]);\n"
"  try { await db.exec('reset role'); } catch(_){}\n"
"}\n"
    )


def main(argv):
    mode_uji_diri = "--uji-diri" in argv
    print("=" * 72)
    print(f"UJI MUTASI {NAMA_PANGGAR} (M F-01 audit 2026-09-24)")
    print("=" * 72)

    print("\nKontrol positif:")
    out = _panggil_node(_js_untuk("") + _uji_insert_langsung())
    print("  " + "\n  ".join(out.split("\n")))
    if "KONTROL:INSERT:GAGAL" not in out:
        print("KONTROL POSITIF GAGAL"); return 1
    if mode_uji_diri:
        print("\n--uji-diri: kontrol positif cukup."); return 0

    print("\nMutasi 1: trigger DIHAPUS")
    out = _panggil_node(_js_untuk(
"await db.exec('drop trigger aa_pembayaran_cegah_insert_langsung on public.pembayaran_iso');\n"
    ) + _uji_insert_langsung())
    if "KONTROL:INSERT:OK" in out: print("  HASIL: MERAH ✓")
    else: print("  HASIL: HIJAU ✗"); return 1

    print("\nMutasi 2: badan diganti return new saja")
    out = _panggil_node(_js_untuk(
"await db.exec(`create or replace function public.cegah_pembayaran_langsung()\n"
"  returns trigger language plpgsql as $$ begin return new; end $$;`);\n"
"await db.exec('drop trigger aa_pembayaran_cegah_insert_langsung on public.pembayaran_iso');\n"
"await db.exec(`create trigger aa_pembayaran_cegah_insert_langsung\n"
"  before insert on public.pembayaran_iso\n"
"  for each row execute function public.cegah_pembayaran_langsung();`);\n"
    ) + _uji_insert_langsung())
    if "KONTROL:INSERT:OK" in out: print("  HASIL: MERAH ✓")
    else: print("  HASIL: HIJAU ✗"); return 1

    print("\nMutasi 3: ALTER TABLE ... DISABLE TRIGGER USER")
    out = _panggil_node(_js_untuk(
"await db.exec('alter table public.pembayaran_iso disable trigger user');\n"
    ) + _uji_insert_langsung())
    if "KONTROL:INSERT:OK" in out: print("  HASIL: MERAH ✓")
    else: print("  HASIL: HIJAU ✗"); return 1

    print("\nKESIMPULAN: pagar 0060 TANGGUH — 3/3 MERAH."); return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
