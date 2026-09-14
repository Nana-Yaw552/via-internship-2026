#!/usr/bin/env bash
# ------------------------------------------------------------------
# @title       Task5_crud_app.sh
# @author      Owusu Nana Yaw
# @index       4195424
# @school      Kwame Nkrumah University of Science and Technology (KNUST)
# @description Interactive console CRUD Todo List manager with backup mechanism.
# @date        2026-09-13
# ------------------------------------------------------------------

# Database configuration files (CSV storage)
DATA_FILE="tasks.csv"
BACKUP_FILE="tasks.csv.bak"

# Display usage instructions
usage() {
    echo "Usage: $0"
    echo "  Launches the interactive CLI Todo List application."
    exit 0
}

# Process help flags
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

# Ensure storage file exists on boot
if [[ ! -f "$DATA_FILE" ]]; then
    touch "$DATA_FILE"
fi

# Backup utility: Creates a safety copy of storage file prior to destructive edits
create_backup() {
    cp "$DATA_FILE" "$BACKUP_FILE" 2>/dev/null
}

# 1. CREATE Operation: Add new task entry
add_task() {
    echo "--- Add New Task ---"
    read -rp "Enter Task Description: " desc
    # Input validation: Reject empty task strings
    if [[ -z "$desc" ]]; then
        echo "[ERROR] Task description cannot be empty."
        return
    fi

    read -rp "Enter Due Date (YYYY-MM-DD) [Optional]: " due_date
    # Set default value if optional input is omitted
    due_date=${due_date:-"None"}

    # Auto-increment ID calculation logic: evaluate current max ID and increment
    if [[ ! -s "$DATA_FILE" ]]; then
        next_id=1
    else
        last_id=$(awk -F',' '{print $1}' "$DATA_FILE" | sort -n | tail -n1)
        next_id=$((last_id + 1))
    fi

    # Append new record line to CSV
    echo "${next_id},${desc},pending,${due_date}" >> "$DATA_FILE"
    echo "[SUCCESS] Task added with ID: $next_id"
}

# 2. READ Operation: Formatted tabular display of all tasks
view_tasks() {
    echo "--- All Tasks ---"
    if [[ ! -s "$DATA_FILE" ]]; then
        echo "No records found."
        return
    fi
    # Format console output into aligned column structure using printf
    printf "%-5s | %-30s | %-10s | %-12s\n" "ID" "Description" "Status" "Due Date"
    echo "------------------------------------------------------------------"
    # Read CSV file line by line using comma (,) delimiter split
    while IFS=',' read -r id desc status due; do
        printf "%-5s | %-30s | %-10s | %-12s\n" "$id" "$desc" "$status" "$due"
    done < "$DATA_FILE"
}

# 3. SEARCH Operation: Case-insensitive query search
search_task() {
    echo "--- Search Tasks ---"
    read -rp "Enter search query: " query
    if [[ -z "$query" ]]; then
        echo "[ERROR] Search query cannot be empty."
        return
    fi

    # Filter matching task lines with case-insensitive grep (-i)
    results=$(grep -i "$query" "$DATA_FILE")
    if [[ -n "$results" ]]; then
        printf "%-5s | %-30s | %-10s | %-12s\n" "ID" "Description" "Status" "Due Date"
        echo "------------------------------------------------------------------"
        echo "$results" | while IFS=',' read -r id desc status due; do
            printf "%-5s | %-30s | %-10s | %-12s\n" "$id" "$desc" "$status" "$due"
        done
    else
        echo "[INFO] No records found matching '$query'."
    fi
}

# 4. UPDATE Operation: Modify task status with backup protection
update_task() {
    echo "--- Update Task Status ---"
    read -rp "Enter Task ID to update status: " target_id
    # Validate target ID existence inside data file using grep pattern search
    if ! grep -q "^${target_id}," "$DATA_FILE"; then
        echo "[ERROR] Task ID '$target_id' not found."
        return
    fi

    read -rp "Enter new status (pending/done): " new_status
    if [[ "$new_status" != "pending" && "$new_status" != "done" ]]; then
        echo "[ERROR] Invalid status. Must be 'pending' or 'done'."
        return
    fi

    # Create safety backup before updating
    create_backup
    # Rebuild CSV record safely via awk substitution and atomic file replace
    awk -F',' -v id="$target_id" -v st="$new_status" 'BEGIN{OFS=","} {if ($1 == id) $3=st; print $0}' "$DATA_FILE" > "${DATA_FILE}.tmp" && mv "${DATA_FILE}.tmp" "$DATA_FILE"
    echo "[SUCCESS] Task $target_id updated."
}

# 5. DELETE Operation: Remove task entry with confirmation prompt
delete_task() {
    echo "--- Delete Task ---"
    read -rp "Enter Task ID to delete: " target_id
    if ! grep -q "^${target_id}," "$DATA_FILE"; then
        echo "[ERROR] Task ID '$target_id' not found."
        return
    fi

    # Request explicit confirmation before performing destructive delete
    read -rp "Are you sure you want to delete task $target_id? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        create_backup
        # Filter out target ID line and write back to storage file
        grep -v "^${target_id}," "$DATA_FILE" > "${DATA_FILE}.tmp" && mv "${DATA_FILE}.tmp" "$DATA_FILE"
        echo "[SUCCESS] Task $target_id deleted."
    else
        echo "[INFO] Deletion cancelled."
    fi
}

# Main Application Menu Loop (while loop + case block execution)
while true; do
    echo ""
    echo "=== TODO LIST MANAGER ==="
    echo "1. Add Task"
    echo "2. View All Tasks"
    echo "3. Search Task"
    echo "4. Update Task Status"
    echo "5. Delete Task"
    echo "6. Exit"
    read -rp "Choose an option [1-6]: " choice

    case "$choice" in
        1) add_task ;;
        2) view_tasks ;;
        3) search_task ;;
        4) update_task ;;
        5) delete_task ;;
        6) echo "Exiting application."; exit 0 ;;
        *) echo "[ERROR] Invalid choice. Please enter a number between 1 and 6." ;;
    esac
done
