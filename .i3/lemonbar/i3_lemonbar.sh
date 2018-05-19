#! /bin/bash
#
# I3 bar with https://github.com/LemonBoy/bar
#
# Boret 04/2018 : Actually uses lemonbar-xft from
# https://github.com/krypt-n/bar.git as regular lemonbar fails miserbly
# to work with fontconfig.

_pwd="$(dirname "$0")"
. "${_pwd}"/i3_lemonbar_config
#set -x
trap 'trap - TERM; kill 0' INT TERM QUIT EXIT

[ -e "${panel_fifo}" ] && rm "${panel_fifo}"
mkfifo "${panel_fifo}"

### EVENTS METERS

# Window title, "WIN"
xprop -spy -root _NET_ACTIVE_WINDOW | sed -un 's/.*\(0x.*\)/WIN\1/p' > "${panel_fifo}" &

# Background scripts which have their own delay time if any, and don't fit
# well with the 1 second delay set in this script.

# i3 Workspaces, "WSP"
# TODO : Restarting I3 breaks the IPC socket con. :(
# Boret: Do not run if not on i3wm
if [[ $(basename "${DESKTOP_SESSION}") == *i3* ]]; then
	"${_pwd}"/i3_workspaces.pl > "${panel_fifo}" &
fi

# Boret battery
"${_pwd}"/battery 2>/dev/null > "${panel_fifo}" &

# Boret hard disks
"${_pwd}"/disk / /home /media/DATOS > "${panel_fifo}" &

while :; do

	# Boret Audio Volume
	"${_pwd}"/volume > "${panel_fifo}"

	# Boret CPU
	"${_pwd}"/cpu_usage_boret > "${panel_fifo}"

	# Boret bandwidth up/down
	"${_pwd}"/bandwidth > "${panel_fifo}"

	# Boret iface (wifi interface - internal IP)
	"${_pwd}"/iface > "${panel_fifo}"

	# Boret Wifi AP
	"${_pwd}"/wifi > "${panel_fifo}"

	# Boret removable disks
	"${_pwd}"/removable-media> "${panel_fifo}"

	# Boret capslock
	"${_pwd}"/keyindicator CAPS > "${panel_fifo}"

	# Boret numlock
	"${_pwd}"/keyindicator NUM > "${panel_fifo}"

	# Finally, wait 1 second
	sleep 1s;

done &

#### LOOP FIFO
"${_pwd}"/i3_lemonbar_parser.sh <"${panel_fifo}" \
	| lemonbar -b -n "boret_lemonbar" -a 15 -f "${font}" -f "${iconfont}" -f "${monofont}" -g "${geometry}" &

wait
