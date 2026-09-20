#!/usr/bin/env python3
"""periksa-temuan-audit.py — penjaga DAFTAR TEMUAN AUDIT (docs/uji/AUDIT_RIWAYAT.md §1b).

Kenapa ada: temuan audit pernah tercatat sebagai satu baris gelondongan ("kertas kerja K-3/K-4"),
sehingga beberapa temuan tidak punya status, bukti, atau pemilik penyelesaian. Laporan audit
menyebut 27 temuan (A: 10, B: 17); daftar penutup harus memuat **setiap** temuan satu per satu —
kalau tidak, temuan bisa hilang tanpa ada yang tahu.

Yang diperiksa:
 1. Setiap `[F-xx]` di SETIAP berkas laporan audit punya baris di daftar penutup §1b/§1c (tidak ada yang hilang).
 2. Setiap baris menyebut laporan+nomor temuan yang benar-benar ada (tidak ada temuan karangan).
 3. Status wajib salah satu: `DITUTUP` atau `TERBUKA` (tidak boleh kosong/abu-abu).
 4. Baris `DITUTUP` wajib menunjuk **bukti yang benar-benar ada** di repo (rujukan ber-backtick).
 5. Baris `TERBUKA` wajib menunjuk **tugas ROADMAP yang benar-benar ada** (mis. `T1-24`) —
    temuan tanpa pemilik penyelesaian adalah temuan yang akan terlupakan.

Mode `--uji-diri`: salin repo ke folder sementara, rusak daftarnya, pastikan pemeriksa MENOLAK.
"""
from __future__ import annotations

import pathlib
import re
import sys

from bantu_uji_diri import AKAR, jalankan_pemeriksa, laporkan, salin_pohon
from artefak import adakah_artefak

RIWAYAT = "docs/uji/AUDIT_RIWAYAT.md"
LAPORAN = {
    "A": "docs/uji/audit/LAPORAN_AUD-3_2026-09-17_menyeluruh.dari-01a0aeb0.md",
    "B": "docs/uji/audit/LAPORAN_AUD-3_2026-09-17_menyeluruh.md",
    # Ronde putaran verifikasi 2026-09-19 (sesi peninjau `arena/01a0b85b`): laporan ini DITOLAK MESIN
    # pada kontrak format (label grup cakupan diparafrase + cabang memuat 2 laporan), tetapi temuan
    # isinya sudah dibantah-balik 10/10 NYATA oleh sesi kerja — karena itu temuan-temuannya tetap
    # WAJIB punya baris penutup di §1b (temuan tidak boleh hilang hanya karena laporannya ditolak).
    "D": "docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0b85b.md",
    # Ronde 2026-09-19/20 (sesi `arena/01a0bbd2`): LULOS KONTRAK, 18 temuan, tiga di antaranya
    # (K-1 jalur uang) sudah dibantah-balik NYATA dan ditutup di migrasi `0015` bagian 6.
    "F": "docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbd2.md",
    # Ronde 2026-09-19/20 lanjutan — dua laporan yang masuk belakangan (sesi auditor lain + ronde
    # kedua sesi 01a0bbd2). Yang penting di sini bukan verdict mesinnya, melainkan bahwa SETIAP
    # temuan punya baris penutup: laporan H DITOLAK MESIN karena kelengkapan format (label grup
    # cakupan diparafrase lagi), tetapi isinya tetap dipakai dan wajib dibantah-balik per temuan.
    "H": "docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbcb.md",
    "I": "docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbd2-907e29e.md",
}
ROADMAP = "docs/ROADMAP.md"


def temuan_laporan(akar: pathlib.Path) -> dict[str, set[str]]:
    hasil: dict[str, set[str]] = {}
    for nama, rel in LAPORAN.items():
        berkas = akar / rel
        if not berkas.is_file():
            continue
        isi = berkas.read_text(encoding="utf-8")
        hasil[nama] = set(re.findall(r"^### \[(F-\d+)\]", isi, re.MULTILINE))
    return hasil


