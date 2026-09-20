# Aplikasi Sajian (`aplikasi/`)

Aplikasi kasir, dapur, laporan, dan pelanggan untuk kedai/resto. Satu aplikasi
untuk semua perangkat (HP, tablet, komputer), warnanya bisa diganti pemilik
tanpa koding (10 tema siap pakai).

Berkas ini ditujukan untuk orang yang menjalankan/mengembangkan aplikasi
(termasuk sesi AI berikutnya). Bahasa dokumen proyek ada di `../docs/`.

## Prasyarat

| Alat    | Versi yang dipakai & diuji | Catatan                                                 |
| ------- | -------------------------- | ------------------------------------------------------- |
| Node.js | 22.12+ (LTS 22)            | `node -v` — versi lebih rendah ditolak pustaka terkunci |
| npm     | 10                         | ikut Node                                               |
| Python  | 3.10+                      | hanya untuk pemeriksa otomatis                          |

## Menjalankan di komputer sendiri

```bash
cd aplikasi
npm install        # sekali saja, mengunduh pustaka
npm run dev        # aplikasi jalan; alamat muncul di layar
```

Buka alamat yang muncul (biasanya `http://localhost:5173`). Kalau muncul pesan
`vite: not found` (pustaka hilang setelah ruang kerja dinyalakan ulang), jalankan
`bash alat/pratinjau.sh` — perintah itu memasang pustaka kalau perlu lalu menyalakan
pratinjau. (Perhatikan: karena kamu sudah ada **di dalam** folder `aplikasi`, jalurnya
`alat/pratinjau.sh`. Kalau kamu menjalankannya dari akar repo, tulis
`bash aplikasi/alat/pratinjau.sh`. Skripnya mencari foldernya sendiri, jadi dua-duanya benar
selama jalurnya ditulis lengkap seperti itu.) Halaman yang tampil
sekarang adalah **layar contoh Fase 0** — dipakai untuk membuktikan tema,
komponen, dan keadaan halaman sudah hidup. Layar sungguhan dibuat mulai Fase 2.

## Daftar perintah

| Perintah               | Gunanya                                                                                   |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| `npm run dev`          | menjalankan untuk pengembangan (berubah langsung tanpa muat ulang)                        |
| `npm run build`        | memeriksa tipe lalu membangun berkas siap pasang ke `dist/`                               |
| `npm run preview`      | mencoba hasil `build` di komputer sendiri                                                 |
| `npm run lint`         | pemeriksa aturan kode (ESLint)                                                            |
| `npm run format`       | merapikan tulisan kode otomatis (Prettier)                                                |
| `npm run format:check` | memeriksa kerapian tanpa mengubah berkas                                                  |
| `npm run typecheck`    | memeriksa tipe TypeScript (`tsc -b --noEmit`)                                             |
| `npm test`             | menjalankan uji unit (Vitest)                                                             |
| `npm run cek:supabase` | menguji sambungan ke proyek Supabase memakai kunci **publik** saja (tanpa kunci rahasia)  |
| `npm run deploy`       | memasang ke Cloudflare Workers (butuh login Cloudflare; menunggu persetujuan Lee — T0-09) |

## Peta folder

| Folder                     | Isinya                                                                                                                                  |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `src/gaya/token/tema.css`  | 10 tema + 2 kerapatan, disalin apa adanya dari `../prototipe/css/tokens.css` (**jangan diubah selama Fase 0**)                          |
| `src/gaya/token/dasar.css` | dasar tingkat aplikasi (ukuran kotak, gulir, cetak)                                                                                     |
| `src/gaya/komponen.css`    | tata letak & komponen tambahan aplikasi (lapis mengambang, pemberitahuan, keadaan halaman)                                              |
| `src/gaya/aset/font/`      | 19 berkas huruf (woff2) + lisensi — huruf ikut aplikasi supaya tetap sama walau internet mati                                           |
| `src/komponen/`            | komponen dasar: `Tombol`, `Kartu`, `Lencana`, `Lapis`, `Toast`, `Tabel`, `KolomIsian`, `KeadaanKosong`, `KeadaanMemuat`, `KeadaanGagal` |
| `src/layar/`               | layar aplikasi: `kasir`, `dapur`, `laporan`, `pengaturan`, `pelanggan-publik`, `voucher`, `masuk` (+ `contoh` untuk layar bukti Fase 0) |
| `src/lib/`                 | akal sehat aplikasi: `format.ts` (rupiah/jam/tanggal), `tema.ts` (pilih tema & kerapatan), `env.ts` (baca pengaturan aman)              |
| `src/hook/`                | pemakaian data berulang: `useJam.ts`, `useTema.ts`                                                                                      |
| `public/`                  | berkas yang dibuka langsung peramban: `favicon.svg`, `robots.txt` (nanti `manifest.webmanifest` & `sw.js`)                              |
| `alat/`                    | pemeriksa otomatis versi aplikasi                                                                                                       |

