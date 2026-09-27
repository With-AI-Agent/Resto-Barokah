# LAPORAN PEMERIKSAAN INDEPENDEN FASE 10 — AGEN 1 (VERSI 2 — AUDIT MENDALAM)

- **Nama Agen:** Agen 1: Basis Data & Multi-Tenant (Spesialis Basis Data, Keamanan SQL & Multi-Tenant)
- **Target Cabang:** `arena/01a0d09b-resto-barokah` @ `5f7b38be21f1921663f6286a26ebe62f285f4d99`
  - Diverifikasi via `git ls-remote origin refs/heads/arena/01a0d09b-resto-barokah` → SHA identik dengan HEAD sesi saat audit dimulai.
  - Sesi diikat platform ke cabang kembar `arena/01a0e1ee-resto-barokah` (konten identik bit-per-bit saat start; kemudian di-fast-forward ke `5bd82f9` yang HANYA menambah 2 berkas laporan Agen 2 — bukan kode; target audit tetap `5f7b38b`).
- **Waktu Pemeriksaan:** 2026-09-27, 08:15–09:50 UTC — dua putaran: (1) 16 perintah wajib; (2) audit mendalam: pemindaian statis pola berbahaya, introspeksi katalog PostgreSQL hidup, pembacaan baris-demi-baris migrasi kunci, 6 checker tambahan, verifikasi tanah-nyata CI via `gh`, dan **baterai penuh 68/68 skrip uji mutasi**.
- **Status Akhir (Verdict):** **PERLU PERBAIKAN**
  - Domain inti (Basis Data, Keamanan SQL, Multi-Tenant): **BERSIH** — 0 temuan K-1; tidak ditemukan celah isolasi penyewa, kebocoran kredensial, bypass RLS/otorisasi, maupun pagar nonaktif pada definisi yang berlaku kini.
  - Yang menahan verdict: **2× K-2** (gerbang CI MERAH pada commit target; 5 harness uji-mutasi basi → 13 pagar kehilangan bukti mutasi yang sah) + **2× K-3** + **4× K-4** — seluruhnya teridentifikasi presisi, murah diperbaiki, dan TIDAK menyentuh keamanan data tenant yang aktif.
- **Mode Kerja:** HANYA-BACA untuk kode. `git status --porcelain -uno` = 0 perubahan di seluruh putaran; 0 pemulihan paksa selama baterai (68/68 skrip memulihkan berkasnya sendiri). Commit pada cabang sesi HANYA berisi laporan + lampiran bukti ini, atas perintah eksplisit Pemilik ("hasil pemeriksaan harus masuk GitHub").

## 1. Ringkasan Eksekutif Hasil Uji

**Putaran 1 — 16 perintah wajib: seluruhnya LULUS.** Suite SQL penuh **132/132 uji hijau · 0 gagal** di atas 82 migrasi yang diterapkan ke PostgreSQL nyata (PGlite/WASM, 7,3 detik). **47/47 tabel publik ber-RLS + 47/47 policy, 0 terbuka** (checker + hitungan grep independen + katalog hidup — tiga sumber cocok). Kunci idempoten ART-8 **8/8 RPC (100%)** dengan indeks unik parsial. Matriks **6 peran** valid; `pemilik_platform` hak-minimum (hanya `mode_dukungan` berkedaluwarsa & teraudit; CHECK 0002 memaksa `penyewa_id NULL`). Pemeriksa fungsi PIN **14/14**. Baterai wajib 9 skrip mutasi: **43/43 mutan terbunuh**. Satu insiden metodologis terdokumentasi jujur: eksekusi paralel 0083+0084 memicu positif-palsu (race working tree); re-run serial → 100% fail-closed.

