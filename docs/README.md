# /docs — Fondasi 6 Dokumen Aplikasi "Sajian" (Resto Barokah)

Folder ini berisi dokumen fondasi aplikasi yang sedang dibangun. **Fondasi 6 dokumen sudah SELESAI**
(status proyek: `CODING_AKTIF` di `PROJECT_STATE.md`).

| Berkas | Isinya | Keadaan |
|---|---|---|
| `DISCOVERY.md` | Masalah, pengguna, ide fitur mentah | **dikunci** — usulkan perubahan, jangan sunting |
| `PRD.md` | Prioritas, fitur wajib M1–M12, aturan bisnis (18 butir), non-goals | **dikunci** — usulkan perubahan, jangan sunting |
| `TECH_SPEC.md` | Stack, arsitektur, data model §4, kontrak RPC §5, Area Berisiko Tinggi **ART-1…ART-15** | **dikunci** — usulkan perubahan, jangan sunting |
| `KEAMANAN.md` **(baru 2026-09-17)** | Aturan resmi keamanan akun, perangkat, sesi, uang, audit, privasi (UU PDP), mode dukungan + matriks uji & risiko sisa | berlaku — mengikat |
| `SPESIFIKASI_UI.md` **(baru 2026-09-17)** | Aturan kelengkapan layar/tombol: registri aksi, kontrak layar, 7 keadaan, pemeriksa CI, DoD UI, naskah jalan | berlaku — mengikat tugas UI |
| `PETA_UI.md` **(hasil generate)** | Daftar layar & aksi (dibuat `alat/peta-ui.py`; dilarang disunting tangan) | dibuat di T1-33 |
| `AGENT_OPERATING_GUIDE.md` | Standar kerja agent (konvensi, uji, DoD, Stop Conditions, Mode Maraton) | berlaku |
| `ROADMAP.md` | **178 tugas** dalam 11 fase (F0–F11) + 2 fase sisipan (**F1B** keamanan perangkat, **F1C** kontrak UI), tiap tugas ber-7 atribut | berlaku — kontrak kerja harian |
| `DECISIONS_LOG.md` | Keputusan nyata di Area Berisiko Tinggi, diisi SELAMA coding | berlaku |
| `TERTANGGUH.md` | Buku tunggu: hal yang sengaja ditunda + tenggatnya (maks. 12 terbuka; kini 7) | wajib dibaca tiap sesi |
| `teknis/BUKU_INSIDEN.md` **(baru 2026-09-17)** | Langkah cepat saat masalah: perangkat hilang, akun dibobol, pegawai berhenti, data bocor (3×24 jam), internet mati, printer, cadangan, kunci bocor | berlaku — untuk pemilik & admin |
| `teknis/USULAN_KEAMANAN_DAN_KELENGKAPAN_UI.md` | Naskah usulan 2026-09-17 yang disetujui pemilik (latar riset & keputusan) | arsip rujukan |
| `PANDUAN_PEMILIK.md` **(baru 2026-09-17)** | Cara pemilik mengendalikan proyek: minta audit independen, membaca istilah K-1…K-4, arti "terkalibrasi", hal yang tidak boleh ditunda | berlaku — untuk pemilik |
| `uji/PROTOKOL_AUDIT_INDEPENDEN.md` **(baru)** | Mekanisme audit AUD-0…AUD-3: independensi, 6 lensa, kontrak laporan, kalibrasi cacat tanaman, gate | berlaku — mengikat |
| `uji/PROMPT_AUDIT_INDEPENDEN.md` **(baru)** | Kalimat pembuka + cara memulai sesi auditor independen | berlaku |
| `uji/AUDIT_RIWAYAT.md` **(baru)** | Riwayat audit, tingkat deteksi kalibrasi, cacat yang lolos ke produksi | hidup |
| `uji/DAFTAR_PEKERJAAN_ULANG.md` **(baru)** | Hasil AUD-0: pekerjaan lama yang wajib diulang karena keputusan keamanan (B.1–B.12) | hidup |
| `uji/paket-audit/` & `uji/audit/` **(baru)** | Paket audit (hasil mesin) & laporan auditor | hidup |

Sub-folder: `teknis/` (catatan diskusi per tahap) · `uji/` (laporan pemeriksaan silang & review) ·
`desain/` (papan referensi, mockup, rencana UI).

**Pemeriksa otomatis yang menjaga folder ini:**

```
python3 alat/periksa-roadmap.py                 # kelengkapan ROADMAP
python3 alat/periksa-fondasi-independen.py      # pemeriksa kedua, ditulis terpisah (review independen)
python3 _sistem/validate_system.py              # struktur sistem kerja agent
python3 alat/audit-independen.py --uji-diri     # mekanisme audit membuktikan dirinya bisa MENOLAK & MENERIMA
python3 alat/audit-independen.py --paket AUD-2 --tugas T1-01..T1-10   # siapkan paket audit independen
```

Template starter keenam dokumen ada di `../_sistem/templates/`.
