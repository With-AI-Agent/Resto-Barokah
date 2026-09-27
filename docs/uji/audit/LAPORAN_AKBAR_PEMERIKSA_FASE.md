# LAPORAN AKBAR — PEMERIKSA RIWAYAT FASE (FASE 0 s/d FASE 10)
### Resto Barokah · Pemeriksaan Akbar Menyeluruh sebelum Fase 11 (Pilot Kedai Nyata)

| | |
|---|---|
| **Peran** | Pemeriksa Riwayat Fase (Vertikal) — peran no. 5 di `docs/uji/PAKET_PEMERIKSAAN_AKBAR_F0_F10.md` |
| **Naskah tugas** | `docs/uji/PROMPT_AKBAR_PEMERIKSA_FASE.md` |
| **Tanggal pemeriksaan** | 2026-09-27 |
| **Pohon yang diperiksa** | cabang `arena/01a0e266-resto-barokah` · commit `0fc63c7` ("docs(audit): perkaya naskah detail audit akbar dan segarkan handoff") |
| **Mode kerja** | **HANYA-BACA** — tidak satu pun berkas roadmap, STATUS, atau penanda bukti diubah. Satu-satunya berkas yang ditulis adalah laporan ini. |
| **Keputusan akhir** | **MEMERLUKAN PERBAIKAN — BELUM SIAP ke Fase 11** (1 temuan K-1 + 4 temuan K-2) |

---

## 1. Ringkasan Eksekutif (bahasa manusia)

Lee, saya menelusuri **sebelas fase** dari Fase 0 sampai Fase 10 secara berurutan, membuka kodenya satu per satu, dan menjalankan mesin pengujinya sendiri. Kesimpulannya begini:

**Yang sudah sangat kuat (tidak perlu diragukan):**
- Tidak ada **kebocoran data antar resto**. 47 tabel semuanya ber-RLS dan lolos 100% (`periksa-sisir-rls.py` → 0 tabel terbuka). Ini syarat K-1 yang paling menakutkan, dan ia bersih.
- Tidak ada **kunci rahasia** yang ikut ke repo (`periksa-rahasia.py` → LOLOS).
- **Tidak ada salah hitung uang**: 132 berkas uji SQL lulus semua, termasuk uji keuangan, pembulatan, sampai rupiah terkecil.
- **126 gerbang CI** utuh, **123 berkas uji antarmuka (1.013 pengujian)**, dan **sepuluh perintah wajib** di naskah tugas saya **lulus 10 dari 10**, masing-masing beserta uji-dirinya (buktinya: setiap pemeriksa terbukti bisa *menolak* yang rusak, bukan sekadar menyetujui yang benar).
- Riwayat audit kekal, cadangan terenkripsi AES-256, denyut harian jam 02:00 WIB, dan Buku Insiden berisi **5 skenario darurat** — semuanya nyata, bukan janji di atas kertas.

**Yang masih berhutang (dan menurut saya wajib beres sebelum pilot):**
1. **Kunci kedua (TOTP) untuk akun owner/admin belum ada sama sekali.** Bukan setengah jadi — benar-benar belum dibangun. Ini temuan lama `L F-01` dari audit AUD-3 (2026-09-24) yang sampai hari ini **masih terbuka**. Akun yang bisa mengubah uang dan pegawai hanya dilindungi email + PIN + perangkat.
2. **19 berkas antarmuka (18 modul fitur) yang sudah dibangun & lulus uji ternyata tidak pernah terpasang ke aplikasi yang berjalan.** Mereka ada di repo, 18 di antaranya punya berkas uji yang hijau di CI — tetapi tidak ada satu pun kode produksi yang memanggilnya. Jadi fiturnya **tidak bisa dipakai Lee**, meski tertulis "selesai".
3. **Printer belum bisa dipakai dari aplikasi.** Penyusun struk & tiket dapur sudah ada dan diuji, pengirim Bluetooth/USB sudah ada dan diuji — tetapi **tidak ada satu pun tombol di aplikasi yang memanggilnya**. Yang terpasang hanya layar "pasang printer" untuk mengecek dukungan perangkat.
4. **Pencatatan fase sudah ketinggalan dari kenyataan.** Fase 4 (Dapur) tertulis **0 dari 10 selesai**, padahal seluruh layarnya sudah ada dan terpasang. Sebaliknya Fase 2 tertulis "100%", padahal TOTP-nya tidak ada. Peta fase tidak lagi menggambarkan kenyataan, dan itu berbahaya untuk sesi agent berikutnya.
5. **Satu pengujian tidak stabil**: dari 5 kali menjalankan seluruh uji antarmuka, **1 kali gagal** di berkas `TutupKas.test.tsx`. Jadi klaim "hijau 100%" belum bisa dijamin berulang.

Ringkasnya: **fondasi uang, data, dan isolasi antar resto sudah kokoh.** Yang belum beres ada di **lapisan pemakaian nyata** — layar yang belum tersambung, kunci kedua yang belum ada, dan printer yang belum terhubung. Ketiganya akan langsung terasa di kedai nyata.

---

## 2. Cara saya memeriksa (supaya Lee bisa mengulang)

1. Menjalankan **sepuluh perintah wajib** di naskah tugas (5 alat × 2 mode: pemeriksaan + uji-diri).
2. Menjalankan **mesin pengujian utama** secara langsung (uji SQL, uji antarmuka, gerbang CI, 9 pemeriksa lain).
3. Membaca **ROADMAP.md** per fase, lalu **membuka berkasnya satu per satu** untuk memastikan yang tertulis "[x]" benar-benar ada.
4. Meminda **seluruh 128 berkas produksi** dan menyilangkan siapa mengimpor siapa → menemukan modul yang tidak pernah dipanggil.
5. Menyilangkan temuan saya dengan **117 temuan audit terdahulu** di `docs/uji/AUDIT_RIWAYAT.md` supaya Lee tahu mana yang baru dan mana yang sudah tercatat.

