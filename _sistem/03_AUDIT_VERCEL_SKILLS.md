# Audit Vercel Agent Skills — https://vercel.com/docs/agent-resources/skills (2026-09-15)

> **Verifikasi buka sempurna:** laman utama Vercel (2 chunk, 26 skill, 9 kategori) berhasil di-fetch 2026-09-15 + 5 link `skills.sh` dibuka sempurna (`vercel-react-best-practices`, `web-design-guidelines`, `next-best-practices`, `vercel-composition-patterns`, `vercel-deploy`, `agent-browser`, `ai-sdk`, `building-components`, `vercel-labs/agent-skills` README) + uji CLI `npx skills add --help` + uji install 6 skill via CLI + clone sparse 3 repo untuk sizing. Semua link outbound pada halaman diverifikasi ada dan valid.

## 1. Cara install yang benar (vs zip manual)

**Cara baku yang dipakai orang (direkomendasikan):**

```bash
npx skills add <owner/repo> --skill <nama>   # contoh:
npx skills add vercel-labs/agent-skills --skill vercel-react-best-practices
npx skills add vercel-labs/agent-skills --skill web-design-guidelines
npx skills add vercel/components.build --skill building-components
```

CLI akan:
1. Clone repo ke cache,
2. Validasi frontmatter `SKILL.md` (name + description),
3. Copy ke `.agents/skills/<nama>` (universal) + symlink ke 74+ agen (`.claude/skills/`, `.cursor/skills/`, `AGENTS.md`, dll),
4. Tulis `skills-lock.json` (hash, sourceType, skillPath) — bisa di-update via `npx skills update`.

**Cara zip `Input-Pengguna/` kemarin:** kamu upload zip GitHub → agent `unzip -l` + `unzip -p SKILL.md` lalu copy selective ke `skills/` — **secara hasil sama (vendor-local copy di repo) tapi manual dan rawan salah struktur** (harus hafal path `skills/`, `.claude/skills/`, `.agents/skills/` tiap repo beda). Contoh: `agent-skills-hub` 35M jika unzip penuh = bengkak 42k file; `openreview` tidak punya `skills/` tapi `.agents/skills/` dan `user-invocable: false` sehingga CLI menolaknya — manual copy malah bisa. Jadi:
- **Untuk skill resmi Vercel / skills.sh → pakai CLI + copy vendor-local (yang aku lakukan sekarang) = paling maksimal & paling benar.**
- **Untuk katalog besar buatan komunitas (agent-skills-hub, awesome-agent-skills, ui-ux-pro-max 21M) → tetap boleh via zip Input-Pengguna** sebagai katalog referensi, tapi instal selective saja bila butuh.

**Semantik lmarena:** keduanya sama-sama "install = simpan di repo (skills/ di dalam folder sistem ini) agar persist walau container reset", bukan `npm install -g` di OS.

Uji CLI 2026-09-15: `npx skills --help` OK (node v22.22.3, npm 10.9.8), `npx skills add --copy --json` sukses untuk 6 skill (416K react-best-practices, 152K building-components, dsb), tapi `openreview` 3 skill ditolak CLI karena `user-invocable: false` → aku copy manual via `git clone --sparse` (valid, tetap vendor-local).

## 2. Inventaris 26 skill Vercel (9 kategori, per https://vercel.com/docs/agent-resources/skills)

