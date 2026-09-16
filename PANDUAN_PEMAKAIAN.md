# ⚠️ VERSI LAMA — SUDAH DIGANTIKAN, JANGAN DIIKUTI

> **Berkas ini arsip.** Ditulis sebagai "Panduan Pemakaian (v3)" sebelum folder ini
> dijadikan template mandiri (run klinik 2026-09-15). **Pedoman yang berlaku sekarang:
> `PANDUAN_PENGGUNA.md`** (untuk pemilik) + `PROMPT_ENTRI_UNIVERSAL.md` (prompt pembuka)
> + `START_DI_SINI.md` (navigasi agent).
>
> **Koreksi paling penting (isi arsip di bawah SALAH di titik ini):**
>
> | Berkas ini (lama, v3) | Yang BENAR sekarang |
> |---|---|
> | "Jangan dimasukkan ke repo GitHub … **yang masuk ke repo hanya `AGENT_SYSTEM.md`**" | **SELURUH isi folder `sistem-building-aplikasi/` yang di-copy ke repo baru** — `cp -r sistem/sistem-building-aplikasi/* my-app-baru/` |
> | Panduan pemilik disimpan di Obsidian, di luar repo | Pedoman pemilik (`PANDUAN_PENGGUNA.md` + `PROMPT_ENTRI_UNIVERSAL.md`) **ikut di dalam folder/repo** — sudah diberi penanda `agent_instruction: IGNORE for execution — USER GUIDE ONLY` supaya agent tidak menjadikannya instruksi kerja |
> | Agent cukup baca `AGENT_SYSTEM.md` + `PROJECT_STATE.md` | Agent WAJIB baca juga `PROFIL_PENGGUNA.md` (LANGKAH 0), `SYSTEM_MANIFEST.md`, `STATUS.md`, `LOG_SESI` terbaru, `skills/README.md` + `skills/` (56 dirs) |
>
> **Kenapa "hanya `AGENT_SYSTEM.md`" tidak lagi benar:** folder ini sekarang
> self-contained — `AGENT_SYSTEM.md` merujuk `PROFIL_PENGGUNA.md` (LANGKAH 0 wajib),
> `skills/` (kewajiban pakai skill), `_sistem/templates/` (10 template Fondasi),
> `_sistem/validate_system.py` (audit hidup), `10_LOG_SESI.md`, `START_DI_SINI.md`.
> Kalau hanya satu berkas yang di-copy, semua rujukan itu putus dan sistem pincang.
> Cara copy yang benar + apa saja yang ikut/ tidak ikut: **`PANDUAN_PENGGUNA.md`
> § "Cara Pakai Sebagai Template"**.
>
> **Status perawatan:** cacat ini ditemukan pemilik 2026-09-16 dan diperbaiki pada
> run klinik ke-2 (rawat inap, kit v0.2.0) — lihat `REKAM-KLINIK.md` + `ACCEPTANCE_TEST_LOG.md`.
> Berkas ini sengaja TIDAK dihapus: isi aslinya diawetkan di bawah sebagai jejak sejarah
> desain (append-only, pola arsip repo ini). **Jangan ikuti instruksi di bawah garis ini.**

---

# ARSIP — isi asli "Panduan Pemakaian (v3)" (SUDAH TIDAK BERLAKU)

# Panduan Pemakaian — Sistem Kerja Fondasi Aplikasi (v3)

> **File ini untuk KAMU, bukan untuk agent.** Jangan dimasukkan ke repo GitHub.
> Simpan ini di Obsidian atau tempat catatan pribadimu. Yang masuk ke repo
> hanya `AGENT_SYSTEM.md`.

---

## Cara kerja sistem ini secara singkat

