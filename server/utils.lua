utils = { callback = {}, cooldowns = {}, debug = {}, fw = {}, skills = {}, ui = {} }

local cooldowns = {}
local skill_key = 'mz_drugselling_xp'
local framework = config.framework or 'auto'
if framework == 'auto' then
    if GetResourceState('qbx_core') == 'started' then framework = 'qbox'
    elseif GetResourceState('qb-core') == 'started' then framework = 'qb'
    elseif GetResourceState('es_extended') == 'started' then framework = 'esx' end
end
assert(framework == 'qbox' or framework == 'qb' or framework == 'esx',
    'mz_drugselling: start qbx_core, qb-core, or es_extended before this resource')
local core = framework == 'qb' and exports['qb-core']:GetCoreObject()
    or framework == 'esx' and exports.es_extended:getSharedObject()
utils.fw.name = framework

local function get_player(source)
    if framework == 'qbox' then return exports.qbx_core:GetPlayer(tonumber(source)) end
    if framework == 'qb' then return core.Functions.GetPlayer(tonumber(source)) end
    return core.GetPlayerFromId(tonumber(source))
end

for _, level in ipairs({ 'err', 'warn', 'info' }) do
    utils.debug[level] = function(message)
        print(('[mz_drugselling] %s: %s'):format(level, tostring(message)))
    end
end

function utils.callback.register(name, handler)
    lib.callback.register(name, function(source, data)
        local result
        handler(source, data, function(...)
            result = table.pack(...)
        end)
        if result then return table.unpack(result, 1, result.n) end
    end)
end

function utils.ui.notify(source, data)
    TriggerClientEvent('ox_lib:notify', source, {
        title = data.header, description = data.message,
        type = data.type == 'police' and 'warning' or data.type,
        duration = data.duration
    })
end

function utils.fw.get_players()
    return GetPlayers()
end

function utils.fw.player_has_job(source, jobs, on_duty)
    local player = get_player(source)
    local job = player and (framework == 'esx' and (player.getJob and player.getJob() or player.job) or player.PlayerData.job)
    if not job or (on_duty and framework ~= 'esx' and not job.onduty)
        or (on_duty and framework == 'esx' and job.onDuty == false) then return false end
    for _, name in ipairs(jobs) do
        if job.name == name then return true end
    end
    return false
end

function utils.fw.get_item(source, item)
    local player = get_player(source)
    if not player then return { quantity = 0 } end
    if framework == 'esx' then
        local found = player.getInventoryItem(item)
        return { quantity = found and (found.count or found.amount or found.quantity) or 0 }
    end
    if player.Functions.GetItemsByName then
        local found = player.Functions.GetItemsByName(item)
        local total = 0
        for _, slot in pairs(found or {}) do
            total = total + (slot.count or slot.amount or slot.quantity or 0)
        end
        return { quantity = total }
    end
    if player.PlayerData.items then
        local total = 0
        for _, slot in pairs(player.PlayerData.items) do
            if slot.name == item then total = total + (slot.count or slot.amount or slot.quantity or 0) end
        end
        return { quantity = total }
    end
    local found = player.Functions.GetItemByName(item)
    return { quantity = found and (found.count or found.amount or found.quantity) or 0 }
end

function utils.fw.has_item(source, item, amount)
    return utils.fw.get_item(source, item).quantity >= amount
end

function utils.fw.adjust_inventory(source, data)
    local player = get_player(source)
    if not player then return false end
    for _, entry in ipairs(data.items) do
        if entry.action == 'remove' then
            if not utils.fw.has_item(source, entry.item_id, entry.quantity) then return false end
            if framework == 'esx' then
                player.removeInventoryItem(entry.item_id, entry.quantity)
            elseif not player.Functions.RemoveItem(entry.item_id, entry.quantity) then return false end
        elseif entry.action == 'add' then
            if framework == 'esx' then
                if player.canCarryItem and not player.canCarryItem(entry.item_id, entry.quantity) then return false end
                player.addInventoryItem(entry.item_id, entry.quantity, entry.data)
            elseif not player.Functions.AddItem(entry.item_id, entry.quantity, false, entry.data) then return false end
        else
            return false
        end
    end
    return true
end

function utils.fw.adjust_balance(source, data)
    local player = get_player(source)
    if not player then return false end
    for _, operation in ipairs(data.operations) do
        if operation.action ~= 'add' then return false end
        if framework == 'esx' then
            if operation.balance_type == 'cash' or operation.balance_type == 'money' then
                player.addMoney(operation.amount, data.reason)
            else
                player.addAccountMoney(operation.balance_type, operation.amount, data.reason)
            end
        elseif not player.Functions.AddMoney(operation.balance_type, operation.amount, data.reason) then return false end
    end
    return true
end

function utils.fw.register_item(item, handler)
    if framework == 'qbox' then exports.qbx_core:CreateUseableItem(item, handler)
    elseif framework == 'qb' then core.Functions.CreateUseableItem(item, handler)
    else core.RegisterUsableItem(item, handler) end
end

function utils.skills.get_skill(source, name)
    if name ~= 'drug_dealing' then return nil end
    local player = get_player(source)
    local stored_xp
    if framework == 'qbox' then stored_xp = exports.qbx_core:GetMetadata(source, skill_key)
    elseif framework == 'qb' then stored_xp = player and player.PlayerData.metadata and player.PlayerData.metadata[skill_key]
    else stored_xp = player and player.getMeta and player.getMeta(skill_key) end
    local xp = tonumber(stored_xp) or 0
    xp = math.max(0, math.floor(xp))
    local progression = config and config.skills and config.skills.progression or {}
    local base_required = math.max(1, tonumber(progression.base_required_xp) or 1000)
    local per_level = math.max(0, tonumber(progression.required_xp_per_level) or 0)
    local level, required = 1, base_required
    while xp >= required do
        xp = xp - required
        level = level + 1
        required = base_required + ((level - 1) * per_level)
    end
    local total_xp = tonumber(stored_xp) or 0
    return { level = level, current_xp = xp, required_xp = required, total_xp = math.max(0, math.floor(total_xp)) }
end

function utils.skills.modify_skill(source, name, amount, action)
    if name ~= 'drug_dealing' then return false end
    local player = get_player(source)
    if not player then return false end
    local skill = utils.skills.get_skill(source, name)
    local xp = math.max(0, skill.total_xp + (action == 'add' and amount or -amount))
    if framework == 'qbox' then exports.qbx_core:SetMetadata(source, skill_key, math.floor(xp))
    elseif framework == 'qb' then player.Functions.SetMetaData(skill_key, math.floor(xp))
    else player.setMeta(skill_key, math.floor(xp)) end
    return true
end

function utils.cooldowns.check(source, name)
    return (cooldowns[source] and cooldowns[source][name] or 0) > os.time()
end

function utils.cooldowns.add(source, name, seconds)
    cooldowns[source] = cooldowns[source] or {}
    cooldowns[source][name] = os.time() + seconds
end

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)
