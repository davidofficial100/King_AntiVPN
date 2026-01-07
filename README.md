# Advanced Anti-VPN & Anti-Proxy Detection System v2.0.0

A professional-grade VPN and proxy detection system for FiveM servers with multiple detection methods, external API integration, and comprehensive admin controls.

## Features

### Detection Methods
- **Behavioral Detection**: Detects impossible player movements (location jumps)
- **ISP/Datacenter Detection**: Identifies suspicious hosting providers
- **VPN Provider Detection**: Matches against database of known VPN providers
- **External API Integration**: Support for ProxyCheck.io, IPQualityScore, and more
- **Pattern Detection**: Identifies proxy and VPN patterns
- **GeoIP Detection**: Location-based inconsistency detection (optional)

### Admin Controls
- **8+ Admin Commands**: Full control over detection system
- **Whitelist System**: IP, player, and country-based whitelisting
- **Statistics Tracking**: Real-time monitoring and analytics
- **History Logging**: Persistent detection history with database support
- **Discord Integration**: Webhook notifications for detections

### Performance & Reliability
- **Intelligent Caching**: Reduces redundant checks
- **Rate Limiting**: Prevents API throttling
- **Async API Checking**: Non-blocking API requests
- **Automatic Cleanup**: Old logs are automatically removed
- **Error Handling**: Graceful degradation on API failures

## Installation

1. **Download or Clone**
   ```bash
   git clone https://github.com/yourname/antivpn.git
   ```

2. **Place in Resources**
   ```
   resources/antivpn/
   ```

3. **Add to Server Config**
   ```
   ensure antivpn
   ```

4. **Configure** (see Configuration section)

5. **Restart Server**
   ```
   restart antivpn
   ```

## Configuration

### Basic Setup

Edit `/shared/config.lua`:

```lua
-- Enable/disable detection
Config.Detection.enabled = true

-- Action on detection (kick | ban | warn | log_only)
Config.Actions.action = 'kick'

-- Custom kick message
Config.Actions.kickMessage = 'VPN/Proxy detected. VPNs are not allowed on this server.'

-- Discord webhook (optional)
Config.Discord.webhook = 'https://discord.com/api/webhooks/YOUR_ID/YOUR_TOKEN'
```

### External API Setup (Optional)

#### ProxyCheck.io
```lua
Config.Detection.apiDetection = {
    enabled = true,
    provider = 'proxycheck',
    apiKey = 'YOUR_API_KEY_HERE',
    timeout = 5000,
    cacheDuration = 3600000
}
```

Get free API key: https://proxycheck.io

#### IPQualityScore
```lua
Config.Detection.apiDetection = {
    enabled = true,
    provider = 'ipquality',
    apiKey = 'YOUR_API_KEY_HERE',
    timeout = 5000,
    cacheDuration = 3600000
}
```

Get free API key: https://www.ipqualityscore.com

### Whitelist Configuration

```lua
Config.Whitelist = {
    -- Discord/Steam IDs
    players = {
        'discord:123456789',
        'steam:110000123456789'
    },

    -- IP addresses
    ips = {
        '127.0.0.1',
        '192.168.1.0/24'
    },

    -- Allowed countries (ISO 3166-1)
    countries = {
        'US', 'GB', 'CA', 'AU'
    },

    -- Enable country-based filtering
    useCountryFilter = false
}
```

## Admin Commands

### Check Player VPN Status
```
/checkvpn <player_id>
```
Manually check if a player is using VPN
- **Example**: `/checkvpn 1`

### Check IP Address
```
/checkip <ip_address>
```
Check specific IP address with external API
- **Example**: `/checkip 1.2.3.4`

### View Statistics
```
/vpnstats
```
Display current VPN detection statistics
- Shows total checks, detections, and detection rate

### Whitelist IP
```
/whitelistip <ip_address>
```
Add IP address to whitelist
- **Example**: `/whitelistip 1.2.3.4`

### Whitelist Player
```
/whitelistplayer <player_id>
```
Add player's Discord ID to whitelist
- **Example**: `/whitelistplayer 1`

### Remove from Whitelist
```
/removewhitelist <ip_or_identifier>
```
Remove entry from whitelist
- **Example**: `/removewhitelist 1.2.3.4`

### Reload Configuration
```
/reloadantivpn
```
Reload configuration from file

### List Detections
```
/detectionlist [limit]
```
View recent VPN detections
- **Example**: `/detectionlist 20`

## Player Commands

### Help Information
```
/vpnhelp
```
Display help about VPN detection system

### System Info
```
/vpninfo
```
Display AntiVPN system version and information

### Status Check
```
/vpnstatus
```
Check your connection status

## Exports (For Other Resources)

### Check if Player Uses VPN
```lua
local isVPN = exports['antivpn']:isPlayerVPN(playerId)
```

### Detailed VPN Check
```lua
local result = exports['antivpn']:checkPlayerVPN(playerId)
-- Returns: { isVPN = bool, reason = string, detectedAt = timestamp }
```

### Get Statistics
```lua
local stats = exports['antivpn']:getAntiVPNStats()
-- Returns: { totalChecks, vpnsDetected, detectionRate, ... }
```

### Get Detection History
```lua
local history = exports['antivpn']:getDetectionHistory(50)
```

### Get Statistics for Period
```lua
local weekStats = exports['antivpn']:getStatisticsForPeriod(7)
```

