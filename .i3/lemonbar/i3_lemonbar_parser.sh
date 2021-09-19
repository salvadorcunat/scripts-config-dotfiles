#!/bin/bash
#
# Input parser for i3 bar
# 14 ago 2015 - Electro7
# 15 Apr 2018 - Boret:	Added support for action buttons in some blocks.
#			The output of lemonbar has to be piped through
#			i3_lemonbar_output_parser.sh

# config
. $(dirname $0)/i3_lemonbar_config

# Pad an string with white spaces to a selected size.
# Actually pads 2 spaces, one before, another after the string, for each
# unit to pad. This is. padding "string" to 8 will result in "  string  "
# arguments: 1.- string to pad
#            2.- desired size
# output: prints the padded string to stdout
pad_str()
{
      local padded="$1"
      if (( ${#1} < $2 )); then
	      i=0
	      while (( (${#1} + i)  < $2 )); do
		      padded=" $padded "
		      (( i++ ))
	      done
      fi
      printf "%s" "$padded"
}
# initial values for global variables
last_bg="${color_ws_bg_inactive}"

# parser
while read -r line ; do
	case ${line} in
		HEAD*)
			# Connected monitors
			heads="%{F${color_ws_fg_inactive} B${color_ws_bg_inactive} T2}$(pad_str ${icon_heads} 3)%{T2}"
			last_bg_head="${color_ws_bg_inactive}"
			set -- ${line#????}
			while [ $# -gt 0 ] ; do
				_screen=${1%????}
				_status=${1##*_}
				case $_status in
					CON)
						# If consecutive screens are connected, use light separator instead of usual hard one
						if [ "${last_bg_head}" == "${color_ws_bg_active}" ]; then
							full_sep="${heads}%{F${color_back} B${last_bg_head}}${sep_l_right}"
						else
							full_sep="${heads}%{F${color_ws_bg_inactive} B${color_ws_bg_active}}${sep_right}"
						fi
						heads="${full_sep}%{F${color_back} B${color_ws_bg_active} T1}$(pad_str "${_screen}" 7)%{T2}"
						last_bg_head="${color_ws_bg_active}"
						#last_bg="$last_bg_head"
						;;
					DIS)
						heads="${heads}%{F${last_bg_head} B${color_head_dis_bg}}${sep_right}%{F${color_fore} B${color_head_dis_bg} T1}$(pad_str "${_screen}" 7)%{T2}"
						last_bg_head="${color_head_dis_bg}"
						#last_bg="${last_bg_head}"
						;;
				esac
				shift
			done
			# force a workspaces reload
			echo "${ws_line}" >${panel_fifo}
			;;
		WSP*)
			# I3 Workspaces
			wsp="%{F${last_bg_head} B${color_ws_bg_inactive}}${sep_right}%{F${color_ws_fg_inactive} B${color_ws_bg_inactive} T2}$(pad_str ${icon_wsp} 3)%{T2}"
			last_bg="${color_ws_bg_inactive}"
			ws_line=${line}
			set -- ${ws_line#???}
			while [ $# -gt 0 ] ; do
				case $1 in
					FOC*|ACT*)
						# If consecutive workspaces are active, use light separator instead of usual hard one
						if [ "${last_bg}" == "${color_ws_bg_active}" ]; then
							full_sep="${wsp}%{F${color_ws_bg_inactive} B${color_ws_bg_active}}${sep_l_right}"
						else
							full_sep="${wsp}%{F${last_bg} B${color_ws_bg_active}}${sep_right}"
						fi
						wsp="${full_sep}%{F${color_ws_fg_active} B${color_ws_bg_active} T1}%{A:change_ws ${1#???}:}$(pad_str "${1#???}" 3)%{A}%{T2}"
						last_bg_ws="${color_ws_bg_active}"
						last_bg="${last_bg_ws}"
						;;
					INA*)
						# If consecutive workspaces are inactive, use light separator instead of usual hard one
						if [ "${last_bg}" == "${color_ws_bg_inactive}" ]; then
							full_sep="${wsp}%{F${color_ws_bg_active} B${color_ws_bg_inactive}}${sep_l_right}"
						else
							full_sep="${wsp}%{F${last_bg} B${color_ws_bg_inactive}}${sep_right}"
						fi
						wsp="${full_sep}%{F${color_ws_fg_inactive} B${color_ws_bg_inactive} T1}%{A:change_ws ${1#???}:}$(pad_str "${1#???}" 3)%{A}%{T2}"
						last_bg_ws="${color_ws_bg_inactive}"
						last_bg="${last_bg_ws}"
						;;
					URG*)
						wsp="${wsp}%{F${last_bg} B${color_ws_bg_urgent}}${sep_right}%{F${color_ws_fg_inactive} B${color_ws_bg_urgent} T1}%{A:change_ws ${1#???}:}$(pad_str "${1#???}" 3)%{A}%{T2}"
						last_bg_ws="${color_ws_bg_urgent}"
						last_bg="${last_bg_ws}"
						;;
				esac
				shift
			done
			# force a windows reload
			echo "$(xprop -root _NET_ACTIVE_WINDOW | sed -un 's/.*\(0x.*\)/WIN\1/p')" >"${panel_fifo}"
			;;
		WIN*)
			# window title
			title=$(xprop -id ${line#???} | awk '/_NET_WM_NAME/{$1=$2="";print}' | cut -d'"' -f2)
			if [[ -n ${title} ]]; then
				title="%{F${last_bg} B${color_sec_b2} T2}${sep_right}%{F${color_head}}$(pad_str "${icon_prog}" 3) %{F${color_sec_b2} B-}${sep_right}%{B- F${color_fore} T1} ${title} %{T2}${sep_l_right}"
			else
				title="%{F${last_bg} B- T2}${sep_right}"
			fi
			;;
		DSK*)
			# Hard drives
			bg_col=${line##*\ }
			fg_col="${color_fore}"
			disk=${line#????}; disk=${disk%%\ *}
			free=${line%\ *}; free=${free##*\ }
			case ${disk} in
				"/")
					bg_col="${bg_col/-/\#21746b}"
					dsk1="%{F${bg_col} T2}${sep_left}%{F${fg_col} B${bg_col} T2}$(pad_str "${icon_hd} ${free}" 8)"
					;;
				"/home")
					bg_col="${bg_col/-/\#1f4d52}"
					dsk2="%{F${bg_col}}${sep_left}%{F${fg_col} B${bg_col} T2}$(pad_str "${icon_home} ${free}" 8)"
					;;
				*DATOS*)
					bg_col="${bg_col/-/\#1f3952}"
					dsk3="%{F${bg_col}}${sep_left}%{F${fg_col} B${bg_col} T2}$(pad_str "${icon_datos} ${free}" 8)"
					;;
			esac
			;;
		REM*)
			# Removable media
			bg_col=${color_back}
			fg_col=${line##*\ }
			rmedia=${line%$fg_col}; rmedia=${rmedia#????}
			rmedia="%{F${bg_col}}${sep_left}%{F${fg_col} B${bg_col} T2}%{A:umount_${rmedia}:}${rmedia}%{A}"
			;;
		IFC*)
			# Wifi interface - internal IP
			bg_col="#2b445a"
			fg_col=${color_fore}
			ifc=${line#???}
			ifc="%{F${bg_col}}${sep_left}%{F${fg_col} B${bg_col}}%{A:iface:}$(pad_str "${ifc}" 15)%{A}"
			;;
		WAP*)
			# Wifi Access Point
			bg_col=${line##*\ }
			fg_col="${color_white}"
			wifi_ap=${line#???}; wifi_ap=${wifi_ap%\ *}
			wifi="%{F${bg_col}}${sep_left}%{F${fg_col} B${bg_col} T2}%{A:wifi_ap:}$(pad_str "${icon_wap}" 3)%{T1}$(pad_str "${wifi_ap}" 16) %{A}"
			;;
		BDW*)
			# Bandwidth up/down
			bg_col="#2b445a"
			fg_col=${color_fore}
			bdw=${line#???}
			[[ ${bdw} != "down" ]] && bdw=$(pad_str "${bdw}" 14)
			bdw="%{F${bg_col} T2}${sep_left}%{F${fg_col} B${bg_col} T3}%{A:bdwidth:}${bdw}%{A}"
			;;
		BLT*)
			# Bluetooth
			bg_col=${line##*\ }
			fg_col="${color_white}"
			blt_ap=${line#???}; blt_ap=${blt_ap%\ *}; [ "$blt_ap" != "" ] && blt_ap=$(pad_str "${blt_ap}" 2)
			bluetooth="%{F${bg_col} T2}${sep_left}%{F${fg_col} B${bg_col} T2}%{A1:blt_man:}%{A3:blt_term:}$(pad_str "${icon_blt}" 3)%{T1}"${blt_ap}"%{A}%{A}"
			;;
		CPU*)
			# Cpu load.
			bg_col="#2b445a"
			set -- ${line#???}
			cpu="%{F$2 B${bg_col} T2}${sep_left}%{F$3 B$2 T2}%{A:cpu_load:}  ${icon_cpu}%{T1}$(pad_str "$1" 9)%{A}"
			;;
		BAT*)
			# Battery status
			set -- ${line#???}
			if [ "$1" != "100%" ]; then
				bat="%{F$4 T2}${sep_left}%{F${color_fore} B$4 T3}$(pad_str "$1 $2 $3" 14)"
			else
				bat="%{F$3 T2}${sep_left}%{F${color_back} B$3 T3}$(pad_str "$1 $2" 7)"
			fi
			;;
		AUD*)
			# Audio volume
			_vol=${line#???}
			_vol="%{F${color_bg_vol} T2}${sep_left}%{F${color_fg_vol} B${color_bg_vol} T3}\
				%{A3:vol_mute:}\
				%{A1:vol_mixer:}\
				%{A4:vol_up:}\
				%{A5:vol_down:}\
				$(pad_str "♪ ${_vol}" 8)%{A}%{A}%{A}%{A}"
			;;
		CAP*)
			# CAPS lock status
			set -- ${line}
			fg_col="${color_black}"
			caps="%{F$2 T2}${sep_left}%{F${fg_col} B$2 T1} $1"
			;;
		NUM*)
			# NUM lock status
			set -- ${line}
			fg_col="${color_black}"
			numl="%{F$2 T2}${sep_left}%{F${fg_col} B$2 T1} $1 "
			;;
		WARN*)
			# Warning block. The warning line should be formated:
			# WARN_action_arguments, where "action" is the next action to catch with
			# output parser and "args" the action arguments. E.g. WARN_detach_sdb1
			# right click cancels warning
			# left click confirms action
			_args="${line##*_}"
			_cmd="${line#?????}"; _cmd=${_cmd%_${_args}}
			if [ -n "$_args" ]; then
				warning="%{F${color_warn} B- T2}${sep_left}%{F${color_white} B${color_warn} T2}%{A1:${_cmd}_${_args}:}%{A3:warn_cancel:} ${_cmd} ${_args} %{A}%{A}%{F${color_warn} B- T2}${sep_right}"
			else
				unset warning
			fi
			;;
	esac

	# Set date/time format out of the case construct to catch the
	# initial value
	_date_time="%{F${color_back} T2}${sep_left}%{B${color_back} F${color_fore} T1}$(pad_str "$(date +"%a %d-%b %R")" 18)"
	# And finally, output
	printf "%s\\n" "%{l}%{B-}   ${heads}${wsp}${title} %{r}${warning} ${bluetooth} ${dsk1}${dsk2}${dsk3} ${rmedia} ${ifc} ${wifi} ${bdw} ${cpu} ${bat} ${_vol} ${_date_time} ${caps} ${numl} %{B-}  "
done
