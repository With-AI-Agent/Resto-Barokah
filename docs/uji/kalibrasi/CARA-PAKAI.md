# Kalibrasi cacat tanaman — cara pakai (jangan hapus cara ini)

**Kenapa ada:** auditor yang tidak pernah diuji ketajamannya tidak boleh dipercaya. Berkas di folder ini dipakai
untuk menguji auditor **tanpa memberitahu di mana cacatnya** (defect injection). Ini standar riset inspeksi
(Perspective-Based Reading + benchmark cacat tanam) dan sudah diwajibkan di `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §7.

**Ada dua jalur kalibrasi — keduanya wajib jalan:**

| Jalur | Bahan | Kunci jawaban | Menjawab pertanyaan |
|---|---|---|---|
| **Mesin** | salinan repo dari `git archive` — **tanpa riwayat Git & tanpa katalog cacat** (sejak audit H F-01, 2026-09-20) | berkas di luar repo (dibuat `--kalibrasi-siapkan`) | *apakah pemeriksa otomatis kita menangkap cacat berbahaya?* |
| **Auditor** | folder `bahan-<tanggal>/` **di dalam repo ini** (ikut ter-commit) | berkas di luar repo (dibuat agent saat penyiapan, **tidak pernah** ditulis di repo/chat auditor) | *apakah auditor manusia/AI-nya tajam?* |
| **Review PR** | berkas `pr-bahan-<tanggal>.diff` **di luar repo** (`/tmp/kalibrasi-pr/`), isinya disematkan ke paket review | berkas di luar repo (`/tmp/KUNCI-KALIBRASI-PR-<tanggal>.md`) | *apakah peninjau tajam saat mengulas perubahan nyata?* |

> **Sejak 2026-09-20 (temuan audit H F-01):** katalog cacat (`kalibrasi-cacat.json`) adalah **kunci jawaban**.
> Jalur **review PR** karena itu **hanya** membacanya dari luar repo (`KALIBRASI_DIR`, baku `/home/user/.kalibrasi`)
> dan **menolak jalan** bila katalog masih di dalam repo — lebih baik kalibrasi tidak jalan daripada skornya bisa
> dipalsukan. Jalur **mesin** tidak lagi memakai `git worktree` (riwayatnya memperlihatkan cacat tanam lewat
> `git diff`); salinannya dibuat ulang tanpa riwayat dan katalognya dikeluarkan. Penjaga: aturan F & G
> `alat/periksa-kunci-kalibrasi.py`. **Sejak 2026-09-20 katalog cacat sudah DIPINDAH ke luar repo** (keputusan Lee atas temuan audit H F-01): berkasnya
kini hidup di `KALIBRASI_DIR` (baku `/home/user/.kalibrasi/kalibrasi-cacat.json`) dan terdaftar di
`docs/uji/BERKAS_PENSIUN.md` baris #2. Alat **menolak jalan** bila katalog tidak ada (gagal-tertutup), dan
`alat/periksa-kunci-kalibrasi.py` aturan A2 menolak bila katalog muncul lagi di dalam repo.

**Kenapa bahan auditor harus berada di dalam repo:** sesi auditor berjalan di **ruang kerja baru** — berkas di luar
repo (mis. `/tmp`) tidak ikut berpindah, jadi kalibrasi lama **tidak bisa jalan lintas sesi** (ini cacat mekanisme
yang ditemukan & ditutup 2026-09-17). Dengan bahan di dalam repo, auditor bisa memeriksanya dari sesi mana pun.

**Aturan untuk auditor (dikutip di paket audit):** folder `bahan-*/` **berisi cacat yang disengaja**. Tugasmu
menemukannya. Kamu **tidak** diberi tahu berapa jumlahnya, di berkas mana, atau kelas apa. Cacat di folder
`bahan-*/` **tidak dihitung** sebagai temuan proyek — hanya sebagai skor kalibrasi. Dilarang mencari kunci
jawaban (di luar repo); menemukan kunci = kalibrasi batal dan dicatat.

**Ambang lulus (`docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §7):** semua K-1/K-2 tertanam **wajib** ditemukan, minimal
70% total, dan nol temuan palsu (mengklaim cacat yang tidak ada). Gagal kalibrasi → verdict "BERSIH" tidak sah.

**Sejak 2026-09-19 (audit D F-05) — bahan review PR hidup DI LUAR repo:** berkas `pr-bahan-*.diff`
dulu ikut ter-commit, padahal diff itu dibuat dari migrasi **nyata**; siapa pun yang bisa membaca repo jadi
tahu persis baris mana yang ditanami cacat (kunci jawaban bocor) dan skor kalibrasi bisa dipalsukan. Sekarang
bahan ditulis di `/tmp/kalibrasi-pr/` dan hanya **isinya** yang disematkan ke paket review. Penjaga:
`alat/periksa-kunci-kalibrasi.py`. Karena bahan lama masih terbaca di riwayat Git, bahan itu **tidak dipakai
lagi** untuk menilai ketajaman — selalu pakai bahan baru bertanggal.

**Berkas yang keluar dari repo:** jalurnya dicatat di `docs/uji/BERKAS_PENSIUN.md` (siapa memutuskan, kapan, kenapa) — rujukan lama tetap terbaca sebagai provenance, dan penjaga menolak bila berkas itu muncul lagi.

**Riwayat bahan:** `bahan-2026-09-17/` (bahan pertama, dibuat setelah pemilik meminta audit menyeluruh lebih dulu).
Bahan lama **jangan dihapus** — riwayat bahan = bukti bahwa kalibrasi tidak dipakai ulang dari jawaban yang bocor.
