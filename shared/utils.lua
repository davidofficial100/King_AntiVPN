-- Anti-VPN Detection System - Utility Functions

Utils = {}

-- Color codes for console output
local Colors = {
    SUCCESS = '^2', -- Green
    ERROR = '^1',   -- Red
    WARN = '^3',    -- Yellow
    INFO = '^5',    -- Purple
    RESET = '^7'    -- White
}

-- ============================================
-- LOGGING FUNCTIONS
-- ============================================

function Utils.log(message, logType, debug)
    logType = logType or 'INFO'
    debug = debug or false

    if debug and not Config.Advanced.debugMode then
        return
    end

    local colorCode = Colors.INFO
    if logType == 'SUCCESS' then colorCode = Colors.SUCCESS
    elseif logType == 'ERROR' then colorCode = Colors.ERROR
    elseif logType == 'WARN' then colorCode = Colors.WARN
    elseif logType == 'DEBUG' then colorCode = Colors.WARN end

    print(colorCode .. '[AntiVPN] [' .. logType .. ']' .. Colors.RESET .. ' ' .. message)
end

function Utils.logDebug(message)
    Utils.log(message, 'DEBUG', true)
end

function Utils.logError(message)
    Utils.log(message, 'ERROR')
end

function Utils.logWarn(message)
    Utils.log(message, 'WARN')
end

function Utils.logSuccess(message)
    Utils.log(message, 'SUCCESS')
end

-- ============================================
-- TIME FORMATTING
-- ============================================

function Utils.formatTime(milliseconds)
    local seconds = math.floor(milliseconds / 1000)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    local days = math.floor(hours / 24)

    if days > 0 then return days .. 'd ' .. (hours % 24) .. 'h' end
    if hours > 0 then return hours .. 'h ' .. (minutes % 60) .. 'm' end
    if minutes > 0 then return minutes .. 'm ' .. (seconds % 60) .. 's' end
    return seconds .. 's'
end

function Utils.formatDuration(seconds)
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    if days > 0 then return days .. 'd' end
    if hours > 0 then return hours .. 'h' end
    if minutes > 0 then return minutes .. 'm' end
    return secs .. 's'
end

function Utils.getCurrentTimestamp()
    return os.date('%Y-%m-%d %H:%M:%S')
end

-- ============================================
-- DISTANCE & LOCATION CALCULATIONS
-- ============================================

