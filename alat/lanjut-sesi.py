#!/usr/bin/env python3
"""lanjut-sesi.py — MENYIAPKAN & MEMERIKSA "lanjut di sesi baru" tanpa kehilangan konteks.

Masalah yang diselesaikan (permintaan Lee 2026-09-18: *"aku mau lanjut di sesi baru…
pastikan mekanismenya ada dan sempurna"*):

* Sesi baru di platform ini **selalu dimulai dari basis `main`**, sedangkan pekerjaan
  hidup di cabang sesi (`arena/…`). Sesi baru yang tidak diberi tahu akan melihat repo
  yang **123 commit tertinggal** dan bisa mengulang pekerjaan yang sudah selesai.
* Keadaan kerja tersimpan di banyak berkas (`PROJECT_STATE.md`, `STATUS.md`,
  `_log-sesi/`, `docs/TERTANGGUH.md`, laporan uji). Tanpa satu berkas penunjuk, agent
  baru harus menebak; tanpa pemeriksa, berkas penunjuk itu bisa **basi diam-diam**
  (inilah kelas cacat yang sama dengan temuan audit F-11/F-12/F-14).

Berkas yang dihasilkan/dijaga:

1. `docs/ops/SIAP-LANJUT.md` — handoff untuk **agent** baru: cabang, commit, keadaan CI,
   butir tertangguh, dan rencana berikutnya (bagian rencana DIPERTAHANKAN apa adanya saat
   disegarkan, supaya tulisan agent tidak hilang).
2. `PROMPT_SESI_BARU.md` — untuk **Lee**: berkas **STATIS** (tidak berubah dari batch ke
   batch) yang disalin seluruhnya ke chat baru. Satu-satunya bagian yang berubah adalah baris
   pertama `SESI YANG AKU LANJUT` — diisi **Lee** sendiri, karena pilihan sesi adalah hak Lee
   (permintaan Lee 2026-09-18); mesin tidak menebak. Isinya: baris pilihan itu + Prompt
   Pembuka Universal apa adanya dari sumber kanonik + arahan lanjut yang generik (cara
   menyusul cabang pilihan, cara melihat daftar sesi tanpa alat, apa yang wajib dibaca).
3. `docs/ops/SESI_DITINGGALKAN.md` — catatan sesi yang **sengaja** ditinggalkan Lee, supaya
   tidak disarankan/dipakai lagi tanpa perintahnya.
4. `docs/ops/SIAP-TEMPEL-SESI-BARU.md` — **pensiun** (berkas penunjuk ke berkas nomor 2).

Cara pakai:
    python3 alat/lanjut-sesi.py                 # periksa kesiapan lanjut (lokal: penuh)
    python3 alat/lanjut-sesi.py --siapkan       # segarkan handoff + pastikan berkas prompt sesi baru
    python3 alat/lanjut-sesi.py --di-ci         # di CI: isi saja (riwayat Git dangkal)
    python3 alat/lanjut-sesi.py --uji-diri      # buktikan pemeriksa bisa MENOLAK
    python3 alat/lanjut-sesi.py --daftar-sesi   # Lee memilih sesi mana yang dilanjutkan
    python3 alat/lanjut-sesi.py --siapkan --lanjut-dari arena/<cabang>   # lanjut dari sesi pilihan Lee

Aturan kesegaran (ditegakkan di komputer, bukan di CI): berkas handoff wajib diperbarui
di **commit terakhir** setiap batch, dan `Commit keadaan kerja` di dalamnya wajib sama
dengan induk commit itu. Jadi handoff tidak bisa ketinggalan satu batch pun.
"""
from __future__ import annotations

import datetime as _dt
import pathlib
import re
import subprocess
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent
NAMA_SIAP = "docs/ops/SIAP-LANJUT.md"
NAMA_PROMPT_SESI = "PROMPT_SESI_BARU.md"
NAMA_TEMPEL_LAMA = "docs/ops/SIAP-TEMPEL-SESI-BARU.md"
NAMA_DITINGGALKAN = "docs/ops/SESI_DITINGGALKAN.md"
SIAP = AKAR / NAMA_SIAP
PROMPT_SESI = AKAR / NAMA_PROMPT_SESI
TEMPEL_LAMA = AKAR / NAMA_TEMPEL_LAMA
DITINGGALKAN = AKAR / NAMA_DITINGGALKAN
PROMPT_KANONIK = AKAR / "PROMPT_ENTRI_UNIVERSAL.md"
TERTANGGUH = AKAR / "docs" / "TERTANGGUH.md"
PROJECT_STATE = AKAR / "PROJECT_STATE.md"

# Penanda di dalam `PROMPT_SESI_BARU.md` (berkas statis yang disalin Lee ke chat baru).
BATAS_KANONIK_AWAL = "===== PROMPT PEMBUKA UNIVERSAL (identik dengan PROMPT_ENTRI_UNIVERSAL.md) ====="
BATAS_KANONIK_AKHIR = "===== AKHIR PROMPT PEMBUKA UNIVERSAL ====="
BARIS_PILIHAN = "SESI YANG AKU LANJUT:"
TOKEN_CABANG = "<CABANG-YANG-DIPILIH>"

# Kerangka berkas `PROMPT_SESI_BARU.md` — dipakai HANYA bila berkas itu belum ada sama sekali.
# Berkas aslinya STATIS: isinya tidak berubah dari batch ke batch. Yang ikut berubah hanyalah
# blok Prompt Pembuka Universal bila sumber kanoniknya berubah, dan itu disegarkan otomatis
# oleh `pastikan_prompt_sesi_baru()` — sisa berkas tidak pernah disentuh mesin.
KERANGKA_PROMPT_SESI_BARU = """SESI YANG AKU LANJUT: .......... (isi nama cabang sesi di sini; contoh bentuknya: arena/01a0a8a2-resto-barokah)

> BERKAS INI STATIS (tidak berubah tiap batch) — simpan sekali, pakai terus.
> Bagian yang kamu isi HANYA baris pertama di atas. Sisa berkas ini jangan diubah.
> Penjelasan untuk manusia: `PANDUAN_PENGGUNA.md` bagian AL-13 dan `docs/PANDUAN_PEMILIK.md` pertanyaan 2b.

LANGKAH PERTAMA (WAJIB, sebelum menjalankan apa pun di bawah): kamu kemungkinan besar masih berdiri di basis `main` yang tertinggal ratusan commit. Susul dulu cabang yang tertulis di baris pertama:

```
git fetch origin <CABANG-YANG-DIPILIH>:refs/remotes/origin/kerja-terakhir
git merge --ff-only origin/kerja-terakhir
python3 alat/mulai-sesi.py
```

- Kalau baris `SESI YANG AKU LANJUT` KOSONG: JANGAN menebak. Tampilkan daftar sesi yang bisa dilanjutkan (cara tanpa alat ada di bagian LANJUT SESI di bawah), laporkan ke Lee, lalu tunggu Lee memilih.
- Kalau baris itu TERISI tetapi cabangnya TIDAK ADA di GitHub (`git ls-remote origin refs/heads/<CABANG-YANG-DIPILIH>` kosong): JANGAN menebak juga — laporkan dan tampilkan daftar sesi.
- Kalau repo ini belum punya `PROJECT_STATE.md` (proyek baru): abaikan baris di atas dan ikuti saja Prompt Pembuka Universal di bawah.

===== PROMPT PEMBUKA UNIVERSAL (identik dengan PROMPT_ENTRI_UNIVERSAL.md) =====

@@KANONIK@@

===== AKHIR PROMPT PEMBUKA UNIVERSAL =====

===== LANJUT SESI (bagian tetap, tidak berubah tiap batch) =====

Yang TIDAK ditulis di berkas ini — dan memang tidak boleh: keadaan proyek (commit terakhir, CI, butir tertangguh, rencana). Keadaan yang benar SELALU dibaca dari isi repo setelah kamu menyusul cabang di atas: `docs/ops/SIAP-LANJUT.md` (penunjuk keadaan buatan mesin), `PROJECT_STATE.md`, `STATUS.md`, `_log-sesi/LOG_SESI_*.md`, `docs/TERTANGGUH.md`, dan `docs/teknis/REKAM_PESAN_PEMILIK.md`.

Kalau `alat/lanjut-sesi.py` BELUM ADA (kamu masih di basis `main`/cabang lama), pakai cara tanpa alat ini untuk melihat pilihan sesi:

```
git fetch origin '+refs/heads/arena/*:refs/remotes/origin/arena/*'
git for-each-ref --sort=-committerdate --format='%(refname:short)  %(committerdate:short)  %(subject)' refs/remotes/origin/arena/
```

lalu susul cabang yang Lee maksud dengan perintah `git fetch origin <CABANG-YANG-DIPILIH>:refs/remotes/origin/kerja-terakhir` seperti di atas.

Setelah mendarat di ujung cabang yang benar:
- Jalankan `python3 alat/lanjut-sesi.py` → harus LOLOS (handoff segar & ter-push). Kalau menolak, perbaiki dulu; jangan bekerja di atas handoff basi.
- Jalankan `python3 alat/mulai-sesi.py` → cetak KARTU SESI; laporkan ke Lee SEBELUM bekerja.
- `python3 alat/lanjut-sesi.py --daftar-sesi` bila Lee ingin melihat atau mengganti sesi. Cabang yang **belum pernah di-push** ke GitHub tidak bisa dilanjutkan (pekerjaannya belum tersimpan). Cabang sesi **lama** biasanya membawa alat versi lebih tua — laporkan apa adanya, jangan mengarang mekanisme baru.
- Sesi yang **sengaja ditinggalkan** Lee ada di `docs/ops/SESI_DITINGGALKAN.md`. Jangan menyarankan atau memakai sesi di daftar itu tanpa perintah Lee.

Aturan tetap:
- **Base branch tidak perlu diatur** — Lee tidak mengaturnya; cabang kerja dibuat otomatis oleh platform dan tidak bisa diganti.
- **PR:** PR #1 menunjuk cabang sesi lama, jadi pekerjaanmu TIDAK otomatis masuk PR #1. Bila Lee ingin meninjau lewat PR, buka PR BARU dari cabang sesimu (base `main`) dan laporkan tautannya. **JANGAN MERGE** apa pun tanpa keputusan Lee.
- Bila `docs/ops/SIAP-LANJUT.md` menulis "Cabang yang dilanjutkan" BERBEDA dari baris `SESI YANG AKU LANJUT` di atas: yang menang adalah baris di atas (pilihan terbaru Lee). Laporkan bedanya, lalu rapikan catatannya: `python3 alat/lanjut-sesi.py --siapkan --lanjut-dari <CABANG-YANG-DIPILIH>`.
"""

