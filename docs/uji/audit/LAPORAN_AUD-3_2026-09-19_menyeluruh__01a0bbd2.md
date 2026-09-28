# LAPORAN AUDIT INDEPENDEN — AUD-3 — 2026-09-20

- **Auditor:** Arena.ai Agent Mode — sesi independen `arena/01a0bbd2-resto-barokah`
- **Tanggal:** 2026-09-20
- **Tingkat audit:** `AUD-3`
- **Commit yang diaudit:** `4830b5a4f876744ecb37e2f4495c6df234376752`
- **Paket audit:** `docs/uji/paket-audit/AUD-3-2026-09-19.md`
- **Mode cakupan:** `menyeluruh`
- **Verdict:** `TIDAK-BERSIH`

**Ringkasan keputusan.** Saya memeriksa clone target yang detached tepat pada SHA di atas, bukan HEAD checkout sesi kerja dan bukan SHA yang tertulis di paket lama. Dua cacat K-1 terverifikasi pada jalur uang (rumus pajak/service dan penulisan ulang pesanan lunas), serta beberapa cacat K-2 terverifikasi (metode bayar nonaktif, status/pembatalan item, jejak audit yang belum ada, dan kontrol keamanan yang belum mendarat). Karena ada K-1/K-2 terverifikasi, verdict tidak boleh lebih tinggi dari `TIDAK-BERSIH`.

## 1. Cakupan

Target dibaca dari `/tmp/resto-audit-4830b5a` dengan `git status --short` kosong dan `git rev-parse HEAD` menghasilkan SHA target yang sama persis. Saya tidak mengaudit commit lain. Perintah `--verifikasi-lingkup` dari paket tidak dipakai sebagai bukti target karena paket lama mengikat dirinya ke SHA `93a50baccffc23ca0f41a9f636fed03b447ae391`.

**Cakupan menyeluruh: 480 dari 436 berkas pada paket audit; 44 berkas target tambahan ditemukan dan ikut diperiksa, sehingga total target aktual adalah 480 berkas non-vendored.** Angka aktual dihitung dari pohon Git target, bukan dari snapshot meja kerja auditor. Grup berikut berjumlah 480.

| # | Artefak/grup target | Diperiksa | Bukti (perintah/baris) |
|---|---|---:|---|
| 1 | `.github/workflows` | 3 | `git ls-files .github/workflows` |
| 2 | `aplikasi/src` | 73 | `find aplikasi/src -type f -print \\| sort` dan `nl -ba aplikasi/src/lib/supabase.ts` |
| 3 | `aplikasi/alat` | 10 | `git ls-files aplikasi/alat` |
| 4 | `aplikasi (konfigurasi)` | 17 | `git ls-files aplikasi \\| grep -v '^aplikasi/src/' \\| grep -v '^aplikasi/alat/'` |
| 5 | `supabase/migrations` | 16 | `git ls-files supabase/migrations` |
| 6 | `supabase/tes` | 47 | `find supabase/tes -type f -print \\| sort` |
| 7 | `supabase/functions` | 2 | `git ls-files supabase/functions` |
| 8 | `supabase (akar)` | 2 | `git ls-files supabase -- \\| grep -vE '^supabase/(migrations|tes|functions)/'` |
| 9 | `alat` | 43 | `git ls-files alat` |
| 10 | `_sistem` | 15 | `git ls-files _sistem` |
| 11 | `docs (fondasi)` | 11 | `git ls-files docs -- \\| grep -vE '^docs/(uji|teknis|ops|desain)/'` |
| 12 | `docs/uji` | 88 | `git ls-files docs/uji` |
| 13 | `docs/teknis` | 6 | `git ls-files docs/teknis` |
| 14 | `docs/ops` | 8 | `git ls-files docs/ops` |
| 15 | `docs/desain` | 59 | `git ls-files docs/desain` |
| 16 | `prototipe` | 58 | `git ls-files prototipe` |
| 17 | `_log-sesi` | 5 | `git ls-files _log-sesi` |
| 18 | `berkas pengguna di akar` | 17 | `git ls-files \\| awk -F/ 'NF==1'` |
| 19 | `belum berggrup` | 0 | `python3 -c 'import alat.audit_independen as a'` atau inventaris prefiks grup |
| 20 | kontrak uang dan keamanan | 3 berkas utama | `nl -ba docs/TECH_SPEC.md \\| sed -n '328,420p'` |
| 21 | migrasi penutup terbaru | 2 migrasi | `nl -ba supabase/migrations/0014_penutup_celah_putaran13.sql` dan `0015_penutup_celah_putaran16.sql` |
| 22 | uji SQL berisiko tinggi | 46 berkas uji | `grep -RIn 'status\\|lunas\\|pembatalan\\|metode' supabase/tes` |
| 23 | aplikasi koneksi dan modal | 2 komponen | `nl -ba aplikasi/src/lib/supabase.ts; nl -ba aplikasi/src/komponen/Lapis.tsx` |
| 24 | operasional dan handoff | seluruh `docs/ops` | `grep -RIn 'arena/01a0b7d1\\|93a50ba\\|NASKAH_JALAN' docs/ops` |

### 1a. Berkas untuk pengguna

Saya menelusuri berkas ini sebagai pengguna non-teknis, bukan hanya sebagai sumber kode. Hasil pentingnya adalah rujukan stale dan langkah yang meminta berkas yang belum ada; detailnya menjadi F-16.

| # | Berkas pengguna | Pemeriksaan cara pengguna | Bukti |
|---|---|---|---|
| 1 | `PANDUAN_PENGGUNA.md`, `START_DI_SINI.md`, `PROMPT_SESI_BARU.md`, `STATUS.md`, `PROJECT_STATE.md` | Langkah awal, status, prompt yang dapat disalin, dan klaim kesiapan dibaca silang; status historis tidak diperlakukan sebagai bukti runtime. | `grep -n -E 'K-2\\|T1-45\\|46\\|NASKAH_JALAN' STATUS.md PROJECT_STATE.md` |
| 2 | `docs/PANDUAN_PEMILIK.md` dan `docs/ops/*` | Handoff, cabang, commit, paket audit, dan perintah sebelum preview diperiksa; `SIAP-LANJUT.md` masih menunjuk cabang/commit lama. | `nl -ba docs/ops/SIAP-LANJUT.md \\| sed -n '8,36p'` |
| 3 | `docs/uji/PROMPT_AUDIT_INDEPENDEN.md` dan paket audit | Prompt, SHA target, daftar tugas, jumlah berkas, kewajiban kalibrasi, serta perintah validasi dibandingkan dengan target aktual. | `grep -n -E 'Commit yang diaudit\\|Jumlah berkas\\|T1-45' docs/uji/PROMPT_AUDIT_INDEPENDEN.md docs/uji/paket-audit/AUD-3-2026-09-19.md` |
| 4 | `docs/teknis/BUKU_INSIDEN.md` dan dokumen uji penerimaan | Jalur insiden/privasi dibaca dan rujukan `docs/uji/NASKAH_JALAN.md` serta `docs/uji/HASIL_UJI_TERIMA_KEAMANAN.md` diuji keberadaannya. | `test -e docs/uji/NASKAH_JALAN.md; test -e docs/uji/HASIL_UJI_TERIMA_KEAMANAN.md` |

