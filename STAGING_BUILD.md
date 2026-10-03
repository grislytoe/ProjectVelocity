# Verify and run the M25 staging build

Use only an artifact attached to the M25 CI run for the exact candidate source SHA. The package is
unsigned and intended for developer review. Do not redistribute it as a release.

## Verify

Download the platform artifact, `staging-manifest.json` and `SHA256SUMS` together. Compare the
source SHA/version/build/channel in the manifest with the PR and manual QA sheet.

Windows PowerShell:

```powershell
Get-FileHash -Algorithm SHA256 .\ProjectVelocity-0.25.0-rc.1-build31-windows-x86_64.zip
Get-Content .\SHA256SUMS
```

Linux/SteamOS:

```sh
sha256sum -c SHA256SUMS
```

`SHA256SUMS` also covers the contained executable/PCK and manifest. A mismatch is a hard stop.

## Windows x86_64

Extract the ZIP to a new writable directory; do not run from inside the archive. Start
`ProjectVelocity.exe`. Windows may warn because the staging binary is intentionally unsigned;
follow organizational security policy and do not disable or bypass OS protections. The UI must
show `STAGING`. No installer, service, registry dependency, Steam client or EOS runtime is needed.

## Linux x86_64

Extract while preserving permissions, then use the launcher:

```sh
tar -xzf ProjectVelocity-0.25.0-rc.1-build31-linux-x86_64.tar.gz
cd ProjectVelocity-0.25.0-rc.1-build31-linux-x86_64
./run-projectvelocity.sh
```

CI validates Ubuntu 24.04 headless and Xvfb Compatibility startup plus `ldd` with no missing
libraries. That is the verified distro scope; it is not a general claim for every Linux distro.

## SteamOS-compatible package

The SteamOS tar contains the same Linux x86_64 standalone content and safe launcher. It does not
need Steam, Steamworks or a Steam client. Add `run-projectvelocity.sh` as a non-Steam shortcut if
desired. Physical Steam Deck/SteamOS runtime, controller prompts and performance remain pending;
the package label means layout/command-line compatibility, not hardware certification.

## Data and offline behavior

First launch creates local versioned data under Godot's ProjectVelocity user directory. Back up
existing data before manual testing or use a fresh OS account. Automated package smokes use unique
temporary APPDATA/LOCALAPPDATA or XDG roots and never open the real save. The game starts offline
without Steam/EOS/network. Online displays a localized unavailable state and must not crash.

Logs stay local and are never automatically uploaded. Do not attach logs without reviewing them
for personal paths. Use `M25_MANUAL_QA.md` for approval; passing CI alone does not approve release.
