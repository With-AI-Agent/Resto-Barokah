#!/usr/bin/env python3
"""periksa-kerapatan.py — penjaga KERAPATAN TAMPILAN (Nyaman/Padat).

Kenapa ada: pemilik melaporkan (2026-09-17) tombol **Nyaman/Padat** "diklik tapi
tidak ada efek apa-apa". Penyebabnya nyata: aturan kerapatan hanya menyasar kelas
prototipe (`kisi-menu`, `menu-kartu`) yang **tidak ada** di aplikasi — jadi tombolnya
mengubah atribut di elemen akar, tetapi tak satu pun komponen aplikasi bereaksi.
Itu kelas cacat "kontrol mati": tombolnya ada, uji lama lolos (hanya memeriksa tombol
DIRENDER), tetapi tak ada yang berubah bagi pemakai.

Pemeriksa ini mengunci efeknya secara terukur:
 1. Kedua kerapatan ada (nyaman & padat) dan tombolnya benar-benar terpasang di kode.
 2. Blok `[data-density="padat"]` mengubah token jarak `--s-*`, dan SEMUA nilainya
    lebih kecil dari nilai dasar (bukti numeric: kerapatan memadat, bukan hiasan).
 3. Setiap kelas yang disebut aturan kerapatan benar-benar dipakai di aplikasi
    (`src/**`) — tidak boleh ada penunjuk mati ke kelas prototipe.
 4. Minimal 3 kelas aplikasi bereaksi (kalau hanya 1, efeknya terlalu kecil untuk
    disebut "memadat").

Mode `--uji-diri`: salin repo, matikan/mutasi aturannya, pastikan pemeriksa MENOLAK.
"""
from __future__ import annotations

import pathlib
import re
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent.parent  # repo
APP = AKAR / "aplikasi"
CSS = APP / "src/gaya/token/tema.css"
# Sengaja HANYA kode TS/TSX (bukan CSS): pertanyaannya "apakah layar benar-benar
# memasang kelas ini?" — kalau CSS ikut dipindai, kelas mati akan lolos karena
# namanya muncul di berkas CSS itu sendiri (persis mutasi uji-diri #3).
SUMBER_APP = list((APP / "src").rglob("*.tsx")) + list((APP / "src").rglob("*.ts"))
SUMBER_PROTOTIPE = list((AKAR / "prototipe").rglob("*.html")) + list((AKAR / "prototipe").rglob("*.js"))

MIN_TOKEN_BERUBAH = 6
MIN_KELAS_APP = 3


def blok(css: str, pembuka: str) -> str | None:
    """Ambil isi blok `pembuka { ... }` (tanpa sarang)."""
    i = css.find(pembuka)
    if i < 0:
        return None
    j = css.find("{", i)
    k = css.find("}", j)
    if j < 0 or k < 0:
        return None
    return css[j + 1 : k]


def token_jarak(isi: str) -> dict[str, int]:
    hasil: dict[str, int] = {}
    for m in re.finditer(r"--s-(\d+)\s*:\s*(\d+)px", isi):
        hasil[f"--s-{m.group(1)}"] = int(m.group(2))
    return hasil


def dipakai_prototipe(kelas: str) -> bool:
    """Kelas yang dipakai halaman prototipe (katalog/tema) — boleh ada di CSS bersama."""
    pola = re.compile(rf"(?<![\w-]){re.escape(kelas)}(?![\w-])")
    for berkas in SUMBER_PROTOTIPE:
        if pola.search(berkas.read_text(encoding="utf-8", errors="ignore")):
            return True
    return False


def dipakai_aplikasi(kelas: str) -> bool:
    """Apakah kelas ini benar-benar muncul di sumber aplikasi (kata utuh)?

    Dicek ke seluruh berkas src (tsx/ts/css), bukan hanya atribut className, supaya
    kelas yang dipasang lewat komponen (mis. `card` di Kartu.tsx) tetap terhitung.
    """
    pola = re.compile(rf"(?<![\w-]){re.escape(kelas)}(?![\w-])")
    for berkas in SUMBER_APP:
        if pola.search(berkas.read_text(encoding="utf-8")):
            return True
    return False