---

## 3. Tabel Bukti Pengujian

### 3.1 Sepuluh perintah wajib dari naskah tugas (wajib lulus semua)

| # | Perintah | Hasil | Keluar |
|---|---|---|---|
| 1 | `python3 alat/periksa-roadmap.py` | **LOLOS** — 193 tugas (T0:15, T1:45, T10:16, T11:13, T2:19, T3:16, T4:10, T5:12, T6:8, T7:12, T8:15, T9:12) · 7 atribut lengkap · fitur M1–M12 lengkap · 40 entitas §4 & 45 RPC §5 punya tugas · 2 rujukan tertangguh (sah) | 0 |
| 2 | `python3 alat/periksa-roadmap.py --uji-diri` | **LOLOS** — 12 kasus: pemeriksa terbukti menolak tanda ❓ palsu, penanda basi, ID tidak ada, dan berkas hilang | 0 |
| 3 | `python3 alat/periksa-panduan.py` | **LOLOS** — buku induk 799 baris · 16 alur · 4 blok prompt · 30 perintah · 13 mekanisme · 89 rujukan hidup | 0 |
| 4 | `python3 alat/periksa-panduan.py --uji-diri` | **LOLOS** — 21 mutasi ditolak (termasuk 11 pagar penyerahan AL-15) | 0 |
| 5 | `python3 alat/periksa-buku-uji.py` | **LOLOS** — 28 baris (6 lakukan + 22 coba), tiap baris punya langkah ≤5, harapan, kolom hasil, tugas sah | 0 |
| 6 | `python3 alat/periksa-buku-uji.py --uji-diri` | **LOLOS** — 5 mutasi ditolak | 0 |
| 7 | `python3 alat/periksa-rujukan.py` | **LOLOS** — 85 dokumen · 3.919 rujukan · 2 berkas pensiun diakui | 0 |
| 8 | `python3 alat/periksa-rujukan.py --uji-diri` | **LOLOS** — 4 mutasi ditolak | 0 |
| 9 | `python3 alat/periksa-angka-bukti.py` | **LOLOS** — semua angka bukti bisa direproduksi atau ditandai jujur | 0 |
| 10 | `python3 alat/periksa-angka-bukti.py --uji-diri` | **LOLOS** — 4 mutasi ditolak | 0 |

**Hasil: 10 / 10 LOLOS.** Tidak ada satu pun yang gagal.

### 3.2 Mesin pengujian utama (bukti tambahan saya)

| Perintah | Hasil | Catatan |
|---|---|---|
| `node alat/uji-sql.mjs` | **132 LULUS · 0 GAGAL** | Sesuai klaim paket "132 berkas uji SQL" |
| `cd aplikasi && npm test` (putaran 1) | **122 lulus · 1 GAGAL** dari 123 berkas (1.013 uji) | GAGAL di `TutupKas.test.tsx:171` → temuan **K3-3** |
| `cd aplikasi && npm test` (putaran 2–5) | **123 lulus · 1.013 uji lulus** | Artinya putaran 1 itu **tidak stabil**, bukan cacat permanen |
| `python3 alat/periksa-gerbang-ci.py` | **LOLOS** — 126 gerbang | Sesuai klaim paket "126 gerbang CI" |
| `python3 alat/periksa-sisir-rls.py` | **LOLOS** — 47/47 tabel terisolasi, 0 tanpa policy | Sesuai klaim "RLS 47 tabel" |
| `python3 alat/periksa-idempoten.py` | **LOLOS** — 8/8 RPC penulisan mendukung kunci idempoten | Lihat temuan K2-3 (yang diukur = sisi peladen) |
| `python3 alat/periksa-rahasia.py` | **LOLOS** — tidak ada kunci rahasia di berkas terlacak | Syarat K-1 terpenuhi |
| `python3 alat/periksa-migrasi-beku.py` | **LOLOS** — 16 migrasi beku utuh | Repo cocok dengan database nyata |
| `python3 alat/periksa-keamanan-sql.py` | **LOLOS** — 2 uji lulus | search_path + ACL + trigger-only + sapuan RLS |
| `python3 alat/periksa-temuan-audit.py` | **LOLOS** — 117 temuan terlacak, 108 ditutup, **5 terbuka** | Salah satu yang terbuka = **L F-01 (TOTP)** |
| `python3 alat/periksa-matriks-izin.py` | **LOLOS** — matriks 6 peran valid | |
| `python3 alat/periksa-fondasi-independen.py` | **BERSIH** — 40 entitas §4 & 45 RPC §5 punya tugas | Sesuai klaim "40 entitas Tech Spec" |
| `python3 alat/periksa-header.py` | **LOLOS** | Lihat temuan K4-3 (presisi kata "tanpa unsafe-inline") |
| `python3 alat/peta-ui.py` | **HIJAU** (Layar, Aksi, RPC, Izin, Uji, PRD M1–M12, Bebas Tombol Liar) | |

### 3.3 Angka yang saya hitung sendiri dari repo (bukan dari dokumen)

