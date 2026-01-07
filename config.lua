Config = {}

-- Detekční metody
Config.Detection = {
    enabled = true,
    
    -- Metoda 1: IP databáze (offline seznam VPN IP)
    ipDatabase = {
        enabled = true,
        checkInterval = 300000, -- ms (5 minut)
    },
    
    -- Metoda 2: Behavioral detection (detekce chování)
    behavioral = {
        enabled = true,
        detectLocationJumps = true,
        maxLocationChangeKmPerSecond = 900, -- rychlost přesunu mezi místy
        checkInterval = 1000,
    },
    
    -- Metoda 3: ISP/Datacenter detekce
    ispDetection = {
        enabled = true,
        suspiciousProviders = {
            'amazon', 'google', 'azure', 'digitalocean', 'vultr', 'linode',
            'ovh', 'vps', 'hosting', 'datacenter', 'vpn', 'proxy'
        }
    }
}

-- Akce při detekci VPN
Config.Actions = {
    action = 'kick', -- 'kick' | 'ban' | 'warn'
    kickMessage = 'VPN detekován. VPN není na tomto serveru povolena.',
    banDuration = 2592000, -- sekund (30 dní)
    logDiscord = true,
    logFile = true
}

-- Whitelist
Config.Whitelist = {
    players = {
        -- 'discord:123456789', -- příklad
    },
    ips = {
        -- '1.2.3.4', -- příklad
    },
    countries = {
        'CZ', 'SK', 'PL', 'DE' -- povolené země
    }
}

-- Discord webhook pro logy
Config.Discord = {
    webhook = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE',
    color = 16711680, -- červená
    username = 'AntiVPN Detection'
}

-- Cache pro IP adresy (aby se neotestovaly neustále)
Config.Cache = {
    enabled = true,
    duration = 3600000 -- ms (1 hodina)
}

-- Admin příkazy
Config.Commands = {
    checkVPN = 'checkvpn',
    whitelistIP = 'whitelistip',
    removeWhitelist = 'removewhitelist',
    vpnStats = 'vpnstats'
}
