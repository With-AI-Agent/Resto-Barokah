#!/usr/bin/env bash
# Jalankan uji database (PostgreSQL di dalam Node) — bisa dipakai APA ADANYA di salinan baru.
#
# Kenapa ada: `node alat/uji-sql.mjs` langsung gagal di klon baru
# (`ERR_MODULE_NOT_FOUND: @electric-sql/pglite`) karena pustakanya belum dipasang
# (temuan review RV-2 putaran8 PR-07). Skrip ini memasang pustakanya dulu kalau perlu,
# lalu menjalankan uji yang sama. Dipakai baris U-03 Buku Uji Pemilik.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

if [ ! -d "alat/node_modules/@electric-sql/pglite" ]; then
  echo "== memasang pustaka alat uji SQL (sekali saja per salinan) =="
  npm ci --prefix alat --no-audit --no-fund
fi

exec node alat/uji-sql.mjs "$@"
