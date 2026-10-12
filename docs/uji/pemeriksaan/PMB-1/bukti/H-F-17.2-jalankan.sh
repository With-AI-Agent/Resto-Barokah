#!/usr/bin/env bash
# ============================================================================
# H-F-17.2 — reproduksi HAKIM atas temuan kalibrasi PMB1-F-192 … PMB1-F-201
#
# Jalankan dari akar repo (butuh: node + `npm ci --prefix alat` untuk uji SQL):
#     bash docs/uji/pemeriksaan/PMB-1/bukti/H-F-17.2-jalankan.sh            # semua kecuali suite penuh
#     bash docs/uji/pemeriksaan/PMB-1/bukti/H-F-17.2-jalankan.sh --penuh    # + seluruh suite SQL (±2 menit)
#
# Kepatuhan aturan bahan kalibrasi (PROMPT_GILIRAN §0, bahan-tahap-1/README.md):
#   • kalibrasi/KUNCI-* TIDAK dibuka; git log / git diff folder kalibrasi TIDAK dibaca;
#   • TIDAK ada perbandingan baris demi baris cuplikan vs dokumen aslinya sendiri;
#   • pembanding = kode/migrasi/uji + dokumen fondasi LAIN + hasil RUN (probe & mutan di bawah).
# Skrip hanya MEMBACA berkas proyek; berkas sementara ditulis ke /tmp saja.
# ============================================================================
set -u
cd "$(git rev-parse --show-toplevel)" || exit 2
B=docs/uji/pemeriksaan/PMB-1/kalibrasi/bahan-tahap-1
BK=docs/uji/pemeriksaan/PMB-1/bukti
PROBE=$BK/H-F-17.2-probe-runtime.sql
MIG=supabase/migrations
KODE=0
SALAH_RUJUKAN=0

run() { printf '$ %s\n' "$1"; eval "$1" 2>&1 | cut -c1-250; }
judul() { printf '\n## %s\n' "$1"; }
sqltest() { node alat/uji-sql.mjs "$@" 2>&1 | sed -n '/Menjalankan/,$p' | grep -v '^$' | head -8; }

echo "# REPRODUKSI HAKIM H-F-17.2 — $(date -u +%Y-%m-%dT%H:%MZ) · commit $(git rev-parse --short HEAD) · node $(node --version)"

# ---------------------------------------------------------------------------
judul "0. Rujukan berkas:baris pemeriksa — apakah baris itu benar-benar memuat kalimat yang diklaim (pelajaran PMB1-F-094)"
chk() { # berkas baris kutipan
  if sed -n "${2}p" "$1" | grep -qF -- "$3"; then echo "OK    $1:$2 memuat «$3»"
  else echo "SALAH $1:$2 TIDAK memuat «$3» → baris itu: $(sed -n "${2}p" "$1" | cut -c1-80)"; SALAH_RUJUKAN=$((SALAH_RUJUKAN+1)); fi; }
chk $B/PRD-cuplikan.md 14 "void masih diperbolehkan dengan PIN owner"
chk $B/PRD-cuplikan.md 8 "bawaan sampai tiga diskon per transaksi"
chk $B/PRD-cuplikan.md 23 'bawaan `false`/fleksibel'
chk $B/KEAMANAN-cuplikan.md 8 "10×/15 menit per akun"
chk $B/KEAMANAN-cuplikan.md 8 "RENCANA Fase 1B"
chk $B/KEAMANAN-cuplikan.md 17 "pemilik platform 30 hari"
chk $B/KEAMANAN-cuplikan.md 18 "hanya berlaku di luar jam aktif"
chk $B/KEAMANAN-cuplikan.md 21 "5×/15 menit per akun"
chk $B/KEAMANAN-cuplikan.md 22 "5×/15 menit per akun"          # baris 22 = 'Pencabutan' → SALAH (F-195 menulis baris 22; yang benar 21)
chk $B/ROADMAP-cuplikan.md 3 "128/128"
chk $B/ROADMAP-cuplikan.md 9 "disaksikan pemilik di perangkat kasir nyata"
chk $B/ROADMAP-cuplikan.md 17 "aplikasi/src/layar/kas/"
chk docs/DECISIONS_LOG.md 323 "T-025"                           # dirujuk F-192 → SALAH (baris 323 = uji Playwright)
chk docs/PRD.md 323 "hapus janji void terselubung sesudah bayar"   # kutipan yang dirujuk F-192 ternyata ada di PRD.md:323
chk docs/DECISIONS_LOG.md 1505 "LARANG ubah/void sesudah bayar"  # yang benar
chk docs/DECISIONS_LOG.md 1527 "sesudah bayar dicatat sebagai pembatalan berizin"
chk docs/ROADMAP.md 2036 "132/132"                              # dirujuk F-199 → tidak memuat bentuk '132/132' (memuat '132 berkas uji SQL lulus')
chk docs/ROADMAP.md 2036 "132 berkas uji SQL lulus"
echo "(SALAH di atas = koreksi rujukan untuk kolom Hakim; substansi temuan dinilai di bagian 1–9)"