| Hal | Angka nyata | Perintah hitung |
|---|---|---|
| Berkas migrasi | **82** (0001–0085, tanpa 0034 / 0044 / 0055) | `ls supabase/migrations \| wc -l` |
| Berkas uji SQL | **132** | `ls supabase/tes/*.sql \| wc -l` |
| Berkas uji antarmuka | **123** (121 `*.test.*` + 2 `*.spec.ts`) | pencarian berkas uji di `aplikasi/` |
| Gerbang CI | **126** | `python3 alat/periksa-gerbang-ci.py` |
| Tabel basis data | **47** | `grep -rhoP "create table ...\K[a-z_]+" supabase/migrations \| sort -u \| wc -l` |
| Fungsi `public` yang dideklarasikan | **207 nama berbeda** (288 deklarasi karena penimpaan antar migrasi; termasuk fungsi pemicu `picu_*`) | `grep -rhoP "create (or replace )?function (public\.)?\K[a-z_]+" supabase/migrations \| sort -u \| wc -l` |
| RPC resmi `TECH_SPEC` §5 | **45 nama**, semuanya punya tugas | `python3 alat/periksa-fondasi-independen.py` → BERSIH |
| Tugas ROADMAP Fase 0–10 | **180** (146 selesai · **34 terbuka**) | pembacaan `docs/ROADMAP.md` |
| Berkas produksi antarmuka | **128**, yang **20 tidak diimpor** oleh berkas produksi lain | pemindaian impor |

---

## 4. Matriks Evaluasi Fase 0 s/d Fase 10

Keterangan status:
- ✅ **TUNTAS** — janji terpenuhi dan terbukti di kode berjalan.
- ⚠️ **TUNTAS SEBAGIAN** — sebagian janji terpenuhi, sebagian belum / tidak terjangkau.
- ❌ **BELUM TUNTAS** — janji utama fase ini belum terpenuhi.
- 📒 **UTANG CATATAN** — pekerjaan sudah ada, tetapi pencatatannya belum diperbarui.

| Fase | Janji (dari naskah) | Tugas selesai | Bukti kode yang saya buka | Status |
|---|---|---|---|---|
| **Fase 0 — Fondasi** | Standar repo, linter, TypeScript ketat, penjaga gerbang | **14 / 15** | ESLint 9 + Prettier + TS ketat aktif; CI hijau & terbukti pernah merah (run 35121292973); 126 gerbang; `.env` diabaikan Git; 0 rahasia di repo; `periksa-fondasi-independen.py` BERSIH | ⚠️ **Tuntas sebagian** — T0-12 (audit independen menyeluruh) memang sengaja terbuka; pemeriksaan akbar ini adalah pelaksananya |
| **Fase 1 — Basis data** | 40 entitas, isolasi multi-tenant, matriks izin peran | **11 / 22** (+ Fase 1B 9/11) | 40 entitas & 45 RPC punya tugas (BERSIH); 47 tabel ber-RLS, 0 terbuka; harga baris pesanan dijaga peladen (`supabase/tes/harga_item.sql`, migrasi 0012/0015); `hitung_total` hidup di 0014/0015/0022; matriks 6 peran valid | ⚠️ **Tuntas sebagian + 📒 utang catatan** — 11 tugas (T1-11…T1-22) masih terbuka; sebagian besar **pekerjaannya sudah mendarat dengan nama lain** (kas/shift → 0045–0054, voucher → 0064–0068, bayar → 0039, idempoten → 0080, sapuan RLS → T10-05). Yang **benar-benar belum ada**: data awal (seed) — lihat **K2-2** |
| **Fase 2 — Autentikasi** | PIN 6 digit kasir, **TOTP 2FA akun owner**, penguncian sesi | **18 / 19** | PIN 6 digit + papan angka fisik nyata di `LayarMasukPegawai.tsx`; pembatasan percobaan sisi-peladen (0014); sesi perangkat & pencabutan (0013, 0081); matriks masuk 6 peran teruji | ❌ **BELUM TUNTAS** — **TOTP sama sekali belum ada** (lihat **K1-1**). Tugas T2-13 memang jujur terbuka, tetapi **T2-18 tertulis `[x]` dengan janji "kata sandi + TOTP + perangkat"** — klaim itu tidak benar |
| **Fase 3 — Kasir utama** | Buka meja, pesanan dine-in & bungkus, kirim ke dapur | **13 / 16** | `LayarKasir` terpasang & terhubung ke RPC; `PemilihMeja`, `Keranjang`, `Bayar`, `VoidItem`, `DiskonManual`, `VoucherKasir` semuanya terpakai; alur E2E & uji beban lulus | ⚠️ **Tuntas sebagian** — T3-05 (RPC `simpan_pesanan`) belum tersambung (**K2-3**), T3-09 (konflik meja) belum ada, T3-13 (batal sebelum dapur) belum ada; `DaftarPesanan.tsx` (T3-12, tertulis `[x]`) **tidak terpasang** |
| **Fase 4 — Dapur/KDS** | Layar dapur & bar terpisah, status masak/saji, tombol stok habis | **0 / 10** | Semua layar **ada dan terpasang**: `App.tsx` mengimpor `LayarDapur`, `LayarBar`, `Stok`, `Opname`; `KartuPesanan` & `TombolHabis` dipakai di dalamnya; migrasi 0032 (`set_status_item`) & 0035 (`tandai_habis`) hidup; uji `status_item.sql`, `tujuan_item.sql`, `menu_habis_sumber.sql` lulus | 📒 **UTANG CATATAN (berat)** — kodenya sudah mendarat, **centangnya belum**. STATUS.md baris 244 masih menyebut "Sisa Fase 4 … menunggu batch berikutnya" (tertulis 2026-09-22). Lihat **K3-1** |
| **Fase 5 — Bayar & void** | Tunai/QRIS, diskon butuh persetujuan atas, void berjenjang | **11 / 12** | `bayar_pesanan` (0039); diskon butuh PIN atasan (0041); void berjenjang + `persetujuan_void.sql` & `bahan_terbuang.sql` lulus; beku setelah bayar (0022) dijaga uji; struk di layar tampil di `Bayar` & `DaftarTransaksi` | ⚠️ **Tuntas sebagian** — T5-10 (cetak ulang + jejak audit) sengaja tertangguh (❓ T-028, putusan Lee, 5 pengait tercatat); **struk digital/WhatsApp (T5-09, tertulis `[x]`) tidak terpasang** — lihat **K2-1** |
| **Fase 6 — Cetak struk** | Bluetooth/USB 58mm/80mm, tiket dapur, struk WhatsApp | **5 / 8** | Penyusun ESC/POS `expos.ts` **murni & teruji** (29 tes); profil 5 merek printer Lee + jaminan merek lain (3 mutasi merah); `kirim.ts` punya `cetakBluetooth` & `cetakUsb`; `susunStruk` & `susunTiket` ada & teruji | ❌ **BELUM TUNTAS untuk pemakaian nyata** — **tidak ada satu pun kode produksi yang memanggil `cetakBluetooth`, `cetakUsb`, `susunStruk`, maupun `susunTiket`**. Aplikasi **tidak bisa mencetak**. Lihat **K2-4** |
| **Fase 7 — Kas & shift** | Modal awal, kas keluar/masuk, tutup shift & selisih | **12 / 12** | `buka_shift` (0045), `tutup_shift` (0046), `kas_pergerakan` (0047), wajib shift (0048), koreksi modal (0050), laporan (0051–0053), transaksi tengah malam (0054); `BukaKas`/`TutupKas`/`KasKeluarMasuk`/`KoreksiModal` terpasang di `LayarKasir` | ✅ **TUNTAS** |
| **Fase 8 — Voucher & laporan** | Kuota voucher cabang, laporan penjualan, (grafik omzet) | **15 / 15** | `katalog_publik` (0062), terbit voucher acak (0064), `cek_voucher`/`pakai_voucher` (0065/0067), pengaman 10 lapis, laporan voucher (0068), privasi UU PDP (0069); `LayarLaporan` + 6 laporan + `Peringatan` terpasang; `Kampanye` & `Daftar` voucher terpasang | ✅ **TUNTAS** (dengan 2 catatan: `KebijakanPrivasi.tsx` tidak terpasang → K2-1; kata "grafik omzet" bukan janji PRD → K4-4) |
| **Fase 9 — Multi-cabang & pengaturan** | Kelola cabang, menu cabang, pendaftaran tenant Lee, riwayat kekal | **12 / 12** | 0070–0078 (identitas, tema, operasional, meja, menu, menu cabang, metode bayar, pegawai, cabang); `LayarPengaturan` terpasang dengan ~18 layar anak; riwayat kekal `catatan_audit` + `truncate_audit_ditolak.sql` + rantai hash (0029) | ⚠️ **Tuntas sebagian** — layar **pendaftaran tenant Lee** (`platform/Penyewa.tsx`, T9-10) **tidak terpasang**; Edge Function `daftar_penyewa` ada. Lihat **K2-1** |
| **Fase 10 — Ketahanan & bencana** | Antrean luring IndexedDB, idempotensi ART-8, Buku Insiden, cadangan AES-256, CSP ketat | **16 / 16** | `antrean-offline.ts` IndexedDB + sanitasi rekursif + fallback memori; `useAntrean` terpasang lewat `StatusAntrean` di bilah kasir; 0080 kunci idempoten 8/8; 0082 denyut harian cron `0 19 * * *` (= 02:00 WIB) **terverifikasi**; cadangan AES-256-CBC + PBKDF2 100.000 iterasi; Buku Insiden **5 skenario** (§7, §8, §9, §12, §13); CSP tanpa `unsafe-inline` untuk skrip; pemulihan kredensial/MFA via tangga peran + kunci induk darurat (T10-16) | ⚠️ **Tuntas sebagian** — 3 catatan: `StatusAntreanOffline.tsx` & `pemulihan-sesi.ts` tidak terpasang (**K2-1**); CSP masih mengizinkan `unsafe-inline` untuk gaya (**K4-3**); klaim T10-02 "idempoten menyeluruh" tidak berlaku di jalur klien (**K2-3**) |

