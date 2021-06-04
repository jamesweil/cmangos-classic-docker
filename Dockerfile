############################################################
# Dockerfile to build a Classic CMaNGOS Server
############################################################
FROM debian:latest

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
ENV MYSQL_ROOT_PASSWORD root

RUN apt-get update
RUN apt install -y grep build-essential gcc g++ automake git-core autoconf make \
patch cmake libmariadb-dev libmariadb-dev-compat mariadb-server libtool libssl-dev \
binutils zlibc libc6 libbz2-dev subversion libboost-all-dev \
supervisor curl dnsutils vim net-tools openssh-server nginx python sudo bash ca-certificates iproute2

# Adding mangos user and group
RUN useradd -m -d /home/mangos -c "MaNGOS" -U mangos

WORKDIR /home/mangos/

# Cloning repos
RUN git clone git://github.com/cmangos/mangos-classic.git mangos
RUN git clone git://github.com/cmangos/classic-db.git

# "Creating build folders"
RUN mkdir build

# Compiling
WORKDIR /home/mangos/build
RUN cmake ../mangos -DCMAKE_INSTALL_PREFIX=\../mangos/run -DBUILD_EXTRACTORS=ON -DPCH=1 -DDEBUG=0 -DBUILD_PLAYERBOT=ON
RUN make -j $(cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l)
RUN make install

WORKDIR /home/mangos/mangos/run/etc
RUN cp mangosd.conf.dist mangosd.conf
RUN cp realmd.conf.dist realmd.conf

# TODO:Extract files from the client

# Adding configs and some scripts
ADD set_realmlist_public.sql /home/mangos/mangos/sql/base/set_realmlist_public.sql
ADD create_gm_account.sql /home/mangos/mangos/sql/
ADD etc/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
ADD etc/supervisor/conf.d/mangosd.conf /etc/supervisor/conf.d/mangosd.conf
ADD etc/supervisor/conf.d/realmd.conf /etc/supervisor/conf.d/realmd.conf
ADD run.sh /run.sh

# Setting permission
RUN chmod +x /run.sh
RUN chown -R mangos:mangos /home/mangos/

EXPOSE 8085
EXPOSE 3724
EXPOSE 3306

CMD ["/run.sh"]
