# SIAP LANJUT — penunjuk keadaan untuk sesi berikutnya

> Berkas ini DIBUAT MESIN oleh `python3 alat/lanjut-sesi.py --siapkan` dan diperiksa
> `python3 alat/lanjut-sesi.py`. Jangan disunting tangan pada bagian 1–2; bagian 3
> (rencana) justru WAJIB ditulis agent dan akan dipertahankan saat disegarkan.
> Aturan kesegaran: berkas ini wajib ikut ter-commit di commit TERAKHIR setiap batch.

## 1. Keadaan sekarang (dibaca sesi baru lebih dulu)

- **Cabang yang dilanjutkan:** `arena/01a0d09b-resto-barokah`
- **Dasar pilihan cabang:** pilihan Lee (`--lanjut-dari`)
- **Ditulis oleh sesi:** `arena/01a0d09b-resto-barokah`
- **Commit keadaan kerja:** `671e40460c167998f83589055404d111ccaa71ce`
- **PR:** PR #3 (base main)
PR #2 (base main)
PR #1 (base main) — **JANGAN MERGE tanpa keputusan Lee**
- **CI terakhir:** failure (run 35961829762, commit 671e4046)
- **PERHATIAN:** CI terakhir BUKAN success — perbaiki CI lebih dulu sebelum pekerjaan baru.
- **Ditulis:** 2026-09-24 (sebelum commit yang memuat berkas ini; jadi commit keadaan di atas
  adalah induk commit ini)
- **Ruang kerja:** bersih & ter-push (dijaga pemeriksa; kalau tidak, berkas ini tidak akan lolos)
- **Berkas yang Lee salin ke chat baru:** `PROMPT_SESI_BARU.md` (STATIS — mesin memeriksanya, bukan
  menulisnya ulang tiap batch; Lee hanya mengisi baris pertama `SESI YANG AKU LANJUT`)

## 2. Keadaan proyek & butir tertangguh

- Posisi proyek: lihat `PROJECT_STATE.md` (STATUS + PUTARAN terakhir) dan `STATUS.md`.
- Bukti terakhir yang hijau: `node alat/uji-sql.mjs` · `python3 alat/uji-mutasi-0012.py` ·
  `python3 alat/uji-mutasi-0014.py` · `bash aplikasi/alat/periksa-semua.sh` · CI (lihat baris CI di atas).
- Butir tertangguh terbuka: **2** — T-026, T-028
  (rincian: `docs/TERTANGGUH.md`; hanya Lee yang boleh menutupnya)
- **Paket peninjau terbaru:** audit `AUD-3-2026-09-20.md` → `cbba4010` (jarak tidak terbaca) · review `PKT-2026-09-19-pr-01-putaran16.md` → `93a50bac` (jarak tidak terbaca) — segarkan paket SEBELUM meminta peninjau bekerja bila
  jaraknya jauh: `python3 alat/audit-independen.py --paket AUD-3 --semua` ·
  `python3 alat/review-pr.py --siapkan --pr 1 --nama pr-01-putaranNN`
- **Ruang kerja baru:** `aplikasi/node_modules` & `alat/node_modules` TIDAK ikut tersimpan di snapshot.
  Sebelum pratinjau/uji aplikasi: `bash aplikasi/alat/pratinjau.sh` (±1–2 menit). Uji SQL & pemeriksa
  Uji SQL (`node alat/uji-sql.mjs`) BUTUH `npm ci --prefix alat` lebih dulu (runner mengimpor PGlite);
  tanpa itu jalankan `npm ci --prefix alat`. Pemeriksa Python berjalan tanpa pemasangan apa pun.

## 2b. Kalau kamu sesi baru: cara menyusul pekerjaan ini

Sesi baru di platform ini mulai dari `main`, sedangkan pekerjaan ada di cabang sesi.
Jalankan (tanpa memindahkan cabang sesimu):

```
git fetch origin arena/01a0d09b-resto-barokah:refs/remotes/origin/kerja-terakhir
git merge --ff-only origin/kerja-terakhir
python3 alat/mulai-sesi.py      # cetak KARTU SESI, lalu LAPORKAN ke Lee
```

Cabang `arena/01a0d09b-resto-barokah` di atas adalah **pilihan Lee** (bukan tebakan mesin). Lee juga bebas memilih sesi
LAIN: saat membuka chat baru, ia menulis pilihannya di baris pertama `PROMPT_SESI_BARU.md` — dan baris
itu yang **MENANG** bila berbeda dengan handoff ini. Laporkan bedanya, lalu rapikan catatan handoff
dengan `python3 alat/lanjut-sesi.py --siapkan --lanjut-dari <cabang>`. Sesi yang belum pernah di-push
tidak bisa dilanjutkan; sesi yang sengaja ditinggalkan ada di `docs/ops/SESI_DITINGGALKAN.md`.

Kalau checkout-mu tidak memuat `supabase/migrations/0014_penutup_celah_putaran13.sql`,
kamu berada di basis yang salah — jangan bekerja dulu, susul cabang di atas.

## 2c. Fakta cabang sesi baru: PR #1 TIDAK otomatis memuat pekerjaanmu

Kamu bekerja di cabang sesi barumu sendiri (dibuat platform; hanya ke cabang itu kamu boleh push).
PR #1 menunjuk cabang sesi SEBELUMNYA, jadi commit barumu tidak muncul di PR itu.
Bila Lee ingin meninjau lewat PR: buka PR BARU dari cabangmu (base `main`) dan laporkan tautannya.
JANGAN merge apa pun tanpa keputusan Lee.

**Base branch bila Lee membuka sesi baru lagi di Arena:** pilih cabang yang disebut di §1
(`arena/01a0d09b-resto-barokah`), BUKAN `main` — pekerjaan belum di-merge ke sana. Kalau platform hanya bisa dari
`main`, tidak apa-apa: jalankan `python3 alat/lanjut-sesi.py --susul` SEBELUM bekerja.

## 3. Rencana berikutnya (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

**KEADAAN SESI INI (2026-09-24, `arena/01a0d09b-resto-barokah` — FASE 7 KAS & SHIFT):**

0N. **T7-04 (Transaksi hanya dalam shift terbuka ⚠️) SELESAI.**
   - Migrasi `0048_wajib_shift.sql` menambahkan konfigurasi `wajib_shift` pada `public.pengaturan`.
   - Pemicu `picu_pesanan_validasi_shift_terbuka` menolak pembuatan pesanan jika `wajib_shift = true` dan kasir/pelayan tidak punya shift kasir berstatus `'terbuka'`.
   - Pemicu `picu_pembayaran_validasi_shift_terbuka` dan RPC `bayar_pesanan` menolak pencatatan pembayaran tanpa shift terbuka, serta menyambungkan transaksi ke `shift_id` aktif.
   - Pagar UI di `LayarKasir.tsx`: banner peringatan kasir belum buka kas tampil jika `wajibShift && !shiftAktif`, tombol cepat `Buka Kasir Sekarang` untuk membuka modal shift langsung, serta tombol bayar dan kirim dapur otomatis mengalihkan kasir ke dialog `BukaKas`.
   - Multibahasa 100% lengkap pada 4 bahasa (`id`, `en`, `zh`, `ar` dengan 188 kunci).
   - Bukti: suite SQL **91 LULUS** · uji mutasi SQL 0048 **6/6 MERAH** · Vitest **77 berkas / 608 tes LULUS** · mutasi aplikasi **77/77 MERAH** · CI **116 gerbang utuh** · kontrak UI hijau (`peta-ui.py`).
   - Langkah berikutnya di Fase 7: `T7-05 Pengingat shift belum ditutup`.

0M. **T7-03 (Kas pergerakan uang masuk/keluar tunai, setoran, & koreksi) SELESAI.**
   - Migrasi `0047_kas_pergerakan.sql` mencatat uang tunai operasional di luar penjualan.
   - Pemicu `picu_kas_pergerakan_kekal` menjamin sifat append-only ledger keuangan kekal (anti-UPDATE dan anti-DELETE).
   - Pemicu `picu_kas_pergerakan_validasi_shift` dan RPC `kas_pergerakan` menjaga pergerakan operasional hanya pada shift terbuka.
   - Setelah shift ditutup, baris lama beku; koreksi dicatat sebagai baris baru bertanda 'koreksi' (ART-6).
   - `tutup_shift` otomatis mengintegrasikan pergerakan kas: `tunai_masuk` (penjualan + kas masuk) dan `tunai_keluar` (kas keluar + setoran) ke dalam `uang_seharusnya = modal_awal + tunai_masuk - tunai_keluar`.
   - Komponen `KasKeluarMasuk.tsx` + `KasKeluarMasuk.test.tsx` (8 unit test) terintegrasi di `LayarKasir.tsx` dengan nominal cepat, chips alasan cepat, dan validasi sisi klien tanpa tombol liar.
   - Bukti: suite SQL **90 LULUS** · uji mutasi SQL 0047 **6/6 MERAH** · Vitest **77 berkas / 605 tes LULUS** · mutasi aplikasi **75/75 MERAH** · CI **115 gerbang utuh** · 100% paritas 4 bahasa (185 kunci).
   - Langkah berikutnya di Fase 7: `T7-04 Transaksi hanya dalam shift terbuka ⚠️`.

0L. **T7-01 (Buka kas & modal awal) & T7-02 (Tutup kas & selisih) SELESAI.**
   - Migrasi `0045_buka_shift.sql` & `0046_tutup_shift.sql` menegakkan siklus hidup shift kasir.
   - Perhitungan uang seharusnya otomatis di peladen: `modal_awal + tunai_masuk - tunai_keluar`.
   - Constraint `shift_kas_selisih_alasan` mewajibkan kasir mengisi alasan jika terjadi selisih kas fisik vs catatan sistem.
   - Pemicu `picu_isi_shift_kas_pembayaran` otomatis menyambungkan transaksi tunai ke shift aktif kasir.
   - Komponen antarmuka `BukaKas.tsx` dan `TutupKas.tsx` terintegrasi di `LayarKasir.tsx` dengan live variance counter, tombol pecahan kas cepat, chips alasan cepat, dan konfirmasi aman.
   - Jejak audit kriptografis berantai hash tersimpan di `public.catatan_audit` (`aksi = 'tutup_shift'`).
   - Uji mutasi backend `0045` (6/6), `0046` (6/6), dan frontend (73/73) terbukti MERAH.

0J. **ATURAN TUTUP SESI — 3 hal wajib disebut agent (teguran Lee 2026-09-23).** Saat menutup sesi /
   menyiapkan pindah sesi (AL-13), agent **tidak boleh** berhenti di kalimat "siap pindah sesi".
   Wajib ditulis langsung di bagian **👉 Langkah Lee**: (a) **base branch** = nama cabang aktif
   **apa adanya** (saat ini `arena/01a0cca9-resto-barokah`, **bukan** `main`, bukan cabang lama
   `arena/01a0cb7f-resto-barokah` yang masih hidup di `e07ae6d`); (b) **prompt pembuka** = salin isi
   `PROMPT_SESI_BARU.md` (jalan pendek untuk chat yang sudah di cabang benar: `baca pro.md`);
   (c) **konfirmasi** baris pertama `PROMPT_SESI_BARU.md` menunjuk cabang aktif. Alasan: informasi
   ini SUDAH ada di `PROMPT_SESI_BARU.md`, tetapi Lee tidak tahu berkas itu harus dibuka.
0K. **PENJAGA BARU di `alat/lanjut-sesi.py`.** Pemeriksa kini **GAGAL** bila baris
   `SESI YANG AKU LANJUT:` menunjuk cabang yang **tidak memuat** HEAD sekarang. Dulu ia hanya
   memastikan baris itu ADA — sehingga baris basi (menunjuk sesi lama yang masih hidup di GitHub)
   lolos diam-diam dan sesi baru mendarat di pekerjaan tertinggal 25 commit tanpa peringatan apa pun.
   Perbaikannya: `python3 alat/lanjut-sesi.py --siapkan --lanjut-dari <cabang-aktif>`.

0g. **T5-05 SELESAI (batch keempat).** Cacat nyata ditemukan & ditutup: `picu_diskon_batas()`
   memeriksa izin PEMANGGIL, sedangkan bukti PIN atasan (0016) tidak pernah menaikkan batas —
   alur "di atas batas → PIN atasan" (PRD M3) **mustahil dijalankan**. Ditutup migrasi
   **`0041_diskon_pin_atasan.sql`**: batas PENYETUJU berlaku bila buktinya sah (terikat pesanan
   itu, sekali pakai, ≤5 menit, penyetuju dicek ulang izinnya), sampai batas atasan saja.
   Sisi layar: **voucher keras-kode `BAROKAH10K` dibuang** (dulu memotong Rp10.000 tanpa izin,
   tanpa alasan, tanpa jejak, tanpa voucher di database), diganti `DiskonManual.tsx`.
0h. **Jebakan yang kena di batch ini — CATAT, mudah terulang:** menambah migrasi baru yang memuat
   pola `and pp.dipakai_pada is null` membuat mutasi **M6** di `alat/uji-mutasi-0012.py` mengenai
   berkas BARU (pencarian "migrasi terbaru dulu"), sehingga M6 terbaca "pagar tumpul" padahal
   pagar void tidak tersentuh — turun 16/16 → 15/16. Perbaikannya: sebut berkas migrasinya
   EKSPLISIT (`0015_penutup_celah_putaran16.sql`). **Pelajaran umum: sesudah menambah migrasi,
   jalankan `periksa-semua.sh` penuh — mutasi lama bisa tergeser diam-diam.**
0i. **T-027 dibuka (butuh keputusan Lee):** pajak & service di keranjang kasir masih dihitung
   layar (10 %/5 % perkiraan). Tidak membahayakan uang — angka sah selalu dari peladen dan itulah
   yang dicetak struk — tetapi bila tarif resto berbeda, angka keranjang bisa meleset. Ini juga
   membuat DoD **T3-02** belum sepenuhnya ditepati; dicatat apa adanya di ROADMAP (❓ T-027).
   Tertangguh terbuka kini **2** (T-026 Playwright, T-027 keranjang).
0j. **T5-06 SELESAI (batch kelima) — TANPA migrasi baru, dan itu disengaja.** ROADMAP
   menjadwalkan `0041_void_pra.sql`, tetapi pemeriksaan isi database lebih dulu menunjukkan
   **seluruh DoD T5-06 sudah ditegakkan** `picu_pembatalan_sah()` di
   `0015_penutup_celah_putaran16.sql`: tahap dibaca dari DUA tanda, alasan wajib lewat `check`
   di tabel `pembatalan` (`0010`), satu target sekali batal, nilai kerugian dari salinan harga,
   tidak ada penghapusan data. Menulis migrasi kembar justru akan mengulang jebakan 0h.
0k. **Cacat nyata T5-06 ada di LAYAR:** tombol "Hapus item" memakai `filter` untuk SEMUA keadaan,
   sehingga item yang sudah tercatat hilang tanpa alasan, tanpa pelaku, tanpa jejak — akibatnya
   tabel `pembatalan` beserta pagarnya **tidak pernah dipanggil siapa pun** dan laporan
   pembatalan harian selalu kosong. Ditutup `aplikasi/src/layar/kasir/VoidItem.tsx` (alasan
   WAJIB, alasan cepat, nilai yang batal ditagih terlihat, peringatan PIN bila dapur sudah
   mulai) + percabangan jujur di `LayarKasir.tsx`: tanpa prop `onBatalkanItem` keranjang tetap
   draf lokal; dengan prop itu, item **hanya** hilang setelah peladen menjawab berhasil.
   Bukti: **368 tes** aplikasi · `uji-mutasi-app.mjs` **24/24 MERAH** · SQL **84 LULUS**.
0l. **T5-07 SELESAI (batch keenam) — migrasi `0042_bahan_terbuang_jujur.sql`.** Dugaan di
   butir sebelumnya benar sebagian: PIN atasan & nilai kerugian memang sudah terpasang di
   `0015`. Yang **tidak pernah dijaga siapa pun** ternyata kolom `pembatalan.bahan_terbuang`
   itu sendiri — ada sejak `0010`, dipakai laporan kerugian, nol pemicu memeriksanya. Kasir
   bisa membatalkan pesanan yang **sudah dimasak** sambil mengirim `false`: sah, ber-PIN,
   bernilai benar, tetapi kerugian bahannya **lenyap dari laporan selamanya**. Sekarang
   penanda dihitung peladen dari tahap; kiriman bawaan ditimpa, kiriman bertentangan ditolak.
   Layar `VoidPasca.tsx` **tidak dibuat** — `VoidItem.tsx` sudah menangani kedua tahap.
0m. **JEBAKAN `berkas_berlaku` KAMBUH (kedua kalinya) — hafalkan:** `0042` menulis ulang utuh
   `picu_pembatalan_sah()`, sehingga mutasi **M6** di `alat/uji-mutasi-0012.py` yang menyasar
   `0015` tidak berpengaruh lagi (yang berlaku definisi TERAKHIR) → 16/16 turun 15/16.
   Jangkarnya dipindah ke `0042` dan pulih. **Aturan: setiap kali sebuah fungsi ditulis ulang
   di migrasi baru, SEMUA uji mutasi yang menyasarnya wajib ikut dipindahkan — dan sesudah
   menambah migrasi, jalankan uji mutasi lama, jangan hanya suite SQL.**
0n. **T5-08 SELESAI (batch ketujuh) — layar saja, penyimpanan SENGAJA belum.** Pemeriksaan
   keputusan terkunci menjawab pertanyaannya: **T-011** (disetujui 2026-09-21) menyatakan data
   pelanggan baru boleh **disimpan** setelah ada kebijakan privasi + halaman persetujuan, dan
   migrasinya dijadwalkan **T8-15**. Jadi yang dibuat hanya `DataPelanggan.tsx` — **tanpa tabel,
   migrasi, atau RPC apa pun** — sehingga tidak ada nomor pelanggan yang bisa tersimpan sebelum
   kebijakannya siap. Bukan Stop Condition: keputusannya tidak bertentangan, malah sudah
   menunjuk tempatnya. Yang dikunci & diuji: persetujuan eksplisit (dikirim sebagai data, bukan
   diasumsikan), minimalisasi (HP + nama panggilan saja), penjelasan di layar, dan tombol
   **Lewati selalu hidup** agar pembayaran tidak pernah terhambat.
0o1. **JEBAKAN 0m KAMBUH LAGI DI TEMPAT KEDUA — dan hanya tertangkap `periksa-semua.sh` penuh.**
   Selain M6 di `uji-mutasi-0012.py`, ternyata **F-05 di `alat/uji-mutasi-0015.py`** juga
   menyasar `picu_pembatalan_sah` di `0015` yang kini ditimpa `0042` → dilaporkan "pagar
   TUMPUL" padahal pagarnya utuh. Diperbaiki dengan konstanta `MIG42` + `berkas_rel=MIG42`.
   **Pelajaran prosedur: sesudah menambah migrasi, JANGAN cukup menjalankan suite SQL —
   jalankan seluruh uji mutasi (atau `periksa-semua.sh` penuh). Suite bisa hijau sempurna
   sementara penilai mutasi diam-diam lumpuh.**
0o2. **JEBAKAN 0m KAMBUH DI TEMPAT KETIGA — inilah penyebab CI merah 4× berturut-turut.**
   `alat/uji-mutasi-0019.py` (pagar diskon T5-04) menyasar `picu_diskon_batas` di `0019`,
   padahal `0041` (T5-05) menulis ulang fungsi itu utuh. Akibatnya **SELURUH 5 mutasinya
   lumpuh sejak T5-05** dan CI gagal di langkah itu pada run 35842018455 & 35842912994;
   pesannya ("pagar tumpul!") mudah disalahartikan sebagai cacat pagar diskon. Sesudah
   `MIGRASI` diarahkan ke `0041`: **5/5 MERAH** — pagarnya sehat sepanjang waktu.
   **Cara cepat memeriksa: `grep -rln "<teks jangkar>" supabase/migrations/` — kalau muncul
   di lebih dari satu migrasi, jangkar wajib menunjuk yang PALING AKHIR.**
