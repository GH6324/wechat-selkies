#!/bin/bash

# configure openbox dock mode for stalonetray
if [ ! -f /config/.config/openbox/rc.xml ] || grep -A20 "<dock>" /config/.config/openbox/rc.xml | grep -q "<noStrut>no</noStrut>"; then
    mkdir -p /config/.config/openbox
    [ ! -f /config/.config/openbox/rc.xml ] && cp /etc/xdg/openbox/rc.xml /config/.config/openbox/
    sed -i '/<dock>/,/<\/dock>/s/<noStrut>no<\/noStrut>/<noStrut>yes<\/noStrut>/' /config/.config/openbox/rc.xml
    openbox --reconfigure
fi

# generate openbox menu
mkdir -p /config/.config/openbox
cp /defaults/menu.xml /tmp/menu.xml

if ls "$HOME/Desktop/"*.desktop >/dev/null 2>&1; then
    for desktop_file in "$HOME/Desktop/"*.desktop; do
        name=$(grep -E "^Name=" "$desktop_file" | head -n 1 | cut -d "=" -f 2-)
        exec_cmd=$(grep -E "^Exec=" "$desktop_file" | head -n 1 | cut -d "=" -f 2-)
        icon=$(grep -E "^Icon=" "$desktop_file" | head -n 1 | cut -d "=" -f 2-)
        
        # strip %U, %u, %F, %f
        exec_cmd=$(echo "$exec_cmd" | sed 's/ %[fFuU]//g')
        
        # resolve icon path if it's just a name (not an absolute path)
        if [ -n "$icon" ] && [ "${icon#/}" = "$icon" ]; then
            icon_resolved=""
            # search in proot-apps icons (prefer 256x256)
            for size in 256x256 512x512 128x128 64x64 48x48 scalable; do
                found=$(find /config/proot-apps/*/usr/share/icons/hicolor/"$size"/apps/"$icon".* 2>/dev/null | head -n 1)
                if [ -n "$found" ]; then
                    icon_resolved="$found"
                    break
                fi
            done
            # fallback: search system icons
            if [ -z "$icon_resolved" ]; then
                found=$(find /usr/share/icons/hicolor/*/apps/"$icon".* 2>/dev/null | head -n 1)
                [ -n "$found" ] && icon_resolved="$found"
            fi
            [ -n "$icon_resolved" ] && icon="$icon_resolved"
        fi
        
        # handle missing icon
        [ -z "$icon" ] && icon="/usr/share/pixmaps/xterm-color_48x48.xpm"
        
        # escape XML entities
        exec_cmd=$(echo "$exec_cmd" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
        name=$(echo "$name" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')
        icon=$(echo "$icon" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')
        
        sed -i "/<menu id=\"root-menu\" label=\"MENU\">/a \\<item label=\"${name}\" icon=\"${icon}\"><action name=\"Execute\"><command>${exec_cmd}</command></action></item>" /tmp/menu.xml
    done
fi

if [ ! -f /config/.config/openbox/menu.xml ] || ! cmp /tmp/menu.xml /config/.config/openbox/menu.xml; then
    cp /tmp/menu.xml /config/.config/openbox/menu.xml
    openbox --reconfigure
fi

nohup stalonetray --dockapp-mode simple > /dev/null 2>&1 &

# start WeChat application in the background if exists and auto-start enabled
if [ "$AUTO_START_WECHAT" = "true" ]; then
    if [ -f /usr/bin/wechat ]; then nohup /usr/bin/wechat > /dev/null 2>&1 & fi
fi

# start QQ application in the background if exists and auto-start enabled
if [ "$AUTO_START_QQ" = "true" ]; then
    if [ -f /usr/bin/qq ]; then nohup /usr/bin/qq --no-sandbox > /dev/null 2>&1 & fi
fi

# !deprecated: start window switcher application in the background
# start window switcher application in the background
# nohup sleep 2 && python /scripts/window_switcher.py > /dev/null 2>&1 &
