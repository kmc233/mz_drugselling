
--- Server configuration.
--- @script config.lua

--- Here, you can adjust the core setup for the resource.
-- A copy of the server config will be sent to the client where relevant.

config = config or {}
config.drugs = config.drugs or {}
config.bulk_sales = config.bulk_sales or {}
config.street_sales = config.street_sales or {}
config.deliveries = config.deliveries or {}

--- Per-mode price adjustments applied to each drug's base price.
config.sales_adjustments = {
    delivery = {
        price_multiplier = 0.80
    },
    bulk = {
        price_multiplier = 0.55
    }
}

--- @section General settings

--- @field debug boolean: Enables or disables server-side debug prints for troubleshooting.
config.debug = false

--- Target System
config.target = 'ox_target' --- Set target choice here. Options: ox_target, qb-target

--- Police alerts: auto selects the first started integration below.
--- Use a resource name to select one explicitly, or 'none' to disable alerts.
config.dispatch = 'auto' --- cd_dispatch, codem-dispatch, origen_police, ps-dispatch, rcore_dispatch

--- @section Skills settings

--- Skills
config.skills = {
    progression = {
        base_required_xp = 1000, --- XP required for level 1 -> 2.
        required_xp_per_level = 100 --- Additional XP required for each next level.
    },
    bulk = {
        base_xp = { min = 5, max = 10 }, --- Base XP added on success.
        quantity_xp = { units = 10, amount = 1, max = 10 }, --- Extra XP per quantity units, capped per transaction.
        price_per_level = 0.01 --- Bulk price bonus per level above level 1.
    },
    delivery = {
        base_xp = { min = 5, max = 10 } --- Base XP added on successful delivery.
    }
}

--- @section Drug items settings

--- Drug items
config.inventoryImagePath = 'nui://ox_inventory/web/images/'
config.drugs = {
    { 
        id = 'weed', --- Item ID
        label = 'Weed', --- Item label
        image = 'weed.png', --- Item image to display in UI.
        required_level = 1,
        price = { min = 10, optimal = 15, max = 20 }, --- Base per-item street price.
        quantity = { min = 3, max = 5 } --- Base amount per transaction.
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

--- @section Bulk sale settings

--- Bulk dealer
config.bulk_dealer = {
    enabled = true,
    blip = {
        id = 'bulk_dealer',
        label = 'Bulk Dealer',
        coords = vector3(-1763.38, 431.12, 127.27),
        category = 'drug_sales',
        sprite = 51,
        colour = 5,
        scale = 0.7,
        show = true
    },
    ped = {
        id = 'bulk_dealer',
        icon = 'fa-solid fa-cannabis',
        model = 'cs_martinmadrazo',
        coords = vector4(-1757.21, 427.49, 127.70, 70.28),
        scenario = 'WORLD_HUMAN_SMOKING',
        category = 'drug_sales',
        networked = false,
        distance = 2.5,
        debug = false,
        sprite = false,
        actions = {
            {
                label = 'Speak To Madrazo',
                icon = 'fa-solid fa-comments',
                colour = '#4dcbc2',
                action_type = 'client',
                action = 'mz_drugselling:cl:start_conversation',
                params = {
                    dialogue = 'bulk_dealer',
                    location = vector4(-1757.21, 427.49, 127.70, 70.28), 
                }
            }
        }
    }
}

--- @section Dealing settings

--- Dealing
config.dealing = {
    street_phone = false, --- false: interact with NPCs directly; true: enable active selling on the phone first.
    corner = {
        interval = 8, --- Seconds between approaching customers.
        models = { 'a_m_m_business_01', 'a_m_y_hipster_01', 'a_m_m_tramp_01', 'a_m_y_bevhills_01', 'g_m_y_ballaorig_01' }
    },
    ped_types = {
        normal = { label = '普通顾客', buy = 55, steal = 10, refuse = 12, alert = 15, xp = 10 },
        party = { label = '派对顾客', buy = 75, steal = 8, refuse = 5, alert = 10, xp = 12 },
        addicted = { label = '成瘾者', buy = 78, steal = 22, refuse = 5, alert = 0, xp = 8 },
        gang = { label = '帮派成员', buy = 58, steal = 25, refuse = 10, alert = 0, xp = 15, gang = true },
        snitch = { label = '告密者', buy = 25, steal = 0, refuse = 45, alert = 55, xp = 30 },
        dealer = { label = '街头商人', buy = 58, steal = 20, refuse = 10, alert = 0, xp = 20 },
        rich = { label = '有钱人', buy = 85, steal = 0, refuse = 2, alert = 12, xp = 10 },
        junkie = { label = '瘾君子', buy = 65, steal = 35, refuse = 10, alert = 0, xp = 5 },
        undercover = { label = '卧底', buy = 30, steal = 0, refuse = 0, alert = 100, xp = 35 }
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
    price_influence = 30, --- Chance points gained/lost at the price limits.
    police = {
        required = 0, --- Required amount of police officers to start dealing or make sales: Use 0 or remove to disable.
        on_duty_required = false, --- Toggle on duty requirements for police officers.
        jobs = { 'police', 'fib' } --- Table of jobs to receive alerts for dealing.
    },
    payments = {
        type = 'item', --- Payment type: money e.g. cash, bank, crypto | item e.g.  
        balance_type = 'cash', --- Balance to add to if type = 'balance' is selected.
        item = { id = 'black_money' } --- One item per dollar of the sale total.
    }
}

--- Build the runtime model -> personality lookup from the grouped configuration.
config.dealing.ped_model_types = {}
for type_id, models in pairs(config.dealing.ped_models) do
    for _, model_name in ipairs(models) do
        config.dealing.ped_model_types[GetHashKey(model_name)] = type_id
    end
end

--- @section Delivery settings

--- Deliveries
config.deliveries = {
    locations = {
        { coords = vector4(314.82, -1375.75, 31.92, 48.51), radius = 45.0, spawn_distance = 110.0 },
        { coords = vector4(298.64, -1360.96, 31.94, 230.58), radius = 40.0, spawn_distance = 100.0 }
    },
    order_count = { min = 6, max = 8 }, --- Number of orders received during one delivery session.
    quantity = { min = 6, max = 12 }, --- Quantity requested by each delivery order.
    arrival_interval = { min = 15, max = 30 }, --- Seconds between incoming order messages.
    offer_seconds = 600, --- Time to choose an order from the inbox.
    delivery_seconds = 600, --- Time to complete an accepted order.
    refresh_cooldown = 30, --- After a completed or cancelled order.
    police = {
        required = 0, --- Required amount of police officers to start deliveries or receive new deliveries: Use 0 or remove to disable.
        on_duty_required = false, --- Toggle on duty requirements for police officers.
        jobs = { 'police', 'fib' } --- Table of jobs to receive alerts for dealing.
    },
    payments = {
        type = 'item', --- Payment type: money e.g. cash, bank, crypto | item e.g.  
        balance_type = 'cash', --- Balance to add to if type = 'balance' is selected.
        item = { id = 'black_money' } --- One item per dollar of the sale total.
    },
    chance = {
        alert = 10 --- % chance to alert police when fail.
    }
}
