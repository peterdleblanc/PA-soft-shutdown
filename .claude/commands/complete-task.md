# Complete Task

Wraps up a completed task: updates all relevant documentation, commits, pushes, and clears context.

Usage: `/complete-task <description of what was completed>`

---

## Instructions

You have just completed a task. The task description is: **$ARGUMENTS**

Work through the following steps in order. Do not skip steps — each one is a gate before committing.

---

### Step 0 — Initialize diagnostic logging

**Mandatory.** Push failures in this workflow have been misdiagnosed in past sessions as "GitHub is down" when the real cause is local (credential-helper / keyring timing). Logging is the fix: every shell command in the rest of this task is captured to a timestamped file so the actual error stays visible.

Run this **first**:

```bash
mkdir -p ~/.claude/logs
LOG="$HOME/.claude/logs/complete-task-$(date +%Y%m%d-%H%M%S).log"
{
  echo "=== /complete-task starting at $(date -Iseconds) ==="
  echo "PWD: $(pwd)"
  echo "TASK: $ARGUMENTS"
  echo "USER: $(whoami)"
  echo "GIT: $(git --version)"
  echo "GH:  $(gh --version 2>/dev/null | head -1)"
  echo ""
} > "$LOG"
echo "LOG_PATH=$LOG"
```

**Capture the printed `LOG_PATH` value.** From this point on, every subsequent Bash call in this task must pipe its output through `tee -a <LOG_PATH>` using the literal path string.

**Two harness traps to remember:**

1. **Shell variables don't persist between Bash calls** in this harness — reference `<LOG_PATH>` literally, not as `$LOG`.
2. **Exit codes after an outer `| tee` capture tee's exit, not the inner command's.** Same for `${PIPESTATUS[*]}` — it gets reset by the outer pipe. Always capture exit codes into a named variable *inside* the inner `{ … }` block before the outer pipe:
   ```bash
   { some_command; RC=$?; echo "rc=$RC"; } 2>&1 | tee -a <LOG_PATH>
   ```

Print the log path to the user at the start and again at the end of the task so they can share it if needed.

---

### Step 1 — Understand what changed

Run these and tee each one to the log (substitute `<LOG_PATH>` with the value from Step 0):

```bash
{
  echo ""
  echo "=== STEP 1: git state at $(date -Iseconds) ==="
  echo "--- git status ---"
  git status
  echo ""
  echo "--- git diff (summary) ---"
  git diff --stat
  echo ""
  echo "--- git diff (full) ---"
  git diff
  echo ""
  echo "--- git log --oneline -5 ---"
  git log --oneline -5
  echo ""
  echo "--- VERSION (if tracked) ---"
  cat VERSION 2>/dev/null || echo "(no VERSION file)"
} 2>&1 | tee -a <LOG_PATH>
```

Read the output carefully. You need to know: what changed, what type of change it is (feature / fix / docs / chore / refactor), and whether it touches any compliance-relevant areas (auth, audit, ITAR, approval workflows).

---

### Step 1B — Testing gate (features only)

If the task type is a **feature** (new user-facing functionality), verify the two-layer testing requirement before proceeding. Skip this step for `chore`, `docs`, `refactor`, or `fix` tasks with no new logic.

**Check 1 — Unit tests exist for the feature:**

Look through the changed files. For each new module, service, or store introduced, verify a corresponding test file exists:
- Rust: `#[cfg(test)]` block in the file, or `backend/tests/[feature].rs`
- Python: `processor/tests/test_[feature].py`
- TypeScript/Svelte: `[feature].test.ts` alongside the module

If no unit tests exist for new logic, stop and tell the user:
```
✗ TESTING GATE FAILED
  Unit tests are missing for: [list the new files with no test coverage]
  Write unit tests before completing this task.
  See TESTING.md for guidance.
```

Do not proceed until the user addresses this.

**Check 2 — Playwright spec exists for the feature:**

Check for a Playwright spec file covering the feature's primary user flow:
- Look in `frontend/tests/e2e/specs/` or `tests/e2e/specs/` for a `.spec.ts` file related to this feature
- The spec must exist and contain at least one test for the happy path

If no Playwright spec exists, stop and tell the user:
```
✗ TESTING GATE FAILED
  No Playwright E2E spec found for this feature.
  Write a Playwright spec covering the primary user flow before completing this task.
  See TESTING.md for guidance.
```

Do not proceed until the user addresses this.

**Check 3 — Run tests and verify they pass:**

```bash
# Run whatever test layers exist in this project
cd frontend && npm run test -- --run 2>/dev/null | tail -5 || true
cd frontend && npx playwright test --reporter=line 2>/dev/null | tail -10 || true
cd backend && cargo test --lib 2>/dev/null | tail -5 || true
```

If any failures are found, stop and show the failing tests. Do not commit failing tests.

