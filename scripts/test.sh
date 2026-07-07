#!/usr/bin/env sh
# test.sh — run this project's own test suite, whatever language it's in.
#
# This is the single entry point the pre-push hook (.githooks/pre-push) calls
# before every push, and the one /end-session runs before committing. It auto-
# detects the toolchains present in the repo and runs each one's tests. A single
# repo may hit several branches (e.g. a Rust backend + a JS frontend) — all of
# them run.
#
# Contract: exit 0 = safe to push. Any non-zero exit blocks the push.
#
# Run it yourself any time:  sh scripts/test.sh
set -eu

ran=0   # did we run any suite at all?

echo "== test.sh: detecting toolchains =="

# --- Rust -------------------------------------------------------------------
if [ -f Cargo.toml ]; then
  if command -v cargo >/dev/null 2>&1; then
    echo ">> cargo test"
    cargo test
    ran=1
  else
    echo "!! Cargo.toml present but 'cargo' not on PATH — skipping (install rustup)" >&2
  fi
fi

# --- Go ---------------------------------------------------------------------
if [ -f go.mod ]; then
  if command -v go >/dev/null 2>&1; then
    echo ">> go test ./..."
    go test ./...
    ran=1
  else
    echo "!! go.mod present but 'go' not on PATH — skipping" >&2
  fi
fi

# --- Python -----------------------------------------------------------------
if [ -f pyproject.toml ] || [ -f setup.py ] || [ -d tests ]; then
  if command -v pytest >/dev/null 2>&1; then
    echo ">> pytest"
    pytest -q
    ran=1
  elif command -v python3 >/dev/null 2>&1 && python3 -c 'import pytest' 2>/dev/null; then
    echo ">> python3 -m pytest"
    python3 -m pytest -q
    ran=1
  else
    echo "!! Python project detected but pytest not available — skipping (pip install pytest)" >&2
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
      echo ">> npm test ($dir)"
      ( cd "$dir" && npm test )
      ran=1
    else
      echo "!! $pkg has a test script but 'npm' not on PATH — skipping" >&2
    fi
  fi
done

echo ""
if [ "$ran" -eq 0 ]; then
  echo "== test.sh: no test suite detected. =="
  echo "   Add tests (and a runner this script knows about) or this gate is a no-op."
  # A project with no tests yet should not be blocked from pushing.
  exit 0
fi

echo "== test.sh: all detected suites passed. =="
