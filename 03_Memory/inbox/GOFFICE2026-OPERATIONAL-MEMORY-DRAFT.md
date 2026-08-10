---
title: GOFFICE2026 Operational Memory - Draft (2026-08-10)
date: 2026-08-10 (UTC)
status: REVIEW_REQUIRED
verified_facts:
  - Repo = github.com/numtip/goffice2026, branch master [GO-DASH-V2-HANDOFF-2026-08-07]
  - Phase A COMPLETE at commit 5a3b6af0154c6b5f4e3f6f641fbbf0152ae9cc34, HEAD == origin/master, Phase B then NOT STARTED [GO-DASH-V2-HANDOFF-2026-08-07]
  - Phase B = PARTIAL (B-A + B-B done, B-C remaining), version 1.3.0, commit 5f3209a4999bb08004f909dc79ea27571c056dc6, GH Pages deployed Run #144 [GO-DASH-V2-PHASE-B-HANDOFF-2026-08-08]
  - Data coverage frozen = 14/72 = 19% (energy 7 months Jan-Jul 2569, water 7 months Jan-Jul 2569, fuel/paper/waste/ghg 0 months, pending); coverage only, never an assessment score [GO-DASH-V2-HANDOFF-2026-08-07]
  - Taxonomy canonical = 7 categories, 24 issues, 65 indicators; evidence = 24 items updated 2026-07-27; last-updated stamp 2026-08-07 [GO-DASH-V2-HANDOFF-2026-08-07]
  - Energy FY2569 = 264,594.4 kWh (7 months); Water FY2569 = 5,572.03 m3 (7 months); both reconcile vs 2569 sheet row 17 col[6], verified 2026-08-07 [GO-DASH-V2-HANDOFF-2026-08-07] [GO-DATA-3-PHASE2-DESIGN]
  - Fuel/Paper/Waste/GHG FY2569 = CURRENT_DATA_PENDING, months=[], total=0 in JSON, VM returns total: null; missing months render em-dash, never 0 [GO-DASH-V2-HANDOFF-2026-08-07]
  - Phase A gates all pass = astro check 0 errors/0 warnings/10 hints, node --test 60/60, test-dashboard-executive 18/18, astro build 252 pages, smoke routes 42/42, deploy run 31165023526 success [GO-DASH-V2-HANDOFF-2026-08-07]
  - Phase B gates all pass = chart-option tests 22/22, npm test all pass, build 252 pages, smoke 42/42, links 10,488 hrefs / 4,316 unique, a11y H1-H2-H3 with table fallback, reduced-motion respected, no overflow at 390px/768px [GO-DASH-V2-PHASE-B-HANDOFF-2026-08-08]
  - B-A added buildExplorerOption (additive in chart-option.ts) + PerformanceExplorer.astro (shared EChart wrapper + details table fallback) at section 2b on TH and EN dashboards [GO-DASH-V2-PHASE-B-HANDOFF-2026-08-08]
  - B-B removed 7 unused components = CategoryScoreChart, MonthlyComparisonChart, DashboardInsight, DashboardKpiCard, ExecutiveKpi, ExecutiveInsight, Sparkline; kept ResourcePerformanceCard (landing page) and EChart (shared wrapper) [GO-DASH-V2-PHASE-B-HANDOFF-2026-08-08]
  - Do-not-touch = ResourcePerformanceCard.astro, EChart.astro, dashboard-phase-a-vm.ts (additive only), chart-option.ts (additive only), src/data/generated/*.json (frozen), src/data/criteria/*.json (canonical) [GO-DASH-V2-HANDOFF-2026-08-07] [GO-DASH-V2-PHASE-B-HANDOFF-2026-08-08]
  - Green Office 2569 categories = cat1 Energy Management, cat2 Water Management, cat3 Waste Management, cat4 GHG Emissions, cat5 Indoor Environmental Quality, cat6 Transportation, cat7 Innovation and Additional Features; canonical data src/data/categories.json; criteria stub docs/KB/GREENOFFICE_2569_CRITERIA.md; pages /categories and /categories/{id} [GREENOFFICE_2569_CONTEXT]
  - GO-DATA-3 Phase 2 = DESIGN only, not yet implemented (2026-08-07); 8 OneDrive workbooks to canonical dashboard JSON; dataset states = WAITING_FOR_INPUT / PUBLISHABLE_PARTIAL / COMPLETE / INVALID_SOURCE_DATA; missing months never zero (display minus sign means missing) [GO-DATA-3-PHASE2-DESIGN]
  - Phase 2 constraints = no production deploy, OneDrive source read-only, staff Excel workflow unchanged; Phase 1 done = staged sources (8) + manifest v2 at data/staging/ [GO-DATA-3-PHASE2-DESIGN]
  - Template baselines = waste2026 f3d42ec9970595bd, ghg2026 8cd94aa0a8f0d052 (identical to FY2568 by design); copied template values carry no edit signal [GO-DATA-3-PHASE2-DESIGN]
  - Canonical FY2569 ranges = water 1.1Water.xlsx, electricity 1.2electric.xlsx, fuel 1.3Gassolene.xlsx, paper 1.4paper.xlsx (all 2569 sheet rows 4-15 col[6]); waste 1.5waste2026.xlsx (monthly-waste sheet rows 3-18 + calc-pct sheet rows 2-5, cols 1-12); ghg 1.6GreenHouseGas2026.xlsx (annual-summary sheet rows 7-24; EF reference sheet EF TGO AR5) [GO-DATA-3-PHASE2-DESIGN]
  - Known data flags = waste cross-sheet mismatch Jan 468.1 vs 468.9 (tolerance 0.5); GHG baseline total 231.23 vs existing 231.6 tCO2e (PO decision) [GO-DATA-3-PHASE2-DESIGN]
  - Maintenance backlog = 6 dependency advisories (astro/vite/js-yaml/postcss/sharp high, esbuild moderate); npm audit fix forbidden; ~25 MB generated dumps under docs/migration/; Lighthouse >=95 baseline pending [GO-DASH-V2-PHASE-B-HANDOFF-2026-08-08]
open_decisions:
  - PO #3 = GHG 2568 baseline: re-baseline to 231.23 tCO2e from approved workbook, or keep 231.6? (needed before ghg-2568 extraction) [GO-DATA-3-PHASE2-DESIGN sec 8]
  - PO #4 = Paper 2569 ream-to-kg conversion factor (needed before paper-2569 extraction) [GO-DATA-3-PHASE2-DESIGN sec 8]
  - PO #5 = Waste authoritative sheet for KPI totals: calc-pct sheet vs detail sheet (needed before waste normalization) [GO-DATA-3-PHASE2-DESIGN sec 8]
  - PO #6 = Publish water/electric 7/12 as PUBLISHABLE_PARTIAL now? (needed at Phase 2 import) [GO-DATA-3-PHASE2-DESIGN sec 8]
  - B-C scope still open = full TH/EN parity audit, visual regression on /dashboard/[id]/ (desktop/tablet/mobile), a11y keyboard nav audit, Lighthouse >=95 retest, reduced-motion check on metric dashboards [GO-DASH-V2-PHASE-B-HANDOFF-2026-08-08]
  - Maintenance decisions = Astro line bump vs 6 advisories (fix plan pending), classification of untracked docs (NEEDS_PO_REVIEW list), disposition of 25 MB docs/migration/ dumps [GO-DASH-V2-PHASE-B-HANDOFF-2026-08-08]
  - Phase C candidates NOT STARTED = data-table drill-down, YoY comparison explorer, metric detail enhancements [GO-DASH-V2-PHASE-B-HANDOFF-2026-08-08]
next_actions:
  - Resume Phase B-C only: cd G:/ProjectAI/goffice2026, git pull origin master, verify HEAD == 5f3209a4999bb08004f909dc79ea27571c056dc6; do NOT redo Phase A / B-A / B-B [GO-DASH-V2-PHASE-B-HANDOFF-2026-08-08]
  - Baseline gates before new work: npm run check (0 errors), node --test scripts/test-chart-option.mjs (22/22), npm run build (252 pages) [GO-DASH-V2-PHASE-B-HANDOFF-2026-08-08]
  - Execute remaining B-C items = TH/EN parity audit, metric-dashboard visual regression, a11y keyboard audit (tab order/focus), Lighthouse >=95 retest, prefers-reduced-motion on metric dashboards [GO-DASH-V2-PHASE-B-HANDOFF-2026-08-08]
  - Raise PO decisions #3-#6 before Phase 2 extraction, waste normalization, and import [GO-DATA-3-PHASE2-DESIGN sec 8]
  - Build GO-DATA-3 Phase 2 pipeline = sync-workbooks.mjs, extract-workbook.mjs (parsers A-D), multi-year-schema.ts extension (datasetState, wasteBreakdown, ghgActivities), validator + dataClassification additions; then run npm run data:build, data:validate, qa:routes [GO-DATA-3-PHASE2-DESIGN sec 7]
  - Plan Astro line bump for the 6 dependency advisories; never run npm audit fix [GO-DASH-V2-PHASE-B-HANDOFF-2026-08-08]
  - Classify/commit untracked docs per NEEDS_PO_REVIEW; review 25 MB docs/migration/ dumps; baseline RUNTIME_QA/Lighthouse after next deploy [GO-DASH-V2-PHASE-B-HANDOFF-2026-08-08]
  - Extend JSON before duplicating page copy; keep criteria summaries concise and chunked, never dump full 2569 criteria into prompts [GREENOFFICE_2569_CONTEXT]
sources:
  - path: G:/ProjectAI/goffice2026/docs/handoff/GO-DASH-V2-HANDOFF-2026-08-07.md (sha256=a1c1ae4baf683def77e135d76ec6e83721998a625825f82097828592d2c61dc2)
  - path: G:/ProjectAI/goffice2026/docs/handoff/GO-DASH-V2-PHASE-B-HANDOFF-2026-08-08.md (sha256=846601ac23b6c1fee6497d32807898dd701a2e0319e6ca2518acee1cc398d1ad)
  - path: G:/ProjectAI/goffice2026/docs/context-packs/GREENOFFICE_2569_CONTEXT.md (sha256=7fc38577e35e0eba0ab5bdcc62f536301441347f72a559433ae5a7a1283de7b8)
  - path: G:/ProjectAI/goffice2026/docs/data/GO-DATA-3-PHASE2-DESIGN.md (sha256=998e436a25ee9c6521f1bc0f06163027f419d55ad0ccc035366e28934b99c579)
---
