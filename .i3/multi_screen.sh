#!/bin/bash
#
# I3 doesn't detect if a monitor is pluged. So we need
# to manually activate it.
#
_usage="
Tiny script to manage connected heads.
Parameters: One single parameter meaning the task to do:
	-f --force: Do not check for connected heads (this has to be the first param)
	-d --desktop : Turn off laptop screen and set external
	-l --laptop : Turn off external screen and set laptop one
	-m --multi: Multi screen mode set external heads left, right or both
		    of laptop screen. Defaults to external at the right of
		    laptop's, but can be changed. Keep in mind that laptop
		    is '0' usually. E.g.:
		    multi_screen.sh -m 1 0  will place external head left of
		    laptop's screen.
		    multi_screen -m 0 1 2   will place 1 at the center, with 0
		    and 2 in the left and right sides.
	-max: Works like --multi, but scales the smaller monitor to the higher resolution.
	-min: Works like --multi, but scales the bigger monitor to the lower resolution.
"
. $HOME/sbin/script-funcs.sh

if [[ $XDG_SESSION_TYPE == wayland ]], then
	exit 0
fi

XRANDR="$(command -v xrandr)"; [[ -z $XRANDR ]] && report_msg "${0##*/}"  "xrandr not avaliable" >&2 && exit 1
TMPFILE=/tmp/tmp_$$
_force="false"
RC=0
declare -a _MONITORS
declare -a _MODES
trap 'rm -f $TMPFILE' 0 1 2

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

# return the array position of the higher resolution
# currently only support two monitors
# return 99 if equal.
#
bigger()
{
	if (( ${1%%x*} > ${2%%x*} )); then
		printf "0"
	elif (( ${2%%x*} > ${1%%x*} )); then
		printf "1"
	else
		printf "99"
	fi
}

smaller()
{
	if (( ${1%%x*} > ${2%%x*} )); then
		printf "1"
	elif (( ${2%%x*} > ${1%%x*} )); then
		printf "0"
	else
		printf "99"
	fi
}

scale_factor()
{
	if [[ $_scale == "max" ]]; then
		_x_factor=$(echo "scale=2;${_higher_res%%x*}/${1%%x*}" |bc -l)
		_y_factor=$(echo "scale=2;${_higher_res##*x}/${1##*x}" |bc -l)
	elif [[ $_scale == "min" ]]; then
		_x_factor=$(echo "scale=2;${_lower_res%%x*}/${1%%x*}" |bc -l)
		_y_factor=$(echo "scale=2;${_lower_res##*x}/${1##*x}" |bc -l)
	else
		_x_factor=1
		_y_factor=1
	fi
	printf "${_x_factor}x${_y_factor}"
}

#
# Set active a single head. Turn off every other.
# Params 1.- Head to keep alive
# Returns 0 on success
#	  1 on failure
#
set_unique ()
{
	# Check if there is more than one monitor
	if [[ -z ${_MONITORS[1]} && $_force == "false" ]]; then
		report2screen  normal "${0##*/}" "There is just one monitor. No multi screen posibility"
		RC=2
		exit $RC
	fi

	local i=0

	while [ "$i" -lt ${#_MONITORS[@]} ]; do
		[ "$i" -ne "$1" ] && $XRANDR --output "${_MONITORS["$i"]}" --off
		(( i++ ))
	done

	if $XRANDR --output "${_MONITORS[$1]}" --primary --mode "${_MODES[$1]}" --fb "${_MODES[$1]}" --rotate 'normal' --scale '1x1' --pos 0x0 2> $TMPFILE
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
	if [[ -z ${_MONITORS[1]} && $_force == "false" ]]; then
		report2screen  normal "${0##*/}" "There is just one monitor. No multi screen posibility"
		RC=2
		exit $RC
	fi

	_big_head="$(bigger "${_MODES[0]}" "${_MODES[1]}")"
	_small_head="$(smaller "${_MODES[0]}" "${_MODES[1]}")"
	_higher_res="${_MODES[$_big_head]}"
	_lower_res="${_MODES[$_small_head]}"

	# Turn on every monitor
	i=0
	while (( i < ${#_MONITORS[@]} )); do
		"$XRANDR" --output "${_MONITORS[$i]}" --rotate normal --mode "${_MODES[$i]}" --scale "$(scale_factor "${_MODES[$i]}")"
		(( i++ ))
	done

	# Set new screen size (for all monitors)
	for q in ${_MODES[*]}; do
		str="$str+${q%%x*}"
	done;
	str=${str#+}
	_total_width=$(echo "$str" |bc -l)
	_total_height=${_higher_res#*x}
	$XRANDR --fb "${_total_width}"x"${_total_height}"
	unset q str

	case "$#" in
		2)	if $XRANDR --output "${_MONITORS["$2"]}" --rotate 'normal' --right-of "${_MONITORS["$1"]}" 2> $TMPFILE
			then
				report2screen normal "${0##*/}" "Multi screen operations enabled\\n${_MONITORS["$2"]} at the right of ${_MONITORS["$1"]} with resolution ${_MODES["$2"]}"
			else
				report2screen critical "${0##*/}" "$(cat $TMPFILE)\\n$($XRANDR |grep -e \ connected)"
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

# Create an array with avaliable _MONITORS
_MONITORS=( $($XRANDR |grep " connected" |cut -d" " -f1) )

# Create an array with preferred _MONITORS resolutions
get_modes _MODES

# Read CLI parameters
if [ $# -lt 1 ]; then
	report2screen  critical "${0##*/}" "Bad parameters. Aborting."
	RC=2
	exit $RC
fi
i=0
while (( $# > 0 )); do
	case "$1" in
		-d|--desktop)	if set_unique 1
				then
					report2screen normal "${0##*/}" "Multi screen operations:\\n${_MONITORS[1]} set as primary monitor with resolution ${_MODES[1]}.\\nLaptop screen ${_MONITORS[0]} turned off"
				else
					report2screen critical "${0##*/}" "$(cat $TMPFILE)\\n$($XRANDR |grep -e \ connected)"
					RC=1
					exit $RC
				fi
				break ;;
		-l|--laptop)	if set_unique 0
				then
					report2screen normal "${0##*/}" "Multi screen operations:\\n${_MONITORS[0]} set as primary monitor with resolution ${_MODES[0]}.\\nExternal screen ${_MONITORS[1]} turned off"
				else
					report2screen critical "${0##*/}" "$(cat $TMPFILE)\\n$($XRANDR |grep -e \ connected)"
					RC=1
					exit $RC
				fi
				break ;;
		-m|--multi)	case "$#" in
					4)	set_multi "$2" "$3" "$4" ;;
					3)	set_multi "$2" "$3" ;;
					2)	report2screen critical "${0##*/}" "multi\\nWrong number of parameters\\nSet two monitors at least." && exit 1 ;;
					*)	report2screen critical "${0##*/}" "multi\\nWrong number of parameters\\nToo much monitors." && exit 1 ;;
				esac
				break ;;
		-f|--force)	_force="true"
				shift ;;
		--max)		_scale="max"
				shift ;;
		--min)		_scale="min"
				shift ;;
		*)		echo "$_usage"
				RC=0
				exit $RC ;;
	esac
done

# Are we running i3_lemonbar script? Reinit it.
# i3_lemonbar.sh reads screen size at init. we need a reload to adjust to new size.
if pgrep i3_lemonbar.sh >/dev/null 2>&1 ; then
	"$HOME"/.i3/lemonbar/i3_lemonbar_wrap.sh >&2
fi
