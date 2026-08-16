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

### Step 2B — Ask the live services

HANDOFF.md is a file someone updated by hand at the end of a session; the
services below are live. When they disagree, that disagreement is usually the
most useful thing you will learn all session — a HANDOFF that missed a session
looks exactly like a HANDOFF that is current.

In parallel:

- `resolve_project` with this repo's absolute path (`pwd`) — keep the id.
- `list_tasks` with that `project_id` and `status: "todo"` — what the tracker
  thinks is open. PCC builds these from `ROADMAP.md` checkboxes, so a ticket
  still open for work that shipped means the roadmap was never ticked.
- `latest_assessment` with the same path — the last published doc/code/db
  scores, **with their dates**. Do not present a stale report as current;
  compare its timestamp against `git log` before quoting a score.

Keep this to reads. Do not create, complete or re-assess anything at session
start — you do not yet know what the user wants.

If toolset-mcp is unavailable, print `PCC/ProjectAssessment unreachable` in the
Notes line and carry on. Everything else in this command works offline.

---

### Step 3 — Reconcile HANDOFF.md with reality

Compare what HANDOFF.md says with what you found in Steps 2 and 2B:
- Does the branch match what HANDOFF.md says?
- Are there uncommitted changes HANDOFF.md didn't mention?
- **Are there commits after HANDOFF.md's "Last Updated" date?** That is the
  signal that a session ended without updating it, and it is easy to miss
  because the file still reads as authoritative.
- Are the services HANDOFF.md expects actually running?
- Do PCC's open tickets match what HANDOFF.md calls "next up"?

Note any discrepancies — they often indicate work-in-progress that needs
attention.

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

Tracker:
  {N open PCC tickets — list the 3 most relevant, or "PCC unreachable"}
  {latest assessment: doc/code/db scores + date, or "never assessed"}

Notes:
  {any discrepancies found in Step 3, or "None"}
═══════════════════════════════════════════════════════
```

If this session is running inside a **cmux** pane and other agents are live,
say so in one line — a grid you did not spawn is context, not decoration. Read
the screen rather than `cmux list-agents`, which lags. Skip silently if
`/github/cmux` is absent.

---

### Step 5 — Ask

Ask: **"What would you like to work on this session?"**

Do not suggest tasks or volunteer to start work. Wait for direction from the user.
