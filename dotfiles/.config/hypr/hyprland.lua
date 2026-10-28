-- Configuración de Hyprland para la Lenovo IdeaPad 3 (Ryzen 5 3500U, Vega 8)
-- Basada en el ejemplo oficial: /usr/share/hypr/hyprland.lua
-- Wiki: https://wiki.hypr.land/Configuring/Start/

-- Colores del tema activo; los genera `tema` en ~/.config/hypr/colors.lua
local theme = dofile(os.getenv("HOME") .. "/.config/hypr/colors.lua")
-- Tamaño de la interfaz (`tamano`): e(N) son N px a 100 %
local function e(n) return math.floor(n * (theme.escala or 100) / 100 + 0.5) end

------------------
---- MONITORS ----
------------------
-- Pantalla de la laptop a 1:1; cualquier monitor externo, en automático.
hl.monitor({ output = "eDP-1", disabled = false, mode = "preferred", position = "0x0", scale = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

---------------------
---- MY PROGRAMS ----
---------------------
local terminal    = "kitty"
local fileManager = "thunar"
local menu        = "~/.config/theme/lanzador-bin"
local browser     = "zen-browser"

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
    -- Inicio automático sin contraseña: el bloqueo va lo primero, para no ver el escritorio antes
    if os.getenv("BLOQUEAR_AL_INICIO") == "1" then
        hl.exec_cmd("~/.config/theme/bloquear-bin")
    end
    -- Todo el arranque está en un script (con registro en ~/.cache/theme/inicio.log)
    hl.exec_cmd("~/.config/theme/inicio-bin")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
local cursor_elegido = "Bibata-Modern-Ice" -- lo cambia `tema` según el modo
do
    local f = io.open(os.getenv("HOME") .. "/.cache/theme/cursor", "r")
    if f then cursor_elegido = f:read("*l") or cursor_elegido; f:close() end
end
hl.env("XCURSOR_THEME", cursor_elegido)
hl.env("XCURSOR_SIZE", tostring(e(24)))
hl.env("HYPRCURSOR_SIZE", tostring(e(24)))
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
-- En máquina virtual (VMware…) Hyprland rechaza los búferes de la gráfica de los programas y los
-- cierra (kitty se abría y se cerraba): que dibujen por software
do
    local p = io.popen("systemd-detect-virt 2>/dev/null")
    local virt = p and p:read("*l") or "none"
    if p then p:close() end
    if virt ~= "none" then hl.env("LIBGL_ALWAYS_SOFTWARE", "1") end
end

-----------------------
---- LOOK AND FEEL ----
-----------------------
-- Separación compacta, borde de 2 con degradado del tema y efecto vidrio.
hl.config({
    general = {
        gaps_in  = e(3),
        gaps_out = e(6),
        border_size = math.max(1, e(2)),
        col = {
            active_border   = { colors = { theme.accent, theme.accent2 }, angle = 45 },
            inactive_border = theme.border_off,
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "scrolling", -- columnas que se desplazan de lado, al estilo Niri
    },
    decoration = {
        rounding       = e(10),
        rounding_power = 2,
        active_opacity   = theme.win_active,
        inactive_opacity = theme.win_inactive,
        fullscreen_opacity = 1.0, -- vídeos y juegos a pantalla completa, siempre opacos
        dim_inactive     = theme.dim,
        dim_strength     = theme.dim_strength,
        shadow = {
            enabled      = true,
            range        = e(4),
            render_power = 3,
            color        = 0xee1a1a1a,
        },
        blur = {
            enabled   = true,
            size      = theme.blur_size,
            passes    = theme.blur_passes,
            vibrancy  = 0.1696,
            noise     = 0.02,
            popups    = true,
        },
    },
})

-- Animaciones con rebote medio
dofile(os.getenv("HOME") .. "/.config/hypr/animaciones.lua")

----------------
----  MISC  ----
----------------
hl.config({
    misc = {
        force_default_wallpaper = 0,    -- sin los fondos de Hyprland: los pone `tema`
        disable_hyprland_logo   = true,
    },
})

---------------
---- INPUT ----
---------------
-- Teclado US; touchpad con toque para clic y desplazamiento clásico.
hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",
        numlock_by_default = true, -- Bloq Num activado al iniciar
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll       = false,
            tap_to_click         = true,
            disable_while_typing = true,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"

-- Apps: Enter = terminal, Espacio = lanzador, Z = Zen, T = Thunar, G = gelly (mostrar/esconder)
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Space",  hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + Z",      hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + T",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + G",      hl.dsp.exec_cmd("~/.config/theme/musica-bin"))

-- Ventanas: Q = cerrar, SHIFT + Q = forzar cierre, B = pantalla completa, SHIFT + B = maximizar
hl.bind(mainMod .. " + Q",         hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.kill())
hl.bind(mainMod .. " + B",         hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- Bloquear, menú de apagado (Escape), fondos y portapapeles
hl.bind(mainMod .. " + L",         hl.dsp.exec_cmd("~/.config/theme/bloquear-bin"))
hl.bind(mainMod .. " + Escape",    hl.dsp.exec_cmd("~/.config/waybar/scripts/menu-apagado")) -- el menú del botón rojo de la barra
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd("~/.config/theme/fondos-bin elegir"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.config/theme/grabar-bin")) -- grabar pantalla
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist list | rofi -dmenu -p Portapapeles | cliphist decode | wl-copy"))

-- Capturas: Impr o Super + Shift + S = elegir zona y editarla con satty; SHIFT + Impr = pantalla completa a ~/Imágenes/Capturas
hl.bind("Print",         hl.dsp.exec_cmd("~/.config/theme/captura-bin zona"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("~/.config/theme/captura-bin zona"))   -- como en Windows
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("~/.config/theme/captura-bin completa"))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + ALT + S",   hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Teclas Fn: volumen, micrófono, brillo y multimedia
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.config/theme/osd-bin volumen-sube"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.config/theme/osd-bin volumen-baja"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("~/.config/theme/osd-bin silencio"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("~/.config/theme/osd-bin mic"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("~/.config/theme/osd-bin brillo-sube"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("~/.config/theme/osd-bin brillo-baja"),                  { locked = true, repeating = true })
-- Avisos de Bloq Mayús y Bloq Num (la tecla sigue funcionando)
hl.bind("Caps_Lock", hl.dsp.exec_cmd("~/.config/theme/osd-bin mayus"),   { locked = true, non_consuming = true })
hl.bind("Num_Lock",  hl.dsp.exec_cmd("~/.config/theme/osd-bin numeros"), { locked = true, non_consuming = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Tapa: al cerrarla se apaga la pantalla interna; al abrirla vuelve.
hl.bind("switch:on:Lid Switch", function()
    hl.monitor({ output = "eDP-1", disabled = true })
end, { locked = true })
hl.bind("switch:off:Lid Switch", function()
    hl.monitor({ output = "eDP-1", disabled = false, mode = "preferred", position = "0x0", scale = 1 })
    hl.exec_cmd("~/.config/theme/tapa-bin abrir") -- si la inactividad había atenuado el brillo, lo devuelve
end, { locked = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Terminal de los ajustes (actualizar, fondos de arranque): flotando y centrada
hl.window_rule({
    name   = "ajustes-terminal",
    match  = { class = "^ajustes-terminal$" },
    float  = true,
    size   = e(900) .. " " .. e(560),
    center = true,
})

-- Ventanas pequeñas que van mejor flotando
hl.window_rule({
    name  = "float-tools",
    match = { class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-connection-editor)$" },
    float = true,
})

-- Efecto vidrio en la barra, el lanzador y las notificaciones
hl.layer_rule({
    name  = "glass-layers",
    match = { namespace = "^(waybar|rofi|swaync-control-center|swaync-notification-window)$" },
    blur  = true,
    ignore_alpha = 0.2,
})

-- Opacidad propia de kitty (activa / inactiva), según el modo de vidrio
hl.window_rule({
    name    = "kitty-opacity",
    match   = { class = "^(kitty|claude)$" },
    opacity = theme.kitty_active .. " " .. theme.kitty_inactive,
})

-- Vídeo e imágenes siempre opacos, con o sin foco: con el vidrio «total» (75 % / 10 %) se mezclaban
-- con el fondo de pantalla y los colores salían lavados. Se apaga con ⚙ → Vidrio o `vidrio medios no`.
if theme.media_opaca then
    hl.window_rule({
        name   = "media-opaca",
        match  = { class = "^(mpv|imv)$" },
        opaque = true,
    })
    -- Zen: solo con pestañas de vídeo o imagen, por el título (Hyprland vuelve a mirarlo al cambiar).
    -- Para añadir un sitio, se añade a esta lista.
    local sitios = "YouTube|Twitch|Netflix|Vimeo|Prime Video|Disney\\+|Crunchyroll|Dailymotion|Jellyfin|Plex|Kick|TikTok"
        .. "|\\d+ [×x] \\d+ (pixels|píxeles)"   -- una imagen abierta sola en una pestaña
    hl.window_rule({
        name   = "zen-media-opaca",
        match  = { class = "^zen$", title = "^.*(" .. sitios .. ").*$" },
        opaque = true,
    })
    -- Web apps (Chromium) con vídeo o fotos (Jellyfin, Immich): opacas, por el título de la ventana
    hl.window_rule({
        name   = "webapps-media-opaca",
        match  = { class = "^chrome-.*__-", title = "^.*(Jellyfin|Immich).*$" },
        opaque = true,
    })
end

-- Vista previa de la cámara (mpv con título «Cámara»): flotante y pequeña, abajo a la derecha
hl.window_rule({
    name   = "camara-vista",
    match  = { class = "^mpv$", title = "^Cámara$" },
    float  = true,
    size   = e(480) .. " " .. e(270),
    move   = "monitor_w-" .. e(490) .. " monitor_h-" .. e(320),
})

-- Lector de QR (zbarcam, vía Xwayland): flotante y pequeña, centrada
hl.window_rule({
    name   = "camara-qr",
    match  = { title = "^zbar barcode reader$" },
    float  = true,
    size   = e(480) .. " " .. e(360),
    center = true,
})

-- Claude Code (lanzador «Claude»): ventana flotante de tamaño fijo, centrada
hl.window_rule({
    name   = "claude-cli",
    match  = { class = "^claude$" },
    float  = true,
    size   = e(900) .. " " .. e(620),
    center = true,
})

-- Ventanas de "Abrir", "Guardar" y "Seleccionar": flotando y centradas
hl.window_rule({
    name   = "dialogos-centrados",
    match  = { title = "^(Abrir|Guardar|Seleccionar|Open|Save|Select).*" },
    float  = true,
    center = true,
})

-- Progreso de copias en Thunar: flotando
hl.window_rule({
    name  = "thunar-progreso",
    match = { class = "^thunar$", title = "^(Progreso|File Operation).*" },
    float = true,
})

-- Vídeo flotante de Zen (imagen en imagen): siempre visible, abajo a la derecha
hl.window_rule({
    name  = "zen-pip",
    match = { title = "^(Picture-in-Picture|Imagen en imagen)$" },
    float = true,
    pin   = true,
    size  = e(480) .. " " .. e(270),
    move  = "monitor_w-" .. e(490) .. " monitor_h-" .. e(280),
})

-- No bajar el brillo ni bloquear mientras haya algo a pantalla completa (vídeos)
hl.window_rule({
    name  = "no-dormir-pantalla-completa",
    match = { class = ".*" },
    idle_inhibit = "fullscreen",
})

-- gelly como mini reproductor: vive en el escritorio especial "musica" (Super + G)
hl.window_rule({
    name      = "gelly-mini",
    match     = { class = "^io\\.m51\\.Gelly$" },
    workspace = "special:musica silent",
    float     = true,
    size      = e(490) .. " " .. e(540),
    center    = true,
})
