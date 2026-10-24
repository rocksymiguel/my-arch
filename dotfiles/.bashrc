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
alias animacion="~/.config/theme/animacion-bin"
alias mosaico="~/.config/theme/mosaico-bin"
alias rebote="~/.config/theme/rebote-bin"
