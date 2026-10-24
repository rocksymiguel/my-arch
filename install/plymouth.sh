#!/bin/bash
# Activa plymouth (animación de arranque) o cambia su tema.
# Uso: sudo bash ~/my-arch/install/plymouth.sh [tema]   (por defecto arch-logo)
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Ejecuta con: sudo bash ~/my-arch/install/plymouth.sh [tema]"; exit 1; }
TEMA="${1:-arch-logo}"
echo "Temas instalados: $(plymouth-set-default-theme -l | tr '\n' ' ')"
if ! plymouth-set-default-theme -l | grep -qx "$TEMA"; then
    TEMA="$(plymouth-set-default-theme -l | grep -m1 -i "^${1:-arch-logo}" || true)"
    [ -n "$TEMA" ] || { echo "No encuentro el tema ${1:-arch-logo}"; exit 1; }
fi

echo "==> Hook de plymouth en el arranque (después de systemd)"
grep -qE '^HOOKS=.*\bplymouth\b' /etc/mkinitcpio.conf || \
    sed -i -E 's/^(HOOKS=\(base systemd)/\1 plymouth/' /etc/mkinitcpio.conf
grep -E '^HOOKS' /etc/mkinitcpio.conf

echo "==> quiet splash en las entradas de systemd-boot"
for e in /boot/loader/entries/arch*.conf; do
    grep -q ' splash' "$e" || sed -i -E 's/^(options .*)$/\1 quiet splash/' "$e"
    grep '^options' "$e"
done

echo "==> Tema: $TEMA (y regenerar las imágenes de arranque)"
plymouth-set-default-theme "$TEMA"
mkinitcpio -P
plymouth-set-default-theme
echo "==> LISTO: reinicia para verlo"
