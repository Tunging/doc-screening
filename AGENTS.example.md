# AGENTS.md — doc-screening overrides (annotated example)
#
# Copy the relevant block into your repo's root AGENTS.md (create the file if needed).
# The doc-screening skill reads this file and overrides its defaults.
# Everything here is optional — the skill works with zero configuration.
#
# Claude Code reads CLAUDE.md; common practice is a symlink so both agents share one file:
#   ln -s AGENTS.md CLAUDE.md

## Doc screening overrides

# Transient dir where screening reports are written (default: _screening/)
# Reports are named screening-YYYY-MM-DD.md; add this dir to .gitignore if you
# don't want reports versioned.
- _screening_dir: _巡检

# Formal documentation roots to screen (default: docs/ if it exists, else the
# root's .md files plus all first-level dirs)
- _screening_formal_dirs: docs, guides, wiki

# Files that must NEVER appear under "suggest delete" (in addition to the
# built-in whitelist: index/README/AGENTS/CLAUDE files)
- _screening_whitelist: 00-索引/README.md, 90-模板/周复盘模板.md, 00-索引/写作风格规范.md

# Days after which old reports in the transient dir become "suggest cleanup"
# (default: 30). Cleanup still requires human confirmation.
- _screening_expiry_days: 30

## (Optional) writing rules the screening will check against

# 1. Transient agent artifacts (plans, audits, logs) go ONLY into the transient dir.
# 2. Before creating a formal doc, search for an existing one to update instead.
# 3. Frontmatter follows the templates in 90-模板/; tags come from the controlled
#    vocabulary in 00-索引/标签体系.md.
# 4. Outdated content moves to an archive dir, never hard-deleted.
