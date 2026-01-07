-- Anti-VPN Detection System Constants
-- This file contains all constants used throughout the system

Constants = {
    -- Detection types
    DETECTION_TYPE = {
        LOCATION_JUMP = 'Location Jump',
        ISP_DATACENTER = 'ISP/Datacenter',
        PROXY_IP = 'Proxy IP',
        VPN_PROVIDER = 'VPN Provider',
        SUSPICIOUS_PATTERN = 'Suspicious Pattern',
        API_CHECK = 'API Check'
    },

    -- Action types
    ACTION = {
        KICK = 'kick',
        BAN = 'ban',
        WARN = 'warn',
        LOG_ONLY = 'log_only'
    },

    -- Status codes
    STATUS = {
        CLEAN = 0,
        SUSPICIOUS = 1,
        VPN_DETECTED = 2,
        PROXY_DETECTED = 3,
        ERROR = 4
    },

    -- Default timeouts (in ms)
    TIMEOUT = {
        API_REQUEST = 5000,
        LOCATION_CHECK = 1000,
        DETECTION_INTERVAL = 1000,
        CACHE_DURATION = 3600000 -- 1 hour
    },

    -- Common VPN providers
    VPN_PROVIDERS = {
        'expressvpn', 'nordvpn', 'surfshark', 'cyberghost', 'privado',
        'windscribe', 'hotspotshield', 'protonvpn', 'mullvadvpn', 'ivacy',
        'bitdefender', 'f-secure', 'avast', 'kaspersky', 'mcafee',
        'tunnelbear', 'opera vpn', 'speedify', 'zenmate', 'hide.me',
        'purevpn', 'pia', 'vpngate', 'vpnbook', 'hide.ip'
    },

    -- Datacenter providers
    DATACENTER_PROVIDERS = {
        'amazon', 'aws', 'ec2', 'google cloud', 'gcp', 'microsoft azure',
        'digitalocean', 'vultr', 'linode', 'ovh', 'hetzner', 'contabo',
        'vps', 'hosting', 'datacenter', 'cdn', 'cloudflare'
    },

    -- Proxy detection keywords
    PROXY_KEYWORDS = {
        'proxy', 'vpn', 'tor', 'socks', 'http proxy', 'https proxy'
    }
}

return Constants
