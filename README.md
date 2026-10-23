# my-arch

Mi instalación de Arch Linux con Hyprland: listas de paquetes, dotfiles y guía de instalación.

## Estructura

| Carpeta | Qué hay |
|---|---|
| `dotfiles/` | Configuraciones (`~/.config/hypr`, `waybar`, `kitty`, `fuzzel`, `mako`, `waypaper`, `gtk-3.0`, `gtk-4.0`, `~/.bashrc`, cursor) |
| `packages/repo.txt` | Paquetes de los repositorios oficiales instalados a mano |
| `packages/aur.txt` | Paquetes del AUR |
| `install/` | Guía de instalación manual (por ahora). Más adelante: `install.sh` único con módulos `iso`, `base`, `hardware/amd`, `hardware/nvidia`, `hyprland` |
| `link.sh` | Enlaza `dotfiles/` en `$HOME` |

## Uso en un equipo con Arch ya instalado

```bash
git clone https://github.com/<usuario>/my-arch.git ~/my-arch
cd ~/my-arch
sudo pacman -S --needed - < packages/repo.txt
paru -S --needed - < packages/aur.txt
./link.sh
```

## Actualizar las listas de paquetes

```bash
pacman -Qqen > packages/repo.txt
pacman -Qqem > packages/aur.txt
```

## Notas

- Hyprland 0.56+ usa configuración en **Lua**: `dotfiles/.config/hypr/hyprland.lua`.
- No guardar aquí contraseñas, claves Wi-Fi ni claves SSH.
