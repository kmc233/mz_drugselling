
fx_version 'cerulean'
games { 'gta5', 'rdr3' }

name 'mz_drugselling'
version '1.0.0'
description 'MZ Drug Selling'
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
    'server/**/*',
    'client/**/*',
    'shared/**/*'
}

dependencies { 'ox_lib' }
