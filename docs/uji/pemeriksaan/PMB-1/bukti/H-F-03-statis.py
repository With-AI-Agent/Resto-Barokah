"""Bukti baca-saja; jalankan dari akar repo. Grep kode 1 = tidak ada kecocokan."""
import subprocess
commands = [
"sed -n '139,204p;241p;255p;263,278p;286p;308,310p;317,323p' docs/PRD.md",
"sed -n '71,124p' aplikasi/src/layar/voucher/Daftar.tsx; sed -n '231,254p' aplikasi/src/lib/auth.ts; sed -n '477,485p' aplikasi/src/App.tsx",
"sed -n '67,80p' supabase/migrations/0002_pengguna_izin_pengaturan.sql; sed -n '331,334p' docs/TECH_SPEC.md",
"head -30 docs/PRIVASI_PELANGGAN.md; grep -n 'T-011\|T-014' docs/TERTANGGUH.md",
"sed -n '1602,1607p;1745,1751p;1858,1863p' docs/ROADMAP.md; sed -n '461,464p' docs/TECH_SPEC.md; sed -n '371,376p;442,470p' aplikasi/src/layar/platform/Penyewa.tsx",
"git show c5dbc98:docs/PRD.md | sed -n '145p'; git show c3a96cb -- docs/PRD.md; sed -n '24,30p' supabase/migrations/0048_wajib_shift.sql; sed -n '1548,1554p' docs/ROADMAP.md; sed -n '2519,2534p' docs/DECISIONS_LOG.md",
"sed -n '157,169p' supabase/migrations/0063_anti_email_palsu.sql; sed -n '80,163p;232,270p' supabase/migrations/0087_perbaiki_search_path_kripto_dan_rpc.sql",
"sed -n '90,106p' supabase/migrations/0040_urutan_rantai_audit.sql; sed -n '81,88p' supabase/functions/ringkasan_harian/index.ts",
"sed -n '164,177p' docs/KEAMANAN.md; sed -n '45,58p' docs/PRIVASI_PELANGGAN.md; sed -n '61,68p;77,104p' aplikasi/src/layar/kasir/DataPelanggan.tsx; sed -n '10,17p' supabase/migrations/0063_anti_email_palsu.sql",
"grep -n -e jwt_expiry -e minimum_password_length -e password_requirements supabase/config.toml; grep -rn 'config push' .github/workflows",
"sed -n '480,491p' supabase/migrations/0084_cabut_akses_pegawai_berhenti.sql; sed -n '13,17p;129,132p' docs/teknis/BUKU_INSIDEN.md; ls aplikasi/src/layar/pengaturan/DaftarPerangkat.tsx",
"sed -n '114,198p' supabase/migrations/0031_mode_dukungan_platform.sql; grep -rn 'mode_dukungan' supabase/functions aplikasi/src",
"ls .github/workflows; grep -rn -e ringkasan_harian -e hasilkan_ringkasan .github/workflows alat/denyut.py supabase/migrations/0082_denyut_harian_pembersih.sql; grep -n -e cron -e schedule supabase/migrations/0085_ringkasan_harian.sql; grep -n 'onKirimEmailManual' aplikasi/src/layar/laporan/Peringatan.tsx",
"sed -n '37,38p;156p' docs/TECH_SPEC.md",
]
for c in commands:
    print('\n$ '+c, flush=True)
    r = subprocess.run(c, shell=True, text=True, capture_output=True)
    print('\n'.join(line.rstrip() for line in r.stdout.splitlines())); print(r.stderr, end=''); print('exit='+str(r.returncode))
