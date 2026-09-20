#!/usr/bin/env python3
"""Pemeriksa gerbang CI — memastikan langkah pengaman di GitHub Actions TIDAK hilang/melemah.

Kenapa ada: temuan palsu peninjau PR-01 (putaran11, 2026-09-17). Peninjau membaca diff
`ci.yml` dan menyimpulkan bahwa langkah "Uji SQL" memakai `node alat/uji-sql.mjs --daftar`
sehingga "tidak menjalankan 28 berkas uji". Kesimpulan itu SALAH — `--daftar` hanya
MENAMBAH cetakan daftar tabel, uji tetap dijalankan (dibuktikan dengan menyuntikkan uji
yang sengaja gagal → `uji: 27 LULUS · 1 GAGAL`, exit 1). Tetapi nama opsinya memang
menjebak, dan itu kelas cacat yang nyata: **gerbang CI yang tampak ada bisa disalahbaca
(atau diam-diam dilemahkan) tanpa ada yang menangkap.**

Dua perbaikan dari pelajaran itu:
  1. Langkah CI memakai perintah penuh (tanpa `--daftar`) dan namanya menyebut "penuh".
  2. Pemeriksa ini mengunci gerbang-gerbang wajib: kalau salah satunya hilang, diturunkan
     ambangnya, atau diberi `|| true`/`continue-on-error`, pemeriksa MERAH.

Jalankan:  python3 alat/periksa-gerbang-ci.py [--uji-diri]
"""

from __future__ import annotations

import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

AKAR = pathlib.Path(__file__).resolve().parents[1]
CI = AKAR / ".github" / "workflows" / "ci.yml"

