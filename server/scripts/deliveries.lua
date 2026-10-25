--- @section Tables

local dealing_data = {}
local preparing = {}
local active_locations = {}
local request_ids = {}
local pending_requests = {}

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
                local price_multiplier = 1 + ((player_skills.level - 1) * skill_config.bonus_chance_multiplier)
                local min_price = math.ceil(drug.delivery.price.min * price_multiplier)
                local max_price = math.ceil(drug.delivery.price.max * price_multiplier)
                local optimal_price = math.random(min_price, max_price)
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
                        count = sell_quantity,
                        required_level = drug.delivery.required_level,
                        price = optimal_price,
                        min = min_price,
                        optimal = optimal_price,
                        max = max_price,
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
RegisterServerEvent('mz_drugselling:sv:request_delivery', function()
    local _src = source
    if sale_modes[_src] ~= 'delivery' then return end
    if active_locations[_src] or pending_requests[_src] then return end
    request_ids[_src] = (request_ids[_src] or 0) + 1
    local request_id = request_ids[_src]
    pending_requests[_src] = request_id
    local police = get_police_players(POLICE_JOBS, REQUIRE_ON_DUTY)
    if #police < REQUIRED_POLICE_COUNT then
        send_notification(_src, lang.deliveries.server.notifications.header, string.format(lang.deliveries.server.notifications.not_enough_police, #police, REQUIRED_POLICE_COUNT), 'error', 3500)
        Wait(1000)
        TriggerClientEvent('mz_drugselling:cl:stop_deliveries', _src)
        pending_requests[_src] = nil
        return
    end
    Wait(10000) -- @todo make a config option and random
    if sale_modes[_src] ~= 'delivery' or request_ids[_src] ~= request_id then return end
    pending_requests[_src] = nil
    local delivery_location = config.deliveries.locations[math.random(#config.deliveries.locations)]
    active_locations[_src] = delivery_location
    TriggerClientEvent('mz_drugselling:cl:spawn_delivery_ped', _src, _src, delivery_location)
end)

RegisterServerEvent('mz_drugselling:sv:delivery_submit_offer', function(data)
    local _src = source
    if type(data) ~= 'table' then return end
    local sale_id, drug_id = data.sale_id, data.drug_id
    local price = tonumber(data.price)
    local sale_data = dealing_data[sale_id]
    local location = active_locations[_src]
    local player_ped = GetPlayerPed(_src)
    if not sale_data or sale_data.source ~= _src or sale_data.location ~= location
        or sale_modes[_src] ~= 'delivery' or not location or player_ped == 0
        or #(GetEntityCoords(player_ped) - vector3(location.x, location.y, location.z)) > 6.0
        or not price or price ~= math.floor(price) then return end
    local selected
    for _, offer in ipairs(sale_data.drugs) do
        if offer.id == drug_id then selected = offer break end
    end
    if not selected or price < selected.min or price > selected.max then return end
    if not complete_sale(_src, { drugs = {{ id = selected.id, label = selected.label, price = price, quantity = selected.quantity }} }, selected.id, selected.quantity, 'delivery') then return end
    reward_xp(_src, sale_data.drugs, selected.quantity, 'dealing')
    dealing_data[sale_id] = nil
    active_locations[_src] = nil
    preparing[_src] = nil
    TriggerClientEvent('mz_drugselling:cl:completed_delivery', _src)
end)

RegisterServerEvent('mz_drugselling:sv:delivery_cancel_offer', function()
    local _src = source
    local sale_id = preparing[_src]
    if sale_id then dealing_data[sale_id] = nil end
    preparing[_src] = nil
end)

--- Main event to prepare sale data
RegisterServerEvent('mz_drugselling:sv:prepare_delivery_data', function()
    local _src = source
    local location = active_locations[_src]
    local player_ped = GetPlayerPed(_src)
    if sale_modes[_src] ~= 'delivery' or preparing[_src] or not location or player_ped == 0
        or #(GetEntityCoords(player_ped) - vector3(location.x, location.y, location.z)) > 6.0 then return end
    preparing[_src] = true
    local police = get_police_players(POLICE_JOBS, REQUIRE_ON_DUTY)
    if #police < REQUIRED_POLICE_COUNT then
        send_notification(_src, lang.deliveries.server.notifications.header, string.format(lang.deliveries.server.notifications.not_enough_police, #police, REQUIRED_POLICE_COUNT), 'error', 3500)
        Wait(1000)
        TriggerClientEvent('mz_drugselling:cl:stop_deliveries', _src)
        preparing[_src] = nil
        return
    end
    local player_skills = fetch_player_data(_src)
    local player_drugs = process_player_drugs(_src, player_skills)
    if #player_drugs == 0 then
        send_notification(_src, lang.deliveries.server.notifications.header, lang.deliveries.server.notifications.no_drugs, 'error', 3500)
        TriggerClientEvent('mz_drugselling:cl:stop_deliveries', _src)
        preparing[_src] = nil
        return
    end
    local selected_drugs = select_random_drugs(player_drugs)
    local sale_id = GetPlayerName(_src) .. "_" .. os.time() .. "_" .. math.random(100000, 999999)
    preparing[_src] = sale_id
    dealing_data[sale_id] = {
        source = _src,
        drugs = selected_drugs,
        location = location,
        timestamp = os.time()
    }
    local alert_chance = config.deliveries.chance.alert
    if math.random(1, 100) <= alert_chance then
        alert_police(_src, 'delivery')
    end
    TriggerClientEvent('mz_drugselling:cl:receive_delivery_data', _src, sale_id, selected_drugs)
    SetTimeout(60000, function()
        if preparing[_src] == sale_id then preparing[_src] = nil end
        dealing_data[sale_id] = nil
    end)
end)

--- Event to handle completing deliveries.
--- @param data table: Table of sale data received from client.
RegisterServerEvent('mz_drugselling:sv:delivery_complete_sale', function(data)
    local _src = source
    if type(data) ~= 'table' then return end
    local sale_id = data.sale_id
    local drug_id = data.drug_id
    local amount = data.amount
    local sale_data = dealing_data[sale_id]
    local location = active_locations[_src]
    local player_ped = GetPlayerPed(_src)
    if not sale_data or sale_data.source ~= _src or sale_data.location ~= location or sale_modes[_src] ~= 'delivery'
        or not location or player_ped == 0
        or #(GetEntityCoords(player_ped) - vector3(location.x, location.y, location.z)) > 6.0 then
        debug_log('err', lang.general.server.invalid_sale_data)
        preparing[_src] = nil
        return
    end
    local success = complete_sale(_src, sale_data, drug_id, amount, 'delivery')
    if success then
        reward_xp(_src, sale_data.drugs, amount, 'dealing')
        dealing_data[sale_id] = nil
        active_locations[_src] = nil
        TriggerClientEvent('mz_drugselling:cl:completed_delivery', _src)
    end
    preparing[_src] = nil
end)

AddEventHandler('mz_drugselling:sv:stop_phone_action', function()
    request_ids[source] = (request_ids[source] or 0) + 1
    pending_requests[source] = nil
    active_locations[source] = nil
    preparing[source] = nil
    for id, deal in pairs(dealing_data) do
        if deal.source == source then dealing_data[id] = nil end
    end
end)

AddEventHandler('playerDropped', function()
    preparing[source] = nil
    active_locations[source] = nil
    request_ids[source] = nil
    pending_requests[source] = nil
    for id, deal in pairs(dealing_data) do
        if deal.source == source then dealing_data[id] = nil end
    end
end)
