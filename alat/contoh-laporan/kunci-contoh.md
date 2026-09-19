# KUNCI JAWABAN CONTOH (untuk uji-diri penilai kalibrasi — bukan kunci sungguhan)

| ID | Tingkat | Kelas | Berkas | Ringkas | Diharapkan ketangkap mesin? | Katakunci |
|---|---|---|---|---|---|---|
| P1 | K-1 | isolasi-penyewa | `supabase/migrations/0004_pola_rls.sql` | Policy dibuka sehingga lintas penyewa bocor | ya | 'policy', 'penyewa_id' |
| P2 | K-2 | uang-lebih-bayar | `supabase/migrations/0010_pembayaran.sql` | Batas lebih bayar dilonggarkan | ya | 'lebih bayar', 'total' |
| P3 | K-3 | dokumen-vs-kode | `docs/KEAMANAN.md` | Dokumen menyebut batas 10× padahal kode 5× | tidak | '10×', 'batas percobaan' |
