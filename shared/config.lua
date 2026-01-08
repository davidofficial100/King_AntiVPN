-- Advanced Anti-VPN & Anti-Proxy Detection System
-- Configuration File

Config = {}

-- ============================================
-- DETECTION SETTINGS
-- ============================================
Config.Detection = {
    -- Enable/disable entire detection system
    enabled = true,

    -- Method 1: Behavioral Detection (Location Jump Detection)
    behavioral = {
        enabled = true,
        detectLocationJumps = true,
        maxLocationChangeKmPerSecond = 900, -- Physics-based warp detection
        checkInterval = 1000 -- ms
    },

    -- Method 2: ISP/Datacenter Detection
    ispDetection = {
        enabled = true,
        checkInterval = 5000 -- ms
    },

    -- Method 3: Proxy Detection (pattern-based)
    proxyDetection = {
        enabled = true,
        checkPattern = true
    },

    -- Method 4: External API Detection (Premium feature)
    -- Supports: proxycheck.io, ipquality.co, maxmind, etc.
    apiDetection = {
        enabled = false,
        provider = 'proxycheck', -- 'proxycheck' | 'ipquality' | 'maxmind'
        apiKey = '', -- Get from provider website
        timeout = 5000, -- ms
        cacheDuration = 3600000 -- 1 hour
    }
}

-- ============================================
-- ACTION SETTINGS
-- ============================================
Config.Actions = {
    -- Default action: 'kick' | 'ban' | 'warn' | 'log_only'
    action = 'kick',

    -- Custom messages
    kickMessage = 'VPN/Proxy detected. VPNs are not allowed on this server.',
    warningMessage = 'Warning: VPN/Proxy detected. Continued use may result in being kicked.',
    
    -- Ban settings (if action = 'ban')
    banDuration = 2592000, -- seconds (30 days), 0 = permanent
    banReason = 'VPN/Proxy Usage Detected',

    -- Notify admins of detection
    notifyAdmins = true,
    adminMessage = '^1[SECURITY] ^7VPN/Proxy detected: %s (%s) - Reason: %s',

    -- Log settings
    logDiscord = true,
    logFile = true,
    logFilePath = 'resources/antivpn/logs/detections.log'
}

-- ============================================
-- WHITELIST SETTINGS
-- ============================================
Config.Whitelist = {
    -- Whitelist entire Discord ID
    players = {
        -- Examples:
        -- 'discord:123456789',
        -- 'steam:110000123456789'
    },

    -- Whitelist specific IP addresses
    ips = {
        -- Examples:
        -- '127.0.0.1', -- Localhost
        -- '192.168.1.0/24' -- Subnet
    },

    -- Whitelist specific countries (ISO 3166-1 alpha-2)
    countries = {
        'US', 'GB', 'CA', 'AU', 'NZ', 'DE', 'FR', 'IT', 'ES', 'NL'
    },

    -- Allow specific VPN providers (if you want to allow some)
    allowedVPNs = {
        -- Examples:
        -- 'corporate-vpn-1'
    },

    -- Enable country-based filtering
    useCountryFilter = false
}

-- ============================================
-- DISCORD WEBHOOK SETTINGS
-- ============================================
Config.Discord = {
    -- Your Discord webhook URL (get from Discord channel settings)
    webhook = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN',

    -- Embed color (decimal format)
    -- Red: 16711680, Green: 65280, Yellow: 16776960, Blue: 255
    colorDetection = 16711680, -- Red for VPN detection
    colorWarning = 16776960, -- Yellow for warnings
    colorInfo = 255, -- Blue for info
    colorSuccess = 65280, -- Green for success

    -- Webhook username
    username = 'AntiVPN Detector',

    -- Include thumbnail
    includeThumbnail = false,
    thumbnailUrl = 'https://via.placeholder.com/100'
}

-- ============================================
-- CACHING SETTINGS
-- ============================================
Config.Cache = {
    -- Enable result caching
    enabled = true,

    -- Cache duration (in milliseconds)
    duration = 3600000, -- 1 hour

    -- Maximum cache size (in entries)
    maxSize = 1000
}

-- ============================================
-- ADVANCED SETTINGS
-- ============================================
Config.Advanced = {
    -- Debug mode (console output)
    debugMode = false,

    -- Enable statistics tracking
    trackStats = true,

    -- Maximum concurrent API requests
    maxConcurrentRequests = 5,

    -- Retry failed API requests
    retryFailedRequests = true,
    maxRetries = 3,

    -- Timeout for API requests (ms)
    requestTimeout = 5000,

    -- Block on error (if API fails, should we kick?)
    blockOnAPIError = false,

    -- Store detection history
    storeHistory = true,
    maxHistoryEntries = 10000
}

-- ============================================
-- ADMIN COMMANDS
-- ============================================
Config.Commands = {
    checkVPN = 'checkvpn',           -- /checkvpn <id> - Check if player uses VPN
    checkIP = 'checkip',             -- /checkip <ip> - Check specific IP
    vpnStats = 'vpnstats',           -- /vpnstats - Show statistics
    whitelistIP = 'whitelistip',     -- /whitelistip <ip> - Add IP to whitelist
    whitelistPlayer = 'whitelistplayer', -- /whitelistplayer <id> - Whitelist player
    removeWhitelist = 'removewhitelist', -- /removewhitelist <ip/id> - Remove from whitelist
    reloadConfig = 'reloadantivpn',  -- /reloadantivpn - Reload configuration
    listDetections = 'detectionlist' -- /detectionlist [limit] - Show recent detections
}

-- ============================================
-- ADMIN ROLES (for permission checking)
-- ============================================
Config.AdminRoles = {
    -- Set to true if using permission system
    usePermissionSystem = false,

    -- Roles that can use AntiVPN commands
    allowedRoles = {
        'admin',
        'superadmin',
        'moderator'
    },

    -- Discord role IDs (if using Discord bot integration)
    discordRoleIds = {
        -- 'role_id_here'
    }
}

-- ============================================
-- LOGGING & MONITORING
-- ============================================
Config.Logging = {
    -- Log level: 'debug' | 'info' | 'warn' | 'error'
    level = 'info',

    -- Log format
    format = '[%timestamp%] [%level%] %message%',

    -- Include file logging
    fileLogging = true,

    -- Include console logging
    consoleLogging = true,

    -- Log file rotation (max size in KB)
    maxFileSize = 10240, -- 10 MB

    -- Keep log files for (in days)
    keepLogsFor = 30
}

-- ============================================
-- GEO-IP SETTINGS
-- ============================================
Config.GeoIP = {
    -- Enable GeoIP-based detection
    enabled = false,

    -- GeoIP API provider: 'maxmind' | 'geoip2' | 'ip-api'
    provider = 'maxmind',

    -- API Key for GeoIP service
    apiKey = '',

    -- Detect location inconsistencies
    detectLocationInconsistencies = true,

    -- Maximum distance change per second (km/s)
    maxSpeedPerSecond = 900 -- ~Mach 1
}

-- ============================================
-- DATABASE SETTINGS
-- ============================================
Config.Database = {
    -- Store detections in database
    enabled = false,

    -- Database type: 'file' | 'mysql' | 'postgresql'
    type = 'file',

    -- File-based storage path
    filePath = 'resources/antivpn/data/',

    -- MySQL connection (if using MySQL)
    mysql = {
        host = 'localhost',
        user = 'root',
        password = '',
        database = 'fivem'
    }
}

print('^2[AntiVPN]^7 Configuration loaded successfully!')
