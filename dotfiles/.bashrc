# .bashrc

# User specific aliases and functions
PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/sbin:/usr/sbin:/usr/local/sbin:/home/boret/sbin:/home/boret/.local/bin:/home/boret/src/install-root/bin

  # Adndroid  development kit definitions
#  export M2_HOME=/usr/local/apache-maven/apache-maven-3.2.1
#  export M2=$M2_HOME/bin
#  export ANDROID_HOME=/home/boret/android-sdk-linux
#  PATH=$M2:$ANDROID_HOME:$PATH

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# enable programmable completion features
if [ -f /etc/bash_completion ]; then
	. /etc/bash_completion
fi

# Set readline mode to vim [boret]
set -o vi

#export TERM="screen.xterm-256color"
export TERM="xterm-termite"
# Activamos un "prompt" coloreado
color_prompt=yes
force_color_prompt=yes
#PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[01;34m\]@\[\033[01;34m\]\h\[\033[00m\]:\[\033[01;34m\]\w \$\[\033[00m\] '

# Para mostrar "branches" en repos git, en el prompt
# uncomment without powerline
function parse_git_branch {
	branch="$(git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')"
	# Al usar echo o printf es necesario eliminar \[  y \] de los colores. Estos son
	# necesarios en la variable PS1 para evitar line wrapping
	prompt_color=${prompt_color:2}; prompt_color=${prompt_color%\\]}
	info_color=${info_color:2}; info_color=${info_color%\\]}
	[ -n "$branch" ] && echo -ne "$prompt_color-[$info_color$branch$prompt_color]"
}
#function proml {
	#local        BLUE="\[\033[0;34m\]"
	## OPTIONAL - if you want to use any of these other colors:
	#local         RED="\[\033[0;31m\]"
	#local   LIGHT_RED="\[\033[1;31m\]"
	#local       GREEN="\[\033[0;32m\]"
	#local LIGHT_GREEN="\[\033[1;32m\]"
	#local       WHITE="\[\033[1;37m\]"
	#local  LIGHT_GRAY="\[\033[0;37m\]"
	## END OPTIONAL
	#local     DEFAULT="\[\033[0m\]"
##	PS1="\h:\W \u$BLUE\$(parse_git_branch) $DEFAULT\$"
	#PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[01;34m\]@\[\033[01;34m\]\h\[\033[00m\]:\[\033[01;34m\]\w$BLUE\$(parse_git_branch) \$\[\033[00m\] "
#}
#proml

# uncomment for xiki
# source ~/.xsh

# added by travis gem
[ -f /home/boret/.travis/travis.sh ] && source /home/boret/.travis/travis.sh

# uncomment for powerline prompt. boret. 26-02-2018
#if [ -f "$(command -v powerline-daemon)" ]; then
  #powerline-daemon -q
  #export POWERLINE_BASH_CONTINUATION=1
  #export POWERLINE_BASH_SELECT=1
  #. /usr/share/powerline/bindings/bash/powerline.sh
#fi

# For Kali like prompt
#
# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# The following block is surrounded by two delimiters.
# These delimiters must not be modified. Thanks.
# START KALI CONFIG VARIABLES
PROMPT_ALTERNATIVE=twoline
NEWLINE_BEFORE_PROMPT=yes
# STOP KALI CONFIG VARIABLES

if [ "$color_prompt" = yes ]; then
    # override default virtualenv indicator in prompt
    VIRTUAL_ENV_DISABLE_PROMPT=1

    prompt_color='\[\033[;32m\]'
    info_color='\[\033[1;34m\]'
    prompt_symbol=☣
    #㉿
    if [ "$EUID" -eq 0 ]; then # Change prompt colors for root user
        prompt_color='\[\033[;94m\]'
        info_color='\[\033[1;31m\]'
        prompt_symbol=💀
    fi
    #git_branch="$(parse_git_branch)"
    case "$PROMPT_ALTERNATIVE" in
        twoline)
		PS1=$prompt_color'┌──${debian_chroot:+($debian_chroot)──}${VIRTUAL_ENV:+(\[\033[0;1m\]$(basename $VIRTUAL_ENV)'$prompt_color')}('$info_color'\u ${prompt_symbol} \h'$prompt_color')-[\[\033[0;1m\]\w'$prompt_color']$(parse_git_branch)\n'$prompt_color'└─'$info_color'\$\[\033[0m\] ';;
        oneline)
            PS1='${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV)) }${debian_chroot:+($debian_chroot)}'$info_color'\u@\h\[\033[00m\]:'$prompt_color'\[\033[01m\]\w\[\033[00m\]\$ ';;
        backtrack)
            PS1='${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV)) }${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ ';;
    esac
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

[ "$NEWLINE_BEFORE_PROMPT" = yes ] && PROMPT_COMMAND="PROMPT_COMMAND=echo"

# set aliases
alias grep='grep --color'
alias yavide="vim --servername yavide -f -N -u /opt/yavide/.vimrc"
alias ls="ls --color=auto"
alias vimcat="vimcat +n --"
alias crt='cool-retro-term -p boret'
alias cat='batcat --paging=never --plain'
alias gitea-connect='/usr/bin/surf -g -n -t -z 0.75 https://192.168.0.172:3000 2> /dev/null &'
alias pihole-connect='/usr/bin/surf -g -n -t -z 0.75 http://192.168.0.172:8008 2> /dev/null &'
alias dol_guldur-connect='/usr/bin/surf -g -n -t -z 0.75 https://192.168.0.2:8443 2> /dev/null &'
alias rpi-connect='ssh boret@192.168.0.172'
alias rpi-btop='ssh boret@192.168.0.172 "xterm -e btop"'
alias surf="/usr/bin/surf -g -n -t -z 0.75"

# For alacritty terminal
#
. "$HOME/.cargo/env"
source ~/.bash_completion/alacritty

# rtv environment vars
#
export RTV_BROWSER="surf -g -n -t -z 0.75"
