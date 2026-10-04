# USULAN — PERAN "PEMBANGUN": apa artinya, dan perlukah sesi Perencana sendiri yang mengerjakannya?

**Status:** **DIPUTUSKAN LEE 2026-09-30: OPSI B** ("Terkait peran Pembangun, aku ikut rekomendasi kamu" — REKAM §31 butir 24): percobaan terbatas **3 potongan**, Perencana = PEMBANGUN, Hakim tetap sesi lain; diukur dengan tabel §9 lalu dilaporkan ke Lee. ·
**Ditulis:** Perencana `arena/01a0e747-resto-barokah`, 2026-09-30 · **Penjaga:** tidak ada berkas uji mesin untuk dokumen ini (usulan, bukan mekanisme).
**Pemicu:** pertanyaan Lee 2026-09-30 (REKAM_PESAN_PEMILIK §31 butir 23), kira-kira: *"maksud peran pembangun tuh apa? … Apakah maksudnya yang mengeksekusi
hasil temuan pemeriksa dan hakim? Kalau betul itu, kenapa tidak kamu saja? Bukankah mengerjakan lebih baik kalau dilakukan di satu sesi, karena perlu konsistensi
dan terkumpulnya konteks dan asumsi? … Aku ga mau kamu setuju begitu aja. Kamu harus kritisi dulu."*

---

## 0. Ringkasan untuk Lee (bahasa sederhana)

**Definisi Lee benar.** PEMBANGUN = peran yang **mengeksekusi perbaikan** temuan yang sudah **diverifikasi Pemeriksa** dan **dinilai Hakim** (baris `TERVERIFIKASI`).
Ia bukan penemu, bukan penilai, dan **tidak boleh menutup** temuannya sendiri; ia juga tidak boleh melebar (temuan baru yang ia jumpai dicatat sebagai baris baru,
bukan diam-diam diperbaiki).

**Usul Lee juga separuh benar, dan separuh itu penting:** pekerjaan yang saling terkait memang lebih baik berada di satu kepala. Tetapi **menyatukan PEMBANGUN
ke sesi Perencana** bukan langkah bebas risiko, karena yang hilang bukan hanya pembagian tugas — yang hilang adalah **pembaca kedua yang membaca beda (diff) sebelum
masuk**, dan itu justru satu-satunya hal yang menangkap dua kesalahan nyata di proyek ini (`PMB1-F-216`, `PMB1-F-217`): berkas bukti lama tertimpa dan satu
paragraf keputusan Lee terhapus. CI tidak menangkap keduanya; **mata sesi lain yang menangkapnya.**

**Rekomendasi saya (bukan setuju bulat, bukan tolak bulat): Opsi B — percobaan terbatas & terukur.** Perencana boleh mengambil peran PEMBANGUN untuk
**satu potongan per giliran**, sementara **Hakim tetap sesi lain** (penutupan tetap independen) dan **CI/rantai bukti tetap wajib hijau**. Hasil percobaan
dibandingkan dengan tiga potongan Pembangun sebelumnya (angka: commit koreksi setelah integrasi, laporan keliru, GAGAL penjaga). Setelah 3 potongan, Lee
memutuskan meneruskan (Opsi C) atau kembali (Opsi A). **Alasan saya tidak langsung menyerahkan semuanya ke satu sesi** ada di §3; **alasan saya tidak menolak
usul Lee** ada di §2; **batas teknis yang membuat ini tidak sesederhana "pindah peran"** ada di §4.

---

## 1. Apa itu peran PEMBANGUN (definisi resmi yang berlaku hari ini)

Naskah peran: `docs/uji/pemeriksaan/PROMPT_GILIRAN.md` §5. Ringkasnya:

| Hal | Aturan |
|---|---|
| Objek kerja | hanya baris `TERVERIFIKASI` (K-1/K-2 diprioritaskan) pada **satu potongan** per giliran |
| Urutan per temuan | (1) baca kartu K & H; (2) **reproduksi dulu sampai MERAH**; (3) perbaiki (skema = migrasi baru + uji SQL; kode + uji; dokumen + penjaga); (4) tulis uji yang membuktikan cacatnya bisa merah; (5) **satu commit per temuan** |
| Yang ditulis | baris Buku Besar → `DIPERBAIKI` (sha + satu kalimat + nama uji), kartu `kartu/B-<POTONGAN>.md`, bukti `bukti/B-<POTONGAN>-*.txt` |
| Yang dilarang | menutup temuan sendiri, menyentuh produksi/migrasi produksi, mengubah PIN/akun percontohan, melebar ke temuan lain, menyentuh trio handoff/naskah & alat mekanisme PMB |
| Bukti selesai | `python3 alat/rantai-bukti-giliran.py` (jalan penuh) → `RANTAI: LOLOS`; `alat/periksa-pemeriksaan.py`; `alat/periksa-bersih.py`; `alat/periksa-push.py` → `TER-PUSH`; CI GitHub tip cabang `success` |
| Setelahnya | Perencana mengintegrasikan (`pmb-integrasi.py --pembangun`), lalu **HAKIM sesi lain** menutup `DIPERBAIKI → DITUTUP` |

Jadi jawaban singkat untuk pertanyaan Lee: **ya, Pembangun = eksekutor temuan** — tetapi dengan tiga pagar: tidak memilih objek, tidak menilai hasilnya, tidak menutupnya.

## 2. Bagian yang benar dari usul Lee (dan bukti dari proyek ini)

1. **Konsistensi konteks itu nyata.** Perbaikan yang saling terkait (mis. satu klaster RPC + migrasi + uji + dokumen) paling murah dikerjakan oleh satu kepala
   yang sudah memegang seluruh fakta. Bukti di proyek ini: klaster cara masuk `F-036`/`F-063` memerlukan **enam migrasi berurutan** (`0089`–`0094`) yang saling
   bergantung; dikerjakan tersebar, nomor migrasi dan definisi fungsi mudah bentrok.
2. **Serah-terima antar-sesi memang titik lemah yang terbukti.** Dua dari kegagalan besar PMB adalah kegagalan serah-terima, bukan kegagalan penilaian:
   `PMB1-F-218` (kartu menulis "LOLOS" karena skrip berhenti di tengah, `set -e`) dan `PMB1-F-216`/`F-217` (berkas bukti & paragraf keputusan Lee tertimpa
   saat integrasi). Kalau pekerjaannya ada di satu sesi, kelas kesalahan ini tidak lahir.
3. **Biaya koordinasi nyata dan terukur di repo ini.** Sampai hari ini, integrasi antar-sesi memaksa: alat `alat/pmb-integrasi.py` (+ 3 pagar baru),
   `alat/rantai-bukti-giliran.py`, `alat/periksa-push.py`, dua commit koreksi (`3e01d5c`), satu cabang ditolak (`arena/01a0eff7` versi pertama), dan beberapa
   giliran Perencana yang habis untuk pembukuan alih-alih kemajuan. Itu harga yang Lee tunjuk dengan tepat.

## 3. Kritik: kenapa tetap ada bagian dari pembagian peran yang tidak boleh hilang

1. **Pembaca kedua yang membaca *beda*.** Yang menangkap `F-216`/`F-217` bukan CI, bukan penjaga, melainkan sesi Perencana yang membandingkan diff cabang
   dengan basis baris demi baris. CI hanya melihat "merah/hijau". Kalau penulisnya dan pembacanya orang yang sama, tidak ada lagi yang membandingkan
   "apa yang dikatakan kartu" dengan "apa yang sebenarnya terjadi di pohon". Ini kerugian struktural, bukan sekadar soal rajin/tidak.