# Cadangan bila cabang aktif tak terbaca dari Git. Cabang yang benar-benar dipakai ditentukan
# oleh `pilih_target()`: bisa dari `--lanjut-dari`, bisa dari berkas handoff sebelumnya, bisa
# bawaan "sesi terakhir yang menulis handoff ini". TIDAK ditebak dari ingatan.
# Pemakaian `CABANG_KERJA` sekarang tinggal: cadangan saat nama cabang tak terbaca, tidak lebih.
CABANG_KERJA = "arena/01a0a8a2-resto-barokah"


def jalankan(perintah: list[str], cwd: pathlib.Path | None = None) -> tuple[int, str]:
    hasil = subprocess.run(perintah, cwd=cwd or AKAR, capture_output=True, text=True)
    return hasil.returncode, (hasil.stdout + hasil.stderr).strip()


def baca(p: pathlib.Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace") if p.is_file() else ""


def blok_prompt_kanonik() -> str:
    """Blok kode pertama dari sumber kanonik `PROMPT_ENTRI_UNIVERSAL.md`."""
    m = re.search(r"^```\n(.*?)^```$", baca(PROMPT_KANONIK), re.MULTILINE | re.DOTALL)
    return m.group(1).strip() if m else ""


def blok_kanonik_dalam_prompt(teks: str) -> str | None:
    """Isi blok Prompt Pembuka Universal di dalam berkas prompt sesi baru (di antara penanda)."""
    if teks.count(BATAS_KANONIK_AWAL) != 1 or teks.count(BATAS_KANONIK_AKHIR) != 1:
        return None
    return teks.split(BATAS_KANONIK_AWAL, 1)[1].split(BATAS_KANONIK_AKHIR, 1)[0].strip()


def sesi_ditinggalkan(akar: pathlib.Path | None = None) -> dict[str, str]:
    """Sesi yang SENGAJA ditinggalkan Lee (catatan manual di `docs/ops/SESI_DITINGGALKAN.md`).

    Dipakai untuk tiga hal: memberi tanda di `--daftar-sesi`, menolak `--siapkan` yang
    menargetkan sesi itu, dan memastikan handoff tidak menunjuk ke sana tanpa perintah Lee.
    """
    hasil: dict[str, str] = {}
    for baris in baca((akar or AKAR) / NAMA_DITINGGALKAN).splitlines():
        m = re.match(r"^\|\s*`?([\w./-]+)`?\s*\|\s*([\d-]+)\s*\|\s*(.+?)\s*\|\s*$", baris)
        if not m or m.group(1) in ("Cabang", "---"):
            continue
        hasil[m.group(1)] = f"{m.group(3)} (dicatat {m.group(2)})"
    return hasil


def pastikan_prompt_sesi_baru(akar: pathlib.Path | None = None) -> list[str]:
    """Buat berkas prompt sesi baru bila hilang; segarkan blok kanoniknya bila sumber kanonik berubah.

    Sengaja TIDAK menulis apa pun bila penandanya rusak: berkas statis yang mungkin sudah
    disunting Lee tidak boleh ditimpa mesin — kalau ragu, laporkan, jangan menebak.
    """
    akar = akar or AKAR
    berkas = akar / NAMA_PROMPT_SESI
    kanonik = blok_prompt_kanonik()
    if not kanonik:
        return ["PROMPT_ENTRI_UNIVERSAL.md tidak terbaca — blok Prompt Pembuka kanonik tidak bisa diambil"]
    teks = baca(berkas)
    if not teks:
        berkas.write_text(KERANGKA_PROMPT_SESI_BARU.replace("@@KANONIK@@", kanonik), encoding="utf-8")
        return [f"{NAMA_PROMPT_SESI} DIBUAT (berkas statis untuk Lee; baris '{BARIS_PILIHAN}' diisi Lee)"]
    lama = blok_kanonik_dalam_prompt(teks)
    if lama is None:
        return [f"{NAMA_PROMPT_SESI} ada, tetapi penanda blok Prompt Pembuka tidak lengkap — TIDAK "
                "ditulis apa pun (mesin tidak menimpa berkas yang sudah disunting; perbaiki manual)"]
    if lama != kanonik:
        baru = (teks.split(BATAS_KANONIK_AWAL, 1)[0] + BATAS_KANONIK_AWAL + "\n\n" + kanonik + "\n\n"
                + BATAS_KANONIK_AKHIR + teks.split(BATAS_KANONIK_AKHIR, 1)[1])
        berkas.write_text(baru, encoding="utf-8")
        return [f"{NAMA_PROMPT_SESI}: blok Prompt Pembuka disegarkan dari sumber kanonik "
                "(sisa berkas TIDAK diubah)"]
    return []


def butir_tertangguh() -> list[str]:
    teks = baca(TERTANGGUH)
    return re.findall(r"^\|\s*(T-\d{3})\s*\|.*\|\s*\[ \]\s*terbuka\s*\|\s*$", teks, re.M)


def bidang(teks: str, nama: str) -> str | None:
    m = re.search(rf"^- \*\*{re.escape(nama)}:\*\*\s*(.+)$", teks, re.M)
    return m.group(1).strip().strip("`") if m else None


def ada_di_remote(cabang: str, akar: pathlib.Path) -> bool:
    """Apakah cabang ini benar-benar ada di GitHub? (ditanya langsung, bukan dari ingatan)"""
    kode, keluaran = jalankan(["git", "ls-remote", "origin", f"refs/heads/{cabang}"], cwd=akar)
    return kode == 0 and bool(keluaran.strip())


def daftar_cabang_sesi(akar: pathlib.Path) -> list[tuple[str, str, str, str, bool, bool]]:
    """Semua cabang sesi di GitHub: (cabang, tanggal, judul, sha, punya_alat, punya_prompt_statis).

    Dipakai `--daftar-sesi` supaya Lee bisa MEMILIH sendiri sesi mana yang dilanjutkan.
    Cabang yang belum pernah di-push tidak muncul di sini — pekerjaannya memang belum
    tersimpan di GitHub, jadi tidak ada yang bisa disusul.
    """
    jalankan(["git", "fetch", "--quiet", "origin", "+refs/heads/arena/*:refs/remotes/origin/arena/*"],
             cwd=akar)
    kode, keluaran = jalankan(["git", "for-each-ref", "--sort=-committerdate",
                               "--format=%(refname:short)\t%(committerdate:short)\t%(subject)\t%(objectname)",
                               "refs/remotes/origin/arena/"], cwd=akar)
    if kode != 0:
        return []
    baris = []
    for isi in keluaran.splitlines():
        bagian = isi.split("\t")
        if len(bagian) != 4:
            continue
        lengkap, tanggal, judul, sha = bagian
        cabang = lengkap[len("origin/"):] if lengkap.startswith("origin/") else lengkap
        punya_alat = 0 == jalankan(["git", "cat-file", "-e", f"{sha}:alat/lanjut-sesi.py"], cwd=akar)[0]
        punya_prompt = 0 == jalankan(["git", "cat-file", "-e", f"{sha}:{NAMA_PROMPT_SESI}"], cwd=akar)[0]
        baris.append((cabang, tanggal, judul[:72], sha, punya_alat, punya_prompt))
    return baris


def pilih_target(cabang_sekarang: str, sipl_lama: str) -> tuple[str, str]:
    """Tentukan cabang yang akan disusul sesi berikutnya + alasan yang bisa dibaca Lee.

    Urutan: (1) `--lanjut-dari <cabang>` — pilihan Lee; (2) cabang yang sudah tertulis di
    handoff sebelumnya (supaya pilihan Lee bertahan walau handoff disegarkan berkali-kali);
    (3) bawaan: cabang sesi ini (perilaku lama).
    """
    for i, argumen in enumerate(sys.argv):
        if argumen == "--lanjut-dari" and i + 1 < len(sys.argv):
            return sys.argv[i + 1].strip(), "pilihan Lee (`--lanjut-dari`)"
    dari_berkas = bidang(sipl_lama, "Cabang yang dilanjutkan")
    if dari_berkas:
        return dari_berkas, "pilihan Lee yang tersimpan di handoff sebelumnya"
    return cabang_sekarang, "bawaan: sesi yang menulis handoff ini"


# --------------------------------------------------------------------------- periksa
def catatan_ci(sipl_teks: str) -> str:
    """Peringatan bila CI terakhir BUKAN success.

    Sengaja PERINGATAN, bukan penolakan: commit yang memperbaiki CI merah pasti memuat berkas
    handoff yang menyebut CI merah itu sendiri — kalau ini dijadikan penolakan, mekanismenya
    justru macet dan tidak bisa keluar dari keadaan merah. Yang penting: sesi baru TAHU.
    """
    nilai = (bidang(sipl_teks, "CI terakhir") or "").strip()
    if nilai.lower().startswith("success"):
        return ""
    return (f"CI terakhir BUKAN success ({nilai or 'tidak terbaca'}) — sesi baru WAJIB memperiksa "
            "dan memperbaiki CI lebih dulu sebelum memulai pekerjaan baru.")

def periksa(akar: pathlib.Path | None = None, sipl_teks: str | None = None,
            prompt_teks: str | None = None, penuh: bool = True) -> list[str]:
    """Kembalikan daftar masalah. Kosong = siap lanjut.

    `penuh=False` (dipakai `--di-ci`) hanya memeriksa ISI berkas; pemeriksaan kesegaran
    riwayat Git dilewati karena checkout CI dangkal/menggabung.
    """
    akar = akar or AKAR
    masalah: list[str] = []
    sipl = sipl_teks if sipl_teks is not None else baca(akar / NAMA_SIAP)
    prompt = prompt_teks if prompt_teks is not None else baca(akar / NAMA_PROMPT_SESI)
    if not sipl:
        return ["docs/ops/SIAP-LANJUT.md BELUM ADA — sesi baru tidak punya penunjuk keadaan. "
                "Jalankan: python3 alat/lanjut-sesi.py --siapkan"]
    if not prompt:
        masalah.append(f"{NAMA_PROMPT_SESI} BELUM ADA — Lee tidak punya berkas (statis) untuk disalin ke "
                       "chat baru. Jalankan: python3 alat/lanjut-sesi.py --siapkan")

    # --- isi berkas handoff (selalu diperiksa, juga di CI) ---
    wajib = {
        "cabang dilanjutkan": r"^- \*\*Cabang yang dilanjutkan:\*\*\s*`[^`]+`",
        "dasar pilihan cabang": r"^- \*\*Dasar pilihan cabang:\*\*",
        "sesi penulis": r"^- \*\*Ditulis oleh sesi:\*\*\s*`[^`]+`",
        "commit": r"^- \*\*Commit keadaan kerja:\*\*\s*`[0-9a-f]{40}`",
        "ci": r"^- \*\*CI terakhir:\*\*",
        "ditulis": r"^- \*\*Ditulis:\*\*",
        "rencana": r"^## .*Rencana berikutnya",
        "paket peninjau": r"^- \*\*Paket peninjau terbaru:\*\*",
        "ruang kerja baru": r"^- \*\*Ruang kerja baru:\*\*",
        "berkas yang Lee salin": r"^- \*\*Berkas yang Lee salin ke chat baru:\*\*",
        "cabang sesi baru vs PR": r"^## 2c\. Fakta cabang sesi baru",
    }
    for nama, pola in wajib.items():
        jumlah = len(re.findall(pola, sipl, re.M))
        if jumlah == 0:
            masalah.append(f"docs/ops/SIAP-LANJUT.md: bagian '{nama}' hilang — sesi baru akan menebak")
        elif jumlah > 1:
            # Kejadian nyata 2026-09-18: `--siapkan` sempat MENDUPLIKASI blok header, sehingga
            # dua baris "Commit keadaan kerja" saling bertentangan. Berkas dengan bagian kembar
            # = sesi baru bisa membaca keadaan yang salah; pemeriksa wajib menolaknya.
            masalah.append(f"docs/ops/SIAP-LANJUT.md: bagian '{nama}' muncul {jumlah}x (harus 1) — "
                           "berkas handoff rusak/berulang, jalankan --siapkan lagi")
    # --- cabang yang dilanjutkan = pilihan Lee (bukan tebakan mesin; sesi yang sengaja
    # ditinggalkan wajib ditolak walau mesinnya bisa) ---
    target = bidang(sipl, "Cabang yang dilanjutkan")
    if target and not re.match(r"^(arena|main|master)/?[\w./-]*$", target) and not re.match(r"^[\w./-]+$", target):
        masalah.append(f"docs/ops/SIAP-LANJUT.md: nama cabang '{target}' tidak masuk akal")
    ditinggalkan = sesi_ditinggalkan(akar)
    dipaksa = "DIPAKSA" in (bidang(sipl, "Dasar pilihan cabang") or "").upper()
    if target and target in ditinggalkan and not dipaksa:
        masalah.append(f"handoff menunjuk sesi yang SENGAJA DITINGGALKAN Lee: '{target}' "
                       f"({ditinggalkan[target]}) — kalau memang mau, jalankan `--siapkan --paksa` "
                       "(dan catatannya tetap tersimpan)")
    if re.search(r"CABANG-KERJA-BELUM-DIISI|TODO", sipl):
        masalah.append("docs/ops/SIAP-LANJUT.md masih memuat penanda TODO — belum diisi sungguhan")

    # --- berkas prompt sesi baru (STATIS, disalin Lee): bentuk & isinya dijaga ---
    if prompt:
        kanonik = blok_prompt_kanonik()
        if not kanonik:
            masalah.append("PROMPT_ENTRI_UNIVERSAL.md tidak terbaca — blok Prompt Pembuka kanonik tidak "
                           "bisa dipastikan")
        else:
            dalam = blok_kanonik_dalam_prompt(prompt)
            if dalam is None:
                masalah.append(f"{NAMA_PROMPT_SESI}: penanda blok Prompt Pembuka tidak lengkap "
                               f"('{BATAS_KANONIK_AWAL}' + pasangannya, masing-masing tepat 1x)")
            elif dalam != kanonik:
                masalah.append(f"{NAMA_PROMPT_SESI} TIDAK memuat Prompt Pembuka Universal apa adanya — "
                               "sesi baru akan mulai tanpa aturan orientasi "
                               "(jalankan: python3 alat/lanjut-sesi.py --siapkan)")
        if len(re.findall(rf"(?m)^{re.escape(BARIS_PILIHAN)}", prompt)) != 1:
            masalah.append(f"{NAMA_PROMPT_SESI}: baris pilihan Lee '{BARIS_PILIHAN}' harus ada tepat 1x di "
                           "paling atas — tanpa itu Lee tidak bisa menentukan sesi yang dilanjutkan")
        if "BERKAS INI STATIS" not in prompt:
            masalah.append(f"{NAMA_PROMPT_SESI} tidak menyatakan dirinya STATIS — Lee bisa mengira harus "
                           "meminta berkas baru setiap batch (padahal tidak perlu)")
        # Jendela sengaja lebar (pelajaran nyata): frasa panjang sering dibungkus baris,
        # sehingga penjaga dengan jendela sempit jadi BUTA terhadap berkas yang sudah benar.
        for nama_fakta, pola_fakta, pesan in (
            ("resep menyusul cabang pilihan",
             rf"git fetch origin\s+{re.escape(TOKEN_CABANG)}:refs/remotes/origin/kerja-terakhir",
             "tanpa resep ini sesi baru bekerja dari basis main yang tertinggal ratusan commit"),
            ("daftar sesi (--daftar-sesi)", r"--daftar-sesi",
             "Lee harus bisa melihat sesi yang tersedia, juga saat baris pilihannya kosong"),
            ("cara tanpa alat (for-each-ref)", r"refs/heads/arena/\*",
             "di basis main `alat/` belum ada — tanpa cara ini sesi baru buntu sebelum bisa memilih"),
            ("larangan menebak saat baris kosong",
             r"(?is)KOSONG.{0,200}?JANGAN menebak|JANGAN menebak.{0,200}?daftar sesi",
             "pilihan sesi adalah hak Lee; mesin tidak boleh menebak"),
            ("base branch tidak perlu diatur", r"(?i)base branch",
             "Lee bisa mengira harus mengatur base branch — padahal tidak"),
            ("PR #1 tidak otomatis", r"PR #1 menunjuk\s+cabang sesi lama",
             "sesi baru bisa mengira pekerjaannya otomatis masuk PR #1"),
            ("catatan sesi ditinggalkan", r"SESI_DITINGGALKAN",
             "sesi yang sengaja ditinggalkan Lee harus bisa dikenali sesi baru"),
        ):
            if not re.search(pola_fakta, prompt):
                masalah.append(f"{NAMA_PROMPT_SESI} tidak menjelaskan '{nama_fakta}' — {pesan}")
        if "JANGAN MERGE" not in prompt.upper():
            masalah.append(f"{NAMA_PROMPT_SESI} tidak memuat larangan merge — keputusan merge milik Lee")
        if "ATURAN BAHASA" not in prompt:
            masalah.append(f"{NAMA_PROMPT_SESI} tidak memuat ATURAN BAHASA — sesi baru bisa menjawab Lee "
                           "dengan bahasa yang salah")

    # --- berkas lama yang dipensiunkan tidak boleh menyesatkan (kalau masih ada) ---
    lama = baca(akar / NAMA_TEMPEL_LAMA)
    if lama:
        if NAMA_PROMPT_SESI not in lama:
            masalah.append(f"{NAMA_TEMPEL_LAMA} masih ada tetapi tidak menunjuk ke {NAMA_PROMPT_SESI} — "
                           "Lee bisa menyalin berkas lama yang sudah tidak dipakai")
        if "MULAI SALIN DARI SINI" in lama:
            masalah.append(f"{NAMA_TEMPEL_LAMA} masih memuat prompt siap-tempel versi lama — isi sebenarnya "
                           f"sudah pindah ke {NAMA_PROMPT_SESI} (statis)")

    # --- butir tertangguh tidak boleh melewati batas yang disetujui Lee ---
    terbuka = butir_tertangguh()
    if len(terbuka) > 12:
        masalah.append(f"butir tertangguh terbuka {len(terbuka)} (> 12) — wajib berhenti & minta keputusan Lee")

    # --- Project State & STATUS harus punya bentuk yang bisa dibaca sesi baru ---
    ps = baca(akar / "PROJECT_STATE.md")
    if not re.search(r"^STATUS:", ps, re.M):
        masalah.append("PROJECT_STATE.md tidak punya baris STATUS: — bootstrap sesi baru akan menebak")
    st = baca(akar / "STATUS.md")
    if len(re.findall(r"\*\*Pekerjaan belum tersimpan:\*\*\s*Tidak ada\s*$", st, re.M)) != 1:
        masalah.append("STATUS.md tidak memuat tepat satu field 'Pekerjaan belum tersimpan: Tidak ada'")

    if not penuh:
        return masalah

    # --- keadaan CI harus terbaca jelas oleh sesi baru (jangan disembunyikan) ---
    pesan_ci = catatan_ci(sipl)
    if pesan_ci:
        print(f"  [catatan] {pesan_ci}")

    # --- pemeriksaan kesegaran riwayat Git (butuh riwayat penuh) ---
    kode, kotor = jalankan(["git", "status", "--porcelain"], cwd=akar)
    if kode == 0 and kotor:
        masalah.append(f"ruang kerja KOTOR ({len(kotor.splitlines())} berkas belum di-commit) — "
                       "sesi baru akan kehilangan pekerjaan yang belum di-push")
    _, nama_cabang = jalankan(["git", "branch", "--show-current"], cwd=akar)
    nama_cabang = nama_cabang.strip()
    _, sha_head = jalankan(["git", "rev-parse", "HEAD"], cwd=akar)
    sha_head = sha_head.strip()
    # Induk commit dicoba APA ADANYA (klon dangkal bisa membuatnya tidak ada → baru dicatat).
    kode_induk, induk = jalankan(["git", "rev-parse", "HEAD^"], cwd=akar)
    induk = induk.strip() if kode_induk == 0 else ""

    if nama_cabang:
        kode, sisi_luar = jalankan(["git", "rev-parse", f"origin/{nama_cabang}"], cwd=akar)
        if kode != 0:
            print(f"  [catatan] cabang lokal tidak punya origin/{nama_cabang} — uji push dilewati")
        elif sisi_luar.strip() != sha_head:
            # Kejadian nyata 2026-09-18: `git push origin HEAD` berhasil, tetapi ref remote-tracking
            # lokal TIDAK ikut diperbarui di sandbox ini — pemeriksa hampir melaporkan GAGAL palsu.
            # Karena itu: tanya remote langsung (ls-remote) sebelum menuduh pekerjaan belum ter-push.
            kode_ls, ls = jalankan(["git", "ls-remote", "origin", f"refs/heads/{nama_cabang}"], cwd=akar)
            tip_remote = ls.split()[0].strip() if (kode_ls == 0 and ls.split()) else ""
            if tip_remote == sha_head:
                print("  [catatan] ref remote-tracking lokal tertinggal, tetapi remote SUDAH memuat commit "
                      f"terakhir (dipastikan ls-remote) — rapikan: git fetch origin {nama_cabang}:refs/remotes/origin/{nama_cabang}")
            else:
                masalah.append(f"commit lokal ({sha_head[:8]}) belum ter-push ke origin/{nama_cabang} "
                               f"({tip_remote[:8] or sisi_luar.strip()[:8]}) — tanpa push, sesi berikutnya "
                               "tidak bisa melanjutkan")
    else:
        # Detached (mis. pemeriksaan PR): kecocokan cabang tidak bisa diuji, beri catatan.
        print("  [catatan] HEAD detached (salinan pemeriksaan) — uji push dilewati")

    # --- cabang tujuan harus benar-benar ada di GitHub: Lee tidak bisa disuruh pindah ke sesi
    # yang pekerjaannya belum pernah tersimpan. (Dilewati bila repo uji memang tanpa remote.)
    kode_remote, _ = jalankan(["git", "remote", "get-url", "origin"], cwd=akar)
    if target and kode_remote == 0 and not ada_di_remote(target, akar):
        masalah.append(f"cabang tujuan '{target}' TIDAK ADA di GitHub — sesi baru akan gagal menyusul. "
                       "Pilih sesi lain: python3 alat/lanjut-sesi.py --daftar-sesi")

    if induk:
        _, tukar = jalankan(["git", "diff-tree", "--no-commit-id", "--name-only", "-r", sha_head, induk], cwd=akar)
        disentuh = set(tukar.split()) if tukar else set()
        for berkas in ("docs/ops/SIAP-LANJUT.md", "PROJECT_STATE.md", "STATUS.md"):
            if berkas not in disentuh:
                masalah.append(f"commit terakhir TIDAK memperbarui {berkas} — handoff basi satu batch "
                               "(jalankan: python3 alat/lanjut-sesi.py --siapkan, lalu commit)")
        ditulis = bidang(sipl, "Commit keadaan kerja")
        if ditulis and ditulis != induk:
            masalah.append(f"handoff menulis commit keadaan {ditulis[:8]}, padahal induk commit terakhir "
                           f"{induk[:8]} — berkas handoff tidak segar")
    else:
        print("  [catatan] riwayat Git dangkal (klon CI) — kesegaran handoff tidak bisa diuji di sini")
    return masalah


# --------------------------------------------------------------------------- siapkan
def _bagian_rencana(sipl_lama: str) -> str:
    """Ambil bagian 'Rencana berikutnya' dari berkas lama (tulisan agent, jangan dihapus).

    Kejadian nyata 2026-09-18: versi pertama fungsi ini mengembalikan heading + seluruh sisa
    berkas, sehingga `--siapkan` yang dijalankan dua kali MENDUPLIKASI blok header (dua baris
    "Commit keadaan kerja" yang saling bertentangan). Sekarang: hanya ambil BADAN rencananya,
    dan buang sisa blok header yang mungkin ikut terbawa.
    """
    m = re.search(r"^## 3\. Rencana berikutnya[^\n]*\n(.*)\Z", sipl_lama, re.M | re.DOTALL)
    if not m:
        return ("## 3. Rencana berikutnya (isi bagian ini sebelum menutup sesi)\n\n"
                "- (belum diisi: tulis tujuan sesi berikutnya, pilihan Lee, dan aturan tetap)")
    badan = m.group(1)
    # Defensif: potong apa pun yang merupakan blok header hasil generator sebelumnya.
    potong = re.search(r"^## 1\. Keadaan sekarang", badan, re.M)
    if potong:
        badan = badan[: potong.start()]
    badan = badan.strip() or "- (belum diisi)"
    if not badan.lstrip().startswith("##"):
        return "## 3. Rencana berikutnya (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)\n\n" + badan
    return badan


def _kunci_angka(nama: str) -> list:
    """Kunci urut alami: putaran9 < putaran10 (bukan urut huruf yang menyesatkan)."""
    return [int(x) if x.isdigit() else x for x in re.split(r"(\d+)", nama)]


def sasaran_paket(akar: pathlib.Path) -> str:
    """Baris fakta: paket peninjau terbaru menunjuk commit mana (temuan sesi baru 2026-09-18).

    Kejadian nyata: bagian rencana di handoff MENGAKUI paket "sudah disegarkan ke commit keadaan",
    padahal paket menunjuk commit 12 langkah di belakang. Sekarang handoff menulis fakta yang
    dibaca mesin dari berkas paketnya sendiri, jadi klaim basi tidak mungkin ditulis lagi.
    """
    hasil = []
    for label, pola, kunci in (("audit", "docs/uji/paket-audit/AUD-*.md", r"Commit yang diaudit"),
                               ("review", "docs/uji/review-pr/PKT-*.md", r"Commit yang direview")):
        berkas = [b for b in akar.glob(pola) if "SIAP-TEMPEL" not in b.name]
        if not berkas:
            hasil.append(f"{label} (belum ada paket)")
            continue
        berkas.sort(key=lambda b: _kunci_angka(b.name))
        baru = berkas[-1]
        m = re.search(rf"{kunci}:\*\*\s*`([0-9a-f]{{7,40}})`", baca(baru))
        if not m:
            hasil.append(f"{label} `{baru.name}` (commit tidak terbaca)")
            continue
        sha = m.group(1)
        kode, jarak = jalankan(["git", "rev-list", "--count", f"{sha}..HEAD"], cwd=akar)
        jarak_teks = f"{jarak.strip()} commit di bawah HEAD saat ini" if kode == 0 else "jarak tidak terbaca"
        hasil.append(f"{label} `{baru.name}` → `{sha[:8]}` ({jarak_teks})")
    return " · ".join(hasil)


def jarak_ke_main(akar: pathlib.Path) -> str:
    for ref in ("origin/main", "main"):
        kode, n = jalankan(["git", "rev-list", "--count", f"{ref}..HEAD"], cwd=akar)
        if kode == 0 and n.strip().isdigit():
            return f"{n.strip()} commit"
    return "ratusan commit"

def siapkan() -> int:
    kode, sha = jalankan(["git", "rev-parse", "HEAD"])
    if kode != 0:
        print("GAGAL: bukan repositori Git — tidak bisa menulis handoff yang bisa dipercaya.")
        return 1
    sha = sha.strip()
    _, nama_cabang = jalankan(["git", "branch", "--show-current"])
    nama_cabang = nama_cabang.strip() or CABANG_KERJA
    sipl_sebelum = baca(SIAP)
    target, alasan_target = pilih_target(nama_cabang, sipl_sebelum)
    # Validasi pilihan: sesi yang belum pernah di-push tidak bisa disusul (pekerjaannya belum ada di GitHub).
    if not ada_di_remote(target, AKAR):
        if target == nama_cabang:
            print(f"  [catatan] cabang sesi ini ('{target}') belum ada di GitHub — push dulu sebelum "
                  "menyuruh Lee pindah (kalau tidak, sesi baru tidak bisa menyusul).")
        else:
            print(f"GAGAL: cabang pilihan Lee '{target}' TIDAK ADA di GitHub. "
                  "Jalankan `python3 alat/lanjut-sesi.py --daftar-sesi` untuk melihat sesi yang tersedia.")
            return 1
    # Sesi yang SENGAJA ditinggalkan Lee tidak boleh dipilih diam-diam (permintaan Lee 2026-09-18).
    pilihan_ditinggalkan = sesi_ditinggalkan(AKAR)
    if target in pilihan_ditinggalkan:
        if "--paksa" in sys.argv:
            alasan_target += " — DIPAKSA atas perintah Lee (sesi tercatat sengaja ditinggalkan)"
            print(f"  [catatan] sesi '{target}' tercatat SENGAJA DITINGGALKAN ({pilihan_ditinggalkan[target]}) "
                  "tetapi tetap dilanjutkan karena `--paksa` (perintah Lee).")
        else:
            print(f"GAGAL: sesi '{target}' tercatat SENGAJA DITINGGALKAN Lee — {pilihan_ditinggalkan[target]}.")
            print("  Kalau memang ingin dilanjutkan, ulangi dengan `--paksa`; kalau tidak, pilih sesi lain:")
            print("  python3 alat/lanjut-sesi.py --daftar-sesi")
            return 1
    _, pr = jalankan(["gh", "pr", "list", "--state", "open", "--limit", "5",
                      "--json", "number,baseRefName,headRefName",
                      "--jq", '.[] | "PR #\\(.number) (base \\(.baseRefName))"'])
    pr = pr.strip() or "(tidak ada PR terbuka terbaca)"
    _, ci = jalankan(["gh", "run", "list", "--limit", "1", "--json", "conclusion,headSha,databaseId",
                      "--jq", '.[] | "\\(.conclusion) (run \\(.databaseId), commit \\(.headSha[0:8]))"'])
    ci = ci.strip() or "(status CI tidak terbaca dari sini — periksa di GitHub)"
    pesan_ci = "" if ci.lower().startswith("success") else (
        f"- **PERHATIAN:** CI terakhir BUKAN success — perbaiki CI lebih dulu sebelum pekerjaan baru.\n")
    terbuka = butir_tertangguh()
    hari_ini = _dt.date.today().isoformat()
    paket_teks = sasaran_paket(AKAR)
    jarak_main = jarak_ke_main(AKAR)
    sipl_lama = sipl_sebelum
    rencana = _bagian_rencana(sipl_lama)

    isi = f"""# SIAP LANJUT — penunjuk keadaan untuk sesi berikutnya

> Berkas ini DIBUAT MESIN oleh `python3 alat/lanjut-sesi.py --siapkan` dan diperiksa
> `python3 alat/lanjut-sesi.py`. Jangan disunting tangan pada bagian 1–2; bagian 3
> (rencana) justru WAJIB ditulis agent dan akan dipertahankan saat disegarkan.
> Aturan kesegaran: berkas ini wajib ikut ter-commit di commit TERAKHIR setiap batch.

## 1. Keadaan sekarang (dibaca sesi baru lebih dulu)

- **Cabang yang dilanjutkan:** `{target}`
- **Dasar pilihan cabang:** {alasan_target}
- **Ditulis oleh sesi:** `{nama_cabang}`
- **Commit keadaan kerja:** `{sha}`
- **PR:** {pr} — **JANGAN MERGE tanpa keputusan Lee**
- **CI terakhir:** {ci}
{pesan_ci}- **Ditulis:** {hari_ini} (sebelum commit yang memuat berkas ini; jadi commit keadaan di atas
  adalah induk commit ini)
- **Ruang kerja:** bersih & ter-push (dijaga pemeriksa; kalau tidak, berkas ini tidak akan lolos)
- **Berkas yang Lee salin ke chat baru:** `PROMPT_SESI_BARU.md` (STATIS — mesin memeriksanya, bukan
  menulisnya ulang tiap batch; Lee hanya mengisi baris pertama `SESI YANG AKU LANJUT`)

## 2. Keadaan proyek & butir tertangguh

- Posisi proyek: lihat `PROJECT_STATE.md` (STATUS + PUTARAN terakhir) dan `STATUS.md`.
- Bukti terakhir yang hijau: `node alat/uji-sql.mjs` · `python3 alat/uji-mutasi-0012.py` ·
  `python3 alat/uji-mutasi-0014.py` · `bash aplikasi/alat/periksa-semua.sh` · CI (lihat baris CI di atas).
- Butir tertangguh terbuka: **{len(terbuka)}** — {", ".join(terbuka) if terbuka else "(tidak ada)"}
  (rincian: `docs/TERTANGGUH.md`; hanya Lee yang boleh menutupnya)
- **Paket peninjau terbaru:** {paket_teks} — segarkan paket SEBELUM meminta peninjau bekerja bila
  jaraknya jauh: `python3 alat/audit-independen.py --paket AUD-3 --semua` ·
  `python3 alat/review-pr.py --siapkan --pr 1 --nama pr-01-putaranNN`
- **Ruang kerja baru:** `aplikasi/node_modules` & `alat/node_modules` TIDAK ikut tersimpan di snapshot.
  Sebelum pratinjau/uji aplikasi: `bash aplikasi/alat/pratinjau.sh` (±1–2 menit). Uji SQL & pemeriksa
  Python tetap berjalan tanpa pemasangan itu.

## 2b. Kalau kamu sesi baru: cara menyusul pekerjaan ini

Sesi baru di platform ini mulai dari `main`, sedangkan pekerjaan ada di cabang sesi.
Jalankan (tanpa memindahkan cabang sesimu):

```
git fetch origin {target}:refs/remotes/origin/kerja-terakhir
git merge --ff-only origin/kerja-terakhir
python3 alat/mulai-sesi.py      # cetak KARTU SESI, lalu LAPORKAN ke Lee
```

Cabang `{target}` di atas adalah **pilihan Lee** (bukan tebakan mesin). Lee juga bebas memilih sesi
LAIN: saat membuka chat baru, ia menulis pilihannya di baris pertama `PROMPT_SESI_BARU.md` — dan baris
itu yang **MENANG** bila berbeda dengan handoff ini. Laporkan bedanya, lalu rapikan catatan handoff
dengan `python3 alat/lanjut-sesi.py --siapkan --lanjut-dari <cabang>`. Sesi yang belum pernah di-push
tidak bisa dilanjutkan; sesi yang sengaja ditinggalkan ada di `docs/ops/SESI_DITINGGALKAN.md`.

Kalau checkout-mu tidak memuat `supabase/migrations/0014_penutup_celah_putaran13.sql`,
kamu berada di basis yang salah — jangan bekerja dulu, susul cabang di atas.

## 2c. Fakta cabang sesi baru: PR #1 TIDAK otomatis memuat pekerjaanmu

Kamu bekerja di cabang sesi barumu sendiri (dibuat platform; hanya ke cabang itu kamu boleh push).
PR #1 menunjuk cabang sesi SEBELUMNYA, jadi commit barumu tidak muncul di PR itu.
Bila Lee ingin meninjau lewat PR: buka PR BARU dari cabangmu (base `main`) dan laporkan tautannya.
JANGAN merge apa pun tanpa keputusan Lee.

{rencana}
"""
    # Self-check: berkas handoff TIDAK BOLEH berisi bagian kembar (pernah terjadi, lihat _bagian_rencana).
    for penanda in ("## 1. Keadaan sekarang", "- **Commit keadaan kerja:**", "## 2b. Kalau kamu sesi baru",
                    "- **Cabang yang dilanjutkan:**"):
        if isi.count(penanda) != 1:
            print(f"GAGAL: hasil handoff memuat '{penanda}' {isi.count(penanda)}x (harus 1) — "
                  "berkas TIDAK ditulis supaya tidak menyesatkan sesi baru.")
            return 1
    SIAP.parent.mkdir(parents=True, exist_ok=True)
    SIAP.write_text(isi, encoding="utf-8")

    # --- berkas prompt sesi baru: STATIS — diperiksa/dibuat oleh pastikan_prompt_sesi_baru(),
    # TIDAK ditulis ulang setiap batch (kalau ditulis ulang, ia berhenti jadi berkas tetap) ---
    catatan_prompt = pastikan_prompt_sesi_baru(AKAR)
    for catatan in catatan_prompt:
        print(f"  [catatan] {catatan}")

    print(f"SIAP-LANJUT.md ditulis     : docs/ops/SIAP-LANJUT.md  (commit keadaan {sha[:8]})")
    print(f"Prompt sesi baru (statis)  : {NAMA_PROMPT_SESI}  — "
          + ("TIDAK ditulis ulang (tetap); diperiksa OK" if not catatan_prompt
             else "LIHAT CATATAN di atas"))
    print(f"Butir tertangguh terbuka   : {len(terbuka)}" + (f" ({', '.join(terbuka)})" if terbuka else ""))
    print(f"Sesi yang dilanjutkan      : {target}  ({alasan_target})")
    print("\nLangkah berikutnya (WAJIB, supaya handoff tidak basi):")
    print("  1) tulis bagian '## 3. Rencana berikutnya' di docs/ops/SIAP-LANJUT.md")
    print("  2) perbarui PROJECT_STATE.md + STATUS.md (aturan akhir batch)")
    print("  3) git add -A && git commit && git push")
    print("  4) python3 alat/lanjut-sesi.py   → harus LOLOS")
    return 0


def daftar_sesi() -> int:
    """Cetak sesi (cabang) yang bisa dilanjutkan — supaya Lee bisa memilih sendiri."""
    _, cabang_sekarang = jalankan(["git", "branch", "--show-current"])
    cabang_sekarang = cabang_sekarang.strip()
    target = bidang(baca(SIAP), "Cabang yang dilanjutkan") or cabang_sekarang
    baris = daftar_cabang_sesi(AKAR)
    print("DAFTAR SESI YANG BISA DILANJUTKAN (dari GitHub, terbaru dulu)")
    print("-" * 78)
    if not baris:
        print("  (tidak ada cabang sesi di GitHub)")
    ditinggalkan = sesi_ditinggalkan(AKAR)
    for i, (cabang, tanggal, judul, _sha, punya_alat, punya_prompt) in enumerate(baris, 1):
        kode, n = jalankan(["git", "rev-list", "--count", f"origin/main..origin/{cabang}"], cwd=AKAR)
        jarak = f"{n.strip()} commit di atas main" if kode == 0 and n.strip().isdigit() else "jarak tak terbaca"
        tanda = []
        if cabang == cabang_sekarang:
            tanda.append("SESI INI")
        if cabang == target:
            tanda.append("SEDANG DITUJU")
        if cabang in ditinggalkan:
            tanda.append(f"SENGAJA DITINGGALKAN ({ditinggalkan[cabang]})")
        print(f"  {i}. {cabang}")
        print(f"       {tanggal} · {jarak} · alat lanjut-sesi: {'ada' if punya_alat else 'TIDAK ADA'}"
              f" · prompt sesi baru (statis): {'ada' if punya_prompt else 'TIDAK ADA'}"
              + (f" · ← {' · '.join(tanda)}" if tanda else ""))
        print(f"       commit terakhir: {judul}")
    print("-" * 78)
    print("Cara memilih: tulis nama cabang pada baris pertama `PROMPT_SESI_BARU.md` saat membuka chat baru;")
    print("atau (kalau sesi ini tetap dipakai) python3 alat/lanjut-sesi.py --siapkan --lanjut-dari <cabang>")
    print("Catatan: sesi yang belum pernah di-push TIDAK muncul di sini — pekerjaannya belum tersimpan di GitHub.")
    return 0


# --------------------------------------------------------------------------- uji-diri
def _repo_uji(tmp: pathlib.Path, sha_ditulis: str | None, segar: bool,
              dengan_remote: bool = False, remote_memuat_head: bool = True,
              tracking_tertinggal: bool = False, cabang: str = "cabang-uji",
              target_palsu: bool = False, ditinggalkan: bool = False,
              lama_menyesatkan: bool = False) -> tuple[pathlib.Path, pathlib.Path | None]:
    """Buat repo Git kecil berisi berkas handoff dengan SHA yang bisa benar/salah.

    Dipakai uji-diri untuk MEMBUKTIKAN pemeriksaan kesegaran riwayat benar-benar bisa MERAH —
    hal yang tidak bisa diuji di salinan pohon biasa (salinan tidak punya riwayat).
    """
    import shutil
    import subprocess as sp

    repo = tmp / "repo"
    (repo / "docs" / "ops").mkdir(parents=True)
    (repo / "docs" / "TERTANGGUH.md").write_text("| ID | Tanggal | Hal |\n|---|---|---|\n", encoding="utf-8")
    (repo / "PROJECT_STATE.md").write_text("STATUS: UJI\nDETAIL: uji\n", encoding="utf-8")
    (repo / "STATUS.md").write_text("- **Pekerjaan belum tersimpan:** Tidak ada\n", encoding="utf-8")
    shutil.copy2(PROMPT_KANONIK, repo / "PROMPT_ENTRI_UNIVERSAL.md")
    shutil.copy2(PROMPT_SESI, repo / NAMA_PROMPT_SESI)   # berkas STATIS: disalin apa adanya
    if lama_menyesatkan:
        # Meniru berkas pensiun yang masih berisi prompt siap-tempel versi lama (harus ditolak).
        (repo / NAMA_TEMPEL_LAMA).write_text("> BERKAS SIAP-TEMPEL — salin SELURUH isi berkas ini.\n"
                                             "===== MULAI SALIN DARI SINI =====\nPrompt versi lama.\n",
                                             encoding="utf-8")
    if ditinggalkan:
        (repo / NAMA_DITINGGALKAN).write_text(
            "| Cabang | Tanggal | Alasan |\n|---|---|---|\n"
            f"| `{cabang}` | 2026-09-18 | sesi uji yang sengaja ditinggalkan |\n", encoding="utf-8")
    isi = baca(SIAP).replace(bidang(baca(SIAP), "Commit keadaan kerja") or "", "0" * 40)
    # Berkas handoff/tempel ditulis ulang supaya menunjuk cabang repo uji ini (bukan sesi asli).
    target = "arena/cabang-hantu" if target_palsu else cabang
    isi = re.sub(r"(?m)^- \*\*Cabang yang dilanjutkan:\*\*.*$",
                 f"- **Cabang yang dilanjutkan:** `{target}`", isi)
    isi = re.sub(r"(?m)^- \*\*Ditulis oleh sesi:\*\*.*$", f"- **Ditulis oleh sesi:** `{cabang}`", isi)
    isi = re.sub(r"git fetch origin \S+:refs", f"git fetch origin {target}:refs", isi)
    # Berkas prompt sesi baru itu STATIS: di sini TIDAK ada yang disunting (dulu berkas tempel
    # harus ditulis ulang agar menunjuk cabang repo uji). Justru itu yang diuji: pemeriksa tidak
    # boleh menuntut resep menunjuk cabang tertentu, karena berkasnya generik.
    (repo / NAMA_SIAP).write_text(isi, encoding="utf-8")
    env = {"GIT_AUTHOR_NAME": "uji", "GIT_AUTHOR_EMAIL": "u@uji", "GIT_COMMITTER_NAME": "uji",
           "GIT_COMMITTER_EMAIL": "u@uji", "PATH": "/usr/bin:/bin"}
    bare = None
    if dengan_remote:
        bare = tmp / "remote.git"
        sp.run(["git", "init", "-q", "--bare", str(bare)], cwd=tmp, env=env, capture_output=True, check=False)
    sp.run(["git", "init", "-q"], cwd=repo, env=env, capture_output=True, check=False)
    # Nama cabang dibuat tetap supaya berkas handoff & uji ls-remote bisa diprediksi.
    sp.run(["git", "symbolic-ref", "HEAD", f"refs/heads/{cabang}"], cwd=repo, env=env,
           capture_output=True, check=False)
    if bare is not None:
        sp.run(["git", "remote", "add", "origin", str(bare)], cwd=repo, env=env, capture_output=True, check=False)
    for perintah in (["git", "add", "-A"], ["git", "commit", "-qm", "awal"]):
        sp.run(perintah, cwd=repo, env=env, capture_output=True, check=False)
    _, induk = jalankan(["git", "rev-parse", "HEAD"], cwd=repo)
    sha = sha_ditulis if sha_ditulis is not None else induk.strip()
    isi = isi.replace("0" * 40, sha)
    (repo / "docs" / "ops" / "SIAP-LANJUT.md").write_text(isi, encoding="utf-8")
    # Meniru aturan akhir batch yang sebenarnya: commit terakhir menyentuh ketiga berkas
    # (handoff + PROJECT_STATE + STATUS). Kalau tidak, yang diuji bukan aturannya.
    (repo / "PROJECT_STATE.md").write_text("STATUS: UJI\nDETAIL: uji\nUPDATE TERAKHIR: uji\n", encoding="utf-8")
    (repo / "STATUS.md").write_text("- **Pekerjaan belum tersimpan:** Tidak ada\n- **Waktu pembaruan:** uji\n", encoding="utf-8")
    for perintah in (["git", "add", "-A"], ["git", "commit", "-qm", "segar" if segar else "basi"]):
        sp.run(perintah, cwd=repo, env=env, capture_output=True, check=False)
    if bare is not None:
        sp.run(["git", "push", "-q", "-u", "origin", f"HEAD:refs/heads/{cabang}"], cwd=repo, env=env,
               capture_output=True, check=False)
        if not remote_memuat_head:
            # Remote "mundur" satu commit: HEAD lokal ada, tapi remote belum memuatnya.
            _, dua = jalankan(["git", "rev-parse", "HEAD^"], cwd=repo)
            sp.run(["git", "update-ref", f"refs/heads/{cabang}", dua.strip()], cwd=bare, env=env,
                   capture_output=True, check=False)
            sp.run(["git", "update-ref", f"refs/remotes/origin/{cabang}", dua.strip()], cwd=repo,
                   env=env, capture_output=True, check=False)
        elif tracking_tertinggal:
            # Remote sudah memuat HEAD, tetapi ref remote-tracking lokal dimundurkan:
            # meniru kejadian nyata `git push origin HEAD` yang tidak memperbarui ref itu.
            _, dua = jalankan(["git", "rev-parse", "HEAD^"], cwd=repo)
            sp.run(["git", "update-ref", f"refs/remotes/origin/{cabang}", dua.strip()], cwd=repo,
                   env=env, capture_output=True, check=False)
    return repo, bare

def uji_diri() -> int:
    """Buktikan pemeriksa bisa MENOLAK: setiap bagian handoff/prompt dimutasi di salinan teks.

    Kenapa di salinan teks, bukan salinan pohon: pemeriksa ini membaca riwayat Git repo
    nyata (kesegaran handoff), dan salinan sementara tidak memilikinya. Yang diuji di sini
    adalah bagian ISI — yang justru paling mudah basi.
    """
    hasil: list[tuple[str, bool, str]] = []
    sipl = baca(SIAP)
    prompt = baca(PROMPT_SESI)
    if not sipl or not prompt:
        print("LEWAT: berkas handoff/prompt sesi baru belum ada — jalankan --siapkan dulu, lalu uji-diri.")
        return 0

    masalah = periksa(penuh=False)
    hasil.append(("berkas handoff + prompt sesi baru sekarang diterima", not masalah,
                  "lolos" if not masalah else masalah[0][:90]))

    target_live = bidang(sipl, "Cabang yang dilanjutkan") or CABANG_KERJA

    def mutasi(nama: str, baru: str) -> None:
        masalah_m = periksa(sipl_teks=baru, prompt_teks=prompt, penuh=False)
        hasil.append((nama, bool(masalah_m),
                      masalah_m[0][:90] if masalah_m else "DILOLOSKAN (tumpul)"))

    def mutasi_prompt(nama: str, baru: str, sipl_uji: str | None = None) -> None:
        masalah_m = periksa(sipl_teks=sipl if sipl_uji is None else sipl_uji, prompt_teks=baru, penuh=False)
        hasil.append((nama, bool(masalah_m),
                      masalah_m[0][:90] if masalah_m else "DILOLOSKAN (tumpul)"))

    # Peringatan CI: merah harus memicu peringatan, success tidak boleh berisik.
    hasil.append(("peringatan muncul saat CI terakhir merah",
                  bool(catatan_ci(re.sub(r"(?m)^- \*\*CI terakhir:\*\*.*$",
                                         "- **CI terakhir:** failure (run 1, commit aaaaaaaa)", sipl))),
                  "CI merah harus diberitahukan ke sesi baru"))
    sipl_sukses = re.sub(r"(?m)^- \*\*CI terakhir:\*\*.*$",
                         "- **CI terakhir:** success (run 1, commit aaaaaaaa)", sipl)
    hasil.append(("tidak ada peringatan saat CI success", not catatan_ci(sipl_sukses),
                  "CI hijau tidak boleh memunculkan peringatan palsu"))

    # Kasus kembar (kejadian nyata): bagian yang sama muncul dua kali → WAJIB ditolak.
    hasil.append(("mutasi: bagian 'Commit keadaan kerja' diduplikasi",
                  bool(periksa(sipl_teks=sipl + "\n" + re.search(r"^- \*\*Commit keadaan kerja:\*\*.*$", sipl, re.M).group(0) + "\n",
                               prompt_teks=prompt, penuh=False)),
                  "dua baris commit yang bertentangan harus ditolak"))

    mutasi("mutasi: commit keadaan di handoff dikosongkan",
           re.sub(r"^- \*\*Commit keadaan kerja:\*\*.*$",
                  "- **Commit keadaan kerja:** (tidak ada)", sipl, count=1, flags=re.M))
    mutasi("mutasi: bagian CI dihapus", re.sub(r"^- \*\*CI terakhir:\*\*.*$", "", sipl, count=1, flags=re.M))
    mutasi("mutasi: bagian rencana berikutnya dihapus",
           re.sub(r"^## .*Rencana berikutnya.*$", "## Catatan lain", sipl, count=1, flags=re.M))
    mutasi("mutasi: baris 'berkas yang Lee salin' dihapus dari handoff",
           re.sub(r"^- \*\*Berkas yang Lee salin ke chat baru:\*\*.*$", "", sipl, count=1, flags=re.M))
    mutasi("mutasi: bagian 'Cabang yang dilanjutkan' dihapus",
           re.sub(r"(?m)^- \*\*Cabang yang dilanjutkan:\*\*.*\n", "", sipl))

    # --- berkas prompt sesi baru (STATIS, disalin Lee): bentuk & isinya dijaga ---
    kanonik = blok_prompt_kanonik()
    # Ganti SEMUA bentuk huruf besar/kecil: pemeriksa memakai .upper() untuk larangan merge.
    mutasi_prompt("mutasi: larangan merge dihapus dari berkas prompt",
                  re.sub(r"jangan merge", "silakan merge", prompt, flags=re.I))
    mutasi_prompt("mutasi: resep menyusul cabang pilihan dihapus",
                  prompt.replace(f"origin {TOKEN_CABANG}:refs/remotes/origin/kerja-terakhir", "origin:"))
    mutasi_prompt("mutasi: Prompt Pembuka Universal tidak lagi apa adanya",
                  prompt.replace(kanonik, "Lanjutkan saja."))
    mutasi_prompt("mutasi: baris pilihan Lee dihapus",
                  re.sub(rf"(?m)^{re.escape(BARIS_PILIHAN)}.*\n", "", prompt, count=1))
    mutasi_prompt("mutasi: penanda 'BERKAS INI STATIS' dihapus",
                  prompt.replace("BERKAS INI STATIS", "Berkas ini"))
    mutasi_prompt("mutasi: larangan menebak saat baris kosong dihapus",
                  re.sub(r"(?i)JANGAN menebak", "silahkan pilih sendiri", prompt))
    mutasi_prompt("mutasi: cara tanpa alat (for-each-ref) dihapus",
                  prompt.replace("refs/heads/arena/*", "refs/heads/arena"))
    mutasi_prompt("mutasi: penunjuk catatan sesi ditinggalkan dihapus",
                  prompt.replace("SESI_DITINGGALKAN.md", "catatan-lain.md"))
    mutasi_prompt("mutasi: fakta 'PR #1 menunjuk cabang sesi lama' dikaburkan",
                  re.sub(r"PR #1 menunjuk\s+cabang sesi lama", "PR #1 menunjuk cabang ini", prompt))
    mutasi_prompt("mutasi: fakta base branch dihapus",
                  re.sub(r"(?i)base branch[^\n]*", "", prompt))
    mutasi_prompt("mutasi: penanda blok Prompt Pembuka dirusak",
                  prompt.replace(BATAS_KANONIK_AKHIR, "===== SELESAI ====="))
    mutasi_prompt("mutasi: blok Prompt Pembuka diduplikasi",
                  prompt + "\n" + BATAS_KANONIK_AWAL + "\n" + kanonik + "\n" + BATAS_KANONIK_AKHIR + "\n")

    # --- catatan sesi yang sengaja ditinggalkan (permintaan Lee): dibaca mesin, tidak diloloskan ---
    import tempfile

    with tempfile.TemporaryDirectory(prefix="lanjut-sesi-") as tmp:
        tmp_p = pathlib.Path(tmp)
        (tmp_p / "docs" / "ops").mkdir(parents=True, exist_ok=True)
        (tmp_p / NAMA_DITINGGALKAN).write_text(
            "| Cabang | Tanggal | Alasan |\n|---|---|---|\n"
            "| `arena/cabang-uji` | 2026-09-18 | sesi uji yang sengaja ditinggalkan |\n",
            encoding="utf-8")
        ditinggal = sesi_ditinggalkan(tmp_p)
        hasil.append(("catatan sesi ditinggalkan terbaca mesin",
                      ditinggal.get("arena/cabang-uji", "").startswith("sesi uji"),
                      "catatan manual Lee wajib terbaca mesin"))

        # Berkas prompt rusak TIDAK boleh ditimpa mesin (Lee bisa sudah menyuntingnya).
        rusak = tmp_p / "rusak"
        rusak.mkdir()
        (rusak / NAMA_PROMPT_SESI).write_text(f"{BARIS_PILIHAN} x\n\n(penanda blok kanonik tidak ada)\n",
                                              encoding="utf-8")
        isi_sebelum = (rusak / NAMA_PROMPT_SESI).read_text(encoding="utf-8")
        catatan_rusak = pastikan_prompt_sesi_baru(rusak)
        hasil.append(("berkas prompt rusak TIDAK ditimpa mesin",
                      bool(catatan_rusak)
                      and (rusak / NAMA_PROMPT_SESI).read_text(encoding="utf-8") == isi_sebelum,
                      "mesin tidak boleh menebak isi berkas yang sudah disunting"))

        kosong = tmp_p / "kosong"
        kosong.mkdir()
        pastikan_prompt_sesi_baru(kosong)
        dibuat = (kosong / NAMA_PROMPT_SESI)
        teks_buat = baca(dibuat)
        hasil.append(("berkas prompt dibuat dari kerangka bila hilang",
                      dibuat.is_file() and BARIS_PILIHAN in teks_buat and kanonik in teks_buat,
                      "berkas statis harus bisa dipulihkan mesin"))

        # --- bukti pemeriksaan kesegaran + pilihan sesi (butuh riwayat Git nyata) ---
        repo_benar, _ = _repo_uji(tmp_p / "benar", None, True)
        masalah_benar = periksa(akar=repo_benar, penuh=True)
        hasil.append(("repo uji dengan handoff SEGAR + berkas statis diterima", not masalah_benar,
                      "lolos" if not masalah_benar else masalah_benar[0][:90]))
        repo_salah, _ = _repo_uji(tmp_p / "salah", "1" * 40, False)
        masalah_salah = periksa(akar=repo_salah, penuh=True)
        hasil.append(("repo uji dengan handoff BASI ditolak", bool(masalah_salah),
                      masalah_salah[0][:90] if masalah_salah else "DILOLOSKAN (tumpul)"))

        for nama_uji, pola_hapus in (
            ("mutasi: bagian 'cabang sesi baru vs PR' dihapus",
             r"(?s)## 2c\. Fakta cabang sesi baru.*?\n\n"),
            ("mutasi: baris 'Paket peninjau terbaru' dihapus",
             r"(?m)^- \*\*Paket peninjau terbaru:\*\*.*\n"),
        ):
            hasil.append((nama_uji,
                          bool(periksa(sipl_teks=re.sub(pola_hapus, "", sipl), prompt_teks=prompt, penuh=False)),
                          "handoff harus memuat bagian itu"))

        # Kasus nyata: ref remote-tracking tertinggal walau remote sudah memuat HEAD.
        repo_tt, _ = _repo_uji(tmp_p / "tt", None, True, dengan_remote=True, tracking_tertinggal=True)
        masalah_tt = periksa(akar=repo_tt, penuh=True)
        hasil.append(("ref remote-tracking tertinggal tapi remote memuat HEAD → TIDAK ditolak",
                      not masalah_tt, "lolos" if not masalah_tt else masalah_tt[0][:90]))

        # Kasus nyata: pekerjaan lokal belum sampai ke remote → WAJIB ditolak.
        repo_bp, _ = _repo_uji(tmp_p / "bp", None, True, dengan_remote=True, remote_memuat_head=False)
        masalah_bp = periksa(akar=repo_bp, penuh=True)
        hasil.append(("commit lokal belum ter-push ditolak", bool(masalah_bp),
                      masalah_bp[0][:90] if masalah_bp else "DILOLOSKAN (tumpul)"))

        # Berkas prompt kini STATIS & generik, jadi nama cabang tidak lagi dicocokkan dengan resep
        # (resep memuat token, bukan nama cabang). Penjaga yang benar-benar bekerja: cabang tujuan
        # WAJIB ada di GitHub. Dua kasus di bawah membuktikannya, termasuk saat nama cabang di
        # handoff DIBELOKKAN ke cabang hantu setelah handoff ditulis.
        repo_palsu, _ = _repo_uji(tmp_p / "palsu", None, True, dengan_remote=True, target_palsu=True)
        masalah_palsu = periksa(akar=repo_palsu, penuh=True)
        hasil.append(("sesi tujuan yang tidak ada di GitHub ditolak", bool(masalah_palsu),
                      masalah_palsu[0][:90] if masalah_palsu else "DILOLOSKAN (tumpul)"))

        repo_belok, _ = _repo_uji(tmp_p / "belok", None, True, dengan_remote=True)
        berkas_belok = repo_belok / NAMA_SIAP
        berkas_belok.write_text(
            re.sub(r"(?m)^- \*\*Cabang yang dilanjutkan:\*\*.*$",
                   "- **Cabang yang dilanjutkan:** `arena/cabang-hantu`",
                   berkas_belok.read_text(encoding="utf-8")), encoding="utf-8")
        masalah_belok = periksa(akar=repo_belok, penuh=True)
        # Sengaja menuntut ALASAN yang benar: repo uji ini juga kotor (berkas handoff baru disunting),
        # jadi tanpa penajaman ini kasus bisa "lolos" karena alasan yang salah = kasus uji tumpul.
        bukti_belok = [m for m in masalah_belok if "TIDAK ADA di GitHub" in m]
        hasil.append(("cabang di handoff dibelokkan ke cabang hantu → ditolak dengan alasan cabang",
                      bool(bukti_belok), bukti_belok[0][:90] if bukti_belok else "DILOLOSKAN (tumpul)"))

        # Sesi yang SENGAJA DITINGGALKAN Lee: ditolak — kecuali Lee memaksa (`--paksa`).
        repo_ditinggal, _ = _repo_uji(tmp_p / "ditinggal", None, True, ditinggalkan=True)
        masalah_ditinggal = periksa(akar=repo_ditinggal, penuh=False)
        hasil.append(("sesi yang SENGAJA DITINGGALKAN ditolak",
                      bool(masalah_ditinggal) and "DITINGGALKAN" in masalah_ditinggal[0],
                      masalah_ditinggal[0][:90] if masalah_ditinggal else "DILOLOSKAN (tumpul)"))
        berkas_sipl = repo_ditinggal / NAMA_SIAP
        berkas_sipl.write_text(re.sub(r"(?m)^- \*\*Dasar pilihan cabang:\*\*.*$",
                                      "- **Dasar pilihan cabang:** pilihan Lee — DIPAKSA atas perintah Lee (uji)",
                                      berkas_sipl.read_text(encoding="utf-8")), encoding="utf-8")
        masalah_paksa = periksa(akar=repo_ditinggal, penuh=False)
        hasil.append(("sesi ditinggalkan tetapi DIPAKSA atas perintah Lee → diterima", not masalah_paksa,
                      "lolos" if not masalah_paksa else masalah_paksa[0][:90]))

        # Berkas pensiun: penunjuk yang benar diterima, isi lama yang menyesatkan ditolak.
        repo_penunjuk, _ = _repo_uji(tmp_p / "penunjuk", None, True)
        (repo_penunjuk / NAMA_TEMPEL_LAMA).write_text(
            f"Berkas ini sudah DIPENSIUNKAN. Yang dipakai sekarang: `{NAMA_PROMPT_SESI}` (statis).\n",
            encoding="utf-8")
        masalah_penunjuk = periksa(akar=repo_penunjuk, penuh=False)
        hasil.append(("berkas pensiun berupa penunjuk ke prompt baru diterima", not masalah_penunjuk,
                      "lolos" if not masalah_penunjuk else masalah_penunjuk[0][:90]))
        repo_lama, _ = _repo_uji(tmp_p / "lama", None, True, lama_menyesatkan=True)
        masalah_lama = periksa(akar=repo_lama, penuh=False)
        hasil.append(("berkas pensiun yang masih memuat prompt lama ditolak", bool(masalah_lama),
                      masalah_lama[0][:90] if masalah_lama else "DILOLOSKAN (tumpul)"))

    print("UJI-DIRI lanjut-sesi")
    gagal = 0
    for kasus, sesuai, ringkas in hasil:
        tanda = "OK " if sesuai else "X  "
        if not sesuai:
            gagal += 1
        print(f"  {tanda} {kasus} → {ringkas}")
    if gagal:
        print(f"\nHASIL: GAGAL — {gagal} kasus uji-diri tidak sesuai harapan (pemeriksa mungkin tumpul)")
        return 1
    print(f"JUMLAH kasus uji-diri: {len(hasil)} (mutasi teks + repo Git uji + peringatan CI + berkas statis) "
          "— semuanya harus sesuai harapan")
    print("\nHASIL: LOLOS — pemeriksa handoff + berkas prompt sesi baru terbukti bisa MENOLAK yang cacat.")
    return 0


def main() -> int:
    if "--siapkan" in sys.argv:
        return siapkan()
    if "--daftar-sesi" in sys.argv:
        return daftar_sesi()
    if "--uji-diri" in sys.argv:
        return uji_diri()
    penuh = "--di-ci" not in sys.argv
    masalah = periksa(penuh=penuh)
    print("PERIKSA SIAP-LANJUT — handoff sesi baru (cabang, commit, berkas prompt statis, rencana)")
    for m in masalah:
        print(f"  [X] {m}")
    if not masalah:
        print("  OK  handoff lengkap & segar: sesi baru bisa melanjutkan tanpa kehilangan konteks")
    print("-" * 70)
    if masalah:
        print(f"HASIL: GAGAL — {len(masalah)} masalah pada handoff lanjut-sesi")
        return 1
    print("HASIL: LOLOS" + ("" if penuh else " (mode CI: pemeriksaan kesegaran riwayat dilewati)"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