### Perbedaan paket dan target

Paket yang tercantum di kepala laporan memetakan 436 berkas pada SHA `93a50ba...`. Perbandingan pohon non-vendored menunjukkan 45 path baru pada target dan 1 path lama tidak lagi ada, yaitu neto `+44`: target 480. Paket `AUD-3-2026-09-19-680ffaf.md` juga ada, tetapi menargetkan SHA lain dan bukan pengganti audit atas `4830b5a...`. Berkas tambahan tidak dikeluarkan dari audit. Kelompok tambahannya adalah: `docs/uji/audit` 16, `supabase/tes` 5, `docs/uji/paket-audit` 4, `alat` 3, `docs/ops` 3, `docs/uji/review-pr` 3, `.github/workflows` 2, `aplikasi/alat` 2, `aplikasi/src` 2, `_log-sesi` 1, `aplikasi` konfigurasi 1, `docs/uji` 1, `supabase` akar 1, dan `supabase/migrations` 1. Satu path yang hilang dari pembanding lama adalah `docs/uji/kalibrasi/pr-bahan-2026-09-17.diff`.

### Tugas dan bukti yang diminta

Lingkup tugas dibaca sebagai rentang paket `T0-00` sampai `T11-13`, termasuk task yang masih `[ ]`; centang ROADMAP bukan dianggap bukti implementasi. `docs/ROADMAP.md` berisi 193 task: 25 `[x]` dan 168 `[ ]`. Per fase: T0 `14/15`, T1 `11/45`, T2 `0/19`, T3 `0/16`, T4 `0/10`, T5 `0/12`, T6 `0/8`, T7 `0/12`, T8 `0/15`, T9 `0/12`, T10 `0/16`, T11 `0/13`. T1-45 pada target dibaca juga walaupun paket 436 yang lebih lama belum mencantumkannya.

Sembilan skill wajib dimuat dan dipakai sesuai lensanya: `skills/security-review/SKILL.md` (L1/L6), `skills/verification-before-completion/SKILL.md` (bukti segar), `skills/systematic-debugging/SKILL.md` (jalur sebab), `skills/verification-loop/SKILL.md` (loop verifikasi), `skills/test-driven-development/SKILL.md` (mutu uji), `skills/prd-taskmaster/SKILL.md` (kontrak–task–uji), `skills/supabase/SKILL.md` (RLS/Auth), `skills/supabase-postgres-best-practices/SKILL.md` (fungsi/RLS/konkurensi), dan `skills/ui-ux-pro-max/SKILL.md` (L5). Folder `skills/` tetap dikecualikan dari 480 sebagai vendored; tidak diubah.

- **L1 — Ancaman & Akses:** RLS, policy, grant, `SECURITY DEFINER`, identitas pemanggil, cabang, akun/perangkat, dan helper hierarki diuji statis. Jalur tanpa runtime diberi `DUGAAN` bila dampaknya belum dapat dibuktikan penuh.
- **L2 — Uang & Jejak:** urutan rumus, pembulatan, perubahan setelah lunas, metode bayar, pembatalan, idempotensi, dan `catatan_audit` dibandingkan dengan TECH_SPEC/PRD dan trigger final.
- **L3 — Kesepakatan Dokumen:** klaim STATUS/ROADMAP/ops diperlakukan sebagai hipotesis; path, SHA, task `[x]`, kontrak ART, dan bukti uji dicari kembali di target.
- **L4 — Mutu Uji:** seluruh 46 uji SQL yang tracked diinventaris; cakupan negative-test, mutasi, unit test, serta kondisi runtime yang tidak tersedia dipisahkan. Tidak ada hasil uji yang diklaim hijau tanpa eksekusi.
- **L5 — Lapangan & UI:** komponen koneksi, modal, status aplikasi, dokumentasi langkah kasir, dan jalur preview dibaca; fokus keyboard, keadaan gagal, dan rujukan operasional diperiksa.
- **L6 — Privasi & Kepatuhan:** kontrol audit, data pelanggan, persetujuan, anonimisasi, dan klaim UU PDP dibandingkan dengan migrasi serta task yang benar-benar ada. Ini bukan opini hukum.

## 2. Klaim pembangun yang saya coba falsifikasi

| # | Klaim (lokasi) | Cara uji | Hasil |
|---|---|---|---|
| 1 | `STATUS.md` menyatakan suite SQL 46 berkas dan penutupan temuan K-2 sudah selesai. | Baca status lalu telusuri migrasi final dan uji yang terkait metode/status/audit. | Klaim tidak cukup untuk menutup F-01–F-09; beberapa kontrol kontrak masih hilang atau dapat dilewati. |
| 2 | `docs/ROADMAP.md:620-623` menyatakan seluruh K-2 putaran verifikasi tuntas dan suite 46 lulus. | Bandingkan klaim dengan kode target, bukan hanya angka suite. | Terbantah oleh F-03, F-04, F-05, dan F-07; status suite tidak menguji semua serangan. |
| 3 | TECH_SPEC ART-3 menetapkan subtotal → diskon → pajak → service → pembulatan. | `nl -ba docs/TECH_SPEC.md \\| sed -n '328,333p'; nl -ba supabase/migrations/0014_penutup_celah_putaran13.sql \\| sed -n '88,115p'` | Terbantah: pajak/service dihitung dari subtotal mentah dan `pembulatan` tidak dibaca. |
| 4 | TECH_SPEC ART-4 menyatakan state machine item hanya maju dan pembayaran/lifecycle ditetapkan jalur sah. | Telusuri policy INSERT/UPDATE item dan `picu_item_jaga`. | Terbantah secara statis: INSERT status akhir dan UPDATE pra-dapur tidak dipagari. |
| 5 | TECH_SPEC ART-6/ART-13 menyatakan semua tindakan sensitif dicatat di `catatan_audit` append-only. | `grep -RIn 'catatan_audit' supabase/migrations` dan cari tabel/rencana migrasi. | Terbantah: tabel/migrasi target tidak ada; T1-13 masih terbuka. |
| 6 | Checklist ROADMAP menyatakan semua API/RPC dan area risiko tinggi sudah punya task dan uji. | Baca checklist lalu cocokkan task `[x]`, berkas aktual, dan negative-test. | Task ada, tetapi implementasi/uji banyak masih terbuka; keberadaan task bukan bukti penyelesaian. |
| 7 | Komentar `0015_penutup_celah_putaran16.sql` menyebut bukti pembatalan satu-satunya adalah baris pembatalan resmi. | Cari semua operasi INSERT/UPDATE pada `pesanan_item` dan trigger status. | Tidak benar untuk pembatalan/status item sebelum dapur; F-04 terverifikasi. |
| 8 | `docs/ops/SIAP-LANJUT.md` menyajikan keadaan sesi yang siap dilanjutkan. | Ikuti path/cabang/commit yang ditulis dan cek file rujukannya. | Terbantah sebagai dokumentasi saat ini: cabang `arena/01a0b7d1`, commit `fedea15`, dan paket `93a50ba` stale. |
| 9 | Unit test aplikasi menganggap HTTP health Auth 200 cukup untuk sukses sambungan. | Baca implementasi `ujiSambungan()` dan test mock status data gagal. | Terverifikasi sebagai false positive yang mungkin: hasil data tidak ikut menentukan `ok`. |
| 10 | Dokumen keamanan menyatakan privasi pelanggan, perangkat terdaftar, MFA, audit, dan pemulihan sebagai kontrol wajib. | Cari tabel/RPC/migrasi yang menyediakannya dan status task-nya. | Klaim normatif ada, tetapi sebagian besar kontrol belum mendarat; F-07–F-09 terverifikasi sebagai gap deliverable. |
| 11 | Paket audit terbaru adalah instruksi yang cocok dengan target yang diaudit. | Bandingkan SHA/jumlah berkas paket dengan `git rev-parse` dan `git ls-tree` target. | Terbantah: paket menunjuk `93a50ba...`/436, target mandat `4830b5a...`/480. |