**Putaran 2 — audit mendalam.** (a) Pemindaian statis seluruh migrasi: 0 `disable row level security`, 0 `with check (true)`, 0 policy permisif `to public/anon` (4 policy yang menyebut anon/public semuanya **DENY-ALL `qual=false`** pada tabel kredensial — diverifikasi dari `pg_policies` hidup), semua `drop policy` berpasangan pengetatan. (b) **Introspeksi katalog hidup**: **215 fungsi publik, 186 SECURITY DEFINER, 0 (NOL) tanpa `search_path` terkunci**; hanya **9** fungsi secdef terpanggil `anon` — semuanya permukaan publik by-design (katalog QR, voucher pelanggan, pairing/verifikasi perangkat), **0 RPC keuangan/istimewa**; seluruh fungsi trigger `picu_*` & helper internal tidak terpanggil `authenticated`; trigger kekalan lengkap di tabel uang/audit (rantai hash SHA-256 + anti-update/delete/truncate pada `catatan_audit`; `kas_pergerakan_kekal`; 9 pagar `pesanan`; pagar tengah-malam `shift_kas`). (c) Pembacaan mendalam: 0080 (pre-check idempoten + backstop indeks unik = anti-dobel fail-closed; cakupan `p_kunci_idempoten` 34 kemunculan/9 migrasi), 0006 (PIN bcrypt bf-10, CHECK regex anti-teks-polos, revoke-all + deny-all, throttle 5×/15 menit), 0025 (sinyal ganda anti-spoof service_role), 0029/0040/0057 (rantai audit kekal), 0031 (mode dukungan ber-expiry), 0062/0070/0071 (katalog publik terproyeksi kolom, `status='aktif'` tetap ditegakkan di versi kini 0071:260), 0083 (redefinisi simpan_menu/kategori/meja dengan pagar otorisasi utuh di :57/:281/:450), 0084 (5 operasi atomik + 5 pagar). (d) Checker tambahan: `periksa-keamanan-sql.py` **LOLOS** + uji-diri **13/13 mutasi terklasifikasi benar**; `periksa-migrasi-beku.py` **LOLOS** (16 migrasi beku SHA-256 utuh = cocok DB Supabase nyata); `periksa-buku-uji.py` **LOLOS**; `periksa-paritas-ci.py` **GAGAL**; `periksa-rujukan.py` **GAGAL (4 rujukan mati)**. (e) **Baterai mutasi penuh 68/68 skrip serial**: 63 LULUS · 5 GAGAL; **±431 mutan merah; 13 mutan hidup** — SEMUA mutan hidup terverifikasi sebagai **mutan ekuivalen akibat harness basi** (memutasi definisi fungsi yang sudah di-DROP + didefinisikan ulang migrasi lebih baru: `katalog_publik` 0062→0070→0071; `daftar_voucher` 0063→0064→0067; `simpan_meja` 0073→0083; `simpan_menu`/`simpan_kategori_menu` 0074→0083). Pagar pada definisi KINI diverifikasi hidup satu-satu (status-aktif katalog 0071:260; consent UU PDP RPC 0067:664 + CHECK skema 0063:154; otorisasi kelola meja/menu 0083:450/57/281; keunikan meja 0083:505). Preseden perbaikan ada di riwayat: commit `fix(mutasi): arahkan uji mutasi 0046 ke definisi terbaru tutup_shift` — pola yang sama belum diterapkan ke 5 harness ini. (f) **Tanah-nyata CI (gh API)**: run tip target `36305336934` = **FAILURE**; satu-satunya step merah = "Pemeriksa fondasi, roadmap, struktur, komponen, uji & kontras"; direproduksi lokal deterministik (paritas: 2 perintah header absen dari `periksa-semua.sh`; rujukan: 4 path alat salah — 2 di antaranya di dokumen paket audit ini sendiri). **Semua step SQL/mutasi CI ✓ hijau** (konsisten dengan temuan saya). CI merah beruntun sejak T10-10; `success` terakhir = T10-09. Ditambah: **31 dari 68 skrip mutasi (0056–0085 + cadangan) tidak digerber CI sama sekali** — itulah mengapa kebasaan harness tak pernah terdeteksi.

**Inti untuk Lee:** isolasi multi-tenant — prioritas mutlak Anda — **terbukti bersih, berlapis, dan tajam** melalui tiga lapis verifikasi independen (statis, katalog hidup, runtime+mutasi). Tidak ada data tenant A yang dapat bocor ke tenant B, tidak ada kredensial terbaca klien, tidak ada RPC keuangan reachable oleh anon, dan jejak audit kekal anti-rusak. Yang wajib dibereskan adalah **lapisan pembuktian & gerbang**: CI merah pada commit target (2 perbaikan kecil), 5 harness mutasi yang menarget definisi mati (retarget ke versi kini — pagar aslinya hidup), 31 skrip mutasi Fase 8–10 belum masuk CI, dan koreksi dokumentasi (85→82 migrasi; 4 path alat). Setelah itu, klaim "CI hijau / bukti mutasi lengkap" sah kembali.

## 2. Bukti Eksekusi Perintah Wajib (Putaran 1 — 16/16)

| # | Perintah | Keluaran Nyata (ringkas) | Status |
|---|----------|---------------------------|--------|
| 1 | `node alat/uji-sql.mjs` | "Menerapkan 82 migrasi: OK ×82" → "uji: **132 LULUS · 0 GAGAL** — HASIL: LOLOS" | LULUS |
| 2 | `python3 alat/periksa-sisir-rls.py` | 47 tabel; RLS **47/47**; terbuka **0**; policy **47/47** — "LOLOS — Seluruh 47 tabel terisolasi 100% secara fail-closed" | LULUS |
| 3 | `python3 alat/periksa-sisir-rls.py --uji-diri` | 4/4 mutasi kebocoran tertangkap — "LOLOS" | LULUS |
| 4 | `python3 alat/periksa-idempoten.py` | "RPC dengan kunci idempoten: **8/8 (100.0%)**; skema 8/8 — LOLOS" | LULUS |
| 5 | `python3 alat/periksa-matriks-izin.py` | Matriks 6 peran × 10 izin + mode_dukungan — "LOLOS" | LULUS |
| 6 | `python3 alat/periksa-fungsi-pin.py` | "**14 lolos, 0 gagal**" | LULUS |
| 7 | `uji-mutasi-0080.py` | kontrol hijau; **5/5 TERBUKTI MERAH** | LULUS |
| 8 | `uji-mutasi-0081.py` | **4/4 TERBUKTI MERAH** | LULUS |
| 9 | `uji-mutasi-0082.py` | **4/4 TERBUKTI MERAH** | LULUS |
| 10 | `uji-mutasi-0083.py` | baseline LOLOS; **4/4 MUTAN MATI** | LULUS |
| 11 | `uji-mutasi-0084.py` | Run-1 paralel: positif-palsu race (F10-A1-02); **run-2 serial: 4/4 terbunuh — "100% FAIL-CLOSED TERBUKTI"** | LULUS (serial) |
| 12 | `uji-mutasi-0085.py` | **4/4 terbunuh** (RLS ringkasan, ART-13, ART-14) | LULUS |
| 13 | `uji-mutasi-0046.py` | **6/6 TERBUKTI MERAH** | LULUS |
| 14 | `uji-mutasi-0047.py` | **6/6 TERBUKTI MERAH** | LULUS |
| 15 | `uji-mutasi-0049.py` | **6/6 TERBUKTI MERAH** | LULUS |
| — | Subtotal | **43/43 mutan terbunuh**; tree bersih sesudah tiap skrip | LULUS |

