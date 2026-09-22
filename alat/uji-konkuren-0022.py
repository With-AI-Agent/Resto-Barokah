#!/usr/bin/env python3
"""T-025(a), dua koneksi PostgreSQL: bayar ↔ edit/void, kedua urutan commit.

Memakai loader skema pgserver yang sama dengan uji-konkuren.py (bukan bukti
Supabase produksi; crypto tiruan). Penantian dibuktikan pg_blocking_pids,
bukan menebak dari sleep. Timeout/setup/deadlock tidak dihitung sebagai
kalibrasi berhasil: mutasi wajib menghasilkan KOMIT yang melanggar kontrak.
"""
from __future__ import annotations

import importlib.util
from pathlib import Path
import threading
import time

import psycopg

spec = importlib.util.spec_from_file_location('konkuren_lama', Path(__file__).with_name('uji-konkuren.py'))
loader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(loader)

ORDER = 'b5220000-0000-0000-0000-000000000001'
ITEM = 'b5220000-0000-0000-0000-000000000101'
TENANT = '11111111-1111-1111-1111-111111111111'
CASHIER = '90000000-0000-0000-0000-000000000004'


def klaim(c):
    c.execute("select uji.klaim(%s)", (CASHIER,))
    c.execute("set local role authenticated")
    c.execute("set local statement_timeout='10s'")


def bayar(c, jumlah):
    c.execute("""insert into public.pembayaran(pesanan_id,metode_id,jumlah,diterima,kunci_idempoten)
      select %s,id,%s,%s,'race-bayar' from public.metode_bayar where penyewa_id=%s and nama='Tunai'""",
              (ORDER, jumlah, jumlah, TENANT))


def ubah(c, jenis):
    if jenis == 'catatan':
        c.execute("update public.pesanan_item set catatan='baru' where id=%s", (ITEM,))
    elif jenis == 'qty':
        c.execute("update public.pesanan_item set qty=1 where id=%s", (ITEM,))
    else:
        c.execute("""insert into public.pembatalan(pesanan_id,pesanan_item_id,tahap,alasan)
          values(%s,%s,'sebelum_dapur','uji balapan')""", (ORDER, ITEM))


def skenario(uri, jenis, bayar_dulu):
    """Return evidence; assertion failures alone are not automatically mutation proof."""
    with psycopg.connect(uri, autocommit=True) as c:
        c.execute("""insert into public.pesanan(id,penyewa_id,cabang_id,nomor,kunci_idempoten)
          values(%s,%s,'a1a1a1a1-0000-0000-0000-000000000001',2222,'race-0022')""", (ORDER, TENANT))
        c.execute("""insert into public.pesanan_item(id,pesanan_id,menu_item_id,nama_saat_itu,harga_saat_itu,qty)
          values(%s,%s,'beef0000-0000-0000-0000-000000000001','Nasi Goreng',27000,2)""", (ITEM, ORDER))
    t1 = psycopg.connect(uri)
    t2 = psycopg.connect(uri)
    siap = threading.Event()
    hasil = {}
    worker = None
    try:
        klaim(t1)
        if bayar_dulu:
            bayar(t1, 1)  # sebagian: penjaga status lunas tidak membantu
        else:
            ubah(t1, jenis)

        def kedua():
            try:
                klaim(t2)
                hasil['pid'] = t2.info.backend_pid
                siap.set()
                if bayar_dulu:
                    ubah(t2, jenis)
                else:
                    bayar(t2, 62100)  # total SEBELUM qty/void, wajib ditolak setelah T1
                t2.commit()
                hasil['commit'] = True
            except psycopg.Error as e:
                t2.rollback()
                hasil['error'] = str(e)
                hasil['sqlstate'] = e.sqlstate
            finally:
                siap.set()

        worker = threading.Thread(target=kedua)
        worker.start()
        if not siap.wait(5) or 'pid' not in hasil:
            raise RuntimeError(f'T2 gagal mulai: {hasil}')
        terkunci = False
        with psycopg.connect(uri, autocommit=True) as observer:
            batas = time.monotonic() + 5
            while time.monotonic() < batas and worker.is_alive():
                blockers = observer.execute('select pg_blocking_pids(%s)', (hasil['pid'],)).fetchone()[0]
                if t1.info.backend_pid in blockers:
                    terkunci = True
                    break
                time.sleep(.02)
        t1.commit()
        worker.join(12)
        if worker.is_alive():
            raise RuntimeError('T2 menggantung, bukan bukti pagar')
        if 'sqlstate' in hasil and hasil['sqlstate'] != 'P0001':
            raise RuntimeError(f'galat infrastruktur/deadlock bukan bukti: {hasil}')
        with psycopg.connect(uri, autocommit=True) as c:
            row = c.execute("""select p.total,p.status,i.qty,i.catatan,i.status,
              (select count(*) from public.pembatalan where pesanan_id=p.id),
              (select coalesce(sum(jumlah),0) from public.pembayaran where pesanan_id=p.id)
              from public.pesanan p join public.pesanan_item i on i.pesanan_id=p.id where p.id=%s""", (ORDER,)).fetchone()
        hasil.update(row=row, terkunci=terkunci)
        return hasil
    finally:
        t1.rollback()
        if worker and worker.is_alive():
            t2.cancel()
            worker.join(12)
        t1.close()
        t2.close()


