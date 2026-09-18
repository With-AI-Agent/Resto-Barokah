#!/usr/bin/env python3
"""periksa-panduan.py — penjaga BUKU PEDOMAN INDUK (PANDUAN_PENGGUNA.md).

Kenapa ada: permintaan pemilik 2026-09-17 — buku pedoman pengguna harus benar-benar
INDUK dan LENGKAP (semua mekanisme + semua prompt), dan tidak boleh basi. Pemeriksa
ini dijalankan di CI, jadi buku tidak bisa pelan-pelan kehilangan isi atau menunjuk
berkas yang tidak ada.

Yang diperiksa:
 1. Semua bagian A–H ada.
 2. Topik wajib ada (audit + kalibrasi, keamanan, darurat, privasi, biaya, glosarium,
    prompt pembuka + penutup, review & merge, template).
 3. Tabel mekanisme memuat >= 10 baris (C1..Cn) dan tiap mekanisme punya berkas rujukan.
 4. Blok Prompt Pembuka identik dengan PROMPT_ENTRI_UNIVERSAL.md.
 5. Blok Prompt Auditor identik dengan blok kanonik di docs/uji/PROMPT_AUDIT_INDEPENDEN.md.
 6. Semua rujukan berkas ber-backtick benar-benar ada (kecuali ditandai "(rencana)").
 7. Berkas untuk pengguna benar-benar ada & menunjuk balik ke buku induk.
 8. Panjang minimum (penjaga anti-penyusutan).
"""
from __future__ import annotations

import pathlib
import re
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent
BUKU = AKAR / "PANDUAN_PENGGUNA.md"
MIN_BARIS = 350
# --- aturan v2 (permintaan Lee 2026-09-17): setiap prompt wajib berlabel pemakainya,
# setiap alur wajib punya 8 bidang tetap, dan tabel perintah wajib menjelaskan fungsi & cara pakai.
LABEL_PROMPT = ("[LEE → AGENT]", "[LEE → PENINJAU]")
# bidang alur boleh punya keterangan dalam tanda kurung, mis. "**Langkah Lee (4 langkah):**"
BIDANG_ALUR = (
    r"\*\*Apa ini[^*]*:\*\*", r"\*\*Kapan dipakai[^*]*:\*\*", r"\*\*Kalimat Lee[^*]*:\*\*",
    r"\*\*Langkah Lee[^*]*:\*\*", r"\*\*Yang agent lakukan[^*]*:\*\*",
    r"\*\*Bukti yang Lee terima[^*]*:\*\*", r"\*\*Lama[^*]*:\*\*", r"\*\*Kalau macet[^*]*:\*\*",
)
# Ambang = jumlah NYATA (temuan audit B-F-12: ambang 10 dengan isi 12 berarti dua alur
# bisa terhapus tanpa ketahuan). Kalau alur bertambah, naikkan angka ini — jangan sebaliknya.
MIN_ALUR = 13
KOLOM_PERINTAH = ("Kalimat Lee", "Fungsinya", "Kalau GAGAL artinya")
LARANGAN_SAPAAN = ("Bapak", "Pak ")  # Lee minta dipanggil "Lee" (2026-09-17)

TOPIK_WAJIB = {
    "prompt pembuka": r"Prompt Pembuka Universal",
    "prompt penutup": r"Prompt Penutup Sesi",
    "audit indep.": r"AUD-3|audit independen",
    "kalibrasi cacat": r"[Kk]alibrasi",
    "istilah audit": r"K-1",
    "keamanan": r"KEAMANAN\.md",
    "darurat/insiden": r"BUKU_INSIDEN\.md",
    "privasi/PDP": r"PDP",
    "biaya": r"[Bb]iaya",
    "review & merge": r"review & merge|Review & Merge",
    "template": r"(?i)sebagai template",
    "titik masuk sesi baru": r"PROMPT_ENTRI_UNIVERSAL",
    "review PR independen": r"Review PR independen|review PR",
    "label prompt": r"\[LEE → (AGENT|PENINJAU)\]",
    "penjelasan perintah": r"Fungsinya",
    "rekam pesan Lee": r"REKAM_PESAN_PEMILIK",
    # Fakta pindah sesi (jawaban Lee 2026-09-18): tanpa bagian ini, Lee akan mengira
    # harus mengatur base branch / wajib mengirim prompt penutup — padahal tidak.
    "pindah sesi: base branch": r"base branch tidak perlu kamu sentuh",
    "pindah sesi: penutup tak wajib": r"disarankan 1 kalimat, bukan wajib",
    "pindah sesi: pakai berkas terbaru": r"Wajib pakai berkas terbaru",
    "pindah sesi: jangan merge": r"Jangan merge PR #1",
    # Koreksi Lee 2026-09-18: agent sempat menjawab dengan bahasa yang salah. Aturan bahasa
    # sekarang WAJIB ada di prompt kanonik + buku induk, dan dijaga di sini.
    "aturan bahasa ke Lee": r"ATURAN BAHASA",
}
BERKAS_PENGGUNA_WAJIB = [
    "docs/PANDUAN_PEMILIK.md",
    "docs/uji/PROMPT_AUDIT_INDEPENDEN.md",
    "docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md",
    "docs/teknis/BUKU_INSIDEN.md",
    "docs/ops/SIAP_AKUN_PEMILIK.md",
    "docs/KEAMANAN.md",
    "PROMPT_ENTRI_UNIVERSAL.md",
    "PROFIL_PENGGUNA.md",
    "10_LOG_SESI.md",
    "ACCEPTANCE_TESTS.md",
]


