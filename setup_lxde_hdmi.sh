#!/bin/bash
# Debian LXDE HDMI ISO Builder Script

# 1. Konfiguration
ISO_NAME="debian-lxde-hdmi.iso"
BUILD_DIR="$HOME/debian-lxde-hdmi-iso"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# 2. Live-Build Setup
sudo apt update
sudo apt install -y live-build curl xorriso squashfs-tools uuid-runtime calamares

# 3. Konfiguration starten
lb config --distribution bookworm --debian-installer false --archive-areas "main contrib non-free-firmware" --binary-images iso-hybrid --bootappend-live "boot=live components quiet splash username=asus hostname=hdmi locales=de_DE.UTF-8 keyboard-layouts=de timezone=Europe/Berlin"

# 4. APT-Quellen setzen
mkdir -p config/includes.chroot/etc/apt
cat <<EOF > config/includes.chroot/etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main contrib non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free-firmware
deb http://security.debian.org bookworm-security main contrib non-free-firmware
EOF

# 5. Benutzer und Passwort setzen
mkdir -p config/includes.chroot/usr/lib/live/config
cat << 'EOF' > config/includes.chroot/usr/lib/live/config/999-set-passwords
#!/bin/sh
echo "asus:root" | chpasswd
echo "root:root" | chpasswd
usermod -aG sudo asus
rm -f /usr/lib/live/config/999-set-passwords
EOF
chmod +x config/includes.chroot/usr/lib/live/config/999-set-passwords

# 6. SSH aktivieren
mkdir -p config/includes.chroot/etc/systemd/system/multi-user.target.wants
if [ ! -e config/includes.chroot/etc/systemd/system/multi-user.target.wants/ssh.service ]; then
  ln -s /lib/systemd/system/ssh.service config/includes.chroot/etc/systemd/system/multi-user.target.wants/ssh.service
fi

# 7. Paketliste
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
EOF

# 8. Autologin einrichten
mkdir -p config/includes.chroot/etc/systemd/system/getty@tty1.service.d
cat <<EOF > config/includes.chroot/etc/systemd/system/getty@tty1.service.d/autologin.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin asus --noclear %I \$TERM
EOF

# 9. ISO bauen
sudo lb build

# 10. Ergebnis
if [ -f "$ISO_NAME" ]; then
  echo -e "\\n✅ ISO erstellt: $(realpath $ISO_NAME)"
else
  echo -e "\\n❌ Fehler: ISO wurde nicht erstellt."
fi