def periksa(akar: pathlib.Path) -> int:
    css_path = akar / "aplikasi/src/gaya/token/tema.css"
    if not css_path.is_file():
        print("GAGAL: tema.css tidak ada")
        return 1
    css = css_path.read_text(encoding="utf-8")
    errs: list[str] = []

    # 1. kontrol terpasang
    layar = (akar / "aplikasi/src/layar/contoh/LayarContoh.tsx").read_text(encoding="utf-8")
    hook = akar / "aplikasi/src/hook/useTema.ts"
    if "gantiKerapatan" not in layar:
        errs.append("layar contoh tidak memanggil gantiKerapatan — tombol kerapatan tidak terpasang")
    if "KERAPATAN" not in layar:
        errs.append("layar contoh tidak membaca daftar KERAPATAN")
    if not hook.is_file() or "terapkanKerapatan" not in hook.read_text(encoding="utf-8"):
        errs.append("hook useTema tidak memanggil terapkanKerapatan — pilihan tidak pernah dipasang ke halaman")

    # 2. token jarak mengecil
    dasar = token_jarak(blok(css, ":root{") or "")
    padat = token_jarak(blok(css, '[data-density="padat"]{') or "")
    if not dasar:
        errs.append("token dasar (--s-1…--s-10) tidak ditemukan di :root")
    if not padat:
        errs.append('tidak ada token jarak yang diubah di blok [data-density="padat"]{…} — kerapatan tidak memadat')
    sama_atau_besar = [k for k, v in padat.items() if k in dasar and v >= dasar[k]]
    for k in sama_atau_besar:
        errs.append(f"token {k} pada mode padat TIDAK lebih kecil ({padat[k]}px vs dasar {dasar[k]}px)")
    kecil = {k: (dasar[k], v) for k, v in padat.items() if k in dasar and v < dasar[k]}
    if len(kecil) < MIN_TOKEN_BERUBAH:
        errs.append(f"hanya {len(kecil)} token jarak mengecil (minimum {MIN_TOKEN_BERUBAH}) — efek padat terlalu tipis")

    # 3. tidak ada penunjuk mati + minimal 3 kelas aplikasi bereaksi
    kelas_aturan: set[str] = set()
    for m in re.finditer(r'\[data-density="(nyaman|padat)"\]([^{]*)\{', css):
        kelas_aturan.update(re.findall(r"\.([a-zA-Z][\w-]*)", m.group(2)))
    kelas_app = sorted(k for k in kelas_aturan if dipakai_aplikasi(k))
    kelas_proto = sorted(k for k in kelas_aturan if k not in kelas_app and dipakai_prototipe(k))
    mati = sorted(k for k in kelas_aturan if k not in kelas_app and k not in kelas_proto)
    for k in mati:
        errs.append(f"aturan kerapatan menyasar kelas '{k}' yang tidak dipakai aplikasi MAUPUN prototipe — penunjuk mati")
    if len(kelas_app) < MIN_KELAS_APP:
        errs.append(
            f"hanya {len(kelas_app)} kelas APLIKASI yang bereaksi saat kerapatan diganti (minimum {MIN_KELAS_APP}) — "
            "kalau semua aturan hanya menyasar kelas prototipe, tombolnya terasa mati di aplikasi (cacat 2026-09-17)"
        )

    # ringkasan
    contoh = ", ".join(f"{k} {a}→{b}px" for k, (a, b) in list(sorted(kecil.items()))[:4])
    print(f"PERIKSA KERAPATAN — token berubah: {len(kecil)} ({contoh})")
    print(f"  kelas APLIKASI bereaksi: {len(kelas_app)} ({', '.join(kelas_app[:8])})")
    if kelas_proto:
        print(f"  kelas prototipe (boleh, halaman contoh): {', '.join(kelas_proto)}")
    if mati:
        print(f"  penunjuk mati: {', '.join(mati)}")
    if errs:
        print(f"\nHASIL: GAGAL — {len(errs)} temuan")
        for e in errs:
            print(f"  [X] {e}")
        return 1
    print("\nHASIL: LOLOS — kerapatan memadat secara terukur dan menyasar kelas yang benar-benar dipakai aplikasi.")
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

            with salin_pohon() as tmp2:
                f = tmp2 / "aplikasi/src/gaya/token/tema.css"
                isi = f.read_text(encoding="utf-8")
                isi = re.sub(r'\[data-density="padat"\]\{[^}]*\}', '[data-density="padat"]{}', isi, count=1)
                f.write_text(isi, encoding="utf-8")
                kode2, _ = jalankan_pemeriksa(periksa, tmp2)
                hasil.append(("mutasi: token jarak padat dihapus", kode2 != 0, "ditolak" if kode2 != 0 else "DILOLOSKAN (tumpul)"))

            with salin_pohon() as tmp3:
                f = tmp3 / "aplikasi/src/gaya/token/tema.css"
                isi = f.read_text(encoding="utf-8")
                isi = re.sub(r'\[data-density="padat"\]\{[^}]*\}',
                             '[data-density="padat"]{--s-5:20px;--s-4:16px;--s-3:12px;--s-2:8px;--s-6:24px;--s-7:32px;}', isi, count=1)
                f.write_text(isi, encoding="utf-8")
                kode3, _ = jalankan_pemeriksa(periksa, tmp3)
                hasil.append(("mutasi: token padat disamakan dengan dasar", kode3 != 0, "ditolak" if kode3 != 0 else "DILOLOSKAN (tumpul)"))

            with salin_pohon() as tmp4:
                # Mutasi 3: yang tersisa hanya aturan kelas prototipe → di aplikasi tombolnya mati lagi
                f = tmp4 / "aplikasi/src/gaya/token/tema.css"
                isi = f.read_text(encoding="utf-8")
                potong = "\n".join(
                    baris for baris in isi.splitlines()
                    if not (baris.startswith('[data-density="padat"] .')
                            and any(k in baris for k in ("card", "kisi-2", "table", "pemisah", "baris-tombol", "baris-rapat")))
                )
                f.write_text(potong, encoding="utf-8")
                kode4, _ = jalankan_pemeriksa(periksa, tmp4)
                hasil.append(("mutasi: hanya aturan prototipe yang tersisa (aplikasi mati)", kode4 != 0,
                              "ditolak" if kode4 != 0 else "DILOLOSKAN (tumpul)"))

            with salin_pohon() as tmp5:
                # Mutasi 4: kelas karangan yang tidak ada di mana pun
                f = tmp5 / "aplikasi/src/gaya/token/tema.css"
                isi = f.read_text(encoding="utf-8")
                f.write_text(isi + '\n[data-density="padat"] .kelas-karangan{display:none}\n', encoding="utf-8")
                kode5, _ = jalankan_pemeriksa(periksa, tmp5)
                hasil.append(("mutasi: aturan menyasar kelas karangan", kode5 != 0,
                              "ditolak" if kode5 != 0 else "DILOLOSKAN (tumpul)"))
        return laporkan("periksa-kerapatan", hasil)

    return periksa(AKAR)


if __name__ == "__main__":
    sys.exit(main())
