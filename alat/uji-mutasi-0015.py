#!/usr/bin/env python3
"""uji-mutasi-0015.py — bukti bahwa pagar penutup celah putaran16 BENAR-BENAR bekerja.

Menguji migrasi `supabase/migrations/0015_penutup_celah_putaran16.sql`:
  * bagian 1 — K-1: penanda pembatalan `resto.pembatalan_pesanan` bisa dipalsukan kasir
                 (uji: `supabase/tes/pembatalan_penanda_palsu.sql`)
  * bagian 2 — K-2a: void SATU item ikut membatalkan seluruh pesanan
                 (uji: `supabase/tes/void_satu_item.sql`)
  * bagian 3 — K-2b: diskon bisa ditanam sesudah pesanan lunas/batal (audit F-01)
                 (uji: `supabase/tes/diskon_sesudah_lunas.sql`)
  * bagian 4 — K-2c: hitungan nomor pesanan bocor antar resto (temuan PR-03)
                 (uji: `supabase/tes/nomor_pesanan_isolasi.sql`)
  * bagian 5 — K-2d: pesan PIN kembar memastikan PIN aktif kolega / oracle (temuan PR-04)
                 (uji: `supabase/tes/pin_bukan_oracle.sql`)
  * bagian 6 — F-01/F-02 audit AUD-3 2026-09-19: pajak & service dihitung dari subtotal
                 SEBELUM diskon, pembulatan tidak dibaca, pesanan lunas bisa dihitung ulang
                 dari perangkat (uji: `supabase/tes/urutan_uang.sql`)
  * bagian 8 — F-03/F-05/F-06 audit AUD-3 2026-09-19 (K-2): metode bayar nonaktif masih bisa
                 dipakai, pembatalan tidak idempoten, stempel lifecycle dikarang perangkat
                 (uji: `supabase/tes/metode_bayar_nonaktif.sql`,
                       `supabase/tes/pembatalan_sekali.sql`,
                       `supabase/tes/lifecycle_pesanan.sql`)
  * bagian 9 — F-04 audit AUD-3 2026-09-19 (K-2): status item bisa dilompati/dimundurkan dan
                 pembatalan pra-dapur tanpa jejak (uji: `supabase/tes/status_item_transisi.sql`)
  * bagian 10 — F-11 audit AUD-3 2026-09-19 (K-2): helper hierarki PIN bisa dipanggil klien
                 sebagai oracle dua UUID bebas (uji: `supabase/tes/pin_helper_pribadi.sql`)
  * bagian 10b — F-13 audit AUD-3 2026-09-19 (K-2, DUGAAN → mitigasi): nomor pesanan diambil
                 tanpa serialisasi (uji: `supabase/tes/nomor_pesanan_kunci.sql`)
  * bagian 11 — F-10 audit AUD-3 2026-09-19 (K-2): izin pegawai bocor lintas cabang ke admin
                 cabang lain (uji: `supabase/tes/rls_pengguna.sql`)
Gerbang yang tidak bisa MERAH dianggap belum terpasang — itu pelajaran mahal proyek ini.

**Penting (temuan audit I F-04, 2026-09-20):** MERAH saja TIDAK cukup. Harness ini dulu memakai
`lulus = (kode != 0)`, sehingga kegagalan lingkungan (`ERR_MODULE_NOT_FOUND`, `SyntaxError`,
"migrasi tidak bisa diterapkan") ikut dihitung sebagai "pagar bekerja" — mutasi yang merusak salinan
akan dilaporkan benar padahal tidak ada penjaga yang diuji. Sekarang penilaian memakai
`alat/klasifikasi_mutasi.py`: hanya merah yang **berasal dari asersi di berkas `supabase/tes/`**
(`HARAPAN TIDAK TERPENUHI` / `SEBAB PENOLAKAN BUKAN YANG DIHARAPKAN`) yang dihitung sebagai bukti.
Salinan yang rusak dilaporkan `BUKAN BUKTI` dan membuat harness GAGAL. Klasifikasinya diuji sendiri
oleh `python3 alat/uji-mutasi-0015.py --uji-diri`.

Cara kerjanya: salin repo ke folder sementara, RUSAK satu penjaga (atau kembalikan versi lama
dari migrasi 0014 yang bocor), lalu jalankan berkas uji regresinya. Kalau uji tetap hijau,
pagar itu tumpul → alat ini GAGAL.

Kontrol yang wajib lulus lebih dulu:
  (1) salinan TANPA mutasi → uji hijau;
  (2) setelah semua mutasi dipulihkan (salinan dibuat ulang tiap mutasi) → hijau lagi.

Jalankan:  python3 alat/uji-mutasi-0015.py
"""
from __future__ import annotations

import pathlib
import re
import shutil
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from klasifikasi_mutasi import HIJAU, MERAH_PAGAR, RUSAK, klasifikasi  # noqa: E402