## Pengaturan rahasia (`.env`)

1. `cp .env.example .env` (sekali saja).
2. Isi **hanya dua** nilai publik: `VITE_SUPABASE_URL` dan `VITE_SUPABASE_ANON_KEY`.
3. Kunci rahasia (service_role, Resend/Brevo, Google, Cloudflare) **tidak pernah**
   ditaruh di `.env` aplikasi — tempatnya panel rahasia Cloudflare/Supabase.
   Nilai rahasia juga tidak boleh dikirim lewat obrolan atau masuk Git.

Berkas `.env` diabaikan Git; `.env.example` (contoh kosong) ikut Git.

### Menguji sambungan ke Supabase (T0-08)

```bash
npm run cek:supabase     # memakai nilai publik di aplikasi/.env
```

Alat ini memeriksa alamat proyek + kunci publik, lalu menanyakan dua jalur resmi Supabase yang **tidak membuka data**:
kesehatan layanan Auth (`/auth/v1/health`) dan akar layanan data (`/rest/v1/`). Kalau yang tertulis justru kunci rahasia
(`service_role`), alat **menolak** sebelum menyentuh jaringan. Jalur yang sama dijalankan otomatis di CI, jadi buktinya bisa
diperiksa siapa pun di tab Actions.

### Menyebarkan ke Cloudflare (T0-09, menunggu persetujuan Lee)

Pengaturan ada di `wrangler.toml` (nama proyek `resto-barokah`, aset statis dari `dist/`, alamat gratis `*.workers.dev`).

```bash
npx --yes wrangler@4 login    # sekali saja, membuka peramban (akun Cloudflare pemilik)
npm run deploy                # bangun lalu unggah; alamat publik muncul di layar
```

Token Cloudflare (bila dipakai) **tidak** disimpan di berkas ini: tempatnya rahasia lingkungan/GitHub, atau panel rahasia
Cloudflare. Halaman yang naik sekarang masih kerangka Fase 0 — tujuannya membuktikan jalan rilis bekerja sejak awal.

## Pemeriksa otomatis

> **Dijalankan dari AKAR repo** (folder induk `aplikasi/`) — bukan dari dalam `aplikasi/`.
> Kalau kamu masih di dalam `aplikasi/`, kembali dulu: `cd ..`

```bash
python3 aplikasi/alat/periksa-struktur.py   # struktur folder, token, larangan warna mentah
python3 aplikasi/alat/uji-kontras.py        # kontras warna + aturan desain (10 tema)
python3 aplikasi/alat/periksa-uji.py        # setiap berkas logika wajib punya uji
python3 aplikasi/alat/periksa-komponen-env.py  # komponen wajib + aturan rahasia
python3 _sistem/validate_system.py          # aturan dokumen & rahasia di repositori
python3 alat/periksa-roadmap.py             # kelengkapan ROADMAP
python3 alat/periksa-fondasi-independen.py  # pemeriksa independen (sesi review)
```

Semua pemeriksa juga dijalankan otomatis di GitHub Actions (`.github/workflows/ci.yml`)
setiap kali ada kiriman kode. **Sebelum mengirim kode, jalankan semuanya dulu di
komputer sendiri** supaya CI tidak pernah kaget:

```bash
bash aplikasi/alat/periksa-semua.sh
```

Pelajaran nyata (2026-09-16): CI pertama gagal dua kali justru karena hal yang tidak
terlihat di komputer — folder kosong tidak ikut Git, dan satu berkas Markdown belum
dirapikan. Karena itu perintah di atas wajib dijalankan sebelum kirim kode.

## Tautan dokumen proyek

- Peta dokumen: `../docs/README.md`
- Rancangan teknis (dikunci): `../docs/TECH_SPEC.md`
- Urutan pekerjaan: `../docs/ROADMAP.md`
- Aturan kerja agent (termasuk cara commit & gaya bahasa): `../docs/AGENT_OPERATING_GUIDE.md`
- Keputusan teknis & area berisiko tinggi: `../docs/DECISIONS_LOG.md`
