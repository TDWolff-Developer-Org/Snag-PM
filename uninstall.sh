#!/bin/bash
set -euo pipefail

RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'

step()  { echo -e "${BLUE}==>${RESET} ${BOLD}${1}${RESET}"; }
ok()    { echo -e "${GREEN}✓${RESET} ${1}"; }
warn()  { echo -e "${YELLOW}⚠${RESET}  ${1}"; }

SNAG_HOME="${HOME}/.snag"

echo
echo -e "  ${RED}${BOLD}Uninstall Snag${RESET}"
echo

# ── Confirm ────────────────────────────────────────────────────────────────────

read -r -p "  This will remove ~/.snag and all installed packages. Continue? [y/N] " confirm
echo
if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
  echo "  Cancelled."
  echo
  exit 0
fi

# ── Remove ~/.snag ─────────────────────────────────────────────────────────────

step "Removing ~/.snag"
if [ -d "${SNAG_HOME}" ]; then
  rm -rf "${SNAG_HOME}"
  ok "Removed ${SNAG_HOME}"
else
  warn "~/.snag not found — already uninstalled?"
fi

# ── Remove PATH line from shell config ─────────────────────────────────────────

remove_from_rc() {
  local rc_file="$1"
  [ -f "${rc_file}" ] || return
  local tmp="${rc_file}.snag.tmp"
  local changed=0

  # Remove single-line PATH entries
  if grep -q '\.snag/bin\|# Snag package manager' "${rc_file}" 2>/dev/null; then
    grep -v -e '# Snag package manager' -e '\.snag/bin' "${rc_file}" > "${tmp}"
    mv "${tmp}" "${rc_file}"
    changed=1
  fi

  # Remove multi-line venv shell function block
  if grep -q 'snag venv shell integration' "${rc_file}" 2>/dev/null; then
    awk '/# snag venv shell integration/{skip=1} skip && /^\}/{skip=0; next} !skip{print}' \
      "${rc_file}" > "${tmp}"
    mv "${tmp}" "${rc_file}"
    changed=1
  fi

  [ "${changed}" -eq 1 ] && ok "Cleaned snag entries from ${rc_file}"
}

step "Cleaning up shell config"
remove_from_rc "${HOME}/.zshrc"
remove_from_rc "${HOME}/.bashrc"
remove_from_rc "${HOME}/.bash_profile"
remove_from_rc "${HOME}/.config/fish/config.fish"

# ── Done ───────────────────────────────────────────────────────────────────────

echo
echo -e "  ${GREEN}${BOLD}Snag uninstalled.${RESET}"
echo -e "  Open a new terminal and the ${CYAN}snag${RESET} command will be gone."
echo