function Utils.getDistanceBetweenCoords(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function Utils.getDistance2D(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function Utils.getSpeedKmPerSecond(distance, timeMs)
    local timeSeconds = timeMs / 1000
    if timeSeconds <= 0 then return 0 end
    
    local distanceKm = distance / 1000
    return distanceKm / timeSeconds
end

-- ============================================
-- DISCORD WEBHOOK FUNCTIONS
-- ============================================

function Utils.sendDiscordLog(title, description, color, fields, additionalData)
    if not Config.Discord.webhook or Config.Discord.webhook == '' then
        Utils.logDebug('Discord webhook not configured')
        return false
    end

    local embeds = {{
        title = title,
        description = description,
        color = color or Config.Discord.colorDetection,
        fields = fields or {},
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        footer = {
            text = 'AntiVPN Detection System v2.0.0'
        }
    }}

    local payload = {
        username = Config.Discord.username,
        embeds = embeds
    }

    local success, encoded = pcall(json.encode, payload)
    if not success then
        Utils.logError('Failed to encode Discord payload: ' .. tostring(encoded))
        return false
    end

    PerformHttpRequest(Config.Discord.webhook, function(statusCode, response, headers)
        if statusCode ~= 204 and statusCode ~= 200 then
            Utils.logDebug('Discord webhook returned status: ' .. statusCode)
        else
            Utils.logDebug('Discord notification sent successfully')
        end
    end, 'POST', encoded, {
        ['Content-Type'] = 'application/json'
    })

    return true
end

function Utils.sendVPNDetectionNotification(playerName, playerId, reason, action)
    local fields = {
        { name = 'Player', value = playerName, inline = true },
        { name = 'ID', value = tostring(playerId), inline = true },
        { name = 'Reason', value = reason, inline = false },
        { name = 'Action', value = action, inline = true },
        { name = 'Timestamp', value = Utils.getCurrentTimestamp(), inline = true }
    }

    return Utils.sendDiscordLog(
        '🚨 VPN Detection Alert',
        'A player has been detected using VPN/Proxy services',
        Config.Discord.colorDetection,
        fields
    )
end

-- ============================================
-- FILE LOGGING
-- ============================================

function Utils.fileLog(message, category)
    if not Config.Actions.logFile then return end

    category = category or 'GENERAL'
    local filename = Config.Actions.logFilePath
    if not filename or filename == '' then
        return false
    end

    local timestamp = Utils.getCurrentTimestamp()
    local logMessage = '[' .. timestamp .. '] [' .. category .. '] ' .. message .. '\n'

    -- Ensure directory exists
    local dir = string.match(filename, '(.+)/')
    if dir and dir ~= '' then
        os.execute('mkdir -p ' .. dir)
    end

    local file = io.open(filename, 'a')
    if file then
        file:write(logMessage)
        file:close()
        return true
    else
        print('^1[AntiVPN Error]^7 Failed to write to log file: ' .. filename)
        return false
    end
end

-- ============================================
-- STRING & DATA MANIPULATION
-- ============================================

function Utils.trim(str)
    return (str:gsub('^%s*(.-)%s*$', '%1'))
end

function Utils.split(str, delimiter)
    local result = {}
    local pattern = '([^' .. delimiter .. ']+)'
    for match in str:gmatch(pattern) do
        table.insert(result, match)
    end
    return result
end

function Utils.tableContains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

function Utils.tableFind(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            return i
        end
    end
    return nil
end

function Utils.deepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == 'table' then
            copy[k] = Utils.deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- ============================================
-- IP UTILITIES
-- ============================================

function Utils.isValidIP(ip)
    local a, b, c, d = ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
    if not a then return false end

    a, b, c, d = tonumber(a), tonumber(b), tonumber(c), tonumber(d)
    return a >= 0 and a <= 255 and
           b >= 0 and b <= 255 and
           c >= 0 and c <= 255 and
           d >= 0 and d <= 255
end

function Utils.isPrivateIP(ip)
    local octets = Utils.split(ip, '.')
    if #octets ~= 4 then return false end

    local a = tonumber(octets[1])
    local b = tonumber(octets[2])

    -- 10.0.0.0 - 10.255.255.255
    if a == 10 then return true end

    -- 172.16.0.0 - 172.31.255.255
    if a == 172 and b >= 16 and b <= 31 then return true end

    -- 192.168.0.0 - 192.168.255.255
    if a == 192 and b == 168 then return true end

    -- 127.0.0.1 - 127.255.255.255 (loopback)
    if a == 127 then return true end

    return false
end

-- ============================================
-- PLAYER UTILITIES
-- ============================================

function Utils.getPlayerIdentifiers(source)
    local identifiers = {}
    if not source or source < 0 then return identifiers end
    
    local numIdentifiers = GetNumPlayerIdentifiers(source)
    if not numIdentifiers or numIdentifiers < 0 then return identifiers end
    
    for i = 0, numIdentifiers - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id then
            table.insert(identifiers, id)
        end
    end
    return identifiers
end

function Utils.getIdentifierOfType(source, identifierType)
    if not identifierType then return nil end
    
    local identifiers = Utils.getPlayerIdentifiers(source)
    for _, id in ipairs(identifiers) do
        if id and string.find(id, identifierType .. ':') then
            return id
        end
    end
    return nil
end

function Utils.isPlayerWhitelisted(source)
    local identifiers = Utils.getPlayerIdentifiers(source)
    
    for _, identifier in ipairs(identifiers) do
        if Utils.tableContains(Config.Whitelist.players, identifier) then
            return true, 'Identifier whitelisted: ' .. identifier
        end
    end

    return false
end

-- ============================================
-- VALIDATION
-- ============================================

function Utils.isValidAction(action)
    return action == 'kick' or action == 'ban' or action == 'warn' or action == 'log_only'
end

function Utils.validateConfig()
    local errors = {}

    if not Utils.isValidAction(Config.Actions.action) then
        table.insert(errors, 'Invalid action: ' .. Config.Actions.action)
    end

    if Config.Actions.logDiscord and (not Config.Discord.webhook or Config.Discord.webhook == '') then
        table.insert(errors, 'Discord webhook URL not configured')
    end

    if #errors > 0 then
        Utils.logError('Configuration errors found:')
        for _, error in ipairs(errors) do
            Utils.logError('  - ' .. error)
        end
        return false
    end

    return true
end

return Utils
