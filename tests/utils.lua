table.pack = table.pack or function(...)
    return { n = select('#', ...), ... }
end
table.unpack = table.unpack or unpack

local callbacks = {}
local stored_xp = 0
local inventory = { water = 5, dealer_phone = 1 }
local notices = {}

lib = { callback = { register = function(name, handler) callbacks[name] = handler end } }
exports = {
    qbx_core = {
        GetPlayer = function(_, source)
            if source ~= 1 then return nil end
            return { PlayerData = { job = { name = 'police', onduty = true } },
                Functions = { AddMoney = function() return true end } }
        end,
        GetMetadata = function()
            if stored_xp == 0 then return end
            return stored_xp
        end,
        SetMetadata = function(_, _, _, value) stored_xp = value end,
        CreateUseableItem = function() end
    },
    ox_inventory = {
        GetItemCount = function(_, _, item) return inventory[item] or 0 end,
        RemoveItem = function(_, _, item, amount)
            if (inventory[item] or 0) < amount then return false end
            inventory[item] = inventory[item] - amount
            return true
        end,
        AddItem = function(_, _, item, amount)
            inventory[item] = (inventory[item] or 0) + amount
            return true
        end
    }
}
GetPlayers = function() return { '1' } end
TriggerClientEvent = function(_, _, data) notices[#notices + 1] = data end
AddEventHandler = function() end

dofile('server/utils.lua')
assert(utils.fw.player_has_job('1', { 'police' }, true))
assert(not utils.fw.player_has_job('1', { 'fib' }, true))
assert(utils.fw.has_item(1, 'dealer_phone', 1))
local initial_skill = utils.skills.get_skill(1, 'drug_dealing')
assert(initial_skill.level == 1 and initial_skill.current_xp == 0)
assert(not utils.fw.adjust_inventory(1, { items = {{ item_id = 'water', action = 'remove', quantity = 6 }} }))
assert(inventory.water == 5)
assert(utils.fw.adjust_inventory(1, { items = {{ item_id = 'water', action = 'remove', quantity = 2 }} }))
assert(inventory.water == 3)

utils.skills.modify_skill(1, 'drug_dealing', 1250, 'add')
local skill = utils.skills.get_skill(1, 'drug_dealing')
assert(skill.level == 2 and skill.current_xp == 250 and stored_xp == 1250)

utils.callback.register('test', function(_, _, cb) cb(true, 'ok', skill) end)
local ok, message, returned_skill = callbacks.test(1, {})
assert(ok and message == 'ok' and returned_skill.level == 2)

utils.ui.notify(1, { header = 'Test', message = 'Ready', type = 'success' })
assert(notices[1].title == 'Test' and notices[1].description == 'Ready')
print('utils: ok')
