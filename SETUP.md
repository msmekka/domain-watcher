# Domain Watcher Setup Guide
## Target: uncommon.ai | Registrar: Porkbun | Alerts: AT&T SMS

---

## Step 1: Install dependencies
```bash
# macOS
brew install whois msmtp

# Linux
sudo apt install whois msmtp
```

---

## Step 2: Configure your .env file
```bash
cp .env.template .env
```
Edit `.env` and fill in:
- Your Porkbun API key and secret key
- Your AT&T number: 9195551234@txt.att.net

---

## Step 3: Configure Gmail for sending alerts

1. Go to myaccount.google.com → Security → 2-Step Verification → App Passwords
2. Generate an App Password for "Mail"
3. Copy msmtprc.template to ~/.msmtprc:
   ```bash
   cp msmtprc.template ~/.msmtprc
   chmod 600 ~/.msmtprc
   ```
4. Replace YOUR_GMAIL_APP_PASSWORD_HERE with your app password

Test it:
```bash
echo "Test alert" | msmtp your10digitnumber@txt.att.net
```

---

## Step 4: Set up cron job (checks every 15 minutes)
```bash
crontab -e
```
Add this line:
```
*/15 * * * * /path/to/domain-watcher/check_domain.sh
```
Replace `/path/to/domain-watcher/` with the actual path, e.g.:
```
*/15 * * * * /Users/mekka/domain-watcher/check_domain.sh
```

---

## Step 5: Test the script manually
```bash
./check_domain.sh
tail -f domain_watcher.log
```

---

## File Structure
```
domain-watcher/
├── check_domain.sh      # Main watcher script
├── .env                 # Your credentials (never commit this)
├── .env.template        # Safe template to share/commit
├── .gitignore           # Keeps .env out of git
├── msmtprc.template     # Gmail SMTP config template
├── domain_watcher.log   # Auto-created on first run
└── SETUP.md             # This file
```

---

## How it works
1. Every 15 min, cron runs check_domain.sh
2. Script does a lightweight WHOIS check first
3. If WHOIS shows available → hits Porkbun API to register immediately
4. If registration succeeds → SMS alert sent to your AT&T number
5. If registration fails → SMS alert sent so you can log in manually
6. Everything logged to domain_watcher.log
