#!/bin/sh
# Done by Peter Andersson
# peter@it-slav.net
# BSD-3 license
#
# Parse /var/db/dhcpd.leases and hopefully get usefull output


printf "IP\t\tHW\t\t\tLease start\t\tLease end\t\tWins\n"

# Get the current date and time in UTC
current_time=$(date -u +"%Y/%m/%d %H:%M:%S UTC")

awk -v current_time="$current_time" '
/lease/ {
    ip = $2;                           # Capture the IP address
    in_lease = 1;                      # Mark that we are in a lease block
    hostname = "";                     # Reset variables for the new lease
    mac = "";
    start_time = "";
    end_time = "";                     # Initialize end_time
}

/client-hostname/ {
    gsub(/"/, "", $2);                 # Remove quotes from the hostname
    hostname = $2;                     # Capture hostname
}

/hardware ethernet/ {
    mac = $3;                          # Capture MAC address
}

/starts/ {
    start_time = $3" "$4" "$5;        # Capture start time
}

/ends/ {
    end_time = $3" "$4" "$5;          # Capture end time
}

/}/ {
    # Only handle valid leases
    if (current_time < end_time) {
        # Check if this IP was seen before
        if (!latest_ip[ip] || start_time > latest_start_time[ip]) {
            latest_start_time[ip] = start_time;  # Update for latest start time
            latest_mac[ip] = mac;                # Update corresponding MAC
            latest_hostname[ip] = hostname;      # Update corresponding hostname
            latest_end_time[ip] = end_time;      # Update corresponding end time
            latest_ip[ip] = 1;                    # Mark IP as seen
        }
    }
}

END {
    # Print unique IPs with their latest details
    for (ip in latest_start_time) {
        print ip "\t" latest_mac[ip] "\t" latest_start_time[ip] "\t" latest_end_time[ip] "\t" latest_hostname[ip];
    }
}' "/var/db/dhcpd.leases" | sed 's/[;]//g'|sort
