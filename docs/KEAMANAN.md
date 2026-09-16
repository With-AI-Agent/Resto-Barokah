# KEAMANAN.md — Aturan Keamanan Akun, Perangkat, Sesi & Data (Resto Barokah)

> **Status: BERLAKU sejak 2026-09-17** setelah pemilik menyetujui usulan
> `docs/teknis/USULAN_KEAMANAN_DAN_KELENGKAPAN_UI.md` (jawaban pemilik: masuk staf = PIN di perangkat terdaftar ·
> perangkat = kode pendaftaran + persetujuan pemilik · mode dukungan = berbatas waktu & tercatat ·
> rencana dokumen & dua fase baru = **setuju semua**). Dua hal diserahkan pemilik kepada agent dan ditetapkan
> agent dengan alasan tertulis: **(a) satu akun = satu peran** dan **(b) TOTP wajib untuk tiga peran berkuasa
> + jalan pemulihannya** — keduanya tercatat di `docs/DECISIONS_LOG.md` 2026-09-17.
>
> Dokumen ini **mengikat** dan menjadi rujukan resmi untuk seluruh pekerjaan akun/perangkat/sesi.
> `docs/TECH_SPEC.md` §8 sekarang hanya ringkasan yang menunjuk ke sini. Mengubah isi dokumen ini wajib
> lewat `DECISIONS_LOG.md` + persetujuan pemilik (sama seperti ART-1…ART-10).

---

## 1. Prinsip (yang tidak boleh dilanggar oleh keputusan lain)

1. **Menolak secara bawaan.** Tanpa izin eksplisit → tidak boleh. Berlaku untuk data, aksi, dan layar.
2. **Layar bukan penjaga.** Menyembunyikan tombol hanya kenyamanan; keputusan sebenarnya ada di **database** (RLS + `boleh()`).
3. **Dua faktor untuk semua orang yang menyentuh uang.** Staf: **perangkat terdaftar** (yang dimiliki) + **PIN** (yang diketahui). Admin/owner/pemilik platform: **kata sandi** + **TOTP**.
4. **Pencabutan tidak menunggu token kedaluwarsa.** Karena token Supabase yang sudah terbit tidak bisa ditarik kembali, semua pemeriksaan perangkat/sesi dilakukan **di database pada setiap permintaan**.
5. **Tidak ada angka uang dari perangkat.** Semua nominal dihitung di peladen (`hitung_total()`), klien hanya menampilkan (sudah berlaku sejak T1-10).
6. **Rahasia tidak pernah ditulis.** PIN, kata sandi, token, dan data pribadi pelanggan tidak boleh masuk log, pesan error, commit, atau dokumen.
7. **Setiap tindakan sensitif meninggalkan jejak** yang tidak bisa diubah (dan sejak Fase 1B: berantai hash).
8. **Kalau ragu → berhenti dan tanya pemilik** (Stop Condition §12 `AGENT_OPERATING_GUIDE.md`).

## 2. Aset yang dilindungi & peta ancaman

| Aset | Kenapa penting | Ancaman utama |
|---|---|---|
| Catatan uang (pesanan, pembayaran, shift) | Sengketa dengan pegawai/pelanggan; dasar laporan | Kasir curang · koreksi tanpa jejak · pembayaran dobel |
| Kas fisik | Uang hilang tanpa bukti | Buka laci tanpa transaksi · selisih tanpa alasan |
| Data pelanggan (nama/kontak voucher) | Kewajiban UU PDP; kepercayaan | Kebocoran · penggunaan di luar tujuan · penyalahgunaan voucher |
| Akun pegawai & perangkat | Pintu masuk seluruh sistem | Perangkat hilang/dicuri · PIN ditebak/dibagikan · mantan pegawai |
| Jejak audit | Bukti satu-satunya saat berselisih | Penghapusan/penyuntingan diam-diam |
| Isolasi antar penyewa | Janji utama platform | Data resto A terlihat resto B |