# Perintah CI yang DIKENAL dan WAJIB ada — SEMUA perintah di ci.yml, bukan hanya yang penting.
#
# Kenapa lengkap (temuan review PR-10 putaran verifikasi 2026-09-19, K-3): dulu daftar ini hanya
# memuat 22 gerbang "penting", sehingga langkah yang tidak terdaftar bisa DIHAPUS tanpa pemeriksa
# menyala (peninjau membuktikannya: menghapus `alat/periksa-rahasia.py` dari salinan ci.yml tetap
# LOLOS) dan langkah yang dinonaktifkan dengan `if: false` tidak terlihat sama sekali. Dua arah kini
# diperiksa:
#   (a) tiap pola di bawah WAJIB cocok dengan satu perintah di ci.yml (tidak boleh hilang/diturunkan),
#   (b) tiap perintah di ci.yml WAJIB cocok dengan satu pola di bawah (tidak ada perintah tak dikenal
#       yang menyelinap — mis. `python3 alat/pemeriksa-palsu.py`).
# Pola diANKUR `^...$` dan dicocokkan PER BARIS PERINTAH (bukan seluruh berkas), supaya baris
# uji-diri tidak ikut memuaskan pola langkah aslinya (pelajaran uji-diri pertama pemeriksa ini).
GERBANG_WAJIB = [
    ("pasang pustaka aplikasi (npm ci)", r"npm ci"),
    ("kerapian kode (Prettier)", r"npm run format:check"),
    ("aturan kode (ESLint)", r"npm run lint"),
    ("tipe (TypeScript ketat)", r"npm run typecheck"),
    ("uji unit (Vitest)", r"npm test"),
    ("bukti mutasi kode aplikasi (uji wajib MERAH pada cacat nyata)", r"node aplikasi/alat/uji-mutasi-app\.mjs"),
    ("uji-diri harness mutasi aplikasi", r"node aplikasi/alat/uji-mutasi-app\.mjs --uji-diri"),
    ("bangun aplikasi", r"npm run build"),
    ("kerentanan dependency (npm audit, 0 toleransi)", r"npm audit --audit-level=low"),
    ("uji sambung Supabase dengan kunci publik (T0-08)", r"npm run cek:supabase"),
    ("pasang alat uji SQL", r"npm ci --prefix alat"),
    ("suite uji SQL penuh", r"node alat/uji-sql.mjs"),
    ("bukti mutasi pagar migrasi 0012", r"python3 alat/uji-mutasi-0012.py"),
    ("bukti mutasi pagar migrasi 0014", r"python3 alat/uji-mutasi-0014.py"),
    ("bukti mutasi pagar migrasi 0015 (K-1 + K-2 putaran16)", r"python3 alat/uji-mutasi-0015.py"),
    ("bukti mutasi pagar migrasi 0016 (penutup celah PIN putaran18 F-13…F-16)",
     r"python3 alat/uji-mutasi-0016.py"),
    ("uji batas Edge Function verifikasi_pin (berkas asli dijalankan tanpa jaringan)", r"node alat/uji-edge-pin\.mjs"),
    ("validator sistem", r"python3 _sistem/validate_system.py"),
    ("pemeriksa fungsi PIN", r"python3 alat/periksa-fungsi-pin.py"),
    ("pemeriksa roadmap", r"python3 alat/periksa-roadmap.py"),
    ("pemeriksa fondasi independen", r"python3 alat/periksa-fondasi-independen.py"),
    ("uji-diri pemeriksa audit independen", r"python3 alat/audit-independen.py --uji-diri"),
    ("uji-diri penyiap pemeriksaan (frasa → paket + prompt pendek)", r"python3 alat/siapkan-pemeriksaan.py --uji-diri"),
    ("pemeriksa buku induk (panduan)", r"python3 alat/periksa-panduan.py"),
    ("uji-diri pemeriksa buku induk", r"python3 alat/periksa-panduan.py --uji-diri"),
    ("pemeriksa rujukan dokumen", r"python3 alat/periksa-rujukan.py"),
    ("uji-diri pemeriksa rujukan", r"python3 alat/periksa-rujukan.py --uji-diri"),
    ("pemeriksa temuan audit", r"python3 alat/periksa-temuan-audit.py"),
    ("uji-diri pemeriksa temuan audit", r"python3 alat/periksa-temuan-audit.py --uji-diri"),
    ("pemeriksa buku uji", r"python3 alat/periksa-buku-uji.py"),
    ("uji-diri pemeriksa buku uji", r"python3 alat/periksa-buku-uji.py --uji-diri"),
    ("uji-diri pemeriksa laporan review", r"python3 alat/review-pr.py --uji-diri"),
    ("pemeriksa kerapatan tampilan", r"python3 aplikasi/alat/periksa-kerapatan.py"),
    ("uji-diri pemeriksa kerapatan", r"python3 aplikasi/alat/periksa-kerapatan.py --uji-diri"),
    ("pemeriksa antarmuka (panel & tepi gulir)", r"python3 aplikasi/alat/periksa-antarmuka.py"),
    ("uji-diri pemeriksa antarmuka", r"python3 aplikasi/alat/periksa-antarmuka.py --uji-diri"),
    ("pemeriksa rahasia & lembar kunci", r"python3 alat/periksa-rahasia.py"),
    ("uji-diri pemeriksa rahasia", r"python3 alat/periksa-rahasia.py --uji-diri"),
    ("pemeriksa pohon bersih", r"python3 alat/periksa-bersih.py"),
    ("pemeriksa gerbang CI", r"python3 alat/periksa-gerbang-ci.py"),
    ("uji-diri pemeriksa gerbang CI", r"python3 alat/periksa-gerbang-ci.py --uji-diri"),
    ("pemeriksa kunci kalibrasi (bahan tidak boleh di repo)", r"python3 alat/periksa-kunci-kalibrasi.py"),
    ("uji-diri pemeriksa kunci kalibrasi", r"python3 alat/periksa-kunci-kalibrasi.py --uji-diri"),
    ("pemeriksa paket audit/review (invarian commit F-11/F-12)", r"python3 alat/periksa-paket.py"),
    ("uji-diri pemeriksa paket (F-11/F-12)", r"python3 alat/periksa-paket.py --uji-diri"),
    ("pemeriksa handoff lanjut-sesi (isi + uji-diri)", r"python3 alat/lanjut-sesi.py --di-ci"),
    ("uji-diri handoff lanjut-sesi", r"python3 alat/lanjut-sesi.py --uji-diri"),
    ("uji-diri kartu sesi (pemetaan skill fase)", r"python3 alat/mulai-sesi.py --uji-diri"),
    ("pemeriksa angka bukti & jumlah tugas (F-14 + jumlah tugas keadaan-sekarang)", r"python3 alat/periksa-angka-bukti.py"),
    ("uji-diri pemeriksa angka bukti ROADMAP (F-14)", r"python3 alat/periksa-angka-bukti.py --uji-diri"),
    ("pemeriksa migrasi beku (repo vs database nyata)", r"python3 alat/periksa-migrasi-beku.py"),
    ("uji-diri pemeriksa migrasi beku", r"python3 alat/periksa-migrasi-beku.py --uji-diri"),
    ("uji-diri alat catat alamat publik (bukti deploy T0-09)", r"node aplikasi/alat/catat-alamat\.mjs --uji-diri"),
    ("uji-diri pemeriksa pohon bersih", r"python3 alat/periksa-bersih.py --uji-diri"),
    ("pemeriksa struktur aplikasi", r"python3 aplikasi/alat/periksa-struktur.py"),
    ("pemeriksa versi Node yang diiklankan vs pustaka terkunci (I F-21)", r"python3 aplikasi/alat/periksa-node\.py"),
    ("uji-diri pemeriksa versi Node (I F-21)", r"python3 aplikasi/alat/periksa-node\.py --uji-diri"),
    ("uji-diri pemeriksa komponen & env", r"python3 aplikasi/alat/periksa-komponen-env.py --uji-diri"),
    ("pemeriksa uji aplikasi", r"python3 aplikasi/alat/periksa-uji.py"),
    ("uji-diri pemeriksa uji aplikasi (I F-19: nama kuat, badan lemah)", r"python3 aplikasi/alat/periksa-uji\.py --uji-diri"),
    ("pemeriksa kontras & aturan desain", r"python3 aplikasi/alat/uji-kontras.py"),
    ("uji-diri pemeriksa kontras", r"python3 aplikasi/alat/uji-kontras.py --uji-diri"),
]

