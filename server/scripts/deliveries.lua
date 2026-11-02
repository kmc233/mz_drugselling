local states = {}
local next_order_id = 0
local contacts = {
    '阿杰', '夜班客', '南区熟人', '陌生号码', '老客户', '小林', '码头联系人', '派对客',
    '阿凯', '小周', '酒吧老板', '东区熟客', '朋友介绍', '白天客户', '午夜联系人', '老陈',
    '公寓住客', '赛车场客人', '仓库联系人', '阿豪', '俱乐部经理', '上次那个人', '小马', '匿名客户'
}

local function now()
    return os.time()
end

local schedule_order

local function notify(player, message, kind)
    send_notification(player, lang.deliveries.client.notifications.header, message, kind or 'info', 3500)
end

local function has_required_police(player)
    local settings = config.deliveries.police
    local required = math.max(0, tonumber(settings.required) or 0)
    if required == 0 then return true end
    local police = get_police_players(settings.jobs, settings.on_duty_required) or {}
    if #police >= required then return true end
    notify(player, lang.deliveries.server.notifications.not_enough_police, 'error')
    return false
end

local function public_order(order)
    return {
        id = order.id, contact = order.contact, drug_id = order.drug_id,
        label = order.label, quantity = order.quantity, price = order.price,
        total = order.price * order.quantity, area = order.area,
        coords = { x = order.coords.x, y = order.coords.y, z = order.coords.z },
        expires_at = order.expires_at, status = order.status, accepted_at = order.accepted_at
    }
end

