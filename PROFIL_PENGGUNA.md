# Profil Pengguna — Sistem Building Aplikasi

> File ini dibaca OTOMATIS oleh agent di awal setiap sesi (sebelum baca PROJECT_STATE). JANGAN dihapus. Diperbarui sekali di sesi pertama, bisa diubah kapan saja bila preferensi berubah.

## Bahasa & Komunikasi
- **Bahasa pilihan:** [isi: Indonesia / English / campur — default Indonesia]
- **Gaya komunikasi:** [isi: santai & singkat / formal & rinci / step-by-step tanpa jargon / to-the-point teknis]
- **Tingkat detail penjelasan:** [isi: ringkas / sedang / sangat rinci dengan contoh]

## Latar Belakang
- **Paham coding?** [isi: tidak sama sekali / sedikit / menengah / expert]
- **Paham arsitektur/DevOps/database?** [isi: tidak / sedikit / ya]
- **Peran:** [isi: pemilik solo / tim — jumlah & peran]
- **Preferensi arahan:** [isi: mau diberi 2-3 opsi + rekomendasi / mau langsung direkomendasikan yang terbaik / mau dijelaskan trade-off dulu]

## Konteks Proyek (diisi bertahap, boleh kosong di awal)
- **Budget:**
- **Timeline:**
- **Skill tim:**
- **Batasan lain:**

## Cara Agent Menggunakan File Ini (prinsip)
- Agent WAJIB baca file ini di awal tiap sesi SEBELUM baca PROJECT_STATE.
- Semua penjelasan, pertanyaan, rekomendasi, dan arahan WAJIB disesuaikan dengan bahasa, gaya, dan latar belakang di atas — bukan dengan asumsi "user paham coding".
- Jika user bilang "terserah" → agent tetap beri rekomendasi eksplisit dengan alasan singkat, lalu catat sebagai keputusan resmi (bukan asumsi) — tapi bahasa dan kedalaman penjelasan harus tetap sesuai profil ini.
- Jika profil belum terisi (file masih template kosong) → agent WAJIB tanya 4 pertanyaan di bawah di sesi pertama, simpan jawabannya di sini, commit & push, baru lanjut ke Tahap 1.

## Pertanyaan Wajib Sesi Pertama (agent harus tanya ini sebelum mulai Tahap 1)
1. Mau pakai bahasa apa untuk komunikasi sehari-hari? (Indonesia / English / campur)
2. Kamu mau gaya penjelasan seperti apa? (santai singkat / formal rinci / step-by-step tanpa jargon — cocok untuk non-teknis)
3. Seberapa paham kamu soal coding/programming/database/DevOps? (tidak sama sekali / sedikit / lumayan / expert) — supaya aku bisa sesuaikan istilah dan kedalaman.
4. Kalau aku kasih pilihan (mis. 2-3 opsi stack), kamu mau aku langsung rekomendasikan yang terbaik + alasan singkat, atau mau aku jelaskan trade-off dulu baru kamu pilih?

> Setelah 4 pertanyaan ini terjawab, agent tulis hasilnya di bagian Bahasa & Komunikasi + Latar Belakang di atas, commit sebagai langkah pertama, dan JANGAN tanya lagi di sesi berikutnya kecuali user minta ubah.

## Log Perubahan Profil
| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-15 | Template dibuat (prinsip komunikasi adaptif) | Agar agent tidak kaku Indonesia/teknis, tapi menyesuaikan otak pengguna — dibaca tiap sesi sebelum PROJECT_STATE |
| | | |
