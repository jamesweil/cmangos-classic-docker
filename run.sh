#!/bin/bash

echo "Starting server"
echo "Waiting on mysql"
while ! mysqladmin ping  --silent; do
  service mysql start
  sleep 10
done

# Creating and Initializing mangos db
mysql -uroot -p < mangos/sql/create/db_create_mysql.sql
mysql -uroot -p classicmangos < mangos/sql/base/mangos.sql

# Installing classicdb
cd /home/mangos/classic-db

./InstallFullDB.sh 

# Running it once to generate the config
sed -i -e 's/CORE_PATH=""/CORE_PATH="\/home\/mangos\/mangos"/g' InstallFullDB.config
cat InstallFullDB.config

./InstallFullDB.sh
if [[ $? != 0 ]]; then echo "Error Installing classicdb. Exiting.."; exit 1; fi
echo "classicdb installed"

# Executing first run
if [ ! -f /home/mangos/run/etc/done_first_run ]; then
  echo "Running first run scripts"

  # Creating and Initializing realmd and characters
  mysql -uroot -p classiccharacters < mangos/sql/base/characters.sql
  mysql -uroot -p classicrealmd < mangos/sql/base/realmd.sql

  # Making server public
  pub_ip=$(dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | cut -d'"' -f2)
  sed -i -e "s/IP/$pub_ip/g" /home/mangos/mangos/sql/base/set_realmlist_public.sql
  mysql -uroot -p  classicrealmd < /home/mangos/mangos/sql/base/set_realmlist_public.sql

  # Creating default gm account (Username: gm PW: password1234) Please change this later.
  mysql -uroot -p  classicrealmd < /home/mangos/mangos/sql/create_gm_account.sql

  # Creating conf files
  sed -i -e 's/DataDir = "."/DataDir = "\/home\/mangos\/run\/"/g' /home/mangos/run/etc/mangosd.conf
  sed -i -e 's/BindIP = \"0.0.0.0\"/BindIP = \"$pub_ip\"/g' /home/mangos/run/etc/mangosd.conf

  # creating an empty file used to check for first run
  touch /home/mangos/run/etc/done_first_run

fi

# Adding mangos lib to LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/home/mangos/run/lib/:$LD_LIBRARY_PATH

# Starting the server
/usr/bin/supervisord
