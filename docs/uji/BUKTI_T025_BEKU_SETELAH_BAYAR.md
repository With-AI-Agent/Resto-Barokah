# Bukti T-025(a) — pembekuan setelah pembayaran pertama

Tanggal: 2026-09-21 · pelaksana: sesi `arena/01a0c2c1-resto-barokah`.
**Status: implementasi + bukti lokal; bukan pengesahan AUD-2 atau izin sebar.**

## Prasyarat dan cakupan

CI hosted **35571459040** pada commit `73bd831c4226ad0d69926484ec65d2f35d30249d`
SUCCESS (job 106243790570, 7m53s), diperiksa **sebelum** implementasi.
Persetujuan: T-025(a) di `docs/DECISIONS_LOG.md`. Pembayaran Rp1 pun mengunci
isi/nominal; tidak membuat prosedur refund, koreksi kas, atau izin pembukaan ulang.

Migrasi `supabase/migrations/0022_beku_setelah_bayar.sql`:
- BEFORE item/diskon/void mengunci parent lama **dan** tujuan berurutan; kunci
  sama dengan jalur pembayaran. Sesudah menunggu, baca ulang keberadaan uang.
- Tidak ada pengecualian peladen/null-auth. Pesan penolakan **BY-201**.
- Header pesanan menjadi pertahanan kedua untuk penulisan ulang total/identitas,
  pembatalan, dan penghapusan. Penjaga izin/status/jejak sebelumnya tetap bekerja.
- Progres item murni `baru → dimasak → siap` tidak menghitung ulang tarif pajak
  hari ini. Bukan izin klien baru: aturan lama tetap menentukan siapa/status
  apa yang boleh maju. Pembayaran terbagi tetap diterima.
- Tidak mengubah 0001–0016 yang dibekukan; tidak menulis ulang transaksi lama.

## Bukti yang dapat diulang

| Perintah | Hasil lokal |
|---|---|
| `node alat/uji-sql.mjs` | 64 berkas hijau; baseline sebelum perubahan 63/63 |
| `python3 alat/uji-mutasi-0022.py` | 9 mutasi wajib merah, kontrol awal/akhir hijau, sintaks rusak ditolak sebagai bukti |
| `python3 alat/uji-konkuren-0022.py` | 5 kontrol dua arah + 2 mutasi pelanggaran tersimpan, seluruhnya sesuai harapan |
| `python3 alat/uji-konkuren.py` | F F-12/F-13 utuh hijau dan mutasi peka |
| `python3 alat/uji-mutasi-0014.py` | 17/17 wajib merah |
| `python3 alat/uji-mutasi-0015.py` | seluruh mutasi wajib merah, kontrol pulih hijau |
| `python3 alat/uji-mutasi-0017.py` | seluruh mutasi wajib merah |
| `python3 alat/uji-mutasi-0021.py` | 2 mutasi wajib merah |

Regresi baru dijalankan **sebelum** 0022: pengurangan qty setelah pembayaran Rp1
benar-benar diterima dan asersi gagal. Sesudah 0022 asersi hijau. Empat fixture
lama (`jejak_pelaku`, `pembayaran`, `uang_peladen`, `void_satu_item`) dipisahkan
antara kontrol sebelum bayar dan penolakan sesudah bayar — tidak menghapus
pemeriksaan izin/PIN/atribusi/cap maupun void item terakhir sebelum bayar.

Mutasi 0022 menuntut kegagalan **HARAPAN TIDAK TERPENUHI**, bukan hanya salah
pesan penolakan. Pagar berlapis dimatikan bersama bila diperlukan (void dan
parent tujuan); itu kalibrasi salinan, bukan perubahan skema utuh. Pagar cap
F F-12 kini punya dua kunci BEFORE (0021 + 0022); kalibrasinya membuang keduanya
agar cacat serialisasi benar-benar dapat muncul.

Uji concurrency memakai PostgreSQL pgserver, READ COMMITTED, dua penulis dan
koneksi pengamat `pg_blocking_pids`, bukan asumsi jeda waktu. Bayar → catatan,
bayar → qty, bayar → void ditolak BY-201; qty/void → bayar memeriksa nominal/status
terbaru. Mutasi tanpa kunci mengizinkan catatan berubah setelah uang Rp1 masuk;
mutasi tanpa pagar void menyimpan void, total nol, dan uang Rp1 bersamaan.
Timeout, SQL rusak, deadlock, atau galat koneksi **bukan** keberhasilan kalibrasi.

## Gerbang lanjut — wajib dibaca agent berikutnya

1. **Pemilik tindak lanjut: agent T1-45.** AUD-2 independen untuk migrasi 0022 +
   harness-nya sebelum mengklaim penutupan penuh I F-17 / K F-02. CI hijau wajib
   pada commit sasaran sebelum membuat paket. Jangan centang T1-45 hanya dari
   bukti sendiri. Langkah berikutnya ada di `docs/ops/SIAP-LANJUT.md` §3.
2. **Pemilik: Lee + agent penyebaran.** Sebar skema hanya atas izin terpisah,
   sesudah audit. Verifikasi pada Supabase asli (RLS, pgcrypto, migrasi, RPC),
   bukan menganggap pgserver/crypto tiruan sebagai bukti produksi.
3. **Sebelum pilot:** periksa anomali transaksi lama (jika ada). Migrasi ini
   mencegah perubahan berikutnya, bukan rekonsiliasi retroaktif atau refund.
4. **Pemilik: agent alur kasir (T3).** Tampilkan BY-201 sebagai larangan ubah
   setelah pembayaran pertama; jangan menawarkan void/refund yang belum
   disetujui. Transaksi multi-pernyataan dengan isolasi lain memerlukan uji
   tersendiri; bukti concurrency di sini khusus READ COMMITTED jalur aplikasi.
