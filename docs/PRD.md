# PRD — Resto Barokah

> **Status dokumen: DISETUJUI** — ditulis 2026-09-16 dan **dikunci atas persetujuan pemilik pada 2026-09-16**
> (pemilik: *"Mari lanjut"* setelah pemeriksaan). Lanjutan: **sesi Desain & UI**, lalu **Tahap 3 (Tech Spec)**.
> Dokumen tetap **dokumen hidup** — perubahan wajib dicatat di **Log Pembaruan Dokumen (bagian 11)**.
>
> Dokumen ini menerjemahkan `docs/DISCOVERY.md` (yang sudah disetujui) menjadi: **apa yang dibangun
> lebih dulu (MVP), bagaimana aturannya, dan bagaimana kami tahu fitur itu sudah benar-benar selesai.**
> Aturan prioritas dipakai **MoSCoW** (Must / Should / Could / Won't).
> Bahasa sengaja dibuat dapat dibaca pemilik non-teknis; istilah teknis dijelaskan saat muncul.

---

## 1. Ringkasan Produk

**Resto Barokah** (nama sementara) adalah platform kasir & operasional untuk usaha makanan-minuman
(warkop, kedai, cafe, warung, rumah makan) yang **dipakai bersama oleh banyak usaha** — setiap usaha
memiliki **merek, pengaturan, pegawai, dan datanya sendiri**; pemilik platform (kamu) tetap memegang
kendali tertinggi atas seluruh penyewa.

Aplikasi berjalan di **browser** (bisa dibuka dari HP, tablet, maupun laptop) sehingga tidak perlu
dipasang dari toko aplikasi.

**Pilot pertama:** **Kedai Oasis** (cafe milik teman pemilik), dipinjamkan gratis. Kondisi pilot:
ada printer struk dan internet lancar. Alur pesanan di Kedai Oasis **campur** — sebagian pelanggan
memesan di kasir, sebagian lagi dilayani pelayan ke meja.

**Prinsip yang mengikat seluruh proyek:**
1. **Biaya nol** selama belum menghasilkan (tanpa payment gateway, tanpa WhatsApp API, tanpa SMS, tanpa toko aplikasi, tanpa domain berbayar).
2. **Tidak ada yang cacat** — fitur baru hanya dianggap selesai setelah diuji; tidak ada fitur "setengah jalan" yang ditampilkan ke pengguna.
3. **Semua bisa diatur tanpa koding** — pemilik resto mengatur menu, tampilan, pajak, meja, pegawai, dan promosi sendiri, tanpa menyentuh kode.

---

## 2. Target Pengguna

| Pengguna | Peran dalam sistem | Kebutuhan utama | Ketakutannya |
|---|---|---|---|
| **Pemilik Platform** (kamu) | Hak tertinggi atas semua penyewa | Mendaftarkan/mengaktifkan resto baru, memastikan semua penyewa berjalan lancar | Platform rusak di depan calon penyewa; biaya muncul tiba-tiba |
| **Owner / Admin Pusat** (pemilik resto) | Hak tertinggi atas seluruh cabang restonya | Tahu pemasukan hari ini sekilas; laporan tutup kasir yang cocok; merasa aman dari kecurangan staf; atur sendiri tanpa orang teknis | Rugi diam-diam; ribet; staf curang |
| **Admin Cabang** | Mengelola satu cabang | Laporan cabangnya, opname stok, atur printer, ajukan permintaan ke pusat | Dituduh salah; tidak punya kewenangan menyelesaikan masalah mendadak |
| **Kasir** | Transaksi & kas shift | Cepat saat antre, tidak pernah selisih kas, jelas apa yang boleh/tidak | Selisih kas dianggap mencuri |
| **Pelayan** | Pesanan & meja | Catat pesanan cepat di samping meja, tahu status meja, pesanan tidak salah antar | Salah catat; pesanan tamu terlupakan |
| **Dapur / Bar** | Layar dapur | Urutan pesanan jelas, instruksi khusus terlihat, bisa tandai menu habis | Salah masak; pesanan menumpuk tanpa terlihat |
| **Pelanggan & Calon Pelanggan** | Melihat katalog, memakai voucher | Lihat menu dari HP tanpa pasang aplikasi, tukar voucher tanpa ribet | Antre lama; voucher tidak bisa dipakai |

---

## 3. Tujuan & Metrik Sukses

### Tujuan versi pertama (MVP)
Membuat Kedai Oasis **berhenti mencatat di kertas** dan menjalankan operasional harian lewat aplikasi,
lalu menjadikannya bukti nyata bahwa platform ini layak ditawarkan ke resto lain.

### Metrik sukses (dikunci bersama pemilik)
| # | Metrik | Target |
|---|---|---|
| 1 | **Pemakaian harian di Kedai Oasis** | **Pakai setiap hari operasional selama 1 bulan penuh, tanpa kembali ke kertas** |
| 2 | Tutup kasir | Waktu tutup kas + laporan harian **di bawah 5 menit** |
| 3 | Selisih kas tanpa alasan | **Nol** kejadian (setiap selisih wajib ada alasan tercatat) |
| 4 | Pembatalan setelah dapur mulai | Terpantau di laporan sebagai kerugian; **tidak ada pembatalan yang tidak terlihat** |
| 5 | Voucher undang-teman | Ada pelanggan baru yang mendaftar lewat tautan dan menukar voucher **di kedai** |
| 6 | Kesiapan ditawarkan | Kedai Oasis bersedia menjadi rujukan/rekomendasi bagi resto lain |

### Metrik penunjang (dipantau, bukan target keras)
Jumlah transaksi/hari melewati sistem · waktu kasir menyelesaikan satu transaksi · jumlah menu habis yang ditandai
dari dapur · jumlah penyewa baru dalam 6 bulan setelah pilot.

---

## 4. Fitur MVP (Must Have)

Setiap fitur dituliskan sebagai **cerita pengguna** (siapa, ingin apa, supaya apa) + **kriteria selesai** (apa yang
harus terbukti) + **kasus tepi** (hal-hal yang biasanya bikin aplikasi gagal di lapangan).

### M1. Pendaftaran & pengelolaan penyewa (resto)
- **Cerita:** Sebagai **Pemilik Platform**, saya ingin mendaftarkan resto baru beserta cabang pertamanya dan mengaktifkannya, supaya resto bisa langsung mulai memakai sistem dengan pengaturannya sendiri.
- **Kriteria selesai:**
  - Saya bisa membuat penyewa baru: nama resto, kontak, cabang pertama (nama & alamat), dan akun Owner-nya.
  - Data setiap penyewa **terpisah total** — saya bisa membuktikan data Resto A tidak terlihat sama sekali oleh Resto B (diuji dengan dua akun berbeda).
  - Saya bisa menonaktifkan penyewa bila perlu; datanya tetap tersimpan (tidak dihapus diam-diam).
- **Kasus tepi:** nama resto sama (boleh) · satu orang memiliki dua resto (boleh, dengan akun berbeda) · penghapusan/penonaktifan tidak menghapus data transaksi.

### M2. Pengaturan tanpa koding (per penyewa)
- **Cerita:** Sebagai **Owner/Admin Pusat**, saya ingin mengatur identitas, tampilan, menu, meja, pajak, dan metode pembayaran sendiri, supaya saya tidak perlu menghubungi siapa pun saat ada perubahan.
- **Kriteria selesai (bisa diatur sendiri):**
  - Identitas & tampilan: nama resto, logo, warna utama, banner, gambar latar halaman pelanggan, tagline.
  - Operasional: jam buka, **pajak PB1 (%)**, **service charge (%)**, aturan pembulatan, nomor & area meja, **cara pesan** (dilayani ke meja / ambil di kasir / dua-duanya), header & footer struk.
  - Menu: kategori, item, varian (panas/es, ukuran), tambahan/topping, foto, harga, urutan tampil, item unggulan, penanda habis (manual).
  - Pembayaran: metode aktif (tunai, QRIS, transfer, e-wallet, kartu) dan aturan tip.
- **Kasus tepi:** pajak 0% (harga apa adanya) · service charge 0% · perubahan nama/warna **tidak boleh mengubah struk & laporan lama** · harga diubah saat ada tagihan terbuka (tagihan lama tetap memakai harga saat pesanan dibuat).

### M3. Peran, hak akses berjenjang, & jejak audit
- **Cerita:** Sebagai **Owner**, saya ingin menentukan izin tiap pegawai dan melihat catatan siapa melakukan apa, supaya saya bisa memberi kepercayaan tanpa kehilangan kendali.
- **Kriteria selesai:**
  - **6 peran tersedia:** Pemilik Platform · Owner/Admin Pusat · Admin Cabang · Kasir · Pelayan · Dapur/Bar.
  - Owner dapat **mencawang (mencentang) izin** per pegawai/peran: ubah harga · beri diskon (dengan **batas maksimal %/nominal**) · batalkan pesanan sebelum dapur mulai · batalkan setelah dapur mulai · lihat laporan keuangan · kelola pegawai · atur pengaturan · pakai voucher.
  - **Tindakan di luar izin** tidak bisa dilakukan; untuk membatalkan setelah dapur mulai & diskon di atas batas → **wajib PIN atasan/owner** (alur permintaan izin jarak jauh = fase 2).
  - **Jejak audit** mencatat: waktu, pelaku, tindakan, nilai/nominal, alasan (bila ada) — untuk void, diskon manual, ubah harga, buka laci tanpa transaksi, pakai voucher, dan perubahan pengaturan penting.
  - Admin Cabang hanya melihat data cabangnya; Owner melihat seluruh cabang.
- **Kasus tepi:** pegawai pindah cabang (izin disesuaikan) · pegawai berhenti (akun dinonaktifkan, riwayat tetap tersimpan) · PIN salah berkali-kali (dibatasi supaya tidak bisa ditebak) · owner sendiri juga boleh dicentang/dibatasi oleh Pemilik Platform bila perlu.

### M4. Pesanan dari kasir & pelayan
- **Cerita:** Sebagai **Kasir/Pelayan**, saya ingin mencatat pesanan dengan cepat (meja / bawa pulang / ojol) beserta catatan khusus dan menyimpannya sementara, supaya pesanan akurat dan pelanggan tidak menunggu lama.
- **Kriteria selesai:**
  - Pilih meja atau jenis pesanan (dine-in / takeaway / ojol).
  - Tambah **catatan khusus** per item (tanpa es, kurang pedas, tanpa jeroan).
  - **Simpan tagihan (open bill)**: pesanan bisa ditambah beberapa kali sebelum dibayar.
  - Kirim pesanan → otomatis muncul di **layar dapur** dan **tiket dapur tercetak** (bila printer aktif).
  - Pelayan bisa mencatat pesanan langsung dari HP di samping meja pelanggan.
  - Meja bisa dipindah; layar menampilkan status meja (kosong / terisi / siap disajikan).
- **Kasus tepi:** dua pelayan membuka meja yang sama (peringatan "meja sudah terisi") · pelanggan pindah meja · pesanan ditambah setelah dikirim · internet terputus saat menekan kirim (pesan gagal harus terlihat jelas, bukan diam-diam hilang) · item yang sudah habis tidak bisa dipesan (terkunci otomatis).

### M5. Layar dapur & tiket dapur (KDS)
- **Cerita:** Sebagai **Dapur/Bar**, saya ingin melihat antrean pesanan dengan urutan yang benar dan instruksi khusus yang mencolok, supaya tidak ada hidangan yang salah atau terlupakan.
- **Kriteria selesai:**
  - Pesanan makanan → tampil di dapur; minuman → tampil di bar (pemisahan otomatis).
  - Urutan **FIFO** (pesanan paling lama di atas).
  - Tanda jenis pesanan (dine-in/takeaway/ojol) terlihat jelas.
  - Instruksi khusus ditampilkan mencolok.
  - Ubah status: **sedang dimasak → siap diantar** (per item maupun seluruh pesanan).
  - Tombol **menu habis** dari layar dapur → langsung mengunci menu di kasir **dan** di katalog pelanggan.
- **Kasus tepi:** pesanan sudah dikirim lalu dibatalkan pelanggan (aturan void berlaku) · printer tiket macet/offline (layar dapur tetap jalan sebagai cadangan — pesanan tidak boleh hilang) · dua dapur menandai selesai pada item yang sama (tidak boleh dobel).

### M6. Pembayaran, struk, & pembatalan
- **Cerita:** Sebagai **Kasir**, saya ingin menerima pembayaran dengan berbagai cara dan mencetak struk yang benar, supaya pelanggan selesai cepat dan uang tercatat akurat.
- **Kriteria selesai:**
  - Metode tercatat: tunai (dengan hitung kembalian), QRIS, transfer, e-wallet, kartu — **pencatatan, bukan integrasi otomatis**.
  - Pajak PB1 & service charge dihitung otomatis sesuai pengaturan resto; **terlihat terpisah di struk**.
  - Diskon: **bawaan satu diskon per transaksi**; pengaturan bisa mengizinkan tumpuk dengan **batas maksimal total**.
  - Struk cetak memuat: nama resto, alamat, tanggal/jam, nomor transaksi, daftar item, subtotal, pajak, service, diskon, total, metode bayar, nama kasir, ucapan terima kasih (header/footer bisa diatur).
  - Nomor HP pelanggan **opsional** (ditawarkan bila pelanggan mau poin/voucher).
  - **Aturan pembatalan bertingkat SEBELUM pembayaran pertama** (dikunci pemilik):
    - Dapur **belum** mulai → kasir boleh membatalkan, **wajib pilih alasan** (pelanggan batal / salah input), tercatat di laporan.
    - Dapur **sudah** menandai sedang dimasak → **wajib PIN atasan/owner** + alasan wajib → dicatat sebagai **bahan terbuang/kerugian** dengan nilai rupiahnya dan muncul di laporan harian.
    - **Sesudah pembayaran pertama, termasuk sebagian: isi/nominal, diskon, dan void dikunci** (T-025(a), keputusan Lee 2026-09-21). PIN atasan tidak melewati larangan ini. Refund resmi tetap fase 2, bukan pembatalan terselubung di MVP.
- **Kasus tepi:** pembayaran sebagian (split bill = fase 2; di MVP dicatat sebagai dua transaksi terpisah) · printer mati (struk bisa dicetak ulang, transaksi tidak boleh hilang) · pembulatan (aturan di pengaturan) · tagihan terbuka ditinggal pelanggan (ditandai & tetap muncul di daftar).

### M7. Kas & shift (buka/tutup kasir)
- **Cerita:** Sebagai **Kasir**, saya ingin membuka dan menutup kas dengan jelas, supaya saya tidak pernah dituduh selisih.
- **Kriteria selesai:**
  - Buka kas: masukkan **modal awal**.
  - Tutup kas: sistem menghitung uang **seharusnya** (modal + penerimaan tunai − pengeluaran tunai) lalu kasir memasukkan **hasil hitung fisik**.
  - Bila ada selisih → **wajib mengisi alasan**; nilainya tercatat di laporan untuk owner.
  - Transaksi hanya bisa dilakukan dalam shift yang sudah dibuka.
- **Kasus tepi:** dua kasir dalam satu shift (satu kas, dicatat siapa yang membuka/menutup) · shift tidak ditutup sampai besok (sistem mengingatkan) · kasir lupa modal awal (bisa dikoreksi dengan izin atasan, tercatat).

### M8. Laporan harian per shift
- **Cerita:** Sebagai **Owner**, saya ingin membuka satu layar dan langsung tahu kondisi hari ini, supaya saya bisa memutuskan tanpa menghitung manual.
- **Kriteria selesai laporan berisi:** omzet (makanan/minuman/lainnya) · jumlah transaksi · rincian metode bayar · menu terlaris · diskon & voucher terpakai · **daftar pembatalan** (siapa, nilai, alasan) · kas awal, uang masuk, seharusnya, hasil hitung, **selisih** · nama kasir & jam shift · bisa dilihat per cabang sesuai peran.
- **Kasus tepi:** transaksi lewat tengah malam (masuk tanggal transaksi, bukan tanggal tutup kas) · koreksi setelah shift ditutup (dicatat sebagai koreksi, tidak menghapus data lama) · laporan dicetak/disimpan (cetak = fase 2; di MVP tampil di layar).

### M9. Stok dasar
- **Cerita:** Sebagai **Kasir/Dapur**, saya ingin menandai menu yang habis dan mencatat stok sederhana, supaya pelanggan tidak memesan yang sudah habis dan owner tahu persediaan.
- **Kriteria selesai:** tombol menu habis (kasir & dapur) mengunci menu di kasir + katalog · pencatatan stok sederhana per bahan · opname berkala (isi jumlah nyata, sistem menunjukkan selisih) · riwayat perubahan stok.
- **Kasus tepi:** menu habis lalu tersedia lagi (dibuka manual) · stok dikoreksi (tercatat siapa & kapan) · bahan tanpa catatan stok tetap boleh (opsional per bahan).
- **Catatan:** resep otomatis (stok berkurang sendiri tiap penjualan) = **fase 2**, sesuai kesepakatan.

### M10. Katalog pelanggan & voucher undang-teman
- **Cerita (katalog):** Sebagai **Calon Pelanggan**, saya ingin melihat menu lewat tautan di HP, supaya saya tahu apa yang dijual sebelum datang.
- **Kriteria selesai (katalog):** halaman publik per resto (nama, logo, warna, banner) · daftar menu berkategori + foto + harga · jam buka & lokasi/kontak · menu habis **otomatis tidak tampil/tertutup** · tampil rapi di HP.
- **Cerita (voucher):** Sebagai **Calon Pelanggan**, saya ingin menerima undangan, mendaftar, lalu mendapat barcode diskon, supaya saya punya alasan datang ke kedai.
- **Kriteria selesai (voucher):**
  - **Alur:** tautan kampanye → halaman pendaftaran → isi nama, alamat (opsional), nomor HP/email → verifikasi (**utamanya "Daftar dengan Google"**; jalur kedua email terverifikasi) → **barcode/kode voucher** muncul → pergi ke kedai → kasir **Cek** lalu **Pakai**.
  - **Tanpa PIN pelanggan** (T-023, keputusan Lee 2026-09-21). Identitas pelanggan memakai Google Sign-In (utama) atau email terverifikasi (kedua); penghapusan ini **tidak** menghapus PIN pegawai/persetujuan saat kasir memakai voucher. Kanal email tetap gerbang T-022/T2-04 sebelum jalur email dibuka.
  - **Aturan voucher diatur admin:** persen/nominal, minimum belanja, **batas maksimal potongan**, masa berlaku, kuota per kampanye, **anggaran kampanye**, per cabang/berlaku di mana.
  - **Cek Voucher (baca saja)** tidak mengubah status; **Pakai Voucher** sekali pakai + **wajib PIN** kasir/atasan dan tercatat.
  - Kasir bisa **scan lewat kamera** atau **mengetik kode manual**.
  - Balasan jelas ke kasir: berhasil (dengan rincian potongan) / gagal (dengan sebab: sudah dipakai, kedaluwarsa, minimum belanja belum terpenuhi, tidak berlaku di cabang ini).
- **Pengaman anti-kecurangan (10):** satu voucher per identitas per kampanye · batas voucher per outlet per hari · wajib belanja minimum + batas maksimal potongan + anggaran kampanye · sekali pakai · kode acak tidak berurutan · log semua percobaan cek/scan · batas percobaan per perangkat · tolak email sekali-pakai · normalisasi alamat Gmail (titik & tanda +) · laporan anomali klaim (fase 2).
- **Kasus tepi:** voucher sudah kedaluwarsa (pesan jelas ke kasir, bukan error) · pelanggan tidak punya email & tidak mau Google (bisa didaftarkan kasir atas izin pelanggan — dicatat siapa yang mendaftarkan) · internet di kedai mati saat memakai voucher (dicatat manual lalu dimasukkan setelah online — **tidak menggandakan** pemakaian).

### M11. Multi-cabang (dasar)
- **Cerita:** Sebagai **Owner**, saya ingin menyiapkan cabang kedua kapan saja tanpa mengubah sistem, supaya pertumbuhan tidak terhambat.
- **Kriteria selesai:** tambah cabang · tiap cabang punya nama/alamat & printer sendiri · laporan per cabang + gabungan untuk owner · admin cabang hanya melihat cabangnya · **harga & menu boleh berbeda per cabang** (diatur, tidak wajib).
- **Kasus tepi:** pegawai merangkap dua cabang (izin per cabang) · cabang ditutup sementara (dinonaktifkan, data lama tetap ada).

### M12. Keamanan fondasi (lintas fitur) — **diperdalam 2026-09-17**
> **Rujukan resmi: `docs/KEAMANAN.md`.** Bagian ini adalah janji ke pemilik; aturan teknisnya ada di sana.
- **Cerita:** Sebagai **Pemilik semua pihak**, saya ingin yakin data & uang aman dari kesalahan maupun kecurangan — termasuk bila perangkat hilang atau pegawai berhenti — supaya platform layak dipercaya.
- **Kriteria selesai:**
  - Data terisolasi antar-penyewa dan antar-cabang; diuji **otomatis untuk setiap peran × tabel × tindakan**, bukan sekadar dua akun contoh.
  - **Satu akun = satu peran.** Satu orang dengan dua fungsi punya **dua akun** (PIN berbeda); izin (centang) tetap boleh berbeda per pegawai.
  - **Bagian staf hanya bisa dibuka dari perangkat terdaftar**: perangkat didaftarkan admin/owner lewat kode sekali pakai, dan pegawai baru yang pertama memakai perangkat itu **harus disetujui pemilik**. Perangkat menyimpan identitas rahasianya; "Tablet Kasir" tidak bisa dipakai masuk sebagai owner.
  - **Masuk cepat:** kasir/pelayan/dapur = pilih nama + **PIN 6 digit** (hanya sah di perangkat terdaftar). Admin/owner/pemilik platform = kata sandi ≥12 karakter + **kunci kedua (TOTP/authenticator)** yang **wajib**.
  - **Perangkat hilang/dicuri:** owner menekan "Cabut perangkat" → akses mati **seketika** (bukan menunggu kedaluwarsa); bisa menandai "hilang", mengakhiri sesi, dan melihat perangkat terakhir aktif.
  - **Sesi:** token pendek (15 menit), umur maksimum sesi (staf 12 jam · admin/owner 30 hari · pemilik platform 8 jam), **kunci otomatis saat menganggur** (15–60 menit sesuai peran) + tombol "Kunci sekarang"; percobaan masuk dibatasi (5×/15 menit per akun, 12×/15 menit per perangkat) dan semuanya tercatat.
  - **PIN:** unik antar pegawai, dilarang pola lemah, disimpan ter-hash, tidak pernah ditulis di log, dipakai juga untuk menyetujui tindakan sensitif (void setelah dapur, diskon di atas batas, pakai voucher).
  - **Jejak audit tidak bisa diakali:** hanya-tambah **dan** berantai hash — perubahan/penghapusan langsung di database bisa dideteksi dan ditunjuk barisnya.
  - **Ringkasan peringatan harian ke owner** (1 email/hari): omzet, void, diskon, selisih kas, percobaan masuk gagal, perubahan perangkat.
  - **Privasi pelanggan (UU PDP):** persetujuan eksplisit, data seminimal mungkin, hak akses/hapus (anonimisasi tanpa menghapus catatan keuangan), dan pemberitahuan kebocoran ≤3×24 jam.
  - **Pemilik platform tidak melihat isi data penyewa** kecuali lewat "mode dukungan" (beralasan, berbatas waktu, hanya-baca, tercatat, owner penyewa diberitahu).
  - **Tidak ada data keuangan yang bisa dihapus permanen**; koreksi selalu pencatatan baru.
- **Kasus tepi:** PIN dilihat/dibagikan orang lain (PIN unik + batas percobaan + laporan "siapa menyetujui apa") · perangkat hilang (cabut + ganti PIN) · pegawai berhenti (nonaktif = sesi & perangkat dicabut seketika) · HP admin hilang (MFA direset atasan dengan langkah terdokumentasi) · internet kedai mati saat perangkat terkunci (prosedur catat manual sementara di Buku Insiden) · percobaan masuk berulang (dibatasi + dicatat) · pegawai pindah cabang (daftar cabang akun diubah, tercatat).

---

## 5. Fitur Fase 2 & Fase 3

### Fase 2 (Should Have) — setelah pilot terbukti dan metrik sukses tercapai
QR pesan sendiri (pelanggan pesan dari HP) · split bill & gabung meja · poin loyalitas & keanggotaan digital · notifikasi meja kotor → bersih (staf kebersihan) · pelanggan melacak status pesanan · struk digital via email · ekspor laporan ke Excel/CSV · promosi terjadwal + segmentasi pelanggan · reservasi meja & daftar tunggu (notifikasi di aplikasi) · **resep sederhana** (stok berkurang otomatis) · tombol "pasang ke layar HP" · **alur permintaan izin jarak jauh** (pegawai minta → owner setuju dari jauh) · refund resmi · laporan anomali voucher · cetak laporan.

### Fase 3 (Could Have) — setelah ada pemasukan
Mode offline · integrasi pembayaran otomatis (QRIS dinamis/e-wallet) · integrasi resmi ojol · tingkatan loyalitas (tier) · analitik lanjutan + ukur hasil kampanye · stok lanjutan (konversi satuan, susut, kedaluwarsa, transfer antar cabang, penerimaan barang/PO) · laba-rugi sederhana + pencatatan pengeluaran · penagihan langganan penyewa · HR ringan (absensi sederhana, jadwal shift, rekap gaji) · menu engineering/HPP · pengantaran internal (catat kurir + setoran) · pesan-antar sendiri + bayar di meja.

---

## 6. Non-Goals (sengaja TIDAK dibangun)

| Tidak dibangun | Alasan |
|---|---|
| Pembukuan lengkap (jurnal, buku besar, neraca, arus kas, PPh, faktur pajak, penyusutan aset) | Itu perangkat akuntan/ERP; jembatannya adalah **ekspor Excel** untuk akuntan |
| Penggajian otomatis penuh, kasbon, slip gaji | Butuh aturan pajak/BPJS — risiko salah hitung tinggi |
| Absensi pengenalan wajah & pelacakan lokasi (GPS) | Data pribadi sensitif (UU PDP), tidak sebanding manfaat |
| Pelacakan kurir langsung & navigasi peta | Butuh akun penagihan peta = berbiaya |
| Tiket perawatan alat, kalender servis, inventaris aset | Bukan pembeda bagi penyewa sasaran |
| WhatsApp API & SMS berbayar (struk/promo/notifikasi kirim) | Berbiaya per pesan — melanggar syarat biaya nol (email gratis dipakai sebagai ganti) |
| Aplikasi di Google Play / App Store | Berbiaya pendaftaran; browser + "pasang ke layar HP" sudah cukup |
| Format khusus export pajak/bank | Menunggu kebutuhan nyata dari penyewa |
| KPI pegawai, pelacakan kesalahan, manajemen cuti | Bukan kebutuhan penyewa sasaran |
| Pendaftaran penyewa mandiri (self-service) | 5–10 penyewa pertama didaftarkan manual supaya rapi |

---

## 7. Alur Pengguna Utama (bernomor)

**A. Penyiapan awal (sekali per resto)**
1. Pemilik Platform membuat penyewa baru (nama resto, kontak, cabang pertama, akun Owner).
2. Owner mengatur identitas & tampilan (nama, logo, warna, banner, tagline).
3. Owner mengatur pajak PB1, service charge, pembulatan, jam buka, metode pembayaran, header/footer struk.
4. Owner mengatur meja & area.
5. Owner mengatur menu (kategori, item, varian, tambahan, foto, harga, urutan).
6. Owner menambah pegawai + peran + PIN + centangan izin.
7. Owner membuat kampanye voucher (aturan potongan, minimum belanja, batas maksimal, masa berlaku, kuota).

**B. Operasional harian**
8. Kasir membuka kas (modal awal).
9. Pelanggan datang → pelayan/kasir mencatat pesanan (meja atau bawa pulang) → dikirim ke dapur.
10. Dapur melihat pesanan di layar/tiket → tandai "sedang dimasak" → setelah selesai tandai "siap" → pelayan mengantar.
11. Pesanan bisa ditambah (tagihan disimpan) sebelum dibayar.
12. Kasir memproses pembayaran → pajak/service/diskon dihitung otomatis → struk dicetak → nomor HP pelanggan diminta **bila pelanggan mau**.
13. Bila ada pembatalan: mengikuti aturan bertingkat (M6) dan tercatat.
14. Kasir menutup kas → mengisi hasil hitung fisik → selisih wajib beralasan.
15. Sistem menyusun **laporan harian per shift** yang bisa dilihat owner.

**C. Voucher undang-teman**
16. Owner/admin membagikan tautan kampanye (WhatsApp/status/media sosial).
17. Calon pelanggan membuka tautan → melihat katalog → mengisi data → verifikasi (Google/email) → menerima voucher; **tanpa PIN pelanggan**.
18. Muncul barcode/kode + imbauan datang ke kedai dengan potongan yang dijanjikan.
19. Pelanggan datang → kasir **Cek Voucher** (opsional, tidak menghanguskan) → **Pakai Voucher** (PIN + tercatat) → potongan masuk ke tagihan.
20. Pemakaian voucher tercatat; kuota & anggaran kampanye berkurang.

**D. Pengawasan**
21. Owner melihat laporan harian (per cabang / semua cabang) + jejak audit tindakan sensitif.
22. Pemilik Platform melihat daftar penyewa aktif (dashboard penyewa = fase 2; di MVP cukup daftar & status).

---

## 8. Aturan Bisnis (mengikat)

1. **Pajak & service charge** dapat diatur per penyewa (0% diperbolehkan); selalu **ditampilkan terpisah** di struk & laporan.
2. **Diskon**: bawaan **satu diskon per transaksi**; pengaturan dapat mengizinkan tumpuk dengan **batas maksimal total potongan**.
3. **Nomor HP pelanggan opsional** — hanya bila pelanggan mau poin/voucher.
4. **Kas per shift**: buka dengan modal awal; tutup dengan hitung fisik; **selisih wajib beralasan**.
5. **Menu habis** mengunci menu di kasir **dan** katalog pelanggan; pembukaan kembali dilakukan manual (kasir/dapur).
6. **Voucher**: sekali pakai · kode acak · minimum belanja · batas maksimal potongan · kuota & anggaran kampanye · satu voucher per identitas per kampanye · **Cek** tidak menghanguskan, **Pakai** butuh PIN.
7. **Pembatalan (void) bertingkat, hanya sebelum pembayaran pertama** (termasuk pembayaran sebagian; sesudahnya terkunci sesuai T-025(a)): sebelum dapur mulai = kasir boleh (wajib alasan, tercatat); setelah dapur mulai = **PIN atasan** + alasan + dicatat sebagai **kerugian/bahan terbuang** bernilai rupiah di laporan. Refund resmi = fase 2.
8. **Semua tindakan sensitif tercatat** (jejak audit): void, diskon manual, ubah harga, buka laci tanpa transaksi, pakai voucher, perubahan pengaturan penting.
9. **Isolasi data**: antar-penyewa dan antar-cabang; Admin Cabang hanya cabangnya; Owner hanya restonya; Pemilik Platform melihat daftar penyewa (bukan isi transaksi mereka, kecuali diizinkan/diperlukan untuk dukungan).
10. **Harga & laporan historis tidak berubah** bila harga/pengaturan diubah kemudian — transaksi lama tetap seperti saat terjadi.
11. **Tidak ada penghapusan permanen** data transaksi oleh pengguna; koreksi = pencatatan baru (koreksi) yang tercatat.
12. **Zona waktu & mata uang** per penyewa (bawaan: Waktu Indonesia Barat, Rupiah).
13. **Fitur baru hanya rilis setelah diuji**; fitur yang belum teruji tidak ditampilkan ke pengguna (prinsip "tidak ada yang cacat").
14. **Satu akun = satu peran.** Satu orang dengan dua fungsi memakai dua akun dengan PIN berbeda; izin (centang) boleh berbeda per pegawai.
15. **Bagian staf hanya bisa dibuka dari perangkat terdaftar**; pegawai baru yang pertama memakai perangkat harus disetujui pemilik. Perangkat hilang/dicuri → akses dicabut **seketika** (berlaku pada permintaan berikutnya) dan wajib dicatat.
16. **Kunci kedua (TOTP) wajib untuk Pemilik Platform, Owner Pusat, dan Admin Cabang**; kasir/pelayan/dapur sudah dua lapis (perangkat + PIN).
17. **Setiap tombol/aksi di aplikasi wajib terdaftar dan diuji** (Registri Aksi + pemeriksa otomatis); tidak ada tombol tanpa fungsi, tidak ada layar tanpa penanganan keadaan kosong/memuat/gagal/tanpa-akses.
18. **Data pelanggan diproses dengan persetujuan & minimalisasi** (UU PDP): data boleh dianonimkan atas permintaan, tetapi catatan keuangan tidak dihapus.

---

## 9. Ketergantungan & Risiko

| # | Ketergantungan/Risiko | Dampak bila terjadi | Mitigasi |
|---|---|---|---|
| 1 | **Cetak struk & tiket dapur dari aplikasi browser** (Bluetooth/USB/LAN) | Kasir & dapur tidak bisa mencetak — menghambat pilot | Uji cetak **lebih awal** di Kedai Oasis sebelum fitur lain dianggap selesai; sediakan mode "tampilkan & cetak ulang"; bila gagal, ada jalur alternatif yang disepakati |
| 2 | Batas layanan gratis (kapasitas, batas email, batas permintaan) | Sistem melambat atau berhenti di jam sibuk | Ukur pemakaian sejak awal; sampaikan batasnya terbuka ke pemilik; hindari fitur berat sebelum ada pemasukan |
| 3 | Email bawaan sistem hanya 2 email/jam (tidak layak produksi) | Pendaftaran pelanggan gagal | **Google Sign-In jalur utama**; email terverifikasi via penyedia gratis sebagai jalur kedua |
| 4 | Penyalahgunaan voucher (akun palsu) | Diskon bocor / kerugian | 10 lapis pengaman + wajib belanja minimum + batas potongan + anggaran kampanye |
| 5 | Printer/layar dapur bergantung jaringan kedai | Pesanan telat sampai ke dapur | Layar dapur sebagai cadangan tiket cetak; indikator koneksi jelas; rencana offline di fase 3 |
| 6 | Ruang lingkup besar (semua alur, semua bisa diatur) | Tidak ada yang selesai | Gelombang G1→G2→G3 + aturan "gelombang berikutnya tidak dimulai sebelum lulus uji" |
| 7 | Pengalaman pemilik nol coding | Salah paham saat pengujian | Semua laporan uji memakai bahasa sehari-hari + langkah satu-satu |
| 8 | Kebijakan/aturan data pelanggan (privasi) | Kehilangan kepercayaan penyewa | Sampaikan kebijakan data & persetujuan pelanggan di Tahap 3/4; data pelanggan seminimal mungkin |
| 9 | **Perangkat staf hilang/dicuri** (tablet kasir, HP admin) | Orang lain bisa memakai akun kasir; MFA admin tidak bisa dibuka | Perangkat terdaftar + PIN + kunci otomatis + **pencabutan seketika**; jalan pemulihan MFA (owner/pemilik platform) ada di `docs/teknis/BUKU_INSIDEN.md` |
| 10 | **Ketaatan UU PDP** (data pelanggan voucher) | Denda administratif s.d. 2% pendapatan tahunan + risiko pidana | Persetujuan eksplisit, minimalisasi, anonimisasi atas permintaan, pemberitahuan kebocoran ≤3×24 jam (template disiapkan) |
| 11 | **HP pegawai hilang = kerja terhenti** (karena TOTP wajib) | Admin cabang tidak bisa bekerja sampai MFA direset | Jalan pemulihan cepat & terdokumentasi (owner pusat / pemilik platform) + dicatat + dinotifikasi |

---

## 10. Pertanyaan Terbuka

1. **Nama produk platform** — belum diputuskan (kandidat: Langgan, Baraka, Sajian, Rame, Nota).
2. **Nilai pajak & service charge nyata di Kedai Oasis** — diisi saat penyiapan resto (aplikasi mendukung dua-duanya).
3. **Jumlah shift & jam operasional Kedai Oasis** — diisi saat penyiapan; menentukan uji buka/tutup kas.
4. **Daftar pegawai Kedai Oasis yang akan dilatih pertama & siapa admin cabangnya** — perlu saat uji pilot.
5. **Berapa lama periode uji pilot** sebelum dianggap memenuhi metrik (usulan: 1 bulan operasional penuh).
6. **Rencana penyewa kedua** — calon berikutnya & kapan ditawarkan (menentukan prioritas fitur fase 2).
7. **Kebijakan privasi & persetujuan data pelanggan** — sejak 2026-09-17 menjadi bagian **Fase 1B** (`docs/KEAMANAN.md` §11): agent menulis draf berbahasa Indonesia + kalimat persetujuan di halaman voucher; pemilik meninjau **sebelum data pelanggan pertama masuk** (butir tertangguh T-011).
8. **Keputusan mode offline untuk penyewa selain Kedai Oasis** — fase 3, dikaji saat ada calon penyewa dengan internet lemah.
9. **Region proyek Supabase** (usul: Singapore) — diputuskan pemilik saat T0-08; menentukan lokasi data pelanggan & dasar transfer (T-014).
10. **Tablet Android yang dipakai untuk mode terkunci satu-aplikasi (kiosk)** — daftar perangkat nyata dibutuhkan saat penyiapan Kedai Oasis; panduan mode kiosk ditulis agent (T-015).

---

## 11. Log Pembaruan Dokumen

| Tanggal | Pembaruan | Oleh |
|---|---|---|
| 2026-09-16 | Dokumen dibuat (DRAF) dari Tahap 1 Discovery yang disetujui + pemilahan MoSCoW (2 giliran PRD: batas MVP, peran 6, voucher & katalog masuk MVP, alur campur, pajak configurable, hak akses berjenjang + approval, void bertingkat, diskon configurable, metrik sukses) | Agent |
| 2026-09-16 | **Dokumen DISETUJUI & dikunci oleh pemilik** ("Mari lanjut") → lanjut ke sesi Desain & UI lalu Tahap 3 Tech Spec | Pemilik + Agent |
| 2026-09-17 | **M12 diperdalam** atas permintaan pemilik (pesan ke-14): satu akun satu peran · perangkat terdaftar (kode pendaftaran + persetujuan pemilik) · masuk staf = perangkat + PIN 6 digit · TOTP wajib untuk Pemilik Platform/Owner/Admin Cabang + jalan pemulihan · kunci otomatis & batas umur sesi · pencabutan seketika · ringkasan peringatan harian · audit berantai · privasi UU PDP · mode dukungan · **Aturan Bisnis 14–18 baru** · risiko #9–#11 baru | Pemilik (permintaan) + Agent (rancangan & riset; rincian di `docs/KEAMANAN.md`) |

| 2026-09-21 | **T-023 dilaksanakan:** hapus pembuatan/pemulihan PIN pelanggan di M10 dan alur 17; Google/email tetap, PIN pegawai/persetujuan tidak berubah. **T-025(a) diselaraskan:** M6 dan aturan 7 melarang ubah/void sesudah pembayaran pertama; hapus janji void terselubung sesudah bayar | Lee (setuju-semua); penegak 0022, bukti di `docs/uji/BUKTI_T025_BEKU_SETELAH_BAYAR.md` |
