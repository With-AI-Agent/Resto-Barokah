#!/usr/bin/env python3
"""Bukti SQL lokal ulangan H-F-07.2; npm ci --prefix alat lebih dahulu.
Kontrol negatif mencabut EXECUTE di transaksi uji (bukan mengubah kode atau produksi).
"""
from pathlib import Path
import subprocess
import tempfile

akar = Path(__file__).resolve().parents[5]
bukti = Path('docs/uji/pemeriksaan/PMB-1/bukti')

def jalankan(berkas, kode):
    cmd = ['node', 'alat/uji-sql.mjs', str(berkas)]
    p = subprocess.run(cmd, cwd=akar, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print('$ ' + ' '.join(cmd) + '\n' + p.stdout.rstrip() + '\nEXIT: ' + str(p.returncode), flush=True)
    assert p.returncode == kode, f'Kode harus {kode}, bukan {p.returncode}'
    return p.stdout

jalankan('supabase/tes/kasir_voucher.sql', 0)
jalankan(bukti / 'H-F-06-admin-lintas-cabang.sql', 0)
# Probe hakim yang benar harus merah ketika artefaknya tak bisa dipanggil peran authenticated.
with tempfile.TemporaryDirectory(prefix='h-f-07-ulang-sql-') as tmp:
    sql = Path(tmp) / 'kontrol-tolak.sql'
    sql.write_text('revoke execute on function public.buat_kode_perangkat(uuid, text, text, text[]) from public, authenticated;\n' + (akar / bukti / 'H-F-06-admin-lintas-cabang.sql').read_text())
    hasil = jalankan(sql, 1)
    assert 'permission denied for function buat_kode_perangkat' in hasil
    # Bukti cacat lama tetap tidak peka pada pencabutan yang sama; disimpan sebagai barang bukti.
    sql.write_text('revoke execute on function public.buat_kode_perangkat(uuid, text, text, text[]) from public, authenticated;\n' + (akar / bukti / 'F-06-admin-lintas-cabang.sql').read_text())
    jalankan(sql, 0)
print('SELESAI: voucher PIN salah/benar diuji; probe pengganti G-04 peka, probe lama tidak peka.')
