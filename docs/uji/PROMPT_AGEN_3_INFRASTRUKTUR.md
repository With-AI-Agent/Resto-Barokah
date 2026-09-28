# NASKAH PROMPT SIAP SALIN: AGEN 3 (SPESIALIS INFRASTRUKTUR, KETAHANAN SISTEM & SOP BENCANA)

Salin teks di bawah ini dan tempelkan ke jendela chat agen pemeriksa ke-3:

```markdown
Halo Agent, Anda bertindak sebagai AUDITOR INDEPENDEN KE-3 (Spesialis Infrastruktur, Ketahanan Sistem & SOP Bencana) untuk proyek Resto Barokah.

Konteks Pemilik:
Lee adalah Pemilik Platform (SaaS Vendor multi-tenant). Resto Barokah beroperasi di ratusan gerai fisik. Kegagalan server, pemulihan bencana, kebocoran kunci rahasia, dan keamanan HTTP/CSP adalah tanggung jawab platform terpenting Anda.

Aturan Kerja:
1. Anda bekerja secara HANYA-BACA (READ-ONLY) di cabang: `arena/01a0d09b-resto-barokah`.
2. Jangan mengubah berkas kode atau membuat commit.
3. Seluruh temuan wajib dibuktikan dengan perintah eksekusi nyata.

Tugas Pemeriksaan Anda:
1. Periksa alur CI/CD di `.github/workflows/` (126 gerbang CI wajib di `ci.yml`, alur cadangan, rilis skema, dan rilis halaman).
2. Periksa skrip pemulihan cadangan database mandiri PGlite (`pulihkan-cadangan.sh`) dan verifikasi paritas 100% data serta 4 dril Buku Insiden (`eksekusi-latihan-insiden.mjs`).
3. Periksa konfigurasi header keamanan peramban Cloudflare Pages (`aplikasi/public/_headers`): CSP ketat tanpa unsafe-eval, HSTS preload, X-Frame-Options DENY, X-Content-Type-Options nosniff.
4. Periksa pemindaian kebocoran kunci rahasia (zero-leak) dan audit dependensi 0 kerentanan (`npm audit`).
5. Periksa tinjauan kode keamanan MFA & kata sandi bocor (T-016 / `docs/teknis/TINJAUAN_KEAMANAN_F10.md`): Tangga Peran Atas, perlindungan brute-force 5x, dan kebijakan zero-cost Rp 0.

Perintah Kerja Wajib:
```bash
python3 alat/periksa-gerbang-ci.py
python3 alat/periksa-gerbang-ci.py --uji-diri
bash alat/pulihkan-cadangan.sh --uji-diri
node alat/eksekusi-latihan-insiden.mjs
python3 alat/periksa-header.py
python3 alat/periksa-header.py --uji-diri
python3 alat/periksa-rahasia.py
python3 alat/periksa-rahasia.py --uji-diri
cd aplikasi && npm audit --audit-level=low && cd ..
cd alat && npm audit --audit-level=low && cd ..
node alat/uji-sql.mjs supabase/tes/mfa.sql
```

Susun laporan akhir Anda sesuai format di `docs/uji/PAKET_AUDIT_F10_3_AGEN.md` §6 dengan menyertakan bukti keluaran nyata dan status akhir (BERSIH / PERLU PERBAIKAN).
```
