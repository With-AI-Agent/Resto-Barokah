#!/usr/bin/env bash
# Jalankan SEMUA pemeriksaan yang sama dengan CI, di komputer sendiri.
# Dipakai sebelum setiap kirim kode supaya CI tidak pernah kaget.
#   bash aplikasi/alat/periksa-semua.sh
set -euo pipefail

APLIKASI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$(dirname "$APLIKASI")"

# Kenapa ada langkah ini (temuan review RV-2 putaran8 PR-07): skrip ini dulu langsung
# menjalankan `npm run format:check`. Di klon BARU (tanpa node_modules) perintah pertama itu
# langsung gagal (`prettier: not found`) dan, karena `set -e`, ia mati SEBELUM sampai ke
# pemasangan pustaka di bawah — sehingga buku uji menjanjikan "SEMUA PEMERIKSAAN LOLOS" yang
# tidak bisa dicapai apa adanya. Sekarang pustaka dipasang lebih dulu bila belum ada.
if [ ! -x "$APLIKASI/node_modules/.bin/prettier" ]; then
  echo "== memasang pustaka aplikasi (sekali saja per salinan) =="
  (cd "$APLIKASI" && npm ci --no-audit --no-fund)
fi
if [ ! -d "$REPO/alat/node_modules/@electric-sql/pglite" ]; then
  echo "== memasang pustaka alat uji SQL (sekali saja per salinan) =="
  (cd "$REPO" && npm ci --prefix alat --no-audit --no-fund)
fi
if ! python3 -c "import pgserver, psycopg" 2>/dev/null; then
  echo "== memasang pustaka uji concurrency nyata (sekali saja per salinan) =="
  python3 -m pip install --quiet --break-system-packages pgserver "psycopg[binary]"
fi

echo "== aplikasi: kerapian kode =="
(cd "$APLIKASI" && npm run format:check)
echo "== aplikasi: aturan kode =="
(cd "$APLIKASI" && npm run lint)
echo "== aplikasi: tipe =="
(cd "$APLIKASI" && npm run typecheck)
echo "== aplikasi: uji unit =="
(cd "$APLIKASI" && npm test)
echo "== bukti mutasi kode aplikasi (uji wajib MERAH pada cacat nyata) ==
"
(cd "$REPO" && node aplikasi/alat/uji-mutasi-app.mjs | tail -2)
(cd "$REPO" && node aplikasi/alat/uji-mutasi-app.mjs --uji-diri | tail -2)
echo "== aplikasi: bangun =="
(cd "$APLIKASI" && npm run build)
echo "== aplikasi: kerentanan dependency =="
(cd "$APLIKASI" && npm audit --audit-level=low)
echo "== koneksi Supabase dengan kunci publik (CI memakai env; lokal opsional) =="
if [ -f "$APLIKASI/.env" ] || [ -n "${VITE_SUPABASE_URL:-}" ] || [ -n "${VITE_SUPABASE_ANON_KEY:-}" ]; then
  (cd "$APLIKASI" && npm run cek:supabase)
else
  echo "CI-only: VITE_SUPABASE_URL/VITE_SUPABASE_ANON_KEY belum tersedia; koneksi nyata dilewati secara eksplisit."
fi
echo "== uji SQL (RLS & isolasi resto, tanpa server) =="
(cd "$REPO" && node alat/uji-sql.mjs)
# Label sengaja TIDAK memuat angka: pernah tertulis "12/12" padahal ringkasan nyatanya sudah 16/16
# (temuan review PR-12, ditutup 2026-09-19). Angka benar datang dari ringkasan alat di bawah.
echo "== bukti mutasi pagar migrasi 0012 & 0013 (kontrol hijau + semua mutasi WAJIB MERAH) =="
(cd "$REPO" && python3 alat/uji-mutasi-0012.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0014.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0015.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0016.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0017.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0018.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0019.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0041.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0042.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0043.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0045.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0046.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0047.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0048.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0049.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0050.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0051.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0052.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0053.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0054.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0056.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0057.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0058.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0009.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0021.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0022.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0024.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0025.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0028.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0029.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0030.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0031.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0032.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0033.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0035.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0036.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0037.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0038.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0039.py | tail -2)
(cd "$REPO" && python3 alat/uji-mutasi-0040.py | tail -2)
(cd "$REPO" && python3 alat/uji-konkuren.py | tail -3)
(cd "$REPO" && python3 alat/uji-konkuren.py --uji-diri | tail -2)
(cd "$REPO" && python3 alat/uji-konkuren-0022.py | tail -3)
(cd "$REPO" && python3 alat/uji-konkuren-a04.py | tail -3)