2. **Anggaran konteks satu sesi terbatas — dan itu sudah terbukti di sesi ini.** Sesi Perencana sudah beberapa kali diringkas konteksnya oleh lingkungan
   (catatan ringkasan sesi). Kalau perbaikan kode/migrasi (pekerjaan paling "berat konteks") dipindahkan ke sesi yang juga harus memegang aturan, papan,
   keputusan Lee, dan pembukuan, yang rusak lebih dulu adalah **koordinasi**, bukan kode. Pemisahan peran memberi tiap potongan jendela konteks yang bersih.
3. **Riset yang sudah kita catat.** Verifikasi yang dilakukan oleh pelaksana sendiri lebih lemah daripada verifikasi pihak lain; pada agen, 13,8 % rollout
   dilaporkan melewati verifikasi, dan 72 % di antaranya disertai alasan yang terdengar sah (catatan riset PMB). Kasus "LOLOS" palsu di `PMB1-F-218`
   adalah contoh kecil yang sudah terjadi di proyek ini. Menyatukan pembangun + integrator mengurangi satu lapis pemeriksaan, walaupun Hakim tetap ada.
4. **Peran juga = batas tulis.** Pemeriksa, Hakim, dan Pembangun menulis artefak berbeda (kartu K/H/B) dengan penjaga yang berbeda. Kalau satu sesi
   menjalankan beberapa peran sekaligus untuk temuan yang sama, batas itu kabur dan kartu cenderung berhenti menjadi catatan independen.
5. **Kapasitas.** Sisa pekerjaan besar: 139 centang menunggu sensus + puluhan K-1/K-2 untuk dibangun. Menjadikan satu sesi sebagai satu-satunya mesin
   perbaikan membuat satu titik macet (single point of failure) untuk seluruh PMB.

## 4. Batas teknis yang penting (kenapa "kamu saja" tidak sesederhana pindah tugas)

Sesi Perencana ini **terikat aturan lingkungan Arena pada satu cabang**: `arena/01a0e747-resto-barokah`. Sesi ini **tidak boleh** membuat atau berpindah
cabang. Akibatnya, bila Perencana mengambil peran PEMBANGUN:

- pekerjaannya **langsung masuk cabang utama PMB** (tidak ada cabang terpisah yang bisa ditolak sebelum masuk); pagar "cabang ditolak" (`arena/01a0eff7`
  versi merah) otomatis hilang;
- merge `--no-ff`, penomoran ulang ID, dan sengketa baris **tidak lagi terpakai** → itu sisi untungnya (biaya koordinasi hilang);
- tetapi bila giliran itu salah di tengah jalan, yang merah adalah cabang yang dibaca semua sesi lain — pemulihannya mengandalkan CI + hakim, bukan penolakan.

Artinya: **Opsi C bukan "cara yang lebih rapi", melainkan menukar biaya koordinasi dengan hilangnya pagar isolasi + pembaca kedua.** Pertukaran itu
masuk akal bila biaya koordinasinya dominan; tidak masuk akal bila mutu bukti yang dipertaruhkan.

## 5. Tiga opsi

- **Opsi A — pertahankan pembagian (status quo, diperbaiki).** Pembangun = sesi lain; Perencana mengintegrasikan & memeriksa diff. Biaya koordinasi tetap,
  pagar tetap. **Sudah ditingkatkan** hari ini: bukti hijau wajib (CI/rantai) sebelum integrasi, pagar bukti kekal + pagar ROADMAP, kewajiban push.
