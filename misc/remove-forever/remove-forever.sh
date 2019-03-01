#!/bin/bash

if ! [ -x /usr/bin/zenity ]; then
	echo "Ошибка: Для удаления необходим пакет - zenity"
	notify-send --urgency=low -i "error" "Ошибка: Для удаления необходим пакет - zenity"
	exit 1
fi
if ! [ -x /usr/bin/wipe ]; then
	echo "Ошибка: Для удаления необходим пакет - wipe"
	notify-send --urgency=low -i "error" "Ошибка: Для удаления необходим пакет - wipe"
	exit 1
fi

if [ "$1" ]; then

	if [ -f "$1" ] || [ -d "$1" ]; then
		zenity --question --title="Удалить файл навсегда" --text="Вы уверены, что хотите удалить: \n\nПуть: $*";
		case $? in 0)
			(shred -v -z -n 9 -- "$@" && wipe -rf -- "$@") | zenity --progress --title="Статус" --text="Удаление										" --percentage=10
			notify-send --urgency=low -i "emblem-default" "Удаление завершено!"
			if [ "$?" = -1 ] ; then
				zenity --error --text="Действие было отменено."
				notify-send --urgency=low -i "dialog-warning" "Действие было отменено."
			fi
		esac
	else
		echo "rf: файл/каталог не был найден"
	fi
	
else
	echo "rf: недостаточно параметров"
fi

exit 0
