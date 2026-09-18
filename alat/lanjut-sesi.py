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

Dua berkas yang dihasilkan/dijaga:

1. `docs/ops/SIAP-LANJUT.md` — handoff untuk **agent** baru: cabang, commit, keadaan CI,
   butir tertangguh, dan rencana berikutnya (bagian rencana DIPERTAHANKAN apa adanya saat
   disegarkan, supaya tulisan agent tidak hilang).
2. `docs/ops/SIAP-TEMPEL-SESI-BARU.md` — untuk **Lee**: satu berkas yang cukup disalin
   seluruhnya ke chat baru (berisi Prompt Pembuka Universal yang identik dengan sumber
   kanonik + arahan lanjut proyek: cara menyusul cabang kerja, apa yang dibaca, aturannya).

Cara pakai:
    python3 alat/lanjut-sesi.py                 # periksa kesiapan lanjut (lokal: penuh)
    python3 alat/lanjut-sesi.py --siapkan       # segarkan kedua berkas di atas
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
SIAP = AKAR / "docs" / "ops" / "SIAP-LANJUT.md"
TEMPEL = AKAR / "docs" / "ops" / "SIAP-TEMPEL-SESI-BARU.md"
PROMPT_KANONIK = AKAR / "PROMPT_ENTRI_UNIVERSAL.md"
TERTANGGUH = AKAR / "docs" / "TERTANGGUH.md"
PROJECT_STATE = AKAR / "PROJECT_STATE.md"

# Cadangan bila cabang aktif tak terbaca dari Git. Cabang yang benar-benar dipakai ditentukan
# oleh `pilih_target()`: bisa dari `--lanjut-dari` (pilihan Lee), bisa dari berkas handoff
# sebelumnya, bisa bawaan "sesi terakhir yang menulis handoff ini". TIDAK ditebak dari ingatan.
# Catatan mati-listrik 2026-09-18 (sesi `01a0b4c3`): pemeriksa PERNAH mewajibkan handoff menunjuk
# nama konstanta ini saja, padahal setiap sesi Arena bekerja di CABANG SESINYA SENDIRI — sehingga
# `--siapkan` yang benar justru SELALU ditolak pemeriksa dan sesi berikutnya diarahkan ke cabang
# yang sudah berhenti. Pemeriksa sekarang menerima cabang mana pun yang pilihan Lee/`pilih_target()`
# sah, dan nama di atas hanya pembanding + cadangan.
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