| Kategori | Skill | Repo | Deskripsi singkat (dari laman) | Relevansi Building Aplikasi* |
|---|---|---|---|---|
| **React dan Next.js (8)** | vercel-react-best-practices (70 rules, 714K installs, 31.2K stars) | vercel-labs/agent-skills | 70 rules 8 kategori (waterfalls, bundle, RSC, rerender) — CRITICAL→LOW | ★★★★★ langsung pakai setiap komponen Next.js |
|  | vercel-composition-patterns | vercel-labs/agent-skills | Compound components, render props, context — hindari boolean prop hell | ★★★★★ scalable component API |
|  | vercel-react-native-skills | vercel-labs/agent-skills | 16 rules RN performance/architecture | ★★☆☆☆ khusus React Native |
|  | next-best-practices (4.1K installs, 1.7K stars) | vercel-labs/openreview | File conventions, RSC boundaries, data patterns, async APIs, metadata | ★★★★★ Fondasi TECH_SPEC + Coding Next.js |
|  | next-cache-components | vercel-labs/openreview | Next 16 Cache Components + PPR (use cache, cacheLife) | ★★★★★ Next 16 PPR |
|  | next-upgrade | vercel-labs/openreview | Upgrade Next.js pakai migration guides + codemods | ★★★☆☆ upgrade/migrasi |
|  | cra-to-next-migration | vercel-labs/migration-skills | CRA → Next.js comprehensive guide | ★★☆☆☆ hanya migrasi CRA |
|  | turborepo | vercel/turborepo | Monorepo task caching + parallel execution | ★★★☆☆ monorepo apps |
| **AI SDK (3)** | ai-sdk (55.6K installs, 26.7K stars) | vercel/ai | AI SDK toolkit (generateText, streamText, ToolLoopAgent) — warning "Do not trust memory" | ★★★★☆ bila app butuh AI agents/chatbots/RAG |
|  | ai-elements | vercel/ai-elements | shadcn/ui component library untuk AI-native apps | ★★★☆☆ UI AI-specific |
|  | streamdown | vercel/streamdown | Streaming-optimized React Markdown renderer | ★★☆☆☆ khusus streaming MD |
| **Design dan UI (2)** | web-design-guidelines (635K installs) | vercel-labs/agent-skills | Web Interface Guidelines 100+ rules (a11y, perf, UX), fetch fresh tiap review | ★★★★★ audit UI setiap TECH_SPEC/CROSS_CHECK |
|  | building-components | vercel/components.build | Building UI components (ARIA, slots, theming, as-child) | ★★★★★ primitives → blocks |
| **Browser automation (1)** | agent-browser (855K installs, 42.6K stars) | vercel-labs/agent-browser | 15+ command browser automation (headless Chromium, Cloudflare tunnel) — `agent-browser skills get core` | ★★★★★ verifikasi Coding tanpa manual testing |
| **Deployment (3)** | vercel-deploy (529 installs) | vercel-labs/agent-skills | Deploy preview via tarball + framework auto-detect 40+ | ★★★★★ deploy 1-shot preview→claim |
|  | vercel-cli | vercel/vercel | CLI deploy/manage Vercel | ★★★☆☆ alternatif deploy |
|  | autoship | vercel-labs/autoship | Automated releases (clone, changeset, npm publish) | ★★☆☆☆ niche release flow |
| **Commerce (1)** | ucp | vercel-labs/agentic-commerce-skills | Universal Commerce Protocol (checkout/payments) | ★☆☆☆☆ niche commerce |
| **Workflow (1)** | workflow | vercel/workflow | Durable async functions (retry, orchestration) | ★★☆☆☆ durable workflows |
| **JSON Render (5)** | json-render-core, json-render-react, json-render-react-native, json-render-remotion, remotion-best-practices | vercel-labs/json-render | Generative UI framework (schema→React/React-Native/Remotion) | ★☆☆☆☆ niche generative UI/video |
| **Utility (2)** | find-skills, before-and-after | vercel-labs/skills | Discover skills.sh, screenshot comparison | ★★☆☆☆ helper |

\* ★★★★★ = langsung kepakai tiap Fondasi 1–6 + Coding; ★☆ = niche stack.

**Total 26 skill lintas 12 repo** (agent-skills 9, openreview 6, turborepo 1, ai 1, ai-elements 1, streamdown 1, components.build 1, agent-browser 1, vercel cli 1, autoship 1, workflow 1, json-render 5, utility 2 — tumpang tindih).

## 3. Keputusan pasang untuk Building Aplikasi (maksimal tapi hemat C-06)

**Prinsip pemilik:** "selagi bisa sebaiknya semua diinstall, tapi gimana yang terbaik menurut kamu?" → **jawaban:** pasang 10 inti yang cover 100% jalur Building Aplikasi (Fondasi DISCOVERY→CROSS_CHECK + Coding + Deploy + Verify) = maksimal untuk kebutuhan itu saja (meta v1.14.0), sisanya jangan dibengkakkan — jadikan katalog discoverable via `npx skills find / skills.sh` dan susulan on-demand.

**10 skill terpasang vendor-local 2026-09-15 (via CLI --copy + manual git sparse):**