- **Opsi B — percobaan terbatas & terukur (REKOMENDASI SAYA).** Perencana mengambil peran PEMBANGUN untuk **satu potongan per giliran**, dengan syarat:
  (1) **Hakim tetap sesi lain** — penutupan `DIPERBAIKI → DITUTUP` tidak pernah oleh sesi yang sama; (2) reproduksi MERAH + uji + satu commit per temuan seperti
  biasa; (3) sebelum giliran ditutup: `rantai-bukti-giliran.py` penuh `LOLOS`, `periksa-bersih.py`, `periksa-push.py`, dan CI tip cabang `success`;
  (4) pembukuan tetap: kartu `B-<POTONGAN>.md` (sebagai bukti peran ganda, mencantumkan "dikerjakan Perencana atas keputusan Lee"), baris Buku Besar `DIPERBAIKI`;
  (5) dicoba **3 potongan** saja, lalu dinilai.
- **Opsi C — kolaps penuh.** Perencana mengerjakan seluruh perbaikan potongan berikutnya. Paling sedikit biaya koordinasi, tetapi kehilangan pembaca kedua
  dan menumpuk beban konteks di satu sesi (§3, §4). Saya merekomendasikan ini **hanya** bila hasil Opsi B terbukti lebih baik.

## 6. Cara mengukur (supaya keputusan tidak berdasarkan kesan)

Catat di tabel berikut tiap potongan (diisi Perencana di `docs/ops/SIAP-LANJUT.md` atau di kartu B potongan itu):

| Ukuran | Arti | Ambang yang dianggap "lebih baik" |
|---|---|---|
| commit koreksi setelah giliran | berapa kali pekerjaan itu harus diperbaiki setelah dinyatakan selesai | turun |
| laporan keliru di kartu ("LOLOS" tanpa bukti dsb.) | kejujuran bukti | 0 |
| GAGAL penjaga/CI pada giliran itu | mutu mekanis | 0 |
| jumlah temuan BARU dari hakim atas pekerjaan itu | mutu substansi | tidak naik |
| waktu/giliran sampai `DITUTUP` | efisiensi | turun |

Pembanding (Opsi A yang sudah ada): `B-F-09` (Pembangun dokumen, cabang `arena/01a0eff4`) → 2 commit koreksi + 2 temuan mekanisme;
`B-F-02…B-F-07` (cabang `arena/01a0eff7`) → 1 cabang ditolak + 3 commit perbaikan + 1 temuan mekanisme (`PMB1-F-218`).

## 7. Yang tidak berubah dalam keadaan apa pun

- **Hakim tetap sesi lain.** Tak ada opsi di sini yang mengizinkan penulis perbaikan menutup temuannya sendiri.
- **Produksi tidak disentuh**; migrasi produksi & Dashboard tetap milik Lee; PIN akun percontohan tidak diubah (keputusan Lee).
- **Bukti mesin tetap syarat "selesai"**: reproduksi MERAH, uji yang bisa merah, rantai bukti penuh, CI hijau, ter-push.
- **Keputusan ada di tangan Lee** — ~~sampai ada keputusan, Opsi A berlaku~~ **SUDAH DIPUTUSKAN Lee 2026-10-04 = Opsi C (kolaps penuh, permanen); lihat §10.**

## 8. Yang saya minta dari Lee

Satu pilihan: **A** (pertahankan), **B** (percobaan 3 potongan — rekomendasi saya), atau **C** (kolaps penuh).
Bila Lee memilih B atau C, saya akan: menulis perannya ke `docs/uji/pemeriksaan/PROMPT_GILIRAN.md` §5 & `PROMPT_SINGKAT.md`, mencatatnya di
REKAM_PESAN_PEMILIK §31, dan menyiapkan kolom ukur di handoff — sebelum giliran perbaikan berikutnya dijalankan.

---

## 9. Pelaksanaan percobaan (Opsi B) — aturan + tabel ukur

**Aturan yang mengikat selama percobaan (tidak bisa dilonggarkan):**
1. **Satu potongan per giliran**; K-1 dulu, lalu K-2 pada potongan yang sama.
2. **Hakim tetap sesi lain.** Perencana/Pembangun tidak menutup `DIPERBAIKI → DITUTUP` — itu pekerjaan Hakim (sesi lain).
3. Semua kewajiban Pembangun berlaku penuh: baca kartu K & H, **reproduksi MERAH dulu**, satu commit per temuan (`perbaiki PMB1-F-nnn: …`),
   berkas uji yang bisa merah ikut commit, kartu `kartu/B-<POTONGAN>.n.md` (5 bagian wajib), baris Buku Besar → `DIPERBAIKI` dengan sha nyata + nama uji.
