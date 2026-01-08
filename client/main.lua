-- Advanced Anti-VPN Detection System - Client Module
-- Handles client-side events and feedback

-- ============================================
-- RESOURCE LIFECYCLE
-- ============================================

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    print('^2[AntiVPN]^7 Client module initialized')
    TriggerServerEvent('antivpn:clientReady')
end)

-- ============================================
-- PLAYER SPAWN EVENT
-- ============================================

RegisterNetEvent('playerSpawned', function()
    TriggerServerEvent('antivpn:playerSpawned', GetPlayerServerId(PlayerId()))
end)

-- ============================================
-- KICK/BAN NOTIFICATIONS
-- ============================================

-- Receive notification when VPN is detected
RegisterNetEvent('antivpn:notifyPlayer', function(message)
    TriggerEvent('chat:addMessage', {
        color = {255, 0, 0},
        multiline = true,
        args = {'AntiVPN Security', message}
    })
end)

-- ============================================
-- HELP COMMAND
-- ============================================

RegisterCommand('vpnhelp', function(source, args, rawCommand)
    TriggerEvent('chat:addMessage', {
        color = {0, 150, 255},
        multiline = true,
        args = {
            'AntiVPN Information',
            'This server uses advanced VPN/Proxy detection. Using a VPN may result in being kicked or banned. For assistance, contact server admins.'
        }
    })
end, false)

-- ============================================
-- INFO COMMAND
-- ============================================

RegisterCommand('vpninfo', function(source, args, rawCommand)
    TriggerEvent('chat:addMessage', {
        color = {0, 200, 200},
        multiline = true,
        args = {
            'AntiVPN System',
            'Advanced Anti-VPN & Anti-Proxy Detection System v2.0.0 | For help type /vpnhelp'
        }
    })
end, false)

-- ============================================
-- STATUS CHECK (Player can check themselves)
-- ============================================

RegisterCommand('vpnstatus', function(source, args, rawCommand)
    TriggerEvent('chat:addMessage', {
        color = {100, 150, 200},
        multiline = true,
        args = {
            'AntiVPN Status',
            'Checking connection status... If you receive no warnings, your connection is clean.'
        }
    })
end, false)

print('^2[AntiVPN]^7 Client module loaded successfully!')
