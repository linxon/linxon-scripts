#!/bin/sh

USER_SCR_DIR="${HOME}/.autorun-script.d"
LOG_FILE="${HOME}/.autorun-scriptd.log"

############################################################

cat /dev/null > "${LOG_FILE}"
if ! [ -d "${USER_SCR_DIR}" ]; then
	mkdir -p "${USER_SCR_DIR}" || exit 1
fi

for f in $(find "/etc/xdg/autorun-script.d" "${USER_SCR_DIR}" \( -iname "*.sh" \)); do
	if [ -x "${f}" ]; then
		echo "[`date '+%x-%R:%S'`] Running: ${f}"   >> "${LOG_FILE}"
		"${f}" >> "${LOG_FILE}" && echo "    ... Done" >> "${LOG_FILE}" \
							  || echo "    ... Error" >> "${LOG_FILE}"
	fi
done