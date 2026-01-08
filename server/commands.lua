-- Admin Commands Module - Provides comprehensive admin controls for AntiVPN system

-- ============================================
-- PERMISSION CHECKING
-- ============================================

local function isAdmin(source)
    -- Console (source = 0) is always admin
    if source == 0 then return true end

    -- Check if using permission system
    if Config.AdminRoles.usePermissionSystem then
        -- You can integrate with permission systems here
        -- For now, return true for testing
        return true
    end

    -- Default: return true for all (change this to your system)
    return true
end

local function checkPermission(source)
    if not isAdmin(source) then
        if source ~= 0 then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {'AntiVPN', 'You do not have permission to use this command'}
            })
        end
        return false
    end
    return true
end

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function sendAdminMessage(source, title, message, color)
    color = color or {0, 150, 255}
    if source == 0 then
        print('^2[' .. title .. ']^7 ' .. message)
    else
        if GetPlayer(source) then
            TriggerClientEvent('chat:addMessage', source, {
                color = color,
                multiline = true,
                args = {title, message}
            })
        end
    end
end

-- ============================================
-- COMMAND: /checkvpn - Check if player uses VPN
-- ============================================

RegisterCommand(Config.Commands.checkVPN, function(source, args, rawCommand)
    if not checkPermission(source) then return end

    if not args[1] then
        sendAdminMessage(source, 'AntiVPN', 'Usage: /' .. Config.Commands.checkVPN .. ' <player_id>', {255, 150, 0})
        return
    end

    local targetId = tonumber(args[1])
    if not targetId or not GetPlayer(targetId) then
        sendAdminMessage(source, 'AntiVPN', 'Invalid player ID', {255, 0, 0})
        return
    end

    local isVPN, reason = VPNDetector.manualCheck(targetId)
    local playerName = GetPlayerName(targetId)

    if isVPN then
        sendAdminMessage(source, 'AntiVPN', 
            '🔴 VPN DETECTED | Player: ' .. playerName .. ' (ID: ' .. targetId .. ') | Reason: ' .. reason, 
            {255, 0, 0})
    else
        sendAdminMessage(source, 'AntiVPN', 
            '✅ CLEAN | Player: ' .. playerName .. ' (ID: ' .. targetId .. ')', 
            {0, 255, 0})
    end
end, false)

-- ============================================
-- COMMAND: /checkip - Check specific IP address
-- ============================================

RegisterCommand(Config.Commands.checkIP, function(source, args, rawCommand)
    if not checkPermission(source) then return end

    if not args[1] then
        sendAdminMessage(source, 'AntiVPN', 'Usage: /' .. Config.Commands.checkIP .. ' <ip_address>', {255, 150, 0})
        return
    end

    local ip = args[1]
    if not Utils.isValidIP(ip) and not string.find(ip, '%*') then
        sendAdminMessage(source, 'AntiVPN', 'Invalid IP address format', {255, 0, 0})
        return
    end

    if not Config.Detection.apiDetection.enabled then
        sendAdminMessage(source, 'AntiVPN', 'API detection is disabled in configuration', {255, 150, 0})
        return
    end

    sendAdminMessage(source, 'AntiVPN', 'Checking IP: ' .. ip .. '...', {100, 150, 200})

    APIHandler.checkIP(ip, function(result, error)
        if error then
            sendAdminMessage(source, 'AntiVPN', 'Error checking IP: ' .. error, {255, 0, 0})
            return
        end

        if result then
            local message = 'IP Check Results for ' .. ip .. ' | '
            message = message .. 'VPN: ' .. (result.isVPN and 'YES' or 'NO') .. ' | '
            message = message .. 'Proxy: ' .. (result.isProxy and 'YES' or 'NO') .. ' | '
            message = message .. 'Provider: ' .. (result.provider or 'Unknown') .. ' | '
            message = message .. 'Country: ' .. (result.country or 'Unknown')

            sendAdminMessage(source, 'AntiVPN', message, {100, 200, 100})
        else
            sendAdminMessage(source, 'AntiVPN', 'No result from API', {255, 150, 0})
        end
    end)
end, false)

-- ============================================
-- COMMAND: /vpnstats - Show statistics
-- ============================================

RegisterCommand(Config.Commands.vpnStats, function(source, args, rawCommand)
    if not checkPermission(source) then return end

    local stats = VPNDetector.getDetailedStats()
    
    local message = '📈 AntiVPN Statistics\n'
    message = message .. '• Total Checks: ' .. stats.totalChecks .. '\n'
    message = message .. '• VPNs Detected: ' .. stats.vpnsDetected .. '\n'
    message = message .. '• Proxies Detected: ' .. stats.proxiesDetected .. '\n'
    message = message .. '• Detection Rate: ' .. stats.detectionRate .. '\n'
    message = message .. '• Cache Size: ' .. stats.cacheSize .. '\n'
    message = message .. '• Players Online: ' .. stats.playersOnline

    sendAdminMessage(source, 'AntiVPN', message, {0, 200, 200})
end, false)

-- ============================================
-- COMMAND: /whitelistip - Add IP to whitelist
-- ============================================

