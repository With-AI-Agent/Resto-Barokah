# Folder `supabase/`

Skema database, kebijakan keamanan (RLS), Edge Function, dan data awal.

| Folder | Isinya |
|---|---|
| `migrations/*.sql` | Skema & kebijakan, bernomor, **tidak pernah diubah setelah dijalankan** — perbaikan selalu berupa berkas baru |
| `functions/` | Edge Function (email, PIN, cetak, pemicu) |
| `tes/*.sql` | Uji SQL: isolasi antar-resto, antar-cabang, izin, dan uang |
| `seed.sql` | Data awal 1 resto contoh (menyusul di Fase 1) |

## Menjalankan uji SQL tanpa server & tanpa akun Supabase

PostgreSQL asli dijalankan di dalam Node (pustaka PGlite, gratis) sehingga migrasi
dan kebijakan RLS bisa benar-benar diuji di komputer mana pun:

```bash
cd alat && npm ci     # sekali saja
cd ..
node alat/uji-sql.mjs           # terapkan semua migrasi + jalankan semua uji
node alat/uji-sql.mjs --daftar  # sekaligus cetak daftar tabel, RLS, dan jumlah policy
```

Cara ini meniru Supabase: peran `anon`, `authenticated`, `service_role`, skema
`auth` + `auth.uid()`/`auth.jwt()`, dan alat bantu uji di skema `uji`
(`uji.klaim(...)`, `uji.harap(...)`, `uji.harap_gagal(...)`).

Setelah akun Supabase jadi (T0-00), uji yang sama dijalankan ulang di proyek
nyata untuk memastikan perilakunya sama.
