#!/usr/bin/env python3
"""Bukti HAKIM H-F-03.6 (2026-10-04, sesi arena/01a1050f-resto-barokah)
Uji mutasi terhadap supabase/migrations/0096_penyatuan_gaya_penulisan_nomor_hp.sql
dan uji langsung backfill 0096 (data lama tanpa kembaran vs data kembar dari 0095).

Cara jalan (dari akar repo):
  python3 docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.6-mutasi-dan-backfill-0096.py
Tidak menyentuh pohon kerja (semua mutasi berjalan di direktori sementara /tmp).
"""
from __future__ import annotations

import pathlib
import shutil
import subprocess
import sys
import tempfile

AKAR = pathlib.Path(__file__).resolve().parents[5]
MIGRASI = "supabase/migrations/0096_penyatuan_gaya_penulisan_nomor_hp.sql"
UJI = "supabase/tes/voucher_kasir_wajib_identitas.sql"

BLOK_BACKFILL = """do $$
declare
  r record;
begin
  for r in
    select p.id, p.telepon
      from public.pelanggan p
     where p.telepon is not null
     order by p.dibuat_pada, p.id
  loop
    begin
      update public.pelanggan
         set telepon = public.normalisasi_telepon_pelanggan(r.telepon)
       where id = r.id;
    exception when unique_violation then
      -- Kembar lama: baris yang lebih tua sudah memegang bentuk kanonik.
      -- Penggabungan/penghapusan data butuh keputusan — dibiarkan dulu.
      null;
    end;
  end loop;
end;
$$;
"""

MUTAN = [
    ("M0 kontrol (berkas 0096 asli)", None, None),
    ("M1 buang loop awalan 00",
     "  while left(v, 2) = '00' loop\n    v := substr(v, 3);\n  end loop;\n", ""),
    ("M2 ubah while 00 jadi if 00 (tidak berulang)",
     "  while left(v, 2) = '00' loop\n    v := substr(v, 3);\n  end loop;\n",
     "  if left(v, 2) = '00' then\n    v := substr(v, 3);\n  end if;\n"),
    ("M3 buang cabang kode negara 62",
     "  if left(v, 2) = '62' then\n    v := substr(v, 3);\n    while left(v, 1) = '0' loop\n      v := substr(v, 2);\n    end loop;\n    if v = '' then\n      return null;\n    end if;\n    return '0' || v;\n  end if;\n",
     ""),
    ("M4 buang loop nol sesudah 62",
     "    while left(v, 1) = '0' loop\n      v := substr(v, 2);\n    end loop;\n", ""),
    ("M5 salah potong 62 (substr 4)",
     "    v := substr(v, 3);\n", "    v := substr(v, 4);\n"),
    ("M6 buang cabang tanpa nol depan (2..9)",
     "  if left(v, 1) between '2' and '9' then\n    v := '0' || v;\n  end if;\n", ""),
    ("M7 sempitkan 2..9 jadi 8..9 (telepon rumah)",
     "between '2' and '9'", "between '8' and '9'"),
    ("M8 buang blok backfill 0096", BLOK_BACKFILL, ""),
]

