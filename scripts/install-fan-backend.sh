#!/usr/bin/env bash
set -euo pipefail
if (( EUID == 0 )); then echo "Als Desktop-Benutzer starten, ohne sudo." >&2; exit 1; fi
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source_dir="$repo/vendor/razer-laptop-control"
# Build before changing any installed files. GTK is a workspace dependency.
cargo build --locked --release --manifest-path "$source_dir/Cargo.toml" -p service --bins
backup="$HOME/.local/state/razor14-monitor/backend-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$HOME/.local/bin" "$HOME/.config/systemd/user" "$backup"
for name in razer-cli razercontrol-daemon razer-settings razor14-power-client; do
    if [[ -f "$HOME/.local/bin/$name" ]]; then cp -p "$HOME/.local/bin/$name" "$backup/$name"; fi
done
if [[ -f "$HOME/.config/systemd/user/razercontrol.service" ]]; then
    cp -p "$HOME/.config/systemd/user/razercontrol.service" "$backup/razercontrol.service"
fi
# Root writes are limited to the shared device database and this model's udev rule.
sudo install -D -m 644 "$source_dir/razer_control_gui/data/devices/laptops.json" /usr/share/razercontrol/laptops.json
sudo install -m 644 "$repo/host/udev/70-razor14-fan-control.rules" /etc/udev/rules.d/70-razor14-fan-control.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --action=change --subsystem-match=hidraw
sudo udevadm settle
systemctl --user stop razercontrol.service || true
install -m 755 "$source_dir/target/release/razer-cli" "$HOME/.local/bin/razer-cli"
install -m 755 "$source_dir/target/release/daemon" "$HOME/.local/bin/razercontrol-daemon"
install -m 755 "$source_dir/target/release/razer-settings" "$HOME/.local/bin/razer-settings"
install -m 755 "$repo/host/razor14-power-client" "$HOME/.local/bin/razor14-power-client"
install -m 644 "$repo/host/systemd/razercontrol.service" "$HOME/.config/systemd/user/razercontrol.service"
systemctl --user daemon-reload
systemctl --user enable --now razercontrol.service
printf 'Lüfter-Backend installiert. Sicherung: %s\n' "$backup"
