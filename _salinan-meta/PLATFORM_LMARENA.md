> Salinan turunan. Sumber: _meta/PLATFORM_LMARENA.md sha 1f8aa6b9031af3c636695f9b8d099d8eb148e932 tanggal 2026-09-15 versi-meta 1.14.0
> Perbedaan: tidak ada
> Pemakaian: fakta platform yang dirujuk bagian Batasan Platform manifest sistem ini (butir W-07) — dibawa agar folder ini berdiri sendiri tanpa _meta/.
# Platform lmarena — Fakta vs Policy

Dokumen ini menjelaskan batasan fisik platform lmarena Agent Mode yang mempengaruhi cara membangun dan memakai sistem apapun di repo ini. Tujuannya agar agent tidak salah asumsi — tahu mana yang **tidak bisa** karena platform, mana yang **sebaiknya jangan** karena policy kita.

Sumber resmi: help.arena.ai/articles/5432423882-how-to-use-agent-mode (diakses 2026-09-04)

---

## Fakta Platform (tidak bisa / otomatis — bukan aturan kita)

### 1. Branch kerja otomatis

**Fakta:** Saat sesi lmarena dimulai, kamu boleh pilih base branch (misal `main`) di UI, tapi setelah itu lmarena **otomatis** membuat branch baru `arena/[id]-...` dan semua kerja agent terjadi di branch tersebut. Ini perilaku platform, bukan pilihan kita.

**Akibat:**
- Branch aktif yang perlu diverifikasi adalah `arena/...`, bukan `main`.
- `main` hanya berubah setelah PR di-merge.
- Jika agent mengasumsikan kerja di `main` langsung, maka commit-nya tidak akan ada di `main` dan akan hilang saat sesi berganti.

**Kenapa penting:** Agent harus cek `git branch --show-current` di awal sesi, bukan asumsi.

### 2. Kehilangan akses push setelah merge/close

**Fakta:** Setelah PR di-merge atau di-close, platform mencabut token push untuk sesi tersebut. Dokumen resmi: *"Once the pull request is merged or closed, the session can no longer push to GitHub. Any files created after that point stay in the session but can't be pushed, downloaded, or carried into a new session."*

**Akibat:**
- Sesi tersebut **tidak bisa** push lagi, bukan "sebaiknya jangan". Push akan gagal secara teknis.
- File yang dibuat setelah merge akan terjebak di sesi dan tidak bisa dibawa ke sesi baru.
- Workaround resmi jika sudah terlanjur: tambah `/download-workspace` di akhir URL sesi untuk download zip workspace (tidak bisa push, tapi masih bisa download).

**Kenapa penting:** Jika user merge PR dari sesi A, lalu lanjut chat di sesi A yang sama, kerjaan barunya hilang. Harus buka sesi baru dari `main`.

### 3. Sesi bisa menjadi unusable di tengah jalan

**Fakta:** Arena sendiri mengakui sesi kadang menjadi unusable (chat tidak bisa lanjut, error halaman keluar sendiri). Mereka sediakan workaround download workspace sebagai mitigasi.

**Akibat:**
- Diskusi panjang yang belum jadi file + commit bisa hilang jika sesi crash.
- File di workspace yang belum commit/push belum aman untuk sesi baru (sesuai FI-03).

**Kenapa penting:** Protokol checkpoint harus memperhitungkan crash platform, bukan hanya kesalahan agent.

---

## Policy Sistem (harus / sebaiknya — aturan kita dengan alasan kausal)

Policy ini dibuat **karena** fakta platform di atas, bukan aturan sembarang.

### P1 — Commit tiap tahap besar selesai

**Policy:** Setelah satu tahap besar selesai (misal Capture, Extract, Structure, atau satu dokumen brief selesai), agent harus commit + push sebelum menyatakan tahap tersedia untuk sesi baru.

**Alasan kausal:** Karena fakta #3 (sesi bisa crash) dan fakta #2 (file workspace belum aman), maka tanpa commit, sesi baru **tidak bisa** melanjutkan. Ini mencegah FI-03.

### P2 — Log sesi berkelanjutan (`LOG_SESI`)

**Policy:** Setiap sesi memelihara file `LOG_SESI_YYYY-MM-DD.md` di folder scope kerja (unit, sistem, atau folder `_log-sesi/` untuk level repo/meta; format `TEMPLATE_LOG_SESI.md`). Agent append + update header "Keadaan Sesi" + commit + push **segera setelah tiap pertukaran yang menghasilkan informasi baru**. Yang dicatat: keputusan/koreksi/kendala/preferensi pengguna (near-verbatim), proposal penting + dasarnya, kesepakatan & penolakan + alasan, fakta terverifikasi, state kerja, pertanyaan terbuka. Yang TIDAK dicatat: konfirmasi, basa-basi, ulang isi `STATUS.md`/Log (tunjuk path), dump chat. Akhir sesi: header ditandai `CLOSED` (atau `OPEN` + "dilanjutkan di mana"). Entry point sesi baru: cari log terbaru; yang `OPEN` wajib dibaca dan keadaannya dilaporkan + dikonfirmasi ke pengguna.

