FROM phusion/baseimage:0.9.19
MAINTAINER Seti <seti@setadesign.net>

# Set correct environment variables.
ENV HOME=/root \
	DEBIAN_FRONTEND=noninteractive \
	LC_ALL=C.UTF-8 \
	LANG=en_US.UTF-8 \
	LANGUAGE=en_US.UTF-8

COPY init.sh /etc/my_init.d/init.sh
COPY php-fpm.sh /etc/service/php-fpm/run
COPY nginx.sh /etc/service/nginx/run

# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

RUN echo 'APT::Install-Recommends 0;' >> /etc/apt/apt.conf.d/01norecommends && \
	echo 'APT::Install-Suggests 0;' >> /etc/apt/apt.conf.d/01norecommends && \
	apt-get update -q && \
	apt-get install -y \
		php7.0-cli php7.0-mysql php7.0-gd php7.0-snmp php-pear php7.0-curl \
		php7.0-fpm snmp graphviz php7.0-mcrypt php7.0-json nginx-full fping \
		imagemagick whois mtr-tiny nmap python-mysqldb snmpd php-net-ipv4 \
		php-net-ipv6 rrdtool git at mysql-client && \
	phpenmod mcrypt && \
	useradd librenms -d /opt/librenms -M -r && usermod -a -G librenms www-data && \
	rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh && \
	locale-gen de_DE.UTF-8 && locale-gen en_US.UTF-8 && \
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
	mkdir -p /data/logs /data/rrd /data/config /run/php && \
    cd /opt && \
	chmod +x /etc/my_init.d/init.sh && \
	chmod +x /etc/service/nginx/run && \
	chmod +x /etc/service/php-fpm/run && \
	chown -R nobody:users /data/config && \
	cp /opt/librenms/librenms.nonroot.cron /etc/cron.d/librenms && \
	chmod 0644 /etc/cron.d/librenms && \
	rm -f /etc/nginx/sites-available/default

COPY nginx.conf /etc/nginx/sites-available/default

EXPOSE 80/tcp

VOLUME ["/data"]
