--- Get bulk dealer settings.
-- @param _src The player's server ID requesting the data.
-- @param data Unused parameter for consistency with callback pattern.
-- @param cb Callback function to return the configurations.
utils.callback.register('boii_drugsales:sv:get_bulk_dealer_data', function(_src, data, cb)
    local player_drugs = {}
    local player_skills = utils.skills.get_skill(_src, 'drug_dealing') or { level = 1, current_xp = 0, required_xp = 1000 }
    local skill_config = config.skills.dealing.bulk
    for _, drug in ipairs(config.drugs) do
        local inventory_item = utils.fw.get_item(_src, drug.id)
        local quantity = 0
        if inventory_item then
            quantity = inventory_item.quantity or inventory_item.count or inventory_item.amount or 0
        end
        local base_price = drug.bulk.price
        local price_multiplier = 1 + ((player_skills.level - 1) * skill_config.bonus_chance_multiplier)
        local adjusted_price = math.ceil(base_price * price_multiplier)
        player_drugs[#player_drugs + 1] = {
            id = drug.id,
            label = drug.label,
            image = drug.image,
            required_level = drug.bulk.required_level,
            price = adjusted_price,
            quantity = quantity
        }
    end
    cb({ skills = player_skills, drugs = player_drugs }, 'Success')
end)

--- Bulk sell drugs.
--- @param _src The players server ID.
--- @param data The data containing drug ID and quantity to sell.
--- @param cb Callback function to return the success status and message.
utils.callback.register('boii_drugsales:sv:bulk_sell_drugs', function(_src, data, cb)
    local dealer_location = data.location
    local drug_id = data.drug
    local quantity_to_sell = tonumber(data.quantity)
    if not drug_id or not quantity_to_sell then return cb(false) end
    local drug = nil
    for _, d in ipairs(config.drugs) do
        if d.id == drug_id then
            drug = d
            break
        end
    end
    if not drug then return cb(false, lang.general.server.missing_drug_config) end
    local inventory_item = utils.fw.get_item(_src, drug_id)
    if not inventory_item or (inventory_item.quantity or inventory_item.amount or inventory_item.count) < quantity_to_sell then
        return cb(false, lang.general.server.insufficient_quantity)
    end
    local sale_data = { drugs = {{ id = drug_id, label = drug.label, price = drug.bulk.price }} }
    local success = complete_sale(_src, sale_data, drug_id, quantity_to_sell)
    if success then
        reward_xp(_src, drug, quantity_to_sell, 'bulk')
        cb(true, string.format(lang.bulk_dealer.server.bulk_sell_notification, quantity_to_sell, drug.label, sale_data.drugs[1].price * quantity_to_sell))
    else
        cb(false, lang.general.server.invalid_sale_data)
    end
end)
