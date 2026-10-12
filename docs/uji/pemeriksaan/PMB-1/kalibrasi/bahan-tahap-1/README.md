# Bahan kalibrasi Tahap 1 — PMB-1 (potongan F-17)

Folder ini berisi **cuplikan dokumen fondasi yang SENGAJA diberi cacat** (mekanisme: `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §7,
jalur auditor; rancangan PMB §9). Perlakukan tiap cuplikan sebagai **usulan revisi resmi** bagian dokumen itu: periksa dengan
pertanyaan pemicu §4a (konsisten? lengkap? asumsi? sesuai suara Lee? masih benar hari ini?) dan **bandingkan dengan dokumen fondasi
lain** (PRD, TECH_SPEC, KEAMANAN, ROADMAP, DECISIONS_LOG, REKAM_PESAN_PEMILIK) sebagaimana kamu memeriksa dokumen sungguhan.

Aturan:
- Kamu **tidak diberi tahu** berapa jumlah cacatnya, di berkas mana, atau kelasnya. Ada pula bagian yang **benar**.
- **Dilarang** membaca `kalibrasi/KUNCI-*`, membaca `git log`/`git diff` folder ini, atau membandingkan baris demi baris dengan
  dokumen asli yang sama (`diff`). Yang diukur adalah ketajaman penalaran & pemeriksaan silang, bukan kemampuan menjalankan `diff`.
- Catat setiap cacat sebagai temuan di kartu `kartu/K-F-17.md` **dan** di Buku Besar dengan potongan `F-17` (tingkat K, baseline
  yang dilanggar, bukti). Temuan berpotongan `F-17` **tidak dihitung** sebagai temuan proyek — hanya untuk mengukur tingkat deteksi.
- Setelah kartu masuk, Perencana membuka kunci (`kalibrasi/KUNCI-TAHAP-1.enc`, kata sandi di tangan Lee) dan menulis hasil
  (ditemukan X dari Y, temuan palsu) di `RINGKASAN_TAHAP-1.md`.

Berkas: `PRD-cuplikan.md` · `KEAMANAN-cuplikan.md` · `ROADMAP-cuplikan.md`.