## 3. Serangan yang dijalankan (kill attempts)

Serangan di bawah adalah probe statis/kontraktual kecuali ditandai `DUGAAN` atau `terhalang runtime`. Saya tidak mengarang hasil SQL yang tidak dapat dieksekusi.

| # | Skenario serangan | Cara | Hasil |
|---|---|---|---|
| A-01 | Panggil `hitung_total` untuk pesanan sendiri setelah status `lunas`. | `grep -n 'grant execute\\|where p.id' supabase/migrations/0014_penutup_celah_putaran13.sql` | Jalur authenticated tersedia dan tidak ada guard status; F-02 TERVERIFIKASI. |
| A-02 | Sisipkan diskon setelah lunas lalu picu hitung ulang. | `nl -ba supabase/migrations/0015_penutup_celah_putaran16.sql \\| sed -n '204,251p'` | Jalur diskon langsung dipagari, tetapi RPC `hitung_total` tetap dapat menulis ulang; F-02. |
| A-03 | Bayar memakai `metode_bayar.aktif = false`. | `nl -ba supabase/migrations/0010_pembayaran.sql \\| sed -n '28,40p;269,280p'` | `aktif` tidak masuk SELECT/validasi pembayaran; F-03 TERVERIFIKASI. |
| A-04 | INSERT item dengan `status='siap'` atau `status='batal'` dari peran kasir/pelayan. | `nl -ba supabase/migrations/0009_pesanan.sql \\| sed -n '55,68p;276,292p'; nl -ba supabase/migrations/0015_penutup_celah_putaran16.sql \\| sed -n '50,72p'` | CHECK hanya membatasi nilai enum; state transition tidak diperiksa; F-04. |
| A-05 | UPDATE item `baru` menjadi `batal` sebelum tanda dapur, tanpa `pembatalan`. | `nl -ba supabase/migrations/0015_penutup_celah_putaran16.sql \\| sed -n '102,116p'` | Penolakan hanya untuk sesudah dapur; jalur pra-dapur lolos secara statis; F-04. |
| A-06 | UPDATE item `baru` langsung menjadi `siap`. | `grep -RIn 'status.*dimasak\\|status.*siap' supabase/migrations/0015_penutup_celah_putaran16.sql supabase/tes` | Tidak ada state machine item lengkap; F-04. |
| A-07 | UPDATE `pesanan` mengisi `dibayar_pada`, `dibatalkan_pada`, atau `alasan_batal` tanpa RPC. | `nl -ba supabase/migrations/0009_pesanan.sql \\| sed -n '259,270p'; nl -ba supabase/migrations/0014_penutup_celah_putaran13.sql \\| sed -n '425,488p'` | Trigger jejak hanya membekukan kasir/tanggal/nomor; lifecycle metadata tidak dipagari; F-06. |
| A-08 | INSERT pembatalan yang sama dua kali. | `nl -ba supabase/migrations/0010_pembayaran.sql \\| sed -n '130,143p'; nl -ba supabase/migrations/0015_penutup_celah_putaran16.sql \\| sed -n '144,201p'` | Tidak ada unique/idempotency guard; trigger AFTER INSERT mengulang dampak; F-05. |
| A-09 | Panggil `peran_lebih_tinggi(uuid_bebas, uuid_bebas)` dengan pasangan ID yang dipilih. | `nl -ba supabase/migrations/0015_penutup_celah_putaran16.sql \\| sed -n '592,610p'` | Fungsi SECURITY DEFINER authenticated callable dan tidak mengikat argumen ke `auth.uid`; dampak eskalasi diberi DUGAAN, F-11. |
| A-10 | Admin cabang membaca/mengubah izin cabang lain dalam penyewa. | `grep -RIn 'create policy izin_pilih\\|sepenyewa(pengguna_id)' supabase/migrations; grep -n 'seluruh izin' supabase/tes/rls_pengguna.sql` | Konflik kontrak PRD versus test; belum diputuskan oleh runtime, F-10 DUGAAN. |
| A-11 | Dua recalculation atau penambahan diskon berjalan bersamaan. | `grep -n -E 'select coalesce\\(sum\\(pi.subtotal\\|select coalesce\\(sum\\(d.nilai' supabase/migrations/0014_penutup_celah_putaran13.sql supabase/migrations/0013_penutup_celah_putaran11.sql` | Lock order tidak terlihat pada jalur hitung/diskon; efek lost update/cap race DUGAAN, F-12. |
| A-12 | Dua INSERT pesanan bersamaan memakai `max(nomor)+1`. | `nl -ba supabase/migrations/0014_penutup_celah_putaran13.sql \\| sed -n '407,417p'; nl -ba supabase/migrations/0015_penutup_celah_putaran16.sql \\| sed -n '270,285p'` | Pola race terlihat statis; tidak ada uji concurrency, F-13 DUGAAN. |
| A-13 | HTTP Auth health 200, PostgREST/data 500. | `nl -ba aplikasi/src/lib/supabase.ts \\| sed -n '101,112p'; nl -ba aplikasi/src/lib/supabase.test.ts \\| sed -n '77,82p'` | `ok=true` hanya melihat health; F-14 TERVERIFIKASI secara kode/unit mock. |
| A-14 | Navigasi keyboard keluar dari modal, fokus tidak dipulihkan. | `nl -ba aplikasi/src/komponen/Lapis.tsx \\| sed -n '26,60p'; grep -n -E 'focus|trap|tabIndex|ref' aplikasi/src/komponen/Lapis.tsx` | Esc/latar/ARIA ada, focus trap/fokus awal/pemulihan tidak ada; F-15. |
| A-15 | Pengguna mengikuti handoff ops apa adanya. | `nl -ba docs/ops/SIAP-LANJUT.md \\| sed -n '8,36p'; test -e docs/uji/NASKAH_JALAN.md` | Cabang/commit/paket lama dan file rujukan hilang; F-16. |
| A-16 | Auditor mempercayai jumlah paket 436 tanpa inventory target. | `git ls-tree -r --name-only 4830b5a4f876744ecb37e2f4495c6df234376752` dibanding `git ls-tree -r --name-only 93a50baccffc23ca0f41a9f636fed03b447ae391` | Selisih net +44; F-17. |
| A-17 | Perubahan izin/PIN/perangkat dapat ditelusuri lewat `catatan_audit`. | `grep -RIn 'create table.*catatan_audit\\|catatan_audit' supabase/migrations` | Tidak ada tabel/migrasi target; F-07. |
| A-18 | Akun/perangkat dicabut atau MFA dipaksa sebelum akses staf. | `find supabase/migrations -type f -maxdepth 1 -printf '%f\\n'; grep -n -E 'T1-24|T1-25|T1-27|T2-' docs/ROADMAP.md \\| head` | Tabel/RPC kontrol belum ada dan task belum selesai; F-08. |
| A-19 | Simpan data pelanggan dengan persetujuan dan anonimisasi. | `grep -RIn 'create table.*pelanggan\\|persetujuan\\|anonim' supabase/migrations; nl -ba docs/TECH_SPEC.md \\| sed -n '391,396p'` | Kontrak ada, implementasi pelanggan/consent/anonymize belum ada; F-09. |
| A-20 | Pegawai menebak PIN kolega melalui hasil `simpan_pin`. | `nl -ba supabase/migrations/0015_penutup_celah_putaran16.sql \\| sed -n '296,309p;374,407p'` | Pesan dibuat netral tetapi sukses/gagal masih oracle boolean; residual dibatasi 20/15 menit, F-18 TERVERIFIKASI K-3. |