def daftar_cabang_sesi(akar: pathlib.Path) -> list[tuple[str, str, str, str, bool]]:
    """Semua cabang sesi di GitHub: (cabang, tanggal, judul, sha, punya_alat_lanjut).

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
        punya_alat = 0 == jalankan(["git", "cat-file", "-e",
                                    f"{sha}:docs/ops/SIAP-TEMPEL-SESI-BARU.md"], cwd=akar)[0]
        baris.append((cabang, tanggal, judul[:72], sha, punya_alat))
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
            tempe_teks: str | None = None, penuh: bool = True) -> list[str]:
    """Kembalikan daftar masalah. Kosong = siap lanjut.

    `penuh=False` (dipakai `--di-ci`) hanya memeriksa ISI berkas; pemeriksaan kesegaran
    riwayat Git dilewati karena checkout CI dangkal/menggabung.
    """
    akar = akar or AKAR
    masalah: list[str] = []
    sipl = sipl_teks if sipl_teks is not None else baca(akar / "docs" / "ops" / "SIAP-LANJUT.md")
    tempe = tempe_teks if tempe_teks is not None else baca(akar / "docs" / "ops" / "SIAP-TEMPEL-SESI-BARU.md")
    if not sipl:
        return ["docs/ops/SIAP-LANJUT.md BELUM ADA — sesi baru tidak punya penunjuk keadaan. "
                "Jalankan: python3 alat/lanjut-sesi.py --siapkan"]
    if not tempe:
        masalah.append("docs/ops/SIAP-TEMPEL-SESI-BARU.md BELUM ADA — Lee tidak punya berkas untuk "
                       "disalin ke chat baru. Jalankan: python3 alat/lanjut-sesi.py --siapkan")

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
    # --- cabang yang dilanjutkan = pilihan Lee; berkas tempel WAJIB menunjuk cabang yang sama ---
    target = bidang(sipl, "Cabang yang dilanjutkan")
    if target and not re.match(r"^(arena|main|master)/?[\w./-]*$", target) and not re.match(r"^[\w./-]+$", target):
        masalah.append(f"docs/ops/SIAP-LANJUT.md: nama cabang '{target}' tidak masuk akal")
    if target and tempe and not re.search(
            rf"git fetch origin\s+{re.escape(target)}:refs/remotes/origin/kerja-terakhir", tempe):
        masalah.append(f"docs/ops/SIAP-TEMPEL-SESI-BARU.md TIDAK menyusul cabang '{target}' yang ditulis "
                       "di handoff — Lee bisa memindahkan sesi ke cabang yang salah")
    if tempe and not re.search(r"(?i)sesi mana|pilih(?:an)? sesi|daftar sesi", tempe):
        masalah.append("docs/ops/SIAP-TEMPEL-SESI-BARU.md tidak menjelaskan bahwa Lee boleh MEMILIH sesi "
                       "yang dilanjutkan — pilihan sesi adalah hak Lee, bukan tebakan mesin")
    # Penjaga warisan (sesi `01a0b4c3`): handoff lama masih memakai `Cabang kerja terakhir`.
    # Kalau field itu ada, nilainya tidak boleh menunjuk cabang yang jelas-jelas bukan tempat
    # pekerjaan berada (dulu inilah yang membuat `--siapkan` + pemeriksa saling menolak = deadlock).
    cabang_lama = bidang(sipl, "Cabang kerja terakhir")
    if cabang_lama:
        _, nama_cabang_lokal = jalankan(["git", "branch", "--show-current"], cwd=akar)
        sah = {x for x in (CABANG_KERJA, nama_cabang_lokal.strip(), target or "") if x}
        if cabang_lama not in sah:
            masalah.append(f"docs/ops/SIAP-LANJUT.md masih menunjuk 'Cabang kerja terakhir' = "
                           f"'{cabang_lama}' yang bukan cabang pilihan sesi ('{target or CABANG_KERJA}') "
                           "dan bukan cabang yang sedang dipakai — perbarui handoff dengan --siapkan")
    if re.search(r"CABANG-KERJA-BELUM-DIISI|TODO", sipl):
        masalah.append("docs/ops/SIAP-LANJUT.md masih memuat penanda TODO — belum diisi sungguhan")

    # --- berkas siap-tempel harus memuat prompt kanonik APA ADANYA ---
    kanonik = blok_prompt_kanonik()
    if not kanonik:
        masalah.append("PROMPT_ENTRI_UNIVERSAL.md tidak terbaca — blok prompt kanonik tidak bisa dipastikan")
    elif tempe and kanonik not in tempe:
        masalah.append("docs/ops/SIAP-TEMPEL-SESI-BARU.md TIDAK memuat Prompt Pembuka Universal apa adanya — "
                       "sesi baru akan mulai tanpa aturan orientasi")
    if tempe and "JANGAN MERGE" not in tempe.upper():
        masalah.append("docs/ops/SIAP-TEMPEL-SESI-BARU.md tidak memuat larangan merge — keputusan merge milik Lee")
    if tempe and "refs/remotes/origin/kerja-terakhir" not in tempe:
        masalah.append("docs/ops/SIAP-TEMPEL-SESI-BARU.md tidak memuat perintah menyusul cabang kerja — "
                       "sesi baru bisa bekerja dari main yang tertinggal")
    for nama_fakta, pola_fakta in (
        ("tidak perlu atur base branch", r"(?i)base branch"),
        # Jendela sengaja lebar: kalimatnya panjang ("Prompt penutup di chat lama disarankan
        # (1 kalimat: ...) tetapi TIDAK wajib") — batas 60 karakter terlalu ketat dan
        # sempat membuat penjaga ini BUTA terhadap berkas yang sebenarnya sudah benar.
        ("prompt penutup tidak wajib", r"(?is)penutup.{0,300}?tidak wajib"),
        ("pakai salinan terbaru", r"(?i)salinan TERBARU|terbaru berkas ini"),
    ):
        if tempe and not re.search(pola_fakta, tempe):
            masalah.append(f"docs/ops/SIAP-TEMPEL-SESI-BARU.md tidak menjelaskan '{nama_fakta}' — "
                           "Lee bisa mengira harus melakukan langkah yang sebenarnya tidak perlu")
    if tempe and "ATURAN BAHASA" not in tempe:
        masalah.append("docs/ops/SIAP-TEMPEL-SESI-BARU.md tidak memuat ATURAN BAHASA — "
                       "sesi baru bisa menjawab Lee dengan bahasa yang salah")
    # Toleran terhadap pembungkusan baris teks (frasa ini sengaja dipecah agar rapi dibaca).
    if tempe and not re.search(r"PR #1 menunjuk\s+cabang sesi lama", tempe):
        masalah.append("docs/ops/SIAP-TEMPEL-SESI-BARU.md tidak menjelaskan bahwa PR #1 menunjuk cabang "
                       "sesi lama — sesi baru bisa mengira pekerjaannya otomatis masuk PR #1")
    if tempe and kanonik and tempe.count(kanonik) != 1:
        masalah.append(f"docs/ops/SIAP-TEMPEL-SESI-BARU.md memuat blok Prompt Pembuka {tempe.count(kanonik)}x "
                       "(harus tepat 1) — berkas tempel rusak/berulang")

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

Cabang `{target}` di atas adalah **pilihan Lee** (bukan tebakan mesin). Kalau bukan itu yang
dimau, jalankan `python3 alat/lanjut-sesi.py --daftar-sesi`, lalu siapkan ulang dengan
`python3 alat/lanjut-sesi.py --siapkan --lanjut-dari <cabang>`.

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

    kanonik = blok_prompt_kanonik()
    tempe = f"""> BERKAS SIAP-TEMPEL — salin SELURUH isi berkas ini ke chat BARU (percakapan baru).
