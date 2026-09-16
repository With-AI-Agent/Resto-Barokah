# 10 — Log Sesi Berkelanjutan (Sistem Building Aplikasi)

> Aturan self-contained sistem ini untuk pemulihan lintas sesi (fakta platform lmarena: sesi bisa crash kapan saja). Turunan dari protokol meta — disalin, bukan dirujuk. Sistem harus tetap berfungsi penuh bila folder diunduh jadi repo standalone.

## Aturan (mode normal — bukan checkpoint darurat)

1. **Setiap sesi memelihara `_log-sesi/` dengan file `LOG_SESI_YYYY-MM-DD.md` (format TEMPLATE di bawah; bila 2 sesi di hari sama → `LOG_SESI_YYYY-MM-DD_2.md`) — append + update header `## Keadaan Sesi` + commit + push segera setelah tiap pertukaran yang menghasilkan informasi baru — bukan mekanis tiap giliran, tapi segera.** Alasan kausal: sesi lmarena bisa crash kapan saja dan agent sesi baru tidak punya akses ke chat lama — hanya file yang bertahan. Biaya over-recording = detik; biaya under-recording = jam konteks hilang.
2. **Header `## Keadaan Sesi` selalu segar** — di mana kita, apa yang disepakati, apa yang terbuka, langkah berikutnya. Agent baru BACA header ini dulu sebelum tanya apa pun.
3. **Yang dicatat:** keputusan/koreksi/kendala/preferensi pengguna (near-verbatim), proposal penting + dasarnya, kesepakatan & penolakan + alasan, fakta terverifikasi, state kerja (PROJECT_STATE/ROADMAP/DECISIONS_LOG), pertanyaan terbuka.
4. **Yang TIDAK dicatat:** konfirmasi, basa-basi, pengulangan isi yang sudah ada di `STATUS.md`/Log Keputusan (cukup tunjuk path-nya), dump chat. Filter ini WAJIB — inilah yang membuat mekanisme efisien, bukan overkill.
5. **Penutupan:** di akhir sesi, ubah header `Keadaan: OPEN` → `CLOSED` (atau `OPEN — dilanjutkan di ...` + “dilanjutkan di mana” kalau memang lanjut) dan tambahkan entri kronologi terakhir. Jangan pernah hapus entri lama (append-only; bila butuh koreksi, tambah entri baru yang menyatakan koreksi). Sesi tanpa informasi baru (mis. cuma cek status) boleh tanpa file LOG_SESI sama sekali — cukup commit terakhir + CLOSED tidak diperlukan.
6. **Pemulihan crash (WAJIB):**
   - Sesi baru mencari `LOG_SESI` terbaru yang `OPEN` (di `_log-sesi/` atau folder sistem) + file lama `DISKUSI_MENTAH_*.md` (pra-v1.2.0) diperlakukan sama sebagai arsip → **baca header Keadaan Sesi, laporkan keadaannya, dan konfirmasi ke pengguna sebelum lanjut** — jangan minta user menjelaskan ulang konteks yang sudah tercatat.
   - Backstop bila log tidak ada/kosong (agent lalai atau sesi pra-mekanisme): pakai `STATUS.md` (field `Pekerjaan belum tersimpan: Tidak ada` + `Waktu pembaruan`) + `PROJECT_STATE.md` + `git log --oneline` + `git status`.
   - Workaround platform bila sudah terlanjur ada file terjebak setelah crash/merge: tambah `/download-workspace` di akhir URL sesi lmarena untuk download zip workspace, lalu pindahkan manual ke sesi baru — jangan mengarang konteks yang tidak tercatat.
7. **Recovery saat konflik & platform failure:** jangan menimpa perubahan tanpa tunjuk konflik (file, branch, keputusan). Jika `gh pr list --state all` tunjuk PR branch aktif sudah MERGED/CLOSED → sesi ini **tidak bisa** push lagi (fakta platform #2) → buka sesi baru dari `main`. Jika sesi menjadi unusable di tengah diskusi (chat tidak bisa lanjut, error halaman) → buka sesi baru, ikuti poin 6.

## Format LOG_SESI (ringkas — lihat TEMPLATE di _log-sesi/ bila ada)

```markdown
# Log Sesi — YYYY-MM-DD

## Keadaan Sesi (selalu segar)
- **Keadaan:** OPEN / CLOSED
- **Scope:** fondasi Tahap X / coding Fase Y
- **Di mana kita sekarang:** ...
- **Sudah disepakati:** ...
- **Masih terbuka:** ...
- **Langkah berikutnya:** ...

## Kronologi (append, terbaru di bawah)
### YYYY-MM-DD — Peristiwa
- ...
```

## Log Keputusan

| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-15 | Aturan log sesi ditanam pada run klinik pertama (kit v0.2.0) | W-02: sistem belum punya mekanisme log sesi berkelanjutan — tanpa ini sesi crash = konteks hilang permanen (fakta platform #3) |
