# Known issues

- M1 implements local profile/persistence foundations only. Gameplay, menus, service adapters, input-device detection, binding application, settings UI, audio buses and networking remain deferred. M2 has not started.
- Saves assume one application writer; simultaneous instances are not coordinated. Flush plus same-directory rename does not guarantee durability under every power-loss/filesystem scenario.
- Recovery is exposed through localized notification state for future UI; no recovery dialog or persistent notification queue is implemented.
- Unsupported versions open read-only and require a compatible application version; no downgrade is attempted.
- Quarantined corrupt saves and interrupted test cache directories are retained for diagnosis; automatic retention/cleanup policy is deferred.
- Target-hardware performance, Linux export and Steam Deck validation remain future work.
- Local Windows export templates are not installed; CI performs Windows staging export and executable boot with pinned official templates.
