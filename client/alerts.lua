
RegisterNetEvent('mz_drugselling:cl:send_dispatch', function(dispatch, code, message)
    if GetResourceState(dispatch) ~= 'started' then
        print(('[mz_drugselling] Dispatch resource %s is not started'):format(tostring(dispatch)))
        return
    end

    local title = code .. ' | ' .. message
    local coords = GetEntityCoords(PlayerPedId())
    local ok, err = pcall(function()
        if dispatch == 'cd_dispatch' then
            local player = exports['cd_dispatch']:GetPlayerInfo()
            TriggerServerEvent('cd_dispatch:AddNotification', {
                job_table = { 'police' },
                coords = player.coords or coords,
                title = title,
                message = message,
                flash = 0,
                unique_id = player.unique_id,
                sound = 1,
                blip = { sprite = 161, scale = 1.2, colour = 1, flashes = false,
                    text = title, time = 5, radius = 0 }
            })
        elseif dispatch == 'codem-dispatch' then
            exports['codem-dispatch']:CustomDispatch({
                type = 'DrugDealing', header = title, text = message, code = code
            })
        elseif dispatch == 'origen_police' then
            TriggerServerEvent('SendAlert:police', {
                coords = coords, title = title, type = 'GENERAL', message = message, job = 'police'
            })
        elseif dispatch == 'ps-dispatch' then
            exports['ps-dispatch']:DrugSale()
        elseif dispatch == 'rcore_dispatch' then
            local player = exports['rcore_dispatch']:GetPlayerData()
            TriggerServerEvent('rcore_dispatch:server:sendAlert', {
                code = code, default_priority = 'medium', coords = player.coords or coords,
                job = 'police', text = message, type = 'alerts', blip_time = 5,
                blip = { sprite = 161, colour = 1, scale = 0.7, text = title,
                    flashes = false, radius = 0 }
            })
        end
    end)
    if not ok then
        print(('[mz_drugselling] %s dispatch failed: %s'):format(dispatch, tostring(err)))
    end
end)