If all checks pass, print:
```
✓ TESTING GATE PASSED — unit tests present, Playwright spec present, all passing
```

Then continue to Step 2.

---

### Step 2 — Archive to HANDOFF_HISTORY.md

Read `HANDOFF_HISTORY.md`. Prepend a new entry at the top (below the file header, above any previous entries) using this format:

```
## YYYY-MM-DD — [one-line summary of what this session accomplished]

**Completed:**
- [what was built, fixed, or shipped — one bullet per distinct item]

**Key decisions:**
- [any notable choices made — or "None" if routine work]

**Commits:** `[SHA]` [message]

---
```

Use today's date. Pull the commit SHA from Step 1's git log output.

---

### Step 3 — Update HANDOFF.md

Read `HANDOFF.md`. Make two changes:

1. Update **"Completed This Session"** to reflect today's task — replace or update the section with a brief summary. Keep it to 3–5 bullets max.
2. Remove this task from **"Next Session — Start Here"** if it appears there.

Do not rewrite the whole file. Surgical edits only. Target: 60–80 lines total.

---

### Step 4 — Update ROADMAP.md (if applicable)

Read `ROADMAP.md`. If the completed task corresponds to a phase item or checkbox, mark it done. If it completes an entire phase, update the project status header.

Skip this step if the task has no roadmap entry.

---

### Step 5 — Update FEATURES.md (if applicable)

Read `FEATURES.md`. If the task adds or changes a user-facing feature:
- Update the feature's status field
- Update the last-modified date
- Add a note if the implementation changed from the original spec

Skip this step if the task is infrastructure, docs, or a bug fix with no user-visible change.

---

### Step 6 — Update CHANGELOG.md (if applicable)

Read `CHANGELOG.md`. Add an entry under `## [Unreleased]` if the task is:
- A new feature → `### Added`
- A changed behavior → `### Changed`
- A bug fix → `### Fixed`

Format: `- **Short title** — one sentence describing the change and its impact`

Skip this step for internal refactors, documentation-only changes, or chores with no user impact.

---

### Step 7 — Confirm branch and commit scope

Show the user:

```
Files to be committed:
[list from git status]

Branch: [current branch]
Commit type: [feat / fix / docs / chore / refactor]
Files updated this step: [list of doc files you changed]

Confirm? (or specify a different branch)
```

Wait for confirmation before proceeding.

---

### Step 8 — Commit and push (with full tracing)

This step is the one that has been failing. **Run every sub-step inside a tee block so the trace lands in the log.** Do not summarize or interpret errors — pass them through verbatim.

**8a — Pre-flight: capture credential helper state and timing**

```bash
{
  echo ""
  echo "=== STEP 8a: PRE-FLIGHT at $(date -Iseconds) ==="
  echo ""
  echo "--- credential helper config ---"
  git config --get-all credential.helper
  echo ""
  echo "--- remote ---"
  git remote -v
  echo ""
  echo "--- current branch and upstream ---"
  git rev-parse --abbrev-ref HEAD
  git rev-parse @{u} 2>&1 || echo "(no upstream set)"
  echo ""
  echo "--- gh auth status ---"
  gh auth status 2>&1
  echo ""
  echo "--- credential lookup timing (no secrets logged) ---"
  # `git credential fill` exercises the same helper path that `git push` will use.
  # Output is suppressed so the token never lands in the log; only timing is captured.
  time ( printf "protocol=https\nhost=github.com\n\n" | git credential fill >/dev/null 2>&1 )
  echo ""
} 2>&1 | tee -a <LOG_PATH>
```

Read the timing line. If the credential lookup takes more than ~1 second, the keyring is the bottleneck and any push slowness is likely downstream of that, not network.

**8b — Stage and commit**

```bash
{
  echo ""
  echo "=== STEP 8b: COMMIT at $(date -Iseconds) ==="
  git add -A
  echo "--- staged ---"
  git status --short
  echo ""
} 2>&1 | tee -a <LOG_PATH>
```

Write the commit message following conventional commits, then run the commit through tee:

```
<type>(<optional scope>): <short description>

<body if needed — what changed and why, not how>

refs #<issue number if known>

Co-Authored-By: Claude <noreply@anthropic.com>
```

```bash
git commit -m "<message>" 2>&1 | tee -a <LOG_PATH>
```

**8c — Push with full protocol tracing**

Run push with three trace flags so a silent hang doesn't produce a silent log:

| Flag | What it captures |
|------|------------------|
| `GIT_TRACE=1` | Built-in commands, refspec resolution, sub-process invocations |
| `GIT_TRACE_SETUP=1` | Working tree, git dir, prefix discovery |
| `GIT_CURL_VERBOSE=1` | DNS resolution, TCP connect, TLS handshake, HTTP request/response headers |

Without `GIT_CURL_VERBOSE` a network hang leaves zero log content — just "Pushing to …" then 30 seconds of nothing. With it, you see exactly which protocol layer fails (DNS, TCP, TLS, or HTTP).

