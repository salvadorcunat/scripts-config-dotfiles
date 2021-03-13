#!/bin/bash
#
# For debugging
#_sleep="$(which sleep)"
#trap 'set +x; $_sleep 0.25; set -x' DEBUG

_usage="
Very simple script to add keywords to media files using exiftool.
Depends on kdialog, mplayer, themed feh and exiftool.
Usage: $ media_tag.sh [-d /initial/directory]
"

# Helper programs
#
_dialog="$(command -v kdialog)" || { echo "Can't find kdialog, aborting." && exit 1; }
_tool="$(command -v exiftool)" || { echo "Can't find exiftool, aborting." && exit 1; }

# Default initial folder
#
_init_dir="/media/DATOS/buceo"
_title="Media files tagging"

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
	_file="$("$_dialog" --title "$_title" --getopenfilename "$_init_dir" "*")"
	# can't get $? but _file is unset if cancel pressed
	if [ -n "$_file" ]; then
		# use different player for images or videos
		_suffix="$(basename "$_file")"; _suffix=${_suffix##*\.}
		case $_suffix in
			jpg|JPG|png|PNG) _player=( "$(which feh)" "-Tinfo_border" )
					 ;;
			mp4|MP4|mov|MOV) _player=( "$(which mplayer)" "-ni" "-nocache" )
					 ;;
		esac
		# visualize the archive
		[[ -f $_file ]] && "${_player[@]}" "$_file"

		if "$_dialog" --title "$_title" --yesno "Do you want to tag the media archive ?"; then
			# get the keywords from the dialog
			_tags="$("$_dialog" --title "$_title" --inputbox "Type the words you want the archive to be tagged")"
			if [ -n "$_tags" ]; then
				# run exiftool and get the output
				_output="$("$_tool" -keywords="\"$_tags\"" "$_file")"
				_output="$_output\\n$(rm -vf "${_file}_original")"
				# show the output in a dialog box
				"$_dialog" --title "$_title" --msgbox "Exiftool output:\\n$_output"
			else
				# if cancel pressed offer to quit the script
				"$_dialog" --title "$_title" --cancel-label "Salir" --warningcontinuecancel "Cancelled\\nDo you want to continue tagging?"
				[[ $? == 2 ]] && exit 0
			fi
		else
			# if cancel pressed offer to quit the script
			"$_dialog" --title "$_title" --cancel-label "Salir" --warningcontinuecancel "Cancelled\\nDo you want to continue tagging?"
			[[ $? == 1 ]] && exit 0
		fi
	else
		# if cancel pressed offer to quit the script
		"$_dialog" --title "$_title" --cancel-label "Salir" --warningcontinuecancel "Cancelled\\nDo you want to continue tagging?"
		[[ $? == 1 ]] && exit 0
	fi
	# reuse current dir for next iteration or default to parent
	_init_dir="$(dirname "${_file:-$_init_dir}")"
	# clean vars for next run
	unset _tags _file _output
done
