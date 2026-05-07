# Security Policy

## Supported Versions

Snag self-updates aggressively via `snag update`, so the only version actively maintained is the latest published in `Formula/registry.json` on the `latest` branch. Older versions receive no fixes — please update before reporting an issue against an old build.

| Version           | Supported          |
| ----------------- | ------------------ |
| 1.0.x (latest)    | :white_check_mark: |
| < 1.0.0           | :x:                |

Run `snag version` to see what you're on. Run `snag update` to get current.

## Security Properties

Snag's threat model assumes a malicious network and a trusted maintainer (me). Within that model:

- **HTTPS-only.** Every fetch (registry, snag binary self-update, package tarballs) goes over `https://`.
- **SHA256 verification.** Every package tarball is hashed after download and compared against the SHA256 published in the registry. Mismatched downloads are rejected and the partial install is rolled back.
- **No privilege escalation.** Snag installs everything under `~/.snag/` — no `sudo`, no system paths touched. Removing snag is just `rm -rf ~/.snag` plus a PATH line.
- **No arbitrary code in the registry.** Registry entries are pure JSON; the executable code lives in the verified tarballs.
- **Reproducible package builds.** `build.rb` normalizes file timestamps so a clean rebuild produces a byte-identical tarball and SHA — making any tampering with a release auditable against a fresh build.

The snag binary itself (`bin/snag`) is fetched from `raw.githubusercontent.com` and is **not** SHA-verified on self-update — its integrity rests on the security of GitHub's servers and your TLS connection. If that is unacceptable for your environment, pin a specific commit by manually downloading `bin/snag` and skipping `snag update`.

## Reporting a Vulnerability

If you find a vulnerability — anything from a SHA bypass, a path traversal in the install/uninstall flow, a malicious tarball getting accepted, an injection issue in shell scripts, or a registry entry that misbehaves — please report it privately.

**Preferred:** Open a [GitHub Security Advisory](https://github.com/TDWolff-Developer-Org/Snag/security/advisories/new) on the repo. This keeps the report private until a fix lands.

**Fallback:** Email me at **torin@torinwolff.com** with `[snag-security]` in the subject line.

Please include:

- A description of the issue and which file/command is affected
- Steps to reproduce (or a proof-of-concept)
- Your assessment of impact (e.g., does it require a malicious registry, a network-level attacker, an existing local foothold?)
- Any suggested fix, if you have one

### What to expect

- **Acknowledgement** within 72 hours.
- **Triage update** within 7 days — whether the report is accepted, declined, or needs more info.
- **Fix timeline:** critical issues (RCE, SHA bypass, supply-chain) target a patch within 7 days; other issues target the next release.
- **Credit:** If you'd like to be credited in the release notes/advisory, say so in your report. If you want to stay anonymous, that's fine too.

### Out of scope

These are known limitations, not vulnerabilities:

- Stale content from `raw.githubusercontent.com` CDN cache (timing issue, not a security issue).
- Anything requiring an attacker to already have write access to your `~/.snag/` directory.
- The registry maintainer (me) publishing a malicious package — that's the trust assumption Snag makes. If you're worried about that, audit `Formula/registry.json` and the linked tarballs before installing.
- Issues affecting unsupported versions (see the table above).
