#!/usr/bin/env bash
# Removes what install.sh added. Leaves PipeWire, filter-chain.service and your HRIR file alone.
# Disables the widget first, so it cannot reinstall the backend on the next shell load.
set -euo pipefail
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/soundfx"
omarchy plugin disable omar.soundfx 2>/dev/null || true
systemctl --user disable --now soundfx.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/soundfx.service" \
      "$HOME/.local/bin/soundfx" \
      "$HOME/.config/pipewire/filter-chain.conf.d/virtual-surround-razer.conf"
rm -rf "$state_dir"
systemctl --user daemon-reload
systemctl --user restart filter-chain.service 2>/dev/null || true
echo "soundfx removed. Run 'omarchy plugin remove omar.soundfx' to delete the plugin files."