0o3. **Catatan alat:** penilai mutasi memakai direktori kerja tetap di `/tmp`
   (mis. `/tmp/mutasi-0015-rb`), jadi **jangan menjalankan dua penilai bersamaan** — hasilnya
   saling merusak dan memberi "GAGAL" palsu. Ini sempat menipu saya satu putaran.
0o. **Berikutnya T5-09** (struk digital sebagai cadangan saat printer bermasalah). Perhatikan:
   T5-03 (struk termal) sudah selesai, jadi **periksa dulu** apa yang sudah ada di berkas struk
   sebelum membuat yang baru — dua batch terakhir menunjukkan rencana ROADMAP sering lebih tua
   daripada isi repo. Migrasi berikutnya bila perlu: **≥ 0043**.
0p. **Kalau butuh angka bukti terakhir:** aplikasi **74 berkas / 578 tes LULUS** · suite SQL
   **87 LULUS** · `uji-mutasi-app.mjs` **65/65 MERAH** · `uji-mutasi-0043.py` **4/4 MERAH** ·
   `uji-mutasi-0042.py` **4/4 MERAH** · `uji-mutasi-0012.py` **16/16** · gerbang & paritas CI
   LOLOS · `tsc` bersih · lint 0 error.

0q. **T5-09 SELESAI (batch kedelapan).** `StrukDigital.tsx` **membungkus `<Struk>` yang sama**,
   tidak menggambar ulang — mitigasi ART-7: kalau struk digital punya kode tata letak sendiri,
   suatu hari angkanya akan berbeda dari kertas dan tidak ada yang tahu mana yang benar.

0r. **T5-10 DIKERJAKAN SEBAGIAN — SENGAJA, dan tugasnya BELUM dicentang.** Yang selesai:
   `DaftarTransaksi.tsx` (cari lewat nomor/jam/nominal; titik ribuan diabaikan) + cetak ulang
   yang **selalu bertanda "SALINAN — CETAK ULANG"** termasuk di pratinjau layar, sebab lembar
   kedua yang terlihat identik bisa dipakai menagih dua kali. "Tidak mengubah data" dijaga uji
   penjaga `?raw` (dilarang `.rpc(`/`fetch(`/`.insert(`/`.update(`/`.delete(`).
   Yang BERHENTI: bagian **catatan audit** butuh RPC baru, sedangkan RPC di luar `TECH_SPEC` §5
   adalah **Stop Condition** milik Lee → dibuka **T-028** dengan tiga pilihan. Tertangguh
   terbuka kini **3** (T-026, T-027, T-028).

0s. **T5-11 SELESAI (batch kesembilan) — tanpa migrasi baru.** RPC `bayar_pesanan` ternyata sudah
   mendukung pembayaran sebagian sejak T5-02; yang belum ada adalah buktinya dan layarnya.
   `supabase/tes/pembayaran_sebagian.sql` menegaskan keputusan MVP: pembayaran sebagian =
   **beberapa baris pembayaran terpisah pada SATU pesanan**, baris pertama tidak ditimpa,
   dan pembayaran sesudah lunas **ditolak**. Alasannya kas: kalau ditimpa, 20.000 tunai +
   14.500 QRIS terbaca satu angka dan laci kas tak bisa dicocokkan per metode di akhir shift.
   `DaftarTagihan.tsx` memberi **penanda umur** (baru → lama ≥30 mnt → mendesak ≥120 mnt).

0t. **TEMUAN T5-11 yang layak diingat:** peladen **tidak memercayai** kolom `total` kiriman
   klien — ia menghitung ulang (pajak 10 % + service 5 %), jadi pesanan uji 30.000 menjadi
   34.500. Uji disesuaikan mengikuti peladen, **bukan sebaliknya**; menurunkan harapan uji agar
   cocok dengan angka klien justru melumpuhkan pagar yang benar.

0u. **CI MERAH ditangkap & diperbaiki — dua pelajaran.** Run `35851999419` jatuh di
   `alat/peta-ui.py`. (a) **Warisan T5-05:** `aksi.ts` menulis `rpc: 'diskon_transaksi'` padahal
   itu **nama tabel**, bukan fungsi — dikembalikan ke `null`. (b) **Dari T5-10:**
   `DaftarTransaksi.tsx` memakai `<button>` mentah yang dilarang Aturan 7 — diganti `<Tombol>`,
   ujinya pindah ke `getByRole` (lebih baik: menguji lewat peran aksesibilitas).
   **PELAJARAN PROSEDUR PALING PENTING SESI INI: tiga push beruntun saling MEMBATALKAN run CI
   sebelumnya, sehingga cacat (a) lolos beberapa commit tanpa terlihat. Run berstatus
   `cancelled` TIDAK boleh dibaca sebagai aman — tunggu satu run sampai `success`, atau
   jalankan sendiri pemeriksa langkah CI itu secara lokal sebelum push.**

0v. **T5-12 laporan pembatalan SELESAI.** `supabase/migrations/0043_laporan_pembatalan.sql` +
   `aplikasi/src/layar/laporan/DaftarPembatalan.tsx`. Dugaan di butir ini ternyata **salah**:
   pagar tabel `pembatalan` TIDAK lengkap. Policy `pembatalan_pilih` hanya menuntut
   `pesanan_sepenyewa(pesanan_id)`, jadi **pelayan/kasir/dapur bisa membaca seluruh nilai
   kerugian dan nama pembatalnya**. 0043 menambah syarat `lihat_laporan`. Laporan berupa **view**
   `public.laporan_pembatalan` (bukan RPC — nama RPC-nya tidak ada di TECH_SPEC §5), wajib
   `security_invoker = true`. **Jangan longgarkan lagi:** `alat/uji-mutasi-0043.py` menahan 4
   mutasi. Migrasi berikutnya **≥ 0044**.

0w. **Pelajaran yang mahal: memperketat RLS membuat uji lama merah, dan itu WAJAR.** Tujuh berkas
   uji SQL jatuh setelah 0043 karena mereka memverifikasi hasil tulisan dengan **membaca ulang
   dari kursi kasir**. Yang benar: pembacaan verifikasi dipindah ke luar kursi kasir
   (`reset role; select uji.klaim(null);` … lalu klaim ulang), **bukan pagarnya dilonggarkan**.
   Kalau suatu saat ada uji pembatalan merah lagi, tanya dulu: "uji ini sedang menguji ISI jejak,
   atau HAK BACA-nya?" — kalau isi, pindahkan kursinya. Aplikasi sendiri tidak pernah membaca
   tabel `pembatalan` langsung (`grep from('pembatalan')` = kosong), jadi pagar ini tidak
   memutus fitur mana pun.

0L. **FASE 7 BERJALAN — T7-01 (Buka kas / modal awal) SELESAI (2026-09-24, sesi arena/01a0d09b).**
   - Migrasi `supabase/migrations/0045_buka_shift.sql`: tabel `public.shift_kas`, RLS InitPlan,
     aturan satu shift terbuka per kasir per cabang (indeks unik parsial + kode SH-409), audit hash otomatis,
     kunci foreign `pesanan.shift_id` & `pembayaran.shift_id`.
   - RPC: `public.buka_shift(cabang_id, modal_awal, catatan)` terpasang di `aplikasi/src/lib/aksi.ts`.
   - UI: `aplikasi/src/layar/kasir/BukaKas.tsx` + `BukaKas.test.tsx` (8 unit test murni) terpasang di `LayarKasir.tsx`.
   - Bukti: 88 suite SQL LULUS, mutasi 0045 6/6 MERAH, 75 berkas Vitest / 586 tes LULUS, mutasi UI 69/69 MERAH,
     kontrak `peta-ui.py` LULUS, tsc/lint/format/build bersih.
   - **TUGAS BERIKUTNYA:** `T7-02 — Tutup kas (seharusnya vs fisik) + alasan selisih ⚠️` (RPC `tutup_shift`,
     layar `TutupKas.tsx`, perhitungan saldo sistem uang_seharusnya vs uang_fisik, toleransi selisih).

0A. **FASE 6 DIMULAI — T6-01, T6-04, T6-05 SELESAI (2026-09-23).** Tiga tugas cetak yang bisa
   dikerjakan tanpa printer sudah jadi: `aplikasi/src/lib/printer/expos.ts` (penyusun ESC/POS),
   `struk.ts` (struk pelanggan), `tiket.ts` (tiket dapur). Semuanya **murni** — hanya data → byte,
   tidak menyentuh Bluetooth/USB. Itu disengaja: uji printer nyata (T6-08) hanya sesekali, jadi
   tata letak dikunci uji byte-level yang jalan di CI setiap saat.

0G. **MULAI DARI SINI (sesi baru, 2026-09-23).** Keadaan: Fase 5 tuntas untuk bagian agent;
   Fase 6 **T6-01/T6-02/T6-03/T6-04/T6-05 SELESAI**. **CI HIJAU** run `35886937856` (commit
   `5b9d4bf`). Tidak ada pekerjaan tergantung, pohon kerja bersih.
   **Kerjakan berikutnya: FASE 7 — kas & shift, mulai `T7-01` (buka kas / modal awal).** Alasan
   memilih Fase 7 dan bukan menuntaskan Fase 6: sisa Fase 6 semuanya terhalang hal di luar kode
   (printer nyata & keputusan RPC), sedangkan Fase 7 murni data + layar dan menutup lubang yang
   sudah terasa sejak T5-11 — tagihan ditinggal & pencocokan kas per metode saat tutup shift.
   Migrasi berikutnya: **≥ 0044** (T7-01 merencanakan `0045_buka_shift.sql`; periksa dulu nomor
   yang masih kosong sebelum menulis).

0H. **HATI-HATI: sandbox pernah DI-KLON ULANG dua kali** (2026-09-23). Gejalanya: ruang kerja
   tiba-tiba tampak kotor berisi puluhan berkas dan `git log` pendek/mundur. **Itu BUKAN pekerjaan
   yang hilang.** Jangan mengerjakan ulang apa pun sebelum menjalankan:
   `git ls-remote origin arena/01a0cca9-resto-barokah` — bandingkan dengan commit terakhir yang
   tercatat di PROJECT_STATE. Pemulihannya: `git stash -u`, `git fetch --unshallow origin <cabang>`,
   `git reset --hard FETCH_HEAD`, periksa isi stash (biasanya murni penghapusan) lalu buang.
   `node_modules` juga ikut hilang → `npm ci` di folder `aplikasi`.

0I. **MILIK LEE, JANGAN DISENTUH AGENT: lima uji printer** (M-12, M-22, M-23, M-24, M-25) kini
   tercantum di blok paling atas `docs/uji/RENCANA_UJI_MANUAL.md`. Lee sudah menyatakan akan
   mengeceknya nanti. **`T6-08` DILARANG dicentang** sampai ada hasil cetak sungguhan, dan agent
   dilarang mencentangnya sendiri.

0D. **T-002 DIJAWAB LEE (2026-09-23) — T6-02 & T6-03 SELESAI.** Printer Kedai Oasis: Goojprt
   PT-210, Kassen BT-P290, Blueprint Lite-58, Xprinter XP-N160II, Epson TM-T82X. Butir T-002 di
   `docs/TERTANGGUH.md` sudah ditutup. Berkas baru: `lib/printer/profil.ts`, `lib/printer/kirim.ts`,
   `layar/pengaturan/PasangPrinter.tsx`. **Butir 0B di bawah soal T6-02/T6-03 sudah TIDAK berlaku.**

0E. **ATURAN YANG TIDAK BOLEH DILANGGAR PENERUS: daftar merek printer = JALAN PINTAS, BUKAN SYARAT.**
   Lee bertanya khusus apakah printer di luar daftar tetap jalan, dan jawabannya sudah dijanjikan
   "ya". `tebakProfil()` wajib SELALU mengembalikan profil yang bisa dipakai (jatuh ke
   `PROFIL_UMUM`), penelusuran BLE menyeluruh wajib tetap ada, dan jalur USB wajib menerima jalur
   keluar apa pun bila kelas 7 tidak ketemu. **Enam mutasi menjaga ini** — kalau ada yang
   "merapikan" kode dengan membatasi ke merek terdaftar, CI langsung merah. Jangan dilonggarkan.

0F. **Yang MASIH kurang soal printer:** semua diuji dengan printer TIRUAN. Itu membuktikan
   logikanya, bukan kertasnya. **T6-08 (uji cetak nyata) tetap gerbang dan milik Lee** — langkahnya
   sudah ditulis awam di `docs/uji/PANDUAN_PRINTER.md`, ceklisnya M-22…M-25 di
   `docs/uji/RENCANA_UJI_MANUAL.md`. Jangan mencentang T6-08 tanpa hasil cetak sungguhan.

0B. **SISA FASE 6 BERHENTI DI STOP CONDITION — jangan dipaksakan.**
   - **T6-02 (Web Bluetooth) & T6-03 (WebUSB):** butuh **perangkat keras nyata**. Keduanya juga
     bergantung butir tertangguh **T-002** (merek/tipe printer Kedai Oasis belum diketahui). Lee
     sudah menyetujui "placeholder ESC/POS generik" — dan placeholder itulah yang kini SELESAI.
     Menulis kode sambungan tanpa tahu perangkatnya = menebak.
   - **T6-06 (antrean cetak & jejak audit):** memuat blok 🔴 **T-028** yang menuntut **RPC baru**;
     RPC di luar `docs/TECH_SPEC.md` §5 adalah keputusan pemilik → Stop Condition.
   - **T6-07 (printer per perangkat):** butuh migrasi `0044_printer.sql` + pengaturan; bisa
     dikerjakan agent, tetapi tanpa T6-02/T6-03 ia tidak bisa dibuktikan bekerja ujung-ke-ujung.
   - **T6-08:** uji cetak nyata di kedai — milik Lee.

0C. **Yang paling berguna dikerjakan berikutnya bila Lee belum sempat urus printer:** lompat ke
   **Fase 7** (kas & shift, `T7-01` buka kas). Fase 7 murni data + layar, tidak bergantung
   perangkat keras, dan menutup lubang yang sudah terasa sejak T5-11 (tagihan ditinggal &
   pencocokan kas per metode).

0y. **FASE 5 TUNTAS untuk bagian yang bisa dikerjakan agent.** Yang tersisa di Fase 5 adalah
   **bukti manual milik Lee** (T4-03 foto, T4-05 dua perangkat, T4-10 cabut jaringan, 5 metode
   bayar) — daftar periksanya sudah siap di `docs/uji/RENCANA_UJI_MANUAL.md`, tinggal Lee jalankan
   dan isi kolom centangnya. **Agent tidak boleh mencentangnya sendiri.**

0z. **Arah sesi berikutnya (urutan usulan, bukan perintah):** (1) mulai **Fase 6** — di sanalah
   **T6-06 memuat blok 🔴 WAJIB DIKERJAKAN DI SINI untuk T-028** (jejak audit cetak ulang), butir
   tertangguh yang sudah dijawab Lee dan tidak boleh terlewat; (2) T-026 (infra e2e Playwright)
   tetap terjadwal **Fase 11**, jangan dimajukan tanpa alasan kuat karena butuh dependensi dev
   baru + langkah CI baru; (3) ingat aturan tiga tempat: setiap perintah CI baru wajib didaftarkan
   di `.github/workflows/ci.yml`, `GERBANG_WAJIB` (`alat/periksa-gerbang-ci.py`), **dan**
   `aplikasi/alat/periksa-semua.sh` — kalau tidak, CI merah sendiri.

0x. **Penjaga `keamanan_fungsi.sql` (T130-initplan) menangkap cacat kinerja nyata.** Versi pertama
   0043 menulis `and public.boleh('lihat_laporan')` tanpa bungkus — PostgreSQL memanggil fungsi itu
   **sekali per baris**, bukan sekali per perintah. Bentuk yang benar: `and (select public.boleh(...))`.
   Setiap policy baru yang memanggil helper izin wajib memakai bentuk berbungkus ini.



