#!/usr/bin/env python3
"""Pemeriksa kerangka uji (Fase 0 T0-10) — penjaga aturan TDD.

Masalah yang dicegah: "uji hanya formalitas". Alat ini memastikan dua hal:

1. Kerangkanya siap: Vitest terpasang, ada skrip `npm test`, dan konfigurasinya
   mengenal berkas uji di `src/`.
2. **Setiap berkas logika wajib punya berkas ujinya sendiri.** Yang dianggap
   logika = berkas di `src/lib/` dan `src/hook/`. Jadi begitu kode uang, izin,
   atau aturan bisnis ditulis mulai Fase 1, ujinya tidak bisa "lupa dibuat" —
   pemeriksa ini akan menolak.

3. **Uji yang NAMANYA menjanjikan interaksi wajib benar-benar melakukan interaksi.**
   Temuan audit I F-19 (2026-09-19): uji bernama "memanggil onUbah saat diisi" hanya
   merender HTML (SSR), memeriksa `type="text"`, lalu `expect(onUbah).not.toHaveBeenCalled()`
   — handler `onChange` tidak pernah tersambung pun pun uji itu hijau. Uji ber-nama kuat
   dengan badan lemah = rasa aman palsu. Aturan di sini: kalau nama uji memuat janji
   interaksi ("saat diisi", "saat diklik", …), badannya WAJIB memicu kejadian
   (`fireEvent` / `userEvent` / `dispatchEvent`, atau `.click(`/`.focus(`/`.type(`).

Jalankan: python3 aplikasi/alat/periksa-uji.py
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

AKAR_REPO = Path(__file__).resolve().parents[2]
APLIKASI = AKAR_REPO / "aplikasi"

ok: list[str] = []
info: list[str] = []
gagal: list[str] = []

AWALAN_UJI = (".test.", ".spec.")

# Nama uji yang MENJANJIKAN interaksi: badannya wajib benar-benar memicu kejadian.
KATA_JANJI_INTERAKSI = (
    "saat diisi", "saat diklik", "saat ditekan", "saat diubah", "saat diketik",
    "saat dipilih", "saat dikirim", "saat di-submit", "saat digulir", "saat disentuh",
    "memanggil on", "memicu on",
)
# Bukti tindakan di dalam badan uji.
BUKTI_TINDAKAN = (
    "fireEvent", "userEvent", "dispatchEvent", ".click(", ".focus(", ".blur(",
    ".type(", ".keyboard(",
)


def berkas_logika() -> list[Path]:
    hasil: list[Path] = []
    for folder in ("lib", "hook"):
        akar = APLIKASI / "src" / folder
        if not akar.is_dir():
            continue
        for berkas in sorted(akar.rglob("*")):
            if berkas.suffix not in {".ts", ".tsx"}:
                continue
            if any(tanda in berkas.name for tanda in AWALAN_UJI):
                continue
            if berkas.name.endswith(".d.ts"):
                continue
            hasil.append(berkas)
    return hasil


def punya_uji(berkas: Path) -> Path | None:
    for akhiran in (".test.ts", ".test.tsx", ".spec.ts", ".spec.tsx"):
        kandidat = berkas.with_name(berkas.stem + akhiran)
        if kandidat.exists():
            return kandidat
    return None


def uji_kerangka() -> None:
    pkg = APLIKASI / "package.json"
    if not pkg.exists():
        gagal.append("GAGAL: aplikasi/package.json tidak ada")
        return
    isi = json.loads(pkg.read_text(encoding="utf-8"))
    skrip = isi.get("scripts", {})
    dev = isi.get("devDependencies", {})

    if "test" in skrip and "vitest" in skrip["test"]:
        ok.append(f"OK: skrip uji ada (npm test → {skrip['test']})")
    else:
        gagal.append("GAGAL: skrip `npm test` belum memanggil vitest")

    for nama in ("vitest", "jsdom", "@testing-library/react"):
        if nama in dev:
            ok.append(f"OK: {nama} terpasang ({dev[nama]})")
        else:
            gagal.append(f"GAGAL: {nama} belum terpasang sebagai alat pengembangan")

    konfig = APLIKASI / "vitest.config.ts"
    if not konfig.exists():
        gagal.append("GAGAL: aplikasi/vitest.config.ts tidak ada")
        return
    isi_konfig = konfig.read_text(encoding="utf-8")
    if "src/**/*.test" in isi_konfig:
        ok.append("OK: konfigurasi uji mengenal berkas uji di src/")
    else:
        gagal.append("GAGAL: konfigurasi uji tidak menyertakan berkas uji src/**/*.test")


def uji_pasangan() -> None:
    daftar = berkas_logika()
    if not daftar:
        gagal.append("GAGAL: tidak ada berkas logika di src/lib atau src/hook (aneh)")
        return
    tanpa_uji = [b for b in daftar if punya_uji(b) is None]
    if tanpa_uji:
        for berkas in tanpa_uji:
            gagal.append(
                f"GAGAL: {berkas.relative_to(AKAR_REPO)} tidak punya berkas uji "
                f"({berkas.with_name(berkas.stem + '.test.ts')} wajib ada)"
            )
    else:
        ok.append(f"OK: {len(daftar)} berkas logika semuanya punya uji")

    # jumlah uji (perkiraan dari kata kunci) — berguna sebagai laporan
    jumlah = 0
    for berkas in sorted((APLIKASI / "src").rglob("*.test.*")):
        teks = berkas.read_text(encoding="utf-8")
        jumlah += len(re.findall(r"\bit\(|\btest\(", teks))
    info.append(f"INFO: {jumlah} uji terbaca di src/ (dijalankan oleh npm test)")


def badan_uji(teks: str) -> list[tuple[int, str, str]]:
    """Kembalikan [(baris, nama uji, badan uji)] — pembaca berbasis indentasi.

    Badan uji = baris-baris setelah `it('…', () => {` sampai `})` pada indentasi yang
    SAMA dengan baris `it(`. Heuristik ini cocok dengan bentuk berkas uji yang sudah
    diformat Prettier. Kalau sebuah `it(`/`test(` tidak menemukan penutupnya, berkas itu
    dianggap tidak terbaca → pemeriksa GAGAL (lebih baik berisik daripada buta).
    """
    hasil: list[tuple[int, str, str]] = []
    baris = teks.splitlines()
    i = 0
    while i < len(baris):
        m = re.match(r"^(?P<spasi>\s*)(?:it|test)\(\s*(?P<kutip>['\"`])(?P<nama>.*?)(?P=kutip)", baris[i])
        if not m:
            i += 1
            continue
        indentasi = len(m.group("spasi"))
        nama = m.group("nama")
        badan: list[str] = []
        j = i + 1
        ketemu = False
        while j < len(baris):
            b = baris[j]
            if b.strip() == "})" and (len(b) - len(b.lstrip())) == indentasi:
                ketemu = True
                break
            badan.append(b)
            j += 1
        if not ketemu:
            return []  # tidak terbaca → pemanggil memberi tahu
        hasil.append((i + 1, nama, "\n".join(badan)))
        i = j + 1
    return hasil


def uji_janji_interaksi() -> None:
    """Nama uji yang menjanjikan interaksi wajib punya tindakan nyata di badannya."""
    semua: list[Path] = []
    for akar_uji in (APLIKASI / "src", APLIKASI / "e2e"):
        if akar_uji.is_dir():
            semua.extend(sorted(akar_uji.rglob("*.test.*")))
    if not semua:
        gagal.append("GAGAL: tidak ada berkas uji di src/ atau e2e/ (aneh)")
        return
    diperiksa = 0
    tak_terbaca: list[str] = []
    for berkas in semua:
        teks = berkas.read_text(encoding="utf-8")
        if not re.search(r"\b(?:it|test)\(", teks):
            continue
        blok = badan_uji(teks)
        if not blok and re.search(r"\b(?:it|test)\(", teks):
            tak_terbaca.append(str(berkas.relative_to(AKAR_REPO)))
            continue
        for nomor, nama, badan in blok:
            if not any(k in nama.lower() for k in KATA_JANJI_INTERAKSI):
                continue
            diperiksa += 1
            if not any(b in badan for b in BUKTI_TINDAKAN):
                gagal.append(
                    f"GAGAL: {berkas.relative_to(AKAR_REPO)}:{nomor} — uji bernama {nama!r} MENJANJIKAN "
                    "interaksi tetapi badannya tidak memicu kejadian apa pun (tidak ada fireEvent/userEvent/"
                    "dispatchEvent/.click()/.focus()/.type()). Nama kuat + badan lemah = rasa aman palsu "
                    "(temuan audit I F-19). Kalau uji ini memang bukan uji interaksi, ganti namanya."
                )
    if tak_terbaca:
        gagal.append(
            "GAGAL: badan uji tidak terbaca (bentuk berkas di luar dugaan) di: " + ", ".join(tak_terbaca)
        )
    if diperiksa and not gagal:
        ok.append(f"OK: {diperiksa} uji berjanji interaksi semuanya memicu kejadian nyata")


def periksa(akar: Path) -> int:
    """Jalankan semua pemeriksaan terhadap `akar` (dipakai juga oleh uji-diri)."""
    global AKAR_REPO, APLIKASI, ok, info, gagal
    AKAR_REPO, APLIKASI = akar, akar / "aplikasi"
    ok, info, gagal = [], [], []
    uji_kerangka()
    uji_pasangan()
    uji_janji_interaksi()
    return 1 if gagal else 0


def uji_diri() -> int:
    """Bukti pemeriksa ini bisa MENOLAK uji yang namanya lebih kuat dari badannya."""
    sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "alat"))
    from bantu_uji_diri import laporkan, salin_pohon

    hasil: list[tuple[str, bool, str]] = []
    with salin_pohon() as tmp:
        kode = periksa(tmp)
        hasil.append(("salinan utuh", kode == 0, f"kode {kode}"))
        if kode != 0:
            print("\n".join(gagal[:4]))

    CONTOH = "src/komponen/komponen.test.tsx"

    def mutasi(nama: str, ubah, harap_tolak: bool = True) -> None:
        with salin_pohon() as tmp:
            f = tmp / "aplikasi" / CONTOH
            isi = f.read_text(encoding="utf-8")
            baru = ubah(isi)
            if baru == isi:
                hasil.append((nama, False, "mutasi TIDAK mengubah berkas (pola tidak ketemu)"))
                return
            f.write_text(baru, encoding="utf-8")
            kode = periksa(tmp)
            sesuai = (kode != 0) if harap_tolak else (kode == 0)
            hasil.append((nama, sesuai, "ditolak" if kode else "diterima"))

    janji_tanpa_tindakan = (
        "\n  it('memanggil onUbah saat diisi palsu', () => {\n"
        "    const onUbah = vi.fn()\n"
        "    expect(onUbah).not.toHaveBeenCalled()\n"
        "  })\n"
    )
    janji_dengan_tindakan = (
        "\n  it('memanggil onUbah saat diisi (dengan tindakan)', () => {\n"
        "    const onUbah = vi.fn()\n"
        "    fireEvent.change(document.createElement('input'), { target: { value: 'x' } })\n"
        "    expect(onUbah).not.toHaveBeenCalled()\n"
        "  })\n"
    )
    nama_biasa = (
        "\n  it('memakai kelas rancangan tabel', () => {\n"
        "    expect(1).toBe(1)\n"
        "  })\n"
    )
    mutasi("mutasi: uji berjanji interaksi TANPA tindakan disisipkan",
           lambda s: s.rstrip("\n") + "\n" + janji_tanpa_tindakan)
    mutasi("kontrol: uji berjanji interaksi DENGAN fireEvent → tetap diterima",
           lambda s: s.rstrip("\n") + "\n" + janji_dengan_tindakan, harap_tolak=False)
    mutasi("kontrol: uji ber-nama biasa tanpa tindakan → tetap diterima",
           lambda s: s.rstrip("\n") + "\n" + nama_biasa, harap_tolak=False)

    with salin_pohon() as tmp:
        # Penjaga lain di pemeriksa ini (konfigurasi uji hilang) harus tetap berisik.
        (tmp / "aplikasi" / "vitest.config.ts").unlink()
        kode = periksa(tmp)
        hasil.append(("mutasi: vitest.config.ts dihapus → ditolak", kode != 0, "ditolak" if kode else "diterima"))

    return laporkan("periksa-uji", hasil)


def main() -> int:
    if "--uji-diri" in sys.argv:
        return uji_diri()
    kode = periksa(AKAR_REPO)
    for baris in ok + info + gagal:
        print(baris)
    print("-" * 60)
    print(f"kerangka uji: {len(ok)} OK · {len(info)} INFO · {len(gagal)} GAGAL")
    print("KEPUTUSAN:", "LOLOS" if not gagal else "GAGAL")
    return kode


if __name__ == "__main__":
    sys.exit(main())
