#!/usr/bin/env bash
# nas.sh: monta las carpetas compartidas (SMB) del NAS en /mnt/truenas/* con automontaje, usando el nombre
# corto del NAS (p. ej. «nas»). El servicio nas-dir mantiene ese nombre (y los demás equipos de tu lista)
# apuntando a la dirección de Tailscale si responde y, si no, a la de tu red de casa.
# Ejecutar con: sudo bash nas.sh      (pide el usuario y la contraseña del NAS la primera vez; no se guardan en el repo)
# Lee tus datos de ~/.config/my-arch/personal.env (se crea con install/personalizar.sh).
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Ejecútalo con sudo."; exit 1; }

D="$(cd "$(dirname "$0")" && pwd)"
USUARIO_REAL="${SUDO_USER:-root}"
HOGAR="$(getent passwd "$USUARIO_REAL" | cut -d: -f6)"
PERSONAL="$HOGAR/.config/my-arch/personal.env"
EQUIPOS="" NAS_NOMBRE="" NAS_USUARIO_SMB="" NAS_RECURSOS=""
# shellcheck disable=SC1090
[ -f "$PERSONAL" ] && source "$PERSONAL"
[ -n "$NAS_NOMBRE" ] || { echo "No hay NAS en $PERSONAL (NAS_NOMBRE vacío): nada que montar. Para configurarlo: bash $D/personalizar.sh"; exit 0; }

# ---- 1. Nombres cortos que siguen a la mejor dirección (Tailscale primero, casa si no) ------------------
echo "==> nas-dir: los nombres cortos siguen a la mejor dirección"
install -m 755 "$D/nas-dir/nas-dir" /usr/local/bin/nas-dir
install -m 644 "$D/nas-dir/nas-dir.service" "$D/nas-dir/nas-dir.timer" /etc/systemd/system/
if [ -d /etc/NetworkManager/dispatcher.d ]; then
    install -m 755 -o root -g root "$D/nas-dir/90-nas-dir" /etc/NetworkManager/dispatcher.d/90-nas-dir
fi
{
    echo "# Lo escribe install/nas.sh a partir de ~/.config/my-arch/personal.env. Formato: nombre dirección_tailscale dirección_de_casa"
    for e in $EQUIPOS; do
        IFS=: read -r n ts lan <<< "$e"
        echo "$n ${ts:--} ${lan:--}"
    done
} > /etc/nas-dir.conf
systemctl daemon-reload
systemctl enable --now nas-dir.timer
/usr/local/bin/nas-dir
getent hosts "$NAS_NOMBRE" || { echo "El nombre $NAS_NOMBRE no se resuelve: revisa EQUIPOS en $PERSONAL" >&2; exit 1; }

# ---- 2. Montajes --------------------------------------------------------------------------------------
[ -n "$NAS_RECURSOS" ] || { echo "NAS_RECURSOS vacío: no hay carpetas que montar."; exit 0; }
CRED=/etc/samba/truenas.cred
UID_U="$(id -u "$USUARIO_REAL")"
GID_U="$(id -g "$USUARIO_REAL")"

pacman -S --needed --noconfirm cifs-utils

if [ ! -f "$CRED" ]; then
  read -rp "Usuario SMB del NAS [${NAS_USUARIO_SMB:-$USUARIO_REAL}]: " U
  U=${U:-${NAS_USUARIO_SMB:-$USUARIO_REAL}}
  read -rsp "Contraseña de $U (no se muestra): " P; echo
  install -d -m 755 /etc/samba
  (umask 077; printf 'username=%s\npassword=%s\n' "$U" "$P" > "$CRED")
  chmod 600 "$CRED"; unset P
fi

OPC="credentials=$CRED,uid=$UID_U,gid=$GID_U,iocharset=utf8,file_mode=0644,dir_mode=0755,soft,noauto,x-systemd.automount,x-systemd.idle-timeout=600,x-systemd.mount-timeout=10,_netdev,nofail"

cp -n /etc/fstab /etc/fstab.antes-de-nas   # copia del original, una sola vez
for r in $NAS_RECURSOS; do
  dir=/mnt/truenas/${r,,}
  mkdir -p "$dir"
  if grep -qF " $dir " /etc/fstab; then
    sed -i -E "s#^//[^/ ]+/$r( $dir )#//$NAS_NOMBRE/$r\\1#" /etc/fstab   # solo cambia el servidor
  else
    echo "//$NAS_NOMBRE/$r $dir cifs $OPC 0 0" >> /etc/fstab
  fi
done

systemctl daemon-reload
for r in $NAS_RECURSOS; do
  ruta="/mnt/truenas/${r,,}"
  # si está montado con la dirección vieja, se suelta (si está en uso, se actualiza tras 10 min sin uso)
  systemctl stop "$(systemd-escape -p --suffix=mount "$ruta")" 2>/dev/null || echo "   $ruta en uso: se actualizará al quedar libre"
  systemctl restart "$(systemd-escape -p --suffix=automount "$ruta")"
done

echo "== Comprobación (el NAS «$NAS_NOMBRE» es $(getent hosts "$NAS_NOMBRE" | awk '{print $1}'))"
for r in $NAS_RECURSOS; do
  dir=/mnt/truenas/${r,,}
  if timeout 15 ls "$dir" >/dev/null 2>&1; then echo "OK   $dir"; else echo "FALLA $dir"; fi
done
