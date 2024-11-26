# Flagship Events Dataflow Job

## Build and Deploy

Java 17

### DataflowTemplates Version

The version is pulled from the release tag specified in `DATAFLOW_RELEASE_TAG` at build time.

### Add Modules

To add new modules, create a subdirectory in the `/v2` hierarchy.

### Deploy

Then you can deploy to a given environment by calling the deploy script with one of "intg", "stge" or "prod":
```sh
./bin/deploy-flagship-events.sh --env {env}
```

The first time you build this project (or any time you need to add `--clean` to 
the parameters due to changing `DATAFLOW_RELEASE_TAG`) an uber-jar will be built 
which can take a very long time.  Subsequent builds will be very fast, comparatively.

### Validate

You can watch records being added to the BigQuery table in each environment as API calls are made:

* [Intg](https://console.cloud.google.com/bigquery?walkthrough_id=dataflow_index&project=is-events-dataflow-intg&ws=!1m5!1m4!4m3!1sis-events-dataflow-prod!2scrm_prod!3sapi_call_made)
* [Stge](https://console.cloud.google.com/bigquery?walkthrough_id=dataflow_index&project=is-events-dataflow-stge&ws=!1m5!1m4!4m3!1sis-events-dataflow-prod!2scrm_prod!3sapi_call_made)
* [Prod](https://console.cloud.google.com/bigquery?walkthrough_id=dataflow_index&project=is-events-dataflow-prod&ws=!1m5!1m4!4m3!1sis-events-dataflow-prod!2scrm_prod!3sapi_call_made)

Once validated in Intg or Stge "Stop" and "Cancel" the job so as to not consume extra resources:

* [Intg](https://console.cloud.google.com/dataflow/jobs?project=is-events-dataflow-intg&walkthrough_id=dataflow_index)
* [Stge](https://console.cloud.google.com/dataflow/jobs?project=is-events-dataflow-stge&walkthrough_id=dataflow_index)

Once deployed to Prod "Stop" and "Drain" the previous job:

* [Prod](https://console.cloud.google.com/dataflow/jobs?project=is-events-dataflow-prod&walkthrough_id=dataflow_index)
