#!/usr/bin/env bash
# nas.sh: monta los recursos SMB de TrueNAS en /mnt/truenas/* con automontaje.
# Ejecutar con: sudo bash nas.sh   (pide usuario y contraseña del NAS; no se guardan en el repo)
# Dirección del NAS: NAS_IP si se da; si no, la de Tailscale (el NAS se llama NAS_TAILSCALE, por defecto
# truenas-scale), que sirve en casa y fuera; y si no hay, la de casa. Si las líneas ya estaban en
# /etc/fstab, se actualiza solo la dirección (las zen-sync y demás usan la ruta /mnt/truenas/…, no la IP).
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Ejecútalo con sudo."; exit 1; }

NAS_TS=${NAS_TAILSCALE:-truenas-scale}
SERVIDOR=${NAS_IP:-}
if [ -z "$SERVIDOR" ] && command -v tailscale >/dev/null 2>&1; then
  SERVIDOR="$(tailscale ip -4 "$NAS_TS" 2>/dev/null | head -n 1 || true)"
  # solo si de verdad contesta por SMB desde aquí
  if [ -n "$SERVIDOR" ] && ! timeout 5 bash -c "</dev/tcp/$SERVIDOR/445" 2>/dev/null; then SERVIDOR=""; fi
fi
SERVIDOR=${SERVIDOR:-192.168.18.42}
echo "NAS: $SERVIDOR"
RECURSOS=(Emulacion Anime Movies Shows)
CRED=/etc/samba/truenas.cred
UID_U=${SUDO_UID:-1000}
GID_U=${SUDO_GID:-1000}

pacman -S --needed --noconfirm cifs-utils

if [ ! -f "$CRED" ]; then
  read -rp "Usuario SMB del NAS [rocksymiguel]: " U
  U=${U:-rocksymiguel}
  read -rsp "Contraseña de $U (no se muestra): " P; echo
  install -d -m 755 /etc/samba
  (umask 077; printf 'username=%s\npassword=%s\n' "$U" "$P" > "$CRED")
  chmod 600 "$CRED"; unset P
fi

OPC="credentials=$CRED,uid=$UID_U,gid=$GID_U,iocharset=utf8,file_mode=0644,dir_mode=0755,soft,noauto,x-systemd.automount,x-systemd.idle-timeout=600,x-systemd.mount-timeout=10,_netdev,nofail"

cp -n /etc/fstab /etc/fstab.antes-de-nas   # copia del original, una sola vez
for r in "${RECURSOS[@]}"; do
  dir=/mnt/truenas/${r,,}
  mkdir -p "$dir"
  if grep -qF " $dir " /etc/fstab; then
    sed -i -E "s#^//[^/ ]+/$r( $dir )#//$SERVIDOR/$r\1#" /etc/fstab   # solo cambia la dirección
  else
    echo "//$SERVIDOR/$r $dir cifs $OPC 0 0" >> /etc/fstab
  fi
done

systemctl daemon-reload
for r in "${RECURSOS[@]}"; do
  ruta="/mnt/truenas/${r,,}"
  # si está montado con la dirección vieja, se suelta (si está en uso, se actualiza tras 10 min sin uso)
  systemctl stop "$(systemd-escape -p --suffix=mount "$ruta")" 2>/dev/null || echo "   $ruta en uso: se actualizará al quedar libre"
  systemctl restart "$(systemd-escape -p --suffix=automount "$ruta")"
done

echo "== Comprobación"
for r in "${RECURSOS[@]}"; do
  dir=/mnt/truenas/${r,,}
  if timeout 15 ls "$dir" >/dev/null 2>&1; then echo "OK   $dir"; else echo "FALLA $dir"; fi
done
