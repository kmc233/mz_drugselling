delivery_orders = { orders = {}, active_id = nil, cooldown_until = 0, server_time = 0 }
local departing_peds = {}
local delivery_zone = nil
local delivery_spawn_token = 0

local function delivery_area(coords)
    if not coords then return '未知区域' end
    local zone = GetNameOfZone(coords.x, coords.y, coords.z)
    local label = zone and GetLabelText(zone)
    if label and label ~= 'NULL' and label ~= '' then return label end
    return zone and zone ~= '' and zone or '未知区域'
end

local function clear_delivery_marker(ped)
    if delivery_blip then RemoveBlip(delivery_blip) delivery_blip = nil end
    if not ped then return end
    if TARGET == 'ox_target' then
        exports.ox_target:removeLocalEntity(ped, 'mz_drugselling_delivery')
    elseif TARGET == 'qb-target' then
        exports['qb-target']:RemoveZone('mz_drugselling_delivery')
    end
end

local function remove_delivery_ped()
    delivery_spawn_token = delivery_spawn_token + 1
    delivery_zone = nil
    local ped = delivery_ped
    clear_delivery_marker(ped)
    if ped and DoesEntityExist(ped) then DeletePed(ped) end
    delivery_ped = nil
end

local function send_delivery_ped_away()
    local ped = delivery_ped
    clear_delivery_marker(ped)
    delivery_ped = nil
    if not ped or not DoesEntityExist(ped) then return end
    ClearPedTasks(ped)
    SetPedKeepTask(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, false)
    SetEntityInvincible(ped, false)
    TaskWanderStandard(ped, 10.0, 10)
    departing_peds[ped] = true
    utils.peds.schedule_departure_cleanup(ped, function()
        departing_peds[ped] = nil
    end)
end

RegisterNetEvent('mz_drugselling:cl:delivery_orders', function(data)
    delivery_orders = data
    for _, order in ipairs(delivery_orders.orders or {}) do
        order.area = delivery_area(order.coords)
    end
    is_delivering = data.active_id ~= nil
    SendNUIMessage({ action = 'phone_mode_changed', mode = dealing_mode or (is_delivering and 'delivery') })
    SendNUIMessage({ action = 'delivery_orders', data = data })
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

local function random_delivery_point(zone)
    local radius = math.max(0.0, tonumber(zone.radius) or 0.0)
    if radius <= 0.0 then return zone.x, zone.y, zone.z, zone.w or 0.0 end
    for _ = 1, 8 do
        local angle = math.random() * math.pi * 2.0
        local distance = math.sqrt(math.random()) * radius
        local x = zone.x + math.cos(angle) * distance
        local y = zone.y + math.sin(angle) * distance
        local found, ground_z = GetGroundZFor_3dCoord(x, y, zone.z + 50.0, false)
        if found then return x, y, ground_z, math.random(0, 359) + 0.0 end
    end
    return zone.x, zone.y, zone.z, zone.w or 0.0
end

local function create_delivery_ped(zone, token)
    local models = zone.models or { 'csb_money', 'a_m_y_beachvesp_01' }
    local model = GetHashKey(models[math.random(#models)])
    if not utils.requests.model(model) or token ~= delivery_spawn_token or not delivery_zone then return end
    local x, y, z, heading = random_delivery_point(zone)
    delivery_ped = CreatePed(4, model, x, y, z - 1.0, heading, false, true)
    SetModelAsNoLongerNeeded(model)
    if delivery_ped == 0 then return end
    SetEntityAsMissionEntity(delivery_ped, true, true)
    SetEntityInvincible(delivery_ped, true)
    SetBlockingOfNonTemporaryEvents(delivery_ped, true)
    TaskStartScenarioInPlace(delivery_ped, 'WORLD_HUMAN_SMOKING', 0, true)
    SetBlipCoords(delivery_blip, x, y, z)
    if TARGET == 'qb-target' then
        exports['qb-target']:AddEntityZone('mz_drugselling_delivery', delivery_ped, {
            name = 'mz_drugselling_delivery', heading = 0.0, debugPoly = false
        }, { distance = 2.5, options = {{
            icon = lang.deliveries.client.target.action_icon,
            label = lang.deliveries.client.phone.deliver_order,
            action = function() TriggerServerEvent('mz_drugselling:sv:complete_delivery') end
        }} })
    elseif TARGET == 'ox_target' then
        exports.ox_target:addLocalEntity(delivery_ped, {{
            name = 'mz_drugselling_delivery', label = lang.deliveries.client.phone.deliver_order,
            icon = lang.deliveries.client.target.action_icon, distance = 2.5,
            onSelect = function() TriggerServerEvent('mz_drugselling:sv:complete_delivery') end
        }})
    end
    delivery_zone = nil
end

RegisterNetEvent('mz_drugselling:cl:spawn_delivery_ped', function(location)
    if not is_delivering then return end
    remove_delivery_ped()
    delivery_zone = location
    delivery_blip = AddBlipForCoord(location.x, location.y, location.z)
    SetBlipSprite(delivery_blip, 51)
    SetBlipColour(delivery_blip, 1)
    SetBlipScale(delivery_blip, 0.7)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(lang.deliveries.client.phone.delivery_point)
    EndTextCommandSetBlipName(delivery_blip)
    SetBlipRoute(delivery_blip, true)
    SetBlipRouteColour(delivery_blip, 1)
    local token = delivery_spawn_token
    CreateThread(function()
        local spawn_distance = math.max(25.0, tonumber(location.spawn_distance) or 100.0)
        while delivery_zone and token == delivery_spawn_token and is_delivering do
            local player_coords = GetEntityCoords(PlayerPedId())
            local zone_coords = vector3(location.x, location.y, location.z)
            if #(player_coords - zone_coords) <= spawn_distance then
                create_delivery_ped(location, token)
                return
            end
            Wait(1000)
        end
    end)
end)

RegisterNetEvent('mz_drugselling:cl:completed_delivery', function()
    utils.requests.anim('mp_common')
    local player = PlayerPedId()
    TaskPlayAnim(player, 'mp_common', 'givetake1_a', 8.0, -8.0, 2000, 0, 0, false, false, false)
    if delivery_ped then
        TaskPlayAnim(delivery_ped, 'mp_common', 'givetake1_b', 8.0, -8.0, 2000, 0, 0, false, false, false)
    end
    Wait(2000)
    send_delivery_ped_away()
    RemoveAnimDict('mp_common')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    remove_delivery_ped()
    for ped in pairs(departing_peds) do
        if DoesEntityExist(ped) then DeletePed(ped) end
    end
end)
