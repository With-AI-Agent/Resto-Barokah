# Tawaran Kapabilitas + Audit Skill — Sistem Building Aplikasi (Susulan K-10, 2026-09-15)

> **[ARSIP BER-tanggal — angka di bawah adalah keadaan 2026-09-15, bukan keadaan sekarang]**
> Koreksi 2026-09-16 (run klinik ke-2): `skills/` kini **26M / 56 direktori** setelah reinstall
> penuh via `npx` — kalimat "yang ikut adalah `skills/` 8.1M hasil selective" di bagian A sudah
> tidak berlaku. Isi arsip di bawah **tidak diubah** (append-only); keadaan terkini ada di
> `skills/README.md` § Registrasi + `SYSTEM_MANIFEST.md` § Dependency.

> Pengganti tawaran 2-kandidat stub sebelumnya (yang tanpa web_search) — disempurnakan maksimal sesuai `05_TAWARAN_KAPABILITAS.md` (W-08, meta v1.14.0 §b).
> **Riset wajib web_search 3-5 kandidat telah dilakukan**: 2026-09-15 query `building full-stack applications Claude Code skills + best Claude Code skills` → sumber [wasp.sh][1], [designrevision][2], [claudecodeguides][3], [nimbalyst][4], [medium/stack AI founders][5].

---

## A. Audit 10 zip dari `Input-Pengguna/` di repo meta (branch main 341fbd3, total 53,813,128 bytes) — **catatan template:** `Input-Pengguna/` tidak ikut saat `cp -r .../*` ke repo baru; yang ikut adalah `skills/` 8.1M hasil selective + catalog index. Bagian ini adalah **arsip audit historis** di repo meta, bukan dependensi template.

Scan: `unzip -l` + `strings | grep -Ei curl|base64|rm -rf|eval|subprocess|shell=True` + `unzip -p SKILL.md`. **Hasil: tidak ada virus/malware jelas.** Temuan `curl|bash`/`rm -rf` bersifat legit (installer `bun.sh`, Dockerfile cleanup, kubeconfig base64) — tidak auto-run.

| # | File zip | Ukuran | Isi / Struktur skill | Lisensi | Skor relevansi Building Aplikasi* | Risiko & catatan |
|---|----------|--------|----------------------|---------|-----------------------------------|------------------|
| 1 | `agent-skills-hub-main.zip` | 35M | 42k file, `skills/*` (3d-web-experience, ab-test, dsb 81857196…) + `.claude-plugin/` hub | Apache/MIT campur | ★★☆☆☆ katalog raksasa generik | **Bengkak parah** jika di-unzip penuh (35M). Ambil subset saja bila butuh skill spesifik. `curl bun.sh\|bash` di CI — jangan auto-run. |
| 2 | `agent-skills-main.zip` | 6.6M | 100+ skill (`accelerated-computing-cudf`, `accessibility`, dll) + `skills/` flat | MIT | ★★☆☆☆ katalog generik | 6.6M bengkak. Contoh `rm -rf /` hanya string di Dockerfile `rm -rf /var/lib/apt/lists` — aman. Selektif saja. |
| 3 | `ai-agent-skills-main.zip` | 328K | `skills/ask-questions-if-underspecified` + docs/workflows | MIT | ★★★☆☆ (gate Fondasi) | Kecil, aman. Cocok untuk Tahap 1-2 Fondasi: wajib tanya balik bila underspecified. |
| 4 | `alibaba-java-coding-guidelines-skill-main.zip` | 32K | `SKILL.md` + references/alibaba-java-rules.md + `skills/alibaba-java-coding-guidelines-skill/` | MIT | ★★☆☆☆ (stack-specific) | Kecil, aman, butuh hanya jika app Java/Spring/MyBatis. Instal selective 51K. |
| 5 | `awesome-agent-skills-main.zip` | 60K | `skills/` koleksi awesome (metadata .claude/skills) | MIT | ★★☆☆☆ katalog | Kecil, aman, katalog referensi — tidak perlu di-unzip penuh, pakai sebagai indeks. |
| 6 | `excalidraw-diagram-skill-main.zip` | 19K | `SKILL.md` (24K) + `references/` (color-palette, element-templates, json-schema, render_excalidraw.py, render_template.html) + `pyproject.toml` | MIT | **★★★★★** | **Kecil, aman, langsung terpasang 57K.** Untuk TECH_SPEC/ROADMAP visual yang argue visually + Playwright render pipeline. |
| 7 | `frontend-designer-skill-main.zip` | 80K | skills/frontend-designer/SKILL.md (5K) + skills/frontend-designer-lite/SKILL.md + references/technical-reference.md | Apache-2.0 | **★★★★★** | **Kecil, aman, langsung terpasang 24K.** Skill #1 peringkat eksternal [2] "Best for distinctive, non-generic UI". Trigger CSS tokens, responsive, a11y — paling cocok Fondasi+Coding non-teknis. |
| 8 | `ios-agent-skill-main.zip` | 2.0M | `SKILL.md` v3.3.0 (5K) + `plugins/ios-agent-skill/skills/ios-builder` + `templates/multiplatform-app` (775 file) | MIT | ★★★☆☆ (platform-specific) | Besar (8.8M unpacked), aman, `torch_model.eval()` bukan `eval(` malware. Butuh hanya jika app menarget iOS/macOS/watchOS. Tawarkan selective, jangan default. |
| 9 | `tsbs-benchmark-agent-skill-main.zip` | 18K | claude/SKILL.md + codex/SKILL.md (QuestDB TSBS) | Apache-2.0 | ★☆☆☆☆ | Kecil, aman, domain time-series benchmark — tidak relevan Building Aplikasi umum. |
| 10 | `ui-ux-pro-max-skill-main.zip` | 8.1M | `.claude/skills/` (banner, brand, design, design-system, slides, ui-styling, ui-ux-pro-max) + `.claude-plugin/` + `stack/` + `cli/` (811 file, 21M unpacked) | — | **★★★★★** (core) | **Besar bila penuh 21M.** Terpasang selective 2.1M: core + 3 subset (design, design-system, ui-styling). Prune 1.9M font data tidak esensial. `subprocess.Popen`/`literal_eval` hanya local Python — aman. |