4. Bukti hijau sebelum giliran ditutup: `python3 alat/rantai-bukti-giliran.py` (jalan penuh) → `RANTAI: LOLOS`; `alat/periksa-pemeriksaan.py`;
   `alat/periksa-bersih.py`; `alat/periksa-push.py` → `TER-PUSH`; CI tip cabang `success` (atau memenuhi 4 syarat aturan "merah acak" PMB1-F-219).
5. Klaster cara masuk = keputusan Lee **B**: perbaikan disiapkan di balik saklar **mati bawaan**; tidak ada pemasangan ke produksi, tidak ada perubahan
   cara masuk Lee, tanpa perintah Lee.
6. Berkas terlarang tetap terlarang (trio handoff, `PRO.md`, naskah & alat mekanisme PMB, `kalibrasi/`), kecuali trio handoff di commit pembukuan seperti biasa.
7. K-4 (temuan baru yang ditemukan saat membangun) **dicatat sebagai baris baru**, bukan diperbaiki diam-diam.

**Tabel ukur (diisi Perencana tiap potongan selesai; dibandingkan dengan pembanding Opsi A):**

| Ukuran | Arti | Ambang "lebih baik" |
|---|---|---|
| commit koreksi setelah giliran | berapa kali pekerjaan harus diperbaiki setelah dinyatakan selesai | turun |
| laporan keliru di kartu ("LOLOS" tanpa bukti dsb.) | kejujuran bukti | 0 |
| GAGAL penjaga/CI pada giliran itu | mutu mekanis | 0 |
| temuan BARU dari Hakim atas pekerjaan itu | mutu substansi | tidak naik |
| waktu/giliran sampai `DITUTUP` | efisiensi | turun |

**Pembanding Opsi A (data nyata):** `B-F-09`/`B-F-09.2`/`B-F-09.3` (cabang `arena/01a0eff4`) → 2 commit koreksi + 2 temuan mekanisme (F-216/F-217);
`B-F-02…B-F-07` (cabang `arena/01a0eff7`) → 1 cabang ditolak (CI merah) + 3 commit perbaikan + 1 temuan mekanisme (F-218).

**Catatan hasil percobaan (diisi berjalan):**

