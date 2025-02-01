#!/bin/bash

SDDM_CURRENT_BG="$(grep background "/usr/share/sddm/themes/boret/theme.conf" |cut -d"=" -f2)"
export SDDM_CURRENT_BG
notify-send "Current SDDM background: $SDDM_CURRENT_BG"
