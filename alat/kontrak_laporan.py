"""Satu kontrak pengiriman untuk paket audit dan review yang baru dibuat."""

def blok_pengiriman(jenis: str, sumber: str) -> str:
    return f'''Tanpa meminta Lee lagi, buat, validasi, **commit dan push otomatis** SATU laporan,
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
python3 "$RUNNER/kirim-laporan.py" --jenis {jenis} --sumber {sumber} --siapkan
```

`--siapkan` mengalokasikan draf `LAPORAN_*_<UUID>.md` secara eksklusif di
`.laporan-lokal/` (diabaikan Git). Catat path keluaran sebagai LAPORAN; isi hanya
laporanmu, jangan mengedit milik penulis lain. Validasi format dengan pemeriksa
paket pada salinan terisolasi; perubahan orang lain di checkout bersama bukan
alasan untuk membersihkannya. Draf/cadangan dan salinan uji boleh dibuat, kode proyek
asli tidak boleh diubah. Setelah validasi, langsung kirim tanpa menunggu Lee:

```sh
python3 "$RUNNER/kirim-laporan.py" --jenis {jenis} --sumber {sumber} --laporan "$LAPORAN"
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
'''
