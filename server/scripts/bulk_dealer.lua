local function bulk_price(drug, level)
    local bulk_config = config.skills and config.skills.bulk or {}
    local sales_config = config.sales_adjustments and config.sales_adjustments.bulk or {}
    local level_bonus = tonumber(bulk_config.price_per_level) or 0
    local bulk_multiplier = tonumber(sales_config.price_multiplier) or 1
    local multiplier = 1 + (math.max(1, level or 1) - 1) * level_bonus
    return math.max(1, math.floor(drug.price.optimal * bulk_multiplier * multiplier + 0.5))
end

--- Get bulk dealer settings.
-- @param _src The player's server ID requesting the data.
-- @param data Unused parameter for consistency with callback pattern.
-- @param cb Callback function to return the configurations.
utils.callback.register('mz_drugselling:sv:get_bulk_dealer_data', function(_src, data, cb)
    local player_drugs = {}
    local player_skills = utils.skills.get_skill(_src, 'drug_dealing') or { level = 1, current_xp = 0, required_xp = 1000 }
    local image_path = config.inventoryImagePath
    if image_path == 'auto' then
        image_path = (utils.fw.name == 'qbox' or utils.fw.name == 'esx') and 'nui://ox_inventory/web/images/'
            or utils.fw.name == 'qb' and 'nui://qb-inventory/html/images/' or nil
    end
    for _, drug in ipairs(config.drugs) do
        if drug.price and drug.quantity then
            local inventory_item = utils.fw.get_item(_src, drug.id)
            local quantity = inventory_item and (inventory_item.quantity or inventory_item.count or inventory_item.amount) or 0
            player_drugs[#player_drugs + 1] = {
                id = drug.id,
                label = drug.label,
                image = image_path and ('%s/%s'):format(image_path:gsub('/+$', ''), drug.image or (drug.id .. '.png')) or nil,
                required_level = drug.required_level or 1,
                price = bulk_price(drug, player_skills.level),
                quantity = quantity
            }
        end
    end
    cb({
        skills = player_skills,
        drugs = player_drugs,
        price_multiplier = tonumber(config.sales_adjustments and config.sales_adjustments.bulk and config.sales_adjustments.bulk.price_multiplier) or 1,
        price_per_level = tonumber(config.skills and config.skills.bulk and config.skills.bulk.price_per_level) or 0
    }, 'Success')
end)

--- Bulk sell drugs.
--- @param _src The players server ID.
--- @param data The data containing drug ID and quantity to sell.
--- @param cb Callback function to return the success status and message.
utils.callback.register('mz_drugselling:sv:bulk_sell_drugs', function(_src, data, cb)
    if type(data) ~= 'table' then return cb(false, lang.general.server.invalid_sale_data) end
    local drug_id = data.drug
    local quantity_to_sell = tonumber(data.quantity)
    if not drug_id or not quantity_to_sell or quantity_to_sell < 1 or quantity_to_sell ~= math.floor(quantity_to_sell) then
        return cb(false, lang.general.server.invalid_sale_data)
    end
    local dealer = config.bulk_dealer.ped.coords
    local player_ped = GetPlayerPed(_src)
    if not config.bulk_dealer.enabled or player_ped == 0
        or #(GetEntityCoords(player_ped) - vector3(dealer.x, dealer.y, dealer.z)) > 5.0 then
        return cb(false, lang.general.server.invalid_sale_data)
    end
    local drug = nil
    for _, d in ipairs(config.drugs) do
        if d.id == drug_id then
            drug = d
            break
        end
    end
    if not drug or not drug.price then return cb(false, lang.general.server.missing_drug_config) end
    local skill = utils.skills.get_skill(_src, 'drug_dealing') or { level = 1 }
    if skill.level < (drug.required_level or 1) then return cb(false, lang.general.server.invalid_sale_data) end
    local inventory_item = utils.fw.get_item(_src, drug_id)
    if not inventory_item or (inventory_item.quantity or inventory_item.amount or inventory_item.count) < quantity_to_sell then
        return cb(false, lang.general.server.insufficient_quantity)
    end
    local sale_data = { drugs = {{ id = drug_id, label = drug.label, price = bulk_price(drug, skill.level) }} }
    local success = complete_sale(_src, sale_data, drug_id, quantity_to_sell)
    if success then
        reward_xp(_src, drug, quantity_to_sell, 'bulk')
        local updated_skill = utils.skills.get_skill(_src, 'drug_dealing')
        cb(true, string.format(lang.bulk_dealer.server.bulk_sell_notification, sale_data.drugs[1].price * quantity_to_sell, quantity_to_sell, drug.label), updated_skill)
    else
        cb(false, lang.general.server.invalid_sale_data)
    end
end)
