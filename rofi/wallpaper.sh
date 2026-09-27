#!/bin/bash
# Wallpaper picker for XFCE via rofi, with image previews.
# Thumbnails are generated once with imagemagick and cached in
# ~/.cache/wallpaper-thumbs (regenerated when a wallpaper file changes).
# Escape in rofi = cancel, nothing changes.
# The chosen wallpaper is applied with a smooth crossfade (wallpaper-fade.sh).
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
THUMB_DIR="$HOME/.cache/wallpaper-thumbs"
THUMB_SIZE="96x54"   # resolution of the cached preview images
ICON_DISPLAY="48"    # preview size in the menu, in pixels

mkdir -p "$THUMB_DIR"

[ -d "$WALLPAPER_DIR" ] || { notify-send "Wallpaper" "Folder not found: $WALLPAPER_DIR" 2>/dev/null; exit 1; }

mapfile -t WALLS < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | sort)

[ ${#WALLS[@]} -gt 0 ] || { notify-send "Wallpaper" "No images in $WALLPAPER_DIR" 2>/dev/null; exit 1; }

SELECTED=$(
    for wall in "${WALLS[@]}"; do
        name=$(basename "$wall")
        thumb="$THUMB_DIR/$name.png"
        if [ ! -f "$thumb" ] || [ "$wall" -nt "$thumb" ]; then
            convert "$wall" -resize "$THUMB_SIZE" "$thumb" 2>/dev/null || { printf '%s\n' "$name"; continue; }
        fi
        printf '%s\0icon\x1f%s\n' "$name" "$thumb"
    done | rofi -dmenu -show-icons -i -p "Wallpaper" \
          -theme-str "element-icon { size: ${ICON_DISPLAY}px; }"
)

[ -n "$SELECTED" ] || exit 0

TARGET="$WALLPAPER_DIR/$SELECTED"
[ -f "$TARGET" ] || exit 0

bash "$HOME/.config/rofi/wallpaper-fade.sh" "$TARGET"
