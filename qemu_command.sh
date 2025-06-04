qemu-system-x86_64 \
  -enable-kvm \
  -m 2048 \
  -cpu host \
  -smp 2 \
  -cdrom ~/debian-lxde-hdmi-iso/debian-lxde-hdmi.iso \
  -boot d \
  -vga virtio \
  -nic user \
  -display gtk
