# Traspaso: personalización de Arch + Hyprland en la Lenovo

Fecha: 2026-10-23 (actualizado el 2026-10-25). Para continuar en una conversación nueva.

**Responde siempre en español.** El usuario personaliza su Arch con Hyprland en la Lenovo, paso a paso, desde este PC con Windows por SSH.

## Acceso y reglas de trabajo

- `ssh lenovo` → `rocksymiguel@192.168.18.52` (clave `id_ed25519`). Para el shell remoto conviene usar la herramienta **Bash** (Git Bash), no PowerShell, porque PowerShell rompe las comillas.
- `sudo` pide contraseña: **el usuario la escribe**. Prepara un script, cópialo a la Lenovo y lánzalo en el panel Terminal con `ssh -t lenovo "sudo bash ~/script.sh"`. Para el AUR, ejecuta `paru` **sin** sudo y con `--sudoloop`. Nunca toques la configuración de sudo ni pidas contraseñas.
- Para actuar sobre la sesión gráfica desde SSH, exporta:
  `XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/1000/hypr | head -n1) DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus`
- Para ver la pantalla: `grim -g "0,0 1366x40" archivo.png` (solo la barra) o `grim archivo.png` (todo, si el usuario lo pide).
- **Cuidado al escribir archivos desde aquí:** los iconos Nerd Font de 3 bytes (U+E000–U+F8FF) **se pierden**. Usa solo iconos Material Design (U+F0000+) o escríbelos con `chr()` en Python en la Lenovo.
- No mandes dispatchers de prueba a la sesión del usuario: una vez se envió un "forzar cierre".
- En el CSS de GTK/waybar no se puede poner `/*` dentro de un comentario, porque mata waybar.

**Preferencias del usuario** (también están en la memoria):
- **Atajos:** solo los que pide y usa, sin duplicados. Pregunta antes de ocupar una tecla.
- **Cuando elige una opción entre varias, se borran las demás** (presets, comandos, alias).
- Le gusta probar en vivo y comparar, con opciones visuales. Antes de implementar algo grande, propón y pregunta. Cuando dice "no implementes", solo hay que proponer.
- Explicaciones claras y en español. Prefiere ligero, por la RAM.

## Equipo

Lenovo IdeaPad 3 15ADA05 · Ryzen 5 3500U · Vega 8 · **pantalla de 1366×768** · Wi-Fi RTL8822CE · NVMe de 954 GB.
⚠️ **RAM:** el módulo de la ranura falla a veces y solo quedan 3,2 GB de 8. Hay que tenerlo en cuenta con apps pesadas (shells de Quickshell).

## Sistema

Arch mínimo (systemd-boot, `linux` y `linux-lts`, zram, NetworkManager, PipeWire, paru). **Hyprland 0.56 con configuración en Lua** (`hyprland.lua`, API `hl.*`; los ejemplos están en `/usr/share/hypr/`, y las referencias en `/usr/share/hypr/stubs/hl.meta.lua`). Para validar: `Hyprland --verify-config`. Para recargar: `hyprctl reload`.

## Repositorio de dotfiles

`~/my-arch` en la Lenovo, subido a GitHub como **privado** en https://github.com/rocksymiguel/my-arch (remote SSH, `gh` con sesión en la Lenovo y en este PC). Las carpetas `~/.config/{hypr,waybar,kitty,rofi,swaync,waypaper,gtk-3.0,gtk-4.0,theme}` son **enlaces** a `~/my-arch/dotfiles`. Hay que editar ahí, hacer **commit y push** después de cada cambio aprobado, y actualizar el README cuando haga falta. Los archivos generados (colors.*, rofi/colors.rasi, swaync/style.css, hypridle.conf) están en `.gitignore`.

Comandos propios (alias en scripts en `~/.config/theme/`):

| Comando | Qué hace |
|---|---|
| `tema oscuro\|claro\|acentos` | Modo (paleta base Nord, GTK, iconos, cursor, carpetas) a partir de plantillas (`theme/templates`, `theme/themes/*.colors`). **Ya no hay modo dinámico:** el acento (bordes, barra, lanzador, kitty, bloqueo) sale siempre del fondo con matugen en la variante del modo. `tema acentos` lo actualiza sin reiniciar waybar (`reload_style_on_change`); cambiar de modo sí reinicia barra y bandeja |
| `vidrio total\|oscurecer` | Opacidad y desenfoque (`theme/vidrio/*.glass`). Total: ventanas al 75 % activas y 10 % inactivas; kitty igual |
| `inactividad [clave min]` | Genera `hypridle.conf` (atenuar, bloquear, apagar, suspender). Ahora: atenuar 10, lo demás nunca |
| `fondos elegir\|siguiente\|poner\|restaurar\|rotar N\|demonio` | Fondos de `~/Imágenes/Fondos` según el modo ("Dark Mode" / "Light Mode" en el nombre). `elegir` (Super + W) es el selector con miniaturas en rofi, Tab alterna oscuros/claros y elegir uno del otro modo cambia el modo; **waypaper se quitó**. awww pinta el fondo y `~/.cache/theme/fondo` recuerda el último. Rotación cada N minutos |
| `musica` (Super + G) | Muestra o esconde gelly en el escritorio especial `musica`, flotando a 490×540 |
| `hypr` | Abre Hyprland desde la TTY |

