#!/bin/bash
# Modo juego: Limine (menú de arranque con Escritorio / Juego), inicio de sesión automático
# en tty1 y el gancho de Steam "Cambiar a escritorio".
# Ejecutar con: sudo bash ~/my-arch/install/modo-juego.sh
# systemd-boot NO se borra: queda en la UEFI como respaldo (F12 al encender).
set -euo pipefail
[ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ] || { echo "Ejecuta con: sudo bash ~/my-arch/install/modo-juego.sh"; exit 1; }
U="$SUDO_USER"
H="$(getent passwd "$U" | cut -d: -f6)"
D="$H/my-arch/install"
export LC_ALL=C

echo "==> Herramientas necesarias"
command -v efibootmgr >/dev/null || pacman -S --needed --noconfirm efibootmgr
efibootmgr --version | head -n 1

echo "==> Limine en la partición EFI"
mkdir -p /boot/EFI/limine /boot/limine
cp /usr/share/limine/BOOTX64.EFI /boot/EFI/limine/BOOTX64.EFI
bash "$D/limine.sh"   # configuración y fondos al azar

echo "==> Entrada de Limine en la UEFI (primera); systemd-boot se queda detrás"
if ! efibootmgr | grep -q "Limine"; then
    efibootmgr --create --disk /dev/nvme0n1 --part 1 --label "Limine" --loader '\EFI\limine\BOOTX64.EFI' >/dev/null
fi
LIM="$(efibootmgr | sed -n 's/^Boot\([0-9A-F]\{4\}\)\* Limine.*/\1/p' | head -n 1)"
RESTO="$(efibootmgr | sed -n 's/^BootOrder: //p' | tr ',' '\n' | grep -v "^$LIM$" | paste -sd,)"
efibootmgr -o "$LIM,$RESTO" >/dev/null
efibootmgr | head -n 4 || true

echo "==> Actualizar Limine solo cuando se actualice el paquete"
mkdir -p /etc/pacman.d/hooks
cat > /etc/pacman.d/hooks/limine.hook <<'EOF'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = limine

[Action]
Description = Copiando Limine a la partición EFI...
When = PostTransaction
Exec = /usr/bin/cp /usr/share/limine/BOOTX64.EFI /boot/EFI/limine/BOOTX64.EFI
EOF

echo "==> Inicio de sesión automático en tty1 para $U"
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\\\u' --noclear --noissue --nohostname --nonewline --skip-login --autologin $U %I \$TERM
EOF
systemctl daemon-reload
cat /etc/systemd/system/getty@tty1.service.d/autologin.conf

echo "==> Steam: 'Cambiar a escritorio' vuelve a Hyprland"
install -m 755 "$D/os-session-select" /usr/lib/os-session-select

echo "==> LISTO: reinicia; verás el menú de Limine"