**Rekap cepat:** Fase 7 & 8 tuntas. Fase 0, 1, 3, 5, 9, 10 tuntas sebagian. **Fase 2 & 6 belum tuntas** untuk pemakaian nyata. **Fase 4** tuntas di kode tetapi belum dicatat.

---

## 5. Daftar Temuan & Utang Teknis

### K-1 — KRITIS

#### K1-1 · Kunci kedua (TOTP 2FA) untuk akun berkuasa belum ada sama sekali
- **Fase:** 2 (Autentikasi) · **Tugas:** T2-13 (terbuka) dan **T2-18 (tertulis `[x]` — klaimnya keliru)**
- **Bukti yang saya jalankan sendiri:**
  - `find aplikasi -iname "Totp*"` → **0 hasil**
  - `grep -rl "totp\|TOTP" supabase/migrations` → **0 dari 82 migrasi**
  - `ls supabase/functions` → `akhiri_sesi`, `daftar_penyewa`, `ringkasan_harian`, `verifikasi_pelanggan`, `verifikasi_pin` — **tidak ada `atur_ulang_mfa`**
  - `ls alat/periksa-fungsi-mfa.py` → **tidak ada**
  - `grep -rn "butuhTotp" aplikasi/src` → hanya di `MasukPengelola.tsx:15` (tipe) dan `:68` (panggilan tiruan), plus berkas ujinya
  - `MasukPengelola` (satu-satunya layar TOTP) **tidak pernah dirender**: `App.tsx` hanya memanggil `LayarMasukPegawai` (baris 532) dan `LayarMasukPelanggan` (baris 514)