## 4. Temuan

### [F-01] Urutan pajak/service salah dan pembulatan konfigurasi diabaikan
- **Tingkat:** K-1
- **Artefak:** `supabase/migrations/0014_penutup_celah_putaran13.sql:88-115`; `docs/TECH_SPEC.md:328-332`
- **Klaim yang dilanggar:** ART-3/TECH_SPEC mewajibkan subtotal → diskon → pajak PB1 → service → pembulatan; pajak dan service memakai subtotal setelah diskon.
- **Bukti:** `nl -ba supabase/migrations/0014_penutup_celah_putaran13.sql \\| sed -n '88,115p'; grep -n 'pembulatan' supabase/migrations/0014_penutup_celah_putaran13.sql` → kode menghitung `v_pajak` dan `v_service` dari `v_subtotal` pada baris 99-100, baru membaca `v_diskon` pada 102-104, lalu tidak membaca `pengaturan.pembulatan`.
- **Skenario gagal:** subtotal 100.000, diskon 20.000, PB1 10%, service 5% menghasilkan pajak/service dari 100.000, bukan 80.000; nominal struk dan laporan salah, dan pilihan pembulatan pemilik tidak berlaku.
- **Dugaan penyebab:** fungsi penutup mengunci rumus lama subtotal-plus-pajak-plus-service-minus-diskon tanpa memindahkan basis pajak/service ke subtotal setelah diskon.
- **Cara membuktikan perbaikan:** `node alat/uji-sql.mjs --daftar` lalu uji kasus diskon, PB1/service setelah diskon, dan setiap mode pembulatan; hasil harus hijau pada database PostgreSQL target.
- **Status verifikasi:** TERVERIFIKASI

### [F-02] RPC `hitung_total` dapat menulis ulang pesanan yang sudah lunas
- **Tingkat:** K-1
- **Artefak:** `supabase/migrations/0014_penutup_celah_putaran13.sql:52-126`
- **Klaim yang dilanggar:** TECH_SPEC ART-4 dan Aturan Bisnis 11: setelah `lunas` tidak ada perubahan nominal; koreksi harus berupa baris baru.
- **Bukti:** `nl -ba supabase/migrations/0014_penutup_celah_putaran13.sql \\| sed -n '67,126p'` → guard hanya memeriksa keberadaan dan tenant pada 67-86, lalu selalu `update public.pesanan` pada 110-116; `grant execute ... to authenticated` ada pada 125-126.
- **Skenario gagal:** kasir yang memiliki pesanan sendiri menjalankan `select public.hitung_total('<id-lunas>')` setelah diskon/item berubah atau memanggilnya langsung; kolom total/komponen struk lunas ditulis ulang tanpa pembatalan/koreksi berjejak.
- **Dugaan penyebab:** fungsi sengaja diekspos sebagai “boleh dipanggil klien” tetapi tidak membedakan panggilan klien dari jalur pemicu peladen dan tidak menolak status final.
- **Cara membuktikan perbaikan:** `node alat/uji-sql.mjs --daftar` dengan probe RPC langsung pada pesanan `lunas`; panggilan klien harus ditolak dan koreksi resmi harus meninggalkan jejak baru tanpa mengubah nominal lama.
- **Status verifikasi:** TERVERIFIKASI

### [F-03] Metode pembayaran nonaktif masih dapat dipakai
- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0010_pembayaran.sql:28-40,269-280`; `supabase/migrations/0012_penutup_celah_review.sql:736-747`
- **Klaim yang dilanggar:** DoD metode pembayaran dan kontrak pembayaran mengharuskan hanya metode aktif dari pengaturan yang dapat dipilih.
- **Bukti:** `nl -ba supabase/migrations/0010_pembayaran.sql \\| sed -n '28,40p;269,280p'; nl -ba supabase/migrations/0012_penutup_celah_review.sql \\| sed -n '736,747p'` → tabel memiliki `aktif`, tetapi SELECT validasi hanya memeriksa `id` dan `penyewa_id`, lalu menyalin nama/jenis tanpa `m.aktif = true`.
- **Skenario gagal:** owner menonaktifkan QRIS/transfer, kemudian kasir mengirim INSERT pembayaran dengan `metode_id` baris itu; trigger menerimanya karena baris masih ada dan mencatat pembayaran dengan metode yang sudah dinonaktifkan.
- **Dugaan penyebab:** validasi menganggap “baris metode ada” sama dengan “metode boleh dipakai” dan tidak membawa status aktif ke snapshot pembayaran.
- **Cara membuktikan perbaikan:** `node alat/uji-sql.mjs --daftar` dengan probe menonaktifkan satu metode lalu mencoba bayar; INSERT harus gagal sebelum baris uang tercipta.
- **Status verifikasi:** TERVERIFIKASI

### [F-04] State machine item dapat dilewati dan pembatalan pra-dapur tidak berjejak
- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0009_pesanan.sql:55-68,276-292`; `supabase/migrations/0015_penutup_celah_putaran16.sql:50-128`; `supabase/tes/item_penjaga.sql`
- **Klaim yang dilanggar:** TECH_SPEC ART-4 menyatakan status item hanya maju `baru → dimasak → siap`; pembatalan harus beralasan dan tercatat, bukan UPDATE/INSERT bebas dari perangkat.
- **Bukti:** `nl -ba supabase/migrations/0009_pesanan.sql \\| sed -n '55,68p;276,292p'; nl -ba supabase/migrations/0015_penutup_celah_putaran16.sql \\| sed -n '50,116p'` → policy memberi authenticated INSERT/UPDATE, trigger menghitung subtotal dan hanya menolak pembatalan/qty setelah dapur (112-115), tanpa aturan transisi pada INSERT atau UPDATE sebelum dapur.
- **Skenario gagal:** kasir memasukkan item dengan `status='siap'`, atau mengubah `baru` menjadi `batal` saat pesanan masih `draf`; tidak ada baris `pembatalan`, alasan, nilai kerugian, atau bukti PIN, tetapi item sudah memengaruhi total/laporan.
- **Dugaan penyebab:** kontrol terbaru hanya menutup jalur yang ditemukan untuk sesudah dapur dan test yang ada mengabadikan izin pra-dapur, bukan state machine lengkap.
- **Cara membuktikan perbaikan:** `node alat/uji-sql.mjs --daftar` dengan probe INSERT status akhir, setiap lompatan status, dan pembatalan pra-dapur; semuanya harus ditolak atau melewati RPC pembatalan yang menghasilkan jejak.
- **Status verifikasi:** TERVERIFIKASI

