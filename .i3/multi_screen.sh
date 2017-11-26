#!/bin/bash
#
# I3 doesn't detect if a monitor is pluged. So we need
# to manually activate it.
#

XRANDR=/usr/bin/xrandr
NOTIFY=/usr/bin/notify-send
TMPFILE=/tmp/tmp_$$
RC=0
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
	local _xrandr=$XRANDR
	_modes=( $($_xrandr |grep -v connect |grep + |sed s/^\ *//) )
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

# Activate secondary monitor at the right  of main laptop monitor if there is
# such a second monitor
if [[ ! -z ${_MONITORS[1]} ]]; then
	if $XRANDR --output "${_MONITORS[1]}" --rotate 'normal' --right-of "${_MONITORS[0]}" --mode "${_MODES[1]}" 2> $TMPFILE
		then
			report2screen normal "${0##*/}" "Multi screen operations enabled\n${_MONITORS[1]} at the right of ${_MONITORS[0]} with resolution ${_MODES[1]}"
		else
			report2screen critical "${0##*/}" "$(cat $TMPFILE)\n$(XRANDR |grep -e \ connected)"
			RC=1
	fi
else
	report2screen  normal "${0##*/}" "There is just one monitor. No multi screen posibility"
	RC=2
fi
exit $RC
