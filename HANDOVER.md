# Traspaso: personalización de Arch + Hyprland en la Lenovo

Fecha: 2026-10-23 (actualizado el 2026-10-26). Para continuar en una conversación nueva.

**Responde siempre en español.** El usuario personaliza su Arch con Hyprland en la Lenovo, paso a paso. Al principio desde el PC con Windows por SSH; desde el 2026-10-25 también con Claude Code **directamente en la Lenovo** (ahí no hace falta `ssh`, y `sudo` lo escribe el usuario en kitty: tú no puedes).

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
**RAM (cambiada el 2026-10-26; ⚠️ intermitente):** 8 GB cuando el módulo de la ranura se detecta (4 soldados + uno nuevo de 4 GB; el anterior fallaba y dejaba 3,2 GB). El BIOS aparta **2 GB a la gráfica integrada**, así que `free` marca ~5,7 GiB. Prueba propia (3,5 GiB, 4 hilos, 15 pasadas, 6 patrones): 0 fallos, sin MCE ni OOM; solo cubre ~60 % de la RAM, no se ha pasado un memtest86+ completo. Ya hay margen para Quickshell y para compilar sin limitar los hilos, pero conviene seguir sin abrir Steam en el escritorio con juegos (ver abajo). El 2026-10-25 el escritorio se colgó porque Steam agotó los 3,2 GB (el kernel mató `steamwebhelper` 8 veces).
**El módulo nuevo también falla a ratos:** de 4 arranques con él, 2 vieron 5,8 GB, el 09:31 se colgó a los 22 s con artefactos en pantalla (sin nada en el registro) y el siguiente (09:33) volvió a ver solo 3,2 GB. `dmidecode` (con los 8 GB presentes): dos módulos de 4 GiB, Hynix HMA851S6JJR6N-VK y Micron 4ATF51264HZ-2G6E1, a 2400 MT/s (el máximo del Ryzen 5 3500U). Como con el módulo viejo pasaba lo mismo, se sospecha de la **ranura o de un mal contacto**; el usuario va a limpiarla y reasentar el módulo (pendiente). Los artefactos encajan con la RAM que el BIOS aparta a la gráfica (2 GB), que la prueba en espacio de usuario no puede cubrir. Mientras solo haya 3,2 GB vuelve el OOM: el 2026-10-26 a las 10:19 (Steam + un programa Electron + un juego en wine) el kernel mató `dbus-broker` y los servicios pequeños de la sesión, y se cayeron `hypridle`, nm-applet, blueman, gelly y Steam; **nada los reinicia solos** (`avion-bin bandeja` relanza Wi-Fi y Bluetooth; `hypridle` y gelly se lanzan a mano). Consejo: mirar `free -h` o `journalctl -b -k | grep Memory:` antes de suponer que hay 8 GB.

## Sistema

Arch mínimo (systemd-boot, `linux` y `linux-lts`, zram, NetworkManager, PipeWire, paru). **Hyprland 0.56 con configuración en Lua** (`hyprland.lua`, API `hl.*`; los ejemplos están en `/usr/share/hypr/`, y las referencias en `/usr/share/hypr/stubs/hl.meta.lua`). Para validar: `Hyprland --verify-config`. Para recargar: `hyprctl reload`.

## Repositorio de dotfiles

`~/my-arch` en la Lenovo, subido a GitHub como **público** (desde el 2026-10-26, para clonarlo desde el USB; se revisó el historial: sin claves ni contraseñas) en https://github.com/rocksymiguel/my-arch (remote SSH, `gh` con sesión en la Lenovo y en el PC con Windows). Las carpetas de `~/.config` que están en `dotfiles/` (hypr, waybar, kitty, rofi, swaync, theme, fish…) son **enlaces** a `~/my-arch/dotfiles` (los crea `link.sh`). Hay que editar ahí, hacer **commit y push** después de cada cambio aprobado, y actualizar el README cuando haga falta. Los archivos **generados por `tema`** están en `.gitignore` y **no se editan**: colors.*, la barra (`waybar/style.css` y `config.jsonc`), `rofi/config.rasi` y `colors.rasi`, `swaync/style.css` y `config.json`, `hypr/hyprlock.conf`, `hypridle.conf`, GTK (`gtk-3.0`, `gtk-4.0`) y el cursor (`~/.icons`). Se editan sus **plantillas** en `dotfiles/.config/theme/templates/`.

