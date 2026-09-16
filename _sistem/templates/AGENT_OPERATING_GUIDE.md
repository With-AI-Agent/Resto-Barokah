# AGENT_OPERATING_GUIDE.md — Template Fondasi Tahap 4 (untuk Aplikasi yang Dibangun)

> Dokumen ini adalah standar kerja KHUSUS untuk AI agent (bukan developer manusia) yang akan melanjutkan coding aplikasi ini lintas sesi. Diwarisi dari meta-sistem: checkpoint deterministik + LOG_SESI berkelanjutan + anti-hilang konteks (W-02/W-03). Isi sesuai stack di TECH_SPEC.md, tapi kerangka anti-hilang TIDAK boleh dihapus.

## Profil User
- Baca `PROFIL_PENGGUNA.md` dulu tiap sesi (bahasa/gaya/latar belakang) — sesuaikan semua kalimat, bukan asumsi teknis.
- Jika profil kosong → tanya 4 pertanyaan wajib dulu, simpan, baru lanjut.

## Coding Conventions
- [isi: mis. Next.js App Router, TypeScript strict, Tailwind, ESLint, Prettier — sesuai TECH_SPEC]

## Struktur Commit & Branch (fakta platform lmarena)
- Setiap sesi = branch kerja sendiri, JANGAN push ke `main`, PR tanpa auto-merge. Di lmarena branch `arena/[id]-...` dibuat otomatis dan tidak bisa diganti → **deskripsi pindah ke judul commit + judul PR + LOG_SESI**. Bila environment mengizinkan branch manual, pakai nama deskriptif (`tahap-1-discovery`, `fase-2-task-5-...`).
- Di awal sesi: `git branch --show-current` (harus `arena/...`) + `gh pr list --state all` (pakai `--state all` agar PR MERGED/CLOSED terlihat). Jika PR branch aktif sudah MERGED → tidak bisa push lagi → buka sesi baru dari `main`.
- Di awal sesi juga cek branch menggantung lain (selain `main` dan branch-mu) → beri tahu user.

## Testing
- Unit test untuk logic penting (minimal Area Berisiko Tinggi)
- E2E via `agent-browser` / Playwright bila UI

## Error Handling Format
- [isi: format log + response error yang dipakai aplikasi]

## Definition of Done (per task ROADMAP)
- [ ] Kode sesuai TECH_SPEC & AGENT_OPERATING_GUIDE
- [ ] Test ada & lulus (`npm test` / `psql` untuk RLS)
- [ ] `ROADMAP.md` task `[x]` + commit & push
- [ ] `DECISIONS_LOG.md` tercatat jika sentuh Area Berisiko Tinggi (WAJIB)
- [ ] `PROJECT_STATE.md` + `STATUS.md` (`Pekerjaan belum tersimpan: Tidak ada` + `Waktu pembaruan: YYYY-MM-DD — ...`) ter-update sebagai langkah TERAKHIR
- [ ] `LOG_SESI` ditutup `CLOSED` (atau `OPEN — dilanjutkan di ...`) sebelum PR

