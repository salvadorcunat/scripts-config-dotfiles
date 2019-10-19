#!/bin/bash
#
# Parse the output of lemonbar.
# Most lemonbar blocks just catch the left mouse button click, but the audio
# block is special as it catches 1,3,4 and 5 buttons.
#
_CRT="$(which cool-retro-term)"
_TERMINATOR="$(which terminator)"
_I3MSG="$(which i3-msg)"
_AMIXER="$(which amixer)"
_STEP="5%"
_BLTMAN="$(command -v blueman-manager)"

. $(dirname $0)/i3_lemonbar_config

# Audio device.
# Return "Capture" if the device is a capture device
capability() {
	amixer -D "default" get "Master" |
	sed -n "s/  Capabilities:.*cvolume.*/Capture/p"
}

while read -r _line; do
	case "$_line" in
		iface|wifi_ap|bdwidth)
			"$_CRT" -e wicd-curses &
			;;
		cpu_load)
			#"$_TERMINATOR" -b -T "Mpstat" -p floating --geometry=700x120 -e 'mpstat -P ALL 1' &
			"$_TERMINATOR" -b -T "Mpstat" -p floating -e 'gotop' &
			;;
		change_ws*)
			"$_I3MSG" workspace "${_line##*\ }" &
			;;
		blt_man*)
			"$_BLTMAN" &
			;;
		blt_term*)
			"$_TERMINATOR" -b -T "Bluetoothctl" -p floating -e "sudo bluetoothctl" 2>/dev/null &
			;;
		vol_mixer*)
			"$_TERMINATOR" -b -T "Mixer" -p floating -e "alsamixer -g -c 0 -V -all" &
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
		umount*)
			# catch click on removable media block. format the device name and print a
			# string to lemonbar fifo to launch a warning block
			_disk="${_line#*_}"; _disk="${_disk%\ *}"; _disk="${_disk#*\ }"; _disk="${_disk#??}"
			printf "%s\n" "WARN_detach_${_disk}" >"${panel_fifo}"
			unset _disk
			;;
		detach*)
			# catch umount confirmation; umount the passed device and send a string to
			# lemonbar fifo to remove the warning block
			udiskie-umount --detach /dev/"${_line##*_}"
			printf "%s\n" "WARN_" >"${panel_fifo}"
			;;
		warn_cancel)
			# catch warning cancel; send a string to lemonbar fifo to remove warning block
			printf "%s\n" "WARN_" >"${panel_fifo}"
			;;
	esac
done
