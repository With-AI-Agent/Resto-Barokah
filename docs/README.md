# /docs — Fondasi 6 Dokumen Aplikasi

Folder ini **hanya berisi `README.md` ini** di Sistem Building Aplikasi (belum ada artefak fondasi) — karena Building Aplikasi adalah **sistem untuk MEMBANGUN aplikasi**, bukan aplikasinya sendiri.

Saat kamu mulai membangun aplikasi pertama (Tahap 1 Discovery) di repo target, agent akan membuat 6 dokumen Fondasi di `/docs` repo target tersebut:

1. `DISCOVERY.md` — Problem, Persona, Ide Fitur mentah
2. `PRD.md` — Prioritas MoSCoW, User Story, Non-Goals
3. `TECH_SPEC.md` — Stack, Arsitektur, Data Model, Area Berisiko Tinggi
4. `AGENT_OPERATING_GUIDE.md` — Standar kerja agent
5. `ROADMAP.md` — Pecahan task atomik
6. `DECISIONS_LOG.md` — Catatan keputusan Area Berisiko Tinggi (diisi selama Coding)

Template starter untuk keenamnya ada di `../_sistem/templates/` (folder itu berisi **10** template: 6 dokumen Fondasi + `PROJECT_STATE.md`, `STATUS.md`, `LOG_SESI.md`, `PROFIL_PENGGUNA.md`) (copy-paste saat mulai, atau biarkan agent generate sesuai AGENT_SYSTEM.md).

Jangan membuat file manual di sini sebelum Tahap 1 — agent akan memandu diskusi dulu.
