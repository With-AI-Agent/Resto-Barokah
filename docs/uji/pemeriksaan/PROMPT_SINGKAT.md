# PROMPT SINGKAT GILIRAN PMB — templat yang Perencana tempel di chat untuk Lee

> Cara pakai (Perencana): salin blok di bawah, isi tiga baris `PERAN` / `POTONGAN` / `CABANG PERENCANA`, berikan ke Lee di chat.
> Lee menempelnya sebagai pesan pertama di sesi Arena baru (base branch = CABANG PERENCANA bila bisa dipilih). Naskah panjang
> yang dirujuk prompt ini: `docs/uji/pemeriksaan/PROMPT_GILIRAN.md`; pengecualian orientasinya tercatat di `PRO.md`.
> **Satu potongan per sesi, potongan berbeda untuk sesi yang berjalan bersamaan** — klaim di PAPAN baru terlihat sesi lain
> setelah diintegrasikan. Ulangan independen potongan yang sama boleh, tetapi harus disengaja Perencana (rancangan §9).

```
Baca PRO.md dan patuhi seluruh isinya (aturan Lee, larangan tetap, bahasa Indonesia sederhana, panggil "Lee", tutup tiap balasan dengan "Langkah Lee"). Sesi ini adalah GILIRAN PMB (Pemeriksaan Mendalam Bertahap) — berlaku "Pengecualian orientasi untuk GILIRAN PMB" di PRO.md.

PERAN: <PEMERIKSA | MENYELURUH | HAKIM | PEMBANGUN>
POTONGAN: <ID dari PAPAN, mis. F-01>
CABANG PERENCANA: <arena/…>

Urutan wajib, jangan dilompati:
1. python3 alat/lanjut-sesi.py --susul  (sesi aktif = CABANG PERENCANA di atas; kalau BERHENTI karena checkout dangkal: git fetch --unshallow origin lalu ulangi) → python3 alat/lanjut-sesi.py harus LOLOS → python3 alat/periksa-pemeriksaan.py harus LOLOS.
2. Baca berurutan sampai selesai: PRO.md → docs/ops/SIAP-LANJUT.md (§3) → docs/teknis/REKAM_PESAN_PEMILIK.md (terutama §31) → docs/uji/pemeriksaan/RANCANGAN_PEMERIKSAAN_BERTAHAP.md → docs/uji/pemeriksaan/PROMPT_GILIRAN.md (naskah peranmu; tiga baris di atas = tiga baris pertamanya) → docs/uji/pemeriksaan/PMB-1/README.md → PAPAN.md → BUKU_BESAR_TEMUAN.md → REGRESI_WAJIB.md → ASUMSI.md.
3. Kerjakan HANYA potongan di atas persis seperti PROMPT_GILIRAN.md §2–§5 (klaim di PAPAN + commit dulu, periksa dengan bukti perintah & riset, kartu, Buku Besar, ASUMSI, penjaga LOLOS — python3 alat/susun-daftar-tunggu-lee.py lalu python3 alat/periksa-pemeriksaan.py DAN python3 alat/periksa-bersih.py —, status, commit + push cabangmu), lalu BERHENTI. Jangan mengerjakan tugas ROADMAP, jangan menyentuh handoff (SIAP-LANJUT/PROJECT_STATE/STATUS), jangan memperbaiki kode/dokumen proyek (kecuali PERAN=PEMBANGUN: hanya temuan TERVERIFIKASI K-1/K-2 potonganmu, reproduksi MERAH dulu, satu commit per temuan, kartu kartu/B-<POTONGAN>.md dari TEMPLAT_B.md, rantai bukti PROMPT_GILIRAN.md §5 dijalankan sungguhan), jangan menyentuh produksi, jangan membaca kunci kalibrasi. Aturan Jaminan Tuntas (PROMPT_GILIRAN.md §4): DIPERBAIKI/DITUTUP wajib menyebut berkas uji yang ADA; tidak pernah menulis [x] di ROADMAP tanpa Bukti; DAFTAR_TUNGGU_LEE.md tidak diedit tangan.
4. Balasan terakhirmu: ID potongan, jumlah temuan per K-1…K-4, nama cabangmu, lalu "Langkah Lee": (a) di sesi Perencana ketik `integrasikan <cabangmu>`; (b) potongan berikutnya = `lanjut` atau sesi baru.
Kalau ada yang tidak bisa kamu jalankan atau ada yang bertentangan, BERHENTI dan tanya Lee — jangan menebak, jangan mengarang mekanisme baru.
```