echo "== keamanan SQL efektif + mutasi T1-30 =="
(cd "$REPO" && python3 alat/periksa-keamanan-sql.py | tail -4)
(cd "$REPO" && python3 alat/periksa-keamanan-sql.py --uji-diri | tail -2)

echo "== batas Edge Function verifikasi_pin (berkas asli dijalankan tanpa jaringan) =="
# Butuh esbuild dari `npm ci --prefix alat` (dipasang di awal skrip ini).
(cd "$REPO" && node alat/uji-edge-pin.mjs)

(cd "$REPO" && python3 alat/periksa-maraton.py && python3 alat/periksa-maraton.py --uji-diri)
(cd "$REPO" && python3 alat/periksa-migrasi-beku.py)
(cd "$REPO" && python3 alat/periksa-migrasi-beku.py --uji-diri)

echo "== pemeriksa Python =="

(cd "$REPO" && python3 _sistem/validate_system.py)
(cd "$REPO" && python3 alat/periksa-fungsi-pin.py)
(cd "$REPO" && python3 alat/periksa-fungsi-pin.py --uji-diri)
(cd "$REPO" && python3 alat/periksa-roadmap.py
python3 alat/periksa-roadmap.py --uji-diri)
(cd "$REPO" && python3 alat/periksa-fondasi-independen.py
python3 alat/audit-independen.py --uji-diri
python3 alat/ci_target.py --uji-diri
python3 alat/periksa-paritas-ci.py
python3 alat/periksa-paritas-ci.py --uji-diri
python3 alat/periksa-panduan.py
python3 alat/periksa-panduan.py --uji-diri
python3 alat/lanjut-sesi.py
python3 alat/lanjut-sesi.py --di-ci
python3 alat/lanjut-sesi.py --uji-diri
python3 alat/mulai-sesi.py --uji-diri
python3 alat/periksa-rujukan.py
python3 alat/periksa-rujukan.py --uji-diri
python3 alat/periksa-temuan-audit.py
python3 alat/periksa-temuan-audit.py --uji-diri
python3 alat/periksa-buku-uji.py
python3 alat/periksa-buku-uji.py --uji-diri
python3 alat/tambah-uji.py --uji-diri
python3 alat/peta-ui.py
python3 alat/peta-ui.py --uji-diri
python3 aplikasi/alat/periksa-bahasa.py
python3 aplikasi/alat/periksa-bahasa.py --uji-diri
python3 aplikasi/alat/periksa-arah.py
python3 aplikasi/alat/periksa-arah.py --uji-diri
python3 alat/periksa-bantuan.py
python3 alat/periksa-bantuan.py --uji-diri
python3 alat/periksa-audit.py
python3 alat/periksa-audit.py --uji-diri
python3 alat/periksa-matriks-izin.py
python3 alat/periksa-matriks-izin.py --uji-diri
python3 alat/periksa-gerbang-ci.py
python3 alat/periksa-gerbang-ci.py --uji-diri
python3 alat/periksa-kunci-kalibrasi.py
python3 alat/periksa-kunci-kalibrasi.py --uji-diri
python3 alat/periksa-paket.py
python3 alat/periksa-paket.py --uji-diri
python3 alat/periksa-angka-bukti.py
python3 alat/periksa-angka-bukti.py --uji-diri
python3 alat/review-pr.py --uji-diri)
(cd "$REPO" && python3 alat/periksa-rahasia.py
python3 alat/periksa-rahasia.py --uji-diri
python3 alat/periksa-bersih.py
python3 alat/periksa-bersih.py --uji-diri
python3 aplikasi/alat/periksa-kerapatan.py
python3 aplikasi/alat/periksa-kerapatan.py --uji-diri
python3 aplikasi/alat/periksa-antarmuka.py
python3 aplikasi/alat/periksa-antarmuka.py --uji-diri
python3 aplikasi/alat/periksa-struktur.py
python3 aplikasi/alat/periksa-node.py
python3 aplikasi/alat/periksa-node.py --uji-diri)
(cd "$REPO" && python3 aplikasi/alat/periksa-komponen-env.py)
(cd "$REPO" && python3 aplikasi/alat/periksa-komponen-env.py --uji-diri)
(cd "$REPO" && node aplikasi/alat/catat-alamat.mjs --uji-diri)
(cd "$REPO" && python3 aplikasi/alat/periksa-uji.py)
(cd "$REPO" && python3 aplikasi/alat/periksa-uji.py --uji-diri)
(cd "$REPO" && python3 alat/siapkan-pemeriksaan.py --uji-diri)
(cd "$REPO" && python3 alat/uji-kirim-laporan.py)
(cd "$REPO" && python3 aplikasi/alat/uji-kontras.py)
(cd "$REPO" && python3 aplikasi/alat/uji-kontras.py --uji-diri)
echo
echo "SEMUA PEMERIKSAAN LOLOS."
