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
Gerbang yang tidak bisa MERAH dianggap belum terpasang — itu pelajaran mahal proyek ini.

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

AKAR = pathlib.Path(__file__).resolve().parent.parent
KERJA = pathlib.Path("/tmp/mutasi-0015-rb")
MIG = "supabase/migrations/0015_penutup_celah_putaran16.sql"
MIG14 = "supabase/migrations/0014_penutup_celah_putaran13.sql"
UJI = "supabase/tes/pembatalan_penanda_palsu.sql"                       # bagian 1 (K-1)
UJI_PR02 = "supabase/tes/void_satu_item.sql"                            # bagian 2 (K-2a)
UJI_F01 = "supabase/tes/diskon_sesudah_lunas.sql"                       # bagian 3 (K-2b)
UJI_PR03 = "supabase/tes/nomor_pesanan_isolasi.sql"                     # bagian 4 (K-2c)
UJI_PR04 = "supabase/tes/pin_bukan_oracle.sql"                          # bagian 5 (K-2d)
UJI_UANG = "supabase/tes/urutan_uang.sql"                               # bagian 6 (F-01/F-02)
UJI_F03 = "supabase/tes/metode_bayar_nonaktif.sql"                      # bagian 8a (F-03)
UJI_F05 = "supabase/tes/pembatalan_sekali.sql"                          # bagian 8b (F-05)
UJI_F06 = "supabase/tes/lifecycle_pesanan.sql"                          # bagian 8c (F-06)
SEMUA_UJI = (UJI, UJI_PR02, UJI_F01, UJI_PR03, UJI_PR04, UJI_UANG, UJI_F03, UJI_F05, UJI_F06)


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


def mutasi(nama: str, ubah, harap_merah: bool = True, uji: str = UJI) -> tuple[str, bool, str]:
    berkas = KERJA / MIG
    asli = berkas.read_text(encoding="utf-8")
    try:
        baru = ubah(asli)
        if baru == asli:
            return nama, False, "mutasi tidak mengubah apa pun (pola tidak ditemukan)"
        berkas.write_text(baru, encoding="utf-8")
        kode, keluar = jalankan_uji(uji)
        lulus = (kode != 0) if harap_merah else (kode == 0)
        catatan = "MERAH (benar)" if kode != 0 else "HIJAU"
        if not lulus:
            catatan += " — pagar TUMPUL\n" + keluar[-600:]
        return nama, lulus, catatan
    finally:
        berkas.write_text(asli, encoding="utf-8")


def main() -> int:
    segarkan_salinan()

    hijau, keluar = semua_hijau()
    if not hijau:
        print("KONTROL GAGAL: salinan utuh pun tidak hijau — perbaiki dulu berkas ujinya.\n" + keluar)
        return 1
    print("  OK  kontrol: salinan utuh → SEMUA uji bagian 1–8 hijau")

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
        return t.replace(blok_penolakan(t), lama).replace(
            "  v_peran   text;\nbegin", "  v_peran   text;\n  v_jejak   text;\nbegin", 1
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
        return t.replace(
            "  if tg_op = 'UPDATE'\n     and (new.status = 'batal' or new.qty < old.qty) then",
            "  if tg_op = 'UPDATE'\n     and (new.status = 'batal' or new.qty < old.qty)\n     and v_peran <> 'kasir' then",
            1,
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
        m15 = re.search(r"create or replace function public\.picu_item_jaga\(\).*?\n\$\$;\n", t, re.S)
        if not m15:
            raise AssertionError("fungsi picu_item_jaga versi 0015 tidak ditemukan")
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
                        hapus_pagar_diskon, uji=UJI_F01))

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
        return t.replace(
            """  if auth.uid() is not null and not public.cabang_pantau_saya(p_cabang_id) then
    raise exception 'Cabang itu bukan cabang yang boleh Anda lihat — hitungan nomor pesanan tidak dibagikan antar resto.';
  end if;
""",
            "",
            1,
        )

    hasil.append(mutasi("pagar isolasi penghitung nomor pesanan dihapus (PR-03)",
                        hapus_pagar_nomor, uji=UJI_PR03))

    # ------------------------------------------------------------------ K-2d (PR-04)
    # 13) Pesan lama yang menyebut "pegawai lain" dikembalikan → uji PR-04 wajib MERAH.
    def kembalikan_pesan_bocor(t: str) -> str:
        return t.replace(
            "    return 'PIN itu tidak bisa dipakai — pilih angka lain.';",
            "    return 'PIN itu sudah dipakai pegawai lain di resto ini — pilih angka lain.';",
            1,
        )

    hasil.append(mutasi("pesan PIN kembar dikembalikan ke versi yang menyebut pegawai lain (PR-04)",
                        kembalikan_pesan_bocor, uji=UJI_PR04))

    # ---------------------------------------------------------- bagian 6 (AUD-3 F-01/F-02)
    # 14) Dasar pajak/service dikembalikan ke subtotal SEBELUM diskon (cacat asli) → MERAH.
    def pajak_dari_subtotal_kotor(t: str) -> str:
        return t.replace(
            """  v_dasar := greatest(v_subtotal - v_diskon, 0);

  -- F-01a: PAJAK & SERVICE DARI SUBTOTAL SETELAH DISKON.
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
                        pajak_dari_subtotal_kotor, uji=UJI_UANG))

    # 15) Pembulatan diabaikan lagi (cacat asli) → MERAH.
    def abaikan_pembulatan(t: str) -> str:
        return t.replace(
            "  if v_langkah > 0 then\n    v_total := (v_total / v_langkah) * v_langkah;\n  end if;",
            "  if false then\n    v_total := (v_total / v_langkah) * v_langkah;\n  end if;",
            1,
        )

    hasil.append(mutasi("pengaturan pembulatan diabaikan mesin (cacat AUD-3 F-01b)",
                        abaikan_pembulatan, uji=UJI_UANG))

    # 16) Penjaga pesanan lunas dilepas (cacat asli F-02) → MERAH.
    def lepas_penjaga_lunas(t: str) -> str:
        return t.replace(
            "  if auth.uid() is not null and pg_trigger_depth() = 0 and v_pesanan.status in ('lunas', 'batal') then",
            "  if false then",
            1,
        )

    hasil.append(mutasi("penjaga 'pesanan lunas tidak dihitung ulang' dilepas (cacat AUD-3 F-02)",
                        lepas_penjaga_lunas, uji=UJI_UANG))

    # 17) Pembulatan dibalik jadi KE ATAS → MERAH (mengunci arah yang diputuskan).
    def bulat_ke_atas(t: str) -> str:
        return t.replace(
            "    v_total := (v_total / v_langkah) * v_langkah;",
            "    v_total := ((v_total + v_langkah - 1) / v_langkah) * v_langkah;",
            1,
        )

    hasil.append(mutasi("arah pembulatan dibalik jadi KE ATAS (keputusan arah diuji)",
                        bulat_ke_atas, uji=UJI_UANG))

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

    # Kontrol penutup: setelah semua mutasi dipulihkan, SEMUA uji wajib hijau lagi.
    hijau_akhir, keluar_akhir = semua_hijau()
    hasil.append(("kontrol penutup: salinan dipulihkan → semua uji hijau", hijau_akhir,
                  "HIJAU" if hijau_akhir else "MERAH\n" + keluar_akhir))

    print("\nUJI MUTASI — penutup celah putaran16 (0015: K-1, K-2a…K-2d, F-01/F-02, F-03/F-05/F-06)")
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


if __name__ == "__main__":
    sys.exit(main())
