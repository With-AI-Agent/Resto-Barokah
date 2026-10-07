#!/usr/bin/env bash
# =============================================================================
# BUKTI HAKIM POTONGAN P-1B-00 — sesi arena/36a4b31f-resto-barokah, 2026-10-07
#
# Objek: empat baris BARU milik potongan P-1B-00 di BUKU_BESAR_TEMUAN.md
#   PMB1-F-095 (K-2) · PMB1-F-233 (K-2) · PMB1-F-237 (K-4) · PMB1-F-239 (K-3)
# plus satu temuan baru hakim (bukti probe basi, G-04).
#
# Berkas ini dijalankan pada pohon kerja hari ini; keluarannya yang tersimpan di
# docs/uji/pemeriksaan/PMB-1/bukti/H-P-1B-00-reproduksi.txt adalah hasil nyata,
# bukan saduran. Nama berkas di dalam perintah diambil dari `ls`/`git ls-files`,
# bukan diketik dari ingatan.
# =============================================================================
set -uo pipefail
cd "$(dirname "$0")/../../../../.."   # bukti/ → PMB-1/ → pemeriksaan/ → uji/ → docs/ → akar repo
pwd

t() { printf '\n===== %s =====\n' "$1"; }

t "0. Keadaan pohon"
date -u +"tanggal UTC: %Y-%m-%d %H:%M:%S"
git rev-parse --short HEAD
git status --porcelain --untracked-files=no | head
echo "(baris di atas kosong = pohon bersih sebelum hakim menulis apa pun)"

t "1. PMB1-F-095 — probe ASLI hakim H-F-06.2, dijalankan hari ini"
node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-F-06-sesi-perangkat-mati.sql 2>&1 | tail -8

t "2. PMB1-F-095 — probe BARU hakim P-1B-00 (penyiapan disesuaikan 0101)"
node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-P-1B-00-probe-sesi.sql 2>&1 | tail -8

t "3. PMB1-F-233 — probe hakim H-F-06.3 (direproduksi hari ini)"
node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-F-06.3-probe-082.sql 2>&1 | tail -8

t "4. PMB1-F-239 — probe hakim H-F-06.5 (direproduksi hari ini)"
node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-F-06.5-probe-105.sql 2>&1 | tail -8

t "5. PMB1-F-233 — satu-satunya definisi daftarkan_perangkat_dengan_kode"
git ls-files supabase/migrations | sort | tail -3
grep -ln "daftarkan_perangkat_dengan_kode" supabase/migrations/*.sql
sed -n '237,239p' supabase/migrations/0030_sesi_dan_persetujuan_perangkat.sql

t "6. PMB1-F-233 — semua tempat yang MENULIS persetujuan_perangkat (migrasi)"
grep -rn "insert into public.persetujuan_perangkat" supabase/migrations/*.sql

t "7. PMB1-F-233 — pemanggil klien untuk tiga RPC kunci"
echo "-- setujui_perangkat_pegawai di aplikasi/src:"; grep -rn "setujui_perangkat_pegawai" aplikasi/src | wc -l
echo "-- buat_kode_perangkat di aplikasi/src:";      grep -rn "buat_kode_perangkat" aplikasi/src | wc -l
echo "-- daftarkan_perangkat_dengan_kode di aplikasi/src:"; grep -rn "daftarkan_perangkat_dengan_kode" aplikasi/src | wc -l
echo "-- layar Perangkat terpasang di App.tsx:";     grep -c "Perangkat" aplikasi/src/App.tsx

t "8. PMB1-F-095 — pemanggil/penulis yang TIDAK ADA (upaya bantahan)"
echo "-- ikat_sesi_perangkat di luar definisi 0030 & berkas uji:"
grep -rln "ikat_sesi_perangkat" supabase aplikasi | grep -v "supabase/tes/" | grep -v "0030_sesi_dan_persetujuan_perangkat"
echo "-- sesi_masih_aktif di luar definisi 0058 & berkas uji:"
grep -rln "sesi_masih_aktif" supabase aplikasi alat | grep -v "supabase/tes/" | grep -v "0058_sesi_masih_aktif" | grep -v "uji-mutasi-0031.py"
echo "-- sesi_perangkat di aplikasi/src:"; grep -rn "sesi_perangkat" aplikasi/src | wc -l
echo "-- signInWithPassword/setSession di aplikasi/src:"; grep -rn -e "signInWithPassword" -e "setSession" aplikasi/src | wc -l
echo "-- header x-perangkat-id di aplikasi/src & supabase/functions:"; grep -rn "x-perangkat-id" aplikasi/src supabase/functions 2>/dev/null | wc -l
echo "-- custom_access_token / auth.hook di supabase/:"; grep -rn -e "custom_access_token" -e "auth.hook" supabase/ | wc -l

t "9. PMB1-F-237 — baris 124 docs/KEAMANAN.md (dipotong) "
sed -n '124p' docs/KEAMANAN.md | cut -c1-520

t "10. PMB1-F-237 — hitungan rujukan jam aktif di aplikasi/src"
echo "-- jam_buka saja:"; grep -rn "jam_buka" aplikasi/src | wc -l
echo "-- jam_buka + jamBuka + 'jam buka':"; grep -rn -e jam_buka -e jamBuka -e 'jam buka' aplikasi/src | wc -l
echo "-- berkas yang memuatnya:"; grep -rln -e jam_buka -e jamBuka -e 'jam buka' aplikasi/src | sort
echo "-- rujukan di jalur kunci otomatis (useKunciOtomatis.ts):"; grep -c -e jam_buka -e jamBuka -e 'jam buka' aplikasi/src/hook/useKunciOtomatis.ts
echo "-- diLuarJamOperasional di App.tsx:"; grep -c "diLuarJamOperasional" aplikasi/src/App.tsx
echo "-- baris 67 kartu B-F-06.2:"; sed -n '67p' docs/uji/pemeriksaan/PMB-1/kartu/B-F-06.2.md

t "11. PMB1-F-239 — isi 0105 yang diklaim (baris 47 & 60-72)"
sed -n '47p' supabase/migrations/0105_aktivasi_pemulihan_perangkat_tanpa_sesi.sql
sed -n '60,72p' supabase/migrations/0105_aktivasi_pemulihan_perangkat_tanpa_sesi.sql

t "12. PMB1-F-239 — adakah kedaluwarsa permohonan 'menunggu'?"
grep -rn "status = 'menunggu'" supabase/migrations/*.sql
echo "-- force RLS pada pemulihan_perangkat:"; grep -rn "pemulihan_perangkat" supabase/migrations/*.sql | grep -c force

t "13. Suite SQL penuh (keadaan dasar hari ini)"
node alat/uji-sql.mjs 2>&1 | tail -4

t "14. Daftar berkas bukti baru giliran ini"
ls -1 docs/uji/pemeriksaan/PMB-1/bukti/ | grep "H-P-1B-00"
