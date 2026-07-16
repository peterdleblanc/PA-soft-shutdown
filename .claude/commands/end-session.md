# End Session

Wrap up the current session: update all documentation, commit, and push.

Usage: `/end-session`

---

## Instructions

You are ending a session. Work through these steps in order. Do not skip steps.

---

### Step 0 — Initialize diagnostic logging

**Mandatory.** Push failures here have been misdiagnosed in past sessions as "GitHub is down" when the real cause is local (credential-helper / keyring timing). Logging is the fix: every shell command from here on is captured to a timestamped file so the actual error stays visible.

Run this **first**:

```bash
mkdir -p ~/.claude/logs
LOG="$HOME/.claude/logs/end-session-$(date +%Y%m%d-%H%M%S).log"
{
  echo "=== /end-session starting at $(date -Iseconds) ==="
  echo "PWD: $(pwd)"
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

Print the log path to the user at the start and again at the end.

---

### Step 1 — Gather what happened

Run these and tee each to the log (substitute `<LOG_PATH>` with the value from Step 0):

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
} 2>&1 | tee -a <LOG_PATH>
```

Build a clear picture of what was accomplished this session before touching any documentation.

---

### Step 2 — Update HANDOFF.md

Read `HANDOFF.md`. Make these changes:

1. Update **"Last Updated"** to today's date and session number
2. Update **"Branch"** and **"Git Status"** to match current reality
3. Replace the **"Completed This Session"** section with a summary of today's work (3–5 bullets, specific — what was built, fixed, or changed)
4. Update **"Next Session — Start Here"** to reflect what's actually next — remove anything just completed, add anything newly discovered

Surgical edits only. Do not rewrite sections that didn't change. Target: 60–80 lines total.

---

### Step 3 — Archive to HANDOFF_HISTORY.md

Read `HANDOFF_HISTORY.md`. Prepend a new entry at the top (below the file header, above any previous entries):

```
## YYYY-MM-DD — [one-line summary of what this session accomplished]

**Completed:**
- [bullet per distinct item built, fixed, or shipped]

**Key decisions:**
- [notable choices made, or "None" if routine work]

**Commits:** `[SHA]` [message]

---
```

Use today's date. Pull the commit SHA from Step 1's git log output. If there are uncommitted changes, note that in the Commits line.

---

### Step 4 — Update CHANGELOG.md (if applicable)

Read `CHANGELOG.md`. Add an entry under `## [Unreleased]` if the session produced:
- A new feature → `### Added`
- A changed behavior → `### Changed`
- A bug fix → `### Fixed`

Format: `- **Short title** — one sentence describing the change and its impact`

Skip this step for sessions that only touched documentation, configuration, or internal changes with no user-visible effect.

---

### Step 5 — Update ROADMAP.md (if applicable)

Read `ROADMAP.md`. If any phase items were completed this session, mark them done (`- [x]`). If a phase is now fully complete, update the status header and the status overview diagram at the top.

Skip if the session had no roadmap-relevant work.

---

### Step 6 — Confirm commit scope

Show the user:

```
Files to be committed:
[list from git status]

Documentation updated:
  [list HANDOFF.md, HANDOFF_HISTORY.md, CHANGELOG.md, ROADMAP.md as applicable]

Branch: [current branch]
Commit message: docs: session wrap-up — [one-line summary]

Confirm commit and push? (or specify a different branch)
```

Wait for confirmation before proceeding.

---

### Step 7 — Commit and push (with full tracing)

Mirror `/complete-task` Steps 8a–8e. The end-of-session push is the most common place where "GitHub is down" gets falsely diagnosed — the diagnostic logging in this step is the entire point of having a logged workflow.

**7a — Pre-flight: capture credential helper state and timing**

```bash
{
  echo ""
  echo "=== STEP 7a: PRE-FLIGHT at $(date -Iseconds) ==="
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
  # Output suppressed so the token never lands in the log; only timing is captured.
  time ( printf "protocol=https\nhost=github.com\n\n" | git credential fill >/dev/null 2>&1 )
  echo ""
} 2>&1 | tee -a <LOG_PATH>
```

