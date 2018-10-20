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
	-m --multi: Multi screen mode set external heads left, right or both
		    of laptop screen. Defaults to external at the right of
		    laptop's, but can be changed. Keep in mind that laptop
		    is "0" usually. E.g.:
		    multi_screen.sh -m 1 0  will place external head left of
		    laptop's screen.
		    multi_screen -m 0 1 2   will place 1 at the center, with 0
		    and 2 in the left and right sides.
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

#
# Set multi head.
# Params: 2 or 3 depending of heads number.
#	- If 2 params: $2 is at right of $1.
#	- If 3 params: $2 is at center; $1 at left and $3 at right.
# Return: nothing; exit script on failure.
set_multi ()
{
	case "$#" in
		2)	if $XRANDR --output "${_MONITORS["$2"]}" --rotate 'normal' --right-of "${_MONITORS["$1"]}" --mode "${_MODES["$2"]}" 2> $TMPFILE
			then
				report2screen normal "${0##*/}" "Multi screen operations enabled\\n${_MONITORS["$2"]} at the right of ${_MONITORS["$1"]} with resolution ${_MODES["$2"]}"
			else
				report2screen critical "${0##*/}" "$(cat $TMPFILE)\\n$(XRANDR |grep -e \ connected)"
				exit 1
			fi ;;
		3)	if $XRANDR --output "${_MONITORS["$3"]}" --rotate 'normal' --right-of "${_MONITORS["$2"]}" --mode "${_MODES["$3"]}" 2> $TMPFILE
			then
				report2screen normal "${0##*/}" "Multi screen operations enabled\\n${_MONITORS["$3"]} at the right of ${_MONITORS["$2"]} with resolution ${_MODES["$3"]}"
			else
				report2screen critical "${0##*/}" "$(cat $TMPFILE)\\n$($XRANDR |grep -e \ connected)"
				exit 1
			fi
			if $XRANDR --output "${_MONITORS["$1"]}" --rotate 'normal' --left-of "${_MONITORS["$2"]}" --mode "${_MODES["$1"]}" 2> $TMPFILE
			then
				report2screen normal "${0##*/}" "Multi screen operations enabled\\n${_MONITORS["$1"]} at the left of ${_MONITORS["$2"]} with resolution ${_MODES["$1"]}"
			else
				report2screen critical "${0##*/}" "$(cat $TMPFILE)\\n$($XRANDR |grep -e \ connected)"
				exit 1
			fi ;;
	esac
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
if [ $# -lt 1 ]; then
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
	-m|--multi)	case "$#" in
				4)	set_multi "$2" "$3" "$4" ;;
				3)	set_multi "$2" "$3" ;;
				2)	report2screen critical "${0##*/}" "multi\\nWrong number of parameters\\nSet two monitors at least." && exit 1 ;;
				*)	set_multi 0 1 ;;
			esac ;;
	*)		echo "$_usage"
			RC=0
			exit $RC ;;
esac

# Are we running i3_lemonbar script? Reinit it.
# i3_lemonbar.sh reads screen size at init. we need a reload to adjust to new size.
if pgrep i3_lemonbar.sh >/dev/null 2>&1 ; then
	"$HOME"/.i3/lemonbar/i3_lemonbar_wrap.sh >&2
fi
