# MARATON G3 — T-05 — Isolasi penyewa ketika identitas kosong

- **Tugas:** T-05 · pekerja-2 · PEMERIKSA, laporan-saja.
- **Status penugasan saat terbit:** DIBERIKAN (disiapkan; bukan klaim pekerja telah mulai).
- **Repo:** With-AI-Agent/Resto-Barokah
- **Cabang sumber/integrator:** arena/01a0c2c1-resto-barokah
- **Commit target:** `e50bac4d897ca65b37dde9e64dbd246a3891b041`
- **CI target:** workflow CI, `.github/workflows/ci.yml`, SUCCESS run 35600019563, SHA `e50bac4d897ca65b37dde9e64dbd246a3891b041`; https://github.com/With-AI-Agent/Resto-Barokah/actions/runs/35600019563
- **Pembanding historis laporan AUD-2:** `09bcb89fc139b3be32ab874e7a004f0a3b0480ee` (bukan pengganti target).
- **SHA paket:** ambil SHA penuh dari prompt pendek yang Lee tempel. Paket ini terbit SETELAH target; jangan mencarinya di pohon target.
- **ID klaim wajib:** A-F02.
- **Lingkup tulis terpublikasi:** HANYA laporan berawalan `LAPORAN_G3_T05_` di folder `docs/uji/audit/`, diikuti UUID dan hash oleh pengirim. Tidak ada nomor migrasi cadangan.

## 0. Mandat, batas, dan bahan yang wajib dibaca

Lee menyetujui tiga pemeriksa paralel untuk **bantah-balik laporan yang sudah ada**.
Ini BUKAN mengulang audit AUD-2 penuh, bukan menghidupkan sesi ketiga yang error,
dan bukan izin implementasi/merge/deploy. Laporan lama tetap utuh. Kamu boleh
membantah klaim; jangan mencari pembenaran bagi pembangun/auditor.
T1-30/T1-45 tetap terbuka. Verdict laporan B tidak membatalkan K-2 laporan A.

Baca paket ini SELURUHNYA, lalu dari SHA PAKET baca:
- `docs/ops/PAPAN_TUGAS.md` baris T-05 dan bagian Gelombang 3.
- `docs/uji/TINDAK_LANJUT_AUD2_2026-09-21.md` (konteks/provenance/antrean).
- `docs/uji/PENGIRIMAN_LAPORAN_AMAN.md` (kontrak pengiriman).
- `PANDUAN_PENGGUNA.md` AL-16 **mode pemeriksaan laporan-saja**; aturan umum tidak memberi izin pull/merge pada gelombang ini.
- `skills/systematic-debugging/SKILL.md`, `skills/verification-before-completion/SKILL.md`, `skills/security-review/SKILL.md`, `skills/test-driven-development/SKILL.md`.
- Untuk SQL/identitas: `skills/supabase-postgres-best-practices/SKILL.md`; bila perlu skill lain gunakan katalog yang tersedia, jangan mengaku membaca skill yang tidak ada.

Kamu menerima tugas eksplisit, bukan melanjutkan sesi integrator: jangan menjalankan
orientasi `--susul`/checkout/pull otomatis dari template pekerja kode atau meminta
Lee memilih tugas lagi. Baca aturan tingkat atas tanpa mengganti cabang sesi.
Jika papan TERKINI sudah DIBATALKAN/DITERIMA atau mandat berubah, berhenti dari
pelaksanaan ulang dan laporkan; jangan menghidupkan tugas lama. Baca papan terbaru
melalui perintah berikut atau objek fetch spesifik:

```sh
gh api "repos/With-AI-Agent/Resto-Barokah/contents/docs/ops/PAPAN_TUGAS.md?ref=arena%2F01a0c2c1-resto-barokah" --jq .content | base64 --decode
```

Baca tanpa berpindah cabang,
bukan berpindah ke cabang sumber. Status DIBERIKAN berarti boleh memulai satu tugas ini.

