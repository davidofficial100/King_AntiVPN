fx_version 'cerulean'
game 'gta5'

author 'King Developmen'
description 'Advanced Anti-VPN & Anti-Proxy Detection System - Professional Edition'
version '1.0.1'

shared_scripts {
    'shared/config.lua',
    'shared/utils.lua',
    'shared/constants.lua'
}

server_scripts {
    'server/main.lua',
    'server/vpn-detector.lua',
    'server/database.lua',
    'server/api-handler.lua',
    'server/commands.lua'
}

client_scripts {
    'client/main.lua'
}

dependencies {
    '/server:5104'
}

lua54 'yes'
