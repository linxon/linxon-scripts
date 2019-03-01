#!/bin/sh

APLAY_BINARY="/usr/bin/aplay"
STARTUP_SOUND_FILES_DIR="${HOME}/.sounds/startup"

#######################################################

if ! [ -d "${STARTUP_SOUND_FILES_DIR}" ]; then
	mkdir -p "${STARTUP_SOUND_FILES_DIR}"
fi

function getRandomSound() {
	local SOUND_LIST i
	
	i=0
	for sound in $(find "${STARTUP_SOUND_FILES_DIR}/" \( -iname "*.wav" \))
	do
		if [ -f "${sound}" ]; then
			let i+=1
			SOUND_LIST[${i}]=${sound}
		fi
	done
	
	echo ${SOUND_LIST[$[ 1 + $[ RANDOM % ${i} ]]]}
}

if [ -x "${APLAY_BINARY}" ]; then
	${APLAY_BINARY} -q "$(getRandomSound)" &
fi
