# omar.soundfx

An Omarchy bar widget that toggles virtual 7.1 surround on headphones, Razer Surround
style. An orb in the panel switches it on and off, and a Soft / Normal / Deep control
sets the bass. Right-click the bar icon to toggle without opening the panel.

## How it works

- `BarWidget.qml` is the UI. It only asks for on/off and reads
  `~/.local/state/soundfx/status.json`.
- `bin/soundfx` is a CLI and daemon (`soundfx.service`, a systemd user unit). It watches
  PipeWire and keeps every app stream on the right sink, so new apps and browser tabs
  follow the toggle.
- `pipewire/virtual-surround-razer.conf` is a PipeWire filter chain: 8 channels through an
  HRIR convolver to stereo, plus a live-adjustable low-shelf bass stage. It adds a second
  sink named "Razer Surround 7.1" and does not change your default sink.

## Requirements

`python3`, PipeWire with `pipewire-pulse`, `pactl`, `pw-dump`, `pw-cli`, systemd user
services, and a `filter-chain.service` user unit (shipped with PipeWire).

**HRIR file (not included).** The effect needs a HeSuVi-format HRIR named `razer.wav`.
Razer's HRIR is not mine to redistribute, so get it yourself from the
[HeSuVi](https://sourceforge.net/projects/hesuvi/) HRIR set and put it at
`~/.config/pipewire/hrir/razer.wav` (or set `SOUNDFX_HRIR`). Check its licence before
sharing it.

## Install

Put your HRIR at `~/.config/pipewire/hrir/razer.wav` first (see above), then:

```bash
omarchy plugin add https://github.com/Pursuit2703/omarchy-soundfx.git --enable
```

On first load the widget runs `install.sh`, which does the following, and nothing else:

- copies `bin/soundfx` to `~/.local/bin/soundfx`
- copies `soundfx.service` to `~/.config/systemd/user/` and enables it
- writes the filter chain to `~/.config/pipewire/filter-chain.conf.d/` (with your HRIR path)
- enables and restarts `filter-chain.service` (PipeWire itself is not restarted)

It runs as your user, with no sudo and no sandbox. Read `install.sh` before enabling. If the
HRIR is missing, nothing is installed and the reason is in `~/.local/state/soundfx/install.log`.
Add the HRIR and restart the shell (or run `./install.sh` yourself).

## Uninstall

```bash
./uninstall.sh
omarchy plugin remove omar.soundfx
```

## Control from a keybind

`omarchy-shell omar.soundfx on|off|toggle|open|close`, or `soundfx toggle|on|off|bass 0|1|2|status`.

## Licence

MIT. The HRIR data is not covered by it and is not included.
