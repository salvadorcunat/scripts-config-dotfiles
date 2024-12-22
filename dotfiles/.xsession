# Disable DPMS turning off the screen
 xset -dpms
 xset s off

# Disable bell
xset -b

# Enable zapping (C-A-<Bksp> kills X)
setxkbmap -option terminate:ctrl_alt_bksp

# Enforce correct locales from the beginning:
# LC_ALL is unset since it overwrites everything
# LANG=de_DE.UTF-8 is used, except for:
# LC_MESSAGES=C never translates program output
# LC_TIME=en_DK leads to yyyy-mm-dd hh:mm date/time output
unset LC_ALL
export LANG=es_ES.UTF-8
export LC_MESSAGES=C
export LC_TIME=en_DK.UTF-8

# Use XToolkit in java applications
export AWT_TOOLKIT=XToolkit

# Set background color
#xsetroot -solid "#333333"

# Enable core dumps in case something goes wrong
ulimit -c unlimited

xset +fp /home/boret/.fonts
xset fp rehash


# Modify sddm boret theme  to get a different background in next run
/home/boret/sbin/sddm_bgs.sh || \
	echo "$(date) sddm_theme.sh failed" >&2

# Start i3 and log to ~/.i3/logfile
printf "%s\n" "**********************************************************************
Starting at $(date)
**********************************************************************" >>$HOME/.i3/i3log
export XDG_CURRENT_DESKTOP="i3-gaps"
exec i3 -V >"$HOME"/.i3/i3log 2>&1