- **Dampak untuk Lee:** akun `pemilik_platform`, `owner_pusat`, `admin_cabang` — yang bisa mengubah uang, menghapus pegawai, dan membuka laporan — hanya dilindungi email + PIN + perangkat. Bila kata sandi/perangkatnya dipinjam atau dicuri, tidak ada lapis kedua.
- **Status riwayat:** ini **sudah tercatat** sebagai temuan `L F-01` (K-1) dari AUD-3 sesi `arena/01a0d3d8` (2026-09-24) dan **sampai hari ini masih TERBUKA** (`periksa-temuan-audit.py`: 5 temuan terbuka). Saya mengonfirmasi ulang dengan bukti baru di pohon ini — **tidak ada kemajuan sejak 2026-09-24.**
- **Yang perlu dikerjakan:** bangun MFA nyata (rahasia TOTP per akun, verifikasi sisi-peladen, kode pemulihan, Edge Function `atur_ulang_mfa` tanpa `console.*`, jejak audit), **pasang ke alur masuk yang benar-benar dipakai**, lalu uji integrasi.

### K-2 — TINGGI

#### K2-1 · 19 berkas antarmuka (18 modul fitur) yang sudah dibangun & lulus uji tidak pernah terpasang ke aplikasi berjalan
- **Cara menemukan:** saya memindai seluruh **128 berkas produksi** di `aplikasi/src` dan menyilangkan pernyataan `import … from '…'`. Hasilnya: **20 berkas tidak diimpor oleh satu pun berkas produksi lain**. Satu di antaranya (`uji/harness.tsx`) adalah utilitas uji yang sah, jadi tersisa **19 berkas nyata = 18 modul fitur** (penyusun cetak `struk.ts` + `tiket.ts` saya hitung satu entri).
- **Perintah yang bisa Lee ulang:** `grep -rn "from '\." aplikasi/src --include="*.ts*" \| grep -v "\.test\."` lalu cocokkan dengan daftar berkas; atau minta sesi kerja menambahkan gerbang `periksa-modul-terpasang.py` (saran obat di bawah).
- **Daftar lengkap & tugas yang mengklaimnya:**

| Modul (ada, punya uji, hijau) | Tugas yang tertulis `[x]` | Akibatnya |
|---|---|---|
| `layar/masuk/MasukPengelola.tsx` | T2-18 | Masuk owner/admin + TOTP tidak bisa dipakai |
| `layar/masuk/MasukStaf.tsx` | T2-14 | Layar masuk staf "pilih nama → PIN" tidak dipakai (yang jalan: `LayarMasukPegawai`) |
| `hook/useKunciOtomatis.ts` | T2-09, T2-16 | **Kunci otomatis saat menganggur tidak pernah aktif** |
| `komponen/KunciSekarang.tsx` | T2-16 | Tombol "Kunci sekarang" tidak pernah tampil |
| `komponen/StrukDigital.tsx` | T5-09 | **Struk digital / WhatsApp tidak bisa dikirim** |
| `komponen/TombolAksi.tsx` | T1-32 | "Satu sumber kebenaran tombol" tidak dipakai satu tombol pun |
| `layar/TidakPunyaAkses.tsx` | T2-08 | Halaman "tidak punya akses" tidak pernah muncul |
| `layar/kasir/DaftarPesanan.tsx` | T3-12 | Daftar pesanan hari ini + filter tidak bisa dibuka |
| `layar/kasir/DaftarTagihan.tsx` | T3-04, T5-11 | Tagihan terbuka tidak bisa dibuka dari layar itu |
| `layar/kasir/DataPelanggan.tsx` | T5-08 | Data pelanggan opsional tidak bisa diisi |
| `layar/kasir/Voucher.tsx` | T8-09 | (duplikat `VoucherKasir.tsx` yang terpasang) |
| `layar/masuk/LupaAkses.tsx` | T2-05 | Pemulihan akses pelanggan tidak bisa dibuka |
| `layar/pelanggan-publik/KebijakanPrivasi.tsx` | T8-15 | Halaman kebijakan privasi tidak bisa dibuka |
| `layar/pengaturan/Perangkat.tsx` | T2-15 | **Pendaftaran perangkat (kode/QR) tidak bisa dibuka**; yang terpasang hanya `DaftarPerangkat` (daftar & cabut) |
| `layar/platform/Penyewa.tsx` | T9-10 | **Pendaftaran tenant baru oleh Lee tidak bisa dibuka** (Edge Function `daftar_penyewa` ada) |
| `lib/pemulihan-sesi.ts` | T10-09 | Pemulihan setelah listrik mati tidak tersambung ke `LayarKasir` |
| `lib/printer/struk.ts`, `lib/printer/tiket.ts` | T6-04, T6-05 | Penyusun struk & tiket dapur tidak pernah dipanggil (lihat K2-4) |
| `komponen/StatusAntreanOffline.tsx` | T10-01 | Duplikat `StatusAntrean.tsx` yang terpasang |

- **Catatan kejujuran:** 18 dari 19 berkas ini punya berkas uji sendiri yang lulus. Satu-satunya yang **tanpa uji** adalah `layar/kasir/Voucher.tsx` — dan ia memang duplikat dari `VoucherKasir.tsx` yang terpasang, jadi ia layak **dipensiunkan**, bukan diuji.
- **Kenapa ini bahaya:** semua berkas ini **lulus uji unitnya sendiri**, jadi CI tetap hijau. Tidak ada satu gerbang pun yang memeriksa "apakah modul ini benar-benar dipakai aplikasi". Ini membuat peta fase terlihat lebih hijau daripada kenyataan.
- **Saran obat permanen:** tambah satu gerbang baru (mis. `alat/periksa-modul-terpasang.py`) yang menolak bila berkas di `aplikasi/src/layar/` atau `aplikasi/src/komponen/` tidak direferensikan berkas produksi lain — dengan daftar pengecualian beralasan. Lengkapi dengan uji-diri supaya gerbangnya terbukti bisa menolak.

