#!/bin/bash

echo "Starting server"
echo "Waiting on mysql"
while ! mysqladmin ping -uroot -p${MYSQL_ROOT_PASSWORD} --silent; do
  service mysql start
  sleep 10
done

# Creating and Initializing mangos db
mysql -uroot -p${MYSQL_ROOT_PASSWORD} < /home/mangos/mangos/sql/create/db_create_mysql.sql
mysql -uroot -p${MYSQL_ROOT_PASSWORD} classicmangos < /home/mangos/mangos/sql/base/mangos.sql

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
if [ ! -f /home/mangos/mangos/run/etc/done_first_run ]; then
  echo "Running first run scripts"

  # Creating and Initializing realmd and characters
  mysql -uroot -p${MYSQL_ROOT_PASSWORD} classiccharacters < /home/mangos/mangos/sql/base/characters.sql
  mysql -uroot -p${MYSQL_ROOT_PASSWORD} classicrealmd < /home/mangos/mangos/sql/base/realmd.sql

  # Making server public
  pub_ip=$(dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | cut -d'"' -f2)
  sed -i -e "s/IP/$pub_ip/g" /home/mangos/mangos/sql/base/set_realmlist_public.sql
  mysql -uroot -p${MYSQL_ROOT_PASSWORD}  classicrealmd < /home/mangos/mangos/sql/base/set_realmlist_public.sql

  # Creating default gm account (Username: gm PW: password1234) Please change this later.
  mysql -uroot -p${MYSQL_ROOT_PASSWORD}  classicrealmd < /home/mangos/mangos/sql/create_gm_account.sql

  # Creating conf files
  sed -i -e 's/DataDir = "."/DataDir = "\/home\/mangos\/mangos\/run\/"/g' /home/mangos/mangos/run/etc/mangosd.conf
  sed -i -e 's/BindIP = \"0.0.0.0\"/BindIP = \"$pub_ip\"/g' /home/mangos/mangos/run/etc/mangosd.conf

  # creating an empty file used to check for first run
  touch /home/mangos/mangos/run/etc/done_first_run

fi