# ---------------------------------------------------------------------------
judul "1. PMB1-F-192 — void sesudah pembayaran pertama (PRD-cuplikan:14)"
run "sed -n 14p $B/PRD-cuplikan.md | cut -c1-240"
run "sed -n 59p docs/TERTANGGUH.md | grep -o 'DIPUTUSKAN[^|]*' | cut -c1-230"
run "sed -n '1,2p;41p;81p' $MIG/0022_beku_setelah_bayar.sql"
run "sed -n 1527p docs/DECISIONS_LOG.md | cut -c1-260"
echo "→ runtime: probe C (kursi OWNER; kontrol positif void SEBELUM bayar) + uji bawaan beku_setelah_bayar.sql — lihat bagian 10–11"

# ---------------------------------------------------------------------------
judul "2. PMB1-F-193 — bawaan diskon (PRD-cuplikan:8)"
run "sed -n 8p $B/PRD-cuplikan.md | cut -c1-230"
run "grep -n tumpuk_diskon $MIG/0002_pengguna_izin_pengaturan.sql | head -2"
run "sed -n '75,78p;127p' $MIG/0019_pesan_diskon_jujur.sql | cut -c1-220"
run "sed -n 204p docs/DECISIONS_LOG.md | grep -o 'Tumpuk diskon mengikuti pengaturan resto[^.]*\.'"
echo "→ runtime: probe D (katalog default) + uji bawaan diskon_tumpuk.sql & diskon_cap_bawaan.sql — bagian 10–11"

# ---------------------------------------------------------------------------
judul "3. PMB1-F-194 — wajib_shift bawaan fleksibel vs T7-04 DoD (PRD-cuplikan:23 vs ROADMAP-cuplikan:5-9)"
run "sed -n 23p $B/PRD-cuplikan.md | cut -c1-330"
run "sed -n '5p;9p' $B/ROADMAP-cuplikan.md | cut -c1-260"
run "sed -n 28p $MIG/0048_wajib_shift.sql"
run "sed -n '4,9p' supabase/tes/wajib_shift.sql"
echo "→ dua mode terdokumentasi di uji bawaan: fleksibel (bawaan) dan wajib; DoD T7-04 tidak menyebut bahwa penolakan hanya berlaku di mode wajib"

# ---------------------------------------------------------------------------
judul "4. PMB1-F-195 — batas percobaan per akun (KEAMANAN-cuplikan:8 vs :21)"
run "sed -n '8p;21p' $B/KEAMANAN-cuplikan.md | cut -c1-140"
run "sed -n '130p;134p' $MIG/0087_perbaiki_search_path_kripto_dan_rpc.sql | cut -c1-170"
run "sed -n 180p supabase/tes/pin.sql"
echo "→ runtime: probe B (RPC login asli; 4 salah belum terkunci, 5 salah mengunci walau PIN benar)"

# ---------------------------------------------------------------------------
judul "5. PMB1-F-196 — 'penyatuan ke percobaan_masuk = RENCANA' (KEAMANAN-cuplikan:8) — diuji sampai PERILAKU"
run "sed -n 8p $B/KEAMANAN-cuplikan.md | cut -c130-420"
run "grep -n 'create table if not exists public.percobaan_' $MIG/*.sql"
run "grep -in 'drop table[^;]*percobaan' $MIG/*.sql | wc -l"
run "sed -n '118,125p;146p' $MIG/0087_perbaiki_search_path_kripto_dan_rpc.sql | cut -c1-110"
run "grep -rn 'catat_percobaan_masuk\|periksa_kunci_masuk' aplikasi/src supabase/functions | grep -v '\.test\.' | wc -l"
run "grep -n 'catat_percobaan_masuk(\|periksa_kunci_masuk(\|catat_percobaan_masuk_tenant(' $MIG/*.sql | grep -v 'create or replace\|comment on\|revoke\|grant' | wc -l"
run "sed -n 431p docs/ROADMAP.md | cut -c1-200"
echo "→ runtime: probe B4/E (percobaan_masuk KOSONG sesudah alur login asli; percobaan_pin terisi)"

# ---------------------------------------------------------------------------
judul "6. PMB1-F-197 — umur maksimum sesi (KEAMANAN-cuplikan:17)"
run "sed -n 17p $B/KEAMANAN-cuplikan.md | cut -c1-200"
run "sed -n '469,478p' $MIG/0030_sesi_dan_persetujuan_perangkat.sql"
run "grep -c 'create or replace function public.ikat_sesi_perangkat' $MIG/*.sql | grep -v ':0$'"
run "grep -n -i 'umur\|12 hours\|8 hours\|30 days' \$(grep -l ikat_sesi_perangkat supabase/tes/*.sql) | cut -c1-160"
run "grep -rn 'ikat_sesi_perangkat' aplikasi/src supabase/functions | grep -v '\.test\.' | wc -l"
echo "→ runtime: probe A (RPC ikat_sesi_perangkat: kasir 12 jam · owner 30 hari · pemilik_platform 8 jam)"

