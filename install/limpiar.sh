#!/bin/bash
# Limpieza del sistema: paquetes huérfanos, caché de pacman, descargas a medias, volcados de
# cuelgues y registros antiguos. Se puede repetir cuando se quiera.
# Uso:  sudo bash ~/my-arch/install/limpiar.sh
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Ejecútalo con sudo: sudo bash $0" >&2; exit 1; }
antes="$(df --output=used -B1M / | tail -n 1)"

echo "==> Paquetes huérfanos"
huerfanos="$(pacman -Qtdq || true)"
if [ -n "$huerfanos" ]; then pacman -Rns --noconfirm $huerfanos; else echo "Ninguno"; fi

echo "==> Caché de pacman: solo la versión instalada de cada paquete"
paccache -rk1
paccache -ruk0                                   # paquetes que ya no están instalados
rm -rf /var/cache/pacman/pkg/download-*          # descargas interrumpidas

echo "==> Volcados de cuelgues"
rm -f /var/lib/systemd/coredump/*

echo "==> Registros del sistema: máximo 50 MB"
journalctl --vacuum-size=50M

despues="$(df --output=used -B1M / | tail -n 1)"
echo "==> LISTO: $((antes - despues)) MB liberados"