**Alasan kausal:** Karena fakta #3 (sesi bisa crash, kadang tidak bisa dibuka lagi) dan karena agent sesi baru tidak punya akses ke chat sesi lama, maka konteks yang tidak segera jadi file **hilang permanen**. Mekanisme ini adalah pencatatan sebagai mode normal, bukan checkpoint darurat: aturan lama (checkpoint >5 giliran mendekati keputusan) diganti karena berbasis ambang+judgment — sebelum ambang tercapai, tidak ada yang tercatat, dan diskusi eksploratif tidak selalu "mendekati" keputusan.

**Anti-overkill (bagian dari policy, bukan anjuran):** filter "yang dicatat / yang tidak dicatat" di atas WAJIB dipatuhi. Biaya over-recording = detik per pertukaran; biaya under-recording = jam konteks yang hilang. Floor-nya tetap aman: bahkan pencatatan minimum (keputusan + keadaan) sudah menyelamatkan 90% nilai.

**Kapan file tidak perlu dibuat:** sesi tanpa informasi baru (mis. cek status lalu selesai).

### P3 — Verifikasi branch dan PR di awal sesi

**Policy:** Di awal sesi baru, agent harus cek `git branch --show-current`, `git log --oneline -3`, dan `gh pr list --state all --limit 20`.

**Alasan kausal:** Karena fakta #1 (branch otomatis), agent tidak boleh asumsi branch. Karena fakta #2, jika PR sudah merge tapi sesi lama masih dipakai, push akan gagal. Verifikasi mencegah mismatch (FI-04). **Perintahnya wajib `--state all`, bukan `--state open`** — P4 harus bisa MENGLIHAT PR branch aktif yang sudah MERGED/CLOSED, dan itu tidak pernah muncul di daftar `open` (dibetulkan di audit meta 5 Sep 2026, temuan M-04; dua sesi nyata 4–5 Sep terpaksa memakai `--state all` untuk bekerja benar).

### P4 — Jangan lanjut kerja di sesi yang PR-nya sudah merge

**Policy:** Jika `gh pr list` menunjukkan PR dari branch aktif sudah MERGED/CLOSED, maka sesi ini tidak boleh dipakai untuk kerja baru. Harus buka sesi baru dari `main`.

**Alasan kausal:** Karena fakta #2 (tidak bisa push setelah merge). Ini bukan larangan moral, tapi konsekuensi fisik.

---

## Bagaimana menanam di sistem yang dihasilkan

Setiap sistem domain yang akan dipakai via lmarena harus memiliki bagian "Batasan Platform" di manifest atau entry point-nya:

```markdown
## Batasan Platform

- **Dipakai via lmarena?** Ya
- **Jika Ya:** rujuk ke `_meta/PLATFORM_LMARENA.md` untuk fakta platform. Terapkan P1-P4 sesuai bentuk sistem ini (bertinjkat/flat/siklus).
- **Jika Tidak:** tulis alasan override eksplisit (misal: sistem ini manual 100% Obsidian, tidak via agent)
```

Untuk sistem baru, pertanyaan ini ditanyakan di Discovery Level-0 (lihat `01_DISCOVERY_LEVEL_0.md`).

Untuk sistem existing (konten kreator, catatan belajar), bagian ini ditambahkan di `00_CARA_PAKAI_SISTEM.md` atau `WORKFLOW.md`.

---

## Override

Jika sebuah sistem memang tidak dipakai via lmarena sama sekali, maka fakta platform di atas tidak berlaku untuk sistem tersebut. Override harus dicatat di manifest sistem dengan alasan, dampak, dan approval — sesuai `QUALITY_ASSURANCE_AND_EVOLUTION.md`. "Tidak dilakukan karena lupa" bukan override valid.

---

## Log Keputusan

| Tanggal | Keputusan | Alasan |
|---|---|---|
| 2026-09-04 | Buat dokumen ini | Menutup gap asumsi agent tentang lifecycle sesi lmarena, setelah observasi pengguna dan verifikasi docs resmi Arena. Fakta platform sebelumnya tidak eksplisit di meta, menyebabkan risiko file terjebak setelah merge dan diskusi hilang saat crash. |
| 2026-09-04 | Bedakan fakta (tidak bisa/otomatis) vs policy (harus/jangan + alasan kausal) | Agar agent tidak salah kalibrasi — tahu mana yang tidak bisa secara fisik vs mana yang sebaiknya jangan karena risiko. Sesuai prinsip Log Keputusan di 02_PRINSIP_UNIVERSAL.md. |
