# Backup script for MongoDB
# Deletes old backups after running
# To backup multiple servers, add another set of settings and MongoDump commands

TODAY=`date +"%Y%m%d_%H%M%S"` # todays date Y-M-D
MONGODUMP=/usr/bin/mongodump # Path to mongodump
[ -x "${MONGODUMP}" ] || (echo "${MONGODUMP}" not found or not executable; exit 1)
FIND=/usr/bin/find # Path to find
MONGO_BACKUP=/var/spool/mongobackup # Path to your mongo backup directory
MONGO_BACKUP_TODAY="${MONGO_BACKUP}"/"${TODAY}"/ # Path to the directory per day
DAYS_RETENTION=7 # How many days of backups do you wish to keep

MONGO_HOST='127.0.0.1' # Host
MONGO_PORT=27017 # Port
MONGO_USER='admin' # User with db access
MONGO_PASS='pass' # Password of user
MONGO_DB='db' # Your DB

#RUN MongoDump
${MONGODUMP} -u "${MONGO_USER}" -o "${MONGO_BACKUP_TODAY}" -h "${MONGO_HOST}":"${MONGO_PORT}" -d "${MONGO_DB}" -p "${MONGO_PASS}"

#ARCHIVE FILES
cd "${MONGO_BACKUP_TODAY}"
"${FIND}" ./* -maxdepth 0 -type d -exec echo "Archiving {}" \; -exec tar -czf "{}.tar.gz" "{}" \; -exec rm -rf "{}" \;

# REMOVE old backups based on DAYS_RETENTION
"${FIND}" "${MONGO_BACKUP}" -maxdepth 1 -type d -mtime +"${DAYS_RETENTION}" -exec echo "Removing Directory => {}" \; -exec rm -rf "{}" \;