#!/bin/bash
# Cambia power-profiles-daemon por TLP (ahorro real en batería: aquí el PPD no hace nada,
# su driver es un "placeholder" porque la CPU no tiene los controles que usa).
# Uso:  sudo bash ~/my-arch/install/energia.sh
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Ejecútalo con sudo: sudo bash $0" >&2; exit 1; }
R="$(cd "$(dirname "$0")" && pwd)"

# 1. Quitar power-profiles-daemon (choca con TLP)
systemctl disable --now power-profiles-daemon.service 2>/dev/null || true
pacman -Rns power-profiles-daemon

# 2. Instalar TLP y dejarle la configuración del repositorio
pacman -S --needed tlp
install -Dm644 "$R/tlp.conf" /etc/tlp.d/10-lenovo.conf

# 3. Activarlo ahora y en cada arranque
systemctl enable --now tlp.service

echo
echo "== Estado de TLP =="
tlp-stat -s | sed -n '1,14p'
tlp-stat -p | grep -iE 'boost|governor' | head -4
