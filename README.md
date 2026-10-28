# my-arch

Mi instalación de Arch Linux con Hyprland: listas de paquetes, dotfiles y guía de instalación.

## Estructura

| Carpeta | Qué hay |
|---|---|
| `dotfiles/` | Configuraciones (`~/.config/hypr`, `waybar`, `kitty`, `rofi`, `swaync`) · GTK y cursor los genera `tema` |
| `packages/` | `comun.txt` (todos), por gráfica `amd`/`nvidia`/`intel.txt`, `portatil.txt`, opcionales `juego`/`nas`/`tailscale.txt`; AUR en `aur.txt` y `aur-juego.txt` |
| `install/` | `base.sh` (fase 1, desde el USB), `post.sh` (fase 2), `detectar.sh` (hardware), scripts del sistema y la guía manual de la Lenovo |
| `link.sh` | Enlaza `dotfiles/` en `$HOME` |

## Instalar desde cero (fase 1)

Desde el USB de Arch, en modo UEFI y con internet (cable, o Wi-Fi con `iwctl`):

```bash
git clone https://github.com/rocksymiguel/my-arch.git   # o copiarlo en otro USB
bash my-arch/install/base.sh
```

Pregunta el disco (**lo borra entero**), el nombre del equipo, el usuario, la zona, el idioma y las contraseñas.
Instala un Arch mínimo: EFI de 1 GB + ext4, systemd-boot, NetworkManager, SSH, zram, sudo y multilib,
con el microcódigo de la CPU. Las redes Wi-Fi de `iwctl` pasan a NetworkManager y el repositorio se copia a
`~/my-arch` del usuario nuevo. Para la VM se pueden dar los datos por variables:
`DISCO=/dev/sda USUARIO=yo bash my-arch/install/base.sh`.

## Instalar Hyprland y el tema (fase 2)

Después de reiniciar, entra con tu usuario (sin sudo):

```bash
bash ~/my-arch/install/post.sh
```

`detectar.sh` mira el equipo y `post.sh` decide qué instalar:

| Detecta | Instala |
|---|---|
| Gráfica AMD / NVIDIA / Intel (o varias) | `packages/amd.txt` / `nvidia.txt` / `intel.txt`; con NVIDIA, sus módulos en el initramfs y variables para Hyprland |
| Batería (portátil) | TLP (`portatil.txt`, `energia.sh`) |
| Máquina virtual | open-vm-tools, VirtualBox guest o qemu-guest-agent, sin drivers de gráfica |
| Resolución | Fondos de Limine a ese tamaño |

Pregunta el modo juego (Steam + Gamescope y la entrada «Juego» en Limine), el NAS y Tailscale
(o `JUEGO=si NAS=no TAILSCALE=no bash ~/my-arch/install/post.sh`). Luego instala paru y el AUR,
pone fish, enlaza los dotfiles, aplica `tema oscuro` y ejecuta zram, sistema, energía, Limine,
Plymouth y el arranque limpio. Los fondos se copian de `~/my-arch/fondos/` si existe.

## Lo personal (NAS, estudio, web apps)

Un resumen de todo está en [`RESUMEN.md`](RESUMEN.md). En un equipo ya instalado:

```bash
bash ~/my-arch/install/post.sh personal
```

Tus datos (direcciones del NAS, usuario, vault, web apps…) viven en `~/.config/my-arch/personal.env`, que **no** se sube al
repositorio y no lleva contraseñas. Si no existe, un asistente (`install/personalizar.sh`) te pregunta y lo crea;
`install/personal.ejemplo` explica cada línea. Así otra persona usa el mismo instalador con lo suyo (o sin NAS).

- **Nombres cortos** (`nas`, `proxmox`…): el servicio `nas-dir` los mantiene en `/etc/hosts` apuntando a la dirección de
  Tailscale si responde y, si no, a la de casa. Los montajes (`nas.sh`), Gelly, Syncthing y las web apps usan siempre el
  nombre, nunca una IP.
- **Obsidian y Syncthing** (`packages/estudio.txt`, `install/estudio-syncthing.sh`): `~/Documentos/obsidian-vault` se
  sincroniza con el NAS solo por Tailscale o la red de casa, con historial de versiones de 30 días en los dos lados.
- **Claude:** CLI oficial con el español y el dictado `/voice` puestos. En el lanzador, «Claude» (conversación nueva) y
  «Claude · elegir conversación» (`--resume`), en una ventana flotante de tamaño fijo dentro del vault.
- **Clases:** el botón del micrófono de la barra graba (roja con el contador mientras graba), transcribe en local
  (`faster-whisper`: «base» 6,8× el tiempo real y 0,5 GB; «small» 2,3× y 1,1 GB, medido en la Lenovo) y abre las carpetas.
  En la terminal: `grabar-clase [nombre]` y `transcribir <audio> [tiny|base|small|medium]`. `~/Grabaciones` es un atajo.
- **Web apps** (`install/webapps.sh`, `packages/webapps.txt`): las de `WEBAPPS` salen en el lanzador, cada una en su ventana,
  con Epiphany. Los logos se descargan al instalar (`install/iconos.sh`), no se guardan en el repo.
- **Lanzador limpio:** `packages/ocultar.txt` + `install/ocultar-apps.sh` esconden lo que no hace falta ver sin quitarle sus
  tipos de archivo.
