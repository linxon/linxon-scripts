#!/bin/ash
#######################

FORCE_OVERWRITE="${FORCE_OVERWRITE:=0}"
AUTOREMOVE="${AUTOREMOVE:=1}" # default ON
REMOVE_DEPENDS="${REMOVE_DEPENDS:=1}" # default ON
LOGGER_ENABLED="${LOGGER_ENABLED:=0}"

LOGGER_DIR="/tmp/system-updater"
LOGGER_FILE_PATH="${LOGGER_DIR}/$(basename ${0%%.sh})-$(date '+%Y-%m-%d').log"

PRIMARY_PKG_LIST="opkg luci luci-base"
EXCLUDE_PKG_LIST="netifd kernel"

#######################

_LOGGER_TMP_MSG=
_OPKG_UPGRADE_ARGS=

#Create folders if not exist
if [ ! -d "${LOGGER_DIR}" ]; then
        mkdir -p "${LOGGER_DIR}" || exit 1
fi

_FLOCK_FILE="${LOGGER_DIR}/$(basename ${0%%.sh})".lock
_FLOCK_FD=200

#Create lock file
eval "exec $_FLOCK_FD>$_FLOCK_FILE"

#Enable force overwrite packages
if [ ${FORCE_OVERWRITE} -ne 0 ]; then
	_OPKG_UPGRADE_ARGS="${_OPKG_UPGRADE_ARGS} --force-overwrite"
fi

#Enable autoremove packages
if [ ${AUTOREMOVE} -ne 0 ]; then
	_OPKG_UPGRADE_ARGS="${_OPKG_UPGRADE_ARGS} --autoremove"
fi

#Enable remove depends
if [ ${REMOVE_DEPENDS} -ne 0 ]; then
	_OPKG_UPGRADE_ARGS="${_OPKG_UPGRADE_ARGS} --force-removal-of-dependent-packages"
fi

ebegin() {
        _LOGGER_TMP_MSG="${*}"
        echo ">>> $_LOGGER_TMP_MSG ..."
}

eend() {
        local err_message="$2"
        local exit_code="$1"

        if [ $exit_code -gt 0 ]; then
                [ -n "$err_message" ] && echo ">>> $_LOGGER_TMP_MSG / $err_message"
                exit $exit_code
        else
                echo ">>> $_LOGGER_TMP_MSG / Done!"
        fi

        _LOGGER_TMP_MSG=
}

elog() {
        printf "[%s] %s\n" "$(date '+%H:%M:%S')" "${*}"
}

logger() {
        while read log; do
                if [ $LOGGER_ENABLED -eq 1 ]; then
                        elog "${log}" >> "${LOGGER_FILE_PATH}"
                else
                        elog "${log}"
                fi
        done

        if [ $LOGGER_ENABLED -eq 1 ]; then
                gzip -f "${LOGGER_FILE_PATH}"
        fi
}

cleanup() {
        #Remove lock file
        [ -f "$_FLOCK_FILE" ] && rm -f "$_FLOCK_FILE" 2>&1 > /dev/null

        #Remove old log files
        find "${LOGGER_DIR}" -type f -name "$(basename ${0%%.sh})-*.log*" -mtime +30 -exec rm -- {} \;
}

{
        printf "--- Starting autoupdater ($(date '+%Y-%m-%d')) ---\n"

        if flock -x $_FLOCK_FD; then
                ebegin "Sync repos"
                /bin/opkg update 2>&1
                eend $? "Error while updating repos!"

                ebegin "Upgrade primary packages before"
                for pkgname in $PRIMARY_PKG_LIST; do
                        /bin/opkg upgrade $_OPKG_UPGRADE_ARGS -- "${pkgname}" 2>&1
                done
                eend $? "Error while upgrading primary packages!"

                ebegin "Update all available packages"
                for pkgname in $(/bin/opkg list-upgradable | cut -d' ' -f1); do
                        echo $EXCLUDE_PKG_LIST | grep -q "${pkgname}" && continue
                        /bin/opkg upgrade $_OPKG_UPGRADE_ARGS -- "${pkgname}" 2>&1
                done
                eend $? "Error while upgrading packages!"
        else
                _LOGGER_TMP_MSG="Starting autoupdater"
                eend 255 "Failed to acquire lock"
        fi

        printf "--- Update completed! Exit status: %s ---\n" $?
} | logger

cleanup

exit $?
