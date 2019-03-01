#!/bin/sh

PW=$(date +%s | sha256sum | base64 | head -c 16)
echo ${PW} | xclip -selection "clipboard" && {
	[ -x /usr/bin/notify-send ] && notify-send --urgency=low -i "$([ $? = 0 ] && echo xfce4-clipman-plugin)" "Пароль скопирован в буфер обмена как:" "${PW}"
}