## 1. Ambil target secara aman (termasuk repo privat)

Locator utama = repo + cabang sumber + SHA paket + path, melalui git/gh berizin;
web/raw URL tidak mewarisi autentikasi. Kalau objek belum lokal, fetch SHA spesifik
dengan `--no-write-fetch-head`, lalu baca `git show <SHA>:<path>`. Pastikan origin
memang repo di atas; jangan meminta sandi/token. Catat nama cabang sesimu dari
`git symbolic-ref --short HEAD`; namanya diberikan platform, **jangan buat/pindah
cabang pada checkout asli**. Sesi bisa berbagi cabang DAN working tree.
Jika cabangmu sama dengan sumber/main atau detached, hentikan pengiriman normal,
simpan laporan/hambatan; jangan mengubah cabang demi memaksa kelulusan.

Untuk pengujian, siapkan repo sementara **unik**, dengan nama cabang yang sama
seperti sesimu, bukan worktree yang mengubah metadata bersama. Jalankan dari
checkout sesi asli (git init/update-ref/restore di bawah HANYA untuk folder baru):

```sh
ASAL="$(git rev-parse --show-toplevel)"
SESI="$(git symbolic-ref --quiet --short HEAD)"
SHA_TARGET=e50bac4d897ca65b37dde9e64dbd246a3891b041
git fetch --no-write-fetch-head origin "$SHA_TARGET"
KERJA="$(mktemp -d)"
SALINAN="$KERJA/target"
git init -q --initial-branch "$SESI" "$SALINAN"
git -C "$SALINAN" fetch --no-write-fetch-head "$ASAL" "$SHA_TARGET"
git -C "$SALINAN" update-ref "refs/heads/$SESI" "$SHA_TARGET"
git -C "$SALINAN" restore --source="$SHA_TARGET" --staged --worktree :/
test "$(git -C "$SALINAN" rev-parse HEAD)" = "$SHA_TARGET"
git -C "$SALINAN" status --porcelain=v1  # harus kosong sebelum eksperimen
printf 'ASAL=%s\nKERJA=%s\nSALINAN=%s\n' "$ASAL" "$KERJA" "$SALINAN"
```

Catat path absolut; variabel shell bisa hilang antar-pemanggilan alat. Tidak ada
remote push di salinan uji. Semua npm/pip/probe/mutan/DB hanya di SALINAN/KERJA;
tidak boleh mengedit checkout asli atau menggunakan database/akun produksi.
Pustaka di sandbox boleh dipasang sesuai lockfile proyek, tanpa mengubah lockfile:
`npm ci --prefix "$SALINAN/alat"`; untuk PG nyata gunakan venv unik di KERJA,
`python3 -m venv "$KERJA/venv"` lalu `"$KERJA/venv/bin/python" -m pip install pgserver 'psycopg[binary]'`.
Perintah Python PG harus memakai interpreter venv itu. Jangan memakai port/direktori
DB tetap milik sesi lain. Sebutkan versi Node/Python/PG, dependency dan tiruan crypto.
Jika instalasi/jaringan tidak tersedia, laporkan keterbatasan; jangan menghitung
gagal setup sebagai kontrol keamanan bekerja. Tidak perlu uji koneksi Supabase nyata.

## 2. Artefak primer di target (baca definisi efektif dan pemanggil)

- `docs/uji/audit/LAPORAN_AUD-2_2026-09-21_terarah__01a0c39d.dari-5529eae.md`
- `supabase/migrations/0010_pembayaran.sql`
- `supabase/migrations/0023_acl_fungsi_pemicu.sql`
- `alat/uji-mutasi-0015.py`
- `alat/periksa-keamanan-sql.py`
- `alat/uji-konkuren.py`

Tambahkan PRD, TECH_SPEC, KEAMANAN dan seed/runner uji yang benar-benar diperlukan.
Berkas boleh **dibaca bersama**; lingkup eksklusif papan adalah penulisan laporan,
bukan larangan membaca kode yang sama. Semua eksperimen pada salinan masing-masing.

