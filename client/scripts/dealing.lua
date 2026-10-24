local pending = false
local pending_id = 0
local used_peds = {}
local corner_ped = nil
local corner_generation = 0
local held_peds = {}
local schedule_corner_customer
local gang_models = {
    'g_m_y_ballaeast_01', 'g_m_y_ballaorig_01', 'g_m_y_ballasout_01',
    'g_m_y_famca_01', 'g_m_y_famdnf_01', 'g_m_y_famfor_01',
    'g_m_y_lost_01', 'g_m_y_lost_02', 'g_m_y_lost_03',
    'g_m_y_mexgoon_01', 'g_m_y_mexgoon_02', 'g_m_y_mexgoon_03',
    'g_m_y_pologoon_01', 'g_m_y_salvagoon_01', 'g_m_y_strpunk_01'
}

local function is_gang_member(ped)
    local model = GetEntityModel(ped)
    for _, name in ipairs(gang_models) do
        if model == GetHashKey(name) then return true end
    end
    return false
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

local function begin_sale(ped)
    if pending or not ped or not DoesEntityExist(ped) or (used_peds[ped] and used_peds[ped] > GetGameTimer()) then return false end
    if IsPedAPlayer(ped) or IsPedDeadOrDying(ped, true) then return false end
    if not NetworkGetEntityIsNetworked(ped) then NetworkRegisterEntityAsNetworked(ped) end
    local net_id = NetworkGetNetworkIdFromEntity(ped)
    if not net_id or net_id == 0 then return false end
    if not hold_ped(ped) then return false end
    dealing_target = ped
    target_coords = GetEntityCoords(ped)
    used_peds[ped] = GetGameTimer() + 30000
    pending = true
    pending_id = pending_id + 1
    local current_id = pending_id
    SetTimeout(65000, function()
        if pending and pending_id == current_id then
            TriggerServerEvent('boii_drugsales:sv:cancel_street_sale')
            close_offer()
            pending = false
            dealing_target = nil
            release_ped(ped, corner_ped ~= ped)
            if corner_ped == ped then
                if DoesEntityExist(ped) then DeletePed(ped) end
                corner_ped = nil
            end
            schedule_corner_customer()
        end
    end)
    CreateThread(function()
        Wait(150)
        if pending and dealing_target == ped then
            TriggerServerEvent('boii_drugsales:sv:prepare_street_sale', net_id)
        end
    end)
    return true
end

function start_street_sale(ped)
    if dealing_mode ~= 'dealing' then return end
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
            TriggerEvent('boii_drugsales:cl:spawn_corner_customer')
        end
    end)
end