## 2B. Bukti Audit Mendalam (Putaran 2)

### B.1 Pemindaian statis pola berbahaya (82 migrasi)
| Pola | Hasil | Penilaian |
|------|-------|-----------|
| `disable row level security` | **0** | Bersih |
| `with check (true)` | **0** | Bersih |
| `using (true)` | **1** — `izin_kode_pilih` (0005:278) | BENAR: katalog kode izin global (PK `kode_izin`, tanpa `penyewa_id`), SELECT-only authenticated |
| policy permisif `to public/anon` | **0** | Bersih |
| `drop policy` | 5 (0014, 0015, 0018×2, 0020) | Semua berpasangan PENGETATAN (0018: revoke-all + `using (false)`; 0020: tenant + `boleh('kelola_pegawai')`) |
| `grant ... to anon` (tabel) | 22 tabel SELECT (warisan 0001/0002/0005/0008) + `pengaturan` UPDATE | Permukaan MATI (0 policy anon permisif → RLS tolak semua); rekomendasi cabut = F10-A1-06 |
| `bypassrls` di migrasi | **0** | Bersih (hanya harness uji lokal, meniru Supabase) |

### B.2 Introspeksi katalog PostgreSQL hidup (bukan regex)
- **A.** `total_tabel=47, rls_aktif=47, rls_mati=0, force_rls=0`
- **B2.** 4 policy menyebut anon/public — SEMUA deny-all (`pg_policies.qual='false'`): `kredensial_pin`, `percobaan_simpan_pin`, `kredensial_perangkat`, `kredensial_pemulihan`
- **C.** SECURITY DEFINER tanpa `search_path` terkunci: **0 dari 186**
- **D.** 215 fungsi publik; 186 security definer
- **E.** Secdef terpanggil anon hanya **9** (permukaan publik by-design): `ambil_kartu_voucher`, `apakah_perangkat_terblokir`, `cek_voucher`, `daftar_voucher`, `daftarkan_perangkat_dengan_kode`, `ikat_sesi_perangkat`, `katalog_publik`, `menu_habis`, `verifikasi_pin_perangkat` — **0 RPC keuangan/istimewa**
- **I.** Tidak terpanggil `authenticated`: seluruh `picu_*` (trigger-only T1-30), `jalur_peladen_terverifikasi`, `boleh_untuk`, `izin_efektif_untuk`, `kunci_lingkup_rincian`, `kunci_rincian_global_sebelum`, `peran_lebih_tinggi`, `perangkat_sah`, `pasang_*_bawaan`
- **J.** `pegawai_berhenti`/`bersihkan_data_sementara`/`verifikasi_rantai_audit`: anon=false, authenticated=true (otorisasi internal — dibuktikan mutasi 0084/0082 + tes lulus)
- **H.** Trigger proteksi: `catatan_audit` {hitung_hash rantai SHA-256, cegah_ubah_hapus, cegah_truncate}; `kas_pergerakan` {kekal, validasi_shift}; `pembayaran` {audit, jujur, metode_wajib, kait_shift, wajib_shift}; `pesanan` 9 pagar; `shift_kas` {jaga, tengah_malam}

