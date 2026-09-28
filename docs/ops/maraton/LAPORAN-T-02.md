# LAPORAN T-02 · pekerja-2

- Tanggal: 2026-09-21 (UTC).
- Cabang sesi: `arena/01a0c1d7-resto-barokah`.
- Cabang integrator: `arena/01a0c1d1-resto-barokah`.
- Basis sesudah fast-forward: `c25d2dc`.
- **Status: MACET — DoD (d) bertentangan dengan perilaku skema saat ini. Bukan SELESAI, bukan siap dipanen sebagai pekerjaan hijau.**
- Lingkup: hanya `supabase/tes/perangkat_registrasi_tepi.sql`, ditambah laporan wajib ini. Tidak ada nomor migrasi cadangan untuk T-02.

## Yang dikerjakan

Checkout awal masih di basis `main` (`253d129`); `PRO.md` dan papan belum tersedia. Menyusul cabang integrator memakai fetch + merge fast-forward, tanpa mengganti cabang sesi. Membaca orientasi, papan T-02, AL-16, runner SQL, fixture, uji registrasi lama, serta implementasi registrasi/pencabutan.

Saat membaca implementasi ditemukan hambatan di DoD (d). Pekerjaan fitur dihentikan; hanya dibuat reproduksi terarah di berkas uji yang diizinkan untuk membuktikan hambatan dan menyediakan bukti bagi integrator. Tidak mencoba memperbaiki produksi atau mengambil keputusan desain.

Reproduksi menggunakan peran `authenticated` dengan admin cabang A1:

1. Memasang PIN sah melalui perangkat fixture.
2. Mendaftarkan `hp-tepi-daftar-ulang`; memeriksa id terisi dan PIN diterima melalui perangkat itu.
3. Mencabut perangkat; memeriksa RPC berhasil dan baris lama benar-benar nonaktif.
4. Mendaftarkan ulang **nama sama**, cabang sama, kunci baru — seharusnya berhasil menurut DoD, tetapi sekarang gagal dengan pelanggaran constraint keunikan.
5. Asersi bahwa id baru berbeda dan perangkat baru menerima PIN sudah ditulis sesudah langkah 4, tetapi **belum tercapai** karena langkah 4 gagal.

Tidak ada `uji.harap_gagal` polos. Kegagalan langkah 4 tidak ditangkap sebagai hasil yang diharapkan: mengubahnya menjadi `harap_gagal_sebab` akan membuat uji hijau dengan harapan yang bertentangan dengan DoD.

## Penyebab dan batas lingkup

Sumber: `supabase/migrations/0018_perangkat_terdaftar.sql`:

- Tabel `perangkat` memiliki `unique (penyewa_id, nama)` tanpa pengecualian untuk perangkat nonaktif (bagian 1).
- `cabut_perangkat` hanya menjalankan `update ... set aktif = false`; nama dan baris lama tetap ada (bagian 3).
- `daftarkan_perangkat` selalu `insert` baris baru dengan nama yang diberikan (bagian 3).

Karena itu nama yang sudah dicabut masih menghalangi pendaftaran baru. Ini bukan masalah fixture/izin: pendaftaran pertama, penggunaan PIN, serta pencabutan berhasil sebelum pendaftaran kedua gagal.

**Memenuhi DoD (d) membutuhkan perubahan produksi di luar lingkup uji T-02 atau peninjauan ulang DoD oleh integrator.** Saya tidak membuat migrasi baru, tidak mengubah migrasi 0018, tidak menghapus/mengganti nama perangkat secara manual di fixture agar uji tampak lulus, dan tidak mengubah papan. Integrator perlu memutuskan tindak lanjut serta lingkup/nomor migrasi jika diperlukan. Jangan memanen cabang ini sebagai hasil selesai sebelum hambatan ditangani.

## Bukti perintah dan hasil

| Perintah | Hasil nyata |
|---|---|
| `git fetch origin arena/01a0c1d1-resto-barokah:refs/remotes/origin/kerja-terakhir` kemudian `git merge --ff-only origin/kerja-terakhir` | Berhasil; fast-forward `253d129` → `c25d2dc`, tetap pada cabang sesi. |
| `python3 alat/lanjut-sesi.py --daftar-sesi` | Berhasil menampilkan daftar sesi. |
| `python3 alat/lanjut-sesi.py --susul` | Tidak ada perubahan; target lama yang tersimpan di handoff sudah termuat. Basis eksplisit integrator dari pesan Lee sudah lebih dulu disusul. |
| `python3 alat/lanjut-sesi.py` | LOLOS saat orientasi, sebelum perubahan pekerja. Tidak menyegarkan/menyunting handoff. |
| `npm ci --prefix alat` | Exit 0; 3 paket dipasang, audit 0 kerentanan. Lockfile tidak berubah. |
| `node alat/uji-sql.mjs supabase/tes/perangkat_registrasi_tepi.sql` | **Exit 1: 0 LULUS · 1 GAGAL**. Seluruh 19 migrasi dan fixture berhasil diterapkan. |
| `node alat/uji-sql.mjs` | **Exit 1: 60 LULUS · 1 GAGAL** dari 61 berkas. Semua 60 uji lama lulus, termasuk `perangkat_registrasi.sql`; satu-satunya kegagalan adalah reproduksi baru. |

Pesan kegagalan persis pada kedua perintah SQL:

```text
duplicate key value violates unique constraint "perangkat_penyewa_id_nama_key"
```

## Keterbatasan jujur

- DoD belum terpenuhi; suite SQL keseluruhan **merah**, bukan hijau.
- Skenario (a) nama kembar satu penyewa, (b) nama sama beda penyewa, (c) cabang nonaktif, dan (e) batas 16/15 karakter belum ditambahkan: berhenti setelah memastikan perbaikan memerlukan berkas di luar lingkup, sesuai instruksi Lee.
- Uji menggunakan PostgreSQL WASM/PGlite lokal; runner meniru antarmuka pgcrypto, bukan bcrypt produksi. Tidak menjalankan pengujian Supabase nyata, aplikasi, Edge, maupun seluruh baterai CI. Tidak mengklaim CI hijau.
- Uji baru sengaja tetap merepresentasikan harapan DoD yang gagal; bukan perubahan perilaku produksi. Setiap berkas SQL dibungkus transaksi dan di-rollback oleh runner.

## Daftar berkas yang disentuh pekerja (di atas basis integrator)

1. `supabase/tes/perangkat_registrasi_tepi.sql` — reproduksi gagal DoD (d).
2. `docs/ops/maraton/LAPORAN-T-02.md` — laporan hambatan, bukti, dan batas pekerjaan.

Tidak menyentuh papan, handoff, PROJECT_STATE/STATUS, migrasi, pemeriksa `alat/`, `.github/`, lockfile, atau cabang resmi. Commit/push hanya ke `arena/01a0c1d7-resto-barokah`; penggabungan dan keputusan tindak lanjut diserahkan kepada integrator.