**Sepuluh ancaman beserta kendalinya** ada di `docs/teknis/USULAN_KEAMANAN_DAN_KELENGKAPAN_UI.md` §B1; ringkasannya: kebocoran uang (izin + PIN + jejak + ringkasan harian), mantan pegawai (nonaktif = cabut seketika), perangkat hilang (perangkat terdaftar + PIN + kunci otomatis + pencabutan), PIN ditebak (batas 5×/15 menit per akun & 12×/15 menit per perangkat + PIN unik), isolasi penyewa (RLS + uji matriks), data pelanggan (UU PDP), penyalahgunaan publik (10 lapis pengaman voucher), kunci bocor (`service_role` tidak pernah di klien + pemeriksa rahasia), platform owner (mode dukungan).

## 3. Identitas & peran

- **Enam peran tetap** (tidak berubah): `pemilik_platform` · `owner_pusat` · `admin_cabang` · `kasir` · `pelayan` · `dapur`.
- **Satu akun = satu peran** (`pengguna.peran` satu kolom, berlaku di semua cabang). Orang dengan dua fungsi → **dua akun**, **PIN berbeda**. Bukti & alasan: `DECISIONS_LOG` 2026-09-17.
- **`pengguna_cabang` hanya menyimpan daftar cabang** (kolom peran per cabang tidak lagi menjadi sumber wewenang).
- **Izin (centang) boleh berbeda per akun** — penyetelan di dalam satu peran, bukan peran kedua.
- Akun staf memakai **alias email internal** (tidak pernah dipakai mengirim email); akun admin/owner memakai **email nyata** + TOTP.
- Akun nonaktif (`pengguna.aktif = false`) **langsung kehilangan seluruh akses**, termasuk sesi & perangkat yang sedang jalan.

## 4. Perangkat terdaftar

- Tabel: `perangkat` (`penyewa_id`, `cabang_id`, `nama`, `jenis`, `peran_diizinkan`, `rahasia_hash`, `status`, `terakhir_aktif`, `terdaftar_oleh`, `dicabut_oleh`, `catatan`) · `kode_pendaftaran_perangkat` (kode sekali pakai, 15 menit) · `sesi_perangkat` (`session_id`, `perangkat_id`, `pengguna_id`, `mulai`, `berakhir_pada`, `status`).
- **Alur pendaftaran:** admin/owner membuat kode → perangkat baru memasukkan kode → rahasia acak 32 byte dibuat di perangkat, server hanya menyimpan **SHA-256** → perangkat aktif dengan peran yang diizinkan.
- **Persetujuan pemilik untuk pasangan (pegawai × perangkat) baru** (keputusan pemilik): pegawai pertama yang memakai perangkat terdaftar harus disetujui owner/admin berizin; berlaku juga saat pegawai lama memakai perangkat berbeda untuk pertama kali.
- **Peran dibatasi per perangkat:** "Tablet Kasir 1" hanya untuk `kasir`; tidak bisa dipakai masuk sebagai `owner_pusat`.
- **Pencabutan seketika:** menekan "Cabut perangkat" (atau menandai "hilang") membuat semua permintaan dari perangkat itu ditolak **di database** pada detik berikutnya; alasan & pelaku dicatat.
- **Pengecualian:** `pemilik_platform` tidak butuh pengikatan perangkat (jalan darurat lintas penyewa), diganti TOTP wajib + umur sesi 8 jam + tanpa akses data penyewa (kecuali mode dukungan).
- **Bukti perangkat per permintaan** dikirim sebagai header dan dibaca `current_setting('request.headers')`; **wajib diverifikasi di Supabase nyata** (T0-08). Bila tidak andal, penegakan tetap berjalan lewat `sesi_perangkat` (perangkat aktif + sesi aktif + belum kedaluwarsa) — jadi tidak ada ketergantungan pada satu mekanisme.

## 5. Cara masuk per peran

| Peran | Faktor | Catatan |
|---|---|---|
| **Kasir · Pelayan · Dapur** | **Perangkat terdaftar + PIN 6 digit** | Satset (2 detik). Tanpa perangkat terdaftar, PIN tidak menghasilkan sesi yang bisa dipakai. PIN = PIN persetujuan (satu rahasia). |
| **Admin Cabang** | Kata sandi (≥12) + **TOTP wajib** + perangkat terdaftar | Boleh mengelola cabang; tidak boleh melihat cabang lain. |
| **Owner Pusat** | Kata sandi + **TOTP wajib** + perangkat terdaftar | Perangkat pertama boleh didaftarkan sendiri (bootstrap) dengan kata sandi + TOTP. |
| **Pemilik Platform** | Kata sandi + **TOTP wajib** (tanpa perangkat) | Sesi 8 jam; data penyewa hanya lewat mode dukungan. |
| **Pelanggan** | Google (utama) / email terverifikasi (kedua) | Tidak diikat perangkat (memakai HP sendiri). |

