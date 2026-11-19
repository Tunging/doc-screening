---
name: doc-screening
description: >
  Periodic documentation screening for any Markdown knowledge base or docs/
  tree: orphan docs, transient-agent-artifacts, frontmatter/tag violations,
  duplicates, drift, and low-quality AI residue. Read-only by default —
  produces one report into the transient dir; never edits, moves, or deletes
  anything else. Trigger words: 文档巡检 / 文档初筛 / docs screening / doc audit.
---

# Doc Screening（文档初筛）

Read-only periodic screening of a Markdown knowledge base or `docs/` tree.
The **only write** this workflow performs is the report itself.

## Overview map

| Map item | Default | Override |
|---|---|---|
| Transient dir (reports live here) | `_screening/` | `_screening_dir` in AGENTS.md |
| Formal docs roots | `docs/` if it exists, else the root's `.md` files plus all first-level dirs | `_screening_formal_dirs` in AGENTS.md |
| Index/register doc | first of `docs/README.md`, `README.md` | — |
| Report path | `<transient>/screening-YYYY-MM-DD.md` | — |
| Report expiry line | 30 days after creation | `_screening_expiry_days` in AGENTS.md |

If a root `AGENTS.md` (or `CLAUDE.md`) exists, its rules **override the defaults** above.
If not, proceed with defaults and note it in the report header ("no AGENTS.md; defaults used").
Write the report in the dominant language of the docs being screened.

## Steps

### 1. Read conventions
Read root `AGENTS.md`/`CLAUDE.md` and the index doc. Extract: transient dir, formal dirs, whitelist, frontmatter template location, controlled tag vocabulary location.

### 2. Deterministic checks (batch with bash/grep; do not read file-by-file)
- **Orphans**: formal-dir `.md` files referenced by no other `.md` (check markdown links, wikilinks `[[...]]`, and HTML hrefs). Whitelist: index/README/AGENTS/CLAUDE files plus anything AGENTS.md lists under `_screening_whitelist`
- **Transient residue**: screening-type files sitting in the root or formal dirs (`_*` prefix, or name contains `audit|report|log|inventory|verification`)
- **Frontmatter**: missing, unparseable, or keys deviating from the project's template
- **Tags**: values outside the controlled vocabulary (if AGENTS.md declares one)
- **Stale reports**: transient-dir files older than the expiry line

### 3. Semantic sampling (read ≤ 20 files)
10 most recently modified + 10 random:
- **Duplicates**: same topic, heavy overlap → suggest `merge-to <target>`
- **Drift**: "planned / TODO / 将要" claims already done or abandoned; frontmatter facts contradicting body facts
- **AI residue / low quality**: dialogue tone ("Sure! Here's…"), hollow template sentences, truncated paragraphs, unfilled placeholders (`{{}}`, `<TODO>`)

### 4. Write the report `<transient>/screening-YYYY-MM-DD.md`

````markdown
---
type: screening
title: Doc Screening YYYY-MM-DD
---
# Doc Screening YYYY-MM-DD

> Read-only screening; no files changed besides this report.

## High priority (this week)
| File | Suggested action | Rule | Evidence |
|---|---|---|---|

## Medium priority
| File | Suggested action | Rule | Evidence |
|---|---|---|---|

## Statistics
- Scanned N files; suggest delete X / archive Y / update Z; semantic sample: 20
````

Action vocabulary: `delete / archive / update / merge-to <target> / register-in-index`.
Rule short names: `orphan` `residue` `frontmatter` `tags` `stale` `duplicate` `drift` `low-quality`.

## Hard boundaries

- **Never modify, move, or delete anything** except writing the one report
- Whitelist files (rules, index, README, templates) never enter "suggest delete"
- Semantic claims must cite evidence (file + line/quote); uncertain items get ⚠️ and drop to medium priority
- Stale transient files are listed as "suggest cleanup" — **human confirms before execution**
