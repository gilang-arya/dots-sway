#!/bin/bash

choice=$(printf "󰍃\n\n\n" | rofi -dmenu -p "⏻  Powermenu: " -theme "~/.config/rofi/menu-block.rasi")

case "$choice" in
  "󰍃") pkill -KILL -u "$USER" ;;
  "") systemctl poweroff ;;
  "") systemctl reboot ;;
  "") swaylock -f ;;
esac
