#!/bin/bash

# Konstanta global
ENABLED_COLOR="#9ece6a"
DISABLED_COLOR="#f7768e"
SIGNAL_ICONS=("󰤟 " "󰤢 " "󰤥 " "󰤨 ")
SECURED_SIGNAL_ICONS=("󰤡 " "󰤤 " "󰤧 " "󰤪 ")
WIFI_DISABLED_ICON="󰖪 "
WIFI_TOGGLE_ON_ICON="󱚽  "
WIFI_TOGGLE_OFF_ICON="󱛅  "
WIFI_MANAGE_ICON="󱓥  "

# Fungsi untuk mendapatkan status Wi-Fi
get_status() {
    local wifi_info
    wifi_info=$(nmcli -t -f "IN-USE,SIGNAL,SECURITY" device wifi list --rescan no | grep '^*')
    
    if [[ -n "$wifi_info" ]]; then
        IFS=: read -r in_use signal security <<< "$wifi_info"
        local signal_level=$((signal / 25))
        local signal_icon="${SIGNAL_ICONS[3]}"

        [[ "$signal_level" -lt ${#SIGNAL_ICONS[@]} ]] && signal_icon="${SIGNAL_ICONS[$signal_level]}"
        [[ "$security" =~ WPA|WEP ]] && signal_icon="${SECURED_SIGNAL_ICONS[$signal_level]}"

        echo "<span color=\"$ENABLED_COLOR\">$signal_icon</span>"
    else
        echo "<span color=\"$DISABLED_COLOR\">$WIFI_DISABLED_ICON</span>"
    fi
}

# Fungsi untuk mengelola Wi-Fi
manage_wifi() {
    pkill rofi
    nmcli device wifi rescan
    notify-send "Scanning Wi-Fi networks..."
    local chosen_network=$(nmcli -t -f SSID device wifi list | awk 'NF' | sort | rofi -dmenu -i -p "Wi-Fi SSID: ")
    
    [[ -z "$chosen_network" ]] && notify-send "Wi-Fi Management" "No network selected." && exit 0
    
    local action=$(echo -e "Connect\nDisconnect\nForget" | rofi -dmenu -p "Action for $chosen_network:"  -theme ~/.config/rofi/menu.rasi)
    case "$action" in
        "Connect") connect_to_wifi "$chosen_network" ;;
        "Disconnect") nmcli connection down "$chosen_network" && notify-send "Wi-Fi Disconnected" "Disconnected from $chosen_network" ;;
        "Forget") nmcli connection delete "$chosen_network" && notify-send "Wi-Fi Forgotten" "Removed $chosen_network from saved networks." ;;
    esac
}

# Fungsi untuk koneksi Wi-Fi
connect_to_wifi() {
    local ssid="$1"

    if nmcli connection show | grep -q "$ssid"; then
        nmcli connection up "$ssid" && notify-send "Wi-Fi Connected" "Connected to $ssid."
    else
        while true; do
            wifi_password=$(rofi -dmenu -p "Password: " -password -theme ~/.config/rofi/input.rasi)
            [[ -z "$wifi_password" ]] && notify-send "Wi-Fi Connection" "No password entered." && exit 0

            nmcli device wifi connect "$ssid" password "$wifi_password"

            if nmcli connection show --active | grep -q "$ssid"; then
                notify-send "Wi-Fi Connected" "Successfully connected to $ssid."
                break
            else
                nmcli connection delete "$ssid"
                notify-send "Wi-Fi Connection Failed" "Wrong password for $ssid. Try again."
            fi
        done
    fi
}

# Menu utama
main_menu() {
    local wifi_status=$(nmcli -t -f WIFI g)
    local wifi_toggle="$WIFI_TOGGLE_ON_ICON Enable Wi-Fi"
    local wifi_command="on"
    
    [[ "$wifi_status" == "enabled" ]] && wifi_toggle="$WIFI_TOGGLE_OFF_ICON Disable Wi-Fi" && wifi_command="off"
    
    local chosen_option=$(echo -e "$wifi_toggle\n$WIFI_MANAGE_ICON Manage Wi-Fi" | rofi -dmenu -p "Network:" -theme ~/.config/rofi/menu.rasi)
    
    case "$chosen_option" in
        "$WIFI_TOGGLE_ON_ICON Enable Wi-Fi" | "$WIFI_TOGGLE_OFF_ICON Disable Wi-Fi")
            nmcli radio wifi "$wifi_command" && notify-send "Wi-Fi Status" "Wi-Fi turned $wifi_command." ;;
        "$WIFI_MANAGE_ICON Manage Wi-Fi")
            manage_wifi ;;
    esac
}

# Parsing argumen
case "$1" in
    --status) get_status ;;
    *) main_menu ;;
esac
