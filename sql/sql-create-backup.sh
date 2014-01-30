#!/bin/bash

#Requires that the password be put in 4 times.

echo "FLUSH TABLES WITH READ LOCK;" | mysql -u root -p 
echo "SHOW MASTER STATUS;" | mysql -u root -p |tee > /z/tmp/dbdump.master.status
mysqldump -u root -p --master-data --databases  nacaudit nacbuffer nacconfig naceventlog nacradiusaudit nacstatus |pigz -9 >/z/tmp/dbdump.db.gz
echo "UNLOCK TABLES;" |  mysql -u root -p 

