delivery_orders = { orders = {}, active_id = nil, refresh_at = 0, server_time = 0 }

local function remove_delivery_ped()
    if delivery_blip then RemoveBlip(delivery_blip) delivery_blip = nil end
    if delivery_ped then
        if TARGET == 'ox_target' then
            exports.ox_target:removeLocalEntity(delivery_ped, 'mz_drugselling_delivery')
        elseif TARGET == 'qb-target' then
            exports['qb-target']:RemoveZone('mz_drugselling_delivery')
        end
        if DoesEntityExist(delivery_ped) then DeletePed(delivery_ped) end
        delivery_ped = nil
    end
end

RegisterNetEvent('mz_drugselling:cl:delivery_orders', function(data)
    delivery_orders = data
    SendNUIMessage({ action = 'delivery_orders', data = data })
end)

RegisterNUICallback('delivery_refresh', function(_, cb)
    cb({ success = true })
    if delivery_receiving then TriggerServerEvent('mz_drugselling:sv:request_delivery') end
end)

RegisterNUICallback('delivery_accept', function(data, cb)
    cb({ success = true })
    TriggerServerEvent('mz_drugselling:sv:accept_delivery', tonumber(data.id))
end)

RegisterNUICallback('delivery_cancel_order', function(_, cb)
    cb({ success = true })
    TriggerServerEvent('mz_drugselling:sv:cancel_delivery')
end)

RegisterNetEvent('mz_drugselling:cl:clear_delivery', remove_delivery_ped)

RegisterNetEvent('mz_drugselling:cl:spawn_delivery_ped', function(location)
    if not is_delivering then return end
    remove_delivery_ped()
    delivery_blip = AddBlipForCoord(location.x, location.y, location.z)
    SetBlipSprite(delivery_blip, 51)
    SetBlipColour(delivery_blip, 1)
    SetBlipScale(delivery_blip, 0.7)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('配送交货点')
    EndTextCommandSetBlipName(delivery_blip)
    SetBlipRoute(delivery_blip, true)
    SetBlipRouteColour(delivery_blip, 1)

    local models = { 'csb_money', 'a_m_y_beachvesp_01' }
    local model = GetHashKey(models[math.random(#models)])
    if not utils.requests.model(model) then return end
    delivery_ped = CreatePed(4, model, location.x, location.y, location.z - 1, location.w, false, true)
    SetModelAsNoLongerNeeded(model)
    SetEntityInvincible(delivery_ped, true)
    SetBlockingOfNonTemporaryEvents(delivery_ped, true)
    TaskStartScenarioInPlace(delivery_ped, 'WORLD_HUMAN_SMOKING', 0, true)
    if TARGET == 'qb-target' then
        exports['qb-target']:AddEntityZone('mz_drugselling_delivery', delivery_ped, {
            name = 'mz_drugselling_delivery', heading = 0.0, debugPoly = false
        }, { distance = 2.5, options = {{
            icon = lang.deliveries.client.target.action_icon,
            label = '交付订单',
            action = function() TriggerServerEvent('mz_drugselling:sv:complete_delivery') end
        }} })
    elseif TARGET == 'ox_target' then
        exports.ox_target:addLocalEntity(delivery_ped, {{
            name = 'mz_drugselling_delivery', label = '交付订单',
            icon = lang.deliveries.client.target.action_icon, distance = 2.5,
            onSelect = function() TriggerServerEvent('mz_drugselling:sv:complete_delivery') end
        }})
    end
end)

RegisterNetEvent('mz_drugselling:cl:completed_delivery', function()
    utils.requests.anim('mp_common')
    local player = PlayerPedId()
    TaskPlayAnim(player, 'mp_common', 'givetake1_a', 8.0, -8.0, 2000, 0, 0, false, false, false)
    if delivery_ped then
        TaskPlayAnim(delivery_ped, 'mp_common', 'givetake1_b', 8.0, -8.0, 2000, 0, 0, false, false, false)
    end
    Wait(2000)
    remove_delivery_ped()
    RemoveAnimDict('mp_common')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then remove_delivery_ped() end
end)
