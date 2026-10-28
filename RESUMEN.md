# Resumen: qué tiene este repositorio

Arch Linux con Hyprland, tema Nord, y herramientas de estudio y NAS. Se instala en dos fases, y lo personal
(NAS, usuario, vault, web apps) vive en un archivo de cada persona que **no** se sube aquí.

## Instalar

| Paso | Dónde | Qué hace |
|---|---|---|
| `bash my-arch/install/base.sh` | Desde el USB de Arch, como root | Disco, Arch mínimo, usuario, red, arranque, copia el repo a `~/my-arch` |
| `bash ~/my-arch/install/post.sh` | En el sistema instalado, como tu usuario | Detecta la gráfica y si es portátil; instala Hyprland, el tema, Steam (opcional) y todo lo demás |
| `bash ~/my-arch/install/post.sh personal` | En un equipo ya instalado | Solo lo personal (abajo), con una sola contraseña |

## Lo personal: `~/.config/my-arch/personal.env`

Cada persona tiene el suyo. Si no existe, `post.sh` lanza un asistente (`install/personalizar.sh`) que pregunta y lo crea;
`install/personal.ejemplo` explica cada línea. **No lleva contraseñas**: la del NAS se pide al montar, y las de Syncthing,
Claude o Zen se escriben en sus pantallas. Ahí van: los equipos de tu red con nombre corto, el usuario y las carpetas del
NAS, el nombre de tu vault de Obsidian, el ID del Syncthing del NAS, la carpeta de `zen-sync`, la dirección de Gelly y las
web apps del lanzador.

## Qué hay

| Área | Qué es |
|---|---|
| **Escritorio** | Hyprland, tema claro/oscuro, vidrio, tamaño 50–200 %, barra en islas, lanzador con calculadora, fondos por modo |
| **Arranque y juego** | Limine (Escritorio / Juego), Plymouth, Steam al iniciar solo con más de 5 GB de RAM y con tope de memoria |
| **Tapa y brillo** | Al cerrar la tapa se apaga la pantalla interna y no se suspende; al abrirla, el brillo atenuado vuelve a como estaba |
| **Nombres cortos** | `nas`, `proxmox`…: un servicio (`nas-dir`) los mantiene apuntando a Tailscale si responde y, si no, a la red de casa |
| **NAS** | Carpetas SMB montadas por el nombre corto en `/mnt/truenas/*` |
| **Zen** | `zen-sync`: pestañas, espacios y atajos iguales en cada equipo, por el NAS; contraseñas y marcadores por Firefox Sync |
| **Estudio** | Obsidian con el vault local sincronizado con el NAS (Syncthing, con historial de versiones de 30 días) |
| **Claude** | CLI de Claude Code, lanzadores «Claude» y «Claude · elegir conversación», dictado `/voice` en español |
| **Clases** | Botón del micrófono en la barra: grabar, transcribir en local (faster-whisper) y abrir las carpetas |
| **Cámara** | Lanzador «Cámara»: vista previa en espejo, foto, vídeo con audio (isla roja al grabar) y lector de QR (`zbar`) |
| **Web apps** | Jellyfin, Navidrome, Immich, TrueNAS… cada una en su ventana, con Chromium en modo aplicación, en el lanzador |
| **Lanzador limpio** | `packages/ocultar.txt`: lo que no hace falta ver (siguen funcionando: abren archivos o tienen atajo) |
| **Ayuda** | Escribe `ayuda`, o ⚙ → Ayuda: atajos y comandos |

## Lo que no se instala solo (es del lado del NAS o es tuyo)

- **La app Syncthing del TrueNAS** (tren Stable, ejecutada con el usuario dueño del vault, solo con esa carpeta). Se emparejan
  los dos con `bash install/estudio-syncthing.sh <ID-del-NAS>`, o dejando el ID en `personal.env`.
- **Iniciar sesión en Claude** (una vez, en el navegador) y **abrir el vault en Obsidian**.
- **Tailscale** en cada equipo, y en el NAS si quieres llegar a él desde fuera de casa.

## Dónde está cada cosa

| Qué | Dónde |
|---|---|
| Dotfiles (enlazados a `~/.config`) | `dotfiles/` · se enlazan con `link.sh` |
| Plantillas de lo que genera `tema` (barra, rofi, hyprlock…) | `dotfiles/.config/theme/templates/` |
| Scripts de instalación | `install/` |
| Listas de paquetes | `packages/` (`comun`, por gráfica, `estudio`, `webapps`, `ocultar`…) |
| Comandos de estudio | `dotfiles/.config/estudio/` (`grabar-clase`, `transcribir`, `ayuda`, `claude-kitty`) |
| `zen-sync` | `scripts/zen-sync/` |
| Notas para continuar el trabajo | `HANDOVER.md` |
