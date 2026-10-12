# KARTU PEMERIKSA — K-<ID>  (salin jadi `kartu/K-<ID>.md`; hapus petunjuk dalam kurung siku)

- **Potongan:** <ID> — <nama potongan persis seperti di PAPAN>
- **Sesi:** <cabang arena/…> · **Model:** <nama model, kalau tahu> · **Tanggal:** <YYYY-MM-DD>
- **Commit basis:** <sha 7 digit yang diperiksa> · **Baseline yang dirujuk:** <tag/commit fondasi, atau "belum ada (Tahap 1)">
- **Lensa dipakai:** <L1…L6 dari PAPAN + tambahan bila perlu>

## 1. Cakupan
[Berkas/baris/alur yang BENAR-BENAR dibaca & dijalankan. Yang dilewati sebutkan dengan alasannya. Bukan "seluruh berkas" tanpa bukti.]

## 2. Klaim yang dicoba dibantah
[Daftar klaim di lingkup ini (janji PRD, DoD ROADMAP, kalimat "sudah diuji", angka) yang kamu coba buktikan SALAH — minimal 5.]

## 3. Serangan / cara memeriksa
[Perintah yang dijalankan, skenario yang dicoba, riset internet yang dilakukan (tautan + tanggal). Untuk dokumen: pertanyaan pemicu
§4a butir 1–5. Untuk kode: §4b butir 1–6. Untuk alur (Menyeluruh): langkah demi langkah dengan bukti tiap langkah.]

## 4. Temuan
[Satu sub-bagian per temuan, ID sama dengan baris Buku Besar (`PMB1-F-xxx`): apa yang salah, di mana (berkas:baris), aturan baseline
yang dilanggar, tingkat K, bukti perintah → hasil, cara mereproduksi. Kalau nihil temuan: tulis apa yang membuatmu yakin — dan ingat
regresi mekanisme lama: potongan "bersih" tanpa serangan tercatat dianggap belum diperiksa.]

## 5. Asumsi
[Asumsi yang ditemukan di lingkup ini → sudah ditambahkan ke `ASUMSI.md` dengan ID `PMB1-A-xxx`. Sebut ID-nya.]

## 6. Tidak bisa diverifikasi
[Hal yang butuh produksi/perangkat/keputusan Lee. Tulis apa yang dibutuhkan dan ke potongan Tahap 7 mana diteruskan.]

## 7. Regresi temuan lama
[ID temuan lama (AUDIT_RIWAYAT §1b / TEMUAN_LUAR_CAKUPAN_REVIEW) yang artefaknya ada di lingkup ini + bukti hari ini bahwa masih tertutup.]

## 8. Angka usaha
- Berkas dibaca: <n> · baris/halaman: <n> · perintah dijalankan: <n> · riset: <n> tautan · waktu kira-kira: <menit>
- Temuan: K-1 <n> · K-2 <n> · K-3 <n> · K-4 <n> · luar cakupan: <n> (dicatat di Buku Besar dengan potongan asal ini)

## 9. Temuan luar cakupan
[Wajib ditulis bila melihat sesuatu di luar lingkup — dicatat juga di Buku Besar; jangan dibiarkan hilang.]

## Sensus klaim (WAJIB untuk potongan Tahap 2 `P-<fase>-xx`; hapus bagian ini untuk potongan lain)
[Semua tugas `[x]` fase ini, satu baris per tugas — cakupan 100 %, bukan sampel. Gerbang tahap 2 menolak tugas `[x]` yang tidak tercatat di sini.]

| Tugas | Bukti yang ada (berkas uji/penjaga; dijalankan hari ini: LULUS/GAGAL) | DoD terpenuhi? | Putusan (BUKTI-SAH / DIBUKA-KEMBALI → PMB1-F-nnn) |
|---|---|---|---|
| T<fase>-01 | … | … | … |
