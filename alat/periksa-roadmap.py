#!/usr/bin/env python3
"""periksa-roadmap.py — pemeriksa otomatis docs/ROADMAP.md (Resto Barokah).

Tujuan: memastikan daftar tugas BENAR-BENAR lengkap dan tidak ada tugas yang cacat,
tanpa mengandalkan ingatan agent. Dijalankan sebelum fase baru dimulai dan di CI.

    python3 alat/periksa-roadmap.py

Yang diperiksa:
  1. Setiap tugas punya 7 atribut wajib (Tujuan, Ref, File, DoD, Kompleksitas, Risiko & mitigasi, Verifikasi).
  2. Semua fitur Must Have M1–M12 disebut minimal sekali di kolom Ref.
  3. Semua entitas data model (TECH_SPEC §4) punya jejak di ROADMAP.
  4. Semua RPC inti (TECH_SPEC §5) punya jejak.
  5. Semua Area Berisiko Tinggi ART-1…ART-10 muncul bersama lambang ⚠️.
  6. Semua tanda ❓ memakai ID yang benar-benar ada di docs/TERTANGGUH.md.
  7. Hal kecil (README, .env.example, favicon, error, memuat/kosong, a11y, responsif) & integrasi
     (Supabase, Google, Resend, Cloudflare, pg_cron) punya tugasnya.
  8. Tugas TERBUKA tidak boleh menunjuk nomor migrasi yang sudah dipakai berkas lain (lihat
     `cek_nomor_migrasi`) — rujukan kerja ulang ke berkas yang memang ada tetap diterima.

Mode `--uji-diri`: salin pohon ke folder sementara, rusak/ulangi nomornya, pastikan pemeriksa
MENOLAK yang cacat dan MENERIMA yang sah (termasuk dua kasus kontrol negatif).
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ROADMAP = ROOT / "docs" / "ROADMAP.md"
TERTANGGUH = ROOT / "docs" / "TERTANGGUH.md"

ATRIBUT = ["**Tujuan:**", "**Ref:**", "**File:**", "**DoD", "**Kompleksitas:**",
           "**Risiko & mitigasi:**", "**Verifikasi:**"]

FITUR = [f"M{i}" for i in range(1, 13)]

TEK_SPEC = ROOT / "docs" / "TECH_SPEC.md"


def nama_entitas() -> list[str]:
    """Nama tabel diambil LANGSUNG dari dokumen terkunci `TECH_SPEC.md` §4 (bukan daftar tangan yang bisa basi).

    Dasar perubahan (temuan review independen W3-03): daftar tangan lama memuat nama pendek
    (`kategori`, `stok`) yang bukan nama tabel resmi, sehingga gerbangnya hijau palsu.
    """
    if not TEK_SPEC.is_file():
        return []
    return sorted(set(re.findall(r"^\|\s*`([a-z_]+)`\s*\|", TEK_SPEC.read_text(encoding="utf-8"), re.M)))


def nama_rpc() -> list[str]:
    """Nama RPC diambil dari `rpc/nama` di `TECH_SPEC.md` §5."""
    if not TEK_SPEC.is_file():
        return []
    return sorted(set(re.findall(r"`rpc/([a-z_]+)`", TEK_SPEC.read_text(encoding="utf-8"))))


ART = [f"ART-{i}" for i in range(1, 11)]

HAL_KECIL = {"README": "README", ".env.example": ".env.example", "favicon": "favicon",
             "halaman error": "TidakPunyaAkses", "keadaan memuat/kosong/gagal": "Keadaan",
             "a11y": "a11y", "responsif": "responsif"}

INTEGRASI = {"Supabase": "Supabase", "Google": "Google", "Resend": "Resend",
             "Cloudflare": "Cloudflare", "pg_cron": "pg_cron"}


def blok_tugas(teks: str) -> list[tuple[str, str]]:
    """Pisahkan ROADMAP menjadi blok per tugas → [(id, isi_blok)]."""
    hasil: list[tuple[str, str]] = []
    sekarang_id, sekarang_isi = None, []
    for baris in teks.splitlines():
        m = re.match(r"^- \[[ x]\] (T\d+-\d+) — (.+)$", baris)
        if m:
            if sekarang_id:
                hasil.append((sekarang_id, "\n".join(sekarang_isi)))
            sekarang_id, sekarang_isi = m.group(1), [m.group(2)]
        elif sekarang_id is not None:
            if baris.startswith("## ") or baris.strip() == "---":
                hasil.append((sekarang_id, "\n".join(sekarang_isi)))
                sekarang_id, sekarang_isi = None, []
            else:
                sekarang_isi.append(baris)
    if sekarang_id:
        hasil.append((sekarang_id, "\n".join(sekarang_isi)))
    return hasil


def nomor_migrasi_terpakai(akar: Path) -> set[str]:
    d = akar / "supabase" / "migrations"
    if not d.is_dir():
        return set()
    return {m.group(1) for p in d.glob("*.sql") if (m := re.match(r"(00\d{2})", p.name))}


def cek_nomor_migrasi(teks: str, akar: Path) -> list[str]:
    """Tugas yang BELUM dikerjakan tidak boleh menunjuk nomor migrasi yang sudah dipakai.

    Kelas cacat nyata (2026-09-18): Fase 1B direncanakan memakai migrasi `0011–0016`, tetapi
    0012/0013/0014 ternyata terpakai oleh berkas penutup celah review/audit yang menyusul di
    tengah jalan. Kalau nomor itu dibiarkan tertulis, sesi berikutnya akan membuat
    `supabase/migrations/0012_…` di atas berkas yang sudah ada — riwayat databasis tertimpa.
    Yang diperiksa HANYA judul tugas dan baris **File:** (kalimat narasi tidak dihitung, supaya
    catatan history seperti "diperbaiki di migrasi 0013" tidak menjadi temuan palsu).
    """
    sudah = nomor_migrasi_terpakai(akar)
    temuan: list[str] = []
    terlihat: set[str] = set()
    id_terkini, belum = None, False
    for baris in teks.splitlines():
        m = re.match(r"^- \[([ x])\] (T\d+-\d+)\b(.*)$", baris)
        if m:
            id_terkini, belum = m.group(2), m.group(1) == " "
            judul = m.group(3)
        elif id_terkini is not None and belum and "**File:**" in baris:
            judul = None
        else:
            continue
        if not belum:
            continue
        if judul is not None:
            # Judul tugas berbunyi "Migrasi NNNN" = tugas itu AKAN MEMBUAT migrasi baru.
            for nomor in re.findall(r"\b[Mm]igrasi\s+`?(00\d{2})`?", judul):
                if nomor in sudah:
                    kunci = f"{id_terkini}:{nomor}"
                    if kunci not in terlihat:
                        terlihat.add(kunci)
                        temuan.append(
                            f"{id_terkini}: judul menunjuk migrasi {nomor} yang SUDAH ADA di `supabase/migrations/` "
                            f"— nomor rencana basi; ambil nomor bebas berikutnya dan catat di DECISIONS_LOG.md")
            continue
        # Baris **File:** `supabase/migrations/NNNN_nama.sql` hanya bermasalah kalau nomornya
        # sudah dipakai berkas lain. Kalau berkas itu memang ada (mis. T1-37 menunjuk ulang
        # `0011_peran_tunggal.sql` yang akan dibongkar), itu rujukan kerja ulang — BUKAN tabrakan.
        for nomor, nama in re.findall(r"supabase/migrations/(00\d{2})_([\w.-]+)\.sql", baris):
            if nomor in sudah and not (akar / "supabase" / "migrations" / f"{nomor}_{nama}.sql").is_file():
                kunci = f"{id_terkini}:{nomor}"
                if kunci not in terlihat:
                    terlihat.add(kunci)
                    temuan.append(
                        f"{id_terkini}: membuat `supabase/migrations/{nomor}_{nama}.sql` padahal nomor {nomor} "
                        f"sudah dipakai berkas lain — ambil nomor bebas berikutnya dan catat di DECISIONS_LOG.md")
    return temuan


def main(akar: Path | None = None) -> int:
    global ROOT, ROADMAP, TERTANGGUH, TEK_SPEC
    if akar is not None:
        ROOT = Path(akar)
        ROADMAP = ROOT / "docs" / "ROADMAP.md"
        TERTANGGUH = ROOT / "docs" / "TERTANGGUH.md"
        TEK_SPEC = ROOT / "docs" / "TECH_SPEC.md"
    if not ROADMAP.is_file():
        print("GAGAL: docs/ROADMAP.md tidak ada")
        return 1
    teks = ROADMAP.read_text(encoding="utf-8")
    tugas = blok_tugas(teks)
    gagal: list[str] = []
    catatan: list[str] = []

    if len(tugas) < 100:
        gagal.append(f"jumlah tugas mencurigakan: {len(tugas)} (harusnya ratusan)")

    for tid, isi in tugas:
        kurang = [a for a in ATRIBUT if a not in isi]
        if kurang:
            gagal.append(f"{tid}: atribut hilang → {', '.join(kurang)}")
        if "⚠️" in isi and "DECISIONS_LOG" not in isi:
            gagal.append(f"{tid}: bertanda ⚠️ tetapi tidak menyebut DECISIONS_LOG")

    isi_tugas = "\n".join(isi for _, isi in tugas)
    for m in FITUR:
        if not re.search(rf"\b{m}\b", teks):
            gagal.append(f"fitur wajib {m} tidak punya tugas")
    for e in nama_entitas():
        if e not in isi_tugas:
            gagal.append(f"entitas '{e}' (TECH_SPEC §4) tidak disebut di blok tugas mana pun")
    for r in nama_rpc():
        if r not in isi_tugas:
            gagal.append(f"RPC '{r}' (TECH_SPEC §5) tidak disebut di blok tugas mana pun")
    for a in ART:
        if not re.search(rf"{a}\b", teks):
            gagal.append(f"Area Berisiko Tinggi {a} tidak disinggung")
        elif f"{a} " not in teks and f"{a}(" not in teks and f"{a}/" not in teks and f"({a})" not in teks:
            catatan.append(f"{a} disinggung tanpa konteks jelas — periksa manual")
    tugas_berisiko = sum(1 for _, isi in tugas if "⚠️" in isi)
    if tugas_berisiko < 20:
        gagal.append(f"hanya {tugas_berisiko} tugas bertanda ⚠️ — Area Berisiko seharusnya tersebar di banyak tugas")

    ids_tertangguh = set(re.findall(r"\|\s*(T-\d{3})\s*\|", TERTANGGUH.read_text(encoding="utf-8"))) if TERTANGGUH.is_file() else set()
    tanda_tanya = set(re.findall(r"❓\s*(T-\d{3})", teks))
    if not tanda_tanya:
        gagal.append("tidak ada tanda ❓ T-xxx (padahal ada butir tertangguh)")
    for t in sorted(tanda_tanya - ids_tertangguh):
        gagal.append(f"RUJUKAN MATI: ❓ {t} tidak ada di docs/TERTANGGUH.md")

    # 8. Nomor migrasi rencana tidak boleh menunjuk berkas yang sudah ada (lihat fungsi di atas).
    temuan_nomor = cek_nomor_migrasi(teks, ROOT)
    for t in temuan_nomor:
        gagal.append(t)

    for label, pola in HAL_KECIL.items():
        if pola not in teks:
            gagal.append(f"hal kecil terlewat: {label}")
    for label, pola in INTEGRASI.items():
        if pola not in teks:
            gagal.append(f"integrasi terlewat: {label}")

    # ringkasan
    per_fase: dict[str, int] = {}
    for tid, _ in tugas:
        f = tid.split("-")[0]
        per_fase[f] = per_fase.get(f, 0) + 1
    print("PERIKSA ROADMAP — Resto Barokah")
    print(f"  Tugas        : {len(tugas)}  ({', '.join(f'{k}:{v}' for k, v in sorted(per_fase.items()))})")
    print(f"  Atribut 7x   : {'lengkap' if not any('atribut hilang' in g for g in gagal) else 'ADA YANG KURANG'}")
    print(f"  Fitur M1-M12 : {'lengkap' if not any('fitur wajib' in g for g in gagal) else 'ADA YANG KURANG'}")
    print(f"  ⚠️ DECISIONS : {tugas_berisiko} tugas bertanda (dihitung per blok tugas, bukan kemunculan lambang)")
    print(f"  Entitas §4   : {len(nama_entitas())} tabel resmi TECH_SPEC — semuanya wajib disebut di blok tugas")
    print(f"  RPC §5       : {len(nama_rpc())} nama resmi TECH_SPEC — semuanya wajib disebut di blok tugas")
    print(f"  ❓ tertangguh : {len(tanda_tanya)} rujukan" + (" (semua sah)" if tanda_tanya <= ids_tertangguh else " (ADA YANG MATI)"))
    print(f"  Nomor migrasi: {'bersih — tidak ada tugas terbuka yang menunjuk nomor terpakai' if not temuan_nomor else f'{len(temuan_nomor)} NOMOR BASI'}"
          f"  ({len(nomor_migrasi_terpakai(ROOT))} berkas migrasi ada di repo)")
    if catatan:
        print("  Catatan      : " + "; ".join(catatan))
    if gagal:
        print(f"\nGAGAL ({len(gagal)} temuan):")
        for g in gagal:
            print(f"  - {g}")
        return 1
    print("\nHASIL: LOLOS — semua pemeriksaan roadmap terpenuhi.")
    return 0


def uji_diri() -> int:
    """Buktikan butir 8 (nomor migrasi) peka: tabrakan nomor harus ditolak, rujukan kerja ulang diterima.

    Standar yang dipakai: PROTOKOL_AUDIT_INDEPENDEN §8 — pemeriksa yang tidak bisa MERAH dianggap
    belum terpasang. Karena itu ada DUA kontrol negatif (kasus yang harus tetap LOLOS), supaya
    pemeriksaan ini tidak berubah menjadi penolak acak.
    """
    from bantu_uji_diri import jalankan_pemeriksa, laporkan, salin_pohon

    hasil: list[tuple[str, bool, str]] = []
    with salin_pohon() as tmp:
        kode, keluar = jalankan_pemeriksa(main, tmp)
        hasil.append(("salinan utuh", kode == 0, f"kode {kode}"))
        if kode != 0:
            print(keluar[:1500])

        roadmap = tmp / "docs" / "ROADMAP.md"
        asli = roadmap.read_text(encoding="utf-8")

        def ubah(nama: str, cari: str, ganti: str, harus_gagal: bool) -> None:
            if cari not in asli:
                hasil.append((nama, False, "pola mutasi tidak ditemukan (perbarui uji-diri ini)"))
                return
            roadmap.write_text(asli.replace(cari, ganti, 1), encoding="utf-8")
            k, _ = jalankan_pemeriksa(main, tmp)
            sesuai = (k != 0) if harus_gagal else (k == 0)
            hasil.append((nama, sesuai,
                          ("ditolak" if k != 0 else "diterima")
                          + ("" if sesuai else " — TIDAK sesuai harapan (tumpul/bocor)")))
            roadmap.write_text(asli, encoding="utf-8")

        # 1) Tabrakan nomor di JUDUL tugas terbuka → wajib ditolak.
        ubah("mutasi: judul T1-24 menunjuk nomor terpakai (0015 → 0012)",
            "- [ ] T1-24 — Migrasi 0015:", "- [ ] T1-24 — Migrasi 0012:", True)
        # 2) Tabrakan lewat baris **File:** (nomor dipakai berkas lain) → wajib ditolak.
        ubah("mutasi: berkas T1-25 memakai nomor terpakai (0016 → 0013)",
             "`supabase/migrations/0016_sesi_perangkat.sql`",
             "`supabase/migrations/0013_sesi_perangkat.sql`", True)
        # 3) Kontrol negatif: nomor yang ditunjuk sudah ada TEPAT berkas yang dirujuk → boleh
        #    (ini kasus T1-37: menunjuk `0011_peran_tunggal.sql` untuk dibongkar ulang).
        ubah("kontrol negatif: File menunjuk berkas yang benar-benar ada",
             "`supabase/migrations/0016_sesi_perangkat.sql`",
             "`supabase/migrations/0012_penutup_celah_review.sql`", False)
        # 4) Kontrol negatif: angka di kalimat narasi (bukan judul/baris File) tidak dihitung.
        ubah("kontrol negatif: angka 0012 di kalimat catatan tidak dianggap tabrakan",
             "- [ ] T1-24 — Migrasi 0015:",
             "- [ ] T1-24 — Migrasi 0015:\n  - **Catatan uji:** dirujuk juga di migrasi `0012` sebagai pembanding.",
             False)
        # 5) Butir 8 tidak boleh menandai apa pun di ROADMAP yang benar hari ini.
        temuan = cek_nomor_migrasi(asli, tmp)
        hasil.append(("ROADMAP terkini bersih dari tabrakan nomor", not temuan,
                      "bersih" if not temuan else f"{len(temuan)} temuan: {temuan[0][:80]}"))

    return laporkan("PERIKSA ROADMAP — butir 8 (nomor migrasi)", hasil)


if __name__ == "__main__":
    sys.exit(uji_diri() if "--uji-diri" in sys.argv else main())
