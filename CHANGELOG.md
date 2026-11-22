# Changelog

## [1.0.6] - 2026-11-22

### Changed

- Bass steps are 0 / +5 / +10 dB at 100 Hz (were 0 / +3 / +6 dB at 120 Hz, too close to
  hear). The mix is trimmed by half the boost so Deep keeps headroom.
- The daemon's safety-net poll runs every 10 s instead of every 2 s.

### Fixed

- A bass click made while the previous one was still being sent is no longer dropped.
- A status update no longer snaps the bass picker back to the old value, or to NaN when
  the field is missing.
- Widget, `install.sh`, `uninstall.sh` and `bin/soundfx` all use the same state dir
  (`$XDG_STATE_HOME/soundfx`, else `~/.local/state/soundfx`).
- The daemon reads PipeWire events unbuffered, so a burst of events is handled at once
  instead of up to 2 s late.
- A corrupt `state.json` or a bad `soundfx bass` argument no longer crashes the CLI or daemon.
- After a change, the CLI waits for the daemon and prints the real status.
- Skipped streams are matched by `node.name` prefix, not by substring, so unrelated apps
  are no longer excluded from surround.
- `install.sh` takes a lock, so several bar instances cannot install at the same time; the
  plugin path is URL-decoded.
- `uninstall.sh` disables the widget first, so it cannot reinstall the backend.

## [1.0.5] - 2026-11-22

### Fixed

- The filter chain no longer pins the output to one machine's sound card; it follows the
  default sink.
- `install.sh` is re-run when the plugin changes (it writes a marker and the widget checks
  it), retries after a failed install, and restarts only the service whose files changed.
- The CLI only signals a PID that is really a soundfx daemon, and the daemon removes its
  PID file on exit.
- Concurrent `on`/`off`/`bass` calls are serialised with a lock, so one cannot undo the other.
- Bass is re-applied whenever a new sink appears (filter chain restarted).
- `status.json` is written only when something changed, not every 2 seconds.
- Choosing the Razer sink as the default no longer marks audio unavailable.
- The HRIR path is substituted without `sed`, so `&`, `#` and `\\` in a path are safe.

## [1.0.4] - 2026-11-22

### Changed

- The Razer HRIR is bundled in `hrir/razer.wav`; `install.sh` copies it into place unless
  one exists already. No manual download.

## [1.0.3] - 2026-11-22

### Changed

- The widget runs `install.sh` itself on first load, so `omarchy plugin add ... --enable`
  is the whole install. If the HRIR file is missing it stops and writes the reason to
  `~/.local/state/soundfx/install.log`.

## [1.0.2] - 2026-11-22

### Added

- `install.sh` / `uninstall.sh`, README, MIT licence. The HRIR file is not bundled; the
  installer checks for it and says where to get it.

### Changed

- `virtual-surround-razer.conf` uses an `@HRIR@` placeholder that the installer fills in,
  instead of a hardcoded home path.
- Manifest version synced with this changelog; author and `license` fields added.

## [1.0.1] - 2026-11-18

### Fixed

- Bar icon is dimmed when off and steady white when on, one headphones glyph for both
  states; the pulsing opacity is gone.

## [1.0.0] - 2026-11-18

### Added

- `omar.soundfx` bar widget: an orb toggles Razer-style virtual 7.1 surround, with
  animated ribbons and pulse rings that ease in and out, and a Soft/Normal/Deep bass control.
  Right-click the bar icon to toggle without opening the panel.
- `bin/soundfx` CLI and daemon (systemd user unit `soundfx.service`): keeps every app
  stream on the right sink by reconciling on each PipeWire event, so the toggle cannot
  desync (new Firefox tabs follow). The widget only requests on/off and mirrors
  `~/.local/state/soundfx/status.json`.
- `pipewire/virtual-surround-razer.conf`: Razer HRIR (HeSuVi) 7.1 filter chain with a
  live-adjustable low-shelf bass stage.
