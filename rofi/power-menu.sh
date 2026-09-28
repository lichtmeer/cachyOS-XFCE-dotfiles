#!/bin/bash
# rofi script-mode power menu (Android-style buttons)
# rofi calls this script; the selected entry arrives as $1.

main_list() {
    printf 'Log out\0icon\x1fsystem-log-out\n'
    printf 'Restart\0icon\x1fsystem-reboot\n'
    printf 'Shutdown\0icon\x1fsystem-shutdown\n'
    printf 'Suspend\0icon\x1fsystem-suspend\n'
    printf 'Switch User\0icon\x1fsystem-users\n'
}

if [ -z "$1" ]; then
    main_list
    exit 0
fi

case "$1" in
    "Log out")
        xfce4-session-logout --logout ;;
    "Restart")
        printf '\0message\x1fRestart now?\n'
        printf 'Cancel\0icon\x1fwindow-close\n'
        printf 'Yes, restart\0icon\x1fsystem-reboot\n'
        ;;
    "Yes, restart")
        xfce4-session-logout --reboot ;;
    "Shutdown")
        printf '\0message\x1fShut down now?\n'
        printf 'Cancel\0icon\x1fwindow-close\n'
        printf 'Yes, shut down\0icon\x1fsystem-shutdown\n'
        ;;
    "Yes, shut down")
        xfce4-session-logout --halt ;;
    "Suspend")
        xfce4-session-logout --suspend ;;
    "Switch User")
        dm-tool switch-to-greeter 2>/dev/null || true ;;
    "Cancel")
        main_list ;;
esac
