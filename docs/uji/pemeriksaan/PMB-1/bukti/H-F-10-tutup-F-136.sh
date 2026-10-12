#!/usr/bin/env bash
# Bukti Hakim H-F-10 — verifikasi ulang PMB1-F-136 (penjaga PMB menerima status berputusan tanpa kartu H).
# Jalankan dari akar repo:  bash docs/uji/pemeriksaan/PMB-1/bukti/H-F-10-tutup-F-136.sh
# Bekerja di SALINAN sementara (/tmp) — tidak mengubah repo. Perlu `gh` (mengambil berkas induk 3f56abb^).
set -u
AKAR="$(pwd)"; T="$(mktemp -d)"; B=docs/uji/pemeriksaan/PMB-1/BUKU_BESAR_TEMUAN.md
git ls-files -z | grep -zv '^skills/' | xargs -0 -I{} cp --parents {} "$T"/ 2>/dev/null
cd "$T" && git init -q && git add -A >/dev/null 2>&1 && git -c user.email=a@b -c user.name=x commit -qm base >/dev/null 2>&1
ubah() { python3 - "$1" "$2" "$3" <<'PY'
import sys
p='docs/uji/pemeriksaan/PMB-1/BUKU_BESAR_TEMUAN.md'; fid,status,hakim=sys.argv[1:4]
L=open(p).read().split('\n')
for i,l in enumerate(L):
    if l.startswith(f'| {fid} '):
        c=l.split('|'); c[8]=f' {status} '; c[9]=f' {hakim} '; L[i]='|'.join(c)
open(p,'w').write('\n'.join(L))
PY
}
jalan() { python3 alat/periksa-pemeriksaan.py 2>&1 | grep -E 'PMB1-F-153|HASIL' | cut -c1-150; }
echo "== kontrol: pohon utuh";                                  jalan
echo "== M1 PALSU tanpa kartu H apa pun (harus GAGAL)";         ubah PMB1-F-153 PALSU 'arena/x tanpa kartu'; jalan; git checkout -q -- .
echo "== M2 PALSU menyebut kartu K pemeriksa (harus GAGAL)";     ubah PMB1-F-153 PALSU 'arena/x K-F-10';      jalan; git checkout -q -- .
echo "== M3 PALSU menyebut kartu H POTONGAN LAIN H-F-01 (PMB1-F-172: LOLOS = celah)"; ubah PMB1-F-153 PALSU 'arena/x H-F-01'; jalan; git checkout -q -- .
echo "== M1 lagi dengan penjaga LAMA (induk 3f56abb, sebelum perbaikan) — harus LOLOS (membuktikan perbaikan berarti)"
cp alat/periksa-pemeriksaan.py /tmp/baru-$$.py
gh api "repos/With-AI-Agent/Resto-Barokah/contents/alat/periksa-pemeriksaan.py?ref=3f56abb%5E" --jq .content | base64 -d > alat/periksa-pemeriksaan.py
ubah PMB1-F-153 PALSU 'arena/x tanpa kartu'; jalan; git checkout -q -- .
cp /tmp/baru-$$.py alat/periksa-pemeriksaan.py
echo "== uji-diri penjaga baru"; python3 alat/periksa-pemeriksaan.py --uji-diri 2>&1 | tail -2 | cut -c1-150
cd "$AKAR"; rm -rf "$T" /tmp/baru-$$.py
