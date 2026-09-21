# Kontrak pengiriman laporan independen — 2026-09-21

Berlaku untuk audit, review PR, dan pemeriksaan independen berikutnya. Paket yang
sudah terbit tidak disunting; paket baru memakai `alat/kontrak_laporan.py`.
Generator prompt pendek menolak paket lama tanpa kontrak pengiriman baru (termasuk
instruksi git-add-folder), bukan diam-diam menerbitkannya ulang. Tidak meminta ulang
auditor yang sudah bekerja.

## Akses privat dan dua SHA

Locator utama: **identitas repo + cabang sumber + SHA paket penuh + path**.
Git/gh memakai autentikasi repo; web tool/raw URL tidak otomatis mewarisinya.
SHA paket memuat paket/protokol/pengirim, SHA target adalah kode yang diperiksa;
jangan menyamakan keduanya. Akses gagal → gagal-tertutup, tidak menebak target dan
tidak meminta token/sandi di chat (hubungkan kembali GitHub di Arena bila perlu).
Baca **seluruh** paket, termasuk protokol dan skill. Baca target lewat objek Git
atau salinan sementara unik; jangan checkout/detach pada working tree bersama.

## Jalur wajib, otomatis tanpa meminta Lee lagi

1. Tetap pada cabang Arena sesi sendiri; jangan buat/pindah cabang atau push sumber/main.
2. Ambil `alat/kirim-laporan.py` dan `alat/kirim_laporan.py` dari SHA **paket**, simpan
   dalam direktori sementara unik. Jalankan dari checkout sesi, bukan salinan target.
3. Jalankan `python3 <runner>/kirim-laporan.py --jenis audit --sumber <cabang-sumber> --siapkan`.
   Untuk review gunakan `--jenis review-pr`. Hasilnya path draf UUID yang dialokasikan
   secara eksklusif, bukan penanda cabang (cabang bisa sama antar-sesi).
4. Isi laporan di path tersebut; validasi format sesuai paket dalam salinan terisolasi
   bila checkout bersama kotor. Dilarang membersihkan/stage pekerjaan orang lain.
5. Langsung jalankan pengirim dengan parameter sama, ganti `--siapkan` menjadi
   `--laporan <path-draf>`. Tidak perlu Lee memerintah commit/push lagi.
6. Akhiri dengan bukti **repo, cabang tujuan, path, commit SHA, remote_tip, SHA-256,
   hasil verifikasi remote**. Chat/lokal saja bukan selesai. Transport terverifikasi
   tidak mengesahkan temuan/verdict atau menutup gerbang audit.

Pengirim menyimpan snapshot `.laporan-lokal/` sebelum menghubungi jaringan. Proses
menggunakan bare repo/index sementara sendiri dan autentikasi `gh auth git-credential`
(tidak menyalin token). Tree remote disalin, **tepat satu tambahan** laporan dibuat
menggunakan commit-tree satu parent; tidak ada git add atas folder bersama.
Path akhir mengandung SHA-256 isi; nama sama + isi berbeda menjadi dua berkas.
Isi identik + nama sama idempoten. Path sudah ada dengan isi/mode berbeda → ditolak,
bukan ditimpa; induk symlink/submodule/berkas juga ditolak.

Normal push ke cabang sendiri saja. Jika penulis lain mendahului, fetch tip baru
lalu susun kandidat **belum terbit** lagi (maksimum 5 kali); bukan rebase/merge
riwayat. Cabang belum tersedia boleh dibuat hanya dari dasar yang bisa diambil
dari origin; rantai lokal yang belum diterbitkan tidak ikut dikirim. Remote mundur,
izin gagal, batas retry, putus jaringan → berhenti aman. HEAD, index, refs dan berkas
checkout asal tidak disentuh. HEAD lokal sengaja tertinggal; sinkronisasi berikutnya
hanya fast-forward saat aman, bukan pull/merge otomatis pada tree bersama.

Verifikasi membaca ref langsung dari server, fetch objek tip, cocokkan mode, blob
serta byte laporan dan pastikan riwayat remote tidak mundur. Balasan push yang hilang
bisa berarti server sudah menerima; alat memeriksa remote sebelum menyimpulkan.
**Tidak ada jaminan mutlak** terhadap kehilangan izin/jaringan, penulis di luar
protokol yang force-push sesudah verifikasi, atau proses yang mati sebelum snapshot.
Nama UUID/content hash memperkecil bentrok, bukan bukti matematika nihil collision.

## Bila terblokir

Status **TERBLOKIR — pengiriman BELUM TERVERIFIKASI**, bukan selesai atau pasti belum
terkirim. Pertahankan draf/snapshot; sebutkan path, checksum bila tersedia, hambatan,
repo/cabang tujuan dan langkah pemulihan. Jangan force, reset, rebase, merge atau
menyatukan verdict untuk menyelesaikannya. Integrator mengambil snapshot yang
tersedia melalui saluran sesi/berkas, memverifikasi byte, lalu mengirim salinan
append-only dari cabangnya sendiri; tidak mengambil kode auditor. Ini cadangan
untuk hambatan nyata, bukan antrean manual wajib setiap laporan. Akses yang sungguh
terputus mungkin tetap membutuhkan pemulihan sambungan oleh Lee; jangan menjanjikan
bahwa prompt dapat mengatasi izin yang tidak ada.

## Mengapa bukan solusi sebelumnya?

- Sufiks cabang bukan ID sesi: insiden 5529eae/b8290b3 membuktikan cabang DAN nama sama.
- UUID saja tidak melindungi index/HEAD bersama; karena itu commit disusun terisolasi.
- Hanya `pull --ff-only` tidak menyelesaikan dua commit saudara; jangan merge/rebase.
- Push `--atomic` tidak otomatis menangani race satu ref; normal push tetap harus retry.
- API Contents tetap menghadapi konflik dan menambah jalur otentikasi/API; Git plumbing
  memanfaatkan penolakan non-fast-forward yang sudah ada. Penolakan itu pagar, bukan cacat.
- Integrator sebagai antrean wajib membebani Lee dan mengurangi otomatisasi.

## Dasar resmi yang dibaca (2026-09-21)

- Git push: https://git-scm.com/docs/git-push — penolakan non-fast-forward melindungi
  riwayat; `--force`/`+` mengabaikannya, tidak digunakan.
- Git fetch: https://git-scm.com/docs/git-fetch — ambil objek/ref spesifik tanpa checkout.
- Git commit-tree: https://git-scm.com/docs/git-commit-tree — membuat objek commit dari
  tree dan parent eksplisit; satu parent bukan merge, tidak harus menggeser HEAD.
- Git update-index: https://git-scm.com/docs/git-update-index — cacheinfo memasukkan
  mode/blob/path langsung; alat memakai index temporary, bukan index checkout.
- GitHub Contents: https://docs.github.com/en/rest/repos/contents#get-repository-content
  — repo privat memerlukan akses Contents(read), ref dapat berupa commit; akses web
  generik bukan bukti bahwa sesi git/gh kehilangan izin.

## Bukti uji

`python3 alat/uji-kirim-laporan.py` memakai remote bare sungguhan: dua penulis
bersamaan (cabang/nama sama), konten identik, fast-forward retry, no merge, satu
path/satu parent, staged+untracked+refs lokal utuh, collision isi, symlink, push
rejected, balasan hilang, sukses palsu tanpa objek remote, input biner/traversal.
Uji ini bukan uji ketersediaan layanan GitHub atau simulasi semua gangguan.
