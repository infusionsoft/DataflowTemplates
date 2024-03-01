# Flagship Events Dataflow Job

## Build and Deploy

In order to have the Conscrypt jar packaged you will need to build the Uber Jar first
```sh
mvn clean package
```

Then you can deploy to a given environment by calling the deploy script with one of `intg`, `stge` or `prod`:
```sh
./bin/deploy-flagship-events.sh --env {env}
```

## Testing Changes

To test changes:

1. Deploy the Dataflow to intg as detailed above
2. Validate
  * Perform an API call to an integration tenant
```
curl --location 'https://api-intg.infusiontest.com/crm/rest/v2/contacts' \
     --header 'Content-Type: application/json' \
     --header 'X-Keap-API-Key: {insert PAT}'
```
  * Determine that the call is processed through the [Dataflow job](https://console.cloud.google.com/dataflow/jobs?project=is-events-dataflow-intg)
  * Validate expected results in [BigQuery api_call_made table](https://console.cloud.google.com/bigquery?project=is-events-dataflow-intg&ws=!1m5!1m4!4m3!1sis-events-dataflow-intg!2scrm_prod!3sapi_call_made):

```
SELECT * FROM `is-events-dataflow-intg.crm_prod.api_call_made`
WHERE TIMESTAMP_TRUNC(_PARTITIONTIME, DAY) =
TIMESTAMP(TIMESTAMP_TRUNC(CURRENT_DATE("MST"), DAY)) LIMIT 100
```

3. Shut down Dataflow in integration to prevent resource consumption
