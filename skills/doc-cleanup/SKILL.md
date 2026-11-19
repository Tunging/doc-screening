---
name: doc-cleanup
description: >
  Execute confirmed items from a doc-screening report: archive, update,
  merge-to, register-in-index, and materialize the suggested AGENTS.md draft.
  Runs ONLY on items a human explicitly confirmed; every filesystem change is
  logged to a manifest in the transient dir. Never hard-deletes.
  Trigger words: 执行文档整理 / 文档清理 / doc cleanup / apply screening report.
---

# Doc Cleanup（执行文档整理）

Companion to the **doc-screening** skill. Screening proposes; this skill disposes — **only what a human explicitly confirmed**.

## Inputs (both required)

1. **Report path**: `<transient>/screening-YYYY-MM-DD.md` produced by doc-screening.
2. **Confirmed items**: the human must state which report rows are approved — by file path or row reference (`确认 docs/b.md 和 _audit.md` / `确认全部` / `approve rows 1 and 3`). "Run cleanup" without a confirmation statement → ask for the list; do not guess.

Read root `AGENTS.md`/`CLAUDE.md` for conventions (transient dir, archive dir override, whitelist). Absent → defaults: transient `_screening/`, archive `_screening/trash-YYYY-MM-DD/`.

## Action semantics

| Action | What it does |
|---|---|
| `delete` / `archive` | **Move** the file into the archive dir (`_screening_archive_dir` override, else `_screening/trash-YYYY-MM-DD/`), preserving its relative path. Never hard-delete; purging the archive dir is a human `rm`. |
| `update` | Apply only the evidence-backed edits named in that report row. No drive-by rewriting beyond them. |
| `merge-to <target>` | Append the source's unique content under a `## Merged from <file>` heading in the target, then archive the source. |
| `register-in-index` | Add a link (markdown or wikilink, matching the index doc's style) in the index/overview doc named in the row's evidence. |
| `adopt-AGENTS-draft` | Write root `AGENTS.md` verbatim from the report's "Suggested AGENTS.md draft" section. Leave `CLAUDE.md` symlinking to the human (`ln -s AGENTS.md CLAUDE.md`); note it in the manifest. |

## Procedure

1. Read the report and the conventions file. Build the work list: confirmed rows only.
2. For each item, state the concrete action (source → destination / edit scope). If anything is ambiguous — missing evidence, target missing, conflicts with whitelist or conventions — **skip it** and record `skipped: <reason>`; never improvise.
3. Execute the actions.
4. Write the manifest `<transient>/cleanup-YYYY-MM-DD.md`:

```markdown
---
type: cleanup
title: Doc Cleanup YYYY-MM-DD
report: screening-YYYY-MM-DD.md
---
# Doc Cleanup YYYY-MM-DD

| File | Action | Before → After | Result |
|---|---|---|---|

- Summary: N applied, M skipped (reasons above)
```

5. Final reply: the manifest table inline; remind the human that archived files sit in the archive dir for review and physical purge is manual.

## Hard boundaries

- Only items present in the referenced report **and** explicitly confirmed by the human. Everything else → refuse.
- Never `rm` content files; archiving is the only form of deletion.
- Whitelist files are touched only by `register-in-index` (adding a link) and `adopt-AGENTS-draft`.
- The manifest is the only write outside the confirmed items.
