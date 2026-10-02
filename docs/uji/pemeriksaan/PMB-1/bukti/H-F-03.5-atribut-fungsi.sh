#!/usr/bin/env bash
# Pembaca HAKIM H-F-03.5 (2026-10-02): apakah migrasi 0095 mengubah atribut keamanan fungsi pemicu secara diam-diam?
# Menjalankan H-F-03.5-atribut-fungsi.sql pada (A) pohon HEAD dan (B) salinan HEAD tanpa berkas 0095.
# Cara jalan (dari akar repo): bash docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.5-atribut-fungsi.sh
# Hanya MEMBACA repo (git archive ke folder sementara). Keluaran runner dicetak apa adanya hanya pada baris PGPROC.
set -u
AKAR="$(cd "$(dirname "$0")/../../../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
SQL="docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.5-atribut-fungsi.sql"

baca() { # $1 = folder kerja
  (cd "$1" && node alat/uji-sql.mjs "$SQL" 2>&1 | grep -m1 'HARAPAN TIDAK TERPENUHI: PGPROC' | sed -e 's/^ *//' -e 's/ ;; /\n   /g')
}

echo "################ A. DENGAN 0095 (pohon HEAD $(git -C "$AKAR" rev-parse --short HEAD))"
echo "\$ node alat/uji-sql.mjs $SQL"
baca "$AKAR"

echo; echo "################ B. TANPA 0095 (salinan sementara: HEAD dikurangi berkas 0095)"
mkdir -p "$TMP/pre"
git -C "$AKAR" archive HEAD | tar -x -C "$TMP/pre"
rm -f "$TMP"/pre/supabase/migrations/0095_*.sql
cp "$AKAR/$SQL" "$TMP/pre/$SQL"
ln -s "$AKAR/alat/node_modules" "$TMP/pre/alat/node_modules"
echo "\$ node alat/uji-sql.mjs $SQL   (di salinan; berkas 0095 ada: $(ls "$TMP/pre/supabase/migrations" | grep -c '^0095_'))"
baca "$TMP/pre"