def baris_daftar(akar: pathlib.Path) -> list[tuple[int, list[str]]]:
    """Ambil baris tabel §1b (daftar temuan). Kembalikan (nomor baris, kolom)."""
    berkas = akar / RIWAYAT
    if not berkas.is_file():
        return []
    baris = berkas.read_text(encoding="utf-8").splitlines()
    # Sejak ronde kedua audit (2026-09-19/20) daftar penutup boleh punya beberapa sub-bagian
    # (`### 1b`, `### 1c`, …) — satu per laporan audit. Semuanya dibaca; kalau hanya `1b`
    # yang dibaca, temuan ronde baru bisa hilang tanpa ada yang tahu.
    hasil: list[tuple[int, list[str]]] = []
    di_bagian_daftar = False
    for i, b in enumerate(baris):
        if b.startswith("### 1"):
            di_bagian_daftar = True
            continue
        if b.startswith("### ") or b.startswith("## "):
            di_bagian_daftar = False
            continue
        if not di_bagian_daftar or not b.strip().startswith("|"):
            continue
        kolom = [k.strip() for k in b.strip().strip("|").split("|")]
        if len(kolom) < 5 or set(kolom[0]) <= set("-: "):
            continue
        if kolom[0].lower().startswith(("laporan", "temuan")):
            continue
        hasil.append((i + 1, kolom))
    return hasil


def jalur_ada(akar: pathlib.Path, rujukan: list[str]) -> list[str]:
    """Rujukan yang TIDAK ada di repo — kecuali yang terdaftar di daftar pensiun.

    Berkas yang sengaja dikeluarkan (mis. katalog cacat kalibrasi = kunci jawaban, audit H F-01
    2026-09-20) tetap boleh disebut sebagai provenance; daftar pensiun yang menjaganya.
    """
    pensiun: set[str] = set()
    daftar = akar / "docs/uji/BERKAS_PENSIUN.md"
    if daftar.is_file():
        for baris in daftar.read_text(encoding="utf-8").splitlines():
            b = baris.strip()
            if not b.startswith("|"):
                continue
            kolom = [k.strip() for k in b.strip("|").split("|")]
            if len(kolom) >= 2 and not set(kolom[0]) <= set("-: "):
                pensiun |= {m.group(1).strip() for m in re.finditer(r"`([^`]+)`", kolom[1])}
    # Sejak audit I F-20/H F-05 (2026-09-20): "ada" bukan hanya `(akar / r).exists()`.
    # Bukti boleh berbentuk PERINTAH (`python3 alat/periksa-roadmap.py`), POLA
    # (`aplikasi/src/komponen/*.tsx`), atau jalur relatif folder kerja (`src/lib/tema.ts`).
    # Menuduh bentuk-bentuk itu sebagai "berkas mati" = menuduh bukti yang hidup.
    return [r for r in rujukan
            if not (akar / r).exists() and not adakah_artefak(r, akar) and r not in pensiun]


LUAR_CAKUPAN = "docs/uji/TEMUAN_LUAR_CAKUPAN_REVIEW.md"


