# Traspaso: personalización de Arch + Hyprland en la Lenovo

Fecha: 2026-10-23. Para continuar en una conversación nueva.

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
⚠️ **RAM:** el módulo de la ranura falla a veces y solo quedan 3,2 GB de 8. Hay que tenerlo en cuenta con apps pesadas (Feishin, shells de Quickshell).

## Sistema

Arch mínimo (systemd-boot, `linux` y `linux-lts`, zram, NetworkManager, PipeWire, paru). **Hyprland 0.56 con configuración en Lua** (`hyprland.lua`, API `hl.*`; los ejemplos están en `/usr/share/hypr/`, y las referencias en `/usr/share/hypr/stubs/hl.meta.lua`). Para validar: `Hyprland --verify-config`. Para recargar: `hyprctl reload`.

## Repositorio de dotfiles

`~/my-arch` en la Lenovo, subido a GitHub como **privado** en https://github.com/rocksymiguel/my-arch (remote SSH, `gh` con sesión en la Lenovo y en este PC). Las carpetas `~/.config/{hypr,waybar,kitty,rofi,swaync,waypaper,gtk-3.0,gtk-4.0,theme}` y `~/.bashrc` son **enlaces** a `~/my-arch/dotfiles`. Hay que editar ahí, hacer **commit y push** después de cada cambio aprobado, y actualizar el README cuando haga falta. Los archivos generados (colors.*, rofi/colors.rasi, swaync/style.css, hypridle.conf) están en `.gitignore`.

Comandos propios (alias en `.bashrc`, scripts en `~/.config/theme/`):

| Comando | Qué hace |
|---|---|
| `tema oscuro\|claro\|dinamico` | Paleta de todo el escritorio a partir de plantillas (`theme/templates`, `theme/themes/*.colors`). El dinámico usa matugen. También cambia el fondo según el modo y reinicia la barra y la bandeja |
| `vidrio total\|oscurecer` | Opacidad y desenfoque (`theme/vidrio/*.glass`). Total: ventanas al 75 % activas y 10 % inactivas; kitty igual |
| `inactividad [clave min]` | Genera `hypridle.conf` (atenuar, bloquear, apagar, suspender). Ahora: atenuar 10, lo demás nunca |
| `fondos siguiente\|rotar N\|demonio` | Fondos de `~/Imágenes/Fondos` según el modo ("Dark Mode" / "Light Mode" en el nombre). Rotación cada N minutos |
| `musica` (Super + F) | Muestra o esconde Feishin en el escritorio especial `musica`, flotando a 960×560 |
| `hypr` | Abre Hyprland desde la TTY |

Estado actual: tema **claro**, vidrio **total**, rotación cada **5 min**.

## Lo que ya está hecho

- **Tema central:** Nord profundo (base oscura), Nord claro y dinámico. Fuentes compactas (JetBrains Mono Nerd), redondeo de 10, separación de 3 y 6, borde de 2 con degradado del tema. El modo claro tiene un borde más oscuro.
- **Hyprland:** animación **rebote medio** (`hypr/animaciones.lua`), layout **scrolling**, reglas (pantalla completa opaca y sin atenuar, diálogos centrados, progreso de Thunar flotante, vídeo flotante de Zen y Feishin mini).
- **Atajos:** Super + Enter kitty · Espacio rofi · Z Zen · T Thunar · F Feishin · W waypaper · L bloquear · Q cerrar · Shift + Q forzar cierre · B pantalla completa · Shift + B maximizar · M salir · V flotar · P pseudo · J división · S y Shift + S scratchpad · Shift + V portapapeles · Impr y Shift + Impr capturas · 1…0 escritorios · teclas Fn.
- **Waybar en islas:** escritorios **1-3 fijos** con iconos de apps · música (MPRIS; clic pausa, clic derecho muestra Feishin) · reloj con fecha · tiempo de Daule (wttr.in) · CPU, RAM y temperatura (clic: btop) · bandeja (Wi-Fi y BT de nm-applet y blueman) · brillo y volumen · batería · 🔔 notificaciones (swaync: clic abre el panel, clic derecho "No molestar") · ⚙ ajustes · ⏻ apagado. La config se genera con iconos por código.
- **Lanzador rofi** minimalista (`rofi/config.rasi` + `colors.rasi` generado por tema). Clic fuera lo cierra. Apps que no usa escondidas con `.desktop` NoDisplay en `dotfiles/.local/share/applications`.
- **Menú de ajustes** (rofi, `waybar/scripts/menu-ajustes`): Tema, Vidrio, Inactividad (submenús de minutos y pausa), Fondo (elegir, siguiente, rotar), Energía (equilibrado o ahorro) y Cursor. Al elegir vuelve atrás, Esc vuelve atrás, y antes de abrir cierra cualquier rofi atascado.
- **Menú de apagado:** bloquear, cerrar sesión, reiniciar y apagar, con confirmación.
- **Notificaciones swaync** (arriba a la derecha, panel con No molestar, música, volumen y brillo). **Avisos (OSD)** con `osd-bin` como notificaciones de swaync: volumen y brillo solo con barra; micrófono, Bloq Mayús y Bloq Num con texto. No van al historial. Bloq Num activado al iniciar.
- **Bloqueo** con `bloquear-bin` y hyprlock estilo completo: hora, fecha y tiempo, batería, música, aviso de Bloq Mayús (borde naranja = Mayús) y el fondo actual desenfocado. La rotación de fondos se congela mientras está bloqueado.
- **Apariencia:** GTK Nordic (oscuro) y Nordic-Polar (claro); carpetas en gris azulado u nordic (copia de Papirus en `~/.local/share/icons`, papirus-folders sin sudo), todo cambiado por `tema`. kitty con cursor de línea parpadeante y pestañas powerline. Zen con tema Nord (lo puso el usuario). Cursor por modo: Bibata Modern Ice en oscuro y Classic en claro (lo cambia `tema`). Las otras variantes de Bibata no se instalan (NoExtract en /etc/pacman.conf).
- **Feishin** (repo extra): arranca escondido. El usuario desactivó "Show tray". Su música está en Navidrome, en el NAS.

