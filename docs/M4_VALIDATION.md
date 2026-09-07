# M4 validation evidence

Branch feature/m4-character-presentation is based on merged M3 dev 1734a4fc5674b41484975c61e62d97829dd2490d. Windows / Godot 4.7.2.stable.official.ed1daf0bf; 60 Hz. Build identity is 0.4.0-dev / build 5; save schema 2 and network protocol 1 are unchanged.

The complete dev_tools/validate.ps1 runner includes editor import, individual parser checks, M0 bootstrap, M1 (139 checks), M2 (129), M3 motor (187), restart (6), real body replay (20 checks at each of 30/60/144 FPS), and M4 presentation (75 checks). A fourth 720-tick physical replay deletes the complete presentation child. All four traces have hash a384c1104e7019e0fd04edd44be816c4db36c703d8d6440ec79f8bb1ff667277, matching M3. Main headless boot uses an isolated save; Git whitespace is checked.

Normal OpenGL Compatibility rendering on AMD Radeon Graphics is exercised by dev_tools/character_gallery_smoke.gd and dev_tools/player_presentation_smoke.gd. Ignored screenshots at builds/validation/m4-gallery.png and m3-playground.png cover all 14 pose previews, local/opponent comparison and the playable actor. Visual inspection checks framing, outlines, nickname, transparent effects and module readability. The gallery uses in-memory profile data; no real saves are accessed.

GitHub Actions runs the same full suite plus the official Windows staging export and executable boot. CI results are linked from the M4 PR. Matching export templates are not locally installed. Developer fixtures remain excluded from staging, which retains the foundation main scene.

Manual keyboard M3 movement/reset/Dash feedback was accepted before M4. Physical gamepad, subjective M4 pose review, final art and Linux/Steam Deck behavior remain deferred. Replay equality is scoped to this engine/platform, not a cross-platform lockstep guarantee. No gameplay tuning, networking or M5 implementation is included.
