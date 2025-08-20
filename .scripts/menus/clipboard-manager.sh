#!/bin/bash

session_type=$XDG_SESSION_TYPE

if [ "$session_type" == "wayland" ]; then
    cliphist list | rofi -dmenu -p " Cliboard: " -display-columns 2 | cliphist decode | wl-copy
fi
