# M8 validation evidence

Base: approved dev 6ac7acc3ea727c2df1f447a95d428c60917f2361 (M6 #7 and M7 #8 merged).
Branch feature/m8-platform-modules in C:/Godot Projects/ProjectVelocity; no worktree/copy.
Godot 4.7.2.stable.official.ed1daf0bf, Windows, physics 60 Hz. Build 0.8.0-dev / 9;
save schema 2 and network protocol 1 unchanged.

The complete dev_tools/validate.ps1 passed import, every script parser, M0–M7 tests,
isolated foundation boot, M8 integration, render-rate comparison and whitespace checks.
After review preserved same-tick Dash events on pad launch; targeted parser and M8
tests reran at all three rates and with the normal renderer. M8 now has 34 checks.

M8 covers absolute route speed/waits/reverse/ping-pong/closed-loop/one-shot stop;
invalid speed/waits/direction; upward one-way passage and top landing; horizontal and
vertical rider carry/jump-off; temporary activation, absence, occupied-volume restore
retry and permanent break; real diagonal pad impact interrupting Dash; death/start/Finish
locks; static vs moving/temporary/pad respawn support; and interactions in all four actual
playground stations. M6 checks all 16 station IDs, translations, resets and navigation
while retaining all original movement geometry and exercises.

Unchanged M3 hash: a384c1104e7019e0fd04edd44be816c4db36c703d8d6440ec79f8bb1ff667277.
Unchanged M5 hash: 6640203a07124a35289a00f60d7ab13cb80403f550082bded7a9dea172944fc4.
M8 hash at 30/60/144 FPS and normal-renderer 60 FPS:
0e2e98ba055b78b3f98571fd8f89a3ed75494a959c049de447bcbf57cfb871dd.

Normal OpenGL Compatibility on AMD Radeon Graphics passed all M8 checks. Playground
capture passed ten stations, including all four additions, with Russian HUD and no engine
warnings/errors; local screenshots live in ignored builds/m6-station-12.png through -15.png.
Tests/fixtures never initialize production saves. Local export templates are absent;
the PR CI runs the full validator with official-template Windows staging export and boot.
Consult the PR checks for the result on the submitted SHA.

Manual review scene: C:/Godot Projects/ProjectVelocity/dev_tools/test_playground.tscn,
F6, stations 13–16. F5/staging stays foundation; developer scenes/tests remain excluded.
Human feel/gamepad, Linux/Steam Deck and crushing gameplay are not validated/implemented.
See PLATFORM_MODULES.md and KNOWN_ISSUES.md for authoring limits. User project.godot
editor normalization is retained locally; only the intended version bump enters the commit.
PR merge requires explicit user approval. Next milestone is not started.

Manual review follow-up adds eight motor assertions and two real continuous-surface Dash checks. The checkpoint integration now enters above the former trigger height. Full M0–M8 validation passed at 30/60/144 FPS with all three replay hashes unchanged. Normal OpenGL lifecycle smoke passed 48 checks and its enlarged checkpoint screenshot was inspected. CI records the submitted commit result.
