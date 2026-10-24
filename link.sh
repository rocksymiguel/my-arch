#!/bin/bash
# Enlaza los dotfiles del repositorio en $HOME.
# Si ya existe un archivo o carpeta real, lo guarda como <nombre>.bak antes de enlazar.
set -euo pipefail
R="$(cd "$(dirname "$0")" && pwd)"

enlazar() {
    local origen="$1" destino="$2"
    mkdir -p "$(dirname "$destino")"
    if [ -L "$destino" ]; then
        rm "$destino"
    elif [ -e "$destino" ]; then
        mv "$destino" "$destino.bak"
        echo "Respaldo: $destino.bak"
    fi
    ln -s "$origen" "$destino"
    echo "$destino -> $origen"
}

for d in "$R"/dotfiles/.config/*/; do
    d="${d%/}"
    enlazar "$d" "$HOME/.config/$(basename "$d")"
done
enlazar "$R/dotfiles/.bashrc" "$HOME/.bashrc"
enlazar "$R/dotfiles/.icons/default/index.theme" "$HOME/.icons/default/index.theme"

# Apps escondidas del lanzador (NoDisplay)
for f in "$R"/dotfiles/.local/share/applications/*.desktop; do
    [ -e "$f" ] && enlazar "$f" "$HOME/.local/share/applications/$(basename "$f")"
done
