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
error() { echo -e "${RED}✗${RESET} ${1}"; exit 1; }

SNAG_HOME="${HOME}/.snag"
SNAG_BIN="${SNAG_HOME}/bin"
SNAG_CELLAR="${SNAG_HOME}/Cellar"
SNAG_URL="https://raw.githubusercontent.com/TDWolff-Developer-Org/Snag-PM/latest/bin/snag"
REGISTRY_URL="https://raw.githubusercontent.com/TDWolff-Developer-Org/Snag-PM/latest/Formula/registry.json"

echo
echo -e "  ${CYAN}${BOLD}Snag${RESET} — simple package manager"
echo -e "  ${BOLD}https://github.com/TDWolff-Developer-Org/Snag-PM${RESET}"
echo

# ── Requirements ───────────────────────────────────────────────────────────────

step "Checking requirements"

if ! command -v ruby &>/dev/null; then
  error "Ruby is required but not found. Install Ruby from https://www.ruby-lang.org and try again."
fi
ok "Ruby found: $(ruby --version)"

if ! command -v curl &>/dev/null; then
  error "curl is required but not found."
fi
ok "curl found"

# ── Directories ────────────────────────────────────────────────────────────────

step "Setting up ~/.snag directory structure"
mkdir -p "${SNAG_BIN}" "${SNAG_CELLAR}"
ok "Created ${SNAG_HOME}"

# ── Download snag binary ───────────────────────────────────────────────────────

step "Downloading snag"
if curl -fsSL "${SNAG_URL}" -o "${SNAG_BIN}/snag"; then
  chmod +x "${SNAG_BIN}/snag"
  ok "snag installed to ${SNAG_BIN}/snag"
else
  error "Failed to download snag from ${SNAG_URL}"
fi

# ── PATH configuration ─────────────────────────────────────────────────────────

PATH_LINE='export PATH="$HOME/.snag/bin:$PATH"'
COMMENT_LINE='# Snag package manager'

add_to_shell_rc() {
  local rc_file="$1"
  if grep -q '\.snag/bin' "${rc_file}" 2>/dev/null; then
    warn "~/.snag/bin is already in ${rc_file}"
  else
    printf '\n%s\n%s\n' "${COMMENT_LINE}" "${PATH_LINE}" >> "${rc_file}"
    ok "Added ~/.snag/bin to PATH in ${rc_file}"
  fi
}

step "Configuring PATH"
CURRENT_SHELL="$(basename "${SHELL:-bash}")"
case "${CURRENT_SHELL}" in
  zsh)
    add_to_shell_rc "${HOME}/.zshrc"
    ;;
  bash)
    if [[ -f "${HOME}/.bash_profile" ]]; then
      add_to_shell_rc "${HOME}/.bash_profile"
    else
      add_to_shell_rc "${HOME}/.bashrc"
    fi
    ;;
  fish)
    FISH_CONFIG="${HOME}/.config/fish/config.fish"
    mkdir -p "$(dirname "${FISH_CONFIG}")"
    if grep -q '\.snag/bin' "${FISH_CONFIG}" 2>/dev/null; then
      warn "~/.snag/bin is already in ${FISH_CONFIG}"
    else
      echo 'fish_add_path $HOME/.snag/bin' >> "${FISH_CONFIG}"
      ok "Added ~/.snag/bin to fish PATH in ${FISH_CONFIG}"
    fi
    ;;
  *)
    warn "Unknown shell '${CURRENT_SHELL}'. Add the following to your shell config:"
    echo
    echo "    ${PATH_LINE}"
    echo
    ;;
esac

# ── Fetch registry ─────────────────────────────────────────────────────────────

step "Fetching package registry"
if curl -fsSL "${REGISTRY_URL}" -o "${SNAG_HOME}/registry.json" 2>/dev/null; then
  PKG_COUNT=$(ruby -e "require 'json'; puts JSON.parse(File.read('${SNAG_HOME}/registry.json'))['packages'].size" 2>/dev/null || echo "?")
  ok "Registry downloaded (${PKG_COUNT} packages)"
else
  warn "Could not download registry now. Run 'snag update' after installation."
fi

# ── Done ───────────────────────────────────────────────────────────────────────

echo
echo -e "  ${GREEN}${BOLD}Snag installed successfully!${RESET}"
echo
echo -e "  ${BOLD}To use snag right now${RESET} (in this terminal window):"
echo -e "    ${CYAN}export PATH=\"\$HOME/.snag/bin:\$PATH\"${RESET}"
echo
echo -e "  ${BOLD}To make it permanent${RESET}, reload your shell config:"
echo -e "    ${CYAN}source ~/.${CURRENT_SHELL}rc${RESET}   (or open a new terminal)"
echo
echo -e "  Then try:"
echo -e "    ${CYAN}snag list${RESET}"
echo -e "    ${CYAN}snag install hello${RESET}"
echo -e "    ${CYAN}hello${RESET}"
echo
