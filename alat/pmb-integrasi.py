#!/usr/bin/env python3
"""pmb-integrasi — alat Perencana untuk perintah Lee `integrasikan <cabang>` (PMB, rancangan §5).

Menggabungkan cabang giliran PMB ke cabang Perencana **baris demi baris** (bukan per hunk teks), supaya:
  • semua baris temuan/asumsi dipertahankan (tidak ada yang hilang atau tertimpa),
  • ID baru dari cabang dinomori ulang melanjutkan ID tertinggi yang sudah ada (rujukan di kartu/bukti ikut digeser),
  • baris yang diubah dua pihak berbeda (mis. dua hakim untuk potongan yang sama) TIDAK diputuskan mesin —
    dilaporkan sebagai SENGKETA untuk diselesaikan Perencana dengan aturan tertulis (README PMB-1 / rancangan §5).

Pakai:  python3 alat/pmb-integrasi.py origin/arena/<id>-resto-barokah [--tanpa-commit] [--laporan <berkas.json>]
Alur:   git merge --no-ff --no-commit <cabang>  →  tulis ulang berkas PMB-1 hasil gabungan baris  →  git add  →
        penjaga (periksa-pemeriksaan.py)  →  commit bila tanpa sengketa & penjaga LOLOS; bila ada sengketa: merge dibiarkan
        terbuka (MERGE_HEAD ada), laporan JSON ditulis, keluar kode 2 — Perencana menyelesaikan lalu commit sendiri.
Batas:  hanya berkas di docs/uji/pemeriksaan/PMB-1/ yang boleh berubah di cabang giliran; berkas lain → berhenti (kode 3).
Catatan: belum punya --uji-diri; divalidasi pada empat cabang nyata 2026-09-29 (ea8f, ea91, ea90 dengan 22 sengketa, ea92 dengan
        39 temuan +2 / 17 asumsi +4) — setiap langkah diikuti `periksa-pemeriksaan.py` LOLOS. Aturan sengketa: PMB-1/README.md.
"""
from __future__ import annotations

import json
import pathlib
import re
import subprocess
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent
PMB = "docs/uji/pemeriksaan/PMB-1/"
LEDGER = PMB + "BUKU_BESAR_TEMUAN.md"
ASUMSI = PMB + "ASUMSI.md"
PAPAN = PMB + "PAPAN.md"
RE_F = re.compile(r"PMB1-F-(\d{3})")
RE_A = re.compile(r"PMB1-A-(\d{3})")
RE_ID_PENUH = re.compile(r"PMB1-[FA]-\d{3}")
RE_ID_POLOS = re.compile(r"(?<![\w-])[FA]-\d{3}(?![\d-])")
RE_BARIS_PAPAN = re.compile(r"^\| ((?:[FXMDGLZ]-\d{2}|P-\d+A?-\d{2})) \|")


def git(*args: str, cek: bool = True) -> str:
    p = subprocess.run(["git", *args], cwd=AKAR, capture_output=True, text=True)
    if cek and p.returncode != 0:
        raise SystemExit(f"git {' '.join(args)} gagal: {p.stderr.strip()}")
    return p.stdout


def show_bytes(rev: str, path: str) -> bytes | None:
    p = subprocess.run(["git", "show", f"{rev}:{path}"], cwd=AKAR, capture_output=True)
    return p.stdout if p.returncode == 0 else None


def show(rev: str, path: str) -> str | None:
    b = show_bytes(rev, path)
    if b is None:
        return None
    # surrogateescape: byte yang bukan UTF-8 sah (mis. log terpotong) dipertahankan apa adanya saat ditulis kembali
    return b.decode("utf-8", "surrogateescape")


def baris_id(teks: str | None, awalan: str) -> dict[str, str]:
    """Baris tabel ber-ID (temuan/asumsi) → {ID: baris utuh}. Urutan mengikuti berkas."""
    out: dict[str, str] = {}
    for b in (teks or "").splitlines():
        if b.startswith(awalan):
            sel = b.strip().strip("|").split("|")
            out[sel[0].strip()] = b
    return out


