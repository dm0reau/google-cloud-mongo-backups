#!/bin/sh

# Backup directory
BACKUPS_DIR="/backups/$MONGO_DBNAME"
TIMESTAMP=`date +%F-%H%M`
BACKUP_NAME="$MONGO_DBNAME-$TIMESTAMP"

echo "Performing backup of $MONGO_DBNAME"
echo "--------------------------------------------"
# Create backup directory
if ! mkdir -p $BACKUPS_DIR; then
  echo "Can't create backup directory in $BACKUPS_DIR. Go and fix it!" 1>&2
  exit 1;
fi;
# Create dump
mongodump --uri="${MONGO_URI}"
du -hs dump
# Rename dump
mv dump $BACKUP_NAME
# Compress backup
tar -czvf $BACKUPS_DIR/$BACKUP_NAME.tar.gz $BACKUP_NAME
# Delete uncompressed backup
rm -rf $BACKUP_NAME
# TODO Delete backups older than retention period
echo "--------------------------------------------"
echo "Database backup complete!"