local function sync(player)
    local state = states[player]
    if not state then return end
    local orders = {}
    for _, order in ipairs(state.orders) do orders[#orders + 1] = public_order(order) end
    TriggerClientEvent('mz_drugselling:cl:delivery_orders', player, {
        orders = orders, active_id = state.active and state.active.id or nil,
        cooldown_until = state.cooldown_until or 0, server_time = now()
    })
end

local function clear_active(player, state, status, cooldown, keep_ped)
    local order = state.active
    if not order then return end
    order.status = status
    order.closed_at = now()
    state.active = nil
    if sale_modes[player] == 'delivery' then sale_modes[player] = nil end
    local default_cooldown = config.deliveries.cancel_cooldown or 0
    local cooldown_seconds = cooldown or default_cooldown
    state.cooldown_until = now() + cooldown_seconds
    state.token = state.token + 1
    if not keep_ped then TriggerClientEvent('mz_drugselling:cl:clear_delivery', player) end
    sync(player)
    if state.receiving then schedule_order(player, state, state.drugs) end
end

local function prune_order_history(state)
    local history_seconds = math.max(0, tonumber(config.deliveries.history_seconds) or 120)
    local max_history = math.max(0, math.floor(tonumber(config.deliveries.max_history_orders) or 8))
    local current_time = now()
    local history = {}
    for index = #state.orders, 1, -1 do
        local order = state.orders[index]
        if order.status == 'pending' and order.expires_at <= current_time then
            table.remove(state.orders, index)
        elseif order.status == 'completed' or order.status == 'cancelled' or order.status == 'expired' then
            order.closed_at = order.closed_at or order.expires_at
            if history_seconds == 0 or current_time - order.closed_at > history_seconds then
                table.remove(state.orders, index)
            else
                history[#history + 1] = order
            end
        end
    end
    table.sort(history, function(a, b) return (a.closed_at or 0) > (b.closed_at or 0) end)
    for index = max_history + 1, #history do
        local order = history[index]
        for position, current in ipairs(state.orders) do
            if current == order then
                table.remove(state.orders, position)
                break
            end
        end
    end
end

local function expire_orders(player, state)
    local changed = false
    for index = #state.orders, 1, -1 do
        local order = state.orders[index]
        if (order.status == 'pending' or order.status == 'accepted') and order.expires_at <= now() then
            if state.active == order then
                clear_active(player, state, 'expired')
            else
                table.remove(state.orders, index)
            end
            changed = true
        end
    end
    prune_order_history(state)
    if state.receiving and not state.active and state.cooldown_until <= now() then
        schedule_order(player, state, state.drugs)
    end
    if changed then sync(player) end
end

local function eligible_drugs(player)
    local skill = utils.skills.get_skill(player, 'drug_dealing') or { level = 1 }
    local drugs = {}
    for _, drug in ipairs(config.drugs) do
        if drug.price and drug.quantity and skill.level >= (drug.required_level or 1) then
            drugs[#drugs + 1] = drug
        end
    end
    return drugs
end

local function new_order(drugs)
    local drug = drugs[math.random(#drugs)]
    local location = config.deliveries.locations[math.random(#config.deliveries.locations)]
    local coords = location.coords or location
    next_order_id = next_order_id + 1
    local adjustment = config.sales_adjustments.delivery
    local order_quantity = config.deliveries.quantity or { min = 6, max = 12 }
    local min_quantity = math.max(1, math.floor(order_quantity.min or 1))
    local max_quantity = math.max(min_quantity, math.floor(order_quantity.max or min_quantity))
    local price = math.max(1, math.floor(drug.price.optimal * adjustment.price_multiplier + 0.5))
    local zone = {
        x = coords.x, y = coords.y, z = coords.z, w = coords.w or 0.0,
        radius = math.max(0.0, tonumber(location.radius) or 0.0),
        spawn_distance = math.max(0.0, tonumber(location.spawn_distance) or 100.0)
    }
    return {
        id = next_order_id, contact = contacts[math.random(#contacts)],
        drug_id = drug.id, label = drug.label,
        quantity = math.random(min_quantity, max_quantity),
        price = price, area = location.label or '指定地点', coords = coords, zone = zone,
        expires_at = now() + config.deliveries.offer_seconds, status = 'pending'
    }
end

local function open_order_count(state)
    local count = 0
    for _, order in ipairs(state.orders) do
        if order.status == 'pending' or order.status == 'accepted' then count = count + 1 end
    end
    return count
end

local function max_pending_orders()
    local configured = config.deliveries.max_pending_orders
    return math.max(1, math.floor(configured or 6))
end

local function add_order(player, state, drugs)
    if states[player] ~= state or not state.receiving or open_order_count(state) >= max_pending_orders() then return false end
    state.orders[#state.orders + 1] = new_order(drugs)
    sync(player)
    notify(player, lang.deliveries.server.notifications.new_order)
    return true
end

schedule_order = function(player, state, drugs)
    if states[player] ~= state or not state.receiving or state.generating or open_order_count(state) >= max_pending_orders() then
        state.generating = false
        return
    end
    state.generating = true
    local interval = config.deliveries.arrival_interval
    local delay = math.random(interval.min, interval.max)
    local token = state.generation_token
    SetTimeout(delay * 1000, function()
        if states[player] ~= state or not state.generating or state.generation_token ~= token then return end
        state.generating = false
        if add_order(player, state, drugs) then schedule_order(player, state, drugs) end
    end)
end

RegisterNetEvent('mz_drugselling:sv:request_delivery', function()
    local player = source
    if not utils.fw.has_item(player, 'dealer_phone', 1) then return end
    local state = states[player]
    if not has_required_police(player) then
        if state then
            state.receiving = false
            state.generating = false
            state.generation_token = (state.generation_token or 0) + 1
            sync(player)
        end
        TriggerClientEvent('mz_drugselling:cl:delivery_receiving_rejected', player)
        return
    end
    if not state then
        state = { orders = {}, token = 0, cooldown_until = 0 }
        states[player] = state
    end
    expire_orders(player, state)
    state.receiving = true
    if state.active or state.generating then return sync(player) end
    if state.cooldown_until > now() then return sync(player) end
    local drugs = state.drugs or eligible_drugs(player)
    if #drugs == 0 or #config.deliveries.locations == 0 then
        notify(player, lang.deliveries.server.notifications.no_orders, 'error')
        return
    end
    state.drugs = drugs
    state.generation_token = (state.generation_token or 0) + 1
    if open_order_count(state) < max_pending_orders() then
        if open_order_count(state) == 0 then add_order(player, state, drugs) end
        schedule_order(player, state, drugs)
    else
        sync(player)
    end
end)

RegisterNetEvent('mz_drugselling:sv:pause_delivery', function()
    local player = source
    local state = states[player]
    if not state or not state.receiving then return end
    state.receiving = false
    state.generating = false
    state.generation_token = (state.generation_token or 0) + 1
    sync(player)
end)

RegisterNetEvent('mz_drugselling:sv:accept_delivery', function(id)
    local player = source
    local state = states[player]
    if not state or state.active or state.cooldown_until > now() or type(id) ~= 'number' or
        (sale_modes[player] and sale_modes[player] ~= 'corner' and sale_modes[player] ~= 'dealing') then return end
    expire_orders(player, state)
    local selected
    for _, order in ipairs(state.orders) do
        if order.id == id and order.status == 'pending' then selected = order break end
    end
    if not selected then return sync(player) end
    if not has_required_police(player) then return end
    if sale_modes[player] then TriggerEvent('mz_drugselling:sv:delivery_accepted', player) end
    sale_modes[player] = 'delivery'
    TriggerClientEvent('mz_drugselling:cl:delivery_accepted', player)
    selected.status = 'accepted'
    selected.accepted_at = now()
    selected.expires_at = now() + config.deliveries.delivery_seconds
    state.active = selected
    state.token = state.token + 1
    local token = state.token
    sync(player)
    TriggerClientEvent('mz_drugselling:cl:spawn_delivery_ped', player, selected.zone or selected.coords)
    SetTimeout(config.deliveries.delivery_seconds * 1000, function()
        if states[player] == state and state.active == selected and state.token == token then
            clear_active(player, state, 'expired')
            notify(player, lang.deliveries.server.notifications.timed_out, 'error')
        end
    end)
end)

RegisterNetEvent('mz_drugselling:sv:cancel_delivery', function()
    local player = source
    local state = states[player]
    if sale_modes[player] ~= 'delivery' or not state or not state.active then return end
    clear_active(player, state, 'cancelled')
    notify(player, lang.deliveries.server.notifications.cancelled)
end)

RegisterNetEvent('mz_drugselling:sv:complete_delivery', function()
    local player = source
    local state = states[player]
    if sale_modes[player] ~= 'delivery' or not state or not state.active then return end
    local order = state.active
    if order.expires_at <= now() then
        clear_active(player, state, 'expired')
        return notify(player, lang.deliveries.server.notifications.timed_out, 'error')
    end
    local ped = GetPlayerPed(player)
    local zone = order.zone or order.coords
    local zone_radius = tonumber(zone.radius) or 0.0
    if ped == 0 or #(GetEntityCoords(ped) - vector3(zone.x, zone.y, zone.z)) > zone_radius + 8.0 then return end
    local item = utils.fw.get_item(player, order.drug_id)
    local quantity = item and (item.quantity or item.count or item.amount) or 0
    if quantity < order.quantity then
        return notify(player, lang.deliveries.server.notifications.insufficient_delivery:format(order.quantity, order.label), 'error')
    end
    local sale = { drugs = {{ id = order.drug_id, label = order.label, price = order.price, quantity = order.quantity }} }
    if not complete_sale(player, sale, order.drug_id, order.quantity, 'delivery') then
        return notify(player, lang.deliveries.server.notifications.delivery_failed, 'error')
    end
    reward_xp(player, sale.drugs[1], order.quantity, 'delivery')
    if math.random(1, 100) <= config.deliveries.chance.alert then alert_police(player, 'delivery') end
    clear_active(player, state, 'completed', 0, true)
    TriggerClientEvent('mz_drugselling:cl:completed_delivery', player)
end)

AddEventHandler('mz_drugselling:sv:stop_phone_action', function()
    states[source] = nil
    TriggerClientEvent('mz_drugselling:cl:clear_delivery', source)
end)

AddEventHandler('playerDropped', function()
    states[source] = nil
end)
