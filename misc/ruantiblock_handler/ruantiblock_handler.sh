#!/bin/ash
#######################
# Crontab rule example:
#	*/5 * * * * /bin/ash -c "ENABLE_RESTART_DEPENDS=1 /usr/local/libexec/ruantiblock_handler.sh check-ip"
#
# OpenWrt init.d script example:
#	#!/bin/sh /etc/rc.common
#	USE_PROCD=1
#	START=99
#	STOP=01
#	start_service() {
#		procd_open_instance
#		procd_set_param command /usr/local/libexec/ruantiblock_handler.sh check-ip
#		procd_close_instance
#	}
#
#
# Written by Yury Martynov (email@linxon.ru)
#######################

# Обработка ошибок после завершения работы скрипта
ENABLE_RESTART_NETWORK="${ENABLE_RESTART_NETWORK:=0}"
ENABLE_RESTART_DEPENDS="${ENABLE_RESTART_DEPENDS:=0}"
ENABLE_REBOOT_SYS="${ENABLE_REBOOT_SYS:=0}"

MAX_CHECKING_COUNT="${MAX_CHECKING_COUNT:=20}"

#######################

_RETURN_OK=0
_RETURN_ERR=1
_RETURN_TRUE=0
_RETURN_FALSE=1
_RETURN_ERR_SERVICE=110
_RETURN_ERR_NETWORK=111
_RETURN_ERR_NETWORK_VLESS=112

_FLOCK_FILE="/var/lock/$(basename ${0%%.sh})".lock
_FLOCK_FD=200

trap quit EXIT
trap force_quit SIGINT SIGTERM

if [ ! -x /usr/bin/flock ]; then
	echo "/usr/bin/flock is not found!"
	exit $_RETURN_ERR
fi

if [ ! -x /etc/init.d/ruantiblock ]; then
	echo "/etc/init.d/ruantiblock is not found!"
	exit $_RETURN_ERR
fi

if [ ! -x /usr/bin/curl ]; then
	echo "/usr/bin/curl is not found!"
	exit $_RETURN_ERR
fi

if [ ! -f /sys/kernel/debug/gpio ]; then
	echo "/sys/kernel/debug/gpio is not found!"
	exit $_RETURN_ERR
fi

if [ ! -d /sys/class/leds/red:power ]; then
	echo "/sys/class/leds/red:power is not found!"
	exit $_RETURN_ERR
fi

_wait_lock() {
	eval "exec $_FLOCK_FD>$_FLOCK_FILE"
	/usr/bin/flock -x $_FLOCK_FD

	return $?
}

_led_timer_on() {
	echo 'timer' > '/sys/class/leds/red:power/trigger'
}
_led_timer_off() {
	echo 'none' > '/sys/class/leds/red:power/trigger'
}
_led_status() {
	echo '50' > '/sys/class/leds/red:power/delay_on'
	echo '50' > '/sys/class/leds/red:power/delay_off'
}
_led_ok() {
	echo '100' > '/sys/class/leds/red:power/delay_on'
	echo '2500' > '/sys/class/leds/red:power/delay_off'
}
_led_err() {
	echo '1000' > '/sys/class/leds/red:power/delay_on'
	echo '1000' > '/sys/class/leds/red:power/delay_off'
}