AKAR = pathlib.Path(__file__).resolve().parent.parent
KERJA = pathlib.Path("/tmp/mutasi-0015-rb")
MIG = "supabase/migrations/0015_penutup_celah_putaran16.sql"
MIG14 = "supabase/migrations/0014_penutup_celah_putaran13.sql"
MIG16 = "supabase/migrations/0016_penutup_celah_pin_putaran18.sql"
MIG18 = "supabase/migrations/0018_perangkat_terdaftar.sql"
MIG21 = "supabase/migrations/0021_kunci_diskon.sql"
# 0025 menulis ulang `hitung_total` sebagai definisi efektif terakhir. Mutasi
# F-01/F-02 harus mengenai salinan ini, bukan definisi lama di 0015; kalau tidak,
# uji tetap hijau palsu meskipun pagar yang masih berjalan tidak pernah disentuh.
MIG25 = "supabase/migrations/0025_isolasi_identitas_null.sql"
UJI = "supabase/tes/pembatalan_penanda_palsu.sql"                       # bagian 1 (K-1)
UJI_PR02 = "supabase/tes/void_satu_item.sql"                            # bagian 2 (K-2a)
UJI_F01 = "supabase/tes/diskon_sesudah_lunas.sql"                       # bagian 3 (K-2b)
UJI_PR03 = "supabase/tes/nomor_pesanan_isolasi.sql"                     # bagian 4 (K-2c)
UJI_PR04 = "supabase/tes/pin_bukan_oracle.sql"                          # bagian 5 (K-2d)
UJI_UANG = "supabase/tes/urutan_uang.sql"                               # bagian 6 (F-01/F-02)
UJI_F03 = "supabase/tes/metode_bayar_nonaktif.sql"                      # bagian 8a (F-03)
UJI_F05 = "supabase/tes/pembatalan_sekali.sql"                          # bagian 8b (F-05)
UJI_F06 = "supabase/tes/lifecycle_pesanan.sql"                          # bagian 8c (F-06)
UJI_F04 = "supabase/tes/status_item_transisi.sql"                       # bagian 9 (F-04)
UJI_F11 = "supabase/tes/pin_helper_pribadi.sql"                         # bagian 10 (F-11)
UJI_F13 = "supabase/tes/nomor_pesanan_kunci.sql"                        # bagian 10b (F-13)
UJI_F10 = "supabase/tes/rls_pengguna.sql"                               # bagian 11 (F-10)
SEMUA_UJI = (UJI, UJI_PR02, UJI_F01, UJI_PR03, UJI_PR04, UJI_UANG, UJI_F03, UJI_F05, UJI_F06,
             UJI_F04, UJI_F11, UJI_F13, UJI_F10)


def segarkan_salinan() -> None:
    """Salinan kerja: seluruh berkas repo (kecuali folder besar) + pustaka uji lewat tautan."""
    if KERJA.exists():
        shutil.rmtree(KERJA)
    KERJA.mkdir(parents=True)
    p1 = subprocess.Popen(
        ["tar", "--exclude=.git", "--exclude=dist", "--exclude=build", "--exclude=coverage",
         "--exclude=__pycache__", "--exclude=.vite", "--exclude=node_modules", "-cf", "-", "."],
        cwd=AKAR, stdout=subprocess.PIPE,
    )
    p2 = subprocess.Popen(["tar", "-xf", "-"], cwd=KERJA, stdin=p1.stdout)
    p1.stdout.close()
    p2.wait()
    p1.wait()
    for paket in ("alat/node_modules", "aplikasi/node_modules"):
        asal = AKAR / paket
        tujuan = KERJA / paket
        if asal.exists() and not tujuan.exists():
            tujuan.parent.mkdir(parents=True, exist_ok=True)
            tujuan.symlink_to(asal)
    if not (KERJA / "alat/node_modules/@electric-sql/pglite").exists():
        print("GAGAL: salinan uji tidak punya pustaka uji (pglite). Jalankan dulu: npm ci --prefix alat")
        sys.exit(2)


def jalankan_uji(uji: str = UJI) -> tuple[int, str]:
    hasil = subprocess.run(
        ["node", "alat/uji-sql.mjs", uji], cwd=KERJA, capture_output=True, text=True, timeout=600
    )
    return hasil.returncode, hasil.stdout + hasil.stderr


def semua_hijau() -> tuple[bool, str]:
    """Kontrol: SEMUA berkas uji bagian 1–3 harus hijau lebih dulu."""
    for uji in SEMUA_UJI:
        kode, keluar = jalankan_uji(uji)
        if kode != 0:
            return False, keluar[-1200:]
    return True, ""


def ganti_terakhir(teks: str, lama: str, baru: str) -> str:
    """Ganti kemunculan TERAKHIR sebuah pola.

    Sejak 0015 menulis ulang fungsi yang sama di beberapa bagian (mis. `picu_item_jaga` di
    bagian 1 dan 9, `nomor_pesanan_berikutnya` di bagian 4 dan 10b), definisi yang BENAR-BENAR
    berlaku adalah `create or replace` TERAKHIR. Menyunting kemunculan pertama = mutasi tumpul
    (pelajaran CI merah 2026-09-20).
    """
    pos = teks.rfind(lama)
    if pos < 0:
        raise AssertionError("pola tidak ditemukan untuk ganti_terakhir")
    return teks[:pos] + baru + teks[pos + len(lama):]