- **Pemulihan:** PIN staf direset admin/owner (`kelola_pegawai`, tercatat). MFA admin cabang direset owner pusat; MFA owner pusat direset pemilik platform (semuanya tercatat + pemberitahuan). Langkah lengkap ada di `docs/teknis/BUKU_INSIDEN.md`.
- **Ditolak dengan sadar:** PIN sebagai kunci enkripsi lokal · Edge Function yang menerbitkan sesi sendiri · login staf dari perangkat mana saja · TOTP untuk kasir/pelayan/dapur (friksi harian besar, tambahan keamanan kecil karena sudah perangkat+PIN).

## 6. PIN

1. **6 digit**, **unik antar pegawai dalam satu resto**, dilarang pola lemah (111111, 123456, tanggal lahir, dsb.).
2. Disimpan hanya sebagai **hash bcrypt** (pgcrypto) dengan batas kolom yang menolak nilai bukan-hash (berlaku sejak T1-06).
3. **Tidak ada fungsi yang mengembalikan hash**, dan PIN tidak pernah masuk log (dijaga pemeriksa statis `alat/periksa-fungsi-pin.py`).
4. **Batas percobaan dua lapis:** 5×/15 menit per akun · 12×/15 menit per perangkat; percobaan yang ditolak karena terkunci tetap dihitung; semua percobaan masuk `percobaan_masuk`.
5. **PIN benar belum cukup untuk aksi:** persetujuan tetap diperiksa lewat `boleh_untuk()` — PIN dapur tidak bisa menyetujui void hanya karena PIN-nya benar (aturan T1-06).
6. Ganti PIN sendiri wajib PIN lama; mengganti PIN pegawai lain wajib `kelola_pegawai` + tercatat + (sejak Fase 1B) pemberitahuan.

## 7. Sesi

| Kendali | Nilai | Penegak |
|---|---|---|
| Umur token akses | 15 menit | Supabase (pengaturan, gratis) |
| Umur maksimum sesi | Staf 12 jam · admin/owner 30 hari · pemilik platform 8 jam | Database (`sesi_perangkat`) |
| Kunci otomatis saat menganggur | 15 / 15 / 15 / 30 / 60 menit (kasir/pelayan/dapur/admin/owner) | Aplikasi + aturan dokumen |
| Kunci = | sesi dihapus dari perangkat; buka lagi wajib PIN/kata sandi | Aplikasi |
| Batas percobaan masuk | 5×/15 menit per akun · 12×/15 menit per perangkat | Database |
| Pencabutan | per perangkat · per akun · semua perangkat | Database + RPC (seketika) |

**Catatan jujur paket gratis:** "time-box sesi", "inactivity timeout", "satu sesi per pengguna", dan pemeriksa kata sandi bocor (HaveIBeenPwned) adalah fitur **Pro**; karenanya kendali di atas dibuat sendiri. Kompensasi untuk kata sandi: minimum 12 karakter + pola umum dilarang + TOTP wajib.

## 8. Otorisasi (dua lapis, satu gerbang)

1. **Lapis 1 — RLS:** deny by default; setiap tabel punya policy; nilai penyewa/cabang diambil dari tabel `pengguna` lewat id Auth (bukan `user_metadata` yang bisa diubah klien).
2. **Lapis 2 — gerbang izin:** setiap RPC memanggil `boleh(...)`/`boleh_untuk(...)` sebagai pemeriksaan pertama; tidak ada pemeriksaan `peran` yang ditulis ulang di tempat lain.
3. **Fungsi `SECURITY DEFINER`** hanya bila perlu, wajib `set search_path` dipaku, `revoke execute from public` + `grant` eksplisit, dan tidak boleh menjadi jalan pintas menyelesaikan masalah izin (paling berbahaya: fungsi `SECURITY DEFINER` di skema `public` bisa dipanggil semua peran bila haknya tidak dicabut).
4. **Uji matriks (T1-29):** setiap peran × setiap aksi diperiksa otomatis — yang berizin **boleh**, yang tidak berizin **ditolak walau RPC dipanggil langsung**.

