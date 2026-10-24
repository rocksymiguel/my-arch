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

## Tema

`~/.config/theme` define los colores de todo el escritorio:

```bash
tema            # siguiente modo: oscuro -> claro -> dinamico
tema oscuro     # Nord profundo (base)
tema claro      # Nord claro (Snow Storm)
tema dinamico   # colores del fondo actual con matugen
```

Los colores viven en `themes/*.colors` y las plantillas por programa en `templates/`.
Los archivos que genera (`colors.lua`, `colors.css`, `fuzzel.ini`, `mako/config`…) no se versionan:
en un equipo nuevo, después de `./link.sh`, ejecuta `tema oscuro`.

## Vidrio

```bash
vidrio            # muestra el modo activo y los disponibles
vidrio total      # todas las ventanas translúcidas (activa 85 %, inactivas 60 %)
vidrio oscurecer  # las inactivas se oscurecen un 35 %, como desactivadas
```

Los modos están en `dotfiles/.config/theme/vidrio/*.glass`. Si no hay ninguno elegido, se usa `oscurecer`.

## Animaciones y mosaico

```bash
animacion            # muestra el modo activo y los disponibles
animacion defecto    # las del ejemplo oficial ("pop" y fundidos)
animacion deslizar   # ventanas y escritorios se desplazan
animacion rebote     # pequeño rebote al aparecer
animacion rapidas    # casi instantáneas
animacion ninguna    # sin animaciones

mosaico dwindle      # cada ventana nueva divide el espacio en espiral
mosaico master       # una ventana principal y las demás apiladas
mosaico scrolling    # columnas que se desplazan de lado, al estilo Niri
```

Los modos de animación están en `dotfiles/.config/hypr/animaciones/*.lua`.