# ---------------------------------------------------------------------------
# ALUR DI LUAR ci.yml (berkas alur "disengaja" milik pemilik: menyebar skema ke proyek nyata,
# dan menaikkan halaman ke Cloudflare). Kenapa ikut diawasi: berkas alur apa pun bisa
# dilemahkan senyap dengan cara yang sama (`continue-on-error`, `|| true`, langkah dihapus) —
# dan justru alur inilah yang menyentuh aset NYATA milik pemilik.
#
# Aturan per berkas:
#   "perintah" = daftar (nama, pola) yang WAJIB ada dan WAJIB dikenali (dua arah, seperti ci.yml);
#   "berkas"   = baris penting yang bukan perintah, mis. penyaring berkas penanda. Kalau penyaring
#                itu hilang, alur akan menyala di SETIAP kiriman kode — bahaya senyap yang nyata.
ALUR_LAIN: dict[str, dict[str, list[tuple[str, str]]]] = {
    "sebar-skema.yml": {
        "perintah": [
            ("matikan galat senyap (`set -euo pipefail`)", r"set -euo pipefail"),
            ("berhenti tanpa kerja bila berkas penanda sudah dihapus",
             r"test -f supabase/SEBAR-SKEMA \|\| \{ echo .*exit 0; \}"),
            ("cek rahasia SUPABASE_ACCESS_TOKEN tersedia",
             r'test -n "\$SUPABASE_ACCESS_TOKEN" \|\| \{ echo .*exit 1; \}'),
            ("cek rahasia SUPABASE_DB_PASSWORD tersedia",
             r'test -n "\$SUPABASE_DB_PASSWORD" \|\| \{ echo .*exit 1; \}'),
            ("tautkan ke proyek Supabase",
             r'npx --yes supabase@2\.117\.0 --yes link --project-ref "\$SUPABASE_PROJECT_REF"'
             r' --password "\$SUPABASE_DB_PASSWORD"'),
            ("pratinjau rencana lebih dulu (dry-run)",
             r"npx --yes supabase@2\.117\.0 --yes db push --dry-run"
             r' --password "\$SUPABASE_DB_PASSWORD"'),
            ("sebar migrasi",
             r"npx --yes supabase@2\.117\.0 --yes db push"
             r' --password "\$SUPABASE_DB_PASSWORD"'),
            ("daftar migrasi terpasang (bukti)",
             r"npx --yes supabase@2\.117\.0 --yes migration list --linked"
             r' --password "\$SUPABASE_DB_PASSWORD"'),
        ],
        "berkas": [
            ("hanya menyala lewat berkas penanda supabase/SEBAR-SKEMA",
             r"^\s*- 'supabase/SEBAR-SKEMA'\s*$"),
        ],
    },
    "sebar-halaman.yml": {
        "perintah": [
            ("matikan galat senyap (`set -euo pipefail`)", r"set -euo pipefail"),
            ("berhenti tanpa kerja bila berkas penanda sudah dihapus",
             r"test -f aplikasi/SEBAR-HALAMAN \|\| \{ echo .*exit 0; \}"),
            ("cek rahasia CLOUDFLARE_API_TOKEN tersedia",
             r'test -n "\$CLOUDFLARE_API_TOKEN" \|\| \{ echo .*exit 1; \}'),
            ("pasang pustaka aplikasi", r"npm ci --prefix aplikasi"),
            ("bangun lalu unggah (satu perintah rilis)", r"npm run --prefix aplikasi deploy"),
            ("catat alamat publik + periksa HTTP (bukti, lewat anotasi)", r"node aplikasi/alat/catat-alamat\.mjs"),
        ],
        "berkas": [
            ("hanya menyala lewat berkas penanda aplikasi/SEBAR-HALAMAN",
             r"^\s*- 'aplikasi/SEBAR-HALAMAN'\s*$"),
        ],
    },
}

# Alur yang WAJIB ADA. Kalau seseorang menghapus berkasnya, penyebaran jadi tidak mungkin —
# itu juga perubahan yang harus disengaja, bukan senyap.
ALUR_WAJIB_ADA = tuple(ALUR_LAIN)

