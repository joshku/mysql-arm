FROM arm32v7/ubuntu:artful

RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y gosu openssl

RUN { \
        echo mysql-community-server mysql-community-server/data-dir select ''; \
        echo mysql-community-server mysql-community-server/root-pass password ''; \
        echo mysql-community-server mysql-community-server/re-root-pass password ''; \
        echo mysql-community-server mysql-community-server/remove-test-db select false; \ 
    } | debconf-set-selections && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server && \
    rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql /var/run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld && \
    # ensure that /var/run/mysqld (used for socket and lock files) is writable regardless of the UID our mysqld instance ends up having at runtime
    chmod 777 /var/run/mysqld && \
    # comment out a few problematic configuration values
    find /etc/mysql/ -name '*.cnf' -print0 \
    | xargs -0 grep -lZE '^(bind-address|log)' \
    | xargs -rt -0 sed -Ei 's/^(bind-address|log)/#&/' && \
    # don't reverse lookup hostnames, they are usually another container
    echo '[mysqld]\nskip-host-cache\nskip-name-resolve' > /etc/mysql/conf.d/docker.cnf && \
    mkdir /docker-entrypoint-initdb.d

VOLUME /var/lib/mysql

COPY docker_entrypoint.sh /

EXPOSE 3306

ENTRYPOINT ["/docker_entrypoint.sh"]

CMD ["mysqld"]

