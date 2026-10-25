# zen-sync

Mantiene la sesión de Zen (pestañas, espacios, essentials, carpetas) igual entre equipos a través del NAS
(`//192.168.18.42/Emulacion/Development/Tools/zen-sync`). Funciona entre Linux y Windows en cualquier sentido.

Un vigilante en segundo plano, en cada equipo:

- con Zen cerrado, cada 10 s baja la sesión del NAS si es más nueva (o sube la local si cambió sin subirse);
- al cerrarse Zen, sube la sesión y avisa con una notificación;
- si Zen está abierto en dos equipos a la vez, avisa; gana la sesión del último que cierre.

El NAS guarda las últimas 5 versiones en `history/`, y cada equipo respalda su sesión local antes de reemplazarla.
Contraseñas, historial, marcadores y extensiones van por Firefox Sync, no por aquí.

## Linux

Necesita el NAS montado (`sudo bash install/nas.sh`). Luego:

```bash
ln -sf ~/my-arch/scripts/zen-sync/zen-sync ~/.local/bin/zen-sync
ln -sf ~/my-arch/scripts/zen-sync/zen-sync.service ~/.config/systemd/user/zen-sync.service
systemctl --user daemon-reload && systemctl --user enable --now zen-sync.service
```

Registro: `~/.local/state/zen-sync/zen-sync.log`. Manual: `zen-sync estado | subir | bajar`.

## Windows

Copiar `windows/zen-sync.ps1` (guardado en UTF-8 con BOM) y `windows/zen-sync.vbs` a `C:\Users\<usuario>\.zen-sync`
y crear una tarea programada al iniciar sesión que ejecute `wscript.exe "C:\Users\<usuario>\.zen-sync\zen-sync.vbs"`.
No usar carpetas nuevas bajo `AppData`. Registro: `C:\Users\<usuario>\.zen-sync\zen-sync.log`.
