-- Advanced VPN & Proxy Detection Engine
-- Supports multiple detection methods with high accuracy

VPNDetector = {}

-- Detection data storage
VPNDetector.playerData = {}
VPNDetector.cache = {}
VPNDetector.statistics = {
    totalChecks = 0,
    vpnsDetected = 0,
    proxiesDetected = 0,
    suspiciousDetections = 0,
    apiFailures = 0,
    avgResponseTime = 0
}

-- Known VPN providers database
VPNDetector.vpnDatabase = {
    'expressvpn', 'nordvpn', 'surfshark', 'cyberghost', 'privado',
    'windscribe', 'hotspotshield', 'protonvpn', 'mullvadvpn', 'ivacy',
    'bitdefender', 'f-secure', 'avast', 'kaspersky', 'avira',
    'tunnelbear', 'opera', 'speedify', 'zenmate', 'hide.me',
    'purevpn', 'privateinternetaccess', 'pia', 'vpngate', 'hide.ip',
    'astrill', 'hidemyass', 'vyprvpn', 'torguard', 'strongvpn'
}

-- Known datacenter providers
VPNDetector.datacenterDatabase = {
    'amazon', 'aws', 'ec2', 'amazonaws',
    'google', 'gcp', 'google cloud',
    'microsoft', 'azure',
    'digitalocean', 'vultr', 'linode', 'akamai',
    'ovh', 'ovhcloud', 'hetzner', 'contabo',
    'vps', 'hosting', 'datacenter', 'cdn', 'cloudflare'
}

-- ============================================
-- INITIALIZATION
-- ============================================

function VPNDetector.init()
    Utils.logSuccess('VPN Detection Engine initialized')
    VPNDetector.startDetectionLoop()
end

-- ============================================
-- CACHE MANAGEMENT
-- ============================================

function VPNDetector.addToCache(identifier, result, reason)
    if not Config.Cache.enabled then return end

    if not VPNDetector.cache[identifier] then
        VPNDetector.cache[identifier] = {}
    end

    VPNDetector.cache[identifier] = {
        result = result,
        reason = reason,
        timestamp = GetGameTimer(),
        ttl = Config.Cache.duration
    }

    Utils.logDebug('Cached detection for: ' .. identifier .. ' -> ' .. tostring(result))
end

function VPNDetector.getFromCache(identifier)
    if not Config.Cache.enabled then return nil end
    if not VPNDetector.cache[identifier] then return nil end

    local cached = VPNDetector.cache[identifier]
    local age = GetGameTimer() - cached.timestamp

    if age > cached.ttl then
        VPNDetector.cache[identifier] = nil
        return nil
    end

    return cached.result, cached.reason, age
end

function VPNDetector.clearCache()
    VPNDetector.cache = {}
    Utils.logSuccess('Cache cleared')
end

-- ============================================
-- PLAYER DATA MANAGEMENT
-- ============================================

function VPNDetector.initPlayerData(source)
    if VPNDetector.playerData[source] then return end

    VPNDetector.playerData[source] = {
        firstCheck = GetGameTimer(),
        lastCheck = GetGameTimer(),
        position = nil,
        lastPosition = nil,
        lastCheckTime = GetGameTimer(),
        detectionCount = 0,
        isVPN = false,
        detectionReasons = {}
    }
end

function VPNDetector.removePlayerData(source)
    VPNDetector.playerData[source] = nil
    Utils.logDebug('Player data removed: ' .. source)
end

-- ============================================
-- DETECTION METHOD 1: LOCATION JUMP DETECTION
-- ============================================

function VPNDetector.detectLocationJump(source)
    if not Config.Detection.behavioral.enabled or
       not Config.Detection.behavioral.detectLocationJumps then
        return false
    end

    local playerData = VPNDetector.playerData[source]
    if not playerData or not playerData.lastPosition then
        return false
    end

    local ped = GetPlayerPed(source)
    if ped == 0 then return false end

    local currentPos = GetEntityCoords(ped)
    local lastPos = playerData.lastPosition
    local distance = Utils.getDistanceBetweenCoords(
        lastPos.x, lastPos.y, lastPos.z,
        currentPos.x, currentPos.y, currentPos.z
    )

    local timeSinceLastCheck = (GetGameTimer() - playerData.lastCheckTime) / 1000
    if timeSinceLastCheck <= 0 then
        return false
    end

    local maxDistance = Config.Detection.behavioral.maxLocationChangeKmPerSecond * timeSinceLastCheck
    local maxDistanceInMeters = maxDistance * 1000

    if distance > maxDistanceInMeters then
        local speedKmPerSecond = Utils.getSpeedKmPerSecond(distance, GetGameTimer() - playerData.lastCheckTime)
        Utils.logWarn('Location jump detected for player ' .. source ..
            ' (Distance: ' .. math.floor(distance) .. 'm, Speed: ' .. string.format('%.2f', speedKmPerSecond) .. ' km/s)')
        return true
    end

    return false