# ---------------------------------------------------------------------------
judul "7. PMB1-F-198 — kunci otomatis 'hanya di luar jam aktif' (KEAMANAN-cuplikan:18)"
run "sed -n 18p $B/KEAMANAN-cuplikan.md | cut -c1-330"
run "sed -n '69,74p' aplikasi/src/hook/useKunciOtomatis.ts"
run "sed -n '19,24p' aplikasi/src/hook/useKunciOtomatis.ts"
run "grep -rn 'useKunciOtomatis' aplikasi/src | grep -v 'hook/useKunciOtomatis' | grep -v '\.test\.' | wc -l"

# ---------------------------------------------------------------------------
judul "8. PMB1-F-199 — angka berkas uji SQL (ROADMAP-cuplikan:3)"
run "sed -n 3p $B/ROADMAP-cuplikan.md"
run "ls supabase/tes/*.sql | wc -l"
run "grep -rn -o '132/132[^,.;]\{0,30\}' docs/ops/DEPLOY.md docs/teknis/TINJAUAN_KEAMANAN_F10.md docs/uji/PAKET_AUDIT_F10_3_AGEN.md | head -4"
run "sed -n 2036p docs/ROADMAP.md | grep -o '132 berkas uji SQL lulus[^)]*'"
run "sed -n '1929p;2008p' docs/ROADMAP.md | grep -o 'Bukti 2026-09-27\|126 berkas uji SQL lulus\|131 berkas lolos'"

# ---------------------------------------------------------------------------
judul "9. PMB1-F-200 / F-201 — klaim vs kenyataan (T7-04) dan rujukan berkas (T7-05)"
run "sed -n '9p;12p' $B/ROADMAP-cuplikan.md | cut -c1-260"
run "grep -rli 'berita acara' docs | grep -v 'pemeriksaan/PMB-1' | wc -l"
run "ls supabase/tes/wajib_shift.sql && grep -n 'create trigger' $MIG/0048_wajib_shift.sql && grep -n 'tombol_buka_kas_cepat' aplikasi/src/layar/kasir/LayarKasir.tsx"
run "sed -n 566p docs/teknis/REKAM_PESAN_PEMILIK.md | cut -c1-230"
run "sed -n '17p;18p' $B/ROADMAP-cuplikan.md | cut -c1-200"
run "ls -d aplikasi/src/layar/kas; ls aplikasi/src/komponen/PengingatShift.tsx"
run "grep -n -i 'tengah\|malam\|midnight\|melewati_tengah' $MIG/0085_ringkasan_harian.sql | wc -l"
run "sed -n 17p $MIG/0049_pengingat_shift.sql | cut -c1-140; sed -n 618p aplikasi/src/layar/laporan/LaporanKas.tsx"

# ---------------------------------------------------------------------------
judul "10. PROBE RUNTIME — dipanggil dari kursi peran sungguhan (harus LULUS)"
run "node alat/uji-sql.mjs $PROBE 2>&1 | sed -n '/Menjalankan/,\$p' | grep -v '^\$' | head -5"

judul "10b. KONTROL NEGATIF PROBE — mutan yang menuliskan klaim bahan/pemeriksa harus MERAH (bila LULUS = probe tumpul)"
python3 $BK/H-F-17.2-mutasi.py | tr '\n' ' '; echo
cekmutan() { # nama  pola-galat
  local keluar; keluar=$(node alat/uji-sql.mjs "/tmp/H-F-17.2-mutan-$1.sql" 2>&1 | sed -n '/Menjalankan/,$p')
  if echo "$keluar" | grep -q "GAGAL" && echo "$keluar" | grep -q -- "$2"; then
    echo "MERAH sesuai harapan · mutan $1 → $(echo "$keluar" | grep -m1 -o -- "$2.*" | cut -c1-210)"
  else
    echo "TUMPUL! mutan $1 tidak merah dengan pola «$2»:"; echo "$keluar" | head -6; KODE=$((KODE+1))
  fi
}
cekmutan A "F-197 umur sesi pemilik_platform"
cekmutan B "F-195 PIN BENAR setelah 5 salah"
cekmutan C "BY-201"
cekmutan D "F-193 bawaan kolom"
cekmutan E "F-196 tabel percobaan_masuk KOSONG"

# ---------------------------------------------------------------------------
judul "11. UJI SQL BAWAAN REPO yang mengunci perilaku yang sama (harus LULUS)"
for f in beku_setelah_bayar diskon_tumpuk diskon_cap_bawaan wajib_shift pin sesi_kedaluwarsa percobaan_masuk_tenant; do
  printf '%-28s ' "$f.sql"; node alat/uji-sql.mjs supabase/tes/$f.sql 2>&1 | grep -E "^  (LULUS|GAGAL)" | head -1
done

if [ "${1:-}" = "--penuh" ]; then
  judul "12. SUITE SQL PENUH (F-199: jumlah berkas uji hari ini)"
  run "node alat/uji-sql.mjs 2>&1 | tail -3"
fi

echo; echo "# SELESAI — rujukan pemeriksa yang SALAH (sengaja dilaporkan untuk koreksi di kolom Hakim; harapan hakim: 3): $SALAH_RUJUKAN · masalah skrip/probe (mutan tumpul atau gagal dibuat; harapan 0): $KODE"
exit 0