## 3. Urutan pembuktian dan DoD tugas

1. Baca aturan isolasi PRD/KEAMANAN dan definisi efektif total_dibayar, hitung_total, pesanan_sepenyewa serta helper terkait. Cari pola auth.uid() null di seluruh migrasi, lalu bedakan definisi terakhir dan yang sudah ditimpa.
2. Buat dua penyewa A/B dengan pesanan dan pembayaran sah. Pada target utuh, kontrol kasir B beridentitas sah harus tidak bisa membaca/mengubah pesanan A. Catat juga akses tabel langsung/RLS.
3. Probe SQL lokal: role authenticated dengan sub sah, sub kosong/null, claims kosong, dan role peladen yang memang sah menurut kode. Ukur auth.uid(), current_user, session_user dan current_setting('role', true) pada konteks relevan—di luar dan di dalam SECURITY DEFINER bila eksperimen memerlukannya.
4. Periksa total_dibayar pesanan tenant lain serta efek hitung_total sesudah commit. Catat nilai sebelum/sesudah, SQLSTATE dan izin EXECUTE efektif; hasil nol dari fixture kosong bukan bukti isolasi.
5. **Pisahkan tiga kesimpulan:** perilaku SQL terverifikasi, pelanggaran kontrak ancaman yang disepakati, dan keterjangkauan dari browser/PostgREST. Jangan menyebut eksploitasi jarak jauh terbukti tanpa jalur yang dibuktikan. Jangan menguji layanan produksi atau meminta token.
6. Usul penggunaan current_user di dalam definer dapat salah karena berubah menjadi pemilik fungsi. Bantah-balik usulan auditor itu juga. Peta jalur peladen/triggers yang memang membutuhkan identitas kosong; jangan menyarankan penolakan semua null secara buta.
7. Ulangi kasus inti pada PG nyata lokal bila tersedia; ungkap pgcrypto tiruan bila memakai loader proyek. Sertakan kontrol sah, lintas tenant dan tanpa identitas. Uji mutasi isolasi boleh dijalankan hanya di salinan. Galat setup/ACL/sintaks bukan bukti pagar bisnis.
8. Laporkan matriks per role × identitas × tenant × fungsi dengan keluaran mentah, severity yang dapat dipertanggungjawabkan dan bukti pembantah alternatif. Status A-F02 wajib TERBUKTI / TERBANTAH / BELUM-TERVERIFIKASI. Rekomendasi desain/tes untuk integrator, **tanpa migrasi/perubahan kode proyek**.

Cari dokumentasi resmi PostgreSQL/Supabase/GitHub bila menyimpulkan perilaku sistem
luar. Catat URL, tanggal akses dan bagian yang relevan. Jika akses internet gagal,
nyatakan batasnya—jangan mengganti hasil eksekusi dengan kutipan dokumentasi.

## 4. Format laporan (lengkap, bukan minimum jumlah temuan)

Tulis satu Markdown, bahasa Indonesia, tanpa rahasia/data produksi:

```markdown
# LAPORAN MARATON G3 — T-05
- Tugas: T-05
- Pemeriksa/sesi/cabang: isi fakta; jangan mengarang identitas model
- Target: e50bac4d897ca65b37dde9e64dbd246a3891b041
- Paket: SHA PAKET penuh + path paket ini
- Pembanding: 09bcb89fc139b3be32ab874e7a004f0a3b0480ee (atau tidak dijalankan, alasannya)
- Status: LENGKAP / PARTIAL / TERBLOKIR

## 1. Identitas dan lingkungan
SHA objek target, path salinan unik, versi runtime, role/klaim, engine/tiruan.
## 2. Matriks klaim
Satu baris per ID wajib: TERBUKTI / TERBANTAH / BELUM-TERVERIFIKASI + rujukan bukti.
## 3. Bukti reproduksi
Command, cwd, script/SQL/fixture LENGKAP, output mentah penting, exit code,
kontrol utuh vs cacat, sebelum/sesudah commit, ulang dan keterbatasan.
## 4. Analisis dan rekomendasi
Akar penyebab yang dibuktikan, dampak, alternatif yang dibantah, prioritas,
usulan regresi/perbaikan untuk integrator; tidak mengklaim sudah memperbaiki proyek.
## 5. Keterbatasan dan sisa
Daftar ID belum tuntas, penyebab, langkah lanjut konkret; temuan luar lingkup terpisah.
## 6. Integritas dan pengiriman
Checkout asli tidak diubah (kecuali draf/cadangan), namespace laporan sendiri,
niat tujuan repo/cabang/path. Bukti commit/hash remote diperoleh SETELAH pengirim jalan
lalu ditempel di chat; jangan mengubah laporan terikat hash hanya untuk memasukkan
SHA commit laporan itu sendiri (siklus referensi).
```

Probe tidak boleh hanya dirujuk `/tmp/...`: tempel isinya dalam laporan agar
integrator bisa mengulang setelah sandbox hilang. Dilarang klaim seluruh suite
hijau jika hanya uji terarah. Tidak perlu mengisi angka artefak/serangan palsu demi
ambang AUD-2; format di atas adalah kontrak **tugas reproduksi**, bukan audit penuh.

## 5. Checklist sebelum menyerahkan

- [ ] Target/paket/cabang/ID tepat; tiap ID wajib punya status dan bukti atau hambatan.
- [ ] Kontrol asli dan kasus cacat dibedakan; hasil mentah + exit + fixture lengkap tersedia.
- [ ] Fakta SQL, keterjangkauan klien dan dugaan dipisah; severity tidak dinaikkan tanpa bukti.
- [ ] Tidak ada perubahan kode produksi, nomor migrasi, keputusan uang atau centang tugas.
- [ ] Semua pekerjaan sisa punya ID/penanggung jawab/langkah lanjut, bukan hilang di chat.
- [ ] Tidak ada rahasia, sumber laporan penulis lain tidak ditimpa, prefix `LAPORAN_G3_T05_` tepat.
- [ ] Jalankan pengirim §6 otomatis, lalu laporkan bukti remote sebenarnya. Status PARTIAL/TERBLOKIR tetap boleh dikirim sebagai laporan jujur, tetapi tidak dihitung tugas selesai secara substantif.

Validasi checklist ini sendiri dan tulis hasilnya; integrator memvalidasi ulang saat
panen. **Jangan menjalankan --periksa-laporan AUD-2 untuk memaksa format ini menjadi
audit penuh.** Pemeriksaan format tidak membuktikan kebenaran temuan.

## 6. Pengiriman wajib — otomatis tanpa pengingat

Tanpa meminta Lee lagi, buat, validasi, **commit dan push otomatis** SATU laporan,
lalu **verifikasi remote**. Chat/lokal saja bukan selesai. Dua sesi bisa berbagi
cabang DAN working tree; nama cabang bukan ID unik. Jangan checkout, git add folder,
merge, rebase, reset, force-push, menimpa laporan, atau menyatukan verdict.

Akses paket privat melalui git/gh terautentikasi: identitas repo + cabang sumber +
SHA paket penuh + path pada prompt pendek. SHA paket BUKAN SHA target audit.
Baca paket SELURUHNYA; URL hanya tambahan (web tool tidak mewarisi autentikasi git/gh).
Jika akses/sasaran gagal, berhenti dan laporkan keterbatasan, jangan menebak/minta token.

Ambil alat pengirim dari **SHA paket pada prompt pendek**, bukan target audit yang
lebih tua. Tetap jalankan dari checkout cabang SESIMU SENDIRI, bukan salinan target:

