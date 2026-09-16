#!/usr/bin/env python3
"""Pemeriksa struktur aplikasi (Fase 0).

Sumber kebenaran: `docs/TECH_SPEC.md` bagian "## 3. Struktur Folder".
Skrip ini membaca pohon folder dari dokumen itu (bukan daftar hardcode),
lalu membuktikan bahwa repo aplikasi benar-benar mengikuti bentuk tersebut.

Catatan penting (jangan dihapus tanpa alasan):
  * Uji "token sama persis dengan prototipe" berlaku selama Fase 0.
    Kalau suatu fase nanti memang mengubah token, uji itu wajib dibarengi
    catatan di docs/DECISIONS_LOG.md dan penyesuaian di sini.
  * Skrip ini TIDAK boleh dilemahkan tanpa catatan keputusan pemilik.

Jalankan:  python3 aplikasi/alat/periksa-struktur.py
Keluaran :  baris [OK]/[INFO]/[GAGAL], ringkasan di akhir.
Keluar 1 :  kalau ada minimal satu GAGAL.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

AKAR_REPO = Path(__file__).resolve().parents[2]
APLIKASI = AKAR_REPO / "aplikasi"
TECH_SPEC = AKAR_REPO / "docs" / "TECH_SPEC.md"
TOKEN_APP = APLIKASI / "src" / "gaya" / "token" / "tema.css"
TOKEN_PROTO = AKAR_REPO / "prototipe" / "css" / "tokens.css"

ok: list[str] = []
info: list[str] = []
gagal: list[str] = []


def catat(daftar: list[str], judul: str, pesan: str) -> None:
    daftar.append(f"{judul}: {pesan}")


# --------------------------------------------------------------------------
# 1. Baca pohon folder dari TECH_SPEC bagian 3
# --------------------------------------------------------------------------
def pohon_dari_tech_spec() -> list[tuple[int, str, bool]]:
    """Ambil daftar (indentasi, path relatif, apakah_folder) dari blok kode §3."""
    teks = TECH_SPEC.read_text(encoding="utf-8")
    cocok = re.search(r"^##\s*3\.\s*Struktur Folder\s*$", teks, re.M)
    if not cocok:
        raise SystemExit("GAGAL: bagian '## 3. Struktur Folder' tidak ada di docs/TECH_SPEC.md")
    sisa = teks[cocok.end() :]
    blok = re.search(r"```\n(.*?)```", sisa, re.S)
    if not blok:
        raise SystemExit("GAGAL: blok kode pohon folder tidak ditemukan setelah judul bagian 3")

    baris: list[tuple[int, str, bool]] = []
    for mentah in blok.group(1).splitlines():
        if not mentah.strip():
            continue
        tanpa_komentar = mentah.split("←")[0].rstrip()
        if not tanpa_komentar.strip():
            continue
        indentasi = len(tanpa_komentar) - len(tanpa_komentar.lstrip(" "))
        potongan = tanpa_komentar.strip()
        if potongan.startswith("/"):
            potongan = potongan[1:]
        # satu baris boleh memuat beberapa nama: "/kasir  /dapur  /laporan"
        for nama in re.split(r"\s+(?=/)", potongan):
            nama = nama.strip().lstrip("/").rstrip("/")
            if not nama:
                continue
            # folder = nama tanpa titik (mis. "public", "token"), berkas = ada titik (mis. "sw.js")
            folder = "." not in Path(nama).name
            baris.append((indentasi, nama, folder))
    return baris


def jelaskan_baris(baris: list[tuple[int, str, bool]]) -> list[tuple[str, bool]]:
    """Ubah (indentasi, nama, folder) menjadi (path relatif penuh, folder)."""
    hasil: list[tuple[str, bool]] = []
    tumpukan: list[tuple[int, str]] = []
    for indentasi, nama, folder in baris:
        while tumpukan and tumpukan[-1][0] >= indentasi:
            tumpukan.pop()
        path = "/".join([p for _, p in tumpukan] + [nama])
        tumpukan.append((indentasi, nama))
        hasil.append((path, folder))
    return hasil


# --------------------------------------------------------------------------
# 2. Uji struktur
# --------------------------------------------------------------------------
def uji_pohon(pohon: list[tuple[str, bool]]) -> None:
    for path, folder in pohon:
        target = AKAR_REPO / path
        if "*" in path:
            induk, pola = path.rsplit("/", 1)
            berkas = (
                [b for b in (AKAR_REPO / induk).glob(pola) if not b.name.startswith(".")]
                if (AKAR_REPO / induk).is_dir()
                else []
            )
            if berkas:
                catat(ok, "OK", f"{path} terisi ({len(berkas)} berkas)")
            elif (AKAR_REPO / induk).is_dir():
                catat(info, "INFO", f"{path} belum diisi (isi menyusul sesuai fase)")
            else:
                catat(gagal, "GAGAL", f"folder {induk} tidak ada, jadi {path} mustahil ada")
            continue
        if folder and not target.is_dir():
            catat(gagal, "GAGAL", f"folder wajib hilang: {path}")
        elif not folder and not target.exists():
            catat(info, "INFO", f"berkas rencana belum dibuat: {path}")

    # Folder di dalam aplikasi/src/layar harus bernama sesuai TECH_SPEC (tidak di-rename)
    layar_spec = {
        p.split("/")[-1] for p, f in pohon if f and p.startswith("aplikasi/src/layar/") and "/" not in p.split("aplikasi/src/layar/")[1]
    }
    layar_disk = {d.name for d in (APLIKASI / "src" / "layar").iterdir() if d.is_dir()} if (
        APLIKASI / "src" / "layar"
    ).is_dir() else set()
    kurang = layar_spec - layar_disk
    if kurang:
        catat(gagal, "GAGAL", f"layar wajib belum ada: {sorted(kurang)}")
    else:
        catat(ok, "OK", f"seluruh {len(layar_spec)} folder layar wajib ada")
    tambahan = layar_disk - layar_spec
    if tambahan:
        catat(info, "INFO", f"layar tambahan (bukan pelanggaran): {sorted(tambahan)}")


def uji_token() -> None:
    if not TOKEN_APP.exists():
        catat(gagal, "GAGAL", "token aplikasi tidak ada: aplikasi/src/gaya/token/tema.css")
        return
    teks = TOKEN_APP.read_text(encoding="utf-8")

    # a. 10 tema
    tema = re.findall(r'\[data-theme="([^"]+)"\]', teks)
    unik = sorted(set(tema))
    if len(unik) == 10:
        catat(ok, "OK", f"10 tema ada: {', '.join(unik)}")
    else:
        catat(gagal, "GAGAL", f"jumlah tema {len(unik)} (wajib 10): {', '.join(unik)}")

    # b. sama persis dengan prototipe (bukti 'dipindah apa adanya')
    if TOKEN_PROTO.exists():
        if TOKEN_PROTO.read_text(encoding="utf-8") == teks:
            catat(ok, "OK", "token aplikasi identik dengan prototipe/css/tokens.css")
        else:
            catat(
                gagal,
                "GAGAL",
                "token aplikasi BERBEDA dari prototipe/css/tokens.css (Fase 0 wajib salinan apa adanya)",
            )
    else:
        catat(info, "INFO", "prototipe/css/tokens.css tidak ada; uji kesamaan dilewati")

    # c. setiap huruf yang dirujuk benar-benar ada di disk
    #    url(data:...) bisa memuat url(%23n) di dalamnya -> buang dulu seluruh data URI
    teks_tanpa_data_uri = re.sub(r"url\(\s*['\"]?data:[^)]*\)", "", teks)
    hilang = []
    for rujukan in re.findall(r"url\(['\"]?([^'\")]+)['\"]?\)", teks_tanpa_data_uri):
        if rujukan.startswith(("http", "data:")):
            continue
        if not (TOKEN_APP.parent / rujukan).resolve().exists():
            hilang.append(rujukan)
    if hilang:
        catat(gagal, "GAGAL", f"berkas huruf/aset hilang: {sorted(set(hilang))}")
    else:
        jumlah = len(list((APLIKASI / "src" / "gaya" / "aset" / "font").glob("*.woff2")))
        catat(ok, "OK", f"semua rujukan huruf di tema.css ada di disk ({jumlah} berkas woff2)")


def uji_berkas_dasar() -> None:
    pkg = APLIKASI / "package.json"
    if not pkg.exists():
        catat(gagal, "GAGAL", "aplikasi/package.json tidak ada")
        return
    isi = json.loads(pkg.read_text(encoding="utf-8"))
    wajib = ["dev", "build", "lint", "typecheck", "test", "format:check"]
    kurang = [n for n in wajib if n not in isi.get("scripts", {})]
    if kurang:
        catat(gagal, "GAGAL", f"skrip npm wajib belum ada: {kurang}")
    else:
        catat(ok, "OK", f"skrip npm wajib lengkap: {', '.join(wajib)}")

    tsc = isi.get("scripts", {}).get("typecheck", "")
    if "tsc -b" not in tsc:
        catat(gagal, "GAGAL", "skrip typecheck harus memakai 'tsc -b' (kalau hanya 'tsc --noEmit', tidak ada yang diperiksa)")
    else:
        catat(ok, "OK", "typecheck memakai mode proyek (tsc -b) sehingga benar-benar memeriksa")

    html = APLIKASI / "index.html"
    if not html.exists():
        catat(gagal, "GAGAL", "aplikasi/index.html tidak ada")
        return
    teks = html.read_text(encoding="utf-8")
    for wajib_teks, judul in [
        ('lang="id"', "bahasa halaman di-set Indonesia"),
        ("viewport", "meta viewport ada"),
        ("theme-color", "meta theme-color ada"),
    ]:
        if wajib_teks in teks:
            catat(ok, "OK", judul)
        else:
            catat(gagal, "GAGAL", f"index.html: {judul} tidak ditemukan")
    fav = re.search(r'rel="icon"[^>]*href="([^"]+)"', teks)
    if fav and (APLIKASI / "public" / fav.group(1).lstrip("/")).exists():
        catat(ok, "OK", f"favicon ada: {fav.group(1)}")
    else:
        catat(gagal, "GAGAL", "favicon dirujuk index.html tetapi tidak ada di public/")

    for wajib_folder in ["src/komponen", "src/lib", "src/hook", "src/gaya/token"]:
        if (APLIKASI / wajib_folder).is_dir():
            catat(ok, "OK", f"{wajib_folder} ada")
        else:
            catat(gagal, "GAGAL", f"{wajib_folder} tidak ada")


def uji_warna_dan_tema() -> None:
    """Tidak ada warna mentah di luar berkas token + tema aplikasi = tema rancangan."""
    berkas_uji = []
    for pola in ("*.ts", "*.tsx", "*.css"):
        berkas_uji += [
            b
            for b in (APLIKASI / "src").rglob(pola)
            if "gaya/token" not in b.as_posix() and "gaya/aset" not in b.as_posix()
        ]
    pola_warna = re.compile(r"#[0-9a-fA-F]{3,8}\b|\brgba?\(|\bhsla?\(")
    pelanggar = []
    for berkas in berkas_uji:
        for nomor, baris in enumerate(berkas.read_text(encoding="utf-8").splitlines(), 1):
            if pola_warna.search(baris):
                pelanggar.append(f"{berkas.relative_to(AKAR_REPO)}:{nomor}")
    if pelanggar:
        catat(gagal, "GAGAL", f"warna mentah di luar token: {pelanggar[:6]}")
    else:
        catat(ok, "OK", f"tanpa warna mentah di luar token ({len(berkas_uji)} berkas diperiksa)")

    # index.html tidak boleh menyimpan warna langsung
    html = (APLIKASI / "index.html").read_text(encoding="utf-8")
    if pola_warna.search(html):
        catat(gagal, "GAGAL", "index.html memuat warna mentah; warna harus dari token tema")
    elif '<meta name="theme-color"' in html:
        catat(ok, "OK", "index.html tanpa warna mentah + ada meta theme-color (diisi dari token)")
    else:
        catat(gagal, "GAGAL", "meta theme-color tidak ada di index.html")

    # kode tema di lib/tema.ts harus sama dengan kode tema di token
    berkas_tema = APLIKASI / "src" / "lib" / "tema.ts"
    if not berkas_tema.exists():
        catat(gagal, "GAGAL", "src/lib/tema.ts tidak ada (pemilih tema hilang)")
        return
    isi_tema_ts = berkas_tema.read_text(encoding="utf-8")
    blok_tema = isi_tema_ts.split("export const TEMA")[1].split("export const KERAPATAN")[0]
    kode_ts = set(re.findall(r"kode:\s*'([a-z-]+)'", blok_tema))
    kode_css = set(re.findall(r'\[data-theme="([a-z-]+)"\]', TOKEN_APP.read_text(encoding="utf-8")))
    kurang = kode_css - kode_ts
    lebih = kode_ts - kode_css
    if not kurang and not lebih:
        catat(ok, "OK", f"kode tema aplikasi sama dengan token ({len(kode_css)} tema)")
    else:
        catat(
            gagal,
            "GAGAL",
            f"kode tema tidak sinkron — hanya di token: {sorted(kurang)}; hanya di aplikasi: {sorted(lebih)}",
        )

    kerapatan_css = set(re.findall(r'\[data-density="([a-z-]+)"\]', TOKEN_APP.read_text(encoding="utf-8")))
    blok_kerapatan = isi_tema_ts.split("export const KERAPATAN")[1].split("export const")[0]
    kerapatan_ts = set(re.findall(r"kode:\s*'(nyaman|padat)'", blok_kerapatan))
    if "padat" in kerapatan_css and kerapatan_ts >= {"nyaman", "padat"}:
        catat(ok, "OK", "kerapatan tampilan (nyaman & padat) tersambung ke token")
    else:
        catat(gagal, "GAGAL", "kerapatan tampilan tidak lengkap antara token dan aplikasi")


def uji_berkas_gaya() -> None:
    for wajib in ["src/gaya/token/tema.css", "src/gaya/token/dasar.css", "src/gaya/komponen.css"]:
        if (APLIKASI / wajib).exists():
            catat(ok, "OK", f"{wajib} ada")
        else:
            catat(gagal, "GAGAL", f"{wajib} tidak ada")


def main() -> int:
    pohon = jelaskan_baris(pohon_dari_tech_spec())
    uji_pohon(pohon)
    uji_token()
    uji_berkas_dasar()
    uji_berkas_gaya()
    uji_warna_dan_tema()

    for baris in ok:
        print(baris)
    for baris in info:
        print(baris)
    for baris in gagal:
        print(baris)
    print("-" * 60)
    print(f"struktur aplikasi: {len(ok)} OK · {len(info)} INFO · {len(gagal)} GAGAL")
    print("KEPUTUSAN:", "LOLOS" if not gagal else "GAGAL")
    return 1 if gagal else 0


if __name__ == "__main__":
    sys.exit(main())
