local mp = require 'mp'
local assdraw = require 'mp.assdraw'

local overlay = mp.create_osd_overlay('ass-events')
local playlist = {}
local current_index = 0
local selected_index = 0
local visible = false
local window_size = 7
local redraw_timer = nil

local function log(msg)
    mp.msg.info('[playlist-osd] ' .. msg)
end

local function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

local function update_playlist()
    playlist = mp.get_property_native('playlist') or {}
    current_index = mp.get_property_number('playlist-pos', 0)
    if selected_index >= #playlist then
        selected_index = math.max(#playlist - 1, 0)
    end
end

local function render()
    if not visible then
        overlay:remove()
        return
    end

    update_playlist()

    if #playlist == 0 then
        overlay.data = '{\\fs28}{\\b1}Nenhum item na playlist{\\b0}'
        overlay.z = 10
        overlay:update()
        return
    end

    local half_window = math.floor(window_size / 2)
    local start_i = clamp(selected_index - half_window, 0, math.max(#playlist - window_size, 0))
    local end_i = math.min(start_i + window_size - 1, #playlist - 1)

    local ass = assdraw.ass_new()
    ass:new_event()
    ass:pos(60, 80)
    ass:append(string.format('{\\fs32}{\\b1}Canais (%d/%d){\\b0}\\N', selected_index + 1, #playlist))
    ass:append('{\\fs26}')

    for i = start_i, end_i do
        local entry = playlist[i + 1]
        local title = entry.title or entry.filename or ('Item ' .. (i + 1))
        local prefix = '   '

        if i == current_index and i == selected_index then
            prefix = '{\\c&H00FF00&}➤ '
        elseif i == current_index then
            prefix = '{\\c&H00FF00&}• '
        elseif i == selected_index then
            prefix = '{\\c&HFFCC00&}→ '
        end

        ass:append(string.format('%s{\\c&HFFFFFF&}%s\\N', prefix, title))
    end

    overlay.data = ass.text
    overlay.z = 10
    overlay:update()
end

local function schedule_redraw()
    if redraw_timer then
        redraw_timer:kill()
    end
    redraw_timer = mp.add_timeout(0.01, render)
end

local function show()
    visible = true
    update_playlist()
    selected_index = current_index
    render()
end

local function hide()
    visible = false
    overlay:remove()
end

local function toggle()
    if visible then
        hide()
    else
        show()
    end
end

local function move_selection(delta)
    if #playlist == 0 then
        return
    end
    selected_index = clamp(selected_index + delta, 0, #playlist - 1)
    schedule_redraw()
end

local function play_selected()
    if #playlist == 0 then
        return
    end
    mp.set_property_number('playlist-pos', selected_index)
    current_index = selected_index
    schedule_redraw()
end

mp.register_script_message('arktv-overlay', function(action)
    if action == 'toggle-playlist' then
        toggle()
    elseif action == 'show-playlist' then
        show()
    elseif action == 'hide-playlist' then
        hide()
    end
end)

mp.register_script_message('arktv-navigation', function(direction)
    if not visible then
        return
    end

    if direction == 'up' then
        move_selection(-1)
    elseif direction == 'down' then
        move_selection(1)
    elseif direction == 'left' then
        move_selection(-window_size)
    elseif direction == 'right' then
        move_selection(window_size)
    elseif direction == 'confirm' then
        play_selected()
        hide()
    elseif direction == 'back' then
        hide()
    end
end)

mp.observe_property('playlist-count', 'number', function()
    if visible then
        schedule_redraw()
    end
end)

mp.observe_property('playlist-pos', 'number', function(_, value)
    current_index = value or 0
    if visible then
        schedule_redraw()
    end
end)

mp.register_event('end-file', function()
    if visible then
        schedule_redraw()
    end
end)

mp.register_event('shutdown', function()
    overlay:remove()
end)

log('Playlist OSD carregado')
