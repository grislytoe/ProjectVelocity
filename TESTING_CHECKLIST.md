# Testing checklist

Run dev_tools/validate.ps1 before committing. Run with -ExportWindows when matching export templates are available.

- [ ] Exact Godot 4.7.2 Stable detected.
- [ ] Clean editor import and every GDScript parse without errors/warnings.
- [ ] Integration assertions: 60 Hz, renderer/aspect, version consistency, config load, build flag, logger formatting, English/Russian translations and watermark.
- [ ] Actual main scene smoke test prints PROJECTVELOCITY_BOOT_OK and exits zero.
- [ ] Windowed editor/main scene smoke; check layout, readable localized text and debugger output.
- [ ] Windows staging export and exported executable smoke pass.
- [ ] Git diff whitespace validation; generated caches/logs/exports ignored.
- [ ] First GitHub Actions run passes and staging artifact is available.

Headless success does not prove GPU performance, Steam Deck behavior or manual UI appearance. See docs/M0_VALIDATION.md for actual completed checks and outstanding acceptance.
