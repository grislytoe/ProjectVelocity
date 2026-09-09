# Audio foundation — M12

SettingsRuntime creates Master, Music, SFX, UI and Ambience AudioServer buses. All child
buses send to Master. Independent linear levels and mutes are applied on startup/Apply;
zero is silent with a finite dB floor. UI buttons and player jump/dash/death use a quiet
procedural placeholder. MenuMusic/LevelMusic route to Music; Ambience is an empty slot.
Final audio production is intentionally deferred. See ../SETTINGS.md and ../SAVE_FORMAT.md.
