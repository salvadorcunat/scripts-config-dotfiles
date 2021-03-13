#!/bin/bash
#
_usage="
	Tiny script to call from udev.
	It's meant to detect hdmi monitor attached/dettached and call
	multi-screen.sh.
	Udev rule has to be something like:
	SUBSYSTEM==\"drm\", ACTION==\"change\", RUN+=\"/bin/su -c '/home/boret/sbin/check-heads.sh' boret\"
	(double quotes scaped for this help)"
sleep 1
read -r _status </sys/devices/pci0000:00/0000:00:02.0/drm/card0/*HDMI*/status
if [[ $_status == "connected" ]]; then
	"$HOME"/sbin/multi_screen -f -d || { echo "$_usage" && exit 1; }
	logger "${0##*/}: HDMI head attached"
else
	"$HOME"/sbin/multi_screen -f -l || { echo "$_usage" && exit 1; }
	logger "${0##*/}: HDMI head dettached"
fi
