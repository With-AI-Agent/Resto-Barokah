#!/usr/bin/env bash
# Jalankan SEMUA pemeriksaan yang sama dengan CI, di komputer sendiri.
# Dipakai sebelum setiap kirim kode supaya CI tidak pernah kaget.
#   bash aplikasi/alat/periksa-semua.sh
set -euo pipefail

APLIKASI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$(dirname "$APLIKASI")"

echo "== aplikasi: kerapian kode =="
(cd "$APLIKASI" && npm run format:check)
echo "== aplikasi: aturan kode =="
(cd "$APLIKASI" && npm run lint)
echo "== aplikasi: tipe =="
(cd "$APLIKASI" && npm run typecheck)
echo "== aplikasi: uji unit =="
(cd "$APLIKASI" && npm test)
echo "== aplikasi: bangun =="
(cd "$APLIKASI" && npm run build)
echo "== aplikasi: kerentanan dependency =="
(cd "$APLIKASI" && npm audit --audit-level=low)
echo "== uji SQL (RLS & isolasi resto, tanpa server) =="
if [ ! -d "$REPO/alat/node_modules" ]; then
  (cd "$REPO/alat" && npm ci --no-audit --no-fund)
fi
(cd "$REPO" && node alat/uji-sql.mjs)
echo "== bukti mutasi pagar migrasi 0012 (harus 12/12 MERAH + kontrol hijau) =="
(cd "$REPO" && python3 alat/uji-mutasi-0012.py | tail -3)

echo "== pemeriksa Python =="

(cd "$REPO" && python3 _sistem/validate_system.py)
(cd "$REPO" && python3 alat/periksa-fungsi-pin.py)
(cd "$REPO" && python3 alat/periksa-roadmap.py)
(cd "$REPO" && python3 alat/periksa-fondasi-independen.py
python3 alat/audit-independen.py --uji-diri
python3 alat/periksa-panduan.py
python3 alat/periksa-panduan.py --uji-diri
python3 alat/periksa-rujukan.py
python3 alat/periksa-rujukan.py --uji-diri
python3 alat/periksa-temuan-audit.py
python3 alat/periksa-temuan-audit.py --uji-diri
python3 alat/periksa-buku-uji.py
python3 alat/periksa-buku-uji.py --uji-diri
python3 alat/review-pr.py --uji-diri)
(cd "$REPO" && python3 alat/periksa-rahasia.py
python3 alat/periksa-rahasia.py --uji-diri
python3 alat/periksa-bersih.py
python3 alat/periksa-bersih.py --uji-diri
python3 aplikasi/alat/periksa-kerapatan.py
python3 aplikasi/alat/periksa-kerapatan.py --uji-diri
python3 aplikasi/alat/periksa-struktur.py)
(cd "$REPO" && python3 aplikasi/alat/periksa-komponen-env.py)
(cd "$REPO" && python3 aplikasi/alat/periksa-uji.py)
(cd "$REPO" && python3 aplikasi/alat/uji-kontras.py)
echo
echo "SEMUA PEMERIKSAAN LOLOS."
