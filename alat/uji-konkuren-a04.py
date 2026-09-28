#!/usr/bin/env python3
"""A-F04: regresi deadlock multi-baris pada pesanan_item.

Dua transaksi mengubah item dari dua pesanan dalam urutan silang. Kontrol wajib
keduanya commit tanpa 40P01; mutasi yang melepas BEFORE STATEMENT advisory lock
wajib menghasilkan deadlock nyata. Semua skema/DB sementara, crypto tiruan.
"""
from __future__ import annotations

import importlib.util
from pathlib import Path
import threading
import uuid

import psycopg

SPEC = importlib.util.spec_from_file_location("uji_konkuren", Path(__file__).with_name("uji-konkuren.py"))
LOADER = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(LOADER)

AKAR = Path(__file__).resolve().parent.parent
TENANT = "11111111-1111-1111-1111-111111111111"
CABANG = "a1a1a1a1-0000-0000-0000-000000000001"
PELAKU = "90000000-0000-0000-0000-000000000004"
MENU = "beef0000-0000-0000-0000-000000000001"
MUTASI = "drop trigger rincian_kunci_global_sebelum on public.pesanan_item;"


def siapkan(uri: str) -> tuple[str, str, str, str]:
    ids = [str(uuid.uuid4()) for _ in range(4)]
    o1, o2, i1, i2 = ids
    with psycopg.connect(uri, autocommit=True) as c:
        c.execute(
            """insert into public.pesanan
               (id,penyewa_id,cabang_id,nomor,kunci_idempoten)
               values (%s,%s,%s,7201,'a04-pesanan-1'),
                      (%s,%s,%s,7202,'a04-pesanan-2')""",
            (o1, TENANT, CABANG, o2, TENANT, CABANG),
        )
        c.execute(
            """insert into public.pesanan_item
               (id,pesanan_id,menu_item_id,nama_saat_itu,harga_saat_itu,qty)
               values (%s,%s,%s,'Nasi Goreng',27000,1),
                      (%s,%s,%s,'Nasi Goreng',27000,1)""",
            (i1, o1, MENU, i2, o2, MENU),
        )
    return o1, o2, i1, i2


def balapan(uri: str, ids: tuple[str, str, str, str]) -> dict[str, str]:
    _, _, item1, item2 = ids
    hasil: dict[str, str] = {}
    siap = [threading.Event(), threading.Event()]
    lanjut = threading.Event()

    def pekerja(n: int, pertama: str, kedua: str) -> None:
        c = psycopg.connect(uri)
        c.execute("select uji.klaim(%s)", (PELAKU,))
        c.execute("set local role authenticated")
        c.execute("set local statement_timeout = '6s'")
        hasil[f"{n}pid"] = str(c.info.backend_pid)
        try:
            c.execute("update public.pesanan_item set qty = qty + 1 where id = %s", (pertama,))
            hasil[f"{n}first"] = "done"
            siap[n].set()
            lanjut.wait(8)
            c.execute("update public.pesanan_item set qty = qty + 1 where id = %s", (kedua,))
            hasil[f"{n}second"] = "done"
            c.commit()
            hasil[str(n)] = "commit"
        except Exception as e:  # noqa: BLE001 — SQLSTATE dicatat untuk klasifikasi
            hasil[str(n)] = f"{type(e).__name__}: {e}"
            c.rollback()
        finally:
            c.close()

    a = threading.Thread(target=pekerja, args=(0, item1, item2))
    b = threading.Thread(target=pekerja, args=(1, item2, item1))
    a.start()
    b.start()
    # Salah satu transaksi kontrol boleh tertahan di kunci global sebelum first;
    # cukup beri waktu agar yang pertama berjalan, lalu lepaskan langkah kedua.
    siap[0].wait(3)
    siap[1].wait(3)
    lanjut.set()
    a.join(12)
    b.join(12)
    if a.is_alive() or b.is_alive():
        hasil["runner"] = "TIMEOUT: utas masih hidup setelah 12 detik"
    return hasil


def jalankan(mutasi: bool) -> tuple[bool, str]:
    LOADER.pasang_tiruan_pgcrypto()
    srv = LOADER.server_baru("konkuren-a04")
    try:
        LOADER.muat_skema(srv.get_uri(), MUTASI if mutasi else None)
        ids = siapkan(srv.get_uri())
        hasil = balapan(srv.get_uri(), ids)
        pesan = repr(hasil)
        if "runner" in hasil:
            return False, pesan
        if mutasi:
            bukti = sum("DeadlockDetected" in hasil.get(str(i), "") for i in (0, 1))
            return bukti == 1, ("mutasi menghasilkan tepat satu 40P01: " + pesan)
        lulus = hasil.get("0") == "commit" and hasil.get("1") == "commit"
        return lulus, ("kontrol dua transaksi commit tanpa deadlock: " + pesan)
    finally:
        srv.cleanup()


def main() -> int:
    kontrol, pesan_kontrol = jalankan(False)
    mutan, pesan_mutan = jalankan(True)
    print(f"{'OK' if kontrol else 'GAGAL'} kontrol: {pesan_kontrol}")
    print(f"{'OK' if mutan else 'GAGAL'} kalibrasi mutasi tanpa kunci: {pesan_mutan}")
    ok = kontrol and mutan
    print(f"HASIL: {'LOLOS' if ok else 'GAGAL'} — kontrol bersih dan mutasi deadlock terkalibrasi.")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
