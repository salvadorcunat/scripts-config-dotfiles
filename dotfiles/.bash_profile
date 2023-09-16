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

# other stuff
if [ -n "$DISPLAY" ]; then
	/usr/bin/udiskie -s &
	case "$DESKTOP_SESSION" in
		*i3*|*spectrwm*)
			/usr/bin/dunst -config /home/boret/.config/dunst/dunstrc &
			#/usr/bin/lxqt-notificationd &
			;;
		*nstant*)
			/usr/bin/dunst -config /home/boret/.config/dunst/dunstrc &
			/home/boret/.i3/fehbg_new -d 10m &
			;;
		*)	;;
	esac
else
	/usr/bin/udiskie -q &
	fortune |cowsay -f r2d2
fi

# set history size
export HISTSIZE=10000

# set personal libraries
export LD_LIBRARY_PATH="$HOME"/src/install-root/lib:"$LD_LIBRARY_PATH"

# set QT5 var needed by qt5ct
export QT_QPA_PLATFORMTHEME="qt5ct"

# trying to run libreoffice without crashing it
# currently works fine with qt5 and kf5
export SAL_USE_VCLPLUGIN="qt5"

. "$HOME/.cargo/env"
