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

--- Drug Dealer Dialogues.
-- @script client/dialogues.lua

--- @section Tables

local dialogues = dialogues or {}

--- @section Dialogue conversations

--- Bulk dealer.
dialogues.bulk_dealer = {
    header = {
        message = 'Bulk Dealer',
        icon = 'fa-solid fa-cannabis',
    },
    conversation = {
        {
            id = 1,
            response = 'You looking to offload something in large quantities? I can help.',
            options = {
                {
                    icon = 'fa-solid fa-store',
                    message = 'Make a deal.',
                    next_id = nil,
                    should_end = true,
                    action_type = 'client',
                    action = 'boii_drugsales:cl:open_bulk_sales',
                    params = {}
                },
                {
                    icon = 'fa-solid fa-question-circle',
                    message = 'What are you offering?',
                    next_id = 2,
                    should_end = false
                },
                {
                    icon = 'fa-solid fa-door-open',
                    message = 'Maybe later. Goodbye!',
                    next_id = nil,
                    should_end = true
                }
            }
        },
        {
            id = 2,
            response = {
                'I can buy all of your drugs in bulk, but i want them cheap!',
                'You could make a higher profit selling on the streets but whos got time for that?'
            },
            options = {
                {
                    icon = 'fa-solid fa-store',
                    message = 'Make a deal.',
                    next_id = nil,
                    should_end = true,
                    action_type = 'client',
                    action = 'boii_drugsales:cl:open_bulk_sales',
                    params = {}
                },
                {
                    icon = 'fa-solid fa-arrow-left',
                    message = 'Back to previous questions.',
                    next_id = 1,
                    should_end = false
                },
                {
                    icon = 'fa-solid fa-door-open',
                    message = 'Maybe later. Goodbye!',
                    next_id = nil,
                    should_end = true
                }
            }
        }
    }
}


--- Event handler to launch dialogue based on store type.
-- @param data table: Data 
RegisterNetEvent('boii_drugsales:cl:start_conversation', function(data)
    if not data or data.dialogue ~= 'bulk_dealer' then return end
    local location = data.location
    lib.registerContext({
        id = 'mz_drugselling_bulk_dealer',
        title = dialogues.bulk_dealer.header.message,
        options = {
            {
                title = 'Make a deal', icon = 'store',
                onSelect = function()
                    TriggerEvent('boii_drugsales:cl:open_bulk_sales', {
                        location = vector3(location.x, location.y, location.z)
                    })
                end
            },
            {
                title = 'What are you offering?', icon = 'circle-question',
                description = 'Bulk sales at a lower price per item.'
            }
        }
    })
    lib.showContext('mz_drugselling_bulk_dealer')
end)