**Security caveat:** `GIT_CURL_VERBOSE` logs HTTP request headers, which on GitHub includes `Authorization: Basic <base64-of-token>`. Step 8d below redacts this from the log before the file is shareable. Do not share the log file with anyone until Step 8d has run.

```bash
{
  echo ""
  echo "=== STEP 8c: PUSH at $(date -Iseconds) ==="
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  echo "pushing branch: $BRANCH"
  echo ""
  time GIT_TRACE=1 GIT_TRACE_SETUP=1 GIT_CURL_VERBOSE=1 \
    git push --porcelain --set-upstream origin "$BRANCH" 2>&1
  PUSH_EXIT=$?
  echo ""
  echo "--- push exit code: $PUSH_EXIT at $(date -Iseconds) ---"
} 2>&1 | tee -a <LOG_PATH>
```

Note `PUSH_EXIT=$?` captured *inside* the inner block — see the Step 0 warning about `$?` after outer pipes.

**8d — Redact secrets from the log**

`GIT_CURL_VERBOSE` writes Authorization headers and any other token-bearing lines to the log. Strip them before the log can be shared. This is in-place, idempotent, and safe to run on logs that have nothing to redact:

```bash
sed -i -E \
  -e 's/([Aa]uthorization:[[:space:]]+).*/\1[REDACTED]/' \
  -e 's/([Bb]earer[[:space:]]+)[A-Za-z0-9._\/+=-]+/\1[REDACTED]/g' \
  -e 's/([Bb]asic[[:space:]]+)[A-Za-z0-9+\/=]+/\1[REDACTED]/g' \
  -e 's/(token=)[A-Za-z0-9._\/+=-]+/\1[REDACTED]/g' \
  -e 's/(password=)[^&[:space:]]+/\1[REDACTED]/g' \
  <LOG_PATH>

# Leak check — flags any sensitive keyword followed within 5 chars by a 20+ char
# token-shaped string. `[REDACTED]` (length 10, starts with `[`) does not match.
grep -niE '(authorization:|bearer |basic |token=|password=).{0,5}[A-Za-z0-9_.+\/=-]{20,}' <LOG_PATH> \
  || echo "✓ no secrets remain"
```

The Authorization-header line is stripped to end-of-line because the credentials follow the scheme word (`Basic eHh4...`, `Bearer ghp_...`) — partial-match patterns leak the token. Standalone `Bearer`/`Basic`/`token=`/`password=` patterns catch cases where the secret appears without an `Authorization:` prefix (URL params, curl trace lines).

**8e — Outcome handling**

If `PUSH_EXIT` is non-zero, classify the failure from the log before announcing anything to the user. Look for these markers (left-to-right is first-error-found-wins):

| Log signature | Diagnosis |
|---------------|-----------|
| `Could not resolve host` or `Name or service not known` | DNS failure |
| `Trying X.Y.Z.W:443...` with no `Connected to ...` line after | TCP connect black-holed (firewall / egress block) |
| `Connected to ...` then `SSL connect error` or `handshake failure` | TLS issue (cert, version, MITM proxy) |
| `< HTTP/1.1 401` or `< HTTP/1.1 403` | Auth — token missing / expired / wrong scope |
| `< HTTP/1.1 404` | Wrong remote URL or repository deleted |
| `non-fast-forward` or `rejected` | Local branch behind remote — pull first |

Then:

1. **Do not** announce "GitHub is down" unless the log contains DNS or TCP-level errors from above. The most common false diagnosis on this machine has been to call a local credential-helper or firewall problem a remote outage.
2. Print the log path to the user: `LOG_PATH=<the path from Step 0>`
3. Print the last 60 lines of the log:
   ```bash
   tail -60 <LOG_PATH>
   ```
4. Stop. Ask the user whether to retry or investigate. Do **not** auto-retry silently.

If `PUSH_EXIT` is zero, record success:

```bash
{
  echo ""
  echo "=== STEP 8e: SUCCESS at $(date -Iseconds) ==="
  echo "SHA: $(git rev-parse HEAD)"
  echo "REMOTE: $(git remote get-url origin)"
} 2>&1 | tee -a <LOG_PATH>
```

---

### Step 9 — Clear context

Print this exact block (substitute real values, including `LOG_PATH` from Step 0):

```
═══════════════════════════════════════════════════════
TASK COMPLETE
═══════════════════════════════════════════════════════

Task:    $ARGUMENTS
Commit:  [SHA] [message]
Branch:  [branch]
Pushed:  [remote URL]

Docs updated:
  [list each file updated and what changed]

Diagnostic log: [LOG_PATH]
  Keep this file if anything looked off — it contains the full trace
  of git state, credential timing, and the push itself.

Context cleared. Ready for next task.
═══════════════════════════════════════════════════════
```

Then run `/clear` to reset the context window.
