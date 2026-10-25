local pending = false
local pending_id = 0
local used_peds = {}
local corner_ped = nil
local corner_spawned = false
local corner_generation = 0
local held_peds = {}
local spawned_peds = {}
local schedule_corner_customer
local function is_gang_member(ped)
    local type_id = config.ped_model_types and config.ped_model_types[GetEntityModel(ped)]
    local personality = type_id and config.ped_types and config.ped_types[type_id]
    return personality and personality.gang == true or false
end

local function close_offer()
    SendNUIMessage({ action = 'close_street_offer' })
    SetNuiFocus(false, false)
end

local function hold_ped(ped)
    if NetworkGetEntityIsNetworked(ped) then
        for _ = 1, 15 do
            if NetworkHasControlOfEntity(ped) then break end
            NetworkRequestControlOfEntity(ped)
            Wait(50)
        end
        if not NetworkHasControlOfEntity(ped) then return false end
    end

    ClearPedTasksImmediately(ped)
    ClearPedSecondaryTask(ped)
    SetPedKeepTask(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    local coords = GetEntityCoords(ped)
    local player_coords = GetEntityCoords(PlayerPedId())
    SetEntityHeading(ped, GetHeadingFromVector_2d(player_coords.x - coords.x, player_coords.y - coords.y))
    TaskStandStill(ped, -1)
    held_peds[ped] = true
    return true
end

local function release_ped(ped, walk_away)
    if not held_peds[ped] then return end
    held_peds[ped] = nil
    if not DoesEntityExist(ped) then return end
    ClearPedTasks(ped)
    SetPedKeepTask(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, false)
    if walk_away then TaskWanderStandard(ped, 10.0, 10) end
end

local function schedule_corner_cleanup(ped)
    if not ped or not spawned_peds[ped] then return end
    CreateThread(function()
        local expires = GetGameTimer() + 90000
        while DoesEntityExist(ped) and GetGameTimer() < expires do
            if #(GetEntityCoords(ped) - GetEntityCoords(PlayerPedId())) > 40.0
                and not IsEntityOnScreen(ped) then break end
            Wait(2000)
        end
        if DoesEntityExist(ped) then DeletePed(ped) end
        spawned_peds[ped] = nil
    end)
end

local function find_corner_ped(player_ped)
    local origin = GetEntityCoords(player_ped)
    local candidates = {}
    for _, ped in ipairs(GetGamePool('CPed')) do
        if ped ~= player_ped and DoesEntityExist(ped) and not IsPedAPlayer(ped)
            and IsPedHuman(ped) and not IsPedDeadOrDying(ped, true)
            and not IsPedInAnyVehicle(ped, false)
            and not IsPedInCombat(ped, player_ped) and GetPedType(ped) ~= 6
            and not IsEntityAMissionEntity(ped) and not spawned_peds[ped]
            and not (used_peds[ped] and used_peds[ped] > GetGameTimer()) then
            local distance = #(GetEntityCoords(ped) - origin)
            if distance >= 6.0 and distance <= 35.0 then
                candidates[#candidates + 1] = ped
            end
        end
    end
    while #candidates > 0 do
        local index = math.random(#candidates)
        local ped = table.remove(candidates, index)
        if not NetworkGetEntityIsNetworked(ped) or NetworkHasControlOfEntity(ped) then
            return ped
        end
        NetworkRequestControlOfEntity(ped)
        for _ = 1, 10 do
            if NetworkHasControlOfEntity(ped) then return ped end
            Wait(50)
        end
    end
    return nil
end

local function begin_sale(ped)
    if pending or not ped or not DoesEntityExist(ped) or (used_peds[ped] and used_peds[ped] > GetGameTimer()) then return false end
    if IsPedAPlayer(ped) or IsPedDeadOrDying(ped, true) then return false end
    if not NetworkGetEntityIsNetworked(ped) then NetworkRegisterEntityAsNetworked(ped) end
    local net_id = NetworkGetNetworkIdFromEntity(ped)
    if not net_id or net_id == 0 then return false end
    if not hold_ped(ped) then return false end
    dealing_target = ped
    target_coords = GetEntityCoords(ped)
    used_peds[ped] = GetGameTimer() + (dealing_mode == 'corner' and 300000 or 30000)
    pending = true
    pending_id = pending_id + 1
    local current_id = pending_id
    SetTimeout(65000, function()
        if pending and pending_id == current_id then
            TriggerServerEvent('mz_drugselling:sv:cancel_street_sale')
            close_offer()
            pending = false
            dealing_target = nil
            release_ped(ped, true)
            if corner_ped == ped then
                if corner_spawned then schedule_corner_cleanup(ped) end
                corner_ped = nil
                corner_spawned = false
            end
            schedule_corner_customer()
        end
    end)
    CreateThread(function()
        Wait(150)
        if pending and dealing_target == ped then
            TriggerServerEvent('mz_drugselling:sv:prepare_street_sale', net_id)
        end
    end)
    return true
end

function start_street_sale(ped)
    if is_delivering or dealing_mode == 'corner' then return end
    if config.street_phone and dealing_mode ~= 'dealing' then return end
    if type(ped) ~= 'number' then
        ped = utils.entities.get_target_ped(PlayerPedId(), 45.0, 5.0)
    end
    begin_sale(ped)
end

schedule_corner_customer = function()
    if dealing_mode ~= 'corner' then return end
    local generation = corner_generation
    local delay = (config.corner and config.corner.interval or 8) * 1000
    SetTimeout(delay, function()
        if dealing_mode == 'corner' and generation == corner_generation then
            TriggerEvent('mz_drugselling:cl:spawn_corner_customer')
        end
    end)
end

RegisterNetEvent('mz_drugselling:cl:spawn_corner_customer', function()
    if dealing_mode ~= 'corner' or pending or corner_ped then return end
    local player_ped = PlayerPedId()
    corner_ped = find_corner_ped(player_ped)
    corner_spawned = false
    if not corner_ped then
        local models = config.corner and config.corner.models or {}
        if #models == 0 then return end
        local model_name = models[math.random(#models)]
        local model = GetHashKey(model_name)
        utils.requests.model(model_name)
        local origin = GetEntityCoords(player_ped)
        local x, y, z
        for _ = 1, 12 do
            local angle = math.random() * math.pi * 2
            local distance = math.random(22, 30)
            local candidate_x = origin.x + math.cos(angle) * distance
            local candidate_y = origin.y + math.sin(angle) * distance
            local found, safe = GetSafeCoordForPed(candidate_x, candidate_y, origin.z, true, 16)
            if found and safe and not IsSphereVisible(safe.x, safe.y, safe.z, 2.0) then
                x, y, z = safe.x, safe.y, safe.z
                break
            end
        end
        if not x then
            SetModelAsNoLongerNeeded(model)
            schedule_corner_customer()
            return
        end
        corner_ped = CreatePed(4, model, x, y, z, 0.0, true, true)
        SetModelAsNoLongerNeeded(model)
        if not DoesEntityExist(corner_ped) then corner_ped = nil return end
        SetEntityAsMissionEntity(corner_ped, true, true)
        spawned_peds[corner_ped] = true
        corner_spawned = true
    end
    if not DoesEntityExist(corner_ped) then corner_ped = nil return end
    TaskGoToEntity(corner_ped, player_ped, -1, 2.0, 1.0, 1073741824, 0)
    local this_ped = corner_ped
    local was_spawned = corner_spawned
    local generation = corner_generation
    CreateThread(function()
        local expires = GetGameTimer() + 45000
        while dealing_mode == 'corner' and generation == corner_generation and corner_ped == this_ped
            and DoesEntityExist(this_ped) and GetGameTimer() < expires do
            if #(GetEntityCoords(this_ped) - GetEntityCoords(PlayerPedId())) < 3.0 then
                TaskTurnPedToFaceEntity(this_ped, PlayerPedId(), 1500)
                if not begin_sale(this_ped) then
                    TaskWanderStandard(this_ped, 10.0, 10)
                    if was_spawned then schedule_corner_cleanup(this_ped) end
                    corner_ped = nil
                    corner_spawned = false
                    schedule_corner_customer()
                end
                return
            end
            Wait(500)
        end
        if corner_ped == this_ped then
            if DoesEntityExist(this_ped) then
                TaskWanderStandard(this_ped, 10.0, 10)
                if was_spawned then schedule_corner_cleanup(this_ped) end
            end
            corner_ped = nil
            corner_spawned = false
            schedule_corner_customer()
        end
    end)
end)

function start_corner_dealing()
    corner_generation = corner_generation + 1
    TriggerEvent('mz_drugselling:cl:spawn_corner_customer')
end

function stop_corner_dealing()
    corner_generation = corner_generation + 1
    release_ped(dealing_target, true)
    if corner_ped and DoesEntityExist(corner_ped) then
        TaskWanderStandard(corner_ped, 10.0, 10)
        if corner_spawned then schedule_corner_cleanup(corner_ped) end
    end
    corner_ped = nil
    corner_spawned = false
    if pending then
        TriggerServerEvent('mz_drugselling:sv:cancel_street_sale')
        close_offer()
    end
    pending = false
    dealing_target, target_coords = nil, nil
    used_peds = {}
end

RegisterNetEvent('mz_drugselling:cl:open_street_offer', function(data)
    if not pending or not dealing_target or not DoesEntityExist(dealing_target) then return end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open_street_offer', data = data })
end)

RegisterNUICallback('street_offer', function(data, cb)
    cb({ success = true })
    if not pending then return end
    close_offer()
    TriggerServerEvent('mz_drugselling:sv:submit_street_offer', data.drug_id, data.price)
end)

RegisterNUICallback('street_cancel', function(_, cb)
    cb({ success = true })
    if not pending then return end
    TriggerServerEvent('mz_drugselling:sv:cancel_street_sale')
    close_offer()
    pending = false
    local ped = dealing_target
    release_ped(ped, true)
    if corner_ped then
        if corner_spawned then schedule_corner_cleanup(corner_ped) end
        corner_ped = nil
        corner_spawned = false
    end
    dealing_target = nil
    schedule_corner_customer()
end)

local function watch_stolen_ped(ped, net_id)
    CreateThread(function()
        local expires = GetGameTimer() + 120000
        while DoesEntityExist(ped) and GetGameTimer() < expires do
            if IsPedDeadOrDying(ped, true) then
                local action = function()
                    TriggerServerEvent('mz_drugselling:sv:recover_stolen_drugs', net_id)
                end
                if TARGET == 'qb-target' then
                    exports['qb-target']:AddTargetEntity(ped, {
                        options = {{ icon = 'fa-solid fa-box-open', label = lang.dealing.client.target.retrieve.label, action = action }},
                        distance = 2.0
                    })
                elseif TARGET == 'ox_target' then
                    exports.ox_target:addLocalEntity(ped, {
                        { name = 'drug_recovery_' .. net_id, icon = 'fa-solid fa-box-open',
                          label = lang.dealing.client.target.retrieve.label, distance = 2.0, onSelect = action }
                    })
                end
                return
            end
            Wait(1000)
        end
    end)
end

RegisterNetEvent('mz_drugselling:cl:street_result', function(result)
    if not pending then return end
    close_offer()
    pending = false
    local ped = dealing_target
    if ped and DoesEntityExist(ped) then
        if result.outcome == 'sold' then
            utils.requests.anim('mp_common')
            TaskPlayAnim(PlayerPedId(), 'mp_common', 'givetake2_a', 8.0, -8.0, 1800, 0, 0, false, false, false)
            TaskPlayAnim(ped, 'mp_common', 'givetake2_a', 8.0, -8.0, 1800, 0, 0, false, false, false)
            SetTimeout(1800, function() release_ped(ped, true) end)
        elseif result.outcome == 'stolen' then
            release_ped(ped, false)
            local net_id = NetworkGetNetworkIdFromEntity(ped)
            if is_gang_member(ped) then
                GiveWeaponToPed(ped, GetHashKey('WEAPON_PISTOL'), 30, false, true)
                TaskAimGunAtEntity(ped, PlayerPedId(), 2500, true)
                Wait(2500)
            end
            TaskSmartFleePed(ped, PlayerPedId(), 120.0, 30000, false, false)
            watch_stolen_ped(ped, net_id)
        else
            release_ped(ped, true)
        end
    else
        release_ped(ped, false)
    end
    if result.outcome == 'unavailable' and not result.reason then
        send_notification(lang.dealing.client.notifications.header, '当前无法和这名顾客交易。', 'error', 3500)
    elseif result.outcome == 'refused' then
        send_notification(lang.dealing.client.notifications.header, '顾客拒绝了交易。', 'error', 3500)
    elseif result.outcome == 'stolen' then
        send_notification(lang.dealing.client.notifications.header, lang.dealing.server.notifications.drugs_stolen, 'error', 3500)
    end
    if ped == corner_ped then
        corner_ped = nil
        if corner_spawned then
            if result.outcome == 'stolen' then
                SetTimeout(120000, function() schedule_corner_cleanup(ped) end)
            else
                schedule_corner_cleanup(ped)
            end
        end
        corner_spawned = false
    end
    dealing_target, target_coords = nil, nil
    if (result.reason == 'no_drugs' or result.reason == 'police')
        and (config.street_phone or dealing_mode == 'corner') then
        TriggerEvent('mz_drugselling:cl:stop_dealing')
        return
    end
    schedule_corner_customer()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for ped in pairs(held_peds) do release_ped(ped, true) end
    for ped in pairs(spawned_peds) do
        if DoesEntityExist(ped) then DeletePed(ped) end
    end
end)
