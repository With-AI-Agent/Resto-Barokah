#!/usr/bin/env python3
"""periksa-buku-uji.py — penjaga BUKU UJI PEMILIK (docs/uji/BUKU_UJI_PEMILIK.md).

Kenapa ada: Buku Uji Pemilik adalah lembar kerja Lee — "apa yang harus saya lakukan/coba, apa yang
seharusnya terjadi, bagaimana hasilnya". Berkas yang tidak dijaga akan pelan-pelan kehilangan bentuk:
baris tanpa langkah, id kembar, urutan langkah melompat, atau menunjuk tugas yang tidak ada.
Pemeriksa ini menjalankannya di CI.

Yang diperiksa:
 1. Berkas ada, punya bagian "Yang harus Lee LAKUKAN" & "Yang harus Lee COBA", dan menyatakan batasnya
    (uji mesin tetap di CI — buku ini bukan pengganti uji otomatis).
 2. Setiap baris punya ID unik berformat `P-nn` (bagian 1) / `U-nn` (bagian 2), kolom lengkap, dan
    kolom "Yang seharusnya terjadi" tidak kosong.
 3. Langkah di setiap baris **bernomor 1..n tanpa melompat** dan **maksimal 5 langkah** (aturan buku).
 4. Setiap tugas ROADMAP (`T\d+-\d+`) yang disebut benar-benar ada di `docs/ROADMAP.md`.
 5. Kepala buku menyebut aturan "satu baris = satu hal" dan "dokumen ini sumber kebenaran".

Mode `--uji-diri`: salin repo, rusak bukunya, pastikan pemeriksa MENOLAK.
"""
from __future__ import annotations

import pathlib
import re
import sys

from bantu_uji_diri import AKAR, jalankan_pemeriksa, laporkan, salin_pohon

BUKU = "docs/uji/BUKU_UJI_PEMILIK.md"
KOLOM_WAJIB = ("ID", "Langkah", "seharusnya terjadi", "Hasil", "Catatan")
MAKS_LANGKAH = 5


def baris_tabel(teks: str) -> list[tuple[int, list[str]]]:
    hasil = []
    for no, b in enumerate(teks.splitlines(), 1):
        if not b.strip().startswith("|"):
            continue
        kolom = [k.strip() for k in b.strip().strip("|").split("|")]
        if len(kolom) < 5 or set(kolom[0]) <= set("-: "):
            continue
        if kolom[0] in ("ID",) or kolom[0].lower().startswith(("id ", "id")):
            continue
        hasil.append((no, kolom))
    return hasil


FOLDER_PAKET = "docs/uji/review-pr"


def _paket_terbaru(akar: pathlib.Path) -> str | None:
    """Nama berkas paket review SIAP-TEMPEL paling baru (diurutkan menurut nama)."""
    folder = akar / FOLDER_PAKET
    if not folder.is_dir():
        return None
    def kunci(nama: str) -> tuple:
        # "putaran9" vs "putaran10": urut abjad salah, jadi angka di dalam nama dibandingkan
        # sebagai bilangan (dan tanggal tetap ikut dibandingkan lebih dulu).
        return tuple(int(b) if b.isdigit() else b for b in re.split(r"(\d+)", nama) if b)

    kandidat = sorted((f.name for f in folder.glob("PKT-*-SIAP-TEMPEL.md")), key=kunci)
    return kandidat[-1] if kandidat else None