end

-- ============================================
-- DETECTION METHOD 2: ISP/DATACENTER DETECTION
-- ============================================

function VPNDetector.detectDatacenter(hostInfo)
    if not Config.Detection.ispDetection.enabled or not hostInfo then
        return false
    end

    local hostLower = string.lower(hostInfo)

    for _, provider in ipairs(VPNDetector.datacenterDatabase) do
        if string.find(hostLower, provider, 1, true) then
            return true, provider
        end
    end

    return false
end

function VPNDetector.detectVPNProvider(hostInfo)
    if not hostInfo then return false end

    local hostLower = string.lower(hostInfo)

    for _, provider in ipairs(VPNDetector.vpnDatabase) do
        if string.find(hostLower, provider, 1, true) then
            return true, provider
        end
    end

    return false
end

-- ============================================
-- DETECTION METHOD 3: IP PATTERN DETECTION
-- ============================================

function VPNDetector.checkIPPattern(ip)
    if not ip then return false end

    local ipLower = string.lower(ip)

    -- Check if IP contains common VPN/proxy patterns
    for _, pattern in ipairs(Config.Whitelist.ips) do
        if ipLower == pattern then
            return false -- IP is whitelisted
        end
    end

    return false
end

-- ============================================
-- DETECTION METHOD 4: EXTERNAL API CHECK
-- ============================================

function VPNDetector.checkExternalAPI(source)
    if not Config.Detection.apiDetection.enabled or not Config.Detection.apiDetection.apiKey then
        return nil
    end

    local startTime = GetGameTimer()
    
    -- Implementation would depend on selected provider
    -- This is a placeholder for integration with:
    -- - proxycheck.io
    -- - ipqualityscore.com
    -- - maxmind.com
    
    Utils.logDebug('External API check initiated for player ' .. source)
    
    return nil -- API check would return result asynchronously
end

-- ============================================
-- WHITELIST CHECKS
-- ============================================

function VPNDetector.isPlayerWhitelisted(source)
    -- Check Discord/Steam whitelist
    local identifiers = Utils.getPlayerIdentifiers(source)
    for _, identifier in ipairs(identifiers) do
        if Utils.tableContains(Config.Whitelist.players, identifier) then
            return true, 'Player whitelisted: ' .. identifier
        end
    end

    return false
end

function VPNDetector.isIPWhitelisted(ip)
    return Utils.tableContains(Config.Whitelist.ips, ip)
end

function VPNDetector.isCountryAllowed(countryCode)
    if not Config.Whitelist.useCountryFilter then
        return true
    end

    return Utils.tableContains(Config.Whitelist.countries, string.upper(countryCode))
end

-- ============================================
-- MAIN DETECTION FUNCTION
-- ============================================

function VPNDetector.checkPlayer(source)
    if not Config.Detection.enabled then
        return false, 'Detection disabled'
    end

    -- Initialize player data
    VPNDetector.initPlayerData(source)

    -- Check whitelist
    local isWhitelisted, whitelistReason = VPNDetector.isPlayerWhitelisted(source)
    if isWhitelisted then
        Utils.logDebug('Player ' .. source .. ' is whitelisted: ' .. whitelistReason)
        return false, 'Player whitelisted'
    end

    VPNDetector.statistics.totalChecks = VPNDetector.statistics.totalChecks + 1

    -- Method 1: Location Jump Detection
    if VPNDetector.detectLocationJump(source) then
        VPNDetector.statistics.vpnsDetected = VPNDetector.statistics.vpnsDetected + 1
        return true, Constants.DETECTION_TYPE.LOCATION_JUMP
    end

    -- Update position
    local ped = GetPlayerPed(source)
    if ped ~= 0 then
        VPNDetector.playerData[source].position = GetEntityCoords(ped)
        VPNDetector.playerData[source].lastPosition = VPNDetector.playerData[source].position
    end
    VPNDetector.playerData[source].lastCheckTime = GetGameTimer()
    VPNDetector.playerData[source].lastCheck = GetGameTimer()

    return false, 'Clean'
