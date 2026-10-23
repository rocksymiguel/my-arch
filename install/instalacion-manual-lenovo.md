# Instalar Arch Linux mínimo en la Lenovo

Equipo: Lenovo IdeaPad 3 15ADA05 (81W1) · Ryzen 5 3500U · Radeon Vega · 8 GB RAM
Wi-Fi Realtek RTL8822CE (`rtw88`) · NVMe 954 GB (`/dev/nvme0n1`) · UEFI, Secure Boot desactivado

Decisiones de esta guía (cámbialas si quieres otra cosa):

- Disco entero para Arch, **borra Fedora**.
- Particiones: EFI de 1 GB (FAT32) montada en `/boot` y el resto `ext4` para `/`.
- Swap en RAM comprimida (`zram-generator`), sin partición de swap.
- Arranque con `systemd-boot`.
- Red con `NetworkManager`. SSH con `openssh` para administrarla desde el PC.
- Idioma `es_EC.UTF-8`, zona `America/Guayaquil`, teclado `us` (igual que en Fedora).

---

## 0. Antes de borrar Fedora

- Copia lo que quieras conservar. En `~/Descargas` hay unos 842 MB; el resto está casi vacío.
- Ten a mano la clave del Wi-Fi `ROCKSY_5G`.
- Conecta el cargador.

## 1. Arrancar el USB

1. Apaga la laptop y conecta el USB.
2. Enciende y pulsa **F12** repetidamente (menú de arranque).
   Si no aparece: con la laptop apagada, pulsa el botón **Novo** (agujerito al lado del conector de carga) con un clip → *Boot Menu*.
3. Elige el USB (la entrada UEFI) → *Arch Linux install medium*.
4. Llegas a `root@archiso ~ #`.

Comprueba que arrancó en modo UEFI (debe salir `64`):

```
cat /sys/firmware/efi/fw_platform_size
```

## 2. Conectar el Wi-Fi

```
rfkill unblock all
iwctl
```

Dentro de `iwctl`:

```
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect ROCKSY_5G
exit
```

Comprueba:

```
ping -c 3 archlinux.org
timedatectl
```

Si `device list` sale vacío o no conecta: usa el móvil Android por USB con **Anclaje USB** activado; Arch lo usa como cable de red sin configurar nada.

## 3. (Recomendado) Seguir la instalación por SSH desde el PC

En la Lenovo:

```
passwd          # contraseña temporal para root, solo para la ISO
ip -br a        # anota la IP de wlan0
```

En PowerShell del PC (borra la huella vieja de Fedora si la IP es la misma):

```
ssh-keygen -R 192.168.18.61
ssh root@192.168.18.61
```

Así puedes copiar y pegar todo lo que sigue.

## 4. Particionar el disco ⚠️ BORRA TODO

Comprueba que el disco es `nvme0n1` (953,9G):

```
lsblk
```

Borra y crea las dos particiones:

```
sgdisk --zap-all /dev/nvme0n1
sgdisk -n1:0:+1G -t1:ef00 -c1:EFI -n2:0:0 -t2:8304 -c2:root /dev/nvme0n1
lsblk /dev/nvme0n1
```

Formatear y montar:

```
mkfs.fat -F 32 /dev/nvme0n1p1
mkfs.ext4 /dev/nvme0n1p2
mount /dev/nvme0n1p2 /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
```

## 5. Instalar el sistema base

```
pacstrap -K /mnt base linux linux-firmware amd-ucode networkmanager openssh sudo nano vim man-db base-devel git zram-generator
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
```

**No olvides `networkmanager`**: sin él te quedas sin Wi-Fi al reiniciar.

## 6. Configurar (dentro de `arch-chroot`)

Zona horaria y reloj:

```
ln -sf /usr/share/zoneinfo/America/Guayaquil /etc/localtime
hwclock --systohc
```

Idioma y teclado:

```
sed -i 's/^#es_EC.UTF-8/es_EC.UTF-8/; s/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=es_EC.UTF-8' > /etc/locale.conf
echo 'KEYMAP=us' > /etc/vconsole.conf
```

Nombre del equipo:

```
echo 'lenovo' > /etc/hostname
```

Usuario (las contraseñas las escribes tú):

```
passwd
useradd -m -G wheel guillo
passwd guillo
EDITOR=nano visudo
```

En `visudo`, quita el `#` de la línea `%wheel ALL=(ALL:ALL) ALL`, guarda con Ctrl+O y sal con Ctrl+X.

Swap en RAM (zram):

```
printf '[zram0]\nzram-size = ram / 2\ncompression-algorithm = zstd\n' > /etc/systemd/zram-generator.conf
```

Ajuste para que el Wi-Fi Realtek no se caiga por ahorro de energía:

```
printf 'options rtw88_core disable_lps_deep=y\noptions rtw88_pci disable_aspm=y\n' > /etc/modprobe.d/rtw88.conf
```

Servicios:

```
systemctl enable NetworkManager sshd
```

## 7. Gestor de arranque (systemd-boot)

```
bootctl install
printf 'default arch.conf\ntimeout 3\neditor no\n' > /boot/loader/loader.conf
cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /amd-ucode.img
initrd  /initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value /dev/nvme0n1p2) rw
EOF
cat /boot/loader/entries/arch.conf
```

La línea `options` debe tener un UUID, no quedar vacía.

## 8. Reiniciar

```
exit
umount -R /mnt
reboot
```

Quita el USB cuando se apague la pantalla.

## 9. Primer arranque

Entra como `guillo` y conecta el Wi-Fi:

```
nmcli device wifi connect ROCKSY_5G --ask
sudo pacman -Syu
ip -br a
```

Desde el PC, vuelve a poner la clave SSH para que `ssh lenovo` funcione sin contraseña:

```
ssh-keygen -R 192.168.18.61
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh guillo@192.168.18.61 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

(Si tu clave tiene otro nombre, cambia `id_ed25519.pub`.)

---

## Siguiente etapa (después de instalar)

- Gráficos AMD: `mesa vulkan-radeon`
- Audio: `pipewire pipewire-pulse wireplumber`
- Bluetooth: `bluez bluez-utils`
- Compositor: Hyprland, Niri, Sway o MangoWM, más terminal, lanzador y barra.
