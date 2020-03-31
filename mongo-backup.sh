#!/bin/sh

DATE_FORMAT="+%F-%H%M"
TIMESTAMP=`date $DATE_FORMAT`
OLD_BACKUP_TIMESTAMP=`date --date="${RETENTION_DAYS} days ago" $DATE_FORMAT`
BACKUP_NAME="$MONGO_DBNAME-$TIMESTAMP"
OLD_BACKUP_NAME="$MONGO_DBNAME-$OLD_BACKUP_TIMESTAMP"
BACKUP_ARCHIVE_NAME=$BACKUP_NAME.tar.gz
GCLOUD_CONFIG_FILE_PATH="/root/.config/gcloud/configurations/config_default"
GCLOUD_KEY_FILE_PATH="key_file.json"

if ! `grep -Fxq project $GCLOUD_CONFIG_FILE_PATH`;then
  echo "Configuring Google Cloud SDK"
  echo -n $GCLOUD_KEY_FILE | base64 -d > $GCLOUD_KEY_FILE_PATH
  gcloud auth activate-service-account --key-file=$GCLOUD_KEY_FILE_PATH
  gcloud config set project $GCLOUD_PROJECT_ID
  rm $GCLOUD_KEY_FILE_PATH
fi

echo "Performing backup of $MONGO_DBNAME"
# Create dump
mongodump --uri="${MONGO_URI}"
# Rename dump
mv dump $BACKUP_NAME
# Compress backup
tar -czvf $BACKUP_ARCHIVE_NAME $BACKUP_NAME
# Upload archive to Google Cloud
echo "Uploading gs://$GCLOUD_BUCKET_NAME/$OLD_BACKUP_NAME"
gsutil cp $BACKUP_ARCHIVE_NAME gs://$GCLOUD_BUCKET_NAME
# Delete backup files
rm -rf $BACKUP_NAME $BACKUP_ARCHIVE_NAME
# Delete backups older than retention period on Google Cloud
if `gsutil -q stat gs://$GCLOUD_BUCKET_NAME/$OLD_BACKUP_NAME`;then
  echo "Deleting gs://$GCLOUD_BUCKET_NAME/$OLD_BACKUP_NAME"
  gsutil rm gs://$GCLOUD_BUCKET_NAME/$OLD_BACKUP_NAME
fi
echo "Database backup complete!"