#### K2-2 · Data awal (seed) belum ada — menghambat pilot
- **Tugas:** T1-21 (terbuka) · **Bukti:** `supabase/seed.sql` dan `supabase/seed_uji.sql` **tidak ada**.
- **Dampak:** DoD T3-12 mensyaratkan "uji manual dengan 300 pesanan contoh (seed) → respons < 1 detik". Tanpa data contoh, uji beban nyata dan persiapan kedai (menu, meja, pegawai Kedai Oasis) tidak bisa dilakukan. **Ini pekerjaan yang benar-benar belum ada**, bukan sekadar catatan yang tertinggal.

#### K2-3 · Penyimpanan pesanan mem-bypass RPC `simpan_pesanan` — janji idempotensi ART-8 tidak utuh di jalur klien
- **Fase:** 3 & 10 · **Bukti:**
  - RPC `public.simpan_pesanan` **ada dan idempoten** (`supabase/migrations/0080_kunci_idempoten_menyeluruh.sql:49`, dilengkapi `revoke`/`grant` dan komentar).
  - Tetapi **tidak pernah dipanggil**: `grep -rn "rpc('simpan_pesanan'" aplikasi/src` → 0 hasil. Yang ada hanya `rpc('hitung_total')`.
  - `App.tsx:86` dan `useAntrean.ts:113` menulis **langsung ke tabel** `pesanan` lalu `pesanan_item`.
  - Proteksi dobel saat ini bergantung pada indeks unik `pesanan(cabang_id, kunci_idempoten)` (migrasi 0009:42) dan pemeriksaan kode galat `23505` di `useAntrean.ts:120`.
- **Catatan riwayat:** temuan `L F-03` (K-1, "simpan pesanan mengembalikan sukses-palsu") ditutup 2026-09-25 **dengan memilih jalur langsung ke tabel**, bukan lewat RPC kanonik. Jadi perbaikannya sah, tetapi jalur tulis sekarang bercabang dari rancangan.
- **Dampak:** dua jalur penulisan pesanan (RPC vs tabel langsung) harus dijaga konsistensinya selamanya; tiap aturan baru di RPC tidak otomatis berlaku di jalur klien.
- **Saran:** satukan ke RPC `simpan_pesanan`, atau tuliskan secara eksplisit di `docs/DECISIONS_LOG.md` bahwa jalur klien sengaja menulis langsung + alasannya, lalu kunci dengan uji.

#### K2-4 · Printer tidak bisa dipakai dari aplikasi (Fase 6)
- **Bukti:**
  - `grep -rn "cetakBluetooth\|cetakUsb" aplikasi/src --include="*.ts*"` (di luar berkas uji) → **0 pemanggil**.
  - `grep -rn "susunStruk\|susunTiket" aplikasi/src` (di luar berkas uji) → hanya **definisi** di `struk.ts` dan `tiket.ts`, **tidak ada pemanggil**.
  - `PasangPrinter.tsx` (satu-satunya layar printer yang terpasang) hanya mengimpor `PenyusunEscPos`, `LEBAR_58MM/80MM`, dan `dukungBluetooth/dukungUsb/pesanTakDidukung` — yaitu **hanya pengecekan dukungan**, bukan pencetakan.
  - `LayarKasir.tsx` **tidak punya aksi cetak sama sekali**; ia hanya menyiapkan `dataStruk` untuk pratinjau struk di layar (`Bayar.tsx`).
- **Dampak untuk Lee:** di kedai nyata, kasir **tidak bisa mencetak struk pelanggan** dan dapur **tidak bisa menerima tiket dapur** dari aplikasi. T6-04 & T6-05 tertulis `[x]`, tetapi jalurnya tidak tersambung.
- **Catatan kejujuran:** uji cetak di printer nyata memang belum pernah dilakukan (T6-08 terbuka, butuh alat), jadi sebagian dari ini konsisten dengan statusnya. Yang saya laporkan adalah **tidak adanya jalur panggil sama sekali** — bukan sekadar "belum diuji".

### K-3 — SEDANG

#### K3-1 · Fase 4 (Dapur/KDS) tertulis 0/10 tetapi kodenya sudah mendarat & terpasang
- **Bukti:** `App.tsx` baris 15–18 mengimpor `LayarDapur`, `LayarBar`, `Stok`, `Opname`; `KartuPesanan.tsx` & `TombolHabis.tsx` dipakai di dalamnya; migrasi `0032_status_item_dapur.sql` & `0035_menu_habis_sumber.sql` hidup dan diuji (`status_item.sql`, `tujuan_item.sql`, `menu_habis_sumber.sql` lulus).
- **Bedanya dengan kenyataan di dokumen:** `docs/STATUS.md` baris 244–245 (tertulis 2026-09-22) masih menyatakan "Sisa Fase 4 (T4-01 … T4-10) menunggu batch berikutnya".
- **Yang masih benar-benar terbuka:** T4-09 (`aplikasi/uji/e2e/dapur.spec.ts`) — sah tertangguh oleh ❓ T-026 (infra Playwright, putusan Lee 2026-09-23).
- **Saran:** centang T4-01…T4-08 & T4-10 dengan bukti baru (sudah ada), biarkan T4-09 terbuka dengan tanda ❓ T-026.

#### K3-2 · Fase 1 & Fase 6 penuh rujukan berkas usang
- **Fase 1:** T1-11…T1-22 masih menunjuk `0018_kas_shift.sql`, `0019_voucher.sql`, `0021_antrean_kesalahan.sql`, `0022_hitung_total.sql`, `0023_urutan_pembulatan.sql`, `0024_penomoran.sql`, `0025_state_machine.sql`, `0026_cek_voucher.sql`, `0027_pakai_voucher.sql` — **semuanya tidak pernah ada**. Pekerjaannya mendarat dengan nama lain.
- **Fase 6:** T6-07 menunjuk `PengaturanPrinter.tsx` & `0044_printer.sql` (tidak ada), padahal `PasangPrinter.tsx` sudah terpasang.
- **Dampak:** agent sesi berikutnya akan mencari berkas hantu, atau mengira pekerjaan belum dimulai lalu mengerjakannya dua kali. Ini adalah **utang catatan**, bukan utang kode.

