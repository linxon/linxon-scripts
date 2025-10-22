#!/bin/ash
#######################

#######################

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

_FLOCK_FILE="/var/lock/$(basename ${0%%.sh})".lock
_FLOCK_FD=200

eval "exec $_FLOCK_FD>$_FLOCK_FILE"

_led_timer_on() {
	echo 'timer' > '/sys/class/leds/red:power/trigger'
#	echo 'default-on' > '/sys/class/leds/white:status/trigger'
}
_led_timer_off() {
	echo 'none' > '/sys/class/leds/red:power/trigger'
#	echo 'default-on' > '/sys/class/leds/white:status/trigger'
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
				cut -d ':' -f 4)" == "lo" ]]; then
		return 0
	fi

	return 1
}

_is_enabled() {
	# /etc/init.d/ruantiblock enabled
	if [ -f /etc/rc.d/S99ruantiblock ]; then
		return 0
	fi

	return 1
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

enable_ruantiblock() {
	local _status

	_led_timer_on
	_led_status

	/etc/init.d/ruantiblock enable
	/usr/bin/ruantiblock start && /usr/bin/ruantiblock force-update
	_status=$?

#	local rule_name=$(uci add system blink_led_ruantiblock) 
#	uci batch <<-EOF set system.$rule_name.name='blink_led_ruantiblock'
#		set system.$rule_name.sysfs='red:power'
#		set system.$rule_name.trigger='timer'
#		set system.$rule_name.delayon='100'
#		set system.$rule_name.delayoff='3000'
#	EOF
#	uci commit

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
		jq '.["outbounds"][0] | .["settings"] | .["vnext"][0] | .address')"

	_led_timer_on
	_led_status

	local _chk_cnt=0
	while true; do
		_chk_cnt=$(($_chk_cnt+1))

		if ping -c1 -W 10 -- openwrt.org > /dev/null 2>&1; then
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
		https://check.torproject.org/api/ip | jq '.IP')"

	_status=$?

	if [[ "_$vless_host_ip" != "_$recieved_ip" ]]; then
		_led_err
		return 1
	fi

	_led_ok

	return $_status
}

cleanup() {
	local _status=$1
	[ -f "$_FLOCK_FILE" ] && rm -f "$_FLOCK_FILE" 2>&1 > /dev/null
	return $_status
}

{
	if flock -x $_FLOCK_FD; then
		if _button_ruantiblock_check; then # если включен
			if _is_enabled; then

				if [ "$1" == "check-ip" ]; then
					check_restricted_host
				fi

				cleanup $?
				exit $?
			fi

			_enable_depends && \
				enable_ruantiblock && \
				check_restricted_host
		else  # если выключен
			if ! _is_enabled; then
				cleanup $?
				exit 0
			fi

			_disable_depends
			disable_ruantiblock
		fi

		cleanup $?
	fi
}

exit $?
