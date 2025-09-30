# copy this file to configure-env.sh and edit it to set environment variables 
# replace _DB_FQDN_, _DATABASE_NAME_, _USERNAME_, _PASSWORD_ with actual values
# do not check configure-env.sh into source control as it may contain sensitive information

export DB_GEMSTONE_CONNECTION_STRING=server=_DB_FQDN_;database=_DATABASE_NAME_;user=_USERNAME_;password=_PASSWORD_;trustServerCertificate=true;encrypt=true