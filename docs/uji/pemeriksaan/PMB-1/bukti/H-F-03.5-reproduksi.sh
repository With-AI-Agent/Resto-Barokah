#!/usr/bin/env bash
# Reproduksi HAKIM H-F-03.5 (2026-10-02) untuk klaim kartu B-F-03.2 / PMB1-F-038 (migrasi 0095, perbaikan 18bd3a7):
#   A. DENGAN 0095 (pohon HEAD)  : uji resmi LULUS; probe lama H-F-03.4 GAGAL (celah +62 tertutup).
#   B. TANPA 0095 (HEAD minus berkas 0095, salinan sementara): uji resmi GAGAL di kasus 5; probe lama LULUS (celah hidup).
#   C. Suite SQL penuh dengan 0095.
# Cara jalan (dari akar repo): bash docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.5-reproduksi.sh
# Hanya MEMBACA repo (git archive ke folder sementara). Penyaring tampilan: baris daftar migrasi `  OK    00xx_*.sql`
# tidak dicetak ulang (jumlah migrasi tetap tercetak di baris `Menerapkan N migrasi`); selebihnya keluaran runner apa adanya.
set -u
AKAR="$(cd "$(dirname "$0")/../../../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
UJI="supabase/tes/voucher_kasir_wajib_identitas.sql"
PROBE="docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.4-probe-plus62.sql"

saring() { grep -v -E '^  OK    [0-9]{4}_'; }
jalan() { # $1 = folder kerja; sisanya = argumen runner
  local dir="$1"; shift
  echo; echo "\$ node alat/uji-sql.mjs $*"
  local saida rc
  saida="$(cd "$dir" && node alat/uji-sql.mjs "$@" 2>&1)"; rc=$?
  printf '%s\n' "$saida" | saring
  echo "[exit=$rc]"
}

echo "HEAD pohon: $(git -C "$AKAR" rev-parse --short HEAD)  ·  berkas migrasi 0095: $(ls "$AKAR/supabase/migrations" | grep '^0095_')"

echo; echo "################ A. DENGAN 0095 (pohon HEAD)"
jalan "$AKAR" "$UJI"
jalan "$AKAR" "$PROBE"

echo; echo "################ B. TANPA 0095 (salinan sementara: HEAD dikurangi berkas 0095)"
mkdir -p "$TMP/pre"
git -C "$AKAR" archive HEAD | tar -x -C "$TMP/pre"
rm -f "$TMP"/pre/supabase/migrations/0095_*.sql
ln -s "$AKAR/alat/node_modules" "$TMP/pre/alat/node_modules"
echo "berkas 0095 di salinan: $(ls "$TMP/pre/supabase/migrations" | grep -c '^0095_') (harus 0)"
jalan "$TMP/pre" "$UJI"
jalan "$TMP/pre" "$PROBE"

echo; echo "################ C. SUITE SQL PENUH dengan 0095 (pohon HEAD)"
echo; echo "\$ node alat/uji-sql.mjs"
saida="$(cd "$AKAR" && node alat/uji-sql.mjs 2>&1)"; rc=$?
printf '%s\n' "$saida" | saring | tail -6
echo "[exit=$rc]"
