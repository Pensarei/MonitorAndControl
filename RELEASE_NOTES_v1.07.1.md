# 1.7.1 — NEW: screen time inside the dashboard

- Integrated Windows account selection, daily limits and today's bonus into the existing sidebar and visual components.
- Removed the external configuration window and browser-launched executable.
- Added a local, bounded service protocol with Windows administrator credential validation, caller throttling and origin/host checks.
- Preserved per-account protected counters and existing app/group behavior.
- Added authorization, protocol and HTTP boundary tests; 38 automated tests pass.
- Browser interaction checked with simulated accounts only. Real Windows credentials, upgrade and logoff still require acceptance testing.