### B.3 Pembacaan mendalam migrasi kunci
- **0080 (ART-8):** pre-check `WHERE cabang_id=... AND kunci_idempoten=v_kunci` → `if found` kembalikan `IDEMPOTEN` + rekaman existing; backstop indeks unik parsial (`shift_kas.kunci_idempoten`, `.kunci_idempoten_tutup`, `stok_pergerakan.kunci_idempoten`) → dobel mustahil bahkan saat race; kunci dinormalisasi `nullif(btrim(...))`. Cakupan `p_kunci_idempoten`: 34 kemunculan / 9 migrasi (termasuk `koreksi_modal_shift` 0050 & overload shift 0048).
- **0006 (PIN):** bcrypt `crypt(pin, gen_salt('bf',10))` di produksi; CHECK `pin_hash ~ '^\$[a-z0-9]+\$'` anti-teks-polos di level skema; revoke-all + deny-all; throttle 5×/15 menit per akun dari `percobaan_pin` (tercatat per perangkat sejak 0018). Tiruan crypt PGlite terdokumentasi jujur di harness.
- **0025:** `jalur_peladen_terverifikasi()` = sinyal ganda (role aktif DAN klaim JWT service_role) — anti-spoof; revoke dari public/anon/authenticated.
- **0029/0040/0057 (ART-13):** hash chain SHA-256 per penyewa + kunci serialisasi + `verifikasi_rantai_audit()`; trigger tolak UPDATE/DELETE; trigger tolak TRUNCATE.
- **0031:** `mode_dukungan` ber-`berakhir_pada` (auto-expiry `> now()`), flag aktif, audit buka/tutup; integrasi `penyewa_saya()` hanya untuk `pemilik_platform` — akses platform ke data tenant HANYA lewat sesi dukungan aktif & teraudit.
- **0058:** `penyewa_saya()` final: secdef + search_path terkunci + stable + syarat `p.aktif AND sesi_masih_aktif()`; tak sah → NULL → semua policy menolak.
- **0062/0070/0071:** katalog publik = proyeksi kolom eksplisit, scope slug tenant `status='aktif'` (**tetap ditegakkan di versi kini 0071:260**), tagline/logo/banner (0071:199-201).
- **0083:** DROP + redefinisi `simpan_menu`(:17→:19), `simpan_kategori_menu`(:253→:255), `simpan_meja`(:411→:413); pagar otorisasi versi kini: :57, :281, :450-451; pesan keunikan meja :505; penanganan 23505 :506.
- **0084 (T10-12):** 5 pagar (login; penyewa non-null; `owner_pusat`/`boleh('kelola_pegawai')`; anti-cabut-diri; hierarki + owner-terakhir) + `FOR UPDATE` + lingkup `penyewa_id=v_penyewa` + 5 operasi atomik (nonaktif pengguna & pengguna_cabang; cabut sesi_perangkat; hapus sesi_cabang; hapus kredensial_pin; tandai perlu_tutup_atasan + saran penutup) + jejak audit kekal; riwayat masa lalu tak disentuh (`riwayat_tidak_berubah.sql` lulus).

### B.4 Kedalaman berkas uji
- `rls_penyewa.sql` (88 baris): dua tenant nyata — anon 0 baris; tanpa identitas 0; kasir A tepat 1 penyewa ("Kedai Oasis") & 0 cabang tenant B; kasir B ("Warung Bandung") kebalikannya; mutasi lintas-tenant ditolak.
- `cabut_akses.sql` 388 baris; `idempoten.sql` 539 baris; `rls_semua_tabel.sql` 278 baris (SETIAP policy tabel ber-penyewa_id wajib `penyewa_saya()`/tolak-semua).
- Uji terarah terpisah (`rls_penyewa + cabut_akses + idempoten + matriks_izin_6_peran + rls_semua_tabel`): **5 LULUS · 0 GAGAL**.
- Catatan higiene (ikut menyebabkan mutan ekuivalen lolos diam-diam): asersi terlalu luas `when others → v_tertangkap:=true` tanpa pencocokan pesan (mis. `pengaturan_meja.sql:290-293` Kasus 10) — direkomendasikan diperketat (bagian dari solusi F10-A1-07).

### B.5 Checker tambahan
| Checker | Hasil |
|---------|-------|
| `periksa-keamanan-sql.py` (skema EFEKTIF dari katalog) | **LOLOS** (search_path, ACL efektif, trigger-only, sapuan RLS, InitPlan) |
| `periksa-keamanan-sql.py --uji-diri` | **LOLOS — 13 mutasi terklasifikasi benar** (MERAH-PAGAR vs RUSAK; kontrol hijau) |
| `periksa-migrasi-beku.py` | **LOLOS** — 16 migrasi beku utuh (cocok DB Supabase nyata Lee) |
| `periksa-buku-uji.py` | **LOLOS** (28 baris valid) |
| `periksa-paritas-ci.py` | **GAGAL** — `periksa-header.py` + `--uji-diri` (ci.yml:289-290) absen dari `aplikasi/alat/periksa-semua.sh` → F10-A1-04 |
| `periksa-rujukan.py` | **GAGAL — 4 rujukan mati** (path alat salah di PAKET_AUDIT:118,131 & PROMPT_AGEN_2:26,31) → F10-A1-04/05 |
| validate_system, roadmap ±uji-diri, fondasi-independen, temuan-audit, audit, gerbang-ci, kunci-kalibrasi, audit-independen --uji-diri, ci_target --uji-diri, fungsi-pin, header | **semua LULUS lokal** → mengisolasi paritas+rujukan sebagai satu-satunya penyebab step CI merah |

### B.6 Verifikasi tanah-nyata CI (`gh`)
- Run tip target `36305336934` (commit 5f7b38b) = **completed failure** (18m20s); satu-satunya step merah: "Pemeriksa fondasi, roadmap, struktur, komponen, uji & kontras" (exit 1).
- **Semua step database ✓ hijau di run yang sama**: "Uji SQL penuh — RLS, isolasi resto & fungsi identitas" ✓; seluruh "Bukti mutasi pagar migrasi …" ✓ — konsisten dengan temuan lokal.
- Riwayat: `success` terakhir = "handoff: catat T10-09 selesai"; sejak T10-10 s/d tip: **failure/cancelled beruntun** → paket audit terbit saat CI merah.
- Cakupan gerbang mutasi di ci.yml: **37 dari 68** skrip; absen: `uji-mutasi-0056…0085` + `cadangan` (31 skrip = seluruh Fase 8–10) → F10-A1-08.

