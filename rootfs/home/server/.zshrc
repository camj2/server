#!/bin/zsh

autoload -Uz compinit add-zsh-hook up-line-or-beginning-search down-line-or-beginning-search
compinit

export PATH="$PATH:$HOME/.bin"

export SVDIR="$HOME/.sv"

export LESSHISTFILE=-

export ZFS_COLOR=1

eval "$(dircolors -b)"

zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

zstyle ':completion:*' menu select

zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'

setopt autocd
setopt globdots
setopt histignoredups

typeset -g -A key

key[Up]='^[[A'
key[Down]='^[[B'

key[Control-Left]='^[[1;5D'
key[Control-Right]='^[[1;5C'

bindkey "${key[Control-Left]}" backward-word
bindkey "${key[Control-Right]}" forward-word

zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey "${key[Up]}" up-line-or-beginning-search
bindkey "${key[Down]}" down-line-or-beginning-search

PS1='%B%F{cyan}%n@%M %F{blue}%~ $%b%f '

function reset_broken_terminal() {
  printf %b '\e[0m\e(B\e)0\017\e[?5l\e7\e[0;0r\e8'
}

add-zsh-hook -Uz precmd reset_broken_terminal

function clear_screen() {
    printf '\x1Bc'
    zle clear-screen
    zle kill-whole-line
}

zle -N clear_screen
bindkey '^L' clear_screen

alias sudo=doas

alias f=pfetch

alias cal="cal -y"

alias grep="grep --color=auto"
alias diff="diff --color=auto"

alias bat="bat --paging=never --theme=base16 --tabs=4"

alias l="lsd -la"
alias la="lsd -la"
alias ls="lsd -A"
alias lt="lsd -A --tree"
alias lta="lsd -la --tree"

alias zl="zfs list -t snapshot -s creation -o name,creation"
alias zu="zfs list -t snapshot -s used -o name,used"
