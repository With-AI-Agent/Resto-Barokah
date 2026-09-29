#!/usr/bin/env python3
"""Membuat MUTAN probe H-F-17.2 di /tmp — kontrol negatif (harus MERAH).

Tiap mutan menukar SATU pernyataan harapan probe dengan klaim bahan kalibrasi / klaim pemeriksa. Probe yang sehat
menjadi MERAH dengan pesan yang memuat nilai nyata; kalau mutan tetap LULUS, probe itu tumpul (pelajaran PMB1-F-092).
Dipanggil dari akar repo oleh H-F-17.2-jalankan.sh:  python3 docs/uji/pemeriksaan/PMB-1/bukti/H-F-17.2-mutasi.py
"""
import pathlib
import re
import sys

SRC = pathlib.Path("docs/uji/pemeriksaan/PMB-1/bukti/H-F-17.2-probe-runtime.sql")
t = SRC.read_text(encoding="utf-8")


def tulis(nama: str, isi: str) -> None:
    if isi == t:
        sys.exit(f"mutan {nama}: pola tidak ditemukan — berkas tidak berubah")
    pathlib.Path(f"/tmp/H-F-17.2-mutan-{nama}.sql").write_text(isi, encoding="utf-8")
    print(f"mutan {nama}: dibuat")


# A — klaim bahan (KEAMANAN-cuplikan:17): umur sesi pemilik platform 30 hari
tulis("A", t.replace("perform uji.sama(v_umur, interval '8 hours', 'F-197", "perform uji.sama(v_umur, interval '30 days', 'F-197", 1))

# B — klaim bahan (KEAMANAN-cuplikan:8): batas 10x → PIN benar setelah 5 salah MASIH masuk
tulis("B", t.replace("perform uji.sama(v->>'kode', 'AKUN_TERKUNCI', 'F-195", "perform uji.sama(v->>'kode', 'LOGIN_SUKSES', 'F-195", 1))

# C — klaim bahan (PRD-cuplikan:14): void oleh owner sesudah bayar BOLEH → perintah dijalankan langsung, tidak diharapkan ditolak
pola_c = re.compile(
    r"select uji\.harap_gagal_sebab\(\n  \$\$(insert into public\.pembatalan\(pesanan_id, tahap, pelaku_id, disetujui_oleh, alasan\)\n"
    r"    values \('b5220000-0000-0000-0000-00000000f171', 'sesudah_dapur',.*?)\$\$,\n  'BY-201',\n  'F-192 owner void tahap sesudah_dapur[^']*'\);",
    re.S,
)
isi_c, n = pola_c.subn(lambda m: m.group(1) + ";", t, count=1)
if n != 1:
    sys.exit("mutan C: blok void owner tidak ditemukan")
tulis("C", isi_c)

# D — klaim bahan (PRD-cuplikan:8): bawaan tumpuk diskon = true
tulis("D", t.replace("'false', 'F-193 bawaan kolom", "'true', 'F-193 bawaan kolom", 1))

# E — klaim pemeriksa (F-196): jalur masuk asli SUDAH menulis percobaan_masuk (satu baris)
tulis("E", t.replace("select uji.sama((select count(*) from public.percobaan_masuk), 0::bigint,",
                     "select uji.sama((select count(*) from public.percobaan_masuk), 1::bigint,", 1))
