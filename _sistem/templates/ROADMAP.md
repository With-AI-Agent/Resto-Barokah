# ROADMAP.md — Template Fondasi Tahap 5

> Pecahan task atomik, referensi PRD/TECH_SPEC, tandai ⚠️ jika sentuh Area Berisiko Tinggi.
>
> **WAJIB: setiap task punya 7 atribut lengkap** (aturan `AGENT_SYSTEM.md` Tahap 5). Bentuk singkat
> seperti `(ref: ..., kompleksitas: ...)` saja **DILARANG** — template ini sengaja memberi contoh
> yang benar, bukan contoh yang dilarang. Task yang masih ambigu → FLAG `❓ AMBIGU`, diskusikan dulu,
> jangan ditulis sebagai task final.

## Contoh format 1 task (7 atribut — semua wajib ada)
```markdown
- [ ] Task N — <judul kerja>
  - **Tujuan:** <1 kalimat jelas: apa yang dicapai dan kenapa>
  - **Ref:** <section PRD/TECH_SPEC spesifik, mis. PRD § Fitur 2, TECH_SPEC § Data Model users>
  - **File:** <file/folder yang disentuh atau dibuat>
  - **DoD (kriteria selesai):** <checklist testable, mis. `npm run test` lulus; anon tidak bisa baca baris user lain>
  - **Kompleksitas:** <kecil/sedang/besar + estimasi jam>
  - **Risiko & mitigasi:** <bila sentuh Area Berisiko Tinggi: `⚠️ wajib update DECISIONS_LOG.md — Area: RLS/Auth`>
  - **Verifikasi:** <cara agent & user tahu task benar-benar selesai, mis. `agent-browser` cek UI, `psql` cek RLS>
```

## Fase 1: Fondasi & Setup (FONDASI_TAHAP_5)
- [ ] Task 1 — Setup repo + env
  - **Tujuan:** repo bisa dijalankan lokal sejak commit pertama (fondasi semua task lain)
  - **Ref:** TECH_SPEC § Struktur Folder; PRD § Non-Goals (alat yang tidak dipakai)
  - **File:** `README.md`, `.env.example`, `.gitignore`, `package.json`
  - **DoD:** `npm install && npm run dev` jalan tanpa error; `.env.example` memuat SEMUA var di TECH_SPEC § Environment Variables
  - **Kompleksitas:** kecil (1 jam)
  - **Risiko & mitigasi:** env var bocor ke git → mitigasi: `.gitignore` memuat `.env*`, hanya `.env.example` yang di-commit
  - **Verifikasi:** `ls -la` + tangkapan layar/URL dev server; `git status` bersih

## Fase 2: Database & Auth (Area Berisiko Tinggi)
- [ ] Task 2 — Migration tabel users + RLS
  - **Tujuan:** setiap user hanya bisa membaca barisnya sendiri (syarat keamanan inti)
  - **Ref:** TECH_SPEC § Data Model users; PRD § Fitur Auth
  - **File:** `supabase/migrations/001_users.sql`, `src/lib/supabase.ts`
  - **DoD:** policy RLS aktif; `SELECT * FROM users` sebagai anon tidak mengembalikan baris user lain
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: RLS/Auth; salah tebak policy → mitigasi: tulis pola policy di DECISIONS_LOG sebelum task lain menyentuh area ini
  - **Verifikasi:** `psql` uji 2 role + `npm run test:rls` lulus

## Fase 3: Fitur Inti
- [ ] Task 3 — ❓ AMBIGU (contoh penanda: jangan dieksekusi sebelum didiskusikan)

## Checklist kelengkapan sebelum ROADMAP disetujui (Tahap 5)
- [ ] Semua fitur Must Have di PRD punya minimal 1 task
- [ ] Semua entitas Data Model punya task migration (+ seed bila perlu)
- [ ] Semua API contract punya task endpoint + test
- [ ] Semua Area Berisiko Tinggi punya task Fase 1 + tanda `⚠️ DECISIONS_LOG`
- [ ] Setup repo, env, lint, test, CI, deploy (Cloudflare/Vercel) masing-masing punya task
- [ ] Integrasi pihak ketiga (Supabase Auth, Google Sheets, R2, dll) punya task setup + test
- [ ] Hal kecil tidak terlupakan: `README.md`, `.env.example`, favicon, error page, loading state, empty state, a11y, responsif

## Log Keputusan
| Tanggal | Perubahan | Alasan |
|---|---|---|
| YYYY-MM-DD | ... | ... |