def periksa_luar_cakupan(akar: pathlib.Path, errs: list[str]) -> int:
    """Temuan peninjau yang DI LUAR cakupan diff wajib punya daftar tunggal yang hidup.

    Aturan kerja (Lee, 2026-09-17): temuan luar cakupan tidak boleh hilang di dalam laporan saja.
    Pemeriksa ini memastikan: berkas daftarnya ada, setiap baris punya status yang dikenali
    (DITANGANI / DITUNDA / DICATAT), dan setiap baris berstatus punya bukti ber-backtick yang
    benar-benar ada (atau perintah yang bisa dijalankan).
    """
    berkas = akar / LUAR_CAKUPAN
    if not berkas.is_file():
        errs.append(f"daftar temuan luar cakupan tidak ada: {LUAR_CAKUPAN}")
        return 0
    baris = 0
    for i, ln in enumerate(berkas.read_text(encoding="utf-8").splitlines(), 1):
        b = ln.strip()
        if not b.startswith("| L-"):
            continue
        kolom = [k.strip() for k in b.strip("|").split("|")]
        if len(kolom) < 5:
            errs.append(f"{LUAR_CAKUPAN}:{i}: kolom kurang ({len(kolom)})")
            continue
        baris += 1
        status = kolom[3].upper()
        if not any(s in status for s in ("DITANGANI", "DITUNDA", "DICATAT")):
            errs.append(f"{LUAR_CAKUPAN}:{i}: status tidak jelas ('{kolom[3][:30]}') — wajib DITANGANI/DITUNDA/DICATAT")
        rujukan = re.findall(r"`([^`\n]+)`", " ".join(kolom))
        if not rujukan:
            errs.append(f"{LUAR_CAKUPAN}:{i}: tanpa bukti ber-backtick (perintah/berkas) — temuan luar cakupan wajib berjejak")
        kandidat = [r for r in rujukan
                    if "/" in r and not r.startswith(("http", "python", "node", "git", "bash"))]
        for r in jalur_ada(akar, kandidat):
            errs.append(f"{LUAR_CAKUPAN}:{i}: bukti menunjuk berkas yang TIDAK ADA: {r}")
        if "DITUNDA" in status and not re.search(r"T\d+-\d+|TERTANGGUH|butir tunggu", " ".join(kolom)):
            errs.append(f"{LUAR_CAKUPAN}:{i}: baris DITUNDA wajib menyebut sarana penutupnya (tugas T\d+-\d+ atau butir tunggu)")
    if baris == 0:
        errs.append(f"{LUAR_CAKUPAN}: tidak ada baris temuan (tabel kosong?)")
    return baris


