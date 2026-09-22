#!/usr/bin/env python3
"""uji-konkuren.py — uji concurrency NYATA (2 koneksi) untuk temuan yang tak bisa
dibuktikan di PGlite (satu koneksi): F F-13 (nomor pesanan) + F F-12 (cap diskon).

Mesin: PostgreSQL 16.2 nyata via `pgserver` (pip; ephemeral di sandbox — pasang
ulang sesudah reset: `python3 -m pip install --user pgserver "psycopg[binary]"`).
Tiap run memakai database sementara yang bersih otomatis. Skema = migrasi repo
0001..0021 + preamble uji (peran + auth + klaim, disalin dari `alat/uji-sql.mjs`)
+ `alat/sql/data-uji.sql` — SAMA dengan yang diuji PGlite, ditambah ekstensi
pgcrypto TIRUAN (pgserver minimal tanpa contrib; tiruannya teks-identik dengan
mock `uji-sql.mjs` sehingga semantiknya sama).

Setiap uji DIJALANKAN DUA KALI: (1) skema utuh → HARUS LULUS; (2) skema dengan
kuncinya dilepas (`create or replace` di database uji SAJA — repo tak disentuh)
→ HARUS GAGAL (bug tereproduksi). Kalibrasi ini membuktikan ujinya PEKA, bukan
hijau karena longgar (prinsip yang sama dengan `--uji-diri` harness mutasi).

Jalankan:  python3 alat/uji-konkuren.py
"""
from __future__ import annotations

import pathlib
import shutil
import subprocess
import sys
import tempfile
import threading
import time

try:
    import pgserver
except ImportError:
    print("GAGAL: pustaka `pgserver` belum terpasang — jalankan dulu:")
    print('  python3 -m pip install --user pgserver "psycopg[binary]"')
    sys.exit(2)
try:
    import psycopg
except ImportError:
    print("GAGAL: pustaka `psycopg` belum terpasang — jalankan dulu:")
    print('  python3 -m pip install --user pgserver "psycopg[binary]"')
    sys.exit(2)

AKAR = pathlib.Path(__file__).resolve().parent.parent
DIR_MIGRASI = AKAR / "supabase" / "migrations"
DATA_UJI = AKAR / "alat" / "sql" / "data-uji.sql"

BIN_PG = pathlib.Path(pgserver.__file__).resolve().parent / "pginstall" / "bin"
PSQL = str(BIN_PG / "psql") if (BIN_PG / "psql").is_file() else shutil.which("psql") or "psql"
DIR_EKSTENSI = pathlib.Path(pgserver.__file__).resolve().parent / "pginstall" / "share" / "postgresql" / "extension"

# --- preamble uji: disalin dari alat/uji-sql.mjs (peran + auth + klaim) --------
PRA = """
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;

create schema if not exists auth;
create table if not exists auth.users (
  id uuid primary key,
  email text
);

create or replace function auth.uid() returns uuid
language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

create or replace function auth.jwt() returns jsonb
language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claims', true), '')::jsonb, '{}'::jsonb)
$$;

create schema if not exists uji;
grant usage on schema uji to public;
grant usage on schema auth to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;
grant execute on function auth.jwt() to anon, authenticated, service_role;

create or replace function uji.klaim(p_id uuid, p_klaim jsonb default '{}'::jsonb)
returns void language plpgsql security definer set search_path = uji, public, pg_temp as $$
begin
  perform set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  perform set_config('request.jwt.claims', coalesce(p_klaim::text, '{}'), true);
end $$;
"""