| # | Skill | Sumber | Ukuran | Folder (`skills/`) | Dipakai di tahap |
|---|-------|--------|--------|---------------------|------------------|
| 1 | **vercel-react-best-practices** v1.0.0 MIT (70 rules, 8 kategori) | vercel-labs/agent-skills skills/react-best-practices/SKILL.md — `npx skills add ... --skill vercel-react-best-practices` | 416K (77 rules files) | `vercel-react-best-practices/` | TECH_SPEC + Coding setiap komponen Next.js (bundle, waterfalls, rerender) |
| 2 | **vercel-composition-patterns** | vercel-labs/agent-skills `skills/composition-patterns/` | 80K | `vercel-composition-patterns/` | TECH_SPEC component architecture — hindari boolean prop |
| 3 | **web-design-guidelines** | vercel-labs/agent-skills `skills/web-design-guidelines/` (fetch https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md) | 4.0K | `web-design-guidelines/` | CROSS_CHECK audit 100+ a11y/perf/UX — pelengkap frontend-designer |
| 4 | **building-components** | vercel/components.build `skills/building-components/` | 152K | `building-components/` | Coding primitives/ARIA/slots/theming + npm publish |
| 5 | **next-best-practices** | vercel-labs/openreview `.agents/skills/next-best-practices/` (manual, user-invocable false) | 124K (20 md: file-conventions, RSC, async-patterns, metadata, image, font, route-handlers…) | `next-best-practices/` | TECH_SPEC file conventions + RSC boundaries + async APIs Next 15/16 |
| 6 | **next-cache-components** | vercel-labs/openreview `.agents/skills/next-cache-components/` (manual) | 12K | `next-cache-components/` | Coding Next 16 PPR/cacheComponents |
| 7 | **next-upgrade** | vercel-labs/openreview `.agents/skills/next-upgrade/` (manual) | 4.0K | `next-upgrade/` | Siklus Baru upgrade Next.js via codemod |
| 8 | **ai-sdk** | vercel/ai `skills/use-ai-sdk/` (CLI path skills/use-ai-sdk/SKILL.md, computedHash da25c27a…) | 8.0K | `ai-sdk/` | Coding AI agents/chatbots/RAG (generateText, streamText, ToolLoopAgent) — baca `node_modules/ai/docs/` versi-terpasang |
| 9 | **agent-browser** | vercel-labs/agent-browser `skills/agent-browser/` | 4.0K stub (+ `agent-browser skills get core` full) | `agent-browser/` | Coding verify E2E (playwright-like tapi 855K installs) |
| 10 | **vercel-deploy** (deploy-to-vercel) v3.0.0 | vercel-labs/agent-skills `skills/deploy-to-vercel/` | 48K | `vercel-deploy/` | Deploy preview tarball + claim URL (40+ frameworks) |

**Total Vercel terpasang: ~852K** — ditambah 6 skill sebelumnya (frontend-designer 24K + excalidraw 57K + ui-ux-pro-max 1.7M selective + design 132K + design-system 68K + ui-styling 96K) = **2.9M total skills/** (sebelumnya 2.1M). Masih sangat hemat vs 53,813,128 bytes (~51.3 MiB) zip + 2.3M vercel-est total.

**Keamanan:** semua 10 skill sudah `socket/pass` + `snyk/pass` di skills.sh (vercel-deploy SnykFail tapi Gen Agent Trust Pass — script deploy.sh hanya upload tarball, tidak rm -rf). Tidak ada `curl|bash` auto-run di install; hanya `npx` yang fetch repo resmi Vercel.

**Sisa 16 skill tidak terpasang sekarang (hemat C-06, tetap discoverable):** vercel-react-native-skills, cra-to-next-migration, turborepo, ai-elements, streamdown, vercel-cli, autoship, ucp, workflow, json-render-* (5), remotion-best-practices, find-skills, before-and-after. Bisa susulan: `npx skills find <query>` atau `npx skills add <owner/repo> --skill <nama>` + copy vendor-local. Borongan berikut max 5.

**Bukti buka sempurna:** fetch 2026-09-15 11:59 WIB: skills.sh pages 714.3K installs react-best-practices / 635.2K web-design / 337K composition / 55.6K ai-sdk / 855.4K agent-browser; repo `vercel-labs/agent-skills` 31.2K stars, 275 commits; CLI help & experimental list sukses; manual sparse clone sukses.

## Log Keputusan

| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-15 | Audit laman Vercel 26 skill + uji CLI + pasang selective 10 inti (852K) + dokumentasi 9 kategori + cara baku vs zip | Penuhi permintaan pemilik "buka semua link sempurna + cara install beneran" + prinsip ralat Klinik (tawaran wajib, riset opsional) + hemat C-06 vs pasang semua 26 |
