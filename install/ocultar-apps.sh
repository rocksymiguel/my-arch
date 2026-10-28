#!/bin/bash
# Esconde del lanzador las entradas de packages/ocultar.txt sin quitarles nada: deja en
# ~/.local/share/applications una copia de cada .desktop del sistema con NoDisplay=true. La copia conserva los
# tipos de archivo (MimeType), así que mpv, Thunar o Zen siguen abriendo lo suyo. No usa Hidden=true, que sí los
# quitaría de todas partes. Se puede repetir sin problema.
#   bash install/ocultar-apps.sh
set -uo pipefail

R="$(cd "$(dirname "$0")/.." && pwd)"
SISTEMA=/usr/share/applications
DEST="$HOME/.local/share/applications"
mkdir -p "$DEST"

grep -v '^\s*#' "$R/packages/ocultar.txt" | sed 's/#.*//' | awk 'NF {print $1}' | while read -r id; do
    origen="$SISTEMA/$id"
    destino="$DEST/$id"
    if [ ! -f "$origen" ]; then echo "  (no está instalada: $id)"; continue; fi
    # si ya hay una copia tuya o un enlace del repo que la esconde, se respeta
    if [ -e "$destino" ] && grep -q '^NoDisplay=true' "$destino"; then echo "  ya oculta: $id"; continue; fi
    if [ -e "$destino" ] && [ ! -L "$destino" ]; then
        cp -n "$destino" "$destino.bak" 2>/dev/null || true   # una copia tuya distinta: se guarda antes de tocarla
    fi
    rm -f "$destino"
    # NoDisplay=true justo después de la línea [Desktop Entry] (el primer grupo del archivo)
    sed '/^NoDisplay=/d' "$origen" \
        | awk '{print} !hecho && /^\[Desktop Entry\]/ {print "NoDisplay=true"; hecho=1}' > "$destino"
    echo "  oculta: $id"
done
update-desktop-database "$DEST" 2>/dev/null || true