# --- tiruan pgcrypto: teks-identik dengan mock uji-sql.mjs --------------------
# pgserver minimal (tanpa contrib) sehingga `create extension pgcrypto` di
# migrasi 0001/0006 akan gagal tanpanya. Tiruan ini dipasang sebagai ekstensi
# palsu bernama pgcrypto supaya migrasi tidak perlu diubah.
TIRUAN_PGCRYPTO_SQL = """
-- Tiruan pgcrypto HANYA untuk uji lokal (disalin dari alat/uji-sql.mjs).
-- Algoritma SENGAJA murah (SHA-256 ber-ulang), BUKAN bcrypt produksi.
create or replace function public.gen_salt(p_jenis text, p_putaran int default 10)
returns text language sql volatile as $$
  select '$tiruan$' || greatest(p_putaran, 1)::text || '$' ||
         encode(sha256(gen_random_uuid()::text::bytea), 'hex')
$$;

create or replace function public.crypt(p_pin text, p_hash text)
returns text language plpgsql immutable as $$
declare
  bagian text[];
  putaran int;
  garam text;
  hasil bytea;
  i int;
begin
  if p_hash is null or p_hash not like '$tiruan$%' then
    return null;
  end if;
  bagian := string_to_array(trim(both '$' from p_hash), '$');
  putaran := bagian[2]::int;
  garam := bagian[3];
  hasil := sha256((garam || p_pin)::bytea);
  for i in 2..putaran loop
    hasil := sha256(hasil);
  end loop;
  return '$tiruan$' || putaran::text || '$' || garam || '$' || encode(hasil, 'hex');
end $$;
"""

TIRUAN_PGCRYPTO_CONTROL = """# tiruan pgcrypto untuk uji-konkuren.py (BACA: bukan bcrypt produksi)
default_version = '1.0'
comment = 'tiruan pgcrypto uji lokal (teks-identik mock uji-sql.mjs)'
"""


def pasang_tiruan_pgcrypto() -> None:
    DIR_EKSTENSI.mkdir(parents=True, exist_ok=True)
    (DIR_EKSTENSI / "pgcrypto.control").write_text(TIRUAN_PGCRYPTO_CONTROL, encoding="utf-8")
    (DIR_EKSTENSI / "pgcrypto--1.0.sql").write_text(TIRUAN_PGCRYPTO_SQL, encoding="utf-8")


def psql_jalankan(uri: str, berkas: pathlib.Path) -> None:
    r = subprocess.run([PSQL, uri, "-v", "ON_ERROR_STOP=1", "-q", "-f", str(berkas)],
                       capture_output=True, text=True, timeout=300)
    if r.returncode != 0:
        raise RuntimeError(f"gagal menerapkan {berkas.name}:\n{r.stderr[-2000:]}")


def muat_skema(uri: str, mutasi_sql: str | None = None) -> None:
    with tempfile.NamedTemporaryFile("w", suffix=".sql", delete=False, encoding="utf-8") as f:
        f.write(PRA)
        pra = pathlib.Path(f.name)
    try:
        psql_jalankan(uri, pra)
        for mig in sorted(DIR_MIGRASI.glob("*.sql")):
            psql_jalankan(uri, mig)
        psql_jalankan(uri, DATA_UJI)
        if mutasi_sql:
            with tempfile.NamedTemporaryFile("w", suffix=".sql", delete=False, encoding="utf-8") as f:
                f.write(mutasi_sql)
                mut = pathlib.Path(f.name)
            try:
                psql_jalankan(uri, mut)
            finally:
                mut.unlink()
    finally:
        pra.unlink()


# --- F F-13: dua pengiriman bersamaan tidak boleh dapat nomor sama ------------
CABANG_F13 = "f1300000-0000-0000-0000-000000000001"
PENYEWA_UJI = "11111111-1111-1111-1111-111111111111"
TAHAN_DETIK = 2.0    # T1 menahan kunci selama ini
BLOKIR_MIN = 1.0     # T2 wajib tertahan minimal ini (bukti serialisasi)

