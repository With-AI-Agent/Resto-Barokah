#!/usr/bin/env python3
"""Mutasi M2 & M3 untuk migrasi 0107 (langkah 7a, PMB1-F-233) — dijalankan Hakim H-P-1B-00.3.

Membangun salinan pohon HEAD di folder sementara (git archive — repo tidak diubah),
menerapkan satu mutasi per salinan, lalu menjalankan uji SQL pada salinan itu.
Harapan: kontrol (tanpa mutasi) LULUS; M2 dan M3 MERAH.
Cara jalan dari akar repo:  python3 docs/uji/pemeriksaan/PMB-1/bukti/H-P-1B-00.3-mutasi-m2-m3.py
"""
import os, re, subprocess, sys, tempfile, pathlib

AKAR = pathlib.Path(__file__).resolve().parents[5]
MIG = 'supabase/migrations/0107_persetujuan_otomatis_jalur_kode_resmi.sql'
UJI = 'supabase/tes/persetujuan_otomatis_kode_resmi.sql'


def salinan(nama: str) -> pathlib.Path:
    dst = pathlib.Path(tempfile.mkdtemp(prefix=f'hakim-{nama}-'))
    arsip = subprocess.run(['git', 'archive', 'HEAD'], cwd=AKAR, capture_output=True, check=True).stdout
    subprocess.run(['tar', '-x', '-C', str(dst)], input=arsip, check=True)
    (dst / 'alat' / 'node_modules').symlink_to(AKAR / 'alat' / 'node_modules')
    return dst


def mutasi_m2(teks: str) -> str:
    # penyetuju = pegawai sendiri (bukan penerbit kode) di blok 7a
    a = teks.index('  -- 7a. PMB1-F-233'); b = teks.index('  -- 7b. PMB1-F-082')
    seg = teks[a:b]
    pola = re.compile(r"      \(select k\.dibuat_oleh\n         from public\.kode_pendaftaran_perangkat k\n"
                      r"        where k\.perangkat_id = v_perangkat\.id\n          and k\.dipakai_pada is not null\n"
                      r"          and k\.penyewa_id = v_pengguna\.penyewa_id\n        order by k\.dibuat_pada asc\n"
                      r"        limit 1\)\n    \)\n    on conflict")
    assert len(pola.findall(seg)) == 1, 'pola M2 tidak ketemu tepat sekali'
    return teks[:a] + pola.sub("      v_pengguna.id\n    )\n    on conflict", seg) + teks[b:]


def mutasi_m3(teks: str) -> str:
    # buang insert catatan_audit di blok 7a
    a = teks.index('  -- 7a. PMB1-F-233'); b = teks.index('  -- 7b. PMB1-F-082')
    seg = teks[a:b]
    i = seg.index('    insert into public.catatan_audit (')
    k = seg.index('    );\n  end if;', i) + len('    );\n')
    return teks[:a] + seg[:i] + seg[k:] + teks[b:]


def jalankan(nama: str, mut=None) -> int:
    d = salinan(nama)
    if mut:
        berkas = d / MIG
        berkas.write_text(mut(berkas.read_text(encoding='utf-8')), encoding='utf-8')
    hasil = subprocess.run(['node', 'alat/uji-sql.mjs', UJI], cwd=d, capture_output=True, text=True)
    keluaran = hasil.stdout + hasil.stderr
    print(f'=== {nama}: rc={hasil.returncode} ===')
    for baris in keluaran.splitlines():
        if 'HARAPAN TIDAK TERPENUHI' in baris or re.match(r'^uji:', baris) or baris.startswith('HASIL'):
            print(baris)
    return hasil.returncode


if __name__ == '__main__':
    rc_kontrol = jalankan('kontrol-HEAD')
    rc_m2 = jalankan('M2-penyetuju-pegawai-sendiri', mutasi_m2)
    rc_m3 = jalankan('M3-tanpa-audit', mutasi_m3)
    ok = rc_kontrol == 0 and rc_m2 != 0 and rc_m3 != 0
    print('HASIL MUTASI:', 'LOLOS (kontrol hijau, M2 & M3 terbunuh)' if ok else 'GAGAL')
    sys.exit(0 if ok else 1)
