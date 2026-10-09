-- conky-glance: Material You "At a Glance" desktop widget
-- Transparent variant: white text directly on the wallpaper.
-- Includes a cava music spectrum between artist and progress bar.

local cairo = require('cairo')
local cairo_xlib = require('cairo_xlib')

local SLANT_NORMAL = 0
local WEIGHT_NORMAL = 0
local WEIGHT_BOLD  = 1

local C = {
    surface   = { 0x1C/255, 0x1B/255, 0x1F/255, 1.0 },
    surface2  = { 0x2A/255, 0x29/255, 0x30/255, 1.0 },
    text      = { 0xE6/255, 0xE1/255, 0xE5/255, 1.0 },
    accent    = { 0xA4/255, 0xC3/255, 0xFF/255, 1.0 },
    secondary = { 0xC3/255, 0xC7/255, 0xCF/255, 1.0 },
    muted     = { 0xE6/255, 0xE1/255, 0xE5/255, 0.75 },
    track     = { 0x48/255, 0x46/255, 0x50/255, 1.0 },
}

local W = 320
local H = 480
local PAD = 28
local R = 16

local buttons = {}

-- ---------- cava -----------------------------------------------------------

local CAVA_FILE = os.getenv('HOME') .. '/.cache/conky-glance/cava.raw'
local CAVA_BARS = 24