## 2C. Baterai Mutasi Penuh — 68/68 skrip `alat/uji-mutasi-*.py` (serial)

- **Hasil agregat:** 68 skrip dijalankan serial (bukan paralel — pelajaran F10-A1-02); **63 LULUS (RC0) · 5 GAGAL (RC1)**; **±431 mutan merah** (marka/ringkasan per skrip); **13 mutan hidup** — seluruhnya pada 5 skrip GAGAL; **0 kali tree kotor** (setiap skrip memulihkan berkasnya; pengaman `git checkout` tidak pernah terpakai); suite penuh penutup pasca-baterai: **132 LULUS · 0 GAGAL**.
- **5 skrip GAGAL:** `0062` (1 mutan hidup), `0063` (1), `0070` (1), `0073` (5), `0074` (5).
- **Akar penyebab tunggal (terverifikasi per kasus):** harness memutasi **definisi fungsi yang sudah usang** — di-DROP dan didefinisikan ulang oleh migrasi lebih baru, sehingga mutasi tidak mengubah perilaku apa pun (**mutan ekuivalen**, mustahil dibunuh oleh tes apa pun):
  - `katalog_publik`: 0062 → 0070 → **0071 (kini)** — mutan 0062-M01 (status aktif) & 0070-M07 (tagline) memutasi versi lama; versi kini 0071 **tetap menyaring `status='aktif'` (:260)** dan **tetap memuat tagline/logo/banner (:199-201)**.
  - `daftar_voucher`: 0063 → 0064 → **0067 (kini)** — mutan 0063-M03 (consent UU PDP) memutasi versi lama; versi kini 0067 **tetap memvalidasi consent (:664)** + CHECK skema `persetujuan_privasi = true` (0063:154) sebagai lapis kedua.
  - `simpan_meja`: 0073 → **0083 (kini)** — 5 mutan 0073 (otorisasi, keunikan, nonaktif-berpesanan-aktif, audit trail, nama wajib) memutasi versi lama; versi kini 0083 **memuat semuanya** (otorisasi :450-451; keunikan :505; audit & validasi di badan baru).
  - `simpan_menu`/`simpan_kategori_menu`: 0074 → **0083 (kini)** — 5 mutan 0074 (otorisasi kelola menu, harga negatif, nama wajib, keunikan per kategori, kategori sepenyewa) memutasi versi lama; versi kini 0083 **memuat otorisasi (:57, :281)** dan validasi-validasinya.
  - Preseden repo: commit `fix(mutasi): arahkan uji mutasi 0046 ke definisi terbaru tutup_shift` — kelas perbaikan yang sama belum diterapkan ke 5 harness ini setelah 0064/0067/0070/0071/0083 mendarat.
- **Konsekuensi jaminan (bukan kerentanan aktif):** 13 pagar pada definisi kini — termasuk 2 pagar OTORISASI (kelola meja, kelola menu) — saat ini **tidak memiliki bukti mutasi yang sah**; bila regresi masa depan menghapusnya, harness-harness ini tidak akan merah. Karena itu diklasifikasi K-2 (F10-A1-07), dengan catatan penting: **pagar-pagarnya ADA dan aktif hari ini** (diverifikasi baris demi baris + baseline hijau + suite 132 hijau).
- Tabel hasil per-skrip (68 baris) + kutipan mentah 5 skrip GAGAL: **`LAMPIRAN_F10_AGEN1_BATERAI_MUTASI_2026-09-27.md`** (direktori yang sama).

## 3. Daftar Temuan Masalah

### F10-A1-04 — Gerbang CI MERAH pada commit target audit (akar penyebab ganda)
- **Tingkat Keparahan:** **K-2** (klasifikasi §2 paket: "kegagalan gerbang CI")
- **Lokasi Berkas & Baris:** `aplikasi/alat/periksa-semua.sh` (absen: `python3 alat/periksa-header.py` + `--uji-diri`; bandingkan `ci.yml:289-290`); `docs/uji/PAKET_AUDIT_F10_3_AGEN.md:118,131`; `docs/uji/PROMPT_AGEN_2_FRONTEND.md:26,31`
- **Deskripsi Masalah:** Step CI "Pemeriksa fondasi…" exit 1 pada `5f7b38b` (run 36305336934). Akar 1: `periksa-paritas-ci.py` GAGAL — T10-14 menambah gerbang header ke ci.yml tanpa entri pendamping di agregator lokal. Akar 2 (tertutupi `bash -e`, terdeteksi lokal): `periksa-rujukan.py` GAGAL — 4 rujukan mati akibat path alat salah di paket audit & prompt Agen 2.
- **Langkah / Perintah Reproduksi:** `gh run view 36305336934` → X step tsb (semua step SQL/mutasi ✓); `python3 alat/periksa-paritas-ci.py` → GAGAL [X]×2; `python3 alat/periksa-rujukan.py` → GAGAL 4 rujukan mati; `grep -c periksa-header aplikasi/alat/periksa-semua.sh` → 0
- **Dampak Bisnis:** Klaim "126 gerbang CI aktif" pada paket audit resmi tidak benar saat terbit; sejak T10-10 gerbang CI TIDAK melindungi commit baru di cabang ini — regresi apa pun (termasuk keamanan) bisa mendarat tanpa terdeteksi; Agen 2 menemui 2 perintah "wajib" yang tidak ada di path tertulis. Domain database tidak terdampak (step SQL/mutasi ✓).
- **Rekomendasi Solusi:** (1) tambah 2 baris periksa-header ke `periksa-semua.sh`; (2) koreksi 4 path (118→`aplikasi/alat/uji-kontras.py`; 131 & 26/31→`aplikasi/alat/uji-mutasi-app.mjs`); (3) push → konfirmasi run hijau; (4) disiplin: setiap gerbang ci.yml baru WAJIB disertai entri periksa-semua.sh (paritas sudah dijaga mesin).