## 9. Uang & kecurangan operasional

1. Angka uang hanya ditulis fungsi peladen; pembayaran tidak bisa diubah/dihapus; kembalian dihitung database (T1-10).
2. **Non-tunai wajib referensi**; layar tutup kas menampilkan daftar referensi untuk dicocokkan dengan QRIS/bank.
3. **Ringkasan peringatan harian** ke email owner: omzet, void, diskon, selisih kas, percobaan masuk gagal, perubahan perangkat.
4. Laporan **"siapa menyetujui apa"** per bulan (semua penggunaan PIN persetujuan) — mencegah PIN atasan dipakai berulang tanpa terasa.
5. Transaksi hanya dalam shift terbuka; selisih wajib beralasan; setelah shift ditutup, koreksi = baris baru (ART-6).

## 10. Jejak audit

- `catatan_audit` **hanya-tambah** (tidak ada hak ubah/hapus untuk siapa pun, termasuk owner).
- Sejak Fase 1B: **rantai hash** (`hash_sebelumnya`, `hash_baris`) dihitung pemicu; pemeriksa `alat/periksa-audit.py` menunjuk baris pertama yang putus bila ada perubahan/penghapusan langsung di database.
- Yang dicatat minimal: void, diskon manual, perubahan harga, buka laci tanpa transaksi, pakai voucher, perubahan pengaturan, perubahan izin, perubahan pegawai/PIN, pendaftaran/pencabutan perangkat, persetujuan PIN, mode dukungan, percobaan masuk.

## 11. Data pelanggan & UU PDP (UU 27/2022)

- **Persetujuan eksplisit** sebelum menyimpan data; kalimat singkat + tautan kebijakan pada halaman pendaftaran voucher.
- **Minimalisasi**: nama, kontak (opsional), catatan voucher. Tidak ada NIK, lokasi, biometrik, atau pelacakan.
- **Hak pelanggan**: akses & hapus → data pribadi **dianonimkan**; catatan keuangan tetap utuh (Aturan Bisnis 11). Tanggap 3×24 jam.
- **Kebocoran**: pemberitahuan tertulis ≤ **3×24 jam** ke subjek data + lembaga pengawas (Pasal 46), memuat data apa, kapan/bagaimana, dan langkah pemulihan → template di `BUKU_INSIDEN.md`.
- **Lokasi data**: region Supabase ditetapkan pemilik saat T0-08 (usul Singapore); dasar transfer = persetujuan + pengamanan penyedia.
- Email/laporan tidak boleh memuat kontak pelanggan.

## 12. Mode dukungan (pemilik platform)

- Bawaan: **tidak ada akses** ke isi data penyewa.
- Mode dukungan: **wajib alasan**, berbatas waktu (bawaan 60 menit), **hanya-baca**, dicatat di `catatan_audit`, dan **owner penyewa diberi tahu** (email).
- Berakhir otomatis; dilarang memperpanjang otomatis; tidak memberi hak mengubah data.

## 13. Operasional (murah, sering terlupa)

- **Offboarding pegawai (daftar simak):** nonaktifkan akun → cabut perangkat pribadi (bila ada) → ganti PIN bersama → periksa jejak 30 hari.
- **Perangkat hilang:** cabut perangkat + tandai "hilang" + catat insiden + (bila perlu) ganti PIN pegawai yang memakainya + pertimbangkan mengganti kunci perangkat.
- **Kebiasaan fisik:** setiap tablet punya slot/nomor di bilik pengisian; dicek saat tutup kedai; mode kunci satu-aplikasi (kiosk/guided access) untuk tablet satu fungsi; layar terkunci saat ditinggal.
- **Kata sandi owner/admin:** ≥12 karakter, tidak dipakai ulang di layanan lain, diganti bila ada kecurigaan.
- **Cadangan:** dump mingguan terenkripsi (T-012); **latihan pemulihan** minimal sekali sebelum pilot.