### Whitelist Player
```lua
exports['antivpn']:whitelistPlayer(playerId)
```

### Clear Cache
```lua
exports['antivpn']:clearDetectionCache()
```

### Reload Configuration
```lua
exports['antivpn']:reloadAntiVPNConfig()
```

## Debug Commands (Console Only)

```
antivpn_debug stats          - Display statistics
antivpn_debug players        - List online players
antivpn_debug cache_clear    - Clear detection cache
antivpn_debug check <id>     - Manually check player
```

## File Structure

```
antivpn/
├── fxmanifest.lua           - Resource manifest
├── README.md                - This file
├── shared/
│   ├── config.lua           - Configuration file
│   ├── constants.lua        - Constants and enums
│   └── utils.lua            - Utility functions
├── server/
│   ├── main.lua             - Main server module
│   ├── vpn-detector.lua     - Detection engine
│   ├── api-handler.lua      - External API integration
│   ├── database.lua         - Database & persistence
│   └── commands.lua         - Admin commands
└── client/
    └── main.lua             - Client-side handler
```

## Logging

### Console Output
- Real-time status messages
- Error notifications
- Debug information (when debug mode enabled)

### File Logging
Logs stored in: `resources/antivpn/logs/detections.log`

Format: `[YYYY-MM-DD HH:MM:SS] [CATEGORY] Message`

### Discord Logging
Automatic notifications sent to configured Discord webhook

## Performance Considerations

### CPU Impact
- Minimal: ~1-2% per detection check
- Behavioral detection runs every 1 second
- External API checks are asynchronous and cached

### Memory Usage
- Base: ~2-3 MB
- Cache: Additional ~1 MB per 1000 cached entries
- Auto-cleanup keeps memory stable

### Network Usage
- External API: Only when enabled, cached for 1 hour
- Discord webhooks: Only on detection
- File logging: Efficient batch writes

## Troubleshooting

### VPN Detection Not Working
1. Check if `Config.Detection.enabled = true`
2. Verify behavioral detection settings
3. Check console for error messages
4. Enable debug mode: `Config.Advanced.debugMode = true`

### API Requests Failing
1. Verify API key is correct
2. Check API provider status
3. Review rate limiting: `Config.Advanced.maxConcurrentRequests`
4. Check timeout setting: `Config.Detection.apiDetection.timeout`

### Discord Webhook Not Working
1. Verify webhook URL is correct
2. Test webhook: https://webhook.site/
3. Check Discord channel permissions
4. Verify JSON encoding: `Config.Discord.username`

### High False Positives
1. Adjust location jump threshold: `Config.Detection.behavioral.maxLocationChangeKmPerSecond`
2. Review whitelist entries
3. Check for server-wide teleportation events
4. Disable behavioral detection if needed

## Advanced Configuration

### Custom Detection Thresholds
```lua
Config.Detection.behavioral = {
    enabled = true,
    detectLocationJumps = true,
    maxLocationChangeKmPerSecond = 900, -- Adjust this value
    checkInterval = 1000
}
```

### Database Persistence
```lua
Config.Database = {
    enabled = true,
    type = 'file',
    filePath = 'resources/antivpn/data/'
}
```

### Logging Configuration
```lua
Config.Logging = {
    level = 'info', -- debug | info | warn | error
    fileLogging = true,
    consoleLogging = true,
    maxFileSize = 10240, -- KB
    keepLogsFor = 30 -- days
}
```

## API Integration Details

### Supported Providers

#### ProxyCheck.io
- **Free Tier**: 1,000 requests/day
- **Detection**: VPN, Proxy, Datacenter
- **Response Time**: <200ms
- **Accuracy**: ~95%

#### IPQualityScore
- **Free Tier**: 5,000 requests/month
- **Detection**: VPN, Proxy, Tor, Bot, ISP
- **Response Time**: <300ms
- **Accuracy**: ~98%

## Security Notes

1. **Never commit API keys** to public repositories
2. **Use environment variables** for sensitive data
3. **Monitor API usage** to avoid throttling
4. **Regularly update** whitelist entries
5. **Review logs** for suspicious patterns
6. **Disable debug mode** in production

## Performance Optimization Tips

1. **Enable caching**: Reduces redundant checks
2. **Set appropriate check intervals**: Balance accuracy vs performance
3. **Use external APIs sparingly**: API calls are slower than local checks
4. **Limit history entries**: Prevents memory bloat
5. **Regular log cleanup**: Keeps disk space minimal

## Support & Issues

- Report bugs: Include console logs and config (sanitized)
- Feature requests: Describe use case clearly
- Performance issues: Include server stats and player count
- API issues: Include API provider name and error codes

## License

GNU General Public License v3.0 - See LICENSE file for details

## Credits

- Detection methods inspired by Pegasus AC and BlockVPN
- API integrations: ProxyCheck.io, IPQualityScore
- FiveM Community

## Changelog

### v2.0.0 (Current)
- Complete rewrite with enhanced architecture
- Multiple detection methods
- External API integration
- Advanced statistics and reporting
- Improved admin commands
- Database persistence
- Discord webhook support
- Performance optimizations

### v1.0.0
- Initial release
- Basic VPN detection
- Simple kick/ban system

---

**Version**: 2.0.0  
**Last Updated**: 2024  
**Maintained By**: Your Server Team
