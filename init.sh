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
	
	ln -s /data/rrd /opt/librenms/rrd
	ln -s /data/plugins /opt/librenms/html/plugins
	ln -s /data/logs /opt/librenms/logs
	cp /opt/librenms/librenms.nonroot.cron /etc/cron.d/librenms
	chmod 0644 /etc/cron.d/librenms
fi

if [ ! -f /data/config/config.php ]; then
	cp /opt/librenms/config.php.default /data/config/config.php
fi
ln -s /data/config/config.php /opt/librenms/config.php

chown -R librenms:librenms /opt/librenms
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
echo "\$config['rrd_dir']       = \"/data/rrd\";" >> /data/config/config.php

sed -i "/\$config\['rrdcached'\].*;/d" /data/config/config.php
echo "\$config['rrdcached']       = \"unix:/var/run/rrdcached/rrdcached.sock\";" >> /data/config/config.php

sed -i "/\$config\['rrdtool_version'\].*;/d" /data/config/config.php
echo "\$config['rrdtool_version']       = \"1.5.5\";" >> /data/config/config.php

sed -i "/\$config\['log_file'\].*;/d" /data/config/config.php
echo "\$config['log_file']      = \"/data/logs/librenms.log\";" >> /data/config/config.php

sed -i "/\$config\['log_dir'\].*;/d" /data/config/config.php
echo "\$config['log_dir']       = \"/data/logs\";" >> /data/config/config.php

# Activate services
SERVICES_ENABLED=${SERVICES_ENABLED:-0}
if [ "${SERVICES_ENABLED}" == "1" ]
then
  sed -i "/\$config\['show_services'\].*;/d" /data/config/config.php
  echo "\$config['show_services']  = 1;" >> /data/config/config.php

  sed -i "/\$config\['nagios_plugins'\].*;/d" /data/config/config.php
  echo "\$config['nagios_plugins'] = \"/usr/lib/nagios/plugins\";" >> /data/config/config.php

  echo '*/5 * * * * librenms /opt/librenms/check-services.php >> /dev/null 2>&1' > /etc/cron.d/librenms
fi

