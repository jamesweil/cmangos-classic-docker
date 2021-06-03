#!/bin/bash

echo "Starting server"

echo "Waiting on mysql"
while ! mysqladmin ping --silent; do
  service mysql start
  sleep 3
done

# Creating mangos user
mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "CREATE USER 'mangos'@'%' IDENTIFIED BY 'mangos';"
mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON *.* TO 'mangos'@'%';"
mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "flush privileges;"

# Creating and Initializing mangos db
mysql -uroot -p${MYSQL_ROOT_PASSWORD} < /home/mangos/mangos/sql/create/db_create_mysql.sql
mysql -uroot -p${MYSQL_ROOT_PASSWORD} classicmangos < /home/mangos/mangos/sql/base/mangos.sql

# Installing classicdb
cd /home/mangos/classicdb

./InstallFullDB.sh # Running it once to generate the config
sed -i -e 's/CORE_PATH=""/CORE_PATH="\/home\/mangos\/mangos"/g' InstallFullDB.config
#sed -i -e 's/DB_HOST="localhost"/DB_HOST="db"/g' InstallFullDB.config
cat InstallFullDB.config

./InstallFullDB.sh
if [[ $? != 0 ]]; then echo "Error Installing classicdb. Exiting.."; exit 1; fi
echo "classicdb installed"

# Filling ScriptDev2 database
mysql -uroot -p${MYSQL_ROOT_PASSWORD} classicmangos < /home/mangos/mangos/sql/scriptdev2/scriptdev2.sql

# Filling ACID to world-database
mysql -uroot -p${MYSQL_ROOT_PASSWORD} classicmangos < /home/mangos/acid/acid_classic.sql


# Executing first run
if [ ! -f /home/mangos/run/etc/done_first_run ]; then
  echo "Running first run scripts"

  # Creating and Initializing realmd and characters
  #mysql -uroot -p${MYSQL_ROOT_PASSWORD} < /home/mangos/mangos/sql/create/create_char_realmd_db.sql
  mysql -uroot -p${MYSQL_ROOT_PASSWORD} classiccharacters < /home/mangos/mangos/sql/base/characters.sql
  mysql -uroot -p${MYSQL_ROOT_PASSWORD} classicrealmd < /home/mangos/mangos/sql/base/realmd.sql

  # Making server public
  pub_ip=$(dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | cut -d'"' -f2)
  sed -i -e "s/IP/$pub_ip/g" /home/mangos/mangos/sql/base/set_realmlist_public.sql
  mysql -uroot -p${MYSQL_ROOT_PASSWORD} classicrealmd < /home/mangos/mangos/sql/base/set_realmlist_public.sql

  # Creating default gm account (Username: gm PW: password1234) Please change this later.
  mysql -uroot -p${MYSQL_ROOT_PASSWORD} classicrealmd < /home/mangos/mangos/sql/create_gm_account.sql

  # Creating conf files
  mv /home/mangos/mangos/src/mangosd/mangosd.conf.dist.in /home/mangos/run/etc/mangosd.conf
  #sed -i -e 's/127.0.0.1;3306/db;3306/g' /home/mangos/run/etc/mangosd.conf
  sed -i -e 's/DataDir = "."/DataDir = "\/home\/mangos\/run\/"/g' /home/mangos/run/etc/mangosd.conf
  sed -i -e 's/BindIP = \"0.0.0.0\"/BindIP = \"$pub_ip\"/g' /home/mangos/run/etc/mangosd.conf
  mv /home/mangos/mangos/src/realmd/realmd.conf.dist.in /home/mangos/run/etc/realmd.conf
  #sed -i -e 's/127.0.0.1;3306/db;3306/g' /home/mangos/run/etc/realmd.conf
  mv /home/mangos/mangos/src/game/AuctionHouseBot/ahbot.conf.dist.in /home/mangos/run/etc/ahbot.conf
  sed -i -e 's/AuctionHouseBot.Seller.Enabled = 0/AuctionHouseBot.Seller.Enabled = 1/g' /home/mangos/run/etc/ahbot.conf

  # creating an empty file used to check for first run
  touch /home/mangos/run/etc/done_first_run

fi

# Adding mangos lib to LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/home/mangos/run/lib/:$LD_LIBRARY_PATH

# Starting the server
/usr/bin/supervisord
