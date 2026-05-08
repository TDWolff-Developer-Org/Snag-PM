# shortcut

Create a Linux `.desktop` start-menu entry from the command line.

```
shortcut <exec_path> <name> [icon_path]
```

- `exec_path` — path to the program to launch (resolved to an absolute path)
- `name` — display name in the application launcher
- `icon_path` — optional, path to an icon image (resolved to an absolute path; skipped with a warning if not found)

The entry is written to `~/.local/share/applications/<sanitized-name>.desktop`. Most modern desktops (GNOME, KDE, XFCE, Cinnamon) watch that directory and show the entry within seconds. On older setups you may need:

```bash
update-desktop-database ~/.local/share/applications
```

## Examples

```bash
shortcut /usr/bin/firefox "Firefox Browser"
shortcut /opt/myapp/bin/myapp "My App" /opt/myapp/icon.png
```

## Building locally

The package ships precompiled via the [`build-shortcut` GitHub Action](../../.github/workflows/build-shortcut.yml) — no local toolchain required to ship a release. To iterate on the source on a Linux box (or in a Linux container):

```bash
gcc -O2 -o shortcut shortcut.c
./shortcut /usr/bin/nano "Nano Editor"
```

The source is C99, single-file, libc-only — no external dependencies.

## Releasing a new version

1. Bump the `1.0.0` tag references in [Formula/registry.json](../../Formula/registry.json) (or hand-edit after CI prints the new SHAs).
2. Tag and push:
   ```bash
   git tag shortcut-1.0.1
   git push --tags
   ```
3. CI compiles for `linux-x86_64` and `linux-arm64`, attaches the tarballs to a GitHub Release named `shortcut-1.0.1`, and prints the SHA256s in the run log.
4. Paste the SHAs into `Formula/registry.json` (or merge the auto-PR if the workflow opens one).
