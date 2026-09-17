# SPESIFIKASI_UI.md — Aturan Kelengkapan Layar, Tombol & Bukti Uji

> **Status: BERLAKU sejak 2026-09-17** (bagian dari rencana yang disetujui pemilik: "setuju semua").
> **Tujuan:** memastikan tidak ada lagi "tombol kurang" atau "fungsi katanya ada tapi tidak bisa dipakai".
> Cara kerjanya bukan janji, tetapi **mekanisme**: daftar tombol di kode + pemeriksa otomatis di CI + uji komponen
> per layar + naskah jalan untuk pemilik.
>
> Rujukan: `docs/KEAMANAN.md` · `docs/TECH_SPEC.md` §11 · `docs/AGENT_OPERATING_GUIDE.md` §5 & §7 ·
> keputusan `docs/DECISIONS_LOG.md` 2026-09-17 (Fase 1C). Hasil generate: **`docs/PETA_UI.md`** (dilarang disunting tangan).

---

## 1. Enam akar masalah yang ditutup dokumen ini

| # | Akar masalah (pengalaman pemilik) | Penutup |
|---|---|---|
| 1 | Spesifikasi → kode ada jarak; kode menafsir | **Kontrak layar** (§3) ditulis sebelum layar dikoding |
| 2 | Tidak ada daftar tombol → tombol "asal ada" | **Registri Aksi** (§2) — tombol tanpa entri tidak bisa dirender |
| 3 | "Selesai" = kode ditulis | **DoD UI** (§6) — butuh bukti uji + naskah jalan dijalankan |
| 4 | Data contoh menyembunyikan kegagalan | Data uji & **seed** yang sama dipakai uji komponen, uji SQL, dan pratinjau |
| 5 | Tidak ada yang mencoba tombolnya sampai pemilik menemukannya | **Uji komponen per layar** + **naskah jalan pemilik** (§7) |
| 6 | Dokumen & kode bisa saling tinggal (drift) | **Pemeriksa `alat/peta-ui.py`** di CI (§5) |

## 2. Registri Aksi — satu sumber kebenaran tombol

Berkas: `aplikasi/src/lib/aksi.ts`. Setiap aksi **wajib** punya entri lengkap:

| Bidang | Arti |
|---|---|
| `id` | Nama unik, berpola `<layar>.<aksi>` (mis. `kasir.bayar`) |
| `label` | Teks tombol (Bahasa Indonesia, kata kerja) |
| `layar` | Layar tempat aksi muncul (id layar, bukan nama berkas) |
| `peran` | Daftar peran yang boleh melihat aksinya |
| `izin` | Kode izin (`boleh()`) atau `null` bila hanya peran yang menentukan |
| `rpc` | Fungsi peladen yang dipanggil (`null` untuk aksi murni tampilan, mis. "Tutup panel") |
| `jenis` | `baca` / `tulis` / `navigasi` |
| `konfirmasi` | Teks pertanyaan sebelum dijalankan (wajib untuk aksi uang & penghapusan) |
| `pin` | Wajib PIN persetujuan? (ya/tidak) |
| `audit` | Wajib menulis `catatan_audit`? (wajib `true` untuk aksi uang & pengaturan) |
| `sukses` / `gagal` | Pesan hasil (Bahasa Indonesia, memuat kode error `PS-1xx` dst.) |
| `uji` | Daftar id uji yang membuktikan aksi ini bekerja |

**Aturan pelaksanaan:**
1. Semua tombol di folder `layar/` dirender lewat `aplikasi/src/komponen/TombolAksi.tsx`. Tombol mentah (`<button>`) dilarang; pemeriksa statis menolaknya.
2. `TombolAksi` menolak `id` yang tidak ada di registri — kesalahan ketahuan **saat pembangunan**, bukan saat dipakai.
3. Peran tanpa izin: aksi **disembunyikan** (bawaan) atau **ditampilkan nonaktif + alasan** (ditulis di entri). Mana yang dipakai harus diputuskan per aksi, bukan diam-diam.
4. Aksi `tulis` wajib punya minimal satu uji di kolom `uji`; aksi uang wajib `audit: true`.

