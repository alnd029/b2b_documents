fx_version 'cerulean'
game 'gta5'

author 'alnd'
description 'B2B ROLEPLAY DOCUMENTS'
version '2.0.0'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
    'web/images/*.png',
    'ui/img/logo.png'
}

exports {
    'usePaper'
}

shared_scripts {
    'config.lua',
    'locales/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@ox_lib/init.lua',
    'server.lua'
}

client_scripts {
    '@ox_lib/init.lua',
    'client.lua'
}

dependencies {
    'ox_inventory',
    'ox_lib',
    'oxmysql',
    'ox_target'
}

escrow_ignore {
    'config.lua',
    'locales/*.lua',
}
