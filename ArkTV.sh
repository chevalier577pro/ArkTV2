#!/bin/bash

#-----------------------#
# ArkTV by AeolusUX     #
#-----------------------#

# --- Root privilege check ---
if [ "$(id -u)" -ne 0 ]; then
    exec sudo -- "$0" "$@"
fi

set -euo pipefail

# --- Global Variables ---
CURR_TTY="/dev/tty1"
MPV_SOCKET="/tmp/mpvsocket"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
JSON_URL="https://raw.githubusercontent.com/AeolusUX/ArkTV/refs/heads/main/channels/channels.json"
JSON_FILE="/tmp/channels.json"  # Temporary file for channels list

# --- Functions ---

ExitMenu() {
    rm -f "$JSON_FILE"
    printf "\033c" > "$CURR_TTY"
    printf "\e[?25h" > "$CURR_TTY" # Show cursor again
    if [[ ! -e "/dev/input/by-path/platform-odroidgo2-joypad-event-joystick" ]]; then
        setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz
    fi
    pkill -f "gptokeyb -1 arktv.sh" || true
    exit 0
}

# Simple internet connectivity check function
check_internet() {
    if ! curl -s --connect-timeout 5 --max-time 5 "http://1.1.1.1" >/dev/null 2>&1; then
        dialog --msgbox "No internet connection detected.\nPlease check your network and try again." 6 50 > "$CURR_TTY"
        return 1
    fi
    return 0
}

check_and_install_dependencies() {
    # Check internet FIRST, before trying to install anything
    if ! check_internet; then
        ExitMenu
    fi

    local missing=()
    for cmd in mpv dialog jq curl; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        if ! command -v apt >/dev/null; then
            dialog --msgbox "Error: apt not found. Please install ${missing[*]} manually." 8 60 > "$CURR_TTY"
            ExitMenu
        fi
        dialog --infobox "Installing missing dependencies: ${missing[*]}..." 3 60 > "$CURR_TTY"
        if ! apt update >/dev/null 2>&1 || ! apt install -y "${missing[@]}" >/dev/null 2>&1; then
            dialog --msgbox "Error: Failed to install ${missing[*]}.\nTry manually: sudo apt update && sudo apt install -y ${missing[*]}" 8 60 > "$CURR_TTY"
            ExitMenu
        fi
    fi
}

fetch_json_file() {
    if ! curl -s -o "$JSON_FILE" "$JSON_URL"; then
        dialog --msgbox "Error: Failed to download channel list." 6 50 > "$CURR_TTY"
        ExitMenu
    fi
}

check_json_file() {
    fetch_json_file
    if [[ ! -f "$JSON_FILE" ]]; then
        dialog --msgbox "Error: Channel list file missing." 6 50 > "$CURR_TTY"
        ExitMenu
    fi
    if ! jq -e '.[] | select(.name and .url) | length' "$JSON_FILE" >/dev/null; then
        dialog --msgbox "Error: Invalid JSON format in channel list." 6 50 > "$CURR_TTY"
        ExitMenu
    fi
}

load_channels() {
    declare -gA CHANNELS
    CHANNEL_MENU_OPTIONS=()
    local index=1
    while IFS= read -r name && IFS= read -r url; do
        CHANNEL_MENU_OPTIONS+=("$index" "$name")
        CHANNELS["$index"]="$url"
        ((index++))
    done < <(jq -r '.[] | .name, .url' "$JSON_FILE")

    CHANNEL_MENU_OPTIONS+=("0" "Exit")
}

play_channel() {
    local idx="$1"
    local url="${CHANNELS[$idx]}"
    local name
    name=$(jq -r --argjson i "$((idx-1))" '.[$i].name' "$JSON_FILE")

    dialog --infobox "Starting channel: $name..." 3 50 > "$CURR_TTY"
    sleep 1

    systemctl start mpv.service >/dev/null 2>&1 || true

    /usr/bin/mpv --fullscreen --geometry=640x480 --hwdec=auto --vo=drm --input-ipc-server="$MPV_SOCKET" "$url" >/dev/null 2>&1

    systemctl stop mpv.service >/dev/null 2>&1 || true

    ExitMenu
}

show_channel_menu() {
    check_and_install_dependencies
    check_json_file

    load_channels

    local choice
    choice=$(dialog --output-fd 1 \
        --backtitle "ArkTV by AeolusUX v1.0" \
        --title "Select Channel" \
        --menu "Choose a channel to play:" 15 60 10 \
        "${CHANNEL_MENU_OPTIONS[@]}" \
        2>"$CURR_TTY")

    if [[ -z "$choice" || "$choice" == "0" ]]; then
        ExitMenu
    fi

    play_channel "$choice"
}

# --- Main execution ---

trap ExitMenu EXIT SIGINT SIGTERM

printf "\033c" > "$CURR_TTY"
printf "\e[?25l" > "$CURR_TTY" # Hide cursor

export TERM=linux
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

if [[ ! -e "/dev/input/by-path/platform-odroidgo2-joypad-event-joystick" ]]; then
    setfont /usr/share/consolefonts/Lat7-TerminusBold22x11.psf.gz
else
    setfont /usr/share/consolefonts/Lat7-Terminus16.psf
fi

# Joystick support setup
if command -v /opt/inttools/gptokeyb &>/dev/null; then
    [[ -e /dev/uinput ]] && chmod 666 /dev/uinput 2>/dev/null || true
    export SDL_GAMECONTROLLERCONFIG_FILE="/opt/inttools/gamecontrollerdb.txt"
    pkill -f "gptokeyb -1 arktv.sh" || true
    /opt/inttools/gptokeyb -1 "ArkTV.sh" -c "/opt/inttools/keys.gptk" >/dev/null 2>&1 &
else
    dialog --infobox "gptokeyb not found. Joystick control disabled." 5 65 > "$CURR_TTY"
    sleep 2
fi

show_channel_menu