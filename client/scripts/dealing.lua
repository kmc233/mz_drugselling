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

--- @section Tables

--- Stores sales records for entities.
local sales_records = {}

--- @section Events

--- Receives sale data and builds dialogue
-- @param sale_id: Unique ID to match the sale server side when awarding.
-- @param player_drugs: Drugs table of the drugs the player can sell in this single conversation.
RegisterNetEvent('boii_drugsales:cl:receive_sale_data', function(sale_id, player_drugs, failed, action_chance)
    local drug_options = {}
    local drug_list = {}
    for _, drug in ipairs(player_drugs) do
        drug_options[#drug_options + 1] = {
            icon = lang.dealing.client.dialogue.conversation.sale_icon,
            message = string.format(lang.dealing.client.dialogue.conversation.sale_message, drug.quantity, drug.label, math.ceil(drug.price * drug.quantity)),
            next_id = nil,
            should_end = true,
            action_type = 'server',
            action = 'boii_drugsales:sv:dealing_complete_sale',
            params = { sale_id = sale_id, drug_id = drug.id, amount = drug.quantity }
        }
        drug_list[#drug_list + 1] = drug.label
    end
    drug_options[#drug_options + 1] = {
        icon = lang.dealing.client.dialogue.conversation.exit_icon,
        message = lang.dealing.client.dialogue.conversation.exit_message,
        next_id = nil,
        should_end = true
    }
    local first_response
    if #drug_list == 1 then
        first_response = string.format(lang.dealing.client.dialogue.conversation.buy_1_message, drug_list[1])
    elseif #drug_list == 2 then
        first_response = string.format(lang.dealing.client.dialogue.conversation.buy_2_message, drug_list[1], drug_list[2])
    elseif #drug_list == 3 then
        first_response = string.format(lang.dealing.client.dialogue.conversation.buy_3_message, drug_list[1], drug_list[2], drug_list[3])
    end
    local dialogue = {
        header = {
            message = lang.dealing.client.dialogue.header.message,
            icon = lang.dealing.client.dialogue.header.icon,
        },
        conversation = {
            {
                id = 1,
                response = first_response,
                options = drug_options
            }
        }
    }
    local player_ped = PlayerPedId()
    dealing_target, target_coords = utils.entities.get_target_ped(player_ped, 45.0, 5.0)
    if not dealing_target then
        debug_log('err', lang.general.client.no_valid_target)
        return
    end
    if not NetworkGetEntityIsNetworked(dealing_target) then
        NetworkRegisterEntityAsNetworked(dealing_target)
    end
    local entity_net_id = NetworkGetNetworkIdFromEntity(dealing_target)
    if sales_records[entity_net_id] then
        send_notification(lang.dealing.client.notifications.header, lang.dealing.client.notifications.already_tried, 'error', 3500)
        return
    end
    ClearPedTasksImmediately(dealing_target)
    TaskTurnPedToFaceEntity(dealing_target, player_ped, -1)
    TaskLookAtEntity(dealing_target, player_ped, -1, 2048, 3)
    Wait(1000)
    ClearPedTasksImmediately(dealing_target)
    Wait(250)
    TaskTurnPedToFaceEntity(dealing_target, player_ped, -1)
    local distance_to_stop = 2.0
    TaskGoToEntity(dealing_target, player_ped, -1, distance_to_stop, 1, 1073741824, 0)
    CreateThread(function()
        while true do
            local target_coords = GetEntityCoords(dealing_target)
            local player_coords = GetEntityCoords(player_ped)
            local distance = #(player_coords - target_coords)
            if distance <= distance_to_stop then
                break
            end
            Wait(100)
        end
        ClearPedTasks(dealing_target)
        TaskStartScenarioInPlace(dealing_target, 'WORLD_HUMAN_STAND_IMPATIENT_UPRIGHT', 0, false)
        Wait(1000)
        if failed then
            ClearPedTasks(dealing_target)
            TriggerEvent('boii_drugsales:cl:dealing_decline_sale', sale_id, action_chance)
        else
            exports.boii_ui:dialogue(dialogue, dealing_target, target_coords)
            Wait(250)
            ClearPedTasks(player_ped)
        end
        sales_records[entity_net_id] = true
    end)
end)

RegisterNetEvent('boii_drugsales:cl:complete_sale_anim', function()
    utils.requests.anim('mp_common')
    local player_ped = PlayerPedId()
    if dealing_target then
        TaskPlayAnim(player_ped, 'mp_common', 'givetake2_a', 8.0, -8, -1, 0, 0, false, false, false)    
        TaskPlayAnim(dealing_target, 'mp_common', 'givetake2_a', 8.0, -8, -1, 0, 0, false, false, false)    	
        Wait(2000)
        StopAnimTask(player_ped, 'mp_common', 'givetake2_a', 1.0)
	    StopAnimTask(dealing_target, 'mp_common', 'givetake2_a', 1.0)
        SetPedAsNoLongerNeeded(dealing_target)
        ClearPedTasks(dealing_target)
        dealing_target, target_coords = nil, nil
    end
end)

local gang_member_models = {
    'g_m_y_ballaeast_01',
    'g_m_y_ballaorig_01',
    'g_m_y_ballasout_01',
    'g_m_y_famca_01',
    'g_m_y_famdnf_01',
    'g_m_y_famfor_01',
    'g_m_y_lost_01',
    'g_m_y_lost_02',
    'g_m_y_lost_03',
    'g_m_y_mexgoon_01',
    'g_m_y_mexgoon_02',
    'g_m_y_mexgoon_03',
    'g_m_y_pologoon_01',
    'g_m_y_pologoon_02',
    'g_m_y_salvaboss_01',
    'g_m_y_salvagoon_01',
    'g_m_y_salvagoon_02',
    'g_m_y_salvagoon_03',
    'g_m_y_strpunk_01',
    'g_m_y_strpunk_02'
}

local function is_gang_member(ped)
    local model = GetEntityModel(ped)
    for _, gang_model in ipairs(gang_member_models) do
        if model == GetHashKey(gang_model) then
            return true
        end
    end
    return false
end

-- Set relationship groups
local PLAYER_GROUP = GetHashKey('PLAYER')
local GANG_GROUP = GetHashKey('GANG')

AddRelationshipGroup('GANG')

--- Steal drugs
-- @param player_ped: PlayerPedId() for player.
-- @param sale_id: Sale ID for the transaction to remove correct drugs.
local function steal_drugs(player_ped, sale_id)
    ClearPedTasksImmediately(dealing_target)
    local cam_x, cam_y, cam_z = table.unpack(GetGameplayCamCoords())
    TaskTurnPedToFaceCoord(dealing_target, cam_x, cam_y, cam_z, 1000)
    TaskStandStill(dealing_target, 1000)

    if is_gang_member(dealing_target) then
        GiveWeaponToPed(dealing_target, GetHashKey("WEAPON_PISTOL"), 50, false, true)
        SetCurrentPedWeapon(dealing_target, GetHashKey("WEAPON_PISTOL"), true)
        SetPedAmmo(dealing_target, GetHashKey("WEAPON_PISTOL"), 50)
        TaskAimGunAtEntity(dealing_target, player_ped, -1, true)
        FreezeEntityPosition(player_ped, true)
        Wait(2000)
        utils.requests.anim('random@mugging3')
        TaskPlayAnim(player_ped, 'random@mugging3', 'handsup_standing_base', 8.0, -8, -1, 49, 0, false, false, false)
        Wait(2000)
        utils.requests.anim('mini@repair')
        TaskPlayAnim(dealing_target, 'mini@repair', 'fixing_a_ped', 8.0, -8.0, 2000, 0, 0, false, false, false)
        Wait(2000)
        StopAnimTask(dealing_target, 'mini@repair', 'fixing_a_ped', 1.0)
        Wait(2000)
        StopAnimTask(player_ped, 'random@mugging3', 'handsup_standing_base', 1.0)
        TaskAimGunAtEntity(dealing_target, player_ped, -1, true)
        FreezeEntityPosition(player_ped, false)
        SetPedRelationshipGroupHash(dealing_target, GANG_GROUP)
        SetRelationshipBetweenGroups(5, GANG_GROUP, PLAYER_GROUP)
        SetRelationshipBetweenGroups(5, PLAYER_GROUP, GANG_GROUP)
    else
        utils.requests.anim('melee@unarmed@streamed_variations')
        Wait(50)
        TaskPlayAnim(dealing_target, 'melee@unarmed@streamed_variations', 'plyr_takedown_front_headbutt', 8.0, 8.0, -1, 50, 0, false, false, false)
        SetPedToRagdoll(player_ped, 5000, 5000, 0, 0, 0, 0)
        Wait(1000)
        utils.requests.anim('amb@prop_human_bum_bin@idle_b')
        FreezeEntityPosition(dealing_target, true)
        TaskPlayAnim(dealing_target, 'amb@prop_human_bum_bin@idle_b', 'idle_d', 100.0, 200.0, -1, 120, 0.2, false, false, false)
        Wait(2000)
        StopAnimTask(dealing_target, 'amb@prop_human_bum_bin@idle_b', 'idle_d', 1.0)
        FreezeEntityPosition(dealing_target, false)
        TaskReactAndFleePed(dealing_target, player_ped)
        Wait(1000)
    end
    ClearPedTasks(player_ped)
    TriggerServerEvent('boii_drugsales:sv:dealing_remove_drugs', sale_id)
    TriggerEvent('boii_drugsales:cl:stop_dealing')

    CreateThread(function()
        while true do
            Wait(1000)
            if IsPedDeadOrDying(dealing_target, true) then
                if TARGET == 'boii_target' then
                    exports.boii_target:add_entity_zone({ dealing_target }, {
                        id = 'boii_drugsales_steal',
                        icon = lang.dealing.client.target.retrieve.main_icon,
                        distance = 2.5,
                        debug = false,
                        sprite = false,
                        actions = {
                            label = lang.dealing.client.target.retrieve.label,
                            action_icon = lang.dealing.client.target.retrieve.action_icon,
                            action_type = 'server',
                            action = 'boii_drugsales:sv:take_back_drugs',
                            params = { sale_id = sale_id }
                        }
                    })
                elseif TARGET == 'qb-target' then
                    exports['qb-target']:AddEntityZone('boii_drugsales_steal', dealing_target, {
                        name = 'boii_drugsales_steal',
                        heading = 0.0,
                        debugPoly = false,
                    }, {
                        distance = 2.5,
                        options = {
                            {
                                icon = lang.dealing.client.target.retrieve.action_icon,
                                label = lang.dealing.client.target.retrieve.label,
                                action = function()
                                    TriggerServerEvent('boii_drugsales:sv:take_back_drugs', { sale_id = sale_id })
                                end
                            }
                        }
                    })
                elseif TARGET == 'ox_target' then
                    exports.ox_target:addLocalEntity(dealing_target, {
                        {
                            name = 'boii_drugsales_steal',
                            label = lang.dealing.client.target.retrieve.label,
                            icon = lang.dealing.client.target.retrieve.action_icon,
                            onSelect = function()
                                TriggerServerEvent('boii_drugsales:sv:take_back_drugs', { sale_id = sale_id })
                            end,
                            distance = 2.5
                        }
                    })
                end
                break
            end
        end
    end)
end

--- Decline sale and walk away
-- @param player_ped: PlayerPedId() for player.
local function decline_and_walk_away()
    ClearPedTasksImmediately(dealing_target)
    utils.requests.anim('gestures@m@standing@casual')
    TaskPlayAnim(dealing_target, 'gestures@m@standing@casual', 'gesture_no_way', 8.0, -8, -1, 0, 0, false, false, false)   
    Wait(2000)
    StopAnimTask(dealing_target, 'gestures@m@standing@casual', 'gesture_no_way', 1.0)
    TaskWanderStandard(dealing_target, 10.0, 10)
    dealing_target, target_coords = nil, nil
end

--- Call police
-- @param player_ped: PlayerPedId() for player.
-- @param sale_id: Sale ID for the transaction.
local function call_police()
    decline_and_walk_away()
    TriggerServerEvent('boii_drugsales:sv:alert_police', GetPlayerServerId(PlayerId()), 'dealing')
    dealing_target, target_coords = nil, nil
end

--- Handles failed sales
-- @param sale_id: Sale ID for the transaction to remove correct drugs.
-- @param chance: The chance to perform different actions.
RegisterNetEvent('boii_drugsales:cl:dealing_decline_sale', function(sale_id, chance)
    local player_ped = PlayerPedId()
    if dealing_target then
        if chance < 10 then
            steal_drugs(player_ped, sale_id)
        elseif chance >= 10 and chance < 30 then
            call_police(player_ped)
        else
            decline_and_walk_away(player_ped)
        end
    end
end)


--- Retreive drugs after being stolen.
RegisterNetEvent('boii_drugsales:cl:take_back_complete', function()
    print('take back complete')
    local player_ped = PlayerPedId()
    FreezeEntityPosition(player_ped, true)
    utils.requests.anim('amb@prop_human_bum_bin@idle_b')
    TaskPlayAnim(player_ped, 'amb@prop_human_bum_bin@idle_b', 'idle_d', 100.0, 200.0, -1, 120, 0.2, false, false, false)
    Wait(2000)
    StopAnimTask(player_ped, 'amb@prop_human_bum_bin@idle_b', 'idle_d', 1.0)
    FreezeEntityPosition(player_ped, false)
    if TARGET == 'boii_target' then
        exports.boii_target:remove_target('boii_drugsales_steal')
    elseif TARGET == 'qb-target' then
        exports['qb-target']:RemoveZone('boii_drugsales_steal')
    elseif TARGET == 'ox_target' then
        exports.ox_target:removeGlobalPed({ 'boii_drugsales_steal' })
    end
    dealing_target, target_coords = nil, nil
end)