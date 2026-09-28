#!/usr/bin/env python3
"""periksa-antarmuka.py — penjaga CARA KERJA ANTARMUKA (penutupan panel & tepi gulir).

Kenapa ada: laporan pemilik 2026-09-17 (pesan ketiga) menyebut dua hal soal tampilan
yang **bukan selera**, melainkan kebiasaan baku aplikasi lain:

 1. Panel "Ganti tema" hanya bisa ditutup dengan mengklik tombolnya lagi — sebabnya
    panel memakai `<details>/<summary>` bawaan peramban, yang memang TIDAK menutup
    saat Esc ditekan (dan tidak tahu soal klik di luar). Yang benar: Esc menutup DAN
    mengembalikan fokus ke tombol, klik di luar menutup, fokus keluar menutup
    (WAI-ARIA APG pola *disclosure*).
 2. Ujung daftar yang bisa digeser "nabrak" tepi kotak — isinya terpotong mentah.
    Yang benar: maska pudar (`mask-image`) pada **elemen yang menggeser**, bukan pada
    wadah ber-bordir, dan pudarnya mengikuti posisi gulir.

Pemeriksa ini mengunci keduanya di **dua tempat sekaligus** (sumber desain
`prototipe/` dan aplikasi `aplikasi/src/`) supaya tidak bisa dipenuhi setengah-setengah:

 1. Salinan CSS aplikasi wajib IDENTIK dengan blok pemilih di sumber desain.
 2. Maska pudar wajib ada di `.picker-daftar` (penggeser), dan DILARANG di
    `.picker-panel` (wadah) — kalau di wadah, bordir/sudut panelnya yang luntur.
 3. Ada jalur cadangan untuk peramban tanpa `animation-timeline`.
 4. Empat jalan menutup ada di komponen aplikasi DAN di sumber desain.
 5. Id pemilih harus unik per pemilih (bukan id tetap yang kembar).
 6. Ada uji otomatis yang menegakkannya (komponen + kaskade CSS).
 7. **Ilmunya tersimpan sebagai kemampuan** (`skills/desain-antarmuka/SKILL.md`) dan
    benar-benar dipakai sesi berikutnya (`alat/mulai-sesi.py` mencantumkannya).
    Butir 7 ini jawaban untuk pesan pemilik: "jangan hanya disimpan, tapi juga harus
    digunakan sebagai kemampuan".

Mode `--uji-diri`: salin repo, rusak satu hal di salinan, pastikan pemeriksa MENOLAK.
"""
from __future__ import annotations

import pathlib
import re
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent.parent
APP = AKAR / "aplikasi"

TSX_PEMILIH = APP / "src/komponen/PemilihRingkas.tsx"
UJI_PEMILIH = APP / "src/komponen/PemilihRingkas.test.tsx"
TSX_LAYAR = APP / "src/layar/contoh/LayarContoh.tsx"
UJI_KASKADE = APP / "src/gaya/kerapatan-css.test.ts"
UI_JS = AKAR / "prototipe/js/ui.js"
CSS_SUMBER = AKAR / "prototipe/css/tokens.css"
CSS_APP = APP / "src/gaya/token/tema.css"
SKILL = AKAR / "skills/desain-antarmuka/SKILL.md"
MULAI_SESI = AKAR / "alat/mulai-sesi.py"

AWAL_BLOK = "/* Panel pilihan tema"
AKHIR_BLOK = ".swatch{"


def bagian_pemilih(css: str) -> str | None:
    """Ambil blok CSS pemilih (dari komentar pembuka sampai definisi `.swatch`)."""
    i = css.find(AWAL_BLOK)
    j = css.find(AKHIR_BLOK, i) if i >= 0 else -1
    if i < 0 or j < 0:
        return None
    teks = css[i:j]
    return "\n".join(baris.rstrip() for baris in teks.splitlines()).strip()


def blok(css: str, pembuka: str) -> str | None:
    """Isi blok `pembuka { ... }` (tanpa sarang)."""
    i = css.find(pembuka)
    if i < 0:
        return None
    j = css.find("{", i)
    k = css.find("}", j)
    if j < 0 or k < 0:
        return None
    return css[j + 1 : k]


def baca(p: pathlib.Path) -> str:
    return p.read_text(encoding="utf-8") if p.is_file() else ""


