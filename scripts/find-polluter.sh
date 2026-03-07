#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────
# find-polluter.sh
#
# Finds which test is polluting shared state, causing another
# test to fail when run together but pass when run alone.
#
# Uses binary search to find the minimum set of tests that
# must run before the failing test to trigger the failure.
# ──────────────────────────────────────────────────────────────

# ── Usage ─────────────────────────────────────────────────────
usage() {
  cat <<'USAGE'
Usage: find-polluter.sh [OPTIONS] --failing <test> --suite <test_list_file>

Find which test pollutes shared state and causes another test to fail.

Options:
  --failing <test>        The test that fails when run after others
  --suite <file>          File containing the full ordered test list (one per line)
  --runner jest|pytest    Test runner to use (default: auto-detect)
  --help                  Show this help message

How it works:
  1. Confirms the failing test passes when run alone
  2. Confirms it fails when run with the full suite
  3. Binary-searches the suite to find the minimal polluter

Examples:
  find-polluter.sh --failing "src/auth.test.ts" --suite test-order.txt
  find-polluter.sh --failing "tests/test_cache.py" --suite test-order.txt --runner pytest

Generate a test order file:
  jest --listTests > test-order.txt
  pytest --collect-only -q | grep '::' > test-order.txt
USAGE
  exit 0
}

# ── Defaults ──────────────────────────────────────────────────
FAILING_TEST=""
SUITE_FILE=""
RUNNER=""

# ── Argument Parsing ──────────────────────────────────────────
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --failing)
        shift
        FAILING_TEST="${1:-}"
        ;;
      --suite)
        shift
        SUITE_FILE="${1:-}"
        ;;
      --runner)
        shift
        RUNNER="${1:-}"
        ;;
      --help|-h)
        usage
        ;;
      *)
        echo "Error: Unknown option '$1'" >&2
        echo "Run 'find-polluter.sh --help' for usage." >&2
        exit 1
        ;;
    esac
    shift
  done

  if [[ -z "$FAILING_TEST" ]]; then
    echo "Error: --failing is required" >&2
    exit 1
  fi

  if [[ -z "$SUITE_FILE" ]]; then
    echo "Error: --suite is required" >&2
    exit 1
  fi

  if [[ ! -f "$SUITE_FILE" ]]; then
    echo "Error: Suite file not found: $SUITE_FILE" >&2
    exit 1
  fi
}

# ── Auto-detect Runner ───────────────────────────────────────
detect_runner() {
  if [[ -n "$RUNNER" ]]; then
    return
  fi

  if [[ -f "package.json" ]] && grep -q '"jest"' package.json 2>/dev/null; then
    RUNNER="jest"
  elif [[ -f "pytest.ini" ]] || [[ -f "pyproject.toml" ]] || [[ -f "setup.cfg" ]]; then
    RUNNER="pytest"
  else
    echo "Error: Cannot auto-detect test runner. Use --runner jest|pytest" >&2
    exit 1
  fi

  echo "Detected runner: $RUNNER"
}

# ── Run Tests ─────────────────────────────────────────────────
# Runs a list of test files followed by the failing test.
# Returns 0 if the failing test FAILS (pollution detected),
# Returns 1 if the failing test PASSES (no pollution).
run_tests_and_check_failure() {
  local -a test_files=("$@")

  case "$RUNNER" in
    jest)
      # Run specified tests in order, check if failing test fails
      if npx jest --no-coverage --bail "${test_files[@]}" "$FAILING_TEST" 2>/dev/null; then
        return 1  # Tests passed — no pollution
      else
        return 0  # Tests failed — pollution detected
      fi
      ;;
    pytest)
      if python -m pytest --no-header -q "${test_files[@]}" "$FAILING_TEST" 2>/dev/null; then
        return 1  # Tests passed — no pollution
      else
        return 0  # Tests failed — pollution detected
      fi
      ;;
    *)
      echo "Error: Unsupported runner: $RUNNER" >&2
      exit 1
      ;;
  esac
}

# ── Binary Search ─────────────────────────────────────────────
binary_search() {
  local -a tests=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && tests+=("$line")
  done < "$SUITE_FILE"

  # Remove the failing test from the suite if present
  local -a filtered=()
  for t in "${tests[@]}"; do
    if [[ "$t" != "$FAILING_TEST" ]]; then
      filtered+=("$t")
    fi
  done
  tests=("${filtered[@]}")

  local total=${#tests[@]}
  if [[ $total -eq 0 ]]; then
    echo "Error: Suite file is empty or only contains the failing test" >&2
    exit 1
  fi

  echo ""
  echo "Binary searching through $total tests..."
  echo ""

  local low=0
  local high=$((total - 1))

  while [[ $low -lt $high ]]; do
    local mid=$(( (low + high) / 2 ))
    local count=$((mid - low + 1))

    echo "Testing range [$low..$mid] ($count tests)..."

    local -a subset=("${tests[@]:$low:$count}")

    if run_tests_and_check_failure "${subset[@]}"; then
      # Pollution detected in this subset — narrow down
      high=$mid
      echo "  -> Pollution detected. Narrowing to [$low..$mid]"
    else
      # No pollution — polluter must be in the other half
      low=$((mid + 1))
      echo "  -> Clean. Polluter must be in [$((mid + 1))..$high]"
    fi
  done

  echo ""
  echo "========================================"
  echo "  POLLUTER FOUND"
  echo "========================================"
  echo ""
  echo "  ${tests[$low]}"
  echo ""
  echo "  This test modifies shared state that causes"
  echo "  $FAILING_TEST to fail when run after it."
  echo ""
  echo "  Next steps:"
  echo "    1. Run both tests together to confirm:"
  echo "       $RUNNER ${tests[$low]} $FAILING_TEST"
  echo "    2. Look for shared state: global variables,"
  echo "       database records, files, environment variables"
  echo "    3. Add proper setup/teardown to isolate the tests"
  echo ""
}

# ── Main ──────────────────────────────────────────────────────
main() {
  parse_args "$@"
  detect_runner

  echo "========================================"
  echo "  find-polluter.sh"
  echo "========================================"
  echo "  Failing test: $FAILING_TEST"
  echo "  Suite file:   $SUITE_FILE"
  echo "  Runner:       $RUNNER"
  echo "========================================"

  # Step 1: Verify the failing test passes alone
  echo ""
  echo "Step 1: Verifying failing test passes alone..."

  local alone_pass=true
  case "$RUNNER" in
    jest)  npx jest --no-coverage "$FAILING_TEST" 2>/dev/null || alone_pass=false ;;
    pytest) python -m pytest --no-header -q "$FAILING_TEST" 2>/dev/null || alone_pass=false ;;
  esac

  if [[ "$alone_pass" == "false" ]]; then
    echo "Error: The failing test also fails when run alone." >&2
    echo "This is not a test pollution issue -- the test itself is broken." >&2
    exit 1
  fi
  echo "  -> PASS (test passes alone)"

  # Step 2: Verify it fails with full suite
  echo ""
  echo "Step 2: Verifying it fails with full suite..."

  local -a all_tests=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && [[ "$line" != "$FAILING_TEST" ]] && all_tests+=("$line")
  done < "$SUITE_FILE"

  if ! run_tests_and_check_failure "${all_tests[@]}"; then
    echo "Error: The failing test passes even with the full suite." >&2
    echo "Cannot reproduce the pollution. Test order may have changed." >&2
    exit 1
  fi
  echo "  -> FAIL (pollution confirmed with full suite)"

  # Step 3: Binary search
  binary_search
}

main "$@"
