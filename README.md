# ProjectVelocity

Competitive high-speed 2D racing platformer, built with Godot **4.7.2 Stable** and typed GDScript.

M0 establishes the engineering foundation; M1 adds persistent profiles, validated versioned JSON, migrations and backup recovery. The main scene remains a translated placeholder with a DEV/STAGING label. No gameplay or online services are implemented. See SAVE_FORMAT.md for the persistence contract.

Open `project.godot` in Godot 4.7.2 and press F6/F5 to run the main scene. See [BUILD_AND_RUN.md](BUILD_AND_RUN.md) for reproducible validation and staging export.

- [Architecture and directory map](ARCHITECTURE.md)
- [Coding standards](CODING_STANDARDS.md)
- [Test checklist](TESTING_CHECKLIST.md)
- [Known issues](KNOWN_ISSUES.md)
- [Next steps](NEXT_STEPS.md)

Primary targets: Windows x64, Linux x64, SteamOS/Steam Deck. Initial CI exports Windows staging only.