#### K3-3 · Satu pengujian antarmuka tidak stabil (klaim "hijau 100%" belum bisa dijamin berulang)
- **Bukti:** dari 5 kali menjalankan `cd aplikasi && npm test`:
  - putaran 1 → **122 lulus · 1 GAGAL** (`src/layar/kasir/TutupKas.test.tsx:171`)
  - putaran 2, 3, 4, 5 → **123 lulus · 1.013 uji lulus**
  - menjalankan berkas itu sendiri → **9 uji lulus** (tidak gagal)
- **Sebab (saya baca kodenya):** baris 166–171 berbunyi `await waitFor(() => expect(mockOnTutupShift).toHaveBeenCalledWith(...))` lalu **langsung** `expect(screen.getByText('Shift Kas Berhasil Ditutup!')).toBeDefined()` tanpa `waitFor`. `waitFor` selesai begitu *pemanggilan* terjadi, padahal *tampilan* sukses baru muncul setelah React memperbarui status — balapan ini kalah saat mesin sedang sibuk.
- **Saran obat:** bungkus pemeriksaan teks sukses itu dengan `await waitFor(...)` juga. Ini pelajaran yang sama dengan yang sudah dicatat di proyek ini: "uji yang tidak bisa direproduksi bukan bukti".

#### K3-4 · Tombol "Kebijakan Privasi" mati di tiga layar
- **Bukti:** `LayarMasukPelanggan.tsx:149`, `layar/voucher/Daftar.tsx:427`, `layar/voucher/Kampanye.tsx:350` memasang `<Tombol onClick={onBukaKebijakanPrivasi}>`, tetapi `App.tsx` **tidak pernah mengisi prop itu** (baris 514–517 hanya mengisi `onMasukGoogle` dan `onKirimTautanEmail`). Klik → tidak terjadi apa-apa.
- **Dampak:** kriteria kelulusan paket menyebut "tidak ada tombol mati". Tombol ini mati, dan kebetulan ia adalah tombol **kewajiban UU PDP** yang seharusnya paling mudah ditemukan pelanggan.

### K-4 — SARAN (bukan cacat, tetapi perlu dirapikan)

| # | Temuan | Bukti | Saran |
|---|---|---|---|
| K4-1 | Paket & prompt spesialis data menyebut **"85 migrasi SQL"** / rentang `0001`–`0085` | Berkas migrasi nyata **82**; nomor **0034, 0044, 0055 tidak pernah dibuat**; 0085 = nomor tertinggi | Ubah jadi "82 berkas migrasi (bernama 0001–0085)". Kalau tidak, pemeriksa data akan mencari 3 berkas hantu |
| K4-2 | Paket menyebut **"Buku Insiden 4 skenario darurat"** | Kenyataannya **5 skenario** (§7 internet mati, §8 Supabase tidur/batas gratis, §9 printer bermasalah, §12 token kedaluwarsa, §13 salah void) + 6 bagian penanganan lain | Kabar baik — tinggal samakan katanya jadi "5 skenario" |
| K4-3 | Klaim **"CSP ketat tanpa `unsafe-inline`"** kurang presisi | `aplikasi/public/_headers:24` → `script-src 'self';` **(benar tanpa unsafe-inline)**, tetapi `style-src 'self' 'unsafe-inline';` **masih mengizinkan gaya sebaris** | Tulis apa adanya: "CSP tanpa `unsafe-inline` untuk skrip; gaya sebaris masih diizinkan karena React". Uji `keamanan-header.test.ts:48` memang sudah mengasumsikan demikian — tinggal dokumennya yang perlu jujur |
| K4-4 | Paket menyebut **"grafik omzet"** untuk Fase 8 | `grep -n "grafik" docs/PRD.md` → **0 hasil**. PRD M8 (terkunci) hanya menjanjikan *isi* laporan (omzet, transaksi, metode bayar, menu terlaris, diskon/voucher, pembatalan, kas, selisih, nama kasir) — tanpa grafik. Yang dikirim: tabel di `LaporanPenjualan.tsx` | Grafik bukan janji PRD. Cabut kata itu dari naskah pemeriksa, atau jadikan permintaan baru untuk Lee |
| K4-5 | Angka tabel RLS tidak seragam antar dokumen | `STATUS.md` T10-05 menyebut "45 dari 45 tabel"; `periksa-sisir-rls.py` dan paket memakai **47** | Samakan ke 47 di `STATUS.md` |
| K4-6 | Dua komponen antrean luring tumpang tindih | `StatusAntrean.tsx` (terpasang di `LayarKasir.tsx:592`) dan `StatusAntreanOffline.tsx` (tidak terpasang) | Pilih satu, pensiunkan yang lain dan catat di `docs/uji/BERKAS_PENSIUN.md` |
| K4-7 | Tidak ada gerbang yang mendeteksi modul tidak terpasang | 126 gerbang ada, tetapi tidak satu pun memeriksa "apakah modul UI ini dipanggil kode produksi" | Lihat saran obat di K2-1 |

---

## 6. Kesimpulan

**Saya menyatakan: SELURUH SEBELAS FASE BELUM TUNTAS TANPA UTANG TEKNIS. Sistem MEMERLUKAN PERBAIKAN sebelum Fase 11 (Pilot Kedai Nyata).**

Penjelasannya dengan kriteria kelulusan paket:

