#!/usr/bin/env bash
# examples-auto-run/scripts/run.sh
# Automatically discovers and runs all examples in the repository,
# capturing output and reporting pass/fail status.

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
EXAMPLES_DIR="${REPO_ROOT}/examples"
LOG_DIR="${REPO_ROOT}/.agents/skills/examples-auto-run/logs"
TIMEOUT_SECONDS=${EXAMPLES_TIMEOUT:-60}
PYTHON=${PYTHON_BIN:-python}

PASSED=0
FAILED=0
SKIPPED=0
FAILED_EXAMPLES=()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { echo "[examples-auto-run] $*"; }
warn() { echo "[examples-auto-run] WARNING: $*" >&2; }
err()  { echo "[examples-auto-run] ERROR: $*" >&2; }

mkdir -p "${LOG_DIR}"

# Verify the examples directory exists
if [[ ! -d "${EXAMPLES_DIR}" ]]; then
  err "Examples directory not found: ${EXAMPLES_DIR}"
  exit 1
fi

# ---------------------------------------------------------------------------
# Dependency check
# ---------------------------------------------------------------------------
if ! command -v "${PYTHON}" &>/dev/null; then
  err "Python interpreter not found: ${PYTHON}"
  exit 1
fi

log "Using Python: $(${PYTHON} --version 2>&1)"
log "Examples directory: ${EXAMPLES_DIR}"
log "Timeout per example: ${TIMEOUT_SECONDS}s"
log "Log directory: ${LOG_DIR}"
log ""

# ---------------------------------------------------------------------------
# Install package in editable mode if not already installed
# ---------------------------------------------------------------------------
if ! "${PYTHON}" -c "import agents" &>/dev/null; then
  log "Installing openai-agents in editable mode..."
  "${PYTHON}" -m pip install -e "${REPO_ROOT}" --quiet
fi

# ---------------------------------------------------------------------------
# Discover examples
# ---------------------------------------------------------------------------
# An example is any *.py file directly inside examples/ or one level deep.
mapfile -t EXAMPLE_FILES < <(
  find "${EXAMPLES_DIR}" -maxdepth 2 -name '*.py' | sort
)

if [[ ${#EXAMPLE_FILES[@]} -eq 0 ]]; then
  warn "No example files found under ${EXAMPLES_DIR}"
  exit 0
fi

log "Discovered ${#EXAMPLE_FILES[@]} example file(s)."
log "$(printf '  - %s\n' "${EXAMPLE_FILES[@]}")"
log ""

# ---------------------------------------------------------------------------
# Run each example
# ---------------------------------------------------------------------------
for example in "${EXAMPLE_FILES[@]}"; do
  relative="${example#${REPO_ROOT}/}"
  safe_name="$(echo "${relative}" | tr '/' '_' | tr ' ' '_')"
  log_file="${LOG_DIR}/${safe_name%.py}.log"

  # Skip files that explicitly opt out via a magic comment
  if grep -q '# examples-auto-run: skip' "${example}" 2>/dev/null; then
    log "SKIP  ${relative}  (opt-out comment found)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  log "RUN   ${relative}"

  set +e
  timeout "${TIMEOUT_SECONDS}" \
    "${PYTHON}" "${example}" \
    > "${log_file}" 2>&1
  exit_code=$?
  set -e

  if [[ ${exit_code} -eq 0 ]]; then
    log "PASS  ${relative}"
    PASSED=$((PASSED + 1))
  elif [[ ${exit_code} -eq 124 ]]; then
    warn "TIMEOUT ${relative} (exceeded ${TIMEOUT_SECONDS}s)"
    echo "[TIMEOUT after ${TIMEOUT_SECONDS}s]" >> "${log_file}"
    FAILED=$((FAILED + 1))
    FAILED_EXAMPLES+=("${relative} (timeout)")
  else
    err "FAIL  ${relative}  (exit code ${exit_code})"
    err "      Log: ${log_file}"
    FAILED=$((FAILED + 1))
    FAILED_EXAMPLES+=("${relative} (exit ${exit_code})")
  fi
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
log ""
log "======================================="
log "Examples run summary"
log "======================================="
log "  Passed:  ${PASSED}"
log "  Failed:  ${FAILED}"
log "  Skipped: ${SKIPPED}"
log "  Total:   ${#EXAMPLE_FILES[@]}"

if [[ ${FAILED} -gt 0 ]]; then
  log ""
  log "Failed examples:"
  for item in "${FAILED_EXAMPLES[@]}"; do
    log "  - ${item}"
  done
  log ""
  err "One or more examples failed. Check logs in ${LOG_DIR}"
  exit 1
fi

log ""
log "All examples passed."
exit 0
