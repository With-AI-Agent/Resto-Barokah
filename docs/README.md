# /docs — Fondasi 6 Dokumen Aplikasi "Sajian" (Resto Barokah)

Folder ini berisi dokumen fondasi aplikasi yang sedang dibangun. **Fondasi 6 dokumen sudah SELESAI**
(status proyek: `CODING_AKTIF` di `PROJECT_STATE.md`).

| Berkas | Isinya | Keadaan |
|---|---|---|
| `DISCOVERY.md` | Masalah, pengguna, ide fitur mentah | **dikunci** — usulkan perubahan, jangan sunting |
| `PRD.md` | Prioritas, fitur wajib M1–M12, aturan bisnis, non-goals | **dikunci** — usulkan perubahan, jangan sunting |
| `TECH_SPEC.md` | Stack, arsitektur, data model §4, kontrak RPC §5, Area Berisiko Tinggi ART-1…ART-10 | **dikunci** — usulkan perubahan, jangan sunting |
| `AGENT_OPERATING_GUIDE.md` | Standar kerja agent (konvensi, uji, DoD, Stop Conditions, Mode Maraton) | berlaku |
| `ROADMAP.md` | 151 tugas dalam 11 fase (F0–F11), tiap tugas ber-7 atribut | berlaku — kontrak kerja harian |
| `DECISIONS_LOG.md` | Keputusan nyata di Area Berisiko Tinggi, diisi SELAMA coding | berlaku |
| `TERTANGGUH.md` | Buku tunggu: hal yang sengaja ditunda + tenggatnya (maks. 12 terbuka) | wajib dibaca tiap sesi |

Sub-folder: `teknis/` (catatan diskusi per tahap) · `uji/` (laporan pemeriksaan silang & review) ·
`desain/` (papan referensi, mockup, rencana UI).

**Pemeriksa otomatis yang menjaga folder ini:**

```
python3 alat/periksa-roadmap.py                 # kelengkapan ROADMAP
python3 alat/periksa-fondasi-independen.py      # pemeriksa kedua, ditulis terpisah (review independen)
python3 _sistem/validate_system.py              # struktur sistem kerja agent
```

Template starter keenam dokumen ada di `../_sistem/templates/`.
