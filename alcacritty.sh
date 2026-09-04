#!/bin/sh
set -e

config_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/alacritty"
theme=$(ls ${config_dir}/themes | grep '\.yaml$' | sed 's/\.yaml$//' | rofi -dmenu)
ed  "${config_dir}/alacritty.yml" <<- EOF
    /  - '.*\/alacritty\/themes\/.*[.]yaml'
    s/[^/]*[.]yaml'$/${theme}.yaml'/
    wq
EOF