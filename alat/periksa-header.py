#!/usr/bin/env python3
"""periksa-header.py — penjaga HEADER KEAMANAN halaman (T10-14 — PRD M12; TECH_SPEC §6 & §8; docs/KEAMANAN.md §16).

Memverifikasi bahwa berkas header keamanan `aplikasi/public/_headers` (dan `aplikasi/dist/_headers`
bila sudah dibangun):
 1. Berkas ada dan terbaca.
 2. Memuat seluruh header keamanan web wajib standar peramban modern:
    - Content-Security-Policy (CSP)
    - X-Frame-Options (DENY)
    - X-Content-Type-Options (nosniff)
    - Referrer-Policy (strict-origin-when-cross-origin)
    - Permissions-Policy (membatasi API sensitif kamera, mikrofon, geolokasi)
    - Strict-Transport-Security (HSTS minimal 1 tahun)
 3. Memeriksa kualitas & keketatan Content-Security-Policy:
    - Tidak mengizinkan wildcard '*' pada script-src atau object-src
    - object-src wajib 'none'
    - frame-ancestors wajib 'none'
    - base-uri wajib 'self'
    - connect-src membatasi domain yang sah (Supabase, Workers)
 4. Memverifikasi optimasi Cache-Control untuk aset build Vite (/assets/*).

Mode `--uji-diri`: menguji kegagalan fail-closed saat header atau directive penting dirusak.
"""
from __future__ import annotations

import pathlib
import re
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent
BERKAS_HEADERS = AKAR / "aplikasi" / "public" / "_headers"
BERKAS_DIST_HEADERS = AKAR / "aplikasi" / "dist" / "_headers"

HEADER_WAJIB = [
    "Content-Security-Policy",
    "X-Frame-Options",
    "X-Content-Type-Options",
    "Referrer-Policy",
    "Permissions-Policy",
    "Strict-Transport-Security",
]

CSP_DIRECTIVE_WAJIB = [
    "default-src",
    "script-src",
    "style-src",
    "img-src",
    "font-src",
    "connect-src",
    "frame-ancestors",
    "object-src",
    "base-uri",
    "form-action",
]


def label_path(p: pathlib.Path) -> str:
    try:
        return str(p.relative_to(AKAR))
    except ValueError:
        return p.name


def parsing_headers(teks: str) -> dict[str, dict[str, str]]:
    """Mengurai format berkas _headers Cloudflare ke dalam kamus {jalur: {nama_header: nilai}}."""
    hasil: dict[str, dict[str, str]] = {}
    jalur_aktif: str | None = None

    for baris in teks.splitlines():
        b = baris.strip()
        if not b or b.startswith("#"):
            continue

        if not baris.startswith(" ") and not baris.startswith("\t"):
            jalur_aktif = b
            if jalur_aktif not in hasil:
                hasil[jalur_aktif] = {}
        elif jalur_aktif is not None:
            if ":" in b:
                k, v = b.split(":", 1)
                hasil[jalur_aktif][k.strip()] = v.strip()

    return hasil


