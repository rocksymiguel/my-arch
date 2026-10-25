#!/usr/bin/env bash
# nas.sh: monta los recursos SMB de TrueNAS en /mnt/truenas/* con automontaje.
# Ejecutar con: sudo bash nas.sh   (pide usuario y contraseña del NAS; no se guardan en el repo)
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Ejecútalo con sudo."; exit 1; }

SERVIDOR=${NAS_IP:-192.168.18.42}
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

for r in "${RECURSOS[@]}"; do
  dir=/mnt/truenas/${r,,}
  mkdir -p "$dir"
  grep -qF " $dir " /etc/fstab || echo "//$SERVIDOR/$r $dir cifs $OPC 0 0" >> /etc/fstab
done

systemctl daemon-reload
for r in "${RECURSOS[@]}"; do
  unit=$(systemd-escape -p --suffix=automount "/mnt/truenas/${r,,}")
  systemctl restart "$unit"
done

echo "== Comprobación"
for r in "${RECURSOS[@]}"; do
  dir=/mnt/truenas/${r,,}
  if timeout 15 ls "$dir" >/dev/null 2>&1; then echo "OK   $dir"; else echo "FALLA $dir"; fi
done
