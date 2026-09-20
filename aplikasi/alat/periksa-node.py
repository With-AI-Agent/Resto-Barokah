#!/usr/bin/env python3
"""Pemeriksa keselarasan versi Node yang DIKLANKAN dengan pustaka TERKUNCI (audit I F-21).

Kenapa ada (temuan audit I F-21, 2026-09-19): `aplikasi/package.json` mengiklankan
`engines.node: ">=20"` dan `aplikasi/README.md` menulis "Node.js 22 (minimal 20)",
padahal dua pustaka yang terkunci di `aplikasi/package-lock.json` menuntut Node 22:
`@supabase/supabase-js` (>=22.0.0) dan `vitest` (^22.12.0 || ^24.0.0 || >=26.0.0).
Akibatnya orang yang mengikuti README bisa memasang versi yang tidak didukung pustaka
wajib aplikasi. Temuan ini kelas K-3 (kebersihan/reprodusibilitas), tetapi akibatnya
nyata: pengguna mengikuti iklan lalu buntu.

Yang diperiksa (semuanya bisa dibaca mesin, tanpa jaringan):

  1. Lock bisa dibaca dan PUNYA entri ber-`engines.node` — kalau tidak, pemeriksa
     GAGAL (gagal-tertutup: jangan mengaku selaras hanya karena tidak bisa membaca).
  2. Batas minimum yang DIBUTUHKAN dihitung dari seluruh entri terkunci yang **bukan
     opsional**. Entri opsional (`"optional": true`, mis. `@napi-rs/lzma-*` bawaan
     rollup) sengaja diabaikan: kalau versinya tidak cocok, npm melewatinya, jadi versi
     itu TIDAK boleh menaikkan syarat minimum yang diiklankan ke pengguna.
  3. `aplikasi/package.json` → `engines.node` berbentuk `>=X` dan `X >= butuh`.
     Bentuk lain (`^22.12.0`, `>= 22`, `22.x`) DITOLAK — supaya alat ini tidak menebak.
  4. `aplikasi/README.md` menyebut batas yang SAMA (`<X>+`) di baris prasyarat Node.
     Iklan di dokumen dan kenyataan di kunci tidak boleh berbeda arah.
  5. Setiap `.github/workflows/*.yml` yang memakai `node-version` memakai versi `>= X`.
     Versi berbentuk satu angka (`'22'`) diartikan **22.0.0** — memang begitu: satu baris
     `22` di `actions/setup-node` boleh mengambil 22.0.0, jadi ia TIDAK cukup bila batas
     minimumnya 22.12.0.
  6. Node yang menjalankan pemeriksaan ini (kalau ada) juga `>= X`; kalau tidak, pemeriksa
     memberi tahu bahwa LINGKUNGANNYA sendiri sudah di bawah dukungan yang diiklankan.

Bukti bahwa pemeriksa ini tidak tumpul: `--uji-diri` (salinan utuh DITERIMA, 8 mutasi
DITOLAK, termasuk mutasi opsional yang justru HARUS tetap diterima).
"""
from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

AKAR_REPO = Path(__file__).resolve().parents[2]

# Bentuk yang diterima untuk engines di package.json: persis ">=X" (tanpa spasi).
POLA_ENGINES = re.compile(r"^>=(\d+(?:\.\d+){0,2})$")
# Rujukan versi pertama di dalam satu rentang, mis. "^22.12.0 || ^24.0.0" → 22.12.0
POLA_ANGKA_VERSI = re.compile(r"(\d+)(?:\.(\d+))?(?:\.(\d+))?")


def versi(teks: str) -> tuple[int, int, int]:
    """'22.12' → (22, 12, 0); 'v22.22.3' → (22, 22, 3)."""
    m = POLA_ANGKA_VERSI.search(teks or "")
    if not m:
        raise ValueError(f"tidak ada angka versi di: {teks!r}")
    return (int(m.group(1)), int(m.group(2) or 0), int(m.group(3) or 0))


def teks_versi(v: tuple[int, int, int]) -> str:
    return ".".join(str(x) for x in v)


