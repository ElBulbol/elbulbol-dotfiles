# Fix Discord Screenshare on Vesktop — Sway + Arch Linux

> **Stack:** Vesktop · Sway (wlroots) · PipeWire · xdg-desktop-portal-wlr · Arch Linux

---

## Quick Fix (try this first)

Corrupted Vencord install is the most common silent killer — the screenshare patch never loads and nothing calls the portal.

```bash
rm -rf ~/.config/vesktop/sessionData/vencordFiles/
```

Relaunch Vesktop. It will re-download Vencord automatically. Try screensharing again.

---

## Full Fix (if quick fix didn't work)

### 1. Install required packages

```bash
sudo pacman -S xdg-desktop-portal xdg-desktop-portal-wlr pipewire wireplumber
```

### 2. Electron Wayland + PipeWire flags

```bash
cat > ~/.config/electron-flags.conf << 'EOF'
--enable-features=UseOzonePlatform,WebRTCPipeWireCapturer
--ozone-platform=wayland
--enable-webrtc-pipewire-capturer
EOF
```

### 3. Portal backend config

Tell xdg-desktop-portal to use the wlr backend for screencasting:

```bash
mkdir -p ~/.config/xdg-desktop-portal
cat > ~/.config/xdg-desktop-portal/sway-portals.conf << 'EOF'
[preferred]
default=wlr;gtk
org.freedesktop.impl.portal.FileChooser=gtk
org.freedesktop.impl.portal.Screenshot=wlr
org.freedesktop.impl.portal.ScreenCast=wlr
org.freedesktop.impl.portal.Inhibit=none
EOF
```

### 4. Fix portal startup timing (systemd override)

Prevents xdg-desktop-portal-wlr from starting before PipeWire is ready:

```bash
mkdir -p ~/.config/systemd/user/xdg-desktop-portal-wlr.service.d
cat > ~/.config/systemd/user/xdg-desktop-portal-wlr.service.d/override.conf << 'EOF'
[Unit]
After=pipewire.service pipewire-pulse.service wireplumber.service

[Service]
ExecStartPre=/bin/sleep 3
Restart=on-failure
RestartSec=3
EOF

systemctl --user daemon-reload
```

### 5. Fix sway config portal section

Replace whatever portal exec block you have in `~/.config/sway/config` with this clean version:

```bash
# XDG DESKTOP PORTAL (file picker, screen share)
exec systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY
exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway DISPLAY
exec systemctl --user restart xdg-desktop-portal-wlr.service
exec systemctl --user restart xdg-desktop-portal.service
```

**Do NOT manually exec `/usr/lib/xdg-desktop-portal-wlr` or `/usr/lib/xdg-desktop-portal` —** let systemd manage them. Running both causes a race condition where the portal crashes on every screenshare attempt.

### 6. Override Vesktop .desktop to use Wayland flags

```bash
mkdir -p ~/.local/share/applications
sed 's|^Exec=vesktop %U|Exec=vesktop --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --ozone-platform=wayland --enable-webrtc-pipewire-capturer %U|' \
  /usr/share/applications/vesktop.desktop > ~/.local/share/applications/vesktop.desktop
```

### 7. Reload everything

```bash
systemctl --user restart pipewire wireplumber
sleep 2
systemctl --user restart xdg-desktop-portal-wlr.service
sleep 2
systemctl --user restart xdg-desktop-portal.service
swaymsg reload
```

Kill and relaunch Vesktop. A monitor picker dialog should appear when you screenshare.

---

## Verify it's working

```bash
# ScreenCast interface must appear in this list
gdbus introspect --session --dest org.freedesktop.portal.Desktop \
  --object-path /org/freedesktop/portal/desktop 2>/dev/null \
  | grep -i screencast
```

Expected output: `interface org.freedesktop.portal.ScreenCast {`

---

## Debugging

```bash
# Watch portal logs live while attempting to screenshare
journalctl --user -u xdg-desktop-portal-wlr.service -f

# Check portal env vars are set correctly
systemctl --user show-environment | grep -E "WAYLAND|XDG|DISPLAY"

# Check Vesktop is running with correct flags
ps aux | grep vesktop | grep -v grep

# Run Vesktop with full logging
ELECTRON_ENABLE_LOGGING=1 vesktop 2>&1 | grep -i "vencord\|portal\|error"
```

---

## What each piece does

| Component | Role |
|---|---|
| `xdg-desktop-portal-wlr` | Bridges Sway/wlroots compositor to apps requesting screenshare |
| `pipewire` | Streams the captured screen frames to the app |
| `electron-flags.conf` | Tells Electron to use Wayland natively and PipeWire for capture |
| `sway-portals.conf` | Tells the portal which backend to use for ScreenCast when desktop is `sway` |
| `systemd override` | Prevents portal from starting before PipeWire is ready |
| `vencordFiles/` | Vencord's JS — if corrupted, screenshare patch never loads |
