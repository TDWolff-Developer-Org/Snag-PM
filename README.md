# Snag

A simple, Homebrew-inspired package manager written in Ruby. Runs on **macOS** and **Linux**.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/TDWolff-Developer-Org/Snag/refs/heads/latest/install.sh)"
```

## Supported Platforms

| OS | Architectures |
|---|---|
| macOS | `arm64`, `x86_64` |
| Linux | `x86_64`, `arm64` |

`snag version` prints the detected platform (e.g. `snag 1.0.3 [linux-x86_64]`). Per-package binaries can be published per platform via the `platforms` key in the registry — script packages stay universal.

## Features

- Installs packages to `~/.snag/Cellar/` (same layout as Homebrew)
- Symlinks executables to `~/.snag/bin/`
- Downloads packages from GitHub Releases
- SHA256 verification on every download
- Colored output and friendly error messages
- Self-updating via `snag update`
- **Venvs** — isolated environments per project (`snag venv new myproject`)
- Zero dependencies beyond Ruby's standard library

## Requirements

- Ruby 2.7+
  - **macOS:** ships with Ruby; install a newer version via `brew install ruby`
  - **Linux (Ubuntu/Debian):** `sudo apt install ruby curl`
  - **Linux (Fedora/RHEL):** `sudo dnf install ruby curl`
  - **Linux (Arch):** `sudo pacman -S ruby curl`
- `tar` (pre-installed on macOS and Linux)
- `curl` (pre-installed on macOS, install above on minimal Linux)

## Installation

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/TDWolff-Developer-Org/Snag/refs/heads/latest/install.sh)"
```

> **Note:** On minimal Linux systems, the `myip` package's Wi-Fi SSID detection requires `nmcli` (NetworkManager) or `iwgetid` (wireless-tools). Both are gracefully skipped if missing — public IP, local IPs, and DNS still work.

The installer:
1. Creates `~/.snag/` with `bin/`, `Cellar/`, and `venvs/` subdirectories
2. Downloads `snag` to `~/.snag/bin/snag`
3. Adds `~/.snag/bin` to `PATH` and installs the venv shell function in your shell config
4. Fetches the package registry

Reload your shell or run `source ~/.zshrc` (or `~/.bashrc`), then try:

```bash
snag install myip
myip
```

## Usage

```
snag <command> [package]
```

| Command | Description |
|---|---|
| `snag install <package>` | Download and install a package |
| `snag install <package>@<version>` | Pin a specific version |
| `snag uninstall <package>` | Remove an installed package |
| `snag upgrade [package]` | Upgrade one package or all installed packages |
| `snag outdated` | Show installed packages with newer versions available |
| `snag list` | List installed packages |
| `snag search <query>` | Search packages by name or description |
| `snag info <package>` | Show package details, version, and SHA256 |
| `snag alias <package> <name>` | Create a short alias for an installed binary |
| `snag alias` | List all aliases |
| `snag unalias <name>` | Remove an alias |
| `snag update` | Refresh registry, self-update snag, and upgrade installed packages |
| `snag doctor` | Check your snag installation for problems |
| `snag venv new <name>` | Create a new isolated environment |
| `snag venv activate <name>` | Activate a venv (updates PATH, routes all snag commands to the venv) |
| `snag venv deactivate` | Deactivate the current venv |
| `snag venv list` | List all venvs |
| `snag venv rm <name>` | Remove a venv |
| `snag venv install-shell` | Install the venv shell function into your shell config |
| `snag self-uninstall` | Completely remove snag from this machine (double-confirm prompt) |
| `snag version` | Print version, platform, and paths |
| `snag help` | Show help |

If you typo a package name (e.g. `snag install snadtools`), snag suggests the closest match.

### Examples

