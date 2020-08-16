#/bin/bash
# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

################################################
# Last modify: Yury Martynov (email@Linxon.ru)
# at Tue 07 Jul 2020 04:36:31 PM MSK
################################################

# set -eo pipefail
export LC_ALL=C.UTF-8
export EMERGE_DEFAULT_OPTS+=(
	--ask=n
	--color=y
	--verbose=y
	--nospinner
	--keep-going=y
	--fail-clean=n
	--verbose-conflicts
	#--autounmask=y
	#--autounmask-continue=y
	#--autounmask-write=y
)

################################################
################################################

_BNAME="$(basename ${0%.sh})"
_CURR_DATE_STR="$(date '+%Y-%m-%d')"

_EMERGE_CMD="/usr/bin/emerge 2>&1"
_EMAINT_CMD="/usr/sbin/emaint 2>&1"

_CL_BBLK='\033[40m'
_CL_FBLK='\033[30m'
_CL_FWHT='\033[37m'
_CL_FRED='\033[31m'
_CL_FGRN='\033[32m'
_CL_FYEL='\033[33m'
_CL_RS='\033[0m'

_EM_MAX_ATTEMPTS=5
_QUIET=0
_LOGGER_ENABLED=0
_LOGGER_FILE_PATH="/var/log/${_BNAME}-${_CURR_DATE_STR}.log"
_IGNORE_CHECKING_NEWS=0
_CLEANUP=0
_BACKUP=0
_BACKUP_FILE="/var/lib/${_BNAME}/portage-configs-${_CURR_DATE_STR}.tar.xz"
# _BACKUP_TARGETS=( "/etc/portage" "/etc/make.conf" "/etc/conf.d" )
_DIR_OF_PATCHES="/etc/${_BNAME}/patches"
_LAST_ETC_UPD_OUTPUT_DIFF="/var/lib/${_BNAME}/etc-update-${_CURR_DATE_STR}.patch"

_EXIT_STATUS=0
_EXIT_STATUS_SYNC_ERR=10
_EXIT_STATUS_NEWS_AVAIL=20
_EXIT_STATUS_UPDATE_FAILS=30
_EXIT_STATUS_PRE_UPDATE_FAILS=31
_EXIT_STATUS_POST_UPD_CLEANUP_FAILS=32
_EXIT_STATUS_POST_UPD_REBUILD_FAILS=33
_EXIT_STATUS_BACKUP_CREATE_ERR=40
_EXIT_STATUS_BACKUP_RESTORE_ERR=41
_EXIT_STATUS_PATCH_ERR=50

_show_help() {
	echo "Usage: $_BNAME [OPTION]..."
	echo
	echo "Options:"
	echo "	-p <dir>        apply patches from <dir>"
	echo "	-l <logfile>    choose file for logging"
	echo "	-q              quiet; do not write anything to standard output"
	echo "	-n              ignore news checking before updating"
	echo "	-c              cleanup after updating"
	echo "	-b              create a backup '/etc/portage'"
	exit 1
}

elog() {
	printf "${_CL_RS}${_CL_BBLK}${_CL_FWHT}[%s]${_CL_RS} %s${_CL_RS}\n" \
		"$(date '+%H:%M:%S')" "${*}"
}

ebegin() {
	if (( $? )); then
		_SKIP_ME=1
		return 1
	fi

	_LOGGER_TMP_MSG="${*}"
	printf "${_CL_FGRN}>>> $_LOGGER_TMP_MSG ...\n"
}

einfo() {
	printf "${_CL_FGRN}>>> $_LOGGER_TMP_MSG / %s ...\n" "${*}"
}

eerror() {
	local err_message="$2"
	local exit_code=$1

	printf "${_CL_FRED}>>> $_LOGGER_TMP_MSG / "
	case ${exit_code} in
		$_EXIT_STATUS_SYNC_ERR)
			printf "Sync error. Abort";;
		$_EXIT_STATUS_NEWS_AVAIL)
			printf "Please read news before updating! Abort";;
		$_EXIT_STATUS_UPDATE_FAILS)
			printf "Update fails. Abort";;
		$_EXIT_STATUS_PRE_UPDATE_FAILS)
			printf "Pre update fails. Abort";;
		$_EXIT_STATUS_POST_UPDATE_FAILS)
			printf "Post update fails. Abort";;
		$_EXIT_STATUS_BACKUP_CREATE_ERR)
			printf "Fail to create backup. Abort";;
		$_EXIT_STATUS_BACKUP_RESTORE_ERR)
			printf "Fail to restore the current backup. Abort";;
		$_EXIT_STATUS_PATCH_ERR)
			printf "Errors while applying patches. Abort";;
		*) printf "${err_message}";;
	esac
	printf " ...\n"
}