### F10-A1-07 — 5 harness uji-mutasi basi: memutasi definisi yang sudah digantikan (13 pagar kehilangan bukti mutasi)
- **Tingkat Keparahan:** **K-2** (aset pembuktian fail-closed proyek merah pada kode bersih; 2 di antaranya pagar otorisasi)
- **Lokasi Berkas & Baris:** `alat/uji-mutasi-0062.py`, `0063.py`, `0070.py`, `0073.py`, `0074.py` (target mutasi menunjuk badan fungsi di `supabase/migrations/0062/0063/0070/0073/0074` yang DI-DROP oleh `0064/0067/0071/0083`); contoh definisi kini: `0071_tema_merek.sql:260` (status aktif), `0067_pengaman_voucher.sql:664` (consent), `0083_versi_pengaturan_bersamaan.sql:57,281,450,505` (otorisasi & keunikan)
- **Deskripsi Masalah:** Baterai penuh 68 skrip: 63 LULUS, 5 GAGAL dengan **13 mutan hidup** ("lolos diam-diam"/"pagar tumpul"). Investigasi membuktikan seluruhnya **mutan ekuivalen**: harness memutasi versi LAMA fungsi yang sudah didefinisikan ulang (drop+create) oleh migrasi berikutnya, sehingga perilaku sistem tidak berubah dan tes tidak mungkin merah. Pagar pada definisi KINI diverifikasi ADA satu-satu (lihat §2C). Kontributor sekunder: beberapa asersi tes terlalu luas (`when others` → tertangkap, tanpa pencocokan pesan — mis. `supabase/tes/pengaturan_meja.sql:290-293`), sehingga bahkan setelah retarget, tes perlu diperketat agar benar-benar membuktikan pagar yang dimaksud.
- **Langkah / Perintah Reproduksi:** `python3 alat/uji-mutasi-0073.py` → "5 mutasi lolos diam-diam"; `grep -n "drop function if exists public.simpan_meja" supabase/migrations/0083_versi_pengaturan_bersamaan.sql` → :411; `grep -n "status = 'aktif'" supabase/migrations/0071_tema_merek.sql` → :260
- **Dampak Bisnis:** Bukan kerentanan aktif (pagar hidup hari ini; suite 132 hijau). Risiko: regresi masa depan yang menghapus otorisasi `kelola meja`/`kelola menu`, filter resto nonaktif di katalog publik, validasi consent UU PDP lapisan RPC, keunikan meja/menu, atau audit trail `simpan_meja` TIDAK akan memerahkan harness mana pun — keselamatan "merah saat dirusak" untuk 13 pagar itu sedang tidak terbukti. Klaim paket "bukti mutasi lengkap" overstated untuk area Fase 8–9.
- **Rekomendasi Solusi:** Retarget 5 harness ke definisi KINI (pola sudah dicontohkan commit `fix(mutasi): arahkan uji mutasi 0046 ke definisi terbaru tutup_shift`): 0062/0070 → mutasi `katalog_publik` versi 0071; 0063 → mutasi `daftar_voucher` versi 0067; 0073/0074 → mutasi `simpan_meja`/`simpan_menu`/`simpan_kategori_menu` versi 0083. Tambahkan penjaga otomatis "definisi terbaru menang": skrip kecil yang memetakan fungsi→migrasi terakh yang mendefinisikan, dan menolak harness yang menarget versi lama. Perketat asersi tes yang menangkap `when others` tanpa pencocokan pesan.

### F10-A1-05 — Dokumen paket audit & prompt Agen 2 menunjuk alat yang tidak ada
- **Tingkat Keparahan:** K-3 (menghambat auditabilitas Agen 2; akar ke-2 F10-A1-04)
- **Lokasi Berkas & Baris:** `docs/uji/PAKET_AUDIT_F10_3_AGEN.md:118,131`; `docs/uji/PROMPT_AGEN_2_FRONTEND.md:26,31`
- **Deskripsi Masalah:** `aplikasi/alat/periksa-kontras.py` tidak ada (yang ada & dijalankan CI:313-314: `aplikasi/alat/uji-kontras.py`); `alat/uji-mutasi-app.mjs` tidak ada (yang ada & dijalankan CI:62: `aplikasi/alat/uji-mutasi-app.mjs`).
- **Langkah / Perintah Reproduksi:** `ls aplikasi/alat/periksa-kontras.py alat/uji-mutasi-app.mjs` → tidak ada; `ls aplikasi/alat/uji-kontras.py aplikasi/alat/uji-mutasi-app.mjs` → ada
- **Dampak Bisnis:** Auditor frontend dapat salah menyimpulkan "alat hilang" atau melewati 2 verifikasi wajib; integritas paket audit resmi berkurang.
- **Rekomendasi Solusi:** Koreksi 4 rujukan; `periksa-rujukan.py` hijau kembali.

