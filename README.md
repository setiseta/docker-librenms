LibreNMS
====

LibreNMS is a fully featured network monitoring system.

---
Last Changes
===
- 2015/12/07: fixed auto update
- 2015/11/30: add mysqlsettings: innodb_buffer_pool_size to 8GB as recommended by librenms (mysqlstartup)

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

### with sameersbn/mysql as database

```bash
NAME="librenms"
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
echo "[mysqld]" > innodb.cnf
echo "innodb_buffer_pool_size = 8192M" >> innodb.cnf
docker run -d -m 1g \
	-v $DIR/mysql:/var/lib/mysql \
	-v $DIR/innodb.cnf:/etc/mysql/conf.d/innodb.cnf \
	-e DB_USER=$NAME \
	-e DB_PASS=pwd4$NAME \
	-e DB_NAME=$NAME \
	--name $NAME-db \
	sameersbn/mysql:latest
```
---
```bash
NAME="librenms"
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
docker run -d \
	-v $DIR/data:/data \
	-p 80:80 \
	-e TZ="Europe/Vienna" \
	--link $NAME-db:mysql \
	-e POLLER=24 \
	--name $NAME \
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
