# Testing checklist

M0 completion record (2026-09-06); details and CI links in docs/M0_VALIDATION.md.

- [x] Exact Godot 4.7.2 Stable detected.
- [x] Clean editor import and every GDScript parse without errors/warnings.
- [x] Integration assertions: 60 Hz, renderer/aspect, version consistency, config load, build flag, logger formatting, English/Russian translations and watermark.
- [x] Actual main scene smoke prints PROJECTVELOCITY_BOOT_OK and exits zero.
- [x] Graphical editor startup and real-renderer main scene; inspect captured logs and readable placeholder screenshot.
- [x] Windows staging export and exported executable smoke pass in CI.
- [x] Git staged/unstaged whitespace checks; caches/logs/exports ignored.
- [x] First GitHub Actions run passes and staging artifact is available.

For subsequent changes run dev_tools/validate.ps1 before committing. Run with -ExportWindows when matching export templates are available. Review failure logs, never rely solely on the Godot exit code.

Headless success does not prove target-hardware performance, Steam Deck behavior or visual appearance. Release-mode exports require developer review and are not part of these M0 results.