Comandos propios (alias en scripts en `~/.config/theme/`):

| Comando | Qué hace |
|---|---|
| `tema oscuro\|claro\|acentos` | Modo (paleta base Nord, GTK, iconos, cursor, carpetas) a partir de plantillas (`theme/templates`, `theme/themes/*.colors`). **Ya no hay modo dinámico:** el acento (bordes, barra, lanzador, kitty, bloqueo) sale siempre del fondo con matugen en la variante del modo. `tema acentos` lo actualiza sin reiniciar waybar (`reload_style_on_change`); cambiar de modo sí reinicia barra y bandeja |
| `tamano [N]` | Tamaño de la interfaz de 50 a 200 % (100 = la Lenovo), también en ⚙ → Tamaño. Ver «Tamaño de la interfaz» abajo |
| `vidrio total\|oscurecer` | Opacidad y desenfoque (`theme/vidrio/*.glass`). Total: ventanas al 75 % activas y 10 % inactivas; kitty igual |
| `inactividad [clave min]` | Genera `hypridle.conf` (atenuar, bloquear, apagar, suspender). Ahora: atenuar 10, lo demás nunca |
| `fondos elegir\|siguiente\|poner\|restaurar\|rotar N\|demonio` | Fondos de `~/Imágenes/Fondos` según el modo ("Dark Mode" / "Light Mode" en el nombre). `elegir` (Super + W) es el selector con miniaturas en rofi, Tab alterna oscuros/claros y elegir uno del otro modo cambia el modo; **waypaper se quitó**. awww pinta el fondo y `~/.cache/theme/fondo` recuerda el último. Rotación cada N minutos |
| `musica` (Super + G) | Muestra o esconde gelly en el escritorio especial `musica`, flotando a 490×540 |
| `hypr` | Abre Hyprland desde la TTY |

Estado actual: tema **claro**, vidrio **total**, rotación cada **5 min**.

## Lo que ya está hecho

