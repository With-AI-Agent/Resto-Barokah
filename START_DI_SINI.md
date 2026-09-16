# START DI SINI — Sistem Building Aplikasi

> Entry point sistem ini. Sesi agent mulai dari sini — SETELAH membaca PROMPT_ENTRI_UNIVERSAL.md / PANDUAN_PENGGUNA.md.
> Sistem ini membantu pemilik non-teknis membangun aplikasi: Fondasi 6 dokumen → Coding task demi task, dengan checkpoint lintas sesi.

## Peta Baca Minimum (semua jenis sesi — SIAP TEMPLATE)

0. `PROFIL_PENGGUNA.md` — **wajib pertama** (bahasa/gaya/latar belakang) — jika masih kosong, tanya 4 pertanyaan dulu, simpan, baru lanjut. Semua kalimat setelahnya harus menyesuaikan profil ini.
1. `SYSTEM_MANIFEST.md` — identitas, tahap, warisan W-01…W-09
2. `STATUS.md` — keadaan kerja terakhir (field deterministik)
3. `AGENT_SYSTEM.md` — aturan kerja agent (6 Tahap + Coding + Handoff + Mekanisme Hidup + ADAPTIF)
4. `LOG_SESI` terbaru yang masih `OPEN` di `_log-sesi/` — bila ada, lanjutkan konteksnya

**Template siap copy:** folder `sistem-building-aplikasi` ini sudah self-contained — `cp -r sistem-building-aplikasi/* my-app-baru/` → `my-app-baru` jadi repo standalone, prompt di `PANDUAN_PENGGUNA.md` langsung jalan tanpa edit (lihat § Cara Pakai Sebagai Template).

Sisanya baca SESUAI jenis sesi di bawah — jangan baca seluruh folder sekaligus.

## Jenis Sesi 1 — Fondasi Tahap 1-6

1. Baca `AGENT_SYSTEM.md` bagian Tahap yang sesuai (misal Tahap 3 = Tech Spec).
2. Baca `/docs` yang sudah ada dari tahap sebelumnya (di `main`).
3. Diskusi 3-5 pertanyaan/giliran, checkpoint ringkas, jangan tulis dokumen final sebelum pengguna bilang “cukup, tulis draftnya”.
4. Setelah disetujui: commit `/docs/[TAHAP].md` + update `PROJECT_STATE.md` ke STATUS tahap berikutnya. Gerbang: approval pengguna per dokumen.

## Jenis Sesi 2 — Coding (PROJECT_STATE = CODING_AKTIF)

1. Assess status: baca `PROJECT_STATE.md`, `git log`, `ROADMAP.md` ([x]/[ ]), `DECISIONS_LOG.md` (WAJIB), `git status`.
2. Baca `TECH_SPEC.md` + `AGENT_OPERATING_GUIDE.md` bagian relevan + `PRD.md` fitur terkait.
3. Ambil task berikutnya `[ ]` dari ROADMAP → eksekusi → update DECISIONS_LOG bila sentuh Area Berisiko Tinggi → `[x]` → commit & push → update PROJECT_STATE.
4. Stop & tanya bila: ambiguitas, beda dari dokumen fondasi, akan ubah DECISIONS_LOG, butuh input user, atau sentuh Area Berisiko tapi belum ada entri.

## Jenis Sesi 3 — Siklus Baru (v1, v2)

1. Baca `/docs/PRD.md` + `TECH_SPEC.md` + `DECISIONS_LOG.md` yang sudah ada.
2. Gali kebutuhan siklus baru (fitur baru/revisi) + cek bentrok dengan Area Berisiko Tinggi historis.
3. Tulis UPDATE `PRD.md` (section baru), UPDATE `TECH_SPEC.md` bila perlu, arsipkan `ROADMAP.md` lama → tulis `ROADMAP` baru. PROJECT_STATE = SIKLUS_BARU → CODING_AKTIF.

## Jenis Sesi 4 — Audit / Cross-Check

1. Baca semua `/docs` (DISCOVERY, PRD, TECH_SPEC, AGENT_GUIDE, ROADMAP).
2. Cari inkonsistensi, gap logika, task tanpa referensi, ambiguitas, Area Berisiko tanpa task.
3. Laporkan severity (Critical/Minor) + saran perbaikan; terapkan setelah disetujui.

## Jenis Sesi 5 — Checkpoint & Handoff (sesi panjang)

Ikuti 6 audit di AGENT_SYSTEM.md §Checkpoint & Handoff (ROADMAP, DECISIONS_LOG, konsistensi, repo, PROJECT_STATE, ringkasan jujur).

## Jenis Sesi 6 — Audit/Sempurnakan Sistem (HIDUP)

Kapan saja bilang "audit sistem ini" / "sempurnakan sistem ini" → baca `SYSTEM_MANIFEST.md` (Quality & Evolution) + `AGENT_SYSTEM.md` § Mekanisme Hidup A, jalankan `validate_system` + `validate_repo` + `check_selfcontained` + FI 72, laporkan Critical/Minor, buka branch `sistem-audit-...`, PR tanpa auto-merge.

## Jenis Sesi 7 — Audit/Sempurnakan Aplikasi / Buat v2 (HIDUP)

Kapan saja setelah rilis bilang "audit aplikasi", "perbaiki ...", "buat v2" → baca `PROJECT_STATE.md` + `ROADMAP.md` + `DECISIONS_LOG.md`, ikuti `AGENT_SYSTEM.md` § Mekanisme Hidup B (Cross-Check atau Tahap 0.5 atau tambah task ROADMAP dengan 7 atribut lengkap).

## Penutup Sesi (semua jenis)

Ikuti Prompt Penutup di `PANDUAN_PENGGUNA.md`: PROJECT_STATE + STATUS disegarkan, LOG_SESI ditutup (CLOSED), semua ter-push sebelum PR, PR tanpa auto-merge. Setelah merge/close sesi tidak bisa push lagi (fakta platform) — buka sesi baru dari main.

---

## Log Keputusan

| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-15 | START_DI_SINI dibuat pada run klinik pertama (kit v0.2.0) | Entry point self-contained agar sistem bisa diunduh jadi repo standalone; sebelumnya navigasi hanya via AGENT_SYSTEM.md |
