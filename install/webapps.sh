#!/bin/bash
# Crea en el lanzador las web apps de WEBAPPS (~/.config/my-arch/personal.env): cada una abre su dirección en su
# propia ventana, sin pestañas ni barra de dirección, con Chromium (modo aplicación). Todas comparten un perfil
# (un solo proceso: menos memoria) pero cada una tiene su propio perfil dentro de él y por eso su propia clase de ventana, para el
# icono de la barra y las reglas de Hyprland (Chromium la forma con el perfil: chrome-<equipo>__-<nombre>). Los iconos se bajan con install/iconos.sh.
# Se puede repetir sin problema: quita las que ya no estén en la lista y deja las demás.
#   bash install/webapps.sh
# Los servicios con certificado propio (TrueNAS, Proxmox) piden aceptarlo la primera vez.
set -uo pipefail

D="$(cd "$(dirname "$0")" && pwd)"
PERSONAL="$HOME/.config/my-arch/personal.env"
WEBAPPS=""
[ -f "$PERSONAL" ] && source "$PERSONAL"
[ -n "${WEBAPPS:-}" ] || { echo "No hay web apps en $PERSONAL (WEBAPPS vacío)."; exit 0; }
command -v chromium >/dev/null 2>&1 || [ -n "${WEBAPPS_SIN_CHROMIUM:-}" ] \
    || { echo "Chromium no está instalado: sudo pacman -S chromium (o bash ~/my-arch/install/post.sh personal)" >&2; exit 1; }

APPS="$HOME/.local/share/applications"
LISTA="$HOME/.local/share/my-arch/webapps.lista"
PERFIL="$HOME/.local/share/my-arch/webapps-chromium"
mkdir -p "$APPS" "$(dirname "$LISTA")" "$PERFIL"

# Lo creado la vez anterior se quita primero (así desaparecen las que ya no estén en la lista)
if [ -f "$LISTA" ]; then
    while read -r f; do
        [ -n "$f" ] || continue
        id="$(basename "$f" .desktop)"
        rm -f "$f"; rm -rf "${HOME:?}/.local/share/${id:?}"   # (las de Epiphany de antes tenían un perfil propio)
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
    # Clase de ventana «webapp-<nombre en minúsculas y sin espacios>»: la barra y Hyprland la reconocen por ella
    slug="$(printf '%s' "$nombre" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')"
    id="webapp-$slug"
    host="$(sed -E 's|^[a-z]+://||; s|[:/].*||' <<< "$url")"
    clase="chrome-${host}__-${slug}"   # así llama Chromium a la ventana (app_id): host, ruta vacía y perfil
    entrada="$APPS/$id.desktop"
    cat > "$entrada" <<EOF
[Desktop Entry]
Type=Application
Name=$nombre
Comment=$nombre (web app, en su propia ventana)
Exec=chromium --app=$url --user-data-dir=$PERFIL --profile-directory=$slug --ozone-platform=wayland --no-first-run --no-default-browser-check --disable-background-networking --disable-sync --disable-extensions --enable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxZeroCopyGL
Icon=${icono:-applications-internet}
StartupWMClass=$clase
Terminal=false
Categories=Network;
X-MyArch-WebApp=true
EOF
    echo "$entrada" >> "$LISTA"
    echo "web app: $nombre → $url"
done
update-desktop-database "$APPS" 2>/dev/null || true
