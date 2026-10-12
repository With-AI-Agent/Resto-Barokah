#!/usr/bin/env bash
# Bukti HAKIM H-F-03.5 (2026-10-02): run CI 36988445582 (commit 25f0faf) MERAH karena penjaga yang gagal
# secara DETERMINISTIK pada pohon commit itu — bukan "pola flake F-219" seperti ditulis kartu B-F-03.2 bagian 4.
#
# Cara jalan (dari akar repo, butuh gh yang sudah masuk): bash docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.5-ci-25f0faf.sh
# Hanya MEMBACA: kloningan sementara di folder sementara; repo asli tidak disentuh.
set -u
AKAR="$(cd "$(dirname "$0")/../../../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
KARTU="docs/uji/pemeriksaan/PMB-1/kartu/B-F-03.2.md"

jalan() { echo; echo "\$ $*"; "$@" 2>&1; echo "[exit=$?]"; }

echo "== 1. Run MERAH 36988445582: langkah mana yang gagal?"
jalan gh run view 36988445582 --json status,conclusion,headSha --jq '{status,conclusion,headSha}'
jalan gh run view 36988445582 --json jobs --jq '[.jobs[].steps[]|select(.conclusion=="failure")|{nomor:.number,nama:.name}]'

echo; echo "== 2. Run HIJAU berikutnya 36991116909 (edba563): apa bedanya dengan commit merah?"
jalan gh run view 36991116909 --json status,conclusion,headSha --jq '{status,conclusion,headSha}'
jalan git -C "$AKAR" diff --stat 25f0faf edba563

echo; echo "== 3. Isi kartu pada commit MERAH: baris Ter-push masih templat"
jalan bash -c "git -C '$AKAR' show 25f0faf:$KARTU | grep -n 'Ter-push sampai'"

echo; echo "== 4. Apakah penjaga ini bagian dari langkah yang gagal (ci.yml)?"
jalan bash -c "grep -n -e 'Pemeriksa fondasi, roadmap' -e 'python3 alat/periksa-pemeriksaan.py\$' '$AKAR/.github/workflows/ci.yml'"

echo; echo "== 5. Jalankan penjaga itu pada pohon commit MERAH (25f0faf)"
git clone -q "$AKAR" "$TMP/c" 2>&1
git -C "$TMP/c" checkout -q 25f0faf 2>&1
jalan bash -c "cd '$TMP/c' && git log -1 --format='%h %s' | cut -c1-90 && python3 alat/periksa-pemeriksaan.py"

echo; echo "== 6. KONTROL NEGATIF: penjaga yang sama pada pohon commit HIJAU (edba563)"
git -C "$TMP/c" checkout -q edba563 2>&1
jalan bash -c "cd '$TMP/c' && git log -1 --format='%h %s' | cut -c1-90 && python3 alat/periksa-pemeriksaan.py"