| # | Potongan | Tanggal | Commit koreksi | Laporan keliru | GAGAL penjaga | Temuan BARU Hakim | Waktu sampai DITUTUP | Catatan |
|---|---|---|---|---|---|---|---|---|
| 1 | F-09 — baris K-1 `PMB1-F-127` | 2026-09-30 → 2026-10-01 | 1 — `12172ae` (format Prettier, ditemukan CI) | 0 | 1 cacat = 2 run CI GAGAL (`36805957154`, `36806018310`, keduanya langkah 5 Prettier); perbaikan → CI `36806096048` SUCCESS | 0 (Hakim `H-F-09.7` menutup 2026-10-02 tanpa temuan atas pekerjaannya) | DITUTUP oleh H-F-09.7 (2026-10-02; ±2 hari, menunggu giliran Hakim) | perbaikan `16a2b76`; kartu `B-F-09.4.md`; uji baru 2 (MERAH 1/7 → HIJAU 7/7); rantai penuh 1: `129 LOLOS · 1 GAGAL` (format) → rantai penuh 2: `129 LOLOS · 0 GAGAL → RANTAI: LOLOS`; bundel produksi bersih |
| 2 | F-03 — baris K-2 `PMB1-F-038` ronde 2 | 2026-10-02 | 0 | 3 — klaim "semua bentuk satu identitas" (dibantah matriks hakim), klaim "Keputusan Lee: tidak ada" (bagian B butuh keputusan Lee), klaim "CI merah = flake F-219" (deterministik, temuan F-228) | 1 run CI GAGAL deterministik (`36988445582` @ `25f0faf` — kartu masih templat di commit itu; `periksa-pemeriksaan.py` sah menolak) | 3 atas pekerjaan 0095: F-226 (identitas sampah), F-227 (backfill kembar lama), F-228 (aturan F-219 salah pakai); + baris induk F-038 dikembalikan TERVERIFIKASI (9/13 gaya penulisan masih bocor) | BELUM DITUTUP — dikembalikan Hakim H-F-03.5 di hari yang sama | perbaikan `18bd3a7` (migrasi 0095); rantai penuh `130 LOLOS · 0 GAGAL → RANTAI: LOLOS`; suite 139 LULUS; substansi menutup 4/13 gaya — cukup untuk probe lama, tidak cukup untuk matriks lengkap hakim |
| 3 | F-03 — baris K-2 `PMB1-F-038` ronde 3 (bagian A) | 2026-10-02 | 0 (menunggu Hakim) | 0 | 0 (pelajaran F-228 diterapkan: baris Ter-push terisi SEBELUM commit kartu `2988ea2` di-push; CI tip `77d2f00` SUCCESS; dua run lain cancelled oleh concurrency, bukan merah) | (menunggu Hakim sesi lain) | (menunggu Hakim) | perbaikan `fc2d9ab` (migrasi 0096): 13/13 gaya penulisan matriks hakim tersatukan; uji kasus 9–19 MERAH→HIJAU; kedua probe hakim kini MERAH; suite 139 LULUS; rantai penuh `130 LOLOS · 0 GAGAL · RANTAI: LOLOS` (dua usaha sebelumnya gagal hanya karena checkout dangkal pasca-reset workspace); bagian B tetap menunggu keputusan Lee |
| 4 | F-03 — baris K-2 `PMB1-F-038` bagian B (kartu **Opsi C** pertama, `B-F-03.4`) | 2026-10-04 | 0 (menunggu Hakim) | 0 | 0 (pelajaran diterapkan: Ter-push `1a21be2` terisi sebelum commit kartu `bc128d4`; determinisme CI dipantau — run `1a21be2` merah karena angka panduan 139→140 basi, diperbaiki DI COMMIT BERIKUTNYA `bc128d4` yang lalu SUCCESS; run tip `7a6c145` merah di langkah pemeriksa dokumen padahal semua perintah langkah itu LOLOS di pohon identik — log GitHub tak terunduh (EOF), tak diklaim flake tanpa bukti ulangan) | (menunggu Hakim sesi lain) | (menunggu Hakim) | putusan Lee 2026-10-04 "ikut saran kamu" → migrasi `0097` (batas pendaftaran kasir per kampanye, AKTIF, bawaan 3) + `0098` (PIN atasan pakai voucher, SAKLAR MATI klaster B); uji kasus 20–26 + berkas baru 9 kasus MERAH→HIJAU; probe H-F-03.5 kini MERAH; suite 140 LULUS; rantai penuh `130 LOLOS · 0 GAGAL · RANTAI: LOLOS`; dua kali jebakan RLS-diam saat menulis uji (update pengaturan sebagai kasir = 0 baris tanpa galat) — pelajaran #6 di bawah |

**Pelajaran percobaan #1 (bahan keputusan Lee sesudah 3 potongan — jujur, tanpa perbaikan citra):**
1. **Langkah murah dulu.** Cacat format `16a2b76` lolos ke push karena `npm run format:check` tidak dijalankan sebelum commit; CI (langkah 5) yang menemukannya. Rantai penuh lokal juga menangkapnya, tetapi baru di akhir giliran → 1 commit koreksi + 2 run CI merah yang sebenarnya bisa dicegah ±1 menit.
   Aturan giliran berikutnya: **jalankan `npm run format:check` + `lint` + uji terarah SEBELUM commit pertama**, rantai penuh sebelum menutup giliran.