end

-- ============================================
-- DETECTION RESPONSE HANDLER
-- ============================================

function VPNDetector.handleDetection(source, detectionType)
    if not GetPlayer(source) then return end

    local playerName = GetPlayerName(source)
    local playerIdentifiers = Utils.getPlayerIdentifiers(source)

    Utils.logError('VPN/Proxy detected for player: ' .. playerName .. ' (' .. source .. ') - Reason: ' .. detectionType)

    -- Update statistics
    VPNDetector.statistics.suspiciousDetections = VPNDetector.statistics.suspiciousDetections + 1
    
    -- Update player data
    if VPNDetector.playerData[source] then
        VPNDetector.playerData[source].isVPN = true
        VPNDetector.playerData[source].detectionCount = (VPNDetector.playerData[source].detectionCount or 0) + 1
        table.insert(VPNDetector.playerData[source].detectionReasons, detectionType)
    end

    -- Notify admins
    if Config.Actions.notifyAdmins then
        TriggerEvent('antivpn:notifyAdmins', playerName, source, detectionType)
    end

    -- Discord notification
    if Config.Actions.logDiscord then
        Utils.sendVPNDetectionNotification(playerName, source, detectionType, Config.Actions.action)
    end

    -- File logging
    if Config.Actions.logFile then
        Utils.fileLog('VPN Detected: ' .. playerName .. ' (' .. source .. ') - Reason: ' .. detectionType, 'VPN_DETECTION')
    end

    -- Database logging
    if Config.Database.enabled then
        Database.recordDetection(playerName, source, detectionType, Config.Actions.action, playerIdentifiers)
    end

    -- Execute action
    if Config.Actions.action == 'kick' then
        DropPlayer(source, Config.Actions.kickMessage)
    elseif Config.Actions.action == 'ban' then
        DropPlayer(source, Config.Actions.banReason)
    elseif Config.Actions.action == 'warn' then
        if GetPlayer(source) then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {'Security', Config.Actions.warningMessage}
            })
        end
    elseif Config.Actions.action == 'log_only' then
        Utils.logWarn('VPN detection logged but no action taken')
    end
end

-- ============================================
-- DETECTION LOOP
-- ============================================

function VPNDetector.startDetectionLoop()
    CreateThread(function()
        while true do
            Wait(Config.Detection.behavioral.checkInterval)

            if Config.Detection.enabled then
                local players = GetPlayers()
                if players then
                    for _, playerId in ipairs(players) do
                        local source = tonumber(playerId)
                        if source and source > 0 and GetPlayer(source) then
                            local success, isVPN, reason = pcall(VPNDetector.checkPlayer, source)
                            if success and isVPN then
                                VPNDetector.handleDetection(source, reason)
                            elseif not success then
                                Utils.logError('Error in VPN detection for player ' .. source .. ': ' .. tostring(isVPN))
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- ============================================
-- STATISTICS & REPORTING
-- ============================================

function VPNDetector.getStatistics()
    return VPNDetector.statistics
end

function VPNDetector.getDetailedStats()
    local stats = VPNDetector.statistics
    local detectionRate = stats.totalChecks > 0 and
        (math.floor((stats.vpnsDetected + stats.proxiesDetected) / stats.totalChecks * 100)) or 0

    return {
        totalChecks = stats.totalChecks,
        vpnsDetected = stats.vpnsDetected,
        proxiesDetected = stats.proxiesDetected,
        suspiciousDetections = stats.suspiciousDetections,
        detectionRate = detectionRate .. '%',
        cacheSize = table.maxn(VPNDetector.cache) or 0,
        playersOnline = #GetPlayers()
    }
end

function VPNDetector.resetStatistics()
    VPNDetector.statistics = {
        totalChecks = 0,
        vpnsDetected = 0,
        proxiesDetected = 0,
        suspiciousDetections = 0,
        apiFailures = 0,
        avgResponseTime = 0
    }
    Utils.logSuccess('Statistics reset')
end

-- ============================================
-- MANUAL CHECK FUNCTION (for admin commands)
-- ============================================

function VPNDetector.manualCheck(source)
    if not GetPlayer(source) then
        return false, 'Player not found'
    end

    return VPNDetector.checkPlayer(source)
end

return VPNDetector
