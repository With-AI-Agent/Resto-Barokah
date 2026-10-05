# PROMPT SINGKAT GILIRAN PMB — templat yang Perencana tempel di chat untuk Lee

> Cara pakai (Perencana): salin blok di bawah, isi tiga baris `PERAN` / `POTONGAN` / `CABANG PERENCANA`, berikan ke Lee di chat.
> Lee menempelnya sebagai pesan pertama di sesi Arena baru (base branch = CABANG PERENCANA bila bisa dipilih). Naskah panjang
> yang dirujuk prompt ini: `docs/uji/pemeriksaan/PROMPT_GILIRAN.md`; pengecualian orientasinya tercatat di `PRO.md`.
> **Sejak 2026-10-04 (keputusan Lee, Opsi C — PERMANEN): sesi PERENCANA menjalankan peran PEMBANGUN biasa untuk satu potongan per giliran (batas percobaan 3 potongan gugur) — Hakim tetap sesi lain; aturan lengkap: PROMPT_GILIRAN §5 + USULAN_PERAN_PEMBANGUN §9–§10.**
> > **Giliran berikutnya yang disarankan Perencana (2026-10-05, putaran 13t — F-229/F-230/F-231 DITUTUP oleh H-P-8-00; dua jalur terbuka):**
> (a) **HAKIM VERIFIKASI `F-06`** — objek: 6 baris K-2 `DIPERBAIKI` menunggu verifikasi ulang: PMB1-F-071 (`729bee8`+`e5b94f8` config kata sandi + penjaga), F-082 (`ffccb09` migrasi 0101 persetujuan wajib login), F-083 (`17e4d5d` migrasi 0102 pemulihan tanpa sesi + residu jujur: kata sandi/TOTP = keputusan Lee B, pembatas laju tepi, UI), F-084 (`1f4e938` kunci otomatis), F-085 (`819e06b` migrasi 0100 pagar pantauan cabang), F-086 (`9d79487` kode 8 karakter). Kartu pembangun `B-F-06.md` (rantai bukti `bukti/B-F-06-rantai.txt` RANTAI LOLOS). Verifikasi khas: probe `bukti/F-06-persetujuan-perangkat-bypass.sql` & `bukti/F-06-admin-lintas-cabang.sql` yang dulu LULUS kini wajib GAGAL (celah tertutup); suite SQL 143 LULUS; uji baru dibongkar semestinya (mutasi ringan).
> (b) **PEMBANGUN `F-06` ronde K-3/K-4** — hanya SESUDAH (a) lewat; objek 9 baris K-3 + 2 baris K-4 (kartu K-F-06 & K-F-06.2).
> (c) **Siklus biasa PMB1-F-232** (K-3, G-04, BARU — temuan hakim H-P-8-00: templat kartu & PROMPT_GILIRAN belum mewajibkan "Langkah Lee selanjutnya"): menunggu hakim verifikasi dulu, baru dibangun — tidak dikerjakan tanpa siklus.
> (d) **Catatan siklus:** penutupan `DIPERBAIKI → DITUTUP` hanya oleh hakim sesi lain; Pembangun (Perencana) tidak menutup temuannya sendiri.
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
