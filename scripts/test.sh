#!/usr/bin/env sh
# test.sh — run this project's own test suite, whatever language it's in.
#
# This is the single entry point the pre-push hook (.githooks/pre-push) calls
# before every push, and the one /end-session runs before committing. It auto-
# detects the toolchains present in the repo and runs each one's tests. A single
# repo may hit several branches (e.g. a Rust backend + a JS frontend) — all of
# them run.
#
# Detects: Rust, Go, Django, Python (pytest), JavaScript/TypeScript (npm).
#
# Output contract (quiet by default): each suite prints ONE line — PASS or
# FAIL — and its full output goes to a log file under $TMPDIR. On failure the
# last 40 log lines are echoed so the pre-push hook still shows the real error.
# Pass --verbose (-v) to stream everything like a normal test run. The quiet
# default exists so an AI session (or a human skimming) reads outcomes, not
# streams — grep the log file when you need the detail.
#
# Contract: exit 0 = safe to push. Any non-zero exit blocks the push.
#
# A detection gap here is dangerous, not merely useless: a suite this script
# cannot see is a suite the gate reports as passing. If you add a toolchain,
# add a branch — and if a branch cannot run (no container, no deps), it must set
# `skipped=1` and say so rather than falling through to "all suites passed".
#
# Run it yourself any time:  sh scripts/test.sh [--verbose]
set -eu

VERBOSE=0
for arg in "$@"; do
  case "$arg" in
    -v|--verbose) VERBOSE=1 ;;
  esac
done

# Repo-named log file so runs in different projects don't clobber each other.
repo_name=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
LOG="${TMPDIR:-/tmp}/test-$repo_name.log"
: >"$LOG"
TAIL_LINES=40

ran=0       # did we run any suite at all?
skipped=0   # did we DETECT a suite but fail to run it? (no container, no deps, ...)

# run_suite <label> <command...> — run one suite.
# Verbose mode streams output exactly like the old behavior. Quiet mode (the
# default) appends the full output to $LOG and prints a single PASS/FAIL line;
# on FAIL it echoes the tail of the log before returning. Returns the command's
# exit code either way — callers decide what a failure means (pytest's exit 5
# is not a failure; everything else propagates and, under set -e, blocks).
#
# OK_RC: a caller may set this to one exit code that is NOT a failure for the
# next suite only (pytest's 5 = "no tests collected"). run_suite prints SKIP
# instead of FAIL + log tail for that code, still returns it, and resets the
# variable so it never leaks into the following suite.
OK_RC=""
run_suite() {
  _label="$1"; shift
  _ok_rc="$OK_RC"; OK_RC=""
  if [ "$VERBOSE" -eq 1 ]; then
    echo ">> $_label"
    "$@"
    return
  fi
  printf '>> %s ... ' "$_label"
  echo "===== $_label =====" >>"$LOG"
  if "$@" >>"$LOG" 2>&1; then
    echo "PASS"
  else
    _rc=$?
    if [ -n "$_ok_rc" ] && [ "$_rc" -eq "$_ok_rc" ]; then
      echo "SKIP (exit $_rc)"
    else
      echo "FAIL (exit $_rc)"
      echo ""
      echo "---- last $TAIL_LINES lines (full log: $LOG) ----"
      tail -n "$TAIL_LINES" "$LOG"
      echo "----"
    fi
    return "$_rc"
  fi
}

# venv_python — echo the project's own virtualenv interpreter if one is checked
# out at the repo root, else return non-zero.
#
# The pre-push hook (and /end-session) run this script with NO venv active, so a
# bare `pytest` or `python3 -m pytest` resolves to the SYSTEM interpreter —
# whose dependency versions can differ from the project's pinned ones. That is
# not hypothetical: a mismatched system WeasyPrint failed 5 PDF-rendering tests
# here that pass cleanly under .venv (weasyprint 69.0 / pydyf 0.12.1), blocking
# an unrelated docs push. Preferring the venv interpreter runs the gate against
# the same deps the project actually ships. Mirrors scripts/test_score.py's
# _target_python().
venv_python() {
  for _rel in .venv/bin/python venv/bin/python .venv/Scripts/python.exe; do
    if [ -x "$_rel" ]; then printf '%s\n' "$_rel"; return 0; fi
  done
  return 1
}

echo "== test.sh: detecting toolchains =="

# --- Rust -------------------------------------------------------------------
if [ -f Cargo.toml ]; then
  if command -v cargo >/dev/null 2>&1; then
    run_suite "cargo test" cargo test
    ran=1
  else
    echo "!! Cargo.toml present but 'cargo' not on PATH — skipping (install rustup)" >&2
  fi
fi

# --- Go ---------------------------------------------------------------------
if [ -f go.mod ]; then
  if command -v go >/dev/null 2>&1; then
    run_suite "go test ./..." go test ./...
    ran=1
  else
    echo "!! go.mod present but 'go' not on PATH — skipping" >&2
  fi
fi

# --- Django -----------------------------------------------------------------
# Django does not look like a generic Python project: there is often no
# pyproject.toml or setup.py, and tests live in <app>/tests.py rather than a root
# tests/ dir. Without this branch the generic Python check below never fires, and
# the gate silently passes having run nothing — not just today, but forever after
# tests are written. A gate that always says yes is worse than no gate.
manage_py=""
for candidate in manage.py backend/manage.py src/manage.py app/manage.py server/manage.py; do
  if [ -f "$candidate" ]; then manage_py="$candidate"; break; fi
done

