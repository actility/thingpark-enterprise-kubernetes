# Observability

## Thingpark enterprise monitoring

The overall health of ThingPark Enterprise can be measured by choosing a [Client Library](https://kubernetes.io/docs/reference/using-api/client-libraries/) to poll each next API items:

1. Network server disruption tolerance is defined in `lrc` [Pod disruption budgets](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/#pod-disruption-budgets) in order to protect service from volontary disruptions. Check that  `status.currentHealthy >= 1` using either:
   - a polling on  `apis/policy/v1beta1/namespaces/<namespace>/poddisruptionbudgets/lrc`  
   - watching `apis/policy/v1beta1/watch/namespaces/<namespace>/poddisruptionbudgets/lrc` events object.

2. Smp is healthful when `status.availableReplicas >= 1 ` using either:
   - a polling on  `apis/apps/v1/namespaces/<namespace>/deployments/smp-tpe`
   - watching `apis/apps/v1/watch/namespaces/<namespace>/deployments/smp-tpe`events object.

3. Twa is healthful when `status.availableReplicas >= 1 ` using either:
   - a polling on  `apis/apps/v1/namespaces/<namespace>/deployments/twa`
   - watching `apis/apps/v1/watch/namespaces/<namespace>/deployments/twa`events object.

## Tooling 

### Kubernetes dashboard

1.  Prepare a custom values file:

   ```shell
   export DASHBOARD_FQDN=<fqdn>
   export CERT_ISSUER=<selfsigned-issuer or letsencrypt-prod>
   cat scripts/dashboard/dashboard-values.yaml | envsubst > dashboard-values.yaml
   ```

2.  Deploy the chart:

   ```shell
   helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
   helm upgrade -i tpe-dashboard kubernetes-dashboard/kubernetes-dashboard -f dashboard-values.yaml
   ```

3.  Create a service account to retrieve its token 

   ```shell
   kubectl apply -f scripts/dashboard/tpe-dashboard-user.yml

   kubectl -n thingpark-enterprise get secret $(kubectl -n thingpark-enterprise get secret | grep tpe-admin-user | awk '{print $1}') -o "jsonpath={.data.token}"|base64 -d

   ```

4.  Browse to the Kubernetes dashboard webui and use a token to authenticate

### Lens

[Lens IDE](https://k8slens.dev/) is a usefull client side tool to manage kubernetes applications.