Estado actual: tema **claro**, vidrio **total**, rotación cada **5 min**.

## Lo que ya está hecho

- **Tema central:** Nord profundo (base oscura), Nord claro y dinámico. Fuentes compactas (JetBrains Mono Nerd), redondeo de 10, separación de 3 y 6, borde de 2 con degradado del tema. El modo claro tiene un borde más oscuro.
- **Hyprland:** animación **rebote medio** (`hypr/animaciones.lua`), layout **scrolling**, reglas (pantalla completa opaca y sin atenuar, diálogos centrados, progreso de Thunar flotante, vídeo flotante de Zen y gelly mini).
- **Atajos:** Super + Enter kitty · Espacio rofi · Z Zen · T Thunar · G gelly · W waypaper · L bloquear · Q cerrar · Shift + Q forzar cierre · B pantalla completa · Shift + B maximizar · M salir · V flotar · P pseudo · J división · S y Shift + S scratchpad · Shift + V portapapeles · Impr y Shift + Impr capturas · 1…0 escritorios · teclas Fn.
- **Waybar en islas:** escritorios **1-3 fijos** con iconos de apps · música (MPRIS; clic pausa, clic derecho muestra gelly) · reloj con fecha · tiempo de Daule (wttr.in) · CPU, RAM y temperatura (clic: btop) · bandeja (Wi-Fi y BT de nm-applet y blueman) · brillo y volumen · batería · 🔔 notificaciones (swaync: clic abre el panel, clic derecho "No molestar") · ⚙ ajustes · ⏻ apagado. La config se genera con iconos por código.
- **Lanzador rofi** minimalista (`rofi/config.rasi` + `colors.rasi` generado por tema). Clic fuera lo cierra. Apps que no usa escondidas con `.desktop` NoDisplay en `dotfiles/.local/share/applications`.
- **Menú de ajustes** (rofi, `waybar/scripts/menu-ajustes`): Tema, Vidrio, Inactividad (submenús de minutos y pausa), Fondo (elegir, siguiente, rotar) y Cursor. Al elegir vuelve atrás, Esc vuelve atrás, y antes de abrir cierra cualquier rofi atascado.
- **Menú de apagado:** bloquear, cerrar sesión, reiniciar y apagar, con confirmación.
- **Notificaciones swaync** (arriba a la derecha, panel con No molestar, música, volumen y brillo). **Avisos (OSD)** con `osd-bin` como notificaciones de swaync: volumen y brillo solo con barra; micrófono, Bloq Mayús y Bloq Num con texto. No van al historial. Bloq Num activado al iniciar.
- **Bloqueo** con `bloquear-bin` y hyprlock estilo completo: hora, fecha y tiempo, batería, música, aviso de Bloq Mayús (borde naranja = Mayús) y el fondo actual desenfocado. La rotación de fondos se congela mientras está bloqueado.
- **Apariencia:** GTK Nordic (oscuro) y Nordic-Polar (claro); carpetas en gris azulado u nordic (copia de Papirus en `~/.local/share/icons`, papirus-folders sin sudo), todo cambiado por `tema`. kitty con cursor de línea parpadeante y pestañas powerline. Zen con tema Nord (lo puso el usuario). Cursor por modo: Bibata Modern Ice en oscuro y Classic en claro (lo cambia `tema`). Las otras variantes de Bibata no se instalan (NoExtract en /etc/pacman.conf).
- **gelly** (AUR, compilado con `CARGO_BUILD_JOBS=2` para no agotar la RAM): arranca escondido en `special:musica`. Credenciales en gnome-keyring: llavero «login» con la contraseña del usuario, que desbloquea hyprlock al entrar (pam_gnome_keyring en /etc/pam.d/hyprlock). Su música está en Navidrome, en el NAS. Sustituyó a Feishin y Strawberry el 2026-10-25 tras medirlos: gelly 4 % CPU / 164 MB / +1,2 W; Strawberry 12 % / 149 MB / +2,3 W; Feishin 22 % / 356 MB / +1,8 W.

