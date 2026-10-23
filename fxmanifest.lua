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
    'ui/index.html',
    'ui/css/*.css',
    'ui/scripts/*.js',
    'ui/assets/images/*',
    'ui/assets/fonts/*'
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/language/en.lua' -- Change language here 
}

server_scripts {
    'server/config.lua',
    'server/utils.lua',
    'server/main.lua',
    'server/alerts.lua',
    'server/scripts/*'
}

client_scripts {
    'client/utils.lua',
    'client/main.lua',
    'client/alerts.lua',
    'client/scripts/*'
}

escrow_ignore {
    'server/**/*',
    'client/**/*',
    'shared/**/*'
}

dependencies { 'ox_lib', 'ox_inventory', 'qbx_core', 'ox_target' }
