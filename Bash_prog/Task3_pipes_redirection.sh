#!/usr/bin/env bash
# ------------------------------------------------------------------
# @title       Task3_pipes_redirection.sh
# @author      Owusu Nana Yaw
# @index       4195424
# @school      Kwame Nkrumah University of Science and Technology (KNUST)
# @description Generates log data and processes it using text processing tools with stream redirections.
# @date        2026-09-13
# ------------------------------------------------------------------

# Display execution guide for user help request
usage() {
    echo "Usage: $0"
    echo "  Generates sample logs and produces summary report results.txt"
    exit 1
}

# Help flag check
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

# Define output targets for data processing
LOG_FILE="sample_logs.log"
RESULTS_FILE="results.txt"
ERROR_FILE="errors.log"

# Clear contents of error log at start of run using empty output redirection
> "$ERROR_FILE"

# Generate mock system log data self-containedly using a Heredoc block (cat << 'EOF')
# Any system warnings/errors during generation are redirected to standard error log (2>> "$ERROR_FILE")
cat << 'EOF' > "$LOG_FILE" 2>> "$ERROR_FILE"
2026-09-11 10:03:21 INFO 192.168.1.10 User login successful
2026-09-11 10:03:45 ERROR 192.168.1.23 Connection timeout
2026-09-11 10:04:02 WARN 192.168.1.10 Disk usage above 80%
2026-09-11 10:05:12 INFO 192.168.1.15 File downloaded
2026-09-11 10:06:01 ERROR 192.168.1.10 Database connection failed
2026-09-11 10:07:33 WARN 192.168.1.23 High CPU utilization
2026-09-11 10:08:19 INFO 192.168.1.44 User logout
2026-09-11 10:09:00 ERROR 192.168.1.10 Unauthorized access attempt
2026-09-11 10:10:15 INFO 192.168.1.23 Service restarted
2026-09-11 10:11:50 ERROR 192.168.1.50 Out of memory error
EOF

# Group text analysis operations inside block {...} and redirect stdout to results.txt and stderr to errors.log
{
    echo "=========================================="
    echo "            LOG ANALYSIS REPORT           "
    echo "=========================================="
    echo ""

    # 1. Calculate total lines using wc -l (stream redirected < to display clean number)
    total_lines=$(wc -l < "$LOG_FILE")
    echo "1. Total Log Lines: $total_lines"
    echo ""

    # 2. Count lines per severity level using grep -c (count matched lines)
    echo "2. Log Count per Level:"
    echo "   INFO : $(grep -c "INFO" "$LOG_FILE")"
    echo "   WARN : $(grep -c "WARN" "$LOG_FILE")"
    echo "   ERROR: $(grep -c "ERROR" "$LOG_FILE")"
    echo ""

    # 3. Pipeline analysis:
    # - awk '{print $4}' extracts 4th column (IP addresses)
    # - sort puts identical IPs adjacent to each other
    # - uniq -c counts duplicate occurrences
    # - sort -nr orders frequency numerically descending
    # - head -n 3 extracts top 3 highest counts
    echo "3. Top 3 IP Addresses:"
    awk '{print $4}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n 3 | awk '{print "   " $2 " - " $1 " occurrences"}'
    echo ""

    # 4. Filter and display all ERROR lines using grep, indented via sed
    echo "4. All Error Logs:"
    grep "ERROR" "$LOG_FILE" | sed 's/^/   /'

} > "$RESULTS_FILE" 2>> "$ERROR_FILE"

# Validate that data pipeline ran without throwing command errors
if [[ $? -eq 0 ]]; then
    echo "[SUCCESS] Log processing completed. Summary written to '$RESULTS_FILE'."
else
    echo "[ERROR] Log processing encountered errors. Check '$ERROR_FILE'." >&2
    exit 1
fi

exit 0
