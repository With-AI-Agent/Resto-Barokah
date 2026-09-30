# KARTU PEMBANGUN — B-<ID>  (salin jadi `kartu/B-<ID>.md`; satu kartu per potongan yang dibangun; naskah: `PROMPT_GILIRAN.md` §5)

- **Potongan:** <ID> · **Kartu sumber:** `kartu/K-<ID>.md`, `kartu/H-<ID>.md` · **Sesi pembangun:** <cabang arena/…> · **Model:** <…> · **Tanggal:** <YYYY-MM-DD>
- **Commit basis:** <sha 7 digit CABANG PERENCANA saat mulai> · **Independensi:** [tegaskan: bukan sesi penemu, bukan hakim potongan ini; kamu tidak menutup temuanmu sendiri]
- **Ter-push sampai:** `<sha 7 digit commit TERAKHIR cabangmu yang sudah ada di origin>` — isi dari keluaran `python3 alat/periksa-push.py` di akhir giliran (arahan Lee 2026-09-30: hasil giliran harus masuk GitHub; penjaga menolak kartu B tanpa baris ini)

## 1. Temuan yang dibangun
[Satu sub-bagian per `PMB1-F-xxx` (K-1 dulu, lalu K-2): (a) reproduksi MERAH — perintah yang sama dengan kolom Bukti → hasil hari ini;
(b) akar masalah (bukan gejala); (c) apa yang diubah — berkas + baris, migrasi baru `supabase/migrations/NNNN_….sql` bila skema;
(d) uji yang membuktikan cacat itu bisa merah (nama berkas uji, cara menjalankannya, hasil MERAH sebelum → HIJAU sesudah);
(e) sha commit `perbaiki PMB1-F-xxx: …`. Baris Buku Besar: status `DIPERBAIKI`, kolom Perbaikan = sha + satu kalimat + nama uji.]

## 2. Yang sengaja tidak disentuh
[Temuan potongan ini yang TIDAK kamu bangun dan alasannya: `MENUNGGU KEPUTUSAN LEE:` (klaster cara masuk F-036/F-063/F-052, PIN
akun percontohan F-001), `BUTUH LEE/OPERATOR:` (Dashboard/produksi/(luar repo)), K-3/K-4 yang dibiarkan, temuan yang setelah
direproduksi ternyata sudah tidak MERAH (kembalikan ke Hakim dengan catatan, jangan ubah status sendiri).]

## 3. Keputusan yang dibutuhkan Lee
[Daftar pertanyaan A/B yang konkret beserta dampak tiap pilihan — kalau tidak ada, tulis "tidak ada".]

## 4. Rantai bukti
[Hasil nyata perintah berikut (bukan "sudah dijalankan"): **`python3 alat/rantai-bukti-giliran.py --simpan bukti/B-<ID>-rantai.txt`** (jalan
PENUH, rantai CI yang sama dengan GitHub tanpa berhenti di kegagalan pertama) → tempel baris `RINGKASAN RANTAI PENUH: n LOLOS · 0 GAGAL · n dilewati`
dan `RANTAI: LOLOS` · `node alat/uji-sql.mjs` → n LULUS / n GAGAL · `python3 alat/periksa-pemeriksaan.py` · `python3 alat/periksa-bersih.py` ·
`python3 alat/periksa-push.py` → `TER-PUSH sampai <sha>`. (`bash aplikasi/alat/periksa-semua.sh` BUKAN bukti giliran: `set -e`, mati di `lanjut-sesi.py`.)
Simpan keluaran panjang di `bukti/B-<ID>-*.txt` — **hanya berkas baru berawalan ID kartumu**; berkas `bukti/` giliran lain tidak boleh
diubah/ditimpa (bukti kekal, PMB1-F-216 — integrasi menolak).]

## 5. Angka usaha
- Temuan dibangun: <n> (K-1 <n> · K-2 <n> · K-3/K-4 ikut sentuhan <n>) · ditunda menunggu Lee/operator: <n> · commit: <n> ·
  migrasi baru: <daftar> · uji baru: <daftar> · waktu kira-kira: <menit>
- **Yang tidak bisa saya verifikasi:** [daftar]
