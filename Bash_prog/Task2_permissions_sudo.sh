#!/usr/bin/env bash
# ------------------------------------------------------------------
# @title       Task2_permissions_sudo.sh
# @author      Owusu Nana Yaw
# @index       4195424
# @school      Kwame Nkrumah University of Science and Technology (KNUST)
# @description Inspects file permissions, modifies them using symbolic/numeric modes, and checks for root privileges.
# @date        2026-09-13
# ------------------------------------------------------------------

# Print usage details if arguments are missing or user passes help flags
usage() {
    echo "Usage: $0 <file_path>"
    echo "  <file_path> : Path to the file to inspect and modify permissions"
    exit 1
}

# Parse command line flags (-h or --help) or empty inputs (-z)
if [[ "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
    usage
fi

TARGET_FILE="$1"

# Input validation: Confirm target file exists before attempting permissions analysis
if [[ ! -e "$TARGET_FILE" ]]; then
    echo "[ERROR] Target path '$TARGET_FILE' does not exist." >&2
    exit 1
fi

# Helper function to extract and format file permissions in symbolic and octal numeric modes
show_permissions() {
    local file="$1"
    # Extract symbolic string (e.g., -rw-r--r--) using ls -l and parsing the first column with awk
    local symbolic
    symbolic=$(ls -l "$file" | awk '{print $1}')
    
    # Extract numeric octal mode (e.g., 644) using stat (handles Linux %a vs macOS %Lp compatibility)
    local numeric
    numeric=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%Lp" "$file" 2>/dev/null)
    
    echo "   Symbolic: $symbolic | Numeric: $numeric"
}

# Display initial permission state
echo "1. Current file permissions:"
show_permissions "$TARGET_FILE"

# Modify permissions using octal (644) and symbolic (u+x) syntax
echo "2. Applying permission changes..."
chmod 644 "$TARGET_FILE" 2>/dev/null     # Set read/write for owner, read-only for group/others
chmod u+x "$TARGET_FILE" 2>/dev/null     # Add execution permission for user/owner only

# Check exit code to confirm chmod commands executed without permission errors
if [[ $? -eq 0 ]]; then
    echo "[SUCCESS] Permissions modified successfully."
else
    echo "[ERROR] Failed to modify permissions." >&2
    exit 1
fi

# Check root privileges: id -u returns current User ID (UID 0 corresponds to root)
echo "3. Checking execution privileges..."
if [[ $(id -u) -eq 0 ]]; then
    echo "[INFO] Executing as root. Attempting ownership change..."
    # If running with root/sudo, change ownership of the file to root user
    chown root "$TARGET_FILE" 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "[SUCCESS] Changed file owner to root."
    else
        echo "[ERROR] Ownership change failed." >&2
    fi
else
    # Graceful degradation: skip root actions without crashing script if non-root user runs it
    echo "[SKIP] Script is not running as root/sudo (UID != 0). Skipping chown step gracefully."
fi

# Print final state of permissions after all modifications
echo "4. Updated file permissions:"
show_permissions "$TARGET_FILE"

exit 0
