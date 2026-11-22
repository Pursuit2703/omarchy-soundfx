# Changelog

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
