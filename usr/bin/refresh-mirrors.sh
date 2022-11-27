#!/usr/bin/env sh

wait_and_exit() {
    WAIT_TIME="$1"
    EXIT_CODE="$2"    

    read -n 1 -s -r -t "$WAIT_TIME" -p "Press any key to exit..."
    exit "$EXIT_CODE"
}

if [ $(id -u) -ne 0 ]; then
    >&2 echo "ERROR: Unauthorized. Please run with superuser privileges..."
    wait_and_exit 10 1
fi

# ========================
# Refresh RebornOS Mirrors
# ========================

rank_rebornos_mirrors() {
    TEMP_FILE="$1"
    TIMEOUT="$2"

    /usr/bin/rate-mirrors --concurrency=8 --per-mirror-timeout="$TIMEOUT" --allow-root --save="$TEMP_FILE" rebornos
    return "$?"
}

TEMP_DIR="/tmp/pacman.d"
DESTINATION_DIR="/etc/pacman.d"
MIRRORLIST_FILENAME="reborn-mirrorlist"
PER_MIRROR_TIMEOUT=3000
FALLBACK_PER_MIRROR_TIMEOUT=10000
MIN_MIRRORS=5

TEMP_FILE="$TEMP_DIR/$MIRRORLIST_FILENAME"
MIRRORLIST_FILE="$DESTINATION_DIR/$MIRRORLIST_FILENAME"

echo ""
set -o xtrace
mkdir -p "$TEMP_DIR"
rm -f "$TEMP_FILE"
set +o xtrace
echo ""

echo "Ranking RebornOS Mirrors..."
echo ""
rank_rebornos_mirrors "$TEMP_FILE" "$PER_MIRROR_TIMEOUT"
REBORN_MIRROR_REFRESH_FAILED="$?"
MIRROR_COUNT=$(grep -oe '^Server\s*=\s*http' "$TEMP_FILE" | wc -l)
echo ""
echo ""

if [ "$MIRROR_COUNT" -lt "$MIN_MIRRORS" ]; then  
    echo "Only $MIRROR_COUNT mirrors found..."
    echo "Retrying with a longer timeout duration. This will be much slower. Please be patient..."
    echo ""
    rm -f "$TEMP_FILE"
    rank_rebornos_mirrors "$TEMP_FILE" "$FALLBACK_PER_MIRROR_TIMEOUT"
    REBORN_MIRROR_REFRESH_FAILED="$?"
    MIRROR_COUNT=$(grep -oe '^Server\s*=\s*http' "$TEMP_FILE" | wc -l)
    echo ""
    echo ""
fi

REBORN_MIRROR_REFRESH_LOG_FILE="$TEMP_FILE"
if [ "$REBORN_MIRROR_REFRESH_FAILED" -ne 0 ]; then
    echo ""  
    echo "ERROR: rate-mirrors exited with the error code $REBORN_MIRROR_REFRESH_FAILED..."
    echo ""  
elif [ "$MIRROR_COUNT" -lt "$MIN_MIRRORS" ]; then
    REBORN_MIRROR_REFRESH_FAILED=-1
    echo "ERROR: Only $MIRROR_COUNT mirrors found even with a longer timeout duration..."
    echo "" 
else    
    echo ""  
    set -o xtrace      
    sudo cp -f "$TEMP_FILE" "$MIRRORLIST_FILE"
    set +o xtrace
    echo ""
fi

# ==========================
# Refresh Arch Linux Mirrors
# ==========================

rank_arch_mirrors() {
    TEMP_FILE="$1"
    TIMEOUT="$2"

    /usr/bin/rate-mirrors --protocol=https --per-mirror-timeout="$TIMEOUT" --allow-root --save="$TEMP_FILE" arch
    return "$?"
}

TEMP_DIR="/tmp/pacman.d"
DESTINATION_DIR="/etc/pacman.d"
MIRRORLIST_FILENAME="mirrorlist"
PER_MIRROR_TIMEOUT=1500
FALLBACK_PER_MIRROR_TIMEOUT=5000
MIN_MIRRORS=5

TEMP_FILE="$TEMP_DIR/$MIRRORLIST_FILENAME"
MIRRORLIST_FILE="$DESTINATION_DIR/$MIRRORLIST_FILENAME"

echo ""
set -o xtrace
mkdir -p "$TEMP_DIR"
rm -f "$TEMP_FILE"
set +o xtrace
echo ""

echo "Ranking Arch Linux Mirrors..."
echo ""
rank_arch_mirrors "$TEMP_FILE" "$PER_MIRROR_TIMEOUT"
ARCH_MIRROR_REFRESH_FAILED="$?"
MIRROR_COUNT=$(grep -oe '^Server\s*=\s*http' "$TEMP_FILE" | wc -l)
echo ""
echo ""

if [ "$MIRROR_COUNT" -lt "$MIN_MIRRORS" ]; then  
    echo "Only $MIRROR_COUNT mirrors found..."
    echo "Retrying with a longer timeout duration. This will be much slower. Please be patient..."
    echo ""
    rm -f "$TEMP_FILE"
    rank_arch_mirrors "$TEMP_FILE" "$FALLBACK_PER_MIRROR_TIMEOUT"
    ARCH_MIRROR_REFRESH_FAILED="$?"
    MIRROR_COUNT=$(grep -oe '^Server\s*=\s*http' "$TEMP_FILE" | wc -l)
    echo ""
    echo ""
fi

ARCH_MIRROR_REFRESH_LOG_FILE="$TEMP_FILE"
if [ "$ARCH_MIRROR_REFRESH_FAILED" -ne 0 ]; then
    echo ""  
    echo "ERROR: rate-mirrors exited with the error code $ARCH_MIRROR_REFRESH_FAILED..."
    echo ""  
elif [ "$MIRROR_COUNT" -lt "$MIN_MIRRORS" ]; then
    ARCH_MIRROR_REFRESH_FAILED=-1
    echo "ERROR: Only $MIRROR_COUNT mirrors found even with a longer timeout duration..."
    echo "" 
else    
    echo ""  
    set -o xtrace      
    sudo cp -f "$TEMP_FILE" "$MIRRORLIST_FILE"
    set +o xtrace
    echo ""
fi

# =========================
# Check exit codes and exit
# =========================

if [ "$REBORN_MIRROR_REFRESH_FAILED" -ne 0 ]; then
    >&2 echo "ERROR: Refresh of RebornOS mirrors failed with exit code: $REBORN_MIRROR_REFRESH_FAILED"
    >&2 echo "Please check the log at: file://$REBORN_MIRROR_REFRESH_LOG_FILE"
    >&2 echo ""    
    wait_and_exit 20 "$REBORN_MIRROR_REFRESH_FAILED"
elif [ "$ARCH_MIRROR_REFRESH_FAILED" -ne 0 ]; then
    >&2 echo "ERROR: Refresh of Arch Linux mirrors failed with exit code: $ARCH_MIRROR_REFRESH_FAILED"
    >&2 echo "Please check the log at: file://$ARCH_MIRROR_REFRESH_LOG_FILE"
    >&2 echo ""    
    wait_and_exit 20 "$ARCH_MIRROR_REFRESH_FAILED"
else
    echo "Refresh of both RebornOS and Arch Linux mirrors completed successfully!"
    echo ""  
    wait_and_exit 10 0
fi