def baris_papan(teks: str | None) -> dict[str, str]:
    out: dict[str, str] = {}
    for b in (teks or "").splitlines():
        m = RE_BARIS_PAPAN.match(b)
        if m:
            out[m.group(1)] = b
    return out


def maks_id(teks: str | None, awalan: str) -> int:
    """ID tertinggi yang benar-benar punya BARIS (bukan sekadar disebut di teks)."""
    nomor = [int(k[-3:]) for k in baris_id(teks, "| " + awalan)]
    return max(nomor) if nomor else 0


class Integrasi:
    def __init__(self, cabang: str) -> None:
        self.cabang = cabang
        self.base = git("merge-base", "HEAD", cabang).strip()
        self.sengketa: list[dict] = []
        self.catatan: list[str] = []
        self.peta: dict[str, str] = {}

    # ---------- penomoran ulang ----------
    def susun_peta(self) -> None:
        led_head, led_base, led_cab = show("HEAD", LEDGER), show(self.base, LEDGER), show(self.cabang, LEDGER)
        asu_head, asu_base, asu_cab = show("HEAD", ASUMSI), show(self.base, ASUMSI), show(self.cabang, ASUMSI)
        f_baru = sorted(set(baris_id(led_cab, "| PMB1-F-")) - set(baris_id(led_base, "| PMB1-F-")))
        a_baru = sorted(set(baris_id(asu_cab, "| PMB1-A-")) - set(baris_id(asu_base, "| PMB1-A-")))
        if f_baru:
            geser = (maks_id(led_head, "PMB1-F-") + 1) - int(f_baru[0][-3:])
            for fid in f_baru:
                self.peta[fid] = f"PMB1-F-{int(fid[-3:]) + geser:03d}"
            self.catatan.append(f"temuan baru {len(f_baru)}: {f_baru[0]}…{f_baru[-1]} → geser {geser:+d} → {self.peta[f_baru[0]]}…{self.peta[f_baru[-1]]}")
        if a_baru:
            geser = (maks_id(asu_head, "PMB1-A-") + 1) - int(a_baru[0][-3:])
            for aid in a_baru:
                self.peta[aid] = f"PMB1-A-{int(aid[-3:]) + geser:03d}"
            self.catatan.append(f"asumsi baru {len(a_baru)}: {a_baru[0]}…{a_baru[-1]} → geser {geser:+d} → {self.peta[a_baru[0]]}…{self.peta[a_baru[-1]]}")
        self.polos = {k[5:]: v[5:] for k, v in self.peta.items()}
        self.polos_dipakai: set[str] = set()

    def renum(self, teks: str) -> str:
        teks = RE_ID_PENUH.sub(lambda m: self.peta.get(m.group(0), m.group(0)), teks)

        def ganti(m: re.Match[str]) -> str:
            k = m.group(0)
            if k in self.polos:
                self.polos_dipakai.add(k)
                return self.polos[k]
            return k

        return RE_ID_POLOS.sub(ganti, teks)

    # ---------- gabungan baris ----------
    def gabung_tabel(self, path: str, awalan: str) -> str | None:
        head, base, cab = show("HEAD", path), show(self.base, path), show(self.cabang, path)
        if cab is None or cab == base:
            return None
        r_head, r_base, r_cab = baris_id(head, awalan), baris_id(base, awalan), baris_id(cab, awalan)
        hilang = set(r_base) - set(r_cab)
        if hilang:
            raise SystemExit(f"{path}: cabang MENGHAPUS baris {sorted(hilang)} — temuan/asumsi tidak boleh dihapus; hentikan integrasi")
        hasil_baris: list[str] = []
        teks_head = (head or "").rstrip("\n").split("\n")
        # tubuh: semua baris HEAD, baris ber-ID diganti bila cabang mengubahnya secara sah
        for b in teks_head:
            if b.startswith(awalan):
                fid = b.strip().strip("|").split("|")[0].strip()
                if fid in r_cab and fid in r_base and r_cab[fid] != r_base[fid]:
                    if r_head[fid] == r_base[fid]:
                        b = self.renum(r_cab[fid])                     # hanya cabang yang mengubah → ambil
                    elif r_head[fid] != self.renum(r_cab[fid]):
                        self.sengketa.append({"berkas": path, "id": fid, "head": r_head[fid], "cabang": self.renum(r_cab[fid]), "base": r_base[fid]})
            hasil_baris.append(b)
        # tambahan: baris baru cabang, dinomori ulang, sesuai urutan cabang
        for fid, b in r_cab.items():
            if fid not in r_base:
                hasil_baris.append(self.renum(b))
        # kepala/teks di luar tabel yang diubah cabang → catat saja (tidak diambil)
        non_tabel = lambda t: [x for x in (t or "").splitlines() if not x.startswith(awalan)]  # noqa: E731
        if non_tabel(cab) != non_tabel(base):
            self.catatan.append(f"{path}: cabang mengubah teks di luar baris tabel — TIDAK diambil (periksa manual bila perlu)")
        return "\n".join(hasil_baris) + "\n"

    def gabung_papan(self) -> str | None:
        head, base, cab = show("HEAD", PAPAN), show(self.base, PAPAN), show(self.cabang, PAPAN)
        if cab is None or cab == base:
            return None
        r_head, r_base, r_cab = baris_papan(head), baris_papan(base), baris_papan(cab)
        if set(r_cab) != set(r_base):
            raise SystemExit("PAPAN: cabang menambah/menghapus potongan — tidak diizinkan untuk giliran; hentikan integrasi")
        keluar = []
        for b in (head or "").rstrip("\n").split("\n"):
            m = RE_BARIS_PAPAN.match(b)
            if m:
                pid = m.group(1)
                if r_cab[pid] != r_base[pid]:
                    if r_head[pid] == r_base[pid]:
                        b = self.renum(r_cab[pid])
                    elif r_head[pid] != self.renum(r_cab[pid]):
                        self.sengketa.append({"berkas": PAPAN, "id": pid, "head": r_head[pid], "cabang": self.renum(r_cab[pid]), "base": r_base[pid]})
            keluar.append(b)
        return "\n".join(keluar) + "\n"

    def berkas_lain(self) -> dict[str, str]:
        """Berkas PMB-1 selain tiga tabel: baru → salin (dinomori ulang); kartu yang sudah ada → nama .n berikutnya."""
        hasil: dict[str, str] = {}
        berubah = git("diff", "--name-only", self.base, self.cabang).split()
        luar = [p for p in berubah if not p.startswith(PMB)]
        if luar:
            raise SystemExit(f"cabang menyentuh berkas di luar PMB-1 (pelanggaran kontrak giliran): {luar} — hentikan, lapor Lee")
        for path in berubah:
            if path in (LEDGER, ASUMSI, PAPAN):
                continue
            mentah = show_bytes(self.cabang, path)
            if mentah is None:
                raise SystemExit(f"{path}: cabang menghapus berkas — tidak diizinkan")
            isi_cab = show(self.cabang, path)
            try:
                mentah.decode("utf-8")
            except UnicodeDecodeError as e:
                self.catatan.append(f"{path}: memuat byte bukan UTF-8 (posisi {e.start}) — dipertahankan apa adanya, ID tetap dinomori ulang")
            isi_base, isi_head = show(self.base, path), show("HEAD", path)
            baru = self.renum(isi_cab)
            if isi_base is None:                      # berkas baru di cabang
                if isi_head is None or isi_head == baru:
                    hasil[path] = baru
                else:
                    m = re.match(r"^(.*/kartu/[KH]-[^./]+)(?:\.(\d+))?\.md$", path)
                    if not m:
                        self.sengketa.append({"berkas": path, "id": "(berkas baru sudah ada di HEAD dengan isi lain)", "head": "", "cabang": "", "base": ""})
                        continue
                    n = 2
                    while (AKAR / f"{m.group(1)}.{n}.md").exists():
                        n += 1
                    tujuan = f"{m.group(1)}.{n}.md"
                    hasil[tujuan] = baru
                    self.catatan.append(f"{path} sudah ada di HEAD (pihak lain) → disimpan sebagai {tujuan}")
            elif isi_head == isi_base or isi_head == baru:
                hasil[path] = baru
            else:
                self.sengketa.append({"berkas": path, "id": "(berkas diubah dua pihak)", "head": "", "cabang": "", "base": ""})
        return hasil

    # ---------- jalan ----------
    def jalankan(self, commit: bool, laporan: pathlib.Path | None) -> int:
        if (AKAR / ".git" / "MERGE_HEAD").exists():
            raise SystemExit("masih ada merge yang belum selesai (MERGE_HEAD) — selesaikan/commit dulu")
        if git("status", "--porcelain", "--", PMB).strip():
            raise SystemExit("pohon kerja PMB-1 belum bersih — commit/simpan dulu")
        self.susun_peta()
        tulis: dict[str, str] = {}
        for path, awalan in ((LEDGER, "| PMB1-F-"), (ASUMSI, "| PMB1-A-")):
            t = self.gabung_tabel(path, awalan)
            if t is not None:
                tulis[path] = t
        t = self.gabung_papan()
        if t is not None:
            tulis[PAPAN] = t
        tulis.update(self.berkas_lain())
        # merge git (riwayat: cabang jadi induk kedua), lalu timpa dengan hasil gabungan baris
        subprocess.run(["git", "merge", "--no-ff", "--no-commit", self.cabang], cwd=AKAR, capture_output=True, text=True)
        for path, isi in tulis.items():
            p = AKAR / path
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_bytes(isi.encode("utf-8", "surrogateescape"))
        # berkas yang hanya berkonflik di mata git tetapi tidak kita tulis (tidak ada perubahan sah) → kembalikan ke HEAD
        for path in git("diff", "--name-only", "--diff-filter=U").split():
            if path not in tulis:
                subprocess.run(["git", "checkout", "HEAD", "--", path], cwd=AKAR, capture_output=True)
        subprocess.run(["git", "add", "-A", "--", PMB], cwd=AKAR, check=True)
        print(f"INTEGRASI {self.cabang} (base {self.base[:7]})")
        for c in self.catatan:
            print("  ·", c)
        if self.polos_dipakai:
            print("  · rujukan tanpa awalan PMB1- yang ikut digeser:", ", ".join(sorted(self.polos_dipakai)))
        penjaga = subprocess.run([sys.executable, "alat/periksa-pemeriksaan.py"], cwd=AKAR, capture_output=True, text=True)
        print("  · penjaga:", "LOLOS" if penjaga.returncode == 0 else "GAGAL\n" + penjaga.stdout[-1500:])
        if laporan is not None:
            laporan.write_text(json.dumps({"cabang": self.cabang, "base": self.base, "peta": self.peta, "sengketa": self.sengketa,
                                           "catatan": self.catatan}, ensure_ascii=False, indent=1), encoding="utf-8")
        if self.sengketa:
            print(f"  · SENGKETA {len(self.sengketa)} — merge dibiarkan terbuka; selesaikan dengan aturan §5 lalu commit:")
            for s in self.sengketa:
                print(f"      - {s['berkas'].split('/')[-1]} {s['id']}")
            return 2
        if penjaga.returncode != 0:
            print("  · penjaga GAGAL — merge dibiarkan terbuka untuk diperbaiki tangan")
            return 1
        if commit:
            pesan = f"pmb: integrasikan {self.cabang.split('/', 1)[-1]} — " + "; ".join(self.catatan[:2] or ["tanpa ID baru"])
            subprocess.run(["git", "commit", "-q", "-m", pesan], cwd=AKAR, check=True)
            print("  · commit:", git("rev-parse", "--short", "HEAD").strip())
        return 0


def main(argv: list[str]) -> int:
    if not argv or argv[0].startswith("-"):
        print(__doc__)
        return 64
    laporan = None
    if "--laporan" in argv:
        laporan = pathlib.Path(argv[argv.index("--laporan") + 1])
    return Integrasi(argv[0]).jalankan(commit="--tanpa-commit" not in argv, laporan=laporan)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
