# doc-screening

> One-sentence install; one sentence to deploy a **read-only AI documentation screening workflow** into any Markdown knowledge base or `docs/` tree.

AI agents produce documents fast — plans, audits, reports, rewrite logs — and they accumulate in the wrong places. This skill gives any agent (Claude Code, Oh-My-Pi/omp, or anything that reads agent skills) a repeatable screening playbook:

- **orphan docs** — never linked from any index
- **transient residue** — audit/report/log files polluting root or formal dirs
- **frontmatter / tag violations** — against your template or controlled vocabulary
- **duplicates, drift, low quality** — semantic sampling with cited evidence

**Hard rule: the agent never edits, moves, or deletes anything.** The only write is one report into a transient dir. Humans decide; agents propose.

## Install (one sentence)

```bash
curl -fsSL https://raw.githubusercontent.com/Tunging/doc-screening/main/install.sh | bash
```

- Team-shared, versioned with the repo: add `--project`
- Remove: append `--uninstall` (plus `--project` if installed that way)

Works anywhere `curl` (or `wget`) and a `~/.claude/skills/`-compatible agent live: **Claude Code** scans that dir natively; **omp (Oh-My-Pi)** auto-discovers it too (`enableClaudeUser` defaults to true — no omp-specific install needed). The script only writes one file: `~/.claude/skills/doc-screening/SKILL.md` (or `./.claude/skills/doc-screening/SKILL.md` with `--project`).

## Deploy in a specific working directory (give this to the agent)

After installing, start a Claude Code or omp session in the target directory and paste **one sentence**:

```text
用 doc-screening 技能对本目录做一次文档初筛：读根目录 AGENTS.md/CLAUDE.md 取约定（没有就用技能默认值），按技能步骤执行只读巡检，报告写入 _screening/screening-<今天日期>.md，除报告外不改动任何文件。
```

English:

```text
Run the doc-screening skill on this directory: read AGENTS.md/CLAUDE.md for conventions (fall back to the skill's defaults if absent), do a read-only screening per the skill, write the report to _screening/screening-<today>.md, and change nothing else.
```

The agent loads the skill, screens, and writes one report. For recurring runs, wire the same prompt into your scheduler of choice — e.g. Paseo:

```bash
paseo schedule create --provider claude --cron "0 9 * * 1" --cwd /path/to/repo \
  "Run the doc-screening skill: read-only screening, report to _screening/screening-<today>.md, change nothing else."
```

## Adapt it to your project (optional, one file)

The skill works zero-config. To give it your conventions, add overrides to the root `AGENTS.md`:

```markdown
## Doc screening overrides

- _screening_dir: _巡检            # transient dir for reports (default _screening/)
- _screening_formal_dirs: 01-核心技能, 02-进阶专题   # formal roots (default: docs/ or root layout)
- _screening_whitelist: 00-索引/README.md, 90-模板/周复盘模板.md   # never "suggest delete"
- _screening_expiry_days: 30       # report cleanup line (default 30)
```

See [`AGENTS.example.md`](AGENTS.example.md) for a complete annotated example. Without this file the agent notes "defaults used" in the report header.

## The report

| Field | Meaning |
|---|---|
| Suggested action | `delete / archive / update / merge-to <target> / register-in-index` |
| Rule | `orphan · residue · frontmatter · tags · stale · duplicate · drift · low-quality` |
| Evidence | file + line/quote — semantic claims must cite; uncertain items get ⚠️ and drop to medium priority |

Priorities: **High** (this week) / **Medium** / statistics line. Stale reports past the expiry line are listed as "suggest cleanup" and only executed after human confirmation.

## Repo layout

```
doc-screening/
├── SKILL.md          # the agent-playbook (the whole workflow lives here)
├── install.sh        # one-sentence installer (user or project scope)
├── AGENTS.example.md # annotated override file template
├── LICENSE           # MIT
└── README.md
```

## Design notes

- **Read-only by default.** The #1 failure mode of doc automation is an agent confidently "cleaning up" real content. This workflow's blast radius is one report file.
- **Deterministic first, semantic second.** Link/-frontmatter/tag checks are mechanical (cheap, no false "AI vibes"); semantic checks are sampled (≤20 files) and require evidence.
- **Convention injection, not convention assumption.** The same skill serves a Unity Obsidian vault, a plain `docs/` repo, or a bare directory — the root `AGENTS.md` carries project specifics; the skill carries the procedure.

## License

MIT
