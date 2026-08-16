---
name: cmux-orchestrate
description: Run a team of Claude agents in cmux panes — decide whether to delegate at all, pick between leading from this pane and spawning a dedicated lead, decompose the work, monitor and unblock workers, integrate their output, and tear them down. Use when the user asks to delegate, parallelize, spawn agents or workers, run a lead, or hand a job to the grid. Also read it before spawning anything with cmux-agent.
version: 1.0.0
---

# Orchestrating agents in cmux panes

> Distributed by ClaudeTemplate and refreshed by `bootstrap.sh --sync-tooling` —
> edit it in `/github/ClaudeTemplate/.claude/skills/`, not in a project's copy.
> `/github/cmux` keeps its own richer version, which this one is generalized from;
> the sync deliberately refuses to overwrite it.

## Before anything: is cmux even here?

```bash
[ -d /github/cmux ] && echo yes
```

If it is not, **say so in one sentence and do the work directly in this session.**
This whole skill assumes the fleet-local cmux install; nothing below degrades
gracefully without it.

**These are cmux panes, not `Agent` tool subagents.** Different mechanisms,
different rules. A standing instruction against spawning subagents is about the
`Agent` tool and does not govern this — but it does set the disposition, so
**step 0 stands.**

---

## Step 0 — Should this be delegated at all?

Default: **no.** Do it yourself in this session. Delegation is worth it only when
the work is genuinely parallel and each part is large enough to survive being
handed off cold.

Delegate when **all** of these hold:

- The task splits into **2–3 parts that do not need each other's output.** One
  part that must wait on another is a sequence, and a sequence is faster here.
- Each part is **big enough to be worth a pane** — roughly, more than a handful of
  tool calls. Spawning costs a pane, a briefing, and your attention.
- Each part has a **verifiable done condition** you can state in the prompt. A
  worker with weak success criteria produces work you then have to redo.

Do **not** delegate when:

- The work is mostly reading and deciding — that is cheaper in one head.
- The parts share a file. Two workers editing one file is a merge you will own.
- You could finish it in the time the briefing would take.

If you decide not to delegate, say so in a sentence and get on with the work.

---

## Step 1 — Pick a path

Two shapes, and the choice is about **whose context matters**. `$PROJECT` below is
this project's absolute path — the repo you are working in, not cmux's own.

### A. Lead from this pane

You keep your own context and run workers directly. Workers land in `agent-1`
through `agent-4`, so there is room for **four**.

```bash
/github/cmux/scripts/cmux-agent spawn --cwd "$PWD" 'prompt with a done condition'
/github/cmux/scripts/cmux-agent list
```

Choose this when **you already hold the context** — you have read the code, made
the decisions, and the workers just need well-specified jobs. This is the common
case in a working session, and it is the cheaper one.

### B. Spawn a dedicated lead

```bash
/github/cmux/scripts/cmux-agent spawn --lead --cwd "$PWD" 'delegate this and report back'
```

The lead takes `agent-1`'s cell and starts **clean** rather than forked, so the
tool caps it at **three** workers (`agent-2..4`) — it holds a slot itself.

Choose this when the job is **self-contained and long**, and the value to the user
is having *one pane to read* instead of four. The lead owns spawning, monitoring,
unblocking, integrating and teardown.

**The trade to state plainly:** a dedicated lead starts with no context, so
everything it needs must be in the prompt. Its advantage is that it costs you
nothing to run — you are not the one watching four panes.

### Never use `--fork` unless asked

A forked spawn replays the caller's whole conversation at full price. It is opt-in
for that reason, and a lead never uses it. Fork only when the worker genuinely
needs the conversation's history, not merely its conclusions — and prefer putting
the conclusions in the prompt.

### Two things that will bite on a first spawn

- **`cmux-agent list` can refuse while `spawn` works fine.** The slot registry is
  screen-scoped, so `list` reports "recorded on screen N, not this one" and exits
  non-zero. That is **not** evidence that spawning will fail — `spawn --dry-run`
  from the same shell is the cheap way to find out.
- **Spawning into a repo Claude Code has not trusted parks the agent on a trust
  dialog** — *"Is this a project you created or one you trust?"* — **even under
  `bypassPermissions`**, which does not cover it. Expect it on the first spawn
  into any new repo. The agent will sit there having done nothing.

---

## Step 2 — Decompose

Write each worker's prompt so it could be judged by someone who was not in this
conversation, because the worker was not.

- **State the done condition.** "Add tests for the parser's error paths until
  `sh scripts/test.sh` passes with the new tests named" beats "add some tests".
- **Name the files.** A worker that has to find them re-derives what you know.
- **Say what not to touch.** In particular `scripts/test.sh` and
  `.claude/commands/*` are fleet-shared and refreshed by
  `bootstrap.sh --sync-tooling`; editing them locally is work that will be
  silently overwritten. And the working tree is shared between all panes — two
  workers in one file will conflict.
- **Pass `--cwd`.** A pane's shell starts in `$HOME`, so without it the agent
  loads the wrong `CLAUDE.md` and works from the wrong project's rules.

---

## Step 3 — Monitor

**Read the screen. Do not trust `cmux list-agents`.**