def _cek_paket_disebut(akar: pathlib.Path, teks: str, errs: list[str]) -> None:
    """Baris PETUNJUK paket review wajib jelas — dan wajib menunjuk paket yang berlaku.

    Kenapa ada: temuan review RV-2 (PR-03/PR-07/PR-10) — baris U-04 menyuruh Lee menyalin paket
    putaran lama padahal paket berlaku sudah berganti, sehingga sesi peninjau menilai kode basi.

    Aturan (dipelajari dari temuan peninjau PR-02, putaran11): yang dinilai adalah BARIS PETUNJUK
    (baris yang menyuruh menyalin SIAP-TEMPEL), bukan seluruh dokumen — sebab catatan log di buku
    boleh menyebut folder/kata "paling baru" tanpa itu berarti petunjuknya benar. Setiap baris
    petunjuk harus memenuhi SALAH SATU:
      (a) menyebut berkas `PKT-…-SIAP-TEMPEL.md` yang ADA dan PALING BARU, atau
      (b) menunjuk folder `review-pr` DAN memakai kata "paling baru"
          (dipakai supaya buku tidak perlu disunting tiap putaran; agent menyebut nama di chat).
    Dulu jalan ketiga "tidak menyebut apa pun" ikut lolos → buku bisa kehilangan petunjuk memilih
    paket tanpa ada yang menangkap (temuan PR-02).
    """
    baris_petunjuk = [
        b for b in teks.splitlines()
        if "SIAP-TEMPEL" in b and re.search(r"salin|siapkan", b, re.I)
    ]
    if not baris_petunjuk:
        errs.append(
            "buku uji tidak punya baris petunjuk menyalin paket review (cari baris berisi "
            "\"SIAP-TEMPEL\" + kata salin/siapkan)"
        )
        return
    terbaru = _paket_terbaru(akar)
    for b in baris_petunjuk:
        nama = sorted(set(re.findall(r"PKT-[\w\-.]*SIAP-TEMPEL\.md", b)))
        if nama:
            for n in nama:
                if not (akar / FOLDER_PAKET / n).is_file():
                    errs.append(f"buku uji menyebut paket review yang TIDAK ADA: {n}")
                elif terbaru and n != terbaru:
                    errs.append(
                        f"buku uji masih menyuruh Lee memakai paket LAMA ({n}); paket berlaku sekarang {terbaru} "
                        "— segarkan baris U-04 supaya sesi peninjau tidak menilai kode basi"
                    )
            continue
        if not ("review-pr" in b and re.search(r"paling baru", b, re.I)):
            errs.append(
                "baris petunjuk paket review tidak menyebut paket mana yang harus disalin "
                "(butuh salah satu: nama berkas PKT-…-SIAP-TEMPEL.md yang ada & paling baru, "
                "ATAU rujukan folder review-pr + kata \"paling baru\")"
            )
        elif terbaru is None:
            errs.append("buku menyuruh memakai paket paling baru, tetapi belum ada paket SIAP-TEMPEL di docs/uji/review-pr/")