# Extractor Data
cd /home/mangos/mangos/run
# download data
mkdir Data
cd Data
curl -H "Authorization: Bearer ya29.a0AfH6SMDd3kUeNo1A29OX0NZxHvLuWErMi-V8wrSp-BxEIi9REIKoWehcbj5UmNqb9H0ZwFtYDvQqVGyiJDMih0PxswiVEPhP5f0kDyVBqWb_ck7kz7y24ogGPZT8AgEMUbGy0LUfeinruwyUtkp16Yz-YLm5" https://www.googleapis.com/drive/v3/files/1-WWuPwFiyEQHY4CiPcM29f-FxWiiHIz7?alt=media -o wmo.MPQ
curl -H "Authorization: Bearer ya29.a0AfH6SMDd3kUeNo1A29OX0NZxHvLuWErMi-V8wrSp-BxEIi9REIKoWehcbj5UmNqb9H0ZwFtYDvQqVGyiJDMih0PxswiVEPhP5f0kDyVBqWb_ck7kz7y24ogGPZT8AgEMUbGy0LUfeinruwyUtkp16Yz-YLm5" https://www.googleapis.com/drive/v3/files/1-vHK1QABEmvpuX2xD4c31-Lc6hIpqudg?alt=media -o terrain.MPQ
curl -H "Authorization: Bearer ya29.a0AfH6SMDd3kUeNo1A29OX0NZxHvLuWErMi-V8wrSp-BxEIi9REIKoWehcbj5UmNqb9H0ZwFtYDvQqVGyiJDMih0PxswiVEPhP5f0kDyVBqWb_ck7kz7y24ogGPZT8AgEMUbGy0LUfeinruwyUtkp16Yz-YLm5" https://www.googleapis.com/drive/v3/files/1-wHWuExOnrfzuqwY0uGG9sXjmKOo-pju?alt=media -o texture.MPQ
curl -H "Authorization: Bearer ya29.a0AfH6SMDd3kUeNo1A29OX0NZxHvLuWErMi-V8wrSp-BxEIi9REIKoWehcbj5UmNqb9H0ZwFtYDvQqVGyiJDMih0PxswiVEPhP5f0kDyVBqWb_ck7kz7y24ogGPZT8AgEMUbGy0LUfeinruwyUtkp16Yz-YLm5" https://www.googleapis.com/drive/v3/files/1-svSlaKdU-Y_LuCiF9SduEXvCMZV8nQT?alt=media -o speech.MPQ
curl -H "Authorization: Bearer ya29.a0AfH6SMDd3kUeNo1A29OX0NZxHvLuWErMi-V8wrSp-BxEIi9REIKoWehcbj5UmNqb9H0ZwFtYDvQqVGyiJDMih0PxswiVEPhP5f0kDyVBqWb_ck7kz7y24ogGPZT8AgEMUbGy0LUfeinruwyUtkp16Yz-YLm5" https://www.googleapis.com/drive/v3/files/1-qJD9iyLuQ1mjnC5y7C_iMFM4m0JOYV5?alt=media -o sound.MPQ
curl -H "Authorization: Bearer ya29.a0AfH6SMDd3kUeNo1A29OX0NZxHvLuWErMi-V8wrSp-BxEIi9REIKoWehcbj5UmNqb9H0ZwFtYDvQqVGyiJDMih0PxswiVEPhP5f0kDyVBqWb_ck7kz7y24ogGPZT8AgEMUbGy0LUfeinruwyUtkp16Yz-YLm5" https://www.googleapis.com/drive/v3/files/1-WWuPwFiyEQHY4CiPcM29f-FxWiiHIz7?alt=media -o patch.MPQ
curl -H "Authorization: Bearer ya29.a0AfH6SMDd3kUeNo1A29OX0NZxHvLuWErMi-V8wrSp-BxEIi9REIKoWehcbj5UmNqb9H0ZwFtYDvQqVGyiJDMih0PxswiVEPhP5f0kDyVBqWb_ck7kz7y24ogGPZT8AgEMUbGy0LUfeinruwyUtkp16Yz-YLm5" https://www.googleapis.com/drive/v3/files/1-jnPp1ovaiqzlZBsgwJKEvxU6ePnPE9z?alt=media -o patch-y.MPQ
curl -H "Authorization: Bearer ya29.a0AfH6SMDd3kUeNo1A29OX0NZxHvLuWErMi-V8wrSp-BxEIi9REIKoWehcbj5UmNqb9H0ZwFtYDvQqVGyiJDMih0PxswiVEPhP5f0kDyVBqWb_ck7kz7y24ogGPZT8AgEMUbGy0LUfeinruwyUtkp16Yz-YLm5" https://www.googleapis.com/drive/v3/files/1-pjZcnvqau_KAiCreQJrxEvWcRZCzjkP?alt=media -o patch-z.MPQ
curl -H "Authorization: Bearer ya29.a0AfH6SMDd3kUeNo1A29OX0NZxHvLuWErMi-V8wrSp-BxEIi9REIKoWehcbj5UmNqb9H0ZwFtYDvQqVGyiJDMih0PxswiVEPhP5f0kDyVBqWb_ck7kz7y24ogGPZT8AgEMUbGy0LUfeinruwyUtkp16Yz-YLm5" https://www.googleapis.com/drive/v3/files/1-fCT699TZnc9WvAJ6XdCBLCvi01Tg2kr?alt=media -o patch-2.MPQ
curl -H "Authorization: Bearer ya29.a0AfH6SMDd3kUeNo1A29OX0NZxHvLuWErMi-V8wrSp-BxEIi9REIKoWehcbj5UmNqb9H0ZwFtYDvQqVGyiJDMih0PxswiVEPhP5f0kDyVBqWb_ck7kz7y24ogGPZT8AgEMUbGy0LUfeinruwyUtkp16Yz-YLm5" https://www.googleapis.com/drive/v3/files/1-P59q6TvmVlFftJZF03YrR3Vk_87TFYw?alt=media -o model.MPQ
curl -H "Authorization: Bearer ya29.a0AfH6SMDd3kUeNo1A29OX0NZxHvLuWErMi-V8wrSp-BxEIi9REIKoWehcbj5UmNqb9H0ZwFtYDvQqVGyiJDMih0PxswiVEPhP5f0kDyVBqWb_ck7kz7y24ogGPZT8AgEMUbGy0LUfeinruwyUtkp16Yz-YLm5" https://www.googleapis.com/drive/v3/files/1-SM3KEV7eN36BcAhKDNUcc8Z0BTad4JO?alt=media -o misc.MPQ
curl -H "Authorization: Bearer ya29.a0AfH6SMDd3kUeNo1A29OX0NZxHvLuWErMi-V8wrSp-BxEIi9REIKoWehcbj5UmNqb9H0ZwFtYDvQqVGyiJDMih0PxswiVEPhP5f0kDyVBqWb_ck7kz7y24ogGPZT8AgEMUbGy0LUfeinruwyUtkp16Yz-YLm5" https://www.googleapis.com/drive/v3/files/1-LNg8cAqQSDBrGGwyr4dFPaFBXuNx4Bi?alt=media -o interface.MPQ
curl -H "Authorization: Bearer ya29.a0AfH6SMDd3kUeNo1A29OX0NZxHvLuWErMi-V8wrSp-BxEIi9REIKoWehcbj5UmNqb9H0ZwFtYDvQqVGyiJDMih0PxswiVEPhP5f0kDyVBqWb_ck7kz7y24ogGPZT8AgEMUbGy0LUfeinruwyUtkp16Yz-YLm5" https://www.googleapis.com/drive/v3/files/1-EVQ4weBqHtgxGznlTBvqJFszZlz4tYt?alt=media -o fonts.MPQ
curl -H "Authorization: Bearer ya29.a0AfH6SMDd3kUeNo1A29OX0NZxHvLuWErMi-V8wrSp-BxEIi9REIKoWehcbj5UmNqb9H0ZwFtYDvQqVGyiJDMih0PxswiVEPhP5f0kDyVBqWb_ck7kz7y24ogGPZT8AgEMUbGy0LUfeinruwyUtkp16Yz-YLm5" https://www.googleapis.com/drive/v3/files/1-6hotCEouxGg_AvmXYUUSVLoBungo-tJ?alt=media -o base.MPQ
curl -H "Authorization: Bearer ya29.a0AfH6SMDd3kUeNo1A29OX0NZxHvLuWErMi-V8wrSp-BxEIi9REIKoWehcbj5UmNqb9H0ZwFtYDvQqVGyiJDMih0PxswiVEPhP5f0kDyVBqWb_ck7kz7y24ogGPZT8AgEMUbGy0LUfeinruwyUtkp16Yz-YLm5" https://www.googleapis.com/drive/v3/files/1-AwoGepQp7tKIE1XQonrT3biq6z-G8z7?alt=media -o backup.MPQ
curl -H "Authorization: Bearer ya29.a0AfH6SMDd3kUeNo1A29OX0NZxHvLuWErMi-V8wrSp-BxEIi9REIKoWehcbj5UmNqb9H0ZwFtYDvQqVGyiJDMih0PxswiVEPhP5f0kDyVBqWb_ck7kz7y24ogGPZT8AgEMUbGy0LUfeinruwyUtkp16Yz-YLm5" https://www.googleapis.com/drive/v3/files/1-G9n3A2LhRPs-gIcJVEt1PPaAgTW_jHd?alt=media -o dbc.MPQ
# extract data
cd /home/mangos/mangos/run
cp ./bin/tools/* .
sed -i s/read\ line/line=2/g ./ExtractResources.sh
chmod +x ExtractResources.sh MoveMapGen.sh
./ExtractResources.sh a

# Adding mangos lib to LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/home/mangos/mangos/run/lib/:$LD_LIBRARY_PATH

# Starting the server
/usr/bin/supervisord
