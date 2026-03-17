# postfwd setup on DMS Postfix

By default, rate-limiting is disabled on OpenPanel servers. To enable it, edit `/usr/local/mail/openmail/postfwd/postfwd.cf` and configure the desired limits for each IP address, email address, or domain.

## Enable


```bash
cd /usr/local/mail/openmail
mv postfwd/postfix-main.cf docker-data/dms/config/postfix-main.cf
docker --context=default compose u -d postfwd
docker --context=default restart openadmin_mailserver
```

## Disable

```bash
cd /usr/local/mail/openmail
mv docker-data/dms/config/postfix-main.cf postfwd/postfix-main.cf
docker --context=default compose down postfwd
docker --context=default restart openadmin_mailserver
```



## Customization

Examples:
```bash
# Limit per IP
id=limit_ip ; protocol_state==RCPT
                action=rate(client_address/300/3600/450 4.7.1 sorry, max 300 requests per hour)

# Limit per email
id=limit_user_hour ; sender=~.+@.+ ; protocol_state==RCPT
                action=rate(sender/500/3600/450 4.7.1 sorry, max 500 emails per user per hour)

# Limit per domain
id=limit_domain_generic ; sender=~.+@.+ ; protocol_state==RCPT
                action=rate(sender_domain/2000/3600/450 4.7.1 sorry, max 2000 emails per domain per hour)

# Limit entire server
id=limit_server_hour ; protocol_state==RCPT
                action=rate(server/10000/3600/450 4.7.1 sorry, max 10000 emails per server per hour)
```