## Cara Kerja Agent Lintas Sesi — Anti-Hilang Konteks (W-02 + W-03 + Platform)
1. **Awal sesi:** baca `PROFIL_PENGGUNA.md` (langkah 0) → `PROJECT_STATE.md` (STATUS) → `STATUS.md` (`Pekerjaan belum tersimpan: Tidak ada` + `Waktu pembaruan`) → `SYSTEM_MANIFEST` jika ada → verifikasi branch/PR → **cari `LOG_SESI_*.md` terbaru yang `OPEN` (plus `DISKUSI_MENTAH_*.md` lama sebagai arsip) → baca header `Keadaan Sesi`, laporkan, konfirmasi sebelum tanya tujuan** — jangan minta user mengulang konteks yang sudah ada.
2. **Selama sesi:** setelah tiap pertukaran yang menghasilkan informasi baru (keputusan, koreksi, preferensi, fakta verifikasi) → **append LOG_SESI + update header Keadaan Sesi + commit & push segera** — filter: yang dicatat keputusan/koreksi/kendala/preferensi (near-verbatim) + proposal penting + kesepakatan/penolakan + fakta + state kerja; yang TIDAK dicatat basa-basi/ulang STATUS/LOG/dump chat. Biaya over-recording = detik; under-recording = jam hilang.
3. **Akhir sesi / Checkpoint:** audit `ROADMAP` (`[x]` sinkron?), `DECISIONS_LOG` (ada yang kelewat?), konsistensi, repo (`git status` bersih?), `PROJECT_STATE`/`STATUS`/`LOG_SESI` — baru nyatakan aman ditutup. Jika crash sebelum sempat checkpoint → sesi baru pakai poin 1 (LOG_SESI OPEN + STATUS + PROJECT_STATE + `git log`) + workaround `/download-workspace` bila file terjebak.
4. **Jangan ulang tahap `approved/merged` tanpa alasan sah** (instruksi user baru kutip+tanggal, atau bukti cacat ber-rujukan) — selain itu tanya dulu.

## Protokol DECISIONS_LOG.md (W-05 + Area Berisiko)
- Sebelum menyentuh Area Berisiko Tinggi (lihat TECH_SPEC § Area Berisiko) → WAJIB baca `DECISIONS_LOG.md` dulu.
- Jika perlu ubah keputusan tercatat → STOP, tanya user dulu.
- Setelah keputusan baru di Area Berisiko → tulis entri baru SEBELUM lanjut task lain.

Format:
```
### [Fase/Tanggal] Judul
- **Area:** RLS/Auth, Role & Permission, dst
- **Keputusan:** ...
- **Alasan:** ...
- **File terkait:** ...
- **Implikasi:** ...
```

## Protokol PROJECT_STATE.md + STATUS.md (W-03)
- `PROJECT_STATE.md` format:
```
STATUS: CODING_AKTIF | FONDASI_TAHAP_X | SIKLUS_BARU
DETAIL: Fase X Task Y — [1 baris]
UPDATE TERAKHIR: YYYY-MM-DD
```
  Diperbarui sebagai langkah TERAKHIR tiap sesi (STATUS = tahap BERIKUTNYA yang siap).
- `STATUS.md` deterministik (W-03) — tepat 1 baris `Pekerjaan belum tersimpan: Tidak ada` (exact, akhir baris) + `Waktu pembaruan: YYYY-MM-DD — peristiwa` tiap checkpoint & akhir sesi. Template ini (`_sistem/templates/STATUS.md`) + file nyata di root harus punya keduanya (validator fail-closed).

## Protokol LOG_SESI Berkelanjutan (W-02 — turunan 10_LOG_SESI.md)
- File `LOG_SESI_YYYY-MM-DD.md` di `_log-sesi/` (bila 2 sesi sehari → `_2.md`), header `## Keadaan Sesi` selalu segar (Keadaan OPEN/CLOSED, Scope, Di mana sekarang, Sudah disepakati, Masih terbuka, Langkah berikutnya) + Kronologi append-only.
- Penutupan: `OPEN` → `CLOSED` + entri terakhir; bila lanjut → `OPEN — dilanjutkan di ...`.
- Sesi tanpa informasi baru boleh tanpa LOG_SESI (cukup commit terakhir).

## Stop Conditions
- Ambiguitas/gap dokumentasi, keputusan beda dari fondasi, akan ubah DECISIONS_LOG, butuh input user (API key, keputusan bisnis), sentuh Area Berisiko tanpa entri DECISIONS_LOG → STOP & tanya.

## Log Keputusan
| Tanggal | Perubahan | Alasan |
|---|---|---|
| YYYY-MM-DD | Template AGENT_OPERATING_GUIDE dibuat (Tahap 4) | Standar agent non-teknis + checkpoint deterministik + LOG_SESI anti-hilang (warisan W-02/W-03/W-07) |
