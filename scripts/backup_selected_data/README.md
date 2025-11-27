# Restic Backup for Unraid

A robust backup script for Unraid that uses [restic](https://restic.net/) to backup selected directories to Backblaze B2 cloud storage.

## Features

- **Automated backups** to Backblaze B2 cloud storage
- **Incremental backups** - only changed data is uploaded
- **Encryption** - all data is encrypted before upload
- **Automatic retention** - configurable policy for keeping daily/weekly/monthly/yearly snapshots
- **Smart notifications** - only notifies on errors or warnings (no spam)
- **Detailed logging** - comprehensive logs for troubleshooting
- **Repository health checks** - automatic integrity verification
- **Sensible defaults** - backs up critical Unraid directories out of the box
- **Secure configuration** - credentials stored separately from code

## Prerequisites

1. **Unraid server** (6.x or later)
2. **Restic** installed on your Unraid server
3. **Backblaze B2 account** with a bucket created
4. **User Scripts plugin** for Unraid (recommended for scheduling)

## Installation

### Step 1: Install Restic

**Option A: Using Nerd Tools (Recommended)**
1. Install the "Nerd Tools" plugin from Community Applications
2. In Nerd Tools settings, check "restic" and click "Apply"

**Option B: Manual Installation**
```bash
# Download and install restic
wget https://github.com/restic/restic/releases/latest/download/restic_linux_amd64.bz2
bunzip2 restic_linux_amd64.bz2
chmod +x restic_linux_amd64
mv restic_linux_amd64 /usr/local/bin/restic
```

Verify installation:
```bash
restic version
```

### Step 2: Set Up Backblaze B2

1. Create a [Backblaze B2 account](https://www.backblaze.com/b2/)
2. Create a new B2 bucket:
   - Log in to B2 console
   - Click "Create a Bucket"
   - Choose a unique name (e.g., `unraid-backups-yourname`)
   - Set to **Private** (recommended)
3. Create an Application Key:
   - Go to "App Keys" in B2 console
   - Click "Add a New Application Key"
   - Name it (e.g., "Unraid Restic Backup")
   - Limit access to your backup bucket only (recommended)
   - **Save the Application Key ID and Application Key** (you can't view the key again!)

### Step 3: Configure the Backup Script

1. Create the configuration directory:
   ```bash
   mkdir -p /boot/config/restic
   ```

2. Copy the example configuration:
   ```bash
   cp scripts/backup_selected_data/config.example /boot/config/restic/backup.conf
   ```

3. Edit the configuration file:
   ```bash
   nano /boot/config/restic/backup.conf
   ```

4. Fill in your credentials:
   ```bash
   B2_ACCOUNT_ID="your_b2_account_id_here"
   B2_ACCOUNT_KEY="your_b2_application_key_here"
   RESTIC_REPOSITORY="b2:your-bucket-name:unraid-backups"
   RESTIC_PASSWORD="your_strong_password_here"
   ```

   **Important**: Choose a strong `RESTIC_PASSWORD`. If you lose it, you cannot restore your backups!

5. Set secure permissions:
   ```bash
   chmod 600 /boot/config/restic/backup.conf
   ```

### Step 4: Install the Script

1. Install the "User Scripts" plugin from Community Applications
2. Go to Settings → User Scripts
3. Click "Add New Script"
4. Name it `backup_selected_data`
5. Copy the script contents or clone this repository

### Step 5: Test the Backup

Run the script manually first to ensure everything works:

1. Go to Settings → User Scripts
2. Find `backup_selected_data`
3. Click "Run Script"
4. Monitor the output for any errors

Check the log file:
```bash
tail -f /var/log/restic_backup.log
```

## Configuration Reference

### Required Settings

| Variable | Description | Example |
|----------|-------------|---------|
| `B2_ACCOUNT_ID` | Backblaze B2 Account/Application Key ID | `0123456789abcdef` |
| `B2_ACCOUNT_KEY` | Backblaze B2 Application Key | `K001abc...` |
| `RESTIC_REPOSITORY` | Repository location | `b2:my-bucket:unraid` |
| `RESTIC_PASSWORD` | Repository encryption password | `SuperSecurePassword123!` |

### Optional Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `BACKUP_PATHS` | See below | Directories to backup (newline-separated) |
| `EXCLUDE_PATTERNS` | See below | Patterns to exclude (newline-separated) |
| `KEEP_DAILY` | `7` | Number of daily backups to keep |
| `KEEP_WEEKLY` | `4` | Number of weekly backups to keep |
| `KEEP_MONTHLY` | `12` | Number of monthly backups to keep |
| `KEEP_YEARLY` | `3` | Number of yearly backups to keep |
| `ENABLE_HEALTH_CHECK` | `true` | Run repository health check after backup |

### Default Backup Paths

If `BACKUP_PATHS` is not set, these directories are backed up by default:
- `/boot/config` - Unraid configuration
- `/mnt/user/appdata` - Docker application data
- `/mnt/user/domains` - VM configurations

### Default Exclusions

If `EXCLUDE_PATTERNS` is not set, these patterns are excluded:
- `*.tmp`, `*.temp` - Temporary files
- `*.cache` - Cache files
- `*.log` - Log files
- `.DS_Store`, `Thumbs.db` - OS metadata files
- `lost+found` - Filesystem recovery files

## Usage

### Manual Backup

Run the script manually from User Scripts interface:
1. Settings → User Scripts
2. Find `backup_selected_data`
3. Click "Run Script"

### Scheduled Backups

Configure automatic backups:
1. Settings → User Scripts
2. Find `backup_selected_data`
3. Click "Schedule" dropdown
4. Select schedule:
   - **Daily**: Runs once per day at 4:40 AM
   - **Weekly**: Runs once per week
   - **Monthly**: Runs once per month
   - **Custom**: Use cron syntax (e.g., `0 2 * * *` for 2 AM daily)

**Recommended**: Schedule during off-peak hours (e.g., 2-4 AM)

### Viewing Logs

Real-time log monitoring:
```bash
tail -f /var/log/restic_backup.log
```

View entire log:
```bash
cat /var/log/restic_backup.log
```

View old log (after rotation):
```bash
cat /var/log/restic_backup.log.old
```

### Listing Backups

View all snapshots:
```bash
source /boot/config/restic/backup.conf
export B2_ACCOUNT_ID B2_ACCOUNT_KEY RESTIC_REPOSITORY RESTIC_PASSWORD
restic snapshots
```

View latest snapshot:
```bash
restic snapshots --last
```

### Restoring Files

**Important**: Test restores periodically to ensure your backups are working!

1. List snapshots to find the one you want:
   ```bash
   source /boot/config/restic/backup.conf
   export B2_ACCOUNT_ID B2_ACCOUNT_KEY RESTIC_REPOSITORY RESTIC_PASSWORD
   restic snapshots
   ```

2. Browse a snapshot:
   ```bash
   restic ls latest
   ```

3. Restore specific files:
   ```bash
   restic restore latest --target /mnt/user/restored --include /path/to/file
   ```

4. Restore entire snapshot:
   ```bash
   restic restore latest --target /mnt/user/restored
   ```

See [restic documentation](https://restic.readthedocs.io/en/latest/050_restore.html) for more restore options.

## Troubleshooting

### Script fails with "restic not found"

**Solution**: Install restic (see Installation step 1)

### Script fails with "Configuration file not found"

**Solution**: Create the config file at `/boot/config/restic/backup.conf`
```bash
mkdir -p /boot/config/restic
cp scripts/backup_selected_data/config.example /boot/config/restic/backup.conf
nano /boot/config/restic/backup.conf
```

### Authentication errors (B2 401/403)

**Solution**: Verify your B2 credentials
- Check `B2_ACCOUNT_ID` and `B2_ACCOUNT_KEY` in config
- Ensure the Application Key has access to your bucket
- Verify the bucket name in `RESTIC_REPOSITORY` is correct

### "Repository does not exist" error

**Solution**: The script will automatically initialize the repository on first run. If you see this error:
1. Verify your `RESTIC_REPOSITORY` path is correct
2. Ensure the B2 bucket exists
3. Check B2 credentials have write access

### Out of space on B2

**Solution**:
1. Check your B2 account storage usage
2. Adjust retention policy to keep fewer snapshots
3. Run manual prune: `restic forget --prune --keep-daily 3 --keep-weekly 2`

### Backup is very slow

**Possible causes**:
1. **First backup**: Initial backup uploads all data (this is normal)
2. **Large files changed**: Changed files must be re-uploaded
3. **Network speed**: Check your upload bandwidth
4. **Health check**: Disable by setting `ENABLE_HEALTH_CHECK="false"` in config

### No notifications received

**Check**:
1. Unraid notification settings (Settings → Notification Settings)
2. Notifications are only sent for errors/warnings (not success)
3. Check the log file for actual errors: `tail /var/log/restic_backup.log`

### Permission denied errors

**Solution**:
```bash
chmod 600 /boot/config/restic/backup.conf
```

Ensure the script runs as root (default for User Scripts).

## Best Practices

1. **Test restores regularly** - Backups are useless if you can't restore!
   ```bash
   restic restore latest --target /tmp/test-restore --include /boot/config
   ```

2. **Monitor logs** - Check logs periodically for warnings
   ```bash
   grep -i "warn\|error" /var/log/restic_backup.log
   ```

3. **Keep config secure** - Never commit `/boot/config/restic/backup.conf` to git
   ```bash
   chmod 600 /boot/config/restic/backup.conf
   ```

4. **Document your password** - Store `RESTIC_PASSWORD` in a password manager

5. **Test disaster recovery** - Practice full restore procedure

6. **Monitor costs** - Check B2 storage and egress usage regularly

7. **Verify backups** - The script runs automatic health checks, but manually verify:
   ```bash
   restic check --read-data
   ```

## Storage Costs

Backblaze B2 pricing (as of 2025):
- **Storage**: $0.006/GB/month (first 10 GB free)
- **Download**: $0.01/GB (first 1 GB/day free)
- **API calls**: Very low cost, usually negligible

**Example**: Backing up 100 GB costs ~$0.60/month storage.

## Advanced Usage

### Customize backup paths

Edit `/boot/config/restic/backup.conf`:
```bash
BACKUP_PATHS="
/boot/config
/mnt/user/appdata
/mnt/user/important-documents
/mnt/user/photos
"
```

### Exclude specific directories

```bash
EXCLUDE_PATTERNS="
*.tmp
*.cache
node_modules
__pycache__
/mnt/user/appdata/plex/Library/Application Support/Plex Media Server/Cache
"
```

### Adjust retention policy

For longer retention:
```bash
KEEP_DAILY="14"      # 2 weeks of daily backups
KEEP_WEEKLY="8"      # 2 months of weekly backups
KEEP_MONTHLY="24"    # 2 years of monthly backups
KEEP_YEARLY="5"      # 5 years of yearly backups
```

### Pre/Post backup hooks

Add custom commands before/after backup by editing the script:
```bash
# In the main() function, add before perform_backup():
log_info "Stopping containers for backup..."
docker stop plex

# After perform_backup():
log_info "Starting containers..."
docker start plex
```

## Security Considerations

1. **Config file security**: Contains sensitive credentials
   - Keep at `/boot/config/restic/backup.conf`
   - Set permissions: `chmod 600`
   - Never commit to git

2. **Encryption**: All data is encrypted with `RESTIC_PASSWORD`
   - Choose a strong password (20+ characters)
   - Store in password manager
   - If lost, backups are unrecoverable

3. **B2 Application Key**: Limit permissions
   - Create dedicated key for backups
   - Restrict to single bucket
   - No master application key

4. **Network**: Data is encrypted in transit (HTTPS)

## Support

- **Restic documentation**: https://restic.readthedocs.io/
- **Backblaze B2 docs**: https://www.backblaze.com/b2/docs/
- **Unraid forums**: https://forums.unraid.net/

## License

This script is provided as-is for use with Unraid systems. Modify as needed for your environment.
