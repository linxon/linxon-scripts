#!/usr/bin/env bash

# usage: `CCACHE_ENV_FILE='/path/to/env' ccache_env make -j9`
: ${CCACHE_ENV_FILE="/etc/portage/env/useccache"}

_CCACHE_PARAMS+=(
	CCACHE_DIR
	CCACHE_MAXSIZE
	CCACHE_UMASK
	CCACHE_NLEVELS
	CCACHE_COMPILERCHECK
	CCACHE_COMPRESS
	CCACHE_COMPRESSLEVEL
	CCACHE_TEMPDIR
)

_update_env() {
	local x i=0
	local _ccache_env

	if [ -f "${CCACHE_ENV_FILE}" ]; then
		source "${CCACHE_ENV_FILE}"
		for x in ${_CCACHE_PARAMS[@]}; do
			eval export ${_CCACHE_PARAMS[$i]}
			i=$(($i + 1))
		done
	else
		_ccache_env="$(portageq envvar ${_CCACHE_PARAMS[*]})"

		# TODO: add support ccache.conf reading using CCACHE_DIR var
		#...

		IFS=$'\n'
		for x in ${_ccache_env}; do
			eval export ${_CCACHE_PARAMS[$i]}="\$x"
			i=$(($i + 1))
		done
	fi

	env | grep "^CCACHE_"
}

if [ $# -eq 0 ]; then
	printf "Usage: ccache_env make -jN [args]\n"
	exit
fi

# WARNING!
# The technique of letting ccache masquerade as the compiler
# works well, but currently doesn't interact well with other
# tools that do the same thing.
#
# See USING CCACHE WITH OTHER COMPILER WRAPPERS and ccache(1)

_update_env
exec "$@" CC="ccache ${CC:-gcc}"
