-- API Handler - Integration with external VPN detection services
-- Supports: proxycheck.io, ipqualityscore.com, maxmind, and more

APIHandler = {}

-- ============================================
-- PROXYCHECK.IO INTEGRATION
-- ============================================

function APIHandler.checkProxycheck(ip, callback)
    if not Config.Detection.apiDetection.apiKey then
        Utils.logError('ProxyCheck API key not configured')
        callback(nil, 'API key missing')
        return
    end

    local url = 'https://proxycheck.io/v2/' .. ip .. '?key=' .. Config.Detection.apiDetection.apiKey .. '&vpn=1'

    PerformHttpRequest(url, function(statusCode, response, headers)
        if statusCode == 200 then
            local data = json.decode(response)
            if data and data[ip] then
                local result = data[ip]
                
                local isVPN = tonumber(result.vpn) == 1
                local isProxy = tonumber(result.proxy) == 1
                local isFound = tonumber(result.asn) ~= 0
                local provider = result.provider or 'Unknown'

                callback({
                    isVPN = isVPN,
                    isProxy = isProxy,
                    provider = provider,
                    country = result.country,
                    isp = result.isp,
                    found = isFound
                }, nil)
            else
                callback(nil, 'Invalid response')
            end
        else
            Utils.logError('ProxyCheck API error: ' .. statusCode)
            callback(nil, 'HTTP ' .. statusCode)
        end
    end, 'GET', '', {})
end

-- ============================================
-- IPQUALITYSCORE INTEGRATION
-- ============================================

function APIHandler.checkIPQualityScore(ip, callback)
    if not Config.Detection.apiDetection.apiKey then
        Utils.logError('IPQualityScore API key not configured')
        callback(nil, 'API key missing')
        return
    end

    local url = 'https://ipqualityscore.com/api/json/ip/' .. ip .. '?key=' .. Config.Detection.apiDetection.apiKey

    PerformHttpRequest(url, function(statusCode, response, headers)
        if statusCode == 200 then
            local data = json.decode(response)
            
            if data then
                callback({
                    isVPN = data.vpn,
                    isProxy = data.proxy,
                    isTor = data.is_crawler,
                    country = data.country_code,
                    isp = data.ISP,
                    threat_level = data.threat_level
                }, nil)
            else
                callback(nil, 'Invalid response')
            end
        else
            Utils.logError('IPQualityScore API error: ' .. statusCode)
            callback(nil, 'HTTP ' .. statusCode)
        end
    end, 'GET', '', {})
end

-- ============================================
-- GENERIC API HANDLER
-- ============================================

function APIHandler.checkIP(ip, callback)
    if not Config.Detection.apiDetection.enabled then
        callback(nil, 'API detection disabled')
        return
    end

    local provider = string.lower(Config.Detection.apiDetection.provider or 'proxycheck')

    if provider == 'proxycheck' then
        APIHandler.checkProxycheck(ip, callback)
    elseif provider == 'ipquality' then
        APIHandler.checkIPQualityScore(ip, callback)
    else
        Utils.logError('Unknown API provider: ' .. provider)
        callback(nil, 'Unknown provider')
    end
end

-- ============================================
-- ASYNC API CHECKING WITH TIMEOUT
-- ============================================

function APIHandler.checkIPAsync(ip, timeout)
    timeout = timeout or Config.Detection.apiDetection.timeout

    return Citizen.CreateThread(function()
        local result = nil
        local error = nil
        local done = false

        APIHandler.checkIP(ip, function(res, err)
            result = res
            error = err
            done = true
        end)

        -- Wait for result or timeout
        local startTime = GetGameTimer()
        while not done and (GetGameTimer() - startTime) < timeout do
            Wait(10)
        end

        if done then
            return result, error
        else
            return nil, 'Timeout'
        end
    end)
end

-- ============================================
-- BATCH API CHECKING
-- ============================================

function APIHandler.checkMultipleIPs(ips, callback)
    local results = {}
    local completed = 0
    local total = #ips

    for _, ip in ipairs(ips) do
        APIHandler.checkIP(ip, function(result, error)
            results[ip] = {
                result = result,
                error = error
            }
            completed = completed + 1

            if completed == total then
                callback(results)
            end
        end)
    end
end

-- ============================================
-- RATE LIMITING
-- ============================================

APIHandler.requestQueue = {}
APIHandler.requestLimiter = {
    maxRequests = Config.Advanced.maxConcurrentRequests,
    activeRequests = 0,
    queue = {}
}

function APIHandler.enqueueRequest(ip, callback)
    table.insert(APIHandler.requestLimiter.queue, {
        ip = ip,
        callback = callback
    })
    APIHandler.processQueue()
end

function APIHandler.processQueue()
    while #APIHandler.requestLimiter.queue > 0 and 
          APIHandler.requestLimiter.activeRequests < APIHandler.requestLimiter.maxRequests do
        
        local request = table.remove(APIHandler.requestLimiter.queue, 1)
        APIHandler.requestLimiter.activeRequests = APIHandler.requestLimiter.activeRequests + 1

        APIHandler.checkIP(request.ip, function(result, error)
            APIHandler.requestLimiter.activeRequests = APIHandler.requestLimiter.activeRequests - 1
            request.callback(result, error)
            APIHandler.processQueue()
        end)
    end
end

-- ============================================
-- CACHING API RESULTS
-- ============================================

function APIHandler.cacheResult(ip, result)
    VPNDetector.addToCache(ip, result, 'API Check')
end

function APIHandler.getCachedResult(ip)
    return VPNDetector.getFromCache(ip)
end

-- ============================================
-- ERROR HANDLING & RETRY
-- ============================================

function APIHandler.checkWithRetry(ip, callback, retries)
    retries = retries or 0
    local maxRetries = Config.Advanced.maxRetries

    APIHandler.checkIP(ip, function(result, error)
        if error and retries < maxRetries and Config.Advanced.retryFailedRequests then
            Utils.logDebug('Retrying API check for: ' .. ip .. ' (Attempt ' .. (retries + 1) .. ')')
            Wait(1000) -- Wait before retry
            APIHandler.checkWithRetry(ip, callback, retries + 1)
        else
            if error then
                VPNDetector.statistics.apiFailures = VPNDetector.statistics.apiFailures + 1
            end
            callback(result, error)
        end
    end)
end

return APIHandler
