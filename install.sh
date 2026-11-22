#!/usr/bin/env bash
# Installs the soundfx backend: CLI/daemon, systemd user unit, PipeWire filter chain.
# Safe to re-run: it only restarts what changed, and never restarts PipeWire itself.
#   install.sh           install or upgrade
#   install.sh --check   exit 0 if the installed copy matches this plugin version
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
hrir="${SOUNDFX_HRIR:-$HOME/.config/pipewire/hrir/razer.wav}"
conf_dir="$HOME/.config/pipewire/filter-chain.conf.d"
unit_dir="$HOME/.config/systemd/user"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/soundfx"
marker="$state_dir/installed"

stamp() {
  (cd "$here" && cat install.sh bin/soundfx soundfx.service \
    pipewire/virtual-surround-razer.conf hrir/razer.wav | sha256sum | cut -d' ' -f1)
}

if [[ "${1:-}" == "--check" ]]; then
  [[ -f "$marker" && "$(<"$marker")" == "$(stamp)" ]]
  exit
fi

# One installer at a time (several bar instances can load the widget at once).
mkdir -p "$state_dir"
exec 9>"$state_dir/install.lock"
flock 9
if [[ -f "$marker" && "$(<"$marker")" == "$(stamp)" ]]; then exit 0; fi  # another instance finished

for c in python3 pactl pw-dump pw-cli systemctl flock; do
  command -v "$c" >/dev/null || { echo "missing dependency: $c" >&2; exit 1; }
done
systemctl --user cat filter-chain.service >/dev/null 2>&1 || {
  echo "filter-chain.service user unit not found (is the PipeWire package complete?)" >&2
  exit 1
}

# Use the HRIR bundled with the plugin unless you already have one (or set SOUNDFX_HRIR).
[[ -f "$hrir" ]] || install -Dm644 "$here/hrir/razer.wav" "$hrir"

# put SRC DST MODE: install only if different; returns 0 when it changed the file.
put() {
  if [[ -f "$2" ]] && cmp -s "$1" "$2"; then return 1; fi
  install -Dm"$3" "$1" "$2"
}

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
python3 -c 'import sys; sys.stdout.write(open(sys.argv[1]).read().replace("@HRIR@", sys.argv[2]))' \
  "$here/pipewire/virtual-surround-razer.conf" "$hrir" > "$tmp"

bin_changed=0
conf_changed=0
put "$here/bin/soundfx" "$HOME/.local/bin/soundfx" 755 && bin_changed=1 || true
put "$here/soundfx.service" "$unit_dir/soundfx.service" 644 && bin_changed=1 || true
put "$tmp" "$conf_dir/virtual-surround-razer.conf" 644 && conf_changed=1 || true

systemctl --user daemon-reload
systemctl --user enable filter-chain.service soundfx.service
if (( conf_changed )) || ! systemctl --user is-active --quiet filter-chain.service; then
  systemctl --user restart filter-chain.service
fi
if (( bin_changed )) || ! systemctl --user is-active --quiet soundfx.service; then
  systemctl --user restart soundfx.service
fi

stamp > "$marker"
echo "soundfx installed. Add the Sound FX widget in your bar settings."
