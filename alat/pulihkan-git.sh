#!/usr/bin/env bash
# ============================================================================
# PEMULIH RUANG KERJA — memeriksa & mengembalikan riwayat Git setelah ruang
# kerja dinyalakan ulang.
#
# Kenapa ada: pada 2026-09-16 ruang kerja di-restart dan salinan Git lokal
# kembali ke titik clone (`main`), padahal seluruh pekerjaan ada di cabang
# sesi di GitHub. Kejadian itu ditangani tanpa kehilangan data, tetapi
# sebaiknya tidak perlu ditebak-tebak lagi.
#
# Cara pakai:
#   bash alat/pulihkan-git.sh             # hanya memeriksa & memberi saran
#   bash alat/pulihkan-git.sh --perbaiki  # memulihkan (hanya bila aman)
#
# Tidak pernah memakai `--hard` / `--force`. Kalau ada perubahan yang belum
# di-commit, skrip ini MENOLAK memulihkan supaya tidak ada karya yang hilang.
# ============================================================================
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

MODE_PERBAIKI="tidak"
if [ "${1:-}" = "--perbaiki" ]; then MODE_PERBAIKI="ya"; fi

if [ ! -d .git ]; then
  echo "GAGAL: bukan repositori Git."
  exit 1
fi

CABANG="$(git rev-parse --abbrev-ref HEAD)"
echo "Cabang sekarang : $CABANG"
echo "Commit sekarang : $(git log --oneline -1)"

echo "Menyegarkan kabar dari GitHub (git fetch)…"
git fetch --quiet origin

KABAR="$(git ls-remote --heads origin "refs/heads/$CABANG" | awk '{print $1}')"
if [ -z "$KABAR" ]; then
  echo
  echo "PENTING: cabang '$CABANG' TIDAK ada di GitHub."
  echo "Artinya HEAD sekarang bukan cabang kerja yang sudah dikirim. Kandidat cabang kerja yang ada di GitHub:"
  git ls-remote --heads origin 'refs/heads/arena/*' | while read -r sha ref; do
    echo "  - ${ref#refs/heads/}  (commit ${sha:0:7})  $(git log -1 --format=%cd --date=short "$sha" 2>/dev/null || echo '')"
  done
  echo
  echo "JANGAN pindah cabang sendiri. Laporkan daftar ini ke pemilik/sesi, lalu pulihkan dengan:"
  echo "  git fetch origin <cabang-yang-benar> && git reset --soft FETCH_HEAD && git restore --source=FETCH_HEAD --staged --worktree ."
  exit 2
fi

KETINGGALAN="$(git rev-list --count "HEAD..$KABAR")"
if [ "$KETINGGALAN" = "0" ]; then
  echo "AMAN: salinan lokal sudah sama atau lebih baru daripada GitHub (tidak ada commit yang hilang)."
  KOTOR="$(git status --porcelain | wc -l | tr -d ' ')"
  if [ "$KOTOR" != "0" ]; then
    echo "Catatan: ada $KOTOR berkas belum di-commit — jangan lupa commit + push."
  fi
  exit 0
fi

echo
echo "TERDETEKSI: salinan lokal tertinggal $KETINGGALAN commit dari GitHub ($CABANG)."

KOTOR="$(git status --porcelain | wc -l | tr -d ' ')"
if [ "$KOTOR" != "0" ]; then
  echo
  echo "BERHENTI: ada $KOTOR berkas yang belum di-commit di ruang kerja ini."
  echo "Aman-nya: periksa dulu berkas itu (git status), commit atau simpan, BARU pulihkan."
  echo "Setelah itu jalankan lagi: bash alat/pulihkan-git.sh --perbaiki"
  exit 3
fi

echo "Rencana pemulihan (tanpa paksa, tanpa --hard):"
echo "  1) git reset --soft $KABAR"
echo "  2) git restore --source=$KABAR --staged --worktree ."
echo "  3) git status  → harus bersih"
if [ "$MODE_PERBAIKI" != "ya" ]; then
  echo
  echo "Ini baru PEMERIKSAAN. Untuk benar-benar memulihkan, jalankan:"
  echo "  bash alat/pulihkan-git.sh --perbaiki"
  exit 0
fi

echo
echo "Memulihkan…"
git reset --quiet --soft "$KABAR"
git restore --quiet --source="$KABAR" --staged --worktree .
echo "Selesai. Commit sekarang: $(git log --oneline -1)"
echo "Status berkas: $(git status --porcelain | wc -l | tr -d ' ') baris (0 = bersih)."
