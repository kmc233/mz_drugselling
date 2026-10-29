local states = {}
local next_order_id = 0
local contacts = { '阿杰', '夜班客', '南区熟人', '陌生号码', '老客户', '小林', '码头联系人', '派对客' }

local function now()
    return os.time()
end

local function notify(player, message, kind)
    send_notification(player, lang.deliveries.client.notifications.header, message, kind or 'info', 3500)
end

local function public_order(order)
    return {
        id = order.id, contact = order.contact, drug_id = order.drug_id,
        label = order.label, quantity = order.quantity, price = order.price,
        total = order.price * order.quantity, area = order.area,
        expires_at = order.expires_at, status = order.status
    }
end

local function sync(player)
    local state = states[player]
    if not state then return end
    local orders = {}
    for _, order in ipairs(state.orders) do orders[#orders + 1] = public_order(order) end
    TriggerClientEvent('mz_drugselling:cl:delivery_orders', player, {
        orders = orders, active_id = state.active and state.active.id or nil,
        refresh_at = state.refresh_at or 0, server_time = now()
    })
end

local function clear_active(player, state, status, cooldown, keep_ped)
    local order = state.active
    if not order then return end
    order.status = status
    state.active = nil
    state.refresh_at = now() + (cooldown or config.deliveries.refresh_cooldown)
    state.token = state.token + 1
    if not keep_ped then TriggerClientEvent('mz_drugselling:cl:clear_delivery', player) end
    sync(player)
end

local function expire_orders(player, state)
    local changed = false
    for _, order in ipairs(state.orders) do
        if (order.status == 'pending' or order.status == 'accepted') and order.expires_at <= now() then
            if state.active == order then
                clear_active(player, state, 'expired')
            else
                order.status = 'expired'
            end
            changed = true
        end
    end
    if changed then sync(player) end
end

local function eligible_drugs(player)
    local skill = utils.skills.get_skill(player, 'drug_dealing') or { level = 1 }
    local drugs = {}
    for _, drug in ipairs(config.drugs) do
        if drug.delivery and skill.level >= drug.delivery.required_level then
            drugs[#drugs + 1] = drug
        end
    end
    return drugs
end

local function new_order(drugs, index)
    local drug = drugs[math.random(#drugs)]
    local location = config.deliveries.locations[math.random(#config.deliveries.locations)]
    local coords = location.coords or location
    next_order_id = next_order_id + 1
    local price = math.random(drug.delivery.price.min, drug.delivery.price.max)
    return {
        id = next_order_id, contact = contacts[((index - 1) % #contacts) + 1],
        drug_id = drug.id, label = drug.label,
        quantity = math.random(drug.delivery.quantity.min, drug.delivery.quantity.max),
        price = price, area = location.label or '指定地点', coords = coords,
        expires_at = now() + config.deliveries.offer_seconds, status = 'pending'
    }
end

RegisterNetEvent('mz_drugselling:sv:request_delivery', function()
    local player = source
    if sale_modes[player] ~= 'delivery' then return end
    local state = states[player]
    if not state then
        state = { orders = {}, token = 0, refresh_at = 0 }
        states[player] = state
    end
    expire_orders(player, state)
    if state.active then return sync(player) end
    if state.refresh_at > now() then
        notify(player, '订单暂时没有更新，请稍后再试。', 'error')
        return sync(player)
    end
    for _, order in ipairs(state.orders) do
        if order.status == 'pending' then return sync(player) end
    end
    local police = get_police_players(config.deliveries.police.jobs, config.deliveries.police.on_duty_required)
    if #police < config.deliveries.police.required then
        notify(player, lang.deliveries.server.notifications.not_enough_police:format(
            #police, config.deliveries.police.required), 'error')
        return
    end
    local drugs = eligible_drugs(player)
    if #drugs == 0 or #config.deliveries.locations == 0 then
        notify(player, '目前没有可提供的配送订单。', 'error')
        return
    end
    state.orders = {}
    local count = math.max(1, config.deliveries.order_count)
    for i = 1, count do state.orders[i] = new_order(drugs, i) end
    sync(player)
    notify(player, '收到了新的订单短信。')
end)

RegisterNetEvent('mz_drugselling:sv:accept_delivery', function(id)
    local player = source
    local state = states[player]
    if sale_modes[player] ~= 'delivery' or not state or state.active or state.refresh_at > now() or type(id) ~= 'number' then return end
    expire_orders(player, state)
    local selected
    for _, order in ipairs(state.orders) do
        if order.id == id and order.status == 'pending' then selected = order break end
    end
    if not selected then return sync(player) end
    selected.status = 'accepted'
    selected.expires_at = now() + config.deliveries.delivery_seconds
    state.active = selected
    state.token = state.token + 1
    local token = state.token
    sync(player)
    TriggerClientEvent('mz_drugselling:cl:spawn_delivery_ped', player, selected.coords)
    SetTimeout(config.deliveries.delivery_seconds * 1000, function()
        if states[player] == state and state.active == selected and state.token == token then
            clear_active(player, state, 'expired')
            notify(player, '配送订单已超时。', 'error')
        end
    end)
end)

RegisterNetEvent('mz_drugselling:sv:cancel_delivery', function()
    local player = source
    local state = states[player]
    if sale_modes[player] ~= 'delivery' or not state or not state.active then return end
    clear_active(player, state, 'cancelled')
    notify(player, '订单已取消。')
end)

RegisterNetEvent('mz_drugselling:sv:complete_delivery', function()
    local player = source
    local state = states[player]
    if sale_modes[player] ~= 'delivery' or not state or not state.active then return end
    local order = state.active
    if order.expires_at <= now() then
        clear_active(player, state, 'expired')
        return notify(player, '配送订单已超时。', 'error')
    end
    local ped = GetPlayerPed(player)
    if ped == 0 or #(GetEntityCoords(ped) - vector3(order.coords.x, order.coords.y, order.coords.z)) > 6.0 then return end
    local item = utils.fw.get_item(player, order.drug_id)
    local quantity = item and (item.quantity or item.count or item.amount) or 0
    if quantity < order.quantity then
        return notify(player, ('需要 %d 个 %s，当前库存不足。'):format(order.quantity, order.label), 'error')
    end
    local sale = { drugs = {{ id = order.drug_id, label = order.label, price = order.price, quantity = order.quantity }} }
    if not complete_sale(player, sale, order.drug_id, order.quantity, 'delivery') then
        return notify(player, '交货失败，请检查库存和收款空间后重试。', 'error')
    end
    reward_xp(player, sale.drugs[1], order.quantity, 'dealing')
    if math.random(1, 100) <= config.deliveries.chance.alert then alert_police(player, 'delivery') end
    clear_active(player, state, 'completed', nil, true)
    TriggerClientEvent('mz_drugselling:cl:completed_delivery', player)
end)

AddEventHandler('mz_drugselling:sv:stop_phone_action', function()
    states[source] = nil
    TriggerClientEvent('mz_drugselling:cl:clear_delivery', source)
end)

AddEventHandler('playerDropped', function()
    states[source] = nil
end)
