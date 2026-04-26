#!/usr/bin/env bash
set -u

INSTALL_COMMAND=(npm install -g @google/gemini-cli)

if ! command -v node >/dev/null 2>&1; then
  echo "ERROR: Required prerequisite 'node' is not available on PATH. Install Node in the consuming devcontainer before using the gemini-cli feature." >&2
  exit 1
fi

NODE_MAJOR=$(node -e 'console.log(process.versions.node.split(".")[0])')
if [ "$NODE_MAJOR" -lt 22 ]; then
  echo "ERROR: Node >= 22 is required, but found Node $(node --version). Install Node 22+ in the consuming devcontainer before using the gemini-cli feature." >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "ERROR: Required prerequisite 'npm' is not available on PATH. Install npm in the consuming devcontainer before using the gemini-cli feature." >&2
  exit 1
fi

echo "Installing gemini-cli with: ${INSTALL_COMMAND[*]}" >&2
"${INSTALL_COMMAND[@]}"
install_exit_code=$?

if [ "$install_exit_code" -ne 0 ]; then
  echo "ERROR: gemini-cli install failed while running: ${INSTALL_COMMAND[*]}" >&2
  exit "$install_exit_code"
fi
