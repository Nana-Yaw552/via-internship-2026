#!/usr/bin/env bash
# ------------------------------------------------------------------
# @title       Task1_file_handling.sh
# @author      Owusu Nana Yaw
# @index       4195424
# @school      Kwame Nkrumah University of Science and Technology (KNUST)
# @description Creates a directory, manages file operations (write, read, copy, delete), and validates step execution.
# @date        2026-09-13
# ------------------------------------------------------------------

# Define a function to display usage guidelines when input arguments are missing or invalid
usage() {
    echo "Usage: $0 <target_directory>"
    echo "  <target_directory> : Directory where operations will take place"
    # Exit with code 1 to indicate missing required parameter
    exit 1
}

# Check if the user passed -h/--help or failed to pass any argument ($# -eq 0 or -z "$1")
if [[ "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
    usage
fi

# Store the first command line argument as the target directory path
TARGET_DIR="$1"
# Construct target file paths for operations
FILE_PATH="${TARGET_DIR}/sample.txt"
BAK_PATH="${TARGET_DIR}/sample.txt.bak"

# 1. Directory creation check: Verify if directory already exists using -d flag
if [[ -d "$TARGET_DIR" ]]; then
    echo "[INFO] Directory '$TARGET_DIR' already exists."
else
    # Create directory tree using -p (parents) and suppress raw error messages (2>/dev/null)
    mkdir -p "$TARGET_DIR" 2>/dev/null
    # Inspect $? (exit status of mkdir); 0 means success
    if [[ $? -eq 0 ]]; then
        echo "[SUCCESS] Created directory '$TARGET_DIR'."
    else
        # Print custom error message to standard error stream (>&2) and terminate
        echo "[ERROR] Failed to create directory '$TARGET_DIR'." >&2
        exit 1
    fi
fi

# 2. File creation: Use single redirection (>) to create or overwrite file with text
echo "Initial content for task 1." > "$FILE_PATH" 2>/dev/null
if [[ $? -eq 0 ]]; then
    echo "[SUCCESS] Created file '$FILE_PATH' with initial content."
else
    echo "[ERROR] Failed to write to '$FILE_PATH'." >&2
    exit 1
fi

# 3. File appending: Use double redirection (>>) to append a new line to existing file
echo "Appended second line of content." >> "$FILE_PATH" 2>/dev/null
if [[ $? -eq 0 ]]; then
    echo "[SUCCESS] Appended content to '$FILE_PATH'."
else
    echo "[ERROR] Failed to append to '$FILE_PATH'." >&2
    exit 1
fi

# 4. Read operations: Display file content via cat command
echo "--- File Content Start ---"
cat "$FILE_PATH" 2>/dev/null
# Verify cat executed cleanly (exit code 0)
if [[ $? -ne 0 ]]; then
    echo "[ERROR] Failed to read '$FILE_PATH'." >&2
    exit 1
fi
echo "--- File Content End ---"

# 5. File backup: Copy original file to a duplicate with .bak extension
cp "$FILE_PATH" "$BAK_PATH" 2>/dev/null
if [[ $? -eq 0 ]]; then
    echo "[SUCCESS] Copied file to '$BAK_PATH'."
else
    echo "[ERROR] Failed to copy file to '$BAK_PATH'." >&2
    exit 1
fi

# 6. Deletion workflow: Verify original file exists (-f flag) before asking for user confirmation
if [[ -f "$FILE_PATH" ]]; then
    # Prompt user for explicit deletion confirmation (-n keeps cursor on same line)
    echo -n "[CONFIRM] Are you sure you want to delete '$FILE_PATH'? (y/n): "
    read -r response
    # Use regular expression matching to handle uppercase/lowercase 'Y' or 'y'
    if [[ "$response" =~ ^[Yy]$ ]]; then
        rm "$FILE_PATH" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            echo "[SUCCESS] Deleted original file '$FILE_PATH'."
        else
            echo "[ERROR] Failed to delete '$FILE_PATH'." >&2
            exit 1
        fi
    else
        echo "[INFO] Deletion cancelled by user."
    fi
else
    echo "[ERROR] Original file '$FILE_PATH' does not exist." >&2
    exit 1
fi

# Exit cleanly with zero status code on total script execution success
exit 0
