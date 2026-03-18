#!/bin/bash

# ============================================================
# Domain Watcher + Auto-Registration Script
# Target: uncommon.ai
# Registrar: Porkbun
# Notification: Email-to-SMS (AT&T)
# ============================================================

# Load environment variables
source "$(dirname "$0")/.env"

DOMAIN=$DOMAIN
LOG_FILE="$(dirname "$0")/domain_watcher.log"
SMS_GATEWAY="${NOTIFY_EMAIL}"  # AT&T: number@txt.att.net
FROM_EMAIL="${FROM_EMAIL}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

send_sms() {
  local message="$1"
  # Use sendmail/msmtp to send email-to-SMS
  echo -e "Subject: Domain Alert\n\n$message" | sendmail "$SMS_GATEWAY"
  log "SMS alert sent: $message"
}

check_availability() {
  local response
  response=$(curl -s -X POST "https://api.porkbun.com/api/json/v3/domain/checkAndRegister/$DOMAIN" \
    -H "Content-Type: application/json" \
    -d '{
      "apikey": "'"$PORKBUN_API_KEY"'",
      "secretapikey": "'"$PORKBUN_SECRET_KEY"'"
    }')
  echo "$response"
}

check_whois() {
  # Use WHOIS as a lightweight pre-check before hitting Porkbun API
  local whois_result
  whois_result=$(whois "$DOMAIN" 2>/dev/null)
  
  # If no match found in WHOIS, domain is likely available
  if echo "$whois_result" | grep -qiE "no match|not found|no entries found|status: available"; then
    return 0  # Available
  else
    return 1  # Still registered
  fi
}

attempt_registration() {
  log "Domain appears available! Attempting registration via Porkbun API..."

  local response
  response=$(curl -s -X POST "https://api.porkbun.com/api/json/v3/domain/create/$DOMAIN" \
    -H "Content-Type: application/json" \
    -d '{
      "apikey": "'"$PORKBUN_API_KEY"'",
      "secretapikey": "'"$PORKBUN_SECRET_KEY"'",
      "years": "1"
    }')

  local status
  status=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','ERROR'))" 2>/dev/null)

  if [ "$status" = "SUCCESS" ]; then
    log "✅ SUCCESS! $DOMAIN registered successfully!"
    send_sms "SUCCESS! $DOMAIN has been registered to your Porkbun account!"
  else
    local error_msg
    error_msg=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message','Unknown error'))" 2>/dev/null)
    log "❌ Registration attempted but failed: $error_msg"
    log "Full response: $response"
    send_sms "ALERT: $DOMAIN is available but registration failed: $error_msg. Log in to Porkbun NOW!"
  fi
}

# ============================================================
# Main
# ============================================================
log "--- Checking availability of $DOMAIN ---"

if check_whois; then
  log "WHOIS shows $DOMAIN may be available. Hitting Porkbun API..."
  attempt_registration
else
  log "$DOMAIN is still registered. Will check again next run."
fi
