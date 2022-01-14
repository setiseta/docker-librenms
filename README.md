LibreNMS
====

Deprecated
====
- since there is an official image now which includes all the features  there is no need to maintain another image
- (https://hub.docker.com/r/librenms/librenms)
- this repo is not longer maintained, feel free to fork.

## Old Info
- LibreNMS is a fully featured network monitoring system.
- PHP 7 FPM / nginx / rrdcached
- Please send an issue an github if you see an error with this docker image.

---
Last Changes
===
- 2020/03/13: Update to PHP7.4
- 2019/03/15: Add folder for custom monitoring plugins
- 2018/09/20: Update to baseiamge 0.11 (bionic, ubuntu 18.04 base)
- 2018/05/10: Update to PHP 7.2 & Fix Timezone Setup & baseimage 0.10.1
- 2018/04/30: Added ceph service support
- 2018/02/09: Update to Phusion Baseimage 0.10.0 & added composer
- 2017/12/14: Support for distributed poller nodes
- 2017/10/31: ldap auth bind support added
- 2017/10/19: add new env UPDATE_CHANNEL with default value: master.
- 2017/10/18: dynamic config.php based on environment variables (fixes #8)
- 2017/10/18: ldap group type added
- 2017/09/02: ldap authentication support; use mariadb as backend database server
- 2017/08/29: update phusion baseiamge 0.9.22
- 2016/09/29: added rrdcached
- 2016/09/29: fix cronjobs
- 2016/09/28: update to Ubuntu 16.04 (phusion baseiamge 0.9.19)
- 2016/09/28: change to php 7 & nginx
- 2016/09/28: fixes graphs on overview pages.

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

### with docker-compose + distributed poller

```bash
docker-compose -f docker-compose-distributed-poller.yml up -d
```

### with docker-compose + ceph support

```bash
docker-compose -f docker-compose-ceph.yml up -d
```

### with mariadb as database

```bash
docker run -d -m 1g \
	-v $PWD/mysql:/var/lib/mysql \
	-v $PWD/50-server.cnf:/etc/mysql/mariadb.conf.d/50-server.cnf:ro \
	-e MYSQL_ROOT_PASSWORD=pwd4librenms \
	-e TZ=Europe/Vienna \
	--name librenms-db \
	mariadb:latest
```
---
```bash
docker run -d \
	-v $PWD/data:/data \
	-p 80:80 \
	-e TZ=Europe/Vienna \
	--link librenms-db:mysql \
	-e POLLER=24 \
	-e DB_TYPE=mysql \
	-e DB_HOST=mysql \
	-e DB_NAME=librenms \
	-e DB_USER=root \
	-e DB_PASS=pwd4librenms \
	-e LDAP_ENABLED=0 \
	-e LDAP_VERSION=3 \
	-e LDAP_SERVER=ldap.example.com \
	-e LDAP_PORT=389 \
	-e LDAP_PREFIX=uid= \
	-e LDAP_SUFFIX=,ou=People,dc=example,dc=com \
	-e LDAP_GROUP=cn=groupname,ou=groups,dc=example,dc=com \
	-e LDAP_GROUP_BASE=ou=group,dc=example,dc=com \
	-e LDAP_GROUP_MEMBER_ATTR=uid \
	-e LDAP_GROUP_MEMBER_TYPE= \
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
- **UPDATE_CHANNEL**: Select update channel, can be `release`or `master`. Default: `master`

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
Monitoring Plugins
===
- to use custom monitoring plugins, place them under `/data/monitoring-plugins`
- a restart is required

---
Credits
===
- This docker image is built upon the baseimage made by phusion
- LibreNMS Team: http://www.librenms.org/
