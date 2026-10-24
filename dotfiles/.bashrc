#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# Abrir Hyprland desde la TTY
alias hypr="start-hyprland"
alias tema="~/.config/theme/tema"
alias vidrio="~/.config/theme/vidrio-bin"
alias inactividad="~/.config/theme/inactividad-bin"
alias fondos="~/.config/theme/fondos-bin"
alias musica="~/.config/theme/musica-bin"
alias cursor="~/.config/theme/cursor-bin"