\* Skor relevansi = seberapa langsung membantu Building Aplikasi membangun aplikasi untuk pemilik **non-teknis** (Fondasi 6 dokumen + Coding). ★★★★★ = langsung pakai setiap Tahap/Coding; ★☆ = niche.

**Keputusan audit (hemat C-06):** Pasang 3 inti (no.6,7,10 selective) = 2.1M (≈4% dari 53,813,128 bytes di repo meta). Sisa 7 zip tetap di `Input-Pengguna/` repo meta sebagai referensi katalog — tidak dihapus, tidak di-unzip penuh di repo meta; **di repo baru (template) yang ada hanya `skills/` hasil selective + catalog, bila butuh iOS/Java tinggal `npx skills add` tanpa Input-Pengguna**.

---

## B. Tawaran Borongan Kapabilitas (K-10) — 5 kandidat riset eksternal + user zip

> Sesuai format wajib 7 kolom `05_TAWARAN_KAPABILITAS.md §3`. Maks 5 item per pesan. Di bawah tabel ada pertanyaan terbuka wajib.

| Nama Kapabilitas | Fungsi / Tujuan | Alasan Butuh (mengapa Building Aplikasi INI butuh) | Cara Install (lmarena) | Risiko Pasang | Alternatif Lokal | Konsekuensi Ditolak |
|---|---|---|---|---|---|---|
| **frontend-designer** (user zip no.7) **[TERPASANG]** | Design-system production: tokens, CSS architecture, responsive, a11y, motion | Building Aplikasi janji pemilik non-teknis dapat UI non-generik; TECH_SPEC butuh token contract, bukan hardcode visual. Skill #1 "Best for Distinctive UI" [2] dan "dipakai product engineers untuk cut frontend time signifikan" [3] | Sudah: `Input-Pengguna/frontend-designer-skill-main.zip` → `skills/frontend-designer/` (SKILL.md+references, tanpa `npx`) [detail SKILL no.7] | Rendah (24K, Apache-2.0, no `curl\|bash` auto-run) | Buat manual `design.md` tanpa gate — rawan hardcode & a11y miss | UI generik, rework besar di Coding |
| **excalidraw-diagram** (user zip no.6) **[TERPASANG]** | Generate `.excalidraw` JSON yang argue visually + render PNG via Playwright | Fondasi DISCOVERY/TECH_SPEC/ROADMAP butuh visual arsitektur/workflow yang meyakinkan, bukan boxes-and-arrows uniform | Sudah: `excalidraw-diagram-skill-main.zip` → `skills/excalidraw-diagram/` (+ `pyproject.toml` `uv sync` bila butuh render) | Rendah (57K), perlu `uv`+`playwright` hanya bila render visual-loop dipakai | Gambar manual/ASCII — lambat & tidak validatable | Spec susah dipahami pemilik, inkonsistensi handoff |
| **ui-ux-pro-max (core+design-system/ui-styling)** (user zip no.10) **[TERPASANG selective]** | Reasoning lintas-stack (tokens, styles, typography, shadcn/Tailwind) + Brand/design assets | Mendukung frontend-designer dengan data-driven token & komponen; TECH_SPEC→Coding konsisten; termasuk template brand/slides untuk app bisnis | Sudah selective 2.1M: copy `.claude/skills/ui-ux-pro-max`+`design`+`design-system`+`ui-styling`; prune font data 1.9M (C-06) | Sedang (data CSV masih 1.7M) — tanpa prune jadi 3.6M | Tulis token manual per app — tidak scalable | Inkonsistensi visual, token drift |
| **Context7 / llms.txt docs** (eksternal riset) | Akses dokumentasi library versi-tepat (fresh docs on demand) vs MCP server | Building Aplikasi di Tahap 3 TECH_SPEC & Coding butuh implementasi akurat tanpa tebak API; Context7 peringkat #6 "Fresh library docs on demand" [2] & rekomendasi "LLM-friendly docs via llms.txt 10x lebih efisien dari MCP" [1] | Vendor-local: simpan llms.txt mirror + script tools/fetch-docs.mjs (stdlib, tidak global install) — runtime lmarena persist di repo | Rendah (text mirror), perlu update manual | web_search ad-hoc per task — lambat & konteks tipis | Bug akibat API hallucination |
| **Superpowers / Planning-with-Files + Playwright verify** (eksternal riset) | Workflow disiplin plan→spec→TDD + verifikasi visual di browser | Building Aplikasi butuh QA 3-lapis (CROSS_CHECK & Coding verify); Superpowers adalah "full plan→spec→TDD workflow" peringkat #2 [2]; Playwright adalah "browser automation & E2E" [2][4] & "Founders pakai Playwright MCP untuk verifikasi UI tanpa manual testing" [5] | Vendor-local: skills/superpowers (script plan/spec) + skills/playwright shim (npx playwright install chromium hanya di repo bila diminta) — tidak asumsi terinstall | Sedang (Playwright binary besar jika penuh) — tawarkan incremental | Checklist manual + test ad-hoc — variance tinggi | Defect lolos ke G-Final |

