> **BERKAS INI SUDAH DIPENSIUNKAN (2026-09-18).** Berkas siap-tempel yang berubah setiap batch
> sudah **diganti** oleh satu berkas **STATIS**:

# 👉 `PROMPT_SESI_BARU.md` (di akar repo)

Cara pakai sekarang:

1. Buka berkas `PROMPT_SESI_BARU.md` (sekali saja — berkas itu tetap, tidak berubah tiap batch).
2. Isi **baris pertama**: `SESI YANG AKU LANJUT: <nama cabang>` — nama cabang sesi yang ingin
   kamu lanjutkan, mis. `arena/01a0a8a2-resto-barokah`.
3. Salin **seluruh isi** berkas itu ke chat baru (percakapan baru). Selesai.

Yang **tidak** perlu lagi: minta agent menyiapkan berkas baru setiap kali mau pindah sesi.
Keadaan proyek (commit terakhir, CI, butir tertangguh, rencana) **tidak** ditulis di berkas itu —
keadaan dibaca dari isi repo oleh agent sesi baru, dan handoff mesin tetap ada di
`docs/ops/SIAP-LANJUT.md`.

Butuh daftar sesi yang bisa dipilih? Tulis di sesi aktif: `Tampilkan daftar sesi yang bisa
dilanjutkan.` (atau agent menjalankan `python3 alat/lanjut-sesi.py --daftar-sesi`).

Penjelasan lengkap untuk manusia: `PANDUAN_PENGGUNA.md` bagian **AL-13** dan
`docs/PANDUAN_PEMILIK.md` pertanyaan **2b**.

> Catatan teknis: berkas ini sengaja **tidak memuat lagi** blok prompt siap-tempel, supaya tidak
> ada dua sumber yang bisa saling bertentangan. Sesi yang lebih tua (sebelum 2026-09-18) mungkin
> belum punya `PROMPT_SESI_BARU.md` — dalam hal itu, pakai berkas lama dari sesi tersebut apa adanya.
