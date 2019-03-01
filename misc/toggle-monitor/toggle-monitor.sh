#!/bin/sh

CURR_RES="$(xdpyinfo | grep -E "dimensions:" | cut -d ' ' -f 7)"
if [[ "${CURR_RES}" == "1366x768" ]]; then
	nvidia-settings --assign CurrentMetaMode="VGA-0: 1366x768_60 +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}, HDMI-0: 1920x1080_60 +1366+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"
elif [[ "${CURR_RES}" == "3286x1080" ]]; then
	nvidia-settings --assign CurrentMetaMode="VGA-0: 1366x768_60 +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"
fi
