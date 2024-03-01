# Keap DataflowTemplates Fork

## Keap Dataflows

See individual Dataflow readme files for details:

* [flagship-events](v2/flagship-events/README.md) - PubSub to Bigquery pipe for events from Core

## Testing Changes

If a change only applies to the v1 branch then testing and redeployment is not currently necessary.  We most frequently see this in PDS or Dependabot tickets for legacy dependencies.

To test changes for a v2 Dataflow:

1. Deploy the Dataflow to Intg with appropriate script
2. Validate
3. Shut down Dataflow in Intg to prevent resource consumption