# PostFW setup on DMS Postfix

Rate-limiting is by defualt disbaled on Openpanel servers. Edit the `/usr/local/mail/openmail/postfwd/postfwd.cf` and set desired limits per IP, email address or domain.


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
