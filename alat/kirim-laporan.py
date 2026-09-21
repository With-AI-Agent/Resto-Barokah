#!/usr/bin/env python3
"""Kirim SATU laporan ke cabang Arena sendiri, otomatis retry+verifikasi tanpa merge.

Cadangan isi disimpan di .laporan-lokal (diabaikan Git). Tidak mengubah HEAD,
index atau working tree: aman untuk beberapa penulis yang berbagi checkout.
Tidak menjamin akses/jaringan/izin tersedia; gagal-tertutup tanpa klaim selesai.
"""
import argparse
import json
import os
from pathlib import Path
import stat
import uuid

from kirim_laporan import Terblokir, identitas_repo, jalur_laporan, kirim, teks


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--jenis', required=True, choices=['audit', 'review-pr'])
    ap.add_argument('--laporan', help='berkas UTF-8 yang SUDAH divalidasi kontraknya')
    ap.add_argument('--sumber', required=True, help='cabang sumber paket; dilarang menjadi tujuan')
    ap.add_argument('--siapkan', action='store_true', help='alokasikan nama draf unik lebih dulu')
    a = ap.parse_args()
    try:
        akar = Path(teks(Path.cwd(), 'rev-parse', '--show-toplevel'))
        spool = akar / '.laporan-lokal'
        repo, cabang = identitas_repo(akar)
        if cabang == a.sumber:
            raise Terblokir('Cabang pemeriksa sama dengan pembangun; gunakan sesi pemeriksa, jangan push di sini.')
        spool.mkdir(mode=0o700, exist_ok=True)
        if spool.is_symlink():
            raise Terblokir('Folder cadangan tidak boleh symlink.')
        if a.siapkan:
            nama = spool / f'LAPORAN_{a.jenis.replace("-", "_")}_{uuid.uuid4().hex}.md'
            with nama.open('x', encoding='utf-8'):
                pass
            print(nama)
            return 0
        if not a.laporan:
            ap.error('--laporan diperlukan kecuali --siapkan')
        fd = os.open(a.laporan, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
        with os.fdopen(fd, 'rb') as f:
            sebelum = os.fstat(f.fileno())
            if not stat.S_ISREG(sebelum.st_mode):
                raise Terblokir('Sumber bukan berkas biasa.')
            isi = f.read(2 * 1024 * 1024 + 1)
            sesudah = os.fstat(f.fileno())
            if (sebelum.st_size, sebelum.st_mtime_ns, sebelum.st_ctime_ns) != (sesudah.st_size, sesudah.st_mtime_ns, sesudah.st_ctime_ns):
                raise Terblokir('Draf berubah saat dibaca; gunakan draf unik, jangan kirim snapshot campuran.')
        path = jalur_laporan(a.jenis, Path(a.laporan).name, isi)
        backup = spool / Path(path).name
        try:
            with backup.open('xb') as f:
                f.write(isi)
                f.flush()
                os.fsync(f.fileno())
        except FileExistsError:
            if backup.is_symlink() or backup.read_bytes() != isi:
                raise Terblokir('Cadangan berbeda; jangan menimpa.')
        print(f'Snapshot laporan tersimpan: {backup}', flush=True)
        hasil = kirim(f'https://github.com/{repo}.git', cabang, a.jenis, Path(a.laporan).name, isi,
                      penulis=(teks(akar, 'config', 'user.name'), teks(akar, 'config', 'user.email')),
                      dasar_baru=teks(akar, 'rev-parse', 'HEAD'))
        hasil['repo'] = repo
        print(json.dumps(hasil, ensure_ascii=False, indent=2))
        print('HEAD/index lokal sengaja tidak digeser; jangan git add/pull/merge ulang laporan ini.')
        return 0
    except (Terblokir, OSError) as e:
        print(f'TERBLOKIR — pengiriman BELUM TERVERIFIKASI: {e}')
        print('Jangan force/rebase/merge atau meminta token di chat. Simpan laporan untuk jalur pemulihan integrator.')
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