## 3. Kontrak layar (satu tabel per layar, ditulis SEBELUM dikoding)

Berkas: `aplikasi/src/lib/layar.ts` (registri) + tabel kontrak di bawah ini.

| Bagian | Isi wajib | Contoh (layar kasir) |
|---|---|---|
| `id` & rute | Nama unik + alamat | `kasir` · `/kasir` |
| Tujuan | Satu kalimat: untuk siapa, menyelesaikan apa | "Kasir mencatat pesanan & menerima pembayaran" |
| Peran | Siapa yang boleh membuka | kasir · admin_cabang · owner_pusat |
| Masuk dari mana | Tombol/tautan menuju layar ini (minimal satu) | Bilah bawah "Kasir" · setelah buka shift |
| Data | Yang tampil + sumbernya (RPC/tabel) | katalog (`harga_berlaku`), keranjang (lokal), total (peladen) |
| Aksi | Semua entri Registri Aksi layar ini | lihat `docs/PETA_UI.md` |
| **7 keadaan** | Kosong · Memuat · Gagal(+coba lagi) · Menunggu terkirim · Tidak punya akses · Data sebagian · Berhasil | "Katalog kosong: belum ada menu" · "Koneksi terputus: pesanan menunggu terkirim" |
| Aturan tampilan | Target sentuh ≥44 px · kontras lolos · teks Indonesia · **angka uang dari peladen** | papan angka besar untuk jumlah |
| Bukti | Nama berkas uji komponen + nomor naskah jalan | `Kasir.test.tsx` · `W-3-01…W-3-06` |

## 4. Peta peran → layar (kerangka; diisi bertahap mengikuti fase)

| Peran | Layar utama | Yang **tidak** boleh dibuka |
|---|---|---|
| Pemilik Platform | Daftar penyewa · Perangkat & Sesi (antar-penyewa terbatas) · Mode dukungan · Ringkasan sistem | Semua layar operasional/keuangan penyewa (kecuali mode dukungan aktif) |
| Owner Pusat | Laporan · Pengaturan · Pegawai · Perangkat & Sesi · Katalog · Semua layar kasir/dapur (mengawasi) | — |
| Admin Cabang | Laporan cabangnya · Pengaturan cabangnya · Pegawai cabangnya · Perangkat cabangnya | Cabang lain · Pengaturan tingkat resto |
| Kasir | Kasir · Shift (buka/tutup) · Pembayaran · Voucher (cek/pakai) · Dapur (lihat) | Pengaturan · Pegawai · Laporan keuangan penuh |
| Pelayan | Pesanan meja · Status meja · Katalog | Pembayaran · Shift · Pengaturan |
| Dapur | Layar dapur/bar · Menu habis · Stok (bila diizinkan) | Pembayaran · Shift · Laporan keuangan |
| Pelanggan | Katalog publik · Voucher miliknya | Semua layar staf |

## 5. Pemeriksa otomatis (gerbang CI)

`alat/peta-ui.py` men-generate `docs/PETA_UI.md` dari `aksi.ts` + `layar.ts`, lalu **menggagalkan CI** bila:
1. aksi menunjuk RPC yang tidak ada di `supabase/migrations/*.sql`;
2. aksi menunjuk kode izin yang tidak ada di tabel `izin_kode`;
3. aksi `tulis` tanpa uji (id uji tidak ditemukan di berkas uji);
4. layar tanpa berkas komponen atau tanpa satu pun peran yang bisa membukanya;
5. `docs/PETA_UI.md` berbeda dari hasil generate (dokumen basi);
6. ada fitur PRD M1–M12 yang belum punya layar/aksi.
7. ada `<button>` mentah di folder `layar/` (aturan §2 butir 1).

Pemeriksa ini **wajib dibuktikan bisa MERAH** untuk tiap sebab (uji mutasi) — hijau tanpa pernah merah tidak membuktikan apa pun.

