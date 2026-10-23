--[[
     ____   ____ _____ _____   _   _____  ________      ________ _      ____  _____  __  __ ______ _   _ _______ 
    |  _ \ / __ \_   _|_   _| | | |  __ \|  ____\ \    / /  ____| |    / __ \|  __ \|  \/  |  ____| \ | |__   __|
    | |_) | |  | || |   | |   | | | |  | | |__   \ \  / /| |__  | |   | |  | | |__) | \  / | |__  |  \| |  | |   
    |  _ <| |  | || |   | |   | | | |  | |  __|   \ \/ / |  __| | |   | |  | |  ___/| |\/| |  __| | . ` |  | |   
    | |_) | |__| || |_ _| |_  | | | |__| | |____   \  /  | |____| |___| |__| | |    | |  | | |____| |\  |  | |   
    |____/ \____/_____|_____| | | |_____/|______|   \/   |______|______\____/|_|    |_|  |_|______|_| \_|  |_|   
                              | |                                                                                
                              |_|               DRUG SALES
]]

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
config.target = 'qb-target' --- Set target choice here. Options: boii_target, ox_target, qb-target

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
        dealing = { --- If this section is included items can be sold to npcs.
            required_level = 1, --- Required level to sell to npcs.
            price = { min = 10, max = 20 },-- Base price for selling this is adjusted based on current cop count and players XP
            quantity = { min = 3, max = 5 } --- Min and max amount that can be sold per single transaction
        },
        delivery = { --- If this section is included items can be dealing sold
            required_level = 1, --- Required level to dealing sell
            price = { min = 10, max = 20 },-- Base price for selling this is adjusted based on current cop count and players XP
            quantity = { min = 3, max = 5 } --- Min and max amount that can be sold per single transaction
        },
        bulk = { --- If this section is included items can be bulk sold
            required_level = 1, --- Required level to bulk sell
            price = 100, --- Base price for selling this should always be lower than dealing sales to encourage dealing selling
        }
    },
    { 
        id = 'burger',
        label = 'Burger',
        image = 'burger.png',
        dealing = { required_level = 1, price = { min = 10, max = 20 }, quantity = { min = 3, max = 5 } },
        delivery = { required_level = 1, price = { min = 10, max = 20 }, quantity = { min = 3, max = 5 } },
        bulk = { required_level = 1, price = 250 }
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
                action = 'boii_drugsales:cl:start_conversation',
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
    police = {
        required = 0, --- Required amount of police officers to start dealing or make sales: Use 0 or remove to disable.
        on_duty_required = false, --- Toggle on duty requirements for police officers.
        jobs = { 'police', 'fib' } --- Table of jobs to receive alerts for dealing.
    },
    payments = {
        type = 'item', --- Payment type: money e.g. cash, bank, crypto | item e.g.  
        balance_type = 'cash', --- Balance to add to if type = 'balance' is selected.
        item = { id = 'markedbills', data = { worth = 0 }} --- Item to give if type = 'item', data can be used optionally to add metadata to items if required.
    },
    chance = {
        fail = 0, --- % chance to fail sales.
        alert = 10, --- % chance to alert police when fail.
        steal = 5 --- % chance for npc to run away with drugs.
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
        item = { id = 'markedbills', data = { worth = 0 }} --- Item to give if type = 'item', data can be used optionally to add metadata to items if required.
    },
    chance = {
        alert = 10 --- % chance to alert police when fail.
    }
}