# Perintah yang boleh ada di CI tanpa masuk daftar di atas (mis. langkah perawatan runner).
# Kosong dengan sengaja: setiap perintah baru WAJIB didaftarkan — itulah inti penjaganya.
PERINTAH_TANPA_GERBANG: tuple[str, ...] = ()

# Kunci NON-perintah yang wajib ada di ci.yml. Kenapa dipisah: pemeriksaan dua arah di atas hanya
# menyisir isi `run:`, sedangkan sebagian gerbang berbentuk KUNCI langkah (mis. `fetch-depth: 0` yang
# dibutuhkan pemeriksa paket agar riwayat commit lengkap). Tanpa daftar ini, menurunkan `fetch-depth`
# ke 1 tidak terdeteksi (mutasi uji-diri yang sudah ada sejak 2026-09-19 menangkapnya kembali).
WAJIB_DI_BERKAS = [
    ("riwayat penuh untuk pemeriksa paket (fetch-depth 0)", r"fetch-depth:\s*0\s*$"),
]

# Pola pelemahan senyap yang dilarang
PELEMAHAN = [
    (r"continue-on-error:\s*true", "langkah diberi `continue-on-error: true` (gagal tidak memerahkan CI)"),
    (r"^\s*run:\s*.*\|\|\s*true", "perintah diberi `|| true` (gagal ditelan)"),
    (r"^\s*run:\s*.*\|\|\s*exit\s+0", "perintah diberi `|| exit 0` (gagal ditelan)"),
    (r"^\s*(?:run:\s*)?\S.*\|\|\s*(?:true|exit\s+0|:)\s*$",
     "perintah diberi penelan galat (`|| true` / `|| exit 0` / `|| :`) — gagal tidak akan memerahkan CI"),
    (r"^\s*run:\s*exit\s+0", "perintah diganti `exit 0`"),
    (r"^\s*run:\s*set\s+\+e", "penanganan galat dimatikan (`set +e`)"),
    (r"^\s*if:\s*", "langkah diberi syarat `if:` — gerbang bisa DILEWATI tanpa mengubah perintahnya "
                      "(temuan PR-10: `if: false` tidak terlihat oleh pemeriksa lama)"),
]


def perintah_ci(teks: str) -> list[str]:
    """Semua perintah yang benar-benar dijalankan CI (isi `run:`, satu per baris).

    Kenapa dipisah jadi daftar: pemeriksa lama hanya mencari pola di seluruh berkas, sehingga
    (1) langkah yang dihapus tidak ketahuan bila polanya tidak terdaftar, dan (2) `if: false`
    sama sekali tidak terlihat. Dengan daftar perintah nyata, kedua arah bisa diperiksa.
    """
    hasil: list[str] = []
    baris = teks.splitlines()
    i = 0
    while i < len(baris):
        m = re.match(r"^(\s*)run:\s*(.*)$", baris[i])
        if not m:
            i += 1
            continue
        indent, sisa = len(m.group(1)), m.group(2).strip()
        if sisa and sisa != "|":
            hasil.append(sisa)
            i += 1
            continue
        i += 1
        while i < len(baris):
            b = baris[i]
            if b.strip() == "":
                i += 1
                continue
            if len(b) - len(b.lstrip()) > indent and not b.lstrip().startswith("#"):
                hasil.append(b.strip())
                i += 1
                continue
            break
    return hasil


