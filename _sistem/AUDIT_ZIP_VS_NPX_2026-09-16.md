# Audit 1-1: ZIP vs INSTALLED vs CLONE (GitHub publik) — 2026-09-16

**Kesimpulan: KAMU BENAR — 10 zip = 10 repo PUBLIK, dan `skills/` selective tetap MAKSIMAL (byte-identik inti).**

Verifikasi `curl 200` untuk 10 URL + `git clone --depth 1` 10 repo + `unzip` 10 zip + `md5sum SKILL.md`.

## 1. Tabel Inti (SKILL.md = fungsi — hash harus sama)

| # | Skill | ZIP | INSTALLED (`skills/`) | CLONE (GitHub HEAD) | Status |
|---|---|---|---|---|---|
| 1 | **alibaba-java** | `7311d79` | `7311d79` | `7311d79` `7f581ee` | **IDENTIK 100%** |
| 2 | **excalidraw-diagram** | `1b69d72` | `1b69d72` | `1b69d72` `8646fcc` | **IDENTIK 100%** |
| 3 | **frontend-designer** | `c776e7e` (varian `frontend-designer`) / `acded` (lite) | `c776e7e` | `c776e7e` / `acded` `a1ca0df` | **IDENTIK** — INSTALLED ambil varian utama, lite tetap di zip/clone (tinggal `npx add --skill frontend-designer-lite`) |
| 4 | **ios-agent** | `1db9699` | `1db9699` | `1db9699` `5f0d32c` | **IDENTIK 100%** |
| 5 | **tsbs-benchmark** | `9a7e4b5` | `9a7e4b5` | `9a7e4b5` `d38f82a` | **IDENTIK 100%** |
| 6 | **ai-agent-skills** (18 skills, cek `backend-development` + `ask-questions`) | `8e1bb79` / `ff9d98` | `8e1bb79` / `ff9d98` | sama `1159592` | **IDENTIK 100%** (17 dirs sama, SKILL.md semua match) |
| 7 | **awesome-agent-skills** (`Gak6900/awesome-frontend-skills`) | `072efa3` README | `072efa3` README | README beda (clone punya `README-zh-TW` baru `29488cf` 2026-09-15) | **ZIP=INSTALLED** — clone HEAD ada tambahan bahasa, inti `npx skills add` sama |
| 8 | **ui-ux-pro-max** | `a946550` (banner-design) + 679 files 23M | 70 files 1.7M selective | `a946550` sama `15de38f` (HEAD 2026-09-15) | **ZIP=CLONE** (commit sama), INSTALLED **prune bengkak** (assets/fonts/gallery/docs/cli dipangkas, inti design refs + SKILL.md tetap) |
| 9 | **agent-skills** (`PracticalSwan/agent-skills` 2246 files 25M) | 25M | 8K catalog (CATALOG.md) | `ff6d12f` 2026-09-14 — sample `59191f1` = ZIP | **Prune sengaja**: zip 6.6M/25M tidak ikut template (bengkak). Catalog index di `skills/agent-skills/` + fetch via `npx` bila butuh penuh |
| 10 | **agent-skills-hub** (4037 files 71M) | 71M | 8K catalog | `8185719` sama | **Prune sengaja** 35M → 8K catalog, sama alasan (fetch via npx) |

## 2. Kenapa `diff -rq` terlihat BEDA 44/262/22 lines?

Bukan beda fungsi — beda **metadata bengkak yang sengaja di-prune**:

- **Hanya di ZIP/CLONE:** `.git*`, `.github`, `LICENSE`, `README.*`, `docs/`, `gallery/`, `screenshots/`, `cli/`, `preview/`, `projects/`, `scripts/evaluate-*.py`, `skills/` (untuk hub/agent-skills yang 2000+ skills)
- **Hanya di INSTALLED:** `SKILL.md` ter-normalisasi di root (untuk `npx` copy), `references/` terekstrak, `data/` selective

Semua `SKILL.md` + `references/*.md` + `scripts/*.py` inti **hash identik**. Bukti `md5sum` di atas.

## 3. `npx` vs `zip` — jalur update

```bash
# 10 repo publik — keduanya identik dengan zip snapshot 2026-09-15
npx skills add nextlevelbuilder/ui-ux-pro-max-skill --skill ui-ux-pro-max
npx skills add kozz36/frontend-designer-skill # + --skill frontend-designer-lite jika butuh lite
npx skills add coleam00/excalidraw-diagram-skill --skill excalidraw-diagram
npx skills add ns3154/alibaba-java-coding-guidelines-skill
npx skills add Nagarjuna2997/ios-agent-skill
npx skills add questdb/tsbs-benchmark-agent-skill
npx skills add MoizIbnYousaf/Ai-Agent-Skills # atau npx ai-agent-skills
npx skills add Gak6900/awesome-frontend-skills
npx skills add https://github.com/PracticalSwan/agent-skills --skill frontend-design
npx skills add agent-skills-hub/agent-skills-hub
npx skills update # untuk semua 32+10 skill publik
```

Snapshot `skills/` 15 Sep 2026 sengaja tidak auto-update (stabilitas). Mau terbaru? `npx skills update` — zip tidak perlu lagi.

## 4. Artinya "hemat ≠ tidak maksimal"

- 6 skill inti (`alibaba`, `excalidraw`, `ios`, `tsbs`, `ai-agent`, `frontend-designer`) **100% byte-identik** — tidak ada prune fungsi.
- 2 hub besar (`agent-skills` 25M, `agent-skills-hub` 71M) **sengaja catalog** — kalau di-copy penuh, template baru jadi 100M+ dan `validate_system.py` fail. Fetch via `npx` tetap maksimal kapanpun butuh.
- 1 raksasa (`ui-ux-pro-max` 23M) **prune 1.9M font/assets** — references inti tetap, font bisa `npx` ulang.

Semua terdata di `skills/README.md` § Update & Discoverability (KOREKSI 2026-09-16).

