local mp = require 'mp'
local assdraw = require 'mp.assdraw'
local utils = require 'mp.utils'

local overlay = mp.create_osd_overlay('ass-events')
local hide_timer = nil
local visible = false
local default_duration = 4
local state_path = os.getenv('ARKTV_STATE_FILE') or (os.getenv('HOME') .. '/.local/share/arktv/state.json')

local function log(msg)
    mp.msg.info('[status-osd] ' .. msg)
end

local function read_state()
    local content = utils.read_file(state_path)
    if not content or content == '' then
        return {}
    end

    local ok, data = pcall(utils.parse_json, content)
    if not ok or type(data) ~= 'table' then
        return {}
    end

    return data
end

local function remove_overlay()
    overlay:remove()
    visible = false
end

local function format_status_text()
    local ass = assdraw.ass_new()
    local media_title = mp.get_property('media-title') or 'Canal desconhecido'
    local playback_time = mp.get_property_osd('playback-time') or '00:00'
    local duration = mp.get_property_osd('duration') or '--:--'
    local volume = mp.get_property_number('volume', 0)
    local time_str = os.date('%H:%M')
    local state = read_state()
    local shuffle_state = state.shuffle and 'Ativo' or 'Inativo'

    ass:new_event()
    ass:pos(80, 80)
    ass:append('{\\fs30}{\\b1}ArkTV Status{\\b0}\\N')
    ass:append(string.format('{\\fs26}%s\\N', media_title))
    ass:append(string.format('{\\fs22}Tempo: %s / %s\\N', playback_time, duration))
    ass:append(string.format('{\\fs22}Volume: %.0f%%%%\\N', volume))
    ass:append(string.format('{\\fs22}Shuffle: %s\\N', shuffle_state))
    ass:append(string.format('{\\fs18}Hora: %s\\N', time_str))

    if state.last_command then
        ass:append(string.format('{\\fs18}Última ação: %s\\N', state.last_command))
    end

    return ass.text
end

local function show_overlay(duration)
    overlay.data = format_status_text()
    overlay.z = 20
    overlay:update()
    visible = true

    if hide_timer then
        hide_timer:kill()
    end

    hide_timer = mp.add_timeout(duration or default_duration, function()
        remove_overlay()
    end)
end

local function reload_playlist()
    local playlist_filename = mp.get_property('playlist-filename')
    if playlist_filename and playlist_filename ~= '' then
        local ok = mp.commandv('loadlist', playlist_filename, 'replace')
        if ok then
            mp.osd_message('Playlist recarregada', 2)
            show_overlay(2)
        else
            mp.osd_message('Erro ao recarregar playlist', 2)
        end
    else
        mp.osd_message('Playlist atual não tem origem conhecida', 2)
    end
end

mp.register_script_message('arktv-overlay', function(action)
    if action == 'status' then
        show_overlay(default_duration)
    elseif action == 'reload-playlist' then
        reload_playlist()
    end
end)

mp.register_event('file-loaded', function()
    show_overlay(default_duration)
end)

mp.register_event('shutdown', function()
    remove_overlay()
end)

log('Status OSD carregado')
