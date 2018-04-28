#!/bin/bash

# globl variables
#
_SRCDIR="$1"
_tempfile="/tmp/$(basename $0)_$$"
_mail="salvador.cunat@gmail.com"
declare _repo
declare _blob

# create a log file of the run to send via mail
#
exec 1> >(tee "$_tempfile") 2>&1

# Blacklisted directories
#
_exclude="subsurface-android subsurface-companion subsurface_gtk subsurface_QT subsurface-web"

# Colors for fancy output
#
BLUE="\033[0;34m"
LIGHT_RED="\033[1;31m"
GREEN="\033[0;32m"
WHITE="\033[1;37m"
DEFAULT="\033[0m"

# For debuging
#trap 'set +x; /bin/sleep 0.25; set -x' DEBUG

# remove tempfile on good exit
trap 'rm -f $_tempfile' 0

# Abort utility
#
aborting()
{
	echo -e "-- ${WHITE}${1}${DEFAULT} --> ${LIGHT_RED}${2}. Aborting.${DEFAULT}"
	exit 1
}

# Return 0 if a directory is blacklisted. 1 otherwise
#
is_excluded_dir()
{
	for i in $_exclude; do
		[[ "$1" == "$i" ]] && return 0
	done
	return 1
}

# Try to find the correct remote if there are more than
# one (tipically github). Refuse fork, as it uses to be the copy,
# and give preference to any remote different than origin. Get
# origin if there are no others.
preferred_remote()
{
	local exclude="fork"
	local include="origin"
	for i in $1; do
		[[ $i == "$exclude" ]] && continue
		[[ $i != "$include" ]] && echo "$i" && return 0
		tmp="$i"
	done
	echo "$tmp"
}

# Check if the $1 repo has submodules
#
has_submodule()
{
	[[ ! -f "$0"/.gitmodules ]] && return 1
	return 0
}

# Return 0 if repo $1 is updated or there is no remote (just local)
# Put the preferred repo and the brach in $2 and $3 (globally declared)
#
is_updated_dir()
{
	declare -n _branch="${3:-master}"
	local _remotes
	declare -n _remote="${2:-origin}"
	local _branch_sha
	local _remote_sha

	# Get local branch and remote
	_branch="$(git -C "$1" branch |grep '*' |cut -d" " -f2)"
	_remotes=( $(git -C "$1" remote) )
	# If we don't have a remote, return "updated"
	[[ -z $_remotes ]] && return 0
	# try to get the correct remote
	_remote="$(preferred_remote "${_remotes[*]}")"
	git -C "$1" fetch "$_remote" "$_branch" 2>/dev/null
	# Get branch and remote shas
	_branch_sha="$(git -C "$1" describe --tags "$_branch")"; _branch_sha="${_branch_sha##*-g}";
	_remote_sha="$(git -C "$1" describe --tags "$_remote/$_branch")"; _remote_sha="${_remote_sha##*-g}";

	if [[ -n $_remote_sha ]] && [[ -n $_branch_sha ]]; then
		[[ "$_remote_sha" != "$_branch_sha" ]] && return 1
	fi
	return 0
}

# main
#
for _dir in $(ls -F "$_SRCDIR/" |grep "/"); do
	_dir=${_dir%/}
	#echo -e "-- ${GREEN}Trying${DEFAULT} --> ${WHITE}${_dir}${DEFAULT}"
	if is_excluded_dir "$_dir"; then
		echo -e "---- ${WHITE}${_dir}${DEFAULT} --> ${LIGHT_RED}Excluded${DEFAULT}"
		continue
	fi
	if [[ -d "$_SRCDIR/$_dir/.git" ]]; then
		if ! is_updated_dir "$_SRCDIR/$_dir" _repo _blob; then
			echo -e "---- ${WHITE}${_dir}${DEFAULT} --> ${BLUE}Not updated ... Pulling${DEFAULT}"
			git -C "$_SRCDIR/$_dir" pull "$_repo" "$_blob" \
				|| aborting "${0##*/}" "Couldn't update (pull) $_dir"
			if has_submodule "$_SRCDIR/$_dir"; then
				git -C "$_SRCDIR/$_dir" submodule update
			fi
			notify-send -u critical "${0##*/}" "Updated $_dir.\nRepo:\t$_repo\nBranch:\t$_blob\nTest changes in directory"
			echo -e "---- ${WHITE}${_dir}${DEFAULT} ------------------ Finished ------------------"
		else
			echo -e "---- ${WHITE}${_dir}${DEFAULT} --> ${GREEN}Up to date${DEFAULT}"
		fi
	else
		echo -e "---- ${WHITE}${_dir}${DEFAULT} --> ${LIGHT_RED}Not a git repo${DEFAULT}"
	fi
done

mail -s "${0##*/} log $(date +"%F %T")" "$_mail" <"$_tempfile"
