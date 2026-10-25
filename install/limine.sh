#!/bin/bash
# Instala la configuración de Limine (install/limine.conf) y copia todos los fondos de
# ~/Imágenes/Fondos a la partición EFI, reducidos a la pantalla: Limine elige uno al azar en
# cada arranque. Vuelve a ejecutarlo después de añadir o quitar fondos.
# Ejecutar con: sudo bash ~/my-arch/install/limine.sh
set -euo pipefail
[ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ] || { echo "Ejecuta con: sudo bash ~/my-arch/install/limine.sh"; exit 1; }
H="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
D="$H/my-arch/install"
FONDOS="$H/Imágenes/Fondos"
DEST=/boot/limine/fondos

echo "==> Fondos para Limine (1366x768, JPEG)"
mkdir -p /boot/EFI/limine "$DEST"
rm -f "$DEST"/*.jpg /boot/limine/fondo.png
n=0
lineas=""
while IFS= read -r -d '' f; do
    n=$((n + 1))
    nombre="$(printf '%02d.jpg' "$n")"   # nombres cortos y sin espacios para la FAT32
    ffmpeg -nostdin -v error -y -i "$f" -frames:v 1 -q:v 3 \
        -vf "scale=1366:768:force_original_aspect_ratio=increase,crop=1366:768" "$DEST/$nombre"
    lineas+="wallpaper: boot():/limine/fondos/$nombre"$'\n'
done < <(find "$FONDOS" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) -print0 | sort -z)
[ "$n" -gt 0 ] || { echo "No hay fondos en $FONDOS" >&2; exit 1; }
echo "$n fondos, $(du -sh "$DEST" | cut -f1) en /boot"

echo "==> limine.conf"
ROOTUUID="$(findmnt -no UUID /)"
awk -v fondos="${lineas%$'\n'}" -v uuid="$ROOTUUID" \
    '$0 == "__FONDOS__" { print fondos; next } { gsub(/__ROOTUUID__/, uuid); print }' \
    "$D/limine.conf" > /boot/EFI/limine/limine.conf
echo "Entradas: $(grep -c '^/' /boot/EFI/limine/limine.conf) · fondos: $(grep -c '^wallpaper:' /boot/EFI/limine/limine.conf)"
