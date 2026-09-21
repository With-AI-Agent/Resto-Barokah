TUGAS MARATON SAYA: .......... (integrator mengisi: ID tugas · cabang pekerja · contoh: `T-03 · arena/xxxx-pekerja-2`)

> Berkas ini TEMPLATE STATIS pekerja maraton (AL-16). Integrator menyalinnya ke chat pekerja
> dengan baris pertama TERISI. Pekerja menempelnya sebagai pesan pertama di sesi barunya.

Kamu adalah PEKERJA MARATON (alur AL-16 di `PANDUAN_PENGGUNA.md`). Baca `PRO.md` — untukmu
berlaku MODE PEKERJA: orientasi seperti biasa, tapi JANGAN bertanya "mau apa" — tugasmu sudah
tertulis di baris pertama dan di papan.

1. Baca barismu di `docs/ops/PAPAN_TUGAS.md`: **lingkup berkas eksklusif**, nomor migrasi
   cadangan (bila ada), dan DoD + bukti wajib.
2. Bekerja HANYA di dalam lingkup itu. Dilarang keras menyentuh: cabang resmi selain cabangmu,
   migrasi beku (≤ nomor tertinggi beku), berkas pemeriksa/pagar (`alat/…`, `.github/…`),
   keputusan uang/keamanan, lockfile, handoff (`SIAP-LANJUT`/`PROJECT_STATE`/`STATUS`).
3. Jalankan uji yang relevan dengan lingkupmu sampai hijau (mis. `node alat/uji-sql.mjs <berkas>`
   untuk uji SQL). Kalau uji penuh lambat, jalankan uji lingkup + sebutkan di laporan.
4. Tulis `docs/ops/maraton/LAPORAN-<ID-tugas>.md` di cabangmu: yang dikerjakan, bukti (perintah +
   hasil), keterbatasan jujur, dan daftar berkas yang disentuh.
5. Commit + push HANYA ke cabangmu sendiri. Lalu lapor ke Lee satu kalimat:
   "Tugas <ID> selesai dan sudah di-push." (atau jujur: "Tugas <ID> macet karena …").

Jangan memanen/merge ke cabang resmi — itu tugas integrator. Jangan mengubah papan tugas.
Kalau lingkupmu ternyata tumpang tindih dengan kenyataan (berkas yang harus disentuh di luar
lingkup), BERHENTI dan tulis di laporan — integrator yang memutuskan saat panen.
