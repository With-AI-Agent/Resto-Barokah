# PROMPT SINGKAT GILIRAN PMB — templat yang Perencana tempel di chat untuk Lee

> Cara pakai (Perencana): salin blok di bawah, isi tiga baris `PERAN` / `POTONGAN` / `CABANG PERENCANA`, berikan ke Lee di chat.
> Lee menempelnya sebagai pesan pertama di sesi Arena baru (base branch = CABANG PERENCANA bila bisa dipilih). Naskah panjang
> yang dirujuk prompt ini: `docs/uji/pemeriksaan/PROMPT_GILIRAN.md`; pengecualian orientasinya tercatat di `PRO.md`.
> **Sejak 2026-10-04 (keputusan Lee, Opsi C — PERMANEN): sesi PERENCANA menjalankan peran PEMBANGUN biasa untuk satu potongan per giliran (batas percobaan 3 potongan gugur) — Hakim tetap sesi lain; aturan lengkap: PROMPT_GILIRAN §5 + USULAN_PERAN_PEMBANGUN §9–§10.**
> > **Giliran berikutnya yang disarankan Perencana (2026-10-06, putaran 13x — F-06 tuntas semua ronde (16 baris ditutup dua hakim); empat siklus terbuka):**
> (a) **Siklus F-083 + F-233/F-234 (K-2, P-1B-00)** — verifikasi hakim dulu atas 3 baris TERVERIFIKASI/BARU itu, lalu Pembangun membangun: aktivasi pemulihan darurat tanpa sesi (F-083/F-234) + jalur pendaftaran resmi menulis baris persetujuan (F-233). Objek kartu: `H-F-06.3.md` §1 F-083 & §2; F-086 punya sisa kosmetik F-235 (K-4, P-9-00) ikut siklus kecil.
> (b) **Siklus F-232 (K-3, G-04)** — templat kartu & PROMPT_GILIRAN wajib memuat "Langkah Lee selanjutnya"; verifikasi dulu, baru dibangun.
> (c) **Siklus F-236/F-237 (K-4)** — koreksi angka Perencana sendiri ("16 asersi" → 12 di KEAMANAN:24 + ROADMAP; parentetis "0 rujukan aplikasi/src" di KEAMANAN:124 → "0 rujukan di jalur kunci otomatis"); verifikasi dulu sesuai siklus.
> (d) **Catatan siklus:** penutupan `DIPERBAIKI → DITUTUP` hanya oleh hakim sesi lain; Pembangun (Perencana) tidak menutup temuannya sendiri. Pekerjaan pra-pilot (pengirim header F-070, jam aktif F-089, wiring UI 0103/0104) terjadwal atas keputusan Lee 2026-10-06 — jangan dibangun sebelum Lee memerintahkan.
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
3. Kerjakan HANYA potongan di atas persis seperti PROMPT_GILIRAN.md §2–§5 (klaim di PAPAN + commit dulu, periksa dengan bukti perintah & riset, kartu, Buku Besar, ASUMSI, penjaga LOLOS — python3 alat/susun-daftar-tunggu-lee.py lalu python3 alat/periksa-pemeriksaan.py DAN python3 alat/periksa-bersih.py —, status, commit + push cabangmu), lalu BERHENTI. Jangan mengerjakan tugas ROADMAP, jangan menyentuh handoff (SIAP-LANJUT/PROJECT_STATE/STATUS), jangan memperbaiki kode/dokumen proyek (kecuali PERAN=PEMBANGUN: hanya temuan TERVERIFIKASI K-1/K-2 potonganmu, reproduksi MERAH dulu, satu commit per temuan, kartu kartu/B-<POTONGAN>.md dari TEMPLAT_B.md, rantai bukti = python3 alat/rantai-bukti-giliran.py --simpan docs/uji/pemeriksaan/PMB-1/bukti/B-<POTONGAN>-rantai.txt harus berakhir RANTAI: LOLOS — bukan periksa-semua.sh yang mati di tengah), jangan menyentuh produksi, jangan membaca kunci kalibrasi. Aturan Jaminan Tuntas (PROMPT_GILIRAN.md §4): DIPERBAIKI/DITUTUP wajib menyebut berkas uji yang ADA; tidak pernah menulis [x] di ROADMAP tanpa Bukti; DAFTAR_TUNGGU_LEE.md tidak diedit tangan.
4. HASIL HARUS MASUK GITHUB (arahan Lee 2026-09-30): push SETIAP commit segera setelah dibuat, bukan ditumpuk. Sebelum menyatakan selesai jalankan python3 alat/periksa-push.py → harus mencetak "TER-PUSH sampai <sha>"; kalau BELUM, kerjakan perintah yang disarankannya. PEMBANGUN: kartu B wajib memuat baris "- **Ter-push sampai:** `<sha>`" dan tidak boleh mengubah berkas bukti/ giliran lain (bukti kekal) maupun menghapus baris ROADMAP di luar pola PEMBANGUN dokumen.
5. Balasan terakhirmu: ID potongan, jumlah temuan per K-1…K-4, nama cabangmu, baris "Ter-push sampai <sha>" (salin dari keluaran periksa-push.py), lalu "Langkah Lee": (a) di sesi Perencana ketik `integrasikan <cabangmu>`; (b) potongan berikutnya = `lanjut` atau sesi baru.
Kalau ada yang tidak bisa kamu jalankan atau ada yang bertentangan, BERHENTI dan tanya Lee — jangan menebak, jangan mengarang mekanisme baru.
```