`list-agents` **lags the screen** and goes stale at `working` — it has reported
`working` while a permission dialog was already up, and stayed `working` after a
worker had finished. Cross-check, never a trigger.

```bash
# 10000ms is a HARD CEILING -- a larger value fails rather than waiting longer.
# Loop it in <=10s slices.
cmux wait-for --surface <SID> --pattern 'Tab to amend|Do you want|Would you like' \
              --timeout-ms 10000
cmux read-screen --surface <SID>          # the fallback, and the ground truth
```

`wait-for` matches **visible screen text**, which includes the command you just
typed — pick a pattern that cannot appear in the command, or the wait is a no-op.
Exit codes: **0** seen, **1** timeout, **3** transport error.

**A monitor that greps a pane re-matches your own instructions.** A real one
reported all four slots busy because its `grep -oE 'agent-[0-9]'` matched the
`free slots:` line, and reported a ticket closed because it matched the literal
tool name *in the brief on screen*. Both were false and both looked like success.
Key on ground truth — `^agent-N +pane=` for occupancy, `git rev-list` for commits,
the tracker itself for ticket state — and never assert an outcome the agent was
merely *told* to produce.

### Unblocking

```bash
cmux send-key --surface <SID> enter      # takes the preselected "1. Yes"
```

**Answering a worker's permission prompt is answering it on the user's behalf.**
Do it only for work you would be allowed to do yourself. If a worker is stopped on
something this session would refuse, leave it stopped and tell the user.

### Messaging

Address workers **by name**, not surface id. Cross-session `SendMessage` needs the
peer's `[ref]` from `ListAgents`, which changes every spawn — read it immediately
before sending. A send returning `success: true` means *accepted*, not
*delivered*: it is held for approval whenever two sessions' permission modes
differ. Keep `--permission-mode` as `cmux-agent` sets it and the gate does not
appear.

Keep the message graph flat — a worker may talk to another worker directly. You
own responsibility, not routing.

---

## Step 4 — Integrate and verify

**Read what a worker produced before believing its report.** A worker claiming a
suite passes is not the suite passing. This is not a hypothetical: in one recorded
run, 8 of 13 worker findings were re-probed at source — **one did not reproduce
and two changed shape.**

```bash
sh scripts/test.sh                 # the project's own gate
```

Report faithfully to the user: what landed, what did not, and what you skipped.

---

## Step 4b — Write the run down before you tear it down

A lead's report exists only on its pane. Closing the pane destroys the only record
of what the team found; leaving it open holds a slot. Neither is a home for it.
Append an entry to **`AGENT_RUNS.md`** at the repo root, using the template in that
file.

The three fields people skip are the ones worth the most: **which findings were
re-checked at source** versus taken from a worker's word, **what was not looked
at** (a run reporting "no problems" without saying what it read is
indistinguishable from a run that read nothing), and **how the run behaved** —
that is how the delegation tooling earns or loses trust.

---

## Step 5 — Tear down

Always. A pane left open holds a slot and keeps rendering as a live agent.

```bash
/github/cmux/scripts/cmux-agent close --workers        # agent-2..4; never agent-1
/github/cmux/scripts/cmux-agent close --all            # all four cells
/github/cmux/scripts/cmux-agent close agent-2 --dry-run
```

`close` reads state **off the screen** and refuses a working or blocked pane
(exit **1**; `--dry-run` returns the same 1, so you can test without touching the
pane). **A refusal means that worker is not finished** — deal with it and re-run.
Reaching for `--force` loses whatever it was doing.

`--workers` never includes `agent-1`, so a lead can run it from its own pane
without closing itself. A lead leaves its own cell to the user.

---

## Failure modes worth knowing before they happen

- **`cmux send --text` does not submit to a Claude TUI.** A trailing `\n` leaves
  the text sitting unsent, which looks exactly like a delivered prompt being
  ignored. Send the text, then send `$'\r'` as a **separate** call.
- **Text sitting unsent in a pane is usually Claude Code's own prompt suggestion**,
  not something a human typed. It renders only on an *idle* pane and cannot be
  cleared with keys.
- **Blocked and idle are indistinguishable in the tab strip** — both render `✳`.
  The `•` is *unseen output*, not a blocked marker, and focusing the pane clears it
  permanently even while the agent stays blocked.
- **A surface id is not stable across a cmux restart.** If reports vanish,
  re-resolve rather than trusting a cached id.
- **`pkill -f` / `pgrep -f` on a probe name matches its own shell.** The Bash
  tool's own `zsh -c …` line contains your pattern, so `pgrep` reports a dead
  process as still running — it does not error, it lies. Filter the shell out
  (`pgrep -af cmux-tui | grep -v 'zsh -c'`) or match the binary.
- **The grid is shared.** Every pane works in the same working tree.
- **Quota is the real ceiling, not slots.** Four panes each burn their own budget;
  check the status line before committing to a large team.

## Reference

`/github/cmux` holds the depth: `REFERENCE.md` for exact flags, key names and the
event table; `DECISIONS.md` for why the grid works the way it does; and
`scripts/cmux-agent` itself for `LEAD_IDENTITY` — the briefing a spawned lead
actually receives, which you do not need to duplicate in a prompt.