# LDAP support
LDAP_ENABLED=${LDAP_ENABLED:-0}
if [ "${LDAP_ENABLED}" == "1" ]
then
  echo "setup ldap support"
  
  LDAP_VERSION=${LDAP_VERSION:-3}
  LDAP_SERVER=${LDAP_SERVER:-ldap.example.com}
  LDAP_PORT=${LDAP_PORT:-389}
  LDAP_PREFIX=${LDAP_PREFIX:-uid=}
  LDAP_SUFFIX=${LDAP_SUFFIX:-,ou=People,dc=example,dc=com}

  sed -i "/\$config\['auth_mechanism'\].*;/d" /data/config/config.php
  echo "\$config['auth_mechanism']                        = \"ldap\";" >> /data/config/config.php

  sed -i "/\$config\['auth_ldap_version'\].*;/d" /data/config/config.php
  echo "\$config['auth_ldap_version']                     = \"${LDAP_VERSION}\";" >> /data/config/config.php

  sed -i "/\$config\['auth_ldap_server'\].*;/d" /data/config/config.php
  echo "\$config['auth_ldap_server']                      = \"${LDAP_SERVER}\";" >> /data/config/config.php

  sed -i "/\$config\['auth_ldap_port'\].*;/d" /data/config/config.php
  echo "\$config['auth_ldap_port']                        = \"${LDAP_PORT}\";" >> /data/config/config.php

  sed -i "/\$config\['auth_ldap_prefix'\].*;/d" /data/config/config.php
  echo "\$config['auth_ldap_prefix']                      = \"${LDAP_PREFIX}\";" >> /data/config/config.php

  sed -i "/\$config\['auth_ldap_suffix'\].*;/d" /data/config/config.php
  echo "\$config['auth_ldap_suffix']                      = \"${LDAP_SUFFIX}\";" >> /data/config/config.php
  
  
  LDAP_GROUP=${LDAP_GROUP:-cn=groupname,ou=groups,dc=example,dc=com}
  LDAP_GROUP_BASE=${LDAP_GROUP_BASE:-ou=group,dc=example,dc=com}
  LDAP_GROUP_MEMBER_ATTR=${LDAP_GROUP_MEMBER_ATTR:-member}
  LDAP_GROUP_MEMBER_TYPE=${LDAP_GROUP_MEMBER_TYPE:-}
  
  sed -i "/\$config\['auth_ldap_group'\].*;/d" /data/config/config.php
  if [ "${LDAP_GROUP}" == "false" ]; then
    echo "\$config['auth_ldap_group']                       = false;" >> /data/config/config.php
  else
    echo "\$config['auth_ldap_group']                       = \"${LDAP_GROUP}\";" >> /data/config/config.php
  fi

  sed -i "/\$config\['auth_ldap_groupbase'\].*;/d" /data/config/config.php
  echo "\$config['auth_ldap_groupbase']                   = \"${LDAP_GROUP_BASE}\";" >> /data/config/config.php

  sed -i "/\$config\['auth_ldap_groupmemberattr'\].*;/d" /data/config/config.php
  echo "\$config['auth_ldap_groupmemberattr']             = \"${LDAP_GROUP_MEMBER_ATTR}\";" >> /data/config/config.php

  sed -i "/\$config\['auth_ldap_groups'\].*;/d" /data/config/config.php
  echo "\$config['auth_ldap_groups']['admin']['level']    = 10;" >> /data/config/config.php
  echo "\$config['auth_ldap_groups']['pfy']['level']      = 7;" >> /data/config/config.php
  echo "\$config['auth_ldap_groups']['support']['level']  = 1;" >> /data/config/config.php

  sed -i "/\$config\['auth_ldap_groupmembertype'\].*;/d" /data/config/config.php
  echo "\$config['auth_ldap_groupmembertype']             = \"${LDAP_GROUP_MEMBER_TYPE}\";" >> /data/config/config.php
  
  LDAP_AUTH_BIND=${LDAP_AUTH_BIND:-0}
  LDAP_BIND_USER=${LDAP_BIND_USER:-cn=librenms,ou=application,dc=example,dc=com}
  LDAP_BIND_PASSWORD=${LDAP_BIND_PASSWORD:-pwd4librenms}
  if [ "${LDAP_AUTH_BIND}" == "1" ]; then
    # Feature request as of 2017-09-02
    # See https://github.com/librenms/librenms/issues/5089
    # and https://community.librenms.org/t/feature-request-ldap-enhancements-bind-recursive-ssl/679

    sed -i "/\$config\['auth_ad_binduser'\].*;/d" /data/config/config.php
    echo "\$config['auth_ad_binduser']                      = \"${LDAP_BIND_USER}\";" >> /data/config/config.php

    sed -i "/\$config\['auth_ad_bindpassword'\].*;/d" /data/config/config.php
    echo "\$config['auth_ad_bindpassword']                  = \"${LDAP_BIND_PASSWORD}\";" >> /data/config/config.php
  fi
fi

# some php configs
sed -i 's/pm.max_children = 5/pm.max_children = 50/g' /etc/php/7.0/fpm/pool.d/www.conf
sed -i 's/pm.start_servers = 2/pm.start_servers = 5/g' /etc/php/7.0/fpm/pool.d/www.conf
sed -i 's/pm.min_spare_servers = 1/pm.min_spare_servers = 3/g' /etc/php/7.0/fpm/pool.d/www.conf
sed -i 's/pm.max_spare_servers = 3/pm.max_spare_servers = 10/g' /etc/php/7.0/fpm/pool.d/www.conf
sed -i 's/;clear_env/clear_env/g' /etc/php/7.0/fpm/pool.d/www.conf

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

#cleanup pid
rm -f /var/run/rrdcached.pid

atd

echo "/opt/librenms/discovery.php -u && /opt/librenms/discovery.php -h all && /opt/librenms/poller.php -h all" | at -M now + 1 minute

echo "init done"
