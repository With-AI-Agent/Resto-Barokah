# PRO.md — pintu masuk universal setiap sesi baru

> Berkas ini perintah pertama Lee di sesi mana pun: **"baca pro.md"**.
> Siapa pun agent-nya, model apa pun: jalankan bagian 1 → 2 → 3 berurutan.
> Jangan melompat, jangan menebak, jangan mengarang mekanisme baru.

> **Pengecualian orientasi untuk mandat PEMERIKSA MARATON laporan-saja:** bila prompt
> sudah menunjuk ID tugas + repo/cabang sumber/SHA paket/path + SHA target, baca
> paket itu dahulu melalui git/gh. Jangan jalankan `--susul`/checkout/pull pada tree
> bersama, jangan bertanya memilih sesi/tugas lagi. Pemeriksaan di salinan unik,
> pengiriman terisolasi otomatis sesuai paket; aturan keamanan tetap berlaku.

## 1. Orientasi (WAJIB, sebelum mengerjakan apa pun)

1. Jalankan: `python3 alat/lanjut-sesi.py --daftar-sesi`
   (daftar semua sesi/cabang di GitHub + tandanya: `SEDANG DITUJU`, `tidak aktif`, `DITINGGALKAN`).
   Kalau alat itu belum ada di checkout-mu (kamu mulai dari `main` yang lama), susul dulu dengan
   perintah manual di `PROMPT_SESI_BARU.md`, lalu ulangi langkah ini.
2. Tentukan **satu** sesi aktif. Aturan keras:
   - Lee sudah menyebut cabang tertentu → itu yang menang.
   - Kalau tidak: cabang yang `docs/ops/SIAP-LANJUT.md`-nya menunjuk **dirinya sendiri** dan
     **tidak** tercatat di `docs/ops/SESI_DITINGGALKAN.md`. Tepat satu → itu sesi aktif.
   - Aturan TERSERAP: calon yang ujung cabangnya sudah menjadi nenek-moyang cabang calon lain
     (pekerjaannya dilanjutkan rantai yang lebih baru) otomatis GUGUR — bukan kandidat, bukan
     ditinggalkan, hanya sudah terserap.
   - Kandidat (sesudah aturan terserap) lebih dari satu, atau nol → **BERHENTI**: tampilkan daftar,
     tanya Lee. JANGAN memilih sendiri.
   - Cabang yang tercatat DITINGGALKAN → jangan pernah ditawarkan. Kalau Lee sendiri yang menyebutnya,
     konfirmasi dulu: *"Sesi ini tercatat sengaja kamu tinggalkan (alasan: …) — yakin mau dibangkitkan?"*
     Bangkitkan hanya setelah Lee jawab ya, dan cabut barisnya dari daftar (dengan tanggal).
3. Susul sesi aktif: `python3 alat/lanjut-sesi.py --susul`
   (hanya fast-forward — mustahil menimpa/menghilangkan pekerjaan; kalau alat berhenti, ikuti pesannya).
4. Verifikasi: `python3 alat/lanjut-sesi.py` harus **LOLOS**. Kalau GAGAL → bereskan dulu, jangan bekerja.
5. Baca berurutan: `docs/ops/SIAP-LANJUT.md` (keadaan + rencana §3) → `PROJECT_STATE.md` →
   `STATUS.md` → `docs/teknis/REKAM_PESAN_PEMILIK.md` (pesan pemilik + aturan bahasa: Indonesia
   sederhana, panggil **Lee**, setiap balasan ditutup **"Langkah Lee"**) → `_log-sesi/` terbaru.

**MODE PEKERJA MARATON:** kalau pesan Lee memuat tugas maraton (template `PROMPT_PEKERJA_MARATON.md`,
baris "TUGAS MARATON SAYA" terisi) → lewati pertanyaan "mau apa": kerjakan tugas itu sesuai alur AL-16
(lingkup eksklusif di `docs/ops/PAPAN_TUGAS.md`), lalu lapor satu kalimat.

## 2. Lalu tanya Lee — jangan berasumsi

Tanyakan: **"Mau apa di sesi ini?"** Jawaban pendek Lee memetakan ke buku pedoman
`PANDUAN_PENGGUNA.md` (bagian C3 / alur AL-1…AL-15):
- "mau lanjut sesi" / "lanjutkan" → kerjakan rencana §3 di handoff (sesi ini = kelanjutan sesi aktif).
- "siapkan audit / pemeriksaan" → AL-15 · "review PR" → AL-15 · "tutup sesi" → AL-3 · dst.
- Tujuan lain (update, upgrade, perbaikan, tanya-tanya) → kerjakan seperti biasa SETELAH orientasi ini.

## 3. Larangan tetap (kapan pun)

- JANGAN merge/close PR tanpa keputusan Lee. JANGAN push ke `main`.
- JANGAN menghapus cabang apa pun — kecuali Lee memintanya eksplisit per cabang, dan selalu
  tawarkan dulu arsip tag (`git tag arsip/<cabang> <sha> && git push origin --tags`) supaya
  riwayat tidak hilang. Agent tidak bisa menghapus sesi Arena (di luar kuasa agent).
- Bekerja hanya di cabang arena sesi ini; jangan membuat/mendorong cabang lain.
- Sesi yang tidak dipilih Lee BUKAN otomatis ditinggalkan (Lee biasa menjalankan beberapa sesi
  paralel). Status "ditinggalkan" hanya dari kata-kata Lee, dicatat di `SESI_DITINGGALKAN.md`.
