# Security and release data handling

Report a suspected vulnerability privately to the repository owner; do not place credentials,
tokens, account identifiers, private crash logs or exploit details in public issues or artifacts.

ProjectVelocity stores saves and rotating diagnostics locally and has no automatic telemetry,
crash-report or log upload. Production Online is unavailable while the EOS gate is blocked. The
six-character future lobby code is not an authentication secret. Network authority rejects client
transform/Finish claims, but local ENet testing is not Internet security evidence.

Release CI uses `contents: read`, immutable action commits, bounded jobs and official Godot files
verified against the upstream SHA-512 manifest. Packaging rejects credentials, saves, logs, cache,
test/dev content and EOS/vendor binaries. Live EOS secrets must never be passed to pull-request
code, chat, CLI arguments, screenshots or artifacts. See the M19 reports for the protected future
acceptance boundary.

M25 artifacts are unsigned portable candidates. Verify SHA-256 before execution and follow OS or
organizational warnings; do not disable security controls. Signing credentials, installers,
release tags and public/store publication require a separate developer-authorized process.