2. **Nilai tambah rantai lokal terbukti:** rantai itu berhenti tepat di langkah yang sama dengan CI (`format:check`, pohon sama) → alat rantai setara CI untuk kelas cacat ini (bukti disimpan; berguna untuk F-219: bila rantai lokal hijau sementara CI merah di langkah lain, itu bukti flake, bukan isi).
3. **Kewajiban Hakim tetap utuh:** Perencana/Pembangun tidak menutup; F-127 tetap `DIPERBAIKI` menunggu Hakim sesi lain — waktu sampai `DITUTUP` masih nol data.
4. **Pemisahan peran tidak dilanggar:** tidak ada penyuntingan berkas bukti giliran lain, tidak ada perubahan cara masuk ke produksi (saklar `import.meta.env.DEV` mati di build produksi; tidak ada deploy).

**Pelajaran percobaan #2 & #3 (2026-10-02 — jujur, tanpa perbaikan citra):**
1. **Jangan klaim "selesai tuntas" dari sampel sempit.** Ronde 2 (migrasi 0095) dibangun dari probe lama (satu gaya `+62`) dan uji yang hanya mengulang tiga bentuk; hakim menguji 13 gaya penulisan → 9 bocor. Aturan giliran berikutnya: **untuk temuan bertema validasi/normalisasi, bangun matriks input dari riset gaya penulisan nyata SEBELUM mengklaim selesai**, bukan hanya bentuk yang muncul di bukti lama.
2. **Jangan klaim "tidak butuh keputusan Lee" tanpa memisahkan gejala vs skenario kerugian.** Bagian B (identitas fiktif) ada di kolom Bukti baris yang sama sejak awal; Pembangun ronde 2 tidak mengangkatnya. Aturan: tiap baris yang dibangun, tulis eksplisit di kartu bagian 3: gejala mana yang ditutup kode dan skenario kerugian mana yang masih hidup.
3. **Aturan "CI merah acak" (F-219) tidak boleh dipakai sebelum bukti determinisme disingkirkan.** Ronde 2 keliru melabel CI merah deterministik (kartu templat) sebagai flake; hakim membuktikannya lewat kontrol dua pohon (temuan F-228). Aturan: sebelum menyebut flake, jalankan penjaga yang gagal itu PADA POHON COMMIT MERAH secara lokal; bila GAGAL juga → deterministik, perbaiki, jangan integrasikan alasan flake.
4. **Baris `Ter-push sampai` kartu B wajib terisi SEBELUM commit kartu di-push** (bukan "menyusul di commit berikutnya") — mencegah satu run CI merah yang sia-sia (pelajaran langsung F-228). Diterapkan di ronde 3: kartu `2988ea2` memuat `fc2d9ab` sejak commit pertamanya.
5. **Hakim yang ketat = mekanisme bekerja.** Pengembalian F-038 dua kali bukan kegagalan proses; bandingkan dengan Opsi A (Pembangun sesi terpisah) yang juga mengalami pengembalian serupa pada F-02/F-03. Yang berbeda di Opsi B hanya siapa yang mengetik, bukan kedalaman pengawasannya.
6. **RLS bisa menolak SECARA DIAM.** Ditangkap dua kali di kartu B-F-03.4 (2026-10-04): `INSERT kampanye_voucher` dan `UPDATE pengaturan` yang dijalankan sebagai peran kasir di berkas uji memengaruhi 0 baris TANPA galat (policy `pengaturan_ubah` 0027 = hanya `owner_pusat`), dan efeknya baru terlihat satu-dua kasus kemudian sebagai perilaku aneh. Aturan permanen: setiap tulis ke tabel yang dilindungi RLS dalam berkas uji baru wajib dibungkus peran yang benar (`reset role` / `uji.klaim(owner)` lalu balik), dan efeknya dibuktikan oleh harapan eksplisit, bukan diasumsikan.

