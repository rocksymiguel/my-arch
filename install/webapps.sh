#!/bin/bash
# Crea en el lanzador las web apps de WEBAPPS (~/.config/my-arch/personal.env): cada una abre su dirección en su
# propia ventana, sin pestañas ni barra de dirección, con Epiphany (modo aplicación). Cada app tiene su perfil:
# sus sesiones y cookies no se mezclan. Los iconos se bajan con install/iconos.sh.
# Se puede repetir sin problema: quita las que ya no estén en la lista y deja las demás.
#   bash install/webapps.sh
# Los servicios con certificado propio (TrueNAS, Proxmox) piden aceptarlo la primera vez.
set -uo pipefail

D="$(cd "$(dirname "$0")" && pwd)"
PERSONAL="$HOME/.config/my-arch/personal.env"
WEBAPPS=""
[ -f "$PERSONAL" ] && source "$PERSONAL"
[ -n "${WEBAPPS:-}" ] || { echo "No hay web apps en $PERSONAL (WEBAPPS vacío)."; exit 0; }
command -v epiphany >/dev/null 2>&1 || [ -n "${WEBAPPS_SIN_EPIPHANY:-}" ] \
    || { echo "Epiphany no está instalado: sudo pacman -S epiphany (o bash ~/my-arch/install/post.sh personal)" >&2; exit 1; }

APPS="$HOME/.local/share/applications"
LISTA="$HOME/.local/share/my-arch/webapps.lista"
mkdir -p "$APPS" "$(dirname "$LISTA")"

# Lo creado la vez anterior se quita primero (así desaparecen las que ya no estén en la lista)
if [ -f "$LISTA" ]; then
    while read -r f; do
        [ -n "$f" ] || continue
        id="$(basename "$f" .desktop)"
        rm -f "$f"; rm -rf "$HOME/.local/share/$id"
    done < "$LISTA"
fi
: > "$LISTA"

bash "$D/iconos.sh" >/dev/null 2>&1 || true

IFS=';' read -ra apps <<< "$WEBAPPS"
for a in "${apps[@]}"; do
    nombre="$(cut -d'|' -f1 <<< "$a" | sed 's/^ *//; s/ *$//')"
    url="$(cut -d'|' -f2 <<< "$a" | sed 's/^ *//; s/ *$//')"
    icono="$(cut -d'|' -f3 <<< "$a" | sed 's/^ *//; s/ *$//')"
    [ -n "$nombre" ] && [ -n "$url" ] || continue
    # Mismo identificador que usa Epiphany para sus web apps: org.gnome.Epiphany.WebApp_<sha1 del nombre>
    id="org.gnome.Epiphany.WebApp_$(printf '%s' "$nombre" | sha1sum | cut -d' ' -f1)"
    perfil="$HOME/.local/share/$id"
    entrada="$APPS/$id.desktop"
    mkdir -p "$perfil"
    cat > "$entrada" <<EOF
[Desktop Entry]
Type=Application
Name=$nombre
Comment=$nombre (web app, en su propia ventana)
Exec=epiphany --application-mode --profile=$perfil $url
Icon=${icono:-applications-internet}
StartupWMClass=$id
Terminal=false
Categories=Network;
X-MyArch-WebApp=true
EOF
    ln -sf "$entrada" "$perfil/.app"
    echo "$entrada" >> "$LISTA"
    echo "web app: $nombre → $url"
done
update-desktop-database "$APPS" 2>/dev/null || true
