#!/bin/bash
# This script processes activealerts1.json and outputs active alerts to activealerts.txt

alertlogo=$(cat << 'EOF'
<pre>
    ___     __     ______ ____  ______
   /   |   / /    / ____// __ \/_  __/
  / /| |  / /    / __/  / /_/ / / /   
 / ___ | / /___ / /___ / _, _/ / /    
/_/  |_|/_____//_____//_/ |_| /_/     

</pre>
EOF
)

# Get current epoch time (seconds since 1970-01-01)
now=$(date +%s)

# Process active alerts
awk -v now="$now" '
  BEGIN {
    RS = "-----------------------\n"
    ORS = "-----------------------\n"
  }
  {
    if (match($0, /Expires: ([^ \n]+)/, arr)) {
      expiry = arr[1]
      cmd = "date -d \"" expiry "\" +%s"
      cmd | getline exp_epoch
      close(cmd)
      if (exp_epoch > now)
        print $0
    }
  }
' db/activealerts1.json > db/activealerts.txt

# Prepend the alertlogo to activealerts.txt using printf and a temporary file
temp_file=$(mktemp)
{
    printf "%s\n" "$alertlogo"  # Print the ASCII art safely
    cat db/activealerts.txt     # Append the active alerts output
} > "$temp_file"

# Overwrite the original file with the modified content
mv "$temp_file" db/activealerts.txt
