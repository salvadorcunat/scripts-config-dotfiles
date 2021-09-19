#!/bin/bash

_usage="
This is a dangerous script.
It's meant to remove duplicated files in a directory tree. Targeted mainly at
cleaning Rosa's mobile backups.
Use with care about the directory you want to clean.

$ undupl /target/dir

The target directory is mandatory
Directories to skip can be avoided with -s param which can also be used to
skip file-names. E.g.

$ undupl.sh /target/dir -s 'skipped_dir' [-s ...]

You can choose to keep files under a directory instead of another using the
-p|--prefer option. E.g.

$ undupl.sh /target/dir -p 'preferred_dir' [-p ...]

The script uses mlocate package (locate & updatedb commands) and sources the
script-funcs.sh file.

"
# For debuging
#_sleep="$(command -v sleep)"
#trap 'set +x; $_sleep 0.05; set -x' DEBUG

DIALOG_OK=0					#
DIALOG_CANCEL=1					#
DIALOG_HELP=2					# Possible dialog return values
DIALOG_EXTRA=3					# for $?
DIALOG_ITEM_HELP=4				#
DIALOG_ESC=255					#

SIG_NONE=0					#
SIG_HUP=1					#
SIG_INT=2					# System signals for trap
SIG_QUIT=3					#
SIG_TERM=15					#

declare _max_files
declare -a _blacklisted
_tempfile="/tmp/test_$$"
_DB="/tmp/undupl_db_$$"

trap 'rm -f $_tempfile $_DB' "$SIG_NONE" "$SIG_HUP" "$SIG_INT" "$SIG_QUIT" "$SIG_TERM"

# Source functions library
. "$HOME"/sbin/script-funcs.sh

# Remove unset values in an array, reducing its size
shrink_array()
{
	[ -z "$1" ] && return 1
	declare -n _sparse=${1}
	declare -a _array
	_array=( "${_sparse[@]}" )
	unset _sparse
	_sparse=( "${_array[@]}" )
	unset _array
}

# 1-	Directory to search
# 2-	array of blacklisted dirs and files to skip
# 3-	global array to store list of files to check
read_files()
{
	declare -n _skip=${2:-_blacklisted}
	declare -n _list=${3:-_files}
	IFS=$'\n'

	# return failure if we don have three args
	[[ $# -ne 3 ]] && return 1

	printf "scanning files ..."
	_list=( $(find "$1" -type f |sort) )
	# bash array will reduce its size while cleaned, but the elements
	# keep their original position. We need to know the original number of elements.
	_max_files="${#_list[@]}"
	# clean blcklisted
	i=0
	while (( i < _max_files )); do
		j=0
		while (( j < ${#_skip[@]} )); do
			[[ ${_list[$i]} == *${_skip[$j]}* ]] && unset "_list[$i]" && break
			(( j++ ))
		done
		(( i++ ))
		printf "."
	done
	echo "."
	echo "Processing ${#_list[@]} files of $_max_files total files ..."
	# We have an sparse array, remove unset elements
	shrink_array _list || return 1
	_max_files="${#_list[@]}"
}

is_preferred()
{
	local _dir="$(dirname "$1")"
	local i=0
	while [ "$i" -lt "${#_preferred[@]}" ]; do
		[[ $_dir ==  *${_preferred[$i]}* ]] && return 0
		(( i++ ))
	done
	return 1
}

# Main body
while [ $# != 0 ]; do
	case "$1" in
		-s|--skip)	_blacklisted[${#_blacklisted[@]}]="$2"
				shift 2
				;;
		-p|--prefer)	_preferred[${#_preferred[@]}]="$2"
				shift 2
				;;
		-h|--help)	echo "$_usage"
				exit 1
				;;
		*)		_dir="$1"
				shift
				;;
	esac
done

# security checks
[[ "$(whoami)" == "root" ]] && echo "Do not run as root" && exit 1
[[ -z $_dir ]] && echo "$_usage" && exit 1

read_files "$_dir" _blacklisted _files || exit 1

report_msg "${0##*\/}" "Creating database for mlocate"
updatedb -l 0 -U "$_dir" -o "$_DB" --prunenames "${_blacklisted[*]}" && \
	report_msg "${0##*\/}" "Database $_DB created" || \
	{ report_msg "${0##*\/}" "Updatedb failed"; exit 1; }

i=0; k=0
while (( i < _max_files )); do
	if [ -n "${_files[$i]}" ]; then
		_testing="${_files[$i]}"
		_testname="$(basename "$_testing")"
		report_msg "( $(( i+1 ))/$_max_files )" "testing $_testing"
		IFS=$'\n'
		test_array=( $(locate -b -d "$_DB" "$_testname") )
			l=1
			while (( l < ${#test_array[@]} )); do
				if [ ! "$_testing" == "${test_array[$l]}" ] && diff --brief "$_testing" "${test_array[$l]}" >/dev/null 2>&1; then
					if ! is_preferred "${test_array[$l]}"; then
						report_msg "${0##*\/}" "$(rm -vf "${test_array[$l]}") --> was the same than --> $_testing"
					else
						report_msg "${0##*\/}" "${test_array[$l]} is preferred."
						report_msg "${0##*\/}" "$(rm -vf "$_testing")"
					fi

					(( k++ ))
					updatedb -l 0 -U "$_dir" -o "$_DB" --prunenames "${_blacklisted[*]}"
				fi
				(( l++  ))
			done
		unset test_array
	fi
	(( i++ ))
done

echo "--------------  end  --------------"
echo "$k files could be safely removed. Bye"
