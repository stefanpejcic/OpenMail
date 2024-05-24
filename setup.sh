#!/bin/bash

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
apt-get update
apt-get install -y docker-compose

#setup snappymail
/mkdir -p /etc/openpanel/email/snappymail
cp snappymail.ini /etc/openpanel/email/snappymail/config.ini



if [ "$SNAPPYMAIL" = true ]; then
    docker-compose -d -p emails up mailserver snappymail
elif [ "$DOVECOT" = true ]; then
    docker-compose -d -p emails up mailserver roundcube
elif [ "$SOGO" = true ]; then
    docker-compose -d -p emails up mailserver sogo
else
    docker-compose -d -p emails up
fi

# open ports
ufw allow 25 && \
#ufw allow 8080 && \ #uncomment to expose webmail
ufw allow 143 && \
ufw allow 465 && \
ufw allow 587 && \
ufw allow 993 



# create user
#
# docker exec -it openadmin_mailserver setup email add stefan@openpanel.site stefan
#

# Add all ACTIVE users to the new network

user_list=$(opencli user-list --json)

# install jq
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Installing jq..."
    apt-get install jq -y  # For Debian/Ubuntu
    # yum install jq -y      # For CentOS/RHEL
    # brew install jq        # For macOS
fi

# Loop through each user
echo "$user_list" | jq -c '.[]' | while read -r user; do
    username=$(echo "$user" | jq -r '.username')
    if [[ "$username" != *"_"* ]]; then
        echo "Enabling emails for: $username"
        docker network connect openadmin_mail_network "$username"
    else
        echo "Skipping suspended user $username"
    fi
done


# todo: enable in modules the new amil module