### [F-05] Baris pembatalan tidak idempoten dan dapat menggandakan dampak
- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0010_pembayaran.sql:130-143`; `supabase/migrations/0015_penutup_celah_putaran16.sql:144-201`
- **Klaim yang dilanggar:** Aturan pembatalan dan pembayaran offline menuntut jejak satu kali/idempotensi; satu pembatalan sah tidak boleh dapat diterapkan lagi sebagai kejadian baru tanpa guard.
- **Bukti:** `nl -ba supabase/migrations/0010_pembayaran.sql \\| sed -n '130,143p'; nl -ba supabase/migrations/0015_penutup_celah_putaran16.sql \\| sed -n '144,201p'` → tabel `pembatalan` tidak memiliki unique key untuk pesanan/item/aksi, dan trigger `after insert` menjalankan update item/pesanan untuk setiap baris baru.
- **Skenario gagal:** kirim ulang INSERT pembatalan yang sama karena antrean offline atau klik ganda; database menerima baris kedua, menghitung/menulis dampak lagi, dan laporan melihat dua kejadian kerugian untuk satu aksi.
- **Dugaan penyebab:** jejak append-only diperlakukan sebagai cukup, tanpa kunci idempotensi atau pemeriksaan bahwa target item sudah batal.
- **Cara membuktikan perbaikan:** `node alat/uji-sql.mjs --daftar` mengirim payload pembatalan identik dua kali; percobaan kedua harus menjadi no-op/idempotent atau ditolak dengan satu jejak yang dapat diaudit.
- **Status verifikasi:** TERVERIFIKASI

### [F-06] Metadata lifecycle pesanan masih dapat ditulis dari UPDATE umum
- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0009_pesanan.sql:259-270`; `supabase/migrations/0014_penutup_celah_putaran13.sql:425-488`
- **Klaim yang dilanggar:** stempel `dibayar_pada`, `dibatalkan_pada`, `alasan_batal`, dan atribut lifecycle harus berasal dari jalur peladen resmi; client tidak boleh mengarang jejak kejadian.
- **Bukti:** `nl -ba supabase/migrations/0009_pesanan.sql \\| sed -n '259,270p'; nl -ba supabase/migrations/0014_penutup_celah_putaran13.sql \\| sed -n '438,480p'` → policy UPDATE mencakup seluruh kolom dan trigger jejak hanya memeriksa `kasir_id`, `tanggal`, `nomor`, serta pelayan; tidak ada pemeriksaan tiga metadata lifecycle tersebut pada UPDATE.
- **Skenario gagal:** kasir melakukan `update pesanan set dibayar_pada=now(), alasan_batal='...'` tanpa pembayaran/pembatalan; status dapat tetap `draf` tetapi jejak menyatakan uang/pembatalan pernah terjadi, atau stempel dapat dihapus kembali.
- **Dugaan penyebab:** penjaga INSERT status awal sudah ada, tetapi penjaga UPDATE hanya mengunci sebagian atribut audit dan status enum.
- **Cara membuktikan perbaikan:** `node alat/uji-sql.mjs --daftar` mencoba mengisi, mengubah, dan menghapus setiap lifecycle timestamp/metadata dari authenticated; semua harus ditolak di luar trigger resmi.
- **Status verifikasi:** TERVERIFIKASI

### [F-07] `catatan_audit` wajib tidak ada pada target
- **Tingkat:** K-2
- **Artefak:** `docs/TECH_SPEC.md:180,301,326,387-389`; `docs/ROADMAP.md:298-305`; `supabase/migrations/`
- **Klaim yang dilanggar:** ART-6/ART-13 dan T1-13 mewajibkan tabel audit append-only, rantai hash, dan catatan perubahan sensitif.
- **Bukti:** `grep -RIn 'catatan_audit' supabase/migrations || true; find supabase/migrations -maxdepth 1 -type f -printf '%f\\n' \\| sort; nl -ba docs/ROADMAP.md \\| sed -n '298,305p'` → tidak ada tabel/migrasi `catatan_audit`, sedangkan task dan DoD masih terbuka.
- **Skenario gagal:** perubahan izin/PIN/perangkat, void, atau mode dukungan terjadi; tidak ada baris audit berantai yang dapat diperiksa pemilik, sehingga penghapusan/penyuntingan sensitif tidak memiliki jejak wajib.
- **Dugaan penyebab:** proyek berhenti pada migrasi 0015 sebelum T1-13/T1-27 dikerjakan; dokumen keamanan sudah lebih maju daripada skema aktual.
- **Cara membuktikan perbaikan:** `node alat/uji-sql.mjs --daftar` menjalankan INSERT perubahan sensitif, UPDATE/DELETE audit, dan pemeriksaan rantai; perubahan harus tercatat dan UPDATE/DELETE harus ditolak/terdeteksi.
- **Status verifikasi:** TERVERIFIKASI

### [F-08] Perangkat terdaftar, sesi pencabutan, percobaan masuk, dan MFA belum tersedia
- **Tingkat:** K-2
- **Artefak:** `docs/KEAMANAN.md:40,93`; `docs/ROADMAP.md` task T1-24/T1-25/T1-26/T2; `supabase/migrations/0001..0015`
- **Klaim yang dilanggar:** dokumen keamanan menetapkan perangkat terdaftar + pencabutan seketika untuk staf dan TOTP wajib untuk peran berkuasa sebelum akses produksi.
- **Bukti:** `find supabase/migrations -maxdepth 1 -type f -printf '%f\\n' \\| sort; grep -RIn -E 'create table.*perangkat|create table.*sesi_perangkat|TOTP|mfa|percobaan_masuk' supabase/migrations docs/ROADMAP.md` → tidak ada tabel/RPC migrasi untuk kontrol tersebut; task terkait masih `[ ]`.
- **Skenario gagal:** akun staf yang hanya memiliki token/authenticated tanpa verifikasi perangkat atau sesi buatan sendiri tidak memiliki gerbang database yang diwajibkan dokumen; jalur MFA pemilik/admin juga belum dapat dijalankan dari target.
- **Dugaan penyebab:** Fase 1B/Fase 2 sengaja belum dikerjakan, tetapi dokumen status dan prompt belum memisahkan “fondasi proyek” dari “siap produksi”.
- **Cara membuktikan perbaikan:** `node alat/uji-sql.mjs --daftar` dan uji migrasi perangkat/sesi/MFA; akun non-perangkat dan sesi dicabut harus ditolak, TOTP wajib bagi tiga peran, dan semua perubahan diaudit.
- **Status verifikasi:** TERVERIFIKASI