def blok_pertama(teks: str) -> str:
    m = re.search(r"```\n(.*?)\n```", teks, re.DOTALL)
    return m.group(1).strip() if m else ""


def cari_blok_kanonik(teks: str) -> str:
    """Ambil blok prompt auditor dari bagian B berkas kanonik."""
    bagian = teks.split("## B.")[-1]
    return blok_pertama(bagian)


def main(akar: pathlib.Path | None = None) -> int:
    akar = akar or AKAR
    buku = akar / "PANDUAN_PENGGUNA.md"
    errs: list[str] = []
    catatan: list[str] = []
    angka: dict = {}
    if not buku.is_file():
        print("GAGAL: PANDUAN_PENGGUNA.md tidak ada"); return 1
    teks = buku.read_text(encoding="utf-8")
    baris = teks.splitlines()

    if len(baris) < MIN_BARIS:
        errs.append(f"buku terlalu pendek: {len(baris)} baris (minimum {MIN_BARIS}) — buku induk tidak boleh menyusut")

    for huruf in "ABCDEFGH":
        if not re.search(rf"^## Bagian {huruf}\b", teks, re.MULTILINE):
            errs.append(f"bagian {huruf} hilang (buku induk wajib punya bagian A–H)")

    for pesan in cek_angka_berkas_uji(akar):
        errs.append(pesan)

    for nama, pola in TOPIK_WAJIB.items():
        if not re.search(pola, teks):
            errs.append(f"topik wajib hilang: {nama} (pola {pola!r}) — tambahkan ke buku")

    # --- v2: alur (Bagian B) ---
    judul_alur = re.findall(r"^### (AL-\d+) — (.+)$", teks, re.MULTILINE)
    if len(judul_alur) < MIN_ALUR:
        errs.append(f"alur terlalu sedikit: {len(judul_alur)} (minimum {MIN_ALUR}) — Bagian B wajib memuat semua cara melakukan")
    for nomor, nama in judul_alur:
        i = teks.index(f"### {nomor} —")
        j = teks.find("\n### ", i + 4)
        blok = teks[i: j if j > 0 else len(teks)]
        hilang = [b for b in BIDANG_ALUR if not re.search(b, blok)]
        if hilang:
            errs.append(f"{nomor} ({nama[:40]}): bidang wajib hilang {hilang} — setiap alur harus punya 8 bidang tetap")
        if len(blok.splitlines()) < 8:
            errs.append(f"{nomor} ({nama[:40]}): alur terlalu pendek ({len(blok.splitlines())} baris)")

    # --- v2: prompt wajib berlabel ---
    blok_kode = list(re.finditer(r"^```\n(.*?)^```$", teks, re.MULTILINE | re.DOTALL))
    angka["blok_prompt"] = len(blok_kode)
    for m in blok_kode:
        awal_baris = teks[: m.start()].count("\n") + 1
        sebelum = "\n".join(baris[max(0, awal_baris - 8): awal_baris])
        if not any(lab in sebelum for lab in LABEL_PROMPT):
            errs.append(f"blok prompt di baris {awal_baris} TIDAK berlabel siapa yang memakainya "
                        f"(wajib ada {LABEL_PROMPT[0]} atau {LABEL_PROMPT[1]} dalam 8 baris sebelum blok)")

    # --- v2: tabel perintah mesin menjelaskan fungsi & cara pakai ---
    kepala_perintah = [b for b in baris if "Kalimat Lee" in b and "Fungsinya" in b]
    if not kepala_perintah:
        errs.append("tabel perintah mesin wajib punya kolom 'Kalimat Lee', 'Fungsinya', dan 'Kalau GAGAL artinya'")
    baris_perintah = [b for b in baris if b.strip().startswith("| `")]
    angka["perintah"] = len(baris_perintah)
    if len(baris_perintah) < 10:
        errs.append(f"tabel perintah mesin hanya {len(baris_perintah)} baris perintah (minimum 10)")
    for b in baris_perintah:
        kolom = [k.strip() for k in b.strip("|").split("|")]
        if len(kolom) < 5:
            errs.append(f"baris perintah tanpa penjelasan lengkap: {b.strip()[:60]}")

    # --- v2b: setiap rujukan bernomor ("Bagian C4", "Bagian D2") wajib punya heading-nya ---
    for m in re.finditer(r"Bagian ([A-H])(\d+)\b", teks):
        huruf, nomor = m.group(1), m.group(2)
        pola_heading = rf"^###\s*{huruf}{nomor}\."
        if not re.search(pola_heading, teks, re.MULTILINE):
            errs.append(f"rujukan 'Bagian {huruf}{nomor}' menunjuk bagian yang tidak ada di buku (heading '### {huruf}{nomor}.' hilang)")

    # --- v2: sapaan (boleh menyebut "Bapak" HANYA dalam kalimat larangan/koreksi) ---
    for i, baris_ in enumerate(baris, 1):
        if any(s in baris_ for s in LARANGAN_SAPAAN):
            if not re.search(r"bukan|jangan|tidak boleh|→|panggil", baris_, re.I):
                errs.append(f"baris {i}: buku memanggil Lee dengan 'Bapak' — Lee minta dipanggil 'Lee' (2026-09-17): {baris_[:60]}")

    baris_mekanisme = [b for b in baris if re.match(r"\|\s*C\d+\s*\|", b)]
    if len(baris_mekanisme) < 10:
        errs.append(f"tabel mekanisme hanya {len(baris_mekanisme)} baris (minimum 10 mekanisme terdaftar)")
    for b in baris_mekanisme:
        kolom = [k.strip() for k in b.strip("|").split("|")]
        punya_rujukan = any(re.search(r"`[^`]*\.(md|py|sh|mjs|ts|tsx|sql|yml|json)|\.md`", k) for k in kolom)
        if len(kolom) < 6 or not punya_rujukan:
            errs.append(f"baris mekanisme tanpa rujukan berkas / kolom kurang: {b.strip()[:70]}")

    # 4. blok prompt pembuka harus identik
    pe = akar / "PROMPT_ENTRI_UNIVERSAL.md"
    if pe.is_file():
        kanonik = blok_pertama(pe.read_text(encoding="utf-8"))
        if not kanonik:
            errs.append("PROMPT_ENTRI_UNIVERSAL.md tidak punya blok prompt bertanda ```")
        elif kanonik not in teks:
            errs.append("blok Prompt Pembuka di buku induk TIDAK identik dengan PROMPT_ENTRI_UNIVERSAL.md — jangan menyalin manual, ambil dari sumbernya")
    else:
        errs.append("PROMPT_ENTRI_UNIVERSAL.md tidak ada")

    # 5. blok prompt auditor harus identik
    pa = akar / "docs" / "uji" / "PROMPT_AUDIT_INDEPENDEN.md"
    if pa.is_file():
        kanonik_audit = cari_blok_kanonik(pa.read_text(encoding="utf-8"))
        if not kanonik_audit:
            errs.append("PROMPT_AUDIT_INDEPENDEN.md bagian B: blok prompt auditor tidak ditemukan")
        elif kanonik_audit not in teks:
            errs.append("blok Prompt Auditor di buku induk TIDAK identik dengan docs/uji/PROMPT_AUDIT_INDEPENDEN.md bagian B")
    else:
        errs.append("docs/uji/PROMPT_AUDIT_INDEPENDEN.md tidak ada")

    # 6. rujukan berkas ber-backtick harus ada
    # rentang baris blok kanonik yang disematkan apa adanya (dari berkas lain) —
    # rujukan di dalamnya dilaporkan sebagai catatan, bukan kegagalan: teks itu milik sumbernya.
    rentang_kanonik: list[tuple[int, int]] = []
    for sumber in (pe, pa):
        if not sumber.is_file():
            continue
        isi = sumber.read_text(encoding="utf-8")
        blok_kanonik = blok_pertama(isi) if sumber is pe else cari_blok_kanonik(isi)
        if not blok_kanonik:
            continue
        awal = teks.find(blok_kanonik)
        if awal >= 0:
            n_awal = teks[:awal].count("\n") + 1
            rentang_kanonik.append((n_awal, n_awal + blok_kanonik.count("\n")))

    def di_dalam_kanonik(no_baris: int) -> bool:
        return any(a <= no_baris <= b for a, b in rentang_kanonik)

    kandidat: set[str] = set()
    for m in re.finditer(r"`([^`\n]+)`", teks):
        t = m.group(1).strip()
        if t.startswith(("http", "python3 ", "node ", "bash ", "cd ", "git ", "gh ", "npx ")):
            continue
        if t.startswith("<") or " " in t or "<" in t or "…" in t or "*" in t:
            continue
        if not (("/" in t) or re.search(r"\.(md|py|sh|mjs|ts|tsx|sql|json|yml|html)$", t)):
            continue
        kandidat.add(t.rstrip("/") if t.endswith("/") and not (AKAR / t).is_dir() else t)
    lewat = 0
    for t in sorted(kandidat):
        if t in {"main", "arena/...", "docs/..."}:
            continue
        jalur = akar / t
        if jalur.exists():
            continue
        # baris yang menyebut berkas ini (+ nomor barisnya)
        pola_baris = [(i, b) for i, b in enumerate(baris, 1) if f"`{t}`" in b or f"`{t.rstrip('/')}/`" in b]
        if pola_baris and all(di_dalam_kanonik(i) for i, _ in pola_baris):
            catatan.append(f"rujukan di dalam blok kanonik yang disematkan (milik sumber lain): {t}")
            lewat += 1
            continue
        if any(re.search(r"\(rencana|belum ada|belum jadi|akan ditulis|observasi", b) for _, b in pola_baris):
            catatan.append(f"rujukan berkas yang belum ada (ditandai rencana): {t}")
            lewat += 1
            continue
        errs.append(f"rujukan berkas tidak ada: `{t}` — perbaiki rujukan atau tandai (rencana)")

    # 7. berkas untuk pengguna wajib ada + menunjuk balik
    for rel in BERKAS_PENGGUNA_WAJIB:
        if not (akar / rel).is_file():
            errs.append(f"berkas untuk pengguna hilang: {rel}")
    pm = akar / "docs" / "PANDUAN_PEMILIK.md"
    if pm.is_file() and "PANDUAN_PENGGUNA.md" not in pm.read_text(encoding="utf-8"):
        errs.append("docs/PANDUAN_PEMILIK.md tidak menunjuk balik ke buku induk PANDUAN_PENGGUNA.md — pengguna bisa tersesat")
    pp = akar / "docs" / "uji" / "PROMPT_AUDIT_INDEPENDEN.md"
    if pp.is_file() and "PANDUAN_PENGGUNA" not in pp.read_text(encoding="utf-8"):
        errs.append("docs/uji/PROMPT_AUDIT_INDEPENDEN.md tidak menunjuk ke buku induk")

    print(f"PERIKSA BUKU PEDOMAN INDUK — {len(baris)} baris · {len(judul_alur)} alur · {angka.get('blok_prompt', 0)} blok prompt "
          f"· {angka.get('perintah', 0)} perintah · {len(baris_mekanisme)} mekanisme · {len(kandidat)} rujukan berkas")
    for c in catatan:
        print(f"  [catatan] {c}")
    if errs:
        print(f"\nHASIL: GAGAL — {len(errs)} temuan")
        for e in errs:
            print(f"  [X] {e}")
        return 1
    print("\nHASIL: LOLOS — buku induk lengkap, rujukan hidup, prompt identik dengan sumbernya.")
    return 0


