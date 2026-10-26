#!/bin/bash
# Fase 1: instalación base de Arch desde el USB (archiso), hasta antes de Hyprland.
# Borra el disco elegido, instala un Arch mínimo con systemd-boot, NetworkManager, zram y sudo,
# y copia este repositorio a ~/my-arch del usuario nuevo para la fase 2.
#
# Antes: arrancar el USB en modo UEFI y tener internet (cable, o Wi-Fi con iwctl).
# Uso:   bash my-arch/install/base.sh
#
# Todo se pregunta, pero se puede dar por variables (útil en la VM):
#   DISCO=/dev/vda EQUIPO=arch USUARIO=yo ZONA=America/Guayaquil IDIOMA=es_EC.UTF-8 TECLADO=us
# Las contraseñas siempre se escriben a mano.
set -euo pipefail

R="$(cd "$(dirname "$0")/.." && pwd)"   # raíz del repositorio
MNT=/mnt

paso() { printf '\n\e[1;34m==> %s\e[0m\n' "$*"; }
error() { printf '\e[1;31mError: %s\e[0m\n' "$*" >&2; exit 1; }
preguntar() {   # preguntar VARIABLE "Texto" "valor por defecto"
    local var="$1" texto="$2" def="$3" r
    [ -n "${!var:-}" ] && return
    read -rp "$texto [$def]: " r
    printf -v "$var" '%s' "${r:-$def}"
}
contrasena() {   # contrasena VARIABLE "Texto"
    local var="$1" texto="$2" a b
    while true; do
        read -rsp "$texto: " a; echo
        read -rsp "Repítela: " b; echo
        [ -n "$a" ] && [ "$a" = "$b" ] && break
        echo "No coinciden o está vacía. Otra vez."
    done
    printf -v "$var" '%s' "$a"
}

# ---------------------------------------------------------------------------
paso "Comprobaciones"
[ "$(id -u)" -eq 0 ] || error "ejecútalo como root desde el USB de Arch"
[ -d /run/archiso ] || error "esto se ejecuta desde el USB de Arch (archiso), no en un sistema instalado"
[ "$(cat /sys/firmware/efi/fw_platform_size 2>/dev/null)" = 64 ] \
    || error "no arrancó en modo UEFI de 64 bits (en la VM: activa EFI)"
ping -c 1 -W 3 archlinux.org >/dev/null 2>&1 || error "sin internet. Cable: debería ir solo. Wi-Fi: iwctl → station wlan0 connect <red>"
timedatectl set-ntp true

# ---------------------------------------------------------------------------
paso "Datos de la instalación"
USB="$(lsblk -no PKNAME "$(findmnt -no SOURCE /run/archiso/bootmnt 2>/dev/null)" 2>/dev/null || true)"
echo "Discos:"
lsblk -dpno NAME,SIZE,MODEL -e 7,11 | grep -v "/dev/${USB:-ninguno} " || true
DEF_DISCO="$(lsblk -dpno NAME -e 7,11 | grep -v "/dev/${USB:-ninguno}$" | head -n1)"
preguntar DISCO "Disco donde instalar (SE BORRA ENTERO)" "$DEF_DISCO"
[ -b "$DISCO" ] || error "$DISCO no es un disco"
[ "$(lsblk -dno TYPE "$DISCO")" = disk ] || error "$DISCO no es un disco entero (pon /dev/sda, no /dev/sda1)"

preguntar EQUIPO "Nombre del equipo" "arch"
preguntar USUARIO "Usuario" "rocksymiguel"
[[ "$USUARIO" =~ ^[a-z_][a-z0-9_-]*$ ]] || error "usuario no válido: minúsculas, números, - y _"
preguntar ZONA "Zona horaria" "America/Guayaquil"
[ -f "/usr/share/zoneinfo/$ZONA" ] || error "zona horaria desconocida: $ZONA"
preguntar IDIOMA "Idioma" "es_EC.UTF-8"
preguntar TECLADO "Teclado de la consola" "us"
contrasena CLAVE_USUARIO "Contraseña de $USUARIO (también será la de sudo)"
contrasena CLAVE_ROOT "Contraseña de root"

# Microcódigo según la CPU
case "$(grep -m1 vendor_id /proc/cpuinfo | awk '{print $3}')" in
    AuthenticAMD) UCODE=amd-ucode ;;
    GenuineIntel) UCODE=intel-ucode ;;
    *) UCODE="" ;;
esac
VIRT="$(systemd-detect-virt || true)"

echo
echo "Disco:    $DISCO ($(lsblk -dno SIZE "$DISCO")) → EFI 1 GB + ext4 el resto"
echo "Equipo:   $EQUIPO · usuario $USUARIO · $ZONA · $IDIOMA · teclado $TECLADO"
echo "CPU:      ${UCODE:-sin microcódigo} · virtualización: $VIRT"
echo
read -rp "Se borrará TODO $DISCO. Escribe BORRAR para seguir: " ok
[ "$ok" = BORRAR ] || error "cancelado"

# ---------------------------------------------------------------------------
paso "Particiones"
umount -R "$MNT" 2>/dev/null || true
swapoff -a 2>/dev/null || true
wipefs -af "$DISCO"
sgdisk --zap-all "$DISCO"
sgdisk -n1:0:+1G -t1:ef00 -c1:EFI -n2:0:0 -t2:8304 -c2:arch "$DISCO"
partprobe "$DISCO"
udevadm settle
# nvme0n1 y mmcblk0 llevan "p" antes del número; sda y vda no
case "$DISCO" in *[0-9]) P="${DISCO}p" ;; *) P="$DISCO" ;; esac
EFI="${P}1"
RAIZ="${P}2"