MUTASI_F13_TANPA_KUNCI = """
-- Kalibrasi F F-13: fungsi TANPA kunci advisory (satu-satunya beda dari 0015 §10b).
create or replace function public.nomor_pesanan_berikutnya(p_cabang_id uuid, p_tanggal date)
returns integer
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_nomor integer;
begin
  if auth.uid() is not null and not public.cabang_pantau_saya(p_cabang_id) then
    raise exception 'Cabang itu bukan cabang yang boleh Anda lihat — hitungan nomor pesanan tidak dibagikan antar resto.';
  end if;

  select coalesce(max(p.nomor), 0) + 1 into v_nomor
    from public.pesanan p
   where p.cabang_id = p_cabang_id and p.tanggal = p_tanggal;

  return v_nomor;
end
$$;
"""


def server_baru(nama: str):
    """Server sementara yang SELALU segar (direktori lama dibuang dulu)."""
    d = pathlib.Path("/tmp") / nama
    shutil.rmtree(d, ignore_errors=True)
    return pgserver.get_server(str(d))

def uji_f13(uri: str) -> tuple[bool, str]:
    """Dua pemanggil bersamaan di cabang+tanggal sama → nomor berbeda & berurutan."""
    with psycopg.connect(uri, autocommit=True) as s:
        s.execute("insert into public.cabang (id, penyewa_id, nama) values (%s, %s, 'Uji-F13')",
                  (CABANG_F13, PENYEWA_UJI))
    hasil: dict = {}
    t1_dapat = threading.Event()
    galat: list[str] = []

    def t1() -> None:
        try:
            c = psycopg.connect(uri)
            v1 = c.execute("select public.nomor_pesanan_berikutnya(%s, current_date)",
                           (CABANG_F13,)).fetchone()[0]
            c.execute("insert into public.pesanan (penyewa_id, cabang_id, nomor, kunci_idempoten)"
                      " values (%s, %s, %s, 'f13-t1')", (PENYEWA_UJI, CABANG_F13, v1))
            hasil["v1"] = v1
            t1_dapat.set()
            time.sleep(TAHAN_DETIK)  # TAHAN kunci advisory sampai COMMIT
            c.commit()
            c.close()
        except Exception as e:  # noqa: BLE001 — dicatat, bukan ditelan
            galat.append(f"T1: {e!r}")
            t1_dapat.set()

    def t2() -> None:
        try:
            t1_dapat.wait(15)
            time.sleep(0.3)  # pastikan T1 sudah masuk TAHAN (kunci dipegang)
            c = psycopg.connect(uri)
            c.execute("set statement_timeout = '10s'")  # jaring anti-gantung
            mulai = time.monotonic()
            v2 = c.execute("select public.nomor_pesanan_berikutnya(%s, current_date)",
                           (CABANG_F13,)).fetchone()[0]
            hasil["tunggu"] = time.monotonic() - mulai
            c.execute("insert into public.pesanan (penyewa_id, cabang_id, nomor, kunci_idempoten)"
                      " values (%s, %s, %s, 'f13-t2')", (PENYEWA_UJI, CABANG_F13, v2))
            c.commit()
            c.close()
            hasil["v2"] = v2
        except Exception as e:  # noqa: BLE001
            galat.append(f"T2: {e!r}")

    a = threading.Thread(target=t1)
    b = threading.Thread(target=t2)
    a.start()
    b.start()
    a.join(20)
    b.join(20)
    if a.is_alive() or b.is_alive():
        return False, "utas menggantung (>20 dtk) — kemungkinan deadlock tak terduga"
    if galat:
        detail = " / ".join(galat)
        # Pada mutasi tanpa advisory lock, tabrakan indeks nomor yang tepat
        # adalah bukti kontrak nomor tidak terserialisasi. Jangan menyamakan
        # bukti spesifik ini dengan koneksi putus/deadlock/timeout umum.
        if 'UniqueViolation' in detail and 'pesanan_cabang_id_tanggal_nomor_key' in detail:
            return False, "MUTASI-PELANGGARAN-F13: unique nomor bertabrakan tanpa kunci — " + detail
        return False, "RUNTIME-ERROR-F13: " + detail
    if hasil.get("tunggu", 0) < BLOKIR_MIN:
        return False, (f"T2 tidak tertahan (tunggu {hasil.get('tunggu', 0):.2f} dtk < {BLOKIR_MIN} dtk) "
                       "— tidak ada serialisasi")
    if hasil.get("v2") != hasil.get("v1", 0) + 1:
        return False, f"tabrakan nomor: v1={hasil.get('v1')} v2={hasil.get('v2')} (harap v2=v1+1)"
    with psycopg.connect(uri, autocommit=True) as s:
        jml = s.execute("select count(*), count(distinct nomor) from public.pesanan "
                        "where cabang_id = %s", (CABANG_F13,)).fetchone()
    if jml != (2, 2):
        return False, f"baris tersimpan {jml} (harap (2, 2))"
    return True, (f"nomor berbeda & berurutan (v1={hasil['v1']} v2={hasil['v2']}); "
                  f"T2 tertahan {hasil['tunggu']:.2f} dtk lalu lanjut — serialisasi terbukti")