> Dibuat mesin oleh `alat/lanjut-sesi.py`; Prompt Pembuka di bawah diambil apa adanya dari
> sumber kanonik (`PROMPT_ENTRI_UNIVERSAL.md`), jadi tidak bisa menyimpang.
>
> CARA PAKAI (untuk Lee):
> 1. Kamu TIDAK perlu mengatur apa pun soal branch — "base branch" hanya dipakai saat Pull
>    Request dibuka (PR ini sudah terbuka), dan cabang kerja dibuat otomatis oleh platform.
> 2. Ini hanya perlu dikirim di chat BARU. Prompt penutup di chat lama disarankan (1 kalimat:
>    `Siapkan pindah ke sesi baru.`) tetapi TIDAK wajib; kalau chat lama sudah mati/mogok,
>    langsung salin berkas ini saja — agent baru diperintah memeriksa keadaan repo lebih dulu.
> 3. Yang bisa tertinggal bila langkah penutup dilewati: pekerjaan yang saat itu belum
>    di-commit/belum di-push ke GitHub.
> 4. Pakai salinan TERBARU berkas ini (berkas berubah setiap batch): minta
>    `Tampilkan berkas siap tempel.`
> 5. JANGAN MERGE PR ini — merge keputusan Lee dan mengakhiri sesi cabang ini.
> 6. Bahasa: balaslah SELALU dalam bahasa Indonesia sederhana (aturan ini sudah tertanam di
>    Prompt Pembuka di bawah, tetapi diulang di sini supaya tidak pernah terlewat).
> 7. Mau melanjutkan sesi LAIN? Kamu yang menentukan, bukan mesin: minta agent menampilkan
>    `python3 alat/lanjut-sesi.py --daftar-sesi` (atau tulis `Tampilkan daftar sesi yang bisa
>    dilanjutkan.`), sebutkan pilihanmu, lalu agent menyiapkan ulang berkas ini dengan
>    `python3 alat/lanjut-sesi.py --siapkan --lanjut-dari <cabang-pilihanmu>`.
>    Ingat: sesi yang belum pernah di-push ke GitHub TIDAK muncul di daftar itu (pekerjaannya
>    belum tersimpan), dan sesi lama biasanya punya alat/pemeriksa versi lebih tua.

===== MULAI SALIN DARI SINI =====

{kanonik}

===== SAMBUNGAN: ARAHAN LANJUT PROYEK (dibuat mesin {hari_ini}) =====

Proyek: **Resto Barokah** — repo `With-AI-Agent/Resto-Barokah`, cabang kerja terakhir
SESI YANG DILANJUT (pilihan Lee): `{target}` — ditulis oleh sesi `{nama_cabang}` @ `{sha}`.
`{sha}` adalah commit KEADAAN (induk dari commit handoff), jadi saat kamu menyusul cabang, ujung
cabang akan berisi satu commit yang lebih baru: commit yang memuat berkas handoff ini.
Cara memastikan kamu di ujung yang benar: `git log --oneline -1` menampilkan commit yang menyentuh
`docs/ops/SIAP-LANJUT.md`. PR #1 **terbuka** — **JANGAN MERGE**: merge hanya keputusan Lee.