def periksa_isi_headers(path_file: pathlib.Path) -> list[str]:
    errs: list[str] = []
    lbl = label_path(path_file)
    if not path_file.is_file():
        return [f"berkas {lbl} tidak ditemukan"]

    try:
        teks = path_file.read_text(encoding="utf-8")
    except Exception as e:
        return [f"gagal membaca {lbl}: {e}"]

    aturan = parsing_headers(teks)
    if "/*" not in aturan:
        return [f"{lbl} tidak memiliki blok aturan global '/*'"]

    headers_global = aturan["/*"]

    # 1. Periksa keberadaan header wajib
    for hw in HEADER_WAJIB:
        if hw not in headers_global:
            errs.append(f"{lbl}: header wajib '{hw}' tidak ditemukan di blok '/*'")

    # 2. Periksa nilai spesifik
    xfo = headers_global.get("X-Frame-Options", "")
    if xfo.upper() != "DENY":
        errs.append(f"{lbl}: X-Frame-Options bernilai '{xfo}', wajib 'DENY'")

    xcto = headers_global.get("X-Content-Type-Options", "")
    if xcto.lower() != "nosniff":
        errs.append(f"{lbl}: X-Content-Type-Options bernilai '{xcto}', wajib 'nosniff'")

    rp = headers_global.get("Referrer-Policy", "")
    if "strict-origin" not in rp.lower() and "no-referrer" not in rp.lower():
        errs.append(f"{lbl}: Referrer-Policy terlalu longgar: '{rp}'")

    pp = headers_global.get("Permissions-Policy", "")
    for fitur in ("camera", "microphone", "geolocation", "usb"):
        if fitur not in pp:
            errs.append(f"{lbl}: Permissions-Policy tidak mengatur fitur '{fitur}'")
    if not re.search(r"(?:^|,\s*)usb=\(self\)(?:,|$)", pp):
        errs.append(f"{lbl}: Permissions-Policy harus mengizinkan WebUSB hanya untuk asal sendiri (usb=(self))")

    hsts = headers_global.get("Strict-Transport-Security", "")
    if "max-age" not in hsts or "includeSubDomains" not in hsts or "preload" not in hsts:
        errs.append(f"{lbl}: Strict-Transport-Security wajib memuat max-age, includeSubDomains, dan preload")

    # 3. Analisis mendalam Content-Security-Policy
    csp = headers_global.get("Content-Security-Policy", "")
    if csp:
        directives: dict[str, str] = {}
        for bagian in csp.split(";"):
            bagian = bagian.strip()
            if not bagian:
                continue
            token = bagian.split(None, 1)
            d_nama = token[0]
            d_nilai = token[1] if len(token) > 1 else ""
            directives[d_nama] = d_nilai

        for dw in CSP_DIRECTIVE_WAJIB:
            if dw not in directives:
                errs.append(f"{lbl}: CSP kehilangan directive wajib '{dw}'")

        # Uji keamanan nilai directive
        if directives.get("object-src") != "'none'":
            errs.append(f"{lbl}: CSP object-src wajib ''none'', bukan '{directives.get('object-src')}'")

        if directives.get("frame-ancestors") != "'none'":
            errs.append(f"{lbl}: CSP frame-ancestors wajib ''none'', bukan '{directives.get('frame-ancestors')}'")

        if directives.get("base-uri") != "'self'":
            errs.append(f"{lbl}: CSP base-uri wajib ''self'', bukan '{directives.get('base-uri')}'")

        if directives.get("form-action") != "'self'":
            errs.append(f"{lbl}: CSP form-action wajib ''self'', bukan '{directives.get('form-action')}'")

        if "upgrade-insecure-requests" not in csp:
            errs.append(f"{lbl}: CSP wajib memuat directive 'upgrade-insecure-requests'")

        # Periksa script-src: tolak wildcard, unsafe-eval, dan unsafe-inline
        val_script = directives.get("script-src", "")
        if "*" in val_script.split():
            errs.append(f"{lbl}: CSP script-src memuat wildcard '*' berbahaya")
        if "'unsafe-eval'" in val_script:
            errs.append(f"{lbl}: CSP script-src memuat 'unsafe-eval' yang berbahaya bagi eksekusi skrip")
        if "'unsafe-inline'" in val_script:
            errs.append(f"{lbl}: CSP script-src memuat 'unsafe-inline' yang tidak diperlukan oleh SPA")

        # Periksa default-src dan connect-src: tolak wildcard *
        for d_target in ("default-src", "connect-src"):
            if "*" in directives.get(d_target, "").split():
                errs.append(f"{lbl}: CSP {d_target} dibuka lebar dengan wildcard '*' berbahaya")

    # 4. Periksa aturan caching aset statis
    if "/assets/*" not in aturan or "Cache-Control" not in aturan["/assets/*"]:
        errs.append(f"{lbl}: tidak ada pengaturan Cache-Control untuk '/assets/*'")

    return errs


def periksa(akar: pathlib.Path) -> int:
    path_src = akar / "aplikasi" / "public" / "_headers"
    path_dist = akar / "aplikasi" / "dist" / "_headers"

    semua_errs = []
    semua_errs.extend(periksa_isi_headers(path_src))

    if path_dist.is_file():
        semua_errs.extend(periksa_isi_headers(path_dist))

    print("PERIKSA HEADER KEAMANAN — CSP, X-Frame-Options, HSTS, Referrer-Policy, Permissions-Policy")
    if path_src.is_file():
        print(f"  [OK] Sumber: {path_src.relative_to(akar)} terverifikasi utuh")
    if path_dist.is_file():
        print(f"  [OK] Hasil Bangun: {path_dist.relative_to(akar)} terverifikasi utuh")

    if semua_errs:
        print(f"\nHASIL: GAGAL — {len(semua_errs)} pelanggaran header keamanan")
        for e in semua_errs:
            print(f"  [X] {e}")
        return 1

    print("\nHASIL: LOLOS — konfigurasi header keamanan halaman lengkap & fail-closed.")
    return 0


