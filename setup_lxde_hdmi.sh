#!/bin/bash
# setup_lxde_hdmi.sh – erstellt ein eigenes Debian-Live-ISO mit LXDE, HDMI-Viewer, Autologin, WLAN, SSH & Installer (vorkonfiguriert)
# Voraussetzung: Debian-basiertes System mit root-Rechten

set -e

USERNAME=$(whoami)
WORKDIR="$HOME/debian-lxde-hdmi-iso"
ISO_NAME="debian-lxde-hdmi.iso"

# 1. Abhängigkeiten installieren
sudo apt update
sudo apt install -y live-build curl xorriso squashfs-tools calamares

# 2. Verzeichnisstruktur erstellen
mkdir -p "$WORKDIR"
cd "$WORKDIR"

lb config \
  --distribution bookworm \
  --debian-installer false \
  --archive-areas "main contrib non-free-firmware" \
  --binary-images iso-hybrid \
  --bootappend-live "boot=live components quiet splash username=asus hostname=hdmi locales=de_DE.UTF-8 keyboard-layouts=de timezone=Europe/Berlin"

# Quellenliste für chroot setzen
mkdir -p config/includes.chroot/etc/apt
cat <<EOF > config/includes.chroot/etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main contrib non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free-firmware
deb http://security.debian.org bookworm-security main contrib non-free-firmware
EOF

# Benutzerverzeichnis anlegen
mkdir -p config/includes.chroot/home/asus
chmod 755 config/includes.chroot/home/asus

# Benutzer und Passwort anlegen, zur sudo-Gruppe hinzufügen
mkdir -p config/includes.chroot/usr/lib/live/config
cat << 'EOF' > config/includes.chroot/usr/lib/live/config/999-set-passwords
#!/bin/sh
echo "asus:root" | chpasswd
echo "root:root" | chpasswd
usermod -aG sudo asus
rm -f /usr/lib/live/config/999-set-passwords
EOF
chmod +x config/includes.chroot/usr/lib/live/config/999-set-passwords

# WLAN-Konfiguration einfügen (WPA2-PSK)
mkdir -p config/includes.chroot/etc/NetworkManager/system-connections
cat <<EOF > config/includes.chroot/etc/NetworkManager/system-connections/o2-WLAN00.nmconnection
[connection]
id=o2-WLAN00
uuid=$(uuidgen)
type=wifi
autoconnect=true
permissions=

[wifi]
mode=infrastructure
ssid=o2-WLAN00

[wifi-security]
key-mgmt=wpa-psk
auth-alg=open
psk=E9E6G3K622FGHG2J

[ipv4]
method=auto

[ipv6]
method=auto
EOF
chmod 600 config/includes.chroot/etc/NetworkManager/system-connections/o2-WLAN00.nmconnection

# 6. SSH aktivieren (PermitRootLogin no, Passwortanmeldung erlaubt)
mkdir -p config/includes.chroot/etc/ssh
cat <<EOF > config/includes.chroot/etc/ssh/sshd_config
Port 22
PermitRootLogin no
PasswordAuthentication yes
UsePAM yes
EOF

# 7. SSH-Dienst aktivieren
mkdir -p config/includes.chroot/etc/systemd/system/multi-user.target.wants
if [ ! -e config/includes.chroot/etc/systemd/system/multi-user.target.wants/ssh.service ]; then
  ln -s /lib/systemd/system/ssh.service config/includes.chroot/etc/systemd/system/multi-user.target.wants/ssh.service
fi

# 8. Calamares vorkonfigurieren
mkdir -p config/includes.chroot/etc/calamares
cat <<EOF > config/includes.chroot/etc/calamares/settings.conf
---
modules:
 - welcome
 - locale:
     defaultLocale: de_DE.UTF-8
 - keyboard:
     defaultLayout: de
     defaultVariant: nodeadkeys
 - timezone:
     zone: Europe/Berlin
 - partition
 - users:
     defaultFullName: Asus
     defaultLoginName: asus
     defaultPassword: root
 - summary
 - install
 - finished
branding:
  sidebarBackground: "#292929"
  productName: HDMI Viewer Linux
  version: 1.0
EOF

# 9. ISO bauen
sudo lb build

# 10. ISO verschieben
if [ -f "$ISO_NAME" ]; then
  echo "
✅ ISO erstellt: $(realpath $ISO_NAME)"
  echo "
💡 Starte das ISO und führe Calamares aus, um es auf Festplatte zu installieren. Benutzername und Passwort sind vorkonfiguriert."
else
  echo "
❌ Fehler: ISO-Datei '$ISO_NAME' wurde nicht erstellt."
  echo "   Überprüfe die vorherigen Ausgaben auf Fehlermeldungen."
fi
