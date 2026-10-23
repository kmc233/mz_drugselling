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

--- @section Events

RegisterNetEvent('boii_drugsales:cl:spawn_delivery_ped', function(_src, location)
    local player_id = PlayerId()
    local loc = location
    if not loc then print('location missing') return end
    if GetPlayerFromServerId(_src) == player_id then
        delivery_blip = AddBlipForCoord(location.x, location.y, location.z)
        SetBlipSprite(delivery_blip, 51)
        SetBlipColour(delivery_blip, 1)
        SetBlipScale(delivery_blip, 0.7)
        SetBlipAsShortRange(delivery_blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString('Drug Delivery')
        EndTextCommandSetBlipName(delivery_blip)
        SetBlipRoute(delivery_blip, true)
        SetBlipRouteColour(delivery_blip, 1)

        send_notification(lang.deliveries.client.notifications.header, lang.deliveries.client.notifications.delivery_received, 'info', 3500)
    end
    local ped_models = { 'csb_money', 'a_m_y_beachvesp_01' }
    local random_model = ped_models[math.random(#ped_models)]
    local scenarios = { 'WORLD_HUMAN_AA_COFFEE', 'WORLD_HUMAN_SMOKING' }
    local random_scenario = scenarios[math.random(#scenarios)]
    utils.requests.model(random_model)
    delivery_ped = CreatePed(4, random_model, loc.x, loc.y, loc.z-1, loc.w, false, true)
    SetEntityInvincible(delivery_ped, true)
    SetBlockingOfNonTemporaryEvents(delivery_ped, true)
    TaskStartScenarioInPlace(delivery_ped, random_scenario, 0, true)
    if not NetworkGetEntityIsNetworked(delivery_ped) then
        NetworkRegisterEntityAsNetworked(delivery_ped)
    end
    
    if TARGET == 'boii_target' then
        exports.boii_target:add_entity_zone({ delivery_ped }, {
            id = 'boii_drugsales_delivery',
            main_icon = lang.deliveries.client.target.main_icon,
            distance = 2.5,
            debug = false,
            sprite = false,
            actions = {
                label = lang.deliveries.client.target.label,
                action_icon = lang.deliveries.client.target.action_icon,
                action_type = 'server',
                action = 'boii_drugsales:sv:prepare_delivery_data',
                params = {}
            }
        })
    elseif TARGET == 'qb-target' then
        exports['qb-target']:AddEntityZone('boii_drugsales_delivery', delivery_ped, {
            name = 'boii_drugsales_delivery',
            heading = 0.0,
            debugPoly = false,
        }, {
            distance = 2.5,
            options = {
                {
                    icon = lang.deliveries.client.target.action_icon,
                    label = lang.deliveries.client.target.label,
                    action = function()
                        TriggerServerEvent('boii_drugsales:sv:prepare_delivery_data')
                    end
                }
            }
        })
    elseif TARGET == 'ox_target' then
        exports.ox_target:addLocalEntity(delivery_ped, {
            {
                name = 'boii_drugsales_delivery',
                label = lang.deliveries.client.target.label,
                icon = lang.deliveries.client.target.action_icon,
                onSelect = function()
                    TriggerServerEvent('boii_drugsales:sv:prepare_delivery_data')
                end,
                distance = 2.5
            }
        })
    end
end)

RegisterNetEvent('boii_drugsales:cl:receive_delivery_data', function(sale_id, player_drugs)
    local drug_options = {}
    local drug_list = {}
    for _, drug in ipairs(player_drugs) do
        drug_options[#drug_options + 1] = {
            icon = lang.deliveries.client.dialogue.conversation.sale_icon,
            message = string.format(lang.deliveries.client.dialogue.conversation.sale_message, drug.quantity, drug.label, math.ceil(drug.price * drug.quantity)),
            next_id = nil,
            should_end = true,
            action_type = 'server',
            action = 'boii_drugsales:sv:delivery_complete_sale',
            params = { sale_id = sale_id, drug_id = drug.id, amount = drug.quantity }
        }
        drug_list[#drug_list + 1] = drug.label
    end
    drug_options[#drug_options + 1] = {
        icon = lang.deliveries.client.dialogue.conversation.exit_icon,
        message = lang.deliveries.client.dialogue.conversation.exit_message,
        next_id = nil,
        should_end = true,
        action_type = 'client',
        action = 'boii_drugsales:cl:stop_deliveries',
        params = {}
    }
    local first_response
    if #drug_list == 1 then
        first_response = string.format(lang.deliveries.client.dialogue.conversation.buy_1_message, drug_list[1])
    elseif #drug_list == 2 then
        first_response = string.format(lang.deliveries.client.dialogue.conversation.buy_2_message, drug_list[1], drug_list[2])
    elseif #drug_list == 3 then
        first_response = string.format(lang.deliveries.client.dialogue.conversation.buy_3_message, drug_list[1], drug_list[2], drug_list[3])
    end
    local dialogue = {
        header = {
            message = lang.deliveries.client.dialogue.header.message,
            icon = lang.deliveries.client.dialogue.header.icon,
        },
        conversation = {
            {
                id = 1,
                response = first_response,
                options = drug_options
            }
        }
    }
    local target_coords = GetEntityCoords(delivery_ped)
    exports.boii_ui:dialogue(dialogue, delivery_ped, target_coords)
end)

RegisterNetEvent('boii_drugsales:cl:completed_delivery', function()
    if delivery_blip then
        RemoveBlip(delivery_blip)
        delivery_blip = nil
    end

    if delivery_ped then
        utils.requests.anim('mp_common')
        local player_ped = PlayerPedId()
        TaskPlayAnim(player_ped, "mp_common", "givetake1_a", 8.0, -8.0, 2000, 0, 0, false, false, false)
        TaskPlayAnim(delivery_ped, "mp_common", "givetake1_b", 8.0, -8.0, 2000, 0, 0, false, false, false)
        Wait(2000)
        RemoveAnimDict("mp_common")
        SetPedAsNoLongerNeeded(delivery_ped)
        Wait(10000)
        DeletePed(delivery_ped)
        delivery_ped = nil
        TriggerServerEvent('boii_drugsales:sv:request_delivery')
    end
end)
