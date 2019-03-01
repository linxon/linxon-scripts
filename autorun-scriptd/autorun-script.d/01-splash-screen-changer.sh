#!/bin/bash

CONFIG_FILE="${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml"
SCREENS_PATH="${HOME}/.xfce-splash"

if ! [[ -f ${CONFIG_FILE} && -d ${SCREENS_PATH} && -n "$(xfce4-session -V | grep '4.12.1')" ]]; then
	exit 1
elif [ -f /etc/xdg/xfce4/kiosk/kioskrc ]; then
	if [[ "`cat /etc/xdg/xfce4/kiosk/kioskrc \
				| grep -i "customizesplash" \
				| tr '[A-Z]' '[a-z]' \
				| sed -e "s/customizesplash=//"`" != "all" ]]; then
		exit 1
	fi
fi

function getRandomImage() {
	
	i=0
	
	for image in `find ${SCREENS_PATH}/ \( -iname "*.JPG" -or -iname "*.JPEG" -or -iname "*.PNG" \)`
	do
		[ -f ${image} ] && {
			let i+=1
			IMAGE_LIST[$i]=${image}
		}
	done
	
	echo ${IMAGE_LIST[$[ 1 + $[ RANDOM % $i ]]]}
}

[ -x /usr/bin/xmllint ] && {

	if $(xmllint --xpath '//property[@name="splash"]/property[@name="Engine"][@value="simple"]' ${CONFIG_FILE} > /dev/null 2>&1); then
		IMAGE=$(xmllint --xpath '//property[@name="splash"]/property[@name="engines"]/property[@name="simple"]/property[@name="Image"]' ${CONFIG_FILE} || echo 1)
		[[ ${IMAGE} == "1" ]] && exit 1
	else
		exit 1
	fi

	IMAGE=`echo ${IMAGE} | awk -F 'value="' '{print $2}' | awk -F '"/>' '{print $1}'`
	echo ${IMAGE} | sed 's/\//\\\//g' > ${SCREENS_PATH}/current_image \
		&& IMAGE=`cat ${SCREENS_PATH}/current_image`

	NEW_IMAGE=`getRandomImage`
	echo ${NEW_IMAGE} | sed 's/\//\\\//g' > ${SCREENS_PATH}/current_image \
		&& NEW_IMAGE=`cat ${SCREENS_PATH}/current_image`

	mv ${CONFIG_FILE} ${CONFIG_FILE}.old
	sed 's/'${IMAGE}'/'${NEW_IMAGE}'/g' ${CONFIG_FILE}.old > ${CONFIG_FILE}

}
