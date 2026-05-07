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
  if [ -f "${rc_file}" ] && grep -q '\.snag/bin' "${rc_file}" 2>/dev/null; then
    local tmp="${rc_file}.snag.tmp"
    grep -v -e '# Snag package manager' -e '\.snag/bin' "${rc_file}" > "${tmp}"
    mv "${tmp}" "${rc_file}"
    ok "Removed PATH entry from ${rc_file}"
  fi
}

step "Cleaning up shell config"
remove_from_rc "${HOME}/.zshrc"
remove_from_rc "${HOME}/.bashrc"
remove_from_rc "${HOME}/.bash_profile"

FISH_CONFIG="${HOME}/.config/fish/config.fish"
if [ -f "${FISH_CONFIG}" ] && grep -q '\.snag/bin' "${FISH_CONFIG}" 2>/dev/null; then
  tmp="${FISH_CONFIG}.snag.tmp"
  grep -v '\.snag/bin' "${FISH_CONFIG}" > "${tmp}"
  mv "${tmp}" "${FISH_CONFIG}"
  ok "Removed PATH entry from ${FISH_CONFIG}"
fi

# ── Done ───────────────────────────────────────────────────────────────────────

echo
echo -e "  ${GREEN}${BOLD}Snag uninstalled.${RESET}"
echo -e "  Open a new terminal and the ${CYAN}snag${RESET} command will be gone."
echo