def mutasi(nama: str, ubah, harap_merah: bool = True, uji: str = UJI,
           berkas_rel: str = MIG) -> tuple[str, bool, str]:
    berkas = KERJA / berkas_rel
    asli = berkas.read_text(encoding="utf-8")
    try:
        baru = ubah(asli)
        if baru == asli:
            return nama, False, "mutasi tidak mengubah apa pun (pola tidak ditemukan)"
        berkas.write_text(baru, encoding="utf-8")
        kode, keluar = jalankan_uji(uji)
        jenis, sebab = klasifikasi(kode, keluar)
        if harap_merah:
            # HANYA merah-karena-asersi yang dihitung bukti pagar bekerja (audit I F-04).
            lulus = jenis == MERAH_PAGAR
            catatan = {
                MERAH_PAGAR: f"MERAH (pagar bekerja) — {sebab}",
                HIJAU: "HIJAU — pagar TUMPUL",
            }.get(jenis, f"BUKAN BUKTI — {sebab}")
        else:
            lulus = jenis == HIJAU
            catatan = "HIJAU" if jenis == HIJAU else (f"BUKAN HIJAU — {sebab}" if jenis != HIJAU else "HIJAU")
        if not lulus:
            catatan += "\n" + "      " + "\n      ".join(keluar.strip().splitlines()[-6:])
        return nama, lulus, catatan
    finally:
        berkas.write_text(asli, encoding="utf-8")


