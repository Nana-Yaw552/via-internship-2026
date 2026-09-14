#!/usr/bin/env bash
# ------------------------------------------------------------------
# @title       Task4_return_codes_error_handling.sh
# @author      Owusu Nana Yaw
# @index       4195424
# @school      Kwame Nkrumah University of Science and Technology (KNUST)
# @description Runs standard system health checks and handles distinct exit status codes cleanly.
# @date        2026-09-13
# ------------------------------------------------------------------

# Exit status schema:
# 0 = All checks passed
# 1 = Missing required argument
# 2 = Host unreachable
# 3 = Insufficient disk space
# 4 = Required file not found
# 5 = Required command not found

# Display usage rules
usage() {
    echo "Usage: $0 <hostname_or_ip>"
    echo "  <hostname_or_ip> : Target host to test network connectivity"
    exit 1
}

# Create a temporary file securely with mktemp
TEMP_FILE=$(mktemp /tmp/health_check_XXXXXX)

# Cleanup trap function: Guarantees temporary file removal upon script termination or interruption (Ctrl+C)
cleanup() {
    echo "[CLEANUP] Removing temporary working file '$TEMP_FILE'..."
    rm -f "$TEMP_FILE"
}
# Attach cleanup function to the shell EXIT signal
trap cleanup EXIT

# Parse help flag request
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

# Input validation: Ensure target host argument was provided
if [[ -z "$1" ]]; then
    echo "[ERROR] Missing target hostname/IP parameter." >&2
    usage
fi

TARGET_HOST="$1"

# Helper function to evaluate step execution return code ($?) against custom exit codes
check_status() {
    local status=$1       # Captured exit status ($?) of target command
    local check_name=$2   # Name of diagnostic check performed
    local err_code=$3     # Assigned exit code to return if check fails

    if [[ $status -eq 0 ]]; then
        echo "[PASS] Check '$check_name' passed."
    else
        echo "[FAIL] Check '$check_name' failed with status $status." >&2
        # Abort execution immediately with the predefined error code mapping
        exit "$err_code"
    fi
}

echo "Starting system diagnostic checks..."

# Check 1: Verify binary availability using command -v
command -v ping >/dev/null 2>&1
check_status $? "Command 'ping' available" 5

# Check 2: Network connectivity check using ping (1 packet, 2s timeout)
ping -c 1 -W 2 "$TARGET_HOST" >/dev/null 2>&1
check_status $? "Host reachability ($TARGET_HOST)" 2

# Check 3: Check available disk space on root volume (ensuring > 1GB free blocks)
df / | awk 'NR==2 {if ($4 > 1000000) exit 0; else exit 1}'
check_status $? "Sufficient free disk space" 3

# Check 4: Configuration file readability (-r test operator)
CONFIG_FILE="/etc/hosts"
[[ -r "$CONFIG_FILE" ]]
check_status $? "Read access to '$CONFIG_FILE'" 4

echo "All diagnostic checks passed successfully."
# Exit with code 0 indicating system passes all required checks
exit 0
