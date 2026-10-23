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
    local location = data.location
    local ped, coords = utils.entities.get_closest_ped(vector3(location.x, location.y, location.z), 5.0)
    local fee = tonumber(data.fee)
    local dialogue = dialogues[data.dialogue]
    for _, convo in pairs(dialogue.conversation) do
        for _, option in pairs(convo.options) do
            if option.action ~= nil and option.action ~= '' then
                option.params = option.params or {}
                option.params['location'] = vector3(location.x, location.y, location.z)
            end
        end
    end
    exports.boii_ui:dialogue(dialogue, ped, coords)
end)