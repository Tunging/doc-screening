# doc-screening

> One-sentence install; one sentence to deploy a **two-stage AI documentation workflow** into any Markdown knowledge base or `docs/` tree: **read-only screening → human confirms → confirmed cleanup**.

AI agents produce documents fast — plans, audits, reports, rewrite logs — and they accumulate in the wrong places. This repo ships two agent skills that work as a pair:

| Skill | Stage | Blast radius |
|---|---|---|
| **doc-screening** | propose: orphans, transient residue, frontmatter/tag violations, duplicates, drift, low quality | one report file |
| **doc-cleanup** | dispose: archive/update/merge/register/adopt-rules — **only rows a human confirmed** | confirmed items + one manifest |

**Design rule: agents propose, humans decide.** Screening never touches content files; cleanup never hard-deletes (archive-first) and refuses anything not explicitly confirmed.

## Install (one sentence)

```bash
curl -fsSL https://raw.githubusercontent.com/Tunging/doc-screening/main/install.sh | bash
```

- Team-shared, versioned with the repo: add `--project`
- Single skill: add `--only doc-screening` (or `doc-cleanup`)
- Remove: append `--uninstall` (plus `--project` if installed that way)

Works anywhere `curl` (or `wget`) and a `~/.claude/skills/`-compatible agent live: **Claude Code** scans that dir natively; **omp (Oh-My-Pi)** auto-discovers it too (`enableClaudeUser` defaults to true). The script writes only `~/.claude/skills/<skill>/SKILL.md` files (or `./.claude/skills/<skill>/SKILL.md` with `--project`).

## New project in four steps

Skills live in `~/.claude/skills/` (machine-wide), so step 0 happens **once per machine** — every new project then starts at step 1 with zero setup.

**1. First screening — discover the current state, get a rules draft**

Open a Claude Code / omp session in the new project and paste the stage-1 prompt from [Use it](#use-it-two-sentences-per-cycle). With no `AGENTS.md` the run uses defaults and appends a **suggested AGENTS.md draft** to the report. A repo without a `docs/` tree is handled automatically: root `.md` files plus first-level dirs become the formal corpus.

**2. Lock in conventions (do this before cleaning)**

```text
用 doc-cleanup 技能处理 _screening/screening-<日期>.md：确认 adopt-AGENTS-draft 这一条，把草案写入根目录 AGENTS.md。
```

```bash
ln -s AGENTS.md CLAUDE.md   # one rules file shared by both agents
```

Want different conventions (transient dir name, archive location, whitelist)? Edit the override keys in `AGENTS.md` — every later run follows them.

**3. Clean up the existing docs**

Review the report, then confirm rows in one sentence (the stage-2 prompt in [Use it](#use-it-two-sentences-per-cycle)). `delete` means **move** into `_screening/trash-<date>/` — nothing is hard-deleted, and the manifest lands in `_screening/cleanup-<date>.md`. Keep transient output out of git:

```bash
echo '_screening/' >> .gitignore
```

**4. Make it recurring (optional)**

Re-run the stage-1 sentence any time (with `AGENTS.md` present it skips the draft), or schedule it — see the Paseo example in [Use it](#use-it-two-sentences-per-cycle). Weekly rhythm: read the report → reply confirming rows → manifest comes back.

**Team sharing**: either each teammate runs the install command (machine scope), or run `install.sh --project` once in the repo so `.claude/skills/` ships with git — conventions then travel with the repository.

## Use it (two sentences per cycle)

Start a Claude Code or omp session in the target directory.

**Stage 1 — screening** (paste one sentence):

```text
用 doc-screening 技能对本目录做一次文档初筛：读根目录 AGENTS.md/CLAUDE.md 取约定（没有就用技能默认值，并在报告末尾附 AGENTS.md 草案），按技能步骤执行只读巡检，报告写入 _screening/screening-<今天日期>.md，除报告外不改动任何文件。
```

The report lists findings as rows: `File | Suggested action | Rule | Evidence`, with actions `delete / archive / update / merge-to <target> / register-in-index` and rules `orphan · residue · frontmatter · tags · stale · duplicate · drift · low-quality`. If the project has no `AGENTS.md`, the report also ends with a **suggested AGENTS.md draft** synthesized from this run's findings.

English:

```text
Run the doc-screening skill on this directory: read AGENTS.md/CLAUDE.md for conventions (fall back to defaults and append an AGENTS.md draft to the report if absent), do a read-only screening per the skill, write the report to _screening/screening-<today>.md, and change nothing else.
```

**Stage 2 — cleanup** (you review the report, then paste one sentence naming the confirmed items):

```text
用 doc-cleanup 技能处理 _screening/screening-<日期>.md：确认 docs/b.md（登记索引）和 _audit.md（删除=归档）这两条，其他条目不动；执行后在 _screening/cleanup-<日期>.md 输出变更清单。
```

English:

```text
Run the doc-cleanup skill on _screening/screening-<date>.md: I confirm the docs/b.md (register-in-index) and _audit.md (archive) rows; leave everything else untouched; write the change manifest to _screening/cleanup-<date>.md.
```

Cleanup semantics: `delete`/`archive` **move** files into an archive dir (default `_screening/trash-YYYY-MM-DD/`) — never hard-delete; `update` applies only the evidence-backed edits from the row; `merge-to <target>` appends unique content then archives the source; `register-in-index` adds the missing link; `adopt-AGENTS-draft` writes the report's AGENTS.md draft to the repo root. Anything ambiguous is skipped with a reason, never improvised. Every change lands in a manifest.

For recurring screening, wire the stage-1 prompt into your scheduler — e.g. Paseo:

```bash
paseo schedule create --provider claude --cron "0 9 * * 1" --cwd /path/to/repo \
  "Run the doc-screening skill: read-only screening, report to _screening/screening-<today>.md, change nothing else."
```

## Adapt it to your project (optional, one file)

The skills work zero-config. To pin your conventions, add overrides to the root `AGENTS.md`:

```markdown
## Doc screening overrides

- _screening_dir: _巡检            # transient dir for reports (default _screening/)
- _screening_formal_dirs: 01-核心技能, 02-进阶专题   # formal roots (default: docs/ or root layout)
- _screening_whitelist: 00-索引/README.md, 90-模板/周复盘模板.md   # never "suggest delete"
- _screening_expiry_days: 30       # report cleanup line (default 30)
```

See [`AGENTS.example.md`](AGENTS.example.md) for a complete annotated example. Cleanup additionally reads `_screening_archive_dir` (default `_screening/trash-YYYY-MM-DD/`).

## Repo layout

```
doc-screening/
├── skills/
│   ├── doc-screening/SKILL.md   # stage 1: read-only screening playbook
│   └── doc-cleanup/SKILL.md     # stage 2: confirmed-item execution playbook
├── install.sh        # one-sentence installer (both skills, user or project scope)
├── AGENTS.example.md # annotated override file template
├── LICENSE           # MIT
└── README.md
```

## Design notes

- **Read-only screening, confirmation-gated cleanup.** The #1 failure mode of doc automation is an agent confidently "cleaning up" real content. Stage 1's blast radius is one report; stage 2 acts only on rows a human named, archives instead of deleting, and logs a manifest.
- **Deterministic first, semantic second.** Link/frontmatter/tag checks are mechanical (cheap, few false positives); semantic checks are sampled (≤20 files) and require cited evidence.
- **Convention injection, not convention assumption.** The same pair serves a Unity Obsidian vault, a plain `docs/` repo, or a bare directory — root `AGENTS.md` carries project specifics; when absent, screening bootstraps a draft from its own findings.

## License

MIT