RegisterNetEvent('boii_drugsales:cl:spawn_corner_customer', function()
    if dealing_mode ~= 'corner' or pending or corner_ped then return end
    local models = config.corner and config.corner.models or {}
    if #models == 0 then return end
    local model_name = models[math.random(#models)]
    local model = GetHashKey(model_name)
    utils.requests.model(model_name)
    local player_ped = PlayerPedId()
    local origin = GetEntityCoords(player_ped)
    local angle = math.random() * math.pi * 2
    local x, y = origin.x + math.cos(angle) * 22, origin.y + math.sin(angle) * 22
    local found, safe = GetSafeCoordForPed(x, y, origin.z, true, 16)
    local z = origin.z
    if found then x, y, z = safe.x, safe.y, safe.z end
    corner_ped = CreatePed(4, model, x, y, z, 0.0, true, true)
    SetModelAsNoLongerNeeded(model)
    if not DoesEntityExist(corner_ped) then corner_ped = nil return end
    SetEntityAsMissionEntity(corner_ped, true, true)
    TaskGoToEntity(corner_ped, player_ped, -1, 2.0, 1.0, 1073741824, 0)
    local this_ped = corner_ped
    local generation = corner_generation
    CreateThread(function()
        local expires = GetGameTimer() + 45000
        while dealing_mode == 'corner' and generation == corner_generation and corner_ped == this_ped
            and DoesEntityExist(this_ped) and GetGameTimer() < expires do
            if #(GetEntityCoords(this_ped) - GetEntityCoords(PlayerPedId())) < 3.0 then
                TaskTurnPedToFaceEntity(this_ped, PlayerPedId(), 1500)
                if not begin_sale(this_ped) then
                    DeletePed(this_ped)
                    corner_ped = nil
                    schedule_corner_customer()
                end
                return
            end
            Wait(500)
        end
        if corner_ped == this_ped then
            if DoesEntityExist(this_ped) then DeletePed(this_ped) end
            corner_ped = nil
            schedule_corner_customer()
        end
    end)
end)

function start_corner_dealing()
    corner_generation = corner_generation + 1
    TriggerEvent('boii_drugsales:cl:spawn_corner_customer')
end

function stop_corner_dealing()
    corner_generation = corner_generation + 1
    release_ped(dealing_target, dealing_target ~= corner_ped)
    if corner_ped and DoesEntityExist(corner_ped) then DeletePed(corner_ped) end
    corner_ped = nil
    if pending then
        TriggerServerEvent('boii_drugsales:sv:cancel_street_sale')
        close_offer()
    end
    pending = false
    dealing_target, target_coords = nil, nil
    used_peds = {}
end

RegisterNetEvent('boii_drugsales:cl:open_street_offer', function(data)
    if not pending or not dealing_target or not DoesEntityExist(dealing_target) then return end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open_street_offer', data = data })
end)

RegisterNUICallback('street_offer', function(data, cb)
    cb({ success = true })
    if not pending then return end
    close_offer()
    TriggerServerEvent('boii_drugsales:sv:submit_street_offer', data.drug_id, data.price)
end)

RegisterNUICallback('street_cancel', function(_, cb)
    cb({ success = true })
    if not pending then return end
    TriggerServerEvent('boii_drugsales:sv:cancel_street_sale')
    close_offer()
    pending = false
    local ped = dealing_target
    release_ped(ped, corner_ped ~= ped)
    if corner_ped then
        local old_ped = corner_ped
        SetTimeout(2500, function() if DoesEntityExist(old_ped) then DeletePed(old_ped) end end)
        corner_ped = nil
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
                    TriggerServerEvent('boii_drugsales:sv:recover_stolen_drugs', net_id)
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
                elseif TARGET == 'boii_target' then
                    exports.boii_target:add_entity_zone({ ped }, {
                        id = 'drug_recovery_' .. net_id, distance = 2.0,
                        actions = { label = lang.dealing.client.target.retrieve.label,
                            icon = 'fa-solid fa-box-open', action_type = 'function', action = action }
                    })
                end
                return
            end
            Wait(1000)
        end
    end)
end

RegisterNetEvent('boii_drugsales:cl:street_result', function(result)
    if not pending then return end
    close_offer()
    pending = false
    local ped = dealing_target
    local is_corner_customer = ped == corner_ped
    if ped and DoesEntityExist(ped) then
        if result.outcome == 'sold' then
            utils.requests.anim('mp_common')
            TaskPlayAnim(PlayerPedId(), 'mp_common', 'givetake2_a', 8.0, -8.0, 1800, 0, 0, false, false, false)
            TaskPlayAnim(ped, 'mp_common', 'givetake2_a', 8.0, -8.0, 1800, 0, 0, false, false, false)
            SetTimeout(1800, function() release_ped(ped, not is_corner_customer) end)
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
            release_ped(ped, not is_corner_customer)
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
        if result.outcome ~= 'stolen' and ped and DoesEntityExist(ped) then
            SetTimeout(2500, function() if DoesEntityExist(ped) then DeletePed(ped) end end)
        end
    end
    dealing_target, target_coords = nil, nil
    if result.reason == 'no_drugs' or result.reason == 'police' then
        TriggerEvent('boii_drugsales:cl:stop_dealing')
        return
    end
    schedule_corner_customer()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for ped in pairs(held_peds) do release_ped(ped, true) end
    if corner_ped and DoesEntityExist(corner_ped) then DeletePed(corner_ped) end
end)
