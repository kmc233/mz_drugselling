--- @section Tables

local dealing_data = {}

--- @section Constants

local DEBUG <const> = debug_log
local POLICE_JOBS = config.deliveries.police.jobs
local REQUIRED_POLICE_COUNT = config.deliveries.police.required
local REQUIRE_ON_DUTY = config.deliveries.police.on_duty_required

--- @section Local functions

--- Fetch player data: inventory and skills
-- @param player_id number: The player's server ID.
-- @return table, table: The player's inventory and skills.
local function fetch_player_data(_src)
    local player_skills = utils.skills.get_skill(_src, 'drug_dealing') or { level = 1, current_xp = 0, required_xp = 1000 }
    return player_skills
end

--- Process player's drugs based on inventory and skills
-- @param player_skills table: The player's skills.
-- @return table: A table of the player's drugs with calculated prices and quantities.
local function process_player_drugs(_src, player_skills)
    local skill_config = config.skills.dealing.dealing
    local player_drugs = {}
    for _, drug in ipairs(config.drugs) do
        if drug.delivery then
            local inventory_item = utils.fw.get_item(_src, drug.id)
            local inventory_quantity = inventory_item and (inventory_item.quantity or inventory_item.count or inventory_item.amount) or 0
            if inventory_quantity > 0 and player_skills.level >= drug.delivery.required_level then
                local base_price = math.random(drug.delivery.price.min, drug.delivery.price.max)
                local price_multiplier = 1 + ((player_skills.level - 1) * skill_config.bonus_chance_multiplier)
                local adjusted_price = math.ceil(base_price * price_multiplier)
                local min_quantity = drug.delivery.quantity.min
                local max_quantity = math.min(drug.delivery.quantity.max, inventory_quantity)
                if max_quantity < min_quantity then
                    min_quantity = max_quantity
                end
                if min_quantity <= max_quantity then
                    local sell_quantity = math.random(min_quantity, max_quantity)
                    player_drugs[#player_drugs + 1] = {
                        id = drug.id,
                        label = drug.label,
                        image = drug.image,
                        required_level = drug.delivery.required_level,
                        price = adjusted_price,
                        quantity = sell_quantity
                    }
                end
            end
        end
    end
    return player_drugs
end

--- Select random drugs (max 3) from the player's available drugs
-- @param player_drugs table: The player's drugs.
-- @return table: A table of randomly selected drugs (max 3).
local function select_random_drugs(player_drugs)
    local selected_drugs = {}
    if #player_drugs > 3 then
        local selected_indices = {}
        while #selected_indices < 3 do
            local random_index = math.random(1, #player_drugs)
            if not selected_indices[random_index] then
                selected_indices[random_index] = true
                selected_drugs[#selected_drugs + 1] = player_drugs[random_index]
            end
        end
    else
        selected_drugs = player_drugs
    end
    return selected_drugs
end

--- @section Events

--- Sends a delivery to client
RegisterServerEvent('boii_drugsales:sv:request_delivery', function()
    local _src = source
    local police = get_police_players(POLICE_JOBS, REQUIRE_ON_DUTY)
    if #police < REQUIRED_POLICE_COUNT then
        send_notification(_src, lang.deliveries.server.notifications.header, string.format(lang.deliveries.server.notifications.not_enough_police, #police, REQUIRED_POLICE_COUNT), 'error', 3500)
        Wait(1000)
        TriggerClientEvent('boii_drugsales:cl:stop_deliveries', _src)
        return
    end
    Wait(10000) -- @todo make a config option and random
    local delivery_location = config.deliveries.locations[math.random(#config.deliveries.locations)]
    TriggerClientEvent('boii_drugsales:cl:spawn_delivery_ped', -1, _src, delivery_location)
end)

--- Main event to prepare sale data
RegisterServerEvent('boii_drugsales:sv:prepare_delivery_data', function()
    local _src = source
    if is_delivering then return end
    is_delivering = true
    local police = get_police_players(POLICE_JOBS, REQUIRE_ON_DUTY)
    if #police < REQUIRED_POLICE_COUNT then
        send_notification(_src, lang.deliveries.server.notifications.header, string.format(lang.deliveries.server.notifications.not_enough_police, #police, REQUIRED_POLICE_COUNT), 'error', 3500)
        Wait(1000)
        TriggerClientEvent('boii_drugsales:cl:stop_deliveries', _src)
        is_delivering = false
        return
    end
    local player_skills = fetch_player_data(_src)
    local player_drugs = process_player_drugs(_src, player_skills)
    if #player_drugs == 0 then
        send_notification(_src, lang.deliveries.server.notifications.header, lang.deliveries.server.notifications.no_drugs, 'error', 3500)
        TriggerClientEvent('boii_drugsales:cl:stop_deliveries', _src)
        is_delivering = false
        return
    end
    local selected_drugs = select_random_drugs(player_drugs)
    local sale_id = GetPlayerName(_src) .. "_" .. os.time() .. "_" .. math.random(100000, 999999)
    dealing_data[sale_id] = {
        source = _src,
        drugs = selected_drugs,
        timestamp = os.time()
    }
    local alert_chance = config.deliveries.chance.alert
    if math.random(1, 100) <= alert_chance then
        TriggerEvent('boii_drugsales:sv:alert_police', _src, 'delivery')
    else
        TriggerClientEvent('boii_drugsales:cl:delivery_decline_sale', _src)
    end
    TriggerClientEvent('boii_drugsales:cl:receive_delivery_data', _src, sale_id, selected_drugs)
end)

--- Event to handle completing deliveries.
--- @param data table: Table of sale data received from client.
RegisterServerEvent('boii_drugsales:sv:delivery_complete_sale', function(data)
    local _src = source
    local sale_id = data.sale_id
    local drug_id = data.drug_id
    local amount = data.amount
    local sale_data = dealing_data[sale_id]
    if not sale_data or sale_data.source ~= _src then
        DEBUG('err', lang.general.server.invalid_sale_data)
        is_delivering = false
        return
    end
    local success = complete_sale(_src, sale_data, drug_id, amount)
    if success then
        reward_xp(_src, sale_data.drugs, amount, 'dealing')
        dealing_data[sale_id] = nil
        TriggerClientEvent('boii_drugsales:cl:completed_delivery', _src)
    end
    is_delivering = false
end)