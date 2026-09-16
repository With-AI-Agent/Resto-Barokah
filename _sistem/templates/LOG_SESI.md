# Log Sesi — YYYY-MM-DD (Template untuk Aplikasi)

> File ini dipelihara SETIAP sesi yang menghasilkan informasi baru — mode normal, bukan darurat. Turunan dari protokol checkpoint meta — self-contained. Alasan kausal: sesi lmarena bisa crash kapan saja, agent baru tidak punya akses chat lama — hanya file yang bertahan.

## Keadaan Sesi (selalu segar — agent baru BACA INI DULU sebelum tanya apa pun)
- **Keadaan:** OPEN / CLOSED (atau `OPEN — dilanjutkan di ...` + “dilanjutkan di mana”)
- **Scope:** fondasi Tahap X / coding Fase Y — Task Z
- **Di mana kita sekarang:** [1-2 kalimat posisi persis]
- **Sudah disepakati:** [poin-poin keputusan/preferensi yang sudah dikunci — near-verbatim user bila penting]
- **Masih terbuka:** [pertanyaan/keputusan yang belum tuntas]
- **Langkah berikutnya:** [1 task paling jelas untuk sesi berikutnya + branch/PR terkait]

## Kronologi (append-only, terbaru di bawah — jangan hapus entri lama)

### YYYY-MM-DD — Peristiwa / Keputusan
- **Konteks:** [apa yang dibahas/dikerjakan]
- **Keputusan/koreksi/preferensi user (near-verbatim):** [...]
- **Proposal agent + dasar:** [...]
- **Kesepakatan/penolakan + alasan:** [...]
- **Fakta/hasil verifikasi:** [commit, test, file path]
- **State kerja:** PROJECT_STATE=..., STATUS=`Pekerjaan belum tersimpan: Tidak ada` @ YYYY-MM-DD — ...
- **Pertanyaan terbuka:** [...]

## Aturan (ringkas)
- Append + update header + `commit & push` segera setelah tiap pertukaran yang menghasilkan informasi baru — filter: catat keputusan/koreksi/kendala/preferensi (near-verbatim), proposal penting + dasar, kesepakatan/penolakan + alasan, fakta terverifikasi, state kerja; JANGAN catat basa-basi/ulang STATUS/LOG/dump chat.
- Penutupan: ubah `OPEN` → `CLOSED` + entri terakhir; sesi tanpa info baru boleh tanpa file.
- Pemulihan crash: sesi baru cari LOG_SESI terbaru `OPEN` (plus `DISKUSI_MENTAH_*.md` lama sebagai arsip) → baca header → laporkan & konfirmasi sebelum lanjut; backstop = `STATUS.md` + `PROJECT_STATE.md` + `git log`; workaround `/download-workspace` bila file terjebak.

## Log Keputusan (file ini)

| Tanggal | Perubahan | Alasan |
|---|---|---|
| YYYY-MM-DD | Template LOG_SESI dibuat untuk aplikasi | W-02 LOG_SESI berkelanjutan — anti-hilang konteks saat sesi crash (fakta platform #3) |
