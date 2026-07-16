# Doc Health

Audit which of the 18 framework files are present and flag anything missing or stale.

Usage: `/doc-health`

---

## Instructions

Check the health of the documentation framework for the current project. No changes are made without user confirmation.

---

### Step 1 — Check file presence

Run this to check all 18 framework files at once:

```bash
for f in CLAUDE.md HANDOFF.md HANDOFF_HISTORY.md DECISIONS.md ROADMAP.md DATABASE.md FEATURES.md CHANGELOG.md README.md USERGUIDE.md DEPLOYMENT.md TESTING.md PORT_REGISTRY.md GIT_WORKFLOW.md DEV_ENVIRONMENT.md SECURITY.md CODESTYLE.md CI_CD.md RELEASE.md; do
  [ -f "$f" ] && echo "PRESENT $f" || echo "MISSING $f"
done
```

---

### Step 2 — Check last-modified dates

For each present file, get the date it was last touched in git:

```bash
for f in CLAUDE.md HANDOFF.md HANDOFF_HISTORY.md DECISIONS.md ROADMAP.md DATABASE.md FEATURES.md CHANGELOG.md README.md USERGUIDE.md DEPLOYMENT.md TESTING.md PORT_REGISTRY.md GIT_WORKFLOW.md DEV_ENVIRONMENT.md SECURITY.md CODESTYLE.md CI_CD.md RELEASE.md; do
  [ -f "$f" ] && echo "$f: $(git log -1 --format="%as" -- "$f" 2>/dev/null || echo "untracked")"
done
```

---

### Step 3 — Check HANDOFF.md freshness

Read `HANDOFF.md` (if present). Extract the "Last Updated" date. If it is more than 7 days ago, mark it as stale — HANDOFF.md should be updated every session.

---

### Step 4 — Check slash commands

Check whether `.claude/commands/` exists and contains the framework commands:

```bash
for cmd in complete-task.md start-session.md end-session.md new-feature.md add-decision.md new-release.md add-port.md schema-change.md doc-health.md; do
  [ -f ".claude/commands/$cmd" ] && echo "PRESENT $cmd" || echo "MISSING $cmd"
done
```

---

### Step 5 — Display health report

Print this block, filling in real values from the steps above:

```
═══════════════════════════════════════════════════════
DOC HEALTH — [project name] — [today's date]
═══════════════════════════════════════════════════════

Framework Files (18):
  ✓  CLAUDE.md              last updated [date]
  ✓  HANDOFF.md             last updated [date]  [⚠ STALE — last updated [date]] if >7 days
  ✓  HANDOFF_HISTORY.md     last updated [date]
  ...
  ✗  [MISSING FILE]         NOT FOUND

Score: [N]/18 files present

Slash Commands:
  ✓  complete-task.md
  ✓  start-session.md
  ✗  [missing-command].md   NOT FOUND

Issues:
  [list each missing file or stale HANDOFF.md]
  — or —
  None — framework is fully in place.
═══════════════════════════════════════════════════════
```

---

### Step 6 — Offer to fix missing files

If any framework files are missing, ask:
"Would you like me to copy the missing template files from /github/ClaudeTemplate now?"

If yes, for each missing file run:
```bash
cp /github/ClaudeTemplate/[missing-file].md ./[missing-file].md
```

Then report which files were copied.

If any slash commands are missing, ask:
"Would you like me to copy the missing commands from /github/ClaudeTemplate/.claude/commands/ now?"

If yes, for each missing command run:
```bash
mkdir -p .claude/commands
cp /github/ClaudeTemplate/.claude/commands/[missing-command].md ./.claude/commands/[missing-command].md
```
