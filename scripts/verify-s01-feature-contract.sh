#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FEATURE_JSON="$ROOT_DIR/src/gsd/devcontainer-feature.json"
INSTALL_SH="$ROOT_DIR/src/gsd/install.sh"
BASH_BIN="$(command -v bash)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file_exists() {
  local path="$1"
  [ -f "$path" ] || fail "Expected file to exist: $path"
}

assert_executable() {
  local path="$1"
  [ -x "$path" ] || fail "Expected file to be executable: $path"
}

assert_contains() {
  local needle="$1"
  local path="$2"
  grep -Fq "$needle" "$path" || fail "Expected '$needle' in $path"
}

assert_not_contains() {
  local needle="$1"
  local path="$2"
  if grep -Fq "$needle" "$path"; then
    fail "Did not expect '$needle' in $path"
  fi
}

run_missing_prereq_case() {
  local case_name="$1"
  local expected_message="$2"
  local stub_kind="$3"
  local temp_dir
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' RETURN

  mkdir -p "$temp_dir/bin"

  case "$stub_kind" in
    node_only)
      cat >"$temp_dir/bin/node" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
      chmod +x "$temp_dir/bin/node"
      ;;
    none)
      ;;
    *)
      fail "Unknown stub kind: $stub_kind"
      ;;
  esac

  local stderr_file="$temp_dir/stderr.log"
  local stdout_file="$temp_dir/stdout.log"

  set +e
  PATH="$temp_dir/bin" "$BASH_BIN" "$INSTALL_SH" >"$stdout_file" 2>"$stderr_file"
  local exit_code=$?
  set -e

  [ "$exit_code" -ne 0 ] || fail "$case_name should have failed"
  grep -Fq "$expected_message" "$stderr_file" || fail "$case_name should mention '$expected_message'"
  assert_not_contains "Installing gsd with:" "$stderr_file"
}

echo "[verify] checking feature package shape"
assert_file_exists "$FEATURE_JSON"
assert_file_exists "$INSTALL_SH"
assert_executable "$INSTALL_SH"
assert_contains '"id": "gsd"' "$FEATURE_JSON"
assert_contains '"name": "GSD CLI"' "$FEATURE_JSON"
assert_contains '"options": {}' "$FEATURE_JSON"

echo "[verify] checking exact install command contract"
assert_contains 'INSTALL_COMMAND=(npm install -g gsd-pi@latest)' "$INSTALL_SH"
assert_contains 'Required prerequisite '\''node'\''' "$INSTALL_SH"
assert_contains 'Required prerequisite '\''npm'\''' "$INSTALL_SH"
assert_contains 'ERROR: gsd install failed while running: ${INSTALL_COMMAND[*]}' "$INSTALL_SH"

echo "[verify] checking missing node failure path"
run_missing_prereq_case "missing node" "Required prerequisite 'node'" none

echo "[verify] checking missing npm failure path"
run_missing_prereq_case "missing npm" "Required prerequisite 'npm'" node_only

echo "PASS: feature contract and prerequisite diagnostics verified"