### F10-A1-08 — 31 dari 68 skrip uji mutasi tidak menjadi gerbang CI
- **Tingkat Keparahan:** K-3 (risiko sistemik — memungkinkan F10-A1-07 bertahan tak terdeteksi)
- **Lokasi Berkas & Baris:** `.github/workflows/ci.yml` (37 skrip `uji-mutasi-*` disebut eksplisit; tanpa loop/glob); absen: `uji-mutasi-0056.py` … `uji-mutasi-0085.py` + `uji-mutasi-cadangan.py`
- **Deskripsi Masalah:** Seluruh harness mutasi Fase 8–10 (voucher, privasi, pengaturan, kelola pegawai/cabang, idempotensi ART-8, sesi, denyut, konkurensi, cabut akses T10-12, ringkasan) hanya dijalankan manual. Buktinya: 5 harness basi (F10-A1-07) lolos dari perhatian karena tidak pernah dieksekusi CI.
- **Langkah / Perintah Reproduksi:** `grep -oE "uji-mutasi-[0-9a-z]+\.py" .github/workflows/ci.yml | sort -u | wc -l` → 37; `ls alat/uji-mutasi-*.py | wc -l` → 68
- **Dampak Bisnis:** Regresi pada pagar Fase 8–10 (termasuk ART-8 & T10-12 — area uang & akses pegawai) bisa mendarat tanpa bukti-mutasi yang memerahkan CI.
- **Rekomendasi Solusi:** Tambahkan 31 skrip ke CI (bila durasi total memberatkan, jadwalkan sebagai job nightly/terpisah WAJIB-hijau), atau buat satu gerbang agregat yang menjalankan seluruh keluarga `uji-mutasi-*.py` serial dengan lock (sinergi dengan F10-A1-02).

### F10-A1-01 — Klaim "85 migrasi" vs realitas 82 berkas; celah penomoran tak terdokumentasi
- **Tingkat Keparahan:** K-4
- **Lokasi Berkas & Baris:** `docs/uji/PAKET_AUDIT_F10_3_AGEN.md:43`; `docs/uji/PROMPT_AGEN_1_DATABASE.md:17`; `docs/ops/SIAP-LANJUT.md:2099`; `supabase/migrations/` (tanpa README)
- **Deskripsi Masalah:** Realitas 82 berkas (runner: "Menerapkan 82 migrasi"). Celah 0034/0044/0055 tak pernah ada di riwayat git: fungsi 0034 → `0032_status_item_dapur.sql`; fungsi 0055 → `0064_terbit_voucher_acak.sql`; 0044 = T6-07 printer belum dikerjakan (`ROADMAP.md:1498` masih `[ ]`).
- **Langkah / Perintah Reproduksi:** `ls supabase/migrations/*.sql | wc -l` → 82
- **Dampak Bisnis:** Kebingungan auditor/pengembang baru; tanpa dampak keamanan.
- **Rekomendasi Solusi:** Koreksi angka di trio dokumen; tambah `supabase/migrations/README.md` (menutup rekomendasi [F-01] audit terdahulu).

### F10-A1-02 — Harness uji mutasi tanpa kunci: eksekusi paralel memicu positif-palsu
- **Tingkat Keparahan:** K-4
- **Lokasi Berkas & Baris:** keluarga `alat/uji-mutasi-*.py` (mutasi in-place `supabase/migrations/*.sql` pada working tree bersama)
- **Deskripsi Masalah:** Terbukti saat audit: 0084 paralel dengan 0083 → "GAGAL 0083… syntax error at or near 'if'" (0084 membaca 0083 yang sedang termutasi sementara). Bukti race: tree bersih + md5 utuh pasca-insiden; re-run serial → 4/4 terbunuh. Risiko sisa: proses dibunuh paksa di tengah mutasi dapat meninggalkan berkas rusak.
- **Langkah / Perintah Reproduksi:** `python3 alat/uji-mutasi-0083.py & python3 alat/uji-mutasi-0084.py & wait`
- **Dampak Bisnis:** False alarm auditor/CI; potensi tree kotor bila interupsi.
- **Rekomendasi Solusi:** `flock` pada lockfile bersama + pemulihan `try/finally` + catatan "JALANKAN SERIAL" di PAKET_AUDIT §3.C. (Baterai 68-skrip audit ini menjalankan serial dengan pengaman restore otomatis: 0 insiden.)

