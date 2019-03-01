#!/bin/sh

BINARY="/usr/bin/openssl"
PARAMS="dgst -binary"
[[ "${1}" != "" ]] && WORKDIR="${1}" || WORKDIR="$(pwd)"
MANIFEST_FILE="${WORKDIR}/META-INF/manifest.mf"
MOZILLA_SF_FILE="${WORKDIR}/META-INF/mozilla.sf"

if ! [ -d "${WORKDIR}"/META-INF ]; then
	echo "META-INF not found!" && exit 1
fi

echo -e "Manifest-Version: 1.0\n" > "${MANIFEST_FILE}"

find "${WORKDIR}" -type f | while read file; do

	if echo "${file}" | grep -oE "(*META-INF*|mozilla-addon_get_hash)" > /dev/null 2>&1; then
		continue
	fi

	FILENAME=$(echo ${file} | sed -e "s:$(pwd -P)\/::" | sed -e "s:\.\/::") && \
		echo "Name: ${FILENAME}" >> "${MANIFEST_FILE}"

	echo "Digest-Algorithms: MD5 SHA1 SHA256" >> "${MANIFEST_FILE}"

	MD5_SUM=$(${BINARY} ${PARAMS} -md5 "${file}" | base64) && \
		echo -e "MD5-Digest: ${MD5_SUM}" >> "${MANIFEST_FILE}"
	SHA1_SUM=$(${BINARY} ${PARAMS} -sha1 "${file}" | base64) && \
		echo -e "SHA1-Digest: ${SHA1_SUM}" >> "${MANIFEST_FILE}"
	SHA256_SUM=$(${BINARY} ${PARAMS} -sha256 "${file}" | base64) && \
		echo -e "SHA256-Digest: ${SHA256_SUM}\n" >> "${MANIFEST_FILE}"
done

cat <<EOF > "${MOZILLA_SF_FILE}"
Signature-Version: 1.0
MD5-Digest-Manifest: $(${BINARY} ${PARAMS} -md5 "${MANIFEST_FILE}" | base64)
SHA1-Digest-Manifest: $(${BINARY} ${PARAMS} -sha1 "${MANIFEST_FILE}" | base64)
SHA256-Digest-Manifest: $(${BINARY} ${PARAMS} -sha256 "${MANIFEST_FILE}" | base64)
EOF
