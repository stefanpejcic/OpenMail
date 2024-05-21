#!/bin/bash

# start the postfix, dovecot and roundcube containers with the new networ for emails
apt-get update
apt-get install -y docker-compose

docker-compose up -d


# open ports
ufw allow 25 && \
#ufw allow 8080 && \
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