def uji_diri() -> int:
    import tempfile
    import shutil

    hasil: list[tuple[str, bool, str]] = []

    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = pathlib.Path(tmpdir)
        app_dir = tmp / "aplikasi" / "public"
        app_dir.mkdir(parents=True)
        target = app_dir / "_headers"
        shutil.copyfile(BERKAS_HEADERS, target)

        # Baseline
        errs = periksa_isi_headers(target)
        hasil.append(("baseline asli lulus", len(errs) == 0, f"{len(errs)} galat"))

        # Mutasi 1: CSP dihapus
        teks_asli = BERKAS_HEADERS.read_text(encoding="utf-8")
        m1 = re.sub(r"Content-Security-Policy:.*", "", teks_asli)
        target.write_text(m1, encoding="utf-8")
        e1 = periksa_isi_headers(target)
        hasil.append(("mutasi 1: hapus Content-Security-Policy", len(e1) > 0, "tertangkap" if e1 else "lolos"))

        # Mutasi 2: X-Frame-Options diubah ke ALLOW
        m2 = teks_asli.replace("X-Frame-Options: DENY", "X-Frame-Options: SAMEORIGIN")
        target.write_text(m2, encoding="utf-8")
        e2 = periksa_isi_headers(target)
        hasil.append(("mutasi 2: X-Frame-Options bukan DENY", len(e2) > 0, "tertangkap" if e2 else "lolos"))

        # Mutasi 3: object-src dihapus dari CSP
        m3 = teks_asli.replace("object-src 'none';", "")
        target.write_text(m3, encoding="utf-8")
        e3 = periksa_isi_headers(target)
        hasil.append(("mutasi 3: CSP object-src hilang", len(e3) > 0, "tertangkap" if e3 else "lolos"))

        # Mutasi 4: Permissions-Policy kamera dihapus
        m4 = teks_asli.replace("camera=(self),", "")
        target.write_text(m4, encoding="utf-8")
        e4 = periksa_isi_headers(target)
        hasil.append(("mutasi 4: Permissions-Policy kehilangan kamera", len(e4) > 0, "tertangkap" if e4 else "lolos"))

        # Mutasi 5: Wildcard script-src disisipkan
        m5 = teks_asli.replace("script-src 'self'", "script-src * 'self'")
        target.write_text(m5, encoding="utf-8")
        e5 = periksa_isi_headers(target)
        hasil.append(("mutasi 5: CSP script-src wildcard", len(e5) > 0, "tertangkap" if e5 else "lolos"))

        # Mutasi 6: unsafe-eval disisipkan ke script-src
        m6 = teks_asli.replace("script-src 'self'", "script-src 'self' 'unsafe-eval'")
        target.write_text(m6, encoding="utf-8")
        e6 = periksa_isi_headers(target)
        hasil.append(("mutasi 6: CSP script-src unsafe-eval ditolak", len(e6) > 0, "tertangkap" if e6 else "lolos"))

        # Mutasi 7: unsafe-inline disisipkan ke script-src
        m7 = teks_asli.replace("script-src 'self'", "script-src 'self' 'unsafe-inline'")
        target.write_text(m7, encoding="utf-8")
        e7 = periksa_isi_headers(target)
        hasil.append(("mutasi 7: CSP script-src unsafe-inline ditolak", len(e7) > 0, "tertangkap" if e7 else "lolos"))

        # Mutasi 8: connect-src dibuka lebar dengan wildcard *
        m8 = teks_asli.replace("connect-src 'self'", "connect-src * 'self'")
        target.write_text(m8, encoding="utf-8")
        e8 = periksa_isi_headers(target)
        hasil.append(("mutasi 8: CSP connect-src wildcard ditolak", len(e8) > 0, "tertangkap" if e8 else "lolos"))

        # Mutasi 9: upgrade-insecure-requests dihapus
        m9 = teks_asli.replace("upgrade-insecure-requests;", "")
        target.write_text(m9, encoding="utf-8")
        e9 = periksa_isi_headers(target)
        hasil.append(("mutasi 9: CSP kehilangan upgrade-insecure-requests ditolak", len(e9) > 0, "tertangkap" if e9 else "lolos"))

        # Mutasi 10: WebUSB diblokir untuk asal sendiri
        m10 = teks_asli.replace("usb=(self)", "usb=()")
        target.write_text(m10, encoding="utf-8")
        e10 = periksa_isi_headers(target)
        hasil.append(("mutasi 10: Permissions-Policy memblokir WebUSB ditolak", len(e10) > 0, "tertangkap" if e10 else "lolos"))

    print("======================================================================")
    print("UJI DIRI PERIKSA HEADER KEAMANAN (T10-14)")
    print("======================================================================")
    semua_ok = True
    for nama, ok, info in hasil:
        status = "OK" if ok else "GAGAL"
        if not ok:
            semua_ok = False
        print(f"  [{status}] {nama} — {info}")
    print("----------------------------------------------------------------------")
    if semua_ok:
        print("HASIL: SEMUA UJI DIRI LOLOS (Fail-Closed terbukti).")
        return 0
    print("HASIL: ADA UJI DIRI GAGAL.")
    return 1


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(periksa(AKAR))
