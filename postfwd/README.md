# PostFW setup on DMS Postfix

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
