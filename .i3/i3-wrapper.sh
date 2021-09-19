#!/bin/bash


XRANDR="$(command -v xrandr)"
NOTIFY="$(command -v notify-send)"
TMPFILE=/tmp/tmp_$$
declare -a _MONITORS
declare -a _MODES

trap 'rm -f $TMPFILE' 0 1 2

. $HOME/sbin/script-funcs.sh

# get preferred mode for monitors
# parameters	1.- global variable to store the modes, default to _MODES
# output:	none
# returns:	0 on success, 1 on failure
#
get_modes ()
{
	declare -n _modes=${1:-_MODES}
	local IFS=$'\n'
	_modes=( $($XRANDR |grep -v connect |grep + |sed s/^\ *//) )
	local i=0
	while [ $i -lt ${#_modes[@]} ]; do
		_modes[$i]=${_modes[$i]%%\ *}
		(( i++ ))
	done
}

# Reporting messages and errors format.
# Put a report in the screen and send another to stderr, which should
# be printed to .xsession-errors
# Parameters	1.- report level for notify-send, e.g. normal
#		2.- header for notify send, usually the program name
#		3.- tex message
#
report2screen()
{
	report_msg "$2" "$3" >&2
	$NOTIFY -u "$1" "$2" "$3"
}

# Create an array with avaliable _MONITORS
_MONITORS=( $($XRANDR |grep " connected" |cut -d" " -f1) )

# Create an array with preferred _MONITORS resolutions
get_modes _MODES

# Activate connected monitor
if [ ${#_MONITORS[@]} -gt 1 ]; then
	if $XRANDR --output "${_MONITORS[1]}" --primary --mode "${_MODES[1]}" --rotate 'normal' --pos 0x0 2> $TMPFILE
		then
			report2screen normal "${0##*/}" "Enabled just one monitor.\\n${_MONITORS[1]} with resolution ${_MODES[1]}"
		else
			report2screen critical "${0##*/}" "$(cat $TMPFILE)\\n$(XRANDR |grep -e \ connected)"
	fi
fi

	SDDM_CURRENT_BG="$(grep background "/usr/share/sddm/themes/boret/theme.conf" |cut -d"=" -f2)"
	export SDDM_CURRENT_BG

# Modify sddm boret theme  to get a different background in next run
/home/boret/sbin/sddm_bgs.sh || \
	echo "$(date) sddm_bg.sh failed" >&2

# Launch i3
/usr/local/bin/i3 -V >"$HOME"/.i3/i3log 2>&1