### [F-09] Kontrak privasi pelanggan belum memiliki jalur implementasi
- **Tingkat:** K-2
- **Artefak:** `docs/TECH_SPEC.md:186,391-396`; `docs/PRD.md:277,294,307`; `supabase/migrations/0001..0015`
- **Klaim yang dilanggar:** ART-10/ART-14 mengharuskan persetujuan eksplisit sebelum menyimpan data pelanggan, minimalisasi, anonimisasi atas permintaan, dan pemisahan catatan keuangan.
- **Bukti:** `grep -RIn -E 'create table.*pelanggan|persetujuan|anonim' supabase/migrations; nl -ba docs/TECH_SPEC.md \\| sed -n '391,396p'` → migrasi target tidak memiliki tabel `pelanggan`, kolom persetujuan, atau RPC anonimisasi, sementara kontrak dan DoD tertulis.
- **Skenario gagal:** alur voucher/pelanggan mulai menyimpan nama/kontak tanpa jalur persetujuan, akses, atau anonimisasi yang dapat dibuktikan; permintaan penghapusan data pribadi tidak punya operasi yang mempertahankan catatan keuangan.
- **Dugaan penyebab:** T8 dan task privasi belum dikerjakan; target belum merupakan implementasi pelanggan, tetapi klaim kesiapan dokumen tidak boleh dibaca sebagai fitur yang ada.
- **Cara membuktikan perbaikan:** `node alat/uji-sql.mjs --daftar` dengan pelanggan tanpa persetujuan, permintaan akses/anonimisasi, dan pemeriksaan laporan tanpa kontak; semua hasil harus sesuai ART-14.
- **Status verifikasi:** TERVERIFIKASI

### [F-10] Isolasi izin admin cabang bertentangan antara policy, kontrak, dan test
- **Tingkat:** K-2
- **Artefak:** policy izin pada migrasi target; `docs/TECH_SPEC.md`/PRD tentang cabang; `supabase/tes/rls_pengguna.sql`
- **Klaim yang dilanggar:** admin cabang dibatasi pada cabang yang menjadi wewenangnya; policy tidak boleh memperluas daftar izin ke seluruh penyewa tanpa keputusan yang konsisten.
- **Bukti:** `grep -RIn 'create policy izin_pilih\\|sepenyewa(pengguna_id)' supabase/migrations; grep -n -A8 -B3 'izin.*seluruh\\|admin_cabang' supabase/tes/rls_pengguna.sql docs/TECH_SPEC.md` → policy memakai keterlihatan sepenyewa, sementara test mengharapkan seluruh izin penyewa dan kontrak cabang membatasi.
- **Skenario gagal:** admin cabang membaca atau mengelola baris izin untuk cabang lain dalam penyewa; bila policy test dianggap sumber kebenaran, pembatas cabang kontraktual tidak pernah ditegakkan.
- **Dugaan penyebab:** model izin global-per-penyewa dan model admin-per-cabang belum disatukan setelah perubahan peran tunggal.
- **Cara membuktikan perbaikan:** `node alat/uji-sql.mjs --daftar` dengan dua cabang dan admin cabang; hasil policy, RPC, dan test harus menyatakan satu aturan yang sama.
- **Status verifikasi:** DUGAAN

### [F-11] Helper hierarki PIN menerima UUID bebas dan identitas pemanggil tidak dipakukan
- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0015_penutup_celah_putaran16.sql:342-361,592-610`
- **Klaim yang dilanggar:** helper hierarki harus menjadi gerbang bahwa pemanggil yang sedang login lebih tinggi dari target, bukan oracle publik atas dua UUID arbitrer.
- **Bukti:** `nl -ba supabase/migrations/0015_penutup_celah_putaran16.sql \\| sed -n '592,610p'; grep -RIn 'peran_lebih_tinggi' supabase/migrations` → fungsi `SECURITY DEFINER` menerima `p_pemanggil` dan `p_target` langsung, diberi execute ke authenticated, dan tidak membandingkan `p_pemanggil` dengan `auth.uid()`.
- **Skenario gagal:** authenticated memanggil helper dengan UUID peran tinggi dan target rendah untuk memetakan hierarki; apabila hasil helper dipakai di jalur baru tanpa pembungkus identitas, pemeriksaan “atasan” dapat dipalsukan.
- **Dugaan penyebab:** helper dibuat generik untuk dipanggil `simpan_pin`, tetapi grant langsung dan argumen bebas memperluas kontrak di luar use case internal.
- **Cara membuktikan perbaikan:** `node alat/uji-sql.mjs --daftar` memanggil helper dengan pemanggil fiktif, JWT lain, dan UUID lintas penyewa; fungsi harus menolak/menetapkan pemanggil dari `auth.uid()` atau tidak callable klien.
- **Status verifikasi:** DUGAAN

### [F-12] Recalculation dan cap diskon tidak memiliki serialisasi order yang terbukti
- **Tingkat:** K-1
- **Artefak:** `supabase/migrations/0014_penutup_celah_putaran13.sql:88-116`; `supabase/migrations/0013_penutup_celah_putaran11.sql:75-120`
- **Klaim yang dilanggar:** hitungan uang dan cap harus atomik; dua operasi bersamaan tidak boleh kehilangan item/diskon atau melampaui cap.
- **Bukti:** `grep -n -E 'sum\\(pi.subtotal\\)|sum\\(d.nilai\\)' supabase/migrations/0014_penutup_celah_putaran13.sql supabase/migrations/0013_penutup_celah_putaran11.sql` → fungsi membaca agregat dan menulis total tanpa `FOR UPDATE` pada order yang terlihat; berbeda dari pembayaran yang eksplisit mengunci baris order pada 0012:719-727.
- **Skenario gagal:** dua kasir menambah diskon atau mengubah item bersamaan, keduanya membaca agregat lama, lalu menulis hasil masing-masing; salah satu perubahan atau pembatas dapat hilang dan angka uang final salah.
- **Dugaan penyebab:** perbaikan race pembayaran tidak diterapkan ke jalur hitung_total/diskon; tidak ada test concurrency di 46 SQL test.
- **Cara membuktikan perbaikan:** `node alat/uji-sql.mjs --daftar` ditambah dua koneksi/transaksi barrier yang mengubah item/diskon order sama; hasil akhir harus serializable dan cap tidak pernah terlewati.
- **Status verifikasi:** DUGAAN

### [F-13] Pembuatan nomor order memakai `max()+1` tanpa serialisasi eksplisit
- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0014_penutup_celah_putaran13.sql:407-417`; `supabase/migrations/0015_penutup_celah_putaran16.sql:270-285`
- **Klaim yang dilanggar:** nomor order per cabang/hari harus unik dan aman saat dua perangkat mengirim bersamaan.
- **Bukti:** `nl -ba supabase/migrations/0014_penutup_celah_putaran13.sql \\| sed -n '407,417p'; nl -ba supabase/migrations/0015_penutup_celah_putaran16.sql \\| sed -n '270,285p'` → implementasi final tetap `coalesce(max(p.nomor), 0) + 1`, tanpa lock/advisory/sequence.
- **Skenario gagal:** dua transaksi membaca nomor maksimum yang sama, keduanya memperoleh nomor berikut yang sama; unique constraint membuat salah satu pesanan gagal atau retry dapat membingungkan dan tidak atomik.
- **Dugaan penyebab:** isolasi lintas penyewa diperbaiki, tetapi serialisasi pengambilan nomor tidak ikut ditambahkan.
- **Cara membuktikan perbaikan:** `node alat/uji-sql.mjs --daftar` menjalankan concurrent INSERT order pada cabang/tanggal sama dan memeriksa bahwa semua order mendapat nomor unik tanpa retry manual.
- **Status verifikasi:** DUGAAN