```sh
SHA_PAKET=<SHA-paket-penuh-dari-prompt-pendek>
git fetch --no-write-fetch-head origin "$SHA_PAKET"
RUNNER="$(mktemp -d)"
git show "$SHA_PAKET:alat/kirim_laporan.py" > "$RUNNER/kirim_laporan.py"
git show "$SHA_PAKET:alat/kirim-laporan.py" > "$RUNNER/kirim-laporan.py"
python3 "$RUNNER/kirim-laporan.py" --jenis audit --penanda G3_T05 --sumber arena/01a0c2c1-resto-barokah --siapkan
```

`--siapkan` mengalokasikan draf `LAPORAN_*_<UUID>.md` secara eksklusif di
`.laporan-lokal/` (diabaikan Git). Catat path keluaran sebagai LAPORAN; isi hanya
laporanmu, jangan mengedit milik penulis lain. Validasi format dengan checklist §5 paket ini (bukan ambang audit menyeluruh); perubahan orang lain di checkout bersama bukan
alasan untuk membersihkannya. Draf/cadangan dan salinan uji boleh dibuat, kode proyek
asli tidak boleh diubah. Setelah validasi, langsung kirim tanpa menunggu Lee:

```sh
python3 "$RUNNER/kirim-laporan.py" --jenis audit --penanda G3_T05 --sumber arena/01a0c2c1-resto-barokah --laporan "$LAPORAN"
```

Pengirim menyimpan snapshot sebelum jaringan; membuat commit **satu tambahan**
laporan bernama hash isi, dalam Git/index sementara; normal push fast-forward saja.
Jika didahului penulis lain, ambil tip remote lalu buat kandidat BELUM TERBIT lagi
(maksimal 5 upaya, bukan rebase/merge); jangan menyentuh HEAD/index/berkas bersama.
Jika cabang belum ada, dasar lokal harus sudah bisa diambil dari origin. Bila
riwayat mundur, path berbeda isi/mode, akses/izin hilang, atau upaya habis: **TERBLOKIR,
pengiriman BELUM TERVERIFIKASI**. Pertahankan snapshot dan berikan path/hambatan/jalur
pemulihan kepada integrator; jangan klaim selesai, jangan meminta sandi/token.
Pemulihan oleh integrator hanya untuk hambatan nyata, bukan antrean wajib normal.

Bukti akhir WAJIB: **repo, cabang tujuan, path laporan, commit SHA, remote_tip,
SHA-256 dan hasil verifikasi remote** dari pengirim. Pemeriksaan membaca ulang ref
langsung dan membandingkan blob/byte di GitHub; exit push saja bukan bukti.
HEAD lokal sengaja tetap: jangan pull/commit ulang, sinkronisasi kelak fast-forward
hanya jika working tree aman. Transport terverifikasi bukan pengesahan isi/verdict.


Bila autentikasi terputus, simpan laporan dan nyatakan sambungan GitHub perlu
perhatian; jangan meminta kredensial lewat chat. Jangan menunda semua hasil hanya
karena satu ID belum bisa diuji. Laporkan ringkas ke Lee: tugas, status substansi,
ID terverifikasi/belum, lokasi laporan dan bukti remote. Akhiri **Langkah Lee**.

## 7. Apa yang dilakukan integrator (bukan kewenangan pekerja)

Integrator memanen setiap laporan tanpa menunggu semua selesai; periksa repo/ref/blob,
SHA target dan ID, arsipkan append-only tanpa merge cabang/kode pekerja, ulangi
probe secara independen. Laporan bertentangan tidak disatukan verdictnya. Perbaikan
uang/identitas dilakukan berurutan setelah bukti cukup: regresi merah → migrasi baru
bila perlu → kontrol hijau + mutasi + regresi lintas area + CI commit perbaikan.
Tugas DITERIMA hanya dengan bukti penerimaan; penerimaan laporan bukan penutupan
K-2/T1-30/T1-45. Review independen tambahan jika perubahan berisiko, merge/deploy
butuh izin terpisah. Pekerja tidak mengubah papan/handoff/ROADMAP.
