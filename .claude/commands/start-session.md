# Start Session

Load context and orient to the current state of the project before beginning work.

Usage: `/start-session`

---

## Instructions

You are starting a new session. Work through these steps in order before taking any action.

---

### Step 1 — Load primary context

Read `HANDOFF.md`. This is the single source of truth for current project state. It tells you:
- What branch and git state you're in
- What was completed last session
- What to do next

If `HANDOFF.md` does not exist, read `CLAUDE.md` and `README.md` instead and note that the project may not follow the 18-file framework yet.

---

### Step 2 — Check environment

Run these in parallel:
- `git status` — current branch, uncommitted changes
- `git log --oneline -5` — recent commit history
- `docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || true` — running services

---

### Step 3 — Reconcile HANDOFF.md with reality

Compare what HANDOFF.md says with what you found in Step 2:
- Does the branch match what HANDOFF.md says?
- Are there uncommitted changes HANDOFF.md didn't mention?
- Are the services HANDOFF.md expects actually running?

Note any discrepancies — they often indicate work-in-progress that needs attention.

---

### Step 4 — Display session summary

Print this block:

```
═══════════════════════════════════════════════════════
SESSION START — {date}
═══════════════════════════════════════════════════════

Project:  {project name from CLAUDE.md or directory name}
Branch:   {current branch}
Status:   {clean | uncommitted changes | discrepancy with HANDOFF}

Last session:
  {3–5 bullets from HANDOFF.md "Completed This Session"}

Next up:
  {items from HANDOFF.md "Next Session — Start Here"}

Services:
  {running containers, or "none detected"}

Notes:
  {any discrepancies found in Step 3, or "None"}
═══════════════════════════════════════════════════════
```

---

### Step 5 — Ask

Ask: **"What would you like to work on this session?"**

Do not suggest tasks or volunteer to start work. Wait for direction from the user.