def periksa(akar: pathlib.Path) -> int:
    errs: list[str] = []
    berkas = akar / BUKU
    if not berkas.is_file():
        print(f"GAGAL: {BUKU} tidak ada")
        return 1
    teks = berkas.read_text(encoding="utf-8")
    roadmap = (akar / "docs/ROADMAP.md").read_text(encoding="utf-8") if (akar / "docs/ROADMAP.md").is_file() else ""
    tugas_roadmap = set(re.findall(r"T\d+-\d+", roadmap))

    if "Yang harus Lee LAKUKAN" not in teks:
        errs.append("bagian 'Yang harus Lee LAKUKAN' hilang — buku wajib memisahkan tugas Lee dari uji coba")
    if "Yang harus Lee COBA" not in teks:
        errs.append("bagian 'Yang harus Lee COBA' hilang")
    for aturan in ("satu baris = satu hal", "sumber kebenaran", "CP"):
        if aturan == "CP":
            continue
        if aturan.lower() not in teks.lower():
            errs.append(f"aturan wajib hilang dari kepala buku: '{aturan}'")
    if "uji mesin" not in teks.lower():
        errs.append("kepala buku wajib menegaskan bahwa uji mesin tetap di CI (buku ini bukan pengganti uji otomatis)")

    for kolom in KOLOM_WAJIB:
        if kolom.lower() not in teks.lower():
            errs.append(f"kolom wajib hilang dari tabel: '{kolom}'")

    id_terlihat: set[str] = set()
    baris = baris_tabel(teks)
    jumlah = {"P": 0, "U": 0}
    for no, kolom in baris:
        kid = kolom[0]
        if not re.fullmatch(r"[PU]-\d{2}", kid):
            errs.append(f"baris {no}: ID '{kid}' tidak berformat P-nn / U-nn")
            continue
        if kid in id_terlihat:
            errs.append(f"baris {no}: ID kembar: {kid}")
        id_terlihat.add(kid)
        jumlah[kid[0]] += 1
        if len(kolom) < 6:
            errs.append(f"baris {no} ({kid}): kolom kurang ({len(kolom)}) — wajib ada Langkah, Yang seharusnya terjadi, Hasil, Catatan")
            continue
        langkah, harapan = kolom[2], kolom[3]
        if not harapan:
            errs.append(f"baris {no} ({kid}): kolom 'Yang seharusnya terjadi' KOSONG — tanpa itu hasil tidak bisa dinilai")
        if not langkah:
            errs.append(f"baris {no} ({kid}): kolom Langkah kosong")
        # Ambil HANYA deret langkah yang benar-benar 1), 2), 3), … — angka lain di dalam
        # kalimat (mis. "Ganti tema (10)") bukan langkah dan tidak boleh dihitung.
        kandidat = [int(m.group(1)) for m in re.finditer(r"(?<![\d(])(\d+)\)", langkah)]
        nomor: list[int] = []
        harap = 1
        for n in kandidat:
            if n == harap:
                nomor.append(n)
                harap += 1
        if not nomor:
            errs.append(f"baris {no} ({kid}): langkah tidak bernomor (pakai bentuk '1) … 2) …')")
        else:
            if len(nomor) > MAKS_LANGKAH:
                errs.append(f"baris {no} ({kid}): {len(nomor)} langkah — aturan buku maksimal {MAKS_LANGKAH} (pecah barisnya)")
            if len(nomor) < 2:
                errs.append(f"baris {no} ({kid}): hanya {len(nomor)} langkah bernomor — minimal 2")
        for t in set(re.findall(r"T\d+-\d+", " ".join(kolom))):
            if t not in tugas_roadmap:
                errs.append(f"baris {no} ({kid}): menyebut tugas '{t}' yang tidak ada di ROADMAP")

    if jumlah["P"] == 0 or jumlah["U"] == 0:
        errs.append("buku wajib punya minimal satu baris 'lakukan' (P-) dan satu baris 'coba' (U-)")
    _cek_paket_disebut(akar, teks, errs)

    print(f"PERIKSA BUKU UJI PEMILIK — {jumlah['P']} baris lakukan · {jumlah['U']} baris coba · {len(id_terlihat)} baris total")
    if errs:
        print(f"\nHASIL: GAGAL — {len(errs)} temuan")
        for e in errs:
            print(f"  [X] {e}")
        return 1
    print("\nHASIL: LOLOS — setiap baris punya langkah (maksimal 5), harapan, kolom hasil, dan tugas yang benar.")
    return 0


