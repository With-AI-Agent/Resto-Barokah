"""Baca artefak terkait F-11 saja; tidak membaca bahan/kunci kalibrasi."""
from pathlib import Path
import re
import subprocess

akar = Path(__file__).resolve().parents[5]

def kutip(nama, nomor):
    isi = (akar / nama).read_text().splitlines()
    for n in nomor:
        print(f'{nama}:{n}: {isi[n-1]}')

print('BASELINE', subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=akar, text=True).strip())
print('\n1. Dua kontrak jawaban yang sama-sama mengikat')
kutip('docs/DECISIONS_LOG.md', [23, 26, 470, 474])
kutip('docs/TECH_SPEC.md', [262, 263])
kutip('supabase/migrations/0018_perangkat_terdaftar.sql', [356, 363])
print('\n2. Janji daftar non-tunai vs pintu komponen')
kutip('docs/DECISIONS_LOG.md', [273])
kutip('aplikasi/src/layar/kasir/TutupKas.tsx', [38, 48, 287, 290, 315])
kutip('aplikasi/src/layar/kasir/LayarKasir.tsx', list(range(869, 881)))
for nama in ['aplikasi/src/layar/kasir/TutupKas.tsx', 'supabase/migrations/0039_bayar_pesanan.sql']:
    hits = [(n, l) for n, l in enumerate((akar/nama).read_text().splitlines(), 1)
            if re.search(r'referensi|non.?tunai|qris', l, re.I)]
    print(nama, 'jumlah kecocokan', len(hits))
    for n,l in hits: print(f'  {n}: {l}')
# Kontrol negatif: pembanding penyimpanan memang punya referensi, bukan regex buta.
assert 'p_referensi' in (akar/'supabase/migrations/0039_bayar_pesanan.sql').read_text()
assert re.search(r'referensi|non.?tunai|qris', 'Nomor referensi QRIS', re.I)
print('\n3. Provenance angka riset')
kutip('docs/DECISIONS_LOG.md', [364, 366])
kutip('docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md', [8, 348])
for nama, awal, akhir in [('docs/DECISIONS_LOG.md', 361, 366),
                          ('docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md', 1, 10000)]:
    teks = '\n'.join((akar/nama).read_text().splitlines()[awal-1:akhir])
    print(nama, f'rentang {awal}..{akhir}:',
          'URL/DOI=', re.findall(r'https?://\S+|doi:\S+', teks, flags=re.I))
assert re.findall(r'https?://\S+|doi:\S+', 'https://contoh.invalid/riset')
print('\n4. Angka kini vs angka historis')
print('Migrasi kini:', len(list((akar/'supabase/migrations').glob('*.sql'))))
print('Berkas uji SQL kini:', len(list((akar/'supabase/tes').glob('*.sql'))))
print('Klaim 41 uji dan 14 migrasi adalah catatan bertanggal, bukan angka kini.')
print('\n5. Keputusan berkas penanda tidak tertinggal')
for nama in ['supabase/SEBAR-SKEMA', 'aplikasi/SEBAR-HALAMAN']:
    print(nama, 'ADA' if (akar/nama).exists() else 'TIDAK ADA')
assert (akar/'supabase/config.toml').exists(), 'kontrol negatif: jalur nyata harus dikenali'
print('\n6. CORS bukan wildcard (bukan bukti otorisasi)')
kutip('supabase/functions/verifikasi_pin/index.ts', list(range(43, 48)))
