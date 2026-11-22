#!/usr/bin/env bash
# Removes what install.sh added. Leaves PipeWire, filter-chain.service and your HRIR file alone.
set -euo pipefail
systemctl --user disable --now soundfx.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/soundfx.service" \
      "$HOME/.local/bin/soundfx" \
      "$HOME/.config/pipewire/filter-chain.conf.d/virtual-surround-razer.conf"
rm -rf "$HOME/.local/state/soundfx"
systemctl --user daemon-reload
systemctl --user restart filter-chain.service 2>/dev/null || true
echo "soundfx removed."
