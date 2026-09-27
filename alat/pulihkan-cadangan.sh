#!/usr/bin/env bash
# ==============================================================================
# ALAT LATIHAN PEMULIHAN CADANGAN & UJI BUKU INSIDEN (T10-15)
# Resto Barokah — Skrip resmi eksekusi latihan bencana, verifikasi paritas data,
# serta dril penanganan insiden operasional (TECH_SPEC §8 & §11).
#
# Penggunaan:
#   bash alat/pulihkan-cadangan.sh [latihan]
#   bash alat/pulihkan-cadangan.sh --uji-diri
#   bash alat/pulihkan-cadangan.sh laporan
#   bash alat/pulihkan-cadangan.sh pulihkan <berkas.sql_atau_gz>
# ==============================================================================

set -euo pipefail

AKAR_PROYEK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$AKAR_PROYEK"

MODE="${1:-latihan}"

cetak_bantuan() {
  cat <<'EOF'
PENGGUNAAN ALAT PEMULIHAN CADANGAN & LATIHAN BUKU INSIDEN RESTO BAROKAH (T10-15):

  bash alat/pulihkan-cadangan.sh [latihan]
      Menjalankan simulasi latihan pemulihan lengkap ke basis data bersih (clean slate),
      memverifikasi 100% paritas data dan status RLS, serta mengeksekusi 4 dril insiden
      resmi Buku Insiden:
        1. Perangkat Kasir Hilang / Dicuri (§2)
        2. Akun Diduga Dibobol / Bocor (§4)
        3. Pegawai Berhenti Mendadak & Serah Terima Shift (§5 / T10-12)
        4. Rekonsiliasi Ringkasan Harian & Kepatuhan Privasi UU PDP (§6 & §10 / ART-13 & ART-14)

  bash alat/pulihkan-cadangan.sh --uji-diri
      Menjalankan mode uji-diri fail-closed dengan 5 skenario mutasi kerusakan data
      dan pembuktian penolakan deterministik.

  bash alat/pulihkan-cadangan.sh laporan
      Mencetak laporan hasil latihan dalam format dokumen resmi markdown siap pakai.

  bash alat/pulihkan-cadangan.sh pulihkan <berkas_sql_atau_gz>
      Memulihkan berkas SQL cadangan ke basis data target yang bersih.
EOF
}

cmd_latihan() {
  echo "==> Menjalankan Latihan Pemulihan Cadangan & Uji Buku Insiden..."
  node "$AKAR_PROYEK/alat/eksekusi-latihan-insiden.mjs"
}

cmd_uji_diri() {
  echo "==> Menjalankan Uji-Diri Fail-Closed (5 Skenario Mutasi)..."
  node "$AKAR_PROYEK/alat/eksekusi-latihan-insiden.mjs" --uji-diri
}

cmd_laporan() {
  node "$AKAR_PROYEK/alat/eksekusi-latihan-insiden.mjs" --laporan
}

cmd_pulihkan() {
  local berkas="${2:-}"
  if [ -z "$berkas" ]; then
    echo "GALAT: Tentukan berkas cadangan SQL yang akan dipulihkan!" >&2
    exit 1
  fi
  bash "$AKAR_PROYEK/alat/cadangan.sh" pulihkan "$berkas"
}

case "$MODE" in
  latihan|uji)
    cmd_latihan
    ;;
  --uji-diri|uji-diri)
    cmd_uji_diri
    ;;
  laporan|--laporan)
    cmd_laporan
    ;;
  pulihkan)
    cmd_pulihkan "$@"
    ;;
  bantuan|-h|--help)
    cetak_bantuan
    ;;
  *)
    echo "Perintah tidak dikenal: $MODE" >&2
    cetak_bantuan
    exit 1
    ;;
esac