def periksa(akar: pathlib.Path) -> int:
    errs: list[str] = []
    catatan: list[str] = []

    # ---------------------------------------------------------------- berkas wajib
    wajib = {
        "komponen pemilih": akar / "aplikasi/src/komponen/PemilihRingkas.tsx",
        "uji komponen pemilih": akar / "aplikasi/src/komponen/PemilihRingkas.test.tsx",
        "sumber desain (ui.js)": akar / "prototipe/js/ui.js",
        "CSS sumber desain": akar / "prototipe/css/tokens.css",
        "CSS aplikasi": akar / "aplikasi/src/gaya/token/tema.css",
        "kemampuan desain": akar / "skills/desain-antarmuka/SKILL.md",
    }
    for nama, p in wajib.items():
        if not p.is_file():
            errs.append(f"{nama} TIDAK ADA: {p.relative_to(akar)}")

    tsx = baca(akar / "aplikasi/src/komponen/PemilihRingkas.tsx")
    uji = baca(akar / "aplikasi/src/komponen/PemilihRingkas.test.tsx")
    layar = baca(akar / "aplikasi/src/layar/contoh/LayarContoh.tsx")
    uji_kaskade = baca(akar / "aplikasi/src/gaya/kerapatan-css.test.ts")
    ui_js = baca(akar / "prototipe/js/ui.js")
    css_app = baca(akar / "aplikasi/src/gaya/token/tema.css")
    css_sumber = baca(akar / "prototipe/css/tokens.css")
    skill = baca(akar / "skills/desain-antarmuka/SKILL.md")

    # ------------------------------------------------- 1. salinan desain = aplikasi
    sumber_blok = bagian_pemilih(css_sumber)
    app_blok = bagian_pemilih(css_app)
    if sumber_blok is None:
        errs.append("blok pemilih tidak ditemukan di sumber desain prototipe/css/tokens.css")
    if app_blok is None:
        errs.append("blok pemilih tidak ditemukan di aplikasi/src/gaya/token/tema.css")
    if sumber_blok and app_blok and sumber_blok != app_blok:
        errs.append(
            "blok pemilih di aplikasi BERBEDA dari sumber desain (prototipe/css/tokens.css) — "
            "perbaikan wajib di sumber desain lalu disalin apa adanya"
        )
    if app_blok:
        catatan.append(f"blok pemilih: {len(app_blok.splitlines())} baris, salinan sumber desain identik")

    # ------------------------------------------------- 2. maska pudar di penggeser
    daftar = blok(css_app, ".picker-daftar{") or ""
    panel = blok(css_app, ".picker-panel{") or ""
    if not daftar:
        errs.append("`.picker-daftar` tidak ada di CSS aplikasi — daftar yang menggeser hilang")
    if not panel:
        errs.append("`.picker-panel` tidak ada di CSS aplikasi — wadah panel hilang")
    if "mask-image" not in daftar:
        errs.append("`.picker-daftar` tidak punya `mask-image` — ujung daftar akan terpotong mentah lagi (keluhan pemilik)")
    if "mask-image" in panel:
        errs.append("`mask-image` dipasang di `.picker-panel` (wadah) — bordir & sudut panelnya yang ikut luntur; maska harus di elemen penggeser")
    if "overflow:auto" not in daftar.replace(" ", ""):
        errs.append("`.picker-daftar` bukan elemen yang menggeser (tidak ada `overflow:auto`)")
    if "padding" not in daftar:
        errs.append("`.picker-daftar` tanpa bantalan — cincin fokus baris teratas/terbawah ikut terpotong maska")

    # ------------------------------------------------- 3. pudar mengikuti gulir + cadangan
    if "animation-timeline:scroll(self" not in css_app.replace(" ", ""):
        errs.append("pudar tidak mengikuti posisi gulir (`animation-timeline: scroll(self …)` hilang) — pudarnya akan 'berbohong'")
    if "@keyframes pudar-gulir" not in css_app:
        errs.append("`@keyframes pudar-gulir` hilang — pudarnya tidak pernah berubah mengikuti gulir")
    cadangan = re.search(r"@supports\s+not\s*\(animation-timeline[^{]*\{(.*?)\n\}", css_app, re.S)
    if not cadangan or "pudar-bawah" not in cadangan.group(1):
        errs.append("tidak ada jalur cadangan `@supports not (animation-timeline …)` — peramban lama (mis. Safari/Firefox versi tua) tidak dapat pudar sama sekali")
    if "--pudar-atas" not in css_app or "--pudar-bawah" not in css_app:
        errs.append("token `--pudar-atas`/`--pudar-bawah` hilang — arah pudarnya tidak bisa dikendalikan")

    # ------------------------------------------------- 4. empat jalan menutup (aplikasi)
    wajib_tsx = {
        "'Escape'": "Esc tidak ditangani di komponen aplikasi",
        "pointerdown": "klik di luar tidak ditangani (`pointerdown`)",
        "relatedTarget": "fokus pindah keluar panel tidak menutup (tanpa `relatedTarget`)",
        "aria-expanded": "`aria-expanded` tidak diumumkan",
        "aria-controls": "`aria-controls` tidak menunjuk panel",
        "aria-labelledby": "panel tidak diberi `aria-labelledby`",
        "useId": "id panel/tombol tidak unik per pemilih (`useId` hilang)",
        "focus()": "fokus tidak dikembalikan ke tombol",
    }
    for pola, pesan in wajib_tsx.items():
        if pola not in tsx:
            errs.append(f"komponen aplikasi: {pesan}")

    # ------------------------------------------------- 5. empat jalan menutup (sumber desain)
    wajib_js = {
        "function bukaPemilih": "sumber desain tidak punya bukaPemilih",
        "function tutupPemilih": "sumber desain tidak punya tutupPemilih",
        "tutupPemilih(p, true)": "sumber desain tidak mengembalikan fokus saat menutup",
        "e.key === 'Escape'": "sumber desain tidak menutup panel saat Esc",
        "contains(e.target)": "sumber desain tidak menutup panel saat klik di luar",
        "'focusout'": "sumber desain tidak menutup panel saat fokus keluar",
        "'panel-tema-' + urutan": "sumber desain memakai id panel tetap (kembar kalau ada dua pemilih)",
        "'tombol-tema-' + urutan": "sumber desain memakai id tombol tetap (aria-labelledby menunjuk elemen yang salah)",
    }
    for pola, pesan in wajib_js.items():
        if pola not in ui_js:
            errs.append(f"sumber desain (ui.js): {pesan}")
    if "closest('details')" in ui_js.split("INTERAKSI")[-1]:
        errs.append("sumber desain masih menyisakan aturan `<details>` lama di blok interaksi (penunjuk mati)")

    # ------------------------------------------------- 6. layar benar-benar memakai
    if "PemilihRingkas" not in layar:
        errs.append("layar contoh tidak memakai PemilihRingkas — perbaikan tidak sampai ke pemakai")
    if "<summary" in layar:
        errs.append("layar contoh masih memakai `<summary>` (bawaan peramban tidak menutup saat Esc)")

    # ------------------------------------------------- 7. uji otomatis yang menjaga
    uji_kecil = uji.lower()
    if "escape" not in uji_kecil or "pointerdown" not in uji_kecil:
        errs.append("uji komponen pemilih tidak menguji Esc/klik-luar — perilakunya bisa hilang tanpa ketahuan")
    if "mask-image" not in uji_kaskade or "pudar" not in uji_kaskade:
        errs.append("uji kaskade CSS tidak menjaga jejak pudar daftar")
    if "aria-expanded" not in uji:
        errs.append("uji komponen pemilih tidak memeriksa `aria-expanded`")

    # ------------------------------------------------- 8. kemampuan tersimpan & dipakai
    if skill:
        wajib_skill = {
            "Material": "pelajaran kerapatan (sumber Material) tidak tercatat",
            "APG": "pelajaran penutupan panel (sumber WAI-ARIA APG) tidak tercatat",
            "mask-image": "pelajaran tepi gulir (mask-image) tidak tercatat",
            "jangan hanya disimpan": "berkas kemampuan tidak menyebut mengapa ia ada (kutipan pemilik)",
            "digunakan": "berkas kemampuan tidak menyebut bahwa ilmunya wajib DIPAKAI",
        }
        for pola, pesan in wajib_skill.items():
            if pola not in skill:
                errs.append(f"skills/desain-antarmuka/SKILL.md: {pesan}")
        catatan.append(f"kemampuan desain tersimpan: {len(skill.splitlines())} baris")
    if "desain-antarmuka" not in baca(akar / "alat/mulai-sesi.py"):
        errs.append(
            "alat/mulai-sesi.py belum mencantumkan `desain-antarmuka` — ilmunya tersimpan tetapi TIDAK dipakai sesi berikutnya"
        )
    menunjuk = "skills/desain-antarmuka/SKILL.md"
    if menunjuk not in tsx and menunjuk not in css_app and menunjuk not in ui_js:
        errs.append("tidak ada satu pun berkas kode yang menunjuk ke skills/desain-antarmuka/SKILL.md — kemampuannya tidak terpakai")

    # ---------------------------------------------------------------- ringkasan
    print("PERIKSA ANTARMUKA — penutupan panel & tepi gulir")
    for c in catatan:
        print(f"  · {c}")
    print(f"  · jalan menutup: klik tombol · Esc (+fokus pulang) · klik di luar · fokus keluar · pilih lalu tutup")
    if errs:
        print(f"\nHASIL: GAGAL — {len(errs)} temuan")
        for e in errs:
            print(f"  [X] {e}")
        return 1
    print("\nHASIL: LOLOS — cara menutup panel & pudar tepi daftar terkunci di aplikasi DAN sumber desain.")
    return 0