def cek_angka_berkas_uji(akar: pathlib.Path) -> list[str]:
    """Angka "N berkas uji" di dokumen hidup wajib sama dengan jumlah berkas uji NYATA.

    Kenapa ada: temuan review putaran11 PR-04 (K-4). `PANDUAN_PENGGUNA.md` dan
    `docs/TERTANGGUH.md` masih menulis "21 berkas uji" padahal repo sudah punya 28
    (dan sekarang 31) — padahal buku induk justru yang paling gampang dicek angkanya,
    dan pemeriksa ini LOLOS saja. Angka yang basi membuat Lee salah menilai cakupan uji.
    """
    nyata = len(list((akar / "supabase" / "tes").glob("*.sql")))
    if nyata == 0:
        return ["tidak ada berkas uji di supabase/tes — pemeriksa angka tidak bisa dinilai"]
    salah: list[str] = []
    for relatif in ("PANDUAN_PENGGUNA.md", "docs/TERTANGGUH.md", "docs/KEAMANAN.md"):
        berkas = akar / relatif
        if not berkas.is_file():
            continue
        for i, baris in enumerate(berkas.read_text(encoding="utf-8").splitlines(), start=1):
            for m in re.finditer(r"(\d+)\s+berkas uji", baris):
                angka = int(m.group(1))
                if angka != nyata:
                    salah.append(
                        f"{relatif}:{i} menulis \"{angka} berkas uji\" padahal nyatanya {nyata} "
                        f"— segarkan angkanya (atau cabut klaimnya); jangan biarkan dokumen basi"
                    )
    return salah


