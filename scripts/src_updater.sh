#!/bin/bash

# globl variables
#
_SRCDIR="$1"
_tempfile="/tmp/$(basename $0)_$$"
_mail="salvador.cunat@gmail.com"
_log="true"
declare _repo
declare _blob

# create a log file of the run to send via mail
#
exec 1> >(tee "$_tempfile") 2>&1

# source funcs file
#
. "$HOME"/sbin/script-funcs.sh

# For debuging

# Colors for fancy output
#
BLUE="\033[0;34m"
LIGHT_RED="\033[1;31m"
GREEN="\033[0;32m"
WHITE="\033[1;37m"
DEFAULT="\033[0m"

# remove tempfile on good exit
trap 'rm -f $_tempfile' 0

# Report and logging utility
#
report_msg()
{
	echo -e "$1" "$2"
	if [ "$_log" == "true" ]; then
		logger --id="$$" -t "$USER-$1" -- "$(sed -e 's/.033..\;3.m//g' -e 's/.033..m//g' <<< "$2")"
	fi
}

# Abort utility
#
aborting()
{
	report_msg "$1" "$2. Aborted"
	[[ -n $DISPLAY ]] && notify-send -u critical "$1" "${2#*\ }.\nAborted."
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
# Return codes:	0	Updated
#		1	Needs to be updated
#		2	git describe failed
#		3	git fetch failed
#		4	no remote (this is the main repo)
#
is_updated_dir()
{
	declare -n _branch="${3:-master}"
	local _remotes
	declare -n _remote="${2:-origin}"
	local _branch_sha
	local _remote_sha
	local -n _current_br="${4}"

	# Try to be smart about tracking branches
	_tr_branch="$(git -C "$1" branch -r |grep -- '->' |sed s/^.*\ \-\>\ .*\\///)"

	# Get local branch and remote
	_branch="$(git -C "$1" branch |grep '*' |cut -d" " -f2)"
	if [[ $_branch != "$_tr_branch" ]]; then
		case "$_branch" in
			"(HEAD")	_current_br="$(cut -f1 <"$1"/.git/FETCH_HEAD)"
					;;
			*)		_current_br="${_branch:-master}"
					;;
		esac
		_branch="${_tr_branch:-master}"
	fi

	_remotes=( $(git -C "$1" remote) )
	# If we don't have a remote, return "updated"
	[[ -z $_remotes ]] && return 4
	# try to get the correct remote
	_remote="$(preferred_remote "${_remotes[*]}")"
	git -C "$1" fetch "$_remote" "$_branch" 2>/dev/null || return 3
	# Get branch and remote shas
	if [[ -f "$1"/.git/refs/heads/"$_branch" ]]; then
		_branch_sha="$(cat "$1"/.git/refs/heads/"$_branch")"
	else
		_branch_sha="$(cat "$1"/.git/"$(cut -d" " -f2 <"$1"/.git/HEAD)")"
	fi
	if [[ -f "$1"/.git/refs/remotes/origin/"$_branch" ]]; then
		_remote_sha="$(cat "$1"/.git/refs/remotes/origin/"$_branch")"
	else
		_remote_sha="$(cut -f1 <"$1"/.git/FETCH_HEAD)"
	fi

	if [[ -n $_remote_sha ]] && [[ -n $_branch_sha ]]; then
		[[ "$_remote_sha" != "$_branch_sha" ]]  && return 1
	else
		return 2
	fi
	return 0
}

# Check internet connectivity. Abort if none, as we can't update anything.
#
check_connect
case $? in
	1)	aborting "${0##*/}" "-- No default route. Check your network settings" ;;
	2)	aborting "${0##*/}" "-- Local route but no internet access. Check your network settings" ;;
esac

# Blacklisted directories
#
declare -a _LINES
_blacklist=."$(basename $0)"; _blacklist="${_blacklist%???}_blacklist"
read_lines "${0%/*}/$_blacklist" _LINES
_exclude="${_LINES[*]}"
unset _LINES _blacklist

# main
#
for _dir in $(ls -F "$_SRCDIR/" |grep "/"); do
	_dir=${_dir%/}
	#echo -e "-- ${GREEN}Trying${DEFAULT} --> ${WHITE}${_dir}${DEFAULT}"
	if is_excluded_dir "$_dir"; then
		report_msg "${0##*/}" "---- ${WHITE}${_dir}${DEFAULT} --> ${LIGHT_RED}Excluded${DEFAULT}"
		continue
	fi
	if [[ -d "$_SRCDIR/$_dir/.git" ]]; then
		is_updated_dir "$_SRCDIR/$_dir" _repo _tr_blob _curr_blob
		case "$?" in
			0)	report_msg "${0##*/}" "---- ${WHITE}${_dir}${DEFAULT} --> ${GREEN}Up to date${DEFAULT}"
				;;
			1)	report_msg "${0##*/}" "---- ${WHITE}${_dir}${DEFAULT} --> ${BLUE}Not updated ... Pulling${DEFAULT}"
				# not in traking branch? stash changes if any, move to it, pull and restore branch
				if [[ "$_tr_blob" != "$_curr_blob" ]]; then
					git -C "$_SRCDIR/$_dir" stash && _stashed=1
					git -C "$_SRCDIR/$_dir" checkout "$_tr_blob"
				fi
				git -C "$_SRCDIR/$_dir" pull "$_repo" master \
					|| aborting "${0##*/}" "Couldn't update (pull) $_dir"
				if has_submodule "$_SRCDIR/$_dir"; then
					git -C "$_SRCDIR/$_dir" submodule update
				fi
				# restore directory's previous state
				(( _stashed == 1 )) && git -C "$_SRCDIR/$_dir" stash pop && unset _stashed
				[[ "$_tr_blob" != "$_curr_blob" ]] && git -C "$_SRCDIR/$_dir" checkout "$_curr_blob"

				[[ -n $DISPLAY ]] && notify-send -u critical "${0##*/}" "Updated $_dir.\nRepo:\t$_repo\nBranch:\t$_blob\nTest changes in directory"
				echo -e "---- ${WHITE}${_dir}${DEFAULT} ------------------ Finished ------------------"
				;;
			2)	report_msg "${0##*/}" "---- ${WHITE}${_dir}${DEFAULT} --> ${LIGHT_RED}Problem with git HEADs, try manually.${DEFAULT}"
				;;
			3)	report_msg "${0##*/}" "---- ${WHITE}${_dir}${DEFAULT} --> ${LIGHT_RED}Git fetch failed, check connection or remote.${DEFAULT}"
				;;
			4)	report_msg "${0##*/}" "---- ${WHITE}${_dir}${DEFAULT} --> ${LIGHT_RED}No remotes. Is this a main repo?${DEFAULT}"
				;;
		esac
	else
		report_msg "${0##*/}" "---- ${WHITE}${_dir}${DEFAULT} --> ${LIGHT_RED}Not a git repo${DEFAULT}"
	fi
done
# Remove color sequences from _tempfile before mailing it
sed -i '{s/\x1b..\;3.m//g ; s/\x1b..m//g}' "$_tempfile"
mail -s "${0##*/} log $(date +"%F %T")" "$_mail" <"$_tempfile"
