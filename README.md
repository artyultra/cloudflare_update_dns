# Cloudflare Dynamic DNS Updater

A lightweight bash script that automatically updates Cloudflare DNS records when your public IP address changes. Perfect for home servers, self-hosted services, or any situation where you need dynamic DNS.

## Features

- **Smart caching** - Only updates DNS when your IP actually changes
- **Batch updates** - Updates multiple DNS records in one run
- **Portable** - Works from anywhere via symlinks (handles symlink resolution properly)
- **Robust** - Built-in retry logic, timeouts, and error handling
- **Logged** - Timestamped logs for debugging and monitoring
- **Modular** - Clean separation of concerns for easy maintenance

## Prerequisites

- Bash 4.0+ (tested with Homebrew bash on macOS)
- `curl` - for API requests
- `jq` - for JSON parsing
- Cloudflare account with API token

## Installation

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd cloudflare
   ```

2. **Configure environment variables:**
   ```bash
   cp scripts/.env.example scripts/.env
   # Edit scripts/.env with your Cloudflare credentials
   ```

3. **Make scripts executable:**
   ```bash
   chmod +x scripts/*.sh
   ```

4. **Create a symlink (optional but recommended):**
   ```bash
   ln -s ~/cloudflare/scripts/check_and_update.sh /usr/local/bin/cloudflare-update
   ```

## Configuration

Edit `scripts/.env` with your Cloudflare details:

```bash
ZONE_ID="your_zone_id_here"
API_TOKEN="your_api_token_here"
BASE_URL="https://api.cloudflare.com/client/v4"
TRACKED_RECORDS="subdomain1.example.com,subdomain2.example.com"
```

### Getting your Cloudflare credentials:

- **Zone ID**: Found in your domain's overview page on the Cloudflare dashboard
- **API Token**: Create one at `My Profile > API Tokens` with `Zone.DNS` edit AND read permissions
- **Tracked Records**: Comma-separated list of DNS record names you want to update

## Usage

### Manual run:
```bash
cloudflare-update
# or
~/cloudflare/scripts/check_and_update.sh
```

### Automated with cron:
```bash
crontab -e
```

Add one of these schedules:
```cron
# Every 15 minutes
*/15 * * * * /usr/local/bin/cloudflare-update

# Every hour
0 * * * * /usr/local/bin/cloudflare-update
```

### View logs:
```bash
tail -f ~/cloudflare/dns.log
```

## How It Works

1. Fetches your current public IP from `api.ipify.org`
2. Compares it against the cached IP in `cache/last_updated_ip.txt`
3. If unchanged, exits early (no unnecessary API calls)
4. If changed:
   - Fetches your tracked DNS records from Cloudflare
   - Updates each record with the new IP *If you need different ips for different dns records youll need to make that change*
   - Updates the cache
   - Logs everything with timestamps

## Project Structure

```
cloudflare/
├── scripts/
│   ├── check_and_update.sh  # Main entry point
│   ├── helpers.sh            # API calls and utility functions
│   ├── get_records.sh        # DNS record fetching/filtering
│   └── .env                  # Configuration (not committed)
├── cache/
│   └── last_updated_ip.txt   # IP cache
├── dns.log                   # Log file
└── README.md
```

## Error Handling

The script includes:
- Exit on error with `set -euo pipefail`
- Curl timeouts and retries
- API response validation
- Environment variable validation
- Detailed error logging

## License

MIT

## Contributing

Pull requests welcome! Please ensure scripts remain POSIX-compatible where possible.