- **Tema central:** Nord profundo (base oscura), Nord claro y dinámico. Fuentes compactas (JetBrains Mono Nerd), redondeo de 10, separación de 3 y 6, borde de 2 con degradado del tema. El modo claro tiene un borde más oscuro.
- **Hyprland:** animación **rebote medio** (`hypr/animaciones.lua`), layout **scrolling**, reglas (pantalla completa opaca y sin atenuar, diálogos centrados, progreso de Thunar flotante, vídeo flotante de Zen y gelly mini).
- **Atajos:** Super + Enter kitty · Espacio rofi (Ctrl + Tab: calculadora) · Z Zen · T Thunar · G gelly · W selector de fondos · L bloquear · Q cerrar · Shift + Q forzar cierre · B pantalla completa · Shift + B maximizar · M salir · V flotar · P pseudo · J división · S y Shift + S scratchpad · Shift + V portapapeles · Impr y Shift + Impr capturas · 1…0 escritorios · teclas Fn.
- **Waybar en islas:** escritorios **1-3 fijos** con iconos de apps · música (`waybar/scripts/musica`: lo que suena o está en pausa, sin nada no hay isla; clic pausa, clic derecho muestra gelly, rueda siguiente/anterior) · reloj con fecha · tiempo de Daule (wttr.in) · CPU, RAM y temperatura (`waybar/scripts/temperatura` busca el sensor de la CPU del equipo; clic: btop) · bandeja (Wi-Fi y BT de nm-applet y blueman) · brillo y volumen · batería · 🔔 notificaciones (swaync: clic abre el panel, clic derecho "No molestar") · ⚙ ajustes · ⏻ apagado. La config sale de la plantilla `theme/templates/waybar-config.jsonc`.
- **Lanzador rofi** minimalista (plantilla `rofi-config.rasi` + `colors.rasi`, ambos generados por tema; con rofi-calc como segundo modo). Clic fuera lo cierra. Apps que no usa escondidas con `.desktop` NoDisplay en `dotfiles/.local/share/applications`.
- **Menú de ajustes** (rofi, `waybar/scripts/menu-ajustes`): Tema, Vidrio, Tamaño, Inactividad (submenús de minutos y pausa), Fondo (elegir, siguiente, rotar) y Sistema: Limpiar (en segundo plano, `/usr/local/bin/limpiar-sistema` con sudoers de `install/sistema.sh`), Actualizar (`paru -Syu` en una terminal flotante) y Fondos de arranque (`limine.sh`). Al elegir vuelve atrás, Esc vuelve atrás, y antes de abrir cierra cualquier rofi atascado.
- **Menú de apagado:** bloquear, cerrar sesión, reiniciar y apagar, con confirmación.
- **Notificaciones swaync** (arriba a la derecha, panel con No molestar, música, volumen y brillo). **Avisos (OSD)** con `osd-bin` como notificaciones de swaync: volumen y brillo solo con barra; micrófono, Bloq Mayús y Bloq Num con texto. No van al historial. Bloq Num activado al iniciar.
- **Bloqueo** con `bloquear-bin` y hyprlock estilo completo: hora, fecha y tiempo, batería, música, aviso de Bloq Mayús (borde naranja = Mayús) y el fondo actual desenfocado. La rotación de fondos se congela mientras está bloqueado.
- **Apariencia:** GTK Nordic (oscuro) y Nordic-Polar (claro); carpetas en gris azulado u nordic (copia de Papirus en `~/.local/share/icons`, papirus-folders sin sudo), todo cambiado por `tema`. kitty con cursor de línea parpadeante y pestañas powerline. Zen con tema Nord (lo puso el usuario). Cursor por modo: Bibata Modern Ice en oscuro y Classic en claro (lo cambia `tema`). Las otras variantes de Bibata no se instalan (NoExtract en /etc/pacman.conf).
- **gelly** (AUR, compilado con `CARGO_BUILD_JOBS=2` para no agotar la RAM): arranca escondido en `special:musica`. Credenciales en gnome-keyring: llavero «login» con la contraseña del usuario, que desbloquea hyprlock al entrar (pam_gnome_keyring en /etc/pam.d/hyprlock). Su música está en Navidrome, en el NAS. Sustituyó a Feishin y Strawberry el 2026-10-25 tras medirlos: gelly 4 % CPU / 164 MB / +1,2 W; Strawberry 12 % / 149 MB / +2,3 W; Feishin 22 % / 356 MB / +1,8 W.

