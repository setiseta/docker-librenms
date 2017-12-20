FROM phusion/baseimage:0.9.22
MAINTAINER Seti <seti@setadesign.net>

# Set correct environment variables.
ENV HOME=/root \
	DEBIAN_FRONTEND=noninteractive \
	LC_ALL=C.UTF-8 \
	LANG=en_US.UTF-8 \
	LANGUAGE=en_US.UTF-8

RUN echo 'APT::Install-Recommends 0;' >> /etc/apt/apt.conf.d/01norecommends && \
	echo 'APT::Install-Suggests 0;' >> /etc/apt/apt.conf.d/01norecommends && \
	apt-get update -q && \
	apt-get upgrade -y -o Dpkg::Options::="--force-confold" && \
	apt-get install -y \
		php7.0-cli php7.0-mysql php7.0-gd php7.0-snmp php-pear php7.0-curl php-memcached \
		php7.0-fpm snmp graphviz php7.0-mcrypt php7.0-json php7.0-opcache nginx-full fping \
		imagemagick whois mtr-tiny nmap python-mysqldb snmpd php-net-ipv4 php7.0-ldap \
		php-net-ipv6 php-imagick rrdtool rrdcached git at mysql-client nagios-plugins sudo \
        memcached && \
	phpenmod mcrypt && \
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
	
RUN	useradd librenms -d /opt/librenms -M -r && usermod -a -G librenms www-data && \
	rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh && \
	locale-gen de_DE.UTF-8 && locale-gen en_US.UTF-8 && \
	mkdir -p /data/logs /data/rrd /data/config /run/php /var/run/rrdcached



# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

COPY init.sh /etc/my_init.d/init.sh
COPY php-fpm.sh /etc/service/php-fpm/run
COPY nginx.sh /etc/service/nginx/run
COPY rrdcached.sh /opt/services/rrdcached/run
COPY memcached.sh /opt/services/memcached/run

RUN cd /opt && \
	chmod +x /etc/my_init.d/init.sh && \
	chmod +x /etc/service/nginx/run && \
	chmod +x /etc/service/php-fpm/run && \
	chmod +x /opt/services/*/run && \
	chown -R nobody:users /data/config && \
	chown librenms:librenms /var/run/rrdcached && \
	chmod 755 /var/run/rrdcached && \
	chmod u+s /usr/bin/fping && \
	chmod u+s /usr/bin/fping6 && \
	rm -f /etc/nginx/sites-available/default

COPY nginx.conf /etc/nginx/sites-available/default

EXPOSE 80/tcp
# Memcached
EXPOSE 11211/tcp
# RRDCached
EXPOSE 42217/tcp

VOLUME ["/data"]
