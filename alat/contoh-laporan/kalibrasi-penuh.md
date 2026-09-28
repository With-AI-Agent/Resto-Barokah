# LAPORAN KALIBRASI CONTOH — auditor menemukan SEMUA cacat tanaman (bentuk yang benar)

## 5. Kalibrasi cacat tanaman

- Ditemukan: 3 dari 3
- Temuan palsu: 0

| # | Cacat tanaman | Ditemukan? | Bukti |
|---|---|---|---|
| P1 | `supabase/migrations/0004_pola_rls.sql` — policy penyewa_id dibuka | ya | baca ulang policy + jalankan uji RLS |
| P2 | `supabase/migrations/0010_pembayaran.sql` — batas lebih bayar dilonggarkan 100.000 | ya | uji pembayaran GAGAL |
| P3 | `docs/KEAMANAN.md` — dokumen menyebut batas percobaan 10× padahal kode 5× | ya | bandingkan dengan 0006_pin.sql |

## 6. Yang tidak bisa saya verifikasi

- Supabase nyata (T0-08 belum jalan).
