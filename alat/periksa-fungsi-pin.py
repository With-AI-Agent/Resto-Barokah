#!/usr/bin/env python3
"""Penjaga Edge Function PIN (T1-06).

Mengapa ada: PIN adalah data paling sensitif di aplikasi ini, dan cara paling umum PIN bocor bukan
lewat serangan canggih — melainkan lewat log yang mencatat permintaan, atau lewat kunci penuh
(service_role) yang dipakai supaya "gampang". Pemeriksa ini menolak kiriman kode bila salah satu
dari itu muncul kembali.

**Diperkuat 2026-09-20 (temuan audit I F-03, K-3).** Pemeriksa versi lama menjaga "PIN tidak pernah
disimpan/dikembalikan" hanya dengan mencari kata `console.` dan `pin_hash`. Dua cacat nyata
diloloskan (dibuktikan auditor dengan membaca berkas memori):

  * balasan yang MENGEMBALIKAN PIN (`{ ..., pin: pin }`) → 9/9 lolos, exit 0;
  * log lewat tanda kurung siku (`console['log'](pin)`) → 9/9 lolos, exit 0.

Pelajarannya: "menolak contoh" bukan sama dengan "menjaga aturan". Sekarang:

  * setiap bentuk `console` ditolak (titik, tanda kurung siku, alias, `globalThis.console`),
    begitu juga `Deno.stdout` / `Deno.stderr`;
  * variabel PIN **dibatasi ke tiga jalur sah** — dibaca dari badan permintaan, diperiksa bentuknya,
    dan diteruskan ke RPC. Muncul di tempat lain (balasan, pesan galat, log, penyimpanan peramban)
    = GAGAL, dan baris pelanggarnya dicetak apa adanya.

Yang diperiksa pada `supabase/functions/verifikasi_pin/index.ts`:

  1. berbentuk fungsi Edge (Deno.serve) dan meneruskan ke RPC `verifikasi_pin`;
  2. hanya menerima POST (menolak metode lain);
  3. tidak memakai `console` dalam bentuk apa pun (PIN tidak mungkin masuk log);
  4. tidak menyebut service_role (RLS tidak boleh dilewati);
  5. memakai Authorization pemanggil + kunci publik dari lingkungan;
  6. PIN dibaca dari badan permintaan;
  7. variabel PIN hanya dipakai di jalur sah (baca · periksa bentuk · teruskan ke RPC);
  8. tidak menyentuh hash PIN maupun penyimpanan peramban;
  9. (I F-02/H F-04) badan RPC memuat `p_pesanan_id` dan aksi berkupon
     (`void_sesudah_dapur`, `beri_diskon`) terdaftar sebagai wajib-pesanan di batas Edge;
 10. (H F-09) CORS tidak memakai wildcard `*` — asal dibatasi daftar sah.

Jalankan:
  python3 alat/periksa-fungsi-pin.py            # memeriksa berkas Edge Function
  python3 alat/periksa-fungsi-pin.py --uji-diri # membuktikan pemeriksa bisa MENOLAK (fixture negatif)
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

AKAR = Path(__file__).resolve().parent.parent
BERKAS = AKAR / "supabase" / "functions" / "verifikasi_pin" / "index.ts"

# Jalur sah untuk variabel PIN — di luar ini, memakainya = kemungkinan bocor.
# Pembacaan dari badan permintaan: `isi['pin']`, `badan.pin`, `const { pin } = …`.
# `(?<!\$)` penting: `${pin}` di dalam template BUKAN pembacaan, itu justru kebocoran.
POLA_BACA_PIN = re.compile(r"\[\s*['\"]pin['\"]\s*\]|\.\s*pin\b|(?<!\$)\{\s*pin\b")
POLA_PERIKSA_PIN = re.compile(r"typeof|\.test\(|\.length|\.trim\(|Number\.|===|!==|==|!=|!\s*[A-Za-z_$]")

POLA_BACA_DARI_BADAN = POLA_BACA_PIN


def rentang_teruskan_rpc(kode: str) -> list[tuple[int, int]]:
    """Rentang karakter tiap panggilan `fetch(...)` yang menuju jalur RPC.

    Dipakai supaya izin "PIN boleh ada di sini" melekat pada TEMPATNYA, bukan pada kata kunci:
    baris `p_pin: pin` di dalam panggilan fetch ke `rpc/` sah; `p_pin: pin` di balasan tidak.
    """
    rentang: list[tuple[int, int]] = []
    for m in re.finditer(r"\bfetch\s*\(", kode):
        i = kode.index("(", m.start())
        dalam, j = 0, i
        while j < len(kode):
            if kode[j] == "(":
                dalam += 1
            elif kode[j] == ")":
                dalam -= 1
                if dalam == 0:
                    break
            j += 1
        if "rpc/" in kode[i:j]:
            rentang.append((i, j))
    return rentang


def baca_nama_pin(kode: str) -> set[str]:
    """Nama variabel yang menyimpan PIN (selain nama `pin` itu sendiri bila dipakai)."""
    nama = {"pin"}
    for m in re.finditer(
        r"\b(?:const|let|var)\s+([A-Za-z_$][\w$]*)\s*=\s*[^;\n]*(?:\[\s*['\"]pin['\"]\s*\]|\.\s*pin\b)", kode
    ):
        nama.add(m.group(1))
    for m in re.finditer(r"\b(?:const|let|var)\s*\{\s*(?:pin\b\s*:\s*([A-Za-z_$][\w$]*)|pin\b)", kode):
        if m.group(1):
            nama.add(m.group(1))
    return nama


def baris_langgar_pin(kode: str) -> list[str]:
    """Baris yang memakai variabel PIN di LUAR jalur sah (baca · periksa · teruskan ke RPC)."""
    nama = baca_nama_pin(kode)
    rentang = rentang_teruskan_rpc(kode)
    langgar: list[str] = []
    offset = 0
    for mentah in kode.splitlines():
        baris = mentah.strip()
        awal, akhir = offset, offset + len(mentah)
        offset = akhir + 1
        if not baris:
            continue
        pakai = [n for n in nama if re.search(rf"\b{re.escape(n)}\b", baris)]
        if not pakai:
            continue
        di_jalur_rpc = any(a <= awal and akhir <= b for a, b in rentang)
        if di_jalur_rpc or POLA_BACA_PIN.search(baris) or POLA_PERIKSA_PIN.search(baris):
            continue
        langgar.append(baris)
    return langgar


def periksa_isi(isi: str) -> list[tuple[str, bool, str]]:
    """Jalankan semua aturan pada ISI berkas (dipisah dari pembacaan berkas supaya bisa diuji)."""
    hasil: list[tuple[str, bool, str]] = []

    def periksa(nama: str, syarat: bool, catatan: str) -> None:
        hasil.append((nama, bool(syarat), catatan))

    kode = "\n".join(b for b in isi.splitlines() if not b.strip().startswith(("//", "*", "/*")))

    periksa("berkas ada & tidak kosong", len(isi.strip()) > 200, f"{len(isi)} huruf")
    periksa("berbentuk Edge Function (Deno.serve)", "Deno.serve" in kode, "memakai Deno.serve")
    periksa(
        "meneruskan ke RPC verifikasi_pin",
        re.search(r"rpc/\$\{?RPC\}?|rpc/verifikasi_pin", kode) is not None,
        "memanggil /rest/v1/rpc/verifikasi_pin",
    )
    periksa(
        "hanya menerima POST",
        "'POST'" in kode and "405" in kode,
        "metode selain POST dijawab 405",
    )
    # I F-02 / H F-04: tanpa p_pesanan_id, kupon persetujuan lahir tak terikat pesanan
    # dan jalur void/diskon buntu dari perangkat kasir.
    periksa(
        "meneruskan p_pesanan_id ke RPC (I F-02/H F-04: kupon wajib terikat pesanan)",
        "p_pesanan_id" in kode,
        "badan RPC memuat p_pesanan_id",
    )
    periksa(
        "aksi berkupon mewajibkan pesanan di batas Edge (void_sesudah_dapur & beri_diskon)",
        "void_sesudah_dapur" in kode and "beri_diskon" in kode,
        "daftar AKSI_WAJIB_PESANAN ada di Edge",
    )
    # H F-09: wildcard CORS diganti daftar asal sah.
    # Regex menangkap dua bentuk penugasan: properti objek (`'...': '*'`) maupun
    # penugasan (`kepala['...'] = '*'`) — fixture uji-diri memakai bentuk kedua.
    periksa(
        "CORS tidak wildcard (H F-09: asal dibatasi daftar sah)",
        re.search(r"Access-Control-Allow-Origin['\"]?\]?\s*[:=]\s*'\*'", isi) is None,
        "tidak ada Access-Control-Allow-Origin: * dalam bentuk apa pun",
    )
    # F-03a: `console['log']`, alias (`const c = console`), dan `globalThis.console` dulu lolos.
    console = re.search(r"\bconsole\b", kode) is not None
    deno_out = re.search(r"\bDeno\s*\.\s*(?:stdout|stderr)\b", kode) is not None
    periksa(
        "TIDAK memakai console dalam bentuk apa pun (PIN tidak mungkin masuk log)",
        not console and not deno_out,
        "tidak ada kata `console` (juga menutup console['log'] dan alias) maupun Deno.stdout/stderr",
    )
    periksa(
        "TIDAK memakai service_role (RLS tidak dilewati)",
        "service_role" not in kode and "SERVICE_ROLE" not in kode,
        "memakai kunci publik + token pemanggil",
    )
    periksa("memakai token pemanggil (Authorization)", "Authorization" in kode, "header Authorization diteruskan apa adanya")
    periksa(
        "memakai kunci publik dari lingkungan, bukan tertulis di berkas",
        "SUPABASE_ANON_KEY" in kode and "Deno.env.get" in kode and "eyJ" not in kode,
        "kunci dibaca dari Deno.env",
    )
    periksa(
        "PIN dibaca dari badan permintaan",
        POLA_BACA_DARI_BADAN.search(kode) is not None,
        "membaca `pin` dari isi permintaan (bukan dari URL/header)",
    )
    # F-03b: aliran PIN — hanya jalur sah. Ini yang menangkap `pin: pin` di balasan,
    # `${pin}` di pesan galat, dan `setItem('pin', pin)`.
    langgar = baris_langgar_pin(kode)
    periksa(
        "variabel PIN hanya dipakai di jalur sah (baca · periksa bentuk · teruskan ke RPC)",
        not langgar,
        "tidak ada pemakaian PIN di balasan/pesan/log/penyimpanan"
        if not langgar
        else f"{len(langgar)} baris di luar jalur sah, mis. `{langgar[0][:90]}`",
    )
    periksa(
        "PIN tidak pernah disimpan/dikembalikan",
        "pin_hash" not in kode and "setItem" not in kode,
        "tidak menyentuh hash maupun penyimpanan peramban",
    )
    return hasil


# ---------------------------------------------------------------------------- uji diri
def _fixture_balasan_pin(isi: str) -> str:
    """Balasan yang MENGEMBALIKAN PIN (cacat asli yang dulu lolos 9/9)."""
    return isi.replace(
        "    {\n      berhasil: hasil?.berhasil === true,",
        "    {\n      pin: pin,\n      berhasil: hasil?.berhasil === true,",
        1,
    )


def _fixture_tanpa_baca_pin(isi: str) -> str:
    """PIN tidak lagi diambil dari kunci `pin` di badan permintaan (mis. diganti kunci lain)."""
    return isi.replace("['pin']", "['kode_rahasia']")


def _fixture_pesan_pin(isi: str) -> str:
    """Pesan galat yang memuat PIN (bocor lewat UI/log pemanggil)."""
    return isi.replace(
        "  if (!jawab.ok) {",
        "  if (!jawab.ok) {\n    // (fixture) PIN dimasukkan ke pesan galat\n"
        "    const bocor = `PIN ${pin} tidak bisa diperiksa`;",
        1,
    )


def _fixture_tanpa_pesanan_id(isi: str) -> str:
    """p_pesanan_id dilepas dari badan RPC (kupon kembali bisa lahir tak terikat)."""
    return isi.replace("        p_pesanan_id: pesananId,\n", "", 1)


def _fixture_cors_wildcard(isi: str) -> str:
    """CORS dikembalikan ke wildcard (H F-09 mundur)."""
    return isi.replace(
        "  if (asal !== null && ASAL_DIIZINKAN.includes(asal)) kepala['Access-Control-Allow-Origin'] = asal",
        "  kepala['Access-Control-Allow-Origin'] = '*'",
        1,
    )


def uji_diri() -> int:
    """Buktikan pemeriksa bisa MENOLAK fixture cacat (dengan alasan yang benar) & MENERIMA yang sah."""
    if not BERKAS.exists():
        print(f"GAGAL: berkas tidak ada: {BERKAS.relative_to(AKAR)}")
        return 1
    asli = BERKAS.read_text(encoding="utf-8")

    def aturan_gagal(isi: str) -> list[str]:
        return [n for n, lulus, _ in periksa_isi(isi) if not lulus]

    kasus: list[tuple[str, str, str | None]] = [
        ("sumber sah (berkas nyata)", asli, None),
        (
            "log lewat tanda kurung siku: console['log'](pin)",
            asli.replace("  const penggunaId =", "  console['log'](pin)\n  const penggunaId =", 1),
            "console",
        ),
        (
            "log biasa (kontrol): console.log('x', pin)",
            asli.replace("  const penggunaId =", "  console.log('minta pin', pin)\n  const penggunaId =", 1),
            "console",
        ),
        (
            "log lewat ALIAS: const c = console; c.log(pin)",
            asli.replace("  const penggunaId =", "  const c = console\n  c.log(pin)\n  const penggunaId =", 1),
            "console",
        ),
        (
            "balasan MENGEMBALIKAN PIN (cacat asli yang dulu lolos)",
            _fixture_balasan_pin(asli),
            "variabel PIN hanya dipakai di jalur sah",
        ),
        (
            "PIN masuk pesan galat (template)",
            _fixture_pesan_pin(asli),
            "variabel PIN hanya dipakai di jalur sah",
        ),
        (
            "PIN disimpan di peramban: localStorage.setItem('pin', pin)",
            asli.replace("  const penggunaId =", "  localStorage.setItem('pin', pin)\n  const penggunaId =", 1),
            "variabel PIN hanya dipakai di jalur sah",
        ),
        (
            "PIN tidak lagi dibaca dari badan permintaan",
            # Fixture harus tahan penamaan variabel: berkas Edge sah-sah saja mengganti nama
            # pembungkus badan permintaan (`isi` → `badan`) — itu refactor, bukan cacat. Yang
            # diuji adalah aturannya: PIN wajib dibaca dari kunci `pin` di badan permintaan.
            _fixture_tanpa_baca_pin(asli),
            "PIN dibaca dari badan permintaan",
        ),
        (
            "jalur RPC dilepas (PIN dikirim ke alamat lain)",
            asli.replace("`${alamat}/rest/v1/rpc/${RPC}`", "`${alamat}/rest/v1/pin-langsung`"),
            "meneruskan ke RPC verifikasi_pin",
        ),
        (
            "p_pesanan_id dilepas dari badan RPC (I F-02/H F-04 mundur)",
            _fixture_tanpa_pesanan_id(asli),
            "meneruskan p_pesanan_id ke RPC",
        ),
        (
            "CORS dikembalikan ke wildcard (H F-09 mundur)",
            _fixture_cors_wildcard(asli),
            "CORS tidak wildcard",
        ),
    ]

    print("UJI DIRI — penjaga Edge Function PIN (harus bisa MENOLAK contoh cacat & MENERIMA yang sah)")
    rusak = 0
    for nama, isi, aturan_diharap in kasus:
        gagal = aturan_gagal(isi)
        if aturan_diharap is None:
            ok = not gagal
            catatan = "semua aturan lolos" if ok else f"padahal harus lolos, tapi gagal di: {gagal}"
        else:
            # Tolakan harus DATANG DARI aturan yang tepat — kalau gagal karena sebab lain,
            # pemeriksaannya tumpul (pelajaran audit I F-04).
            ok = any(aturan_diharap in g for g in gagal)
            catatan = f"gagal di: {gagal}" if gagal else "TIDAK MENOLAK SAMA SEKALI"
        rusak += 0 if ok else 1
        print(f"  [{'OK' if ok else 'X '}] {nama}: {catatan}")

    if rusak:
        print(f"\nHASIL: GAGAL — {rusak} kasus berperilaku salah (penjaga PIN belum bisa dipercaya)")
        return 1
    print(f"\nHASIL: LOLOS — sumber sah diterima, {len(kasus) - 1} contoh cacat ditolak DENGAN ALASAN yang benar.")
    return 0


def utama() -> int:
    if not BERKAS.exists():
        print(f"GAGAL: berkas tidak ada: {BERKAS.relative_to(AKAR)}")
        return 1

    hasil = periksa_isi(BERKAS.read_text(encoding="utf-8"))
    gagal = [h for h in hasil if not h[1]]
    print(f"Pemeriksa Edge Function PIN — {BERKAS.relative_to(AKAR)}")
    for nama, lulus, catatan in hasil:
        print(f"  {'LOLOS' if lulus else 'GAGAL'}  {nama}  [{catatan}]")
    print(f"\nRINGKASAN: {len(hasil) - len(gagal)} lolos, {len(gagal)} gagal")
    return 1 if gagal else 0


if __name__ == "__main__":
    sys.exit(uji_diri() if "--uji-diri" in sys.argv else utama())