local function cava_read()
    local f = io.open(CAVA_FILE, 'r')
    if not f then return nil end
    f:seek('set', 0)
    local s = f:read('*a') or ''
    f:close()
    s = s:gsub('[;\r\n]+$', '')
    if s == '' then return nil end
    local vals = {}
    for v in s:gmatch('[^;]+') do
        vals[#vals + 1] = tonumber(v) or 0
    end
    if #vals == 0 then return nil end
    return vals
end

-- ---------- helpers ---------------------------------------------------------

local function rounded(cr, x, y, w, h, r)
    if h <= 0 or w <= 0 then return end
    if r > h / 2 then r = h / 2 end
    if r > w / 2 then r = w / 2 end
    cairo_new_sub_path(cr)
    cairo_arc(cr, x + w - r, y + r,         r, -math.pi/2, 0)
    cairo_arc(cr, x + w - r, y + h - r,     r, 0, math.pi/2)
    cairo_arc(cr, x + r,     y + h - r,     r, math.pi/2, math.pi)
    cairo_arc(cr, x + r,     y + r,         r, math.pi, 3*math.pi/2)
    cairo_close_path(cr)
end

local function set_color(cr, c)
    cairo_set_source_rgba(cr, c[1], c[2], c[3], c[4] or 1)
end

local function cava_draw(cr, x, y, w, h)
    local vals = cava_read()
    if not vals then return end
    local n = math.min(#vals, CAVA_BARS)
    if n == 0 then return end
    local gap = 2
    local bw = (w - gap * (n - 1)) / n
    for i = 1, n do
        local v = math.max(0, math.min(100, vals[i] or 0))
        local bh = math.max(2, (v / 100) * h)
        local bx = x + (i - 1) * (bw + gap)
        rounded(cr, bx, y + h - bh, bw, bh, 1.5)
        if v > 60 then
            set_color(cr, C.accent)
        else
            set_color(cr, C.secondary)
        end
        cairo_fill(cr)
    end
end

local function draw_button(cr, kind, cx, cy, col)
    set_color(cr, col)
    if kind == 'play' then
        cairo_move_to(cr, cx - 5, cy - 8)
        cairo_line_to(cr, cx - 5, cy + 8)
        cairo_line_to(cr, cx + 9, cy)
        cairo_close_path(cr)
        cairo_fill(cr)
    elseif kind == 'pause' then
        cairo_rectangle(cr, cx - 7, cy - 8, 5, 16)
        cairo_fill(cr)
        cairo_rectangle(cr, cx + 2, cy - 8, 5, 16)
        cairo_fill(cr)
    elseif kind == 'prev' then
        cairo_move_to(cr, cx + 7, cy - 8)
        cairo_line_to(cr, cx + 7, cy + 8)
        cairo_line_to(cr, cx - 6, cy)
        cairo_close_path(cr)
        cairo_fill(cr)
        cairo_rectangle(cr, cx - 9, cy - 8, 3, 16)
        cairo_fill(cr)
    elseif kind == 'next' then
        cairo_move_to(cr, cx - 7, cy - 8)
        cairo_line_to(cr, cx - 7, cy + 8)
        cairo_line_to(cr, cx + 6, cy)
        cairo_close_path(cr)
        cairo_fill(cr)
        cairo_rectangle(cr, cx + 6, cy - 8, 3, 16)
        cairo_fill(cr)
    end
end

local function exec(cmd)
    local f = io.popen(cmd, 'r')
    if not f then return nil end
    local s = f:read('*a')
    f:close()
    if s then s = s:gsub('[%s%c]+$', '') end
    return s
end

local function text_extents(cr, txt, font, size)
    cairo_select_font_face(cr, font, SLANT_NORMAL, WEIGHT_NORMAL)
    cairo_set_font_size(cr, size)
    local te = cairo_text_extents_t:create()
    cairo_text_extents(cr, txt, te)
    local w = te.x_advance
    te = nil
    return w
end

local function text_ink(cr, txt, font, size)
    cairo_select_font_face(cr, font, SLANT_NORMAL, WEIGHT_NORMAL)
    cairo_set_font_size(cr, size)
    local te = cairo_text_extents_t:create()
    cairo_text_extents(cr, txt, te)
    local w, xb = te.width, te.x_bearing
    te = nil
    return w, xb
end

local function text_ink_box(cr, txt, font, size)
    cairo_select_font_face(cr, font, SLANT_NORMAL, WEIGHT_NORMAL)
    cairo_set_font_size(cr, size)
    local te = cairo_text_extents_t:create()
    cairo_text_extents(cr, txt, te)
    local xb, yb, w, h = te.x_bearing, te.y_bearing, te.width, te.height
    te = nil
    return xb, yb, w, h
end

local function pick_font(txt, base)
    if txt and txt:find('[\128-\255]') then
        return 'Noto Sans CJK TC'
    end
    return base
end

local function draw_text(cr, txt, x, y, font, size, col, weight, align, maxw)
    cairo_select_font_face(cr, font, SLANT_NORMAL, weight or WEIGHT_NORMAL)
    cairo_set_font_size(cr, size)
    local w = text_extents(cr, txt, font, size)
    if maxw and w > maxw then
        local fit = txt
        while #fit > 1 and text_extents(cr, fit .. '\u{2026}', 'Noto Sans', size) > maxw do
            fit = fit:sub(1, -2)
        end
        txt = fit .. '\u{2026}'
        w = text_extents(cr, txt, font, size)
    end
    local px = x
    if align == 'center' then px = x - w/2 end
    if align == 'right'  then px = x - w   end
    set_color(cr, col)
    cairo_move_to(cr, px, y)
    cairo_show_text(cr, txt)
    cairo_new_path(cr)
    return w
end

-- ---------- data ------------------------------------------------------------

local weather_cache = { time = 0, temp = nil, desc = nil }

local function get_weather()
    local now = os.time()
    if now - weather_cache.time < (weather_cache.temp and 60 or 10) then
        return weather_cache.temp, weather_cache.desc
    end
    weather_cache.time = now
    local out = exec('bash ~/.config/conky/weather.sh 2>/dev/null')
    weather_cache.temp, weather_cache.desc = nil, nil
    if out and out ~= '' then
        weather_cache.temp = out:match('^([^|]+)|')
        weather_cache.desc = out:match('|([^|]+)$')
    end
    return weather_cache.temp, weather_cache.desc
end

local function weather_icon(desc)
    local d = (desc or ''):lower()
    if d:find('rain')  or d:find('drizzle') or d:find('shower') then return '\u{f73d}' end
    if d:find('snow')  or d:find('sleet')   or d:find('blizzard') then return '\u{f2dc}' end
    if d:find('thunder') or d:find('storm') then return '\u{f0e7}' end
    if d:find('fog')   or d:find('mist')    or d:find('haze') then return '\u{f75f}' end
    if d:find('clear') or d:find('sunny') then return '\u{f185}' end
    return '\u{f0c2}'
end

local spotify_cache = { time = 0, data = nil }

local function get_spotify()
    local now = os.time()
    if now - spotify_cache.time < 1 then
        return spotify_cache.data
    end
    spotify_cache.time = now
    local out = exec('bash ~/.config/conky/spotify-status.sh 2>/dev/null')
    spotify_cache.data = nil
    if out and out ~= '' and not out:match('^NONE') then
        local status, title, artist, pos, len =
            out:match('^(%a+)|([^|]*)|([^|]*)|([%d%.]+)|(%d+)')
        if status then
            spotify_cache.data = {
                status = status,
                title  = title,
                artist = artist,
                pos    = tonumber(pos) or 0,
                len    = tonumber(len) or 0,
            }
        end
    end
    return spotify_cache.data
end

-- ---------- layout constants -----------------------------------------------

local CLOCK_Y    = 108
local DIV1_Y     = 170
local WX_Y       = 200
local DIV2_Y     = 228
local SP_TITLE_Y = 268
local SP_ART_Y   = 296
local CAVA_Y     = 316
local CAVA_H     = 28
local PROG_Y     = 354
local BTN_Y      = 416
local BTN_R      = 20
local BTN_SEP    = 76

-- ---------- main draw ------------------------------------------------------

function conky_main()
    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(
        conky_window.display,
        conky_window.drawable,
        conky_window.visual,
        conky_window.width,
        conky_window.height)
    if cs == nil then return end
    local cr = cairo_create(cs)
    if cr == nil then cairo_surface_destroy(cs) return end

    buttons = {}

    local months = { 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December' }
    local days = { 'Sunday', 'Monday', 'Tuesday', 'Wednesday',
        'Thursday', 'Friday', 'Saturday' }
    local date_s = days[os.date('*t').wday] .. ', '
        .. months[os.date('*t').month] .. ' ' .. os.date('%d')

    draw_text(cr, date_s, W/2, CLOCK_Y, 'Noto Sans', 28, C.text,
        WEIGHT_NORMAL, 'center')

    set_color(cr, { 1, 1, 1, 0.35 })
    cairo_set_line_width(cr, 1)
    cairo_move_to(cr, PAD, DIV1_Y)
    cairo_line_to(cr, W - PAD, DIV1_Y)
    cairo_stroke(cr)

    -- weather (plain centered text; removed nerd-font icon that showed as [])
    local temp, desc = get_weather()
    if temp then
        local label = (temp or '') .. '  ' .. (desc or '')
        draw_text(cr, label, W/2, WX_Y, pick_font(label, 'Noto Sans'), 14, C.secondary, nil, 'center')
    else
        draw_text(cr, 'weather unavailable', W/2, WX_Y, 'Noto Sans', 13, C.muted, nil, 'center')
    end

    local sp = get_spotify()
    if sp then
        draw_text(cr, sp.title, W/2, SP_TITLE_Y, pick_font(sp.title, 'Noto Sans'), 16, C.text, nil, 'center', W - 2*PAD)
        draw_text(cr, sp.artist, W/2, SP_ART_Y, pick_font(sp.artist, 'Noto Sans'), 13, C.muted, nil, 'center', W - 2*PAD)

        -- cava spectrum between artist and progress bar
        if sp.status == 'Playing' then
            cava_draw(cr, PAD + 4, CAVA_Y, W - 2*PAD - 8, CAVA_H)
        end

        local bar_x, bar_w, bar_h = PAD + 4, W - 2*PAD - 8, 4
        rounded(cr, bar_x, PROG_Y, bar_w, bar_h, bar_h/2)
        set_color(cr, { 1, 1, 1, 0.25 })
        cairo_fill(cr)
        local frac = (sp.len > 0) and (sp.pos / sp.len) or 0
        frac = math.max(0, math.min(1, frac))
        if frac > 0.01 then
            rounded(cr, bar_x, PROG_Y, math.max(bar_h, bar_w * frac), bar_h, bar_h/2)
            set_color(cr, C.accent)
            cairo_fill(cr)
        end

        local function fmt(s)
            s = math.floor(tonumber(s) or 0)
            return string.format('%d:%02d', math.floor(s/60), s % 60)
        end
        draw_text(cr, fmt(sp.pos), bar_x, PROG_Y + 22, 'Noto Sans', 11, C.muted, nil, 'left')
        if sp.len > 0 then
            draw_text(cr, fmt(sp.len), bar_x + bar_w, PROG_Y + 22, 'Noto Sans', 11, C.muted, nil, 'right')
        end

        local kinds = {
            'prev',
            (sp.status == 'Playing' and 'pause' or 'play'),
            'next',
        }
        local actions = { 'previous', 'play-pause', 'next' }
        local cx = W/2 - BTN_SEP
        for i = 1, 3 do
            local bx = cx + (i - 1) * BTN_SEP
            if buttons.hover == i then
                rounded(cr, bx - BTN_R, BTN_Y - BTN_R, 2*BTN_R, 2*BTN_R, BTN_R)
                set_color(cr, { 1, 1, 1, 0.25 })
                cairo_fill(cr)
            end
            local icol = (buttons.hover == i) and C.text or C.secondary
            draw_button(cr, kinds[i], bx, BTN_Y, icol)
            buttons[i] = { x = bx - BTN_R, y = BTN_Y - BTN_R, w = 2*BTN_R, h = 2*BTN_R, action = actions[i] }
        end
    else
        draw_text(cr, '\u{f001}', W/2, SP_TITLE_Y, 'Symbols Nerd Font', 20, C.muted, nil, 'center')
        draw_text(cr, 'Nothing playing', W/2, SP_ART_Y + 6, 'Noto Sans', 13, C.muted, nil, 'center')
    end

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end

-- ---------- mouse ----------------------------------------------------------

local function in_rect(px, py, r)
    return r and px >= r.x and px <= r.x + r.w and py >= r.y and py <= r.y + r.h
end

function conky_on_mouse(event)
    if event.type == 'button_down' and event.button == 'left' then
        for i, r in ipairs(buttons) do
            if in_rect(event.x, event.y, r) then
                os.execute('playerctl -p spotify ' .. r.action .. ' >/dev/null 2>&1 &')
                return true
            end
        end
    elseif event.type == 'mouse_move' then
        local h = 0
        for i, r in ipairs(buttons) do
            if in_rect(event.x, event.y, r) then h = i; break end
        end
        if h ~= buttons.hover then
            buttons.hover = h
            return true
        end
    end
    return false
end
