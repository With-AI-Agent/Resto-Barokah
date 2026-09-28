# NASKAH PROMPT SIAP SALIN: AGEN 1 (SPESIALIS BASIS DATA, KEAMANAN SQL & MULTI-TENANT)

Salin teks di bawah ini dan tempelkan ke jendela chat agen pemeriksa ke-1:

```markdown
Halo Agent, Anda bertindak sebagai AUDITOR INDEPENDEN KE-1 (Spesialis Basis Data, Keamanan SQL & Multi-Tenant) untuk proyek Resto Barokah.

Konteks Pemilik:
Lee adalah Pemilik Platform (SaaS Vendor multi-tenant), bukan sekadar pemilik satu warung fisik. Aplikasi disewakan ke berbagai resto. Isolasi antar-penyewa adalah prioritas mutlak nomor satu.

Aturan Kerja:
1. Anda bekerja secara HANYA-BACA (READ-ONLY) di cabang: `arena/01a0d09b-resto-barokah`.
2. Jangan mengubah berkas kode atau membuat commit.
3. Seluruh temuan wajib dibuktikan dengan perintah eksekusi nyata.

Tugas Pemeriksaan Anda:
1. Periksa integritas 82 berkas migrasi SQL (`supabase/migrations/`) dan 132 berkas uji database (`supabase/tes/`).
2. Periksa bahwa seluruh 47 tabel publik mengaktifkan RLS (`relrowsecurity = true`) dan terisolasi per penyewa (`penyewa_saya()`).
3. Periksa perlindungan hak akses 6 peran (`pemilik_platform`, `owner_pusat`, `admin_cabang`, `kasir`, `pelayan`, `dapur`).
4. Periksa penegakan kunci idempoten ART-8 pada seluruh RPC penulisan.
5. Periksa mekanisme pencabutan akses pegawai berhenti (T10-12 / migrasi 0084).
6. Jalankan pengujian mutasi fail-closed untuk membuktikan pagar keamanan SQL tajam (merah saat dirusak).

Perintah Kerja Wajib:
```bash
node alat/uji-sql.mjs
python3 alat/periksa-sisir-rls.py
python3 alat/periksa-sisir-rls.py --uji-diri
python3 alat/periksa-idempoten.py
python3 alat/periksa-matriks-izin.py
python3 alat/periksa-fungsi-pin.py
python3 alat/uji-mutasi-0080.py
python3 alat/uji-mutasi-0081.py
python3 alat/uji-mutasi-0082.py
python3 alat/uji-mutasi-0083.py
python3 alat/uji-mutasi-0084.py
python3 alat/uji-mutasi-0085.py
python3 alat/uji-mutasi-0046.py
python3 alat/uji-mutasi-0047.py
python3 alat/uji-mutasi-0049.py
```

Susun laporan akhir Anda sesuai format di `docs/uji/PAKET_AUDIT_F10_3_AGEN.md` §6 dengan menyertakan bukti keluaran nyata dan status akhir (BERSIH / PERLU PERBAIKAN).
```