# --- F F-12: dua pencatat diskon bersamaan tidak boleh menjebol cap ----------
PESANAN_F12 = "eeee0000-0000-0000-0000-000000000010"  # seed: subtotal 54.000
OWNER_UJI = "90000000-0000-0000-0000-000000000002"    # Bu Oasis, owner_pusat
NOMINAL_F12 = 30000  # 30rb + 30rb = 60rb > 54rb: T2 wajib ditolak cap

SETUP_F12 = """
-- Kondisi uji F F-12 (database uji SAJA): tumpuk dinyalakan + cap-resto 50→100
-- + izin owner dilonggarkan, supaya penentu keputusan = cap-JUMLAH-vs-subtotal
-- (pemeriksaan cap-jumlah berjalan SEBELUM cap-resto di fungsinya) — satu-sebab.
update public.pengaturan set tumpuk_diskon = true, batas_maks_potongan_persen = 100
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
update public.izin set batas_nominal = 999999999, batas_persen = 100
 where pengguna_id = '90000000-0000-0000-0000-000000000002' and kode_izin = 'beri_diskon';
"""

MUTASI_F12_TANPA_KUNCI = """
-- 0022 menambah kunci BEFORE yang sama. Kalibrasi membuang lapis redundan ini
-- HANYA di DB mutasi agar hilangnya serialisasi cap betul-betul diuji.
drop trigger aaa_diskon_beku_setelah_bayar on public.diskon_transaksi;
-- Kalibrasi F F-12: pemicu BEFORE pertama TANPA `for update` (satu-satunya
-- beda dari 0021). Kunci AFTER di hitung_total (§6) tetap utuh.
create or replace function public.picu_diskon_awal_pesanan()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pesanan_id uuid;
  v_status     text;
begin
  if tg_op = 'DELETE' then
    v_pesanan_id := old.pesanan_id;
  else
    v_pesanan_id := new.pesanan_id;
  end if;

  select p.status into v_status
    from public.pesanan p where p.id = v_pesanan_id;

  if v_status in ('lunas', 'batal') then
    raise exception 'Pesanan yang sudah % tidak boleh lagi ditambah/diubah/dihapus diskonnya.', v_status;
  end if;

  return case when tg_op = 'DELETE' then old else new end;
end
$$;
"""


