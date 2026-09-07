# Known issues

- M2 implements a reusable input/device layer, not player movement, ability state, pause/restart behavior or a settings UI. M3 has not started.
- No physical controllers were available during M2. Synthetic events and Godot hotplug signals pass tests; real USB/Bluetooth hotplug, platform driver mappings and device-name detection require hardware validation.
- Controller prompt family detection uses names and may need the explicit family override. Prompt descriptors are text/tokens; final glyph art is deferred.
- One InputLayer and one save writer are supported per application. Concurrent processes writing the same save are not coordinated.
- Recovery remains localized state for future UI. Same-directory rename plus flush is not a universal power-loss durability guarantee; unsupported saves stay read-only.
- Quarantined corrupt files and interrupted test-cache folders can remain for diagnosis.
- Linux export, Steam Deck hardware behavior and target-hardware performance are not validated. CI builds Windows staging with official templates.