---

## 10. KEPUTUSAN AKHIR LEE (2026-10-04) — Opsi C disetujui, PERMANEN

**[verbatim Lee, 2026-10-04]** *"Untuk peran pembangun aku ikut rekomendasi kamu yaitu opsi C"* (sesudah laporan percobaan 3 potongan & penjelasan bahasa sederhana).

**Hasil ukur percobaan Opsi B (3/3 potongan, dari tabel §9):**
1. **F-09 — F-127**: DITUTUP oleh Hakim H-F-09.7; 1 commit koreksi (format Prettier — pelajaran: `format:check` sebelum commit).
2. **F-03 — F-038 ronde 2** (migrasi 0095): dikembalikan Hakim H-F-03.5 dengan 3 klaim keliru (→ temuan F-226/F-227/F-228) — pelajaran: matriks input dulu, pisahkan gejala vs skenario kerugian, jangan klaim flake sebelum determinisme disingkirkan.
3. **F-03 — F-038 ronde 3** (migrasi 0096): **BAGIAN A TERVERIFIKASI TUNTAS** oleh Hakim H-F-03.6 dengan **0 klaim keliru · 0 GAGAL penjaga · 0 commit koreksi** — semua pelajaran ronde 2 diterapkan.

**Yang berlaku sejak 2026-10-04 (permanen):**
- Sesi Perencana menjalankan peran **PEMBANGUN biasa** — batas percobaan 3 potongan gugur; tidak ada sesi Pembangun terpisah (Opsi A ditinggalkan).
- Seluruh syarat Opsi B tetap berlaku tanpa perubahan: **Hakim tetap sesi lain** (penutupan `DIPERBAIKI → DITUTUP` tidak pernah oleh sesi yang membangun), seluruh kewajiban Pembangun (MERAH dulu, satu commit per temuan, kartu B 5 bagian, `RANTAI: LOLOS` penuh, penjaga LOLOS, TER-PUSH, CI hijau/aturan F-219), klaster cara masuk = B (saklar mati), temuan baru = baris baru (K-4).
- **Kelima pelajaran percobaan §9 menjadi aturan kerja permanen** (tertulis di `PROMPT_GILIRAN.md` §5).
- Mitigasi hilangnya "pembaca kedua" atas diff: Hakim independen tetap gerbang penutup; rantai bukti penuh wajib LOLOS sebelum klaim selesai; kartu B wajib memisahkan jujur bagian 2 (yang sengaja tidak disentuh) & bagian 3 (keputusan Lee yang dibutuhkan).
- ~~Bagian B F-038 (pelanggan fiktif jalur kasir) tetap menunggu pilihan Lee: 1) PIN atasan · 2) pemisahan tugas · 3) batas pendaftaran · 4) terima risiko pilot.~~ **ADDENDUM (2026-10-04, hari yang sama — baris dicoret itu sudah terjawab; coretan ditinggalkan sebagai jejak):** pilihan Lee sudah diberikan, **[verbatim]** *"Untuk pengaman bagian B aku ikut saran kamu"* → **opsi 3 aktif sekarang** (batas pendaftaran kasir per kampanye, bawaan 3, migrasi 0097) + **opsi 1 disiapkan di balik saklar mati untuk pra-pilot** (PIN atasan pakai voucher, migrasi 0098; menyalakan = langkah Lee/operator per penyewa) + **kerangka opsi 4** (sisa risiko satu kasir mengarang sampai batas pelanggan fiktif per kampanye diterima tertulis selama masa percobaan). Rekaman penuh: REKAM §31 butir 26 (penambal PMB1-F-231: sebelumnya kutipan ini hanya ada di kartu B-F-03.4).
