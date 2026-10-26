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
source "$D/detectar.sh"
ANCHO="${RES%x*}"; ALTO="${RES#*x}"
DEST=/boot/limine/fondos

echo "==> Fondos para Limine ($RES, JPEG)"
mkdir -p /boot/EFI/limine "$DEST"
rm -f "$DEST"/*.jpg /boot/limine/fondo.png
n=0
lineas=""
while IFS= read -r -d '' f; do
    n=$((n + 1))
    nombre="$(printf '%02d.jpg' "$n")"   # nombres cortos y sin espacios para la FAT32
    ffmpeg -nostdin -v error -y -i "$f" -frames:v 1 -q:v 3 \
        -vf "scale=$ANCHO:$ALTO:force_original_aspect_ratio=increase,crop=$ANCHO:$ALTO" "$DEST/$nombre"
    lineas+="wallpaper: boot():/limine/fondos/$nombre"$'\n'
done < <(find "$FONDOS" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) -print0 2>/dev/null | sort -z)
if [ "$n" -gt 0 ]; then echo "$n fondos, $(du -sh "$DEST" | cut -f1) en /boot"; else echo "No hay fondos en $FONDOS: Limine sin fondo"; fi

echo "==> limine.conf"
ROOTUUID="$(findmnt -no UUID /)"
# La entrada «Juego» solo si está instalado el modo juego (modo-juego.sh y packages/juego.txt)
JUEGO=0; command -v gamescope-session-plus >/dev/null && JUEGO=1
awk -v fondos="${lineas%$'\n'}" -v uuid="$ROOTUUID" -v usuario="$SUDO_USER" -v juego="$JUEGO" '
    /^\// { saltar = (!juego && /Juego/) }
    saltar { next }
    $0 == "__FONDOS__" { if (fondos != "") print fondos; next }
    { gsub(/__ROOTUUID__/, uuid); gsub(/__USUARIO__/, usuario); print }' \
    "$D/limine.conf" > /boot/EFI/limine/limine.conf
echo "Entradas: $(grep -c '^/' /boot/EFI/limine/limine.conf) · fondos: $(grep -c '^wallpaper:' /boot/EFI/limine/limine.conf)"
