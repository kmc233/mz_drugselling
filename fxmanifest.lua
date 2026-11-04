
fx_version 'cerulean'
game 'gta5'

author 'Muzi Scripts'
name 'mz_drugselling'
description 'MZ Drug Selling'
version '1.0.0'

lua54 'yes'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/css/*.css',
    'web/scripts/*.js',
    'web/dist/css/*.css',
    'web/dist/scripts/*.js'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/*.lua',
    'shared/language.lua'
}

server_scripts {
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
    'config.lua',
    'locales/*.lua',
    'shared/language.lua',
    'server/utils.lua',
    'server/alerts.lua',
    'client/main.lua',
    'client/alerts.lua',
    'client/scripts/dealer_phone.lua',
    'client/scripts/bulk_dealer.lua',
    'web/**/*'
}

dependencies { 'ox_lib' }
