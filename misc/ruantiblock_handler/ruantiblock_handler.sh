#!/bin/ash
#######################

#######################

_FLOCK_FILE="/var/lock/$(basename ${0%%.sh})".lock
_FLOCK_FD=200

eval "exec $_FLOCK_FD>$_FLOCK_FILE"

trap quit EXIT
trap force_quit SIGINT SIGTERM

if [ ! -x /usr/bin/flock ]; then
	echo "/usr/bin/flock is not found!"
	exit 1
fi

if [ ! -x /etc/init.d/ruantiblock ]; then
	echo "/etc/init.d/ruantiblock is not found!"
	exit 1
fi

if [ ! -x /usr/bin/jq ]; then
	echo "/usr/bin/jq is not found!"
	exit 1
fi

if [ ! -x /usr/bin/curl ]; then
	echo "/usr/bin/curl is not found!"
	exit 1
fi

if [ ! -f /sys/kernel/debug/gpio ]; then
	echo "/sys/kernel/debug/gpio is not found!"
	exit 1
fi

if [ ! -d /sys/class/leds/red:power ]; then
	echo "/sys/class/leds/red:power is not found!"
	exit 1
fi

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

_button_ruantiblock_check() {
	if [[ "$(cat /sys/kernel/debug/gpio |
				grep -E "\|mode" |
				tr ' ' ':' |
				cut -d ')' -f 2 |
				cut -d ':' -f 4)" != "lo" ]]; then
		return 1
	fi
}

_is_enabled() {
	if ! /etc/init.d/ruantiblock enabled; then
		return 1
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

	if [ $_status -eq 0 ]; then
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
		jq -r '.["outbounds"][0] | .["settings"] | .["vnext"][0] | .address')"

	_led_timer_on
	_led_status

	local _chk_cnt=0
	while true; do
		_chk_cnt=$(($_chk_cnt+1))

		if /usr/bin/curl -s --connect-timeout 10 -- openwrt.org > /dev/null 2>&1; then
			break
		elif [ $_chk_cnt -gt 5 ]; then
			_led_err
			return 1
		else
			sleep 1
			continue
		fi
	done

	recieved_ip="$(/usr/bin/curl -s \
		-H "X-Requested-With:XMLHttpRequest" \
		--retry 5 \
		--connect-timeout 20 -- \
		https://check.torproject.org/api/ip | jq -r '.IP')"

	_status=$?

	if [[ "_$vless_host_ip" != "_$recieved_ip" ]]; then
		_led_err
		return 1
	fi

	_led_ok

	return $_status
}

force_quit() {
	_led_timer_off
	exit 1
}

quit() {
	_cleanup
}

{
	if flock -x $_FLOCK_FD; then
		if _button_ruantiblock_check; then # если включен
			if _is_enabled; then

				if [ "$1" == "check-ip" ]; then
					check_restricted_host
				fi

				exit $?
			fi

			_enable_depends && \
				enable_ruantiblock && \
				check_restricted_host
		else  # если выключен
			if ! _is_enabled; then
				exit 0
			fi

			_disable_depends
			disable_ruantiblock
		fi
	fi
}

exit $?
