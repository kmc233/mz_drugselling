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

fx_version 'cerulean'
games { 'gta5', 'rdr3' }

name 'boii_drugsales'
version '1.1.0'
description 'BOII | Development - Drug Sales'
author 'boiidevelopment'
repository 'https://github.com/boiidevelopment'
lua54 'yes'

ui_page 'ui/index.html'

files {
    'ui/**/**/**/**',
}

shared_scripts {
    'shared/language/en.lua' -- Change language here 
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/config.lua',
    'server/main.lua',
    'server/alerts.lua',
    'server/scripts/*'
}

client_scripts {
    'client/main.lua',
    'client/alerts.lua',
    'client/scripts/*'
}

escrow_ignore {
    'server/**/*',
    'client/**/*',
    'shared/**/*'
}

dependency '/assetpacks'