# 2026-10: CPU widget fixed-width

- CPU percentage always shows two digits (01%, 09%, 12%) so widgets to its left never shift when usage drops below 10%.
- Module is now a small script (polybar/cpu.sh) reading /proc/stat; same look (grey glyph, white number), refreshes every 2s.
- First reading after restart is 00%, accurate from the second refresh.
