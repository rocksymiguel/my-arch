# my-arch

Mi instalación de Arch Linux con Hyprland: listas de paquetes, dotfiles y guía de instalación.

## Estructura

| Carpeta | Qué hay |
|---|---|
| `dotfiles/` | Configuraciones (`~/.config/hypr`, `waybar`, `kitty`, `rofi`, `swaync`, `waypaper`, `gtk-3.0`, `gtk-4.0`, cursor) |
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
Los archivos que genera (`colors.lua`, `colors.css`, `rofi.ini`, `swaync/config`…) no se versionan:
en un equipo nuevo, después de `./link.sh`, ejecuta `tema oscuro`.

## Vidrio

```bash
vidrio            # muestra el modo activo y los disponibles
vidrio total      # todas las ventanas translúcidas (activa 85 %, inactivas 60 %)
vidrio oscurecer  # las inactivas se oscurecen un 35 %, como desactivadas
```

Los modos están en `dotfiles/.config/theme/vidrio/*.glass`. Si no hay ninguno elegido, se usa `oscurecer`.

## Fondos

En `~/Imágenes/Fondos` (no se versionan): los que llevan `Dark Mode` en el nombre
son para `tema oscuro` y los que llevan `Light Mode`, para `tema claro`. Al cambiar de tema
se pone uno de ese modo, salvo que el actual ya lo sea.

## Barra

Islas: escritorios con iconos de apps, música (MPRIS, p. ej. Feishin), reloj y tiempo (wttr.in, Daule),
CPU/RAM/temperatura, bandeja, brillo/volumen/Bluetooth/Wi-Fi, batería, ajustes () y apagado ().
Los menús están en `dotfiles/.config/waybar/scripts/`.

## Inactividad, fondos y música

Desde el menú de ajustes () o con comandos:

```bash
inactividad ver                 # valores actuales (minutos, 0 = nunca)
inactividad atenuar 5           # atenuar, bloquear, apagar, suspender
fondos siguiente                # siguiente fondo del modo actual
fondos rotar 10                 # rotar cada 10 min (0 = apagado)
musica                          # Super + F: mostrar/esconder Feishin
```

`hypridle.conf` lo genera `inactividad` (no se versiona).

## Terminal

**fish** es la shell del usuario (TTY y kitty); bash queda solo para los scripts. Prompt de una línea con **starship** (`~/.config/starship.toml`) y fastfetch al abrir.

```bash
ls / ll / la / tree    # eza con iconos
cat archivo            # bat con colores
z carpeta              # zoxide: cd inteligente
y                      # yazi: gestor de archivos en la terminal
Ctrl+R / Ctrl+T        # fzf: historial / archivos
```

## Capturas y grabación

- Impr: elegir zona y editarla con satty · Shift+Impr: pantalla completa a ~/Imágenes/Capturas
- Super+Shift+R: grabar pantalla (isla roja ⏺ REC; clic o el atajo para parar) → ~/Vídeos/Grabaciones
- "Selector de color" en el lanzador (hyprpicker): copia el color de un punto de la pantalla
