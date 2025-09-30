# Custom bash settings for the dev container

# Enable vi mode for the command line
set -o vi

# Colorized output and aliases
export LS_OPTIONS='--color=auto'
eval "$(dircolors)"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias l='ls $LS_OPTIONS -lA'
