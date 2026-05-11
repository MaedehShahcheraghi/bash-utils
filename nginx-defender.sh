#!/bin/bash

MAX_ERRORS=1

LOG_FILE="/var/log/nginx-defender.log"

WHITELIST=("127.0.0.1" "192.168.18.139" "192.168.1.100")

ContainerIds=$(docker ps --filter "name=nginx" --filter "status=running" -q)

if [ -z "$ContainerIds" ]; then
    echo "No running Nginx containers found. Exiting."
    exit 0
fi
for containerId in $ContainerIds; do
    
    BadIps=$(docker logs "$containerId" 2>/dev/null | awk '($9 == "404" || $9 == "403") {print $1}' | sort | uniq -c | awk -v limit="$MAX_ERRORS" '$1 > limit {print $2}')

    for ip in $BadIps; do
        
        Is_Whitelisted=0
        for white_ip in "${WHITELIST[@]}"; do
            if [ "$ip" == "$white_ip" ]; then
                Is_Whitelisted=1
                break
            fi
        done

        if [ $Is_Whitelisted -eq 1 ]; then
        	continue
	fi

        if ! ufw status | grep -qw "$ip"; then
            
            TimeStamp=$(date +"%Y-%m-%d %H:%M:%S")
            echo "[$TimeStamp] Blocking malicious IP: $ip from container $containerId" >> "$LOG_FILE"
            ufw deny from "$ip" to any > /dev/null
        fi
    done
done


