def periksa(akar: pathlib.Path) -> int:
    errs: list[str] = []
    temuan = temuan_laporan(akar)
    if not temuan:
        print("GAGAL: berkas laporan audit tidak ditemukan")
        return 1
    roadmap = (akar / ROADMAP).read_text(encoding="utf-8") if (akar / ROADMAP).is_file() else ""
    tugas_roadmap = set(re.findall(r"T\d+-\d+", roadmap))

    baris = baris_daftar(akar)
    if not baris:
        print(f"GAGAL: tabel daftar temuan (§1b) tidak ditemukan di {RIWAYAT}")
        return 1

    tercatat: dict[str, set[str]] = {nama: set() for nama in temuan}
    tertutup = terbuka = 0
    for no, kolom in baris:
        laporan_temuan, tingkat, ringkas, status, bukti = kolom[0], kolom[1], kolom[2], kolom[3], " ".join(kolom[4:])
        # 2. rujukan laporan+nomor wajib benar
        rujukan = re.findall(r"\b([A-I])\s*(F-\d+)", laporan_temuan)
        if not rujukan:
            errs.append(f"baris {no}: kolom 'Laporan' tidak menyebut satu pun temuan (mis. 'A F-01'): {laporan_temuan[:60]}")
        for nama, fid in rujukan:
            if fid not in temuan.get(nama, set()):
                errs.append(f"baris {no}: temuan {nama} {fid} tidak ada di laporan {nama} — rujukan salah")
            else:
                tercatat[nama].add(fid)
        # 3. status wajib jelas
        if "DITUTUP" not in status and "TERBUKA" not in status:
            errs.append(f"baris {no}: status tidak jelas ('{status[:40]}') — wajib memuat DITUTUP atau TERBUKA")
        # 4/5. bukti atau pemilik penyelesaian
        if "DITUTUP" in status:
            tertutup += 1
            # Ambil HANYA token pertama tiap rujukan: sel "bukti" sering memuat perintah
            # (`alat/periksa-x.py --uji-diri`) — yang diperiksa keberadaan berkasnya, bukan flag-nya.
            rujukan_berkas = []
            for r in re.findall(r"`([^`\n]+)`", bukti):
                kandidat = r.split()[0] if r.split() else r
                if "/" in kandidat and not kandidat.startswith(("http", "python", "node", "git", "bash")):
                    rujukan_berkas.append(kandidat)
            if not rujukan_berkas:
                errs.append(f"baris {no} ({laporan_temuan}): DITUTUP tanpa rujukan bukti ber-backtick")
            hilang = jalur_ada(akar, rujukan_berkas)
            for h in hilang:
                errs.append(f"baris {no} ({laporan_temuan}): bukti penutup menunjuk berkas yang TIDAK ADA: {h}")
        if "TERBUKA" in status:
            terbuka += 1
            tugas = set(re.findall(r"T\d+-\d+", bukti))
            if not tugas:
                errs.append(f"baris {no} ({laporan_temuan}): TERBUKA tanpa tugas ROADMAP — temuan tanpa pemilik akan terlupakan")
            for t in sorted(tugas - tugas_roadmap):
                errs.append(f"baris {no} ({laporan_temuan}): tugas '{t}' tidak ada di ROADMAP.md")

    # 1. tidak ada temuan yang hilang
    for nama, ids in temuan.items():
        for fid in sorted(ids):
            if fid not in tercatat.get(nama, set()):
                errs.append(f"temuan {nama} {fid} BELUM punya baris di daftar §1b — temuan tidak boleh hilang")

    total = sum(len(v) for v in temuan.values())
    jumlah_luar = periksa_luar_cakupan(akar, errs)
    # Ringkasan dibuat DATA-DRIVEN: laporan baru tidak boleh perlu menyunting baris cetak ini
    # (pelajaran dari ronde audit 2026-09-20 — ringkasan manual membuat temuan "tak terlihat").
    rincian = " · ".join(
        f"{nama}: {len(ids)}" + (" (ditolak mesin, isinya dipakai)" if nama == "D" else "")
        for nama, ids in sorted(temuan.items()))
    print(f"PERIKSA TEMUAN AUDIT — {rincian} temuan "
          f"· daftar penutup: {len(baris)} baris ({tertutup} ditutup · {terbuka} terbuka)")
    if errs:
        print(f"\nHASIL: GAGAL — {len(errs)} temuan")
        for e in errs:
            print(f"  [X] {e}")
        return 1
    print(f"\nHASIL: LOLOS — {total} temuan terlacak semua, tiap DITUTUP punya bukti hidup, tiap TERBUKA punya tugas; "
          f"{jumlah_luar} temuan luar cakupan review berjejak di daftar tunggal.")
    return 0


