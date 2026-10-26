#!/bin/bash
# Fase 2: deja Hyprland y todo el tema como en la Lenovo, en cualquier equipo.
# Se ejecuta en el sistema ya instalado (después de base.sh), como tu usuario, no como root:
#   bash ~/my-arch/install/post.sh
# Detecta la gráfica (AMD, NVIDIA, Intel o máquina virtual) y si es portátil, instala los
# paquetes que tocan, paru y el AUR, enlaza los dotfiles y aplica los scripts del sistema.
# sudo pide tu contraseña una sola vez, al principio.
#
# Opcionales: se preguntan, o se dan por variables (si/no):
#   JUEGO=si NAS=no TAILSCALE=no bash ~/my-arch/install/post.sh
set -euo pipefail

D="$(cd "$(dirname "$0")" && pwd)"   # install/
R="$(dirname "$D")"                  # raíz del repositorio
P="$R/packages"

paso() { printf '\n\e[1;34m==> %s\e[0m\n' "$*"; }
error() { printf '\e[1;31mError: %s\e[0m\n' "$*" >&2; exit 1; }
preguntar() {   # preguntar VARIABLE "Texto" si|no
    local var="$1" texto="$2" def="$3" r
    [ -n "${!var:-}" ] && return
    read -rp "$texto (si/no) [$def]: " r
    r="${r:-$def}"
    [[ "$r" =~ ^[sS] ]] && printf -v "$var" si || printf -v "$var" no
}
trap 'printf "\e[1;31mFalló la línea %s de %s: %s\e[0m\n" "$LINENO" "$(basename "$0")" "$BASH_COMMAND" >&2' ERR
lista() { grep -v '^\s*#' "$P/$1" | grep . ; }   # paquetes de packages/<archivo>

# ---------------------------------------------------------------------------
paso "Comprobaciones"
[ "$(id -u)" -ne 0 ] || error "ejecútalo como tu usuario, sin sudo: bash $0"
[ "$R" = "$HOME/my-arch" ] || error "el repositorio tiene que estar en ~/my-arch (está en $R)"
ping -c 1 -W 3 archlinux.org >/dev/null 2>&1 || error "sin internet. Wi-Fi: nmcli device wifi connect <red> --ask"
sudo -v
# Contraseña una sola vez: renovar sudo cada minuto mientras dure el script
( while kill -0 "$$" 2>/dev/null; do sudo -n -v 2>/dev/null; sleep 60; done ) &
trap 'kill $! 2>/dev/null' EXIT
# Instalaciones hechas con un base.sh anterior: la regla de wheel pisaba las de sin contraseña
if sudo test -f /etc/sudoers.d/wheel; then sudo mv /etc/sudoers.d/wheel /etc/sudoers.d/00-wheel; fi
sudo pacman -S --needed --noconfirm pciutils >/dev/null   # lspci, para detectar la gráfica

# shellcheck source=detectar.sh
source "$D/detectar.sh"
resumen_hardware
echo
preguntar JUEGO "¿Modo juego (Steam con Gamescope, elegible en el arranque)?" si
preguntar NAS "¿Carpetas del NAS de casa (TrueNAS por SMB)?" no
preguntar TAILSCALE "¿Tailscale?" no

# ---------------------------------------------------------------------------
paso "pacman: multilib y descargas en paralelo"
sudo sed -i -e 's/^#\?ParallelDownloads.*/ParallelDownloads = 5/' -e 's/^#Color/Color/' \
    -e '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf
sudo pacman -Syu --noconfirm

# ---------------------------------------------------------------------------
paso "Paquetes"
PAQ=($(lista comun.txt))
for g in $GPUS; do
    [ "$VIRT" = none ] && PAQ+=($(lista "$g.txt"))
done
[ "$PORTATIL" = si ] && PAQ+=($(lista portatil.txt))
[ "$JUEGO" = si ] && PAQ+=($(lista juego.txt))
[ "$NAS" = si ] && PAQ+=($(lista nas.txt))
[ "$TAILSCALE" = si ] && PAQ+=($(lista tailscale.txt))
case "$VIRT" in
    vmware) PAQ+=(open-vm-tools) ;;
    oracle) PAQ+=(virtualbox-guest-utils) ;;
    kvm|qemu) PAQ+=(qemu-guest-agent spice-vdagent) ;;
esac
# power-profiles-daemon choca con TLP
[ "$PORTATIL" = si ] && pacman -Qq power-profiles-daemon >/dev/null 2>&1 \
    && sudo pacman -Rns --noconfirm power-profiles-daemon
sudo pacman -S --needed --noconfirm "${PAQ[@]}"

# ---------------------------------------------------------------------------
paso "paru y paquetes del AUR"
# Con poca RAM, compilar en Rust con muchos hilos la agota (paru, gelly)
[ "$(awk '/MemTotal/ {print $2}' /proc/meminfo)" -lt 6000000 ] && export CARGO_BUILD_JOBS=2
# paru se compila (paru-bin se queda atrás de pacman y no arranca: falta libalpm.so.N)
if ! paru --version >/dev/null 2>&1; then
    for v in paru-bin paru-bin-debug; do
        pacman -Qq "$v" >/dev/null 2>&1 && sudo pacman -Rns --noconfirm "$v"
    done
    tmp="$(mktemp -d)"
    git clone --depth 1 https://aur.archlinux.org/paru.git "$tmp/paru"
    (cd "$tmp/paru" && makepkg -si --noconfirm)
    rm -rf "$tmp"