- **Modo avión:** `avion-bin vigilar` (arranca con Hyprland) escucha `rfkill event`; con el modo avión activo cierra nm-applet y blueman-applet y la isla `group/conexion` muestra solo el avión; al desactivarlo los vuelve a abrir. Ojo: en la sesión `rfkill` sale en español, por eso usa `LC_ALL=C`; usa un PID (no flock) porque los applets heredarían el candado.
- **Lanzador:** `lanzador-bin` (Super + Espacio) calcula el ancho de rofi según el nombre de app visible más largo (8 px por carácter + 74). Otra vez Super + Espacio lo cierra.

## Problemas conocidos o decisiones

- **Energía: TLP en lugar de power-profiles-daemon** (el PPD era un "placeholder": no aplicaba nada con esta CPU). Se instala con `sudo bash ~/my-arch/install/energia.sh` (configuración en `install/tlp.conf`: turbo apagado en batería, sin límite de carga porque la batería está al ~68 % de su capacidad). El menú de ajustes ya no tiene Energía.

- **El clic en los escritorios de waybar no funciona:** waybar 0.15 manda `dispatch workspace N` y Hyprland en Lua lo rechaza (Waybar #5008, arreglado pero sin publicar). El usuario **decidió no instalar waybar-git** y esperar a la versión oficial. Mientras tanto, usa Super + número.
- Solo hay **un fondo "Dark Mode"** (Mightyena). En claro están Lucario y Snorlax.

## Lista de personalización: estado

| # | Pieza | Estado |
|---|---|---|
| 1 | Tema central | ✅ Hecho |
| 2 | Hyprland | ✅ Hecho (el usuario no quiere atajos extra para el scrolling) |
| 3 | waybar | ✅ Islas, escritorios con números (descartados flotante y japonés) |
| 4 | Módulos de waybar | ✅ Hecho (ventana activa y perfil de energía quitados) |
| 5 | Lanzador | ✅ rofi minimalista |
| 6 | Notificaciones | ✅ swaync |
| 7 | hyprlock | ✅ Estilo completo |
| 8 | hypridle | ✅ Hecho (menú de inactividad) |
| 9 | Fondos | ✅ Por modo, con rotación y selector con miniaturas en rofi (Super + W) |
| 10 | kitty | ✅ Cursor y pestañas |
| 11 | Apariencia GTK | ✅ Nordic / Nordic-Polar |
| 12 | Papirus | ✅ Carpetas por tema |
| 13 | Cursor | ✅ Ice en oscuro, Classic en claro |
| 14 | Zen | ✅ Tema Nord |
| 15 | Thunar | ✅ Comprimir/extraer, miniaturas de vídeo, "Abrir terminal aquí" |
| 16 | fastfetch | ✅ Logo = personaje del fondo actual (`logo-bin`: recorta quitando el color liso del fondo, caché en `~/.cache/theme/logos`; colores originales o, si no contrasta con la terminal, dos tonos acento/texto). Lo actualiza `tema`; `fondos preparar` recorta los nuevos. Datos esenciales, al abrir kitty |
| 17 | btop | ✅ Tema Nord |
| 18 | Prompt | ✅ starship de una línea, con línea en blanco entre comandos |
| A | matugen | ✅ Hecho (tema dinámico) |
| B | Avisos de volumen y brillo | ✅ Con swaync (`osd-bin`); que salgan bajo su isla → lista de deseos de Quickshell |
| C | Menú de apagado | ✅ Hecho (rofi) |
| D | rofi | ✅ Hecho |
| E | swaync | ✅ Hecho |
| F | Dock | ❌ Descartado (ya hay lanzador e iconos en los escritorios) |
| G | Plugins de Hyprland | ⏳ Solo hyprexpo, **cuando la versión oficial sea compatible** con su Hyprland (el usuario no quiere la versión no oficial de sandwichfarm). hyprbars, hyprtrails y hyprfocus descartados |
| H | Fondos animados | ❌ Desaconsejado (RAM) |
| I | cava | ✅ Barritas pegadas a la isla de música (`cava-bin`; el waybar de Arch no trae el módulo cava) |
| J | Editar capturas | ✅ satty en Impr |
| K | Grabar pantalla | ✅ gpu-screen-recorder, Super+Shift+R, isla REC (`grabar-bin`) |
| L | hyprpicker | ✅ Como app "Selector de color" en rofi (sin atajo) |
| M–P | Terminal | ✅ fish (solo en kitty), eza, bat (cat), fzf, zoxide (z), yazi (y) |
| Q | plymouth | ✅ amdgpu en el initramfs (MODULES y hook kms). Se probó a sacarlo con `plymouth.use-simpledrm`: fuera tardaba ~9 s y dejaba ~6 s de negro tras la animación (Plymouth pierde la pantalla del firmware al llegar amdgpu), así que se volvió atrás. Cargar amdgpu tarda ~4,5 s y no se sabe por qué; hook tras systemd, `quiet splash`; sin Plymouth al apagar/reiniciar (servicios enmascarados). Limine espera 2 s. Colección adi1090x: **connect** (n.º 16). Cambiar: `sudo bash ~/my-arch/install/plymouth.sh <tema>` |
| R | Gestor de arranque | ✅ Limine con tema Nord |
| S | Pantalla de login | ❌ No hay: autologin + elección en Limine |
| T–V | Apps | ✅ Vesktop (Discord; el tema Nord lo elige el usuario en Vencord) · Qt y Spotify no hacen falta |

## Otros pendientes grandes

- **Modo juego (hecho, 2026-10-24):** Limine (`/boot/EFI/limine/BOOTX64.EFI`, config `/boot/EFI/limine/limine.conf` generada desde `install/limine.conf` por `install/limine.sh`, que copia todos los fondos a `/boot/limine/fondos` para que salga uno al azar; hay que volver a ejecutarlo tras añadir fondos) con solo dos entradas, Escritorio y Juego (sin comentarios; la LTS se quitó del menú, el kernel sigue instalado), que pasan `modo=` en cmdline; systemd-boot sigue en la UEFI como respaldo (F12). Autologin en tty1 (getty override); fish llama a `modo-bin arrancar` en tty1, que abre `start-hyprland` (bloqueado al inicio: BLOQUEAR_AL_INICIO=1 → inicio-bin lanza bloquear-bin) o `gamescope-session-plus steam`, y al cerrarse abre el modo pedido en `~/.cache/theme/siguiente-modo`. Cambiar: ⏻ → Modo juego (`modo-bin juego`); en Steam, Cambiar a escritorio → `/usr/lib/os-session-select` → `modo-bin escritorio`. Instalación: `sudo bash ~/my-arch/install/modo-juego.sh`.
- **Arranque y modo juego (decidido):** elegir "Arch – Escritorio" o "Arch – Juego" **en el menú de arranque**, con un gestor bonito (Limine o rEFInd con tema Nord) y entrada directa sin pantalla de login. Se hará cuando toque el modo juego.

- **Modo juego** al estilo SteamOS: `gamescope-session-steam`, multilib, `lib32-mesa`, `lib32-vulkan-radeon`. Elegible desde **systemd-boot** con las entradas "Arch – Escritorio" y "Arch – Juego". El usuario prefiere una sola pantalla de selección.
- **Quickshell** (cuando arregle la RAM): migrar pieza por pieza, en una rama `quickshell`. Ir llevando una **lista de deseos** de lo que waybar no puede hacer (panel de ajustes con interruptores, por ejemplo).
- **`install.sh` único** con módulos (iso, base, hardware/amd o nvidia, hyprland) en `my-arch`, para reinstalar en otro equipo. El PC con Windows tiene NVIDIA.
- **Módulo de RAM de la ranura:** revisar los contactos o cambiarlo (hoy solo hay 3,2 GB de 8). Es lo que bloquea Quickshell y obliga a compilar con pocos hilos (`CARGO_BUILD_JOBS=2`).
- ~~Probar el micrófono interno~~ ✅ Probado, funciona.

## Siguiente paso sugerido

La lista de personalización está terminada. Queda:
- **Arranque limpio** (`install/arranque.sh`): Plymouth se cierra con `--retain-splash` y el kernel no dibuja consola en tty1 (`fbcon=vc:2-6`; consola de emergencia en Ctrl+Alt+F2), getty de tty1 silencioso, kernel en silencio y sin cursor (cmdline de Limine), Steam puede cambiar el brillo (sudoers solo para `tee` del brillo), gelly se abre tras desbloquear (el llavero pedía contraseña porque gelly preguntaba antes) y awww-daemon espera al bloqueo (repinta solo el último fondo al arrancar), `modo-splash` (sudo sin contraseña solo para `mostrar`/`ocultar`) para ver Plymouth al cambiar de modo, y el bloqueo del inicio lo lanza `hyprland.lua` antes que nada con el último fondo (copia a tamaño de pantalla en `~/.cache/theme/fondo-bloqueo.jpg`, que hace `fondos-bin`). La cuenta atrás de Limine, en azul Nord; su texto está en inglés dentro del binario.
- RAM: Steam ya no arranca con el escritorio (unos 900 MB), y zram con `swappiness` 180 (`install/zram.sh`). El disco va sobrado (14 GB de 937).
- **Limine:** personalizar más su aspecto (`install/limine.conf`).
- **`install.sh`** único y, cuando se arregle la RAM, **Quickshell**.
- Esperando a terceros: el clic en los escritorios de waybar (arreglo sin publicar en 0.15) y hyprexpo oficial para Hyprland 0.56.
