#!/bin/sh

# Fist is a priority; 2 — MAX
# index=3 — is a "Beeline2"
# index=8 — is a "Letai"
APN_INDEX_LIST=( 3 8 )
NOTIFY="true"
ROUTER_ADDR="192.168.0.1"
ROUTER_WAIT_TIMEOUT=120
ROUTER_MAX_CONNECTION_PROBE=5
ROUTER_MAX_REBOOT=3
CURL_EXEC="$(which curl)"
CURL_TIMEOUT=5
CURL_URI_HANDLER="http://${ROUTER_ADDR}/goform/goform_set_cmd_process"
PING_PAUSE_TIME=15
PING_TIMEOUT=10
PING_TO_HOSTS=( 
	"linxon.ru" \
	"google.com" \
	"github.com" \
	"vk.com" \
	"twitter.com" \
	"yandex.ru" \
	"ya.ru" \
	"ok.ru" \
	"opennet.ru" \
	"coub.com" \
	"tumbler.com" \
	"aliexpress.com" \
	"facebook.com"
)

if ! [ -x ${CURL_EXEC} ]; then
	echo "mf823: Curl is not found!"
	exit 1
fi

send_request() {
	local default_args="isTest=false&notCallback=true"
	local other_args="${1}"
	local sleep_count="${2}"

	${CURL_EXEC} --connect-timeout ${CURL_TIMEOUT} --max-time ${CURL_TIMEOUT} \
		-H "X-Requested-With:XMLHttpRequest" \
		-H "Referer:http://${ROUTER_ADDR}/index.html" \
		--data "${default_args}&${other_args}" \
		${CURL_URI_HANDLER} > /dev/null 2>&1

	if [ -n "${sleep_count}" ]; then
		sleep ${sleep_count}
	else
		sleep 3
	fi
}

check_host() {
	local host=( $(shuf -e ${PING_TO_HOSTS[@]}) )
	if ! ping -c1 -W ${PING_TIMEOUT} -- ${host[0]} > /dev/null 2>&1; then
		return 1
	fi
}

show_alert() {
	local title="${1}"
	local message="${2}"
	local icon="${3}"
	local timer=10
	local notifer="$(which notify-send)"

	[ -n "${4}" ] && timer=${4}

	if [[ "${NOTIFY}" == "true" && -x ${notifer} ]]; then
		${notifer} --urgency=low -t "${timer}000" -i \
			"${icon}" \
			"${title}" "${message}"
	fi
}

if [[ "$1" == "connect" ]]; then
	send_request "goformId=CONNECT_NETWORK" 0
elif [[ "$1" == "disconnect" ]]; then
	send_request "goformId=DISCONNECT_NETWORK" 0
elif [[ "$1" == "reconnect" ]]; then
	send_request "goformId=DISCONNECT_NETWORK"
	send_request "goformId=CONNECT_NETWORK" 0
elif [[ "$1" == "reboot" ]];  then
	send_request "goformId=REBOOT_DEVICE" 0
elif [[ "$1" == "fuck_beeline" ]]; then
	if [ "${2}" == "timeout" ]; then
		ROUTER_WAIT_TIMEOUT="${3}"
		echo "mf823: Timeout set to: ${ROUTER_WAIT_TIMEOUT}"
	fi

	CURR_C=0
	CURR_CON_C=0
	CURR_REBOOT_C=0

	echo -ne "[\033[4mPING STATUS\033[0m]\033[34m::\033[0m"
	while true; do
		CURR_C=$((${CURR_C}+1))
		if (( ${CURR_C} >= ${ROUTER_WAIT_TIMEOUT} )); then
			echo " Error!"
			echo "mf823: Wait timeout (ROUTER_WAIT_TIMEOUT == ${ROUTER_WAIT_TIMEOUT})"
			show_alert "mf823" "Wait timeout (ROUTER_WAIT_TIMEOUT == ${ROUTER_WAIT_TIMEOUT})" "dialog-error"
			exit 1
		fi

		sleep 1

		ROUTER_INTERFACE=$(ip a \
			| grep $(echo ${ROUTER_ADDR} \
			| grep -oE "^([0-9]?[0-9]?[0-9])\.([0-9]?[0-9]?[0-9])\.([0-9]?[0-9]?[0-9])\.")*/24 \
			| cut -d " " -f 12)
		INTERFACE_STATUS=$(ip addr show ${ROUTER_INTERFACE} \
			| head -n1 \
			| cut -d " " -f 9)

		if [[ "${ROUTER_INTERFACE}" != "" ]] && [[ "${INTERFACE_STATUS}" != "DOWN" ]]; then
			CURR_CON_C=$((${CURR_CON_C}+1))
			if (( ${CURR_CON_C} >= ${ROUTER_MAX_CONNECTION_PROBE} )); then
				CURR_REBOOT_C=$((${CURR_REBOOT_C}+1))
				if (( ${CURR_REBOOT_C} >= ${ROUTER_MAX_REBOOT} )); then
					echo " Error!"
					echo "mf823: Cannot connect to network (ROUTER_MAX_REBOOT == ${ROUTER_MAX_REBOOT})"
					show_alert "mf823" "Cannot connect to network (ROUTER_MAX_REBOOT == ${ROUTER_MAX_REBOOT})" "dialog-error"
					exit 1
				fi

				send_request "goformId=REBOOT_DEVICE" 0
				show_alert "mf823" "Reboot device..." "dialog-error" 20
				CURR_CON_C=0

				continue
			fi

			send_request "goformId=CONNECT_NETWORK" 5

			while check_host; do
				echo -en "\033[1m\033[42m\033[32m*\033[0m"

				if (( ${CURR_CON_C} != 0 )); then
					show_alert "mf823" "Connected!" "dialog-ok-apply"
				fi

				CURR_CON_C=0
				CURR_REBOOT_C=0

				sleep ${PING_PAUSE_TIME}
			done

			echo -en "\033[1m\033[41m\033[31mX\033[0m"
			show_alert "mf823" "Lost connection!" "dialog-error"
			send_request "goformId=DISCONNECT_NETWORK" 5

			#APN_INDEX_LIST=( ${APN_INDEX_LIST[1]} ${APN_INDEX_LIST[0]} )
			#send_request "goformId=APN_PROC_EX&apn_mode=manual&apn_action=set_default&set_default_flag=1&pdp_type=IP&index=${APN_INDEX_LIST[0]}" 0

			CURR_C=0
		fi
	done
else
	echo "mf823: Unknown command!"
	exit 1
fi