def periksa(akar: pathlib.Path) -> tuple[int, list[str]]:
    ci = akar / ".github" / "workflows" / "ci.yml"
    pesan: list[str] = []
    if not ci.is_file():
        return 1, [f"berkas CI tidak ada: {ci}"]
    teks = ci.read_text(encoding="utf-8")

    perintah = perintah_ci(teks)

    for nama, pola in WAJIB_DI_BERKAS:
        if not re.search(pola, teks, re.M):
            pesan.append(f"kunci wajib CI tidak ditemukan/diturunkan: {nama}")

    # (a) tiap gerbang wajib harus ada
    kurang: list[str] = []
    for nama, pola in GERBANG_WAJIB:
        if not any(re.search(rf"^{pola}$", p) for p in perintah):
            kurang.append(nama)
    if kurang:
        pesan.append(
            "gerbang wajib TIDAK ADA (atau diubah sehingga tidak dikenali) di .github/workflows/ci.yml: "
            + ", ".join(kurang)
        )

    # (b) tidak boleh ada perintah tak dikenal
    dikenal = [re.compile(rf"^{pola}$") for _, pola in GERBANG_WAJIB]
    for p in perintah:
        if any(r.search(p) for r in dikenal):
            continue
        if any(re.search(rf"^{pola}$", p) for pola in PERINTAH_TANPA_GERBANG):
            continue
        pesan.append(
            f"perintah TIDAK DIKENAL di CI: `{p}` — setiap perintah wajib terdaftar di "
            "`GERBANG_WAJIB` (alat/periksa-gerbang-ci.py) supaya tidak ada langkah yang tak diawasi"
        )

    for pola, alasan in PELEMAHAN:
        for cocok in re.finditer(pola, teks, re.M):
            baris = teks[: cocok.start()].count("\n") + 1
            pesan.append(f"pelemahan gerbang di baris {baris}: {alasan}")

    # ---- alur di luar ci.yml: perintah diawasi dua arah + dilarang dilemahkan senyap ----
    for nama_alur in ALUR_WAJIB_ADA:
        alur = akar / ".github" / "workflows" / nama_alur
        if not alur.is_file():
            pesan.append(f"alur wajib TIDAK ADA: .github/workflows/{nama_alur} (penyebaran jadi tidak mungkin)")
            continue
        aturan = ALUR_LAIN[nama_alur]
        isi_alur = alur.read_text(encoding="utf-8")
        perintah_alur = perintah_ci(isi_alur)

        for nama, pola in aturan["berkas"]:
            if not re.search(pola, isi_alur, re.M):
                pesan.append(f".github/workflows/{nama_alur}: kunci wajib hilang/diubah — {nama}")

        kurang_alur: list[str] = []
        for nama, pola in aturan["perintah"]:
            if not any(re.search(rf"^{pola}$", q) for q in perintah_alur):
                kurang_alur.append(nama)
        if kurang_alur:
            pesan.append(
                f".github/workflows/{nama_alur}: perintah wajib TIDAK ADA (atau diubah sehingga tidak "
                "dikenali): " + ", ".join(kurang_alur)
            )

        # URUTAN juga penting, bukan hanya keberadaan: "pratinjau lebih dulu" dan "penanda
        # diperiksa sebelum menyentuh proyek" adalah sifat keselamatan. Kalau urutannya ditukar
        # (mis. sebar sebelum dry-run), pemeriksa lama tetap lolos — itu lubang yang ditutup di sini.
        letak: list[int] = []
        for _, pola in aturan["perintah"]:
            letak.append(
                next((i for i, q in enumerate(perintah_alur) if re.fullmatch(pola, q)), -1)
            )
        if all(i >= 0 for i in letak) and letak != sorted(letak):
            pesan.append(
                f".github/workflows/{nama_alur}: URUTAN perintah berubah — daftar di `ALUR_LAIN` "
                f"menuntut urutan {list(range(len(letak)))}, tetapi berkas memberi {letak}. "
                "Perintah berurutan yang benar adalah bagian dari keamanan alur ini."
            )

        pola_alur = [re.compile(rf"^{pola}$") for _, pola in aturan["perintah"]]
        for q in perintah_alur:
            if any(r.search(q) for r in pola_alur):
                continue
            pesan.append(
                f"perintah TIDAK DIKENAL di .github/workflows/{nama_alur}: `{q}` — daftarkan di "
                "`ALUR_LAIN` (alat/periksa-gerbang-ci.py) supaya tidak ada langkah yang tak diawasi"
            )

        for pola, alasan in PELEMAHAN:
            for cocok in re.finditer(pola, isi_alur, re.M):
                baris_alur = isi_alur[: cocok.start()].count("\n") + 1
                pesan.append(
                    f"pelemahan gerbang di .github/workflows/{nama_alur} baris {baris_alur}: {alasan}"
                )

    for i, baris_ci in enumerate(teks.splitlines(), start=1):
        if baris_ci.lstrip().startswith("#"):
            continue  # komentar boleh menyebut --daftar (justru menjelaskan kenapa tidak dipakai)
        if "--daftar" in baris_ci and "uji-sql" in baris_ci:
            pesan.append(
                f"baris {i}: langkah CI memakai `--daftar`. Opsi itu TETAP menjalankan uji, tetapi "
                "namanya menjebak dan sudah pernah menyesatkan peninjau — pakai perintah penuh "
                "`node alat/uji-sql.mjs` supaya tidak ada yang bisa salah baca"
            )

    return (1 if pesan else 0), pesan


def _jalankan(skrip: pathlib.Path, cwd: pathlib.Path) -> tuple[int, str]:
    """Jalankan SALINAN pemeriksa di dalam pohon uji (bukan berkas asli) supaya
    mutasi benar-benar dinilai oleh salinan itu."""
    hasil = subprocess.run(
        [sys.executable, str(skrip)], capture_output=True, text=True, cwd=str(cwd)
    )
    return hasil.returncode, hasil.stdout + hasil.stderr