def main() -> int:
    segarkan_salinan()

    hijau, keluar = semua_hijau()
    if not hijau:
        print("KONTROL GAGAL: salinan utuh pun tidak hijau — perbaiki dulu berkas ujinya.\n" + keluar)
        return 1
    print("  OK  kontrol: salinan utuh → SEMUA uji bagian 1–10 hijau")

    hasil: list[tuple[str, bool, str]] = []

    def blok_penolakan(teks: str) -> str:
        m = re.search(r"  -- 3\) Pembatalan item.*?\n  end if;\n", teks, re.S)
        if not m:
            raise AssertionError("blok penolakan pembatalan tidak ditemukan")
        return m.group(0)

    # 1) Pagar penolakan DIHAPUS seluruhnya → uji wajib MERAH.
    def hapus_pagar(t: str) -> str:
        return t.replace(blok_penolakan(t), "")

    hasil.append(mutasi("pagar penolakan pembatalan item dihapus", hapus_pagar))

    # 2) Pagar dikembalikan ke bentuk LAMA yang bocor (percaya `current_setting`) → wajib MERAH.
    def kembalikan_bocor(t: str) -> str:
        lama = """  if tg_op = 'UPDATE'
     and (new.status = 'batal' or new.qty < old.qty) then
    if v_pesanan.dikirim_ke_dapur_pada is not null
       or coalesce(v_pesanan.status, '') in ('dimasak', 'siap', 'lunas') then
      v_jejak := coalesce(current_setting('resto.pembatalan_pesanan', true), '');
      if v_jejak is distinct from v_pesanan.id::text then
        raise exception 'Pembatalan item setelah dapur mulai wajib lewat baris pembatalan resmi (alasan + persetujuan PIN atasan).';
      end if;
    end if;
  end if;
"""
        # Deklarasi `v_jejak` harus ditambahkan di SEMUA kemunculan fungsi (bagian 1 dan 9):
        # definisi `picu_item_jaga` yang berlaku adalah yang TERAKHIR. Dulu hanya kemunculan
        # PERTAMA yang disunting, sehingga mutasi ini sebenarnya **tidak pernah menguji pagar** —
        # migrasinya gagal dikompilasi (`"v_jejak" is not a known variable`) dan harness lama
        # (yang menghitung `kode != 0` sebagai bukti) melaporkannya "MERAH (benar)".
        # Ketahuan begitu penilai mutasi diperketat (audit I F-04, 2026-09-20).
        tanpa_deklarasi = "  v_peran   text;\nbegin"
        assert t.count(tanpa_deklarasi) >= 1
        return t.replace(blok_penolakan(t), lama).replace(
            tanpa_deklarasi, "  v_peran   text;\n  v_jejak   text;\nbegin"
        )

    hasil.append(mutasi("pagar dikembalikan ke versi lama yang mempercayai penanda (K-1)", kembalikan_bocor))

    # 3) Pemicu item dilepas → tidak ada penjaga sama sekali → wajib MERAH.
    def lepas_pemicu(t: str) -> str:
        # Pemicu 0014 masih terpasang dari migrasi sebelumnya, jadi "menghapus baris di 0015"
        # saja TIDAK cukup melepas penjaganya — mutasi ini harus benar-benar MELEPAS pemicunya
        # (drop tanpa create ulang), persis seperti keadaan "penjaga dicabut dari tabel".
        return t.replace(
            "drop trigger if exists item_jaga on public.pesanan_item;\n"
            "create trigger item_jaga\n  before insert or update on public.pesanan_item\n"
            "  for each row execute function public.picu_item_jaga();\n",
            "drop trigger if exists item_jaga on public.pesanan_item;\n",
            1,
        )

    hasil.append(mutasi("pemicu penjaga item dilepas dari tabel", lepas_pemicu))

    # 4) Pengecualian diam-diam untuk kasir → wajib MERAH (serangan diuji dari kursi kasir).
    def kecualikan_kasir(t: str) -> str:
        # Catatan (2026-09-20): definisi `picu_item_jaga` kini muncul DUA kali di berkas ini
        # (bagian 1 dan versi lengkapnya di bagian 9, yang menang saat migrasi dijalankan).
        # Mutasi harus menyentuh SEMUA kemunculan — kalau hanya yang pertama, versi bagian 9
        # menimpanya kembali dan mutasi jadi tumpul (kejadian nyata saat bagian 9 ditambahkan).
        return t.replace(
            "  if tg_op = 'UPDATE'\n     and (new.status = 'batal' or new.qty < old.qty) then",
            "  if tg_op = 'UPDATE'\n     and (new.status = 'batal' or new.qty < old.qty)\n     and v_peran <> 'kasir' then",
        )

    hasil.append(mutasi("pagar diberi pengecualian diam-diam untuk peran kasir", kecualikan_kasir))

    # 5) Pemicu resmi menulis ULANG penanda yang bisa dipalsukan (kembalinya jebakan lama) → RED.
    def tulis_ulang_penanda(t: str) -> str:
        return t.replace(
            "begin\n  -- CATATAN K-1 (2026-09-19): baris `perform set_config('resto.pembatalan_pesanan', …)`",
            "begin\n  perform set_config('resto.pembatalan_pesanan', new.pesanan_id::text, true);\n"
            "  -- CATATAN K-1 (2026-09-19): baris `perform set_config('resto.pembatalan_pesanan', …)`",
            1,
        )

    # Catatan jujur: mutasi ini SENDIRI tidak cukup memerahkan uji (penanda tidak lagi dibaca);
    # yang diuji adalah bahwa mengembalikan penanda WAJIB disertai kembalinya pagar lama — kalau
    # tidak, uji tetap hijau = tidak ada yang terluka. Karena itu harapannya: HIJAU.
    hasil.append(mutasi("pemicu resmi menulis ulang penanda lama (tanpa pagar lama)", tulis_ulang_penanda, harap_merah=False))

    # 6) Versi 0014 (yang bocor) dipakai ulang untuk fungsi penjaganya → wajib MERAH.
    def pakai_versi_0014(t: str) -> str:
        lama14 = (KERJA / MIG14).read_text(encoding="utf-8")
        m = re.search(r"create or replace function public\.picu_item_jaga\(\).*?\n\$\$;\n", lama14, re.S)
        if not m:
            raise AssertionError("fungsi picu_item_jaga versi 0014 tidak ditemukan")
        # Ambil kemunculan TERAKHIR: definisi yang benar-benar berlaku saat migrasi dijalankan.
        semua15 = list(re.finditer(r"create or replace function public\.picu_item_jaga\(\).*?\n\$\$;\n", t, re.S))
        if not semua15:
            raise AssertionError("fungsi picu_item_jaga versi 0015 tidak ditemukan")
        m15 = semua15[-1]
        return t[: m15.start()] + m.group(0) + t[m15.end():]

    hasil.append(mutasi("fungsi penjaga dikembalikan ke versi 0014 (yang bocor)", pakai_versi_0014))

    # ------------------------------------------------------------------ K-2a (PR-02)
    # 7) Pesanan selalu ditutup begitu ada baris pembatalan (perilaku 0014 yang bocor:
    #    void SATU item ikut membatalkan seluruh pesanan) → uji PR-02 wajib MERAH.
    def tutup_selalu(t: str) -> str:
        return t.replace(
            "  if new.pesanan_item_id is null or v_sisa_item = 0 then",
            "  if true then",
            1,
        )

    hasil.append(mutasi("pesanan selalu ditutup walau baru SATU item dibatalkan (versi 0014)",
                        tutup_selalu, uji=UJI_PR02))

    # 8) Pesanan yang ditutup tidak lagi menandai itemnya batal → keadaan setengah jalan
    #    (pesanan batal tapi item tampak masih terutang) → uji PR-02 wajib MERAH.
    def item_tidak_ditandai(t: str) -> str:
        return t.replace(
            """    update public.pesanan_item pi
       set status = 'batal'
     where pi.pesanan_id = new.pesanan_id
       and pi.status <> 'batal';
""",
            "",
            1,
        )

    hasil.append(mutasi("item pesanan yang ditutup tidak ikut ditandai batal", item_tidak_ditandai,
                        uji=UJI_PR02))

    # ------------------------------------------------------------------ K-2b (F-01)
    # 9) Pagar diskon sesudah lunas/batal dihapus → uji F-01 wajib MERAH.
    #    Sasaran = salinan 0021 (DEFINISI HIDUP): `create or replace` di 0021
    #    menutupi badan fungsi versi 0015, sehingga memutasi salinan 0015 tidak
    #    bisa memerahkan apa pun (pelajaran 2026-09-21: mutasi wajib menyasar
    #    definisi hidup, bukan teks asal yang sudah tertutup).
    def hapus_pagar_diskon(t: str) -> str:
        return t.replace(
            """  if v_status in ('lunas', 'batal') then
    raise exception 'Pesanan yang sudah % tidak boleh lagi ditambah/diubah/dihapus diskonnya — uang sudah tercatat. Jalur sah: pembatalan/void resmi (berikut persetujuan PIN atasan bila dapur sudah mulai).', v_status;
  end if;
""",
            "",
            1,
        )

    hasil.append(mutasi("pagar diskon sesudah lunas/batal dihapus (audit F-01)",
                        hapus_pagar_diskon, uji=UJI_F01, berkas_rel=MIG21))

    # 10) Pemicu diskon dilepas dari tabel (pagar ada tapi tidak terpasang) → wajib MERAH.
    def lepas_pemicu_diskon(t: str) -> str:
        return t.replace(
            "drop trigger if exists diskon_awal_pesanan on public.diskon_transaksi;\n"
            "create trigger diskon_awal_pesanan\n"
            "  before insert or update or delete on public.diskon_transaksi\n"
            "  for each row execute function public.picu_diskon_awal_pesanan();\n",
            "drop trigger if exists diskon_awal_pesanan on public.diskon_transaksi;\n",
            1,
        )

    hasil.append(mutasi("pemicu pagar diskon dilepas dari tabel", lepas_pemicu_diskon, uji=UJI_F01))

    # 11) Nama pemicu dibuat berjalan SETELAH `diskon_batas` → penolakan pada pesanan batal
    #     berbunyi tentang NILAI (subtotal 0), bukan STATUS. Uji F-01 §6 menuntut sebab yang
    #     benar, jadi mutasi ini WAJIB MERAH — sekaligus mengunci janji urutan pada komentar.
    def urutan_pemicu_dibalik(t: str) -> str:
        return t.replace(
            "drop trigger if exists diskon_awal_pesanan on public.diskon_transaksi;\n"
            "create trigger diskon_awal_pesanan\n",
            "drop trigger if exists diskon_awal_pesanan on public.diskon_transaksi;\n"
            "create trigger zdiskon_awal_pesanan\n",
            1,
        )

    hasil.append(mutasi("nama pemicu diubah sehingga berjalan setelah pemicu nilai (urutan rusak)",
                        urutan_pemicu_dibalik, uji=UJI_F01))

    # ------------------------------------------------------------------ K-2c (PR-03)
    # 12) Pagar isolasi lintas resto di penghitung nomor pesanan dihapus → uji PR-03 wajib MERAH.
    def hapus_pagar_nomor(t: str) -> str:
        # Catatan (2026-09-20): `nomor_pesanan_berikutnya` kini ditulis ULANG di bagian 10b
        # (kunci serialisasi F-13), jadi mutasi harus menyentuh kemunculan TERAKHIR.
        return ganti_terakhir(
            t,
            """  if auth.uid() is not null and not public.cabang_pantau_saya(p_cabang_id) then
    raise exception 'Cabang itu bukan cabang yang boleh Anda lihat — hitungan nomor pesanan tidak dibagikan antar resto.';
  end if;
""",
            "",
        )

    hasil.append(mutasi("pagar isolasi penghitung nomor pesanan dihapus (PR-03)",
                        hapus_pagar_nomor, uji=UJI_PR03))

    # ------------------------------------------------------------------ K-2d (PR-04)
    # 13) Pesan lama yang menyebut "pegawai lain" dikembalikan → uji PR-04 wajib MERAH.
    #     Catatan (2026-09-20): `simpan_pin` ditulis ulang di migrasi 0016 (F-14), dan yang
    #     berlaku adalah `create or replace` TERAKHIR — jadi mutasi diarahkan ke 0016.
    #     Catatan (2026-09-21): `simpan_pin` ditulis ulang LAGI di 0018 (perangkat terdaftar) —
    #     mutasi kini diarahkan ke 0018 (definisi berlaku).
    def kembalikan_pesan_bocor(t: str) -> str:
        return t.replace(
            "    return 'PIN itu tidak bisa dipakai — pilih angka lain.';",
            "    return 'PIN itu sudah dipakai pegawai lain di resto ini — pilih angka lain.';",
            1,
        )

    hasil.append(mutasi("pesan PIN kembar dikembalikan ke versi yang menyebut pegawai lain (PR-04)",
                        kembalikan_pesan_bocor, uji=UJI_PR04, berkas_rel=MIG18))

    # ---------------------------------------------------------- bagian 6 (AUD-3 F-01/F-02)
    # 14) Dasar pajak/service dikembalikan ke subtotal SEBELUM diskon (cacat asli) → MERAH.
    # 0025 menulis ulang `hitung_total` sebagai definisi efektif terakhir. Semua
    # mutasi F-01/F-02 di bawah sengaja menyasar 0025; menyentuh blok 0015 yang
    # sudah ditimpa akan menghasilkan hijau palsu.
    def pajak_dari_subtotal_kotor(t: str) -> str:
        return t.replace(
            """  v_dasar := greatest(v_subtotal - v_diskon, 0);
  v_pajak   := coalesce(round(v_dasar * coalesce(v_persen_pajak, 0) / 100), 0);
  v_service := coalesce(round(v_dasar * coalesce(v_persen_service, 0) / 100), 0);
  v_total := greatest(v_dasar + v_pajak + v_service, 0);""",
            """  v_dasar := greatest(v_subtotal, 0);
  v_pajak   := coalesce(round(v_dasar * coalesce(v_persen_pajak, 0) / 100), 0);
  v_service := coalesce(round(v_dasar * coalesce(v_persen_service, 0) / 100), 0);
  v_total := greatest(v_subtotal - v_diskon + v_pajak + v_service, 0);""",
            1,
        )

    hasil.append(mutasi("pajak & service dihitung dari subtotal SEBELUM diskon (cacat AUD-3 F-01a)",
                        pajak_dari_subtotal_kotor, uji=UJI_UANG, berkas_rel=MIG25))

    # 15) Pembulatan diabaikan lagi (cacat asli) → MERAH.
    def abaikan_pembulatan(t: str) -> str:
        return t.replace(
            "  if v_langkah > 0 then\n    v_total := (v_total / v_langkah) * v_langkah;\n  end if;",
            "  if false then\n    v_total := (v_total / v_langkah) * v_langkah;\n  end if;",
            1,
        )

    hasil.append(mutasi("pengaturan pembulatan diabaikan mesin (cacat AUD-3 F-01b)",
                        abaikan_pembulatan, uji=UJI_UANG, berkas_rel=MIG25))

    # 16) Penjaga pesanan lunas dilepas (cacat asli F-02) → MERAH.
    def lepas_penjaga_lunas(t: str) -> str:
        return t.replace(
            "  if auth.uid() is not null and pg_trigger_depth() = 0 and v_pesanan.status in ('lunas', 'batal') then",
            "  if false then",
            1,
        )

    hasil.append(mutasi("penjaga 'pesanan lunas tidak dihitung ulang' dilepas (cacat AUD-3 F-02)",
                        lepas_penjaga_lunas, uji=UJI_UANG, berkas_rel=MIG25))

    # 17) Pembulatan dibalik jadi KE ATAS → MERAH (mengunci arah yang diputuskan).
    def bulat_ke_atas(t: str) -> str:
        return t.replace(
            "    v_total := (v_total / v_langkah) * v_langkah;",
            "    v_total := ((v_total + v_langkah - 1) / v_langkah) * v_langkah;",
            1,
        )

    hasil.append(mutasi("arah pembulatan dibalik jadi KE ATAS (keputusan arah diuji)",
                        bulat_ke_atas, uji=UJI_UANG, berkas_rel=MIG25))

    # ---------------------------------------------------------- bagian 8 (AUD-3 F-03/F-05/F-06)
    # 18) Metode bayar nonaktif boleh dipakai lagi (cacat asli F-03) → MERAH.
    def metode_nonaktif_diizinkan(t: str) -> str:
        return t.replace(
            """    if not v_metode.aktif then
      raise exception 'Metode bayar itu sudah dinonaktifkan pemilik resto — pilih metode yang masih aktif.';
    end if;""",
            "    -- (mutasi) pemeriksaan aktif DIHAPUS",
            1,
        )

    hasil.append(mutasi("metode bayar nonaktif boleh dipakai mencatat uang (cacat AUD-3 F-03)",
                        metode_nonaktif_diizinkan, uji=UJI_F03))

    # 19) Penjaga idempotensi pembatalan dilepas (cacat asli F-05) → MERAH.
    def pembatalan_boleh_diulang(t: str) -> str:
        return t.replace(
            """  if new.pesanan_item_id is not null then
    if (select pi.status from public.pesanan_item pi where pi.id = new.pesanan_item_id) = 'batal' then
      raise exception 'Item ini sudah dibatalkan — kiriman ulang tidak dicatat lagi (satu aksi = satu jejak).';
    end if;
  elsif v_pesanan.status = 'batal' then
    raise exception 'Pesanan ini sudah dibatalkan — kiriman ulang tidak dicatat lagi (satu aksi = satu jejak).';
  end if;""",
            "  -- (mutasi) penjaga idempotensi pembatalan DIHAPUS",
            1,
        )

    hasil.append(mutasi("pembatalan bisa diulang untuk target yang sudah batal (cacat AUD-3 F-05)",
                        pembatalan_boleh_diulang, uji=UJI_F05))

    # 20) Penjaga stempel lifecycle dilepas (cacat asli F-06) → MERAH.
    def stempel_boleh_dikarang(t: str) -> str:
        return t.replace(
            """    if new.dibayar_pada is distinct from old.dibayar_pada then
      raise exception 'Stempel pembayaran (dibayar_pada) hanya diisi jalur peladen setelah pembayaran sah.';
    end if;
    if new.dibatalkan_pada is distinct from old.dibatalkan_pada
       or new.alasan_batal is distinct from old.alasan_batal then
      raise exception 'Stempel pembatalan hanya diisi jalur peladen setelah pembatalan resmi (baris pembatalan ber-PIN bila sesudah dapur).';
    end if;""",
            "    -- (mutasi) penjaga stempel lifecycle DIHAPUS",
            1,
        )

    hasil.append(mutasi("stempel lifecycle pesanan boleh dikarang perangkat (cacat AUD-3 F-06)",
                        stempel_boleh_dikarang, uji=UJI_F06))

    # ---------------------------------------------------------- bagian 9 (AUD-3 F-04)
    # 21) Aturan transisi status item dilepas (cacat asli F-04) → MERAH.
    def status_item_bebas(t: str) -> str:
        return t.replace(
            """  if tg_op = 'INSERT' then
    if new.status is distinct from 'baru' then
      raise exception 'Item baru selalu mulai dari status baru (diminta %). Pembatalan punya jalurnya sendiri: baris pembatalan beralasan.', new.status;
    end if;
  elsif new.status is distinct from old.status then
    if new.status = 'batal' then
      raise exception 'Pembatalan item WAJIB lewat baris pembatalan resmi (alasan + persetujuan PIN bila dapur sudah mulai) — bukan dengan mengubah status baris item.';
    end if;
    if not (old.status = 'baru' and new.status = 'dimasak')
       and not (old.status = 'dimasak' and new.status = 'siap') then
      raise exception 'Status item hanya maju satu langkah: baru → dimasak → siap (dari % ke %).', old.status, new.status;
    end if;
  end if;""",
            "  -- (mutasi) aturan transisi status item DIHAPUS",
            1,
        )

    hasil.append(mutasi("status item boleh dilompati / dimundurkan / jadi batal bebas (cacat AUD-3 F-04)",
                        status_item_bebas, uji=UJI_F04))

    # --------------------------------------------------------- bagian 10 (AUD-3 F-11)
    # 22) Hak execute helper hierarki PIN dikembalikan ke klien (cacat asli F-11) → MERAH.
    def buka_akses_helper(t: str) -> str:
        return t.replace(
            "revoke all on function public.peran_lebih_tinggi(uuid, uuid) from authenticated;",
            "grant execute on function public.peran_lebih_tinggi(uuid, uuid) to authenticated;",
            1,
        )

    hasil.append(mutasi("hak execute helper hierarki PIN dikembalikan ke klien (cacat AUD-3 F-11)",
                        buka_akses_helper, uji=UJI_F11))

    # 23) Pemakuan identitas dilepas (jawaban mengikuti UUID kiriman lagi) → MERAH.
    #     Catatan (2026-09-20): `peran_lebih_tinggi` ditulis ulang di migrasi 0016 (F-11/F-13),
    #     sehingga definisi yang berlaku ada di sana — mutasi diarahkan ke 0016.
    def paku_identitas_hilang(t: str) -> str:
        return ganti_terakhir(
            t,
            """  if auth.uid() is not null and p_pemanggil is distinct from auth.uid() then
    return false;
  end if;""",
            "  -- (mutasi) pemakuan identitas pemanggil DIHAPUS",
        )

    hasil.append(mutasi("pemakuan identitas pemanggil pada helper hierarki PIN dilepas",
                        paku_identitas_hilang, uji=UJI_F11, berkas_rel=MIG16))

    # -------------------------------------------------------- bagian 10b (AUD-3 F-13)
    # 24) Kunci serialisasi pengambilan nomor pesanan dilepas → MERAH.
    def kunci_nomor_hilang(t: str) -> str:
        return t.replace(
            "  perform pg_advisory_xact_lock(hashtextextended(p_cabang_id::text || ':' || p_tanggal::text, 0));",
            "  -- (mutasi) kunci serialisasi nomor pesanan DIHAPUS",
            1,
        )

    hasil.append(mutasi("kunci serialisasi pengambilan nomor pesanan dilepas (audit AUD-3 F-13)",
                        kunci_nomor_hilang, uji=UJI_F13))

    # 25) Fungsi pengambil nomor dikembalikan ke STABLE (tidak boleh mengunci) → MERAH.
    def nomor_kembali_stable(t: str) -> str:
        return t.replace(
            "language plpgsql\nvolatile    -- mengunci (advisory)",
            "language plpgsql\nstable      -- (mutasi) kembali STABLE",
            1,
        )

    hasil.append(mutasi("fungsi pengambil nomor dikembalikan ke STABLE (kunci jadi percuma)",
                        nomor_kembali_stable, uji=UJI_F13))

    # -------------------------------------------------------- bagian 11 (AUD-3 F-10)
    # 26) Lingkup baca izin dikembalikan ke se-penyewa (cacat asli F-10) → MERAH.
    def izin_kembali_sepenyewa(t: str) -> str:
        return ganti_terakhir(
            t,
            """      and public.peran_saya() = 'admin_cabang'
      and exists (
        select 1
          from public.pengguna_cabang pc
         where pc.pengguna_id = public.izin.pengguna_id
           and pc.cabang_id = public.cabang_saya()
      )""",
            """      and public.peran_saya() = 'admin_cabang'""",
        )

    hasil.append(mutasi("lingkup baca izin admin cabang dikembalikan ke se-penyewa (cacat AUD-3 F-10)",
                        izin_kembali_sepenyewa, uji=UJI_F10))

    # Kontrol penutup: setelah semua mutasi dipulihkan, SEMUA uji wajib hijau lagi.
    hijau_akhir, keluar_akhir = semua_hijau()
    hasil.append(("kontrol penutup: salinan dipulihkan → semua uji hijau", hijau_akhir,
                  "HIJAU" if hijau_akhir else "MERAH\n" + keluar_akhir))

    print("\nUJI MUTASI — penutup celah putaran16 (0015: K-1, K-2a…K-2d, F-01/F-02, "
          "F-03/F-05/F-06, F-04, F-10, F-11, F-13)")
    merah = 0
    for nama, lulus, catatan in hasil:
        if not lulus:
            merah += 1
        print(f"  {'OK  ' if lulus else 'X   '}{nama}: {catatan}")
    if merah:
        print(f"\nHASIL: GAGAL — {merah} mutasi tidak sesuai harapan (pagar mungkin tumpul).")
        return 1
    print("\nHASIL: LOLOS — semua mutasi WAJIB MERAH benar-benar merah; pagar K-1/K-2 dan aturan uang terbukti bekerja.")
    return 0