## Problemas conocidos o decisiones

- **El clic en los escritorios de waybar no funciona:** waybar 0.15 manda `dispatch workspace N` y Hyprland en Lua lo rechaza (Waybar #5008, arreglado pero sin publicar). El usuario **decidió no instalar waybar-git** y esperar a la versión oficial. Mientras tanto, usa Super + número.
- **Sin modo rendimiento:** la CPU no lo soporta y el usuario usa "ahorro". Se descartó `tuned-ppd`.
- Solo hay **un fondo "Dark Mode"** (Mightyena). En claro están Lucario y Snorlax.

## Lista de personalización: estado

| # | Pieza | Estado |
|---|---|---|
| 1 | Tema central | ✅ Hecho |
| 2 | Hyprland | ✅ Hecho (el usuario no quiere atajos extra para el scrolling) |
| 3 | waybar | ✅ Islas · ⏳ probar la barra **flotante** y los escritorios en **japonés** (一 二 三) |
| 4 | Módulos de waybar | ✅ Hecho (ventana activa y perfil de energía quitados; la energía va en ajustes) |
| 5 | Lanzador | ✅ rofi minimalista |
| 6 | Notificaciones | ✅ swaync |
| 7 | hyprlock | ✅ Estilo completo |
| 8 | hypridle | ✅ Hecho (menú de inactividad) |
| 9 | Fondos | ✅ Por modo y con rotación · ⏳ selector con miniaturas en rofi (opcional) |
| 10 | kitty | ✅ Cursor y pestañas |
| 11 | Apariencia GTK | ✅ Nordic / Nordic-Polar |
| 12 | Papirus | ✅ Carpetas por tema |
| 13 | Cursor | ✅ Ice en oscuro, Classic en claro |
| 14 | Zen | ✅ Tema Nord |
| 15 | Thunar | ⏳ |
| 16 | fastfetch | ⏳ |
| 17 | btop | ⏳ Tema Nord |
| 18 | Bash / prompt | ⏳ Junto con M y N |
| A | matugen | ✅ Hecho (tema dinámico) |
| B | Avisos de volumen y brillo | ✅ Con swaync (`osd-bin`); que salgan bajo su isla → lista de deseos de Quickshell |
| C | Menú de apagado | ✅ Hecho (rofi) |
| D | rofi | ✅ Hecho |
| E | swaync | ✅ Hecho |
| F | Dock | ⏳ Sin decidir |
| G | Plugins de Hyprland | ⏳ Comprobar compatibilidad con la 0.56 en Lua |
| H | Fondos animados | ❌ Desaconsejado (RAM) |
| I | cava | ⏳ Sin decidir |
| J | Editar capturas (satty o swappy) | ⏳ |
| K | Grabar pantalla | ⏳ |
| L | hyprpicker | ⏳ |
| M–P | zsh o fish, starship, eza, bat, fzf, zoxide, yazi | ⏳ Sin decidir |
| Q | plymouth | ⏳ |
| R | Limine o rEFInd con tema | ⏳ |
| S | Pantalla de login | ⏳ Va junto con el **modo juego** |
| T–V | Qt, Spotify, Discord | ⏳ Solo si los usa |

## Otros pendientes grandes

- **Modo juego** al estilo SteamOS: `gamescope-session-steam`, multilib, `lib32-mesa`, `lib32-vulkan-radeon`. Elegible desde **systemd-boot** con las entradas "Arch – Escritorio" y "Arch – Juego". El usuario prefiere una sola pantalla de selección.
- **Quickshell** (cuando arregle la RAM): migrar pieza por pieza, en una rama `quickshell`. Ir llevando una **lista de deseos** de lo que waybar no puede hacer (panel de ajustes con interruptores, por ejemplo).
- **`install.sh` único** con módulos (iso, base, hardware/amd o nvidia, hyprland) en `my-arch`, para reinstalar en otro equipo. El PC con Windows tiene NVIDIA.
- Probar el **micrófono interno**.

## Siguiente paso sugerido

Seguir con lo que queda: 15–18 (Thunar, fastfetch, btop, prompt), la terminal (M–P), capturas (J–L) y, más adelante, el modo juego, Quickshell y el `install.sh`.