## 6. Definisi Selesai untuk tugas UI (menggantikan DoD lama untuk tugas layar)

Sebuah tugas layar/fitur hanya boleh `[x]` bila **semua** benar:
1. Kontrak layar ditulis & lengkap (§3).
2. Semua aksinya ada di Registri Aksi, lengkap dengan izin/RPC/pesan/uji.
3. Ketujuh keadaan ditangani (dan dapat dilihat di pratinjau).
4. Uji komponen per peran lulus: aksi berizin memanggil RPC yang benar; aksi terlarang tidak ada; keadaan tampil.
5. Pemeriksa `alat/peta-ui.py` lulus.
6. Izin ditegakkan **di database** (bukan hanya disembunyikan di layar) — dibuktikan uji SQL.
7. Naskah jalan bernomor ditulis & **dijalankan** di pratinjau; hasilnya dicatat di blok Bukti ROADMAP.
8. `DECISIONS_LOG.md` diperbarui bila menyentuh uang/keamanan/data pelanggan.

## 7. Naskah jalan pemilik (bukti manusia)

Berkas: `docs/uji/NASKAH_JALAN.md`, penomoran **`W-<fase>-<nomor>`** (mis. `W-3-04`).

Bentuk tiap butir:

```
W-3-04 · Kasir: bayar tunai & kembalian
Buka: halaman Kasir (tablet kasir) → pilih meja → tambah 1 Nasi Goreng
1. Tekan "Bayar" → panel pembayaran muncul
2. Pilih "Tunai", isi uang diterima 100.000 → kembalian harus 73.000
3. Tekan "Selesaikan" → pesan "Pembayaran tercatat", struk muncul
4. Tekan "Bayar" lagi pada pesanan yang sama → tombol tidak aktif + alasan "sudah lunas"
Harus TIDAK terjadi: total berubah sendiri · kembalian salah · bisa bayar dua kali
```

**Aturan:** naskah dijalankan **di pratinjau dengan data contoh**, oleh agent setiap selesai tugas, dan oleh pemilik
pada uji terima fase. Naskah yang gagal = cacat; dicatat & diperbaiki, bukan dihapus.

## 8. Hubungan dengan dokumen lain

- `docs/PETA_UI.md` — **hasil generate** (daftar layar & aksi); jangan disunting tangan.
- `docs/desain/RENCANA_DESAIN_UI.md` — keputusan visual (tema, susunan, komponen) yang tetap berlaku; dokumen ini mengatur **kelengkapan & bukti**, bukan gaya visual.
- `docs/AGENT_OPERATING_GUIDE.md` §5 & §7 — uji & DoD tingkat kerja agent.

## 9. Perilaku & gerakan (spesifikasi rinci — ditambahkan 2026-09-17)

> **Kenapa baru sekarang:** pesan Lee ke-14 meminta *"setiap fitur, fungsi, laman, UI, tombol-tombol, dan lain nya
> secara lebih matang … gerakan/animasi/perilaku"*. Aturan dasar (8 standar kehalusan) sudah ada di
> `docs/desain/RENCANA_DESAIN_UI.md` §7–§8 dan sudah dipasang di prototipe; bagian ini menutup celah yang Lee temukan:
> **aturan perilakunya belum ditulis sebagai spesifikasi yang bisa diperiksa.**

### 9.1 Delapan keadaan layar (diperluas dari 7 keadaan §3)

| Keadaan | Yang terlihat | Yang bisa dilakukan pengguna |
|---|---|---|
| Kosong | pesan + **satu** tombol tindakan utama | tindakan utama |
| Memuat | kerangka bentuk (skeleton), bukan lingkaran berputar di tengah | tidak ada (tetap bisa berpindah) |
| Gagal | sebab singkat + tombol **Coba lagi** | coba lagi |
| Menunggu terkirim | penanda "menunggu" pada baris data + jumlah antrean di bilah atas | batalkan (bila belum terkirim) |
| Tidak punya akses | pesan tegas + siapa yang boleh membuka | kembali |
| Data sebagian | data tampil + spanduk "sebagian data belum masuk" | segarkan |
| Berhasil | pesan singkat 2 detik di kanan bawah + jejak di daftar | lanjut kerja |
| Konflik/ditolak peladen | sebab dalam bahasa manusia + nomor rujukan | ulangi / hubungi admin |