1. Kamu bikin repo GitHub baru untuk ide aplikasimu.
2. Kamu masukkan file `AGENT_SYSTEM.md` ke root repo itu — **tanpa perlu diedit apa pun**.
3. Kamu hubungkan lmarena agent ke repo tersebut.
4. Setiap kali kamu mau mulai kerja (baik pertama kali maupun lanjutan), kamu buka sesi baru di lmarena agent dan cukup paste **PROMPT PEMICU UNIVERSAL** di bawah — **sama persis setiap kali**, tidak peduli situasinya apa.
5. Agent akan otomatis membaca `AGENT_SYSTEM.md` dan `PROJECT_STATE.md` (kalau sudah ada) untuk tahu sendiri posisi proyek — masih fondasi tahap berapa, atau sudah coding — lalu bekerja sesuai itu.
6. Tugasmu di tiap sesi: diskusi/jawab pertanyaan agent, approve hasil kalau sudah oke, lalu **merge branch sesi itu ke `main`**.

Kamu tidak perlu menghafal atau memilih prompt yang berbeda-beda. Satu prompt, dipakai berulang-ulang.

---

## PROMPT PEMICU UNIVERSAL (pakai ini setiap kali mulai sesi)

```
Cek dulu apakah ada file PROJECT_STATE.md di root repo ini.

Kalau TIDAK ADA (repo kosong/baru): ini proyek baru. Baca AGENT_SYSTEM.md di repo ini secara penuh, lalu mulai dari TAHAP 1 (Discovery).

Kalau ADA: baca isinya, lihat nilai STATUS-nya, lalu ikuti instruksi yang sesuai di AGENT_SYSTEM.md untuk STATUS tersebut.

Setelah kamu tahu posisi kita, laporkan singkat ke aku: sedang di tahap/fase apa, dan apa yang akan kamu kerjakan sekarang — sebelum mulai bekerja.

Sebagai langkah TERAKHIR nanti sebelum sesi ini berakhir (baik karena tahap/task selesai, atau karena aku minta checkpoint), WAJIB update PROJECT_STATE.md supaya sesi berikutnya tahu harus lanjut dari mana.
```

Ide untuk memulai proyek baru ditulis di dalam prompt di atas sendiri —
kalau ini proyek benar-benar baru, tambahkan ide mentahmu setelah prompt
di atas, misalnya:

```
Ide aplikasi yang mau aku bangun (masih mentah):
"[tulis ide kamu di sini]"
```

---

## Yang perlu kamu lakukan di tiap jenis sesi

### Sesi fondasi (Tahap 1-6)
- Agent akan mengajakmu diskusi bertahap. Jawab pertanyaannya, koreksi kalau ada yang meleset.
- Jangan buru-buru bilang "cukup, tulis draftnya" — pastikan kamu memang sudah puas dengan hasil diskusinya.
- Setelah dokumen ditulis dan kamu setujui, agent akan commit ke `/docs` di branch sesi ini.
- **Tugasmu:** buka GitHub, review file yang di-commit, kalau sudah oke → **merge branch ke `main`**.
- Sesi berikutnya (tahap selanjutnya) selalu sesi BARU, bukan lanjutan sesi yang sama — pakai PROMPT PEMICU UNIVERSAL lagi.

### Sesi coding
- Agent akan lapor dulu status & rencana kerja sebelum mulai.
- Kalau ada yang butuh persetujuanmu (keputusan teknis, input seperti API key, dll), agent akan berhenti dan bertanya dengan bahasa sederhana — ikuti instruksinya.
- Di akhir sesi, agent akan kasih laporan: apa yang selesai, kondisi repo, task berikutnya, dan apa yang perlu kamu lakukan.
- **Tugasmu:** review perubahan (kalau bisa/mau), lalu **merge branch ke `main`**.

### Kapan pakai Checkpoint & Handoff
Kalau sesi coding sudah berjalan panjang dan kamu curiga kualitasnya menurun, cek tanda-tanda ini dulu (tidak perlu paham coding):
1. `DECISIONS_LOG.md` tidak bertambah padahal agent baru saja mengerjakan sesuatu yang berisiko tinggi
2. `ROADMAP.md` — agent bilang "task X selesai" tapi checklist-nya masih `[ ]`
3. Kamu tanya balik hal yang sudah dijawab, jawabannya sekarang beda/kontradiksi
4. Progress report makin pendek/generik dibanding awal sesi
5. Sesi sudah sangat panjang (banyak task selesai berturut-turut tanpa jeda)

Kalau salah satu (apalagi lebih dari satu) muncul, **jangan langsung tutup sesi**. Paste prompt ini dulu, di sesi yang sama:

```
STOP dulu sebelum lanjut kerja. Aku mau kamu melakukan Checkpoint & Handoff sebelum sesi ini aku akhiri, karena sesi ini sudah cukup panjang dan aku mau pastikan tidak ada yang tercecer. Ikuti prosedur CHECKPOINT & HANDOFF di AGENT_SYSTEM.md, lakukan dengan jujur dan teliti, lalu konfirmasi ke aku kalau sudah aman untuk ditutup.
```

Setelah agent konfirmasi aman: merge branch ini ke `main` (kalau layak), lalu buka sesi baru dengan PROMPT PEMICU UNIVERSAL seperti biasa.

**Kebiasaan yang disarankan:** jangan tunggu sampai parah. Kalau proyek sedang intens, jadikan ini rutinitas — misal tiap habis 1 fase besar, atau tiap mau berhenti kerja untuk hari itu.

---

## Kapan pakai Tahap 0.5 (siklus berikutnya: v1, v2, dst)

Setelah satu siklus (misal MVP) sudah selesai 100% dan sudah kamu tes/pakai, dan kamu mau menambah hal besar berikutnya:

1. Buka sesi baru, pakai PROMPT PEMICU UNIVERSAL — tapi tambahkan konteks kamu ingin mulai siklus berikutnya, misalnya:

```
Aku mau mulai merancang siklus pengembangan berikutnya (v1) untuk
aplikasi ini. Versi yang baru saja selesai/berjalan: MVP.

Konteks tambahan dariku:
- Hal yang menurutku sudah bagus: [...]
- Hal yang bermasalah/perlu diperbaiki: [...]
- Feedback dari user/pemakaian nyata (jika ada): [...]
- Ide fitur baru yang mau ditambahkan: [...]
```

2. Agent akan mengikuti prosedur TAHAP 0.5 di `AGENT_SYSTEM.md` — update PRD & TECH_SPEC, buat ROADMAP baru, arsipkan ROADMAP lama.
3. Review & merge seperti biasa.
4. Lanjut sesi coding dengan PROMPT PEMICU UNIVERSAL lagi.

---

## Istilah penting (biar kamu ga bingung pas baca laporan agent)

- **MVP** = versi paling minim yang sudah bisa dipakai sungguhan untuk masalah inti — bukan versi murahan, tapi versi "cukup, tidak lebih dari perlu".
- **v1** = MVP yang dipoles jadi rilis resmi pertama.
- **v2, v3, dst** = penambahan besar berikutnya.
- **Area Berisiko Tinggi** = bagian sistem yang gampang "salah ditebak ulang" oleh agent di sesi lain (contoh: hak akses, kalkulasi keuangan) — makanya wajib dicatat di `DECISIONS_LOG.md`.
- **`PROJECT_STATE.md`** = file penunjuk status singkat, dibaca otomatis agent tiap sesi, supaya kamu ga perlu jelasin ulang posisi proyek tiap kali.
- **`DECISIONS_LOG.md`** = catatan keputusan teknis nyata yang dibuat SELAMA coding — bukan rencana di awal, tapi apa yang benar-benar terjadi.
- **Branch per sesi** = tiap sesi kerja bikin cabang kode sendiri; kamu yang menyatukannya (merge) ke `main` kalau sudah oke — ini "gerbang review" kamu.

---

## Checklist ringkas — mulai proyek baru dari nol

- [ ] Buat repo GitHub baru
- [ ] Masukkan `AGENT_SYSTEM.md` ke root repo (tanpa edit)
- [ ] Hubungkan lmarena agent ke repo
- [ ] Sesi 1: PROMPT PEMICU UNIVERSAL + ide mentah aplikasimu → Tahap 1 Discovery
- [ ] Review & merge tiap tahap (1 sampai 6), tiap tahap = sesi baru
- [ ] Setelah Tahap 6, `DECISIONS_LOG.md` & `PROJECT_STATE.md` otomatis dibuat agent → review & merge
- [ ] Fondasi selesai — sesi berikutnya tinggal PROMPT PEMICU UNIVERSAL terus, agent otomatis lanjut coding
