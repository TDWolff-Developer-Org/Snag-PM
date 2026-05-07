# Snag — Setup Guide

How to add a new package to Snag, bump an existing one, or fork the project to run your own registry.

---

## Adding a new package

### 1. Write the script

Create `examples/<name>/<name>`. It can be any language — just give it a valid shebang (`#!/usr/bin/env ruby`, `#!/usr/bin/env bash`, etc.) and make it self-contained.

```
examples/
└── mytool/
    └── mytool     ← your script (or compiled binary)
```

### 2. Register it

Add an entry to `Formula/registry.json`:

```json
"mytool": {
  "name": "mytool",
  "version": "1.0.0",
  "description": "Does something useful",
  "homepage": "https://github.com/TDWolff-Developer-Org/Snag",
  "url": "https://github.com/TDWolff-Developer-Org/Snag/releases/download/mytool-1.0.0/mytool-1.0.0.tar.gz",
  "sha256": "PLACEHOLDER"
}
```

For a compiled binary that ships per-platform, use the `platforms` map instead of top-level `url`/`sha256`:

```json
"mytool": {
  "name": "mytool",
  "version": "1.0.0",
  "description": "...",
  "platforms": {
    "darwin-arm64":  { "url": "...", "sha256": "PLACEHOLDER" },
    "darwin-x86_64": { "url": "...", "sha256": "PLACEHOLDER" },
    "linux-x86_64":  { "url": "...", "sha256": "PLACEHOLDER" },
    "linux-arm64":   { "url": "...", "sha256": "PLACEHOLDER" }
  }
}
```

### 3. Build the tarball

```bash
ruby build.rb mytool
```

This writes `dist/mytool-1.0.0.tar.gz` and replaces the `PLACEHOLDER` SHA256 in `registry.json` with the real hash. Reproducible builds are enforced by normalizing file timestamps before archiving — running `build.rb` twice produces byte-identical tarballs and SHAs.

### 4. Create the GitHub Release and upload

```bash
gh release create mytool-1.0.0 dist/mytool-1.0.0.tar.gz --title "mytool 1.0.0"
```

> **Important:** Tag name must exactly match the URL in the registry (`mytool-1.0.0` for `.../releases/download/mytool-1.0.0/mytool-1.0.0.tar.gz`). And **never** reuse a tag — GitHub's release CDN caches asset bytes by URL forever. If the tarball needs changing, bump the version.

### 5. Push and verify

```bash
git add Formula/registry.json examples/mytool/
git commit -m "Add mytool 1.0.0"
git push

snag update
snag install mytool
```

---

## Bumping a package version

1. Edit the script in `examples/<name>/<name>` and bump any internal version constants
2. Bump `"version"` for that package in `Formula/registry.json`
3. Run `ruby build.rb <name>` to rebuild and refresh the SHA
4. Create a **new** GitHub Release with the new tag (never reuse old tags)
5. Commit + push the registry change

Users get the update via `snag update` (the next run will detect the version change and reinstall the package automatically).

---

## Bumping snag itself

When you change `bin/snag`:

1. Bump `SNAG_VERSION` in `bin/snag`
2. Bump the top-level `snag_version` in `Formula/registry.json` to the same value
3. Commit + push

`snag update` checks the registry's `snag_version` against the running binary's `SNAG_VERSION` constant. If they differ, it downloads the new `bin/snag` from `raw.githubusercontent.com`. The registry version is the authoritative source — file-content comparison would be unreliable due to GitHub raw CDN caching.

> **CDN heads-up:** the raw URL CDN may take up to ~5 minutes to serve new content after a push. The registry usually updates faster than the binary URL since it's modified more often. Polling one-liner if you're impatient:
> ```bash
> until curl -s https://raw.githubusercontent.com/TDWolff-Developer-Org/Snag/refs/heads/latest/Formula/registry.json | grep -q '"snag_version": "1.2.3"'; do sleep 10; done && echo "✓ CDN updated"
> ```

---

## Forking Snag for your own registry

If you want to use this repo as a template for your own package manager:

### 1. Fork or clone

```bash
git clone https://github.com/TDWolff-Developer-Org/Snag.git my-snag
cd my-snag
```

### 2. Replace the org name everywhere

Find `TDWolff-Developer-Org` in these files and swap with your GitHub org/username:

```
bin/snag             (REGISTRY_URL, SNAG_RAW_URL constants)
install.sh           (SNAG_URL, REGISTRY_URL variables)
uninstall.sh         (no URL refs, but check anyway)
Formula/registry.json (every package "url" + "homepage")
README.md            (install one-liner, etc.)
SETUP.md             (this file)
```

One-liner (works on macOS and Linux because GNU and BSD `grep`/`xargs` agree on these flags):

```bash
grep -rl "TDWolff-Developer-Org" . --include="*.rb" --include="*.sh" --include="*.json" --include="*.md" \
  | while read -r f; do
      tmp="$f.snag.tmp"
      sed 's|TDWolff-Developer-Org|YOUR_ORG|g' "$f" > "$tmp" && mv "$tmp" "$f"
    done
```

### 3. Build your packages, push, release

Follow the "Adding a new package" flow above for each package you ship.

### 4. Test the install

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/Snag/refs/heads/latest/install.sh)"
source ~/.zshrc   # or ~/.bashrc
snag version
snag install <yourpkg>
```

---

## Repo structure reference

```
.
├── bin/snag                  Ruby CLI — the package manager itself
├── install.sh                One-line installer (curl | bash)
├── uninstall.sh              One-line uninstaller (alt to `snag self-uninstall`)
├── build.rb                  Packages examples → dist/, updates SHA256 in registry
├── Formula/
│   └── registry.json         Package registry (source of truth, includes snag_version)
├── examples/
│   ├── myip/myip             Detailed IP info (macOS + Linux)
│   └── snagtools/snagtools   Syntax-highlighted cat / JSON / hex dump
├── dist/                     Built .tar.gz files (git-ignored)
├── README.md
├── USAGE.md                  Developer workflow cheat sheet
└── SETUP.md                  This file
```