def batas_bawah(rentang: str) -> tuple[int, int, int] | None:
    """Batas bawah yang PASTI dibutuhkan sebuah rentang `engines.node`.

    Rentang dipecah pada `||` (pilihan), lalu diambil versi terkecil di antara
    alternatif. Untuk `^22.12.0` batas bawahnya 22.12.0 dan untuk `18 || 20 || >=22`
    batas bawahnya 18.0.0 — keduanya cukup untuk memutuskan "minimal Node berapa".
    Rentang tanpa angka sama sekali → None (tidak bisa dinilai → dianggap tidak ada).
    """
    batas: list[tuple[int, int, int]] = []
    for pilihan in rentang.split("||"):
        m = POLA_ANGKA_VERSI.search(pilihan)
        if not m:
            return None
        batas.append((int(m.group(1)), int(m.group(2) or 0), int(m.group(3) or 0)))
    return min(batas) if batas else None


def batas_minimum_dibutuhkan(lock: dict) -> tuple[tuple[int, int, int] | None, list[str], int]:
    """Hitung syarat Node dari lock. Kembalikan (batas, catatan, jumlah entri dinilai)."""
    paket = lock.get("packages") or {}
    batas: tuple[int, int, int] | None = None
    catatan: list[str] = []
    dinilai = 0
    for nama, isi in paket.items():
        if nama == "":  # entri akar = engines aplikasi sendiri (jangan melingkar)
            continue
        rentang = (isi.get("engines") or {}).get("node")
        if not rentang:
            continue
        if isi.get("optional"):
            continue
        dinilai += 1
        bawah = batas_bawah(rentang)
        if bawah is None:
            catatan.append(f"{nama} punya `engines.node` tanpa angka: {rentang!r} (dilewati)")
            continue
        if batas is None or bawah > batas:
            batas = bawah
            catatan.append(f"paling menuntut: {nama.removeprefix('node_modules/')} → {rentang}")
    return batas, catatan, dinilai


def periksa_node_version(berkas: Path, butuh: tuple[int, int, int], akar: Path) -> list[str]:
    """Satu berkas alur `.yml`: `node-version` wajib >= butuh."""
    pesan: list[str] = []
    teks = berkas.read_text(encoding="utf-8")
    cocok = re.findall(r"node-version:\s*['\"]?([0-9][0-9.]*)['\"]?", teks)
    if not cocok:
        return pesan  # alur tanpa Node (atau tanpa setup-node) → bukan urusan pemeriksa ini
    for tulis in cocok:
        punya = versi(tulis)
        if punya < butuh:
            pesan.append(
                f"{berkas.relative_to(akar)}: `node-version: '{tulis}'` = "
                f"{teks_versi(punya)}, di bawah kebutuhan {teks_versi(butuh)} — "
                "naikkan (versi bernama satu angka punya arti 22.0.0, bukan 22.x terbaru)"
            )
    return pesan


