#!/usr/bin/env bash

TARGET="$1"
REPO_PATH=$(portageq get_repo_path / gentoo)

sed \
	-e "s/^#.*//g;/^$/d;s/^.*[=|<|>|~]//;s/^\(.*\):.*/\1/;s/-[0-9].*$//" \
	"${REPO_PATH}/profiles/package.mask" \
	| sort -u | while read -r x

do
	[[ ! -d "${TARGET}" || -z "${TARGET}" ]] && {
		echo "Error: target is not found!"
		exit 1
	}

	grep --color=always -r "$x" "${TARGET}" && echo -e ">>> Found: $x\n"
done
