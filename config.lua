
config = config or {}
config.locale = 'en' -- Language key from locales/*.lua.
config.framework = 'auto' -- auto, qbox, qb, or esx.

config.sales_adjustments = {
    delivery = {
        price_multiplier = 0.80 -- Delivery price multiplier.
    },
    bulk = {
        price_multiplier = 0.55 -- Bulk sale price multiplier.
    }
}

config.debug = false -- Enable debug logging.
config.target = 'ox_target' -- ox_target or qb-target.
config.dispatch = 'auto' -- Dispatch integration, or none to disable alerts.

config.skills = {
    progression = {
        base_required_xp = 1000, -- XP required for level 1 -> 2.
        required_xp_per_level = 100 -- Additional XP required per level.
    },
    bulk = {
        base_xp = { min = 5, max = 10 }, -- Base XP on successful bulk sales.
        quantity_xp = { units = 10, amount = 1, max = 10 }, -- Extra XP per quantity units.
        price_per_level = 0.01 -- Bulk price bonus per level above 1.
    },
    delivery = {
        base_xp = { min = 5, max = 10 } -- Base XP on successful deliveries.
    }
}

config.inventoryImagePath = 'auto' -- Qbox/ESX: ox_inventory, QB: qb-inventory. Example: 'nui://ox_inventory/web/images/'.
config.drugs = {
    { 
        id = 'weed',
        label = 'Weed',
        image = 'weed.png',
        required_level = 1, -- Required dealing skill level.
        price = { min = 10, optimal = 15, max = 20 },
        quantity = { min = 3, max = 5 }
    },
    { 
        id = 'meth',
        label = 'Meth',
        image = 'meth.png',
        required_level = 1,
        price = { min = 10, optimal = 15, max = 20 },
        quantity = { min = 3, max = 5 }
    },
    {
        id = 'cocaine',
        label = 'Cocaine',
        image = 'cocaine.png',
        required_level = 1,
        price = { min = 10, optimal = 15, max = 20 },
        quantity = { min = 3, max = 5 }
    }
}

config.bulk_dealer = {
    enabled = true, -- Enable the bulk dealer.
    blip = {
        enabled = true, -- Show the bulk dealer on the map.
        sprite = 51,
        colour = 5,
        scale = 0.7
    },
    ped = {
        model = 'cs_martinmadrazo',
        coords = vector4(146.253845, 324.968170, 112.138855, 204.901550),
        scenario = 'WORLD_HUMAN_SMOKING',
        distance = 2.5
    }
}

config.dealing = {
    street_phone = false, -- Require starting active street sales from the phone.
    corner = {
        interval = 8, -- Seconds between approaching customers.
        models = { 'a_m_m_business_01', 'a_m_y_hipster_01', 'a_m_m_tramp_01', 'a_m_y_bevhills_01', 'g_m_y_ballaorig_01' }
    },
    ped_types = {
        normal = { buy = 55, steal = 10, refuse = 12, alert = 15, xp = 10 },
        party = { buy = 75, steal = 8, refuse = 5, alert = 10, xp = 12 },
        addicted = { buy = 78, steal = 22, refuse = 5, alert = 0, xp = 8 },
        gang = { buy = 58, steal = 25, refuse = 10, alert = 0, xp = 15, gang = true },
        snitch = { buy = 25, steal = 0, refuse = 45, alert = 55, xp = 30 },
        dealer = { buy = 58, steal = 20, refuse = 10, alert = 0, xp = 20 },
        rich = { buy = 85, steal = 0, refuse = 2, alert = 12, xp = 10 },
        junkie = { buy = 65, steal = 35, refuse = 10, alert = 0, xp = 5 },
        undercover = { buy = 30, steal = 0, refuse = 0, alert = 100, xp = 35 }
    },
    ped_models = {
        party = {
            'a_m_y_hipster_01', 'a_f_y_clubcust_01', 'a_m_y_clubcust_01',
            'a_f_y_clubcust_02', 'a_m_y_clubcust_02', 'a_m_y_clubcust_03', 'csb_ramp_hipster'
        },
        addicted = { 'a_f_m_skidrow_01' },
        gang = {
            'g_m_y_ballaeast_01', 'g_m_y_ballasout_01', 'g_m_y_famca_01',
            'g_m_y_famdnf_01', 'g_m_y_mexgoon_01', 'g_m_y_mexgoon_02',
            'g_m_y_mexgoon_03', 'g_m_y_ballaorig_01', 'g_m_y_famfor_01',
            'g_m_y_strpunk_01', 'g_m_y_strpunk_02', 'g_m_y_lost_01',
            'g_m_y_lost_02', 'g_m_y_lost_03', 'g_m_y_pologoon_01', 'g_m_y_salvagoon_01'
        },
        snitch = { 'a_m_m_business_01', 'csb_reporter', 'a_f_y_business_01', 'a_f_y_business_02', 'a_m_m_eastsa_02' },
        dealer = { 'g_m_y_mexgang_01' },
        rich = { 'a_m_y_bevhills_01', 'a_f_y_bevhills_01', 'a_f_y_bevhills_02', 'u_m_y_imporage', 'u_m_y_party_01' },
        junkie = { 'a_m_m_tramp_01', 'a_f_m_tramp_01', 'a_m_y_skater_01', 'a_m_y_skater_02', 'a_m_m_trampbeac_01' },
        undercover = { 's_m_y_cop_01', 'csb_undercover', 's_m_m_ciasec_01', 's_m_m_highsec_01' }
    },
    price_influence = 30, -- Chance points gained or lost at price limits.
    police = {
        required = 0, -- Required police count; 0 disables the requirement.
        on_duty_required = false, -- Require officers to be on duty.
        jobs = { 'police', 'fib' } -- Jobs that receive alerts.
    },
    payments = {
        type = 'item', -- money or item.
        balance_type = 'cash', -- Balance used when type is money.
        item = { id = 'black_money' } -- Item used when type is item.
    }
}

config.dealing.ped_model_types = {}
for type_id, models in pairs(config.dealing.ped_models) do
    for _, model_name in ipairs(models) do
        config.dealing.ped_model_types[GetHashKey(model_name)] = type_id
    end
end

config.deliveries = {
    locations = {
        -- { coords = vector4(314.82, -1375.75, 31.92, 48.51), radius = 45.0, spawn_distance = 110.0 },
        -- { coords = vector4(298.64, -1360.96, 31.94, 230.58), radius = 40.0, spawn_distance = 100.0 }
        { coords = vector4(456.30, -761.75, 27.35, 79.94), radius = 40.0, spawn_distance = 100.0 }
    },

    max_pending_orders = 6, -- Maximum pending or active orders.
    quantity = { min = 6, max = 12 }, -- Quantity requested per order.
    history_seconds = 120, -- How long closed orders remain visible.
    max_history_orders = 8, -- Maximum closed orders retained.
    arrival_interval = { min = 15, max = 30 }, -- Seconds between new orders.
    offer_seconds = 600, -- Time to accept a pending order.
    delivery_seconds = 600, -- Time to complete an accepted order.
    cancel_cooldown = 30, -- Cooldown after cancellation or timeout.

    police = {
        required = 0, -- Required police count; 0 disables the requirement.
        on_duty_required = true, -- Count only on-duty officers for deliveries.
        jobs = { 'police', 'fib' } -- Jobs counted for delivery availability.
    },
    payments = {
        type = 'item', -- money or item.
        balance_type = 'cash', -- Balance used when type is money.
        item = { id = 'black_money' } -- Item used when type is item.
    },
    chance = {
        alert = 10 -- Chance to alert police after a successful delivery.
    }
}
