# REKAM PESAN PEMILIK — sumber kebenaran permintaan Lee

**Kenapa berkas ini ada:** permintaan Lee 2026-09-17 — *"sepertinya sebaiknya kamu simpan dulu chat ini supaya bener-bener semuanya tersepon, setelah itu baru hapus lagi."*
Chat bisa hilang (sesi ditutup, konteks penuh, platform berubah). Berkas ini menyimpan **permintaan Lee secara verbatim**
sejauh tercatat, dan **keputusan yang lahir dari permintaan itu**, supaya tidak ada satu pun yang terlewat di sesi berikutnya.

**Aturan pemakaian berkas ini (untuk agent sesi berikutnya):**
1. Baca berkas ini **sebelum** mengubah aturan kerja/keamanan/mekanisme apa pun — ini suara pemilik, bukan usulan agent.
2. Kutipan ditandai **[verbatim]** = kata-kata Lee apa adanya (jangan diubah). **[ringkas]** = ringkasan agent atas permintaan yang tercatat.
3. Permintaan yang **belum tuntas** wajib ada di tabel "Status permintaan" di bawah dan ditampilkan saat sesi dibuka.
4. Berkas ini **tidak boleh dihapus** meskipun chat asalnya dihapus. Tambahkan pesan baru sebagai bagian baru, jangan menimpa yang lama.

**Cara Lee menyebut dirinya:** **Lee**. Agent **tidak boleh** memanggilnya "Bapak" (aturan 2026-09-17).

---

## 1. Status permintaan (semua pesan yang pernah disampaikan)

