#!/bin/bash
######################################
#    by Linxon (email@linxon.ru)     #
######################################

BIN_PATH="/usr/bin/conky"
STAT_FILE="${HOME}/.conkystat"

if [ -f "${STAT_FILE}" ] && ! [ $(pidof `basename "${BIN_PATH}"`) ]; then
	WAIT_COUNT=25
	CURR_WAIT_COUNT=0

	while true; do

		if [ "$(pidof {xfwm4,xfdesktop})" ]; then
			echo "Starting conky..." && sleep 9
			${BIN_PATH} > /dev/null 2>&1 &

			[ $? = 0 ] && pidof conky > "${STAT_FILE}"
			break
		fi

		sleep 1

		CURR_WAIT_COUNT=$((${CURR_WAIT_COUNT}+1))
		if (( ${CURR_WAIT_COUNT} == ${WAIT_COUNT} )); then
			break
		fi
	done
fi
