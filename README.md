# MongoDB backups on Google Cloud

Perform backups with retention of your MongoDB databases (running in [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) for example), and store it in [Google Cloud Storage](https://cloud.google.com/storage/).

You can run the backups with [Google Cloud Run](https://cloud.google.com/run/), and schedule it with [Google Cloud Scheduler](https://cloud.google.com/scheduler/).

## How it works

This repo contains a Dockerfile which builds a working image on Google Cloud Run (maybe also on App Engine Flexible or Kubernetes cluster, but not tested). 
The container entrypoint runs a basic Python HTTP server which triggers a Bash backup script. 
The backup script launch `mongodump` utility, makes a `tar.gz` archive and upload it to Google Cloud Storage for every database you want to backup.

## Requirements

To test and deploy, you have to :

* Install [Docker Engine](https://docs.docker.com/install/)
* Install [Google Cloud SDK](https://cloud.google.com/sdk/)
* Create a project on [Google Cloud](https://console.cloud.google.com/project)
* Create a [Google Cloud Storage bucket](https://cloud.google.com/storage/docs/json_api/v1/buckets) for backups storage
* Create a [Google Cloud Service Account](https://cloud.google.com/compute/docs/access/service-accounts) with write access to the Google Cloud Storage bucket
* [Create a key for this Service Account](https://cloud.google.com/docs/authentication/production), and save credentials locally as a JSON file 

## Testing

Before deploying on Google Cloud Run, you should test it, and maybe modify scripts to fit your needs.

First, build the Docker image :
```
docker build -t gcp-mongo-backups .
```
Then you have to set environment variables for the container. You can copy and edit the content of `env-variables.samples` repo file in a new file called `.env`. 

For GCLOUD_KEY_FILE variable, you have to encode your service account's JSON credentials as base64 :
```
base64 -w 0 your_key_file.json
```

Then you can run the container with :
```
docker run --env-file .env -p 127.0.0.1:8080:8080 gcp-mongo-backups
```
Finally, test the backup :
```
curl http://localhost:8080
```

After that, you should see in Google Cloud Storage console one `database-AAAA-MM-DD-HH-MM.tar.gz` file per database.

## Deploy backups with Google Cloud Run & Google Cloud Scheduler

Now you have a working container, you can push it to [Google's Container Registry](https://cloud.google.com/container-registry/) :
```
# Configure Google's Container registry locally
gcloud auth configure-docker
# Tag local Docker image for registry
docker tag gcp-mongo-backups gcr.io/[YOUR-PROJECT-ID]/mongo-backups
# Push it on Google's Container Registry
docker push gcr.io/[YOUR-PROJECT-ID]/mongo-backups
```

Then, deploy it on [Cloud Run](https://cloud.google.com/run/docs/quickstarts/build-and-deploy) :
```
# Here I use Cloud Run managed platform. Fit it to your needs if you want to run it on GKE for example.
gcloud beta run deploy mongo-backups --image gcr.io/[YOUR-PROJECT-ID]/mongo-backups --port=8080 --memory 128Mi --concurrency=1 --platform=managed --no-allow-unauthenticated --service-account=[YOUR-SERVICE-ACCOUNT-EMAIL] --set-env-vars="RETENTION_DAYS=30,MONGO_DBNAMES=db1;db2,MONGO_URI='mongodb+srv://user:password@mongodb.example.com',GCLOUD_KEY_FILE=base64key,GCLOUD_PROJECT_ID=your-project-id,GCLOUD_BUCKET_NAME=your-bucket-name"
```

Now you can perform backups with an URL call. We can schedule it daily with [Scheduler](https://cloud.google.com/scheduler/docs/creating). Here is an example *without* authentication :
```
# Run backups every days at 2AM
gcloud scheduler jobs create http mongo-backups-task --schedule "0 2 * * *" --uri "[YOUR-CLOUD-RUN-SERVICE-URL]" --http-method GET
```
If you want to use authentication (it's better) with Cloud Run & Cloud Scheduler, I recommend to use [the console](https://console.cloud.google.com/cloudscheduler/jobs/new) for task creation instead. Here, you can specify that you want OIDC token in headers, with a service account's email which has rights to run your Cloud Run service.