0. **BACA DULU — SATU HAL YANG BELUM SELESAI: commit `227a51b` BELUM TER-PUSH.** Token GitHub
   kedaluwarsa di akhir sesi (`gh auth status` → "The github.com token in GH_TOKEN is no longer
   valid"; `git push` menolak dengan "could not read Username"). Pekerjaannya **aman sebagai commit
   lokal** di cabang `arena/01a0cca9-resto-barokah`. **Langkah pertama sesi baru:** minta Lee
   menyambungkan ulang GitHub di Arena, lalu `git push origin arena/01a0cca9-resto-barokah`, lalu
   periksa CI commit terakhir sebelum memulai pekerjaan baru. Jangan mengulang pekerjaannya —
   cek `git log` dulu.
0b. **FASE 5 YANG SUDAH SELESAI di sesi ini (jangan dikerjakan ulang):** **T5-01 sambungan**
   (`e8baf2c`), **T5-03 struk** (`66312f9`), **T5-04 diskon** (`227a51b`).
   Sisa Fase 5 menurut `docs/ROADMAP.md`: struk termal, buka/tutup shift, dan butir lain yang
   belum `[x]`.
0c. **T5-04 — pelajaran yang mahal, jangan diulang:** pagar diskon **sudah ada** sejak
   `0019_pesan_diskon_jujur.sql` (`picu_diskon_batas()`; cap kumulatif dari `0014`), jadi TIDAK
   dibuat migrasi baru — dua tempat yang mengatur uang berarti dua tempat yang bisa berbeda.
   Nomor migrasi yang tertulis di ROADMAP adalah rencana lama, bukan perintah (`0039_diskon.sql`
   sudah terpakai `bayar_pesanan`). **Sebelum menulis migrasi untuk butir ROADMAP mana pun,
   periksa dulu apakah aturannya sudah hidup di migrasi lama.** Yang ditambah: bukti —
   `supabase/tes/diskon_tumpuk.sql` + `alat/uji-mutasi-0019.py` (5/5 MERAH).
0d. **Jebakan uji diskon (sudah dua kali memakan korban):** asersi "total diskon melebihi subtotal"
   mudah jadi hijau-palsu karena satu baris diskon besar lebih dulu ditahan pagar **batas izin**
   (owner pun berbatas 20 %), sehingga pagar subtotal tak pernah tersentuh. Cara yang benar:
   tumpuk menyala + cap resto 100 % + penambahan **bertahap**. Ketahuan hanya karena uji mutasi —
   ini alasan uji mutasi tidak boleh dilewati.
0e. **T-026 TERBUKA (butuh jawaban Lee):** infra e2e Playwright. Chromium **tidak bisa diunduh**
   di ruang kerja agent — dicoba dua cara 2026-09-23 dan dua-duanya gagal (paket sistem tak
   tersedia; "Download failure code=1"). Karena itu langkah CI e2e **tidak** ditambahkan: menambah
   perintah CI yang tidak bisa dijalankan lokal melanggar paritas CI dan membuat CI merah sendiri.
   `T11-01`/`T11-11` di ROADMAP ditandai ❓ T-026. Pilihan untuk Lee ada di `docs/TERTANGGUH.md`.
0f. **Bukti akhir sesi ini:** aplikasi **330 tes LULUS** · suite SQL **83 LULUS · 0 GAGAL** ·
   `uji-mutasi-app.mjs` 14/14 MERAH · `uji-mutasi-0019.py` 5/5 MERAH · gerbang & paritas CI LOLOS
   (**109 perintah**) · `periksa-rujukan.py`/`periksa-bersih.py`/`periksa-roadmap.py` LOLOS ·
   `bash aplikasi/alat/periksa-semua.sh` hijau pada seluruh pemeriksa kode.

---

**KEADAAN SESI SEBELUMNYA (2026-09-23, `arena/01a0cb7f` — pintu "baca pro.md"):**

1. **Pindah sesi SUDAH terjadi.** Sesi ini dibuka dari `arena/01a0c97c` dan bekerja di cabang sendiri
   `arena/01a0cb7f-resto-barokah`. Handoff di atas kini menunjuk cabang ini (`--lanjut-dari`).
2. **Perintah pertama PRO.md §1 sudah dikerjakan — CI merah DIPERBAIKI (baca, bukan klaim):**
   run `35797734100` (`d923e99`) ternyata **cancelled** (tertimpa push `f7fd468`); run penggantinya
   `35798327450` (`f7fd468`) **failure** di langkah "Pemeriksa fondasi, roadmap, struktur, komponen,
   uji & kontras". 5 dari 53 perintah langkah itu gagal lokal. Empat cacat nyata ditutup:
   (a) `uji-mutasi-0032/0033/0035/0036/0037.py` masuk `ci.yml` tanpa entri `GERBANG_WAJIB`;
   (b) lima perintah yang sama tidak ada di `aplikasi/alat/periksa-semua.sh` (paritas CI);
   (c) `PANDUAN_PENGGUNA.md` menulis "72 berkas uji" padahal nyata 78;
   (d) `docs/PROJECT_STATE.md` merujuk `aplikasi/uji/e2e/dapur.spec.ts` (berkas rencana — belum dibuat) tanpa penanda rencana.
   Bukti lokal: 53/53 perintah langkah itu LOLOS · `bash aplikasi/alat/periksa-semua.sh` kode keluar 0
   · Prettier bersih. Rincian: `_log-sesi/LOG_SESI_2026-09-23.md` bagian sesi `arena/01a0cb7f`.
3. **CI SUDAH HIJAU TERBUKTI:** run **`35801364931`** pada commit **`9a6a6c8`** = `completed success`
   (job "Periksa (lint · tipe · uji · pemeriksa Python)" ✓ 11m51s, 0 langkah merah). Pembanding: run
   `35798327450` pada `f7fd468` (pohon sebelum perbaikan) = failure. Sesudah commit penutup batch ini,
   sesi berikutnya tetap wajib membaca ulang status CI commit terakhir sebelum mulai pekerjaan baru.
4. **Penting bila Lee membuka sesi baru lagi:** baris pertama `PROMPT_SESI_BARU.md` masih berisi
   `arena/01a0c97c-resto-barokah` (berkas STATIS — hanya Lee yang mengisinya). Ganti ke
   `arena/01a0cb7f-resto-barokah` supaya pekerjaan perbaikan CI ini tidak tertinggal.
5. **KABEL DATA REALTIME KDS = SELESAI (batch `7650483`, 2026-09-23).** `useTiketDapur` jadi
   kontainer `LayarDapur`/`LayarBar`; umur tiket dari jam peladen (migrasi `0038_waktu_peladen.sql`).
   Bukti: suite SQL **79 lulus** · aplikasi **268 tes lulus** · mutasi 0038 **3/3 MERAH** ·
   62/62 perintah langkah pemeriksa CI LOLOS lokal. Rincian: `_log-sesi/LOG_SESI_2026-09-23.md`
   bagian "BATCH 2".
6. **REGISTRI LAYAR + KABEL DATA STOK/OPNAME = SELESAI (batch `4fc0e28`, 2026-09-23).**
   `DAFTAR_LAYAR` **11 layar** (8 layar G1 tetap wajib + `bar`/`stok`/`opname` resmi),
   `REGISTRI_AKSI` **38 aksi**, bantuan kontekstual **11/11 layar**, `docs/PETA_UI.md` digenerate
   ulang, kontrak `layar.test.ts` direvisi (layar tak dikenal tetap ditolak), kabel data baru
   `aplikasi/src/hook/useStok.ts`. Dasar keputusan Lee + bukti: `docs/DECISIONS_LOG.md`
   [Kelengkapan UI/2026-09-23] dan `_log-sesi/LOG_SESI_2026-09-23.md` bagian "BATCH 3".
8. **CATATAN WAJIB (insiden 2026-09-23):** setiap suntingan `docs/ops/SIAP-LANJUT.md` — termasuk
   §3 yang memang ditulis agent — WAJIB diikuti `python3 alat/periksa-rujukan.py` +
   `python3 alat/periksa-bersih.py` sebelum commit. Rujukan ke berkas yang belum ada harus
   ditandai pada BARIS YANG SAMA dengan salah satu penanda `(rencana`, `belum ada`, `belum dibuat`,
   `akan dibuat`, `menyusul`, `dijadwalkan`, atau `T<numor>-<nomor>` (kata `rencana,` saja tidak
   dikenali pola). Langkah CI "Pemeriksa fondasi…" berisi **63 perintah**, semuanya bisa
   dijalankan lokal sebelum push.
9. **URUTAN BERIKUTNYA:** (a) infra e2e Playwright (`aplikasi/uji/e2e/dapur.spec.ts` — berkasnya belum dibuat) — butuh dependensi dev baru + langkah CI baru (ingat: setiap perintah CI
   baru WAJIB didaftarkan di `GERBANG_WAJIB` + `periksa-semua.sh`, kalau tidak CI merah sendiri);
   (b) Fase 5 sisa: **T5-03 struk** (pajak & service terpisah), **menyambungkan `LayarKasir.tsx`
   ke layar Bayar** (lihat butir 13 — modal lama masih mengeras-kodekan 3 metode), lalu struk
   termal/buka-tutup shift. T5-01 dan T5-02 sudah selesai (butir 10 & 13).
   **Bukti manual/visual T4-03, T4-05, T4-10 tetap milik Lee** (agent tidak bisa memotret layar
   atau mencabut kabel jaringan).
10. **T5-02 RPC `bayar_pesanan` = SELESAI (batch 2026-09-23).** Pintu tunggal uang masuk ada di
    `supabase/migrations/0039_bayar_pesanan.sql` (kunci baris pesanan, pagar peran DI DALAM fungsi,
    kembalian dihitung peladen, idempoten, memajukan pesanan ke `lunas`, jejak audit, kode galat
    **BY-301**). Bukti: `supabase/tes/bayar_pesanan.sql` + `alat/uji-mutasi-0039.py` **6/6 MERAH**;
    suite SQL **81 lulus**. Dasar: `docs/DECISIONS_LOG.md` [Fase 5/2026-09-23].
11. **CACAT FONDASI DITUTUP: urutan rantai hash audit (migrasi `0040_urutan_rantai_audit.sql`).**
    `catatan_audit.waktu` memakai `now()` = waktu mulai transaksi, jadi dua baris audit dalam SATU
    transaksi selalu seri waktunya dan urutan rantai ditentukan UUID acak → pemeriksa rantai bisa
    melaporkan "tautan terputus" padahal tidak ada yang diubah (terukur 7 dari 12 run merah saat uji
    T5-02 ditulis). Kini rantai diurutkan kolom `urutan bigserial` yang diterbitkan peladen; payload
    hash tidak berubah sehingga hash lama tetap sah. Bukti: `supabase/tes/urutan_rantai_audit.sql`
    + `alat/uji-mutasi-0040.py` **4/4 MERAH**. Dasar: `docs/DECISIONS_LOG.md` [Fase 5/2026-09-23].
13. **T5-01 LAYAR BAYAR = SELESAI (batch 2026-09-23, CI `35817220796` SUCCESS).**
    `aplikasi/src/layar/kasir/Bayar.tsx` (komponen murni) + `aplikasi/src/hook/useBayar.ts`
    (kabel data). Metode bayar dari peladen dan hanya yang aktif; uang lewat RPC `bayar_pesanan`;
    kunci idempoten STABIL `bayar-<pesananId>-<urutan>`; kembalian pra-konfirmasi = perkiraan,
    yang sah dari peladen; pembayaran sebagian sah ("Bayar sisa"). Registri aksi
    `kasir.proses_bayar` dipindah dari `hitung_total` ke `bayar_pesanan`; `PETA_UI.md` digenerate
    ulang. Bukti: aplikasi **56 berkas / 305 tes**, `uji-mutasi-app.mjs` **9/9 MERAH** (+4 mutasi).
    **Yang sengaja belum:** `LayarKasir.tsx` belum disambungkan ke layar ini — modal bayar lamanya
    masih mengeras-kodekan `'tunai' | 'qris' | 'kartu'`. Menyambungkan berarti mengubah alur kasir
    (dan `AlurKasirE2E.test.tsx`), jadi sebaiknya diputuskan Lee lebih dulu.
14. **CATATAN LINGKUNGAN (2026-09-23):** sandbox sempat di-reset saat GitHub disambung ulang —
    klon kembali ke commit dasar dan **riwayat lokal hilang** (commit yang belum ter-push lenyap),
    tetapi isi berkas dikembalikan snapshot sebagai perubahan belum di-commit. Pemulihannya:
    `git fetch origin` → `git reset <ujung-remote>` (tanpa menyentuh isi kerja) → commit ulang.
    Klon baru juga **dangkal**: `periksa-paket.py` merah palsu sampai `git fetch --unshallow`
    (CI memakai `fetch-depth: 0`). Dependensi (`npm ci`, `pip install pgserver psycopg`) hilang semua.
    **Pelajaran: push segera setelah bukti lengkap.**
15. **Dua jebakan pemeriksa yang kena di batch ini:** (a) test id di repo ini `data-testid`, bukan
    `data-uji`; (b) `periksa-struktur.py` menolak pola warna heksadesimal di SEMUA `.ts/.tsx`
    termasuk berkas uji — teks `#101` pun kena, pakai `No. 101`.
16. **JARING PENGAMAN PINDAH SESI (2026-09-23):** seluruh pekerjaan sesi ini juga diikat tag
    **`arsip/arena-01a0cb7f-7c30697`** (sudah di-push ke origin). Kalau sandbox di-reset lagi dan
    riwayat lokal hilang, pekerjaan bisa dipulihkan dari tag itu tanpa mengandalkan snapshot:
    `git fetch origin --tags && git checkout -b <cabang> arsip/arena-01a0cb7f-7c30697`.
    Tag ini penanda baca-saja, bukan cabang — jangan dihapus sebelum Lee memutuskan.
12. **Yang diukur dan TIDAK jadi diuji (jangan diulang):** kunci baris `for update` di 0039 tidak bisa
    dibuktikan dengan mutasi karena `picu_pembayaran_jujur` (0012) mengunci baris pesanan yang sama saat
    INSERT — diukur langsung dua koneksi nyata (pgserver): pekerja tetap tertahan di pemicu, bukti
    `pg_stat_activity` wait_event `transactionid`, CONTEXT "while locking tuple (0,4) in relation
    pesanan". Jadi kunci 0039 adalah pagar lapis kedua; alasan lengkap di kepala `alat/uji-mutasi-0039.py`.

### Riwayat penutup §3 (jangan dijadikan rencana)

**PINDAH SESI (2026-09-23, permintaan Lee — tanpa merge):** sesi baru melanjutkan dari `arena/01a0c97c-resto-barokah` (ujung `d923e99`, semua ter-push) lewat pintu **"baca pro.md"**. **Langkah pertama sesi baru: periksa hasil CI `35797734100` (commit `d923e99`) — jangan klaim hijau tanpa bukti run sukses, dan jangan mulai pekerjaan baru sebelum CI terbaca.**

**RENCANA AKTIF (2026-09-22 malam, sesi arena/01a0c97c) — FASE 4 TUNTAS di kode & uji; sisa kecil:**

1. **SELESAI batch ini (jangan dikerjakan ulang):** seluruh Fase 4 — T4-01 `LayarDapur.tsx` (FIFO
   `dikirimPada` waktu peladen + keadaan + cadangan `antrean-lokal` + mode TV/T4-10) · T4-02
   `LayarBar.tsx` + `0033_tujuan_item.sql` · T4-03 `KartuPesanan.tsx` · T4-04 `0032` · T4-05
   `TombolHabis.tsx` + `0035_menu_habis_sumber.sql` (RPC `tandai_habis`, riwayat `menu_habis_riwayat`) ·
   T4-06 `Stok.tsx` + `0036_stok.sql` (RPC `set_stok`) · T4-07 `Opname.tsx` + `0037_opname.sql`
   (RPC `opname_stok`) · T4-08 penanda waktu 10/20 mnt · T4-09 `supabase/tes/anti_dobel.sql` +
   kasus T-409 dua koneksi nyata terkalibrasi di `alat/uji-konkuren.py` · T4-10. Bukti: suite SQL
   **78 berkas lulus**, aplikasi **253 tes lulus**, mutasi 0032/0033/0035/0036/0037 semua merah.
2. **Sisa Fase 4 (butuh keputusan/bukti Lee):** (a) bukti manual/visual — foto T4-03 (baca 2 meter),
   uji dua perangkat manual T4-05 (dapur & kasir), uji cabut-jaringan T4-10; (b) infra e2e
   Playwright (`aplikasi/uji/e2e/dapur.spec.ts` — rencana, belum dibuat) — belum ada pustakanya, butuh izin tambah
   dependensi; (c) **kabel data realtime** (langganan perubahan) untuk antrean KDS & penanda
   habis — saat ini komponen murni menunggu kontainer; (d) registri `DAFTAR_LAYAR` DIKUNCI tes
   lama (tepat 8 layar G1) — layar baru hidup via `App.tsx` tanpa entri registri; perluasan
   registri = perubahan kontrak = butuh putusan Lee.
3. **Lanjut natural berikutnya:** Fase 5 (pembayaran multimode, split bill, struk termal,
   buka/tutup shift) di `docs/ROADMAP.md` — atau kerjakan sisa (2) di atas lebih dulu.
4. **Aturan tetap:** TDD · migrasi 0001–0014 BEKU · kontrak tes lama MENANG (pelajaran
   `layar.test.ts` batch ini) · tanpa warna mentah · `--siapkan` SEBELUM commit penutup ·
   PR #1–#4 jangan merge tanpa keputusan Lee · tanpa deploy/sebar Supabase.

### Arsip riwayat penutup §3 (sejarah — JANGAN dijadikan rencana; nomor tugas lama di bawah bisa tidak sesuai ROADMAP)

> **MARATON FASE 1B, 1C, FASE 2, & FASE 3 KASIR/PESANAN POS SELESAI LENGKAP 100% (2026-09-22):** Seluruh fondasi Fase 1B, 1C, Fase 2, serta seluruh komponen utama Terminal Kasir POS Fase 3 (T3-01 s/d T3-16: Katalog Menu POS dinamis, Keranjang Server-Calculated tanpa manipulasi klien, Pemilih Denah Meja & Tipe Pesanan, Tagihan Terbuka / Open Bill, Kirim ke Dapur, Pembayaran Tunai/QRIS/EDC, Layar Pesanan Pelayan Mobile HP, Riwayat Pesanan Harian, Uji E2E Kasir & Beban Ringan) telah selesai dikerjakan dan diverifikasi penuh. Vitest suite 45 berkas (213 pengujian unit) dan 72 SQL suite 100% LULUS. Gerbang CI 100 gerbang diawasi dua arah.

**Langkah berikutnya (urut):**
1. **Fase 4: Dapur / Kitchen Display System (KDS) & Stok Dasar (T4-01 s/d T4-10)**:
   - `T4-01`: Layar dapur (makanan) dengan urutan FIFO (`aplikasi/src/layar/dapur/LayarDapur.tsx`).
   - `T4-02`: Layar bar/minuman terpisah (stasiun minuman).
   - `T4-03`: Status item pesanan (dimasak → siap saji → diantar) dengan tombol sentuh besar.
   - `T4-04`: Penanda waktu & peringatan pesanan lama (> 15 menit).
   - `T4-05`: Suara notifikasi pesanan masuk & siap.
   - `T4-06` s/d `T4-10`: Void/batal dari dapur berizin supervisor, opname stok harian sederhana, dan sinkronisasi realtime status pesanan.
2. **Fase 5: Pembayaran Multimetode & Tutup Kasir / Shift (M6, M1)**:
   - Pembagian tagihan (split bill per item / per nominal).
   - Cetak struk Bluetooth & format struk termal standar 58mm/80mm.
   - Buka/tutup shift kasir, rekonsiliasi kas laci (cash drawer), dan serah terima shift.

> **MARATON G3 — HANDOFF SESI BARU (2026-09-22):** T-04/A, T-05/B, T-06/C sudah dipanen; pagar 0024/0025/0026, regresi/mutasi, dan penguatan B-F01..B-F09 sudah masuk branch sesi. **Hosted CI `35691286819` untuk commit `be14b40` SUCCESS penuh, termasuk pemeriksa fondasi/history.** Sesi berikutnya melanjutkan pekerjaan teknis agent-owned T1-45/T1-30 dan bantah-balik AUD-2; jangan merge PR, deploy, atau sebar Supabase. A-F02 tentang keterjangkauan PostgREST produksi masih belum terverifikasi dan memerlukan izin Lee sebelum uji/sebar produksi. Rincian ada di `docs/uji/TINDAK_LANJUT_AUD2_2026-09-21.md`.

**RIWAYAT SEBELUM G3 — dua laporan diterima, tindak lanjut TERBUKA:** dua laporan asal `5529eae` dan `b8290b3` disimpan terpisah, byte-identik; format lolos di klon bersih. Sesi ketiga error **diabaikan**, tidak meminta audit/prompt pengganti. Target tetap `09bcb89`; K-2 A-F01/A-F02 BELUM direproduksi integrator, verdict B tidak menutupnya. Antrean 16 temuan, pemilik dan syarat bukti: `docs/uji/TINDAK_LANJUT_AUD2_2026-09-21.md`. T1-30/T1-45 tetap terbuka; tidak merge/deploy/perluasan fitur. Atas izin Lee, alur pengiriman berikutnya memakai locator privat repo/cabang/SHA paket/path, SHA target terpisah, prompt pendek DI CHAT, otomatis commit/push/verifikasi tanpa pengingat dengan index terisolasi + retry fast-forward (`docs/uji/PENGIRIMAN_LAPORAN_AMAN.md`). Cabang/working tree bisa bersama; larangan force/rebase/merge/timpa tetap. Paket beku tidak disunting.

**RIWAYAT SEBELUM LAPORAN MASUK — HASIL BATCH-5 (2026-09-21):** prasyarat CI `35571459040`/`73bd831` hijau sebelum implementasi. Kode akhir `09bcb89` **CI SUCCESS run 35574069120**; periksa-semua lokal LOLOS (65 SQL, 101 uji aplikasi, semua mutasi/concurrency). 0022, PIN pelanggan, sapuan penundaan, T1-30 parsial 0023/ACL mendarat. **BATAS SAAT INI: AUD-2 independen belum dijalankan.** Paket `docs/uji/paket-audit/AUD-2-2026-09-21-SIAP-TEMPEL.md` menargetkan `09bcb89`; jangan menyunting lingkup audit sampai laporan sah masuk. Lee membuka sesi auditor setelah exam (P-06); agent berikutnya ambil laporan (`python3 alat/audit-independen.py --ambil-laporan`), validasi kontrak/independensi lalu bantah-balik, perbaiki temuan sebelum mencentang T1-45. Setelah itu lanjut AST/initplan policy T1-30 sesuai `docs/uji/BUKTI_T130_KEAMANAN_SQL.md`; jangan membuat pengecualian agar CI hijau. Verifikasi/sebar Supabase tetap butuh izin Lee TERPISAH; tidak ada izin merge. Log `_log-sesi/LOG_SESI_2026-09-21_2.md`. Keputusan tertangguh: 0 terbuka / 25 selesai, tetapi implementasi & gerbang tersebut TIDAK selesai. Catatan lama di bawah = sejarah.

**MARATON GELOMBANG 2 DILUNCURKAN 2026-09-21 (sesi integrator arena/01a0c1d1):** T-01/T-02/T-03 DIBERIKAN di `docs/ops/PAPAN_TUGAS.md`; prompt 3 pekerja dikirim DI CHAT (blok siap tempel, REKAM butir 7); base branch sesi pekerja = `arena/01a0c1d1-resto-barokah`. Panen saat Lee bilang `Panen hasil maraton.` (verifikasi sendiri + merge berurutan + baterai tiap merge, AL-16). Sambil menunggu pekerja: lanjut §3 lama di bawah (B F-16/B F-14 lokal dulu).

**PINDAH SESI 2026-09-21 (Lee):** sesi berikutnya = integrator maraton AL-16 dengan base `main` (susul dulu cabang ini!). Maraton gelombang 1 **belum diluncurkan** — 3 tugas siap pakai (T-01/T-02/T-03) ada di `docs/ops/PAPAN_TUGAS.md` (DIBATALKAN sebelum jalan; terbitkan ulang sebagai DIBERIKAN saat Lee bilang `Siapkan maraton kerja sama.`, lalu kirim prompt pekerja DI CHAT sesuai REKAM butir 7).

**MARATON MALAM 2026-09-21 (tuntas; CI HIJAU `6e3ca83`) — baca ini lebih dulu.**

- **Ditutup malam ini:** K F-03 + F-11 §1b (migrasi `0018_perangkat_terdaftar.sql`: PIN hanya dilayani dari perangkat TERDAFTAR — id + kunci bcrypt, jawaban seragam `'Perangkat tidak dikenali.'`, lapis 12×/15 menit keyed `perangkat_id`, perangkat karangan dilayani **0×**; `daftarkan_perangkat`/`cabut_perangkat` izin `kelola_pegawai`) · D F-09 (kembar J F-09) · D F-10 (migrasi `0019_pesan_diskon_jujur.sql`: pesan diskon menunjuk alur nyata). **Temuan terbuka: 12.**
- **T1-24 JANGAN dicentang**: intinya sudah mendarat (0018), sisa DoD = kode pendaftaran sekali pakai + `persetujuan_perangkat` + gating staf via sesi perangkat → lanjut di T1-25/Fase 1C. Lihat catatan status di ROADMAP baris T1-24.
- **Aturan yang TERBUKTI lagi malam ini (AL-15):** migrasi baru yang menulis ulang fungsi membuat harness mutasi migrasi LAMA tumpul-semu — mutasi wajib diarahkan ke `create or replace` TERAKHIR. Sudah terjadi di 0015/0016 (diperbaiki, `berkas_rel=MIG18`). **Kalau kamu menambah migrasi 0020+ yang menulis ulang fungsi PIN/pesanan, periksa semua `alat/uji-mutasi-*.py` dan arahkan mutasinya ke definisi berlaku.**
- **Infra:** GitHub token sandbox bisa kedaluwarsa mid-sesi (push/gh 401) → minta Lee sambungkan ulang di Arena; `.git` lokal bisa di-reset ke `253d129` → pulihkan dengan `git fetch origin arena/01a0b7d1-resto-barokah` + `git reset --mixed <sha remote>` (berkas kerja tidak hilang); `node_modules` bisa terhapus → `npm ci --prefix alat` (+ root bila perlu). pglite HANYA di `alat/package.json`, jangan di root.
- **Auditor ketiga AUD-3-2026-09-20** (target `cbba401`) masih belum kirim laporan — cek `python3 alat/audit-independen.py --ambil-laporan` berkala; jangan tunggu pasif.
- **Rencana berikutnya (urut):** (1) panen laporan auditor ketiga bila masuk; (2) B F-16 (lingkup paket audit menutup berkasnya sendiri) & B F-14 (sapuan isolasi lintas resto) — keduanya lokal, tanpa keputusan Lee; (3) F F-18 (sisa oracle boolean pemasangan PIN) — hati-hati, butuh bukti mutasi; (4) F F-12/F F-13 tetap TERBLOKIR lingkungan (butuh 2 koneksi nyata); (5) I F-17 sisa = keputusan uang Lee (Stop Condition); (6) deploy 0017–0019 ke Supabase nyata butuh "Silahkan Sebar" baru dari Lee.
- **Standing:** PR #2 JANGAN merge; PR #1 untouched; beku migrasi ≤ 0016; setiap balasan ke Lee WAJIB ditutup "Langkah Lee".

**CATATAN PENTING PUTARAN 18aa (2026-09-20) — CI TIDAK BISA MULAI: TAGIHAN AKUN GITHUB (BUTUH LEE).**
**RALAT 18ab (2026-09-20, screenshot billing Lee):** penyebab PASTI = menit gratis organisasi **2.000/2.000 habis** (GitHub Free, tagihan $0 — BUKAN gagal bayar); reset otomatis ±1 Okt; mode hemat + opsi publik/transfer menunggu keputusan Lee (LANGKAH_PEMILIK bagian atas).

Dua run untuk commit `84d3126` **tidak pernah dijalankan**. Anotasi GitHub apa adanya:

> _"The job was not started because recent account payments have failed or your spending limit needs to be
> increased. Please check the 'Billing & plans' section in your settings."_

Jadi **merahnya bukan cacat kode**. Buktinya: seluruh rantai langkah CI (termasuk tiga langkah baru putaran 18z)
dijalankan ulang di **klon bersih** dari GitHub — semuanya LOLOS (npm ci/format/lint/typecheck/test/build/audit,
uji SQL 58 LULUS, harness mutasi app 5/5 + uji-diri, 0012/0014/0015/0016 (11 mutasi), Edge 17/17, dan seluruh pemeriksa Python).

**Dampak yang harus diketahui sesi berikutnya:** (1) tidak ada cap "CI hijau" dari GitHub sampai pulih → gerbang
paket audit (`alat/ci_target.py`, aturan H F-02) akan MENOLAK membuat paket baru (itu perilaku benar, fail-closed);
(2) alur **"Sebar skema"** juga tidak akan jalan. Langkah Lee ada di `docs/ops/LANGKAH_PEMILIK_SEKARANG.md`
(bagian paling atas) + butir `T-024` di `docs/TERTANGGUH.md`.

**Langkah berikutnya (urut):** lanjut maraton **tanpa** menunggu CI (verifikasi lokal = rantai yang sama) →
probe **F F-12** (concurrency) → I F-13/F-14/F-15/F-16 (probe PIN) → I F-02 & H F-09 (kupon PIN + CORS) →
H F-07 (kolom non-uang pesanan) → sisa K-3 → setelah tagihan GitHub beres: paket audit/review baru + "Sebar skema".

**PUTARAN 18z (2026-09-20) — TIGA TEMUAN SATU KELAS DITUTUP: "ALAT BILANG AMAN, PADAHAL BELUM TERBUKTI".**

- **F F-14 & I F-05 (dua laporan, satu cacat) — sambungan Supabase.** `ujiSambungan()` dulu hanya melihat
  kesehatan Auth: Auth 200 + jalur data 401/404/500 tetap dilaporkan "berhasil". Kini `ok = jalur.auth &&
jalur.data`, status tiap jalur dilaporkan di bidang `jalur`, dan pesan gagal menyebut jalur + HTTP-nya.
  Ujinya dulu memberi **satu status untuk dua jalur** — kombinasi yang dicari auditor memang mustahil teruji.
  Sekarang ada `jawabJalur({sehat, data})` + 7 kasus (401/403/500/404/503, jalur data tak terhubung, 206).
  Mutasi `ok` dikembalikan melihat Auth saja → **7 uji MERAH**.
- **I F-06 — kegagalan Storage di fondasi tema.** Penjagaan lama hanya mengelilingi PENGAMBILAN objek
  `localStorage`; `getItem`/`setItem` sendiri bisa melempar (`SecurityError` izin ditolak, `QuotaExceededError`
  penuh) sehingga effect React saat ganti tema bisa putus. Kini `bacaKunci()`/`tulisKunci()` menjaga
  pemanggilannya, `simpanPilihan()` **jujur** mengembalikan `false`, dan tema tetap berganti di layar.
  Mutasi penjagaan dicabut → **2 uji MERAH**.
- **Pagar permanen baru `aplikasi/alat/uji-mutasi-app.mjs`** (kelas yang sama dengan `alat/uji-mutasi-0015.py`
  untuk SQL): salinan `aplikasi/` di folder sementara → kontrol hijau → 5 mutasi perilaku WAJIB MERAH.
  **Merah PALSU ditolak:** pelajaran nyata sesi ini, opsi `--reporter=basic` sudah tidak ada di Vitest 5 sehingga
  semua mutasi sempat "merah" padahal ujinya tidak pernah jalan — harness kini hanya menerima merah yang benar-benar
  memuat kegagalan uji (bidang `merahSah`). `--uji-diri` 2/2 (pola mutasi salah ditolak · uji yang dilemahkan
  terdeteksi). Ikut CI + `periksa-semua.sh` + terdaftar gerbang wajib.

**Angka:** uji aplikasi **87 → 100** (13 uji baru). **Temuan terlacak: 86 → 53 DITUTUP · 28 TERBUKA** (baris penutup: 80; I F-05 ·
I F-06 · F F-14 ditutup di putaran ini).

**Langkah berikutnya (urut):** probe **F F-12** (concurrency hitung ulang — belum bisa di PGlite, catat jujur) →
I F-13/F-14/F-15/F-16 (probe PIN: tiga dugaan + satu terverifikasi) → I F-02 & H F-09 (kupon PIN lewat Edge + CORS)
→ H F-07 (kolom non-uang pesanan setelah lunas) → I F-08 (buku darurat) → sisa K-3 (PR-05…09, PR-13, PR-14) →
**hubungi Lee** untuk "Sebar skema".

**PUTARAN 18y (2026-09-20) — NAMA UJI TIDAK BOLEH LEBIH KUAT DARIPADA YANG DIUJI (I F-19 tuntas).**

Uji bernama `'memanggil onUbah saat diisi'` hanya merender HTML (SSR), memeriksa `type="text"`, lalu
**memastikan callback TIDAK terpanggil**. Artinya handler `onChange` yang tidak tersambung ke apa pun pun
akan hijau — "86 uji terbaca" sebagian tidak membuktikan apa yang namanya janjikan.

- **Penjaga mesin (baru)** di `aplikasi/alat/periksa-uji.py` (aturan 3): uji yang namanya menjanjikan interaksi
  ("saat diisi", "saat diklik", "memanggil on…") WAJIB memicu kejadian (`fireEvent`/`userEvent`/`dispatchEvent`/
  `.click(`/`.focus(`/`.type(`) — kalau tidak, GAGAL dengan **berkas:baris**. Sebelum ujinya diperbaiki, penjaga
  ini **langsung menunjuk cacat aslinya** (`aplikasi/src/komponen/komponen.test.tsx:145`).
- **Ujinya diperbaiki**: berkas uji memakai `// @vitest-environment jsdom` + `@testing-library/react`; isian
  benar-benar diisi (`fireEvent.change` → nilai `Budi`) dan `onUbah` diperiksa **nilainya**, plus satu uji nilai
  terkendali. Uji markup lain di berkas itu tetap SSR.
- **Bukti uji baru tidak tumpul (mutasi):** handler dilepas (`onChange` → kosong) → **1 uji GAGAL**; handler
  mengirim nilai salah (`+ 'X'`) → **1 uji GAGAL**; dipulihkan → **18 uji LULUS**. Berkas `KolomIsian.tsx`
  dikembalikan utuh (diff kosong).
- `--uji-diri` **5 kasus** (uji berjanji tanpa tindakan ditolak · dua kontrol diterima · `vitest.config.ts`
  dihapus ditolak), ikut CI + `periksa-semua.sh`, terdaftar gerbang wajib + 1 mutasi baru.

**Langkah berikutnya (urut):** **I F-05/I F-06** (klien sambungan & Storage tema) + **F F-14** (ujiSambungan bisa
hijau palsu) → probe **F F-12** → I F-13/F-14/F-15/F-16 (probe PIN) → I F-02/H F-09 (CORS & kupon PIN) →
sisa K-3 (PR-05…09, PR-13, PR-14) → **hubungi Lee** untuk "Sebar skema".

**PUTARAN 18x (2026-09-20) — VERSI NODE YANG DIKLANKAN DITURUNKAN DARI PUSTAKA TERKUNCI (I F-21 tuntas).**

Aplikasi mengiklankan `engines.node: ">=20"` (README: "Node.js 22, minimal 20"), padahal pustaka yang
terkunci menuntut lebih: `@supabase/supabase-js` **>=22.0.0** dan `vitest` **^22.12.0**. Pemakai yang
menuruti README bisa memasang Node yang tidak didukung pustaka wajib — iklan yang salah arah.

Yang dikerjakan:

- batas minimum kini **dihitung mesin** dari `aplikasi/package-lock.json` → **`>=22.12.0`**; entri yang
  bertanda `optional` (mis. `@napi-rs/lzma-*` bawaan rollup) sengaja TIDAK dihitung, karena npm melewatinya;
- `aplikasi/README.md` menulis `22.12+` dan ketiga alur GitHub memakai `node-version: '22.12.0'` — jadi
  **CI menguji tepat versi minimum yang diiklankan**, bukan versi lain;
- penjaga baru `aplikasi/alat/periksa-node.py` menolak: iklan lebih rendah / bentuk bukan `>=X` / README
  berbeda / lock tanpa `engines` (gagal-tertutup) / alur ber-`node-version` di bawah batas (bentuk `'22'`
  diartikan 22.0.0, jadi tidak cukup). `--uji-diri` **9 kasus**: 1 salinan utuh diterima, 7 mutasi ditolak,
  1 kontrol (entri opsional menuntut Node 30) tetap diterima;
- ikut `aplikasi/alat/periksa-semua.sh` dan CI; terdaftar sebagai gerbang wajib + 1 mutasi baru
  ("langkah pemeriksa versi Node dihapus → ditolak").

**Batas jujur:** yang dijamin adalah keselarasan iklan↔lock dan bahwa CI berjalan di versi minimum.
Ruang kerja sesi ini ber-Node 22.22.3, jadi "npm ci berhasil di 22.12.0" dibuktikan oleh CI.

**Langkah berikutnya (urut):** **I F-19** (uji bernama "memanggil onUbah saat diisi" tidak pernah mengisi input) →
**I F-05/I F-06** (klien sambungan & Storage tema) + **F F-14** (ujiSambungan bisa hijau palsu) → probe **F F-12** →
I F-13/F-14/F-15/F-16 (probe PIN) → sisa K-3 (PR-05…09, PR-13, PR-14) → **hubungi Lee** untuk "Sebar skema".

**PUTARAN 18w (2026-09-20) — BATAS EDGE FUNCTION DIUJI SUNGGUHAN (I F-07 tuntas).**

Sebelum ini berkas Edge hanya dijaga pemeriksa **teks** — tidak ada satu pun pengujian yang pernah
**menjalankan** handler-nya, jadi cacat batas lolos tanpa jejak:

- JSON `null` → `TypeError` (kasir melihat kegagalan platform, bukan 400 berbahasa Indonesia);
- UUID "36 tanda minus" lolos regex longgar `^[0-9a-f-]{36}$` → diteruskan ke database;
- jaringan putus pada `fetch` dan jawaban upstream yang bukan JSON → `Error`/`SyntaxError` tak tertangkap.

Dua-duanya ditutup: **perbaikannya** (badan permintaan diperiksa · UUID diperiksa lengkap sebelum
menyentuh database · satu bentuk jawaban gagal terkendali untuk semua gangguan teknis) dan
**penjaganya** — `alat/uji-edge-pin.mjs`:

- mengubah berkas ASLI `supabase/functions/verifikasi_pin/index.ts` TS → JS memakai `esbuild`
  (bukan menulis ulang tangan), lalu menjalankannya di `node:vm` **tanpa jaringan**
  (`Response`/`Request` milik Node, `Deno.serve`/`Deno.env`/`fetch` dikendalikan uji);
- 17 kasus batas (E01–E17), termasuk "PIN tidak pernah muncul di jawaban mana pun";
- **MERAH di 4 kasus sebelum perbaikan** (bukti uji ini tidak tumpul), hijau sesudahnya;
- jalan di `aplikasi/alat/periksa-semua.sh` dan CI (langkah tersendiri setelah `npm ci --prefix alat`;
  `esbuild` kini devDependency `alat/package.json`).
- Catatan kecil: fixture "PIN tidak lagi dibaca dari badan permintaan" di `alat/periksa-fungsi-pin.py`
  dibuat tahan penamaan variabel (refactor `isi` → `badan` bukan cacat).

**Langkah berikutnya (urut):** **I F-21** (minimum Node vs lockfile) → **I F-19** (uji yang tidak mengisi input) →
**I F-05/I F-06** (klien sambungan & Storage tema) + F F-14 → I F-13/F-14/F-15/F-16 (probe PIN) → sisa K-3/K-4 →
tutup batch mekanisme → **hubungi Lee** untuk "Sebar skema".

**CATATAN CI (2026-09-20, dua kali):** **(1)** CI commit `a2d6b16` MERAH — satu rujukan mati di bukti penutup I F-09 (`aplikasi/alat/pratinjau.sh` padahal berkasnya `aplikasi/alat/pratinjau.sh`), ditangkap `python3 alat/periksa-rujukan.py` (kelas yang sama dengan H F-08: jalur bukti wajib bisa dibuka dari akar repo); diperbaiki di `4ddb905`. **(2)** CI commit `17cefb5` (batch I F-07) MERAH — langkah CI BARU `node alat/uji-edge-pin.mjs` ditolak `python3 alat/periksa-gerbang-ci.py` karena belum terdaftar di daftar gerbang wajib; memang begitu aturannya (dua arah: tiap perintah CI wajib dikenal DAN tiap gerbang wajib wajib ada). Ditutup dengan mendaftarkannya sebagai gerbang ke-55 + satu mutasi uji-diri baru ("langkah uji batas Edge dihapus → ditolak"). Seluruh rantai pemeriksa CI dijalankan ulang lokal sebelum push: hijau.

**CATATAN CI (2026-09-20):** CI commit `a2d6b16` MERAH — sebabnya satu rujukan mati di bukti penutup I F-09 (`aplikasi/alat/pratinjau.sh`, seharusnya `aplikasi/alat/pratinjau.sh`), ditangkap `python3 alat/periksa-rujukan.py` (kelas yang sama dengan H F-08: jalur bukti wajib bisa dibuka dari akar repo). Sudah diperbaiki dan seluruh rantai pemeriksa CI dijalankan ulang lokal (hijau) sebelum push.

**PUTARAN 18v (2026-09-20) — BATCH "DOKUMEN JUJUR": 8 TEMUAN + 4 DUPLIKAT DITUTUP (47 ditutup · 34 terbuka).**

Dokumen yang menjanjikan lebih dari kenyataan, atau aturan yang saling bertabrakan, dibereskan sekaligus:

- **H F-06** `docs/KEAMANAN.md`: `hitung_total()` tidak lagi disebut "belum mendarat" — versi awalnya sudah hidup di
  `supabase/migrations/0014_penutup_celah_putaran13.sql`; yang belum: pembulatan (T1-16) & suite 12 uji uang.
- **H F-08** bukti T0-03 memakai jalur lengkap `aplikasi/src/lib/tema.ts`.
- **H F-10** klasifikasi penanda-palsu diberi justifikasi jujur: nyata di level DB, tetapi eksploitasi produksi
  menuntut koneksi SQL langsung (PostgREST tak mengizinkan `pg_catalog`); pagar 0015 tetap.
- **I F-09** `aplikasi/README.md` tidak lagi mencampur dua folder kerja (pemulihan: `bash aplikasi/alat/pratinjau.sh` dari dalam
  `aplikasi/`, dengan catatan bentuk akar; bagian pemeriksa ditandai "dari AKAR repo").
- **I F-10** resep audit: auditor **wajib kembali ke cabang sesinya** (`git symbolic-ref --short HEAD`) dan push eksplisit
  `git push origin HEAD:refs/heads/<CABANG-SESIMU>` sebelum menyerahkan laporan (blok kanonik & buku induk tetap identik).
- **I F-11** janji rahasia GitHub dikoreksi: terenkripsi ≠ tak terbaca (siapa pun yang boleh mengubah workflow bisa membacanya)
  → least privilege, TTL, jaga akses tulis repo.
- **I F-12** **satu aturan pindah sesi**: melihat/melanjutkan pekerjaan TIDAK perlu merge (`fetch` + `merge --ff-only`),
  merge PR ke `main` tetap keputusan Lee. Pendampingnya: `docs/ops/SIAP_AKUN_PEMILIK.md` disegarkan dan prasyarat PGlite
  (`npm ci --prefix alat`) kini tertulis di handoff.
- **D F-06** ROADMAP T1-15/T1-17 diberi catatan silang: fungsinya sudah hidup di 0014/0015 — **jangan tulis rumus kedua**.
- Duplikat yang obatnya sudah mendarat ikut ditutup: **B F-09 · B F-17 · D F-03 · D F-04** (paket wajib menunjuk induk commit
  sendiri · gerbang CI hijau · pemecah artefak).

**Langkah berikutnya (urut):** **I F-07** (boundary Edge: JSON null & galat upstream) → **I F-21** (minimum Node vs lockfile) →
**I F-19** (uji yang tidak mengisi input) → **I F-05/I F-06** (klien sambungan & Storage tema) + F F-14 → sisa K-3/K-4 →
tutup batch mekanisme → **hubungi Lee** untuk "Sebar skema".

**PUTARAN 18u (2026-09-20) — H F-05 & I F-20 TUNTAS: PEMBUAT PAKET BERHENTI MENUDUH PERINTAH/POLA SEBAGAI "BERKAS HILANG".**

Paket audit dulu menyuruh auditor mencari artefak yang sebenarnya NYATA, lengkap dengan label
"sudah [x] — berkasnya TIDAK ADA: laporkan!":

- `python3 alat/periksa-roadmap.py` → itu **perintah**, bukan berkas;
- `aplikasi/src/komponen/*.tsx` → itu **pola** yang cocok 13 berkas nyata;
- `src/lib/tema.ts` → itu **jalur relatif** folder `aplikasi/` (= `aplikasi/src/lib/tema.ts`).

Dua mesin tertangkap cacat yang sama: pembuat paket `alat/audit-independen.py` DAN pemeriksa daftar
temuan `alat/periksa-temuan-audit.py` (yang terakhir menolak bukti penutup berpola/jalur-relatif).

- Pemecah artefak bersama **`alat/artefak.py`** → `pisah_artefak()`: **berkas · perintah · pola ·
  hilang** (plus `pola-kosong` & `perintah-hilang`); jalur relatif folder kerja diselesaikan,
  rujukan baris (`…sql:120`) dibuang, dan pola dihitung berapa berkas nyata yang cocok.
- Paket audit sekarang menaruh perintah di bagian tersendiri **"1a. Perintah bukti"** — auditor
  MALAH memakainya; baris "TIDAK ADA" dihitung sekali per jalur+tugas (dulu duplikat = baris terpisah).
- Bukti: paket baru pada pohon sekarang → **0 baris** tuduhan palsu (dari 13) sementara artefak yang
  benar-benar hilang tetap dilaporkan; `--uji-diri` +10 contoh (persis contoh dari temuan ini) dan
  +2 kasus di `alat/periksa-temuan-audit.py` (pola/jalur relatif diterima · yang hilang tetap ditolak).

**Langkah berikutnya (urut):** sisa §1d/§1e (K-3/K-4) → **K-3** (PR-05…09, PR-13, PR-14) → **K-4** → tutup batch mekanisme →
**hubungi Lee** untuk "Sebar skema" (`0015` ke DB nyata) → `0015` dibekukan. Ingin mempercepat: paket audit berikutnya
sudah bisa dibuat (`python3 alat/audit-independen.py --paket AUD-3 --semua`) karena CI commit ini hijau.

**PUTARAN 18t (2026-09-20) — I F-03 & I F-04 TUNTAS: DUA "GERBANG PALSU" DITUTUP, SATU BUKTI PALSU HISTORIS KETEMU.**

- **I F-03 — penjaga PIN tumpul** (`alat/periksa-fungsi-pin.py`): dulu hanya mencari `console.` / `pin_hash` / `setItem`,
  sehingga **balasan yang mengembalikan PIN** (`{ …, pin: pin }`) dan **log lewat tanda kurung siku** (`console['log'](pin)`)
  lolos 9/9 exit 0. Sekarang: setiap bentuk `console` ditolak (titik, bracket, alias, `globalThis.console`) + `Deno.stdout/stderr`;
  variabel PIN **dibatasi ke tiga jalur sah** (dibaca dari badan permintaan · diperiksa bentuknya · diteruskan ke RPC).
  Jalur "teruskan" melekat pada **rentang panggilan `fetch(... rpc/ ...)`**, bukan pada kata kunci — jadi `p_pin: pin` di balasan
  tetap ditolak. Tambah aturan "PIN dibaca dari badan permintaan". `--uji-diri` 9 kasus (1 sumber sah + 8 contoh cacat, tiap
  tolakan harus DATANG DARI aturan yang benar) dan ikut berjalan di `periksa-semua.sh`.
- **I F-04 — penilai mutasi menerima crash sebagai bukti** (`alat/uji-mutasi-0015.py`): `lulus = (kode != 0)` diganti penilai
  bersama `alat/klasifikasi_mutasi.py` → HIJAU / **MERAH-PAGAR** (asersi `HARAPAN TIDAK TERPENUHI` / `SEBAB PENOLAKAN BUKAN YANG
DIHARAPKAN` di berkas `supabase/tes/`) / **RUSAK** (crash, sintaks, migrasi gagal terpasang, merah bukan asersi). Hanya
  MERAH-PAGAR yang dihitung bukti; RUSAK membuat harness GAGAL, bukan "MERAH (benar)".
- **Hasil sampingan yang penting:** pengetatan itu **langsung menemukan bukti palsu historis** — mutasi "pagar dikembalikan ke
  versi lama (K-1)" ternyata **gagal dikompilasi** (`"v_jejak" is not a known variable`, deklarasi hanya ditambahkan di kemunculan
  pertama fungsi) dan dulu dilaporkan "MERAH (benar)". Sudah diperbaiki (deklarasi di semua kemunculan) dan **benar-benar
  memerahkan uji K-1**. Seluruh **26 mutasi + kontrol penutup** kini LOLOS sebagai MERAH-PAGAR.