> **Apakah ada fungsi, skill, atau plugin lain yang kamu butuhkan tetapi belum ada di daftar di atas?** (wajib borongan K-10 — silakan sebut mis. `alibaba-java` untuk Java stack, `ios-agent-skill` untuk iOS-native, `ask-questions-if-underspecified` untuk gate Fondasi, atau plugin lain dari 10 zip yang belum terpasang — nanti ditanam selective di susulan berikutnya.)

**Catatan semantik install lmarena:** Semua skill di atas ditanam sebagai folder di skills/ di dalam folder sistem ini sehingga persist walau container reset — bukan npm install -g OS.

---

## C. Jejak riset eksternal (bukti web_search 2026-09-15)

- [1] https://wasp.sh/blog/2026/01/29/claude-code-fullstack-development-essentials — 3 essentials: debugging visibility, llms.txt, opinionated framework (Wasp)
- [2] https://designrevision.com/blog/best-claude-code-skills — 15 ranked: #1 Frontend Design, #2 Superpowers, #6 Context7, #10 webapp-testing, #11 Playwright, #13 security-guidance
- [3] https://claudecodeguides.com/claude-code-skills-for-product-engineers-building-full-stack — frontend-design, backend-api, tdd, pdf, xlsx, supermemory workflow
- [4] https://nimbalyst.com/blog/best-claude-code-skills-2026 — bundled: /code-review, write-tests, /batch, /debug, playwright, /verify
- [5] https://medium.com/activated-thinker/the-exact-stack-ai-founders-use-to-build-and-deploy-a-full-app-with-claude-code-in-2026-17efb2597a2c — stack founders: CLAUDE.md, skills/hooks, MCP, Playwright verification

---

## Log Keputusan

| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-15 | Tawaran 2-kandidat stub (tanpa web_search) dibuat lalu ditunda | Sesuai alur Klinik B, tapi belum penuhi wajib web_search §2 |
| 2026-09-15 | Audit 10 zip Input-Pengguna + scan keamanan + web_search 5 sumber, tawaran borongan 5 item (7 kolom) + pasang selective 3 skill inti (frontend-designer, excalidraw, ui-ux-pro-max selective 2.1M) | Perbaiki janji Klinik yang tertagih + penuhi C-06 hemat aset + amankan virus (curl\|bash tidak auto-run) |
