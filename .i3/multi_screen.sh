#!/bin/bash
#
# I3 doesn't detect if a monitor is pluged. So we need
# to manually activate it.
#

_usage="
Tiny script to manage connected heads.
Parameters: One single parameter meaning the task to do:
	-d --desktop : Turn off laptop screen and set external
	-l --laptop : Turn off external screen and set laptop one
	-m --multi: Multi screen mode set an external head at the right of
	            laptop screen.
"
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

#
# Set active a single head. Turn off every other.
# Params 1.- Head to keep alive
# Returns 0 on success
#	  1 on failure
#
set_unique ()
{
	local i=0

	while [ "$i" -lt ${#_MONITORS[@]} ]; do
		[ "$i" -ne "$1" ] && $XRANDR --output "${_MONITORS["$i"]}" --off
		(( i++ ))
	done

	if $XRANDR --output "${_MONITORS[$1]}" --primary --mode "${_MODES[$1]}" --fb "${_MODES[$1]}" --rotate 'normal' --pos 0x0 2> $TMPFILE
	then
		return 0
	else
		return 1
	fi

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

# Check if there is more than one monitor
if [[ -z ${_MONITORS[1]} ]]; then
	report2screen  normal "${0##*/}" "There is just one monitor. No multi screen posibility"
	RC=2
	exit $RC
fi

# Read CLI parameters
if [ $# -ne 1 ]; then
	report2screen  critical "${0##*/}" "Bad parameters. Aborting."
	RC=2
	exit $RC
fi

case "$1" in
	-d|--desktop)	if set_unique 1
			then
				report2screen normal "${0##*/}" "Multi screen operations:\\n${_MONITORS[1]} set as primary monitor with resolution ${_MODES[1]}.\\nLaptop screen ${_MONITORS[0]} turned off"
			else
				report2screen critical "${0##*/}" "$(cat $TMPFILE)\\n$(XRANDR |grep -e \ connected)"
				RC=1
				exit $RC
			fi ;;
	-l|--laptop)	if set_unique 0
			then
				report2screen normal "${0##*/}" "Multi screen operations:\\n${_MONITORS[0]} set as primary monitor with resolution ${_MODES[0]}.\\nExternal screen ${_MONITORS[1]} turned off"
			else
				report2screen critical "${0##*/}" "$(cat $TMPFILE)\\n$(XRANDR |grep -e \ connected)"
				RC=1
				exit $RC
			fi ;;
	-m|--multi)	if $XRANDR --output "${_MONITORS[1]}" --rotate 'normal' --right-of "${_MONITORS[0]}" --mode "${_MODES[1]}" 2> $TMPFILE
			then
				report2screen normal "${0##*/}" "Multi screen operations enabled\\n${_MONITORS[1]} at the right of ${_MONITORS[0]} with resolution ${_MODES[1]}"
			else
				report2screen critical "${0##*/}" "$(cat $TMPFILE)\\n$(XRANDR |grep -e \ connected)"
				RC=1
				exit $RC
			fi ;;
	*)		echo "$_usage"
			RC=0
			exit $RC ;;
esac

# Are we running i3_lemonbar script? Reinit it.
# i3_lemonbar.sh reads screen size at init. we need a reload to adjust to new size.
if pgrep i3_lemonbar.sh >/dev/null 2>&1 ; then
	"$HOME"/.i3/lemonbar/i3_lemonbar_wrap.sh >&2
fi