- Bukti: `python3 alat/periksa-fungsi-pin.py` (14/14) · `--uji-diri` (11 kasus) · `python3 alat/uji-mutasi-0015.py` (LOLOS) ·
  `--uji-diri` (10 kasus) · `bash aplikasi/alat/periksa-semua.sh`.

**Langkah berikutnya (urut):** **H F-05 / I F-20** (pembuat paket menyebut perintah/glob sebagai "berkas hilang") → sisa §1d/§1e
dan K-3/K-4 → tutup batch mekanisme → **hubungi Lee** untuk "Sebar skema" (`0015` ke DB nyata).

**PUTARAN 18s (2026-09-20) — H F-02 TUNTAS: PAKET WAJIB MENUNJUK COMMIT BER-CI HIJAU.**

Bukti masalahnya nyata: paket AUD-3 2026-09-19 menargetkan `4830b5a` yang dua run CI-nya **cancelled**
(ditimpa push berikutnya) — auditor memeriksa pohon yang tidak pernah lewat gerbang otomatis.

- `alat/ci_target.py` (baru): `status_ci(sha)` bertanya ke GitHub Actions; mengembalikan `bisa/hijau/run/rincian`.
  **Tidak bisa diperiksa ≠ hijau** (ketidak-tahuan tidak dibaca sebagai bukti aman). SHA pendek diperluas otomatis.
