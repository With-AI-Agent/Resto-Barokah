#!/usr/bin/env python3
"""Cetak bukti bernomor H-F-07.2. Tidak mengubah dokumen yang diperiksa."""
from pathlib import Path
import subprocess

akar = Path(__file__).resolve().parents[5]
print('Tanggal pemeriksaan: 2026-09-29 (Asia/Jakarta)')
print('HEAD:', subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=akar, text=True).strip())

def kutip(rel, rentang):
    baris = (akar / rel).read_text().splitlines()
    print('\n$ kutip', rel, rentang)
    for awal, akhir in rentang:
        for i in range(awal, akhir + 1):
            print(f'{i}: {baris[i-1]}'.rstrip())

kutip('alat/peta-ui.py', [(36,49), (354,360), (393,399)])
print('\n$ judul M1–M12 dari docs/PRD.md')
for i, l in enumerate((akar / 'docs/PRD.md').read_text().splitlines(), 1):
    if l.startswith('### M') and len(l)>5 and l[5].isdigit():
        print(i, l)
kutip('docs/PRD.md', [(164,171), (201,201)])
kutip('aplikasi/src/lib/aksi.ts', [(243,290), (733,747)])
kutip('aplikasi/src/komponen/TombolAksi.tsx', [(36,70)])
kutip('aplikasi/src/hook/useTiketDapur.ts', [(272,302)])
kutip('docs/SPESIFIKASI_UI.md', [(22,22), (35,39), (62,62), (71,71), (79,95), (158,160)])
kutip('docs/PETA_UI.md', [(34,35), (68,71), (103,104), (108,108), (120,120)])
kutip('supabase/migrations/0067_pengaman_voucher.sql', [(321,333), (365,390)])
kutip('supabase/migrations/0071_tema_merek.sql', [(67,78), (124,136)])
kutip('supabase/migrations/0083_versi_pengaturan_bersamaan.sql', [(281,290), (318,326)])
print('\n$ komponen bersama bernama Keadaan')
for p in sorted((akar / 'aplikasi/src/komponen').glob('Keadaan*.tsx')):
    if '.test.' not in p.name:
        print(p.relative_to(akar))
print('\n$ status T1-31..T1-35')
for i, l in enumerate((akar / 'docs/ROADMAP.md').read_text().splitlines(), 1):
    if any('] T1-'+str(n)+' ' in l for n in range(31,36)):
        print(i, l)
print('\n$ regresi lama dengan artefak lingkup')
for rel in ['docs/uji/AUDIT_RIWAYAT.md','docs/uji/TEMUAN_LUAR_CAKUPAN_REVIEW.md']:
    for i,l in enumerate((akar / rel).read_text().splitlines(),1):
        if any(x in l for x in ['SPESIFIKASI_UI', 'PETA_UI', 'peta-ui.py']):
            print(rel, i, l)
kutip('docs/KEAMANAN.md', [(46,46), (49,49), (53,54), (124,125), (161,162), (186,188), (196,198)])
print('\n$ python3 alat/peta-ui.py --periksa')
subprocess.run(['python3','alat/peta-ui.py','--periksa'],cwd=akar, check=True)
print('\n$ python3 alat/periksa-temuan-audit.py')
subprocess.run(['python3','alat/periksa-temuan-audit.py'],cwd=akar, check=True)