def uji_f12(uri: str) -> tuple[bool, str]:
    """Dua insert 30rb bersamaan di subtotal 54rb: T1 masuk, T2 ditolak cap."""
    with psycopg.connect(uri, autocommit=True) as s:
        s.execute(SETUP_F12)
    hasil: dict = {}
    t1_dapat = threading.Event()
    galat: list[str] = []

    def klaim_owner(c) -> None:
        c.execute("select uji.klaim(%s)", (OWNER_UJI,))
        c.execute("set local role authenticated")

    def t1() -> None:
        try:
            c = psycopg.connect(uri)
            klaim_owner(c)
            c.execute("insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan)"
                      " values (%s, 'manual', %s, %s, 'uji-konkuren T1')",
                      (PESANAN_F12, NOMINAL_F12, NOMINAL_F12))
            t1_dapat.set()
            time.sleep(TAHAN_DETIK)  # TAHAN kunci baris pesanan sampai COMMIT
            c.commit()
            c.close()
        except Exception as e:  # noqa: BLE001 — dicatat, bukan ditelan
            galat.append(f"T1: {e!r}")
            t1_dapat.set()

    def t2() -> None:
        try:
            t1_dapat.wait(15)
            time.sleep(0.3)  # pastikan T1 sudah masuk TAHAN
            c = psycopg.connect(uri)
            c.execute("set statement_timeout = '10s'")  # jaring anti-gantung
            klaim_owner(c)
            mulai = time.monotonic()
            try:
                c.execute("insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan)"
                          " values (%s, 'manual', %s, %s, 'uji-konkuren T2')",
                          (PESANAN_F12, NOMINAL_F12, NOMINAL_F12))
            except Exception as e:  # noqa: BLE001 — penolakan = hasil yang diharap
                hasil["t2_galat"] = str(e)
            hasil["tunggu"] = time.monotonic() - mulai
            try:
                c.commit()
            except Exception:  # noqa: BLE001 — transaksi gagal → batalkan
                c.rollback()
            c.close()
        except Exception as e:  # noqa: BLE001
            galat.append(f"T2-luar: {e!r}")

    a = threading.Thread(target=t1)
    b = threading.Thread(target=t2)
    a.start()
    b.start()
    a.join(20)
    b.join(20)
    if a.is_alive() or b.is_alive():
        return False, "utas menggantung (>20 dtk) — kemungkinan deadlock tak terduga"
    if galat:
        return False, "galat koneksi: " + " / ".join(galat)
    with psycopg.connect(uri, autocommit=True) as s:
        jml = s.execute("select count(*), coalesce(sum(nilai), 0) from public.diskon_transaksi "
                        "where pesanan_id = %s", (PESANAN_F12,)).fetchone()
    hasil["baris"] = jml
    if hasil.get("tunggu", 0) < BLOKIR_MIN:
        return False, (f"T2 tidak tertahan (tunggu {hasil.get('tunggu', 0):.2f} dtk < {BLOKIR_MIN} dtk)")
    if "melebihi subtotal" not in hasil.get("t2_galat", ""):
        return False, ("MUTASI-PELANGGARAN-F12: "
                       f"T2 tidak ditolak cap (galat: {hasil.get('t2_galat', '(diterima!)')[:100]}); "
                       f"baris={jml} — CAP JEBOL")
    if jml != (1, NOMINAL_F12):
        return False, f"baris tersimpan {jml} (harap (1, {NOMINAL_F12}))"
    return True, (f"T1 masuk 30rb, T2 ditolak cap sesudah tertahan {hasil['tunggu']:.2f} dtk; "
                  f"1 baris tersimpan — serialisasi cap terbukti")

def validasi_kalibrasi_mutasi(nama: str, lulus: bool, catat: str) -> tuple[bool, str]:
    """Terima hanya kegagalan mutan yang merupakan bukti kontrak spesifik.

    `lulus=False` saja terlalu longgar: koneksi putus, deadlock, timeout, atau
    setup rusak juga bisa membuat fungsi uji mengembalikan False (B-F02).
    """
    if lulus:
        return False, f"{nama}: mutan masih LULUS — pagar/uji tumpul"
    if nama == "F-13" and "MUTASI-PELANGGARAN-F13:" in catat:
        return True, catat
    if nama == "F-12" and "MUTASI-PELANGGARAN-F12:" in catat:
        return True, catat
    return False, f"{nama}: hasil bukan bukti mutasi yang terkalibrasi — {catat}"


