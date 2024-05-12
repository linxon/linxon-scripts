#!/bin/sh
#########################
# Usage:
# 	~$ ROUTER_ADDR='192.168.1.1' ./send_alert.sh -c -n '+79xxxxxxxxx' -m 'hello world!'
#########################

CURL_EXEC="$(which curl)"
CURL_TIMEOUT=5
TIMEZONE="UTC-3"

_ROUTER_ADDR=${ROUTER_ADDR:-"192.168.0.1"}
_CURL_URI_HANDLER="http://${_ROUTER_ADDR}/goform/goform_set_cmd_process"
_PHONE_NUM=
_MESSAGE=
_CURR_ACTION=0

send_request() {
	local default_args="isTest=false&notCallback=true"
	local other_args="${1}"

	${CURL_EXEC} --connect-timeout ${CURL_TIMEOUT} --max-time $((${CURL_TIMEOUT}+10)) \
		-H "X-Requested-With:XMLHttpRequest" \
		-H "Referer:http://${_ROUTER_ADDR}/index.html" \
		--data "${default_args}&${other_args}" \
		-X POST ${_CURL_URI_HANDLER} --compressed  2> /dev/null | jq -r ".result"
}

send_sms() {
	local req_string="goformId=SEND_SMS&ID=-1&encode_type=UNICODE"
	local phone_num="${1}"
	local message="${2}"

	req_string="${req_string}&Number=$(printf %s ${phone_num} | jq -sRr @uri)"
	req_string="${req_string}&MessageBody=$(printf "${message}" | iconv -f UTF-8 -t UCS-2BE | xxd -p | tr -d '\n')"
	req_string="${req_string}&sms_time=$(TZ=":$TIMEZONE" date +'%y;%m;%d;%H;%M;%S;')"

	send_request "${req_string}"
}

show_help() {
	echo "Usage: $(basename ${0}) [OPTION...]"
	echo -e "  -i \t\tIP address of the router. Example: -i 192.168.0.1"
	echo -e "  -c \t\tCreate sms. Example: -c -n +1234567890 -m 'message'"
	echo -e "  -n \t\tPhone number"
	echo -e "  -m \t\tMessage"
}

while getopts "hci:n:m:" opt; do
	case ${opt} in
		h)
			show_help
			exit 1
			;;
		i)
			_ROUTER_ADDR="${OPTARG}"
			_CURL_URI_HANDLER="http://${_ROUTER_ADDR}/goform/goform_set_cmd_process"
			;;
		n)
			_PHONE_NUM="${OPTARG}"
			;;
		m)
			_MESSAGE="${OPTARG}"
			;;
		c)
			# Create sms
			_CURR_ACTION=1
			;;
		:)
			echo "Option -${OPTARG} requires an argument."
			exit 1
			;;
		?)
			echo "Invalid option: -${OPTARG}."
			show_help
			exit 1
			;;	  
	esac
done

if [ -z $_PHONE_NUM ]; then
	echo "Error: phone number is required!"
	exit 1
fi

if [ -z $_MESSAGE ]; then
	echo "Error: message is required!"
	exit 1
fi

case ${_CURR_ACTION} in
	1) # Create sms
		send_sms ${_PHONE_NUM} "${_MESSAGE}"
		;;
	# ...
esac


exit $?
