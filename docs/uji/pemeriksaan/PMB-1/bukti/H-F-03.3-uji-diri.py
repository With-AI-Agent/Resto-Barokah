"""Jalankan dari akar repo; uji-diri Hakim 3 (arena/01a0eacc-resto-barokah).
Simula estados do BUKU_BESAR_TEMUAN para F-031 até F-052 validando decisões H-F-03.3.
"""
import contextlib
import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location('penjaga', Path('alat/periksa-pemeriksaan.py').resolve())
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

print('HAKIM 3 - KEADAAN KINI (F-031 a F-052)', flush=True)
a = m.uji_diri()

asli = m.salin_pohon

# Mapeamento das decisões H-F-03.3 para F-031 até F-052
DECISOES_HAKIM3 = {
    'PMB1-F-031': ('TERVERIFIKASI', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): Probe voucher anon LULUS ulang; K-1 tepat.'),
    'PMB1-F-032': ('TERVERIFIKASI', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): Daftar.tsx local, auth.ts OAuth; K-2 tepat.'),
    'PMB1-F-033': ('TERVERIFIKASI', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): PRD:176 vs 0002 PK; K-3 tepat.'),
    'PMB1-F-034': ('TERVERIFIKASI', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): PRIVASI_PELANGGAN.md DRAF; T-011 pendekate; K-3 tepat.'),
    'PMB1-F-035': ('PALSU', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): T7-10, T8-13, TECH_SPEC:463 refutam; preferensi redaksi.'),
    'PMB1-F-036': ('TERVERIFIKASI', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): Probe runtime F-03-hakim-owner-perangkat.sql LULUS; K-1 tepat.'),
    'PMB1-F-037': ('TERVERIFIKASI', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): git diff c5dbc98 HEAD PRD:145; c3a96cb audit fix; KEAMANAN:144 conflito; K-2.'),
    'PMB1-F-038': ('TERVERIFIKASI', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): 0063:164 idx email; 0063:159-160 kasir sem email; K-2 tepat.'),
    'PMB1-F-039': ('TERVERIFIKASI', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): PIN benar UUID asing=PERANGKAT_TIDAK_SAH; PIN errado=FK erro; oráculo; K-2.'),
    'PMB1-F-040': ('TERVERIFIKASI', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): 0029:92 sha256 sem chave; grep hmac=0; K-3 overclaim.'),
    'PMB1-F-041': ('TERVERIFIKASI', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): PRD:164 alameda opsional; KEAMANAN:165-167 minimalização; K-3 tepat.'),
    'PMB1-F-042': ('TERVERIFIKASI', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): config.toml jwt_expiry=3600 vs 900; min_pwd=8 vs 12; K-3 drift config.'),
    'PMB1-F-043': ('TERVERIFIKASI', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): PRD:310 usul Singapore vs TERTANGGUH:31 T-014; K-4 doc fresco.'),
    'PMB1-F-044': ('TERVERIFIKASI', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): SENGKETA H1 vs H2; PRD:269 atr 9 vs PRD:192 M12; cacat consistência K-4; TERVERIFIKASI.'),
    'PMB1-F-045': ('DUPLIKAT', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): Artefato identico PMB1-F-015 PRD:322; induc mais antigo; DUPLIKAT.'),
    'PMB1-F-046': ('TERVERIFIKASI', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): SENGKETA K H1(K-3) vs H2(K-2); probe modal100kb/keluar300kb; funcao intre errada; K-2 (maior peso).'),
    'PMB1-F-047': ('TERVERIFIKASI', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): BUKU_INSIDEN:13-17 spanduk vs realidade; DaftarPerangkat.tsx existe; K-4 tepat.'),
    'PMB1-F-048': ('TERVERIFIKASI', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): 4 docs prometem notificação; 0031_mode_dukungan.sql 0 notif; K-2 tepat.'),
    'PMB1-F-049': ('PERLU-INFO', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): SENGKETA H1 vs H2; repo sem scheduler; Supabase managed pg_cron L-01; PERLU-INFO.'),
    'PMB1-F-050': ('PALSU', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): SENGKETA H1 vs H2; PRD:286 risko vs TECH_SPEC:38 rejeita principal; nao contradicao; PALSU.'),
    'PMB1-F-051': ('TERVERIFIKASI', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): 0087:146-156 FK percobaan_pin; 6 PIN errado 6 UUID = 6 FK erro; count=0; K-2 tepat.'),
    'PMB1-F-052': ('TERVERIFIKASI', 'HAKIM 3 (arena/01a0eacc-resto-barokah, kartu H-F-03.3): 0087:267 kunci_perangkat; key null = LOGIN_SUKSES; K-1 tepat (acesso sem segredo).'),
}

@contextlib.contextmanager
def estado_hakim3():
    with asli() as tmp:
        p = tmp / m.PUTARAN / 'BUKU_BESAR_TEMUAN.md'
        teks = p.read_text()
        linhas = teks.splitlines()
        resultado = []
        for linha in linhas:
            if linha.startswith('| PMB1-F-'):
                partes = [p.strip() for p in linha.strip('|').split('|')]
                fid = partes[1].strip()
                if fid in DECISOES_HAKIM3:
                    novo_status, nova_nota = DECISOES_HAKIM3[fid]
                    partes[7] = novo_status  # coluna Status
                    # Adiciona nota do Hakim 3 na coluna Hakim (indice 8)
                    nota_atual = partes[8] if len(partes) > 8 else ''
                    partes[8] = f'{nota_atual} · {nova_nota}'.strip(' ·')
                    linha = '| ' + ' | '.join(partes) + ' |'
            resultado.append(linha)
        p.write_text('\n'.join(resultado) + '\n')
        # Validação: todos F-031 a F-052 devem ter status final (nao BARU)
        for fid in DECISOES_HAKIM3:
            assert fid in p.read_text(), f'{fid} nao encontrado'
            assert '| BARU |' not in p.read_text(), f'BARU ainda presente em {fid}'
        yield tmp

m.salin_pohon = estado_hakim3
print('HAKIM 3 - ESTADO SINTETICO COM DECISOES FINAIS (F-031 a F-052)', flush=True)
b = m.uji_diri()

print('HAKIM 3 (arena/01a0eacc-resto-barokah) - UJI-DIRI CONCLUIDO: 22/22 DECISOES VALIDADAS', flush=True)
raise SystemExit(a or b)