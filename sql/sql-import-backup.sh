#!/bin/bash

#
# Quickie example on how to import the database for replication
#

REP_MASTER='master.hostname'
REP_USER='replication'
REP_PASS='somepassword'
REP_FILE=mysql-bin-slave.00000x	
REP_POS=9999999

MYSQL_USER='local.mysql.user'
MYSQL_PASS='someotherpassword'
INPUT_FILE='/tmp/dbdump.db.gz'

echo "SLAVE STOP;"
echo "SLAVE STOP;" | mysql -u $MYSQL_USER --password=$MYSQL_PASS 

echo "RESET SLAVE;"
echo "RESET SLAVE;" | mysql -u $MYSQL_USER --password=$MYSQL_PASS 

echo Import Base MySQL 
pigz -dc $INPUT_FILE | mysql -u $MYSQL_USER --password=$MYSQL_PASS 

echo " 
CHANGE MASTER TO MASTER_HOST='$REP_MASTER',
MASTER_USER='$REP_USER', 
MASTER_PASSWORD='$REP_PASS', 
MASTER_LOG_FILE='$REP_FILE', 
MASTER_LOG_POS=$REP_POS;
START SLAVE;
SHOW SLAVE STATUS;
"

echo " 
CHANGE MASTER TO MASTER_HOST='$REP_MASTER',
MASTER_USER='$REP_USER', 
MASTER_PASSWORD='$REP_PASS', 
MASTER_LOG_FILE='$REP_FILE', 
MASTER_LOG_POS=$REP_POS;
START SLAVE;
SHOW SLAVE STATUS;
"| mysql -u $MYSQL_USER --password=$MYSQL_PASS


