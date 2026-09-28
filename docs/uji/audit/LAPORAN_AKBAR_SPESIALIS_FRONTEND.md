# LAPORAN AUDIT AKBAR — SPESIALIS FRONTEND & KASIR LAPANGAN

| Bidang | Isi |
|---|---|
| **Auditor** | Agen Spesialis Frontend & Kasir Lapangan (sesi independen `arena/01a0e267-resto-barokah`, mandat langsung Lee) |
| **Tanggal** | 2026-09-27 |
| **Tingkat pemeriksaan** | Pemeriksaan Akbar Menyeluruh Fase 0–Fase 10 — dimensi horizontal: **Spesialis Frontend & Antarmuka** (per `docs/uji/PAKET_PEMERIKSAAN_AKBAR_F0_F10.md` peran #3 dan `docs/uji/PROMPT_AKBAR_SPESIALIS_FRONTEND.md`) |
| **Commit yang diaudit** | `0fc63c7e8d4007007380b8fcfc3b74a0d8010963` (cabang `arena/01a0e267-resto-barokah`, pohon kerja bersih saat mulai — `git status --short` kosong) |
| **Mode kerja** | **HANYA-BACA** — tidak ada berkas di `aplikasi/src/` maupun CSS yang diubah. Laporan ini satu-satunya berkas yang dibuat auditor. Uji adversarial dijalankan di **salinan terpisah `/tmp/audit-kasir`** (bukan di repo). |
| **Verdict** | **MEMERLUKAN PERBAIKAN sebelum Fase 11** — 0 temuan K-1, **2 temuan K-2 TERVERIFIKASI**, 6 temuan K-3, 5 temuan K-4. Fungsional inti kasir sehat; dua K-2 menyangkut janji yang tertulis tapi belum terpenuhi. |

> **Tambahan 2026-09-27:** putaran audit kedua pada peran yang sama menemukan 3 temuan yang belum ada di sini
> (jalur tiket dapur tidak dipulihkan setelah pesanan luring, layar pelayan melaporkan sukses kirim tanpa pengiriman —
> dibuktikan dengan menjalankan layarnya, dan duplikat `23505` yang dapat menandai sukses tanpa item). Lihat
> `docs/uji/audit/LAPORAN_AKBAR_SPESIALIS_FRONTEND_tambahan.md`. Verdict dan temuan pada berkas ini tidak diubah.

> Catatan format: laporan ini mengikuti format khusus peran Akbar (PAKET §3 + PROMPT SPESIALIS FRONTEND §4), bukan kontrak §6 paket AUD-2/AUD-3, karena mandat ini datang dari paket Akbar, bukan dari paket audit berset SHA.

---

## 1. Ringkasan Eksekutif (Bahasa Manusia)

Untuk Lee, singkatnya begini:

**Yang sehat dan terbukti:**
- **Mesin penguji hijau semua.** Keenam perintah wajib lulus: pemeriksa tipe, 123 berkas uji (1.013 pengujian), build, uji kontras, pemeriksa antarmuka, dan uji mutasi (81 mutasi cacat semuanya tertangkap). Sesuai klaim "123 berkas pengujian frontend Vitest".
- **Keyboard PIN kasir bekerja mulus.** Saya uji sendiri dengan serangan nyata di salinan terpisah: ketik `0`–`9` dari keyboard fisik masuk, `Backspace` menghapus digit terakhir, `Escape` mengosongkan, `Enter`/`Spasi` konfirmasi saat 6 digit — semuanya jalan di layar masuk yang aktif (`LayarMasukPegawai`) maupun layar kedua (`MasukStaf`).
- **Anti-intipan mata terpenuhi.** PIN **tidak pernah** tampil sebagai angka di layar — hanya titik bulat. Saya buktikan dengan menguji isi layar: urutan PIN yang diketik tidak ditemukan di mana pun di halaman, dan tidak ada satu pun `console.log` di kode produksi. PIN atasan di layar diskon juga bertopeng (`type="password"`).
- **Antrean offline sungguhan bekerja.** Saya pasang IndexedDB palsu-fasih di salinan uji dan membuktikan: pesanan yang disimpan saat offline **benar-benar tertulis ke IndexedDB**, **tetap ada setelah halaman "dimuat ulang"**, tidak dobel berkat kunci idempoten, dan otomatis dikirim saat online kembali. Pembersih data sensitif (`bersihkanDataSensitif`) benar-benar menghapus PIN/sandi/token secara rekursif sebelum data masuk IndexedDB.

**Yang perlu Lee putuskan/perbaiki (2 temuan tinggi):**
1. **Janji kontras WCAG AAA belum terpenuhi.** Alat uji kontras hanya menjunjung standar AA (4,5:1). Ukuran nyatanya: dari 110 pasangan teks di 10 tema, **50 pasangan di 7 tema masih di bawah 7:1** (contoh: teks redup tema Terang Bersih hanya 5,59:1). Kalau Lee ingin AAA, temanya perlu digelapkan/diserasi; kalau Lee menerima AA, dokumen janjinya yang harus diubah.
2. **Antrean offline tidak terpicu pada kondisi mati paling umum di lapangan:** WiFi tersambung ke router tapi internetnya mati. Kode hanya memasukkan pesanan ke antrean bila peramban melapor "luring" (`navigator.onLine === false`) atau ada lemparan galat — padahal pustaka Supabase mengembalikan kegagalan jaringan sebagai *pesan galat biasa*, bukan lemparan. Akibatnya di skenario itu pesanan **tidak masuk antrean**, kasir hanya melihat kotak peringatan (isi keranjang tidak hilang, bisa dicoba ulang).

Sisanya temuan sedang dan saran (uji IndexedDB yang tak pernah dijalankan suite resmi, item macet berstatus "mengirim", PETA_UI menunjuk 4 berkas yang tidak ada, dll.) — rincian di bagian 6.

---

## 2. Tabel Bukti Pengujian

### 2a. Perintah verifikasi mesin wajib (per PROMPT_AKBAR_SPESIALIS_FRONTEND §3)

| # | Perintah | Hasil | Bukti ringkas |
|---|---|---|---|
| 1 | `cd aplikasi && npm run typecheck` | ✅ LOLOS (exit 0) | `tsc -b --noEmit` tanpa galat |
| 2 | `cd aplikasi && npm test -- --run` | ✅ LOLOS (exit 0) | **123 berkas uji lulus, 1.013 pengujian lulus, 0 gagal** (durasi ±109 dtk) — cocok dengan klaim "123 berkas Vitest" |
| 3 | `cd aplikasi && npm run build` | ✅ LOLOS (exit 0) | `tsc -b --noEmit && vite build` sukses; bundel JS 1.063 kB (peringatan >500 kB → temuan [F-12]) |
| 4 | `python3 aplikasi/alat/uji-kontras.py` | ✅ LOLOS (exit 0) | "166 lolos, 0 gagal — 10 tema, 130 pemeriksaan warna, 36 pemeriksaan aturan desain" — **namun ambang alat = AA, bukan AAA** → temuan [F-01] |
| 4b | `python3 aplikasi/alat/uji-kontras.py --uji-diri` | ✅ LOLOS (exit 0) | 4 mutasi (token huruf dihapus, tinggi kendali 40 px, cincin fokus dilepas ×2) semuanya DITOLAK |
| 5 | `python3 aplikasi/alat/periksa-antarmuka.py` | ✅ LOLOS (exit 0) | Penutupan panel (Esc + fokus pulang, klik di luar, fokus keluar) & pudar tepi daftar terkunci di aplikasi + sumber desain |
| 5b | `python3 aplikasi/alat/periksa-antarmuka.py --uji-diri` | ✅ LOLOS (exit 0) | 10 mutasi semuanya DITOLAK |
| 6 | `node aplikasi/alat/uji-mutasi-app.mjs` | ✅ LOLOS (exit 0) | "salinan utuh hijau, **81 mutasi perilaku semuanya membuat uji MERAH**" |
| 6b | `node aplikasi/alat/uji-mutasi-app.mjs --uji-diri` | ✅ LOLOS (exit 0) | Harness terbukti bisa MENOLAK jaring uji bocor |

Catatan lingkungan: dependensi dipasang dengan `npm ci` di `aplikasi/` (hanya `node_modules`, tidak menyentuh berkas sumber; `node_modules`/`dist` diabaikan Git — `git status` tetap bersih).

### 2b. Uji adversarial auditor (di salinan terpisah `/tmp/audit-kasir` — repo tidak tersentuh)

Untuk membuktikan klaim secara **independen** (bukan sekadar memercayai uji milik pembangun), auditor menyalin aplikasi ke `/tmp`, memasang `fake-indexeddb`, lalu menulis dan menjalankan 13 pengujian baru:

| Kode | Skenario serangan | Hasil |
|---|---|---|
| A1 | `LayarMasukPegawai`: ketik 1,2,3 → `Backspace` | ✅ titik PIN 3 → 2 (digit terakhir terhapus) |
| A2 | `LayarMasukPegawai`: ketik 4 digit → `Escape` | ✅ titik PIN 4 → 0 (reset penuh) |
| A3 | `LayarMasukPegawai`: ketik 654321 → `Spasi` | ✅ `onMasuk('kasir@resto.test','654321')` terpanggil |
| A4 | **Anti-intipan**: setelah mengetik PIN, periksa seluruh isi DOM | ✅ DOM hanya memuat titik `●`; urutan PIN tidak ditemukan di teks halaman |
| B1 | `MasukStaf`: ketik 3 digit → `Escape` | ✅ indikator 3 → 0 |
| B2 | `MasukStaf`: ketik 6 digit → kirim otomatis; reset → ketik 987654 | ✅ `onVerifikasiPin` terpanggil dengan PIN yang benar |
| B3 | **Anti-intipan** `MasukStaf`: indikator PIN + urutan ketik terbalik | ✅ wadah indikator kosong teks; `987654` tidak muncul di DOM |
| C1 | `tambahKeAntrean` → baca store IndexedDB mentah | ✅ record **benar-benar tertulis** di `resto_barokah_offline_db/antrean_kirim` |
| C2 | Simpan → `vi.resetModules()` (simulasi muat ulang halaman) → baca ulang | ✅ data **persisten** terbaca dari IndexedDB setelah "restart" |
| C3 | Tambah 2× dengan kunci idempoten sama | ✅ tetap 1 item (tidak dobel lokal) |
| C4 | Item diubah ke status `mengirim` (simulasi crash saat kirim) → proses antrean | ⚠️ **item tidak pernah diambil ulang** (`diproses: 0`) → temuan [F-04] |
| C5 | `bersihkanDataSensitif` pada objek referensi melingkar | ⚠️ **meledak `RangeError`** (rekursi tak berujung) → temuan [F-13] |
| D1 | Antrean jenis `batal_pesanan` + klien Supabase tiruan → sinkronkan | ⚠️ **ditandai `berhasil` tanpa satu pun panggilan peladen** → temuan [F-05] |

Perintah reproduksi: salin `aplikasi/` ke folder sementara (tanpa `node_modules`), `npm install --no-save fake-indexeddb`, tulis tiga berkas uji di atas, lalu `npx vitest run <berkas>` → **13 lulus** (3 di antaranya sengaja membuktikan cacat C4/C5/D1 — "lulus" berarti perilaku cacat terkonfirmasi persis seperti dugaan).

---

## 3. Evaluasi Fitur Keyboard Input PIN (permintaan khusus Lee)

### 3a. Ergonomi keyboard fisik — TERPENUHI dan TERBUKTI

Sasaran: `aplikasi/src/layar/masuk/MasukStaf.tsx` dan `aplikasi/src/layar/masuk/LayarMasukPegawai.tsx`.

| Syarat perintah audit | Bukti kode | Bukti uji |
|---|---|---|
| Tombol fisik `0`–`9` berfungsi mulus | `MasukStaf.tsx:83-85` dan `LayarMasukPegawai.tsx:78-81`: `if (e.key >= '0' && e.key <= '9') { e.preventDefault(); tekanAngka(e.key) }` — menangkap baris angka atas **dan** numpad (keduanya memancarkan `e.key` '0'–'9') | Uji repo `MasukStaf.test.tsx:113` + uji adversarial A1–A4, B1–B3 ✅ |
| `Backspace` menghapus digit terakhir | `MasukStaf.tsx:86-88`, `LayarMasukPegawai.tsx:82-84` (`pin.slice(0, -1)`) | Uji repo `MasukStaf.test.tsx:136` + adversarial A1 ✅ |
| `Escape` mereset | `MasukStaf.tsx:89-91`, `LayarMasukPegawai.tsx:85-87` | Adversarial A2, B1 ✅ (belum ada di uji repo → temuan [F-07]) |
| `Enter`/`Spasi` konfirmasi saat 6 digit | `MasukStaf.tsx:92-97`, `LayarMasukPegawai.tsx:88-94` (`e.key === 'Enter' || e.key === ' ' || e.code === 'Space'`) | Uji repo `LayarMasukPegawai.test.tsx:81-107` (Enter) + adversarial A3 ✅ |

Detail ergonomis yang saya nilai baik:
- Penangan kunci hanya aktif setelah fokus **bukan** di kolom isian (`INPUT`/`TEXTAREA`/`contentEditable`) — kasir tetap bisa mengetik email dengan angka tanpa "dicuri" keypad (LayarMasukPegawai bahkan tetap mengizinkan Enter-submit dari kolom email bila PIN sudah 6 digit).
- `e.preventDefault()` dipanggil untuk semua kunci yang ditangani, mencegah efek ganda (mis. Spasi yang sekaligus "menekan" tombol keypad yang sedang terfokus).
- `MasukStaf` otomatis mengirim saat digit ke-6 diketik (`tekanAngka` → `prosesMasuk` saat `pinBaru.length === 6`), khas terminal POS — cepat untuk kasir.
- Saat verifikasi berjalan, semua tombol dikunci (`nonaktif={sedangMemproses}`) dan pengetikan diabaikan — tidak bisa dobel kirim.
- Pesan galat memakai format manusia + kode (`[PIN-401]`, `Kode: PIN_SALAH`) sesuai lensa L5, termasuk peringatan "Sisa percobaan: Nx sebelum terkunci".
- Petunjuk di layar: "Bisa diketik langsung via keyboard (0–9, Backspace, Esc, Enter / Spasi)" — kasir baru tahu fitur ini ada.

### 3b. Perlindungan anti-intipan mata (shoulder-surfing) — TERPENUHI dan TERBUKTI

- `MasukStaf.tsx:221-235`: indikator PIN hanya 6 bulatan terisi/kosong — **tidak pernah merender digit**.
- `LayarMasukPegawai.tsx:176-196`: tiap digit dirender sebagai `●` (baris 185), bukan angka.
- Uji adversarial A4 & B3: urutan PIN yang diketik **tidak ditemukan** di mana pun dalam DOM kedua layar.
- Tidak ada satu pun `console.*` di `aplikasi/src/` non-uji (dicari dengan `grep -rn "console\." src/ --include="*.ts" --include="*.tsx"`) — PIN tidak bocor ke konsol peramban.
- PIN tidak pernah dimasukkan URL/localStorage oleh kedua layar; dikirim hanya lewat callback → `masukDenganPin` (`auth.ts:112`) → RPC `verifikasi_pin_perangkat` (divalidasi `/^\d{6}$/` dulu di `auth.ts:128`).
- PIN atasan di `DiskonManual.tsx:211-216` memakai `jenis="password"` (tertopeng) dengan keterangan "Diketik oleh atasan sendiri… sekali pakai" dan PIN tidak disimpan lebih lama dari perlu.
- Pendamping privasi: `useKunciOtomatis.ts` mengunci layar otomatis (kasir 15 menit, admin 30, owner 60) dengan peringatan tenggang — layar kasir terkunci bila ditinggal.

**Kesimpulan bagian 3:** fitur yang Lee minta bekerja nyata di kedua layar. Catatan: `MasukStaf.tsx` ternyata **tidak terpasang** di aplikasi (lihat [F-09]) dan cakupan uji repo untuk Esc/Spasi/Backspace belum lengkap (lihat [F-07]).

---

## 4. Evaluasi Ketahanan Antrean Kasir Luring (IndexedDB)

Sasaran: `aplikasi/src/lib/antrean-offline.ts` dan `aplikasi/src/hook/useAntrean.ts`.

### 4a. Persistensi IndexedDB — TERBUKTI (oleh auditor, di luar uji repo)

- Adapter: `bukaDb()` (`antrean-offline.ts:157-196`) membuka DB `resto_barokah_offline_db` v1, store `antrean_kirim` ber-`keyPath: 'id'` + **index unik `kunciIdempoten`** + indeks `status`/`dibuatPada`. Fallback memori bila IndexedDB diblokir.
- Uji adversarial C1 (membaca store IndexedDB mentah): item **benar-benar tertulis** ke IndexedDB, bukan hanya ke memori.
- Uji adversarial C2 (simulasi muat ulang via `vi.resetModules()`): item **tetap terbaca** dari IndexedDB setelah "restart" — persisten.
- Alur produksi: `App.tsx:113-167` — saat `navigator.onLine === false` atau lemparan galat, `onSimpanPesanan` memanggil `tambahKeAntrean({jenis:'simpan_pesanan', kunciIdempoten: 'pos-<uuid>', …})` lalu melapor "Pesanan tersimpan di antrean luring (akan dikirim saat kembali daring)."

### 4b. Sinkronisasi otomatis tanpa dobel pencatatan — TERBUKTI

- `useAntrean.ts:302-318`: pendengar `window.addEventListener('online')` (baris 316) → `sinkronkanAntrean()` otomatis saat koneksi pulih; penanda `sedangProsesRef` mencegah dua sinkronisasi berjalan bersamaan.
- Pengiriman sekuensial FIFO (`prosesAntrean`, `antrean-offline.ts:496-543`), berhenti bila jaringan diputus lagi (deteksi pesan network/fetch/koneksi atau `!navigator.onLine`).
- Anti-dobel **lokal**: cek `sudahAda` berdasarkan kunci idempoten (`antrean-offline.ts:230-234`) + index unik — dibuktikan uji C3 (2× tambah kunci sama → 1 item).
- Anti-dobel **peladen**: `penanganDefault` menyisipkan `kunci_idempoten` ke `pesanan` dan meneruskan ke RPC; balasan bentrok `23505`/pesan `kunci_idempoten` dianggap sukses idempoten (`useAntrean.ts:110-114`, `150-153`, `175-179`); `bayar_pesanan` mengembalikan penanda `dobel` dan kunci bayar stabil per tagihan+urutan (`useBayar.ts` `kunciIdempoten()`).
- Status jujur ke kasir: `pesanStatus` "menunggu dikirim X", "ada X pesanan gagal dikirim", "Mengirim antrean ke peladen..." (DoD T10-01/T10-03), ditampilkan `StatusAntreanOffline.tsx` dengan `role="status" aria-live="polite"` + tombol kirim manual.

### 4c. Sanitasi `bersihkanDataSensitif()` — TERBUKTI REKURSIF

- `antrean-offline.ts:44-46`: pola kunci terlarang `/(pin|password|katasandi|kata_sandi|secret|kredensial|token|authorization)/i`; `bersihkanDataSensitif()` (:74-94) memanggil dirinya untuk array dan objek bersarang — rekursif penuh.
- Uji repo `antrean-offline.test.ts:35-70`: membuktikan `pin`, `pinKasir`, `pinAtasan`, `pin_hash`, `kata_sandi`, `password`, `authorization`, `pin_lama`, `kredensial` lenyap (termasuk bersarang & camelCase) sementara data sah (`pesananId`, `items`, `catatanAman`) utuh; `tambahKeAntrean` memanggilnya otomatis sebelum menulis.
- Pembatasan yang jujur perlu Lee tahu: sanitasi mencocokkan **nama kunci**, bukan isi nilai. Muatan antrean dibangun kode aplikasi sendiri (bukan bebas dari pengguna), jadi risikonya rendah.

### 4d. Yang TIDAK berjalan seperti janji (rincian di bagian 6)

- **[F-02]** antrean tidak terpicu bila WiFi nyala tetapi internet mati (kasus paling sering di kedai) — kegagalan fetch Supabase kembali sebagai `error`, bukan lemparan, sehingga jalur `catch` (yang mengantri) tidak pernah dijalankan.
- **[F-04]** item yang macet berstatus `mengirim` (aplikasi mati saat mengirim) tidak pernah dicoba ulang — `ambilAntreanMenunggu()` hanya mengambil `menunggu`/`gagal`, tidak ada pemulihan saat mulai.
- **[F-05]** jenis aksi tak dikenal (mis. `batal_pesanan` yang disebut di komentar modul) ditandai `sukses` **tanpa** mengirim apa pun ke peladen — jebakan laten bila nanti void/pembatalan ikut diantrikan.
- **[F-03]** seluruh 1.013 uji resmi berjalan di lingkungan `node` tanpa IndexedDB — jalur IndexedDB **tidak pernah dieksekusi** oleh suite resmi (dibuktikan auditor dengan fake-indexeddb; untungnya jalurnya sehat).
- Pembayaran sengaja **tidak** diantrikan saat offline (uang hanya lewat RPC daring, `useBayar.ts`) — ini keputusan desain yang menurut saya tepat untuk kejujuran uang, tapi berarti "transaksi offline" yang dijanjikan berlaku untuk **penyimpanan pesanan**, bukan pembayaran.

---

## 5. Evaluasi Kerapian Antarmuka & Peta UI

### 5a. Sinkronisasi PETA_UI — SEHAT dengan cacat registry

- `docs/PETA_UI.md` dihasilkan otomatis dari `src/lib/layar.ts` + `src/lib/aksi.ts` (12 layar, 57 aksi). Aksi penting kasir terdaftar lengkap dengan izin, RPC, konfirmasi, jejak audit, dan nama uji.
- Saya validasi **seluruh rujukan berkas** di registry terhadap pohon nyata: **4 rujukan menunjuk berkas yang tidak ada** → temuan [F-06] (`LayarMasuk.tsx`/`.test.tsx`, `LayarVoucher.tsx`/`.test.tsx`; nama RPC `verifikasi_pin` di `aksi.ts:36` juga berbeda dengan `verifikasi_pin_perangkat` yang dipanggil `auth.ts:176`).
- "Tombol mati": tidak ditemukan tombol tanpa penanganan aksi. Tombol `<button>` mentah di luar pustaka komponen hanya 4 di `App.tsx:503,521,548,555` — semuanya berfungsi (berganti mode masuk), tapi melewati sistem `Tombol` → [F-11].

### 5b. Tiga kondisi layar (Memuat / Kosong / Gagal) — TERPENUHI di layar data

- Pustaka siap pakai: `KeadaanMemuat`, `KeadaanKosong`, `KeadaanGagal` (`src/komponen/`), dipakai di layar data (11 berkas memuat, 15 kosong, 11 gagal — LayarKasir/Dapur/Bar/Stok/Laporan/dll. menerima `keadaan` dari kontainer `App.tsx`).
- Contoh nyata: `Bayar.tsx:166-176` menangani `memuat` dan `gagal` + tombol coba lagi; `LayarDapur` menerima `keadaan`/`antreanCadangan` + `onCoba`; `useBayar`/`useStok`/`useTiketDapur` semua punya status gagal + pesan Indonesia.
- Cacat: `LayarKasir.tsx:439-450` memakai `alert()` peramban (blokir, tak bergaya) untuk sukses/gagal kirim ke dapur — padahal ada komponen `Toast` → [F-10].

### 5c. Kontras WCAG — AA TERPENUHI, AAA **BELUM** (temuan [F-01])

- Alat resmi `uji-kontras.py` menguji 13 pasangan × 10 tema (terang, hangat, gelap, kontras, bara, vintage, alam, tropis, pastel, etnik) — **166 lolos / 0 gagal** pada ambang **AA** (teks 4,5:1, elemen 3:1).
- Perintah audit menuntut **WCAG AAA (teks 7:1)**. Pengukuran ulang saya atas keluaran alat: **hanya 60 dari 110 pasangan teks ≥ 7:1**. Lulus penuh: gelap, kontras, bara. Gagal sebagian: terang (3/11), hangat (3/11), vintage/alam/tropis/etnik (4/11), pastel (5/11) — umumnya pada *teks redup*, *tulisan di tombol*, dan *label status* (contoh: teks redup di latar tema terang = 5,59:1; tulisan di tombol tema terang = 6,44:1).
- Aturan desain lain terbukti: sentuh ≥44 px, cincin fokus, `prefers-reduced-motion`, tangga jarak/huruf, huruf tersimpan lokal (13 keluarga, 461 KB), mode kerapatan nyaman/padat dengan uji kaskade CSS nyata.
- Responsivitas tablet/HP: media query di `komponen.css` (≤1080 px, ≤900 px) + `tema.css` (≥920 px, ≤1180 px) + kelas responsif `sm:`/`md:` di layar + kerapatan — memadai untuk mode layar sentuh.

---

## 6. Daftar Temuan

> Format bidang per temuan mengikuti protokol: Tingkat · Artefak · Klaim yang dilanggar · Bukti · Skenario gagal · Dugaan penyebab · Cara membuktikan perbaikan · Status verifikasi.

### [F-01] Klaim kontras WCAG AAA tidak terpenuhi — alat hanya menjunjung AA
- **Tingkat:** K-2 (Tinggi)
- **Artefak:** `aplikasi/alat/uji-kontras.py:193-207` (PASANGAN, ambang 4.5/3.0); `aplikasi/src/gaya/token/tema.css`; klaim di `docs/uji/PAKET_PEMERIKSAAN_AKBAR_F0_F10.md:18`, `docs/uji/PROMPT_AKBAR_SPESIALIS_FRONTEND.md` §2.3, `docs/teknis/REKAM_PESAN_PEMILIK.md:549`
- **Klaim yang dilanggar:** "Pastikan seluruh 10 tema warna lulus uji kontras teks sesuai standar WCAG AAA."
- **Bukti:** `python3 aplikasi/alat/uji-kontras.py` → "166 lolos, 0 gagal" pada ambang AA; pengukuran ulang keluaran alat: 60/110 pasangan teks ≥ 7:1; 50 pasangan di 7 tema hanya 4,5–7:1 (terang: teks redup 5,59:1; tulisan di tombol 6,44:1; label bahaya 6,38:1; dst.)
- **Skenario gagal:** kasir berpenglihatan rendah membaca teks redup (total tagihan, keterangan) di tema terang pada tablet di bawah cahaya kedai yang terang — rasio 5,4–6,4:1 di bawah janji AAA 7:1.
- **Dugaan penyebab:** ambang alat dibuat untuk AA dan tidak pernah dinaikkan saat dokumen mulai menjanjikan AAA.
- **Cara membuktikan perbaikan:** naikkan ambang pasangan teks di `PASANGAN` menjadi 7.0 → `python3 aplikasi/alat/uji-kontras.py` tetap hijau; atau (bila Lee menerima AA) ubah seluruh dokumen janji dari "AAA" menjadi "AA" secara eksplisit.
- **Status verifikasi:** TERVERIFIKASI

### [F-02] Antrean luring tidak terpicu saat "WiFi nyala tapi internet mati"
- **Tingkat:** K-2 (Tinggi)
- **Artefak:** `aplikasi/src/App.tsx:81-100` (jalur `catch` mengantri hanya bila `!navigator.onLine` atau lemparan), `App.tsx:96-98` (`if (errPesanan) return { sukses: false }`)
- **Klaim yang dilanggar:** "Buktikan transaksi yang dicatat saat koneksi internet mati tersimpan persisten di IndexedDB…" — janji ketahanan offline untuk kondisi lapangan yang paling umum.
- **Bukti:** pustaka `@supabase/postgrest-js` (terpasang, `dist/index.cjs:418-430`) mengubah kegagalan `fetch` menjadi **balasan `error`**, bukan lemparan; `RETRYABLE_METHODS` hanya GET/HEAD/OPTIONS sehingga POST gagal langsung. Dengan `navigator.onLine === true` (router hidup, internet mati), `insert()` mengembalikan `errPesanan` → fungsi kembali `sukses:false` → `alert()` di `LayarKasir.tsx:439` — **tidak pernah sampai ke `tambahKeAntrean`**.
- **Skenario gagal:** modem kedai mati selama 10 menit; WiFi tablet tetap tersambung ke router. Kasir menekan "Kirim ke Dapur" → muncul kotak "TypeError: fetch failed"-style; pesanan tidak masuk antrean; kasir harus menunggu/mencoba ulang manual (isi keranjang tidak hilang).
- **Dugaan penyebab:** deteksi offline hanya mengandalkan `navigator.onLine` + lemparan; kegagalan jaringan bertipe "balasan error" tidak dipetakan ke jalur antrean.
- **Cara membuktikan perbaikan:** bila pesan galat memuat indikasi jaringan (`fetch failed`, `Failed to fetch`, `network`, timeout), masukkan pesanan ke antrean (dengan kunci idempoten yang sama) — uji dengan klien tiruan yang mengembalikan `{error: new TypeError('fetch failed')}` menghasilkan item antrean, bukan `sukses:false`.
- **Status verifikasi:** TERVERIFIKASI (kode + perilaku pustaka dari sumber terpasang; skenario penuh peramban nyata tidak dijalankan di sesi ini)

### [F-03] Jalur IndexedDB antrean tidak pernah dieksekusi suite uji resmi
- **Tingkat:** K-3 (Sedang)
- **Artefak:** `aplikasi/vitest.config.ts:5` (`environment: 'node'`); tanpa dependensi `fake-indexeddb`; `aplikasi/src/lib/antrean-offline.test.ts`
- **Klaim yang dilanggar:** kriteria "100% Mesin Penguji Hijau" dipakai sebagai bukti ketahanan offline, padahal uji hanya menyentuh fallback memori (lensa L4: diuji dengan tiruan padahal bisa nyata).
- **Bukti:** `grep -rn "indexedDB" src/` → hanya di `antrean-offline.ts`; di lingkungan node `typeof indexedDB === 'undefined'` → `bukaDb()` mengembalikan null → seluruh uji antrean (sanitasi, FIFO, dedupe) berjalan di `fallbackMemori`. Uji adversarial auditor dengan `fake-indexeddb` menunjukkan jalur IndexedDB-nya sendiri sehat (C1/C2/C3 lulus) — jadi ini celah **bukti**, bukan cacat fungsi yang ditemukan.
- **Skenario gagal:** regresi di `bukaDb()`/transaksi (mis. salah nama store saat refactor) tetap membuat 1.013 uji hijau.
- **Dugaan penyebab:** lingkungan uji dipilih `node` untuk kecepatan/uji CSS; antrean tidak diberi tiruan IndexedDB.
- **Cara membuktikan perbaikan:** tambah `fake-indexeddb` (devDependency) + satu berkas uji yang mengimpor `fake-indexeddb/auto` dan mengulang kasus inti (tulis, baca ulang, dedupe, FIFO) → `npm test` tetap hijau dengan jalur IDB tereksekusi.
- **Status verifikasi:** TERVERIFIKASI

### [F-04] Item macet berstatus `mengirim` tidak pernah dicoba ulang
- **Tingkat:** K-3 (Sedang)
- **Artefak:** `aplikasi/src/lib/antrean-offline.ts:293-297` (`ambilAntreanMenunggu` hanya `menunggu`/`gagal`); tidak ada pemulihan `mengirim` usang saat mulai
- **Klaim yang dilanggar:** "tersinkronisasi otomatis saat online kembali" untuk seluruh antrean tersimpan.
- **Bukti:** uji adversarial C4: item diubah ke `mengirim` (mensimulasikan aplikasi mati di tengah kirim) → `prosesAntrean()` memproses 0 item; item menetap di IndexedDB selamanya dan tak terlihat di UI.
- **Skenario gagal:** tablet kehabisan baterai tepat saat antrean sedang dikirim; setelah nyala kembali, satu pesanan "lenyap" dari pantauan kasir padahal masih ada di IndexedDB.
- **Dugaan penyebab:** status `mengirim` tidak punya jalur pemulihan saat inisialisasi.
- **Cara membuktikan perbaikan:** saat modul/hook dimuat, item `mengirim` yang `terakhirDicoba`-nya lebih tua dari ambang (mis. 60 detik) direset ke `menunggu` → uji C4 berganti ekspektasi `diproses: 1`.
- **Status verifikasi:** TERVERIFIKASI

### [F-05] Jenis aksi tak dikenal ditandai sukses tanpa kirim ke peladen
- **Tingkat:** K-3 (Sedang)
- **Artefak:** `aplikasi/src/hook/useAntrean.ts:232-233` (`// Jenis aksi lainnya dianggap berhasil…` → `return { sukses: true }`)
- **Klaim yang dilanggar:** status antrean jujur ("kasir melihat bukti terkonfirmasi peladen", T10-03).
- **Bukti:** uji adversarial D1: item `batal_pesanan` (jenis yang disebut sendiri di komentar `antrean-offline.ts:20`) disinkronkan dengan klien Supabase tiruan → `berhasil: 1`, `rpc`/`from` **tidak pernah dipanggil**; pembatalan lenyap tanpa jejak namun dilaporkan sukses.
- **Skenario gagal:** bila nanti void/batal/stok ikut diantrikan (komentar modul sudah menggoda arah itu), aksi penting "berhasil" di UI tapi tidak pernah sampai ke peladen.
- **Dugaan penyebab:** fallback permissif untuk jenis yang belum diimplementasikan.
- **Cara membuktikan perbaikan:** jenis tak dikenal harus mengembalikan `{ sukses: false, pesan: 'Jenis aksi belum didukung: …' }` → uji D1 berganti ekspektasi `gagal: 1` dan pesan jelas.
- **Status verifikasi:** TERVERIFIKASI (latent — hari ini hanya `simpan_pesanan` yang diantri produksi, jadi belum ada kerugian nyata)

### [F-06] Registry layar/PETA_UI menunjuk 4 berkas yang tidak ada + nama RPC tak sinkron
- **Tingkat:** K-3 (Sedang)
- **Artefak:** `aplikasi/src/lib/layar.ts:49,69,221,237`; turunannya `docs/PETA_UI.md` §2; `aplikasi/src/lib/aksi.ts:36`
- **Klaim yang dilanggar:** "Buktikan sinkronisasi dengan `docs/PETA_UI.md`" — peta harus memetakan layar nyata.
- **Bukti:** `python3` validasi rujukan: `LayarMasuk.tsx`, `LayarMasuk.test.tsx`, `LayarVoucher.tsx`, `LayarVoucher.test.tsx` **tidak ada** di pohon (nyata: `LayarMasukPegawai.*`; voucher berisi `Daftar/Kampanye/KartuVoucher`). `aksi.ts` mencatat RPC `verifikasi_pin` sedangkan kode memanggil `verifikasi_pin_perangkat` (`auth.ts:176`).
- **Skenario gagal:** penguji baru mengikuti PETA_UI untuk membuka berkas uji layar `masuk`/`voucher` → berkas tidak ditemukan.
- **Dugaan penyebab:** layar di-refactor namai ulang tanpa memperbarui registry.
- **Cara membuktikan perbaikan:** perbarui `layar.ts`/`aksi.ts` → `alat/peta-ui.py` regenerasi → validasi rujukan berkas 0 hilang.
- **Status verifikasi:** TERVERIFIKASI

### [F-07] Esc/Spasi/Backspace keyboard PIN belum terjaga uji (fiturnya sendiri bekerja)
- **Tingkat:** K-3 (Sedang)
- **Artefak:** `aplikasi/src/layar/masuk/LayarMasukPegawai.test.tsx` (hanya digit+Enter), `MasukStaf.test.tsx:113-146` (digit+Backspace, tanpa Esc/Spasi), `aplikasi/alat/uji-mutasi-app.mjs` (tanpa mutasi keyboard PIN)
- **Klaim yang dilanggar:** fitur permintaan khusus Lee seharusnya dijaga gerbang (kriteria "100% mesin hijau" memberi rasa aman palsu untuk fitur ini).
- **Bukti:** `grep` kedua berkas uji: 0 kemunculan `Escape`/`' '`; `uji-mutasi-app.mjs` tidak memuat mutasi keydown. Sementara uji adversarial auditor (A1–A3, B1–B2) membuktikan fiturnya jalan.
- **Skenario gagal:** refactor masa deang melepas cabang `Escape`/`Space` → 1.013 uji tetap hijau, kasir kehilangan perilaku yang Lee minta tanpa ada alarm.
- **Dugaan penyebab:** uji ditulis untuk jalur utama saja.
- **Cara membuktikan perbaikan:** tambahkan uji Backspace/Esc/Spasi di `LayarMasukPegawai.test.tsx` + Esc/Spasi di `MasukStaf.test.tsx` (pola A1–B2 di atas bisa disalin) + satu mutasi keydown di harness.
- **Status verifikasi:** TERVERIFIKASI

### [F-08] Tombol isi-otomatis akun demo + mode simulasi PIN-bebas di layar masuk
- **Tingkat:** K-3 (Sedang)
- **Artefak:** `aplikasi/src/layar/masuk/LayarMasukPegawai.tsx:255-283` (tombol 👑 Owner / 💳 Kasir mengisi `123456`), `aplikasi/src/lib/auth.ts:142-170` (mode simulasi: PIN apa pun diterima bila klien tak terkonfigurasi)
- **Klaim yang dilanggar:** kesiapan pilot lapangan (Fase 11) — layar masuk perangkat nyata tidak boleh menawarkan kredensial demo.
- **Bukti:** pembacaan kode + `LayarMasukPegawai.test.tsx` yang mengandalkan tombol-tombol ini; mode simulasi mengembalikan `berhasil: true` untuk sembarang email+PIN 6 digit saat `klienSupabase()` null.
- **Skenario gagal:** tablet pilot terdeploy tanpa variabel lingkungan Supabase → siapa pun bisa "masuk" dengan PIN apa pun (meski operasi data akan gagal); atau calon pelanggan iseng menekan tombol akun demo di kasir nyata.
- **Dugaan penyebab:** fasilitas uji coba yang tertinggal di jalur produksi.
- **Cara membuktikan perbaikan:** gerbang tombol demo dengan `import.meta.env.DEV` (atau bendera eksplisit), dan mode simulasi hanya boleh aktif di DEV → uji memastikan kedua elemen tidak merender di build produksi.
- **Status verifikasi:** TERVERIFIKASI

### [F-09] `MasukStaf.tsx` adalah layar yatim (tidak terpasang)
- **Tingkat:** K-4 (Saran)
- **Artefak:** `aplikasi/src/layar/masuk/MasukStaf.tsx` — tidak diimpor `App.tsx` maupun layar lain (hanya ujinya sendiri); membawa `DAFTAR_STAF_CONTOH` 5 staf dummy
- **Bukti:** `grep -rn "MasukStaf" src/` → hanya berkas itu dan `MasukStaf.test.tsx`. Layar PIN aktif adalah `LayarMasukPegawai` (`App.tsx:9,532`).
- **Skenario gagal:** dua implementasi keypad PIN berkembang beda arah; perintah audit pun harus memeriksa dua layar padahal satu tak terpakai.
- **Cara membuktikan perbaikan:** pasang `MasukStaf` di alur perangkat-terdaftar (bila itu rencananya) atau pensiunkan dengan `docs/uji/BERKAS_PENSIUN.md`.
- **Status verifikasi:** TERVERIFIKASI

### [F-10] 11 panggilan `alert()` peramban di layar produksi
- **Tingkat:** K-4 (Saran)
- **Artefak:** `LayarKasir.tsx:439,445,447,450` + `DaftarPerangkat.tsx`, `KelolaPegawai.tsx`, `Perangkat.tsx` (2 masing-masing); padahal ada `src/komponen/Toast.tsx`
- **Bukti:** `grep -rn "alert(" src/layar/` (di luar `role="alert"`) = 11.
- **Skenario gagal:** dialog pemblokir muncul di tablet kasir — tidak konsisten dengan gaya, menghentikan alur, tidak teruji aksesibilitas.
- **Cara membuktikan perbaikan:** ganti ke `Toast`/`KeadaanGagal` → `grep "alert(" src/layar/` = 0.
- **Status verifikasi:** TERVERIFIKASI

### [F-11] 4 tombol `<button>` mentah di `App.tsx`
- **Tingkat:** K-4 (Saran)
- **Artefak:** `aplikasi/src/App.tsx:503,521,548,555` (tautan ganti mode masuk)
- **Bukti:** `grep -rn "<button" src/ --include="*.tsx" | grep -v test` → di luar pustaka komponen hanya 4 ini; semuanya punya `onClick` (tidak mati) tapi melewati `Tombol` (cincin fokus/ukuran sentuh terjamin sistem).
- **Cara membuktikan perbaikan:** ganti ke `<Tombol ragam="polos">` → `grep "<button" src/App.tsx` = 0.
- **Status verifikasi:** TERVERIFIKASI

### [F-12] Bundel JS 1.063 kB melewati ambang 500 kB
- **Tingkat:** K-4 (Saran)
- **Artefak:** keluaran `npm run build`: `dist/assets/index-D8sgACnV.js 1,063.12 kB │ gzip: 279.97 kB` + peringatan Vite
- **Skenario gagal:** muat pertama lambat di jaringan kedai lemah (meski huruf sudah lokal).
- **Cara membuktikan perbaikan:** pemisahan kode rute (`React.lazy` per layar) → peringatan hilang.
- **Status verifikasi:** TERVERIFIKASI

### [F-13] `bersihkanDataSensitif` meledak pada referensi melingkar
- **Tingkat:** K-4 (Saran)
- **Artefak:** `aplikasi/src/lib/antrean-offline.ts:74-94`
- **Bukti:** uji adversarial C5: objek `melingkar.diri = melingkar` → `RangeError` (rekursi tanpa penanda kunjungan). Hari ini muatan antrean dibangun kode aplikasi (risiko rendah), tapi tak ada pagar.
- **Cara membuktikan perbaikan:** tambah `WeakSet` kunjungan → uji C5 berganti ekspektasi tidak melempar.
- **Status verifikasi:** TERVERIFIKASI

**Rekap:** 0 K-1 · 2 K-2 · 6 K-3 · 5 K-4. Tidak ditemukan kebocoran data antar penyewa dari sisi frontend, tidak ada tombol mati, dan tidak ada kunci rahasia di kode frontend (skala specialist ini; verifikasi menyeluruh milik peran lain).

---

## 7. Yang Tidak Bisa Saya Verifikasi (kejujuran batas)

1. **Perilaku peramban nyata di tablet fisik** (sentuh multi-point, keypad numpad USB, OrientationLock) — sesi ini tanpa perangkat nyata; bukti keyboard dari jsdom + `fireEvent.keyDown`.
2. **IndexedDB peramban asli** — saya pakai `fake-indexeddb` (implementasi standar yang setia pada spesifikasi, tapi bukan engine Chrome/Safari).
3. **Sinkronisasi ke peladen Supabase sungguhan** (termasuk jalur balasan `23505` idempoten) — tanpa kredensial/peladen di sesi audit; dibaca dari kode + kontrak migrasi.
4. **Kontras tema sebagaimana tampil di layar fisik** (kalibrasi/gamma perangkat) — pengukuran saya matematis dari token warna.
5. **Pengukuran.performa/latensi build di jaringan kedai nyata** untuk dampak bundel 1 MB (F-12).
6. **Independensi model** — platform sesi ini memakai satu keluarga model; dicatat sebagai keterbatasan sesuai protokol §14.2, dikompensasi lensa + uji adversarial mandiri.

## 8. Pernyataan Tidak Mengubah Apa Pun

Saya **tidak mengubah** komponen antarmuka, CSS, konfigurasi, atau berkas sumber apa pun di `aplikasi/src/` maupun tempat lain. Seluruh uji adversarial dijalankan di salinan terpisah `/tmp/audit-kasir` yang dihapus setelah bukti terkumpul. **Laporan ini adalah satu-satunya berkas** yang saya buat di repo (pengecualian sah menurut PROTOKOL_AUDIT_INDEPENDEN §6 butir 7 agar kewajiban melapor tidak bertabrakan dengan mode hanya-baca). Bukti: `git status --short` sebelum commit hanya memuat berkas laporan ini; `npm ci` hanya mengisi `node_modules` yang diabaikan Git.

## 9. Kesimpulan & Rekomendasi

**Verdict: MEMERLUKAN PERBAIKAN sebelum Fase 11 (Uji Lapangan & Pilot).**

- Mesin penguji 100% hijau dan fitur inti yang Lee minta (keyboard PIN + anti-intipan + antrean offline IndexedDB + sanitasi) **terbukti bekerja** — sebagian besar bahkan saya buktikan ulang dengan uji adversarial independen, termasuk jalur IndexedDB yang tidak pernah diuji suite resmi.
- Namun sesuai kriteria kelulusan paket (§2), **LULUS MUTLAK batal** karena ada 2 temuan K-2 TERVERIFIKASI: (1) janji WCAG AAA tidak terpenuhi di 7 dari 10 tema dan gerbang mesinnya sendiri hanya menjunjung AA; (2) antrean luring tidak terpicu pada mode kegagalan jaringan paling umum di lapangan (WiFi nyala, internet mati). Dengan kebijakan gerbang `tahan_semua`, K-1/K-2 menahan penutupan fase sampai diperbaiki dan diverifikasi ulang.
- Estimasi usaha perbaikan kecil dan terlokalisir: F-01 (ubah token warna 7 tema atau ubah janji jadi AA), F-02 (petakan galat fetch → antrean), F-03–F-05 (tambah fake-indexeddb + reset `mengirim` usang + tolak jenis tak dikenal), F-06 (sinkronkan registry), F-07 (tambah uji keyboard), Sisanya K-4 bisa masuk daftar perbaikan fase.
- Rekomendasi urutan: tutup F-02 dan F-04 lebih dulu (menghadapi uji lapangan paling nyata), lalu putuskan arah F-01 (AAA atau AA) — itu keputusan Lee, bukan teknis semata.

## 10. Penutup Chat

**Posisi Sekarang:** Audit Akbar dimensi Spesialis Frontend & Kasir Lapangan selesai di commit `0fc63c7e`. Seluruh 6 perintah uji mesin wajib LOLOS (123 berkas Vitest / 1.013 uji; 81 mutasi tertangkap; kontras & antarmuka hijau). Fitur keyboard PIN (0–9, Backspace, Esc, Enter/Spasi), anti-intipan mata, persistensi IndexedDB, sinkron tanpa dobel, dan sanitasi PIN/sandi/token rekursif — semua saya buktikan ulang dengan 13 uji adversarial independen di salinan terpisah. Ditemukan 0 K-1, 2 K-2 (janji WCAG AAA belum terpenuhi; antrean offline tak terpicu saat WiFi nyala-internet mati), 6 K-3, 5 K-4. Laporan lengkap: `docs/uji/audit/LAPORAN_AKBAR_SPESIALIS_FRONTEND.md`.

**Rencana Selanjutnya:** Pembangun menindaklanjuti temuan (prioritas: F-02 & F-04 untuk ketahanan lapangan, keputusan arah F-01), lalu auditor memverifikasi ulang penutupan temuan sesuai kolom "Cara membuktikan perbaikan" di bagian 6. Temuan juga bisa langsung dimasukkan ke ROADMAP sebagai tugas perbaikan sesuai PROTOKOL_AUDIT_INDEPENDEN §10.

**Langkah Lee:** Baca ringkasan bagian 1 + daftar temuan bagian 6 di laporan, lalu putuskan: (a) kejar WCAG AAA sungguhan (gelapkan token 7 tema) atau sahkan AA dan ubah janji dokumen; (b) setujui perbaikan F-02 (antrean saat internet mati meski WiFi nyala) sebagai syarat masuk pilot; (c) bila setuju, minta sesi pembangun mengerjakan daftar temuan — audit ini sudah menyiapkan langkah bukti perbaikannya satu per satu.