def uji_diri() -> int:
    """Buktikan pemeriksa ini bisa MENOLAK yang rusak dan MENERIMA yang utuh."""
    kasus: list[tuple[str, int]] = []
    akar_asli = AKAR
    with tempfile.TemporaryDirectory(prefix="gerbang-ci-") as tmp:
        tmp_p = pathlib.Path(tmp)
        (tmp_p / ".github" / "workflows").mkdir(parents=True)
        for berkas_alur in sorted((akar_asli / ".github" / "workflows").glob("*.y*ml")):
            shutil.copy2(berkas_alur, tmp_p / ".github" / "workflows" / berkas_alur.name)
        (tmp_p / "alat").mkdir(parents=True, exist_ok=True)
        shutil.copy2(akar_asli / "alat" / "periksa-gerbang-ci.py", tmp_p / "alat" / "periksa-gerbang-ci.py")

        skrip_uji = tmp_p / "alat" / "periksa-gerbang-ci.py"
        kode, keluar = _jalankan(skrip_uji, tmp_p)
        kasus.append(("salinan utuh → diterima", kode == 0))
        if kode != 0:
            print(keluar[:1200])

        def mutasi(nama: str, ubah) -> None:
            ci = tmp_p / ".github" / "workflows" / "ci.yml"
            asli = ci.read_text(encoding="utf-8")
            ci.write_text(ubah(asli), encoding="utf-8")
            kode_m, keluar_m = _jalankan(skrip_uji, tmp_p)
            kasus.append((f"mutasi: {nama} → ditolak", kode_m != 0))
            if kode_m == 0:
                print(f"  ! {nama} DILOLOSKAN\n{keluar_m[:600]}")
            ci.write_text(asli, encoding="utf-8")

        mutasi("suite SQL diberi `--daftar`", lambda t: t.replace("run: node alat/uji-sql.mjs", "run: node alat/uji-sql.mjs --daftar"))
        mutasi("langkah bukti mutasi dihapus", lambda t: re.sub(r"\n\s*- name: Bukti mutasi[\s\S]*?run: python3 alat/uji-mutasi-0012\.py", "", t, count=1))
        # Gerbang 0014 (putaran13/audit 2026-09-18) dibuktikan sama kuat: kalau
        # langkahnya dihapus dari CI, pemeriksa ini harus MENOLAK.
        mutasi("langkah bukti mutasi 0015 dihapus",
               lambda t: re.sub(r"\n\s*- name: Bukti mutasi pagar migrasi 0015[\s\S]*?run: python3 alat/uji-mutasi-0015\.py", "", t, count=1))
        mutasi("langkah bukti mutasi 0014 dihapus", lambda t: re.sub(r"\n\s*- name: Bukti mutasi pagar migrasi 0014[\s\S]*?run: python3 alat/uji-mutasi-0014\.py", "", t, count=1))
        mutasi("langkah bukti mutasi 0016 dihapus",
               lambda t: re.sub(r"\n\s*- name: Bukti mutasi pagar migrasi 0016[\s\S]*?run: python3 alat/uji-mutasi-0016\.py", "", t, count=1))
        # I F-07 (putaran18w): batas Edge Function kini diuji dengan MENJALANKAN berkas aslinya.
        # Kalau langkah itu lenyap dari CI, handler Edge kembali hanya dijaga pemeriksa teks —
        # wajib DITOLAK (kelas cacat yang sama dengan H F-02: langkah hilang senyap).
        mutasi("langkah uji batas Edge Function verifikasi_pin dihapus",
               lambda t: re.sub(r"\n\s*- name: Uji batas Edge Function[\s\S]*?run: node alat/uji-edge-pin\.mjs", "", t, count=1))
        mutasi("npm audit diberi `|| true`", lambda t: t.replace("run: npm audit --audit-level=low", "run: npm audit --audit-level=low || true"))
        mutasi("ambang audit diturunkan", lambda t: t.replace("npm audit --audit-level=low", "npm audit --audit-level=critical"))
        mutasi("langkah pemeriksa pohon bersih dihapus", lambda t: t.replace("          python3 alat/periksa-bersih.py\n", "", 1))
        mutasi("langkah pemeriksa antarmuka dihapus", lambda t: t.replace("          python3 aplikasi/alat/periksa-antarmuka.py\n", "", 1))
        mutasi("langkah uji-diri kontras dihapus", lambda t: t.replace("          python3 aplikasi/alat/uji-kontras.py --uji-diri\n", "", 1))
        # I F-21 (putaran18x): versi Node yang diiklankan dulu lebih rendah dari kebutuhan pustaka
        # terkunci. Kalau pemeriksanya lenyap dari CI, iklan versi bisa berbohong lagi tanpa jejak.
        mutasi("langkah bukti mutasi kode aplikasi dihapus (I F-19/F F-14/I F-06)",
               lambda t: t.replace("        run: node aplikasi/alat/uji-mutasi-app.mjs\n", "", 1))
        mutasi("langkah uji-diri pemeriksa uji aplikasi dihapus (I F-19)",
               lambda t: t.replace("          python3 aplikasi/alat/periksa-uji.py --uji-diri\n", "", 1))
        mutasi("langkah pemeriksa versi Node dihapus (I F-21)",
               lambda t: t.replace("          python3 aplikasi/alat/periksa-node.py\n", "", 1))

        # PR-10 (review putaran verifikasi 2026-09-19, K-3): dua cara paling senyap melemahkan CI —
        # menghapus langkah yang TIDAK terdaftar di daftar gerbang, dan mematikan langkah dengan
        # syarat `if: false` (perintahnya tetap ada, jadi pemeriksa lama buta). Keduanya WAJIB ditolak.
        mutasi("langkah pemeriksa rahasia dihapus (PR-10 bukti G1)",
               lambda t: t.replace("          python3 alat/periksa-rahasia.py\n", "", 1))
        mutasi("langkah uji SQL dimatikan dengan `if: false` (PR-10 bukti G2)",
               lambda t: t.replace("      - name: Uji SQL penuh", "      - name: Uji SQL penuh\n        if: false", 1))
        mutasi("perintah tak dikenal disisipkan ke daftar langkah",
               lambda t: t.replace("          python3 _sistem/validate_system.py\n",
                                   "          python3 _sistem/validate_system.py\n          python3 alat/pemeriksa-palsu.py\n", 1))
        mutasi("gerbang ditutup `|| exit 0`",
               lambda t: t.replace("          python3 alat/periksa-bersih.py\n",
                                   "          python3 alat/periksa-bersih.py || exit 0\n", 1))
        mutasi("ambang kerentanan dependency dinonaktifkan (`--audit-level=critical`)",
               lambda t: t.replace("npm audit --audit-level=low", "npm audit --audit-level=critical", 1))
        mutasi("langkah diberi continue-on-error", lambda t: t.replace("    runs-on: ubuntu-latest", "    runs-on: ubuntu-latest\n    continue-on-error: true", 1))
        # Sejak 2026-09-19, dua pemeriksa ini dijalankan SUNGGUHAN (dulu hanya uji-dirinya,
        # sehingga aturan F-11/F-12/F-14 tidak pernah ditegakkan di CI). Buktikan gerbangnya.
        mutasi("pemeriksa paket (invarian commit) dihapus",
               lambda t: t.replace("          python3 alat/periksa-paket.py\n", "", 1))
        mutasi("pemeriksa angka bukti & jumlah tugas dihapus",
               lambda t: t.replace("          python3 alat/periksa-angka-bukti.py\n", "", 1))
        # Sejak 2026-09-19 skema hidup di proyek nyata: berkas migrasi lama dibekukan, dan penjaganya
        # WAJIB tidak bisa dihapus dari CI (kalau dihapus, repo bisa menyimpang dari database nyata).
        mutasi("pemeriksa migrasi beku dihapus dari CI",
               lambda t: t.replace("          python3 alat/periksa-migrasi-beku.py\n", "", 1))
        mutasi("riwayat penuh (fetch-depth 0) diturunkan ke 1",
               lambda t: t.replace("          fetch-depth: 0", "          fetch-depth: 1", 1))
        # Sejak 2026-09-20 (AL-15): pemicu satu kalimat → paket + prompt pendek. Uji-dirinya
        # menjaga peta frasa & kependekan prompt — tidak boleh bisa dihapus diam-diam dari CI.
        mutasi("uji-diri penyiap pemeriksaan dihapus dari CI",
               lambda t: t.replace("          python3 alat/siapkan-pemeriksaan.py --uji-diri\n", "", 1))

        # Alur penyebaran milik pemilik (sejak 2026-09-19) juga WAJIB tidak bisa dilemahkan senyap.
        def mutasi_berkas(relatif: str, nama: str, ubah) -> None:
            berkas = tmp_p / relatif
            asli = berkas.read_text(encoding="utf-8")
            berkas.write_text(ubah(asli), encoding="utf-8")
            kode_m, keluar_m = _jalankan(skrip_uji, tmp_p)
            kasus.append((f"mutasi: {nama} → ditolak", kode_m != 0))
            if kode_m == 0:
                print(f"  ! {nama} DILOLOSKAN\n{keluar_m[:600]}")
            berkas.write_text(asli, encoding="utf-8")

        mutasi_berkas(".github/workflows/sebar-skema.yml", "alur sebar skema diberi continue-on-error",
                      lambda s: s.replace("    runs-on: ubuntu-latest", "    runs-on: ubuntu-latest\n    continue-on-error: true", 1))
        mutasi_berkas(".github/workflows/sebar-skema.yml", "pratinjau dry-run dihapus dari alur sebar skema",
                      lambda s: s.replace("npx --yes supabase@2.117.0 --yes db push --dry-run --password \"$SUPABASE_DB_PASSWORD\"\n", "", 1))
        mutasi_berkas(".github/workflows/sebar-skema.yml", "perintah sebar migrasi ditelan (|| true)",
                      lambda s: s.replace("--yes db push --password", "--yes db push --password || true", 1))
        mutasi_berkas(".github/workflows/sebar-skema.yml", "penyaring berkas penanda sebar skema dihapus",
                      lambda s: s.replace("      - 'supabase/SEBAR-SKEMA'\n", "", 1))
        mutasi_berkas(".github/workflows/sebar-halaman.yml", "alur sebar halaman diberi if: selalu",
                      lambda s: s.replace("      - name: Periksa penanda & kunci, lalu pasang pustaka dan unggah\n",
                                          "      - name: Periksa penanda & kunci, lalu pasang pustaka dan unggah\n        if: always()\n", 1))
        # Dua lubang baru (2026-09-19): (a) pemeriksaan penanda dihapus → alur bisa menyentuh proyek
        # walau penanda sudah dihapus; (b) urutan ditukar → penyebaran berjalan TANPA pratinjau.
        mutasi_berkas(".github/workflows/sebar-skema.yml", "pemeriksaan berkas penanda sebar skema dihapus",
                      lambda s: s.replace("          test -f supabase/SEBAR-SKEMA", "          true supabase/SEBAR-SKEMA", 1))
        mutasi_berkas(".github/workflows/sebar-skema.yml", "pratinjau dipindah ke BELAKANG penyebaran (urutan ditukar)",
                      lambda s: s.replace(
                          "          npx --yes supabase@2.117.0 --yes db push --dry-run --password \"$SUPABASE_DB_PASSWORD\"\n"
                          "          npx --yes supabase@2.117.0 --yes db push --password \"$SUPABASE_DB_PASSWORD\"\n",
                          "          npx --yes supabase@2.117.0 --yes db push --password \"$SUPABASE_DB_PASSWORD\"\n"
                          "          npx --yes supabase@2.117.0 --yes db push --dry-run --password \"$SUPABASE_DB_PASSWORD\"\n",
                          1))
        mutasi_berkas(".github/workflows/sebar-halaman.yml", "langkah catat alamat publik dihapus",
                      lambda s: s.replace("          node aplikasi/alat/catat-alamat.mjs\n", "", 1))
        mutasi_berkas(".github/workflows/sebar-halaman.yml", "pemeriksaan berkas penanda sebar halaman dihapus",
                      lambda s: s.replace("          test -f aplikasi/SEBAR-HALAMAN", "          true aplikasi/SEBAR-HALAMAN", 1))
        mutasi_berkas(".github/workflows/sebar-halaman.yml", "perintah rilis diganti sekadar build",
                      lambda s: s.replace("npm run --prefix aplikasi deploy", "npm run --prefix aplikasi build", 1))

    print("\nUJI-DIRI PEMERIKSA GERBANG CI")
    for nama, lulus in kasus:
        print(f"  {'OK ' if lulus else 'X  '} {nama}")
    gagal = [n for n, l in kasus if not l]
    if gagal:
        print(f"\nHASIL: GAGAL — {len(gagal)} kasus uji-diri tidak sesuai harapan (pemeriksa mungkin tumpul)")
        return 1
    print("\nHASIL: LOLOS — pemeriksa terbukti bisa MENOLAK yang rusak dan MENERIMA yang utuh.")
    return 0


def main() -> int:
    if "--uji-diri" in sys.argv:
        return uji_diri()

    kode, pesan = periksa(AKAR)
    jumlah_gerbang = len(GERBANG_WAJIB)
    if kode != 0:
        print(f"PERIKSA GERBANG CI — GAGAL ({len(pesan)} temuan)")
        for p in pesan:
            print(f"  [X] {p}")
        print("\nHASIL: GAGAL — gerbang CI hilang/dilemahkan.")
        return 1
    print(
        f"PERIKSA GERBANG CI — {jumlah_gerbang} gerbang wajib ada, tanpa pelemahan, dan suite SQL dijalankan penuh."
    )
    print(
        "  · alur di luar ci.yml ikut diawasi: "
        + ", ".join(f"{n} ({len(ALUR_LAIN[n]['perintah'])} perintah)" for n in ALUR_WAJIB_ADA)
    )
    print("\nHASIL: LOLOS — gerbang CI utuh (bukti bisa MENOLAK: jalankan dengan --uji-diri).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
