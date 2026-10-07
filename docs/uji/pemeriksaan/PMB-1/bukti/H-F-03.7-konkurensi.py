#!/usr/bin/env python3
"""Reproduksi batas pendaftaran kasir 0097 dengan dua transaksi PostgreSQL nyata.

Ketergantungan: `python3 -m pip install pgserver 'psycopg[binary]'`.
Jalankan dari akar repo: `python3 docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.7-konkurensi.py`.
Semua basis data berjalan di pgserver sementara dan dihapus saat proses selesai.
Tidak mengubah migrasi, data, atau layanan produksi.

Dua voucher awal membuat hitungan mencapai 2 dari batas 3. Pemicu uji sementara
pada INSERT voucher memakai sequence sebagai penghalang: kedua transaksi harus
tiba setelah pemeriksaan batas dan sebelum salah satunya boleh INSERT/COMMIT.
Jika pagar tidak mengunci hitung-dan-terbit, keduanya melihat 2 lalu terbit,
sehingga hasilnya 4. Pemicu/sequence hanya hidup di basis data sementara.
"""
from __future__ import annotations

import importlib.util
import pathlib
import sys
import threading

import psycopg

AKAR = pathlib.Path(__file__).resolve().parents[5]
PEMUAT = AKAR / "alat" / "uji-konkuren.py"
SPEC = importlib.util.spec_from_file_location("pmb_uji_konkuren", PEMUAT)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"tidak dapat memuat {PEMUAT}")
MOD = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MOD)

PENYEWA = "11111111-1111-1111-1111-111111111111"
KASIR = "90000000-0000-0000-0000-000000000004"
KAMPANYE = "d3000000-0000-0000-0000-000000000701"


def daftar(uri: str, nama: str, telepon: str, ip: str) -> dict:
    """Panggil RPC asli dari kursi kasir authenticated, dalam transaksi sendiri."""
    with psycopg.connect(uri) as conn:
        conn.execute("set local statement_timeout = '15s'")
        conn.execute("select uji.klaim(%s)", (KASIR,))
        conn.execute("set local role authenticated")
        hasil = conn.execute(
            """select public.daftar_voucher(
                 %s, %s, %s, null, %s, null, true, 'kasir', 'hf037-device', %s)""",
            (PENYEWA, KAMPANYE, nama, telepon, ip),
        ).fetchone()[0]
        conn.commit()
        return hasil


def main() -> int:
    MOD.pasang_tiruan_pgcrypto()
    server = MOD.server_baru("konkuren-h-f-03-7-voucher")
    try:
        uri = server.get_uri()
        print("PostgreSQL sementara:", uri.split("@")[-1])
        print("Memuat semua migrasi dan alat/sql/data-uji.sql.")
        MOD.muat_skema(uri)
        with psycopg.connect(uri, autocommit=True) as conn:
            versi = conn.execute("select current_setting('server_version')").fetchone()[0]
        print("Versi PostgreSQL:", versi)

        with psycopg.connect(uri, autocommit=True) as conn:
            conn.execute(
                """insert into public.kampanye_voucher
                   (id, penyewa_id, nama, kode_kampanye, jenis, nilai, min_belanja,
                    mulai, selesai, kuota, aktif)
                   values (%s, %s, 'H-F-03.7 race', 'HF037RACE', 'nominal', 10000, 0,
                           now()-interval '1 hour', now()+interval '1 day', 20, true)""",
                (KAMPANYE, PENYEWA),
            )

        for nomor in (1, 2):
            hasil = daftar(
                uri, f"Base {nomor}", f"08170000000{nomor}", f"10.7.7.{nomor}"
            )
            print(f"pendaftaran awal {nomor}:", hasil.get("kode"), hasil.get("berhasil"))

        # Pemicu sementara menahan kedua INSERT voucher setelah fungsi bisnisnya
        # melewati pemeriksaan cap. Sequence dapat dilihat lintas transaksi tanpa
        # membuat baris penghitung transaksional yang menyerialkan kedua pemanggil.
        with psycopg.connect(uri, autocommit=True) as conn:
            conn.execute("create sequence public.hf037_race_barrier_seq start 1")
            conn.execute(
                """create function public.hf037_voucher_barrier()
                   returns trigger language plpgsql as $$
                   declare n bigint; latest bigint; i integer;
                   begin
                     if new.kampanye_id = 'd3000000-0000-0000-0000-000000000701' then
                       n := nextval('public.hf037_race_barrier_seq');
                       if n = 1 then
                         for i in 1..1000 loop
                           select last_value into latest from public.hf037_race_barrier_seq;
                           exit when latest >= 2;
                           perform pg_sleep(0.01);
                         end loop;
                         if latest < 2 then
                           raise exception 'HARNESS_BARRIER_TIMEOUT: peserta kedua tidak mencapai INSERT voucher';
                         end if;
                       end if;
                     end if;
                     return new;
                   end $$"""
            )
            conn.execute(
                """create trigger hf037_voucher_barrier before insert on public.voucher
                   for each row execute function public.hf037_voucher_barrier()"""
            )

        awal = threading.Barrier(3)
        hasil_bersama: dict[str, dict] = {}
        galat: list[tuple[str, str]] = []

        def peserta(nama: str, telepon: str, ip: str) -> None:
            try:
                awal.wait(timeout=10)
                hasil_bersama[nama] = daftar(uri, nama, telepon, ip)
            except Exception as exc:  # catat galat koneksi/RPC, jangan sembunyikan
                galat.append((nama, repr(exc)))

        threads = [
            threading.Thread(target=peserta, args=("Race A", "081700000003", "10.7.7.3")),
            threading.Thread(target=peserta, args=("Race B", "081700000004", "10.7.7.4")),
        ]
        for thread in threads:
            thread.start()
        awal.wait(timeout=10)
        for thread in threads:
            thread.join(30)
        if any(thread.is_alive() for thread in threads):
            raise RuntimeError("peserta konkuren menggantung")

        print("respons konkuren:", {
            nama: (jawab.get("kode"), jawab.get("berhasil"))
            for nama, jawab in hasil_bersama.items()
        })
        print("galat peserta:", galat)
        with psycopg.connect(uri, autocommit=True) as conn:
            jumlah = conn.execute(
                """select count(*) from public.voucher vo
                   join public.pelanggan pl on pl.id = vo.pelanggan_id
                   where vo.kampanye_id = %s and pl.didaftarkan_oleh = %s""",
                (KAMPANYE, KASIR),
            ).fetchone()[0]
            rincian = conn.execute(
                """select pl.nama, vo.status from public.voucher vo
                   join public.pelanggan pl on pl.id = vo.pelanggan_id
                   where vo.kampanye_id = %s and pl.didaftarkan_oleh = %s
                   order by pl.nama""",
                (KAMPANYE, KASIR),
            ).fetchall()
        print("jumlah akhir voucher kasir/kampanye:", jumlah)
        print("rincian:", rincian)
        if jumlah > 3:
            print("TERBUKTI: dua transaksi serentak melewati batas bawaan 3.")
            return 0
        print("TIDAK TEREPRODUKSI: batas tidak terlampaui dalam run ini.")
        return 1
    finally:
        server.cleanup()


if __name__ == "__main__":
    sys.exit(main())