fi
AUR=($(lista aur.txt))
[ "$JUEGO" = si ] && AUR+=($(lista aur-juego.txt))
paru -S --needed --noconfirm --sudoloop "${AUR[@]}"

# ---------------------------------------------------------------------------
paso "Servicios"
sudo systemctl enable bluetooth.service
[ "$PORTATIL" = si ] && sudo systemctl enable tlp.service
[ "$TAILSCALE" = si ] && sudo systemctl enable tailscaled.service
case "$VIRT" in
    vmware) sudo systemctl enable vmtoolsd.service vmware-vmblock-fuse.service ;;
    oracle) sudo systemctl enable vboxservice.service ;;
    kvm|qemu) sudo systemctl enable qemu-guest-agent.service ;;
esac
if [[ " $GPUS " == *" nvidia "* ]] && [ "$VIRT" = none ]; then
    # Hyprland con NVIDIA: vídeo por hardware y GLX de NVIDIA
    for v in LIBVA_DRIVER_NAME=nvidia __GLX_VENDOR_LIBRARY_NAME=nvidia; do
        grep -qx "$v" /etc/environment || echo "$v" | sudo tee -a /etc/environment >/dev/null
    done
fi

# ---------------------------------------------------------------------------
paso "Tu usuario: fish, carpetas, iconos y fondos"
[ "$(getent passwd "$USER" | cut -d: -f7)" = /usr/bin/fish ] || sudo chsh -s /usr/bin/fish "$USER"
xdg-user-dirs-update
FONDOS="$(xdg-user-dir PICTURES)/Fondos"
mkdir -p "$FONDOS"
[ -d "$R/fondos" ] && cp -n "$R"/fondos/* "$FONDOS"/ 2>/dev/null || true
echo "Fondos: $(find "$FONDOS" -maxdepth 1 -type f | wc -l) en $FONDOS"
# Copia personal de Papirus: tema cambia el color de las carpetas sin sudo
mkdir -p "$HOME/.local/share/icons"
for i in Papirus Papirus-Dark Papirus-Light; do
    [ -d "$HOME/.local/share/icons/$i" ] || cp -r "/usr/share/icons/$i" "$HOME/.local/share/icons/"
done

# ---------------------------------------------------------------------------
paso "Apps por defecto: imv para imágenes (con las de la carpeta) y mpv para vídeo"
xdg-mime default imv-dir.desktop image/png image/jpeg image/gif image/webp image/bmp image/tiff image/avif
xdg-mime default mpv.desktop video/mp4 video/x-matroska video/webm video/quicktime video/x-msvideo video/mpeg video/ogg

# ---------------------------------------------------------------------------
paso "Dotfiles y tema"
bash "$R/link.sh"
# Tamaño de la interfaz según la pantalla (si ya había uno elegido, se respeta)
mkdir -p "$HOME/.cache/theme"
[ -f "$HOME/.cache/theme/tamano" ] || echo "$TAMANO" > "$HOME/.cache/theme/tamano"
"$HOME/.config/theme/tema" oscuro
"$HOME/.config/theme/inactividad-bin"
"$HOME/.config/theme/fondos-bin" preparar 2>/dev/null || true   # logos de fastfetch

# ---------------------------------------------------------------------------
paso "Sistema: zram, menú de ajustes, energía y arranque"
sudo bash "$D/zram.sh"
sudo bash "$D/sistema.sh"
[ "$PORTATIL" = si ] && sudo bash "$D/energia.sh"
sudo bash "$D/modo-juego.sh"    # Limine e inicio automático (la entrada Juego, solo con Steam)
sudo bash "$D/plymouth.sh" connect
sudo bash "$D/arranque.sh"      # gráfica en el initramfs, Plymouth limpio y Limine
[ "$NAS" = si ] && sudo bash "$D/nas.sh"

# ---------------------------------------------------------------------------
paso "Limpieza: restos de compilar y descargas"
# Paquetes de depuración que deja makepkg (paru-debug…)
DEBUG=($(pacman -Qq | grep -- '-debug$' || true))
[ ${#DEBUG[@]} -gt 0 ] && sudo pacman -Rns --noconfirm "${DEBUG[@]}"
# Huérfanos (Rust, meson… que solo servían para compilar el AUR), coredumps y registros
sudo bash "$D/limpiar.sh"
# Nada en la caché de pacman: todo está recién instalado
sudo paccache -rk0 >/dev/null || true
# Compilaciones del AUR y caché de Rust
rm -rf "$HOME/.cache/paru/clone" "$HOME/.cargo/registry" "$HOME/.cargo/git"
df -h / | awk 'NR == 2 {print "Disco usado: " $3 " de " $2}'

# ---------------------------------------------------------------------------
paso "LISTO"
echo "Reinicia: Limine → Escritorio abre Hyprland con el tema oscuro."
[ "$(find "$FONDOS" -maxdepth 1 -type f | wc -l)" -gt 0 ] \
    || echo "Pon fondos en $FONDOS (con «Dark Mode» o «Light Mode» en el nombre) y ejecuta: sudo bash ~/my-arch/install/limine.sh"
