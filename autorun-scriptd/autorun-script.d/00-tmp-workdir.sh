#!/bin/bash

TMP_DIR="/tmp/${USER}-tmp-files"
LINK_2_TMP_DIR="${HOME}/WorkDir"

if [ -d ${TMP_DIR} ]; then
	# пропускаем
	exit
fi

/bin/mkdir -p --mode=0700 ${TMP_DIR} && {

	echo "Это временная директория (tmpfs). Все файлы будут удалены после перезагрузки." > "${TMP_DIR}"/README.txt

	if ! [ -d ${LINK_2_TMP_DIR} ]; then
		/bin/ln -sf "${TMP_DIR}" "${LINK_2_TMP_DIR}" || exit 1
	fi

	GTK3_CONF_DIR="${HOME}/.config/gtk-3.0/"
	if [[ -f "${GTK3_CONF_DIR}"/bookmarks \
			&& ! $(cat "${GTK3_CONF_DIR}"/bookmarks | grep -i "file://${LINK_2_TMP_DIR}") ]]; then
		/bin/mv "${GTK3_CONF_DIR}"/bookmarks "${GTK3_CONF_DIR}"/bookmarks.bak
		echo "file://${LINK_2_TMP_DIR}" > "${GTK3_CONF_DIR}"/bookmarks
		/bin/cat "${GTK3_CONF_DIR}"/bookmarks.bak >> "${GTK3_CONF_DIR}"/bookmarks
	fi

} || exit 1