If the credential lookup takes more than ~1 second, the keyring is the bottleneck — push slowness downstream is likely caused by that, not by network.

**7b — Stage and commit**

```bash
{
  echo ""
  echo "=== STEP 7b: COMMIT at $(date -Iseconds) ==="
  git add -A
  echo "--- staged ---"
  git status --short
  echo ""
} 2>&1 | tee -a <LOG_PATH>
```

Then commit with the wrap-up message:

```bash
git commit -m "$(cat <<'EOF'
docs: session wrap-up — [one-line summary of what was accomplished]

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)" 2>&1 | tee -a <LOG_PATH>
```

**7c — Push with full protocol tracing**

Three trace flags so a silent hang doesn't produce a silent log:

| Flag | What it captures |
|------|------------------|
| `GIT_TRACE=1` | Built-in commands, refspec resolution, sub-process invocations |
| `GIT_TRACE_SETUP=1` | Working tree, git dir, prefix discovery |
| `GIT_CURL_VERBOSE=1` | DNS resolution, TCP connect, TLS handshake, HTTP request/response headers |

Without `GIT_CURL_VERBOSE` a network hang leaves zero log content. With it, you see exactly which protocol layer fails.

**Security caveat:** `GIT_CURL_VERBOSE` logs HTTP request headers, which on GitHub includes `Authorization: Basic <base64-of-token>`. Step 7d below redacts this before the log is shareable. Do not share the log file until Step 7d has run.

```bash
{
  echo ""
  echo "=== STEP 7c: PUSH at $(date -Iseconds) ==="
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

`PUSH_EXIT=$?` is captured *inside* the inner block — see the Step 0 warning about `$?` after outer pipes.

**7d — Redact secrets from the log**

In-place, idempotent, safe to run on logs that have nothing to redact:

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

**7e — Outcome handling**

If `PUSH_EXIT` is non-zero, classify the failure from the log before announcing anything:

| Log signature | Diagnosis |
|---------------|-----------|
| `Could not resolve host` or `Name or service not known` | DNS failure |
| `Trying X.Y.Z.W:443...` with no `Connected to ...` line after | TCP connect black-holed (firewall / egress block) |
| `Connected to ...` then `SSL connect error` or `handshake failure` | TLS issue (cert, version, MITM proxy) |
| `< HTTP/1.1 401` or `< HTTP/1.1 403` | Auth — token missing / expired / wrong scope |
| `< HTTP/1.1 404` | Wrong remote URL or repository deleted |
| `non-fast-forward` or `rejected` | Local branch behind remote — pull first |

Then:

1. **Do not** announce "GitHub is down" unless the log contains DNS or TCP-level errors from above.
2. Print the log path: `LOG_PATH=<the path from Step 0>`
3. Print the last 60 lines:
   ```bash
   tail -60 <LOG_PATH>
   ```
4. Stop. Ask the user whether to retry or investigate. Do **not** auto-retry silently.

If `PUSH_EXIT` is zero, record success and continue to Step 8:

```bash
{
  echo ""
  echo "=== STEP 7e: SUCCESS at $(date -Iseconds) ==="
  echo "SHA: $(git rev-parse HEAD)"
  echo "REMOTE: $(git remote get-url origin)"
} 2>&1 | tee -a <LOG_PATH>
```

---

### Step 8 — Display summary

Print this exact block:

```
═══════════════════════════════════════════════════════
SESSION END — {date}
═══════════════════════════════════════════════════════

Completed this session:
  {bullets from updated HANDOFF.md}

Docs updated:
  {list each file and what changed}

Commit:  {SHA} {message}
Branch:  {branch}
Pushed:  yes

Next session:
  {bullets from HANDOFF.md "Next Session — Start Here"}
═══════════════════════════════════════════════════════
```