def uji_diri() -> int:
    """Uji klasifikasi kalibrasi tanpa database: runtime bukan bukti."""
    kasus = [
        ("F-13", False, "MUTASI-PELANGGARAN-F13: unique nomor bertabrakan", True),
        ("F-13", False, "RUNTIME-ERROR-F13: koneksi putus", False),
        ("F-13", True, "serialisasi terbukti", False),
        ("F-12", False, "MUTASI-PELANGGARAN-F12: CAP JEBOL", True),
        ("F-12", False, "RUNTIME-ERROR-F12: timeout", False),
        ("F-12", True, "serialisasi cap terbukti", False),
    ]
    gagal = 0
    for nama, lulus, catat, harap in kasus:
        diterima, sebab = validasi_kalibrasi_mutasi(nama, lulus, catat)
        ok = diterima is harap
        gagal += int(not ok)
        print(f"{'OK' if ok else 'GAGAL'} {nama} {catat}: {'diterima' if diterima else 'ditolak'}")
    print(f"HASIL UJI-DIRI: {'LOLOS' if not gagal else 'GAGAL'} — {len(kasus)} kasus klasifikasi, {gagal} tidak sesuai.")
    return int(bool(gagal))


def main() -> int:
    pasang_tiruan_pgcrypto()
    gagal = 0

    print("== F F-13 · skema utuh (harap LULUS) ==")
    srv = server_baru("konkuren-f13-utuh")
    try:
        muat_skema(srv.get_uri())
        lulus, catat = uji_f13(srv.get_uri())
        print(f"  [{'OK' if lulus else 'X '}] {catat}")
        gagal += 0 if lulus else 1
    finally:
        srv.cleanup()

    print("== F F-13 · kunci dilepas (harap GAGAL = bug tereproduksi) ==")
    srv = server_baru("konkuren-f13-mutasi")
    try:
        muat_skema(srv.get_uri(), MUTASI_F13_TANPA_KUNCI)
        lulus, catat = uji_f13(srv.get_uri())
        kalibrasi, bukti = validasi_kalibrasi_mutasi("F-13", lulus, catat)
        print(f"  [{'OK' if kalibrasi else 'X '}] kalibrasi: {'bukti mutasi spesifik — ' if kalibrasi else 'DITOLAK — '}{bukti}")
        gagal += 0 if kalibrasi else 1
    finally:
        srv.cleanup()


    print("== F F-12 · skema utuh (harap LULUS) ==")
    srv = server_baru("konkuren-f12-utuh")
    try:
        muat_skema(srv.get_uri())
        lulus, catat = uji_f12(srv.get_uri())
        print(f"  [{'OK' if lulus else 'X '}] {catat}")
        gagal += 0 if lulus else 1
    finally:
        srv.cleanup()

    print("== F F-12 · kunci dilepas (harap GAGAL = bug tereproduksi) ==")
    srv = server_baru("konkuren-f12-mutasi")
    try:
        muat_skema(srv.get_uri(), MUTASI_F12_TANPA_KUNCI)
        lulus, catat = uji_f12(srv.get_uri())
        kalibrasi, bukti = validasi_kalibrasi_mutasi("F-12", lulus, catat)
        print(f"  [{'OK' if kalibrasi else 'X '}] kalibrasi: {'bukti mutasi spesifik — ' if kalibrasi else 'DITOLAK — '}{bukti}")
        gagal += 0 if kalibrasi else 1
    finally:
        srv.cleanup()

    if gagal:
        print(f"\nHASIL: GAGAL — {gagal} bagian tidak sesuai harapan.")
        return 1
    print("\nHASIL: LOLOS — F F-13 + F F-12 terbukti terserialisasi di 2 koneksi nyata; tiap uji terbukti peka.")
    return 0


if __name__ == "__main__":
    sys.exit(uji_diri() if "--uji-diri" in sys.argv else main())
