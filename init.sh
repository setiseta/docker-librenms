#!/bin/bash

if [ ! -d /data/config ]; then
	mkdir /data/config
fi
if [ ! -d /data/rrd ]; then
	mkdir /data/rrd
fi
if [ ! -d /data/logs ]; then
	mkdir /data/logs
fi
if [ ! -d /data/plugins ]; then
	mkdir /data/plugins
fi

if [ ! -d /opt/librenms ]; then
	echo "Clone Repo from github."
	cd /opt
	git clone https://github.com/librenms/librenms.git librenms
	rm -rf /opt/librenms/html/plugins
	cd /opt/librenms
	if [ ! -f /data/config/config.php ]; then
		cp /opt/librenms/config.php.default /data/config/config.php
	fi

	ln -s /data/config/config.php /opt/librenms/config.php
	ln -s /data/rrd /opt/librenms/rrd
	ln -s /data/plugins /opt/librenms/html/plugins
	ln -s /data/logs /opt/librenms/logs
fi

chown librenms:librenms /opt/librenms -R
chown nobody:users /data/config/config.php
chown www-data:www-data /data/logs
chown nobody:users /data/plugins
chown nobody:users /data/config
chmod 775 /data/rrd
chown librenms:librenms /data/rrd
chmod 0777 /data/logs -R

if [ ! -f /etc/container_environment/TZ ] ; then
	echo UTC > /etc/container_environment/TZ
	TZ="UTC"
fi

if [ ! -f /etc/container_environment/POLLER ] ; then
	echo 16 > /etc/container_environment/POLLER
	POLLER=16
fi

sed -i "s#\;date\.timezone\ \=#date\.timezone\ \=\ $TZ#g" /etc/php/7.0/fpm/php.ini
sed -i "s#\;date\.timezone\ \=#date\.timezone\ \=\ $TZ#g" /etc/php/7.0/cli/php.ini
sed -i "s/#PC#/$POLLER/g" /etc/cron.d/librenms

DB_TYPE=${DB_TYPE:-}
DB_HOST=${DB_HOST:-}
DB_PORT=${DB_PORT:-}
DB_NAME=${DB_NAME:-}
DB_USER=${DB_USER:-}
DB_PASS=${DB_PASS:-}

if [ -n "${MYSQL_PORT_3306_TCP_ADDR}" ]; then
	DB_TYPE=${DB_TYPE:-mysql}
	DB_HOST=${DB_HOST:-${MYSQL_PORT_3306_TCP_ADDR}}
	DB_PORT=${DB_PORT:-${MYSQL_PORT_3306_TCP_PORT}}

	# support for linked sameersbn/mysql image
	DB_USER=${DB_USER:-${MYSQL_ENV_DB_USER}}
	DB_PASS=${DB_PASS:-${MYSQL_ENV_DB_PASS}}
	DB_NAME=${DB_NAME:-${MYSQL_ENV_DB_NAME}}

	# support for linked orchardup/mysql and enturylink/mysql image
	# also supports official mysql image
	DB_USER=${DB_USER:-${MYSQL_ENV_MYSQL_USER}}
	DB_PASS=${DB_PASS:-${MYSQL_ENV_MYSQL_PASSWORD}}
	DB_NAME=${DB_NAME:-${MYSQL_ENV_MYSQL_DATABASE}}
fi

if [ -z "${DB_HOST}" ]; then
  echo "ERROR: "
  echo "  Please configure the database connection."
  echo "  Cannot continue without a database. Aborting..."
  exit 1
fi

# use default port number if it is still not set
case "${DB_TYPE}" in
  mysql) DB_PORT=${DB_PORT:-3306} ;;
  *)
    echo "ERROR: "
    echo "  Please specify the database type in use via the DB_TYPE configuration option."
    echo "  Accepted value \"mysql\". Aborting..."
    exit 1
    ;;
esac

# set default user and database
DB_USER=${DB_USER:-root}
DB_NAME=${DB_NAME:-librenms}

sed -i -e "s/\$config\['db_pass'\] = .*;/\$config\['db_pass'\] = \"$DB_PASS\";/g" /data/config/config.php
sed -i -e "s/\$config\['db_user'\] = .*;/\$config\['db_user'\] = \"$DB_USER\";/g" /data/config/config.php
sed -i -e "s/\$config\['db_host'\] = .*;/\$config\['db_host'\] = \"$DB_HOST\";/g" /data/config/config.php
sed -i -e "s/\$config\['db_name'\] = .*;/\$config\['db_name'\] = \"$DB_NAME\";/g" /data/config/config.php
sed -i "/\$config\['rrd_dir'\].*;/d" /data/config/config.php
sed -i "/\$config\['log_file'\].*;/d" /data/config/config.php
sed -i "/\$config\['log_dir'\].*;/d" /data/config/config.php
echo "\$config['rrd_dir']       = \"/data/rrd\";" >> /data/config/config.php
echo "\$config['log_file']      = \"/data/logs/librenms.log\";" >> /data/config/config.php
echo "\$config['log_dir']       = \"/data/logs\";" >> /data/config/config.php

# checking for supported plugins
#weathermap
if [ -f /etc/container_environment/WEATHERMAP ] ; then
	cd /data/plugins/
	if [ ! -d /data/plugins/Weathermap ] ; then
		git clone https://github.com/setiseta/Weathermap.git
	else
		cd /data/plugins/Weathermap
		git pull
	fi
	chown www-data:www-data /data/plugins/Weathermap/configs -R
	chown www-data:www-data /data/plugins/Weathermap/output -R
	chmod +x /data/plugins/Weathermap/map-poller.php
	echo "*/5 * * * *   root    php /opt/librenms/html/plugins/Weathermap/map-poller.php >> /dev/null 2>&1" > /etc/cron.d/weathermap
	sed -i -e "s/\$ENABLED=false;/\$ENABLED=true;/g" /data/plugins/Weathermap/editor.php
fi

prog="mysqladmin -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} ${DB_PASS:+-p$DB_PASS} status"
timeout=60
echo "Waiting for database server to accept connections"
while ! ${prog} >/dev/null 2>&1
do
	timeout=$(expr $timeout - 1)
	if [ $timeout -eq 0 ]; then
		printf "\nCould not connect to database server. Aborting...\n"
		exit 1
	fi
	printf "."
	sleep 1
done
echo "DB onnection is ok"

QUERY="SELECT count(*) FROM information_schema.tables WHERE table_schema = '${DB_NAME}';"
COUNT=$(mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} ${DB_PASS:+-p$DB_PASS} -ss -e "${QUERY}")

cd /opt/librenms
if [ -z "${COUNT}" -o ${COUNT} -eq 0 ]; then
	echo "Setting up Librenms for firstrun."
	php build-base.php
	php adduser.php librenms librenms 10
	#php addhost.php localhost public v2c
fi

atd

echo "/opt/librenms/discovery.php -u && /opt/librenms/discovery.php -h all && /opt/librenms/poller.php -h all" | at -M now + 1 minute

echo "init done"