- **Tapa:** cerrarla apaga la pantalla interna; al abrirla, `tapa-bin` devuelve el brillo si la inactividad lo había atenuado.
- **Atajos:** Super + Escape abre el menú de apagado (solo «Modo juego» pide confirmar). `ayuda` muestra la chuleta.

## Añadir paquetes

Al instalar algo nuevo a mano, añádelo a la lista que toque: `packages/comun.txt` si va en todos
los equipos, o a la de su gráfica u opcional.

## Notas

- Hyprland 0.56+ usa configuración en **Lua**: `dotfiles/.config/hypr/hyprland.lua`.
- No guardar aquí contraseñas, claves Wi-Fi ni claves SSH.

## Tema

`~/.config/theme` define los colores de todo el escritorio:

```bash
tema            # cambia de modo: oscuro <-> claro
tema oscuro     # Nord profundo (base)
tema claro      # Nord claro (Snow Storm)
tema acentos    # vuelve a sacar los acentos del fondo actual (sin reiniciar la barra)
```

El **modo** pone fondos, superficies, texto, GTK, iconos, cursor y carpetas; el **fondo de pantalla**
pone solo el acento (bordes de ventana, barra, lanzador, kitty, bloqueo) con matugen, en la variante
del modo. Al cambiar de fondo, o al rotar, se actualiza sin reiniciar waybar.

Los colores viven en `themes/*.colors` y las plantillas por programa en `templates/`.
Los archivos que genera (`colors.lua`, `colors.css`, la barra, rofi, swaync, `hyprlock.conf`…) no se versionan:
en un equipo nuevo, después de `./link.sh`, ejecuta `tema oscuro`.

## Tamaño

⚙ → Tamaño, o con un comando:

```bash
tamano          # muestra el actual
tamano 125      # de 50 a 200 %; 100 es el de la Lenovo
```

Cambia la barra, el lanzador y los menús, las notificaciones y los avisos (siguen bajo su isla), kitty,
el bloqueo, la separación, el borde y el redondeo de las ventanas, la letra de GTK y el cursor. Las
plantillas de `theme/templates` marcan cada medida como `{{e:N}}` (N px a 100 %) o `{{d:N}}` (letras,
con decimal) y `tema` las genera al tamaño elegido. Al instalar, `post.sh` elige uno según la densidad
de la pantalla (la Lenovo, ~102 ppp, es el 100 %; los monitores de escritorio, +10 %).

## Vidrio

```bash
vidrio            # muestra el modo activo y los disponibles
vidrio total      # todas las ventanas translúcidas (activa 85 %, inactivas 60 %)
vidrio oscurecer  # las inactivas se oscurecen un 35 %, como desactivadas
```

Los modos están en `dotfiles/.config/theme/vidrio/*.glass`. Si no hay ninguno elegido, se usa `oscurecer`.

```bash
vidrio medios si|no   # vídeo e imágenes opacos aunque el vidrio sea «total» (por defecto, sí)
```

Con el vidrio «total» las ventanas son translúcidas (75 % con foco, 10 % sin él) y los vídeos se veían lavados.
`mpv`, `imv` y Zen **con una pestaña de vídeo o de imagen** (se decide por el título: YouTube, Twitch,
Netflix…; la lista está en `hyprland.lua`) se dejan al 100 % con o sin foco. También está en ⚙ → Vidrio.

## Fondos

En `~/Imágenes/Fondos` (copiados de `fondos/` del repositorio por `post.sh`): los que llevan `Dark Mode` en el nombre
son para `tema oscuro` y los que llevan `Light Mode`, para `tema claro`. Al cambiar de tema
se pone uno de ese modo, salvo que el actual ya lo sea.

Super + W abre el selector con miniaturas (rofi): empieza en el modo actual y Tab alterna entre
oscuros y claros. Elegir un fondo del otro modo cambia también el modo. Las miniaturas se guardan
en `~/.cache/theme/miniaturas`; el último fondo, en `~/.cache/theme/fondo`.

## Barra

Islas: escritorios con iconos de apps, música (MPRIS, p. ej. gelly), reloj y tiempo (wttr.in, Daule),
CPU/RAM/temperatura, bandeja, brillo/volumen/Bluetooth/Wi-Fi, batería, ajustes () y apagado ().
Los menús están en `dotfiles/.config/waybar/scripts/`.

## Inactividad, fondos y música

Desde el menú de ajustes () o con comandos:

```bash
inactividad ver                 # valores actuales (minutos, 0 = nunca)
inactividad atenuar 5           # atenuar, bloquear, apagar, suspender
fondos elegir                   # selector con miniaturas (Super + W)
fondos siguiente                # siguiente fondo del modo actual
fondos rotar 10                 # rotar cada 10 min (0 = apagado)
musica                          # Super + G: mostrar/esconder gelly
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

## Arranque

Animación con plymouth. Cambiar de tema (regenera el arranque):

```bash
sudo bash ~/my-arch/install/plymouth.sh connect
```

## Modo juego

Al encender, Limine ofrece **Escritorio** (Hyprland) o **Juego** (Steam Big Picture con Gamescope). Inicio de sesión automático; el escritorio se abre bloqueado.

- Escritorio → juego: ⏻ → Modo juego (o `modo juego`)
- Juego → escritorio: Steam → Encendido → Cambiar a escritorio
- Instalar/reinstalar: `sudo bash ~/my-arch/install/modo-juego.sh`
