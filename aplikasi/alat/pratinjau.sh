#!/usr/bin/env bash
# Menyalakan pratinjau aplikasi (untuk dilihat pemilik di peramban).
#
# Kenapa ada berkas ini: pustaka aplikasi (`node_modules`) sengaja tidak
# disimpan di repositori DAN tidak ikut tersimpan di cuplikan ruang kerja,
# jadi setelah ruang kerja dinyalakan ulang biasanya pustaka itu hilang dan
# pratinjau mati dengan pesan `vite: not found`. Skrip ini memasang ulang
# pustaka kalau perlu (sekitar 3 detik) lalu menyalakan pratinjau.
#
# Cara pakai:  bash aplikasi/alat/pratinjau.sh
set -euo pipefail

APLIKASI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$APLIKASI"

if [ ! -x "node_modules/.bin/vite" ]; then
  echo "Pustaka belum ada — memasang dulu (npm ci)…"
  npm ci --no-audit --no-fund
fi

echo "Menyalakan pratinjau aplikasi…"
exec npm run dev
