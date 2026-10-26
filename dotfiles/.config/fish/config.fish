# fish: la shell de kitty. La TTY sigue con bash (ahí está el alias hypr).

set -g fish_greeting ""                       # sin el mensaje de bienvenida
set -gx EDITOR nano
set -gx VISUAL nano
set -gx BAT_THEME ansi                        # bat usa los colores del tema de kitty
set -gx FZF_DEFAULT_OPTS "--color=16 --height=40% --layout=reverse --border=rounded"

# Comandos propios del escritorio
alias tema       "~/.config/theme/tema"
alias vidrio     "~/.config/theme/vidrio-bin"
alias tamano     "~/.config/theme/tamano-bin"
alias inactividad "~/.config/theme/inactividad-bin"
alias fondos     "~/.config/theme/fondos-bin"
alias musica     "~/.config/theme/musica-bin"
alias logo       "~/.config/theme/logo-bin"
alias hypr       "start-hyprland"
alias modo       "~/.config/theme/modo-bin"

# Herramientas modernas
alias ls  "eza --icons --group-directories-first"
alias ll  "eza --icons --group-directories-first -l --git"
alias la  "eza --icons --group-directories-first -la --git"
alias tree "eza --icons --tree"
alias cat "bat --paging=never"

if status is-interactive
    # En la TTY (sin iconos ni colores ricos) prompt sencillo; en kitty, starship
    if test "$TERM" != linux
        starship init fish | source
    end
    zoxide init fish | source                 # z <carpeta>: cd inteligente
    fzf --fish | source                       # Ctrl+R historial, Ctrl+T archivos

    # yazi: al salir, quedarse en la carpeta donde estabas
    function y
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end

    # fastfetch al abrir kitty (solo en la primera ventana de cada terminal)
    if test "$TERM" = xterm-kitty; and not set -q FASTFETCH_HECHO
        set -gx FASTFETCH_HECHO 1
        fastfetch
    end
end

# Inicio automático en tty1: abrir el modo elegido en el menú de arranque (Limine).
# Al salir sin pedir otro modo se vuelve aquí, a la terminal.
if status is-login; and test (tty) = /dev/tty1; and not set -q WAYLAND_DISPLAY; and not set -q MODO_LANZADO
    set -gx MODO_LANZADO 1
    ~/.config/theme/modo-bin arrancar
end