_get_button_status() {
	if [[ "$(cat /sys/kernel/debug/gpio |
				grep -E "\|mode" |
				tr ' ' ':' |
				cut -d ')' -f 2 |
				cut -d ':' -f 4)" != "lo" ]]; then

		return $_RETURN_FALSE
	fi
}

_is_srv_enabled() {
	if ! /etc/init.d/ruantiblock enabled; then
		return $_RETURN_FALSE
	fi
}

_enable_depends() {
	/etc/init.d/xray enable
	/etc/init.d/sslocal enable
	/etc/init.d/xray start && /etc/init.d/sslocal start

	return $?
}

_disable_depends() {
	/etc/init.d/sslocal stop && /etc/init.d/xray stop
	/etc/init.d/sslocal disable
	/etc/init.d/xray disable
}

_cleanup() {
	[ -f "$_FLOCK_FILE" ] && rm -f "$_FLOCK_FILE" 2>&1 > /dev/null
}

enable_ruantiblock() {
	local _status

	_led_timer_on
	_led_status

	/etc/init.d/ruantiblock enable
	/usr/bin/ruantiblock start && /usr/bin/ruantiblock force-update
	_status=$?

	if [ $_status -eq $_RETURN_OK ]; then
		_led_ok
	else
		_led_err
	fi

	return $_status
}

disable_ruantiblock() {
	local _status

	_led_timer_on
	_led_status

	/etc/init.d/ruantiblock disable
	/usr/bin/ruantiblock destroy
	_status=$?

	_led_timer_off

	return $_status
}

check_restricted_host() {
	local _status=

	local recieved_ip=
	local vless_host_ip="$(cat /etc/xray/config.json | \
		jsonfilter -e '$.outbounds.*.settings.vnext.*.address')"

	_led_timer_on
	_led_status

	local _chk_cnt=0
	while true; do
		_chk_cnt=$(($_chk_cnt+1))

		if /usr/bin/curl -s --connect-timeout 10 -- openwrt.org > /dev/null 2>&1; then
			break
		elif [ $_chk_cnt -gt 5 ]; then
			_led_err
			return $_RETURN_ERR_NETWORK
		else
			sleep 1
			continue
		fi
	done

	recieved_ip="$(/usr/bin/curl -s \
		-H 'X-Requested-With:XMLHttpRequest' \
		--retry 5 \
		--connect-timeout 20 -- \
		https://check.torproject.org/api/ip | jsonfilter -e '$.IP')"

	_status=$?

	if [[ "_$vless_host_ip" != "_$recieved_ip" ]]; then
		_led_err
		return $_RETURN_ERR_NETWORK_VLESS
	fi

	_led_ok

	return $_status
}

force_quit() {
	_led_timer_off
	exit $_RETURN_ERR
}

quit() {
	local _status=$?

	local _cnt=0
	local _cnt_file="/tmp/ruantiblock/$(basename ${0%%.sh}).cnt"

	# перезагрузка сетевых интерфейсов, если что-то пошло не так с подключением
	if [ $ENABLE_RESTART_NETWORK -ne 0 ] && [ $_status -eq $_RETURN_ERR_NETWORK ]; then
		if [ -f "$_cnt_file" ]; then
			_cnt=$(cat "$_cnt_file")
		fi

		if [ $_cnt -gt $MAX_CHECKING_COUNT ]; then
			/etc/init.d/network restart # TODO: сделать перезагрузку только WAN интерфейсов, а не всей сети
		fi

		echo $(($_cnt+1)) > "$_cnt_file"

	# перезагрузка зависимостей Ruantiblock, если что-то пошло не так с подключением
	elif [ $ENABLE_RESTART_DEPENDS -ne 0 ] && [ $_status -eq $_RETURN_ERR_NETWORK_VLESS ]; then
		if [ -f "$_cnt_file" ]; then
			_cnt=$(cat "$_cnt_file")
		fi

		if [ $_cnt -gt $MAX_CHECKING_COUNT ]; then
			disable_ruantiblock && _disable_depends
			_enable_depends && enable_ruantiblock
		fi

		echo $(($_cnt+1)) > "$_cnt_file"

	# перезагрузка устройства после прочих ошибок
	elif [ $ENABLE_REBOOT_SYS -ne 0 ] && [ $_status -ne $_RETURN_OK ]; then
		if [ -f "$_cnt_file" ]; then
			_cnt=$(cat "$_cnt_file")
		fi

		if [ $_cnt -gt $MAX_CHECKING_COUNT ]; then
			/sbin/reboot -d 60
		fi

		echo $(($_cnt+1)) > "$_cnt_file"

	else
		[ -f "$_cnt_file" ] && rm -f "$_cnt_file" 2>&1 > /dev/null
	fi

	_cleanup
}

_wait_lock || exit $_RETURN_ERR

if _get_button_status; then
	if _is_srv_enabled; then

		if [ "$1" == "check-ip" ]; then
			check_restricted_host
		fi

		exit $?
	fi

	_enable_depends && \
		enable_ruantiblock && \
		check_restricted_host
else
	if ! _is_srv_enabled; then
		exit $_RETURN_OK
	fi

	disable_ruantiblock
	_disable_depends
fi

exit $?
