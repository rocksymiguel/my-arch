#!/bin/bash
# Descarga logos de https://github.com/homarr-labs/dashboard-icons (los de apps y servicios más usados) a
# ~/.local/share/icons/hicolor/scalable/apps/, para el lanzador. Los logos son de sus marcas, por eso se bajan
# al instalar y no se guardan en este repositorio.
#   bash install/iconos.sh claude-ai jellyfin immich …
# Sin argumentos baja los de Claude y los de las web apps de ~/.config/my-arch/personal.env.
set -uo pipefail

DEST="$HOME/.local/share/icons/hicolor/scalable/apps"
BASE="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg"
mkdir -p "$DEST"

nombres=("$@")
if [ ${#nombres[@]} -eq 0 ]; then
    nombres=(claude-ai)
    WEBAPPS=""
    [ -f "$HOME/.config/my-arch/personal.env" ] && source "$HOME/.config/my-arch/personal.env"
    IFS=';' read -ra apps <<< "${WEBAPPS:-}"
    for a in "${apps[@]}"; do
        i="$(cut -d'|' -f3 <<< "$a")"; [ -n "$i" ] && nombres+=("$i")
    done
fi

for n in "${nombres[@]}"; do
    [ -s "$DEST/$n.svg" ] && continue
    if curl -fsSL --max-time 30 -o "$DEST/$n.svg.tmp" "$BASE/$n.svg" && head -c 400 "$DEST/$n.svg.tmp" | grep -q '<svg'; then
        mv -f "$DEST/$n.svg.tmp" "$DEST/$n.svg"
        echo "icono: $n"
    else
        rm -f "$DEST/$n.svg.tmp"
        echo "No encontré el icono «$n» (se verá el genérico)" >&2
    fi
done