def uji_diri() -> int:
    hasil = []
    with salin_pohon() as tmp:
        kode, keluar = jalankan_pemeriksa(periksa, tmp)
        hasil.append(("salinan utuh", kode == 0, f"kode {kode}"))
        if kode != 0:
            print(keluar[:2000])

        # Mutasi 1: satu baris daftar dihapus → harus GAGAL
        with salin_pohon() as tmp2:
            berkas = tmp2 / RIWAYAT
            isi = berkas.read_text(encoding="utf-8").splitlines()
            idx = next((i for i, b in enumerate(isi) if re.match(r"\|\s*[AB]\s*F-\d+", b)), None)
            if idx is None:
                hasil.append(("mutasi hapus baris", False, "tidak menemukan baris daftar untuk dihapus"))
            else:
                del isi[idx]
                berkas.write_text("\n".join(isi) + "\n", encoding="utf-8")
                kode2, keluar2 = jalankan_pemeriksa(periksa, tmp2)
                hasil.append(("mutasi: satu temuan dihapus dari daftar", kode2 != 0,
                              "ditolak" if kode2 != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 1b: baris temuan laporan D (putaran verifikasi) dihapus → harus GAGAL.
        # Tanpa kasus ini, cakupan laporan D bisa hilang tanpa ada yang tahu.
        with salin_pohon() as tmp1b:
            berkas = tmp1b / RIWAYAT
            isi = berkas.read_text(encoding="utf-8").splitlines()
            idx = next((i for i, b in enumerate(isi) if re.match(r"\|\s*D\s*F-\d+", b)), None)
            if idx is None:
                hasil.append(("mutasi hapus baris D", False, "tidak menemukan baris D untuk dihapus"))
            else:
                del isi[idx]
                berkas.write_text("\n".join(isi) + "\n", encoding="utf-8")
                kode1b, _ = jalankan_pemeriksa(periksa, tmp1b)
                hasil.append(("mutasi: satu temuan laporan D dihapus dari daftar", kode1b != 0,
                              "ditolak" if kode1b != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 1c: baris temuan laporan F (ronde 2026-09-19/20) dihapus → harus GAGAL.
        with salin_pohon() as tmp1c:
            berkas = tmp1c / RIWAYAT
            isi = berkas.read_text(encoding="utf-8").splitlines()
            idx = next((i for i, b in enumerate(isi) if re.match(r"\|\s*F\s*F-\d+", b)), None)
            if idx is None:
                hasil.append(("mutasi hapus baris F", False, "tidak menemukan baris F untuk dihapus"))
            else:
                del isi[idx]
                berkas.write_text("\n".join(isi) + "\n", encoding="utf-8")
                kode1c, _ = jalankan_pemeriksa(periksa, tmp1c)
                hasil.append(("mutasi: satu temuan laporan F dihapus dari daftar", kode1c != 0,
                              "ditolak" if kode1c != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 2: bukti penutup diarahkan ke berkas yang tidak ada → harus GAGAL
        with salin_pohon() as tmp3:
            berkas = tmp3 / RIWAYAT
            isi = berkas.read_text(encoding="utf-8")
            baris = isi.splitlines()
            idx = next((i for i, b in enumerate(baris) if "DITUTUP" in b and "`supabase/tes/" in b), None)
            if idx is None:
                hasil.append(("mutasi bukti palsu", False, "tidak menemukan baris DITUTUP ber-bukti untuk dimutasi"))
            else:
                baris[idx] = re.sub(r"`supabase/tes/[^`]+`", "`supabase/tes/tidak-ada.sql`", baris[idx], count=1)
                berkas.write_text("\n".join(baris) + "\n", encoding="utf-8")
                kode3, _ = jalankan_pemeriksa(periksa, tmp3)
                hasil.append(("mutasi: bukti penutup menunjuk berkas palsu", kode3 != 0,
                              "ditolak" if kode3 != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi 3: temuan terbuka kehilangan tugas ROADMAP → harus GAGAL
        with salin_pohon() as tmp4:
            berkas = tmp4 / RIWAYAT
            baris = berkas.read_text(encoding="utf-8").splitlines()
            # hanya baris tabel — kalimat pengantar juga memuat kata "TERBUKA"
            idx = next((i for i, b in enumerate(baris) if b.strip().startswith("|") and "TERBUKA" in b), None)
            if idx is None:
                hasil.append(("mutasi tugas hilang", False, "tidak menemukan baris TERBUKA"))
            else:
                baris[idx] = re.sub(r"T\d+-\d+", "T9-99", baris[idx])
                berkas.write_text("\n".join(baris) + "\n", encoding="utf-8")
                kode4, _ = jalankan_pemeriksa(periksa, tmp4)
                hasil.append(("mutasi: temuan terbuka menunjuk tugas palsu", kode4 != 0,
                              "ditolak" if kode4 != 0 else "DILOLOSKAN (tumpul)"))
        # Mutasi 4: baris temuan luar cakupan diberi status karangan → harus GAGAL
        with salin_pohon() as tmp5:
            berkas = tmp5 / LUAR_CAKUPAN
            baris = berkas.read_text(encoding="utf-8").splitlines()
            idx = next((i for i, b in enumerate(baris) if b.strip().startswith("| L-")), None)
            if idx is None:
                hasil.append(("mutasi status luar cakupan", False,
                              "daftar temuan luar cakupan tidak punya baris untuk dimutasi"))
            else:
                kolom = [k.strip() for k in baris[idx].strip().strip("|").split("|")]
                kolom[3] = "SEDANG DIPIKIRKAN"
                baris[idx] = "| " + " | ".join(kolom) + " |"
                berkas.write_text("\n".join(baris) + "\n", encoding="utf-8")
                kode5, _ = jalankan_pemeriksa(periksa, tmp5)
                hasil.append(("mutasi: status temuan luar cakupan dikarang", kode5 != 0,
                              "ditolak" if kode5 != 0 else "DILOLOSKAN (status tak dijaga)"))

        # Mutasi 5: baris DITUNDA dihapus sarananya → harus GAGAL
        with salin_pohon() as tmp6:
            berkas = tmp6 / LUAR_CAKUPAN
            isi = berkas.read_text(encoding="utf-8")
            isi = isi.replace("masuk tugas `T1-44` (paket audit diperketat)", "masuk rencana nanti")
            isi = isi.replace("`docs/TERTANGGUH.md`; ditutup oleh `T1-24`", "dibiarkan saja")
            berkas.write_text(isi, encoding="utf-8")
            kode6, _ = jalankan_pemeriksa(periksa, tmp6)
            hasil.append(("mutasi: baris DITUNDA tanpa sarana penutup", kode6 != 0,
                          "ditolak" if kode6 != 0 else "DILOLOSKAN (penundaan tanpa sarana)"))

        # Mutasi 6 (audit I F-20/H F-05): bukti penutup berbentuk POLA dan JALUR RELATIF folder
        # kerja harus DITERIMA — ketiganya nyata. Dulu pemeriksa ini menuduhnya "berkas mati".
        with salin_pohon() as tmp7:
            berkas = tmp7 / RIWAYAT
            baris = berkas.read_text(encoding="utf-8").splitlines()
            idx = next((i for i, b in enumerate(baris) if "DITUTUP" in b and "`supabase/tes/" in b), None)
            if idx is None:
                hasil.append(("mutasi bukti pola/relatif", False, "tidak menemukan baris DITUTUP untuk dimutasi"))
            else:
                baris[idx] = re.sub(r"`supabase/tes/[^`]+`",
                                    "`aplikasi/src/komponen/*.tsx` dan `src/lib/tema.ts`", baris[idx], count=1)
                berkas.write_text("\n".join(baris) + "\n", encoding="utf-8")
                kode7, keluar7 = jalankan_pemeriksa(periksa, tmp7)
                hasil.append(("mutasi: bukti berbentuk pola & jalur relatif TIDAK dituduh hilang", kode7 == 0,
                              "diterima" if kode7 == 0 else f"DITOLAK PALSU: {keluar7.strip().splitlines()[-1][:90]}"))

        # Mutasi 7: bukti yang MEMANG hilang tetap ditolak (ketajaman tidak dikorbankan).
        with salin_pohon() as tmp8:
            berkas = tmp8 / RIWAYAT
            baris = berkas.read_text(encoding="utf-8").splitlines()
            idx = next((i for i, b in enumerate(baris) if "DITUTUP" in b and "`supabase/tes/" in b), None)
            if idx is None:
                hasil.append(("mutasi bukti benar-benar hilang", False, "tidak menemukan baris DITUTUP untuk dimutasi"))
            else:
                baris[idx] = re.sub(r"`supabase/tes/[^`]+`", "`supabase/tes/benar-benar-tidak-ada.sql`", baris[idx], count=1)
                berkas.write_text("\n".join(baris) + "\n", encoding="utf-8")
                kode8, _ = jalankan_pemeriksa(periksa, tmp8)
                hasil.append(("mutasi: bukti penutup benar-benar hilang tetap DITOLAK", kode8 != 0,
                              "ditolak" if kode8 != 0 else "DILOLOSKAN (tumpul)"))

    return laporkan("periksa-temuan-audit", hasil)


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(periksa(AKAR))