- **Modo avión:** `avion-bin vigilar` (arranca con Hyprland) escucha `rfkill event`; con el modo avión activo cierra nm-applet y blueman-applet y la isla `group/conexion` muestra solo el avión; al desactivarlo los vuelve a abrir. Ojo: en la sesión `rfkill` sale en español, por eso usa `LC_ALL=C`; usa un PID (no flock) porque los applets heredarían el candado.
- **Lanzador:** `lanzador-bin` (Super + Espacio) calcula el ancho de rofi según el nombre de app visible más largo (8 px por carácter + 74, a 100 %; escala con el tamaño). Otra vez Super + Espacio lo cierra.
- **Tamaño de la interfaz (2026-10-26):** ⚙ → Tamaño (50, 75, 90, **100**, 110, 125, 150, 175, 200) o `tamano N`; se guarda en `~/.cache/theme/tamano`. `tema` genera al tamaño elegido waybar, rofi, swaync, hyprlock, kitty, las medidas de Hyprland (`e(N)` en `hyprland.lua` con `theme.escala`: separación, borde, redondeo, tamaños de ventana), la letra de GTK y el cursor. Las plantillas marcan cada medida como `{{e:N}}` (N px a 100 %) o `{{d:N}}` (letras, con decimal). El ancho del lanzador y del selector de fondos también escala (este nunca pasa del 90 % de la pantalla). swaync **se reinicia** al cambiar de tamaño (recargar su config no cambia el ancho; se borra el historial). El aviso de volumen/brillo va bajo su isla: `osd_margen` lo calcula `tema` (151 px con batería, 90 sin ella, por el tamaño). `post.sh` elige el tamaño inicial según la densidad de la pantalla (`detectar.sh`: la Lenovo ~102 ppp = 100 %; +10 % en equipos sin batería).
- **Apps (2026-10-26):** mpv (vídeo; por defecto, con `mpv-mpris` para que salga en la isla de música), imv (imágenes; por defecto `imv-dir.desktop`; antes los PNG se abrían en satty), calculadora en el lanzador (rofi-calc: Super + Espacio y Ctrl + Tab; qalc entiende unidades en inglés, `5 km to mi`), gdu (uso del disco en la terminal). Todo en `packages/comun.txt`.
- **Steam escondido al iniciar (2026-10-26):** `inicio-bin` lanza `steam -silent` (bandeja, sin ventana, ~1,1 GB) 20 s después de desbloquear, si Steam está instalado **y la RAM total es de más de 5 GB** (con 8 GB el sistema ve ~5,9; con el módulo sin detectarse hay 3,2 GB y no arranca). Va en su propio cgroup con tope: `systemd-run --user --scope -p MemoryHigh=1800M -p MemoryMax=2200M -p MemorySwapMax=0`. **`MemorySwapMax=0` es imprescindible:** `MemoryMax` solo cuenta la RAM y sin él el exceso iba a zram y, al no comprimirse, devolvía la presión a todos (probado: 4 GB → 1 GB libres). Un juego lanzado desde ese Steam comparte el tope; los grandes, en modo juego. `modo-bin` lo cierra antes del modo juego (`cerrar_steam`, ~5 s) porque chocaría con el Steam de gamescope. Steam necesita `DISPLAY` (Xwayland): en una shell de pruebas por SSH falta y sale con «Unable to open X11 display». Confirmado tras un reinicio: arranca solo con su tope.
- **Icono de Steam en la barra (2026-10-26):** Steam manda su propia carpeta de iconos (`IconThemePath`, `~/.local/share/Steam/public/steam_tray_mono.png`, claro) y waybar la usa antes que Papirus, así que en modo claro no se veía. `theme/icono-steam` lo repinta con el color del texto del modo conservando el canal alfa; lo llama `tema` al cambiar de modo y al iniciar (antes de lanzar Steam, que puede rehacer el archivo al actualizarse). En una instalación nueva, el primer arranque de Steam sale con el icono original.
- **Isla de conexión sin vacíos (2026-10-26):** waybar no esconde un grupo cuyos módulos están todos escondidos; el relleno de `#conexion` (avión + bandeja) pasa a sus módulos (`#tray`, `#custom-avion`) para que sin iconos no quede una cápsula vacía.

## Instalador para cualquier equipo (2026-10-25/26)

Objetivo: reinstalar el rice en **cualquier PC** (escritorio o portátil; AMD, NVIDIA o Intel), no solo en la Lenovo. Dos fases, probadas de principio a fin en una VM de VMware (en el PC con Windows):