def uji_diri() -> int:
    """Standar proyek: pemeriksa yang tidak bisa MERAH dianggap belum terpasang (B-F-12)."""
    from bantu_uji_diri import jalankan_pemeriksa, laporkan, salin_pohon

    hasil = []
    with salin_pohon() as tmp:
        kode, keluar = jalankan_pemeriksa(main, tmp)
        hasil.append(("salinan utuh", kode == 0, f"kode {kode}"))
        if kode != 0:
            print(keluar[:1500])

        # Mutasi 1: satu alur dihapus → harus GAGAL (ambang = jumlah nyata)
        with salin_pohon() as tmp2:
            berkas = tmp2 / "PANDUAN_PENGGUNA.md"
            isi = berkas.read_text(encoding="utf-8")
            awal = [m.start() for m in re.finditer(r"^### AL-\d+ — ", isi, re.MULTILINE)]
            potong_awal = awal[1]
            potong_akhir = isi.find("\n### ", potong_awal + 4)
            berkas.write_text(isi[:potong_awal] + isi[potong_akhir:], encoding="utf-8")
            kode2, _ = jalankan_pemeriksa(main, tmp2)
            hasil.append(("mutasi: satu alur dihapus dari Bagian B", kode2 != 0,
                          "ditolak" if kode2 != 0 else "DILOLOSKAN (ambang longgar)"))

        # Mutasi 2: label pemakai prompt dihapus → harus GAGAL
        with salin_pohon() as tmp3:
            berkas = tmp3 / "PANDUAN_PENGGUNA.md"
            isi = berkas.read_text(encoding="utf-8")
            for lab in ("[LEE → AGENT]", "[LEE → PENINJAU]"):
                isi = isi.replace(lab, "[PROMPT]")
            berkas.write_text(isi, encoding="utf-8")
            kode3, _ = jalankan_pemeriksa(main, tmp3)
            hasil.append(("mutasi: label pemakai prompt dihapus", kode3 != 0,
                          "ditolak" if kode3 != 0 else "DILOLOSKAN (label tidak dijaga)"))

        # Mutasi 3: buku memanggil Lee dengan "Bapak" → harus GAGAL
        with salin_pohon() as tmp4:
            berkas = tmp4 / "PANDUAN_PENGGUNA.md"
            isi = berkas.read_text(encoding="utf-8")
            berkas.write_text(isi + "\nSilakan tanya Bapak kalau bingung.\n", encoding="utf-8")
            kode4, _ = jalankan_pemeriksa(main, tmp4)
            hasil.append(("mutasi: buku memanggil \"Bapak\"", kode4 != 0,
                          "ditolak" if kode4 != 0 else "DILOLOSKAN (sapaan tidak dijaga)"))
        # Mutasi 4: angka berkas uji dibuat basi → harus GAGAL (temuan review putaran11 PR-04)
        with salin_pohon() as tmp5:
            berkas = tmp5 / "PANDUAN_PENGGUNA.md"
            isi = berkas.read_text(encoding="utf-8")
            m = re.search(r"\d+(?=\s+berkas uji)", isi)
            if not m:
                hasil.append(("mutasi: angka berkas uji dibuat basi", False,
                              "buku tidak menulis angka berkas uji — tidak bisa dimutasi"))
            else:
                basi = str(int(m.group(0)) - 1)
                berkas.write_text(isi[:m.start()] + basi + isi[m.end():], encoding="utf-8")
                kode5, _ = jalankan_pemeriksa(main, tmp5)
                hasil.append(("mutasi: angka berkas uji dibuat basi", kode5 != 0,
                              "ditolak" if kode5 != 0 else "DILOLOSKAN (angka basi tidak dijaga)"))
    return laporkan("periksa-panduan", hasil)


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(main())
