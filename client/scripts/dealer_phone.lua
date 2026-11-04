
--- Stop dealing.
-- @param player_ped: The players ped id.
local function stop_dealing(player_ped, for_delivery)
    stop_corner_dealing()
    is_dealing = false
    dealing_mode = nil
    SendNUIMessage({ action = 'phone_mode_changed', mode = for_delivery and 'delivery' or nil })
    if not for_delivery then TriggerServerEvent('mz_drugselling:sv:stop_sales_mode') end
    send_notification(lang.dealing.client.notifications.header, lang.dealing.client.notifications.stopped, 'info', 3500)

    if config.street_phone then
        if TARGET == 'qb-target' then
            exports['qb-target']:RemoveGlobalPed(lang.dealing.client.target.sales.label)
        elseif TARGET == 'ox_target' then
            exports.ox_target:removeGlobalPed({ 'mz_drugselling_dealing' })
        end
    end
end

local function can_sell_to_ped(entity)
    if not entity or not DoesEntityExist(entity) or not IsEntityAPed(entity)
        or IsPedAPlayer(entity) or IsPedInAnyVehicle(entity, false)
        or IsPedDeadOrDying(entity, true) or IsPedInCombat(entity, PlayerPedId())
        or GetEntityHealth(entity) <= 0 or (is_street_ped_used and is_street_ped_used(entity)) then return false end
    if is_delivering or dealing_mode == 'corner' then return false end
    if config.street_phone and dealing_mode ~= 'dealing' then return false end
    local ped_type = GetPedType(entity)
    local model = GetEntityModel(entity)
    return not (IsPedAPlayer(entity) or ped_type == 28 or ped_type == 29
        or ped_type == 30 or ped_type == 31
        or (config.bulk_ped and model == GetHashKey(config.bulk_ped)))
end

function setup_street_target()
    if TARGET == 'qb-target' then
        exports['qb-target']:AddGlobalPed({
            options = {
                {
                    icon = lang.dealing.client.target.sales.action_icon,
                    label = lang.dealing.client.target.sales.label,
                    action = function(entity)
                        start_street_sale(entity)
                    end,
                    canInteract = can_sell_to_ped
                }
            },
            distance = 2.5
        })
    elseif TARGET == 'ox_target' then
        exports.ox_target:addGlobalPed({{
            name = 'mz_drugselling_dealing',
            label = lang.dealing.client.target.sales.label,
            distance = 2.5,
            canInteract = can_sell_to_ped,
            onSelect = function(data)
                start_street_sale(data.entity)
            end
        }})
    end
end

--- Start dealing.
-- @param player_ped: The players ped id.
local function start_dealing(player_ped, mode)
    is_dealing = true
    dealing_mode = mode
    SendNUIMessage({ action = 'phone_mode_changed', mode = mode })
    SendNUIMessage({ action = 'close_dealer_phone' })
    send_notification(lang.dealing.client.notifications.header,
        mode == 'corner' and lang.dealing.client.notifications.corner_started or lang.dealing.client.notifications.started, 'info', 3500)
    if mode == 'corner' then
        start_corner_dealing()
    else
        setup_street_target()
    end
end

--- Stop delivering.
-- @param player_ped: The players ped id.
local function stop_deliveries()
    delivery_receiving = false
    SendNUIMessage({ action = 'delivery_receiving_changed', receiving = false })
    TriggerServerEvent('mz_drugselling:sv:pause_delivery')
    send_notification(lang.deliveries.client.notifications.header, lang.deliveries.client.notifications.stopped, 'info', 3500)
end

local function start_deliveries()
    delivery_receiving = true
    SendNUIMessage({ action = 'delivery_receiving_changed', receiving = true })
    send_notification(lang.deliveries.client.notifications.header, lang.deliveries.client.notifications.started, 'info', 3500)
    TriggerServerEvent('mz_drugselling:sv:request_delivery')
end

RegisterNetEvent('mz_drugselling:cl:delivery_receiving_rejected', function()
    delivery_receiving = false
    SendNUIMessage({ action = 'delivery_receiving_changed', receiving = false })
end)

--- @section NUI callbacks

RegisterNUICallback('dealer_phone_action', function(data, cb)
    cb(true)
    local action = data.action
    if not action then print('action missing') return end
    local player_ped = PlayerPedId()
    if action == 'dealing_start' or action == 'corner_start' then
        if action == 'dealing_start' and not config.street_phone then return end
        if is_delivering then
            send_notification(lang.dealing.client.notifications.header, lang.dealing.client.notifications.is_delivering, 'error', 3500)
            return
        end
        local mode = action == 'corner_start' and 'corner' or 'dealing'
        utils.callback.cb('mz_drugselling:sv:perform_phone_action', { action = mode }, function(success, message)
            if success then
                start_dealing(player_ped, mode)
            else
                send_notification(lang.dealing.client.notifications.header, message or lang.dealing.client.notifications.start_failed, 'error', 3500)
            end
        end)

    end

    if action == 'delivery_start' then
        if not delivery_receiving then start_deliveries() end
        return
    end

    if action == 'dealing_stop' or action == 'corner_stop' then
        if action == 'dealing_stop' and not config.street_phone then return end
        if not is_dealing then 
            send_notification(lang.dealing.client.notifications.header, lang.dealing.client.notifications.not_dealing, 'error', 3500)
            return
        end
        stop_dealing(player_ped)
        return
    end

    if action == 'delivery_stop' then
        if not delivery_receiving then
            send_notification(lang.deliveries.client.notifications.header, lang.deliveries.client.notifications.not_delivering, 'error', 3500)
            return
        end
        stop_deliveries()
        return
    end

end)

--- @section Events

--- Opens the dealer phone
RegisterNetEvent('mz_drugselling:cl:open_dealer_phone', function()
    local player_ped = PlayerPedId()
    utils.requests.model('prop_v_m_phone_o1s')
    utils.requests.anim('cellphone@')
    local coords = GetEntityCoords(player_ped)
    phone_prop = CreateObject('prop_v_m_phone_o1s', coords.x + 2, coords.y, coords.z, true, true, true)
    AttachEntityToEntity(phone_prop, player_ped, GetPedBoneIndex(PlayerPedId(), 28422), 0, 0, 0, 50, 320, 50, false, false, false, false, 2, true)
    TaskPlayAnim(player_ped, 'cellphone@', 'cellphone_text_in', 3.0, 3.0, -1, 50, 0, false, false, false)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open_dealer_phone',
        data = {
            street_phone = config.street_phone,
            active_mode = dealing_mode or (is_delivering and 'delivery'),
            delivery_receiving = delivery_receiving,
            delivery_orders = delivery_orders,
            phone_locale = lang.deliveries.client.phone,
            sms_dialogue = lang.deliveries.client.sms_dialogue
        }
    })
end)

RegisterNetEvent('mz_drugselling:cl:stop_dealing', function()
    local player_ped = PlayerPedId()
    stop_dealing(player_ped)
end)


RegisterNetEvent('mz_drugselling:cl:stop_deliveries', function()
    stop_deliveries()
end)

RegisterNetEvent('mz_drugselling:cl:delivery_accepted', function()
    is_delivering = true
    if is_dealing then
        stop_dealing(PlayerPedId(), true)
    else
        SendNUIMessage({ action = 'phone_mode_changed', mode = 'delivery' })
    end
end)
