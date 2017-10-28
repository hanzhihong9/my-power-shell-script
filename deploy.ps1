# before start
# run this from PS shell  : 'Set-ExecutionPolicy -Scope CurrentUser'
#                           'set-executionpolicy unrestricted'
#                           'Set-ExecutionPolicy RemoteSigned'

$mySQLDBInstanceIdentifier = "mysql-db-instance-test100"


### get config file from S3
echo  '----- get config file from S3'
$mysql_cfg_file_name = "mysql_cfg.json"
aws s3 cp s3://hanzhihong2/mysql/mysql_cfg.json $mysql_cfg_file_name
$mySQLCfgObject = Get-Content $mysql_cfg_file_name | Out-String | ConvertFrom-Json

echo $mySQLCfgObject.db_name
echo $mySQLCfgObject.password
echo $mySQLCfgObject.user_name

### create mysql db
#### Create a security-groups manually  for MySQL TCP port 3306 and user defual (sg-bf46c9d7)

echo  '----- create mysql db'

$createdMySQLInstance_output = & aws rds create-db-instance --db-instance-identifier $mySQLDBInstanceIdentifier `
 --allocated-storage 5 `
 --db-instance-class db.t2.micro `
 --engine mysql `
 --master-username $mySQLCfgObject.user_name `
 --master-user-password $mySQLCfgObject.password
 ## TODO not clear how to add security-groups for now ?? --db-security-groups sg-bf46c9d7, Do it mannally during the waiting ..


echo $createdMySQLInstance_output

### wait for db instance ready  -- should have a better way
echo  '----- wait  for db instance ready'
Start-Sleep -s 600

### get db instance endpoint address
$mySQLInstance_desc = & aws rds describe-db-instances --db-instance-identifier $mySQLDBInstanceIdentifier
echo $mySQLInstance_desc


$mySQLInstance_desc_JsonObj =  $mySQLInstance_desc | ConvertFrom-Json
echo $mySQLInstance_desc_JsonObj
echo ' ---- db instance address is'  $mySQLInstance_desc_JsonObj.DBInstances[0].Endpoint.Address

$mySQLInstance_address =  $mySQLInstance_desc_JsonObj.DBInstances[0].Endpoint.Address

##shoud creat other users other than root, but here I just use 'root'
$mysqlsh_exe = "./mysqlsh/bin/mysqlsh.exe"

$new_db_name = $mySQLCfgObject.db_name
$db_user_name = $mySQLCfgObject.user_name
$db_user_password = $mySQLCfgObject.password
$mysql_instance_uri = $db_user_name + ":" + $db_user_password + "@" +  $mySQLInstance_address

echo ("---- create a database " + $new_db_name +  " at " + $mySQLInstance_address)

#echo $mysql_instance_uri

$create_db_script = "create database "+$new_db_name+";"
echo $create_db_script

#$new_db_name = "blog"
#$db_user_name = "root"
#$db_user_password = "hanzhihong2"
#$mySQLInstance_address = "mysql-db-instance-test10.csndk189qm1y.us-east-2.rds.amazonaws.com"
#$mysql_instance_uri = $db_user_name + ":" + $db_user_password + "@" +  $mySQLInstance_address
echo $mysql_instance_uri

echo $create_db_script |  ./mysqlsh/bin/mysqlsh.exe --sql --uri $mysql_instance_uri

echo " ------ cleanning ------"
echo ("-- clean file : "  + $mysql_cfg_file_name )
rm $mysql_cfg_file_name
