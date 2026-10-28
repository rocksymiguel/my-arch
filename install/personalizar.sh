#!/bin/bash
# Asistente: crea ~/.config/my-arch/personal.env con TUS datos (NAS, Syncthing, servicios, web apps).
# Se puede repetir: enseña lo que ya había como valor por defecto (Enter = dejarlo).
#   bash ~/my-arch/install/personalizar.sh
# No guarda contraseñas. El archivo es solo tuyo: no se sube al repositorio.
set -euo pipefail

D="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.config/my-arch/personal.env"
mkdir -p "$(dirname "$DEST")"

# Valores por defecto: lo que ya había y, si no, la plantilla
set +u
[ -f "$DEST" ] && source "$DEST" || source "$D/personal.ejemplo"
set -u

pregunta() {   # pregunta VARIABLE "Texto"   (Enter = dejar el valor que se muestra entre corchetes)
    local var="$1" texto="$2" r
    read -rp "$texto [${!var:-}]: " r
    printf -v "$var" '%s' "${r:-${!var:-}}"
}

echo "Vamos a guardar tus datos en $DEST"
echo "(Enter deja el valor que se muestra entre corchetes; escribe un guion - para dejarlo vacío.)"
echo
read -rp "¿Tienes un NAS en casa al que conectarte? (si/no) [si]: " NAS_SI; NAS_SI="${NAS_SI:-si}"

if [[ "$NAS_SI" =~ ^[sS] ]]; then
    echo
    echo "Equipos de tu red con nombre corto, «nombre:dirección_Tailscale:dirección_de_casa», separados por espacios."
    echo "Si un equipo no tiene Tailscale deja esa parte vacía:  proxmox::192.168.1.40"
    pregunta EQUIPOS "Equipos"
    pregunta NAS_NOMBRE "¿Cuál de esos nombres es el NAS?"
    pregunta NAS_USUARIO_SMB "Usuario de las carpetas compartidas del NAS"
    pregunta NAS_RECURSOS "Carpetas compartidas a montar (separadas por espacios)"
    echo
    pregunta VAULT_NOMBRE "Nombre de tu vault de Obsidian"
    pregunta SYNCTHING_NAS_ID "ID del Syncthing del NAS (se puede dejar vacío y ponerlo luego)"
    pregunta SYNCTHING_NAS_PUERTO "Puerto de sincronización del Syncthing del NAS"
    echo
    echo "Carpeta del NAS (ya montada) para sincronizar la sesión de Zen con zen-sync; - = no usarlo"
    pregunta ZEN_SYNC_DIR "Carpeta de zen-sync"
    pregunta GELLY_URL "Servidor de música de Gelly (Navidrome), p. ej. http://nas:4533"
    echo "Web apps del lanzador: «Nombre|dirección|icono» separadas por «;»  (Enter = las que hay)"
    pregunta WEBAPPS "Web apps"
else
    EQUIPOS=""; NAS_NOMBRE=""; NAS_USUARIO_SMB=""; NAS_RECURSOS=""; SYNCTHING_NAS_ID=""; SYNCTHING_NAS_PUERTO=22000
    GELLY_URL=""; WEBAPPS=""; ZEN_SYNC_DIR=""
    pregunta VAULT_NOMBRE "Nombre de tu vault de Obsidian"
fi
for v in EQUIPOS NAS_NOMBRE NAS_USUARIO_SMB NAS_RECURSOS VAULT_NOMBRE SYNCTHING_NAS_ID ZEN_SYNC_DIR GELLY_URL WEBAPPS; do
    [ "${!v}" = "-" ] && printf -v "$v" ''
done

umask 077
cat > "$DEST" <<EOF
# Datos personales (creado por install/personalizar.sh el $(date +%F)). No se sube al repositorio. Sin contraseñas.
EQUIPOS="${EQUIPOS}"
NAS_NOMBRE="${NAS_NOMBRE}"
NAS_USUARIO_SMB="${NAS_USUARIO_SMB}"
NAS_RECURSOS="${NAS_RECURSOS}"
VAULT_NOMBRE="${VAULT_NOMBRE}"
SYNCTHING_NAS_ID="${SYNCTHING_NAS_ID}"
SYNCTHING_NAS_PUERTO="${SYNCTHING_NAS_PUERTO:-22000}"
ZEN_SYNC_DIR="${ZEN_SYNC_DIR}"
GELLY_URL="${GELLY_URL}"
WEBAPPS="${WEBAPPS}"
EOF
echo
echo "Guardado: $DEST"
