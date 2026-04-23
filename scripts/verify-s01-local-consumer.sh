#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVCONTAINER_JSON="$ROOT_DIR/.devcontainer/devcontainer.json"
FEATURE_DIR="$ROOT_DIR/src/gsd"
WORKSPACE_FOLDER="$ROOT_DIR"
READ_CONFIG_TIMEOUT="${READ_CONFIG_TIMEOUT:-120}"
UP_TIMEOUT="${UP_TIMEOUT:-1800}"
EXEC_TIMEOUT="${EXEC_TIMEOUT:-300}"
DEVCONTAINER_ID_LABEL="gsd-s01-local-consumer"

fail() {
  echo "FAIL[$1]: $2" >&2
  exit 1
}

assert_file_exists() {
  local path="$1"
  [ -f "$path" ] || fail config "Expected file to exist: $path"
}

assert_dir_exists() {
  local path="$1"
  [ -d "$path" ] || fail config "Expected directory to exist: $path"
}

assert_contains() {
  local needle="$1"
  local path="$2"
  grep -Fq "$needle" "$path" || fail config "Expected '$needle' in $path"
}

assert_not_contains() {
  local needle="$1"
  local path="$2"
  if grep -Fq "$needle" "$path"; then
    fail config "Did not expect '$needle' in $path"
  fi
}

require_command() {
  local command_name="$1"
  command -v "$command_name" >/dev/null 2>&1 || fail cli "Required command '$command_name' is not available on PATH"
}

run_phase() {
  local phase="$1"
  local timeout_seconds="$2"
  shift 2

  local -a command=("$@")
  echo "[verify][$phase] ${command[*]}" >&2

  set +e
  timeout --foreground "$timeout_seconds" "${command[@]}"
  local exit_code=$?
  set -e

  case "$exit_code" in
    0)
      return 0
      ;;
    124)
      fail "$phase" "Timed out after ${timeout_seconds}s while running: ${command[*]}"
      ;;
    *)
      fail "$phase" "Command failed with exit code ${exit_code}: ${command[*]}"
      ;;
  esac
}

echo "[verify][config] checking repository devcontainer wiring" >&2
assert_file_exists "$DEVCONTAINER_JSON"
assert_dir_exists "$FEATURE_DIR"
assert_contains '"./src/gsd": {}' "$DEVCONTAINER_JSON"
assert_contains '"ghcr.io/devcontainers/features/node:1"' "$DEVCONTAINER_JSON"
assert_not_contains 'postCreateCommand' "$DEVCONTAINER_JSON"
assert_not_contains 'npm install -g gsd-pi@latest' "$DEVCONTAINER_JSON"

require_command timeout
require_command npx
command -v docker >/dev/null 2>&1 || fail runtime "Required command 'docker' is not available on PATH, so the devcontainer CLI cannot inspect or start the workspace container"

run_phase read-configuration "$READ_CONFIG_TIMEOUT" \
  npx @devcontainers/cli read-configuration --workspace-folder "$WORKSPACE_FOLDER"

run_phase up "$UP_TIMEOUT" \
  npx @devcontainers/cli up --workspace-folder "$WORKSPACE_FOLDER" --id-label "$DEVCONTAINER_ID_LABEL=true" --skip-post-create

run_phase exec "$EXEC_TIMEOUT" \
  npx @devcontainers/cli exec --workspace-folder "$WORKSPACE_FOLDER" gsd --version

echo "PASS: local devcontainer consumes ./src/gsd and gsd is available inside the running container" >&2
