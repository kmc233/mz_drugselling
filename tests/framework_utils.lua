table.pack = table.pack or function(...) return { n = select('#', ...), ... } end

local selected, inventory, balance, xp, registered
local player = {}
local qb_core = { Functions = {} }
local esx_core = {}

GetResourceState = function(name)
    local active = { qbox = 'qbx_core', qb = 'qb-core', esx = 'es_extended' }
    return name == active[selected] and 'started' or 'missing'
end
GetPlayers = function() return { '1' } end
AddEventHandler = function() end
TriggerClientEvent = function() end
lib = { callback = { register = function() end } }

local function remove(item, amount)
    if (inventory[item] or 0) < amount then return false end
    inventory[item] = inventory[item] - amount
    return true
end
local function add(item, amount)
    inventory[item] = (inventory[item] or 0) + amount
    return true
end

exports = {
    qbx_core = {
        GetPlayer = function(_, source) return source == 1 and player or nil end,
        GetMetadata = function() return xp end,
        SetMetadata = function(_, _, _, value) xp = value end,
        CreateUseableItem = function(_, item) registered = item end
    },
    ['qb-core'] = { GetCoreObject = function() return qb_core end },
    es_extended = { getSharedObject = function() return esx_core end }
}
qb_core.Functions.GetPlayer = function(source) return source == 1 and player or nil end
qb_core.Functions.CreateUseableItem = function(item) registered = item end
esx_core.GetPlayerFromId = function(source) return source == 1 and player or nil end
esx_core.RegisterUsableItem = function(item) registered = item end

for _, name in ipairs({ 'qbox', 'qb', 'esx' }) do
    selected, inventory, balance, xp, registered = name, { water = 5, dealer_phone = 1 }, 0, 0, nil
    local can_carry = true
    config = { framework = 'auto', skills = { progression = { base_required_xp = 1000, required_xp_per_level = 100 } } }
    if name == 'esx' then
        player = {
            getJob = function() return { name = 'police' } end,
            getInventoryItem = function(item) return { count = inventory[item] or 0 } end,
            removeInventoryItem = remove,
            addInventoryItem = add,
            canCarryItem = function() return can_carry end,
            addMoney = function(amount) balance = balance + amount end,
            getMeta = function() return xp end,
            setMeta = function(_, value) xp = value end
        }
    else
        player = { PlayerData = { job = { name = 'police', onduty = true }, metadata = {} }, Functions = {
            GetItemByName = function(item) return { amount = inventory[item] or 0 } end,
            GetItemsByName = name == 'qbox' and function(item)
                local count = inventory[item] or 0
                return count > 1 and { { count = 1 }, { count = count - 1 } } or { { count = count } }
            end or nil,
            RemoveItem = remove,
            AddItem = add,
            AddMoney = function(_, amount) balance = balance + amount; return true end,
            SetMetaData = function(_, value) xp = value end
        } }
        if name == 'qb' then
            player.PlayerData.items = {
                { name = 'water', amount = 2 }, { name = 'water', amount = 3 },
                { name = 'dealer_phone', amount = 1 }
            }
        end
    end

    dofile('server/utils.lua')
    assert(utils.fw.player_has_job(1, { 'police' }, true), name .. ': job')
    assert(utils.fw.has_item(1, 'dealer_phone', 1), name .. ': phone')
    if name == 'qb' then
        assert(utils.fw.get_item(1, 'water').quantity == 5, name .. ': split slots')
        player.PlayerData.items = nil
    end
    assert(not utils.fw.adjust_inventory(1, { items = {{ action = 'remove', item_id = 'water', quantity = 6 }} }), name .. ': insufficient items')
    assert(utils.fw.adjust_inventory(1, { items = {{ action = 'remove', item_id = 'water', quantity = 2 }} }), name .. ': remove')
    assert(utils.fw.adjust_inventory(1, { items = {{ action = 'add', item_id = 'water', quantity = 1 }} }), name .. ': add')
    assert(utils.fw.get_item(1, 'water').quantity == 4, name .. ': count')
    if name == 'esx' then
        can_carry = false
        assert(not utils.fw.adjust_inventory(1, { items = {{ action = 'add', item_id = 'water', quantity = 1 }} }), name .. ': capacity')
        can_carry = true
    end
    assert(utils.fw.adjust_balance(1, { operations = {{ action = 'add', balance_type = 'cash', amount = 20 }} }), name .. ': balance')
    assert(balance == 20, name .. ': paid')
    utils.fw.register_item('dealer_phone', function() end)
    assert(registered == 'dealer_phone', name .. ': usable item')
    assert(utils.skills.modify_skill(1, 'drug_dealing', 1250, 'add'), name .. ': xp write')
    if name == 'qb' then player.PlayerData.metadata.mz_drugselling_xp = xp end
    local skill = utils.skills.get_skill(1, 'drug_dealing')
    assert(skill.level == 2 and skill.current_xp == 250 and xp == 1250, name .. ': xp read')
end

print('framework_utils: ok')