### [F-14] `ujiSambungan()` dapat memberi sukses walau jalur data gagal
- **Tingkat:** K-3
- **Artefak:** `aplikasi/src/lib/supabase.ts:87-112`; `aplikasi/src/lib/supabase.test.ts:77-82`
- **Klaim yang dilanggar:** indikator sambungan harus melaporkan layanan yang benar-benar dibutuhkan aplikasi, bukan hanya health endpoint Auth.
- **Bukti:** `nl -ba aplikasi/src/lib/supabase.ts \\| sed -n '101,112p'; nl -ba aplikasi/src/lib/supabase.test.ts \\| sed -n '77,82p'` → dua fetch dipanggil, tetapi kondisi sukses hanya `sehat.status === 200`; status `data` tidak dipakai untuk menentukan `ok`.
- **Skenario gagal:** Auth health mengembalikan 200 tetapi PostgREST/data route mengembalikan 500/404; UI menyatakan sambungan berhasil dan pengguna diarahkan ke operasi yang pasti gagal.
- **Dugaan penyebab:** test hanya menguji status health 200/401 dan tidak mempunyai kasus kombinasi health sukses + data gagal.
- **Cara membuktikan perbaikan:** `cd aplikasi && npm test` dengan mock health 200/data 500; hasil harus `ok=false` dan pesan menunjukkan jalur data gagal.
- **Status verifikasi:** TERVERIFIKASI

### [F-15] Modal `Lapis` belum mengunci dan memulihkan fokus keyboard
- **Tingkat:** K-3
- **Artefak:** `aplikasi/src/komponen/Lapis.tsx:26-60`
- **Klaim yang dilanggar:** kontrak UI/a11y mengharuskan dialog keyboard-safe; pengguna tidak boleh kehilangan fokus ke belakang modal.
- **Bukti:** `nl -ba aplikasi/src/komponen/Lapis.tsx \\| sed -n '26,60p'; grep -n -E 'focus|trap|tabIndex|ref' aplikasi/src/komponen/Lapis.tsx` → ada Escape, overlay click, `role=dialog`, dan `aria-modal`, tetapi tidak ada fokus awal, focus trap, atau restore focus.
- **Skenario gagal:** pengguna keyboard membuka dialog, menekan Tab berulang, lalu fokus keluar ke halaman belakang; setelah Tutup fokus tidak kembali ke pemicu sehingga alur kasir kehilangan posisi.
- **Dugaan penyebab:** implementasi menutup dialog dan scroll body tetapi belum mengimplementasikan pola dialog modal penuh.
- **Cara membuktikan perbaikan:** `cd aplikasi && npm test` ditambah uji komponen keyboard: fokus pertama masuk dialog, Tab membungkus, Escape/Tutup mengembalikan fokus ke pemicu.
- **Status verifikasi:** TERVERIFIKASI

### [F-16] Panduan operasional stale dan menyebut berkas yang belum ada
- **Tingkat:** K-3
- **Artefak:** `docs/ops/SIAP-LANJUT.md:8-36`; `docs/ROADMAP.md:551,1849-1862`; `docs/uji/`.
- **Klaim yang dilanggar:** pengguna harus dapat mengikuti handoff dan naskah penerimaan dari berkas yang benar pada target.
- **Bukti:** `nl -ba docs/ops/SIAP-LANJUT.md \\| sed -n '8,36p'; test -e docs/uji/NASKAH_JALAN.md; test -e docs/uji/HASIL_UJI_TERIMA_KEAMANAN.md` → panduan menunjuk `arena/01a0b7d1`, `fedea15`, paket `93a50ba`, sementara dua path penerimaan tidak ada.
- **Skenario gagal:** pemilik mengikuti cabang/commit lama atau mencoba membuka naskah jalan dari link dokumentasi; langkah berhenti atau mengaudit keadaan yang bukan target mandat.
- **Dugaan penyebab:** handoff dan paket dibuat pada putaran berbeda lalu tidak disegarkan ketika target berpindah ke `4830b5a`.
- **Cara membuktikan perbaikan:** `python3 _sistem/validate_system.py` dan pemeriksa rujukan Markdown harus hijau terhadap clone bersih; semua path dan SHA handoff harus ada/tepat.
- **Status verifikasi:** TERVERIFIKASI

### [F-17] Paket audit dan jumlah lingkup tidak mengikat commit mandat
- **Tingkat:** K-3
- **Artefak:** `docs/uji/paket-audit/AUD-3-2026-09-19.md:13-19,74`; target `4830b5a...`
- **Klaim yang dilanggar:** paket audit menyatakan commit dan jumlah berkas yang benar-benar menjadi objek audit.
- **Bukti:** `grep -n -E 'Commit yang diaudit|Jumlah berkas dalam lingkup' docs/uji/paket-audit/AUD-3-2026-09-19.md; git ls-tree -r --name-only 93a50baccffc23ca0f41a9f636fed03b447ae391; git ls-tree -r --name-only 4830b5a4f876744ecb37e2f4495c6df234376752` → paket menunjuk SHA lama dan 436, target mandat memiliki 480; validator `--verifikasi-lingkup` lama bukan bukti SHA target.
- **Skenario gagal:** auditor menyalin paket dan hanya memeriksa 436 path/SHA 93, sehingga 44 path target—termasuk migrasi/uji/workflow/dokumen baru—tidak masuk pemeriksaan.
- **Dugaan penyebab:** paket dibuat sebelum commit target dan mekanisme paket belum mengikuti pohon target secara deterministik.
- **Cara membuktikan perbaikan:** `python3 alat/audit-independen.py --paket AUD-3 --semua` dijalankan dari clone target; SHA kepala, jumlah, grup, dan daftar tambahan harus cocok dengan pohon target.
- **Status verifikasi:** TERVERIFIKASI

