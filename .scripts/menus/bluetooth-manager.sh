#!/bin/bash

# Konstanta global
ENABLED_COLOR="#9ece6a"
DISABLED_COLOR="#f7768e"
SERVICE_DISABLED_COLOR="#545c7e"

BLUETOOTH_ON_ICON="󰂯 "
BLUETOOTH_OFF_ICON="󰂲 "
BLUETOOTH_MANAGE_ICON="󰂱 "
BLUETOOTH_TRUST_ICON="󰃇 "
BLUETOOTH_SERVICE_ICON="󰂰 " 

# Fungsi untuk mendapatkan status Bluetooth
get_status() {
    local service_status bt_status
    service_status=$(systemctl is-active bluetooth.service)
    
    if [[ "$service_status" != "active" ]]; then
        echo "<span color=\"$SERVICE_DISABLED_COLOR\">$BLUETOOTH_OFF_ICON</span>"
        return
    fi

    bt_status=$(bluetoothctl show 2>/dev/null | grep -Po '(?<=Powered: )\w+' || echo "no")

    if [[ "$bt_status" == "yes" ]]; then
        echo "<span color=\"$ENABLED_COLOR\">$BLUETOOTH_ON_ICON</span>"
    else
        echo "<span color=\"$DISABLED_COLOR\">$BLUETOOTH_OFF_ICON</span>"
    fi
}

# Fungsi untuk mengelola perangkat Bluetooth
manage_bluetooth() {
    pkill rofi
    local devices
    devices=$(bluetoothctl devices | awk '{print $2" "$3" "$4" "$5}')

    [[ -z "$devices" ]] && notify-send "Bluetooth" "No devices found." && exit 0

    local chosen_device
    chosen_device=$(echo "$devices" | rofi -dmenu -i -p "Bluetooth Devices:")

    [[ -z "$chosen_device" ]] && exit 0

    local mac_address
    mac_address=$(echo "$chosen_device" | awk '{print $1}')

    local trusted_status
    trusted_status=$(bluetoothctl info "$mac_address" | grep -Po '(?<=Trusted: )\w+')
    local trust_option="Trust"
    [[ "$trusted_status" == "yes" ]] && trust_option="Untrust"

    local action
    action=$(echo -e "Connect\nDisconnect\nRemove\n$trust_option" | rofi -dmenu -p "Action for $chosen_device:" -theme ~/.config/rofi/menu.rasi)

    case "$action" in
        "Connect") bluetoothctl connect "$mac_address" && notify-send "Bluetooth" "Connected to $chosen_device." ;;
        "Disconnect") bluetoothctl disconnect "$mac_address" && notify-send "Bluetooth" "Disconnected from $chosen_device." ;;
        "Remove") bluetoothctl remove "$mac_address" && notify-send "Bluetooth" "$chosen_device removed." ;;
        "Trust") bluetoothctl trust "$mac_address" && notify-send "Bluetooth" "Device $chosen_device is now trusted." ;;
        "Untrust") bluetoothctl untrust "$mac_address" && notify-send "Bluetooth" "Device $chosen_device is now untrusted." ;;
    esac
}


# Menu utama
main_menu() {
    local service_status
    service_status=$(systemctl is-active bluetooth.service)

    if [[ "$service_status" == "active" ]]; then
        local bt_status
        bt_status=$(bluetoothctl show 2>/dev/null | grep -Po '(?<=Powered: )\w+' || echo "no")

        local bt_toggle="$BLUETOOTH_ON_ICON Enable Bluetooth"
        local bt_command="power on"

        [[ "$bt_status" == "yes" ]] && bt_toggle="$BLUETOOTH_OFF_ICON Disable Bluetooth" && bt_command="power off"

        local chosen_option
        chosen_option=$(echo -e "$bt_toggle\n$BLUETOOTH_MANAGE_ICON Manage Bluetooth\n$BLUETOOTH_SERVICE_ICON Disable Bluetooth Service" | rofi -dmenu -p "Bluetooth:" -theme ~/.config/rofi/menu.rasi)

        case "$chosen_option" in
            "$BLUETOOTH_ON_ICON Enable Bluetooth" | "$BLUETOOTH_OFF_ICON Disable Bluetooth")
                bluetoothctl <<< "$bt_command"
                notify-send "Bluetooth" "Bluetooth turned $(echo $bt_command | awk '{print $2}')."
                get_status ;;
            "$BLUETOOTH_MANAGE_ICON Manage Bluetooth")
                manage_bluetooth ;;
            "$BLUETOOTH_SERVICE_ICON Disable Bluetooth Service")
                pkexec systemctl disable --now bluetooth.service && notify-send "Bluetooth" "Bluetooth service disabled."
        esac
    else
        local chosen_option
        chosen_option=$(echo -e "$BLUETOOTH_SERVICE_ICON Enable Bluetooth Service" | rofi -dmenu -p "Bluetooth:" -theme ~/.config/rofi/menu.rasi)
        
        case "$chosen_option" in
            "$BLUETOOTH_SERVICE_ICON Enable Bluetooth Service")
                pkexec systemctl enable --now bluetooth.service && notify-send "Bluetooth" "Bluetooth service enabled." ;;
        esac
    fi
}

# Parsing argumen
case "$1" in
    --status) get_status ;;
    *) main_menu ;;
esac
