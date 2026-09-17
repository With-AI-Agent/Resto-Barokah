# LAPORAN KALIBRASI CONTOH — auditor melewatkan cacat + melaporkan temuan palsu (bentuk yang buruk)

## 5. Kalibrasi cacat tanaman

- Ditemukan: 2 dari 3
- Temuan palsu: 1

| # | Cacat tanaman | Ditemukan? | Bukti |
|---|---|---|---|
| P1 | `supabase/migrations/0004_pola_rls.sql` — policy penyewa_id dibuka | ya | uji RLS GAGAL |
| P2 | `supabase/migrations/0010_pembayaran.sql` — batas lebih bayar dilonggarkan | ya | uji pembayaran GAGAL |
| X1 | `supabase/migrations/0007_katalog.sql` — menurut saya harga cabang bisa ditimpa | ya | dugaan saja (TIDAK ADA di kunci → temuan palsu) |

## 6. Yang tidak bisa saya verifikasi

- Supabase nyata.