mkfs.fat -F 32 -n EFI "$EFI"
mkfs.ext4 -F -L arch "$RAIZ"
mount "$RAIZ" "$MNT"
mount --mkdir -o fmask=0077,dmask=0077 "$EFI" "$MNT/boot"

# ---------------------------------------------------------------------------
paso "Sistema base (pacstrap)"
sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
# shellcheck disable=SC2206  # $UCODE sin comillas: si está vacío, no se añade
PAQUETES=(base linux linux-firmware $UCODE base-devel sudo nano man-db man-pages git
          networkmanager openssh zram-generator efibootmgr)
pacstrap -K "$MNT" "${PAQUETES[@]}"
genfstab -U "$MNT" >> "$MNT/etc/fstab"

# ---------------------------------------------------------------------------
paso "Configuración"
# pacman: descargas en paralelo, colores y multilib (Steam y lib32 en la fase 2)
sed -i -e 's/^#\?ParallelDownloads.*/ParallelDownloads = 5/' -e 's/^#Color/Color/' \
    -e '/^#\[multilib\]/{s/^#//;n;s/^#//}' "$MNT/etc/pacman.conf"

ln -sf "/usr/share/zoneinfo/$ZONA" "$MNT/etc/localtime"
sed -i -e "s/^#\($IDIOMA\)/\1/" -e 's/^#\(en_US.UTF-8\)/\1/' "$MNT/etc/locale.gen"
echo "LANG=$IDIOMA" > "$MNT/etc/locale.conf"
echo "KEYMAP=$TECLADO" > "$MNT/etc/vconsole.conf"
echo "$EQUIPO" > "$MNT/etc/hostname"
cat > "$MNT/etc/hosts" <<EOF
127.0.0.1 localhost
::1       localhost
127.0.1.1 $EQUIPO.localdomain $EQUIPO
EOF

# Swap en RAM comprimida
printf '[zram0]\nzram-size = ram / 2\ncompression-algorithm = zstd\n' > "$MNT/etc/systemd/zram-generator.conf"

# Wi-Fi Realtek RTL8822CE (Lenovo): sin ahorro de energía, que lo hace caerse
if lspci -n | grep -qi '10ec:c822'; then
    printf 'options rtw88_core disable_lps_deep=y\noptions rtw88_pci disable_aspm=y\n' > "$MNT/etc/modprobe.d/rtw88.conf"
    echo "Ajuste para Realtek RTL8822CE aplicado"
fi

# Las redes Wi-Fi conectadas con iwctl en el USB pasan a NetworkManager
for f in /var/lib/iwd/*.psk; do
    [ -e "$f" ] || continue
    ssid="$(basename "$f" .psk)"
    [[ "$ssid" == =* ]] && continue   # nombres con caracteres raros: se conectan a mano
    clave="$(sed -n 's/^Passphrase=//p' "$f")"
    [ -n "$clave" ] || clave="$(sed -n 's/^PreSharedKey=//p' "$f")"
    [ -n "$clave" ] || continue
    nm="$MNT/etc/NetworkManager/system-connections/$ssid.nmconnection"
    cat > "$nm" <<EOF
[connection]
id=$ssid
type=wifi

[wifi]
mode=infrastructure
ssid=$ssid

[wifi-security]
key-mgmt=wpa-psk
psk=$clave

[ipv4]
method=auto

[ipv6]
method=auto
EOF
    chmod 600 "$nm"
    echo "Wi-Fi guardado: $ssid"
done

arch-chroot "$MNT" /bin/bash -e <<EOF
hwclock --systohc
locale-gen >/dev/null
useradd -m -G wheel -s /bin/bash "$USUARIO"
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel
visudo -cf /etc/sudoers.d/wheel >/dev/null
systemctl enable NetworkManager sshd systemd-timesyncd fstrim.timer
EOF
printf '%s:%s\nroot:%s\n' "$USUARIO" "$CLAVE_USUARIO" "$CLAVE_ROOT" | arch-chroot "$MNT" chpasswd
unset CLAVE_USUARIO CLAVE_ROOT

# ---------------------------------------------------------------------------
paso "Arranque (systemd-boot)"
# La fase 2 añade Limine con el menú Escritorio/Juego; systemd-boot queda de respaldo.
arch-chroot "$MNT" bootctl install
UUID="$(blkid -s UUID -o value "$RAIZ")"
printf 'default arch.conf\ntimeout 3\neditor no\n' > "$MNT/boot/loader/loader.conf"
cat > "$MNT/boot/loader/entries/arch.conf" <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=$UUID rw
EOF
grep -q "UUID=$UUID" "$MNT/boot/loader/entries/arch.conf" || error "la entrada de arranque no tiene UUID"

# ---------------------------------------------------------------------------
paso "Repositorio para la fase 2"
H="$MNT/home/$USUARIO"
if [ -d "$R/.git" ]; then
    cp -a "$R" "$H/my-arch"
else
    git clone https://github.com/rocksymiguel/my-arch.git "$H/my-arch" \
        || echo "No se pudo clonar: en el sistema nuevo, clona my-arch en ~/my-arch"
fi
[ -d "$H/my-arch" ] && arch-chroot "$MNT" chown -R "$USUARIO:$USUARIO" "/home/$USUARIO/my-arch"

# ---------------------------------------------------------------------------
paso "LISTO"
sync
umount -R "$MNT"
echo "Instalado en $DISCO. Quita el USB y reinicia con: reboot"
echo "Después entra como $USUARIO y sigue con la fase 2 (Hyprland y el tema)."
