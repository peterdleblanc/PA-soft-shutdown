# Docker Test

Run the full test suite — unit tests, integration tests, and Playwright E2E — and report results.

Usage: `/docker-test` (all) or `/docker-test unit` or `/docker-test e2e` or `/docker-test [service-name]`

---

## Instructions

### Step 1 — Understand the project's test setup

Run in parallel:
```
cat package.json 2>/dev/null | python3 -c "import sys,json; p=json.load(sys.stdin); [print(k,':',v) for k,v in p.get('scripts',{}).items() if any(x in k for x in ['test','e2e','playwright'])]" 2>/dev/null || true
ls docker-compose.test.yml docker-compose.testing.yml 2>/dev/null || true
ls backend/Cargo.toml 2>/dev/null || true
ls processor/requirements*.txt 2>/dev/null || true
ls frontend/playwright.config.ts frontend/playwright.config.js 2>/dev/null || true
```

Parse `$ARGUMENTS` to determine scope:
- Empty → run all test layers found
- `unit` → unit tests only (no Playwright)
- `e2e` or `playwright` → Playwright only
- A service name (e.g. `backend`, `frontend`) → that layer only

### Step 2 — Start test services if needed

If `docker-compose.test.yml` exists and we're running integration or E2E tests:

```bash
docker compose -f docker-compose.test.yml up -d
```

Wait 5 seconds for services to be ready, then verify:
```bash
docker compose -f docker-compose.test.yml ps
```

Tell the user which test services are now running.

### Step 3 — Run each test layer

Run only the layers that exist in this project. For each one found, run it and capture pass/fail counts.

**Rust backend unit + integration tests:**
```bash
cd backend && cargo test 2>&1 | tail -20
```
Parse output for: `test result: ok. N passed; M failed`

**Python processor tests:**
```bash
cd processor && python -m pytest --tb=short -q 2>&1 | tail -20
```
Parse output for: `N passed, M failed`

**Frontend unit tests (Vitest):**
```bash
cd frontend && npm run test -- --run 2>&1 | tail -20
```
Parse output for pass/fail counts.

**Frontend Playwright E2E tests:**
```bash
cd frontend && npx playwright test --reporter=line 2>&1 | tail -30
```
Parse output for: `N passed (Xs)` or `N failed`

If any test layer is not present (no config file, no test directory), skip it and note it as "not configured".

### Step 4 — Check the testing gate

After all tests run, evaluate whether the **testing gate** is satisfied:

1. **Unit tests exist?** — Check that at least one unit test file exists for each major feature area
2. **Unit tests passing?** — Zero failures across all unit test layers
3. **Playwright spec exists?** — `frontend/tests/e2e/specs/` or similar has at least one `.spec.ts` file
4. **Playwright passing?** — Zero failures in E2E run

Gate status: PASS only if all 4 conditions are true and no test layer has failures.

### Step 5 — Tear down test services

If test services were started in Step 2:
```bash
docker compose -f docker-compose.test.yml down
```

### Step 6 — Report results

Print this summary block:

```
═══════════════════════════════════════════════════════
TEST RESULTS
═══════════════════════════════════════════════════════

  Rust unit/integration   [N passed / M failed | not configured]
  Python processor        [N passed / M failed | not configured]
  Frontend unit (Vitest)  [N passed / M failed | not configured]
  Frontend E2E (Playwright)[N passed / M failed | not configured]

  ─────────────────────────────────────────────────────
  Total:  N passed  |  M failed
  Time:   Xs

TESTING GATE: [✓ PASS — ready to commit | ✗ FAIL — fix before committing]

[If FAIL: list each specific failure with file name and test name]
[If gate fails due to missing tests: name the layer that has no tests written]
═══════════════════════════════════════════════════════
```

If the gate fails, do not proceed. Show the failures and stop.

If the gate passes, tell the user: "All tests passing. Safe to commit."
