#!/usr/bin/env bash
# Installs the soundfx backend: CLI/daemon, systemd user unit, PipeWire filter chain.
# Never restarts PipeWire. Run from the plugin directory.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
hrir="${SOUNDFX_HRIR:-$HOME/.config/pipewire/hrir/razer.wav}"
conf_dir="$HOME/.config/pipewire/filter-chain.conf.d"
unit_dir="$HOME/.config/systemd/user"

for c in python3 pactl pw-dump pw-cli systemctl; do
  command -v "$c" >/dev/null || { echo "missing dependency: $c" >&2; exit 1; }
done

if [[ ! -f "$hrir" ]]; then
  cat >&2 <<EOM
HRIR file not found: $hrir
This plugin does not ship the Razer HRIR. Get a 14-channel HeSuVi-format
"razer.wav" (HeSuVi: https://sourceforge.net/projects/hesuvi/), put it at the path
above, or set SOUNDFX_HRIR=/path/to/file.wav, then run this script again.
EOM
  exit 1
fi

install -Dm755 "$here/bin/soundfx" "$HOME/.local/bin/soundfx"
install -Dm644 "$here/soundfx.service" "$unit_dir/soundfx.service"
mkdir -p "$conf_dir"
sed "s#@HRIR@#$hrir#g" "$here/pipewire/virtual-surround-razer.conf" > "$conf_dir/virtual-surround-razer.conf"

systemctl --user daemon-reload
systemctl --user enable --now filter-chain.service
# filter-chain only reads its config at start; restart just this service, not PipeWire
systemctl --user restart filter-chain.service
systemctl --user enable --now soundfx.service
echo "soundfx installed. Add the Sound FX widget in your bar settings."
