"""Append-only delivery: private Git object store/index, no working branch mutation.

Retries create an UNPUBLISHED candidate on the newest remote parent; they never
rebase/merge/reset published history. Server fast-forward checks serialize writers.
The CLI derives destination from the current Arena branch, not caller input.
"""
from __future__ import annotations

import hashlib
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time


class Terblokir(RuntimeError):
    pass


def jalur_laporan(jenis: str, nama: str, isi: bytes) -> str:
    if jenis not in ('audit', 'review-pr'):
        raise Terblokir('Jenis laporan tidak sah.')
    if not isi.strip() or len(isi) > 2 * 1024 * 1024 or b'\0' in isi:
        raise Terblokir('Laporan kosong, biner, atau melebihi 2 MiB.')
    try:
        isi.decode('utf-8')
    except UnicodeError as e:
        raise Terblokir('Laporan harus UTF-8.') from e
    digest = hashlib.sha256(isi).hexdigest()
    # Retrying the preserved snapshot must keep the same final path, not append
    # another hash (nor silently publish an edited immutable snapshot).
    suffix = re.fullmatch(r'(.+)__([0-9a-f]{64})\.md', nama)
    if suffix:
        if suffix.group(2) != digest:
            raise Terblokir('Hash snapshot tidak cocok; jangan mengedit snapshot terikat hash.')
        nama = suffix.group(1) + '.md'
    if not re.fullmatch(r'LAPORAN_[A-Za-z0-9_.-]{1,140}\.md', nama):
        raise Terblokir('Nama harus LAPORAN_*.md, tanpa folder/karakter kontrol.')
    return f'docs/uji/{jenis}/{nama[:-3]}__{digest}.md'


def git(akar: Path, *args: str, data: bytes | None = None, wajib=True):
    # Never inherit another session's index/object/ref overrides.
    env = {k: v for k, v in os.environ.items() if not k.startswith('GIT_')}
    env['GIT_TERMINAL_PROMPT'] = '0'
    try:
        p = subprocess.run(['git', '-C', str(akar), *args], input=data,
                           capture_output=True, env=env, timeout=90)
    except (OSError, subprocess.TimeoutExpired) as e:
        raise Terblokir(f'Operasi git {args[0]} tidak selesai; status remote belum pasti.') from e
    if wajib and p.returncode:
        # Do not echo credential-bearing URL / server stderr into a public report.
        auth = b'Authentication failed' in p.stderr or b'Permission denied' in p.stderr
        pesan = ('Sambungan GitHub perlu dihubungkan ulang di Arena; jangan kirim token di chat.'
                 if auth else f'Git {args[0]} ditolak (exit {p.returncode}); jangan paksa.')
        raise Terblokir(pesan)
    return p


def teks(akar: Path, *args: str) -> str:
    return git(akar, *args).stdout.decode().strip()


def identitas_repo(akar: Path) -> tuple[str, str]:
    cabang = teks(akar, 'symbolic-ref', '--quiet', '--short', 'HEAD')
    if not cabang.startswith('arena/') or not re.fullmatch(r'[A-Za-z0-9_./-]+', cabang):
        raise Terblokir('Wajib tetap di cabang Arena sesi sendiri, bukan main/detached.')
    url = teks(akar, 'remote', 'get-url', 'origin')
    m = re.fullmatch(r'(?:https://github\.com/|git@github\.com:)([\w.-]+/[\w.-]+?)(?:\.git)?', url)
    if not m:
        raise Terblokir('Origin harus repo GitHub tanpa kredensial tertanam dalam URL.')
    return m.group(1), cabang


