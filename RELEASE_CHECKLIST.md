# Authoritative M25 staging release checklist

Candidate: **ProjectVelocity 0.25.0-rc.1 / build31 / STAGING**. Protocol5, wire4, save5;
Training v8 and Foundry v7. This checklist gates review artifacts only. It cannot authorize a
merge, tag, GitHub Release, Steam/store/CDN publication or a public release.

## Source and supply chain

- [x] Branch created from exact `origin/dev` `1b226dfc8e5efe12209822801554334847770a97`.
- [x] User `project.godot` hash preserved and excluded.
- [x] Godot 4.7.2 official engine/templates pinned to upstream SHA-512 manifest entries.
- [x] Dependencies/licenses inventoried; no new runtime dependency or EOS/vendor binary.
- [ ] Immutable candidate source SHA recorded after commit.
- [ ] Clean tracked-source/credential/save/log/cache/vendor scan passes in CI.
- [ ] Git whitespace and repository-clean checks pass in CI.

## Automated and packaging gates

- [ ] Complete Windows M0–M25 automated validator passes without `continue-on-error`.
- [ ] Independent Linux parser/deterministic/headless matrix passes on Ubuntu 24.04.
- [ ] Windows x86_64 release-template export, resource/package audit and clean extraction pass.
- [ ] Windows isolated headless plus 1280×720, 1280×800 and 1920×1080 normal smokes pass.
- [ ] Linux x86_64 release-template export, permissions, `ldd`, extraction, headless and Xvfb pass.
- [ ] SteamOS-compatible tar layout/launcher/permissions pass on Linux.
- [ ] Uploaded artifacts exist, are non-empty, download successfully and pass `SHA256SUMS`.
- [ ] Both platforms embed the same source/version/channel/protocol/wire/save/map identity.
- [ ] Export denies tests/dev_tools/docs/builds/.tools/.git/.github, saves/logs/credentials/vendor files.
- [ ] Release export refuses developer ENet tooling; production Online stays unavailable cleanly.

## Manual and external gates

- [ ] Developer completes every applicable row in `M25_MANUAL_QA.md` against exact hashes.
- [ ] Windows clean-machine package review passes.
- [ ] Linux target-distro package review passes.
- [ ] Physical keyboard/mouse and controller/hotplug review passes.
- [ ] Physical Steam Deck/SteamOS runtime, 1280×800 UI/gamepad and performance review passes.
- [ ] Approved low-end GTX1050Ti/RX570-class 1080p Low performance matrix passes.
- [ ] Production EOS Auth/Connect/Lobby/P2P/Internet gate passes, or master scope is explicitly changed.
- [ ] Signing/installer/distribution decision is made separately; current binaries remain unsigned.
- [ ] Developer explicitly approves or rejects the candidate.

Current verdict: **NO-GO for release; staging automation in progress.** Once automated rows pass,
the maximum truthful status is **READY FOR MANUAL REVIEW** until the unchecked external rows are
resolved. Never convert PENDING/BLOCKED to PASS from synthetic, loopback, CI or prior-milestone
evidence outside its actual scope.
