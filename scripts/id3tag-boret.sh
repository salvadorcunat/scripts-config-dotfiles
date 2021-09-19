#!/bin/bash
#
# For debugging
#_sleep="$(command -v sleep)"
#trap 'set +x; $_sleep 0.25; set -x' DEBUG

_usage="
Kdialog front to avoid repetitive id3tag command line calls on full folder
files, which are complex to remember onece and again.
"
# Return codes
#
OK=0
CANCEL=1

# Helper programs
#
_dialog="$(command -v kdialog)" || { echo "Can't find kdialog, aborting." && exit 1; }
_tool="$(command -v id3tag)" || { echo "Can't find exiftool, aborting." && exit 1; }

# aborting message
# WARNING: $_title should be declared script global for consistency
# parameters:	1- Error related messages
# --pasivepopup generates a message for the notification daemon instead of a
# popup window.
#
abort_dlg()
{
	$_dialog --title "$_title" --passivepopup "${1:-Aborting}" 2
}

# Id3 V2 tags to change.
# A dialog to select which tags we want to change
# Returns an string with the selected options
#
tag_select_dlg()
{
	local _options=( Artist Album Song Year Number Totalnum )
	local _tags=( a A s y t T )
	i=0
	_str=""
	while [ "$i" -lt ${#_options[@]} ]; do
		_str+="${_tags[$i]} ${_options[$i]} off "
		(( i++ ))
	done
	$_dialog --title "$_title" --checklist "Please select the tags to add/modify" $_str
}

options_dlg()
{
	local _value
	local _message="Insert a shell command or a value. If value, SINGLE QUOTE it."

	_value="$($_dialog --title $_title --inputbox "$_message" "$1")"
	check_RC $?
	echo "-$1 $_value"
}

# Checking return codes from kdialog
#
check_RC()
{
	case "$1" in
		"$CANCEL")	abort_dlg "ESC or CANCEL pressed.\nExiting."
				return "$1";;
		*)		return "$1";;
	esac
}

# Default initial folder
#
_init_dir="/media/DATOS/musica"
_title="MP3 files tagging"

# Read parameter if any
#
while [ "$#" -gt 0 ]; do
	case "$1" in
		-d|--dir) _init_dir="$2"
			  shift 2;;
		*)	  echo "$_usage"
			  exit 0;;
	esac
done

# Main loop
#
while : ; do
	_dir="$("$_dialog" --title "$_title" --getexistingdirectory "$_init_dir" "*")"
	check_RC $?
	if [ "$?" -eq 1 ]; then
		exit 0
	fi
	cd "$_dir" || { abort_dlg "Couldn't cd into $_dir"; exit 1; }
	_sel_tags=( $(tag_select_dlg) )
	i=0
	_command="$_tool"
	while [ $i -lt ${#_sel_tags[@]} ]; do
		_command+=" $(options_dlg "${_sel_tags[$i]}")"
		(( i++ ))
	done
	echo "$_command"
done
