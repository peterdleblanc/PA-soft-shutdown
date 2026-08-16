# The `/github` Toolset

> Shared across every project bootstrapped from ClaudeTemplate. Identical fleet-wide,
> so `bootstrap.sh --sync-tooling` refreshes it — do not edit a project's copy. Edit
> `/github/ClaudeTemplate/.claude/TOOLSET.md` and re-sync.
>
> If this project is not part of the `/github` fleet, delete the `@` import from
> CLAUDE.md and this file with it.

This project's `.mcp.json` registers **toolset-mcp**, the live interface to Project
Command Center (`:10002`) and ProjectAssessment (`:5050`). Those services — not the
markdown in this repo — are the source of truth for ports, tasks and decisions
across the fleet.

**Prefer a tool call over guessing, and over reading a markdown file that describes
the same thing.** PCC is live; the markdown is a snapshot someone wrote once. Reads
are free and fast (~20ms).

- **Never pick a port by hand.** `find_free_port`, then `allocate_port` to claim it.
  This is the whole point of a shared registry — it is what stops two projects
  silently binding the same port. `PORT_REGISTRY.md` is the human-readable mirror,
  not the authority.
- **Identify the repo with `resolve_project`** and chain the id it returns into
  everything else. Identity is keyed on the `/github/...` **path**, not the name;
  names collide, paths can't.
- **Before re-litigating a design choice, `list_decisions`.** Cheapest possible way
  to avoid re-deciding something already settled.
- **Before proposing work, `list_tasks`** for what is already open.
- **`search` spans 9 entity types in one call** — projects, tasks, decisions,
  runbooks, prompts, skills, tools, commands. Follow up with `get_library_item` for
  a body. "List all runbooks" is a `search`.

**The caveat, so you don't over-trust it:** everything PCC reports is a snapshot of
its last **scan**, not a live view of the disk. If a tool's answer contradicts this
repo's own files, the tool is usually right — but a stale scan is the other
explanation, and `rescan_projects` / `rescan_ports` are the fix.

`run_assessment` and `run_brief` **spend Anthropic quota** and take minutes. Offer
them; never fire one as a side effect of another task.

## Agent orchestration (cmux)

**Only if `/github/cmux` exists on this machine** — check before relying on any of
this; the fleet tooling is local and a clone elsewhere will not have it.

cmux is the terminal multiplexer this fleet runs in. It can host Claude agents in
panes with a managed lifecycle, which is a different mechanism from `Agent`-tool
subagents and follows different rules.

- **Load the `cmux-orchestrate` skill before spawning anything.** It carries the
  judgement — whether to delegate at all (default: **no**), how to brief, monitor,
  and tear down.
- **Pane state is already reported.** `cmux-hook` is registered globally in
  `~/.claude/settings.json`, so this session's working/idle/blocked state reaches
  cmux without any per-project setup.
- **`cmux list-agents` lags the screen** and goes stale at `working`. It is a
  cross-check, never a trigger. Read the screen for ground truth.