- **Fase 1, `install/base.sh`** (desde el USB de Arch, como root, UEFI e internet; clonar el repo público): pregunta disco (borra todo; hay que escribir BORRAR), equipo, usuario, zona, idioma, teclado y contraseñas. Particiona (EFI 1 GB + ext4), pacstrap (microcódigo AMD/Intel detectado, `pciutils`, `dosfstools`…), zram, systemd-boot, NetworkManager (copia las redes Wi-Fi de iwctl), multilib, y copia el repo a `~/my-arch`. Se pueden dar por variables: `DISCO`, `EQUIPO`, `USUARIO`, `ZONA`, `IDIOMA`, `TECLADO`. El sudoers de wheel se llama **`00-wheel`** a propósito: `sudoers.d` se lee en orden y gana la última regla, y las de sin contraseña (`limpiar-sistema`, `modo-splash`…) tienen que ir después.
- **Fase 2, `install/post.sh`** (en el sistema instalado, como el usuario, **sin sudo**): `install/detectar.sh` deja `GPUS`, `VIRT`, `PORTATIL`, `RES`, `TAMANO`, `KMS` y la partición EFI, y de ahí salen los paquetes. En `packages/`: `comun.txt`, `amd|nvidia|intel.txt`, `portatil.txt`, `juego.txt`, `nas.txt`, `tailscale.txt`, `aur.txt`, `aur-juego.txt`. Pregunta modo juego, NAS y Tailscale (o `JUEGO=si NAS=no TAILSCALE=no`). Después: paru (se **compila**; `paru-bin` se queda atrás de libalpm), fish, carpetas y fondos (`~/my-arch/fondos/`, 37 imágenes), `link.sh`, tamaño inicial, `tema oscuro`, y zram, sistema, energía (solo portátil), modo juego/Limine, plymouth, arranque limpio y una limpieza final (cachés, huérfanos, paquetes `-debug`). Pide la contraseña de sudo una sola vez (la renueva cada minuto).
- Los scripts de `install/` siguen sirviendo solos; lo que era de la Lenovo (amdgpu en el initramfs, resolución de los fondos de Limine, partición EFI, entrada «Juego» solo con Steam) sale de `detectar.sh`. Los dos scripts muestran en rojo la línea que falla.
- **Límites de la VM (VMware):** hyprlock se cae (`zwlr_screencopy_frame_v1.copy`: Hyprland rechaza la captura en la gráfica virtual), así que no hay bloqueo ni se desbloquea el llavero (gelly pide su contraseña). kitty se cerraba hasta que `hyprland.lua` puso `LIBGL_ALWAYS_SOFTWARE=1` cuando `systemd-detect-virt` detecta una VM. Sin sensor o sin batería, esas piezas desaparecen.
- **Pendiente:** probarlo en hardware real con **NVIDIA** o **Intel** (drivers, initramfs, bloqueo): solo está probado en AMD (Lenovo) y en la VM. Cosas de la Lenovo que quizá se vean mal en otro equipo: la posición de los avisos de swaync depende de las islas de la barra.

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
| I | cava | ❌ Quitado el 2026-10-25 (las barritas de música no gustaron y gastaban CPU sin parar) |
| J | Editar capturas | ✅ satty en Impr |
| K | Grabar pantalla | ✅ gpu-screen-recorder, Super+Shift+R, isla REC (`grabar-bin`) |
| L | hyprpicker | ✅ Como app "Selector de color" en rofi (sin atajo) |
| M–P | Terminal | ✅ fish (solo en kitty), eza, bat (cat), fzf, zoxide (z), yazi (y) |
| Q | plymouth | ✅ amdgpu en el initramfs (MODULES y hook kms). Se probó a sacarlo con `plymouth.use-simpledrm`: fuera tardaba ~9 s y dejaba ~6 s de negro tras la animación (Plymouth pierde la pantalla del firmware al llegar amdgpu), así que se volvió atrás. También se probó `plymouth.use-simpledrm` (animación al instante): al llegar amdgpu bajaba el brillo, la animación empezaba otra vez y se perdía la imagen fija, así que se quitó. En la BIOS, el modo de rendimiento no acelera el arranque y Linux no puede cambiarlo (DYTC v4 desactivado en ideapad_laptop; se podría probar `ideapad_laptop.allow_v4_dytc=Y`): dejarlo en Intelligent Cooling. Cargar amdgpu tarda ~4,5 s y no se sabe por qué; hook tras systemd, `quiet splash`; sin Plymouth al apagar/reiniciar (servicios enmascarados). Limine espera 2 s. Colección adi1090x: **connect** (n.º 16). Cambiar: `sudo bash ~/my-arch/install/plymouth.sh <tema>` |
| R | Gestor de arranque | ✅ Limine con tema Nord |
| S | Pantalla de login | ❌ No hay: autologin + elección en Limine |
| T–V | Apps | ✅ Vesktop (Discord; el tema Nord lo elige el usuario en Vencord) · Qt y Spotify no hacen falta |

