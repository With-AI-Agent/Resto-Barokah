#!/usr/bin/env python3
"""Regresi pengiriman: remote bare sungguhan, tanpa jaringan/GitHub produksi."""
import unittest
from pathlib import Path
import subprocess
import tempfile
import threading
from concurrent.futures import ThreadPoolExecutor
from unittest.mock import patch
import kirim_laporan as modul
from kirim_laporan import kirim, Terblokir, git, teks
from kirim_laporan import jalur_laporan

class RegresiNama(unittest.TestCase):
    def test_nama_sama_isi_berbeda_tidak_bertabrakan(self):
        self.assertNotEqual(jalur_laporan('audit', 'LAPORAN_sesi.md', b'verdict A'),
                            jalur_laporan('audit', 'LAPORAN_sesi.md', b'verdict B'))


    def test_retry_snapshot_bernama_hash_idempoten(self):
        path = jalur_laporan('audit', 'LAPORAN_asal.md', b'isi')
        self.assertEqual(jalur_laporan('audit', Path(path).name, b'isi'), path)
        with self.assertRaises(Terblokir):
            jalur_laporan('audit', Path(path).name, b'isi diubah')

class Pengiriman(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.work = self.root / 'work'
        self.remote = self.root / 'origin.git'
        self.work.mkdir()
        self.branch = 'arena/01a0c2c1-resto-barokah'
        git(self.root, 'init', '--bare', '--initial-branch', self.branch, str(self.remote))
        git(self.work, 'init', '--initial-branch', self.branch)
        git(self.work, 'config', 'user.name', 'Uji')
        git(self.work, 'config', 'user.email', 'uji@example.test')
        (self.work / 'kode.txt').write_text('kode awal')
        git(self.work, 'add', 'kode.txt')
        git(self.work, 'commit', '-m', 'dasar')
        git(self.work, 'remote', 'add', 'origin', str(self.remote))
        git(self.work, 'push', 'origin', self.branch)
        self.base = teks(self.work, 'rev-parse', 'HEAD')

    def kirim(self, isi=b'laporan A', **kw):
        return kirim(str(self.remote), self.branch, 'audit', 'LAPORAN_sama.md', isi,
                     penulis=('Auditor', 'uji@example.test'), **kw)

    def test_normal_satu_file_satu_parent_dan_bukti(self):
        r = self.kirim()
        self.assertEqual(r['status'], 'TERVERIFIKASI')
        self.assertEqual(teks(self.remote, 'rev-parse', r['commit']+'^'), self.base)
        self.assertEqual(git(self.remote, 'show', r['commit']+':'+r['path']).stdout, b'laporan A')
        self.assertEqual(teks(self.remote, 'diff', '--name-only', self.base, r['commit']), r['path'])

    def test_checkout_bersama_staged_untracked_refs_tetap_utuh(self):
        (self.work / 'kode.txt').write_text('pekerjaan orang lain')
        git(self.work, 'add', 'kode.txt')
        (self.work / 'belum.txt').write_text('belum staged')
        sebelum = {str(p.relative_to(self.work)): p.read_bytes() for p in self.work.rglob('*') if p.is_file()}
        self.kirim()
        sesudah = {str(p.relative_to(self.work)): p.read_bytes() for p in self.work.rglob('*') if p.is_file()}
        self.assertEqual(sebelum, sesudah)

    def test_kirim_ulang_idempoten_tanpa_commit_baru(self):
        a = self.kirim()
        b = self.kirim()
        self.assertEqual(a['commit'], b['commit'])
        self.assertEqual(teks(self.remote, 'rev-list', '--count', 'HEAD'), '2')

    def test_dua_penulis_bersamaan_nama_dan_branch_sama(self):
        barrier = threading.Barrier(2)
        def tunggu(n, *_):
            if n == 1:
                barrier.wait(timeout=15)
        with ThreadPoolExecutor(max_workers=2) as ex:
            a = ex.submit(self.kirim, b'A', sebelum_push=tunggu)
            b = ex.submit(self.kirim, b'B', sebelum_push=tunggu)
            hasil = [a.result(timeout=45), b.result(timeout=45)]
        self.assertEqual(sorted(r['upaya'] for r in hasil), [1, 2])
        self.assertEqual(teks(self.remote, 'rev-list', '--count', 'HEAD'), '3')
        for r in hasil:
            self.assertEqual(git(self.remote, 'merge-base', '--is-ancestor', r['commit'], 'HEAD').returncode, 0)
            self.assertTrue(git(self.remote, 'show', 'HEAD:'+r['path']).stdout in (b'A', b'B'))
        self.assertEqual(teks(self.remote, 'rev-list', '--merges', 'HEAD'), '')

    def test_konten_identik_bersamaan_idempoten(self):
        barrier = threading.Barrier(2)
        def tunggu(n, *_):
            if n == 1:
                barrier.wait(timeout=15)
        with ThreadPoolExecutor(max_workers=2) as ex:
            fs = [ex.submit(self.kirim, sebelum_push=tunggu) for _ in range(2)]
            hasil = [f.result(timeout=45) for f in fs]
        self.assertEqual(hasil[0]['commit'], hasil[1]['commit'])
        self.assertEqual(teks(self.remote, 'rev-list', '--count', 'HEAD'), '2')

    def test_push_diterima_tetapi_balasan_hilang_tetap_diverifikasi(self):
        asli = modul.git
        def putus(root, *args, **kw):
            out = asli(root, *args, **kw)
            if args[0] == 'push':
                raise Terblokir('balasan hilang')
            return out
        with patch.object(modul, 'git', side_effect=putus):
            self.assertEqual(self.kirim()['status'], 'TERVERIFIKASI')

    def test_exit_push_nol_tanpa_pengiriman_bukan_bukti(self):
        asli = modul.git
        def palsu(root, *args, **kw):
            if args[0] == 'push':
                return subprocess.CompletedProcess(args, 0, b'', b'')
            return asli(root, *args, **kw)
        with patch.object(modul, 'git', side_effect=palsu), self.assertRaises(Terblokir):
            self.kirim(upaya=1)
        self.assertEqual(teks(self.remote, 'rev-parse', 'HEAD'), self.base)

    def test_izin_push_ditolak_bukan_selesai(self):
        hook = self.remote / 'hooks/pre-receive'
        hook.write_text('#!/bin/sh\nexit 1\n')
        hook.chmod(0o755)
        with self.assertRaises(Terblokir):
            self.kirim(upaya=2)
        self.assertEqual(teks(self.remote, 'rev-parse', 'HEAD'), self.base)

    def test_collision_isi_atau_mode_tidak_ditimpa(self):
        path = jalur_laporan('audit', 'LAPORAN_sama.md', b'laporan A')
        dst = self.work / path
        dst.parent.mkdir(parents=True)
        dst.write_bytes(b'berbeda')
        git(self.work, 'add', path)
        git(self.work, 'commit', '-m', 'collision fixture')
        git(self.work, 'push', 'origin', self.branch)
        tip = teks(self.remote, 'rev-parse', 'HEAD')
        with self.assertRaises(Terblokir):
            self.kirim()
        self.assertEqual(teks(self.remote, 'rev-parse', 'HEAD'), tip)

    def test_folder_remote_symlink_ditolak(self):
        (self.work / 'docs').symlink_to('kode.txt')
        git(self.work, 'add', 'docs')
        git(self.work, 'commit', '-m', 'symlink fixture')
        git(self.work, 'push', 'origin', self.branch)
        with self.assertRaises(Terblokir):
            self.kirim()

    def test_lima_race_berturut_berhenti_tanpa_merusak_kiriman_lain(self):
        seen = []
        def pesaing(n, *_):
            seen.append(self.kirim(f'pesaing {n}'.encode()))
        with self.assertRaises(Terblokir):
            self.kirim(sebelum_push=pesaing)
        self.assertEqual(len(seen), 5)
        self.assertEqual(teks(self.remote, 'rev-list', '--count', 'HEAD'), '6')
        for n, r in enumerate(seen, 1):
            self.assertEqual(git(self.remote, 'show', 'HEAD:'+r['path']).stdout, f'pesaing {n}'.encode())

    def test_cabang_baru_hanya_dasar_yang_ada_di_remote(self):
        baru = self.root/'baru.git'
        git(self.root, 'init', '--bare', '--initial-branch', self.branch, str(baru))
        # No branch at destination yet; seed only a server-visible base object.
        git(baru, 'fetch', '--no-write-fetch-head', str(self.remote), self.base)
        r = kirim(str(baru), self.branch, 'audit', 'LAPORAN_x.md', b'x',
                  penulis=('A','a@x'), dasar_baru=self.base)
        self.assertEqual(teks(baru, 'rev-parse', r['commit']+'^'), self.base)
        kosong = self.root/'kosong.git'
        git(self.root, 'init', '--bare', '--initial-branch', self.branch, str(kosong))
        with self.assertRaises(Terblokir):
            kirim(str(kosong), self.branch, 'audit', 'LAPORAN_x.md', b'x',
                  penulis=('A','a@x'), dasar_baru=self.base)

    def test_cli_draf_eksklusif_dan_snapshot_tetap_saat_gagal(self):
        import importlib.util
        import contextlib
        import io
        import os
        import sys
        spec = importlib.util.spec_from_file_location('cli_test', Path(__file__).with_name('kirim-laporan.py'))
        m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
        git(self.work, 'remote', 'set-url', 'origin', 'https://github.com/Contoh/Privat.git')
        prev = Path.cwd()
        try:
            os.chdir(self.work)
            args = ['kirim-laporan.py', '--jenis', 'audit', '--sumber', 'arena/sumber', '--penanda', 'G3_T04']
            paths = []
            for _ in range(2):
                output = io.StringIO()
                with patch.object(sys, 'argv', args+['--siapkan']), contextlib.redirect_stdout(output):
                    self.assertEqual(m.main(), 0)
                paths.append(Path(output.getvalue().strip()))
            self.assertNotEqual(paths[0], paths[1])
            self.assertTrue(all(p.name.startswith('LAPORAN_G3_T04_') for p in paths))
            for penanda in ('', '../sumber', 'a:b', 'x'*41):
                with patch.object(sys, 'argv', args[:-2]+['--penanda', penanda, '--siapkan']), \
                     contextlib.redirect_stdout(io.StringIO()):
                    self.assertEqual(m.main(), 1)
            with patch.object(sys, 'argv', args[:-1]+['G3_T05', '--laporan', str(paths[0])]), \
                 contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(m.main(), 1)
            paths[0].write_bytes(b'laporan utuh')
            with patch.object(sys, 'argv', args+['--laporan', str(paths[0])]), \
                 patch.object(m, 'kirim', side_effect=Terblokir('izin ditolak')), \
                 contextlib.redirect_stdout(io.StringIO()) as output:
                self.assertEqual(m.main(), 1)
            self.assertIn('BELUM TERVERIFIKASI', output.getvalue())
            self.assertEqual(len(list((self.work/'.laporan-lokal').glob('*.md'))), 3)
            self.assertTrue(any(p.read_bytes() == b'laporan utuh' and p != paths[0]
                                for p in (self.work/'.laporan-lokal').glob('*.md')))
            with patch.object(sys, 'argv', ['kirim-laporan.py', '--jenis', 'audit',
                                           '--sumber', self.branch, '--siapkan']), \
                 contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(m.main(), 1)
        finally:
            os.chdir(prev)

    def test_nama_traversal_biner_dan_jenis_salah_ditolak(self):
        for jenis, nama, isi in [('audit', '../LAPORAN_x.md', b'a'),
                                  ('audit', 'LAPORAN_x.md', b'\x00'),
                                  ('kode', 'LAPORAN_x.md', b'a'),
                                  ('audit', 'LAPORAN_x.md', b''),
                                  ('audit', 'LAPORAN_x.md', b'\xff')]:
            with self.subTest(nama=nama, isi=isi), self.assertRaises(Terblokir):
                jalur_laporan(jenis, nama, isi)

    def test_main_dan_refspec_injection_ditolak(self):
        for cabang in ['main', 'arena/a:refs/heads/main', '+arena/a']:
            with self.subTest(cabang=cabang), self.assertRaises(Terblokir):
                kirim(str(self.remote), cabang, 'audit', 'LAPORAN_x.md', b'a', penulis=('A','a@x'))

class KontrakPrompt(unittest.TestCase):
    def test_kontrak_panjang_kedua_jenis_dan_tidak_stage_folder(self):
        from kontrak_laporan import blok_pengiriman
        for jenis in ('audit', 'review-pr'):
            isi = blok_pengiriman(jenis, 'arena/sumber')
            for token in ('Tanpa meminta Lee lagi', 'verifikasi remote', '--siapkan',
                          '--laporan', 'SHA paket', 'BELUM TERVERIFIKASI',
                          'working tree', 'remote_tip', 'SHA-256'):
                self.assertIn(token, isi)
            self.assertIn(f'--jenis {jenis} --sumber arena/sumber', isi)
            self.assertNotIn('git add docs/', isi)

    def test_generator_review_menghasilkan_blok_pengiriman(self):
        # Run the actual builder against a disposable repo. CI evidence is a
        # fixture here, never a claim about a live target or permission bypass.
        import importlib.util
        import ci_target
        import contextlib
        import io
        spec = importlib.util.spec_from_file_location('review_test', Path(__file__).with_name('review-pr.py'))
        m = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(m)
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            git(root, 'init', '--initial-branch', 'arena/01a0c2c1-resto-barokah')
            git(root, 'config', 'user.name', 'Uji')
            git(root, 'config', 'user.email', 'uji@example.test')
            (root / 'awal.txt').write_text('awal')
            git(root, 'add', 'awal.txt'); git(root, 'commit', '-m', 'dasar')
            (root / 'awal.txt').write_text('baru')
            git(root, 'add', 'awal.txt'); git(root, 'commit', '-m', 'perubahan')
            with patch.object(m, 'AKAR', root), patch.object(m, 'FOLDER', root / 'docs/uji/review-pr'), \
                 patch.object(m, 'bahan_bocor_di_repo', return_value=[]), \
                 patch.object(m, 'bahan_kalibrasi_terbaru', return_value=None), \
                 patch.object(ci_target, 'status_ci', return_value={'hijau': True}), \
                 patch.object(ci_target, 'baris_paket', return_value='CI fixture'), \
                 contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(m.siapkan('HEAD^', 'HEAD', 'uji-pengiriman'), 0)
            paket = list((root/'docs/uji/review-pr').glob('*SIAP-TEMPEL.md'))
            self.assertEqual(len(paket), 1)
            isi = paket[0].read_text()
            self.assertIn('Tanpa meminta Lee lagi', isi)
            self.assertIn('--jenis review-pr --sumber arena/01a0c2c1-resto-barokah', isi)
            self.assertNotIn('git add docs/uji/review-pr/', isi)

    def test_paket_g3_target_artefak_dan_namespace_per_tugas(self):
        import re
        root = Path(__file__).resolve().parent.parent
        target = 'e50bac4d897ca65b37dde9e64dbd246a3891b041'
        for nomor in ('04', '05', '06'):
            path = root / f'docs/uji/maraton/G3-T-{nomor}-2026-09-21-SIAP-TEMPEL.md'
            text = path.read_text()
            self.assertIn(f'**Tugas:** T-{nomor}', text)
            self.assertIn(f'**Commit target:** `{target}`', text)
            self.assertIn(f'--penanda G3_T{nomor}', text)
            self.assertIn('35600019563', text)
            self.assertIn('Tanpa meminta Lee lagi', text)
            self.assertIn('BELUM TERVERIFIKASI', text)
            self.assertIn('## 5. Checklist', text)
            self.assertNotIn('git add docs/uji/', text)
            bagian = text.split('## 2. Artefak primer')[1].split('## 3.')[0]
            artifacts = re.findall(r'^- `([^`]+)`', bagian, re.M)
            self.assertGreaterEqual(len(artifacts), 6)
            has_target = git(root, 'cat-file', '-t', target, wajib=False).returncode == 0
            if not has_target:
                git(root, 'fetch', 'origin', target, wajib=False)
                has_target = git(root, 'cat-file', '-t', target, wajib=False).returncode == 0
            for artifact in artifacts:
                if has_target:
                    self.assertEqual(git(root, 'cat-file', '-e', target+':'+artifact, wajib=False).returncode, 0)
                else:
                    self.assertTrue((root / artifact).exists())

    def test_dokumen_kanonik_tidak_kembali_ke_pengiriman_bersama(self):
        root = Path(__file__).resolve().parent.parent
        for f in ['PROMPT_AUDIT_INDEPENDEN.md', 'PROMPT_REVIEW_PR_INDEPENDEN.md',
                  'PROTOKOL_AUDIT_INDEPENDEN.md', 'PROTOKOL_REVIEW_PR_INDEPENDEN.md']:
            text = (root/'docs/uji'/f).read_text()
            self.assertIn('kirim-laporan.py', text)
            self.assertIn('BELUM TERVERIFIKASI', text)
            self.assertNotIn('git add docs/uji/', text)

if __name__ == '__main__':
    unittest.main(verbosity=2)