| # | Tanggal | Inti permintaan | Status | Bukti / berkas |
|---|---|---|---|---|
| 1 | 2026-09-15/16 | Bangun aplikasi resto dari ide mentah; sistem 6 dokumen fondasi; Roadmap detail; mode maraton | ✅ selesai & dipakai | `docs/DISCOVERY.md`, `docs/PRD.md`, `docs/TECH_SPEC.md`, `docs/ROADMAP.md` |
| 2 | 2026-09-16 | Maksimalkan desain (font, layout, jarak, shadow, glow, transisi, laman mengambang, blur) | ✅ dikerjakan (ronde 3 v3 "KERAJINAN") | `docs/desain/RENCANA_DESAIN_UI.md` §7–§8 |
| 3 | 2026-09-16 **[verbatim]** *"Aku ga bisa liat preview"* | Pratinjau yang dijadikan bukti harus benar-benar bisa dibuka | ✅ diperbaiki & dijaga | `aplikasi/alat/pratinjau.sh` (T0-04) |
| 4 | 2026-09-16 **[verbatim]** *"Lanjut"* | Setuju lanjut batch berikutnya | ✅ | LOG_SESI 2026-09-16 |
| 5 | 2026-09-16 **[verbatim]** *"Apakah mungkin klo aku tunda dulu dan kamu lanjut dulu maraton? Aku lagi sibuk."* | T0-00 (akun) ditunda; maraton lanjut | ✅ dipakai: akun ditunda, kode jalan | `docs/TERTANGGUH.md` T0-00 |
| 6 | 2026-09-16 **[verbatim]** *"Lanjutkan maraton. Ingat, klo maraton akan menimbulkan buruknya kualitas, jangan lanjut."* | Kualitas di atas kecepatan; berhenti di batas bersih bila mutu tak bisa dijaga | ✅ jadi aturan tetap | `PANDUAN_PENGGUNA.md` Bagian B |
| 7 | 2026-09-17 **[verbatim]** *"kita belum diskusi soal keamanan dengan sempurna ya? … jangan lanjut sebelum matangkan dulu"* | Matangkan keamanan login per peran + kelengkapan fitur/layar/tombol SEBELUM lanjut; jangan langsung meng-iya-kan; riset; maksimalkan skill | ✅ dikerjakan penuh | `docs/KEAMANAN.md`, `docs/SPESIFIKASI_UI.md`, `docs/teknis/BUKU_INSIDEN.md`, TECH_SPEC ART-11…ART-15 |
| 8 | 2026-09-17 | PIN hanya di perangkat terdaftar; kode pendaftaran admin + persetujuan pemilik; satu akun satu peran; TOTP; mode dukungan berbatas waktu; **[verbatim]** *"setuju semua"* | ✅ ditetapkan | `docs/KEAMANAN.md` §3–§6 |
| 9 | 2026-09-17 | Kode perangkat oleh owner pusat + admin cabang; semua peran wajib perangkat; **[verbatim]** *"Itu harus dipikirkan"* (perangkat hilang); jam aktif diatur owner; region Singapore; notifikasi email + aplikasi; **[verbatim]** *"Harus tanyakan dulu ke aku… kasih tau dan jelasin alasan nya dengan bahasa yang mudah aku pahami. Dan kemudian itu harus tercatat."* | ✅ ditetapkan (tangga pemulihan) | `docs/KEAMANAN.md` §4b, ROADMAP T1-23…T1-30 |
| 10 | 2026-09-17 **[verbatim]** *"setuju seperti rancangan"* · *"aku minta saran kamu"* | Tangga pemulihan disetujui; penyimpanan kode → 2 amplop tersegel; hanya owner pusat boleh pakai | ✅ ditetapkan | `docs/KEAMANAN.md` §4b |
| 11 | 2026-09-17 **[verbatim]** (lihat §2 di bawah) | Tanam **mekanisme audit/pemeriksaan/review independen** yang teliti & terukur; jelaskan caranya di panduan pengguna; **nilai dulu idenya** | ✅ ditanam (AUD-0…AUD-3) + dinilai bagus dengan 3 koreksi | `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md`, `alat/audit-independen.py` |
| 12 | 2026-09-17 **[verbatim]** *"sekarang aku mau audit dulu"* + *"bener-bener menyeluruh… termasuk file2 yang disiapkan untuk pengguna"* + *"satu file untuk pengguna yang betul-betul isinya lengkap… semacam manual book"* + gerbang **`tahan_semua`** | Audit dulu sebelum kerja ulang; lingkup menyeluruh termasuk berkas pengguna; satu buku induk lengkap; K-1 & K-2 menahan fase | ✅ mekanisme diperluas + buku induk dibuat (**diperbaiki lagi** di putaran 5, lihat §4) | `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §2b, `PANDUAN_PENGGUNA.md` |
| 13 | 2026-09-17 (putaran 5) | Lihat **§4** — 7 permintaan baru | ✅ semuanya dikerjakan (P1–P7) | bukti di §3 di bawah |
| 16 | 2026-09-19 (putaran 18c) | Lihat **§16** — permintaan **mode bimbingan** (respon cepat saat dipandu) + laporan bahwa rahasia Cloudflare sudah dipasang | ✅ dipakai | `PANDUAN_PENGGUNA.md` alur **AL-14**; `docs/AGENT_OPERATING_GUIDE.md` §14; `PROFIL_PENGGUNA.md` |
| 15 | 2026-09-19 (putaran 18) | Lihat **§15** — akun Supabase/Resend/Cloudflare dibuat + nilai non-rahasia diisi di repo; izin menghapus bahan kalibrasi lama | ✅ dipakai | `docs/ops/DAFTAR_KUNCI_PEMILIK_NONSECRET.md` (commit `bd68685`); butir `T-018` ditutup |
| 14 | 2026-09-17 (putaran 7) | Lihat **§9** — "pastikan semua permintaanku sudah dikerjakan" + bantuan tiap laman + Buku Uji Pemilik bertahap (juga ditampilkan di chat) | 🟡 **diverifikasi**: 6 cacat ketertelusuran ditemukan & diperbaiki; 6 temuan audit masih terbuka (bertugas) · 2 permintaan baru dijadwalkan (`T1-42`, `T1-43`) | `docs/teknis/REKAM_PESAN_PEMILIK.md` §9 · `docs/uji/AUDIT_RIWAYAT.md` §1b |

**Bukti P1–P7 (putaran 5):** P1 berkas ini · P2 `alat/audit-independen.py --verifikasi-lingkup` + PROTOKOL §5b + LANGKAH 0 di paket · P3 `PANDUAN_PENGGUNA.md` v2 (12 alur, prompt berlabel, perintah berpenjelasan) + `alat/periksa-panduan.py` diperluas · P4 panggilan Lee (+ PROFIL_PENGGUNA) · P5 `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md` + `alat/review-pr.py` + `docs/uji/PROMPT_REVIEW_PR_INDEPENDEN.md` + `docs/uji/REVIEW_PR_RIWAYAT.md` · P6 dijelaskan di buku Bagian C4/C5 (dua cara memakai; SIAP-TEMPEL = termudah) · P7 dijawab jujur di §6 bawah + `docs/SPESIFIKASI_UI.md` §9 & tugas ROADMAP baru.

---

## 2. Kutipan verbatim yang penting (jangan diubah)

**[verbatim] Pesan audit pertama (2026-09-17):**
> "Aku ga mau lanjut coding dulu. Bahkan sesi coding yang sebelumnya udh sempet kita mulai, klo itu perlu diulang karena
> berkaitan dengan perubahan ini, maka harus diulang. Yang aku mau lakukan dulu untuk saat ini adalah melakukan mekanisme
> audit, pemeriksaan, analisis dan review independen yang sangat teliti dan sangat cerdas. Pastikan agent independen
> betul-betul jeli dan bisa betul-betul menemukan masalah (klo memang ada) dan betul betul melakukan secara sempurna
> tanpa terlewat hal sekecil apapun. Klo ada skill yang bisa mendukung mekanisme ini, pastikan agent independen
> menggunakan nya. Dan klo perlu riset di internet untuk ini, pastikan agent independen melakukan nya. Sekarang kamu harus
> tanamkan mekanisme ini dalam sistem ini, tapi tentunya harus dimatangkan dulu… Aku mau setelah mekanisme ini tertanam,
> di panduan pengguna dijelaskan cara ketika aku mau melakukan ini."
> "Tapi sebelum eksekusi, kamu harus pastikan dulu, apakah ide aku bagus atau tidak. Jika tidak, jangan lakukan."

**[verbatim] Pesan keamanan (2026-09-17) — dasar `docs/KEAMANAN.md`:**
> "Maaf, aku baru terpikir sesuat yang aku rasa ini penting banget. Kita perasaan blm diskusi soal keamanan dengan
> sempurna ya? Perasaan aku kita blm diskusiin tentang mekanisme login terbaik dan teraman untuk setiap role. Kita harus
> pastikan Kasir hanya bisa buka kasir, pelanggan hanya bisa buka bagian nya, dan seterusnya. Ga ada yang dua rangkap
> fungsi. Klo ada satu orang yang punya 2 fungsi, aku rasa sebaiknya dia terdaftar dengan 2 akun. Dan aku rasa kita juga
> harus jadikan bagian-bagian staf itu hanya bisa diakses di perangkat yang udh ditentukan/didaftarkan. Admin ataupun
> admin cabang bisa mengelola itu. Dan kita harus buat login untuk staf itu mudah tapi aman, karena mereka perlu kerja
> satset. Dan kita harus antisipasi jangan sampe perangkat yang lagi dipake seseorang kecuri atau ilang lalu akun nya di
> fungsi tersebut dipake sama orang lain, sehingga misalnya tiba2 ada orang mainin aplikasi kasir nya. Dan mungkin masih
> banyak lagi hal-hal terkait ini dan terkait keamanan secara umum yang harus betul-betul kita matangkan. Aku rasa kita
> ga boleh lanjut sebelum matangkan dulu ini. Dan tentunya aku tau bahwa sangat mungkin ini bakal perlu merombak banyak
> pada docs file-file fondasi, dan bagiku itu ga masalah, justru sangat bagus. Karena memang itu harus tercatat dengan
> baik di situ."
> "Selain soal keamanan, aku rasa kita juga harus rencanakan setiap fitur, fungsi, laman, UI, tombol-tombol, dan lain nya
> secara lebih matang. Karena jujur, aku sebelumnya pernah buat aplikasi dengan cara ini (menggunakan agent AI), hasilnya
> banyak masalah, banyak tombol yang kurang, fungsi yang katanya ada tapi ga bisa dipake, dan banyak lagi masalah lain
> nya, padaha 6 file fondasi udh dirancang sedetail mungkin. Jadi aku rasa kita memang perlu perbaiki dan sempurnakan
> banyak hal di docs file-file fondasi dulu sebelum lanjut. Dan pastinya Roadmap juga akan mengalami banyak perbaikan.
> Mari kita sempurnakan dulu semuanya."
> "Tapi harus jujur aku katakan bahwa yang aku katakan ini semua adalah hanyalah ide ku. Sangat mungkin aku salah. Maka
> aku ga mau kamu langsung meng-iya-kan gitu aja. Harus dengan pemikiran mendalam, riset mendalam, klo ada yang ga cocok
> beri saran yang lebih baik, dan seterusnya. Jadi mari sekarang kita matangkan. Klo perlu kamu bisa lakukan riset
> endalam di internet untuk semua yang diperlukan. Dan kamu juga harus gunakan skill yang kamu punya untuk memaksimalkan
> kinerja. Aku tau di sistem ini terdapat skill yang berfungsi untuk hal-hal terkait perancangan, fitur, fungsi, desai,
> dan sebagainya. Masimalkan itu semua"

---

## 3. Putaran 5 (2026-09-17) — 7 permintaan Lee

| # | Permintaan (ringkas; kutipan verbatim di §4) | Yang dikerjakan |
|---|---|---|
| P1 | **Simpan dulu isi chat ini** ke repo supaya tidak ada yang terlewat, baru kemudian chat boleh dihapus | Berkas ini dibuat + ditunjuk dari buku induk Bagian G + `PROJECT_STATE.md` |
| P2 | **Jelaskan base branch untuk sesi auditor**; usul: mekanisme dibuat **tidak bergantung** pada pilihan base branch, dan pastikan itu masih maksimal | Paket audit mencantumkan branch wajib + "Langkah 0 verifikasi" + alat `--verifikasi-lingkup`; auditor berhenti (bukan salah audit) bila commit tidak cocok |
| P3 | **Buku induk masih banyak kurang & cacat**: cara melakukan audit, cara menindaklanjuti hasil audit, cara pekerjaan lama diulang (baru ada prompt, belum ada panduan langkahnya); tabel perintah mesin tanpa penjelasan fungsi & cara pakai; **dugaan**: ada prompt yang kata-katanya bukan untuk agent tetapi untuk pengguna | Buku induk ditulis ulang (v2) dengan pola tetap per alur: *apa ini · kapan dipakai · langkah Lee · yang agent lakukan · hasil/bukti · prompt (berlabel siapa yang memakai)*; penjaga `alat/periksa-panduan.py` ditambah aturan **setiap blok prompt wajib berlabel** |
| P4 | **Jangan panggil "Bapak"** — panggil **Lee** | Diganti di seluruh berkas untuk pengguna; ditambahkan ke `PROFIL_PENGGUNA.md` sebagai aturan tetap + `docs/AGENT_OPERATING_GUIDE.md` |
| P5 | **Mekanisme audit/review PR independen** — Lee tidak bisa menilai *Files changed*; minta riset dulu: apakah bagus, bagaimana supaya maksimal, bagaimana cara kerja Lee & agent yang terbaik | Riset dijalankan; mekanisme dibuat: `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md` + `alat/review-pr.py` + prompt + laporan + riwayat + kartu keputusan untuk Lee |
| P6 | **Klarifikasi**: di buku ada prompt audit, tapi agent bilang prompt disiapkan di berkas terpisah — mana yang benar? | Dijelaskan di buku Bagian D: dua cara memakai; berkas **SIAP-TEMPEL** dibuat mesin = cara termudah; blok di buku = teks kanonik bila berkas belum ada |
| P7 | **Pertanyaan**: setelah pesan keamanan, apakah hal lain (fitur, fungsi, laman, tombol, desain, gerakan/animasi/perilaku) sudah dimatangkan? Curiga baru keamanan | Jawaban jujur: **belum semua** — baru keamanan (dalam) + mekanisme kelengkapan UI (kontrak/registri/pemeriksa) ; konten per layar & spesifikasi gerakan/perilaku baru **direncanakan**; ditambahkan `docs/SPESIFIKASI_UI.md` §9 (perilaku & gerakan) + tugas ROADMAP agar tidak terlewat |

---

## 4. Kutipan verbatim Putaran 5 (2026-09-17)

> "Chat ku ini panjang. Supaya ga ada satupun yang aku sampein ini terlewat untuk kamu respon, sepertinya sebaiknya kamu
> simpan dulu chat ini supaya bener-bener semuanya tersepon, setelah itu baru hapus lagi."

> "Terkait auditor, kamu ga jelasin aku harus buat sesi baru dengan base branch apa. Apakah dengan base branch main,
> atau dengan base branch sesi ini. Itu harus dijelaskan. Dan klo bisa, aku lebih suka klo mekanisme ini dibuat ga perlu
> nentuin base branch secara presisi, artinya base branch manapun yang aku pilih, agent independen akan tau mana yang
> harus dia audit. Apakah ini mungkin dan akan tetap maksimal? Tolong pastikan dulu."

> "aku udh liat buku panduan pengguna. Aku berterimakasih karena kamu udh membuatnya lebih lengkap. Tapi harus aku
> katakan bahwa isi nya masih banyak kurang dan cacat. Di antara nya adalah banyak hal berkaitan cara tidak kamu
> sertakan di situ. Misalnya cara jika pengguna mau melakukan audit independen (kamu hanya nyediakan prompt tapi ga
> ngasih panduan nya), cara ketika auditor independen udh ngasih hasil (kamu juga cuma ngasih prompt nya), cara ketika
> mau pekerjaan lama diulang (kamu juga cuma tulis prompt nya), ada juga Perintah mesin yang boleh Bapak minta agent
> jalankan (disebut dan ditulis rapi dalam tabel tapi ga dijelasin fungsi dan cara pake nya). Bahkan aku juga merasa
> curiga, aku menduga ada beberapa prompt yang justru isi kata-katanya bukan ditujukan untuk agent, melainkan untuk
> pengguna. Dan masih banyak lagi masalah yang lain. Aku harap kamu baca ulang semuanya dan perbaiki lagi semuanya.
> Pastikan lebih sistematis, lebih mudah dipahami, semua fungsi dan tujuan serta caranya dijelasin dengan bahasa yang
> mudah buat aku pahami."

> "Aku juga bingung, di file buku pedoman itu ada prompt buat lakukan audit independen, tapi kamu bilang bahwa prompt itu
> nanti disiapin nya sama agent di file tersendiri. Mana yang bener? Apakah aku salah paham atau gimana?"

> "aku mau sampein ke kamu bahwa mulai sekarang agent ga boleh sebut aku bapak. Nama aku Lee."

> "apakah mekanisme audit/review independen udh mencakup untuk audit/review PR secara independen juga? Klo belum, aku mau
> buat mekanisme audit/review PR secara independen juga karena aku sendiri ga bisa melakukan review itu (karena aku
> sangat awam, aku bingung ketika liat komparasi file changed dan sebagainya). Tapi gimana menurut kamu? Aku mau kamu
> lakukan riset dulu agar memastikan apakah ini bagus atau tidak dan jika bagus bagaimana agar hasilnya bener2 bagus dan
> maksimal dan bagaimana cara kerja aku dan agent yang terbaik."

> "Tapi kok perasaan setelah aku bilang gitu belum semuanya dimatangkan ya? Perasaan baru keamanan aja yang dimatangkan,
> sedangkan beberapa hal yang aku sebut yang lain nya (seperti fungsi tiap laman, fitur, tombol, desain,
> gerakan/animasi/prilaku, dan sebagainya) aku rasa belum dibahas. Apakah aku aja yang salah paham atau gimana? Tolong
> pastikan"

---

## 5. Aturan tetap yang lahir dari pesan-pesan ini (ringkas untuk agent)

1. Panggil pemilik **Lee**; jangan "Bapak". Bahasa sederhana, tanpa jargon (PROFIL_PENGGUNA).
2. **Kualitas di atas kecepatan**; bila mutu tak bisa dijaga → berhenti di batas bersih.
3. **Delegasi penuh** boleh, **kecuali**: menyimpang dari kata-kata/rancangan Lee → tanya dulu, jelaskan sederhana, catat.
4. **Audit dulu** sebelum pekerjaan ulang/baru bila Lee meminta; gerbang **`tahan_semua`** (K-1 & K-2 menahan fase).
5. **Buku induk** (`PANDUAN_PENGGUNA.md`) wajib diperbarui bersamaan dengan setiap mekanisme/prompt baru — dijaga CI.
6. Auditor/peninjau **tidak boleh** dari sesi yang sama dengan pembangun; hasilnya wajib lolos pemeriksa mesin.
7. Setiap klaim wajib bukti yang bisa dijalankan ulang; cacat dilaporkan jujur, tidak disembunyikan.

---

## 6. Jawaban jujur atas P7 (apakah semua sudah dimatangkan?)

**Tidak semua — dan ini rinciannya apa adanya** (jawaban lengkap disampaikan di chat):

| Hal yang Lee sebut | Status sebenarnya | Bukti |
|---|---|---|
| Mekanisme login teraman per peran | ✅ **matang** | `docs/KEAMANAN.md` · TECH_SPEC ART-11…ART-15 · Fase 1B (T1-23…T1-30) |
| Perangkat terdaftar, PIN di perangkat, perangkat hilang | ✅ **matang** (termasuk tangga pemulihan 4 tingkat) | `docs/KEAMANAN.md` §3–§6 · migrasi 0011–0016b · `docs/teknis/BUKU_INSIDEN.md` §2–§5 |
| Kelengkapan tombol/fungsi/layar (mekanisme-nya) | ✅ **matang mekanismenya** (kontrak layar + registri aksi + pemeriksa + uji komponen + naskah jalan) | `docs/SPESIFIKASI_UI.md` §1–§8 · Fase 1C (T1-31…T1-35) |
| **Isi** setiap laman (daftar tombol & aksi per layar) | 🟡 **belum diisi** — dikerjakan per layar di Fase 1C (T1-31/T1-32) lalu diperluas tiap fase UI | `docs/PETA_UI.md` (rencana) + table kontrak layar |
| Desain visual (10 tema, font, bayangan, glow, kaca, laman mengambang) | ✅ **matang** (v3 "KERAJINAN", prototipe + papan bukti) | `docs/desain/RENCANA_DESAIN_UI.md` §7–§8 |
| **Gerakan/animasi & perilaku** (feedback tombol, transisi, notifikasi, keadaan memuat) | 🟡 **aturan dasar sudah ada, spesifikasi rincinya baru dibuat** di `docs/SPESIFIKASI_UI.md` §9 | ditambahkan putaran ini |
| Roadmap diperbaiki menyeluruh | 🟡 sebagian: bertambah 151 → **186 tugas**, tetapi **penyempurnaan menyeluruh baru terjadi setelah audit AUD-3** (temuan audit bisa menambah/mengubah tugas) | `docs/ROADMAP.md` |

**Kesimpulan:** pesan Lee ke-14 memang baru menuntaskan **keamanan** + **mekanisme** kelengkapan & desain; **isi** (daftar tombol per layar, spesifikasi gerakan/perilaku) dan **penyempurnaan roadmap** masih berjalan dan itu memang rencana sesudah audit.

---

## 7. Putaran 6 (2026-09-17) — laporan 3 sesi audit & temuan "memenuhi syarat"

**Kata Lee:**
- *"Aku udh menjalankan prompt docs/uji/paket-audit/AUD-3-2026-09-17-SIAP-TEMPEL.md. Bahkan aku menjalankan nya di 3 sesi agent sekaligus… Selanjutnya apa yang harus aku lakukan? Gimana caranya supaya kamu tau hasil dari audit… Apakah ada yang harus aku masukkan/laporkan? Atau kamu bisa cek sendiri…?"*
- *"Tadi salah satu sesi bilang begini: 'Saya baca dulu aturan pemeriksa laporan supaya laporannya memenuhi syarat tanpa melebih-lebihkan cakupan.' Aku merasa janggal. Aku rasa seharusnya jika memang ada yang perlu dilaporkan maka seharusnya itu tetap dilaporkan biarpun tidak masuk dalam cakupan yang diminta."*

**Jawaban & tindakan agent:**
1. **Jalur pulang laporan** (celah nyata: protokol menyuruh auditor menulis laporan, tetapi tidak pernah menjelaskan bagaimana laporan itu kembali ke sesi kerja) → alat baru `--ambil-laporan` di kedua alat (audit & review PR) + §5c di protokol audit + §6b di protokol review PR + langkah push di kedua prompt kanonik + buku (AL-5, AL-7, Bagian E).
2. **Lee benar soal "memenuhi syarat"** → aturan anti-teater dikunci: ambang minimum = **lantai, bukan target**; **temuan di luar cakupan wajib dilaporkan** (bagian 8 baru di kedua kontrak laporan); **dilarang menyusun laporan agar lolos pemeriksa**; mesin menandai laporan yang berhenti tepat di ambang sebagai CATATAN.
3. **Dua laporan lama tidak ada** di cabang mana pun saat diperiksa (`git ls-remote` → hanya cabang sesi lama 15–16 Sep) → karena itu jalur pulang dibuat wajib di prompt, bukan opsional.

## §10. Putaran 8 (2026-09-17) — laporan cacat tampilan, lembar kunci, cara menjalankan perintah

| # | Permintaan/kata Lee (ringkas) | Jawaban & tindakan agent |
|---|---|---|
| 1 | *"Kamu bilang kamu bakal nyiapin 10 theme kan? Tapi kok aku cuma liat ada 5 theme doang?"* | **10 tema memang ada di kode** dan tombolnya berbunyi "Ganti tema (10)"; yang kurang: panel tidak memberi petunjuk daftar bisa digeser dan bisa terpotong di layar kecil. Diperbaiki: keterangan jumlah + cara menggeser. |
| 2 | *"tombol 'Nyaman' dan 'Padat' … waktu aku klik dan switch ga ada efek apa apa. Pastikan berfungsi."* | **Benar, dan itu cacat nyata**: aturan kerapatan hanya menyasar kelas prototipe yang tidak dipakai aplikasi. Diperbaiki di **sumber desain** (prototipe) lalu disalin ke aplikasi + penjaga `aplikasi/alat/periksa-kerapatan.py` (4 uji mutasi) + 5 uji interaksi + 6 uji kaskade angka (`aplikasi/src/gaya/kerapatan-css.test.ts`). |
| 3 | *"Terkait Jawab Butir Tunggu. aku kurang paham. Bahkan aku juga ngerasa ga nemu baris P-02."* | Baris itu ada di Bagian 1 `docs/uji/BUKU_UJI_PEMILIK.md`; judulnya dibuat lebih jelas + langkahnya kini cukup bilang `Tampilkan butir tunggu.` di chat. |
| 4 | Lembar isian untuk hal yang harus dikumpulkan, **termasuk kunci rahasia** (risiko sudah diperhitungkan: data percobaan, rotasi sebelum rilis, repo privat) | Formulir `docs/ops/DAFTAR_KUNCI_PEMILIK.template.md` (ikut Git, kosong) → disalin jadi berkas kerja terisi bernama DAFTAR_KUNCI_PEMILIK.local.md (tidak ikut Git) + penjaga `alat/periksa-rahasia.py`. Aturan tetap: nilai rahasia **tidak lewat chat**. |
| 5 | *"Aku ga paham gimana caranya"* (menjalankan perintah) | Lee tidak perlu terminal: cukup bilang `Uji semuanya.` / `Uji database.` di chat; agent menjalankan dan **menempelkan hasilnya**. Langkah U-02/U-03 di Buku Uji diubah mengikuti ini. |
| 6 | *"Review PR masih sedang berjalan."* | Ditunggu; paket putaran8 (`7e8c0b9`) tetap berlaku untuk sesi yang sedang berjalan — pekerjaan sesudahnya akan masuk putaran berikutnya setelah laporan masuk. |

## §9. Putaran 7 (2026-09-17) — "pastikan semua permintaanku sudah dikerjakan" + dua permintaan baru

**Kata Lee (verbatim, diringkas):** *"Semua yang aku minta matangkan sebelumnya udh belum? Tolong pastikan dulu.
Kamu kan menyimpan chat aku yang panjang itu. Pastikan itu bukan cuma disimpan, tapi juga dibaca."* —
lalu dua permintaan baru: **(a)** bantuan/panduan di **setiap laman** supaya pengguna tidak perlu mengingat sosialisasi;
**(b)** **buku panduan uji** untuk Lee: berisi apa yang harus dicoba, langkah lengkap bahasa sederhana, tempat mengisi
"sudah/belum & bagaimana hasilnya", **ditulis bertahap mengikuti jalannya proyek**, dan **juga ditampilkan di chat**;
hal yang harus Lee **lakukan** (mis. penyiapan Supabase) diperlakukan sama. Lee juga minta **dikritisi** bila idenya kurang tepat.

### 9a. Hasil verifikasi (dijalankan 2026-09-17, bukan mengandalkan centang lama)

Diperiksa: berkas fondasi · keamanan (§3–§6 `docs/KEAMANAN.md`) · darurat (Buku Insiden) · desain · bahasa ·
alat audit/review · buku induk · daftar tunggu · rujukan · lingkungan CI. **Cara:** jalankan pemeriksa + cek berkas + greps.

| Temuan verifikasi | Sifat | Tindakan |
|---|---|---|
| Rujukan mati di dokumen pengikat **3 berkas** (Buku Insiden menyuruh alat denyut yang tidak ada & berkas catatan pemulihan; KEAMANAN §10 menyebut pemeriksa rantai audit) | cacat nyata | diperbaiki (ditandai rencana + tugasnya) + penjaga baru `alat/periksa-rujukan.py` (uji-diri 2 mutasi) |
| Daftar temuan audit **gelondongan**: 27 temuan laporan (A: 10 · B: 17) tidak semuanya berstatus; beberapa id tertukar | cacat ketertelusuran | `docs/uji/AUDIT_RIWAYAT.md` §1b ditulis per temuan (21 baris; 15 ditutup · 6 terbuka) + penjaga `alat/periksa-temuan-audit.py` |
| Klaim bukti `T0-01` "31 berkas huruf pindah" tidak bisa direproduksi | klaim tanpa bukti | klaim dicabut, diganti angka terhitung (57 berkas `.woff2`) + perintah hitungnya |
| `docs/SPESIFIKASI_UI.md` menyebut `alat/peta-ui.py` seolah sudah ada | klaim tanpa bukti | ditandai rencana + tugas `T1-33` |
| Kerentanan dependency dev 5 (1 kritis) & CI tidak memeriksa | cacat nyata | vitest → 5.0.1 (0 kerentanan) + langkah `npm audit --audit-level=low` di CI |
| Penjaga buku induk ambang longgar (10 dari 12 alur) & tanpa uji-diri | cacat nyata | `MIN_ALUR = 12` + `--uji-diri` (3 mutasi) + langkah CI |
| Akun/proyek Supabase (`T0-00`) **tidak tercatat** di daftar tunggu, padahal diketahui menunggu Lee | cacat ketertelusuran | dicatat sebagai `T-018` + ditandai ❓ di ROADMAP |

**Masih terbuka (jujur, ada pemiliknya):** A-F-07 (kontrol keamanan → `T1-24`…`T1-30`) · B-F-09/B-F-16/B-F-17
(mekanisme paket audit → `T1-44`) · B-F-11 (lapis perangkat → `T1-24`) · B-F-14 (sapuan isolasi → `T1-22`).

### 9b. Tanggapan atas dua permintaan baru (dikritisi, bukan langsung di-iya-kan)

- **Bantuan di setiap laman — bagus, tapi ada syaratnya.** Bantuan yang ditulis terpisah dari kode akan **basi**.
  Karena itu teks bantuan dibuat **satu sumber dengan registri aksi** (T1-32) dan dijaga pemeriksa: aksi/layar tanpa bantuan → CI GAGAL.
  Batas panjang: 1–2 kalimat + maksimal 5 langkah + "kalau macet" + "siapa yang boleh". Bantuan **tidak** menggantikan pelatihan;
  ia menggantikan **mengingat**.
- **Buku Uji Pemilik — bagus dan justru menutup lubang maraton.** Risiko yang harus ditahan: (1) buku jadi daftar raksasa yang
  tak diisi → satu baris = satu hal, maksimal 5 langkah, peta cepat + penanda "sejak kapan menunggu"; (2) buku dianggap
  pengganti uji mesin → ditulis tegas di kepala buku: **uji mesin tetap di CI**; buku ini hanya untuk yang butuh mata manusia;
  (3) dokumen dan chat bisa berbeda → aturan: **dokumen = sumber kebenaran, chat = ringkasan baris baru** di batch yang sama.
  Tambahan dari agent: kolom **bukti** (tautan/tangkapan layar) dan kolom **"yang seharusnya terjadi"** wajib ada —
  tanpa itu, "sudah saya coba" tidak bisa dinilai.
- **Kejujuran penting:** sampai layar pertama ada, isi buku uji untuk Lee masih **sedikit** (database tidak bisa diuji manusia
  dengan mata). Agent **tidak akan mengarang baris** supaya buku terlihat penuh.
- Keduanya masuk ROADMAP: **T1-42** (bantuan) · **T1-43** (Buku Uji Pemilik + pemeriksa + gema chat).

## §14. Putaran 12 (2026-09-17) — tiga keluhan pratinjau (Padat · panel tema · ujung gulir) + tanya sesi

**Kata Lee:** *"blok blok nya hanya berkurang panjang nya aja, tapi lebar (atas-bawah) nya ga ikut mengecil"* ·
*"Kamu kan punya skill-skill. Kamu harus maksimalkan skill skill itu. Atau klo kamu ga menemukan itu di skill-skill kamu, kamu harus pelajari ilmu desain dan visual dari internet **dan simpan hasil yang kamu pelajari itu untuk menjadi kemampuan. Dan ingat, jangan hanya disimpan, tapi juga harus digunakan sebagai kemampuan**"* ·
*"(panel Ganti tema) harus bisa ditutup dengan Esc / klik di luar… coba pelajari bagaimana umumnya aplikasi-aplikasi lain"* ·
*"ujung nya itu kayak nabrak gitu… semacam blur/feather"* · *"menurut kamu apa yang terbaik buat sesi ini? ditutup aja dan buka sesi baru? atau gimana?"*

**Catatan jujur lebih dulu:** tiga gambar yang Lee kirim **tidak sampai ke ruang kerja saya** (folder unggahan tidak ada di sandbox — sama seperti gambar
pertama pada putaran sebelumnya). Karena itu pemahaman saya saya tulis ulang dengan kata-kata sendiri di bawah, dan saya minta Lee mengoreksi kalau ada yang meleset.

| # | Keluhan | Akar masalah (bukan selera) | Perbaikan | Bukti |
|---|---|---|---|---|
| 1 | Mode **Padat** hanya memendekkan kiri-kanan | Benar: yang dulu dipadatkan hanya `padding` mendatar; **tinggi blok tidak pernah turun**, jadi proporsinya aneh. Riset sistem desain besar: kerapatan = **tinggi −4 px per langkah**, jarak kiri-kanan **tidak** dikurangi, huruf **tidak** dikecilkan, sasaran sentuh dijaga | Token dipisah **per sumbu**: `--tinggi-kendali` 48→44 px · `--tinggi-baris-tema` 56→48 px · `--pad-v-blok` 20→12 px · `--baris-isi` 1,55→1,42; `--pad-h-*` **dikunci sama** dengan mode Nyaman | uji kaskade nyata `aplikasi/src/gaya/kerapatan-css.test.ts` (11 uji) + `periksa-kerapatan.py` |
| 2 | *"maksimalkan skill… kalau tidak ada, pelajari dari internet dan **simpan sebagai kemampuan**"* | Ilmu itu belum ada di `skills/` — jadi dipelajari, lalu **disimpan** dan **dipakai** | Berkas kemampuan baru `skills/desain-antarmuka/SKILL.md` (3 pelajaran: kerapatan, penutupan panel, tepi gulir) — **wajib dibaca** di fase DESAIN (`alat/mulai-sesi.py`) dan dijaga pemeriksa | `python3 aplikasi/alat/periksa-antarmuka.py` (10 uji-diri) |
| 3 | Panel "Ganti tema" hanya bisa ditutup dengan mengklik tombolnya lagi | Panel memakai `<details>/<summary>` bawaan peramban — memang **tidak** menutup saat Esc. Kebiasaan aplikasi lain (WAI-ARIA APG): **Esc menutup + fokus pulang**, klik di luar menutup, fokus keluar menutup, `aria-expanded`/`aria-controls` | Komponen baru `aplikasi/src/komponen/PemilihRingkas.tsx` + aturan sama di sumber desain `prototipe/js/ui.js`; sisa aturan `<details>` lama dibuang | 8 uji komponen + `periksa-antarmuka.py` |
| 4 | Ujung daftar gulir "nabrak" tepi | Benar, dan ada namanya: *scroll fade*. Maska pudar dipasang di elemen yang **menggeser** (bukan wadah ber-bordir, kalau salah justru bordirnya yang luntur) dan pudarnya **mengikuti posisi gulir**, dengan cadangan untuk peramban lama | `.picker-panel` (wadah) dipisah dari `.picker-daftar` (penggeser + `mask-image` + `@keyframes pudar-gulir` + `animation-timeline: scroll(self block)`) | uji "daftar tema punya JEJAK PUDAR" + `periksa-antarmuka.py` |
| 5 | *"apa yang terbaik buat sesi ini?"* | Dijawab di chat (bukan di berkas): isi sesi ini **ditutup di batas bersih dulu** (commit + CI hijau + paket review), lalu buka sesi baru yang mulai dari review + Fase 1B | — | jawaban di chat + `LOG_SESI_2026-09-17.md` |

**Pelajaran yang saya simpan (dan akan saya pakai lagi, bukan hanya dicatat):** kalau Lee bilang sesuatu "kelihatan kurang pas", tersangka pertamanya
bukan selera — **sembilan dari sepuluh** kali itu pola yang sudah punya nama & aturan di dunia desain. Cara cepat menemukannya: cari istilahnya
("*density scale*", "*disclosure pattern*", "*scroll fade*"), baca 2–3 sumber, ambil angka konkretnya, lalu **kunci dengan pemeriksa** supaya tidak luntur.

## §13. Putaran 11b (2026-09-17) — "Apakah laporannya sudah dipush?" → 3 laporan lengkap masuk

**Kata Lee:** *"Aku katakan ke setiap hakim begini: 'Apakah laporan hasil review nya sudah dipush? Jika blm, lakukan push'."* — lalu ia menempelkan jawaban ketiga sesi.

**Hasilnya:** sesi pertama (hakim 1) ternyata punya **laporan penuh 390 baris dengan verdict TIDAK-BERSIH dan 4 temuan**, dan laporan itu
**menimpa** berkas bernama sama milik sesi lain (79 baris, BERSIH). Jadi putaran review ini benar-benar menghasilkan 3 laporan:

| Sesi | Berkas | Baris | Verdict | Temuan |
|---|---|---|---|---|
| Hakim 3 (pertama sampai) | `…__01a0b093-pendek-tertimpa.md` | 79 | BERSIH | 0 |
| Hakim 2 | `…__01a0b093-reviewer.md` | 127 | BERSIH-DENGAN-CATATAN | 2 (1 nyata, 1 palsu) |
| **Hakim 1** | `…__01a0b093.md` | **390** | **TIDAK-BERSIH** | **4 (semuanya nyata)** |

**Yang saya kerjakan (bantah-balik wajib — tidak mempercayai laporan):** keempat temuan hakim 1 saya uji ulang dengan probe SQL sendiri, dan
**keempatnya terbukti hidup**:

| Temuan | Inti (bahasa awam) | Bukti probe | Perbaikan |
|---|---|---|---|
| PR-01 (K-2, uang) | Kasir bisa mencatat "diskon voucher" sampai 100% nota **tanpa voucher apa pun** — batas diskon manual 25.000 dilewati hanya dengan mengganti jenis | Diskon manual 54.000 ditolak; nilai yang sama berlabel `voucher` **tercatat** | Diskon voucher **ditutup** (gagal-aman) sampai mesin voucher benar-benar ada; uji + mutasi baru |
| PR-02 (K-3, status) | Pesanan bisa **lahir** langsung berstatus "batal" (tanpa jejak pembatalan) atau "lunas" (tanpa pembayaran) | Insert `batal` diterima tanpa satu pun baris pembatalan | Pesanan dari perangkat wajib lahir `draf`; uji + 2 mutasi baru |
| PR-03 (K-3, jejak) | Nilai kerugian pembatalan **bisa dikarang**: pesanan 54.000 dicatat rugi 1 rupiah | Kerugian 1 rupiah diterima | Nilai kerugian dihitung peladen; angka klien yang berbeda ditolak |
| PR-04 (K-4, dokumen) | Dokumen menulis "21 berkas uji" padahal sudah 28 | Angka tidak cocok dengan isi folder | Angka disegarkan + pemeriksa baru yang menolak angka basi |

**Kenapa ini kabar baik, bukan kabar buruk.** Dua sesi bilang "bersih", satu sesi menemukan 4 cacat nyata — dan yang menemukan itu **hakim 1**,
sesi yang mengerjakan paling dalam (390 baris, memeriksa hal-hal yang tidak dilihat sesi lain: mencoba **menyalahgunakan** jalur uang lewat
SQL langsung, bukan membaca kode saja). Artinya mekanisme review-nya bekerja: sesi yang lebih tekun menghasilkan temuan yang lebih keras,
dan sesi kerja **tidak** boleh serta-merta mempercayai verdict mana pun.

**Catatan mekanisme yang jujur:** ketiga sesi memakai penanda sesi yang sama (`01a0b093` = nama cabang), sehingga laporan penuh menimpa
laporan pendek. Penarik laporan (`--ambil-laporan`) menyelamatkan versi yang tertimpa, dan prompt peninjau sekarang mewajibkan
memeriksa daftar berkas dulu + memakai pembeda unik.

**Arti bagi Lee:** PR #1 tetap **jangan di-merge dulu**. Empat temuan sudah ditutup, tetapi penutupnya (migrasi `0013`, 3 uji baru, 4 mutasi
baru, gerbang CI) belum pernah dilihat peninjau — kalau nanti mau merge, saya siapkan paket review baru untuk tip tersebut.

## §12. Putaran 11 (2026-09-17) — review PR dijalankan Lee (3 sesi, satu cabang)

**Kata Lee:** *"review udh selesai, aku menjalankan review PR nya di 3 sesi sekaligus. Namun 3 sesi itu melakukan nya di satu branch yang sama, yaitu arena/01a0b093-resto-barokah. Silahkan mulai periksa hasilnya."*

**Yang masuk:** 2 laporan dari cabang `arena/01a0b093-resto-barokah` (ditarik lewat `python3 alat/review-pr.py --ambil-laporan`):
`LAPORAN_2026-09-17_pr-01-putaran11__01a0b093.md` (verdict **BERSIH**) dan `LAPORAN_2026-09-17_pr-01-putaran11__01a0b093-reviewer.md`
(verdict **BERSIH-DENGAN-CATATAN**, 2 temuan). Keduanya **LOLOS kontrak** pemeriksa, keduanya mengikat commit `750889a`
(paket `PKT-2026-09-17-pr-01-putaran11.md` seperti yang dibaca). Kalibrasi: **4 dari 4 cacat ditemukan · 0 temuan palsu** (dua sesi).

**Hasil bantah-balik (aturan protokol §6a — sesi kerja WAJIB menguji ulang temuan, bukan mempercayainya):**

| Temuan | Hasil uji ulang | Tindakan |
|---|---|---|
| **PR-01**: "CI tidak menjalankan 28 tes SQL, hanya `--daftar`" | **PALSU.** `--daftar` hanya menambah cetakan daftar; seluruh berkas uji tetap dijalankan. Dibuktikan dengan menyisipkan uji yang sengaja dirusak → `uji: 27 LULUS · 1 GAGAL`, exit 1 | Dicatat sebagai temuan palsu (`REVIEW_PR_RIWAYAT.md` §2b). Akarnya nama opsi yang menjebak → langkah CI diganti perintah penuh, nama langkah "Uji SQL penuh", komentar `alat/uji-sql.mjs` diperjelas, dan lahir penjaga baru `alat/periksa-gerbang-ci.py` (gerbang CI tidak boleh hilang/dilemahkan) |
| **PR-02**: "penjaga buku uji lebih longgar dari klaim" | **BENAR.** Sebelumnya: menghapus petunjuk paket dari U-04 → pemeriksa tetap LOLOS | Diperbaiki: penjaga menilai **baris petunjuk paket** dan menolak bila tidak menunjuk paket; uji-diri kini 5 mutasi |

**Temuan luar-cakupan peninjau** (wajib dilaporkan, aturan §8): `owner_pusat` & `pilih_cabang` → diverifikasi **bukan cacat hari ini**
(policy owner tidak memakai `cabang_saya()`; `boleh()` punya jalur khusus owner) — sisa pertanyaan produknya dicatat; salinan tanpa `.git`;
dan cakupan harness mutasi → semuanya masuk daftar tunggal sebagai `L-09`, `L-10`, `L-11`.

**Yang belum selesai (jujur):** sesi peninjau **ke-3** belum mengirim laporannya ke cabang itu. Lee cukup meminta sesi itu push berkasnya
(nama berkas wajib memakai penanda sesi), lalu bilang lagi "Laporan review sudah masuk, periksa" — penarik laporan akan mengambilnya.

**Catatan kejujuran untuk Lee:** verdict "BERSIH"/"BERSIH-DENGAN-CATATAN" datang dari peninjau, bukan dari saya; saya tetap **tidak**
menyarankan merge sekarang, karena setelah review tip sudah bergerak (perbaikan PR-02 + penguatan CI) sehingga pemeriksaan sebaiknya
dilakukan pada tip yang baru bila Lee mau keputusan merge — dan keputusan itu tetap milik Lee.

## §11. Putaran 10 (2026-09-17) — pesan ke-28 & ke-29

**Kata Lee (verbatim, diringkas):**
- *"tombol-tombol buat pilih theme nya malah kepotong begini (lihat image-1.png), dan munculnya malah ke arah yang bikin dia kepotong"* → panel tidak boleh terpotong.
- *"kamu hanya memperkecil jarak, tapi ukuran blok-blok nya ga disesuain… ukuran tulisan memang ga usah dikecilin, tapi ukuran blok tulisan tersebut perlu disesuaikan… Gunakan semua skill-skill itu dengan maksimal."*
- *"tolong baca hasilnya. Dan aku rasa sebaiknya kita ga usah merge dulu."* (3 laporan sesi peninjau)
- *"Uji semuanya" / "Uji database" itu apa? Apakah itu mekanisme yang kamu tanam, atau gimana? Kalau iya, siapkan "Uji semuanya" dan siapkan "Uji database".*
- *"Kenapa kamu berhenti? Lanjutkan"* (pesan ke-29)

**Jawaban & tindakan agent:**

| # | Permintaan | Jawaban & tindakan | Bukti |
|---|---|---|---|
| 1 | Panel pilih tema terpotong | Cacat nyata: panel dibuka di dalam wadah ber-`overflow` sehingga terpotong saat tombol ada di dekat tepi; perbaikan: panel diposisikan agar **tidak pernah** terpotong (di dalam batas layar, bisa digulir bila tinggi terbatas) + uji warna/desain diperluas | commit `597cc77`; uji 13 warna/desain hijau |
| 2 | Mode **Padat** "kurang rapih" | Cacat nyata: yang dulu dikecilkan hanya **jarak**, sedangkan **ukuran blok** tetap → tampak sesak tak beraturan. Kini token Padat mengecilkan **padding + radius blok + tinggi baris** pada kelas aplikasi, **ukuran tulisan tidak diubah**; dijaga `aplikasi/alat/periksa-kerapatan.py` (wajib menyasar ≥3 kelas aplikasi, 4 uji mutasi merah) | commit `597cc77`; `periksa-kerapatan` LOLOS |
| 3 | Baca 3 laporan peninjau + **jangan merge** | Dibaca seluruhnya (28·9·20, 11·9·11, 40·9·9 baris; ketiganya **LOLOS kontrak** + verdict **TIDAK-BERSIH**). Semua temuan lapis-database ditutup migrasi `0012` + 7 uji baru; dokumen menyesatkan dikoreksi; temuan mekanisme dikerjakan. **PR #1 tetap TIDAK di-merge** dan Lee tetap pemegang keputusan merge | `docs/uji/review-pr/LAPORAN_2026-09-17_pr-01-putaran8__*.md`; `REVIEW_PR_RIWAYAT.md` baris 4 |
| 4 | *"Uji semuanya"/"Uji database" — mekanisme tanam atau bukan?* | **Jujur: itu kalimat pemicu biasa, bukan mekanisme rahasia.** Tidak ada pemeriksa yang mencari kata itu. Yang dijaga mesin adalah **isinya**: `bash aplikasi/alat/periksa-semua.sh` dan `bash alat/uji-database.sh` harus jalan dan hijau — keduanya diperiksa penjaga `periksa-struktur.py` + langkah CI | `PANDUAN_PENGGUNA.md` Bagian E + catatan kejujuran |
| 5 | *"siapkan Uji semuanya & Uji database"* | Diartikan sebagai **perintahnya harus bisa dijalankan apa adanya di salinan baru** (temuan PR-07). Dulu: `periksa-semua.sh` mati di `prettier: not found` sebelum sempat memasang pustaka; `node alat/uji-sql.mjs` gagal tanpa `alat/node_modules`. Sekarang keduanya **memasang pustakanya sendiri** (`npm ci`) dan ada pembungkus `alat/uji-database.sh` | commit `1102e12`; bukti salinan baru: `uji: 28 LULUS · 0 GAGAL` · `HASIL: LOLOS` · `RINGKASAN: 166 lolos, 0 gagal` · `SEMUA PEMERIKSAAN LOLOS.` |
| 6 | *"Kenapa kamu berhenti? Lanjutkan"* | Penyebabnya **galat alat sesaat** (salah `cwd` sebelum direktori ada), bukan masalah proyek; pekerjaan diteruskan di sesi yang sama sampai batas bersih. Aturan baru ditulis supaya tidak terulang: §13 butir 10 `AGENT_OPERATING_GUIDE.md` | commit menyesuaikan; log sesi |

**Catatan kejujuran yang penting untuk Lee:** "Uji semuanya"/"Uji database" **tidak** menambah pemeriksaan baru dengan sendirinya —
kalimat itu hanya memanggil pemeriksa yang sudah ada. Supaya kalimat itu benar-benar terjaga, yang ditambah adalah **penjaga atas perintah-perintahnya**
(PR-07) dan **langkah CI** yang menjalankannya di tiap push. Jadi janjinya: *selama CI hijau, kedua perintah itu memang bisa dijalankan dan memang hijau di salinan baru.*

---

## §8. Putaran 6 (2026-09-17) — bahasa aplikasi

| # | Permintaan (kutipan) | Status |
|---|---|---|
| 1 | *"aku mau aplikasi ini mendukung multi bahasa, termasuk mandarin dan arab. Tapi aku blm tau apakah itu berat di awal atau tidak. Klo sekiranya ada kendala, maka setidaknya untuk versi rilis awal harus mendukung 2 bahasa, yaitu Inggris/english dan Indonesia"* | **DIPUTUSKAN — Opsi 1**: G1 memakai **Indonesia · Inggris · Mandarin**; **Arab** disiapkan kuncinya + tata letak RTL diuji di G1, teksnya G2. Analisis biaya + 3 opsi di `docs/DECISIONS_LOG.md` «Bahasa aplikasi»; tugas **T1-40** & **T1-41** + `docs/SPESIFIKASI_UI.md` **§10** |
| 2 | *(alasan penyampaian)* *"Maaf aku sampaikan ini tidak pada tempat nya"* | Tidak ada masalah — permintaan diterima **sebelum** layar G1 ditulis (Fase 1C belum mulai), jadi justru waktu termurah; tidak ada pekerjaan yang terbuang |

## §9. Putaran 7 (2026-09-18) — putaran13, audit, dan pindah sesi

| # | Permintaan (kutipan) | Status |
|---|---|---|
| 1 | *"Aku buka 4 sesi … semuanya udh selesai. Silahkan lihat hasilnya. Dan karena ada kemungkinan mereka bekerja pada branch yang sama, maka jika kamu merasa tidak menemukan 4, kamu harus periksa dulu, barangkali ada yang tertimpa"* | **SELESAI** — laporan yang tertimpa diselamatkan lebih dulu (`--ambil-laporan`); 7 berkas laporan dibaca penuh; 27 temuan diverifikasi NYATA lalu ditutup migrasi `0014` + 10 uji baru; suite 41/41, mutasi 16/16 & 17/17 MERAH; CI hijau |
| 2 | *"Jadi sekarang apa?"* / *"Aku minta saran terbaik dari kamu"* | **DIJAWAB** — saran bertahap diberikan: (a) tutup sesi dengan handoff bersih, (b) putaran verifikasi (2 chat peninjau) atau lanjut `T1-24`, (c) pratinjau; rekomendasi utama: putaran verifikasi lebih dulu karena dua putaran berturut-turut menemukan cacat nyata |
| 3 | *"apakah mungkin kalo aku lanjut nya di sesi baru? … sesi ini udh kerasa berat (mengambil ram lokal cukup besar)"* | **SELESAI** — lihat #4 |
| 4 | *"aku rasa udh ada juga mekanisme lanjut tanpa hilang konteks sedikitpun bahkan walaupun sesi sebelumnya eror. Tolong pastikan. Klo memang udh ada, tolong beri arahan. Klo blm ada atau blm sempurna, tolong siapkan"* | **SELESAI (diperkuat)** — mekanisme lama (`alat/mulai-sesi.py`, PROJECT_STATE/STATUS/LOG_SESI, `alat/pulihkan-git.sh`) sudah ada tetapi **buta terhadap satu risiko nyata**: sesi baru selalu mulai dari `main` (tertinggal 123 commit) dan tidak ada pemeriksa yang menjamin handoff segar. Ditambahkan: `alat/lanjut-sesi.py` (periksa + `--siapkan` + `--di-ci` + `--uji-diri`), `docs/ops/SIAP-LANJUT.md` (handoff untuk agent), `docs/ops/SIAP-TEMPEL-SESI-BARU.md` (satu berkas siap tempel untuk Lee), alur **AL-13** di buku induk, bagian "Pindah ke chat/sesi baru" di `docs/PANDUAN_PEMILIK.md`, dan baris status handoff di KARTU SESI (`alat/mulai-sesi.py`). Pemeriksa ikut CI & `periksa-semua.sh`; handoff wajib diperbarui di commit terakhir setiap batch (kalau tidak, pemeriksa MENOLAK) |
| 11 | *"apakah hanya dengan kalimat perintah sederhana itu agent manapun akan langsung tau apa yang harus dia lakukan dan file apa aja yang harus dia baca? … aku ingin memastikan itu semua"* + *"Siapkan pindah sesi dan tutup sesi ini dengan baik"* | **DIPERIKSA JUJUR → 4 CELAH NYATA DITUTUP, LALU SESI DITUTUP** — celahnya: (1) Prompt Pembuka tidak menunjuk buku pedoman → item 2d baru; (2) KARTU SESI tidak menunjuk buku → blok `PETUNJUK_PERINTAH` dicetak + dijaga (uji-diri 5 → 7 kasus); (3) kalimat gabungan & sinonim "baik/benar" tidak ada di buku → AL-3/AL-13 + tabel C3; (4) prompt kanonik masih menunjuk berkas pensiun → dibetulkan ke `PROMPT_SESI_BARU.md`. Dijaga `alat/periksa-panduan.py` (+3 topik, +2 mutasi uji-diri terbukti MENOLAK). Sesi ditutup: papan keadaan diperbarui, LOG_SESI CLOSED, handoff + berkas statis disegarkan, ter-push, CI hijau | ✅ diterapkan & sesi ditutup |
| 10 | *"aku ga mau pake sesi itu. Aku mau buka sesi baru. dan aku mau ngelanjutin sesi ini… aku mau prompt buat buka sesi baru tuh dibuat generik… hanya saja aku mau di bagian awal prompt ada bagian semacam place holder buat aku ngarahin agent nya aku mau lanjutin sesi yang mana… Patiin dulu kamu paham, kemudian kritisi, dan klo bagus silahkan terapkan, dan pastikan dimasukkan dalam file panduan pengguna / manual book"* | **DITERAPKAN** — (a) sesi `arena/01a0b4c3-resto-barokah` dicatat **sengaja ditinggalkan** di `docs/ops/SESI_DITINGGALKAN.md` (mesin menolak handoff yang menunjuk ke sana); (b) `PROMPT_SESI_BARU.md` **baru & STATIS** — disimpan sekali, dipakai terus; **satu baris di awal** (`SESI YANG AKU LANJUT:`) diisi Lee; (c) `--siapkan` tidak lagi menulis ulang berkas tempel (`docs/ops/SIAP-TEMPEL-SESI-BARU.md` dipensiunkan jadi penunjuk); (d) penjaga baru + uji-diri 23 → **36 kasus**; (e) masuk buku: `PANDUAN_PENGGUNA.md` AL-13 · `docs/PANDUAN_PEMILIK.md` 2b & 3 · `alat/periksa-panduan.py` +3 topik | ✅ diterapkan |
| 9 | *"Kadang ada sesi yang justru sengaja mau aku tinggalin… aku tentukan di promptnya sesi mana yang mau aku lanjutin"* | **DITERAPKAN + DIPERLUAS** — mekanisme tidak lagi menebak "sesi terakhir": Lee memilih sendiri lewat `python3 alat/lanjut-sesi.py --daftar-sesi` (daftar semua sesi di GitHub + tanggal + jarak dari main) dan `--siapkan --lanjut-dari <cabang>` (pilihan tersimpan di handoff). Penjaga: cabang tujuan wajib ada di GitHub; resep berkas tempel wajib sejalan; berkas tempel wajib menjelaskan hak pilih Lee. Uji-diri 19 → **23 kasus**. Buku: AL-13 +3 butir (pilih sesi; batas sesi belum di-push & sesi lama; satu sesi aktif) + PANDUAN_PEMILIK pertanyaan 2b. Ditemukan: `arena/01a0b4c3-resto-barokah` (sesi baru Lee) sudah di-push & mengerjakan hal serupa → dua garis pekerjaan; pilihan sesi = keputusan Lee |
| 8 | *"Aku udh coba buka sesi dengan prompt yang udh disiapin kamu dan ini respon nya… supaya kamu bisa menilai apakah bener-bener bekerja sesuai harapan atau ngga"* | **DINILAI + DIPERBAIKI** — mekanisme TERBUKTI bekerja (sesi baru mengenali basis salah, menyusul `main`→`51feb34`, melaporkan KARTU SESI, tidak menulis sebelum tujuan dikonfirmasi, memakai bahasa Indonesia). Sesi baru juga jujur menemukan 4 hal; 3 di antaranya cacat mekanisme milik agent dan sudah ditutup: (1) KARTU SESI buta pada status jeda → 1 skill padahal harus 15 + `--uji-diri` 5 kasus + masuk CI; (2) klaim paket "sudah disegarkan" yang basi → diganti baris fakta yang ditulis mesin; (3) PR #1 vs cabang sesi baru tidak dijelaskan → §2c + catatan di berkas siap-tempel. Uji-diri lanjut-sesi 16 → **19 kasus** |
| 7 | *"Kamu ngomong apa? Kamu lupa klo bicara sama aku harus pake bahasa apa?"* | **KOREKSI DITERIMA + DIKUNCI** — agent wajib menjawab Lee dalam **bahasa Indonesia sederhana**; aturan sekarang jadi baris pertama blok Prompt Pembuka (`PROMPT_ENTRI_UNIVERSAL.md` + `PANDUAN_PENGGUNA.md`), dijaga topik wajib `alat/periksa-panduan.py` dan penjaga berkas siap-tempel `alat/lanjut-sesi.py` |
| 6 | *"jadi setiap kali aku mau pindah sesi baru buat lanjutin aku tinggal pake prompt itu di sesi baru tanpa harus atur base branch dan tanpa perlu kirim prompt penutup ke sesi lama dulu ya?"* | **DIJAWAB + MASUK BUKU** — base branch tidak perlu disentuh (dibuat otomatis; hanya dipakai saat PR dibuka); prompt penutup disarankan 1 kalimat tetapi TIDAK wajib (kalau sesi lama mati, boleh langsung pindah); wajib memakai salinan terbaru berkas siap-tempel. Ditulis di `PANDUAN_PENGGUNA.md` AL-13 dan `docs/PANDUAN_PEMILIK.md`, dijaga 4 topik wajib di `alat/periksa-panduan.py` |
| 5 | (Permintaan tetap yang masih berlaku) *"aku ga mau ada cacat sama sekali"* + *"jangan merge dulu"* | **BERLAKU** — PR #1 tetap terbuka; merge hanya keputusan Lee |


---

## §15. Putaran 18 (2026-09-19) — akun dibuat, izin menghapus bahan kalibrasi, lanjut maraton

**Kutipan verbatim (jangan diubah):**

1. *"Aku udh buat supabase, resend, dan cloudflare. Aku juga udh input DAFTAR_KUNCI_PEMILIK_NONSECRET di repo. Klo perlu lanjut silahkan"*
   — artinya: tugas `T0-00` (hanya pemilik yang bisa) **selesai**; agent boleh melanjutkan Fase 0 tanpa menunggu.
   Bukti: commit `bd68685` (berkas `docs/ops/DAFTAR_KUNCI_PEMILIK_NONSECRET.md` — URL proyek, kunci publik, id proyek,
   region Singapura, id akun Cloudflare). Kunci rahasia **tidak** ikut; itu memang aturan yang disepakati.
2. *"Boleh, keluarkan sekarang"* (jawaban atas pertanyaan izin) — izin menghapus bahan kalibrasi lama dari repo
   (`docs/uji/kalibrasi/pr-bahan-2026-09-17.diff`): tindakan tak bisa dibatalkan, karena itu agent berhenti dan bertanya
   lebih dulu. Ditutup sebagai temuan **D F-05** dengan penjaga `alat/periksa-kunci-kalibrasi.py`.

**Yang dikerjakan agent setelah izin itu (ringkas):** F-05 ditutup · PR-10 ditutup (penjaga gerbang CI dua arah, 49 perintah) ·
hari yang sama: `T0-00` + butir tunggu `T-018` ditutup · klien Supabase aman + alat uji sambung (`npm run cek:supabase`,
diuji di CI sebagai **gerbang ke-50**) · `wrangler.toml` + `npm run deploy` siap (menunggu keputusan deploy publik).

**Dua hal yang masih menunggu Lee (ditulis di `docs/TERTANGGUH.md`):** `T-020` (menyebar skema ke proyek Supabase nyata) dan
`T-021` (menaikkan halaman kosong ke Cloudflare).

---

## §16. Putaran 18c (2026-09-19) — mode bimbingan + rahasia Cloudflare sudah dipasang

**Kutipan verbatim (jangan diubah):**

1. *"Secret udh dipasang. Sekarang aku harus apa?"* — Lee menyelesaikan **Langkah B** (rahasia `CLOUDFLARE_API_TOKEN`
   di kotak rahasia GitHub) dan menanyakan langkah berikutnya. Artinya: butir `T-021` tinggal menunggu **izin publik**
   dari Lee; agent **tidak** menjalankan deploy publik tanpa itu (Stop Condition §12).
2. *"klo lagi pembimbingan usahakan respon nya mode respon cepat ya, kecuali klo memang perlu ada hal-hal yang dibaca
   dan diperiksa atau diedit dulu supaya betul maka silahkan lakukan itu. Tapi menurut kamu sendiri gimana sebaiknya?
   Apakah permintaan aku ini tepat atau ngga? Tolong kritisi…"* — Lee meminta **mode bimbingan**, sekaligus meminta agent
   mengkritisi bila permintaannya kurang baik.
3. *"aku mau itu ditanam dalam sistem ini, sehingga ketika aku perlu bimbingan aku tinggal bilang 'Tolong bimbing' atau
   'Mode bimbingan' atau 'Beri arahan step by step' …"* — Lee meminta mekanismenya **ditanam**, bukan sekadar dijanjikan.

**Keputusan agent & kritik yang disampaikan (dijawab apa adanya):**

- Permintaan Lee **tepat** untuk bagian bimbingan: balasan panjang saat Lee sedang memegang layar memang memperlambat
  tanpa menambah mutu. Karena itu ditanam sebagai **alur AL-14** (`PANDUAN_PENGGUNA.md`) + **§14**
  (`docs/AGENT_OPERATING_GUIDE.md`) + catatan di `PROFIL_PENGGUNA.md`, dengan pemicu: `Tolong bimbing.` ·
  `Mode bimbingan.` · `Beri arahan step by step.` · `Aku bingung, pandu aku.`, dan penutup
  `Sudah beres, lanjut normal.`.
- **Batasnya disampaikan lebih dulu (ini bagian kritiknya):** mode bimbingan **hanya memendekkan cara bicara**, bukan
  memotong mutu. Bagian yang menyentuh **Stop Conditions §12** (biaya, keamanan/uang/data, keputusan terkunci,
  tindakan tak bisa dibatalkan seperti **deploy publik**) dan klaim **"selesai"** tetap butuh bukti diperiksa dulu —
  agent keluar dari mode singkat selama bagian itu saja. Alasan: aturan Lee sendiri — *"kalau maraton menimbulkan
  buruknya kualitas, jangan lanjut"*.
- **Yang tidak berubah:** catatan teknis, pemeriksa, dan handoff tetap dikerjakan penuh (di belakang), supaya sesi ini
  tetap bisa dilanjutkan walau balasan ke Lee jadi pendek.

## §17. Putaran 19 (2026-09-20) — mekanisme satu kalimat (AL-15) + aturan penutup pesan

1. *"Aku mau mekanisme review dan audit dan pemeriksaan itu … semua dibuat lebih mudah dikerjakan …
   aku tinggal bilang kata-kata simple … agent kasih aku prompt yang singkat … setelah selesai,
   agent sesi independen otomatis masukin hasilnya ke github … Tolong kritisi dan beri saran terbaik."*
   — disetujui setelah agent menyampaikan kritik & rancangan: *"Baik, aku setuju."*
   **Dikerjakan:** alur **AL-15** + `alat/siapkan-pemeriksaan.py` (commit `cbba401`); dipakai nyata
   pertama kali hari itu juga: *"Siapkan pemeriksaan independen menyeluruh"* → paket
   `AUD-3-2026-09-20` (commit `cfc6097`) + prompt pendek diserahkan ke Lee.

2. *"Tolong setiap menjelaskan sesuatu dan setiap komunikasi sama aku, di akhirnya jelaskan apa
   yang perlu aku lakukan. Misalnya jawab pertanyaan anu, atau lakukan anu, atau periksa anu,
   dan sebagainya. Jadi aku ga ngerasa bingung."*
   — **ATURAN TETAP: SETIAP balasan ke Lee WAJIB ditutup dengan bagian "Langkah Lee"** yang
   menyebut tindakan konkretnya (atau tegas menyatakan "tidak ada — tunggu/lanjut"). Ini berlaku
   untuk semua komunikasi, bukan hanya laporan batch.

3. *"sekarang kan udh jadi public. Berarti harusnya sekarang semua itu lebih dijaga kerahasiaannya. Tapi gimana ya
   dengan riwayatnya? Apakah orang lain bisa akses riwayatnya? Berikan yang terbaik ya"* — tentang email pribadinya
   di repo publik (temuan K F-06). **Dijalankan:** email disamarkan di berkas; riwayat TIDAK ditulis-ulang (destruktif &
   tidak menjamin — cache/fork); Lee diberi tahu jejak lama tetap bisa dibaca orang dan diimbau jaga 2FA.
4. *"sesi auditor yang ketiga terasa lelet… kamu lanjut maraton aja… klo nanti ketiga udah selesai, baca hasilnya dan
   perbaiki semua yang perlu"* — disetujui agent (tidak ada cacat rencana; auditor ketiga terkunci di commit `cbba401`
   sehingga hasilnya tetap sah kapan pun selesai). Maraton lanjut.
5. *"kalo aku mau buka sesi baru … aku cukup hanya bilang kata-kata pendek seperti 'baca pro.md' … agent akan
   otomatis terarahkan untuk baca semua yang harus dia baca … dan setelah itu agent akan langsung tanya apa yang mau
   aku lakukan"* + *"setiap kali aku bilang siapkan pindah sesi, agent harus jelaskan itu (base branch) di bagian
   langkah yang harus aku ambil"* + *"sesi yang sengaja ditinggalkan … klo aku blm pernah bilang begitu sebelumnya,
   maka sesi itu sepertinya tetap perlu ditawarkan"* — **Dijalankan (2026-09-21):** `PRO.md` di root = pintu masuk
   universal (orientasi → tanya Lee → jalankan); kalimat `baca pro.md` dan `mau lanjut sesi` terdaftar di C3 +
   AL-13 `PANDUAN_PENGGUNA.md`; fakta lama "base branch tidak perlu kamu sentuh" DIGANTI fakta baru (base branch =
   cabang sesi selama belum merge ke main; agent WAJIB menyebutnya di Langkah Lee — dijaga
   `alat/periksa-panduan.py`); sesi yang tidak dipilih TIDAK otomatis ditinggalkan (label "tidak aktif");
   status ditinggalkan hanya dari kata Lee; penghapusan cabang hanya atas permintaan eksplisit per cabang,
   selalu dengan tawaran arsip tag lebih dulu. Kebijakan lengkap di header `docs/ops/SESI_DITINGGALKAN.md`.
6. *"Aku mau kita buat mekanisme kerja sama/gotong royong/maraton bersama … satu sesi kerja utama …
   prompt yang pendek saja … siap copy paste … setelah semua sesi selesai kerja, semua otomatis masuk
   github … dia bakal kumpulkan semua hasil kerja nya dan menilai semuanya"* — **Dijalankan (2026-09-21):**
   alur **AL-16 Maraton kerja sama** (satu integrator + ≤4 pekerja per gelombang, lingkup berkas
   EKSKLUSIF, nomor migrasi dicadangkan, panen BERURUTAN dengan baterai penuh tiap merge, OPT-IN via
   `Siapkan maraton kerja sama.`); `docs/ops/PAPAN_TUGAS.md` (penulis tunggal integrator) +
   `PROMPT_PEKERJA_MARATON.md` (pendek, siap tempel) + `alat/periksa-maraton.py` (9 kasus uji-diri,
   gerbang CI) + mode pekerja di `PRO.md` + aturan TERSERAP di pemilihan sesi (menjawab kekhawatiran Lee
   soal daftar menumpuk: kandidat terserap gugur otomatis, tanpa mengarang status ditinggalkan).
   Kritik yang disampaikan ke Lee dan diterima: 10 pekerja → maks 4/gelombang; "otomatis masuk GitHub"
   = cabang pekerja otomatis, cabang resmi TIDAK PERNAH otomatis; panen tidak menunggu semua.
7. *"Aku mau ketika aku bilang siapkan maraton kerja sama, agent akan siapkan semuanya, dan prompt
   untuk setiap sesi nya dikasih di chat nya, bukan hanya di file, supaya aku ga perlu cari file nya.
   Ini harus ditanam juga dalam mekanisme ini."* — **Dijalankan (2026-09-21):** AL-16 di
   `PANDUAN_PENGGUNA.md` kini mewajibkan integrator mengirim TEKS LENGKAP tiap prompt pekerja
   langsung di chat (blok siap salin-tempel, baris pertama terisi); menunjuk berkas saja dinyatakan
   melanggar alur. Header `PROMPT_PEKERJA_MARATON.md` dipertegas sama.

## §18. Putaran 20 (2026-09-21) — panen parsial maraton gelombang 2 + tiga insiden ditanam obatnya

1. *"Lanjut semua … nilai 3 sesi 1 cabang … pastikan semua baik … penyebab pasti + tanamkan mekanisme"*
   — **Dijalankan (2026-09-21):** panen parsial gelombang 2: T-03 DITERIMA (draf privasi `61e739b` +
   poles 1 baris AT-08) · T-02 DITERIMA (DoD benar → 0018 jadi indeks parsial + uji DoD a–e dilengkapi
   integrator dari bukti pekerja) · T-01 jalan (pesan pelindung ditempel via Lee). Tiga insiden ditanam
   obatnya: (i) 3 chat dalam 1 sesi → berbagi cabang (AL-16: 1 pekerja = 1 sesi baru; templat butir 6–7;
   pemeriksa aturan 5); (ii) race edit paralel se-berkas (GUIDE §0 fakta 6); (iii) reset sandbox →
   cek induk pra-push (GUIDE §4).

## §19. Maraton solo Batch-1–4 + putusan setuju-semua (2026-09-21)

1. *"Lanjut"* (×4) — **Dijalankan (2026-09-21):** Batch-1 (B F-16, B F-14, F F-18) · Batch-2 (T1-22, B F-11, D F-08, parsial F F-07/F F-08, F F-12-dipagari) · Batch-3 (F F-13-verifikasi, A F-07-peta, F F-09-tutup, I F-17+T-025) · Batch-4 (PG nyata via pgserver; F F-13 + F F-12 DITUTUP uji 2-koneksi).
2. *"Ya, aku setuju saran terbaik dari kamu."* — **Dijalankan (2026-09-21):** 9 butir → Selesai (T-025=(a) LARANG; T-023=hapus PIN pelanggan; sisanya terima placeholder/usulan); KEAMANAN §10 disegarkan. Tindak lanjut Batch-5: penegak 0022 + goresan PIN + sapu ❓.
3. *"Aku mau lanjut di sesi baru. Siapkan perpindahan sesi."* — **Dijalankan (2026-09-21):** putusan dicatat, handoff disegarkan (`--siapkan`), semua di-commit+push, `lanjut-sesi` LOLOS; blok prompt sesi baru dikirim di chat.

## §20. Batch-5 (2026-09-21) — mandat maraton saat Lee persiapan exam

- **[ringkas]** CI wajib hijau dulu → 0022 penegak T-025(a) + uji → hapus PIN pelanggan di PRD/TECH_SPEC → sapu penanda tertangguh basi → T1-30-sisa bila sempat. Kualitas, bukan kecepatan; jangan ganggu untuk hal yang aman ditunda. Jika batas keamanan/uang/biaya membutuhkan Lee, berhenti di batas aman.
- **Status:** berjalan di `arena/01a0c2c1-resto-barokah`; pemulihan CI dulu. Rekam kerja & tindak lanjut: `_log-sesi/LOG_SESI_2026-09-21_2.md`, `docs/ROADMAP.md`, `docs/ops/SIAP-LANJUT.md`. Tidak ada izin deploy atau merge PR baru.


## §21. Prompt pendek wajib di chat, bukan hanya tautan (2026-09-21)

- **[verbatim]** “Aku cukup copy paste prompt yang hanya beberapa baris tapi agent baru otomatis baca prompt yang panjang … termasuk bahwa dia harus kirim hasilnya ke github.”
- **[verbatim]** “aku udh jalanin prompt yang kamu arahin link nya itu di 3 sesi pemeriksa. Jadi ga perlu siapin prompt pendek nya.”
- **[verbatim]** “Mode kerja lagi seperti biasa. Ya, betul begitu. Sambil menunggu hasil pemeriksaan, tanamkan itu ya”.
- **Pelaksanaan:** perkuat AL-15 + profil + gerbang respons di GUIDE; generator memberi URL immutable, cabang sumber, target, wajib baca semua, gagal-tertutup, larangan ubah kode/merge/main, kewajiban commit/push laporan dan bukti status. Pemeriksa `--periksa-serah` menolak draf yang hanya menampilkan tautan; uji-diri ikut CI yang sudah ada.
- **Batas:** tidak mengklaim mesin bisa membaca chat aktual atau menjamin jaringan/push; agent tetap mengirim blok hasil pemeriksaan. Tidak membuat/mengubah paket AUD-2 aktif, tidak mengganggu tiga sesi pemeriksa, dan tidak mengubah target `09bcb89`.

## §22. Pengiriman otomatis, akses privat, cabang bersama (2026-09-21)

- **[ringkas]** Lee kembali mode kerja normal, meminta kritik lebih dalam, skill/riset internet dan penyelidikan insiden push, bukan menerima solusi integrator antrean begitu saja. Repo privat harus bisa diakses via repo/cabang/SHA paket/path; SHA target berbeda. Semua pemeriksa otomatis commit/push/verifikasi tanpa pengingat lagi; platform dapat memberi cabang yang sama. Prompt pendek wajib di chat untuk penyerahan mendatang, prompt panjang juga memuat kontrak.
- **[ringkas]** Dua laporan sudah tersedia; sesi ketiga error diabaikan. Jangan meminta audit ulang. Ceklist sementara boleh disimpan lalu dihapus setelah ditangani.
- **Pelaksanaan:** `alat/kirim-laporan.py`, kontrak terpusat untuk dua generator, AL-15 + mutasi, uji bare-remote/race di CI. Bukti dan keterbatasan: `docs/uji/PENGIRIMAN_LAPORAN_AMAN.md`. Dua laporan asal disimpan terpisah; temuan belum ditutup, daftar tindak lanjut lintas-sesi lengkap di `docs/uji/TINDAK_LANJUT_AUD2_2026-09-21.md`. Tidak ada izin merge/deploy; paket beku utuh.

## §24. Format Komunikasi Penutup Chat Wajib 3 Bagian (2026-09-22)

- **[verbatim]** “Aku lihat saat ini kamu setiap akhir chat tidak menjelaskan apa yang selanjutnya. Dan itu sering bikin aku bingung. Aku rasa sebaiknya ditanamkan dalam sistem ini bahwa setiap akhir chat, sebelum beritahu apa yang harus aku lakukan, kamu juga harus jelasin terkait posisi kita dan langkah selanjutnya, dijelaskan dengan bahasa yang mudah aku pahami dan sebisa mungkin tanpa bertele-tele (ringkas) kecuali klo memang butuh penjelasan panjang… Ok. Lanjut. Tanamkan itu semua dan lanjutkan maraton”.
- **Pelaksanaan:** Menanamkan aturan format penutup wajib 3 bagian di setiap akhir balasan agent ke Lee:
  1. **📍 Posisi Sekarang:** status posisi roadmap/tugas saat ini & apa yang baru saja selesai.
  2. **⏩ Rencana Selanjutnya (Agent):** langkah konkret berikutnya yang akan dikerjakan agent.
  3. **👉 Langkah Lee:** tindakan nyata yang perlu dilakukan Lee atau penegasan cukup ketik *"Lanjut"*.
- **Batas:** Bukan pembatasan informasi — info penting, risiko, atau pertimbangan tetap disampaikan di badan pesan. Format ini dikunci di `PROFIL_PENGGUNA.md`, `docs/AGENT_OPERATING_GUIDE.md`, `PANDUAN_PENGGUNA.md`, dan `docs/DECISIONS_LOG.md`.

## §25. Peringatan Penyelesaian Fase 7 & Audit Menyeluruh (2026-09-24)

- **[verbatim]** “Lanjut. Dan ingatkan klo fase 7 udah selesai, aku mau melakukan mekanisme pemeriksaan dan audit menyeluruh”
- **Pelaksanaan:** Menjadwalkan pengingat eksplisit kepada Lee tepat saat seluruh tugas Fase 7 selesai (setelah T7-12 tuntas diverifikasi), bahwa Fase 7 telah selesai dan Lee ingin melakukan mekanisme pemeriksaan dan audit menyeluruh. Agent dilarang langsung meloncat ke Fase 8 tanpa jeda dan persetujuan Lee untuk audit tersebut.

## §26. Persiapan Pindah Sesi & Audit Menyeluruh di Sesi Baru (2026-09-24)

- **[verbatim]** “Aku mau pindah sesi dulu. Aku mau lanjut di sesi baru. Aku mau pemeriksaan/audit menyeluruh dilakukan di sesi baru. Aku mau pemeriksaan/audit ini betul betul maksimal dan sempurna. Dan aku mau itu betul betul menyeluruh, bukan hanya pada sistem, keuangan, dan sebagainya. Harus menyeluruh. Harus mencakup UI, UX, Fungsi, Fitur, bahkan fondasi, dan semua yang ada dalam pembangunan aplikasi ini. Siapkan semuanya”
- **Pelaksanaan:** Menyiapkan paket audit menyeluruh AUD-3-2026-09-24 (docs/uji/paket-audit/AUD-3-2026-09-24.md dan docs/uji/paket-audit/AUD-3-2026-09-24-SIAP-TEMPEL.md) yang mencakup seluruh 383 berkas proyek, 193 tugas roadmap, seluruh 10 tema UI, UX aksesibilitas kontras/sentuh, fungsi POS, KDS dapur, kas & shift, transaksi tengah malam, audit log kriptografis SHA-256, RLS multi-tenant, serta 98 berkas SQL + 84 berkas Vitest frontend. Menyiapkan berkas handoff penutup `docs/ops/SIAP-LANJUT.md` dan prompt ringkas terverifikasi untuk disalin Lee ke sesi baru.

## §27. Pembatalan Pindah Sesi & Penugasan Kembali Sesi Utama untuk Evaluasi Hasil Audit 3 Sesi Independen (2026-09-25)

- **[verbatim]** “Aku berubah pikiran. Aku rasa sebaiknya kamu saja yang lanjutkan. Aku tadi udh terlanjur buka sesi baru, tapi aku mau lupakan itu. Aku udh buka 3 sesi agent pemeriksa independen menyeluruh dan mereka udh selesai. Silahkan liat hasilnya”
- **Pelaksanaan:** Sesi kerja ini (`arena/01a0d09b-resto-barokah`) tetap menjadi PEKERJA UTAMA sesuai keputusan Lee. Sesi baru yang sempat dibuka Lee (`arena/01a0d3d7-resto-barokah`) dilupakan/tidak diserap otomatis tanpa izin eksplisit Lee. Ketiga laporan audit independen dari `origin/arena/01a0d3d8-resto-barokah` (Laporan L, M, N) telah ditarik dan diperiksa secara menyeluruh. Ditemukan 15 temuan nyata (L: 9, M: 1, N: 5). Hasil telaah lengkap dipaparkan secara terstruktur, jelas, dan tanpa jargon kepada Lee beserta opsi rencana penanganan langkah demi langkah.

## §28. Persiapan Audit Putaran Kedua (AUD-4) & Jaminan Kesiapan Handoff (2026-09-25)

- **[ringkas]** Lee menginstruksikan dua hal penting: (1) Jaminan handoff total bila sesi sewaktu-waktu terputus/eror — Lee cukup mengatur base branch ke `arena/01a0d09b-resto-barokah` dan mengirim chat *"baca pro.md"* untuk melanjutkan tanpa kehilangan konteks apa pun. (2) Mempersiapkan pemeriksaan menyeluruh putaran kedua (AUD-4) yang jauh lebih dalam, teliti, dan sempurna, dibagi ke beberapa agen pemeriksa independen terfokus (Agent A: Keamanan & Sistem/DB, Agent B: UI & Desain Antarmuka, Agent C: Logika Bisnis / POS / Kasir).
- **Pelaksanaan:** Menyiapkan 4 paket audit independen AUD-4 di `docs/uji/paket-audit/` lengkap dengan format SIAP-TEMPEL dan instruksi eksekusi terisolasi: (i) Master AUD-4 Menyeluruh (409 berkas), (ii) Agent A Keamanan (173 berkas), (iii) Agent B Antarmuka UI/UX (96 berkas), dan (iv) Agent C Bisnis & Kasir POS (191 berkas). Menyegarkan `PRO.md`, `docs/ops/SIAP-LANJUT.md`, `STATUS.md`, dan `PROJECT_STATE.md` agar transisi antar-sesi terjamin mulus dan deterministic.

## §29. Peringatan Penyelesaian Fase 10 & Pemeriksaan Mendalam Menyeluruh (2026-09-26)

- **[verbatim]** “Lanjut. Dan catat dan ingatkan, setelah fase 10 selesai aku mau lakukan pemeriksaan mendalam menyeluruh. Tapi untuk detail nya terkait mekanisme pemeriksaan yang aku inginkan akan aku jelaskan kemudian. Yang penting sekarang catat dulu dan pastikan nanti ingatkan aku”
- **Pelaksanaan:** Menjadwalkan pengingat mutlak kepada Lee tepat setelah tugas terakhir Fase 10 (T10-16) selesai tuntas dan terverifikasi. Agent WAJIB BERHENTI, dilarang langsung melangkah ke Fase 11 atau fase lainnya tanpa instruksi Lee, dan wajib secara eksplisit mengingatkan Lee bahwa Fase 10 telah selesai dan siap untuk mekanisme pemeriksaan mendalam menyeluruh sesuai arahan detail yang akan diberikan Lee kemudian.