def validasi(hasil, jenis, bayar_dulu):
    if not hasil['terkunci']:
        return False
    row = hasil['row']
    if bayar_dulu:
        return ('BY-201:' in hasil.get('error', '') and not hasil.get('commit')
                and row == (62100, 'draf', 2, None, 'baru', 0, 1))
    sebab = 'melebihi total pesanan' if jenis == 'qty' else 'sudah dibatalkan'
    return (not hasil.get('commit') and sebab in hasil.get('error', '')
            and row[0] == (31050 if jenis == 'qty' else 0)
            and row[5] == (0 if jenis == 'qty' else 1) and row[6] == 0)


def main():
    loader.pasang_tiruan_pgcrypto()
    asli = (loader.AKAR / 'supabase/migrations/0022_beku_setelah_bayar.sql').read_text()
    # Satu baris yang hilang: hanya definisi fungsi BEFORE (CREATE OR REPLACE).
    fungsi = asli[asli.index('create function'):asli.index('revoke all')]
    tanpa_kunci = fungsi.replace('create function', 'create or replace function', 1).replace(' for update;', ';')
    # 0024 adalah lapisan baru untuk data-modifying CTE. Pada mutasi yang
    # khusus menguji pagar BEFORE 0022, lapisan itu juga dilepas agar bukti
    # benar-benar mengkalibrasi 0022, bukan tertahan oleh obat yang lebih baru.
    tanpa_pagar = '''drop trigger aaa_item_beku_setelah_bayar on public.pesanan_item;
      drop trigger aaa_pembatalan_beku_setelah_bayar on public.pembatalan;
      drop trigger zzz_pesanan_beku_setelah_bayar on public.pesanan;
      drop trigger item_beku_akhir_satu_pernyataan on public.pesanan_item;
      drop trigger pembatalan_beku_akhir_satu_pernyataan on public.pembatalan;
      drop trigger pesanan_beku_akhir_satu_pernyataan on public.pesanan;'''
    kasus = [(f'utuh bayar→{j}', j, True, None) for j in ('catatan', 'qty', 'void')]
    kasus += [(f'utuh {j}→bayar', j, False, None) for j in ('qty', 'void')]
    kasus += [('mutasi kunci BEFORE hilang', 'catatan', True, tanpa_kunci),
              ('mutasi pagar void hilang', 'void', True, tanpa_pagar)]
    gagal = 0
    for nama, jenis, bayar_dulu, mutasi in kasus:
        srv = loader.server_baru('konkuren-0022')
        try:
            loader.muat_skema(srv.get_uri(), mutasi)
            hasil = skenario(srv.get_uri(), jenis, bayar_dulu)
            if not mutasi:
                ok = validasi(hasil, jenis, bayar_dulu)
            else:
                # TUNTUT bukti pelanggaran tersimpan, bukan sekadar exception/timeout.
                row = hasil['row']
                ok = (hasil.get('commit') is True and row[6] == 1 and
                      (row[3] == 'baru' if jenis == 'catatan' else row[5] == 1 and row[0] == 0))
            print(f"{'OK' if ok else 'GAGAL'} {nama}: {hasil}", flush=True)
            gagal += not ok
        finally:
            srv.cleanup()
    print(f'HASIL: {"LOLOS" if not gagal else "GAGAL"} — 5 kontrol dua arah + 2 mutasi pelanggaran nyata; {gagal} tidak sesuai.')
    return int(bool(gagal))


if __name__ == '__main__':
    raise SystemExit(main())
