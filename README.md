# Snag

A simple, Homebrew-inspired package manager written in Ruby.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/TDWolff-Developer-Org/Snag/refs/heads/latest/install.sh)"
```

## Features

- Installs packages to `~/.snag/Cellar/` (same layout as Homebrew)
- Symlinks executables to `~/.snag/bin/`
- Downloads packages from GitHub Releases
- SHA256 verification on every download
- Colored output and friendly error messages
- Self-updating via `snag update`
- Zero dependencies beyond Ruby's standard library

## Requirements

- Ruby 2.7+ (macOS ships with Ruby; install via `brew install ruby` for a newer version)
- `tar` (pre-installed on macOS and Linux)
- `curl` (pre-installed on macOS and Linux)

## Installation

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/TDWolff-Developer-Org/Snag/latest/install.sh)"
```

The installer:
1. Creates `~/.snag/` with `bin/` and `Cellar/` subdirectories
2. Downloads `snag` to `~/.snag/bin/snag`
3. Adds `~/.snag/bin` to `PATH` in your shell config
4. Fetches the package registry

Reload your shell or run `source ~/.zshrc` (or `~/.bashrc`), then try:

```bash
snag list
snag install hello
hello
```

## Usage

```
snag <command> [package]
```

| Command | Description |
|---|---|
| `snag install <package>` | Download and install a package |
| `snag uninstall <package>` | Remove an installed package |
| `snag list` | List all available packages |
| `snag installed` | Show installed packages |
| `snag search <query>` | Search packages by name or description |
| `snag info <package>` | Show package details and SHA256 |
| `snag update` | Refresh registry + self-update snag |
| `snag version` | Print version and paths |
| `snag help` | Show help |

### Examples

```bash
# Install a package
snag install quickserve

# Serve the current directory on port 3000
quickserve -p 3000

# Install colorcat and use it
snag install colorcat
colorcat myfile.rb

# Check what's installed
snag installed

# Remove a package
snag uninstall hello

# Update everything
snag update
```

## How it works

### Directory layout

```
~/.snag/
├── bin/               ← symlinks to installed executables (add to PATH)
├── Cellar/
│   ├── hello/
│   │   └── 1.0.0/
│   │       └── bin/
│   │           └── hello
│   └── quickserve/
│       └── 1.0.0/
│           └── bin/
│               └── quickserve
└── registry.json      ← local copy of the package registry
```

### Package format

Each package is a `.tar.gz` archive hosted on GitHub Releases. Inside:

```
hello-1.0.0/
└── bin/
    └── hello      ← the executable(s)
```

`snag install` downloads the archive, verifies the SHA256, extracts it to
`~/.snag/Cellar/<name>/<version>/`, then symlinks every file in `bin/` to
`~/.snag/bin/`.

### Registry

The registry lives at `Formula/registry.json` in this repo and is fetched to
`~/.snag/registry.json` by `snag update`. Each entry looks like:

```json
{
  "name": "hello",
  "version": "1.0.0",
  "description": "A friendly greeting program",
  "homepage": "https://github.com/TDWolff-Developer-Org/Snag",
  "url": "https://github.com/TDWolff-Developer-Org/Snag/releases/download/hello-1.0.0/hello-1.0.0.tar.gz",
  "sha256": "abc123..."
}
```

## Included packages

| Package | Description |
|---|---|
| `hello` | Classic Hello, World! greeting program |
| `quickserve` | Instantly serve any directory over HTTP |
| `colorcat` | `cat` with syntax highlighting for Ruby, Python, JS, Shell, JSON |

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
│   ├── hello/hello
│   ├── quickserve/quickserve
│   └── colorcat/colorcat
├── Formula/
│   └── registry.json      ← package registry
├── dist/                  ← built tarballs (git-ignored)
├── build.rb               ← packaging helper script
└── install.sh             ← one-line installer
```

## Uninstalling Snag

```bash
rm -rf ~/.snag
```

Then remove the `~/.snag/bin` line from your shell config (`~/.zshrc` or `~/.bashrc`).

## License

MIT — see [LICENSE](LICENSE).
