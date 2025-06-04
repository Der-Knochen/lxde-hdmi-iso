#!/bin/bash
# Debian LXDE HDMI ISO Builder mit /usr/bin/env-Fix

# 1. Grundkonfiguration
ISO_NAME="debian-lxde-hdmi.iso"
BUILD_DIR="$HOME/debian-lxde-hdmi-iso"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# 2. Abhängigkeiten installieren
sudo apt update
sudo apt install -y live-build curl xorriso squashfs-tools uuid-runtime calamares

# 3. Live-Build Konfiguration
lb config --distribution bookworm \
  --debian-installer false \
  --archive-areas "main contrib non-free-firmware" \
  --binary-images iso-hybrid \
  --bootappend-live "boot=live components quiet splash username=asus hostname=hdmi locales=de_DE.UTF-8 keyboard-layouts=de timezone=Europe/Berlin" \
  --mirror-bootstrap http://deb.debian.org/debian \
  --mirror-chroot http://deb.debian.org/debian

# 4. Mirror-Konfiguration absichern
mkdir -p config/archives
cat <<EOF > config/archives/debian.list.chroot
deb http://deb.debian.org/debian bookworm main contrib non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free-firmware
deb http://security.debian.org bookworm-security main contrib non-free-firmware
EOF

# 5. Ubuntu-Apt-Quellen entfernen
mkdir -p config/hooks/normal
cat << 'EOF' > config/hooks/normal/10-clean-apt.chroot
#!/bin/bash
rm -f /etc/apt/sources.list
rm -f /etc/apt/sources.list.d/*
EOF
chmod +x config/hooks/normal/10-clean-apt.chroot

# 6. Passwort setzen (env-fix über direkte bash, chpasswd absichern)
mkdir -p config/hooks/live/late-command
cat << 'EOF' > config/hooks/live/late-command/99-passwords.chroot
#!/bin/bash
command -v chpasswd >/dev/null || (apt update && apt install -y passwd)
echo "asus:root" | chpasswd
echo "root:root" | chpasswd
usermod -aG sudo asus
EOF
chmod +x config/hooks/live/late-command/99-passwords.chroot

# 7. SSH Autostart aktivieren
mkdir -p config/includes.chroot/etc/systemd/system/multi-user.target.wants
if [ ! -e config/includes.chroot/etc/systemd/system/multi-user.target.wants/ssh.service ]; then
  ln -s /lib/systemd/system/ssh.service config/includes.chroot/etc/systemd/system/multi-user.target.wants/ssh.service
fi

# 8. Paketliste mit coreutils und passwd für Kompatibilität
mkdir -p config/package-lists
cat <<EOF > config/package-lists/hdmi.list.chroot
lxde
xserver-xorg
xinit
network-manager
wireless-tools
wpasupplicant
openssh-server
curl
sudo
calamares
debian-archive-keyring
coreutils
passwd
EOF

# 9. Autologin einrichten
mkdir -p config/includes.chroot/etc/systemd/system/getty@tty1.service.d
cat <<EOF > config/includes.chroot/etc/systemd/system/getty@tty1.service.d/autologin.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin asus --noclear %I \$TERM
EOF

# 10. ISO Build starten
sudo lb build

# 11. Ergebnis prüfen
if [ -f "$ISO_NAME" ]; then
  echo -e "\n✅ ISO erstellt: $(realpath $ISO_NAME)"
else
  echo -e "\n❌ Fehler: ISO wurde nicht erstellt."
fi
