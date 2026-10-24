
--- Server configuration.
--- @script server/config.lua

--- Here, you can adjust the core setup for the resource.
-- A copy of the server config will be sent to the client where relevant.

config = config or {}
config.drugs = config.drugs or {}
config.bulk_sales = config.bulk_sales or {}
config.street_sales = config.street_sales or {}
config.deliveries = config.deliveries or {}

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
    dealing = {
        bulk = {
            success = { min = 5, max = 10 }, --- XP added on success
            failed = { min = 0, max = 2 }, --- XP removed on fail
            bonus_threshold = 2, --- Level required before xp bonus is applied
            bonus_chance_multiplier = 1.05 --- XP multipler per level after threshold
        },
        dealing = {
            success = { min = 5, max = 10 }, --- XP added on success
            failed = { min = 0, max = 2 }, --- XP removed on fail
            bonus_threshold = 2, --- Level required before xp bonus is applied
            bonus_chance_multiplier = 1.05 --- XP multipler per level after threshold
        }
    }
}

--- @section Drug items settings

--- Drug items
config.drugs = {
    { 
        id = 'water', --- Item ID
        label = 'Water', --- Item label
        image = 'water.png', --- Item image to display in UI.
        dealing = { --- Street and corner offers; prices are per item.
            required_level = 1, --- Required level to sell to npcs.
            price = { min = 10, optimal = 15, max = 20 },
            quantity = { min = 3, max = 5 } --- Min and max amount that can be sold per single transaction
        },
        delivery = { --- If this section is included items can be dealing sold
            required_level = 1, --- Required level to dealing sell
            price = { min = 10, max = 20 },-- Base price for selling this is adjusted based on current cop count and players XP
            quantity = { min = 3, max = 5 } --- Min and max amount that can be sold per single transaction
        },
        bulk = { --- If this section is included items can be bulk sold
            required_level = 1, --- Required level to bulk sell
            price = 8, --- Per-item wholesale price; keep below the street price.
        }
    },
    { 
        id = 'burger',
        label = 'Burger',
        image = 'burger.png',
        dealing = { required_level = 1, price = { min = 10, optimal = 15, max = 20 }, quantity = { min = 3, max = 5 } },
        delivery = { required_level = 1, price = { min = 10, max = 20 }, quantity = { min = 3, max = 5 } },
        bulk = { required_level = 1, price = 8 }
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
    corner = {
        interval = 8, --- Seconds between approaching customers.
        models = { 'a_m_m_business_01', 'a_m_y_hipster_01', 'a_m_m_tramp_01', 'a_m_y_bevhills_01', 'g_m_y_ballaorig_01' }
    },
    ped_types = {
        normal = { label = '普通顾客', buy = 55, steal = 8, refuse = 12, alert = 15, xp = 25 },
        party = { label = '派对顾客', buy = 75, steal = 8, refuse = 5, alert = 10, xp = 15 },
        addicted = { label = '成瘾者', buy = 78, steal = 22, refuse = 5, alert = 0, xp = 8 },
        snitch = { label = '告密者', buy = 25, steal = 0, refuse = 45, alert = 55, xp = 40 },
        dealer = { label = '街头商人', buy = 58, steal = 20, refuse = 10, alert = 0, xp = 30 },
        rich = { label = '有钱人', buy = 85, steal = 0, refuse = 2, alert = 12, xp = 12 },
        junkie = { label = '瘾君子', buy = 65, steal = 35, refuse = 10, alert = 0, xp = 5 },
        undercover = { label = '卧底', buy = 30, steal = 0, refuse = 0, alert = 100, xp = 50 }
    },
    ped_models = {
        [GetHashKey('a_m_y_hipster_01')] = 'party',
        [GetHashKey('a_f_y_clubcust_01')] = 'party',
        [GetHashKey('a_m_y_clubcust_01')] = 'party',
        [GetHashKey('a_f_y_clubcust_02')] = 'party',
        [GetHashKey('a_m_y_clubcust_02')] = 'party',
        [GetHashKey('a_m_y_clubcust_03')] = 'party',
        [GetHashKey('csb_ramp_hipster')] = 'party',
        [GetHashKey('a_f_m_skidrow_01')] = 'addicted',
        [GetHashKey('g_m_y_ballaeast_01')] = 'addicted',
        [GetHashKey('g_m_y_ballasout_01')] = 'addicted',
        [GetHashKey('g_m_y_famca_01')] = 'addicted',
        [GetHashKey('g_m_y_famdnf_01')] = 'addicted',
        [GetHashKey('g_m_y_mexgoon_03')] = 'addicted',
        [GetHashKey('g_m_y_salvagoon_01')] = 'addicted',
        [GetHashKey('a_m_m_business_01')] = 'snitch',
        [GetHashKey('csb_reporter')] = 'snitch',
        [GetHashKey('a_f_y_business_01')] = 'snitch',
        [GetHashKey('a_f_y_business_02')] = 'snitch',
        [GetHashKey('a_m_m_eastsa_02')] = 'snitch',
        [GetHashKey('g_m_y_ballaorig_01')] = 'dealer',
        [GetHashKey('g_m_y_mexgang_01')] = 'dealer',
        [GetHashKey('g_m_y_mexgoon_01')] = 'dealer',
        [GetHashKey('g_m_y_famfor_01')] = 'dealer',
        [GetHashKey('g_m_y_strpunk_02')] = 'dealer',
        [GetHashKey('a_m_y_bevhills_01')] = 'rich',
        [GetHashKey('a_f_y_bevhills_01')] = 'rich',
        [GetHashKey('a_f_y_bevhills_02')] = 'rich',
        [GetHashKey('u_m_y_imporage')] = 'rich',
        [GetHashKey('u_m_y_party_01')] = 'rich',
        [GetHashKey('a_m_m_tramp_01')] = 'junkie',
        [GetHashKey('a_f_m_tramp_01')] = 'junkie',
        [GetHashKey('a_m_y_skater_01')] = 'junkie',
        [GetHashKey('a_m_y_skater_02')] = 'junkie',
        [GetHashKey('a_m_m_trampbeac_01')] = 'junkie',
        [GetHashKey('s_m_y_cop_01')] = 'undercover',
        [GetHashKey('csb_undercover')] = 'undercover',
        [GetHashKey('s_m_m_ciasec_01')] = 'undercover',
        [GetHashKey('s_m_m_highsec_01')] = 'undercover'
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

--- @section Delivery settings

--- Deliveries
config.deliveries = {
    locations = {
        vector4(314.82, -1375.75, 31.92, 48.51),
        vector4(298.64, -1360.96, 31.94, 230.58)
    },
    police = {
        required = 1, --- Required amount of police officers to start deliveries or receive new deliveries: Use 0 or remove to disable.
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