RegisterCommand(Config.Commands.whitelistIP, function(source, args, rawCommand)
    if not checkPermission(source) then return end

    if not args[1] then
        sendAdminMessage(source, 'AntiVPN', 'Usage: /' .. Config.Commands.whitelistIP .. ' <ip_address>', {255, 150, 0})
        return
    end

    local ip = args[1]
    if not Utils.isValidIP(ip) and not string.find(ip, '/') then
        sendAdminMessage(source, 'AntiVPN', 'Invalid IP address format', {255, 0, 0})
        return
    end

    if Utils.tableContains(Config.Whitelist.ips, ip) then
        sendAdminMessage(source, 'AntiVPN', 'IP is already whitelisted', {255, 150, 0})
        return
    end

    table.insert(Config.Whitelist.ips, ip)
    sendAdminMessage(source, 'AntiVPN', 'IP ' .. ip .. ' has been added to whitelist', {0, 255, 0})

    Utils.fileLog('Whitelisted IP: ' .. ip, 'WHITELIST')
end, false)

-- ============================================
-- COMMAND: /whitelistplayer - Whitelist player
-- ============================================

RegisterCommand(Config.Commands.whitelistPlayer, function(source, args, rawCommand)
    if not checkPermission(source) then return end

    if not args[1] then
        sendAdminMessage(source, 'AntiVPN', 'Usage: /' .. Config.Commands.whitelistPlayer .. ' <player_id>', {255, 150, 0})
        return
    end

    local targetId = tonumber(args[1])
    if not targetId or not GetPlayer(targetId) then
        sendAdminMessage(source, 'AntiVPN', 'Invalid player ID', {255, 0, 0})
        return
    end

    local identifiers = Utils.getPlayerIdentifiers(targetId)
    if not identifiers or #identifiers == 0 then
        sendAdminMessage(source, 'AntiVPN', 'Could not get player identifiers', {255, 0, 0})
        return
    end

    local discordId = Utils.getIdentifierOfType(targetId, 'discord')
    if discordId and not Utils.tableContains(Config.Whitelist.players, discordId) then
        table.insert(Config.Whitelist.players, discordId)
        sendAdminMessage(source, 'AntiVPN', 'Player ' .. GetPlayerName(targetId) .. ' whitelisted (' .. discordId .. ')', {0, 255, 0})
        Utils.fileLog('Whitelisted player: ' .. GetPlayerName(targetId) .. ' (' .. discordId .. ')', 'WHITELIST')
    else
        sendAdminMessage(source, 'AntiVPN', 'Player already whitelisted or no Discord ID found', {255, 150, 0})
    end
end, false)

-- ============================================
-- COMMAND: /removewhitelist - Remove from whitelist
-- ============================================

RegisterCommand(Config.Commands.removeWhitelist, function(source, args, rawCommand)
    if not checkPermission(source) then return end

    if not args[1] then
        sendAdminMessage(source, 'AntiVPN', 'Usage: /' .. Config.Commands.removeWhitelist .. ' <ip_or_identifier>', {255, 150, 0})
        return
    end

    local target = args[1]
    local found = false

    -- Try to remove from IP whitelist
    for i, ip in ipairs(Config.Whitelist.ips) do
        if ip == target then
            table.remove(Config.Whitelist.ips, i)
            sendAdminMessage(source, 'AntiVPN', 'IP ' .. target .. ' removed from whitelist', {0, 255, 0})
            found = true
            break
        end
    end

    -- Try to remove from player whitelist
    if not found then
        for i, identifier in ipairs(Config.Whitelist.players) do
            if identifier == target or string.find(identifier, target) then
                table.remove(Config.Whitelist.players, i)
                sendAdminMessage(source, 'AntiVPN', 'Identifier ' .. identifier .. ' removed from whitelist', {0, 255, 0})
                found = true
                break
            end
        end
    end

    if not found then
        sendAdminMessage(source, 'AntiVPN', 'Not found in whitelist', {255, 0, 0})
    end

    Utils.fileLog('Removed from whitelist: ' .. target, 'WHITELIST')
end, false)

-- ============================================
-- COMMAND: /reloadantivpn - Reload configuration
-- ============================================

RegisterCommand(Config.Commands.reloadConfig, function(source, args, rawCommand)
    if not checkPermission(source) then return end

    -- Validate config
    if not Utils.validateConfig() then
        sendAdminMessage(source, 'AntiVPN', 'Configuration validation failed', {255, 0, 0})
        return
    end

    VPNDetector.clearCache()
    Utils.logSuccess('AntiVPN configuration reloaded')
    sendAdminMessage(source, 'AntiVPN', 'Configuration reloaded successfully', {0, 255, 0})
end, false)

-- ============================================
-- COMMAND: /detectionlist - Show recent detections
-- ============================================

RegisterCommand(Config.Commands.listDetections, function(source, args, rawCommand)
    if not checkPermission(source) then return end

    local limit = tonumber(args[1]) or 10
    local detections = Database.getDetectionHistory(limit)

    if #detections == 0 then
        sendAdminMessage(source, 'AntiVPN', 'No detection history available', {255, 150, 0})
        return
    end

    local message = '📋 Recent Detections (Last ' .. #detections .. ')\n'
    for i, detection in ipairs(detections) do
        message = message .. i .. '. ' .. detection.playerName .. ' - ' .. detection.reason .. ' (' .. detection.dateTime .. ')\n'
    end

    sendAdminMessage(source, 'AntiVPN', message, {100, 200, 100})
end, false)

-- ============================================
-- ADMIN NOTIFICATION EVENT
-- ============================================

RegisterNetEvent('antivpn:notifyAdmins', function(playerName, playerId, reason)
    for _, player in ipairs(GetPlayers()) do
        if isAdmin(tonumber(player)) then
            TriggerClientEvent('chat:addMessage', tonumber(player), {
                color = {255, 0, 0},
                multiline = true,
                args = {'[SECURITY]', 'VPN Detection: ' .. playerName .. ' (' .. playerId .. ') - ' .. reason}
            })
        end
    end
end)

print('^2[AntiVPN]^7 Admin commands loaded successfully!')
