# ThingPark Enterprise on Azure Kubernetes Service
---
## 1. Overview
### 1.1. Requirements
#### Workstation
- `az cli` [Official Installation Note](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed/configured on workstation

#### Cloud resources

ThingPark Enterprise OCP deployment have following requirement:

- A **Kubernetes control plan version 1.19+**
- A dedicated node pool based on Virtual machine scale set:
  - Standard_D4s_v4 instances
  - Node Count: 3
  - Deployed on 3 Availability Zones

- An `Azure Blob Container` with an optional `lifecycle management policy` to manage backup retention

- A `Service Principal` allowed to push Blob to the Container. Following informations are required for backup configuration:
  - A SubscriptionID
  - A ClientId
  - A Secret 
  - A TenantID

### 1.2. Additional provisioned resources
#### Cloud resources

Installation process will provision dynamically following resources:

- `Premium_LRS` block volumes for cloud persistence (local persistence not covered)
- Public IP and inbound Load Balancer

#### Data stack

- The data stack includes database & messaging services required by TPE.
- The only supported option to fulfill these requirements is to deploy `thingpark-data` helm chart.
- Following third parties are used:
  - strimzi/strimzi-kafka-operator
  - percona/percona-server-mongodb-operator
  - bitnami/mariadb-galera

#### Infrastructure stack

- Infrastructure stack refer to additional kubernetes operators/controllers required by ThingPark Enterprise deployment. 
- These requirements are fulfilled by thingpark-enterprise-controllers chart. It optionally deploy following third parties:
  - kubernetes/ingress-nginx
  - cert manager

---
## 2. Installation

### STEP 1: Data stack deployment

1. Deploy the chart using your customization
    ```shell
    helm upgrade -i tpe-data-controllers -n $NAMESPACE --create-namespace  \
      actility/thingpark-data-controllers --version $THINGPARK_DATA_CONTROLLERS_VERSION \
      -f $CONFIG_REPO_BASEURL/configs/values.yaml

    helm  upgrade -i tpe-data -n $NAMESPACE \
      actility/thingpark-data --version $THINGPARK_DATA_VERSION \
      -f $CONFIG_REPO_BASEURL/configs/values.yaml \
      -f $CONFIG_REPO_BASEURL/configs/segments/values-s-segment.yaml \
      -f $CONFIG_REPO_BASEURL/configs/distributions/values-azure-aks.yaml \
      -f custom-values.yaml
    ```
### STEP 2: ThingPark Enterprise deployment
1. Deploy the `thingpark-enterprise-controllers` chart
    ```shell
    helm upgrade -i tpe-controllers -n $NAMESPACE \
      actility/thingpark-enterprise-controllers --version $THINGPARK_ENTERPRISE_CONTROLLERS_VERSION \
      -f $CONFIG_REPO_BASEURL/configs/values.yaml \
      -f $CONFIG_REPO_BASEURL/configs/segments/values-s-segment.yaml \
      -f custom-values.yaml
    ```
2. Wait for all statefulsets and deployments readiness. It can be check in following ways:

    ```shell
    kubectl get -n $NAMESPACE statefulsets.apps,deployments.apps
    kubectl get -n $NAMESPACE -w statefulsets.apps
    ```

3. Finally deploy the `thingpark-enterprise` chart using your customization:
    ```shell
    helm upgrade -i tpe --debug --timeout 10m -n $NAMESPACE \
      actility/thingpark-enterprise --version $THINGPARK_ENTERPRISE_VERSION \
      -f $CONFIG_REPO_BASEURL/configs/values.yaml \
      -f $CONFIG_REPO_BASEURL/configs/segments/values-s-segment.yaml \
      -f $CONFIG_REPO_BASEURL/configs/distributions/values-azure-aks.yaml \
      -f custom-values.yaml
    ```
2. Wait for all statefulsets and deployments readiness:

    ```shell
    kubectl get -n $NAMESPACE statefulsets.apps,deployments.apps
    kubectl get -n $NAMESPACE -w statefulsets.apps
    kubectl get -n $NAMESPACE -w deployments.apps
    ```

## 3. Post installation considerations

1. **After** Thingpark Enterprise Helm deployment, Load Balancer ip can be retreive using following command:
```shell
kubectl get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```
2. Ensure the custom-values.yaml file is carrefully backuped, for example in a GIT repository. This file is required in case of disastery recovery