### [F-18] Sisa oracle boolean pada penggantian PIN tetap terlihat
- **Tingkat:** K-3
- **Artefak:** `supabase/migrations/0015_penutup_celah_putaran16.sql:296-309,374-407`; `supabase/tes/pin_bukan_oracle.sql`
- **Klaim yang dilanggar:** mitigasi oracle PIN harus menyembunyikan apakah tebakan adalah PIN aktif kolega, bukan hanya menghapus kata “pegawai lain”.
- **Bukti:** `nl -ba supabase/migrations/0015_penutup_celah_putaran16.sql \\| sed -n '296,309p;374,407p'` → fungsi mengembalikan `PIN tersimpan.` bila kandidat tidak kembar dan pesan penolakan bila `crypt()` cocok; komentar sendiri mengakui sifat ya/tidak masih terbaca, walau dibatasi 20 percobaan/15 menit.
- **Skenario gagal:** pegawai yang mengetahui PIN lamanya mencoba kandidat kuat satu per satu pada `simpan_pin`; perbedaan sukses/gagal masih menjadi oracle keberadaan hash kolega dalam batas biaya yang ditentukan.
- **Dugaan penyebab:** perbaikan menetralkan teks pesan tetapi mempertahankan API sukses/gagal yang diperlukan untuk operasi simpan PIN.
- **Cara membuktikan perbaikan:** `node alat/uji-sql.mjs --daftar` mengukur respons kandidat kembar/tidak kembar dan memastikan kontrak baru tidak membocorkan bit keberadaan tanpa menghilangkan batas percobaan dan jejak internal.
- **Status verifikasi:** TERVERIFIKASI

## 5. Kalibrasi cacat tanaman

Kalibrasi dibaca terpisah dari temuan proyek. Saya tidak mencari kunci jawaban dan tidak menghitung hasil berikut sebagai F-01–F-18. Lima artefak bahan kalibrasi masing-masing berisi cacat yang dapat diidentifikasi dari isi langsung.

| ID | Bahan | Cacat yang ditemukan | Bukti |
|---|---|---|---|
| C-01 | `docs/uji/kalibrasi/bahan-2026-09-17/01_gerbang_izin.sql` | Fungsi SECURITY DEFINER diberi execute kepada `authenticated` tanpa `revoke ... from public`, dan search path tidak dipakukan lengkap. | `nl -ba docs/uji/kalibrasi/bahan-2026-09-17/01_gerbang_izin.sql` |
| C-02 | `02_policy_pengaturan.sql` | Policy SELECT memakai `penyewa_id is not null`, bukan isolasi penyewa pemanggil; tenant lain dapat terlihat. | `nl -ba docs/uji/kalibrasi/bahan-2026-09-17/02_policy_pengaturan.sql` |
| C-03 | `03_fungsi_terima_bayar.sql` | Pemeriksaan lebih bayar dilakukan sebelum menambahkan `p_jumlah` (`v_sebelum > total`), sehingga pembayaran baru dapat melewati total. | `nl -ba docs/uji/kalibrasi/bahan-2026-09-17/03_fungsi_terima_bayar.sql \\| sed -n '12,24p'` |
| C-04 | `04_panduan_singkat.md` | Panduan memakai `aplikasi/pratinjau.sh` dan `docs/PANDUAN_KEAMANAN.md` yang tidak ada, serta menulis kebijakan PIN 10 kali yang tidak cocok dengan kontrak repo. | `nl -ba docs/uji/kalibrasi/bahan-2026-09-17/04_panduan_singkat.md; test -e aplikasi/pratinjau.sh` |
| C-05 | `05_pemeriksa_ambang.py` | Akar path relatif salah untuk repo dan ambang pemeriksaan layar sengaja 5, lebih rendah dari ambang proyek 20, sehingga dapat `SKIP` terlalu dini. | `nl -ba docs/uji/kalibrasi/bahan-2026-09-17/05_pemeriksa_ambang.py \\| sed -n '7,21p'` |

**Ditemukan: 5 dari 5. Temuan palsu: 0.** Kalibrasi tidak dipakai untuk menaikkan atau menurunkan tingkat temuan proyek.

## 6. Yang tidak bisa saya verifikasi

- Eksekusi PostgreSQL/Supabase tidak tersedia dalam sesi audit. `node_modules` aplikasi dan alat tidak ada; saya tidak menjalankan `npm ci`, tidak memasang dependensi, dan tidak menebak hasil `node alat/uji-sql.mjs`, `npm test`, lint, typecheck, atau mutasi.
- Tidak ada akses runtime database/Auth/PostgREST, akun uji, dua koneksi concurrency, printer, perangkat kasir, atau browser. Karena itu F-10–F-13 memuat status `DUGAAN` bila dampak runtime belum dapat dibuktikan; temuan `TERVERIFIKASI` berarti jalur/ketidakadaan kontrol terbukti dari kode atau dokumen, bukan klaim bahwa transaksi sungguhan sudah dijalankan.
- Saya tidak mengakses jaringan eksternal dan tidak membuat kesimpulan hukum di luar kontrak yang tersimpan di PRD/TECH_SPEC/KEAMANAN. Kepatuhan UU PDP perlu ditinjau pemilik/penasihat yang berwenang setelah fitur benar-benar ada.
- Klaim CI, deploy/live, dan “46 uji hijau” pada STATUS/ROADMAP tidak dieksekusi ulang dan tidak diperlakukan sebagai bukti segar.
- Paket/validator lama menargetkan SHA berbeda. Validator laporan diminta dijalankan dari clone target dengan path laporan absolut, bukan memakai `--verifikasi-lingkup` lama sebagai bukti audit.

## 7. Pernyataan tidak mengubah apa pun

Saya hanya-baca selama audit. Saya tidak mengubah, memperbaiki, menjalankan migrasi, memasang dependensi, atau menerapkan kode pada clone target. Satu-satunya berkas yang dibuat pada checkout sesi adalah laporan ini; target audit tetap bersih. Bukti meja target: `git status --short` pada `/tmp/resto-audit-4830b5a` kosong. Temuan ditulis, bukan diperbaiki.

## 8. Temuan di luar cakupan

| # | Temuan | Mengapa di luar cakupan | Bukti | Syarat dilanjutkan ke audit lain |
|---|---|---|---|---|
| 1 | Lima cacat pada bahan kalibrasi C-01–C-05 | Bahan berada di `docs/uji/kalibrasi/` dan bukan kode proyek target; dilaporkan terpisah pada bagian 5 sesuai aturan. | `find docs/uji/kalibrasi/bahan-2026-09-17 -maxdepth 1 -type f -print` | Jangan dimasukkan ke backlog produk; gunakan hanya untuk menilai kalibrasi auditor berikutnya. |
| 2 | Tidak ada temuan proyek tambahan yang sengaja disembunyikan dari bagian 4 | Semua gap yang ditemukan pada task/artefak target dimasukkan ke bagian 4; keterbatasan runtime ada di bagian 6. | `git ls-files` dan tabel cakupan bagian 1 | Audit runtime/acceptance terpisah setelah dependensi, database, perangkat, dan naskah jalan tersedia. |