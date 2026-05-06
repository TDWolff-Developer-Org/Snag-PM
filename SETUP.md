# Snag — Setup Guide

Everything you need to go from this repo to a live, installable package manager.

---

## Step 1 — Fork or clone this repo

```bash
git clone https://github.com/YOUR_TDWolff-Developer-Org/Snag-PM.git
cd snag
```

## Step 2 — Replace TDWolff-Developer-Org with your GitHub TDWolff-Developer-Org

Search for `TDWolff-Developer-Org` in these files and replace with your actual GitHub TDWolff-Developer-Org:

```
bin/snag         (REGISTRY_URL and SNAG_RAW_URL constants)
install.sh       (SNAG_URL and REGISTRY_URL variables)
Formula/registry.json  (all "url" fields)
README.md        (install command)
```

One-liner to do all of them at once (macOS):

```bash
grep -rl "TDWolff-Developer-Org" . --include="*.rb" --include="*.sh" --include="*.json" --include="*.md" \
  | xargs sed -i '' 's/TDWolff-Developer-Org/YOUR_GITHUB_TDWolff-Developer-Org/g'
```

Linux:

```bash
grep -rl "TDWolff-Developer-Org" . --include="*.rb" --include="*.sh" --include="*.json" --include="*.md" \
  | xargs sed -i 's/TDWolff-Developer-Org/YOUR_GITHUB_TDWolff-Developer-Org/g'
```

## Step 3 — Build the example packages

```bash
ruby build.rb
```

This creates `dist/hello-1.0.0.tar.gz`, `dist/quickserve-1.0.0.tar.gz`, and
`dist/colorcat-1.0.0.tar.gz`, then writes the real SHA256 hashes back into
`Formula/registry.json`.

## Step 4 — Create GitHub Releases and upload tarballs

For each package, create a release tagged `<name>-<version>`:

```bash
# Using the GitHub CLI (gh):
gh release create hello-1.0.0     --title "hello 1.0.0"     dist/hello-1.0.0.tar.gz
gh release create quickserve-1.0.0 --title "quickserve 1.0.0" dist/quickserve-1.0.0.tar.gz
gh release create colorcat-1.0.0   --title "colorcat 1.0.0"   dist/colorcat-1.0.0.tar.gz
```

Or do it manually on github.com → your repo → Releases → Draft a new release.

**Important:** The tag name must exactly match the tag in the registry URL, e.g.
`hello-1.0.0` for
`https://github.com/YOU/snag/releases/download/hello-1.0.0/hello-1.0.0.tar.gz`.

## Step 5 — Commit and push

```bash
git add Formula/registry.json
git commit -m "Add real SHA256 hashes for initial packages"
git push
```

## Step 6 — Test the install

In a fresh terminal (or a VM):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_TDWolff-Developer-Org/Snag-PM/main/install.sh)"
source ~/.zshrc   # or ~/.bashrc
snag list
snag install hello
hello "Snag"
```

---

## Adding a new package

### 1. Write the script

Create `examples/<name>/<name>`. It can be any language — just make sure it
has a valid shebang (`#!/usr/bin/env ruby`, `#!/usr/bin/env bash`, etc.).

```
examples/
└── mytool/
    └── mytool     ← your script
```

### 2. Register it

Add an entry to `Formula/registry.json`:

```json
"mytool": {
  "name": "mytool",
  "version": "1.0.0",
  "description": "Does something useful",
  "homepage": "https://github.com/YOUR_TDWolff-Developer-Org/Snag-PM",
  "url": "https://github.com/YOUR_TDWolff-Developer-Org/Snag-PM/releases/download/mytool-1.0.0/mytool-1.0.0.tar.gz",
  "sha256": "PLACEHOLDER"
}
```

### 3. Build it

```bash
ruby build.rb mytool
```

This updates the `sha256` in `registry.json` and writes `dist/mytool-1.0.0.tar.gz`.

### 4. Release it

```bash
gh release create mytool-1.0.0 --title "mytool 1.0.0" dist/mytool-1.0.0.tar.gz
```

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

1. Update the script in `examples/<name>/`
2. Bump `"version"` in `registry.json`
3. Run `ruby build.rb <name>`
4. Upload the new tarball to a new GitHub Release with the updated tag
5. Commit the updated `registry.json`

Users get the update by running `snag update && snag install <name>`.

---

## Repo structure reference

```
.
├── bin/snag               Ruby CLI — the package manager itself
├── install.sh             One-line installer (curl | bash)
├── build.rb               Packages examples → dist/, updates SHA256
├── Formula/
│   └── registry.json      Package registry (source of truth)
├── examples/
│   ├── hello/hello        Example: greeting script
│   ├── quickserve/quickserve  Example: HTTP file server
│   └── colorcat/colorcat  Example: syntax-highlighting cat
├── dist/                  Built .tar.gz files (git-ignored)
└── README.md
```