### 9.2 Gerakan (motion) — angka wajib

| Kejadian | Gerakan | Lama | Kurva |
|---|---|---|---|
| Kursor menyentuh kartu | terangkat 2 px + bayangan menguat | 180 ms | `cubic-bezier(.22,.61,.36,1)` |
| Tombol ditekan | skala 0,98 | 120 ms | kurva sama |
| Jendela konfirmasi muncul | naik 8 px + memudar masuk, latar gelap 45% | 240 ms | kurva sama |
| Pesan berhasil | meluncur masuk dari kanan bawah | 200 ms | kurva sama |
| Perpindahan tab/segmen | sorotan bergeser (bukan berkedip) | 180 ms | kurva sama |
| Baris baru di papan pesanan | masuk + sorotan 1× (menandai "baru") | 260 ms | kurva sama |

**Aturan pengaman (tidak bisa ditawar):** semua gerakan **mati** bila pengguna memilih *"kurangi gerak"*
(`prefers-reduced-motion`) · tidak ada gerakan yang menahan kerja (durasi maksimum 260 ms) · tidak ada kedipan
berulang (aksesibilitas) · angka di atas **diuji** lewat pemeriksa kontras & aturan desain yang sudah ada.

### 9.3 Perilaku masukan (input) yang wajib

1. **Tombol utama tahan ganda-tekan:** menekan dua kali cepat tidak mengirim dua pesanan (dikunci saat proses).
2. **Angka & uang:** kolom uang hanya menerima angka; titik ribuan ditampilkan otomatis; nilai akhir **selalu dihitung ulang di peladen** sebelum disimpan.
3. **Tombol wajib:** setiap aksi di Registri Aksi (`docs/SPESIFIKASI_UI.md` §2) harus punya tombol yang bisa ditekan dari layar tempat aksi itu dijanjikan — tidak boleh "fungsi ada tapi tak bisa dipakai".
4. **Keadaan menunggu:** aksi yang memanggil peladen wajib menampilkan penanda dan **melarang** aksi ganda pada baris yang sama.
5. **Umpan balik gagal:** kegagalan tidak boleh berupa "tidak terjadi apa-apa" — wajib ada sebab singkat + langkah berikutnya.
6. **Fokus & papan tulis (kiosk):** masuk kembali ke aplikasi setelah terkunci tidak boleh mengubah isi keranjang/pesanan yang sedang dikerjakan.

### 9.4 Perilaku perangkat & sesi (ringkas, rujuk `docs/KEAMANAN.md`)

- Sesi menganggur **panjang** yang diatur owner → kunci ringan: layar terkunci, keranjang tetap tersimpan.
- Perangkat dicabut → pada percobaan aksi berikutnya layar menampilkan "perangkat tidak terdaftar" + langkah menghubungi admin.
- Mode dukungan aktif → bilah merah "mode dukungan" selalu terlihat + bisa dihentikan siapa pun yang berwenang.

### 9.5 Cara memeriksa (bukti yang harus ada di setiap tugas UI)

| Yang diperiksa | Alat/perintah | Kapan |
|---|---|---|
| 8 keadaan ada & bisa dipanggil | pemeriksa peta UI (`alat/peta-ui.py`, Fase 1C) + uji komponen | setiap tugas layar |
| Gerakan sesuai angka + menghormati "kurangi gerak" | uji komponen + pemeriksa aturan desain (`aplikasi/alat/uji-kontras.py`) | batch UI pertama |
| Tidak ada tombol janji tanpa aksi & sebaliknya | pemeriksa peta UI: Registri Aksi ↔ kontrak layar ↔ kode | setiap batch UI |
| Perilaku bisa dicoba manusia | naskah jalan bernomor `W-<fase>-<nomor>` + bukti pratinjau | setiap akhir fase UI |
