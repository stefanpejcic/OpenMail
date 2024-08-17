#!/bin/bash


# NOT PRODUCTION READY

SNAPPYMAIL=false
DOVECOT=false
SOGO=false

for arg in "$@"; do
    case $arg in
        --snappymail)
            SNAPPYMAIL=true
            DOVECOT=false
            SOGO=false
            ;;
        --dovecot)
            SNAPPYMAIL=false
            DOVECOT=true
            SOGO=false
            ;;
        --sogo)
            SNAPPYMAIL=false
            DOVECOT=false
            SOGO=true
            ;;
        --debug)
            DEBUG=true
            ;;
        *)
            ;;
    esac
done

# start the postfix, dovecot and roundcube/snappymail containers with the new network for emails
#apt-get update
#apt-get install -y docker-compose

#setup snappymail
mkdir -p /etc/openpanel/email/snappymail
cp snappymail.ini /etc/openpanel/email/snappymail/config.ini



if [ "$SNAPPYMAIL" = true ]; then
    docker compose up -d mailserver snappymail
elif [ "$DOVECOT" = true ]; then
    docker compose up -d mailserver roundcube
elif [ "$SOGO" = true ]; then
    docker compose up -d mailserver sogo
else
    docker compose up -d mailserver
fi








function open_port_csf() {
    local port=$1
    local csf_conf="/etc/csf/csf.conf"
    
    # Check if port is already open
    port_opened=$(grep "TCP_IN = .*${port}" "$csf_conf")
    if [ -z "$port_opened" ]; then
        # Open port
        sed -i "s/TCP_IN = \"\(.*\)\"/TCP_IN = \"\1,${port}\"/" "$csf_conf"
        echo "Port ${port} opened in CSF."
        ports_opened=1
    else
        echo "Port ${port} is already open in CSF."
    fi
}



# CSF
if command -v csf >/dev/null 2>&1; then
    open_port_csf 25
    open_port_csf 143
    open_port_csf 465
    open_port_csf 587
    open_port_csf 993 
    
# UFW
elif command -v ufw >/dev/null 2>&1; then
    ufw allow 25
    #ufw allow 8080 && \ #uncomment to expose webmail
    ufw allow 143
    ufw allow 465
    ufw allow 587
    ufw allow 993
else
    echo "Error: Neither CSF nor UFW are installed. make sure ports 25 243 465 587 and 993 are opened on external firewall, or email will not work."
fi



















# create user
#
# docker exec -it openadmin_mailserver setup email add stefan@openpanel.site stefan
#

# Add all ACTIVE users to the new network

user_list=$(opencli user-list --json)




ensure_jq_installed() {
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        # Install jq using apt
        sudo apt-get update > /dev/null 2>&1
        sudo apt-get install -y -qq jq > /dev/null 2>&1
        # Check if installation was successful
        if ! command -v jq &> /dev/null; then
            echo "Error: jq installation failed. Please install jq manually and try again."
            exit 1
        fi
    fi
}



# install jq
ensure_jq_installed





# Loop through each user
echo "$user_list" | jq -c '.[]' | while read -r user; do
    username=$(echo "$user" | jq -r '.username')
    if [[ "$username" != *"_"* ]]; then
        echo "Enabling emails for: $username"
        docker network connect openmail_network "$username"
    else
        echo "Skipping suspended user $username"
    fi
done


# todo: enable in modules the new amil module
