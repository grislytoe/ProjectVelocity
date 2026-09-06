# Dependencies

| Component | Version | Source | License / redistribution | Status |
| --- | --- | --- | --- | --- |
| Godot engine and official export templates | 4.7.2 Stable | https://godotengine.org/download/archive/4.7.2-stable/ | MIT; commercial Steam and free standalone redistribution permitted with required notices | Engine installed; export templates required for staging export |
| Git | Environment-installed 2.55.0.windows.5 | https://git-scm.com/ | GPL-2.0; development tool, not bundled | Existing tool |
| PowerShell | Host / GitHub runner version | https://github.com/PowerShell/PowerShell | MIT for PowerShell 7; Windows PowerShell is OS tooling, not bundled | Validation tooling |
| actions/checkout | v4.2.2, 11bd71901bbe5b1630ceea73d27597364c9af683 | https://github.com/actions/checkout | MIT; CI only, not bundled | CI |
| actions/upload-artifact | v4.6.2, ea165f8d65b6e75b540449e92b4886f43607fa02 | https://github.com/actions/upload-artifact | MIT; CI only, not bundled | CI |

EOSG 2.3.0 is the approved future integration candidate, **not installed or validated**. Its license, redistribution terms and compatibility across Windows/Linux/SteamOS must be recorded and smoke-tested before production integration. Do not replace it without developer approval.

No other third-party runtime dependency or art asset is introduced in M0. Record justification, exact version, source, license and commercial/free redistribution compatibility before adding dependencies. Godot redistribution notices: https://godotengine.org/license/
