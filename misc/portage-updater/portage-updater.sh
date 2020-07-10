#/bin/bash
# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

################################################
# Last modify: Yury Martynov (email@Linxon.ru)
# at Tue 07 Jul 2020 04:36:31 PM MSK
################################################

# set -eo pipefail
export LC_ALL=C.UTF-8

EMERGE_CMD_ARGS+=(
	--color=y
	--verbose=y
	--nospinner
	--keep-going=y
	--fail-clean=n
	#--autounmask=y
	#--autounmask-continue=y
	#--autounmask-write=y
)

CLEANUP=1

LOGGER_ENABLED=1
LOGGER_FILE_PATH="/var/log/$(basename ${0%.sh})-$(date '+%Y-%m-%d').log"

################################################
################################################

_EMERGE_CMD="/usr/bin/emerge ${EMERGE_CMD_ARGS[*]} 2>&1"
_EMAINT_CMD="/usr/sbin/emaint 2>&1"

_EXIT_STATUS=0
_EXIT_STATUS_NEWS_AVAIL=10
_EXIT_STATUS_UPDATE_FAILS=20
_EXIT_STATUS_PRE_UPDATE_FAILS=21
_EXIT_STATUS_POST_UPDATE_FAILS=22
_EXIT_STATUS_CLEANUP_FAILS=30

is_stat() {
	(( $1 == $_EXIT_STATUS )) || return 1
}

backup_config() {
	echo ">>> ${FUNCNAME[0]}: create a backup (/etc/portage) ..."
	:
}

sync_repos() {
	eval $_EMAINT_CMD sync -A || return 1

	if [ -x /usr/bin/eix-diff ]; then
		_EIX_IS_AVAIL=1
		/usr/bin/eix-update --quiet && \
		/usr/bin/eix-diff --force-color 2>&1 # || return 1
	fi

	if eselect --brief news list | grep ^N > /dev/null 2>&1; then
		_EXIT_STATUS=$_EXIT_STATUS_NEWS_AVAIL
		return 1
	fi
}

save_metadata() {
	:
}

cleanup() {
	[ -z $CLEANUP ] && return

	echo ">>> ${FUNCNAME[0]}: remove old distfiles/binpkgs and packages ..."

	eval CLEAN_DELAY=0 $_EMERGE_CMD --verbose=n --depclean

	if (( $? > 0 )); then
		_EXIT_STATUS=$_EXIT_STATUS_CLEANUP_FAILS
		return 1
	fi

	if [ -x /usr/bin/eclean ]; then
		/usr/bin/eclean-dist -d 2>&1
		/usr/bin/eclean-pkg -nd 2>&1
	fi
}

pre_update() {
	backup_config || return 1

	echo ">>> ${FUNCNAME[0]}: install new version of portage and fix moveinst/movebin before updating ..."

	/usr/sbin/fixpackages || return 1

	eval $_EMERGE_CMD --oneshot --noreplace --update sys-apps/portage && \
	eval $_EMAINT_CMD moveinst -f && \
	eval $_EMAINT_CMD movebin -f

	if (( $? > 0 )); then
		_EXIT_STATUS=$_EXIT_STATUS_PRE_UPDATE_FAILS
		return 1
	fi
}

post_update() {
	cleanup

	echo ">>> ${FUNCNAME[0]}: rebuild modules and preserved packages ..."

	eval $_EMERGE_CMD --nodeps @preserved-rebuild @module-rebuild && \
	/usr/bin/revdep-rebuild --ignore

	if (( $? > 0 )); then
		_EXIT_STATUS=$_EXIT_STATUS_POST_UPDATE_FAILS
		return 1
	fi
}

update_pkgs() {
	local max_prbcnt=3

	pre_update || return 1

	echo ">>> ${FUNCNAME[0]}: update packages ..."

	for i in $(seq 1 $max_prbcnt); do
		echo ">>> ${FUNCNAME[0]}: emerge attempt $i (of $max_prbcnt)"

		eval $_EMERGE_CMD --changed-use --changed-deps --deep --update @world

		if (( $? > 0 )); then
			/usr/sbin/etc-update --verbose --automode -5 2>&1
		else
			break
		fi
	done

	(( $? == 0 )) && post_update
}

ebegin() {
	_LOGGER_TMP_MSG="${*}"
	echo ">>> $_LOGGER_TMP_MSG ..."
}

eend() {
	local err_message="$2"
	local exit_code=$1

	if (( $exit_code > 0 )); then
		[ -n "$err_message" ] && echo ">>> $_LOGGER_TMP_MSG / $err_message"
	else
		echo ">>> $_LOGGER_TMP_MSG / Done!"
	fi

	_LOGGER_TMP_MSG=

	return $exit_code
}

elog() {
	printf "[%s] %s\n" "$(date '+%H:%M:%S')" "${*}"
}

send_alert() {
	# use dbus messages
	:
}

logger() {
	(( ${#} == 0 )) || return 1

	set -- "${@}"

	while read -r log; do
		if [ -n "$LOGGER_ENABLED" ]; then
			elog "$log" >> "$LOGGER_FILE_PATH"
		else
			elog "$log"
		fi
	done
}

################################################
################################################

{
	printf "=== Starting autoupdater ===\n"
	printf " *\n"
	printf " * Warning! This is a very dangerous thing to do and will break your system at some point!\n"
	printf " *\n"

	ebegin "Sync repos"
	sync_repos
	eend $? $(
		if is_stat $_EXIT_STATUS_NEWS_AVAIL; then
			echo "Skip"
		else
			echo "Error while synchronize repos!"
		fi
	)

	if (( $? == 0 )); then
		ebegin "Update packages"
		update_pkgs
		eend $? "Error while updating packages!"
	fi

	case $_EXIT_STATUS in
		$_EXIT_STATUS_NEWS_AVAIL)
			echo " * Please read news before updating! Abort";;
		$_EXIT_STATUS_UPDATE_FAILS)
			echo " * Update fails. Abort";;
		$_EXIT_STATUS_PRE_UPDATE_FAILS)
			echo " * Pre update fails. Abort";;
		$_EXIT_STATUS_POST_UPDATE_FAILS)
			echo " * Post update fails. Abort";;
	esac

	printf "=== Update completed! Exit status: %s ===\n" $_EXIT_STATUS
} | logger

exit $?
