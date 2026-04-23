#!/usr/bin/env bash
set -u

INSTALL_COMMAND=(npm install -g gsd-pi@latest)

if ! command -v node >/dev/null 2>&1; then
  echo "ERROR: Required prerequisite 'node' is not available on PATH. Install Node in the consuming devcontainer before using the gsd feature." >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "ERROR: Required prerequisite 'npm' is not available on PATH. Install npm in the consuming devcontainer before using the gsd feature." >&2
  exit 1
fi

echo "Installing gsd with: ${INSTALL_COMMAND[*]}" >&2
"${INSTALL_COMMAND[@]}"
install_exit_code=$?

if [ "$install_exit_code" -ne 0 ]; then
  echo "ERROR: gsd install failed while running: ${INSTALL_COMMAND[*]}" >&2
  exit "$install_exit_code"
fi