def kirim(remote: str, cabang: str, jenis: str, nama: str, isi: bytes,
          *, penulis: tuple[str, str], dasar_baru: str | None = None,
          upaya: int = 5, sebelum_push=None) -> dict:
    """Core transport; tests use a local bare remote, never live GitHub.

    sebelum_push is a test seam for real races/response loss. Production CLI
    never exposes it. No local checkout/index/branch is updated by this function.
    """
    if not cabang.startswith('arena/') or not re.fullmatch(r'[A-Za-z0-9_./-]+', cabang):
        raise Terblokir('Cabang tujuan bukan cabang Arena.')
    if not 1 <= upaya <= 5:
        raise Terblokir('Batas upaya wajib 1–5.')
    path = jalur_laporan(jenis, nama, isi)
    ref = f'refs/heads/{cabang}'
    with tempfile.TemporaryDirectory(prefix='kirim-laporan-') as tmp:
        root = Path(tmp)
        git(root, 'init', '--bare', '--initial-branch', cabang, '.')
        # Read auth through gh; do not copy/store tokens or original repo config.
        git(root, 'config', 'credential.helper', '!gh auth git-credential')
        git(root, 'config', 'user.name', penulis[0])
        git(root, 'config', 'user.email', penulis[1])
        blob = teks_dari_input(root, isi)
        terakhir = None

        def ambil() -> str | None:
            p = git(root, 'ls-remote', '--exit-code', remote, ref, wajib=False)
            if p.returncode == 2:
                return None
            if p.returncode:
                raise Terblokir('Remote tidak dapat dibaca; periksa sambungan GitHub di Arena.')
            baris = p.stdout.decode().strip().split('\t')
            if len(baris) != 2 or baris[1] != ref or not re.fullmatch(r'[0-9a-f]{40,64}', baris[0]):
                raise Terblokir('Jawaban remote tidak cocok cabang tujuan.')
            sha = baris[0]
            git(root, 'fetch', '--no-tags', '--no-write-fetch-head', remote, sha)
            return sha

        def cek(sha: str) -> bool:
            entry = git(root, 'ls-tree', sha, '--', path).stdout
            if not entry:
                return False
            if not entry.startswith(f'100644 blob {blob}\t'.encode()):
                raise Terblokir('Path tujuan telah berisi data/mode berbeda; DILARANG menimpa.')
            if git(root, 'show', f'{sha}:{path}').stdout != isi:
                raise Terblokir('Isi remote tidak sama dengan snapshot laporan.')
            return True

        def bukti(sha: str, n: int) -> dict:
            commit = teks(root, 'log', '-1', '--format=%H', sha, '--', path)
            return dict(status='TERVERIFIKASI', cabang=cabang, path=path,
                        commit=commit, remote_tip=sha, blob=blob,
                        sha256=hashlib.sha256(isi).hexdigest(), upaya=n)

        for n in range(1, upaya + 1):
            parent = ambil()
            if parent is None:
                if terakhir is not None or not dasar_baru:
                    raise Terblokir('Cabang hilang/belum ada dan tidak ada dasar terbit yang aman.')
                # For a not-yet-published session branch, parent must already be
                # obtainable from origin; never export an unpublished local chain.
                if not re.fullmatch(r'[0-9a-f]{40,64}', dasar_baru):
                    raise Terblokir('Dasar cabang baru tidak sah.')
                git(root, 'fetch', '--no-tags', '--no-write-fetch-head', remote, dasar_baru)
                parent = dasar_baru
            if terakhir and git(root, 'merge-base', '--is-ancestor', terakhir, parent, wajib=False).returncode:
                raise Terblokir('Riwayat remote mundur/bercabang; tidak boleh dipulihkan otomatis.')
            terakhir = parent
            if cek(parent):
                return bukti(parent, n)
            # Reject any non-directory ancestor (symlink/submodule/file).
            for prefix in ('docs', 'docs/uji', f'docs/uji/{jenis}'):
                entry = git(root, 'ls-tree', parent, '--', prefix).stdout
                if entry and not entry.startswith(b'040000 tree '):
                    raise Terblokir('Folder laporan remote bukan direktori biasa.')
            git(root, 'read-tree', parent)
            git(root, 'update-index', '--add', '--cacheinfo', f'100644,{blob},{path}')
            tree = teks(root, 'write-tree')
            commit = teks(root, 'commit-tree', tree, '-p', parent, '-m', f'laporan: {Path(path).name}')
            diff = git(root, 'diff-tree', '--no-commit-id', '--name-status', '-r', parent, commit).stdout
            if diff != f'A\t{path}\n'.encode():
                raise Terblokir('Calon commit bukan tepat SATU tambahan laporan.')
            if sebelum_push:
                sebelum_push(n, root, commit, ref)
            # A timeout or lost reply is ambiguous: verify server state before
            # deciding failure. Never interpret a successful exit alone as proof.
            try:
                git(root, 'push', '--porcelain', remote, f'{commit}:{ref}', wajib=False)
            except Terblokir:
                pass
            seen = ambil()
            if seen is None:
                raise Terblokir('Cabang menghilang setelah push; jangan buat ulang otomatis.')
            if git(root, 'merge-base', '--is-ancestor', parent, seen, wajib=False).returncode:
                raise Terblokir('Riwayat remote berubah tidak fast-forward.')
            if cek(seen):
                return bukti(seen, n)
            if n < upaya:
                time.sleep(0.05 * n)
        raise Terblokir('Lima upaya habis/ditolak: laporan BELUM TERVERIFIKASI, jangan klaim selesai.')


def teks_dari_input(root: Path, isi: bytes) -> str:
    return git(root, 'hash-object', '-w', '--stdin', data=isi).stdout.decode().strip()
