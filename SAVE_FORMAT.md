# Save format

Not implemented in M0. Bootstrap creates no profile or game save.

Future persistence uses JSON with save_version and migrations. Back up valid data before replacement, restore corrupt primary data from backup, and notify the user if both copies are corrupt. Never silently discard data. Save ownership belongs in save_system/. See the master specification for the required fields.
