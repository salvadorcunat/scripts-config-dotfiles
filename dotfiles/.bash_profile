# ~/.bash_profile: executed by bash(1) for login shells.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/login.defs
#umask 022

# include .bashrc if it exists
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# set PATH so it includes user's private bin if it exists
if [ -d ~/bin ] ; then
    PATH=~/bin:"${PATH}"
fi

# set default editor to vim
export EDITOR=/usr/bin/vim.nox

# set aliases
alias tig='tig --all'
alias grep='grep --color'
alias gtypist='gtypist esp.typ'

/usr/bin/dunst -config /home/boret/.config/dunst/dunstrc &
/usr/bin/udiskie -s &


source ~/.xsh

