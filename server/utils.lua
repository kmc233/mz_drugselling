utils = { callback = {}, cooldowns = {}, debug = {}, fw = {}, skills = {}, ui = {} }

local cooldowns = {}
local skill_key = 'mz_drugselling_xp'

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
    local player = exports.qbx_core:GetPlayer(tonumber(source))
    local job = player and player.PlayerData.job
    if not job or (on_duty and not job.onduty) then return false end
    for _, name in ipairs(jobs) do
        if job.name == name then return true end
    end
    return false
end

function utils.fw.get_item(source, item)
    return { quantity = exports.ox_inventory:GetItemCount(source, item) or 0 }
end

function utils.fw.has_item(source, item, amount)
    return (exports.ox_inventory:GetItemCount(source, item) or 0) >= amount
end

function utils.fw.adjust_inventory(source, data)
    for _, entry in ipairs(data.items) do
        local success
        if entry.action == 'remove' then
            success = exports.ox_inventory:RemoveItem(source, entry.item_id, entry.quantity)
        elseif entry.action == 'add' then
            success = exports.ox_inventory:AddItem(source, entry.item_id, entry.quantity, entry.data)
        end
        if not success then return false end
    end
    return true
end

function utils.fw.adjust_balance(source, data)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end
    for _, operation in ipairs(data.operations) do
        if operation.action ~= 'add' or not player.Functions.AddMoney(operation.balance_type, operation.amount, data.reason) then
            return false
        end
    end
    return true
end

function utils.fw.register_item(item, handler)
    exports.qbx_core:CreateUseableItem(item, handler)
end

function utils.skills.get_skill(source, name)
    if name ~= 'drug_dealing' then return nil end
    local xp = tonumber((exports.qbx_core:GetMetadata(source, skill_key))) or 0
    xp = math.max(0, math.floor(xp))
    local level = math.floor(xp / 1000) + 1
    return { level = level, current_xp = xp % 1000, required_xp = 1000, total_xp = xp }
end

function utils.skills.modify_skill(source, name, amount, action)
    if name ~= 'drug_dealing' then return false end
    local skill = utils.skills.get_skill(source, name)
    local xp = math.max(0, skill.total_xp + (action == 'add' and amount or -amount))
    exports.qbx_core:SetMetadata(source, skill_key, math.floor(xp))
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
