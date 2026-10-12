#!/usr/bin/env bash
# Bukti HAKIM H-F-03.6 (2026-10-04, sesi arena/01a1050f-resto-barokah)
# Verifikasi independen perbaikan ronde 3 PMB1-F-038 bagian A (migrasi 0096, commit fc2d9ab)
# dan pemeriksaan status bagian B (menunggu keputusan Lee).
#
# Cara jalan (dari akar repo):
#   bash docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.6-reproduksi.sh
# Tidak mengubah pohon kerja (kontrol negatif tanpa 0096 dijalankan di direktori sementara /tmp).
set -euo pipefail

AKAR="$(cd "$(dirname "$0")/../../../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "=== 1. Commit perbaikan fc2d9ab ==="
git -C "$AKAR" show --stat fc2d9ab

echo
echo "=== 2. DENGAN migrasi 0096 (HEAD): uji resmi kasus 1-19 ==="
(cd "$AKAR" && node alat/uji-sql.mjs supabase/tes/voucher_kasir_wajib_identitas.sql) | tail -n 8

echo
echo "=== 3. DENGAN migrasi 0096 (HEAD): probe H-F-03.4 (+62) dan H-F-03.5 (10 varian nomor) ==="
for p in \
  docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.4-probe-plus62.sql \
  docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.5-probe-varian-nomor.sql \
  docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.5-matriks-varian-nomor.sql \
  docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.5-tabel-normalisasi.sql; do
  echo "--- $p ---"
  (cd "$AKAR" && node alat/uji-sql.mjs "$p" || true) | tail -n 6
done

echo
echo "=== 4. KONTROL NEGATIF (TANPA migrasi 0096 di salinan sementara) ==="
git -C "$AKAR" archive HEAD | tar -x -C "$TMP"
ln -s "$AKAR/alat/node_modules" "$TMP/alat/node_modules"
rm "$TMP/supabase/migrations/0096_penyatuan_gaya_penulisan_nomor_hp.sql"

echo "--- TANPA 0096: supabase/tes/voucher_kasir_wajib_identitas.sql (wajib GAGAL di kasus 9) ---"
(cd "$TMP" && node alat/uji-sql.mjs supabase/tes/voucher_kasir_wajib_identitas.sql || true) | tail -n 7

echo "--- TANPA 0096: bukti/H-F-03.5-probe-varian-nomor.sql (wajib LULUS = celah hidup) ---"
(cd "$TMP" && node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.5-probe-varian-nomor.sql || true) | tail -n 5

echo
echo "=== 5. Bagian B PMB1-F-038 (identitas fiktif bernomor berbeda): probe H-F-03.5-probe-identitas-fiktif.sql ==="
(cd "$AKAR" && node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.5-probe-identitas-fiktif.sql || true) | tail -n 5

echo
echo "=== 6. Suite SQL penuh (139 berkas uji) ==="
(cd "$AKAR" && node alat/uji-sql.mjs) | tail -n 5
