#!/bin/bash

_CRT="$(which cool-retro-term)"
_TERMINATOR="$(which terminator)"
_I3MSG="$(which i3-msg)"
_AMIXER="$(which amixer)"
_STEP="5%"

# Audio device.
#Return "Capture" if the device is a capture device
capability() {
	amixer -D "default" get "Master" |
	sed -n "s/  Capabilities:.*cvolume.*/Capture/p"
}

while read -r _line; do
	case "$_line" in
		iface|wifi_ap|bdwidth)
			"$_CRT" -e wicd-curses
			;;
		cpu_load)
			"$_TERMINATOR" -b -T "Mpstat" -p floating --geometry=700x120 -e 'mpstat -P ALL 1'
			;;
		change_ws*)
			"$_I3MSG" workspace "${_line##*\ }"
			;;
		vol_mixer*)
			"$_TERMINATOR" -b -T "Mixer" -p floating -e "alsamixer -g -c 0 -V -all"
			;;
		vol_mute*)
			"$_AMIXER" -q -D "default" sset "Master" "$(capability)" toggle
			;;
		vol_up*)
			"$_AMIXER" -q -D "default" sset "Master" "$(capability)" ${_STEP}+ unmute
			;;
		vol_down*)
			"$_AMIXER" -q -D "default" sset "Master" "$(capability)" ${_STEP}- unmute
			;;
	esac
done
wait
