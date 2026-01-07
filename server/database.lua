-- Database Module - Handles persistent storage of detections

Database = {}

Database.detections = {}
Database.maxEntries = Config.Advanced.maxHistoryEntries or 10000

-- ============================================
-- FILE OPERATIONS
-- ============================================

function Database.ensureFileExists()
    local path = Config.Actions.logFilePath
    local file = io.open(path, 'a')
    if file then
        file:close()
        return true
    end
    return false
end

function Database.loadFromFile()
    if not Config.Database.enabled then return end

    local path = Config.Database.filePath .. 'detections.json'
    local file = io.open(path, 'r')

    if file then
        local content = file:read('*a')
        file:close()

        if content and content ~= '' then
            Database.detections = json.decode(content) or {}
            Utils.logSuccess('Loaded ' .. #Database.detections .. ' detection records from file')
        end
    else
        Utils.logDebug('No detection history file found, creating new one')
    end
end

function Database.saveToFile()
    if not Config.Database.enabled then return end

    local path = Config.Database.filePath .. 'detections.json'
    local file = io.open(path, 'w')

    if file then
        file:write(json.encode(Database.detections))
        file:close()
        return true
    else
        Utils.logError('Failed to save detection history to file')
        return false
    end
end

-- ============================================
-- DETECTION RECORDING
-- ============================================

function Database.recordDetection(playerName, playerId, reason, action, identifiers)
    if not Config.Database.enabled and not Config.Advanced.storeHistory then
        return
    end

    local detection = {
        id = #Database.detections + 1,
        playerName = playerName,
        playerId = playerId,
        reason = reason,
        action = action,
        identifiers = identifiers or {},
        timestamp = os.time(),
        dateTime = Utils.getCurrentTimestamp()
    }

    table.insert(Database.detections, detection)

    -- Limit table size
    if #Database.detections > Database.maxEntries then
        table.remove(Database.detections, 1)
    end

    if Config.Database.enabled then
        Database.saveToFile()
    end

    Utils.logDebug('Detection recorded: ' .. playerName .. ' - ' .. reason)
end

-- ============================================
-- QUERY FUNCTIONS
-- ============================================

function Database.getDetectionHistory(limit)
    limit = limit or 50
    local history = {}

    local startIdx = math.max(1, #Database.detections - limit + 1)
    for i = startIdx, #Database.detections do
        table.insert(history, Database.detections[i])
    end

    return history
end

function Database.getDetectionsByPlayer(playerName, limit)
    limit = limit or 50
    local results = {}

    for i = #Database.detections, math.max(1, #Database.detections - limit) + 1, -1 do
        if Database.detections[i].playerName == playerName then
            table.insert(results, Database.detections[i])
        end
        if #results >= limit then break end
    end

    return results
end

function Database.getDetectionsByTimeRange(startTime, endTime)
    local results = {}

    for _, detection in ipairs(Database.detections) do
        if detection.timestamp >= startTime and detection.timestamp <= endTime then
            table.insert(results, detection)
        end
    end

    return results
end

function Database.getDetectionsByReason(reason)
    local results = {}

    for _, detection in ipairs(Database.detections) do
        if detection.reason == reason then
            table.insert(results, detection)
        end
    end

    return results
end

function Database.getDetectionsByAction(action)
    local results = {}

    for _, detection in ipairs(Database.detections) do
        if detection.action == action then
            table.insert(results, detection)
        end
    end

    return results
end

-- ============================================
-- STATISTICS
-- ============================================

function Database.getStatistics()
    local stats = {
        totalDetections = #Database.detections,
        detectionsByReason = {},
        detectionsByAction = {},
        uniquePlayers = {},
        detectionsByDay = {}
    }

    for _, detection in ipairs(Database.detections) do
        -- By reason
        stats.detectionsByReason[detection.reason] = (stats.detectionsByReason[detection.reason] or 0) + 1

        -- By action
        stats.detectionsByAction[detection.action] = (stats.detectionsByAction[detection.action] or 0) + 1

        -- Unique players
        stats.uniquePlayers[detection.playerName] = true

        -- By day
        local day = os.date('%Y-%m-%d', detection.timestamp)
        stats.detectionsByDay[day] = (stats.detectionsByDay[day] or 0) + 1
    end

    stats.uniquePlayersCount = 0
    for _ in pairs(stats.uniquePlayers) do
        stats.uniquePlayersCount = stats.uniquePlayersCount + 1
    end

    return stats
end

function Database.getStatisticsForPeriod(days)
    local startTime = os.time() - (days * 86400)
    local endTime = os.time()

    return Database.getDetectionsByTimeRange(startTime, endTime)
end

-- ============================================
-- CLEANUP & MAINTENANCE
-- ============================================

function Database.clearOldEntries(daysOld)
    daysOld = daysOld or 30
    local cutoffTime = os.time() - (daysOld * 86400)
    local removed = 0

    for i = #Database.detections, 1, -1 do
        if Database.detections[i].timestamp < cutoffTime then
            table.remove(Database.detections, i)
            removed = removed + 1
        end
    end

    if removed > 0 then
        Database.saveToFile()
        Utils.logSuccess('Removed ' .. removed .. ' old detection records')
    end

    return removed
end

function Database.clearAll()
    Database.detections = {}
    Database.saveToFile()
    Utils.logSuccess('All detection records cleared')
end

-- ============================================
-- EXPORT FUNCTIONS
-- ============================================

function Database.exportToCSV()
    local csv = 'ID,PlayerName,PlayerId,Reason,Action,Timestamp\n'

    for _, detection in ipairs(Database.detections) do
        csv = csv .. string.format('%d,"%s",%d,"%s","%s","%s"\n',
            detection.id,
            detection.playerName,
            detection.playerId,
            detection.reason,
            detection.action,
            detection.dateTime
        )
    end

    local file = io.open(Config.Database.filePath .. 'detections_export.csv', 'w')
    if file then
        file:write(csv)
        file:close()
        return true
    end

    return false
end

-- ============================================
-- INITIALIZATION
-- ============================================

function Database.init()
    if not Config.Database.enabled and not Config.Advanced.storeHistory then
        Utils.logDebug('Database persistence disabled')
        return
    end

    Database.loadFromFile()
    
    -- Automatic cleanup (every hour)
    CreateThread(function()
        while true do
            Wait(3600000) -- 1 hour
            if Config.Logging.keepLogsFor > 0 then
                Database.clearOldEntries(Config.Logging.keepLogsFor)
            end
        end
    end)
end

return Database
