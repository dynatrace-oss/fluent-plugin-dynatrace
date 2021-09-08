
# FluentD to AG Log Ingest

It is possible to have FluentD ingest the logs of your kubernetes nodes and let FluentD send the resulting logs to your ActiveGate. See below for instructions.
## Prerequisites

- Create a [PaaS Token](https://www.dynatrace.com/support/help/get-started/access-tokens/)
- Create an [API Token](https://www.dynatrace.com/support/help/dynatrace-api/basics/dynatrace-api-authentication/) with "Ingest logs" permission

## Build FluentD docker image

Build the FluentD docker image provided in our example and upload it to your repository. **Depending on the applications running on your cluster you might need to add plugins.**

## Deploy ActiveGate

1. Create a dedicated namespace, if you do not already have one.

   ``kubectl create namespace dynatrace``

2. Create a service account and cluster role for accessing the Kubernetes API. 

   ``kubectl apply -f https://www.dynatrace.com/support/help/codefiles/kubernetes/kubernetes-monitoring-service-account.yaml``

3. Create a secret holding the environment URL and login credentials for this registry, making sure to replace.

   * ${YOUR_ENVIRONMENT_URL} with your environment URL (without 'http'). Example: environment.live.dynatrace.com
   * ${YOUR_ENVIRONMENT_ID} with the ID in your environment URL
   * ${YOUR_PAAS_TOKEN} with the PaaS token you created in Prerequisites

   ``kubectl create secret docker-registry dynatrace-docker-registry --docker-server=${YOUR_ENVIRONMENT_URL} --docker-username=${YOUR_ENVIRONMENT_ID} --docker-password=${YOUR_PAAS_TOKEN} -n dynatrace``

4. Edit the file named configmap.yaml, making sure to replace
   * ${YOUR_ENVIRONMENT_ID} with the ID in your environment URL.
   * ${YOUR_CLUSTER_ID} with your cluster id.
    
     ``kubectl get namespace kube-system  -o jsonpath='{.metadata.uid}'``
   
   * fluent.conf with an configuration suiting your environment. Our example is using the kubernetes-metadata-filter to enrich ingested log lines with information about its underlying kubernetes infrastructure. **Depending on the applications on your cluster you might need to manually modify the fluent.conf.**

5. Edit the file named activegate.yaml, making sure to replace.
   * ${YOUR_ENVIRONMENT_URL} with your environment URL (without 'http'). Example: environment.live.dynatrace.com

6. Deploy ActiveGate

   ``kubectl apply -f activegate.yaml``

## Deploy FluentD 

1. Create a secret with your API Token. Make sure to replace ${YOUR_AG_INGEST_TOKEN} with the API Token that has log ingest permissions.

   ``kubectl create secret generic tokens --from-literal="log-ingest=${YOUR_AG_INGEST_TOKEN}" -n dynatrace``

2. Replace ${YOUR_FLUENTD_IMAGE} with the fluentd image you built 

3. Deploy fluentd.yaml

   ``kubectl apply -f fluentd.yaml``

##  Connect your Kubernetes clusters to Dynatrace 
To get native Kubernetes metrics, you need to connect the Kubernetes API to Dynatrace.

1. Get the Kubernetes API URL.

   ``kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'``

2. Get the bearer token from the dynatrace-monitoring service account.

   ``kubectl get secret $(kubectl get sa dynatrace-monitoring -o jsonpath='{.secrets[0].name}' -n dynatrace) -o jsonpath='{.data.token}' -n dynatrace | base64 --decode ``

3. In the Dynatrace menu, go to Settings > Cloud and virtualization > Kubernetes, and select Connect new cluster.

4. Provide a Name, Kubernetes API URL, and the Bearer token for the Kubernetes cluster.
Note: For Rancher distributions, you need the bearer token that was created in Rancher web UI, as described in Special instructions for Rancher distributions above. 
Once you connect your Kubernetes clusters to Dynatrace, you can get native Kubernetes metrics, like request limits, and differences in pods requested vs. running pods.