Catatan cabang (penting): pekerjaanmu hidup di cabang sesi barumu sendiri, sedangkan PR #1 menunjuk
cabang sesi lama — jadi pekerjaan baru TIDAK otomatis masuk PR #1. Bila Lee ingin meninjau lewat PR,
buka PR baru dari cabangmu (base `main`) dan laporkan tautannya; jangan merge tanpa keputusan Lee.

Langkah pertama sesi ini (WAJIB, supaya tidak bekerja dari `main` yang tertinggal {jarak_main}):

```
git fetch origin {target}:refs/remotes/origin/kerja-terakhir
git merge --ff-only origin/kerja-terakhir
python3 alat/mulai-sesi.py
```

Kalau `{target}` BUKAN sesi terakhir: alat & aturan di sana mungkin versi lebih tua — laporkan apa
adanya ke Lee, jangan mengarang mekanisme baru, dan jangan menyentuh `main`.

Lalu baca `docs/ops/SIAP-LANJUT.md` (penunjuk keadaan: cabang, commit, CI, butir tertangguh,
rencana berikutnya) dan `PROJECT_STATE.md`. Laporkan KARTU SESI ke Lee SEBELUM bekerja.

Ringkas keadaan terakhir: putaran13 (review PR #1 + audit AUD-3 2026-09-18) — 27 temuan
diverifikasi nyata dan ditutup migrasi `0014`; suite SQL 41/41, mutasi 16/16 & 17/17 MERAH,
CI hijau. Sisa pekerjaan terdekat dan pilihannya ada di bagian "Rencana berikutnya" pada
`docs/ops/SIAP-LANJUT.md`.

===== SELESAI SALIN =====
"""
    TEMPEL.write_text(tempe, encoding="utf-8")

    print(f"SIAP-LANJUT.md ditulis     : docs/ops/SIAP-LANJUT.md  (commit keadaan {sha[:8]})")
    print(f"SIAP-TEMPEL ditulis        : docs/ops/SIAP-TEMPEL-SESI-BARU.md")
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
    for i, (cabang, tanggal, judul, _sha, punya_alat) in enumerate(baris, 1):
        kode, n = jalankan(["git", "rev-list", "--count", f"origin/main..origin/{cabang}"], cwd=AKAR)
        jarak = f"{n.strip()} commit di atas main" if kode == 0 and n.strip().isdigit() else "jarak tak terbaca"
        tanda = []
        if cabang == cabang_sekarang:
            tanda.append("SESI INI")
        if cabang == target:
            tanda.append("SEDANG DITUJU")
        if not punya_alat:
            tanda.append("belum punya berkas mekanisme (sesi lama)")
        print(f"  {i}. {cabang}")
        print(f"       {tanggal} · {jarak} · alat lanjut-sesi: {'ada' if punya_alat else 'TIDAK ADA'}"
              + (f" · ← {' · '.join(tanda)}" if tanda else ""))
        print(f"       commit terakhir: {judul}")
    print("-" * 78)
    print("Cara memilih (contoh): python3 alat/lanjut-sesi.py --siapkan --lanjut-dari <cabang>")
    print("Catatan: sesi yang belum pernah di-push TIDAK muncul di sini — pekerjaannya belum tersimpan di GitHub.")
    return 0


# --------------------------------------------------------------------------- uji-diri
def _repo_uji(tmp: pathlib.Path, sha_ditulis: str | None, segar: bool,
              dengan_remote: bool = False, remote_memuat_head: bool = True,
              tracking_tertinggal: bool = False, cabang: str = "cabang-uji",
              target_palsu: bool = False) -> tuple[pathlib.Path, pathlib.Path | None]:
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
    shutil.copy2(TEMPEL, repo / "docs" / "ops" / "SIAP-TEMPEL-SESI-BARU.md")
    isi = baca(SIAP).replace(bidang(baca(SIAP), "Commit keadaan kerja") or "", "0" * 40)
    # Berkas handoff/tempel ditulis ulang supaya menunjuk cabang repo uji ini (bukan sesi asli).
    target = "arena/cabang-hantu" if target_palsu else cabang
    isi = re.sub(r"(?m)^- \*\*Cabang yang dilanjutkan:\*\*.*$",
                 f"- **Cabang yang dilanjutkan:** `{target}`", isi)
    isi = re.sub(r"(?m)^- \*\*Ditulis oleh sesi:\*\*.*$", f"- **Ditulis oleh sesi:** `{cabang}`", isi)
    isi = re.sub(r"git fetch origin \S+:refs", f"git fetch origin {target}:refs", isi)
    # PENTING: blok Prompt Pembuka (kanonik) mengandung CONTOH perintah susul — jangan diubah,
    # kalau tidak penjaga "prompt apa adanya" akan menolak berkas uji ini (kesalahan nyata
    # 2026-09-18: regex ikut menyunting blok kanonik sehingga uji-diri merah palsu).
    tempe_uji = baca(TEMPEL)
    kanonik_uji = blok_prompt_kanonik()
    kepala, pemisah, ekor = tempe_uji.partition(kanonik_uji) if kanonik_uji in tempe_uji \
        else (tempe_uji, "", "")
    kepala = re.sub(r"git fetch origin \S+:refs", f"git fetch origin {target}:refs", kepala)
    ekor = re.sub(r"git fetch origin \S+:refs", f"git fetch origin {target}:refs", ekor)
    ekor = re.sub(r"(?m)^.*SESI YANG DILANJUT.*$", f"SESI YANG DILANJUT: `{target}` (uji)", ekor)
    tempe_uji = kepala + pemisah + ekor
    (repo / "docs" / "ops" / "SIAP-TEMPEL-SESI-BARU.md").write_text(tempe_uji, encoding="utf-8")
    (repo / "docs" / "ops" / "SIAP-LANJUT.md").write_text(isi, encoding="utf-8")
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
    # Repo uji punya cabangnya sendiri (master/main tergantung git init) — handoff harus menunjuk
    # cabang ITU, bukan cabang sesi asli yang ikut tersalin dari repo. Tanpa penyesuaian ini,
    # pemeriksaan "cabang handoff = cabang sesi ini" salah tuduh pada repo uji (bukan cacat pemeriksa).
    _, cabang_uji = jalankan(["git", "branch", "--show-current"], cwd=repo)
    if cabang_uji.strip():
        for nama_bidang in ("Cabang kerja terakhir", "Cabang yang dilanjutkan"):
            isi = re.sub(rf"^- \*\*{nama_bidang}:\*\*\s*`[^`]+`",
                         f"- **{nama_bidang}:** `{cabang_uji.strip()}`", isi, count=1, flags=re.M)
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
    """Buktikan pemeriksa bisa MENOLAK: setiap bagian handoff dimutasi di salinan teks.

    Kenapa di salinan teks, bukan salinan pohon: pemeriksa ini membaca riwayat Git repo
    nyata (kesegaran handoff), dan salinan sementara tidak memilikinya. Yang diuji di sini
    adalah bagian ISI — yang justru paling mudah basi.
    """
    hasil: list[tuple[str, bool, str]] = []
    sipl = baca(SIAP)
    tempe = baca(TEMPEL)
    if not sipl or not tempe:
        print("LEWAT: berkas handoff belum ada — jalankan --siapkan dulu, lalu uji-diri.")
        return 0

    masalah = periksa(penuh=False)
    hasil.append(("berkas handoff sekarang diterima", not masalah,
                  "lolos" if not masalah else masalah[0][:90]))

    target_live = bidang(sipl, "Cabang yang dilanjutkan") or CABANG_KERJA

    def mutasi(nama: str, baru: str) -> None:
        masalah_m = periksa(sipl_teks=baru, tempe_teks=tempe, penuh=False)
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
                               tempe_teks=tempe, penuh=False)),
                  "dua baris commit yang bertentangan harus ditolak"))

    mutasi("mutasi: commit keadaan dihandoff dikosongkan", re.sub(r"^- \*\*Commit keadaan kerja:\*\*.*$",
                                                                  "- **Commit keadaan kerja:** (tidak ada)", sipl, count=1, flags=re.M))
    mutasi("mutasi: cabang dihandoff diubah ke cabang lain",
           sipl.replace(target_live, "arena/cabang-yang-salah", 1))
    # Lapangan nama warisan (penjaga deadlock `01a0b4c3`): baris lama yang menunjuk cabang asing
    # harus tetap tertolak walau field baru sudah benar.
    hasil.append(("mutasi: 'Cabang kerja terakhir' warisan menunjuk cabang asing → ditolak",
                  bool(periksa(sipl_teks=sipl + "- **Cabang kerja terakhir:** `arena/cabang-yang-salah`\n",
                               tempe_teks=tempe, penuh=False)),
                  "cabang warisan yang salah harus diberhentikan, bukan dipercaya"))
    # ...sebaliknya, nilai yang sama dengan cabang pilihan (kasus yang DULU dibunuh pemeriksa buta)
    # tidak boleh ditolak — inilah inti perbaikan deadlock.
    _cadangan = sipl + f"- **Cabang kerja terakhir:** `{target_live}`\n"
    hasil.append(("mutasi: 'Cabang kerja terakhir' warisan = cabang pilihan → diterima",
                  not periksa(sipl_teks=_cadangan, tempe_teks=tempe, penuh=False),
                  "kalau tidak lolos, sesi baru akan mati-listrik seperti 2026-09-18"))
    mutasi("mutasi: bagian CI dihapus", re.sub(r"^- \*\*CI terakhir:\*\*.*$", "", sipl, count=1, flags=re.M))
    mutasi("mutasi: bagian rencana berikutnya dihapus",
           re.sub(r"^## .*Rencana berikutnya.*$", "## Catatan lain", sipl, count=1, flags=re.M))

    # Ganti SEMUA bentuk (huruf besar/kecil): pemeriksa memakai .upper(), jadi mutasi
    # yang hanya mengganti bentuk huruf besar akan lolos palsu — pernah terjadi.
    tempe_tanpa_larangan = re.sub(r"jangan merge", "silakan merge", tempe, flags=re.I)
    masalah_t = periksa(sipl_teks=sipl, tempe_teks=tempe_tanpa_larangan, penuh=False)
    hasil.append(("mutasi: larangan merge dihapus dari berkas siap-tempel", bool(masalah_t),
                  masalah_t[0][:90] if masalah_t else "DILOLOSKAN (tumpul)"))
    masalah_s = periksa(sipl_teks=sipl, tempe_teks=tempe.replace("refs/remotes/origin/kerja-terakhir", "refs/heads/x"), penuh=False)
    hasil.append(("mutasi: cara menyusul cabang dihapus", bool(masalah_s),
                  masalah_s[0][:90] if masalah_s else "DILOLOSKAN (tumpul)"))
    kanonik = blok_prompt_kanonik()
    masalah_p = periksa(sipl_teks=sipl, tempe_teks=tempe.replace(kanonik, "Lanjutkan saja."), penuh=False)
    hasil.append(("mutasi: Prompt Pembuka Universal tidak lagi apa adanya", bool(masalah_p),
                  masalah_p[0][:90] if masalah_p else "DILOLOSKAN (tumpul)"))

    # --- pilihan sesi (permintaan Lee 2026-09-18): pilihan Lee yang dihormati, bukan tebakan mesin ---
    hasil.append(("mutasi: bagian 'Cabang yang dilanjutkan' dihapus",
                  bool(periksa(sipl_teks=re.sub(r"(?m)^- \*\*Cabang yang dilanjutkan:\*\*.*\n", "", sipl),
                               tempe_teks=tempe, penuh=False)),
                  "tanpa bagian ini sesi baru kehilangan tahu harus menyusul ke mana"))
    hasil.append(("mutasi: resep berkas tempel menunjuk cabang lain",
                  bool(periksa(sipl_teks=sipl,
                               tempe_teks=re.sub(r"git fetch origin \S+:refs",
                                                 "git fetch origin arena/cabang-lain:refs", tempe),
                               penuh=False)),
                  "berkas tempel harus menyusul cabang yang sama dengan handoff"))
    hasil.append(("mutasi: penjelasan 'Lee boleh memilih sesi' dihapus",
                  bool(periksa(sipl_teks=sipl, tempe_teks=re.sub(r"(?is)7\. Mau melanjutkan sesi LAIN.*?versi lebih tua\.", "", tempe),
                               penuh=False)),
                  "pilihan sesi adalah hak Lee — harus dijelaskan di berkas tempel"))

    # --- bukti pemeriksaan kesegaran (butuh riwayat Git nyata) ---
    import tempfile

    with tempfile.TemporaryDirectory(prefix="lanjut-sesi-") as tmp:
        repo_benar, _ = _repo_uji(pathlib.Path(tmp) / "benar", None, True)
        masalah_benar = periksa(akar=repo_benar, penuh=True)
        hasil.append(("repo uji dengan handoff SEGAR diterima", not masalah_benar,
                      "lolos" if not masalah_benar else masalah_benar[0][:90]))
        repo_salah, _ = _repo_uji(pathlib.Path(tmp) / "salah", "1" * 40, False)
        masalah_salah = periksa(akar=repo_salah, penuh=True)
        hasil.append(("repo uji dengan handoff BASI ditolak", bool(masalah_salah),
                      masalah_salah[0][:90] if masalah_salah else "DILOLOSKAN (tumpul)"))

        # Blok CARA PAKAI (jawaban atas pertanyaan Lee) tidak boleh hilang.
        tempe_tanpa_cara = re.sub(r"(?s)CARA PAKAI \(untuk Lee\).*?JANGAN MERGE PR ini[^\n]*\n", "", tempe)
        hasil.append(("mutasi: blok CARA PAKAI dihapus",
                      bool(periksa(sipl_teks=sipl, tempe_teks=tempe_tanpa_cara, penuh=False)),
                      "berkas tempel harus menjelaskan base branch/penutup/berkas terbaru"))

        # Bagian baru (temuan sesi baru 2026-09-18) tidak boleh hilang tanpa ditolak.
        for nama_uji, pola_hapus, tempe_mana in (
            ("mutasi: bagian 'cabang sesi baru vs PR' dihapus", r"(?s)## 2c\. Fakta cabang sesi baru.*?\n\n", False),
            ("mutasi: baris 'Paket peninjau terbaru' dihapus", r"(?m)^- \*\*Paket peninjau terbaru:\*\*.*\n", False),
            ("mutasi: catatan cabang di berkas tempel dihapus",
             r"(?s)Catatan cabang \(penting\).*?keputusan Lee\.\n", True),
        ):
            if tempe_mana:
                hasil.append((nama_uji,
                              bool(periksa(sipl_teks=sipl, tempe_teks=re.sub(pola_hapus, "", tempe), penuh=False)),
                              "berkas tempel harus menjelaskan cabang baru vs PR #1"))
            else:
                hasil.append((nama_uji,
                              bool(periksa(sipl_teks=re.sub(pola_hapus, "", sipl), tempe_teks=tempe, penuh=False)),
                              "handoff harus memuat bagian itu"))

        # Kasus nyata: ref remote-tracking tertinggal walau remote sudah memuat HEAD.
        repo_tt, _ = _repo_uji(pathlib.Path(tmp) / "tt", None, True, dengan_remote=True,
                               tracking_tertinggal=True)
        masalah_tt = periksa(akar=repo_tt, penuh=True)
        hasil.append(("ref remote-tracking tertinggal tapi remote memuat HEAD → TIDAK ditolak",
                      not masalah_tt, "lolos" if not masalah_tt else masalah_tt[0][:90]))

        # Kasus nyata: pekerjaan lokal belum sampai ke remote → WAJIB ditolak.
        repo_bp, _ = _repo_uji(pathlib.Path(tmp) / "bp", None, True, dengan_remote=True,
                               remote_memuat_head=False)
        masalah_bp = periksa(akar=repo_bp, penuh=True)
        hasil.append(("commit lokal belum ter-push ditolak", bool(masalah_bp),
                      masalah_bp[0][:90] if masalah_bp else "DILOLOSKAN (tumpul)"))

        # Pilihan sesi yang tidak ada di GitHub WAJIB ditolak (Lee tidak bisa disuruh pindah ke sana).
        repo_palsu, _ = _repo_uji(pathlib.Path(tmp) / "palsu", None, True, dengan_remote=True,
                                  target_palsu=True)
        masalah_palsu = periksa(akar=repo_palsu, penuh=True)
        hasil.append(("sesi tujuan yang tidak ada di GitHub ditolak", bool(masalah_palsu),
                      masalah_palsu[0][:90] if masalah_palsu else "DILOLOSKAN (tumpul)"))

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
    print(f"JUMLAH kasus uji-diri: {len(hasil)} (mutasi teks + repo Git uji + peringatan CI) — semuanya harus sesuai harapan")
    print("\nHASIL: LOLOS — pemeriksa handoff terbukti bisa MENOLAK handoff cacat.")
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
    print("PERIKSA SIAP-LANJUT — handoff sesi baru (cabang, commit, berkas tempel, rencana)")
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