## 14. Matriks uji keamanan (wajib hijau sebelum pilot)

| Uji | Bentuk | Tugas |
|---|---|---|
| Isolasi penyewa & cabang (semua tabel) | SQL otomatis | T1-04, T1-22 |
| Peran × aksi (boleh/ditolak) | SQL otomatis (matriks) | T1-29 |
| Perangkat tidak terdaftar → tabel staf tertutup | SQL otomatis | T1-24 |
| Cabut perangkat → permintaan berikutnya gagal | SQL otomatis | T1-24 |
| Sesi lewat umur maksimum → ditolak | SQL otomatis | T1-24 |
| Kunci 5×/15 menit & 12×/15 menit | SQL otomatis | T1-25 |
| PIN lemah & PIN kembar ditolak | SQL otomatis | T1-23 |
| Rantai audit terdeteksi bila diubah/dihapus | SQL otomatis + pemeriksa | T1-26 |
| Mode dukungan: tanpa mode = 0 baris; dengan mode = hanya-baca; kedaluwarsa = 0 baris | SQL otomatis | T1-28 |
| Hak istimewa fungsi (`security definer`, `grant execute`) | pemeriksa statis SQL | T1-30 |
| Rahasia tidak masuk repo · `npm audit` bersih | pemeriksa CI | T1-30 |
| Setiap aksi UI → RPC & izin benar (per peran) | uji komponen + pemeriksa peta aksi | T1-31…T1-35 |
| 9 alur wajib di peramban | Playwright di CI | T11-11 |

## 15. Risiko sisa yang diterima (dicatat terbuka, bukan disembunyikan)

| # | Risiko sisa | Kenapa diterima | Kompensasi |
|---|---|---|---|
| 1 | PIN 6 digit lemah bila hash database bocor | Perangkat terdaftar tetap diperlukan; bcrypt + batas percobaan | Ganti PIN massal bila ada indikasi kebocoran; prioritas upgrade bila sudah berbayar |
| 2 | Pemeriksa kata sandi bocor (HIBP) tidak tersedia di paket gratis | Tidak berbiaya nol | Aturan kata sandi ≥12 + larangan pola + TOTP wajib |
| 3 | PIN bisa dibagikan antar pegawai | Manusia; tidak bisa dicegah teknis | PIN unik + jejak + laporan "siapa menyetujui apa" + ingatan pemilik |
| 4 | Bukti perangkat per permintaan belum terbukti di Supabase nyata | T0-08 belum jalan | `sesi_perangkat` + status perangkat tetap diperiksa tanpa header |
| 5 | Pemilik platform tidak terikat perangkat | Jalan darurat lintas penyewa | TOTP wajib + sesi 8 jam + tanpa data penyewa + mode dukungan tercatat |
| 6 | HP pegawai hilang = kerja terhenti sampai MFA direset | Harga dari TOTP wajib | Jalan pemulihan cepat (owner/pemilik platform) + langkah di Buku Insiden |
| 7 | Internet mati = tidak bisa masuk (sesi terkunci) | Keamanan didahulukan | Kunci otomatis diperpanjang wajar + prosedur catat manual sementara (Buku Insiden) |

## 16. Aturan untuk sesi agent berikutnya

1. Jangan mengubah dokumen ini atau ART-11…ART-15 tanpa `DECISIONS_LOG.md` + persetujuan pemilik.
2. Jangan menambah tabel/kolom yang menyimpan identitas atau perangkat tanpa uji isolasi + uji perangkat.
3. Jangan memakai `user_metadata` untuk keputusan otorisasi; jangan mengandalkan klaim JWT yang bisa basi untuk pencabutan.
4. Jangan menulis PIN/kata sandi/token/data pelanggan ke log, pesan error, atau dokumen.
5. Setiap fungsi `SECURITY DEFINER` baru: `search_path` dipaku + hak `execute` dicabut dari `public` + pemeriksaan izin di dalam badan fungsi.
6. Setiap layar baru: kontrak layar + aksi terdaftar + 7 keadaan + uji komponen (lihat `docs/SPESIFIKASI_UI.md`).
7. Kalau menemukan cacat pada pekerjaan yang sudah diklaim selesai → laporkan, jangan sembunyikan (Stop Condition §12).
