#!/bin/bash

black_col="#000000"
bg_color="#FF0000"
fg_color="#ffffff"
bg_yes="#49dde7"
bg_no="#FF1D1F21"

# get monitor resolution
_res=( $(xrandr | grep "current" | awk '{print $8a " " $10a}' |sed s/,//) )

_scr_offset=$(echo "${_res[1]} / 2" |bc)
echo "-$_scr_offset-"

# set lemonbar line
_line="%{c} %{F$bg_color T2}%{B$bg_color F$fg_color T1} Do you want to unmount the device? %{A:yes:}%{B$bg_yes F$black_col T1} Yes %{A}%{A:no:}%{B$bg_no F$fg_color T1} No %{A}%{B- F$bg_color T2}"

echo "$_line" | lemonbar -b -p -f "URW Gothic-10" -f "FontAwesome-10"