eend() {
	local err_message="$2"
	local exit_code=$1

	if (( $_SKIP_ME )); then
		unset _SKIP_ME
		return 1
	fi

	if (( $exit_code )); then
		eerror $_EXIT_STATUS

		[ -n "$err_message" ] && \
			printf "${_CL_FRED}>>> $_LOGGER_TMP_MSG / $err_message${_CL_RS}\n"
	else
		printf "${_CL_FGRN}>>> $_LOGGER_TMP_MSG / Done!\n"
	fi

	_LOGGER_TMP_MSG=

	return $exit_code
}

logger() {
	local output

	(( ${#} )) && return 1

	set -- "${@}"
	while read -r output; do
		(( $_LOGGER_ENABLED )) || elog "$output" >> "$_LOGGER_FILE_PATH"
		(( $_QUIET )) || elog "$output"
	done
}

_is_stat() {
	(( $1 == $_EXIT_STATUS )) || return 1
}

# _is_int() {
# 	printf "%d" "${*}" > /dev/null 2>&1 || return 1
# }

sync_repos() {
	(( $_SKIP_ME )) && return 1

	einfo "sync all repos using \"emaint sync -A\""

	eval $_EMAINT_CMD sync -A
	if (( $? )); then
		_EXIT_STATUS=$_EXIT_STATUS_SYNC_ERR
		return 1
	fi

	if [ -x /usr/bin/eix-diff ]; then
		_EIX_IS_AVAIL=1
		/usr/bin/eix-update --quiet > /dev/null 2>&1 && \
		/usr/bin/eix-diff --force-color 2> /dev/null # || return 1
	fi

	if ! (( $_IGNORE_CHECKING_NEWS )); then
		local news_file="/var/lib/gentoo/news/news-gentoo.unread"
		[ -f "$news_file" ] || return
		if (( $(wc -l "$news_file" | cut -c1) > 0 )); then
			_EXIT_STATUS=$_EXIT_STATUS_NEWS_AVAIL
			return 1
		fi
	fi
}

_backup_config() {
	(( $_BACKUP )) || return 0

	einfo "create a backup for '/etc/portage'"

	mkdir -p "$(dirname -- "${_BACKUP_FILE}")" && \
	/bin/tar -cvJp --xattrs \
		-f "${_BACKUP_FILE}" '/etc/portage' 2> /dev/null

	if (( $? )); then
		_EXIT_STATUS=$_EXIT_STATUS_BACKUP_CREATE_ERR
		return 1
	fi
}

_restore_curr_backup() {
	(( $_BACKUP )) || return 0

	local tmp_d="$(mktemp -d)"

	if _is_stat $_EXIT_STATUS_BACKUP_CREATE_ERR; then
		return 1
	fi

	einfo "restore configurations in '/etc/portage' from last backup"

	/bin/tar -xJp --xattrs -f "${_BACKUP_FILE}" \
		-C "${tmp_d}" 2> /dev/null && \
		/usr/bin/rsync -aqzP --delete "${tmp_d}/etc/portage/" '/etc/portage/' 2>&1

	if (( $? )); then
		_EXIT_STATUS=$_EXIT_STATUS_BACKUP_RESTORE_ERR
		return 1
	else
		if [ -d "${tmp_d}/etc/portage/" ]; then
			rm -fr "${tmp_d}" 2>&1 || return 1
			[ -f "${_BACKUP_FILE}" ] && rm -f "${_BACKUP_FILE}" 2>&1
		else
			_EXIT_STATUS=$_EXIT_STATUS_BACKUP_RESTORE_ERR
			return 1
		fi
	fi
}

_apply_patches() {
	if ! [ -d "$_DIR_OF_PATCHES" ]; then
		return
	fi

	einfo "applying patches from '$_DIR_OF_PATCHES'"

	pushd '/etc/portage' > /dev/null
	/usr/bin/find "$_DIR_OF_PATCHES" -maxdepth 1 \
		-iname '*.patch' -iname '*.diff' \
		-print 2> /dev/null | while read -r p; do
			/usr/bin/patch -p1 < "$p" 2>&1
			if (( $? )); then
				_EXIT_STATUS=$_EXIT_STATUS_PATCH_ERR
				return 1
			fi
	done
	popd >/dev/null
}

_pre_update() {
	_backup_config || return 1
	_apply_patches || return 1

	einfo "perform package move updates for all packages"
	/usr/sbin/fixpackages || return 1

	einfo "install new version of portage before updating"
	eval $_EMERGE_CMD --oneshot --noreplace --update sys-apps/portage && \
	eval $_EMAINT_CMD moveinst -f && \
	eval $_EMAINT_CMD movebin -f

	if (( $? )); then
		_EXIT_STATUS=$_EXIT_STATUS_PRE_UPDATE_FAILS
		return 1
	fi
}

_post_update() {
	if (( $_CLEANUP )); then
		einfo "remove unused packages, distfiles and binpkgs"

		eval CLEAN_DELAY=0 $_EMERGE_CMD --verbose=n --depclean

		if (( $? )); then
			_EXIT_STATUS=$_EXIT_STATUS_POST_UPD_CLEANUP_FAILS
			return 1
		fi

		if [ -x /usr/bin/eclean ]; then
			/usr/bin/eclean-dist -d 2>&1
			/usr/bin/eclean-pkg -nd 2>&1
		fi
	fi

	einfo "rebuild modules and preserved packages"

	eval $_EMERGE_CMD --nodeps @preserved-rebuild @module-rebuild && \
	/usr/bin/revdep-rebuild --quiet --ignore

	if (( $? )); then
		_EXIT_STATUS=$_EXIT_STATUS_POST_UPD_REBUILD_FAILS
		return 1
	fi
}

update_pkgs() {
	(( $_SKIP_ME )) && return 1

	local max_prbcnt=${1}
	local em_status

	_pre_update || return 1

	einfo "starting update packages (@world)"

	for i in $(seq 1 $max_prbcnt); do
		einfo "emerge attempt $i (of $max_prbcnt)"

		eval $_EMERGE_CMD --changed-{use,deps} --newuse --deep --update @world
		em_status=$?

		if (( $em_status && $i != $max_prbcnt )); then
			einfo "applying changes in '/etc/portage'"
			/usr/sbin/etc-update --automode -5 '/etc/portage' 2>&1
		else
			break
		fi
	done

	if (( $em_status == 0 )); then
		_post_update || return 1
	else
		_restore_curr_backup || return 1

		_EXIT_STATUS=$_EXIT_STATUS_UPDATE_FAILS
		return 1
	fi
}

_alert_via_dbus() {
	:
}

_alert_via_email() {
	:
}

_alert_via_telegram() {
	:
}

send_report() {
	(( $_SKIP_ME )) && return 1

	local title="${1}"
	local raw_message

	set -o noglob; while read -r raw_message; do
		:
	done; set +o noglob

	_alert_via_email

	return
}

################################################
################################################

while getopts 'bcnhql:p:' opt; do
	case "${opt}" in
		b) _BACKUP=1;;
		c) _CLEANUP=1;;
		n) _IGNORE_CHECKING_NEWS=1;;
		l)
			_LOGGER_ENABLED=1
			if [ -f ${OPTARG} ]; then
				_LOGGER_FILE_PATH="${OPTARG}"
			else
				echo "Warning: ${OPTARG} - is not found!"
			fi
			;;
		p)
			if [ -d "${OPTARG}" ]; then
				_DIR_OF_PATCHES="${OPTARG}"
			else
				echo "Error: ${OPTARG} - is not found!"
				exit 1
			fi
			;;
		q) _QUIET=1;;
		h) _show_help;;
	esac
