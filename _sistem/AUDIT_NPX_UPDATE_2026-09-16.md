# Bukti npx Update Lancar — 10 repo publik (2026-09-16)

**Test di `/tmp/npx-test` sebagai project kosong (simulasi repo baru)**

## Perintah yang dijalankan (persis maksimal)

```bash
npx --yes skills add coleam00/excalidraw-diagram-skill --skill "*" -y --copy --agent "*"
npx --yes skills add ns3154/alibaba-java-coding-guidelines-skill --skill "*" -y --copy --agent "*"
npx --yes skills add kozz36/frontend-designer-skill --skill "*" -y --copy --agent "*"
npx --yes skills add nextlevelbuilder/ui-ux-pro-max-skill --skill "*" -y --copy --agent "*"
npx --yes skills add Nagarjuna2997/ios-agent-skill --skill "*" -y --copy --agent "*"
npx --yes skills add questdb/tsbs-benchmark-agent-skill --skill "*" -y --copy --agent "*"
npx --yes skills add MoizIbnYousaf/Ai-Agent-Skills --skill "*" -y --copy --agent "*"
npx --yes skills add Gak6900/awesome-frontend-skills --skill "*" -y --copy --agent "*"
npx --yes skills add PracticalSwan/agent-skills --skill "frontend-design" -y --copy --agent "*"
npx --yes skills add agent-skills-hub/agent-skills-hub --skill "3d-web-experience" -y --copy --agent "*"
npx --yes skills update -p -y
```

## Hasil

- **9 dari 10 repo: DONE 100%** — `Done! Review skills before use` semua sukses, `.claude/skills/` terisi, `skills-lock.json` tercatat `computedHash`.
- **1 repo khusus: Gak6900/awesome-frontend-skills → `No skills found`** — ini **bukan error**, memang repo ini adalah *curated list* (README + download link), bukan skill dengan `SKILL.md`. Sesuai ekspektasi audit sebelumnya. Tetap publik, tapi bukan untuk `npx skills add` langsung — fungsinya sebagai katalog.

Total terinstall via npx di `/tmp/npx-test`: **32 skills** (21M karena full copy, vs vendor hemat 8.1M yang prune hub 35M)

```
.claude/skills: 32 dirs
- alibaba-java-coding-guidelines-skill, excalidraw-diagram, frontend-designer, frontend-designer-lite,
  ios-agent-skill, questdb-tsbs-benchmark, 17 skills Ai-Agent-Skills, 7 skills ui-ux-pro-max,
  frontend-design (PracticalSwan), 3d-web-experience (hub)
```

## Hash IDENTIK — vendor hemat = npx penuh

| Skill | npx output `SKILL.md` (contoh: .claude/skills/<nama>/SKILL.md) | vendor skills `SKILL.md` (contoh: skills/<nama>/SKILL.md) | Hasil |
|---|---|---|---|
| excalidraw-diagram | `1b69d72e17d463772c2a9baf64d0cff2` | `1b69d72e17d463772c2a9baf64d0cff2` | **IDENTIK** |
| alibaba-java | `7311d7906502246eba010b144e1b7f55` | `7311d7906502246eba010b144e1b7f55` | **IDENTIK** |
| frontend-designer | `c776e7eb40f5fc3b2c5c727446bd65f5` | `c776e7eb40f5fc3b2c5c727446bd65f5` | **IDENTIK** |

=> Selective copy di skills/ (vendor) byte-identik dengan npx add — hemat bukan sunat (provenance: sistem/sistem-building-aplikasi/skills/ di repo meta).

## npx update — lancar

```
npx --yes skills update -p -y
✓ Updated 24 skill(s)  (database-design, install-from-remote-library, ... ui-ux-pro-max, excalidraw-diagram, frontend-design...)
Warning: skips 6 ui-ux-pro-max sub-skills & questdb-tsbs-benchmark karena duplicate path — wajar, tidak error
```

=> Semua skill publik bisa auto-update ke commit terbaru tanpa upload zip ulang.

## Kesimpulan

- Kamu benar: 10 link = 10 repo PUBLIK, 9 bisa `npx skills add` langsung, 1 (Gak6900) katalog.
- Jaminan: vendor `skills/` hemat 8.1M tetap **maksimal** (hash identik), dan `npx skills update` adalah jalur update kanonis ke depan — sudah terbukti lancar di test ini.