HARNESS_BACKFILL_JS = r"""
const fs = require("node:fs");
const path = require("node:path");
const AKAR = process.env.AKAR_UJI;
const { PGlite } = require(path.join(AKAR, "alat", "node_modules", "@electric-sql/pglite"));
const runner = fs.readFileSync(path.join(AKAR, "alat", "uji-sql.mjs"), "utf8");
const cocok = runner.match(/const SKEMA_UJI = `([\s\S]*?)\n`\n/);
const SKEMA = new Function("return `" + cocok[1] + "\n`")();
const DIR_MIGRASI = path.join(AKAR, "supabase", "migrations");
const BERKAS_0096 = "0096_penyatuan_gaya_penulisan_nomor_hp.sql";
const PENYEWA = "11111111-1111-1111-1111-111111111111";
const RINA = "90000000-0000-0000-0000-000000000004";

async function siapkanSampai0095() {
  const db = await PGlite.create();
  await db.exec(SKEMA);
  for (const f of fs.readdirSync(DIR_MIGRASI).filter(x => x.endsWith(".sql")).sort()) {
    if (f >= "0096") continue;
    await db.exec(fs.readFileSync(path.join(DIR_MIGRASI, f), "utf8"));
  }
  await db.exec(fs.readFileSync(path.join(AKAR, "alat", "sql", "data-uji.sql"), "utf8"));
  return db;
}

(async () => {
  // S1: data lama di bawah 0095 tanpa kembaran
  let db = await siapkanSampai0095();
  await db.exec(`insert into public.pelanggan (penyewa_id, nama, cara_masuk, didaftarkan_oleh, persetujuan_privasi, telepon)
    values ('${PENYEWA}', 'LAMA-1', 'kasir', '${RINA}', true, '+62 (0)813-9999-8888'),
           ('${PENYEWA}', 'LAMA-2', 'kasir', '${RINA}', true, '0062 21 5790 1234')`);
  const s1_sebelum = (await db.query("select nama, telepon from public.pelanggan where nama like 'LAMA-%' order by nama")).rows;
  await db.exec(fs.readFileSync(path.join(DIR_MIGRASI, BERKAS_0096), "utf8"));
  const s1_sesudah = (await db.query("select nama, telepon from public.pelanggan where nama like 'LAMA-%' order by nama")).rows;
  console.log("S1_TANPA_KEMBAR sebelum=" + JSON.stringify(s1_sebelum) + " sesudah=" + JSON.stringify(s1_sesudah));
  await db.close();

  // S2: data kembar yang lolos di bawah 0095 lewat RPC daftar_voucher
  db = await siapkanSampai0095();
  await db.exec(`insert into public.kampanye_voucher (id, penyewa_id, nama, kode_kampanye, jenis, nilai, min_belanja, mulai, selesai, kuota, aktif)
    values ('c3000000-0000-0000-0000-000000000802', '${PENYEWA}', 'Kampanye 0095', 'K095', 'nominal', 20000, 50000, now() - interval '1 hour', now() + interval '1 day', 100, true)`);
  for (const [nama, tel, ip] of [["Orang-1", "+62 (0)812-3456-7890", "10.8.1.1"], ["Orang-2", "0062 812 3456 7890", "10.8.1.2"]]) {
    await db.exec(`select uji.klaim('${RINA}'); set role authenticated;
      select public.daftar_voucher('${PENYEWA}', 'c3000000-0000-0000-0000-000000000802', '${nama}', null, '${tel}', null, true, 'kasir', 'hp', '${ip}');
      reset role;`);
  }
  const s2_sebelum = (await db.query("select nama, telepon from public.pelanggan where nama like 'Orang-%' order by nama")).rows;
  await db.exec(fs.readFileSync(path.join(DIR_MIGRASI, BERKAS_0096), "utf8"));
  const s2_sesudah = (await db.query("select nama, telepon from public.pelanggan where nama like 'Orang-%' order by nama")).rows;
  console.log("S2_KEMBAR_0095  sebelum=" + JSON.stringify(s2_sebelum) + " sesudah=" + JSON.stringify(s2_sesudah));
  await db.close();
})();
"""


def alasan_gagal(keluaran: str) -> str:
    baris = keluaran.splitlines()
    for i, b in enumerate(baris):
        if b.strip().startswith("GAGAL ") and i + 1 < len(baris):
            return baris[i + 1].strip()[:110]
    return "(alasan tidak terbaca)"


def main() -> int:
    sandi = pathlib.Path(tempfile.mkdtemp(prefix="mutasi0096-"))
    try:
        arsip = subprocess.run(["git", "-C", str(AKAR), "archive", "HEAD"], capture_output=True, check=True)
        subprocess.run(["tar", "-x", "-C", str(sandi)], input=arsip.stdout, check=True)
        (sandi / "alat" / "node_modules").symlink_to(AKAR / "alat" / "node_modules")
        target = sandi / MIGRASI
        asli = target.read_text(encoding="utf-8")
        sha = subprocess.run(["git", "-C", str(AKAR), "rev-parse", "--short", "HEAD"],
                             capture_output=True, text=True, check=True).stdout.strip()
        print(f"=== A. UJI MUTASI 0096 (salinan sementara dari HEAD {sha}) ===")
        print(f"Berkas uji: {UJI}\n")
        for nama, a, b in MUTAN:
            if a is not None:
                assert a in asli, f"Jangkar mutasi tidak ditemukan: {nama}"
                target.write_text(asli.replace(a, b, 1), encoding="utf-8")
            else:
                target.write_text(asli, encoding="utf-8")
            r = subprocess.run(["node", "alat/uji-sql.mjs", UJI], cwd=sandi, capture_output=True, text=True)
            keluaran = r.stdout + r.stderr
            lulus = "uji: 1 LULUS" in keluaran
            if a is None:
                status = "LULUS   (kontrol)   " if lulus else "GAGAL   (KONTROL RUSAK)"
            else:
                status = "LULUS   (SELAMAT)   " if lulus else "GAGAL   (TERTANGKAP)"
            catatan = "" if lulus else " <- " + alasan_gagal(keluaran)
            print(f"{nama:45s} -> {status}{catatan}")

        target.write_text(asli, encoding="utf-8")
        print("\n=== B. UJI LANGSUNG BACKFILL 0096 (transisi 0095 -> 0096) ===")
        env = dict(**subprocess.os.environ, AKAR_UJI=str(sandi))
        r_bf = subprocess.run(["node", "-e", HARNESS_BACKFILL_JS], cwd=sandi, env=env, capture_output=True, text=True, check=True)
        print("Dengan 0096 utuh:")
        print(r_bf.stdout.strip())

        target.write_text(asli.replace(BLOK_BACKFILL, "", 1), encoding="utf-8")
        r_bf_m8 = subprocess.run(["node", "-e", HARNESS_BACKFILL_JS], cwd=sandi, env=env, capture_output=True, text=True, check=True)
        print("\nKontrol negatif M8 (blok backfill 0096 dihapus):")
        print(r_bf_m8.stdout.strip())
        return 0
    finally:
        shutil.rmtree(sandi, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
