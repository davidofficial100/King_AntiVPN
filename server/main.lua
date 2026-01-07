-- Advanced Anti-VPN Detection System - Main Server Module
-- Handles initialization, events, and lifecycle management

-- ============================================
-- RESOURCE LIFECYCLE EVENTS
-- ============================================

AddEventHandler('onServerResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    -- Validate configuration
    if not Utils.validateConfig() then
        Utils.logError('Configuration validation failed. Please check config.lua')
        return
    end

    -- Initialize database
    Database.init()

    -- Initialize VPN detector
    VPNDetector.init()

    -- Log startup info
    Utils.logSuccess('======================================')
    Utils.logSuccess('Advanced Anti-VPN Detection System v2.0.0')
    Utils.logSuccess('======================================')
    Utils.logSuccess('Detection enabled: ' .. tostring(Config.Detection.enabled))
    Utils.logSuccess('Action: ' .. Config.Actions.action)
    Utils.logSuccess('Discord logging: ' .. tostring(Config.Actions.logDiscord))
    Utils.logSuccess('Database logging: ' .. tostring(Config.Database.enabled))
    Utils.logSuccess('======================================')
end)

AddEventHandler('onServerResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    Utils.logWarn('Anti-VPN Detection System shutting down...')
    
    -- Clean up player data
    for source in pairs(VPNDetector.playerData) do
        VPNDetector.removePlayerData(source)
    end

    Utils.logSuccess('Anti-VPN Detection System stopped')
end)

-- ============================================
-- PLAYER LIFECYCLE EVENTS
-- ============================================

AddEventHandler('playerJoining', function()
    local source = source
    local playerName = GetPlayerName(source)

    Utils.logDebug('Player joining: ' .. playerName .. ' (' .. source .. ')')

    -- Initialize player detection data
    VPNDetector.initPlayerData(source)

    -- Log player identifiers for debugging
    local identifiers = Utils.getPlayerIdentifiers(source)
    for _, identifier in ipairs(identifiers) do
        Utils.logDebug('  Identifier: ' .. identifier)
    end
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    local playerName = GetPlayerName(source)

    Utils.logDebug('Player dropped: ' .. playerName .. ' (' .. source .. ') - Reason: ' .. reason)

    -- Clean up player data
    VPNDetector.removePlayerData(source)
end)

-- ============================================
-- DISCORD NOTIFICATION SYSTEM
-- ============================================

RegisterNetEvent('antivpn:notifyAdmins', function(playerName, playerId, reason)
    local onlineAdmins = 0

    -- Notify all online admins
    for _, player in ipairs(GetPlayers()) do
        local playerSource = tonumber(player)
        -- TODO: Add proper admin check here
        onlineAdmins = onlineAdmins + 1
    end

    Utils.logWarn('VPN Detection notified to ' .. onlineAdmins .. ' admins')
end)

-- ============================================
-- MONITORING & PERIODIC CHECKS
-- ============================================

-- Periodic health check (every 5 minutes)
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes

        if Config.Advanced.trackStats then
            local stats = VPNDetector.getDetailedStats()
            Utils.logDebug('Health Check - Total checks: ' .. stats.totalChecks ..
                ', VPNs detected: ' .. stats.vpnsDetected ..
                ', Detection rate: ' .. stats.detectionRate)
        end
    end
end)

-- Periodic cache cleanup (every 30 minutes)
CreateThread(function()
    while true do
        Wait(1800000) -- 30 minutes

        if Config.Cache.enabled then
            local cacheSize = 0
            for _ in pairs(VPNDetector.cache) do
                cacheSize = cacheSize + 1
            end

            if cacheSize > Config.Cache.maxSize then
                VPNDetector.clearCache()
                Utils.logDebug('Cache cleared due to size limit')
            end
        end
    end
end)

-- ============================================
-- EXPORTS FOR OTHER RESOURCES
-- ============================================

-- Check if player is using VPN
exports('isPlayerVPN', function(source)
    if not VPNDetector.playerData[source] then
        return VPNDetector.manualCheck(source)
    end
    return VPNDetector.playerData[source].isVPN
end)

-- Get detailed VPN check result
exports('checkPlayerVPN', function(source)
    local isVPN, reason = VPNDetector.checkPlayer(source)
    return {
        isVPN = isVPN,
        reason = reason,
        detectedAt = os.time()
    }
end)

-- Get current statistics
exports('getAntiVPNStats', function()
    return VPNDetector.getDetailedStats()
end)

-- Get detection history
exports('getDetectionHistory', function(limit)
    return Database.getDetectionHistory(limit)
end)

-- Get statistics for period
exports('getStatisticsForPeriod', function(days)
    return Database.getStatisticsForPeriod(days)
end)

-- Whitelist a player
exports('whitelistPlayer', function(source)
    local identifier = Utils.getIdentifierOfType(source, 'discord')
    if identifier and not Utils.tableContains(Config.Whitelist.players, identifier) then
        table.insert(Config.Whitelist.players, identifier)
        Utils.logSuccess('Player whitelisted via export: ' .. identifier)
        return true
    end
    return false
end)

-- Clear cache
exports('clearDetectionCache', function()
    VPNDetector.clearCache()
    return true
end)

-- Reload configuration
exports('reloadAntiVPNConfig', function()
    if not Utils.validateConfig() then
        return false
    end
    VPNDetector.clearCache()
    Utils.logSuccess('AntiVPN config reloaded via export')
    return true
end)

-- ============================================
-- TESTING & DEBUG COMMANDS (Console only)
-- ============================================

RegisterCommand('antivpn_debug', function(source, args, rawCommand)
    if source ~= 0 then return end

    local command = args[1]

    if command == 'stats' then
        local stats = VPNDetector.getDetailedStats()
        print('^2[AntiVPN Debug] Statistics:^7')
        print('  Total Checks: ' .. stats.totalChecks)
        print('  VPNs Detected: ' .. stats.vpnsDetected)
        print('  Detection Rate: ' .. stats.detectionRate)
        print('  Cache Size: ' .. stats.cacheSize)

    elseif command == 'players' then
        local players = GetPlayers()
        print('^2[AntiVPN Debug] Online Players:^7')
        for _, playerId in ipairs(players) do
            local name = GetPlayerName(tonumber(playerId))
            print('  ID: ' .. playerId .. ' | Name: ' .. name)
        end

    elseif command == 'cache_clear' then
        VPNDetector.clearCache()
        print('^2[AntiVPN Debug] Cache cleared^7')

    elseif command == 'check' then
        local targetId = tonumber(args[2])
        if targetId and GetPlayer(targetId) then
            local isVPN, reason = VPNDetector.manualCheck(targetId)
            print('^2[AntiVPN Debug] Manual Check for ID ' .. targetId .. ':^7')
            print('  Result: ' .. (isVPN and 'VPN DETECTED' or 'CLEAN'))
            print('  Reason: ' .. reason)
        else
            print('^1Invalid player ID^7')
        end

    else
        print('^3[AntiVPN Debug] Available commands:^7')
        print('  antivpn_debug stats - Show statistics')
        print('  antivpn_debug players - List online players')
        print('  antivpn_debug cache_clear - Clear detection cache')
        print('  antivpn_debug check <id> - Manually check player')
    end
end, false)

print('^2[AntiVPN]^7 Main server module loaded successfully!')
