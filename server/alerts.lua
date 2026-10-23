--[[
     ____   ____ _____ _____   _   _____  ________      ________ _      ____  _____  __  __ ______ _   _ _______ 
    |  _ \ / __ \_   _|_   _| | | |  __ \|  ____\ \    / /  ____| |    / __ \|  __ \|  \/  |  ____| \ | |__   __|
    | |_) | |  | || |   | |   | | | |  | | |__   \ \  / /| |__  | |   | |  | | |__) | \  / | |__  |  \| |  | |   
    |  _ <| |  | || |   | |   | | | |  | |  __|   \ \/ / |  __| | |   | |  | |  ___/| |\/| |  __| | . ` |  | |   
    | |_) | |__| || |_ _| |_  | | | |__| | |____   \  /  | |____| |___| |__| | |    | |  | | |____| |\  |  | |   
    |____/ \____/_____|_____| | | |_____/|______|   \/   |______|______\____/|_|    |_|  |_|______|_| \_|  |_|   
                              | |                                                                                
                              |_|               DRUG SALES
]]

--- Alert police with an action
-- @param action string: The action to alert the police about.
function alert_police(_src, action)
    if not _src or not action then return end

    local settings = action == 'delivery' and config.deliveries.police or config.dealing.police
    local police = get_police_players(settings.jobs, settings.on_duty_required)
    if not police then print('no police found') return end

    local player_coords = GetEntityCoords(GetPlayerPed(_src))
    local alert_data = {
        dealing = {
            code = lang.dealing.server.alerts.code,
            message = lang.dealing.server.alerts.message
        },
        delivery = {
            code = lang.deliveries.server.alerts.code,
            message = lang.deliveries.server.alerts.message
        }
    }

    if not alert_data[action] then return end
    local label = alert_data[action].code .. ' | ' .. alert_data[action].message
    for _, player_source in pairs(police) do
        --- Replace this event with the handler for your own dispatch in order to change
        -- Or you can modify the client event whatever suits.
        TriggerClientEvent('boii_drugsales:cl:alert_police', player_source, player_coords, label)
    end
end
