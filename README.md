LibreNMS
====

- LibreNMS is a fully featured network monitoring system.
- PHP 7 FPM / nginx / rrdcached
- Please send an issue an github if you see an error with this docker image.

---
Last Changes
===
- 2017/08/29: update phusion baseiamge 0.9.22
- 2016/09/29: added rrdcached
- 2016/09/29: fix cronjobs
- 2016/09/28: update to Ubuntu 16.04 (phusion baseiamge 0.9.19)
- 2016/09/28: change to php 7 & nginx
- 2016/09/28: fixes graphs on overview pages.
- 2017/09/02: ldap authentication support; use mariadb as backend database server

---
Version
===
- on docker start it will pull the latest version.
- the system is updating every day
- [new/changed] weathermap support, activate with environment var.
- [02.08.2015] Fixed auto update permission problem.

---
Usage example
===
### Needed directories on host:
- data
- mysql

### with docker-compose

```bash
docker-compose up -d
```

### with docker-compose + LDAP

```bash
docker-compose -f docker-compose-ldap.yml up -d
```

### with mariadb as database

```bash
docker run -d -m 1g \
	-v `pwd`/mysql:/var/lib/mysql \
	-v `pwd`/50-server.cnf:/etc/mysql/mariadb.conf.d/50-server.cnf:ro \
	-e MYSQL_ROOT_PASSWORD=pwd4librenms \
	-e LDAP_ENABLED=1 \
	-e LDAP_VERSION=3 \
	-e LDAP_SERVER=ldap.example.com \
	-e LDAP_PORT=389 \
	-e LDAP_PREFIX=uid= \
	-e LDAP_SUFFIX=,ou=People,dc=example,dc=com \
	-e LDAP_GROUP=cn=groupname,ou=groups,dc=example,dc=com \
	-e LDAP_GROUP_BASE=ou=group,dc=example,dc=com \
	-e LDAP_GROUP_MEMBER_ATTR=uid \
	--name librenms-db \
	mariadb:latest
```
---
```bash
docker run -d \
	-v `pwd`/data:/data \
	-p 80:80 \
	-e TZ="Europe/Vienna" \
	--link librenms-db:mysql \
	-e POLLER=24 \
	-e DB_TYPE=mysql \
	-e DB_HOST=mysql \
	-e DB_NAME=librenms \
	-e DB_USER=root \
	-e DB_PASS=pwd4librenms \
	--name librenms \
	seti/librenms
```

---
Access
===
- URL: http://localhost (or the ip from the host running this docker)
- User: librenms
- Pass: librenms

---
Environment Vars
===
- **POLLER**: Set poller count. [a good value is 4 x CPU Count] Defaults to `16`
- **TZ**: Set timezone. Defaults to `UTC`
- **WEATHERMAP**: if set [=1], it pulls the weathermap plugin. Needs to be enabled in frontend.

---
Plugins
===
- to use the weathermap plugin do following:

```bash
[change to your data folder on host]
mkdir plugins (if it not exists. first run of this container will create it.)
cd plugins
git clone https://github.com/laf/Weathermap-for-Observium.git weathermap
```


---
Credits
===
- This docker image is built upon the baseimage made by phusion
- LibreNMS Team: http://www.librenms.org/