```bash
# Install a package
snag install myip

# Run it
myip

# Install a developer toolkit
snag install snagtools
snagtools cat myfile.rb         # syntax-highlighted file viewer
snagtools json --validate x.json
snagtools hex /usr/bin/ruby

# Pin a specific version
snag install snagtools@1.0.1

# See what's installed
snag list

# See what has updates available
snag outdated

# Upgrade everything that's outdated
snag upgrade

# Refresh registry, self-update snag, and upgrade all in one go
snag update

# Remove a single package
snag uninstall myip

# Create an isolated environment for a project
snag venv new myproject
snag venv activate myproject
snag install ripgrep           # installs into myproject venv only
snag list                      # shows only myproject's packages
snag venv deactivate           # back to global environment

# Wipe snag completely (double-confirm prompt)
snag self-uninstall
```

## How it works

### Directory layout

```
~/.snag/
├── bin/               ← symlinks to installed executables (add to PATH)
├── Cellar/
│   ├── myip/
│   │   └── 1.0.1/
│   │       └── bin/
│   │           └── myip
│   └── snagtools/
│       └── 1.0.1/
│           └── bin/
│               └── snagtools
├── venvs/             ← isolated environments (see snag venv)
│   └── myproject/
│       ├── bin/       ← venv's own symlinks (prepended to PATH when active)
│       ├── Cellar/    ← venv's own package installs
│       └── installed.json
└── registry.json      ← local copy of the package registry
```

### Package format

Each package is a `.tar.gz` archive hosted on GitHub Releases. Inside:

```
myip-1.0.1/
└── bin/
    └── myip          ← the executable(s)
```

`snag install` downloads the archive, verifies the SHA256, extracts it to
`~/.snag/Cellar/<name>/<version>/`, then symlinks every file in `bin/` to
`~/.snag/bin/`.

### Registry

The registry lives at `Formula/registry.json` in this repo and is fetched to
`~/.snag/registry.json` by `snag update`. The top-level `snag_version` field
drives self-updates of the snag binary itself. A script-style entry looks like:

```json
{
  "name": "myip",
  "version": "1.0.1",
  "description": "Detailed local and public IP info",
  "homepage": "https://github.com/TDWolff-Developer-Org/Snag",
  "url": "https://github.com/TDWolff-Developer-Org/Snag/releases/download/myip-1.0.1/myip-1.0.1.tar.gz",
  "sha256": "abc123..."
}
```

A binary package with per-platform builds uses a `platforms` map instead of
top-level `url`/`sha256`:

```json
{
  "name": "mytool",
  "version": "1.0.0",
  "description": "...",
  "platforms": {
    "darwin-arm64":  { "url": "...", "sha256": "..." },
    "darwin-x86_64": { "url": "...", "sha256": "..." },
    "linux-x86_64":  { "url": "...", "sha256": "..." },
    "linux-arm64":   { "url": "...", "sha256": "..." }
  }
}
```

## Adding your own package

See [SETUP.md](SETUP.md) for a full walkthrough.

Quick version:
1. Create `examples/<name>/<name>` (your script/binary)
2. Add an entry to `Formula/registry.json`
3. Run `ruby build.rb <name>` to produce the tarball and SHA256
4. Upload the tarball to a GitHub Release tagged `<name>-<version>`
5. Commit the updated `registry.json` and push

## Repository layout

```
.
├── bin/
│   └── snag               ← the CLI itself
├── examples/
│   ├── myip/myip
│   └── snagtools/snagtools
├── Formula/
│   └── registry.json      ← package registry (with snag_version)
├── dist/                  ← built tarballs (git-ignored)
├── build.rb               ← packaging helper script
├── install.sh             ← one-line installer
└── uninstall.sh           ← bash uninstaller (alternative to `snag self-uninstall`)
```

## Uninstalling Snag

The clean way (built into snag, with a double-confirm prompt):

```bash
snag self-uninstall
```

Or run the bash uninstaller from the repo:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/TDWolff-Developer-Org/Snag/refs/heads/latest/uninstall.sh)"
```

Either method removes `~/.snag` and strips the `~/.snag/bin` PATH entry from your shell config.

## License

CC0-1.0 — see [LICENSE](LICENSE).
