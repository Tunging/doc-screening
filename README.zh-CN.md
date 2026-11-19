# doc-screening（文档巡检）

> English | [中文](README.zh-CN.md)

> 一句话安装，一句话部署一套**两阶段 AI 文档管理工作流**到任何 Markdown 知识库或 `docs/` 目录：**只读初筛 → 人工确认 → 确认项执行**。

AI agent 产出文档很快——计划、审计报告、改写日志——它们总是堆在错误的位置。本仓库提供两个成对工作的 agent 技能：

| 技能 | 阶段 | 影响范围 |
|---|---|---|
| **doc-screening** | 提议：孤儿文档、过程产物残留、frontmatter/标签违规、重复、漂移、低质量 | 仅一份报告 |
| **doc-cleanup** | 执行：归档/更新/合并/登记索引/落盘规范——**只处理人工确认的条目** | 确认项 + 一份变更清单 |

**设计原则：agent 提议，人来拍板。** 初筛不碰任何内容文件；清理永不硬删（一律先进归档），未确认的条目一律拒绝执行。

## 安装（一句话）

```bash
curl -fsSL https://raw.githubusercontent.com/Tunging/doc-screening/main/install.sh | bash
```

- 随仓库分发、团队共享：加 `--project`
- 只装单个技能：加 `--only doc-screening`（或 `doc-cleanup`）
- 卸载：追加 `--uninstall`（装在项目里就再加 `--project`）

凡是能跑 `curl`（或 `wget`）且兼容 `~/.claude/skills/` 的 agent 都能用：**Claude Code** 原生扫描该目录；**omp（Oh-My-Pi）** 也会自动发现它（`enableClaudeUser` 默认开启）。脚本只写入 `~/.claude/skills/<技能>/SKILL.md`（`--project` 则写入 `./.claude/skills/<技能>/SKILL.md`）。

## 新项目四步走

技能装在 `~/.claude/skills/`（机器级），第 0 步**每台机器只做一次**——之后每个新项目从第 1 步开始，零准备。

**1. 首次初筛——摸清现状，拿到规范草案**

在新项目目录里起 Claude Code / omp 会话，贴「用法」一节的 Stage 1 话术。项目没有 `AGENTS.md` 时，本次按默认约定巡检，并在报告末尾附上**建议的 AGENTS.md 草案**。没有 `docs/` 目录的仓库也能自动适配：根目录 `.md` 文件加一级目录就是正式区。

**2. 落定规范（先于清理）**

```text
用 doc-cleanup 技能处理 _screening/screening-<日期>.md：确认 adopt-AGENTS-draft 这一条，把草案写入根目录 AGENTS.md。
```

```bash
ln -s AGENTS.md CLAUDE.md   # 一份规则，两个 agent 共用
```

想改约定（临时目录名、归档位置、白名单）？直接编辑 `AGENTS.md` 里的 override 键，之后所有巡检跟着走。

**3. 清理存量文档**

审阅报告，一句话确认要执行的条目（「用法」一节的 Stage 2 话术）。`delete` 是**移入** `_screening/trash-<日期>/`——不硬删，变更清单落在 `_screening/cleanup-<日期>.md`。让过程产物不进 git：

```bash
echo '_screening/' >> .gitignore
```

**4. 周期化（可选）**

随时重跑 Stage 1 那句话（已有 `AGENTS.md` 就不再附草案），或接定时调度——见「用法」一节的 Paseo 示例。每周节奏：看报告 → 回一句确认条目 → 拿回变更清单。

**团队共享**：要么每个队友自己跑安装命令（机器级），要么在仓库里跑一次 `install.sh --project`，让 `.claude/skills/` 随 git 分发——规范跟着仓库走。

## 用法（每个周期两句话）

在目标目录里起 Claude Code 或 omp 会话。

**Stage 1——初筛**（贴一句话）：

```text
用 doc-screening 技能对本目录做一次文档初筛：读根目录 AGENTS.md/CLAUDE.md 取约定（没有就用技能默认值，并在报告末尾附 AGENTS.md 草案），按技能步骤执行只读巡检，报告写入 _screening/screening-<今天日期>.md，除报告外不改动任何文件。
```

报告逐行列出发现：`文件 | 建议动作 | 触发规则 | 证据`，动作取值 `delete / archive / update / merge-to <目标> / register-in-index`，规则短名 `orphan · residue · frontmatter · tags · stale · duplicate · drift · low-quality`。项目没有 `AGENTS.md` 时，报告末尾还会附一份从本次发现综合出的**建议 AGENTS.md 草案**。

**Stage 2——清理**（审阅报告后，一句话点名确认的条目）：

```text
用 doc-cleanup 技能处理 _screening/screening-<日期>.md：确认 docs/b.md（登记索引）和 _audit.md（删除=归档）这两条，其他条目不动；执行后在 _screening/cleanup-<日期>.md 输出变更清单。
```

清理语义：`delete`/`archive` 是把文件**移入**归档目录（默认 `_screening/trash-YYYY-MM-DD/`）——永不硬删；`update` 只应用该行证据支持的修改；`merge-to <目标>` 追加源文件独有内容后归档源文件；`register-in-index` 补上缺失的索引链接；`adopt-AGENTS-draft` 把报告里的 AGENTS.md 草案写入仓库根目录。任何含糊之处都会跳过并注明原因，绝不即兴发挥。每项变更都记入变更清单。

周期化初筛可接入调度器——以 Paseo 为例：

```bash
paseo schedule create --provider claude --cron "0 9 * * 1" --cwd /path/to/repo \
  "按 doc-screening 技能做只读文档初筛，报告写 _screening/，不改其他文件，完成后摘要高优先级条目。"
```

## 按项目定制（可选，一个文件）

技能零配置可用。要固定你的约定，在根目录 `AGENTS.md` 里加 override：

```markdown
## Doc screening overrides

- _screening_dir: _巡检            # 报告所在的过程目录（默认 _screening/）
- _screening_formal_dirs: 01-核心技能, 02-进阶专题   # 正式文档根（默认：docs/ 或根目录布局）
- _screening_whitelist: 00-索引/README.md, 90-模板/周复盘模板.md   # 永不进入「建议删除」
- _screening_expiry_days: 30       # 报告清理线（默认 30 天）
```

完整带注释的示例见 [`AGENTS.example.md`](AGENTS.example.md)。doc-cleanup 额外读取 `_screening_archive_dir`（默认 `_screening/trash-YYYY-MM-DD/`）。

## 仓库结构

```
doc-screening/
├── skills/
│   ├── doc-screening/SKILL.md   # 阶段 1：只读初筛 playbook
│   └── doc-cleanup/SKILL.md     # 阶段 2：确认项执行 playbook
├── install.sh        # 一句话安装器（双技能，机器级/项目级）
├── AGENTS.example.md # 带注释的 override 模板
├── LICENSE           # MIT
├── README.md         # English
└── README.zh-CN.md   # 简体中文（本文件）
```

## 设计取舍

- **初筛只读，清理需确认。** 文档自动化最大的翻车方式是 agent 自信满满地"清理"真内容。阶段 1 的影响半径只有一份报告；阶段 2 只动人点名的条目、一律归档代替删除、全程记清单。
- **确定性优先，语义其次。** 链接/frontmatter/标签检查是机械的（便宜、误报少）；语义检查只抽样（≤20 篇）且必须引用证据。
- **注入约定，而非假设约定。** 同一对技能既服务 Unity Obsidian 知识库，也服务普通 `docs/` 仓库或裸目录——项目差异放在根 `AGENTS.md`；没有时，初筛用本次发现自举一份草案。

## License

MIT
