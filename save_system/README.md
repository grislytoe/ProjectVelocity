# Save system

SaveSchema validates JSON-compatible data and migrates sequential versions without I/O. SaveStore loads, stages, backs up and recovers data using an injected directory. The default is user://saves; tests must supply isolated paths. See ../SAVE_FORMAT.md for the complete version 1 contract and recovery policy.
