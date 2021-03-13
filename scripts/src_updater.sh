#!/bin/bash
#
_usage="
###                                                                        ###
# Update git repos in directoris passed as CLI parameters.                   #
# Options:	-v|--verbose	show messages if running on terminal         #
#		-m|--mail	send a log file to an e-mail                 #
#		-l|--log	records messages to syslog                   #
#		-h|--help	show this help                               #
#		-b|--build	call after-update.sh script (if any)         #
# examples:                                                                  #
#	src_updater.sh -v ~/src ~/.vim/bundle                                #
#	update git repos in ~/src and ~/.vim/bundle dirs, while outputting   #
#	to stdout if run from command line.                                  #
###                                                                        ###
"
# globl variables
#
_tempfile="/tmp/$(basename $0)_$$"
_MAIL="false"
_VERBOSE="false"
_mail="salvador.cunat@gmail.com"
_log="false"
declare _repo
declare _blob

# create a log file of the run to send via mail
#
exec 1> >(tee "$_tempfile") 2>&1

# source funcs file
#
. "$HOME"/sbin/script-funcs.sh

# For debuging
#_sleep="$(which sleep)"		#/bin/sleep
#trap 'set +x; $_sleep 0.25; set -x' DEBUG

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
	# Send messages to stdout if set and running from CLI
	# [ -t 1 ] checks if stdout is attached to a terminal
	if [[ "$_VERBOSE" == "true" && -t 0 ]]; then
		echo -e "$1" "$2"
	fi
	# Log messages to syslog if not running from CLI or manually set
	if [[ "$_log" == "true" || ! -t 0 ]]; then
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
	[[ ! -f "$1"/.gitmodules ]] && return 1
	return 0
}

# Re-build a source directory. But only if we have a local script named
# after-update.sh
# Return:	0 - If built and correct
#		1 - No after-update.sh --> Do not build
#		2 - Couldn't cd into repo dir
#		3 - Build failed
#		4 - Couldn't get back to original directory
#
re-build()
{
	local _orig_dir="$(pwd)"
	[[ ! -x "$1/after-update.sh" ]] && \
		return 1
	cd "$1" || \
		return 2
	report_msg "Building" " ---- $WHITE${1##*/}$DEFAULT"
	./after-update.sh
	local rc="$?"
	cd "$_orig_dir" || \
		return 4
	[[ $rc -ne 0 ]] && return 3
	return "$rc"
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
	declare -n _current_br="${4}"

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
	else
		_current_br="$_branch"
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

# Check CLI parameters
#
while [ "$#" -gt 0 ]; do
	case "$1" in
		-m|--mail)	_MAIL="true"
				shift ;;
		-v|--verbose)	_VERBOSE="true"
				shift ;;
		-l|--log)	_log="true"
				shift;;
		-b|--build)	_build="true"
				shift;;
		-h|--help)	echo "$_usage" && exit 0
				;;
		*)		break ;;
	esac
done

# Check internet connectivity. Abort if none, as we can't update anything.
#
i=0; RC=1
while [[ $RC -ne 0 && $i -lt 20 ]]; do
	sleep 0.5
	(( i++ ))
	check_connect
	RC=$?
done
case $RC in
	1)	aborting "${0##*/}" "-- No default route. Check your network settings" ;;
	2)	aborting "${0##*/}" "-- Local route but no internet access. Check your network settings" ;;
esac

#Blacklisted directories
#
declare -a _LINES
_blacklist=."$(basename $0)"; _blacklist="${_blacklist%???}_blacklist"
read_lines "${0%/*}/$_blacklist" _LINES
_exclude="${_LINES[*]}"
unset _LINES _blacklist

# Assume any other param is a directory to update
#
while [ $# -gt 0 ]; do

	_SRCDIR="$1"

	# main
	#
	for _dir in $(ls -F "$_SRCDIR/" |grep "/"); do
		_dir=${_dir%/}
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
						git -C "$_SRCDIR/$_dir" status -s -uno |grep -q ' M '
						if (( $? == 0 ))	; then
							git -C "$_SRCDIR/$_dir" stash && _stashed=1
						fi
						git -C "$_SRCDIR/$_dir" checkout "$_tr_blob"
					fi
					if ! git -C "$_SRCDIR/$_dir" pull "$_repo" "$_tr_blob" ; then
						report_msg "${0##*/}" "--------- ${WHITE}${_dir}${DEFAULT} --> ${LIGHT_RED}Pull failed. Check it out${DEFAULT}"
						continue
					fi
					if has_submodule "$_SRCDIR/$_dir"; then
						git -C "$_SRCDIR/$_dir" pull --recurse-submodules=yes
						git -C "$_SRCDIR/$_dir" submodule update
					fi
					(
						re-build "$_SRCDIR/$_dir"
						case $? in
							0)	report_msg "${GREEN}Building done$DEFAULT" ;;
							2)	report_msg "Couldn't cd into $_SRCDIR/$dir" "${LIGHT_RED}Not Built$DEFAULT";;
							3)	report_msg "Build failed" "${LIGHT_RED} Check output$DEFAULT" ;;
							4)	report_msg "${LIGHT_RED}Couldn't get back to prevous directory. Be careful.${DEFAULT}";;
						esac
						# restore directory's previous state
						[[ "$_tr_blob" != "$_curr_blob" ]] && git -C "$_SRCDIR/$_dir" checkout "$_curr_blob"
						(( _stashed == 1 )) && git -C "$_SRCDIR/$_dir" stash pop

						[[ -n $DISPLAY ]] && notify-send -u critical "${0##*/}" "Updated $_dir.\nRepo:\t$_repo\nBranch:\t$_blob\nTest changes in directory"
						echo -e "---- ${WHITE}${_dir}${DEFAULT} ------------------ Finished ------------------"
					)
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
		unset _repo _tr_blob _curr_blob _stashed
	done
	shift
done
# Remove color sequences from _tempfile before mailing it
sed -i '{s/\x1b..\;3.m//g ; s/\x1b..m//g}' "$_tempfile"
[[ $_MAIL = "true" ]] && mail -s "${0##*/} log $(date +"%F %T")" "$_mail" <"$_tempfile"
exit 0
