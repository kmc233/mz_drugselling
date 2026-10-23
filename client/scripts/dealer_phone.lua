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

--- @section Local function

--- Stop dealing.
-- @param player_ped: The players ped id.
local function stop_dealing(player_ped)
    stop_corner_dealing()
    is_dealing = false
    dealing_mode = nil
    TriggerServerEvent('boii_drugsales:sv:stop_phone_action')
    send_notification(lang.dealing.client.notifications.header, lang.dealing.client.notifications.stopped, 'info', 3500)

    if TARGET == 'boii_target' then
        exports.boii_target:remove_target('boii_drugsales_dealing')
    elseif TARGET == 'qb-target' then
        exports['qb-target']:RemoveGlobalPed(lang.dealing.client.target.sales.label)
    elseif TARGET == 'ox_target' then
        exports.ox_target:removeGlobalPed({ 'boii_drugsales_dealing' })
    end
end

--- Start dealing.
-- @param player_ped: The players ped id.
local function start_dealing(player_ped, mode)
    is_dealing = true
    dealing_mode = mode
    SendNUIMessage({ action = 'close_dealer_phone' })
    send_notification(lang.dealing.client.notifications.header,
        mode == 'corner' and '站街模式已开启，顾客会主动走来。' or lang.dealing.client.notifications.started, 'info', 3500)
    if mode == 'corner' then
        start_corner_dealing()
        return
    end
    if TARGET == 'boii_target' then
        exports.boii_target:add_ped({
            id = 'boii_drugsales_dealing',
            icon = lang.dealing.client.target.sales.main_icon,
            distance = 2.5,
            disabled_types = { 28, 29, 30, 31 },
            actions = {
                label = lang.dealing.client.target.sales.label,
                icon = lang.dealing.client.target.sales.action_icon,
                action_type = 'function',
                action = function(entity)
                    start_street_sale(entity)
                end,
                can_interact = function(entity)
                    local ped_type = GetPedType(entity)
                    local model = GetEntityModel(entity)
                    return not (IsPedAPlayer(entity) or (config.bulk_ped and model == GetHashKey(config.bulk_ped)))
                end
            }
        })
    elseif TARGET == 'qb-target' then
        exports['qb-target']:AddGlobalPed({
            options = {
                {
                    icon = lang.dealing.client.target.sales.action_icon,
                    label = lang.dealing.client.target.sales.label,
                    action = function(entity)
                        start_street_sale(entity)
                    end,
                    canInteract = function(entity)
                        local ped_type = GetPedType(entity)
                        local model = GetEntityModel(entity)
                        return not (IsPedAPlayer(entity) or ped_type == 28 or ped_type == 29 or ped_type == 30 or ped_type == 31 or (config.bulk_ped and model == GetHashKey(config.bulk_ped)))
                    end
                }
            },
            distance = 2.5
        })
    elseif TARGET == 'ox_target' then
        exports.ox_target:addGlobalPed({{
            name = 'boii_drugsales_dealing',
            label = lang.dealing.client.target.sales.label,
            distance = 2.5,
            canInteract = function(entity)
                local ped_type = GetPedType(entity)
                local model = GetEntityModel(entity)
                return not (IsPedAPlayer(entity) or ped_type == 28 or ped_type == 29 or ped_type == 30 or ped_type == 31 or (config.bulk_ped and model == GetHashKey(config.bulk_ped)))
            end,
            onSelect = function(data)
                start_street_sale(data.entity)
            end
        }})
    end
end

--- Stop delivering.
-- @param player_ped: The players ped id.
local function stop_deliveries(player_ped)
    is_delivering = false
    TriggerServerEvent('boii_drugsales:sv:stop_phone_action')
    if delivery_blip then
        RemoveBlip(delivery_blip)
        delivery_blip = nil
    end
    send_notification(lang.deliveries.client.notifications.header, lang.deliveries.client.notifications.stopped, 'info', 3500)
    if delivery_ped then
        SetPedAsNoLongerNeeded(delivery_ped)
        Wait(5000)
        DeletePed(delivery_ped)
        delivery_ped = nil
    end
end

--- Start dealing.
-- @param player_ped: The players ped id.
local function start_deliveries(player_ped)
    is_delivering = true
    SendNUIMessage({ action = 'close_dealer_phone' })
    send_notification(lang.deliveries.client.notifications.header, lang.deliveries.client.notifications.started, 'info', 3500)
    TriggerServerEvent('boii_drugsales:sv:request_delivery')
end

--- @section NUI callbacks

RegisterNUICallback('dealer_phone_action', function(data, cb)
    cb(true)
    local action = data.action
    if not action then print('action missing') return end
    local player_ped = PlayerPedId()
    if action == 'dealing_start' or action == 'corner_start' then
        if is_delivering then 
            send_notification(lang.dealing.client.notifications.header, lang.dealing.client.notifications.is_delivering, 'error', 3500)
            return
        end
        local mode = action == 'corner_start' and 'corner' or 'dealing'
        utils.callback.cb('boii_drugsales:sv:perform_phone_action', { action = mode }, function(success, message)
            if success then
                start_dealing(player_ped, mode)
            else
                print(message)
            end
        end)

    end

    if action == 'delivery_start' then
        if is_dealing then 
            send_notification(lang.deliveries.client.notifications.header, lang.deliveries.client.notifications.is_dealing, 'error', 3500)
            return
        end
        utils.callback.cb('boii_drugsales:sv:perform_phone_action', { action = 'delivery' }, function(success, message)
            if success then
                start_deliveries(player_ped)
            else
                print(message)
            end
        end)
    end

    if action == 'dealing_stop' or action == 'corner_stop' then
        if not is_dealing then 
            send_notification(lang.dealing.client.notifications.header, lang.dealing.client.notifications.not_dealing, 'error', 3500)
            return
        end
        stop_dealing(player_ped)
        return
    end

    if action == 'delivery_stop' then
        if not is_delivering then 
            send_notification(lang.deliveries.client.notifications.header, lang.deliveries.client.notifications.not_delivering, 'error', 3500)
            return
        end
        is_delivering = false
        stop_deliveries(player_ped)
        return
    end

end)

--- @section Events

--- Opens the dealer phone
RegisterNetEvent('boii_drugsales:cl:open_dealer_phone', function()
    local player_ped = PlayerPedId()
    utils.requests.model('prop_v_m_phone_o1s')
    utils.requests.anim('cellphone@')
    local coords = GetEntityCoords(player_ped)
    phone_prop = CreateObject('prop_v_m_phone_o1s', coords.x + 2, coords.y, coords.z, true, true, true)
    AttachEntityToEntity(phone_prop, player_ped, GetPedBoneIndex(PlayerPedId(), 28422), 0, 0, 0, 50, 320, 50, false, false, false, false, 2, true)
    TaskPlayAnim(player_ped, 'cellphone@', 'cellphone_text_in', 3.0, 3.0, -1, 50, 0, false, false, false)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open_dealer_phone'
    })
end)

RegisterNetEvent('boii_drugsales:cl:stop_dealing', function()
    local player_ped = PlayerPedId()
    stop_dealing(player_ped)
end)


RegisterNetEvent('boii_drugsales:cl:stop_deliveries', function()
    local player_ped = PlayerPedId()
    stop_deliveries(player_ped)
end)