| Kriteria | Hasil |
|---|---|
| **0 temuan Kritis (K-1)** | ❌ **TIDAK TERPENUHI** — 1 temuan: TOTP 2FA akun berkuasa tidak ada (K1-1). *(Catatan adil: dua syarat K-1 lainnya terpenuhi — 0 kebocoran antar penyewa, 0 salah hitung uang, 0 rahasia bocor.)* |
| **0 temuan Mayor (K-2)** | ❌ **TIDAK TERPENUHI** — 4 temuan: 19 berkas antarmuka tidak terpasang, seed belum ada, bypass RPC `simpan_pesanan`, printer tidak tersambung. Termasuk 1 **tombol mati** (K3-4) yang secara tegas dilarang kriteria ini. |
| **100% mesin penguji hijau** | ⚠️ **HAMPIR TERPENUHI** — 10/10 perintah wajib lulus; 132/132 uji SQL; 126 gerbang CI; tetapi **1 dari 5 putaran uji antarmuka gagal** karena satu uji tidak stabil (K3-3). |

**Yang paling perlu Lee putuskan sebelum pilot** (urutan saya sarankan):
1. **K1-1 TOTP** — akun yang memegang uang & pegawai harus berlapis dua. Ini sudah terbuka sejak 2026-09-24 dan belum bergerak.
2. **K2-1 pasang modul yang sudah jadi** — 19 berkas antarmuka sudah dibangun & 18 di antaranya teruji; tinggal disambungkan. Ini pekerjaan penyambungan, bukan membangun dari nol, jadi relatif murah dan langsung menaikkan nilai pakai.
3. **K2-4 printer** — tanpa ini, kasir tidak bisa menyerahkan struk dan dapur tidak menerima tiket. T6-08 (uji alat nyata) memang menunggu alat, tetapi **jalur panggilnya harus ada lebih dulu**.
4. **K3-1 & K3-2 rapikan peta fase** — supaya sesi berikutnya tidak mengerjakan ulang yang sudah ada dan tidak melewatkan yang benar-benar belum ada.

**Yang sudah boleh Lee percaya:** uang, data, dan pemisahan antar resto. 132 uji SQL, 47 tabel ber-RLS, dan 1.013 uji antarmuka semuanya lulus; tidak ada kebocoran lintas penyewa; tidak ada kunci rahasia di repo; cadangan terenkripsi & buku insiden tersedia.

---

## 7. Penutup

### Posisi Sekarang
Pemeriksaan vertikal 11 fase sudah selesai dijalankan di cabang `arena/01a0e266-resto-barokah` (commit `0fc63c7`) dengan mode hanya-baca. Sepuluh perintah wajib lulus 10/10, 132 uji SQL lulus, 126 gerbang CI lulus, 1.013 uji antarmuka lulus (dengan 1 uji rapuh). Dari 180 tugas Fase 0–10, **146 selesai dan 34 terbuka**. Ditemukan **1 temuan K-1, 4 K-2, 4 K-3, dan 7 K-4**. Fondasi uang & isolasi data **sudah kuat**; yang belum beres ada di lapisan pemakaian nyata: **kunci kedua belum ada, 19 berkas antarmuka belum tersambung, printer belum terhubung, dan peta fase ketinggalan dari kenyataan.**

### Rencana Selanjutnya
Laporan ini adalah peran ke-5 dari 5 peran dalam matriks pemeriksaan akbar. Setelahnya, hasil saya perlu disilangkan dengan empat pemeriksa lain di `docs/uji/PAKET_PEMERIKSAAN_AKBAR_F0_F10.md`: Auditor Utama (holistik), Spesialis Basis Data & Keuangan, Spesialis Frontend & Antarmuka, dan Spesialis Infrastruktur & SOP Bencana. Beberapa temuan saya **bersinggungan langsung** dengan mereka dan sebaiknya dibaca bersama: modul tidak terpasang (K2-1) dan uji rapuh (K3-3) → Spesialis Frontend; bypass RPC `simpan_pesanan` (K2-3) dan seed (K2-2) → Spesialis Data; CSP & cadangan (K4-3) → Spesialis Infrastruktur.

### Langkah Lee
1. **Baca bagian 5 (K-1 & K-2) dan putuskan tiga hal:** (a) apakah TOTP (K1-1) wajib beres sebelum pilot, (b) apakah 19 berkas antarmuka yang sudah jadi (K2-1) disambungkan sekarang atau dicatat sebagai lingkup Fase 11, (c) bagaimana menuntaskan printer (K2-4) mengingat uji alat nyata butuh kehadiran di Kedai Oasis.
2. **Jalankan 4 pemeriksa lainnya** dengan naskah siap-salin di `docs/uji/` (`PROMPT_AKBAR_AUDITOR_UTAMA.md`, `PROMPT_AKBAR_SPESIALIS_DATA.md`, `PROMPT_AKBAR_SPESIALIS_FRONTEND.md`, `PROMPT_AKBAR_SPESIALIS_INFRASTRUKTUR.md`) supaya matriksnya lengkap sebelum mengambil keputusan Fase 11.
3. **Perintahkan sesi kerja (bukan sesi pemeriksa) untuk merapikan K3-1 & K3-2** — centang Fase 4 yang sudah mendarat, perbarui rujukan berkas usang di Fase 1 & T6-07 — karena pekerjaan catatan ini tidak boleh dikerjakan oleh pemeriksa (mode hanya-baca).
4. **Ulangi sendiri 3 perintah ini** bila ingin memverifikasi temuan saya tanpa percaya kata-kata saya:
   `cd aplikasi && npm test` · `node alat/uji-sql.mjs` · `python3 alat/periksa-gerbang-ci.py`

---
*Laporan ini ditulis dalam mode hanya-baca. Tidak ada berkas roadmap, STATUS, PROJECT_STATE, atau penanda bukti yang diubah selama pemeriksaan.*