## Otros pendientes grandes

- **Modo juego (hecho, 2026-10-24):** Limine (`/boot/EFI/limine/BOOTX64.EFI`, config `/boot/EFI/limine/limine.conf` generada desde `install/limine.conf` por `install/limine.sh`, que copia todos los fondos a `/boot/limine/fondos` para que salga uno al azar; hay que volver a ejecutarlo tras añadir fondos) con solo dos entradas, Escritorio y Juego (sin comentarios; la LTS se quitó del menú, el kernel sigue instalado), que pasan `modo=` en cmdline; systemd-boot sigue en la UEFI como respaldo (F12). Autologin en tty1 (getty override); fish llama a `modo-bin arrancar` en tty1, que abre `start-hyprland` (bloqueado al inicio: BLOQUEAR_AL_INICIO=1 → inicio-bin lanza bloquear-bin) o `gamescope-session-plus steam`, y al cerrarse abre el modo pedido en `~/.cache/theme/siguiente-modo`. Cambiar: ⏻ → Modo juego (`modo-bin juego`); en Steam, Cambiar a escritorio → `/usr/lib/os-session-select` → `modo-bin escritorio`. Instalación: `sudo bash ~/my-arch/install/modo-juego.sh`.
- **Quickshell** (la RAM ya lo permite desde el 2026-10-26): migrar pieza por pieza, en una rama `quickshell`. Ir llevando una **lista de deseos** de lo que waybar no puede hacer (panel de ajustes con interruptores, por ejemplo).
- ~~`install.sh` único~~ ✅ Hecho como `base.sh` + `post.sh` (ver arriba).
- ~~Módulo de RAM de la ranura~~ ✅ Cambiado el 2026-10-26 (ver «Equipo»). Queda un memtest86+ completo si se quiere estar seguro.
- ~~Probar el micrófono interno~~ ✅ Probado, funciona.

## Siguiente paso sugerido

La lista de personalización está terminada. Queda:
- **Arranque limpio** (`install/arranque.sh`): Plymouth se cierra con `--retain-splash` y el kernel no dibuja consola en tty1 (`fbcon=vc:2-6`; consola de emergencia en Ctrl+Alt+F2), getty de tty1 silencioso, kernel en silencio y sin cursor (cmdline de Limine), Steam puede cambiar el brillo (sudoers solo para `tee` del brillo), gelly se abre tras desbloquear (el llavero pedía contraseña porque gelly preguntaba antes) y awww-daemon espera al bloqueo (repinta solo el último fondo al arrancar), `modo-splash` (sudo sin contraseña solo para `mostrar`/`ocultar`) para ver Plymouth al cambiar de modo, y el bloqueo del inicio lo lanza `hyprland.lua` antes que nada con el último fondo (copia a tamaño de pantalla en `~/.cache/theme/fondo-bloqueo.jpg`, que hace `fondos-bin`). La cuenta atrás de Limine, en azul Nord; su texto está en inglés dentro del binario.
- RAM: Steam vuelve a arrancar con el escritorio, escondido (ver arriba), y zram con `swappiness` 180 (`install/zram.sh`). El disco va sobrado (14 GB de 937; Steam y sus juegos son 4,3 GB).
- Aviso en el registro: `FAT-fs (nvme0n1p1): Volume was not properly unmounted` (del apagado forzado del 2026-10-25). Se revisa con `sudo fsck.fat -a /dev/nvme0n1p1` (hace falta `dosfstools`).
- **Limine:** personalizar más su aspecto (`install/limine.conf`).
- **Probar el instalador en hardware real** (NVIDIA o Intel) y, después, **Quickshell**.
- Esperando a terceros: el clic en los escritorios de waybar (arreglo sin publicar en 0.15) y hyprexpo oficial para Hyprland 0.56.