done; shift $((OPTIND -1))

{
	printf "=== Starting $_BNAME ===\n"
	printf "$_CL_FYEL *\n"
	printf "$_CL_FYEL * Warning! This is a very dangerous thing to do\n"
	printf "$_CL_FYEL * and will break your system at some point!\n"
	printf "$_CL_FYEL *\n"

	ebegin "Sync repos"
	sync_repos
	eend $? "Error while synchronize repos!"

	ebegin "Update packages"
	update_pkgs $_EM_MAX_ATTEMPTS
	eend $? "Error while updating packages!"

	# unset _SKIP_ME # send always report message
	# ebegin "Send report"
	# send_report "${_BNAME}: update completed!" <<-_EOF_
	# 	date: $_CURR_DATE_STR
	# 	exit status: $(printf "%s (%d)\n" "$(eerror $_EXIT_STATUS)" $_EXIT_STATUS)
	# 	changes in '/etc/portage':
	# 	$(
	# 		if [ -f "$_LAST_ETC_UPD_OUTPUT_DIFF" ]; then
	# 			< "$_LAST_ETC_UPD_OUTPUT_DIFF"
	# 		else
	# 			echo -n "Warning: $_LAST_ETC_UPD_OUTPUT_DIFF - is not found!"
	# 		fi
	# 	)
	# 	used patches: $(echo blahblah-harhar.patch)
	# 	eix-diff: $( (( $_EIX_IS_AVAIL )) && { echo; eix-diff; } || echo -n 'not installed!' )
	# _EOF_
	# eend $? "Fail to send report message!"

	printf "=== Update completed! Exit status: %d ===\n" $_EXIT_STATUS
} | logger

exit $?
