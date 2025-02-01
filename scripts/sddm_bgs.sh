#!/bin/bash
_usage="
Randomly modify sddm config file choosing different backgrounds from a given
file containing a selection of them.
The script can be run manually, but it's intended to run from another program,
e.g.  from  .i3/i3_wrapper.sh.
No parameters allowed.
Requires sudo permisions.
Requires sed, logger and notify-send.
"
. "$HOME"/sbin/script-funcs.sh

# For debuging
#_sleep="$(command -v sleep)"
#trap 'set +x; $_sleep 0.25; set -x' DEBUG

# If there is any parameter, show usage and exit
#
if (( $# > 0 )); then
	echo "$_usage"
	exit 1
fi

# notifications command
#
_notify="$(command -v notify-send)"
report()
{
	# display on screen on graph environment
	[[ -n $DISPLAY ]] && $_notify -u "$1" "$2" "$3"
	# log to syslog and send to stderr
	logger -s --id="$$" "$2 --> $3"
}

# config file for sddm background (per theme; this is for "boret") and sanity check
#
_config="/usr/share/sddm/themes/boret/theme.conf"
if [ ! -f "$_config" ]; then
	report "critical""sddm_theme.sh""failed ---> $_config doesn't exist"
	exit 1
fi

# background line number in config
#
_bgline=$(grep -n "background=" "$_config" |cut -d":" -f1)

# backgrounds list file, and sanity checks
#
_bg_repo=$HOME/sbin/.sddm_bgs.txt
if [[ ! -s $_bg_repo ]] || [[ ! -r $_bg_repo ]]; then
	abort_dlg "Sanity checks failed." "Doublecheck $_bg_repo and its permissions"
	exit 1
fi

# to get the upper randomize limit, get the number of lines in $_bg_repo,
# if _max is not set, default to 1 to avoid infinite looping in randomize()
#
_max=$(wc -l "$_bg_repo" |cut -d" " -f1)
[[ -z $_max ]] && _max=1

# randomized number, is the line to read from $_bg_repo
#
_idx=$(randomize 1 $(( _max + 1 )))

# _bg_file is the image archive (full path)
# we need to scape the backslashes to make sed work
_bg_file=$(sed -n "$_idx"p <"$_bg_repo")
_bg_file_scaped=${_bg_file//'/'/'\/'}
# apply changes
#
if [[ -n $_bg_file ]]
	then
		if sudo sed -i ${_bgline}s/background=.*/background=${_bg_file_scaped}/ "$_config"; then
			report "normal" "$0"  "SDDM background changed to ${_bg_file}"
			exit 0
		else
			report "critical" "$0" "failed to change $_config with $_bg_file_scaped"
			exit 1
		fi
	else
		report "critical" "$0" "failed to read $_bg_file or index $_idx is wrong"
		exit 1
fi
