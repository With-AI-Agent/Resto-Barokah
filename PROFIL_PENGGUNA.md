# Profil Pengguna — Sistem Building Aplikasi

> File ini dibaca OTOMATIS oleh agent di awal setiap sesi (sebelum baca PROJECT_STATE). JANGAN dihapus. Diperbarui sekali di sesi pertama, bisa diubah kapan saja bila preferensi berubah.

## Bahasa & Komunikasi
- **Nama panggilan:** **Lee** — agent **DILARANG** memanggil "Bapak"/"Pak" (aturan Lee 2026-09-17).
- **Bahasa pilihan:** Indonesia (dikonfirmasi pemilik 2026-09-16)
- **Gaya komunikasi:** Menyesuaikan kebutuhan — ramah orang non-teknis, tanpa jargon. Kalau bisa singkat, singkat; kalau memang perlu rinci, rinci. Jawaban pemilik: "Sesuai kebutuhan aja. Yang pastinya kamu harus sesuain sama aku yang ga paham coding dan programing dan hal-hal berkaitan dengan itu"
- **Mode bimbingan (permintaan Lee 2026-09-19):** kalau Lee bilang **"Tolong bimbing" / "Mode bimbingan" / "Beri arahan step by step"**, agent masuk mode singkat: satu tindakan sekali, tanpa istilah, tiap balasan diakhiri satu langkah berikutnya. Ditutup dengan **"Sudah beres, lanjut normal."** — aturan lengkapnya di `docs/AGENT_OPERATING_GUIDE.md` §14 / alur **AL-14**.
- **Format Penutup Chat Wajib 3 Bagian (permintaan Lee 2026-09-22):** Setiap akhir balasan agent ke Lee **WAJIB** ditutup dengan 3 bagian ringkas:
  1. **📍 Posisi Sekarang:** status posisi roadmap & apa yang baru saja diselesaikan.
  2. **⏩ Rencana Selanjutnya (Agent):** langkah konkret yang akan dikerjakan agent berikutnya.
  3. **👉 Langkah Lee:** tindakan nyata yang harus dilakukan Lee (atau penegasan cukup ketik *"Lanjut"*).
  *(Info penting lainnya tetap disampaikan di atas bagian penutup ini).*
- **Tingkat detail penjelasan:** Sedang — setiap istilah teknis wajib diterjemahkan ke bahasa sehari-hari; kalau pemilik perlu melakukan sesuatu, tulis langkah-langkahnya satu per satu (step-by-step), bukan daftar istilah

- **Penyerahan audit/review/pemeriksaan independen (ditegaskan 2026-09-21):** selalu tampilkan prompt pendek langsung di chat dalam blok siap-tempel; tautan/berkas saja tidak cukup. Prompt memakai repo + cabang sumber + SHA paket + path (privat via git/gh), SHA target terpisah. Tanpa pengingat lagi wajib otomatis commit/push/verifikasi laporan ke GitHub memakai pengirim terisolasi; cabang/working tree bisa bersama. Bukti repo/cabang/path/commit/hash atau TERBLOKIR, bukan klaim selesai lokal. Periksa draf sebelum mengirim (AL-15). Jangan kirim ulang bila Lee sudah menjalankannya dan tidak meminta penggantian.

## Latar Belakang
- **Paham coding?** Tidak sama sekali — jawaban pemilik: "Aku masih nol soal ini"
- **Paham arsitektur/DevOps/database?** Tidak — konsekuensi dari poin di atas; seluruh pekerjaan teknis (kode, database, deploy, server) adalah tanggung jawab agent, bukan pemilik
- **Peran:** Belum dikonfirmasi — digali di Tahap 1 Discovery (solo atau tim, siapa saja yang terlibat)
- **Preferensi arahan:** Agent memberi rekomendasi terbaik + alasan singkat, pemilik memilih. Pemilik juga terbuka pada pertimbangan/usulan tambahan — jawaban pemilik: "Beri rekomendasi terbaik dan alasan nya, nanti aku bisa pilih. Tapi klo ada pertimbanagn atau usulan lain juga bisa disampaikan"

## Konteks Proyek (diisi bertahap, boleh kosong di awal)
- **Budget:** Belum diisi — digali di Tahap 1 Discovery
- **Timeline:** Belum diisi — digali di Tahap 1 Discovery
- **Skill tim:** Belum diisi — digali di Tahap 1 Discovery (pemilik sendiri: nol coding)
- **Batasan lain:** Belum diisi — digali di Tahap 1 Discovery

## Cara Agent Menggunakan File Ini (prinsip)
- Agent WAJIB baca file ini di awal tiap sesi SEBELUM baca PROJECT_STATE.
- Semua penjelasan, pertanyaan, rekomendasi, dan arahan WAJIB disesuaikan dengan bahasa, gaya, dan latar belakang di atas — bukan dengan asumsi "user paham coding".
- Jika user bilang "terserah" → agent tetap beri rekomendasi eksplisit dengan alasan singkat, lalu catat sebagai keputusan resmi (bukan asumsi) — tapi bahasa dan kedalaman penjelasan harus tetap sesuai profil ini.
- Jika profil belum terisi (file masih template kosong) → agent WAJIB tanya 4 pertanyaan di bawah di sesi pertama, simpan jawabannya di sini, commit & push, baru lanjut ke Tahap 1.

## Pertanyaan Wajib Sesi Pertama — SUDAH DIJAWAB 2026-09-16 (jangan tanya lagi, kecuali pemilik minta ubah)
1. Bahasa komunikasi sehari-hari? → **Indonesia**
2. Gaya penjelasan? → **Menyesuaikan kebutuhan**, dengan syarat utama: disesuaikan untuk orang yang tidak paham coding
3. Seberapa paham coding/programming/database/DevOps? → **Nol / tidak sama sekali**
4. Kalau ada pilihan (mis. 2-3 opsi stack teknologi)? → **Beri rekomendasi terbaik + alasannya**, pemilik memilih; usulan/pertimbangan lain tetap boleh disampaikan

> Profil ini sudah terisi. Sesi berikutnya langsung lanjut kerja — jangan mengulang pertanyaan di atas kecuali pemilik meminta perubahan bahasa/gaya.

## Log Perubahan Profil
| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-15 | Template dibuat (prinsip komunikasi adaptif) | Agar agent tidak kaku Indonesia/teknis, tapi menyesuaikan otak pengguna — dibaca tiap sesi sebelum PROJECT_STATE |
| 2026-09-22 | Format penutup chat wajib 3 bagian (Posisi Sekarang, Rencana Selanjutnya, Langkah Lee) | Permintaan Lee: agar tidak bingung dan selalu tahu posisi serta langkah berikutnya |
| 2026-09-19 | Mode bimbingan ditambahkan (AL-14 / AGENT_OPERATING_GUIDE §14) | Lee minta respon cepat saat dibimbing; agent mengusulkan batasnya: cepat untuk bimbingan, tetap teliti untuk bukti |
| 2026-09-17 | Panggilan resmi: **Lee** (bukan "Bapak") | Permintaan Lee: *"mulai sekarang agent ga boleh sebut aku bapak. Nama aku Lee."* |
| 2026-09-16 | Profil diisi pertama kali di sesi aplikasi Resto Barokah (Tahap 1 Discovery) | 4 pertanyaan wajib dijawab pemilik: Indonesia; gaya menyesuaikan kebutuhan tapi wajib ramah non-teknis; nol coding; rekomendasi terbaik + alasan (boleh ditambah usulan lain) — LANGKAH 0 AGENT_SYSTEM.md terpenuhi |
