#!/bin/sh

gcloud eventarc triggers update trigger-cloudsql-pgaudit \
  --location=europe-west2 \
  --destination-run-service=cloudsql-eventarc \
  --destination-run-region=europe-west2 \
  --destination-run-path=/ \
  --service-account=425411032467-compute@developer.gserviceaccount.com \
  --event-filters=type=google.cloud.audit.log.v1.written \
  --event-filters=serviceName=cloudsql.googleapis.com \
  --event-filters=methodName=cloudsql.instances.query \
  --event-filters=resourceName=instances/chris-sandbox