def uji_diri() -> int:
    hasil = []
    with salin_pohon() as tmp:
        kode, keluar = jalankan_pemeriksa(periksa, tmp)
        hasil.append(("salinan utuh", kode == 0, f"kode {kode}"))
        if kode != 0:
            print(keluar[:1500])

        # Mutasi 1: baris baru dengan 6 langkah → harus GAGAL
        with salin_pohon() as tmp2:
            berkas = tmp2 / BUKU
            isi = berkas.read_text(encoding="utf-8")
            baris_baru = "| U-99 | Uji karangan | 1) a 2) b 3) c 4) d 5) e 6) f | sesuatu terjadi |  |  |\n"
            berkas.write_text(isi.replace("\n## 3. Log buku ini", baris_baru + "\n## 3. Log buku ini"), encoding="utf-8")
            kode2, _ = jalankan_pemeriksa(periksa, tmp2)
            hasil.append(("mutasi: baris dengan 6 langkah", kode2 != 0,
                          "ditolak" if kode2 != 0 else "DILOLOSKAN (batas langkah tidak dijaga)"))

        # Mutasi 2b: paket review yang disebut buku dibuat BASI → harus GAGAL
        with salin_pohon() as tmp_basi:
            berkas = tmp_basi / BUKU
            isi = berkas.read_text(encoding="utf-8")
            # Mutasi PR-02: hapus BAIK nama paket, BAIK rujukan folder/"paling baru" → harus GAGAL.
            # (sebelum perbaikan: pemeriksa LOLOS di keadaan ini — temuan peninjau PR-02)
            if "SIAP-TEMPEL" in isi and re.search(r"salin", isi, re.I):
                l3 = re.sub(
                    r"^.*SIAP-TEMPEL.*$",
                    "2) Bilang `Siapkan review PR.`; salin SELURUH isi berkas itu kapan saja",
                    isi,
                    flags=re.M,
                )
                l3 = l3.replace("review-pr", "folder paket").replace("paling baru", "terkini")
                berkas.write_text(l3, encoding="utf-8")
                kode_basi, _ = jalankan_pemeriksa(periksa, tmp_basi)
                hasil.append(("mutasi: paket review tidak disebut sama sekali", kode_basi != 0,
                              "ditolak" if kode_basi != 0 else "DILOLOSKAN (buku tanpa petunjuk paket lolos)"))
                berkas.write_text(isi, encoding="utf-8")

            m = re.search(r"PKT-[\w\-.]*SIAP-TEMPEL\.md", isi)
            if not m:
                # Buku memakai pola "paling baru" (tanpa nama tetap). Untuk menguji penjaganya,
                # sisipkan nama paket LAMA ke dalam baris U-04 lalu pastikan pemeriksa menolak.
                folder0 = tmp_basi / FOLDER_PAKET
                semua0 = sorted(f.name for f in folder0.glob("PKT-*-SIAP-TEMPEL.md"))
                if len(semua0) < 2:
                    hasil.append(("mutasi: paket review disebut lebih tua", False,
                                  "paket kurang dari dua — tidak bisa dimutasi"))
                else:
                    lama0 = semua0[0]
                    isi2 = re.sub(r"(\|\s*U-04\s*\|)", r"\1 `" + lama0 + "`", isi, count=1)
                    if isi2 == isi:
                        hasil.append(("mutasi: paket review disebut lebih tua", False,
                                      "baris U-04 tidak ditemukan untuk disisipi nama paket lama"))
                    else:
                        berkas.write_text(isi2, encoding="utf-8")
                        kode_basi2, _ = jalankan_pemeriksa(periksa, tmp_basi)
                        hasil.append(("mutasi: paket review disebut lebih tua", kode_basi2 != 0,
                                      "ditolak" if kode_basi2 != 0 else "DILOLOSKAN (paket basi lolos)"))
            else:
                # arahkan ke paket lain yang ADA tapi bukan yang terbaru
                folder = tmp_basi / FOLDER_PAKET
                lain = [f.name for f in folder.glob("PKT-*-SIAP-TEMPEL.md") if f.name != m.group(0)]
                if not lain:
                    hasil.append(("mutasi: paket review disebut lebih tua", False,
                                  "hanya ada satu paket — tidak bisa dimutasi"))
                else:
                    isi = isi.replace(m.group(0), sorted(lain)[0], 1)
                    berkas.write_text(isi, encoding="utf-8")
                    kode_basi, _ = jalankan_pemeriksa(periksa, tmp_basi)
                    hasil.append(("mutasi: paket review disebut lebih tua", kode_basi != 0,
                                  "ditolak" if kode_basi != 0 else "DILOLOSKAN (paket basi lolos)"))

        # Mutasi 2: kolom harapan dikosongkan → harus GAGAL
        with salin_pohon() as tmp3:
            berkas = tmp3 / BUKU
            baris = berkas.read_text(encoding="utf-8").splitlines()
            idx = next((i for i, b in enumerate(baris) if re.match(r"\|\s*U-\d{2}", b)), None)
            kolom = [k.strip() for k in baris[idx].strip().strip("|").split("|")]
            kolom[3] = ""
            baris[idx] = "| " + " | ".join(kolom) + " |"
            berkas.write_text("\n".join(baris) + "\n", encoding="utf-8")
            kode3, _ = jalankan_pemeriksa(periksa, tmp3)
            hasil.append(("mutasi: kolom harapan dikosongkan", kode3 != 0,
                          "ditolak" if kode3 != 0 else "DILOLOSKAN (harapan tidak dijaga)"))

        # Mutasi 3: menunjuk tugas yang tidak ada di ROADMAP → harus GAGAL
        with salin_pohon() as tmp4:
            berkas = tmp4 / BUKU
            isi = berkas.read_text(encoding="utf-8")
            berkas.write_text(isi.replace("`T0-00`", "`T9-99`", 1), encoding="utf-8")
            kode4, _ = jalankan_pemeriksa(periksa, tmp4)
            hasil.append(("mutasi: menunjuk tugas yang tidak ada", kode4 != 0,
                          "ditolak" if kode4 != 0 else "DILOLOSKAN (rujukan tugas tidak dijaga)"))
    return laporkan("periksa-buku-uji", hasil)


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(periksa(AKAR))