def periksa(akar: Path) -> tuple[int, list[str], list[str]]:
    """Periksa `akar`. Kembalikan (kode, ok, gagal)."""
    ok: list[str] = []
    gagal: list[str] = []
    package = akar / "aplikasi" / "package.json"
    kunci = akar / "aplikasi" / "package-lock.json"
    readme = akar / "aplikasi" / "README.md"

    if not kunci.is_file() or not package.is_file() or not readme.is_file():
        return 1, ok, [f"berkas wajib tidak ada: {package.name}/{kunci.name}/{readme.name} di aplikasi/"]

    try:
        lock = json.loads(kunci.read_text(encoding="utf-8"))
        pkg = json.loads(package.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        return 1, ok, [f"JSON tidak bisa dibaca: {e}"]

    butuh, catatan, dinilai = batas_minimum_dibutuhkan(lock)
    if butuh is None or dinilai == 0:
        return 1, ok, [
            "gagal-tertutup: tidak ada satu pun entri terkunci ber-`engines.node` yang bisa dinilai "
            "— pemeriksa ini tidak boleh mengaku selaras tanpa bukti"
        ]
    ok.append(f"kebutuhan Node dari lock: >= {teks_versi(butuh)} (dinilai dari {dinilai} entri non-opsional)")
    for c in catatan[-1:]:
        ok.append(c)

    # (3) engines di package.json
    engines = (pkg.get("engines") or {}).get("node")
    if not isinstance(engines, str):
        gagal.append("aplikasi/package.json: `engines.node` tidak ada — tidak ada iklan versi minimum sama sekali")
        return 1, ok, gagal
    m = POLA_ENGINES.match(engines.strip())
    if not m:
        gagal.append(
            f"aplikasi/package.json: `engines.node: \"{engines}\"` bukan bentuk `>=X` yang dikenal pemeriksa "
            "(tulis mis. `>=22.12.0` supaya bisa diperiksa mesin)"
        )
        return 1, ok, gagal
    diiklankan = versi(m.group(1))
    if diiklankan < butuh:
        gagal.append(
            f"aplikasi/package.json: iklan `engines.node: \"{engines}\"` ({teks_versi(diiklankan)}) "
            f"lebih rendah dari kebutuhan pustaka terkunci ({teks_versi(butuh)}) — pengguna bisa memasang "
            "versi yang tidak didukung"
        )
    else:
        ok.append(f"aplikasi/package.json: `engines.node: \"{engines}\"` >= kebutuhan")

    # (4) iklan di README harus sama
    baris_node = [b for b in readme.read_text(encoding="utf-8").splitlines() if "Node.js" in b]
    teks_min = f"{diiklankan[0]}.{diiklankan[1]}+" if diiklankan[1] else f"{diiklankan[0]}+"
    if not baris_node:
        gagal.append("aplikasi/README.md: tidak ada baris prasyarat `Node.js` — prasyarat hilang dari dokumen")
    elif not any(teks_min in b for b in baris_node):
        gagal.append(
            f"aplikasi/README.md: baris prasyarat Node TIDAK menyebut `{teks_min}` (batas yang diiklankan "
            f"package.json) — iklan dokumen dan mesin bisa berbeda arah. Barisnya: {baris_node[0].strip()!r}"
        )
    else:
        ok.append(f"aplikasi/README.md: prasyarat menyebut `{teks_min}` (sama dengan package.json)")

    # (5) alur GitHub
    alur = sorted((akar / ".github" / "workflows").glob("*.y*ml")) if (akar / ".github" / "workflows").is_dir() else []
    if not alur:
        gagal.append("tidak ada berkas alur `.github/workflows/*.yml` untuk diperiksa — pemeriksa tidak boleh buta")
    for berkas in alur:
        gagal.extend(periksa_node_version(berkas, butuh, akar))
    if alur and not any("node-version" in b.read_text(encoding="utf-8") for b in alur):
        gagal.append("tidak ada satu pun alur yang memasang Node — versi yang diuji di CI jadi tak terlihat")
    else:
        ok.append(f"alur GitHub ({len(alur)} berkas): semua `node-version` >= {teks_versi(butuh)}")

    # (6) lingkungan yang menjalankan pemeriksaan ini
    node_bin = shutil.which("node")
    if node_bin:
        try:
            keluaran = subprocess.run([node_bin, "--version"], capture_output=True, text=True, timeout=20).stdout
            nyata = versi(keluaran)
        except (subprocess.SubprocessError, ValueError):
            ok.append("catatan: versi Node lingkungan ini tidak terbaca — dilewati (bukan bukti keliru)")
        else:
            if nyata < butuh:
                gagal.append(
                    f"Node lingkungan ini {teks_versi(nyata)} < kebutuhan {teks_versi(butuh)} — "
                    "lingkungannya sendiri sudah di bawah dukungan yang diiklankan"
                )
            else:
                ok.append(f"Node lingkungan ini {teks_versi(nyata)} >= {teks_versi(butuh)}")
    else:
        ok.append("catatan: `node` tidak ada di PATH — pemeriksaan versi lingkungan dilewati")

    return (1 if gagal else 0), ok, gagal


def jalankan(akar: Path) -> int:
    kode, ok, gagal = periksa(akar)
    print("PERIKSA NODE (iklan versi minimum vs pustaka terkunci) — audit I F-21")
    for b in ok:
        print(f"  OK  {b}")
    for b in gagal:
        print(f"  X   {b}")
    print("-" * 70)
    if kode:
        print(f"HASIL: GAGAL — {len(gagal)} masalah. Versi Node yang diiklankan tidak boleh lebih rendah "
              "dari kebutuhan pustaka terkunci.")
    else:
        print(f"HASIL: LOLOS — {len(ok)} pemeriksaan; iklan Node selaras dengan pustaka terkunci "
              "(bukti bisa MENOLAK: jalankan dengan --uji-diri).")
    return kode


def _tulis(path: Path, isi: str) -> None:
    path.write_text(isi, encoding="utf-8")


def uji_diri() -> int:
    """Bukti pemeriksa ini bisa MENOLAK (dan tetap MENERIMA yang utuh)."""
    sys.path.insert(0, str(AKAR_REPO / "alat"))
    from bantu_uji_diri import laporkan, salin_pohon

    hasil: list[tuple[str, bool, str]] = []
    with salin_pohon() as tmp:
        kode, _, _ = periksa(tmp)
        hasil.append(("salinan utuh", kode == 0, f"kode {kode}"))
        if kode != 0:
            _, _, pesan = periksa(tmp)
            print("\n".join(pesan[:6]))

    def mutasi(nama: str, berkas: str, ubah) -> None:
        with salin_pohon() as tmp:
            f = tmp / berkas
            isi = f.read_text(encoding="utf-8")
            baru = ubah(isi)
            if baru == isi:
                hasil.append((nama, False, "mutasi TIDAK mengubah berkas (pola tidak ketemu)"))
                return
            _tulis(f, baru)
            kode, _, pesan = periksa(tmp)
            hasil.append((nama, kode != 0, "ditolak" if kode != 0 else "DILOLOSKAN (tumpul)"))
            if kode == 0:
                print("  ! lolos tanpa alasan:", pesan[:2])

    mutasi("mutasi: engines diturunkan ke `>=20` (iklan kembali berbohong)",
           "aplikasi/package.json",
           lambda s: s.replace('">=22.12.0"', '">=20"', 1))
    mutasi("mutasi: engines ditulis `^22.12.0` (bentuk tak dikenal, jangan menebak)",
           "aplikasi/package.json",
           lambda s: s.replace('">=22.12.0"', '"^22.12.0"', 1))
    mutasi("mutasi: README berhenti menyebut batas yang sama",
           "aplikasi/README.md",
           lambda s: s.replace("22.12+ (LTS 22)", "22+ (versi Node modern)", 1))
    mutasi("mutasi: pustaka terkunci menuntut Node lebih baru (vitest ^24)",
           "aplikasi/package-lock.json",
           lambda s: s.replace('"node": "^22.12.0 || ^24.0.0 || >=26.0.0"', '"node": "^24.0.0"', 1))
    with salin_pohon() as tmp:
        # Dihapus lewat JSON (bukan regex): entri lock ditulis multi-baris dan sebagian
        # punya kunci engine lain, sehingga penggantian teks bisa menyisakan sebagian.
        f = tmp / "aplikasi/package-lock.json"
        lock = json.loads(f.read_text(encoding="utf-8"))
        for nama, isi in lock.get("packages", {}).items():
            if nama != "":
                isi.pop("engines", None)
        _tulis(f, json.dumps(lock, indent=2))
        kode, _, _ = periksa(tmp)
        hasil.append(("mutasi: semua entri lock kehilangan `engines.node` (harus gagal-tertutup)",
                      kode != 0, "ditolak" if kode != 0 else "DILOLOSKAN (tumpul)"))
    mutasi("mutasi: alur CI memakai `node-version: '22'` (bisa 22.0.0)",
           ".github/workflows/ci.yml",
           lambda s: s.replace("node-version: '22.12.0'", "node-version: '22'", 1))
    mutasi("mutasi: alur lain memakai `node-version: '20'`",
           ".github/workflows/sebar-skema.yml",
           lambda s: s.replace("node-version: '22.12.0'", "node-version: '20'", 1))

    # Kontrol penting: entri OPSIONAL dengan syarat lebih ketat TIDAK boleh memerahkan pemeriksa.
    with salin_pohon() as tmp:
        f = tmp / "aplikasi/package-lock.json"
        lock = json.loads(f.read_text(encoding="utf-8"))
        lock["packages"]["node_modules/lzma-op-uji"] = {
            "version": "1.0.0", "optional": True, "engines": {"node": "^30.0.0"},
        }
        _tulis(f, json.dumps(lock, indent=2))
        kode, _, _ = periksa(tmp)
        hasil.append(("kontrol: entri OPSIONAL menuntut Node 30 → tetap diterima",
                      kode == 0, "diterima" if kode == 0 else "DITOLAK (terlalu ketat)"))

    return laporkan("periksa-node", hasil)


def main() -> int:
    if "--uji-diri" in sys.argv:
        return uji_diri()
    return jalankan(AKAR_REPO)


if __name__ == "__main__":
    raise SystemExit(main())