if [ -n "$manage_py" ]; then
  django_ran=0
  django_dir=$(dirname "$manage_py")

  # Prefer running INSIDE the container. Django's test runner has to create a
  # test database, and the project's dependencies live in the image.
  if command -v docker >/dev/null 2>&1 && [ -f docker-compose.yml ]; then
    for svc in $(docker compose ps --status running --services 2>/dev/null || true); do
      case "$svc" in
        backend|web|api|django|app|server)
          run_suite "docker compose exec $svc python manage.py test" \
            docker compose exec -T "$svc" python manage.py test
          ran=1
          django_ran=1
          break
          ;;
      esac
    done
  fi

  # Host fallback — but probe with `manage.py check`, NOT `import django`.
  # Distros ship a system-wide python3-django, so `import django` succeeds on a
  # machine that does not have the project's real dependencies. The gate then
  # dies on ModuleNotFoundError partway through and blocks the push for no good
  # reason. `manage.py check` actually loads the project's settings, so it fails
  # honestly when the environment cannot run this project.
  if [ "$django_ran" -eq 0 ] && command -v python3 >/dev/null 2>&1; then
    if ( cd "$django_dir" && python3 manage.py check >/dev/null 2>&1 ); then
      run_suite "python3 manage.py test ($django_dir)" \
        sh -c "cd '$django_dir' && python3 manage.py test"
      ran=1
      django_ran=1
    fi
  fi

  if [ "$django_ran" -eq 0 ]; then
    echo "!! Django detected ($manage_py) but its tests could not be run:" >&2
    echo "   no running container to exec into, and 'manage.py check' fails on the" >&2
    echo "   host (missing dependencies, or no database)." >&2
    echo "   Bring the stack up and push again." >&2
    skipped=1
  fi
fi

# --- Python (pytest) --------------------------------------------------------
# Gate on Python test FILES, not on the mere existence of a `tests/` dir. That
# dir is not a Python signal: Workbench and MondayClone keep Playwright
# *.spec.ts under tests/, where bare `pytest` collects nothing, exits 5, and --
# under `set -e` -- aborted the gate and blocked the push of a repo that has no
# Python in it at all.
py_test_files=$(git ls-files \
  'test_*.py' '*_test.py' 'conftest.py' \
  '*/test_*.py' '*/*_test.py' '*/conftest.py' 2>/dev/null | head -1)

if [ -n "$py_test_files" ]; then
  # Prefer the project's own venv interpreter (see venv_python above) so the gate
  # runs against the project's pinned deps, not whatever the host happens to ship.
  # Fall back to a PATH pytest, then a system `python3 -m pytest`.
  pytest_cmd=""
  if _vpy=$(venv_python) && "$_vpy" -c 'import pytest' 2>/dev/null; then
    pytest_cmd="$_vpy -m pytest"
  elif command -v pytest >/dev/null 2>&1; then
    pytest_cmd="pytest"
  elif command -v python3 >/dev/null 2>&1 && python3 -c 'import pytest' 2>/dev/null; then
    pytest_cmd="python3 -m pytest"
  fi

  if [ -n "$pytest_cmd" ]; then
    # pytest exits 5 for "no tests collected". That is not a failure and must not
    # block a push. Any OTHER non-zero exit is a real failure and must propagate.
    set +e
    OK_RC=5
    # shellcheck disable=SC2086  # $pytest_cmd is intentionally word-split ("python3 -m pytest")
    run_suite "$pytest_cmd -q" $pytest_cmd -q
    py_rc=$?
    set -e
    if [ "$py_rc" -eq 0 ]; then
      ran=1
    elif [ "$py_rc" -eq 5 ]; then
      echo "   (pytest collected no tests — not treated as a failure)"
    else
      exit "$py_rc"
    fi
  else
    echo "!! Python tests found but pytest is not available — skipping (pip install pytest)" >&2
    skipped=1
  fi
fi

# --- JavaScript / TypeScript (one per package.json with a real test script) -
# git ls-files keeps us to tracked manifests and skips node_modules/ for free.
for pkg in $(git ls-files 'package.json' '*/package.json' 2>/dev/null || true); do
  dir=$(dirname "$pkg")
  # Only run if there's a real "test" script — skip the `npm init` placeholder
  # stub (`"test": "... no test specified ... && exit 1"`) which always fails.
  if grep -q '"test"[[:space:]]*:' "$pkg" && ! grep -q 'no test specified' "$pkg"; then
    if command -v npm >/dev/null 2>&1; then
      run_suite "npm test ($dir)" sh -c "cd '$dir' && npm test"
      ran=1
    else
      echo "!! $pkg has a test script but 'npm' not on PATH — skipping" >&2
    fi
  fi
done

echo ""
if [ "$ran" -eq 0 ]; then
  if [ "$skipped" -eq 1 ]; then
    # Do NOT say "passed" here. A suite exists and we failed to run it; claiming
    # success is a lie the pre-push hook would then act on.
    echo "== test.sh: a suite was DETECTED but could not be run (see warnings above). =="
    echo "   The push gate is passing WITHOUT having run any test."
  else
    echo "== test.sh: no test suite detected. =="
    echo "   Add tests (and a runner this script knows about) or this gate is a no-op."
  fi
  # Neither case blocks the push: a project with no tests, or a developer without
  # their stack up, is not a reason to refuse a push. The warning is loud enough.
  exit 0
fi

echo "== test.sh: all detected suites passed. =="
if [ "$VERBOSE" -eq 0 ]; then
  echo "   (full output: $LOG)"
fi