- Gerbang di pembuat paket: `alat/audit-independen.py --paket` & `alat/review-pr.py --siapkan` **MENOLAK** bila CI commit target belum hijau;
  ada jalan pengecualian `--izinkan-ci-belum-hijau "<alasan>"` yang **tercetak di paket** (izin pemilik, bukan diam-diam).
- Paket menulis `- **CI commit target:** success (run …)`; penjaga `alat/periksa-paket.py` aturan **F-02**:
  paket bertanggal ≥ 2026-09-20 wajib punya baris itu, klaim "success" **diperiksa ulang ke GitHub**, dan "belum hijau" tanpa izin pemilik ditolak
  (+2 kasus `--uji-diri`, termasuk mencari commit non-hijau sungguhan lalu membuktikan klaim palsu ditolak).

**Cara pakai saat mau menerbitkan paket berikutnya:** pilih commit yang CI-nya SUDAH hijau (atau tunggu), lalu
`python3 alat/audit-independen.py --paket AUD-3 --semua`. Kalau commit sekarang belum hijau, alat akan bilang.

**Langkah berikutnya (urut):** **I F-04** (classifier mutasi menerima crash sebagai "pagar bekerja") → **I F-03** (pemeriksa PIN tumpul/bracket)
→ **H F-05 / I F-20** (pembuat paket menyebut perintah/glob sebagai berkas hilang) → sisa §1d/§1e + K-3/K-4 → tutup batch lalu **hubungi Lee** untuk sebar skema.

**PUTARAN 18r (2026-09-20) — H F-01 TUNTAS: KATALOG CACAT KALIBRASI KELUAR DARI REPO (izin Lee).**

Izin Lee: _"Aku ikut yang terbaik menurut kamu. Klo sebaiknya dikeluarkan, silahkan keluarkan."_

- `/home/user/.kalibrasi/kalibrasi-cacat.json` (dipensiunkan ke luar repo — H F-01) (pasangan cari/ganti = **kunci jawaban**) **dipindah ke luar repo** →
  `KALIBRASI_DIR` (baku `/home/user/.kalibrasi/kalibrasi-cacat.json`); berjejak `docs/uji/BERKAS_PENSIUN.md` baris #2 + `docs/DECISIONS_LOG.md`.
- Salinan kalibrasi jalur mesin: `git archive` + satu commit bersih, katalog **dikeluarkan**, `pastikan_salinan_bersih()` menolak
  salinan yang membawa katalog/kunci/riwayat/perubahan belum-di-commit.
- Alat **gagal-tertutup**: katalog hanya dibaca dari luar repo (jalur mesin & review PR).
- Penjaga: `alat/periksa-kunci-kalibrasi.py` aturan **A2** (katalog tidak boleh ada di repo) + F + G → `--uji-diri` **13 kasus** semua menolak.
- Bonus mekanisme: `alat/periksa-rujukan.py` & `alat/periksa-temuan-audit.py` kini **mengakui daftar pensiun** (riwayat jujur ≠ rujukan mati);
  `periksa-temuan-audit.py` mengambil token pertama rujukan sehingga sel bukti boleh memuat perintah.
- Catatan lingkungan: `alat/node_modules` & `aplikasi/node_modules` **tidak ikut snapshot** sandbox → setelah ruang kerja pulih,
  jalankan `npm ci --prefix alat` (dan `--prefix aplikasi`) dulu sebelum uji SQL/mutasi.

**Langkah berikutnya (urut) — maraton lanjut tanpa menunggu Lee:**

1. **H F-02** (K-3): paket audit/review wajib menunjuk commit yang CI-nya **sudah hijau** — bukti di paket + penjaga/`T1-44`.
2. **I F-04 & I F-03** (K-3): classifier mutasi menganggap crash sebagai bukti pagar bekerja; pemeriksa PIN tumpul terhadap bracket.
3. **H F-05 / I F-20** (K-3): pembuat paket menyebut perintah/glob sebagai "berkas hilang" (tabel §1b memuat baris palsu).
4. Sisanya dari §1d/§1e + temuan lama K-3/K-4; yang **DUGAAN** wajib diprobe dulu.
5. Setelah temuan MEKANISME habis → tutup batch, **hubungi Lee** untuk menekan "Sebar skema" (menyebar `0015` ke database nyata), lalu `0015` dibekukan.

**PUTARAN 18q (2026-09-20) — KUNCI KALIBRASI TIDAK BISA LAGI DICONTEK (audit H F-01); SATU KEPUTUSAN MENUNGGU LEE.**

Bantah-balik temuan **H F-01** (K-2) membuktikan cacatnya **lebih parah dari dugaan laporan**:

1. Salinan auditor jalur mesin dulu dibuat `git worktree add` → di dalam salinan itu `git diff`/`git show` **langsung memperlihatkan
   baris mana yang ditanami cacat** (cacat ditanam sebagai perubahan belum-di-commit).
2. Berkas katalog `/home/user/.kalibrasi/kalibrasi-cacat.json` (dipensiunkan ke luar repo — H F-01) (pasangan cari/ganti = daftar jawaban) ikut tersalin ke salinan auditor.
3. Jalur review PR menyematkan diff ke paket, dan peninjau bisa mencocokkannya dengan katalog yang ada di repo.

**Sudah diperbaiki (kode + penjaga + dokumen):**

- `alat/audit-independen.py` — salinan kalibrasi dibuat lewat `git archive` + `git init` + **satu commit bersih**; katalog dikeluarkan dari salinan;
  fungsi baru `pastikan_salinan_bersih()` menolak salinan yang masih membawa katalog/berkas kunci atau perubahan belum di-commit.
- `alat/review-pr.py` — katalog **hanya** dibaca dari luar repo (`KALIBRASI_DIR`, baku `/home/user/.kalibrasi`); bila katalog masih di dalam repo,
  perintah **GAGAL-tertutup** dengan instruksi jelas (tidak membuat bahan yang bisa dicocokkan).