### F10-A1-03 — Tidak ada `FORCE ROW LEVEL SECURITY` (pertahanan-berlapis opsional)
- **Tingkat Keparahan:** K-4
- **Lokasi Berkas & Baris:** seluruh migrasi (0 pernyataan; katalog hidup `force_rls=0`)
- **Deskripsi Masalah:** Pemilik tabel melewati RLS implisit untuk kueri langsung. Jalur API tidak terdampak (anon/authenticated tunduk policy; service_role bypassrls by-design Supabase).
- **Langkah / Perintah Reproduksi:** `grep -rhoi "force row level security" supabase/migrations/*.sql | wc -l` → 0
- **Dampak Bisnis:** Sangat rendah; relevan hanya untuk kueri langsung sebagai pemilik tabel.
- **Rekomendasi Solusi:** Evaluasi Fase 11 untuk tabel inti keuangan (pesanan, pembayaran, shift_kas, kas_pergerakan, catatan_audit).

### F10-A1-06 — Permukaan ACL anon warisan (mati efektif, higiene)
- **Tingkat Keparahan:** K-4
- **Lokasi Berkas & Baris:** `0001:68-69`, `0002:116-120`, `0005:294-295`, `0008:64` (22 tabel SELECT ke anon; `pengaturan` SELECT+UPDATE)
- **Deskripsi Masalah:** Katalog hidup membuktikan permukaan MATI: 0 policy anon permisif → baca anon = 0 baris, tulis ditolak. Namun grant berlebihan memperbesar permukaan bila suatu hari policy anon keliru dibuat.
- **Langkah / Perintah Reproduksi:** introspeksi §2B.2 bagian F + B; `supabase/tes/rls_penyewa.sql:8-10` (anon → 0 baris)
- **Dampak Bisnis:** Tidak ada kebocoran aktif; risiko laten higiene-izin.
- **Rekomendasi Solusi:** Migrasi ≥0086: `revoke all on <tabel-tabel itu> from anon;` (permukaan publik sudah lewat RPC `katalog_publik`, bukan ACL tabel).

## 4. Kesimpulan & Rekomendasi untuk Pemilik Platform (Lee)

**VERDICT: PERLU PERBAIKAN** — dengan penegasan berlapis: **inti Basis Data, Keamanan SQL & Multi-Tenant BERSIH**. Dua putaran audit (16 perintah wajib + audit mendalam: statis, katalog hidup, runtime, 6 checker tambahan, tanah-nyata CI via gh, dan baterai mutasi PENUH 68/68 skrip dengan ±431 mutan merah) tidak menemukan satu pun celah isolasi penyewa (K-1), kebocoran kredensial, bypass RLS/otorisasi aktif, atau pagar hilang pada definisi yang berlaku kini: 47/47 tabel fail-closed; 0/186 SECURITY DEFINER tanpa search_path terkunci; permukaan anon terbatas 9 RPC publik berpagar; PIN bcrypt+throttle+deny-all; rantai audit SHA-256 kekal; idempotensi 8/8 RPC; cabut-akses pegawai atomik; 13 mutan yang "hidup" seluruhnya terbukti mutan ekuivalen dari 5 harness basi — pagarnya sendiri hidup dan diverifikasi baris demi baris.

Yang menahan verdict BERSIH adalah **lapisan pembuktian & gerbang**, bukan lapisan data: (1) **K-2 F10-A1-04** — CI merah beruntun sejak T10-10 pada commit target (2 baris hilang di periksa-semua.sh + 4 rujukan path salah; estimasi perbaikan <15 menit); (2) **K-2 F10-A1-07** — 5 harness mutasi menarget definisi mati sehingga 13 pagar (termasuk 2 pagar otorisasi kelola meja/menu) kehilangan bukti "merah saat dirusak" (retarget ke definisi kini, preseden commit fix-0046 sudah ada); (3) **K-3 F10-A1-05** — paket audit menunjuk 2 alat di path yang salah (menghambat Agen 2); (4) **K-3 F10-A1-08** — 31 skrip mutasi Fase 8–10 belum digerber CI; (5) empat K-4 (85→82, lock harness, FORCE RLS, ACL anon warisan).

**Urutan kerja yang direkomendasikan sebelum Fase 11:** ① perbaiki F10-A1-04 (2 baris + 4 path) → push → CI hijau; ② retarget 5 harness basi (F10-A1-07) + perketat asersi `when others`; ③ masukkan keluarga mutasi 0056–0085 ke gerbang CI (F10-A1-08); ④ rapikan K-4 (README migrasi, lock serial, revoke ACL anon, evaluasi FORCE RLS). Dari sisi **keamanan data penyewa, sistem SIAP DISEWAKAN hari ini**; klaim publik "CI hijau & bukti mutasi lengkap" baru sah setelah ①–③.

---
*Auditor Independen Ke-1 (Basis Data, Keamanan SQL & Multi-Tenant) — 2026-09-27. Seluruh keluaran = eksekusi nyata (Node v22.22.3, Python 3.11.2, PGlite/PostgreSQL WASM, gh CLI) pada target `5f7b38be21f1921663f6286a26ebe62f285f4d99`. Kode target tidak diubah; commit pada cabang sesi `arena/01a0e1ee-resto-barokah` hanya berisi laporan + lampiran ini. Bukti mentah baterai: `LAMPIRAN_F10_AGEN1_BATERAI_MUTASI_2026-09-27.md`.*
