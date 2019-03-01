#!/bin/bash
######################################
#    by Linxon (email@linxon.ru)     #
######################################

BIN_PATH="/usr/bin/conky"
CONKY_PID=$(pidof `basename "${BIN_PATH}"`)
STAT_FILE="${HOME}/.conkystat"

if [ ! -x "${BIN_PATH}" ]; then
	echo "${BIN_PATH} — is not found!"
	exit 1
fi

if [ ! -z "${CONKY_PID}" ]; then
	echo "Conky running as: ${CONKY_PID}"
	killall -q $(basename "${BIN_PATH}")

	# Удалим файл, который используется для автозапуска conky скриптом "autostart-conky.sh"
	if [ -f "${STAT_FILE}" ] && [ ! -z $(cat "${STAT_FILE}" | grep "${CONKY_PID}") ]; then
		rm -f "${STAT_FILE}"
	fi
else
	${BIN_PATH} > /dev/null 2>&1 &
	[ $? = 0 ] && pidof conky > "${STAT_FILE}"
fi