- `alat/periksa-kunci-kalibrasi.py` — aturan **F** (salinan kalibrasi bersih) & **G** (katalog review PR dari luar repo) + **3 mutasi uji-diri baru** (12 kasus, semua menolak).
- Dokumen: `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §7 · `docs/uji/kalibrasi/CARA-PAKAI.md` · `docs/uji/AUDIT_RIWAYAT.md` (status H F-01) ·
  `docs/uji/TEMUAN_LUAR_CAKUPAN_REVIEW.md` (L-03).

**MENUNGGU KEPUTUSAN LEE (satu langkah, tidak bisa agent putuskan sendiri):** memindahkan berkas katalog cacat ke luar repo
(`/home/user/.kalibrasi/kalibrasi-cacat.json` (dipensiunkan ke luar repo — H F-01) → `/home/user/.kalibrasi/kalibrasi-cacat.json`) + barisnya di daftar pensiun `docs/uji/BERKAS_PENSIUN.md`
(aturan daftar itu mewajibkan keputusan Lee). Selama belum dipindah: **jalur kalibrasi review PR tidak bisa dipakai** (sengaja),
sementara jalur mesin sudah aman dan tetap jalan.

**Langkah berikutnya:** (1) tunggu jawaban Lee soal pemindahan katalog; (2) lanjut temuan mekanisme lain — **H F-02** (paket audit
menargetkan commit yang CI-nya belum hijau → penjaga paket wajib menolak) dan **I F-20/I F-04/I F-03** (alat audit sendiri);
(3) bantah-balik sisa temuan laporan H & I (yang DUGAAN wajib diprobe dulu).

**PUTARAN 18p (2026-09-20) — DUA LAPORAN AUDIT LANJUTAN MASUK: 31 TEMUAN BARU TERDAFTAR (2 sudah tertutup).**

Ambil laporan: `python3 alat/audit-independen.py --ambil-laporan` (idempoten) menemukan **5 berkas** — 2 laporan baru + 3 versi lama
yang tertimpa (diselamatkan otomatis). Kontrak mesin:

- **Laporan H** = `docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbcb.md` (sesi `arena/01a0bbcb`): 10 temuan, kalibrasi **12/12**,
  **DITOLAK MESIN** (4 alasan: label grup cakupan diparafrase) → **isinya tetap dipakai**, tiap temuan dapat baris di §1d.
- **Laporan I** = `docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbd2-907e29e.md` (ronde kedua sesi `01a0bbd2`): 21 temuan,
  kalibrasi 5/5, cakupan 442/480, **LOLOS KONTRAK** → baris penutup di §1e.

Keduanya mengaudit commit `4830b5a` (snapshot yang sama dengan laporan F). 31 temuan sudah **terdaftar** dan dilacak
`alat/periksa-temuan-audit.py` (kunci H & I; ringkasan alat dibuat **data-driven** supaya laporan berikutnya cukup ditambah di kamus,
tanpa menyunting baris cetak). Daftar penutup: **86 temuan terlacak · 29 ditutup · 52 terbuka**.

**Sudah tertutup tanpa pekerjaan baru** (perbaikannya mendarat sesudah commit yang diaudit, jadi auditor tak bisa melihatnya):

- **I F-01 (K-1)** dasar pajak/service sebelum diskon → ditutup bagian 6 `0015` + uji `supabase/tes/urutan_uang.sql`.
- **I F-13 (K-1 dugaan)** oracle peran lintas penyewa = tumpang-tindih F-11 laporan F → ditutup bagian 10 `0015` + uji `supabase/tes/pin_helper_pribadi.sql`.
- **I F-17 (K-1 dugaan)** hitung ulang pesanan lunas → **DITUTUP sebagian**; sisa jalurnya (pembayaran sudah ada lalu item diturunkan) masih `T1-45`.

**Prioritas yang menyerang mekanisme kita sendiri** (jangan diabaikan — ini kelas cacat yang membuat audit kehilangan nilainya):

1. **H F-01** kunci kalibrasi masih terbaca dari dalam repo (penutupan D F-05 belum tuntas) → `T1-44`.
2. **H F-02 / I F-20 / I F-04 / I F-03** paket audit menargetkan commit ber-CI-belum-hijau, perintah/glob disebut "berkas hilang",
   classifier mutasi menerima crash sebagai "bukti pagar bekerja", dan pemeriksa PIN tumpul (bracket) → `T1-44`.
3. **H F-03** (pemilik): database nyata baru memuat `0001`–`0014`; `0015` **belum tersebar**. Klaim "tidak ada langkah menunggu"
   sudah dikoreksi di `docs/ops/LANGKAH_PEMILIK_SEKARANG.md`. **Penyebaran menunggu batch selesai** — berkas migrasi yang sudah masuk
   database tidak boleh diubah lagi, jadi jangan sebar `0015` di tengah maraton.

**Langkah berikutnya (urut):**

1. Bantah-balik temuan K-2/K-3 dulu (yang terverifikasi) lalu yang **DUGAAN** wajib diprobe sebelum disebut nyata — daftar lengkap ada di §1d/§1e.
2. Kembali melanjutkan penutupan sisa laporan F (F-07 → `T1-13`, F-09 → `T8-01`) + 16 temuan lama K-3/K-4.
3. Kalau sudah tidak ada temuan MEKANISME yang tersisa → batch T1-45 ditutup, minta Lee menekan "Sebar skema" (tindakan pemilik), lalu `0015` **dibekukan** dan pekerjaan berikutnya pindah ke `0016+`.

**PUTARAN 18o (2026-09-20) — BANTUAN-BALIK 3 TEMUAN AUDIT F: F-10 & F-11 NYATA (DITUTUP), F-13 DIREDAM (TETAP TERBUKA).**

Pola yang dipakai: **bantah-balik dulu, baru memperbaiki** — tiga probe baru di
`docs/uji/audit/probe-2026-09-20/` meng-ASERSI keadaan yang salah; selama probe masih LULUS, cacatnya nyata.

1. **F-10 (K-2) — NYATA, DITUTUP (bagian 11 `supabase/migrations/0015_penutup_celah_putaran16.sql`):**
   `aud-3-f10-admin-cabang-izin.sql` LULUS = admin Cabang Pusat membaca izin pegawai Cabang Dua
   (8 baris = seluruh penyewa). Kontrak (`docs/TECH_SPEC.md` §294 · `docs/PRD.md` · `docs/DISCOVERY.md` 53) berkata
   admin cabang **hanya cabangnya** → policy `izin_pilih` diselaraskan ke kontrak **dan** ke pola policy
   `pengguna_pilih` (satu aturan). Uji `supabase/tes/rls_pengguna.sql` §5 dikoreksi (dulu mengunci 8 baris).
   Probe kini **GAGAL** = cacat hilang.
2. **F-11 (K-2) — NYATA, DITUTUP (bagian 10):** `aud-3-f11-helper-pin.sql` LULUS = kasir memanggil
   `peran_lebih_tinggi(<uuid siapa pun>, <uuid siapa pun>)` sebagai oracle hierarki (termasuk lintas resto).
   Perbaikan dua lapis: **hak execute klien dicabut** + **`p_pemanggil` dipakukan ke `auth.uid()`**.
   Uji `supabase/tes/pin_helper_pribadi.sql` (termasuk pembungkus SECURITY DEFINER = "jalur baru tanpa
   pembungkus identitas") + kontrol owner tetap boleh mengganti PIN bawahan. Probe kini **GAGAL**.
3. **F-13 (K-2, DUGAAN) — DIREDAM, BELUM DITUTUP (bagian 10b):** `nomor_pesanan_berikutnya()` mengambil nomor
   di bawah `pg_advisory_xact_lock` per (cabang, tanggal) dan kembali **VOLATILE**. Pembuktian yang diminta
   laporan adalah uji dua transaksi nyata; lingkungan uji proyek (PGlite, satu koneksi) belum bisa menjalankannya
   → temuan **tetap TERBUKA** dengan catatan jujur (jangan dicap selesai). Yang dijaga mesin: sifat serialisasinya
   (`supabase/tes/nomor_pesanan_kunci.sql` + 2 mutasi wajib-MERAH). Sama untuk **F-12** (uang) — sudah diredam
   `for update` di bagian 6, uji concurrency menyusul.

**Bukti mesin batch ini:** suite SQL `node alat/uji-sql.mjs` **53 LULUS · 0 GAGAL** · `python3 alat/uji-mutasi-0015.py`
**25 mutasi wajib MERAH + kontrol hijau** (kini termasuk F-10, F-11, F-13) · daftar temuan `docs/uji/AUDIT_RIWAYAT.md`
§1c **26 DITUTUP / 23 TERBUKA** · `docs/DECISIONS_LOG.md` 3 entri baru · `docs/ROADMAP.md` progres bagian 10–11.

**Langkah berikutnya (urut):**

1. **Bantah-balik sisa temuan audit F** — yang masih **TERBUKA**: F-07 (`T1-13`, tabel `catatan_audit` memang belum
   dibangun), F-09 (`T8-01`, kontrak privasi pelanggan belum ada jalurnya), F-12 & F-13 (dipagari, butuh uji dua
   transaksi), sisanya ber-pemilik di §1c. Jangan buka temuan baru sebelum ini beredar habis; jangan menutup
   F-12/F-13 tanpa bukti concurrency nyata.
2. Lanjut **K-3** (PR-05…PR-09, PR-13, PR-14) lalu **K-4** (PR-11 & D F-04 milik `T1-44`).
3. Aturan tetap: bagian baru `0015` + uji regresi + mutasi (`ganti_terakhir` untuk definisi yang ditulis ulang) +
   `DECISIONS_LOG.md` bila menyentuh uang/keamanan; commit & push per batch; **jangan merge PR mana pun** tanpa Lee.

**PUTARAN 18n (2026-09-20) — CI MERAH DIPERBAIKI: alat bukti mutasi memilih definisi yang berlaku (kemunculan TERAKHIR).**

Tiga commit (`e8487a8`, `7aab673`, `4a5b1d6`) gagal di langkah "bukti mutasi pagar migrasi 0012 + 0013"
walaupun pemeriksaan lokal hijau. Sebabnya **alat bukti mutasi**, bukan kode aplikasi:

1. Sejak `0015` menulis ulang fungsi yang sama di bagian berbeda (mis. `picu_item_jaga` di bagian 1 dan
   bagian 9), pola mutasi muncul DUA kali di berkas yang sama → alat lama menolak menjalankan (`LEWAT`,
   dihitung gagal). Sekarang: berkas berlaku = **migrasi terbaru yang memuat pola**, dan mutasi menyentuh
   **kemunculan TERAKHIR** (`ganti_terakhir()`) = definisi yang benar-benar berlaku.
2. Dua mutasi jadi **tumpul** karena menyunting definisi PERTAMA yang ditimpa definisi terakhir.
3. Pola `M14-12` dibuat khas penjaga kupon **DISKON** (dulu identik dengan penjaga kupon void → ambigu).
4. Uji `supabase/tes/persetujuan_void.sql` diperkuat: kupon sekali pakai diuji pada pesanan ber-**dua item**
   supaya yang menahan benar-benar aturan kupon, bukan aturan idempotensi pembatalan yang baru (F-05).

**Bukti mesin:** `python3 alat/uji-mutasi-0012.py` **16/16 MERAH** (kode 0) · `python3 alat/uji-mutasi-0014.py`
**17/17 MERAH** (kode 0) · `python3 alat/uji-mutasi-0015.py` **21 kasus LOLOS** (kode 0) · suite SQL
**51 berkas** · **CI `61e8d92` HIJAU** (push & PR). Catatan jujur ada di `STATUS.md` & `PROJECT_STATE.md`.

**Langkah berikutnya (urut) — maraton T1-45 lanjut:**

1. Bantah-balik sisa **11 temuan audit F**: mulai **F-07** (`catatan_audit` belum ada → pemilik `T1-13`),
   **F-08** (`T1-24`…`T1-26`, Fase 1B), **F-09** (`T8-01`) — ketiganya memang pekerjaan yang belum
   dijadwalkan selesai, bukan cacat tersembunyi; lalu yang **DUGAAN** (F-10 izin admin cabang · F-11 helper
   PIN · F-12 serialisasi uang · F-13 nomor pesanan) → WAJIB diprobe dulu sebelum disebut nyata.
2. Lanjut temuan lama K-3 (PR-05…PR-09, PR-13, PR-14) lalu K-4 (5 butir; PR-11 & D F-04 milik `T1-44`).
3. Aturan tetap: bagian baru `0015` + uji regresi + mutasi + `DECISIONS_LOG.md` bila menyentuh
   uang/keamanan; commit & push per batch; **jangan merge PR mana pun** tanpa Lee.

**PUTARAN 18m (2026-09-20) — BAGIAN 9 SELESAI: F-04 DITUTUP (status item & pembatalan berjejak).**

Pola yang sama: probe dulu, baru perbaikan. Probe `docs/uji/audit/probe-2026-09-20/aud-3-f04-status-item.sql`
dulu **LULUS** (cacat ada: item bisa lahir `siap`, status bisa melompat/mundur, item bisa dibatalkan
hanya dengan mengubah statusnya), sesudah perbaikan **GAGAL**. Perbaikannya di
`supabase/migrations/0015_penutup_celah_putaran16.sql` **bagian 9** (versi berlaku `picu_item_jaga`):
item baru selalu `baru`; status hanya maju satu langkah `baru → dimasak → siap` (TECH_SPEC ART-4);
`batal` **hanya** lewat baris `pembatalan` resmi (beralasan, ber-PIN bila sesudah dapur).

**Bukti mesin:** suite SQL **51 berkas LULUS · 0 GAGAL** · `python3 alat/uji-mutasi-0015.py` **21 kasus**
(semua wajib MERAH terbukti) · daftar temuan `docs/uji/AUDIT_RIWAYAT.md` §1c = **24 DITUTUP / 25 TERBUKA** ·
`python3 _sistem/validate_system.py` PASS · `python3 alat/periksa-bersih.py` LOLOS · keputusan di
`docs/DECISIONS_LOG.md`. **Pelajaran mekanisme:** karena `picu_item_jaga` kini punya definisi berlaku di
bagian 9, mutasi WAJIB menyentuh definisi TERAKHIR (dua mutasi lama sudah disesuaikan).

**Langkah berikutnya (urut) — maraton T1-45 lanjut:**

1. **Sisa 11 temuan audit F**, mulai yang bisa diprobe cepat: **F-07** (`catatan_audit` belum ada →
   pemilik `T1-13`, dicatat bukan disembunyikan) · **F-08** (`T1-24`…`T1-26`, Fase 1B) · **F-09** (`T8-01`) ·
   lalu yang **DUGAAN** (F-10 izin admin cabang · F-11 helper PIN · F-12 serialisasi uang · F-13 nomor
   pesanan): dugaan WAJIB diuji dulu dengan probe, tidak boleh langsung disebut nyata. Terakhir K-3
   (F-14 `ujiSambungan`, F-15 fokus modal, F-16 handoff basi, F-18 oracle PIN sisa).
2. **Lanjut temuan lama**: K-3 (PR-05…PR-09, PR-13, PR-14) lalu K-4 (5 butir; PR-11 & D F-04 milik `T1-44`).
3. Aturan tetap: bagian baru `0015` + uji regresi + mutasi + `DECISIONS_LOG.md` bila menyentuh
   uang/keamanan; commit & push per batch; **jangan merge PR mana pun** tanpa Lee.

**PUTARAN 18l (2026-09-20) — BAGIAN 8 SELESAI: TIGA CACAT K-2 AUDIT F DITUTUP (commit `e8487a8`).**

Sama polanya seperti 18k: dibuktikan dulu dengan probe sendiri, baru diperbaiki.
Probe `docs/uji/audit/probe-2026-09-20/aud-3-f03-f05-f06-uang.sql` dulu **LULUS** (berarti cacat ada);
sesudah perbaikan **GAGAL** (berarti cacat hilang). Perbaikannya di
`supabase/migrations/0015_penutup_celah_putaran16.sql` **bagian 8** — semuanya pemeriksaan TAMBAHAN
pada pemicu yang sudah ada (definisi lama di berkas beku `0012`/`0013`/`0014`):

1. **F-03** — metode bayar yang dinonaktifkan pemilik tidak bisa lagi mencatat uang
   (`supabase/tes/metode_bayar_nonaktif.sql`).
2. **F-05** — satu target pembatalan = satu jejak; kiriman ulang (klik ganda kasir / antrean
   perangkat offline) DITOLAK sehingga laporan kerugian tidak bisa tergandakan
   (`supabase/tes/pembatalan_sekali.sql`; uji lama `supabase/tes/pembayaran.sql` diselaraskan
   memakai pesanan kedua karena pembatalan ulang target yang sudah batal memang harus ditolak).
3. **F-06** — stempel lifecycle (`dibayar_pada`, `dibatalkan_pada`, `alasan_batal`) tidak bisa
   dikarang perangkat lewat UPDATE biasa, termasuk menghapusnya; jalur peladen tetap bebas dan
   kasir tetap boleh mengirim pesanan ke dapur (`supabase/tes/lifecycle_pesanan.sql`).

**Bukti mesin:** suite SQL **50 berkas LULUS · 0 GAGAL** · `python3 alat/uji-mutasi-0015.py` **20 kasus**
(3 mutasi baru wajib MERAH, terbukti) · `bash aplikasi/alat/periksa-semua.sh` hijau ·
`python3 alat/periksa-bersih.py` LOLOS · `python3 _sistem/validate_system.py` PASS · daftar temuan
`docs/uji/AUDIT_RIWAYAT.md` **§1c = 23 DITUTUP / 26 TERBUKA** · keputusan di `docs/DECISIONS_LOG.md`.

**Langkah berikutnya (urut) — maraton T1-45 lanjut:**

1. **Bantah-balik + tutup sisa 12 temuan audit F**, mulai dari yang bisa diprobe cepat:
   F-04 (state machine item bisa dilewati) · F-07 (`catatan_audit` belum ada → `T1-13`) ·
   lalu yang berstatus **DUGAAN** (F-10 izin admin cabang, F-11 helper PIN, F-12 serialisasi uang,
   F-13 nomor pesanan) — dugaan WAJIB diuji dulu, tidak boleh langsung disebut nyata.
2. **Lanjut temuan lama**: K-3 (PR-05…PR-09, PR-13, PR-14) lalu K-4 (5 butir; PR-11 & D F-04 milik `T1-44`).
3. Aturan tetap tiap perbaikan: bagian baru `0015` + uji regresi + mutasi (`mutasi(..., uji=)`) +
   entri `DECISIONS_LOG.md` bila menyentuh uang/keamanan; commit & push per batch; **jangan merge PR mana pun**.

**PUTARAN 18k (2026-09-20) — BAGIAN 6 SELESAI: TIGA CACAT UANG DITUTUP (commit `d2ba20a`).**

Tiga cacat uang yang dibuktikan probe di 18j **sudah diperbaiki** di `supabase/migrations/0015_penutup_celah_putaran16.sql`
**bagian 6** (berkas `0001`–`0014` tetap beku). Aturan uang kini hidup di satu tempat (`hitung_total`):

1. **F-01a** — pajak PB1 & service dihitung dari subtotal **setelah** diskon (aturan terkunci `docs/TECH_SPEC.md` §329-331).
   Contoh: 100.000 didiskon 20.000 → PB1 8.000 · service 4.000 · total **92.000** (dulu 95.000). Regresi uji: 27.000 − 1.350
   → dasar 25.650 · PB1 2.565 · service 1.283 · total **29.498**.
2. **F-01b** — `pengaturan.pembulatan` dibaca lagi dan diterapkan di langkah **TERAKHIR**, arah **KE BAWAH** (langkah 500:
   31.050 → 31.000). Arah pembulatan TIDAK PERNAH dikunci dokumen (diperiksa ulang PRD §88/§229, TECH_SPEC §331, ROADMAP
   T1-15/T1-16) → arah ini **diputuskan sekarang** dan dikunci uji; bisa dibalik satu baris bila Lee minta lain.
3. **F-02** — pesanan `lunas`/`batal` tidak bisa dihitung ulang dari perangkat; jalur pemicu peladen tetap sah dibedakan
   lewat `pg_trigger_depth() = 0` (penanda `set_config` DITOLAK: bisa dipalsukan klien = mengulang celah K-1). Baris pesanan
   dikunci `for update` (mengurangi risiko temuan dugaan F-12).

**Bukti mesin yang wajib tetap hijau:** `node alat/uji-sql.mjs` → **47 berkas LULUS · 0 GAGAL** · `python3 alat/uji-mutasi-0015.py`
→ **17 kasus** (4 mutasi baru: pajak dari pra-diskon · pembulatan diabaikan · penjaga lunas dilepas · pembulatan dibalik ke atas —
semuanya terbukti MERAH) · probe lama `docs/uji/audit/probe-2026-09-20/aud-3-f01-f02-uang.sql` kini **GAGAL = cacat hilang** ·
`python3 alat/periksa-bersih.py` LOLOS · `python3 _sistem/validate_system.py` PASS · `bash aplikasi/alat/periksa-semua.sh` hijau.
Keputusan uang dikunci di `docs/DECISIONS_LOG.md` (entri 2026-09-20). Seluruh **18 temuan audit F** kini punya baris + pemilik di
`docs/uji/AUDIT_RIWAYAT.md` **§1c** (dijaga `alat/periksa-temuan-audit.py`; F-17 → T1-44 · F-07 → T1-13 · F-09 → T8-01).

**Langkah berikutnya (urut) — maraton T1-45 lanjut:**

1. **Bantah-balik + tutup sisa 15 temuan audit F** (mulai dari yang K-2 dan bisa dibuktikan probe: F-03 metode bayar nonaktif ·
   F-05 pembatalan tidak idempoten · F-06 metadata lifecycle bisa ditulis klien · F-07 `catatan_audit`); yang berstatus **DUGAAN**
   (F-10/F-11/F-12/F-13) wajib diuji dulu dengan probe sebelum disebut nyata.
2. **Lanjut temuan lama**: K-3 (PR-05…PR-09, PR-13, PR-14) lalu K-4 (5 butir; PR-11 & D F-04 milik `T1-44`).
3. Setiap perbaikan = bagian baru `0015` + uji regresi + mutasi (`mutasi(..., uji=)`) + entri `DECISIONS_LOG.md` bila menyentuh
   uang/keamanan; commit per batch + push ke `arena/01a0b7d1-resto-barokah`; **jangan merge PR mana pun** tanpa Lee.
4. Fase 1B (`0016`+) baru dimulai **setelah** T1-45 tuntas (aturan: tidak ada kode fitur baru sebelum audit & rework selesai).

**PUTARAN 18j (2026-09-20) — HASIL AUDIT INDEPENDEN MASUK: 3 CACAT UANG TERBUKTI NYATA.**

Lee menjalankan 3 sesi auditor sekaligus (2026-09-19 malam). Yang sudah mendarat: **satu laporan AUD-3 menyeluruh**
(`docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbd2.md`, cabang berbeda → tidak bertabrakan) — **LOLOS KONTRAK**,
kalibrasi **5/5**, verdict **TIDAK-BERSIH**, 18 temuan; plus satu **review fondasi putaran 3** (mekanisme lama, cabang
`01a0b9f2`) yang **tidak digabung utuh** karena berakar di `main` (akan menimpa berkas terbaru) — hanya dipanen per butir.

**Bantah-balik sesi kerja (bukan percaya laporan):** probe sendiri `docs/uji/audit/probe-2026-09-20/aud-3-f01-f02-uang.sql`
(dijalankan `node alat/uji-sql.mjs …` → **LULUS = cacat ada**) membuktikan **tiga cacat jalur uang NYATA**:

1. **PB1 & service dihitung dari subtotal SEBELUM diskon** — melanggar aturan terkunci di docs/TECH_SPEC.md §329-330
   ("pajak & service dari subtotal SETELAH diskon"). Contoh nyata: subtotal 100.000 + diskon 20.000 → mesin menulis
   pajak 10.000 & service 5.000 (seharusnya 8.000 & 4.000), total 95.000 (seharusnya 92.000).
2. **`pengaturan.pembulatan` tidak pernah dibaca** — pemilik memilih 500/1000 tetapi total tetap 31.050.
3. **RPC `hitung_total` bisa menulis ulang angka pesanan yang sudah LUNAS** — kasir memanggilnya dan total 31.050
   berubah jadi 33.750 hanya karena tarif pajak di pengaturan berubah. Melanggar ART-4/Aturan Bisnis 11.

**Langkah berikutnya (urut) — perbaiki di `0015 bagian 6` + uji + mutasi — SUDAH DIKERJAKAN, lihat PUTARAN 18k di atas:**

1. `hitung_total`: basis pajak/service = subtotal SETELAH diskon; baca `pengaturan.pembulatan`; tolak penulisan ulang
   pesanan `lunas`/`batal` dari panggilan klien (koreksi sah hanya lewat pembatalan resmi); kunci baris pesanan
   (`for update`) supaya dua kasir bersamaan tidak saling menimpa angka.
2. Uji regresi baru + probe lamanya WAJIB jadi MERAH; tambah mutasi di `alat/uji-mutasi-0015.py`.
3. Sisa temuan audit (K-2/K-3, 15 butir) dibantah-balik batch berikutnya; **T-022/T-023** sudah masuk `docs/TERTANGGUH.md`.

**PUTARAN 18i (2026-09-19) — CELAH MEKANISME AUDIT DITUTUP (auditor terblokir).**

Sesi auditor independen Lee (`arena/01a0b9f2`) **berhenti di langkah 1** — bukan karena proyeknya cacat, tetapi karena:
(a) Lee menyalin **berkas cetakan** `docs/uji/PROMPT_AUDIT_INDEPENDEN.md`, yang kalimat pembukanya (di sumber kanonik) masih memuat
baris kosong `<<< TEMPEL ISI docs/uji/paket-audit/… DI SINI >>>` — jadi auditor melihat paket belum diisi; dan (b) sesi auditor baru
bercabang dari `main` sehingga `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` tidak ada di checkout-nya, sementara paket tidak memberi cara
mengambil bahan. Auditor berhenti dengan jujur, tidak menulis apa pun (benar secara aturan).

**Perbaikan (semua ber-mesin):**

1. `alat/audit-independen.py` — kalimat pembuka di berkas siap-tempel kini **dibersihkan dari penanda kosong** dan diberi **langkah 0
   AMBIL BAHAN**; paket menyebut **commit + cabang** target dan perintah `git fetch origin <cabang> && git checkout --detach <sha>`.
2. `docs/uji/PROMPT_AUDIT_INDEPENDEN.md` + `PANDUAN_PENGGUNA.md` (blok C4) — langkah 0 ditambahkan (dijaga cek identik); berkas cetakan
   diberi **peringatan tebal** di kepalanya: "JANGAN SALIN BERKAS INI — salin `<paket>-SIAP-TEMPEL.md`".
3. `alat/periksa-paket.py` — **aturan baru**: berkas siap-tempel paket audit wajib tanpa `<<<`, memuat bagian `SAMBUNGAN: PAKET AUDIT`,
   dan memuat cara mengambil bahan di bagian pembukanya; + 2 mutasi uji-diri (kini 8 kasus, semuanya terbukti bisa MENOLAK).
4. Nama berkas paket tidak lagi menimpa paket lain di hari yang sama (`<tingkat>-<tanggal>-<sha7>.md` bila sudah ada).
5. `.obsidian/workspace.json` dikeluarkan dari Git (sudah di `.gitignore`) — kehadirannya membuat pembuat paket berhenti `F-13`.
6. Riwayat jujur: baris audit **E — TERBLOKIR** di `docs/uji/AUDIT_RIWAYAT.md`.

**Langkah berikutnya (aksi Lee):** salin berkas **`docs/uji/paket-audit/AUD-3-2026-09-19-4830b5a-SIAP-TEMPEL.md`**
(seluruh isinya, dari baris pertama sampai terakhir) ke **chat auditor baru**, lalu kirim laporannya ke sesi ini. Sementara menunggu,
maraton T1-45 lanjut ke **K-3**.

**PUTARAN 18h (2026-09-19) — MARATON T1-45: SELURUH K-2 TUNTAS (4/4).**

Bagian 4–5 `supabase/migrations/0015_penutup_celah_putaran16.sql`:

- **PR-03 — hitungan nomor pesanan tidak bocor antar resto.** `nomor_pesanan_berikutnya()` (SECURITY DEFINER,
  bisa dipanggil klien) kini memeriksa keterlihatan cabang (`cabang_pantau_saya`) sama seperti `hitung_total` dan
  `total_dibayar`; kasir Resto B tidak lagi mendapat angka pesanan Resto A. Peladen (tanpa identitas) tetap bisa,
  karena pemicu penomoran pesanan baru berjalan sebagai peladen — uji `supabase/tes/nomor_pesanan_isolasi.sql`.
- **PR-04 — pesan PIN kembar dibuat netral.** Kalimat 'PIN itu sudah dipakai pegawai lain' MEMASTIKAN angka kiriman
  adalah PIN aktif kolega (oracle). Sekarang jawabannya netral ('PIN itu tidak bisa dipakai — pilih angka lain'),
  sementara alasan sebenarnya tetap tercatat di `percobaan_simpan_pin`. Catatan jujur: sifat berhasil-vs-ditolak tetap
  bisa dibaca, jadi pengendali biaya menebak tetap **pembatas 20 percobaan/15 menit** (T1-23) — dicatat di
  `docs/DECISIONS_LOG.md`, bukan diklaim hilang. Uji `supabase/tes/pin_bukan_oracle.sql` (dua uji lama yang memeriksa
  pesan lama diselaraskan).

**Bukti mesin:** suite SQL **46 berkas LULUS · 0 GAGAL**; `python3 alat/uji-mutasi-0015.py` **15 kasus — 13 mutasi wajib
MERAH semuanya terbukti merah**, 2 kasus memang diharapkan hijau. Sisa temuan **16** (14 `T1-45`, 2 `T1-44`).

**Langkah berikutnya (urut) — lanjut maraton ke K-3:**

1. **K-3 (7):** PR-05 pra-dapur tanpa izin/jejak · PR-06 jejak hierarki ikut rollback · PR-07 kupon tanpa ikatan pesanan
   (jalur Edge buntu) · PR-08 saldo awal stok tanpa baris buku · PR-09 PIN warisan 4 angka buntu · PR-13 `KEAMANAN.md`
   menunjuk tabel hantu · PR-14 hak `service_role`/`peringkat_peran`.
2. **K-4 (5):** PR-15 hapus meja memutus riwayat · temuan ringan lain · D F-04 & PR-11 (pemilik `T1-44`).
3. Fase 1B: `T1-24`/`T1-25`/`T1-26` dengan nomor migrasi `0016`+.

**PUTARAN 18g (2026-09-19) — MARATON T1-45: K-2a + K-2b DITUTUP.**

Dua temuan K-2 tuntas, keduanya di **bagian 2–3** `supabase/migrations/0015_penutup_celah_putaran16.sql`:

- **PR-02 — void satu item tidak lagi membatalkan seluruh pesanan.** Pemicu resmi
  `picu_pembatalan_jejak` sekarang menutup pesanan (`status = 'batal'`) **hanya** bila tidak ada item hidup
  tersisa atau pembatalannya memang tingkat pesanan; pesanan yang ditutup menandai **seluruh** itemnya batal
  (tidak ada lagi keadaan setengah jalan). Akibatnya pembayaran sisa tidak lagi buntu — uji
  `supabase/tes/void_satu_item.sql` (termasuk membayar item yang masih hidup, dan pesanan yang memang batal).
- **Audit D F-01 — diskon tidak bisa lagi ditanam sesudah uang tercatat.** Pemicu baru `diskon_awal_pesanan`
  menolak tambah/ubah/hapus baris diskon pada pesanan `lunas`/`batal`; jalur sahnya pembatalan/void resmi. Nama
  pemicu sengaja berjalan **sebelum** pemicu nilai `diskon_batas` (abjad nama) supaya penolakan berbunyi tentang
  status, dan urutan itu ikut dikunci mutasi — uji `supabase/tes/diskon_sesudah_lunas.sql`.

**Bukti mesin:** suite SQL **44 berkas LULUS · 0 GAGAL** (`node alat/uji-sql.mjs`); `python3 alat/uji-mutasi-0015.py`
**11 kasus — 10 mutasi wajib MERAH semuanya terbukti merah**, 1 kasus memang diharapkan hijau; keputusan dikunci di
`docs/DECISIONS_LOG.md` `[Uang/2026-09-19]`. Sisa temuan **18** (16 `T1-45`, 2 `T1-44`).

**Langkah berikutnya (urut) — lanjut maraton, sisa `T1-45`:**

1. **K-2 (sisa 2):** kebocoran hitungan `nomor_pesanan_berikutnya` lintas resto (PR-03, sekaligus tabrakan nomor
   antar-kasir) · oracle PIN kembar (PR-04).
2. **K-3 (7):** PR-05 pra-dapur tanpa izin/jejak · PR-06 jejak hierarki ikut rollback · PR-07 kupon tanpa ikatan
   pesanan (jalur Edge buntu) · PR-08 saldo awal stok tanpa baris buku · PR-09 PIN warisan 4 angka buntu ·
   PR-13 `KEAMANAN.md` menunjuk tabel hantu · PR-14 hak `service_role`/`peringkat_peran`.
3. **K-4 (5):** PR-15 hapus meja memutus riwayat · D F-04 & PR-11 + sisa temuan audit ringan (pemilik `T1-44`).
4. Fase 1B: `T1-24`/`T1-25`/`T1-26` dengan nomor migrasi `0016`+.

**PUTARAN 18f (2026-09-19) — MARATON T1-45: K-1 (PR-01) DITUTUP.**

Temuan **paling berbahaya** tuntas. Sebelumnya kasir bisa memalsukan penanda transaksi
(`set_config('resto.pembatalan_pesanan', …)`) lalu membatalkan item sesudah dapur **tanpa PIN atasan & tanpa satu pun
baris jejak**. Perbaikan ada di **migrasi baru** `supabase/migrations/0015_penutup_celah_putaran16.sql` **bagian 1**:
penanda transaksi tidak lagi diakui di mana pun; pembatalan item setelah dapur hanya sah lewat baris `pembatalan`
resmi (0013: tahap + PIN + kupon sekali pakai), dan pemicu resmi berhenti menulis penanda itu.

**Bukti:** uji regresi `supabase/tes/pembatalan_penanda_palsu.sql` (4 serangan dari kursi kasir, semuanya ditolak;
keadaan data tidak berubah) + `alat/uji-mutasi-0015.py` — **6 mutasi**, termasuk "kembalikan versi lama yang bocor",
"lepas pemicunya", "beri pengecualian diam-diam untuk peran kasir" → semuanya **MERAH** (terbukti), kontrol hijau.
Masuk CI sebagai **gerbang ke-52** (uji + bukti mutasi). Suite SQL kini **42 berkas LULUS · 0 GAGAL**. Keputusan
dikunci di `DECISIONS_LOG.md` `[Keamanan uang/2026-09-19]`.

**Langkah berikutnya (urut) — lanjut maraton:**

1. **K-2 (sisa 4)** — diskon pada pesanan `lunas`/`batal` (audit D F-01) · void satu item ikut membatalkan seluruh
   pesanan (PR-02) · kebocoran hitungan `nomor_pesanan_berikutnya` lintas resto (PR-03) · oracle PIN kembar (PR-04).
   Ditulis sebagai **bagian 2…5 dalam `0015_penutup_celah_putaran16.sql`** + uji regresi + mutasi baru di
   `alat/uji-mutasi-0015.py`.
2. K-3/K-4 (16 temuan tersisa), lalu Fase 1B (`T1-24`/`T1-25`/`T1-26` dengan nomor migrasi `0016`+).
   (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

**PUTARAN 18e (2026-09-19) — FASE 0 TUNTAS: HALAMAN PUBLIK NAIK; MARATON T1-45 DIMULAI.**

Lee menulis **"Boleh naik"** (izin publik — Stop Condition, jadi wajib menunggu). Agent memicu penanda
`aplikasi/SEBAR-HALAMAN`: run `35440300274` hijau (unggahan pertama), lalu `35440432817` hijau (unggahan ulang +
**pencatatan alamat otomatis**). Alamat publik: **https://resto-barokah.fatrizmubarok.workers.dev** — **HTTP 200**.
Bukti dibaca dari **anotasi** (`ALAMAT-PUBLIK`) karena log job GitHub tidak bisa dibaca dari lingkungan agent;
alat baru `aplikasi/alat/catat-alamat.mjs` (+`--uji-diri` 6 kasus) menjadi **gerbang CI ke-51** dan membuat
"hijau" berarti halaman benar-benar menjawab. Alamat & cara mundur dicatat di `docs/ops/ALAMAT_PUBLIK.md`;
`T0-09` DITUTUP, `T-021` SELESAI (terbuka kini **6**).

**Penjaga batas mode bimbingan diperkuat (permintaan Lee):** `alat/periksa-panduan.py` kini memeriksa blok
AL-14 **dan** §14 `AGENT_OPERATING_GUIDE.md`; mutasi yang menghapus batas (2 kasus baru) WAJIB ditolak.

**Langkah berikutnya (urut) — MARATON:**

1. **T1-45 K-1** (paling berbahaya): penanda `resto.pembatalan_*` bisa dipalsukan kasir → void sesudah dapur tanpa
   PIN & tanpa jejak. Ditulis sebagai migrasi BARU `supabase/migrations/0015_penutup_celah_putaran16.sql`
   (+ uji regresi di `supabase/tes/`, + `alat/uji-mutasi-0015.py` semua mutasi WAJIB MERAH).
2. Lanjut K-2 (diskon pada lunas/batal · void satu item · kebocoran nomor lintas resto · oracle PIN) → K-3/K-4.
3. Setelah T1-45: Fase 1B (T1-24/25/26) memakai nomor migrasi `0015`+ sesuai catatan; lalu T1-37 (B.4–B.9).
   (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

**PUTARAN 18d (2026-09-19) — PEMERIKSAAN PRA-MARATON (permintaan Lee) SELESAI.**

Diperiksa ulang semua yang bisa terlupakan: butir tunggu (**7 terbuka**), daftar temuan (audit §1b + review PR),
rencana pekerjaan ulang (`docs/uji/DAFTAR_PEKERJAAN_ULANG.md`), dan angka-angka di dokumen. Hasil:

1. **PR-12 DITUTUP** — label `12/12` basi di `aplikasi/alat/periksa-semua.sh` diganti label tanpa angka (angka benar
   selalu datang dari ringkasan alat).
2. **Angka sisa temuan dibetulkan: 23 → 21 terbuka** (19 milik `T1-45`; PR-11 & D F-04 milik `T1-44`). Sebelumnya
   dokumen menulis 23 padahal F-05/F-07/PR-10 sudah ditutup lebih dulu — kelas cacat F-14.
3. **Bentrok penomoran ditemukan & dibereskan:** `T1-24`/`T1-25`/`T1-26` masih merencanakan migrasi `0012`–`0014`
   yang kini terpakai & **beku** → diberi catatan wajib memakai nomor baru `0015`–`0017`.
4. **Tidak ada temuan tanpa pemilik** dan tidak ada pekerjaan setengah jalan yang tersembunyi.

**Langkah berikutnya (urut):**

1. **`T-021` halaman publik** — tinggal izin Lee (`Boleh naik`); rahasia Cloudflare sudah dipasang.
2. **T1-45 sisa 21 temuan** (19 milik `T1-45`) — mulai K-1, ditulis sebagai migrasi BARU `0015_…` dst.
3. **Fase 1B (T1-24/25/26)** — setelah temuan tuntas, memakai nomor migrasi `0015`+ sesuai catatan baru.
   (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

**PUTARAN 18c (lanjutan) — MODE BIMBINGAN DITANAM + LANGKAH B LEE SELESAI.**

Lee menyelesaikan **Langkah B** (rahasia `CLOUDFLARE_API_TOKEN` dipasang) dan meminta dua hal: (a) bimbingan singkat
saat ia memegang layar, (b) mekanismenya **ditanam** di sistem. Hasilnya: alur **AL-14** (`PANDUAN_PENGGUNA.md`,
8 bidang lengkap) + **§14** (`docs/AGENT_OPERATING_GUIDE.md`) + baris `PROFIL_PENGGUNA.md` + rekam pesan §16.
Pemicu: `Tolong bimbing.` · `Mode bimbingan.` · `Beri arahan step by step.` · `Aku bingung, pandu aku.`
Penutup: `Sudah beres, lanjut normal.` Penjaga `alat/periksa-panduan.py`: **MIN_ALUR 13 → 14** + topik wajib
"mode bimbingan". **Batas yang disampaikan ke Lee:** mode ini hanya memendekkan cara bicara — Stop Conditions §12
(biaya, keamanan/uang/data, keputusan terkunci, deploy publik) dan klaim "selesai" tetap butuh bukti diperiksa dulu.

**Langkah berikutnya (urut):**

1. **`T-021` (halaman publik)** — tinggal **izin publik** dari Lee (`Boleh naik`). Begitu dikatakan: buat penanda
   `aplikasi/SEBAR-HALAMAN` → alur mengunggah → catat alamat `*.workers.dev` + pemeriksaan HTTPS → hapus penanda.
2. **T1-45 sisa 21 temuan** (19 milik `T1-45`; PR-11 & D F-04 milik `T1-44`) — K-1…K-4 dalam bentuk migrasi **BARU** `0015_penutup_celah_putaran16.sql`
   (berkas `0001`–`0014` beku; penjaga `alat/periksa-migrasi-beku.py`), tiap perbaikan + uji regresi + mutasi wajib MERAH.
   (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

**PUTARAN 18c (2026-09-19) — SKEMA HIDUP DI PROYEK NYATA: `T0-08` DITUTUP, `T-020` SELESAI.**

Lee menyelesaikan **Langkah A** (2 rahasia Supabase di kotak rahasia GitHub); agent memicu berkas penanda
supabase/SEBAR-SKEMA → run `35435248540` **hijau berurutan** (`link` → `db push --dry-run` → `db push` →
`migration list`), jadi 14 migrasi kini ADA di proyek `bdvjirmbuqelmduztryj`. Bukti baca data (setara `select 1`):
gerbang CI ke-50 membaca tabel katalog dengan kunci publik → **HTTP 200** (run `35435414653`).

**Aturan baru yang mengikat (dikunci di `DECISIONS_LOG.md`):** berkas migrasi `0001`–`0014` **DIBEKUKAN** — semua
perubahan skema, termasuk seluruh perbaikan temuan audit K-1…K-4, WAJIB ditulis sebagai berkas BARU `0015`+ dan
dijaga `alat/periksa-migrasi-beku.py` (ikut berjalan di CI, punya `--uji-diri`, plus mutasi "penjaga dihapus"
di `alat/periksa-gerbang-ci.py --uji-diri`).

**Langkah berikutnya (urut):**

1. **T1-45 sisa 21 temuan** (PR-12 sudah ditutup 2026-09-19) — mulai **K-1**, tetapi kini dalam bentuk **`supabase/migrations/0015_penutup_celah_putaran16.sql`**
   (berkas lama tidak boleh disunting), lengkap dengan uji regresi + semua mutasi wajib MERAH.
2. **`T-021` (halaman publik)** — menunggu DUA hal dari Lee: rahasia `CLOUDFLARE_API_TOKEN` (panduan
   `docs/ops/LANGKAH_PEMILIK_SEKARANG.md`, pakai templat **Edit Cloudflare Workers**, bukan _Create Custom Token_)
   dan izin **"Boleh naik"** karena deploy publik = tindakan tak bisa dibatalkan.
3. **Uji ulang berkas uji `supabase/tes/` di proyek nyata** (bcrypt asli pgcrypto) — bukti bahwa perilaku di proyek
   Lee sama dengan PostgreSQL lokal; dicatat di `supabase/README.md`, belum dijadwalkan sebagai tugas.
   (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

**PUTARAN 18b (2026-09-19) — FASE 0 DIBERESKAN (akun pemilik aktif). RENCANA BERIKUTNYA: K-1.**

Keadaan sekarang: `T0-00` + butir tunggu `T-018` **DITUTUP** — Lee membuat akun **Supabase + Resend + Cloudflare** dan
mengisi nilai non-rahasia di `docs/ops/DAFTAR_KUNCI_PEMILIK_NONSECRET.md` (commit `bd68685`; kunci rahasia tidak pernah
masuk repo/obrolan). Selesai hari ini: klien Supabase aman `aplikasi/src/lib/supabase.ts` (+10 uji) · alat uji sambung
`aplikasi/alat/cek-supabase.mjs` (+`--uji-diri` 5 kasus) · **gerbang CI ke-50** `npm run cek:supabase` (bukti live: run
`35432334878` hijau, langkah ke-11 = success) · jalur rilis `aplikasi/wrangler.toml` + `npm run deploy`.

**Dua hal menunggu Lee — jangan dikerjakan tanpa jawaban:** `T-020` menyebar 14 migrasi ke proyek Supabase nyata (butuh
kredensial pemilik; sesudahnya DoD `select 1` T0-08 bisa dituntaskan) · `T-021` deploy publik halaman kosong ke Cloudflare
(tindakan publik & tak bisa dibatalkan).

**Bukti jalur (2026-09-19, sudah dijalankan):** penanda terpasang → kedua alur **menyala lalu berhenti aman** di gerbang rahasia tanpa menyentuh proyek (run `35433200326` skema, `35433200375` halaman; semua langkah penyebaran `skipped`) · penanda dihapus → kedua alur **hijau tanpa kerja** (run `35433237658`, `35433237656`) — jadi tidak ada penyebaran tak sengaja di kiriman berikutnya. Penjaga gerbang kini memeriksa **urutan** perintah (pratinjau wajib benar-benar mendahului penyebaran) dan menolak 9 mutasi alur.

**Jalurnya sudah disiapkan mesin (2026-09-19):** Lee tinggal menempel **3 rahasia** ke kotak rahasia GitHub
(`SUPABASE_ACCESS_TOKEN`, `SUPABASE_DB_PASSWORD`, `CLOUDFLARE_API_TOKEN`) — panduan langkah bernomor tanpa perintah:
`docs/ops/LANGKAH_PEMILIK_SEKARANG.md` (baris `BUKU_UJI_PEMILIK` P-04/P-05). Setelah Lee bilang "Rahasia sudah dipasang",
agent: (1) buat berkas penanda supabase/SEBAR-SKEMA → alur menjalankan **dry-run lebih dulu** lalu menyebar → hapus
penanda; (2) catat bukti tabel ada; (3) bila Lee setuju, buat penanda aplikasi/SEBAR-HALAMAN → alur menaikkan halaman
→ catat alamat publik + hapus penanda. Kedua alur diawasi `alat/periksa-gerbang-ci.py` (dua arah, 8 + 5 perintah, **urutan diperiksa**).

**Langkah berikutnya (urut):**

1. **T1-45, sisa 21 temuan** — mulai **K-1** (penanda `resto.pembatalan_*` dipalsukan → void sesudah dapur tanpa PIN
   & tanpa jejak), lalu **K-2** (diskon pada `lunas`/`batal` · void satu item jangan menutup pesanan · kebocoran
   `nomor_pesanan_berikutnya` lintas resto · oracle PIN kembar), lalu K-3/K-4 (jejak berjenjang, kupon↔pesanan Edge
   `p_pesanan_id`, buku besar stok, PIN warisan 4 angka, grant `service_role`/`anon`, tautan meja, tabel hantu
   `percobaan_masuk`, label `12/12` basi, generator paket audit, pesan diskon F-10).
   Target: `supabase/migrations/0015_penutup_celah_putaran16.sql` + `supabase/tes/` + `alat/uji-mutasi-0015.py`.
2. Setiap perbaikan wajib: uji regresi baru + `alat/uji-mutasi-0015.py` (semua mutasi MERAH) + suite penuh hijau +
   `DECISIONS_LOG.md` bila menyentuh cara membuktikan izin/uang.
3. Butir tertangguh terbuka **8** (batas 12) → di akhir batch, tawarkan jawaban agent untuk semuanya.
4. Kalau Lee menjawab `T-020`/`T-021`, kerjakan itu lebih dulu: Fase 0 tuntas adalah syarat sebelum pekerjaan Fase 1
   berlanjut (dan penyebaran skema membuka uji RLS di layanan nyata — nilai besar untuk penutupan T1-45).

**Jangan merge PR #2** selama K-1/K-2 masih terbuka. PR #1 tetap tidak disentuh.

**PUTARAN 18 (2026-09-19) — 25 TEMUAN PENINJAU DIBANTAH-BALIK (25/25 NYATA); 2 SUDAH DITUTUP, SISA 23.**

Dua laporan diterima (sesi peninjau `arena/01a0b85b`): AUD-3 menyeluruh (10 temuan, **laporan DITOLAK MESIN** karena
kelengkapan format — label grup cakupan diparafrase + cabang memuat 2 laporan; isinya tetap dipakai setelah
diverifikasi ulang) dan review PR putaran16 (15 temuan, **LOLOS KONTRAK**, verdict TIDAK-BERSIH). Semua temuan
**dibantah-balik sendiri dengan probe** dan semuanya NYATA (0 palsu). DITUTUP: **D F-05** (kunci kalibrasi keluar
dari repo + daftar pensiun + bahan review PR hidup di luar repo) dan **PR-10** (gerbang CI gagal-terbuka: penjaga
kini dua arah — 49 perintah CI diawasi, `if:` dilarang — dibuktikan menolak di salinan `/tmp/gc2`).

**Langkah berikutnya yang wajib (urut):**

1. **Lanjutkan `T1-45`** — sisa **21 temuan**. Urutan nilai:
   **(a) K-1** penanda `resto.pembatalan_*` jangan dipercaya (kasir bisa memasang penanda transaksi sendiri →
   void sesudah dapur tanpa PIN & tanpa jejak; bukti probe peninjau sudah direproduksi);
   **(b) K-2** diskon pada pesanan `lunas`/`batal` · void satu item jangan menutup seluruh pesanan · kebocoran
   `nomor_pesanan_berikutnya` lintas resto · oracle PIN kembar;
   **(c)** K-3/K-4: jejak penolakan berjenjang, kupon ↔ pesanan (Edge `p_pesanan_id`), buku besar stok, PIN
   warisan 4 angka, grant `service_role`/`anon`, tautan meja, tabel hantu `percobaan_masuk`, label `12/12` basi,
   generator paket audit (baris "TIDAK ADA" palsu), pesan diskon F-10.
   Target berkas: `supabase/migrations/0015_penutup_celah_putaran16.sql` + `supabase/tes/` + `alat/*`.
2. Setiap perbaikan: uji regresi baru + `alat/uji-mutasi-0015.py` (semua mutasi WAJIB MERAH) + suite penuh hijau
   - `DECISIONS_LOG.md` bila menyentuh cara membuktikan persetujuan/keamanan uang.
3. **Satu hal masih menunggu Lee:** auditor diminta memperbaiki **format** laporannya (label grup cakupan sama
   seperti paket + satu laporan per cabang) lalu mengirim ulang agar auditnya sah formal.
4. Selagi menunggu: butir tertangguh terbuka **7** (batas 12) — tawarkan jawaban agent untuk masing-masing.

**Jangan merge PR #2** (temuan K-1/K-2 masih terbuka di commit yang direview). PR #1 tetap tidak disentuh.

**PUTARAN 17 SEDANG BERJALAN (2026-09-19) — putaran verifikasi, MENUNGGU LEE.** Paket peninjau
**sudah terbit & ter-push** (target `93a50ba`): audit
`docs/uji/paket-audit/AUD-3-2026-09-19-SIAP-TEMPEL.md` dan review PR
`docs/uji/review-pr/PKT-2026-09-19-pr-01-putaran16-SIAP-TEMPEL.md` (PR **#2**; jalur risiko Merah).
Tugas Lee: **buka 2 chat baru** (idealnya model berbeda) dan **salin satu berkas `-SIAP-TEMPEL` ke
tiap chat**; setelah selesai bilang **"Laporan audit/review sudah masuk, periksa."** Keadaan
menunggu ini **normal dan tidak menghambat**: sambil menunggu, agent boleh menutup cacat lain yang
ditemukan sendiri (aturan: cacat yang sudah diketahui ditutup dulu supaya peninjau tidak membuang
anggaran). Saat laporan masuk: ambil (`--ambil-laporan`), **bantah-balik setiap temuan dengan probe
sendiri**, tutup yang nyata, catat yang palsu.

**Catatan pilihan cabang (penting untuk sesi baru):** handoff ini menunjuk
`arena/01a0b7d1-resto-barokah` — dipilih **supaya pekerjaan terbaru tidak hilang**: cabang sesi
sebelumnya (`arena/01a0a8a2-resto-barokah`) berhenti di `0af1cf9` dan **tidak memuat** paket peninjau
2026-09-19 + perbaikan putaran ini. Mesin kini **menolak** handoff yang menunjuk cabang tanpa keadaan
kerja terbaru (`alat/lanjut-sesi.py`, uji-diri 39 kasus) — jadi kalau Lee ingin melanjutkan dari
cabang lain, itu tetap haknya, tapi harus lewat `--lanjut-dari` atau `--paksa` (tercatat).

**Sesi ditutup (putaran 16, 2026-09-18)** atas perintah Lee: _"Siapkan pindah sesi dan tutup sesi ini dengan baik."_
Sebelum menutup, pertanyaan kepercayaan Lee diperiksa jujur dan **4 celah nyata ditutup** (rantai "kalimat perintah
sederhana Lee → alur" sekarang dijaga mesin): Prompt Pembuka item **2d** menunjuk `PANDUAN_PENGGUNA.md`; **KARTU SESI**
mencetak penunjuk buku; kalimat gabungan & sinonim ("dengan baik" = "dengan benar") masuk AL-3/AL-13 + tabel C3;
rujukan berkas pensiun dibetulkan. Jadi: kalau Lee menulis kalimat pendek, **cari di buku (Bagian C3/B/E)** —
jangan mengarang langkah. Sesi yang sengaja ditinggalkan Lee tetap `arena/01a0b4c3-resto-barokah`.

**Putaran 15 (2026-09-18):** permintaan Lee — berkas prompt pindah sesi dijadikan
**STATIS** (`PROMPT_SESI_BARU.md`, satu baris `SESI YANG AKU LANJUT:` diisi Lee) dan sesi yang **sengaja
ditinggalkan** dicatat di `docs/ops/SESI_DITINGGALKAN.md` (mesin menolak handoff ke arah sana).
`docs/ops/SIAP-TEMPEL-SESI-BARU.md` dipensiunkan menjadi penunjuk. Jadi: **untuk pindah sesi, Lee cukup
menyalin `PROMPT_SESI_BARU.md` — tidak perlu minta apa pun ke agent.**

Keadaan keputusan Lee (2026-09-18, sesi ditutup karena berat): arah berikutnya **belum dipilih**.
Urutan yang disarankan agent, dan alasannya:

1. **Putaran verifikasi (disarankan lebih dulu, kecil).** Commit yang ditunjuk paket peninjau
   TIDAK diklaim tangan di sini — bacalah baris **"Paket peninjau terbaru"** di §2 (ditulis mesin
   dari berkas paketnya sendiri). Sebelum dua peninjau mulai bekerja, segarkan paket ke commit
   terkini: `python3 alat/audit-independen.py --paket AUD-3 --semua` dan
   `python3 alat/review-pr.py --siapkan --pr 1 --nama pr-01-putaranNN` (pakai NN berikutnya —
   jangan menimpa nama lama, laporan peninjau pernah tertimpa karena ini). Lee tinggal menyalin
   **satu berkas `-SIAP-TEMPEL` per chat baru** (dua chat). Setelah laporan masuk:
   bantah-balik setiap temuan dengan probe sendiri (aturan tetap), tutup yang nyata, catat yang palsu.
   Bukti dari laporan putaran sebelumnya: dua putaran berturut-turut menemukan cacat nyata, dan dua
   cacat terakhir justru tertangkap CI — jadi verifikasi ini bukan formalitas.
2. **Lanjut kerja T1-24** (perangkat terdaftar + `perangkat_sah()` + RLS staf diperketat) — menutup
   akar beberapa kelemahan (batas PIN per perangkat masih memakai nama perangkat kiriman klien).
   **PENTING (temuan baru):** ROADMAP T1-24 menyebut "Migrasi 0012", padahal 0012 **sudah terpakai**
   (penutup celah review) dan migrasi sudah mencapai `0014`. T1-24..T1-28 wajib memakai nomor
   berikutnya (0015 dst.) — perbarui ROADMAP + catat di `DECISIONS_LOG.md` saat dikerjakan.
**MARATON G3 BATCH FASE 1B, 1C & FASE 2 SELESAI LENGKAP 100% (2026-09-22):**
1. **Fase 1B & 1C Selesai Penuh:** Seluruh migrasi keamanan (`0011`–`0031`), 72 pengujian SQL PGlite (100% lulus), fondasi tema, i18n 4 bahasa, tata letak, registri aksi, dan kontrak antarmuka telah diverifikasi solid.
2. **Fase 2 (Masuk & Kerangka Aplikasi) Selesai Penuh:**
   - T2-01: Supabase Auth & Sesi Aman di klien
   - T2-02: Layar Masuk Pegawai (Email + PIN Keypad)
   - T2-03: Kelola Pegawai & Atur Ulang PIN oleh Admin (`KelolaPegawai.tsx` + uji unit)
   - T2-04: Masuk Pelanggan: Google One-Tap & Tautan Email (`LayarMasukPelanggan.tsx` + uji unit)
   - T2-05: Pemulihan Akses Pelanggan (`LupaAkses.tsx` + uji unit)
   - T2-06: Kerangka Layout & Navigasi 6 Peran (`Rangka.tsx`, `Navigasi.tsx` + uji unit)
   - T2-07: Pemilih Cabang & Konteks Cabang Aktif (`PemilihCabang.tsx` + uji unit)
   - T2-08: Halaman Tidak Punya Akses & Pesan Ramah Berkode (`TidakPunyaAkses.tsx` + uji unit)
   - T2-09 & T2-16: Sesi Berakhir Otomatis & Kunci Instan (`useKunciOtomatis.ts`, `KunciSekarang.tsx` + uji unit)
   - T2-10: Pembatasan Percobaan Masuk Server-Side (Migrasi 0028 & SQL test)
   - T2-11: PWA Dasar (Manifest Webmanifest + Ikon + Service Worker `sw.js`)
   - T2-12 & T2-19: Uji Menyeluruh Hak Akses & Navigasi 6 Peran (`SkenarioMasukPeran.test.tsx` 8 tes lulus)
   - T2-13 & T2-18: Masuk Pengelola Sandi + TOTP 2FA (`MasukPengelola.tsx` + uji unit)
   - T2-14: Layar Masuk Staf Perangkat Terdaftar (`MasukStaf.tsx` + uji unit)
   - T2-15: Pendaftaran Perangkat Baru & Persetujuan Pegawai (`Perangkat.tsx` + uji unit)
   - T2-17: Daftar Perangkat & Pencabutan Sesi Hilang (`DaftarPerangkat.tsx` + uji unit)
3. **Rencana Selanjutnya:** Melanjutkan ke Fase 3 (Pesanan & Kasir - M4):
   - T3-01: Layar Kasir: katalog nyata dari database (kategori, varian, tambahan)
   - T3-02: Keranjang belanja: tambah/kurang/catatan khusus per item
   - T3-03: Simpan pesanan draf / meja terbuka
   - T3-04: Pembayaran kasir (Tunai, QRIS, Kartu, Split Bill)
   - T3-05: Cetak struk kasir & kirim nota elektronik (PDF/WhatsApp)

**MARATON G3 BATCH FASE 1B, 1C, FASE 2, & FASE 3 POS KASIR SELESAI LENGKAP (2026-09-22):**
1. **Fase 1B & 1C Selesai Penuh:** Seluruh migrasi keamanan (`0011`–`0031`), 72 pengujian SQL PGlite (100% lulus), fondasi tema, i18n 4 bahasa, tata letak, registri aksi, dan kontrak antarmuka telah diverifikasi solid.
2. **Fase 2 (Masuk & Kerangka Aplikasi) Selesai Penuh:** Seluruh 19 tugas (T2-01 s/d T2-19) terverifikasi lengkap.
3. **Fase 3 (Pesanan & Kasir - M4) Selesai Penuh:**
   - T3-01 & T3-07: Katalog menu dinamis, pencarian instan, filter kategori, penandaan & penguncian menu habis (`Katalog.tsx` + uji unit)
   - T3-02: Keranjang belanja server-calculated, subtotal, diskon, service, PB1, dan catatan per item (`Keranjang.tsx` + uji unit)
   - T3-03 & T3-06: Pemilih meja (dine-in/takeaway/ojol), denah meja, dan alur pindah meja (`PemilihMeja.tsx` + uji unit)
   - T3-04: Tagihan terbuka (open bill) aktif & pembuatan tagihan baru (`TagihanTerbuka.tsx` + uji unit)
   - T3-05, T3-08, T3-10, T3-13, T3-15: Terminal kasir POS terpadu, modal pembayaran multi-metode (tunai dengan pecahan cepat & kembalian akurat, QRIS, kartu EDC), diskon voucher, kirim dapur, dan keadaan memuat/gagal (`LayarKasir.tsx` + uji unit)
   - T3-11: Layar pesanan pelayan mobile HP di samping meja (`LayarPelayan.tsx` + uji unit)
   - T3-12: Riwayat pesanan hari ini dengan filter status/tipe/meja (`DaftarPesanan.tsx` + uji unit)
   - T3-14 & T3-16: Uji alur kasir ujung-ke-ujung (E2E) dan uji beban ringan (<10ms per kalkulasi 50 item) (`AlurKasirE2E.test.tsx`, `BebanKasir.test.ts`)
4. **Rencana Selanjutnya:** Melanjutkan ke Fase 4 (Dapur / Kitchen Display System - KDS & Stok Dasar: M5, M9):
   - T4-01: Layar dapur (makanan) dengan urutan FIFO (`aplikasi/src/layar/dapur/LayarDapur.tsx`)
   - T4-02: Layar bar/minuman terpisah (stasiun minuman)
   - T4-03: Status item pesanan (dimasak → siap saji → diantar)
   - T4-04: Penanda waktu & peringatan pesanan lama (> 15 menit)
   - T4-05: Suara notifikasi pesanan masuk & siap saji
   - T4-06 s/d T4-10: Void/batal dapur berizin supervisor, opname stok harian sederhana, dan realtime sync

**PERBAIKAN TAMPILAN, POS 2-KOLOM, DAN PARITAS BAHASA SELESAI LENGKAP (2026-09-24):**
1. **Penyelarasan Kamus Multi-Bahasa:** 100% sinkronisasi 171 kunci di seluruh 4 bahasa (`id.ts`, `en.ts`, `zh.ts`, `ar.ts`).
2. **Design Tokens & Komponen CSS:** Penambahan variabel token di `dasar.css` dan layout kelas POS modern (`.pos-wadah`, `.pos-kiri`, `.pos-kanan`, `.katalog-wadah`, `.kategori-pills`, `.kisi-menu-grid`, `.kartu-menu`, `.keranjang-kotak`, `.pemilih-meja`, `.tipe-pesanan-grid`, `.meja-grid`, `.meja-kartu`, `.buka-kas-wadah`, `.tutup-kas-wadah`, `.kotak-rincian-kas`).
3. **Penyempurnaan Komponen UI:**
   - `LayarKasir.tsx`: Tata letak 2 kolom desktop (katalog di kiri, keranjang belanja sticky di kanan).
   - `Katalog.tsx`: Kategori pills filter, pencarian cepat, kartu menu ber-elevasi bersih, tag favorit & habis.
   - `Keranjang.tsx`: Ringkasan tagihan server-calculated, kontrol kuantitas, catatan dapur per item, tombol voucher.
   - `PemilihMeja.tsx`: Pilihan segmented Dine In/Takeaway/Ojol, denah kartu meja dengan lencana status & kapasitas tamu.
   - `BukaKas.tsx` & `TutupKas.tsx`: Formulir modal terstruktur dengan kalkulasi selisih kas dan alasan otomatis.
   - `Navigasi.tsx` & `LayarContoh.tsx`: Terjemahan 100% terhubung via i18n hook.
4. **Verifikasi Kualitas:**
   - 76 berkas uji Vitest (596 tes lulus 100%).
   - 73/73 mutasi aplikasi terbunuh (100% mutation score).
   - 89 berkas uji SQL PGlite lulus (100%).
   - `python3 aplikasi/alat/periksa-struktur.py` (29 OK, 0 GAGAL).
   - `python3 aplikasi/alat/periksa-bahasa.py` (100% paritas).
   - Build produksi Vite bersih 0 eror.
