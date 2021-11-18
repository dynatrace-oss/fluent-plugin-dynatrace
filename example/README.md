# FluentD to Dynatrace Log Ingest

It is possible to have FluentD ingest the logs of your kubernetes nodes and let FluentD send the resulting logs to your Dynatrace environment. See below for instructions.

## Prerequisites

Generally needed:

- A Dynatrace namespace, if you do not already have one
- An [API Token](https://www.dynatrace.com/support/help/dynatrace-api/basics/dynatrace-api-authentication/) with "Ingest logs" permission
- The dynatrace-monitoring service-account

   ``kubectl apply -f service-account.yaml``

Only needed in combination with a Dynatrace ActiveGate:

- A [PaaS Token](https://www.dynatrace.com/support/help/get-started/access-tokens/)
- Available persistent storage in your Kubernetes cluster

## Decide on a log ingest endpoint

You have two options when choosing the endpoint fluentd sends your log to.
This is either an ActiveGate, which might already exist in your environment or a pre-existing log ingest on your SaaS Dynatrace environment.

### Option 1: Deploy an ActiveGate

1. Create a secret holding the environment URL and login credentials for this registry, making sure to replace

   - `${YOUR_ENVIRONMENT_URL}` with your environment URL without 'https' (e.g., `env123456.live.dynatrace.com`)
   - `${YOUR_ENVIRONMENT_ID}` with the ID of your environment (e.g., `env123456`)
   - `${YOUR_PAAS_TOKEN}` with the PaaS token you created as described in the Prerequisites

   ``kubectl create secret docker-registry tenant-docker-registry --docker-server=${YOUR_ENVIRONMENT_URL} --docker-username=${YOUR_ENVIRONMENT_ID} --docker-password=${YOUR_PAAS_TOKEN} -n dynatrace``

2. Edit the file named `configmap-activegate.yaml`, making sure to replace
   - `${YOUR_ENVIRONMENT_ID}` with the ID of your environment (e.g., `env123456`)
   - `${YOUR_CLUSTER_ID}` with your Kubernetes Cluster ID which can be retrieved using this command:

     ``kubectl get namespace kube-system  -o jsonpath='{.metadata.uid}'``

   - your `fluent.conf` file with a configuration suiting your environment. Our example is using the kubernetes-metadata-filter to enrich ingested log lines with information about its underlying kubernetes infrastructure. **Depending on the applications on your cluster you might need to manually modify the `fluent.conf` file.**

3. Edit the file named `activegate.yaml`, making sure to replace
   - `${YOUR_ENVIRONMENT_URL}` with your environment URL (without 'https' (e.g., `env123456.live.dynatrace.com`)

4. That same `activegate.yaml` also deploys a persistent volume to queue log entries that were not pushed to Dynatrace yet. Make sure you have a persistent volume or storage class readily available.

5. Deploy Configmap and ActiveGate

   ``kubectl apply -f activegate.yaml configmap-activegate.yaml``

### Option 2: Use the log ingest of your managed SaaS Dynatrace environment

Not only your ActiveGate presents an endpoint, but also your Dynatrace environment is able to ingest logs directly.

1. Edit the file named `configmap-saas.yaml`, making sure to replace
   - `${YOUR_ENVIRONMENT_ID}` with the ID of your environment (e.g., `env123456`)
   - `${YOUR_CLUSTER_ID}` with your Kubernetes Cluster ID which can be retrieved using this command:

     ``kubectl get namespace kube-system  -o jsonpath='{.metadata.uid}'``

   - your `fluent.conf` file with a configuration suiting your environment. Our example is using the kubernetes-metadata-filter to enrich ingested log lines with information about its underlying kubernetes infrastructure. **Depending on the applications on your cluster you might need to manually modify the `fluent.conf` file.**

2. Deploy Configmap and ActiveGate

   ``kubectl apply -f configmap-saas.yaml``

## Build FluentD docker image

Build the FluentD docker image provided in our example and upload it to your repository. **Depending on the applications running on your cluster you might need to add plugins.**

## Deploy FluentD

1. Create a secret with your Dynatrace API Token. Make sure to replace `${YOUR_API_TOKEN}` with the API Token that has log ingest permissions.

   ``kubectl create secret generic tokens --from-literal="log-ingest=${YOUR_API_TOKEN}" -n dynatrace``

2. Replace `${YOUR_FLUENTD_IMAGE}` in `fluentd.yaml` with the fluentd image you built

3. Deploy `fluentd.yaml`

   ``kubectl apply -f fluentd.yaml``
