#!/bin/bash +x

PORTAGE_VDB_PATH="${PORTAGE_VDB_PATH:-/var/db/pkg}"
PORTAGE_BIN_PATH="${PORTAGE_BIN_PATH:-/usr/lib/portage/python$(python -c '\
	import sys;\
	version=sys.version_info[:2];\
	print("{0}.{1}".format(*version))'
)}"

export __HOME_DIR__="${QKERNEL_HOME_DIR:-/tmp/$(basename $0)}"
export __CEC_STATE_FILE__="${__HOME_DIR__}/.check_extra_config_state"

source "${PORTAGE_BIN_PATH}/isolated-functions.sh" || exit 1
source "${PORTAGE_BIN_PATH}/phase-functions.sh" || die
source "${PORTAGE_BIN_PATH}/phase-helpers.sh" || die
source "${PORTAGE_BIN_PATH}/bashrc-functions.sh" || die

__is_func__() {
	if ! [[ "$(type -t $1)" == 'function' ]]; then
		return 1
	fi
}

__dis_func__() {
	for x in ${@}; do
		unset -f ${x}
		eval "${x}() { :; }"
	done
}

__cleanup__() {
	popd >/dev/null
	unset -f 'check_extra_config'
	[ -f "${__CEC_STATE_FILE__}" ] && unlink "${__CEC_STATE_FILE__}"

	printf '\n'
}

echo -e "=== Getting packages with 'kernel_linux' flag. Please wait ...\n"

mkdir -p "${__HOME_DIR__}" || die "failed to create: ${__HOME_DIR__}"
grep -lr 'kernel_linux' "${PORTAGE_VDB_PATH%/}"/*/*/IUSE \
			| sed -e 's/\/IUSE$//' \
			| while read x
do
	echo ">>> Entering to $x ..."

	pushd "${__HOME_DIR__}" >/dev/null && (
		source <(bzip2 -dc "${x}"/environment.bz2 | sed -e 's/\(^check_extra_config\)/\1_glob/g')

		# a state file allow to run it once only ( check_extra_config -> pkg_pretend || pkg_setup )
		function check_extra_config() {
			if __is_func__ 'check_extra_config_glob'; then
				[ -f "${__CEC_STATE_FILE__}" ] && return
				echo > "${__CEC_STATE_FILE__}" && check_extra_config_glob || die
			fi
		}

		# disable insecure funcs before checking
		__dis_func__ 'src_unpack src_prepare move_old_moduledb remove_moduledb
			update_moduledb multibuild_copy_sources multibuild_merge_root
			update_depmod eapply eapply_user enewuser enewgroup gnome2_environment_reset
			python_setup python-any-r1_pkg_setup debug-print debug-print-function
			debug-print-section tc-ld-disable-gold tc-export linux-mod_pkg_setup multilib_layout'

		__is_func__ 'pkg_pretend' && pkg_pretend
		__is_func__ 'pkg_setup' && pkg_setup

		check_extra_config
	)

	__cleanup__
done
