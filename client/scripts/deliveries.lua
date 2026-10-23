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
    local model_hash = GetHashKey(random_model)
    local scenarios = { 'WORLD_HUMAN_AA_COFFEE', 'WORLD_HUMAN_SMOKING' }
    local random_scenario = scenarios[math.random(#scenarios)]
    if not utils.requests.model(model_hash) then return end
    delivery_ped = CreatePed(4, model_hash, loc.x, loc.y, loc.z-1, loc.w, false, true)
    SetModelAsNoLongerNeeded(model_hash)
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
    for _, drug in ipairs(player_drugs) do
        local selected = drug
        drug_options[#drug_options + 1] = {
            icon = lang.deliveries.client.dialogue.conversation.sale_icon,
            title = string.format(lang.deliveries.client.dialogue.conversation.sale_message,
                drug.quantity, drug.label, math.ceil(drug.price * drug.quantity)),
            onSelect = function()
                TriggerServerEvent('boii_drugsales:sv:delivery_complete_sale', {
                    sale_id = sale_id, drug_id = selected.id, amount = selected.quantity
                })
            end
        }
    end
    drug_options[#drug_options + 1] = {
        icon = lang.deliveries.client.dialogue.conversation.exit_icon,
        title = lang.deliveries.client.dialogue.conversation.exit_message,
        onSelect = function() TriggerEvent('boii_drugsales:cl:stop_deliveries') end
    }
    lib.registerContext({
        id = 'mz_drugselling_delivery',
        title = lang.deliveries.client.dialogue.header.message,
        options = drug_options
    })
    lib.showContext('mz_drugselling_delivery')
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