def main() -> int:
    sys.path.insert(0, str(AKAR / "alat"))
    if "--uji-diri" in sys.argv:
        from bantu_uji_diri import jalankan_pemeriksa, laporkan, salin_pohon

        hasil = []
        with salin_pohon() as tmp:
            kode, keluar = jalankan_pemeriksa(periksa, tmp)
            hasil.append(("salinan utuh", kode == 0, f"kode {kode}"))
            if kode != 0:
                print(keluar[:1200])

        def mutasi(nama: str, berkas: str, ubah) -> None:
            with salin_pohon() as tmp:
                f = tmp / berkas
                isi = f.read_text(encoding="utf-8")
                baru = ubah(isi)
                if baru == isi:
                    hasil.append((nama, False, "mutasi TIDAK mengubah berkas (pola tidak ketemu)"))
                    return
                f.write_text(baru, encoding="utf-8")
                kode, _ = jalankan_pemeriksa(periksa, tmp)
                hasil.append((nama, kode != 0, "ditolak" if kode != 0 else "DILOLOSKAN (tumpul)"))

        mutasi("mutasi: Esc dihapus dari komponen aplikasi",
               "aplikasi/src/komponen/PemilihRingkas.tsx",
               lambda s: s.replace("e.key === 'Escape'", "e.key === 'F2'", 1))

        mutasi("mutasi: maska dipasang di WADAH (.picker-panel)",
               "aplikasi/src/gaya/token/tema.css",
               lambda s: s.replace(".picker-panel{position:fixed;",
                                   ".picker-panel{mask-image:linear-gradient(to bottom,transparent,#000);position:fixed;", 1)
               + "\n".join([]))

        mutasi("mutasi: klik di luar tidak lagi menutup (sumber desain)",
               "prototipe/js/ui.js",
               lambda s: s.replace("if (!p.contains(e.target)) tutupPemilih(p, false);",
                                   "void e.target;", 1))

        mutasi("mutasi: salinan CSS aplikasi menyimpang dari sumber desain",
               "aplikasi/src/gaya/token/tema.css",
               lambda s: s.replace("--pudar:16px;", "--pudar:24px;", 1))

        mutasi("mutasi: id pemilih kembali kembar (sumber desain)",
               "prototipe/js/ui.js",
               lambda s: s.replace("var idPanel = 'panel-tema-' + urutan;", "var idPanel = 'panel-tema';", 1))

        with salin_pohon() as tmp:
            f = tmp / "skills/desain-antarmuka/SKILL.md"
            f.unlink()
            kode, _ = jalankan_pemeriksa(periksa, tmp)
            hasil.append(("mutasi: kemampuan desain dihapus", kode != 0, "ditolak" if kode != 0 else "DILOLOSKAN (tumpul)"))

        mutasi("mutasi: kemampuan tidak lagi dipakai sesi berikutnya",
               "alat/mulai-sesi.py",
               # Ganti SEMUA kemunculan: kalau hanya yang pertama, komentar yang kena
               # dan daftar fase DESAIN tetap utuh -> mutasinya palsu (pernah kejadian).
               lambda s: s.replace("desain-antarmuka", "diubah-jadi-tidak-ada"))

        mutasi("mutasi: jalur cadangan peramban lama dibuang",
               "aplikasi/src/gaya/token/tema.css",
               lambda s: s.replace("@supports not (animation-timeline: scroll(self block)){", "@supports not (animation-timeline: scroll(self inline)){", 1))

        # Mutasi lintas-berkas: SEMUA penunjuk ke berkas kemampuan dihapus. Kalau hanya satu
        # berkas, pemeriksa memang seharusnya tetap lolos (penunjuk lain masih ada) — itu
        # bukan tumpul, itu benar. Jadi yang diuji: keadaan "tidak ada satu pun penunjuk".
        with salin_pohon() as tmp:
            for rel in ("prototipe/css/tokens.css", "aplikasi/src/gaya/token/tema.css",
                        "aplikasi/src/komponen/PemilihRingkas.tsx", "prototipe/js/ui.js"):
                f = tmp / rel
                f.write_text(f.read_text(encoding="utf-8").replace("skills/desain-antarmuka/SKILL.md", "catatan"),
                             encoding="utf-8")
            kode, _ = jalankan_pemeriksa(periksa, tmp)
            hasil.append(("mutasi: semua penunjuk ke kemampuan dihapus dari kode", kode != 0,
                          "ditolak" if kode != 0 else "DILOLOSKAN (tumpul)"))

        return laporkan("periksa-antarmuka", hasil)

    return periksa(AKAR)


if __name__ == "__main__":
    sys.exit(main())
