
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
                    action = 'mz_drugselling:cl:open_bulk_sales',
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
                    action = 'mz_drugselling:cl:open_bulk_sales',
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
RegisterNetEvent('mz_drugselling:cl:start_conversation', function(data)
    if not data or data.dialogue ~= 'bulk_dealer' then return end
    local location = data.location
    lib.registerContext({
        id = 'mz_drugselling_bulk_dealer',
        title = dialogues.bulk_dealer.header.message,
        options = {
            {
                title = 'Make a deal', icon = 'store',
                onSelect = function()
                    TriggerEvent('mz_drugselling:cl:open_bulk_sales', {
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
