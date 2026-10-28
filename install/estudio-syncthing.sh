#!/bin/bash
# Deja Syncthing listo en esta laptop para el vault de Obsidian del NAS:
#   - sin descubrimiento global ni relés: solo habla con el NAS por Tailscale (o por la red de casa);
#   - la carpeta ~/Documentos/obsidian-vault es la misma del NAS (Emulacion/obsidian-vault);
#   - ignora lo que es de cada equipo (el workspace.json de Obsidian).
# Se puede repetir sin problema. Sin argumentos solo prepara esta parte y enseña el ID de esta
# laptop, para pegarlo en el Syncthing del TrueNAS. Con el ID del NAS lo empareja y le comparte la carpeta:
#   bash ~/my-arch/install/estudio-syncthing.sh <ID-del-Syncthing-del-NAS>
# Para pruebas: SYNCTHING_BIN, SYNCTHING_HOME, SYNCTHING_GUI y VAULT_LOCAL cambian el ejecutable, su carpeta
# de datos, su puerto y la carpeta del vault.
set -euo pipefail

ST="${SYNCTHING_BIN:-syncthing}"
ARGS=(); [ -n "${SYNCTHING_HOME:-}" ] && ARGS+=(--home="$SYNCTHING_HOME")
VAULT="${VAULT_LOCAL:-$HOME/Documentos/obsidian-vault}"
ID_CARPETA=obsidian-vault
NAS_TS="${NAS_TAILSCALE:-truenas-scale}"
NAS_ID="${1:-}"
PUERTO_NAS="${NAS_SYNCTHING_PUERTO:-22000}"   # puerto de sincronización de la app del TrueNAS

cli() { "$ST" cli "${ARGS[@]}" "$@"; }

command -v "$ST" >/dev/null 2>&1 || { echo "Syncthing no está instalado: ejecuta antes  bash ~/my-arch/install/post.sh estudio" >&2; exit 1; }

# El servicio de usuario tiene que estar en marcha (y la API, escuchando)
if [ -z "${SYNCTHING_HOME:-}" ]; then
    systemctl --user enable --now syncthing.service 2>/dev/null || true
fi
for _ in $(seq 1 40); do cli show system >/dev/null 2>&1 && break; sleep 1; done
cli show system >/dev/null 2>&1 || { echo "Syncthing no responde. Mira: systemctl --user status syncthing" >&2; exit 1; }

echo "==> Opciones: solo por Tailscale o la red de casa, sin servidores públicos"
cli config options global-ann-enabled set false
cli config options relays-enabled set false
cli config options natenabled set false
cli config options uraccepted set -- -1   # no enviar estadísticas de uso

echo "==> Carpeta del vault: $VAULT"
mkdir -p "$VAULT"
cat > "$VAULT/.stignore" <<'EOF'
// Lo que Obsidian guarda por equipo (ventanas abiertas, caché): no se sincroniza
**/.obsidian/workspace.json
**/.obsidian/workspaces.json
**/.obsidian/cache
// Restos de edición
**/*.tmp
**/*.sync-conflict-*
EOF
if cli config folders list | grep -qx "$ID_CARPETA"; then
    echo "    ya estaba configurada"
else
    cli config folders add --id "$ID_CARPETA" --label "Obsidian (NAS)" --path "$VAULT" --type sendreceive
fi

ID_LOCAL="$(cli show system | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["myID"])')"

if [ -n "$NAS_ID" ]; then
    DIR_NAS="$(tailscale ip -4 "$NAS_TS" 2>/dev/null | head -n 1 || true)"
    [ -n "$DIR_NAS" ] && DIRS="tcp://$DIR_NAS:$PUERTO_NAS" || DIRS="dynamic"
    echo "==> Emparejando con el NAS ($NAS_ID) en $DIRS"
    if cli config devices list | grep -qx "$NAS_ID"; then
        echo "    el NAS ya estaba emparejado"
    else
        cli config devices add --device-id "$NAS_ID" --name "truenas-scale" --addresses "$DIRS"
    fi
    if cli config folders "$ID_CARPETA" devices list 2>/dev/null | grep -qx "$NAS_ID"; then
        echo "    la carpeta ya estaba compartida con el NAS"
    else
        cli config folders "$ID_CARPETA" devices add --device-id "$NAS_ID"
    fi
    echo "    Listo: en cuanto el NAS acepte esta laptop, empieza a sincronizar."
fi

echo
echo "ID de esta laptop en Syncthing (pégalo en el Syncthing del TrueNAS):"
echo "  $ID_LOCAL"
