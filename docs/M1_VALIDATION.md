# M1 validation evidence

Base: approved dev 1a1f4f3e702603baac100ba901dd50c92b39b85d.
Branch: feature/m1-core-data-save. Date: 2026-09-06.

Local Godot 4.7.2 validation passed:
- Editor import and all GDScript parser checks.
- Existing M0 bootstrap tests.
- M1 persistence suite: 139 checks (profile, nickname, JSON, backup/recovery, schema, migration, language and failure preservation).
- Main-scene headless startup with isolated save creation.
- No real-user save path is used by tests or startup smoke checks.

Clean staged-snapshot validation also passed (fresh .godot cache, M0 and all 139 M1 checks). Normal-renderer OpenGL Compatibility startup on AMD Radeon Graphics printed PROJECTVELOCITY_BOOT_OK and exited zero with no errors/warnings. Staged whitespace review passed, and no user saves or secrets were staged. CI runs the same M0 + M1 suite plus Windows staging export and executable boot. Remote CI evidence will be linked in the M1 PR once available.

Schema version is 1. Version 0 is an explicitly synthetic pre-release migration fixture, not evidence of a previously shipped schema. No M2, gameplay, network, SDK or third-party dependency work was performed.
