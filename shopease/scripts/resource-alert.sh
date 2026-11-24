#!/bin/bash

# ShopEase Server Resource Monitoring
# Runs every 15 minutes through Cron

CONFIG="/opt/shopease/scripts/.telegram.env"

# Load Telegram credentials
if [[ ! -r "$CONFIG" ]]; then
    echo "Telegram configuration missing or unreadable"
    exit 1
fi

source "$CONFIG"

if [[ -z "$BOT_TOKEN" || -z "$CHAT_ID" ]]; then
    echo "Telegram credentials are missing"
    exit 1
fi

HOST=$(hostname)
TIME=$(date '+%Y-%m-%d %H:%M:%S')

# Calculate CPU usage
read -r _ u n s idle io irq softirq steal _ _ < /proc/stat
IDLE1=$((idle + io))
TOTAL1=$((u + n + s + idle + io + irq + softirq + steal))

sleep 1

read -r _ u n s idle io irq softirq steal _ _ < /proc/stat
IDLE2=$((idle + io))
TOTAL2=$((u + n + s + idle + io + irq + softirq + steal))

TOTAL_DIFF=$((TOTAL2 - TOTAL1))
IDLE_DIFF=$((IDLE2 - IDLE1))

if (( TOTAL_DIFF > 0 )); then
    CPU=$(awk -v t="$TOTAL_DIFF" -v i="$IDLE_DIFF" \
        'BEGIN {printf "%.2f", (t-i)*100/t}')
else
    CPU="0.00"
fi

# RAM information (MB)
read -r MEM_TOTAL MEM_AVAILABLE < <(
    awk '
    /^MemTotal:/ {total=$2}
    /^MemAvailable:/ {available=$2}
    END {print int(total/1024), int(available/1024)}
    ' /proc/meminfo
)

MEM_USED=$((MEM_TOTAL - MEM_AVAILABLE))
MEM_PERCENT=$(awk -v u="$MEM_USED" -v t="$MEM_TOTAL" \
    'BEGIN {printf "%.2f", u*100/t}')

# Top 5 CPU consuming processes
TOP_CPU=$(ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6)

# Top 5 RAM consuming processes
TOP_RAM=$(ps -eo pid,comm,%cpu,%mem --sort=-%mem | head -n 6)

# Prepare Telegram message
MESSAGE="ShopEase SERVER MONITOR

Server: $HOST
Time: $TIME

CPU USAGE: ${CPU}%

RAM TOTAL: ${MEM_TOTAL} MB
RAM USED: ${MEM_USED} MB
RAM AVAILABLE: ${MEM_AVAILABLE} MB
RAM USAGE: ${MEM_PERCENT}%

TOP 5 CPU PROCESSES
$TOP_CPU

TOP 5 RAM PROCESSES
$TOP_RAM

Monitoring Status: ACTIVE"

# Send Telegram notification
RESPONSE=$(curl -sS --max-time 15 \
    -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${CHAT_ID}" \
    --data-urlencode "text=${MESSAGE}")

if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo "Telegram notification sent successfully"
else
    echo "Telegram notification failed: $RESPONSE"
    exit 1
fi
