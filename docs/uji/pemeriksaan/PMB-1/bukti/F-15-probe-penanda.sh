#!/usr/bin/env bash
# Probe PMB1 F-15: apakah butir TERTANGGUH yang dipindah ke "Butir selesai"
# (padahal syaratnya belum dipenuhi) lolos dari gerbang mesin?
# Memanggil artefak nyata: alat/periksa-roadmap.py dan alat/mulai-sesi.py
# pada salinan `git archive HEAD` (repo asli tidak disentuh).
# Kontrol negatif: salinan TANPA ubahan harus LOLOS dan "Terbuka: 2 butir".
# Perlakuan: baris T-022 dikembalikan ke tabel "Butir terbuka" berstatus
# "[ ] terbuka" (bentuk yang dituntut TERTANGGUH.md:20 selama belum dijawab).
set -u
ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
git -C "$ROOT" archive HEAD | tar -x -C "$TMP"
cd "$TMP"
echo "== KONTROL (tanpa ubahan)"
python3 alat/periksa-roadmap.py 2>&1 | tail -1; echo "exit=${PIPESTATUS[0]}"
python3 alat/mulai-sesi.py 2>&1 | grep -m1 "Terbuka:"
echo "== PERLAKUAN (T-022 tetap di tabel terbuka)"
python3 - <<'PY'
import re, pathlib
p = pathlib.Path("docs/TERTANGGUH.md")
s = p.read_text(encoding="utf-8")
baris = "| T-022 | 2026-09-21 | Cara kirim email ke pelanggan | putusan ditunda ke Fase 2 | Google saja | Fase 2 | pemilik | [ ] terbuka |"
s = s.replace("## Butir selesai", baris + "\n\n## Butir selesai", 1)
p.write_text(s, encoding="utf-8")
PY
python3 alat/periksa-roadmap.py 2>&1 | grep -E "T-022|HASIL|GAGAL|MERAH" | head -4; echo "exit=${PIPESTATUS[0]}"
python3 alat/mulai-sesi.py 2>&1 | grep -m1 "Terbuka:"

# ---- Bagian 2: penanda posisi STATUS.md (AOG §10 "validator fail-closed")
# Kontrol negatif: salinan apa adanya -> validator PASS, kartu sesi mengutip 2026-09-25.
# Perlakuan: hapus DUA baris lama berformat 'YYYY-MM-DD —' (09-25 dan 09-23);
# 23 baris terbaru (format 'YYYY-MM-DD HH:MM WIB (...) —') tetap ada.
cd "$TMP"
git -C "$ROOT" show HEAD:STATUS.md > STATUS.md
echo "== B2 KONTROL"
python3 _sistem/validate_system.py 2>&1 | tail -1
python3 alat/mulai-sesi.py 2>&1 | grep -m1 "STATUS.md        :" | cut -c1-90
echo "== B2 PERLAKUAN (buang baris lama berformat ketat)"
python3 - <<'PY'
import re, pathlib
p = pathlib.Path("STATUS.md")
s = p.read_text(encoding="utf-8")
s = re.sub(r"^.*\*\*Waktu pembaruan:\*\*\s*\d{4}-\d{2}-\d{2}\s+—.*\n", "", s, flags=re.M)
p.write_text(s, encoding="utf-8")
PY
grep -c "Waktu pembaruan:\*\*" STATUS.md
python3 _sistem/validate_system.py 2>&1 | grep -E "Waktu pembaruan|PASS|FAIL" | head -2
python3 alat/mulai-sesi.py 2>&1 | grep -m1 "STATUS.md        :" | cut -c1-90
