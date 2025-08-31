fx_version 'cerulean'
game 'gta5'

name 'love_restaurant'
description 'Restaurant management system for LoveCity'
author 'LoveCity Development Team'
version '1.0.0'

shared_scripts {
    'config/config.lua',
    'locales/locales.lua',
}

client_scripts {
    'client/main.lua',
    'client/menu.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'qb-core'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/app.js',
    'html/style.css',
    'html/img/*.png',
}

lua54 'yes' 