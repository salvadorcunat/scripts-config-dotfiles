#!/bin/bash

# Check if there is running already running a bar. kill it and run it again
#
prev=( $(pgrep -x "i3_lemonbar.sh") )

if [[ ${#prev[@]} -gt 0 ]]; then
	echo "The status bar is already running. Killing it." >&2
	kill "${prev[@]}"
fi

"$(dirname "$0")"/i3_lemonbar.sh | \
	"$(dirname "$0")"/i3_lemonbar_output_parser.sh 2>/dev/null &