def uji_diri() -> int:
    """Buktikan penilai mutasi bisa MENOLAK salinan rusak dan MENERIMA asersi pagar.

    Cara uji ini sengaja meniru cara auditor membuktikannya (laporan I F-04): jalankan fungsi
    `mutasi` yang ASLI, tetapi pengganti `jalankan_uji` disuapkan keluaran palsu — jadi yang dinilai
    benar-benar jalur penilaian harness, bukan tiruan yang ditulis ulang di tes.
    """
    import tempfile

    print("UJI DIRI — penilai mutasi (harus bisa MENOLAK salinan rusak & MENERIMA asersi pagar)")
    kasus = [
        ("lingkungan: pustaka uji tidak ditemukan", 1,
         "node:internal/modules/cjs/loader\nError: Cannot find module '@electric-sql/pglite'\n"
         "ERR_MODULE_NOT_FOUND\n", RUSAK),
        ("sintaks JS rusak", 1,
         "SyntaxError: unexpected token '}'\n", RUSAK),
        ("migrasi tidak bisa diterapkan", 1,
         "  GAGAL 0015_penutup_celah_putaran16.sql\n        syntax error at or near \"end\"\n\n"
         "HASIL: GAGAL — migrasi tidak bisa diterapkan; uji dihentikan.\n", RUSAK),
        ("berkas uji hilang", 1,
         "  GAGAL supabase/tes/urutan_uang.sql (berkas tidak ada)\n\n" + "-" * 70 +
         "\nuji: 0 LULUS · 1 GAGAL\nRincian kegagalan:\n  - supabase/tes/urutan_uang.sql: berkas tidak ada\n"
         "HASIL: GAGAL\n", RUSAK),
        ("merah dari berkas uji tetapi BUKAN asersi (fungsi hilang karena mutasi salah)", 1,
         "  GAGAL supabase/tes/urutan_uang.sql\n        function public.hitung_total(uuid) does not exist\n\n"
         + "-" * 70 + "\nuji: 4 LULUS · 1 GAGAL\nHASIL: GAGAL\n", RUSAK),
        ("asersi pengaman benar-benar gagal (bukti pagar bekerja)", 1,
         "  GAGAL supabase/tes/urutan_uang.sql\n        HARAPAN TIDAK TERPENUHI: total harus 86250 (dapat 90000)\n\n"
         + "-" * 70 + "\nuji: 4 LULUS · 1 GAGAL\nHASIL: GAGAL\n", MERAH_PAGAR),
        ("sebab penolakan bukan yang diharapkan", 1,
         "  GAGAL supabase/tes/urutan_uang.sql\n        SEBAB PENOLAKAN BUKAN YANG DIHARAPKAN: dapat \"…\"\n\n"
         + "-" * 70 + "\nuji: 4 LULUS · 1 GAGAL\nHASIL: GAGAL\n", MERAH_PAGAR),
        ("kontrol hijau", 0,
         "  LULUS supabase/tes/urutan_uang.sql\n\n" + "-" * 70 + "\nuji: 5 LULUS · 0 GAGAL\nHASIL: LOLOS\n", HIJAU),
    ]
    rusak_jumlah = 0
    for nama, kode, keluaran, harap in kasus:
        jenis, sebab = klasifikasi(kode, keluaran)
        ok = jenis == harap
        rusak_jumlah += 0 if ok else 1
        print(f"  [{'OK' if ok else 'X '}] {nama}: jenis={jenis} harap={harap} ({sebab[:70]})")

    # Jalur penilaian di dalam `mutasi()` — harness asli, runner disuapi keluaran palsu.
    asli_jalankan, asli_kerja = globals()["jalankan_uji"], globals()["KERJA"]
    try:
        with tempfile.TemporaryDirectory(prefix="uji-diri-mutasi-") as tmp:
            salinan = pathlib.Path(tmp)
            (salinan / MIG).parent.mkdir(parents=True, exist_ok=True)
            (salinan / MIG).write_text("-- salinan uji\n", encoding="utf-8")
            globals()["KERJA"] = salinan
            globals()["jalankan_uji"] = lambda uji=None: (1, "Error: Cannot find module 'x'\n")
            _, lulus, catatan = mutasi("(uji) salinan rusak", lambda t: t + "\n-- mutasi\n")
            ok = (not lulus) and "BUKAN BUKTI" in catatan
            rusak_jumlah += 0 if ok else 1
            print(f"  [{'OK' if ok else 'X '}] mutasi() menolak salinan rusak sebagai bukti: {catatan.strip()[:80]}")
            globals()["jalankan_uji"] = lambda uji=None: (
                1, "  GAGAL supabase/tes/x.sql\n        HARAPAN TIDAK TERPENUHI: pagar tidak bekerja\n"
                   + "-" * 70 + "\nuji: 1 LULUS · 1 GAGAL\nHASIL: GAGAL\n")
            _, lulus2, catatan2 = mutasi("(uji) asersi pagar", lambda t: t + "\n-- mutasi\n")
            ok2 = lulus2 and "pagar bekerja" in catatan2
            rusak_jumlah += 0 if ok2 else 1
            print(f"  [{'OK' if ok2 else 'X '}] mutasi() menerima asersi pagar sebagai bukti: {catatan2.strip()[:80]}")
    finally:
        globals()["jalankan_uji"], globals()["KERJA"] = asli_jalankan, asli_kerja

    if rusak_jumlah:
        print(f"\nHASIL: GAGAL — {rusak_jumlah} kasus berperilaku salah (penilai mutasi belum bisa dipercaya)")
        return 1
    print("\nHASIL: LOLOS — penilai mutasi menolak salinan rusak, menerima asersi pagar, dan menghitung kontrol hijau.")
    return 0


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(main())
