# ThingPark Enterprise on Azure Kubernetes Service
---
## 1. Overview

### 1.1 Licensing
- Before starting to deploy, you must contact Sales to obtain required Licences & Installation ID.

### 1.2. Requirements
#### Workstation

- Linux with bash shell
- `az cli` [Official Installation Note](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed/configured on workstation
- `helm v3.7.1`: [Offical Installation Note](https://helm.sh/docs/intro/install/)
- `kubectl` installed/configured [Offical Installation Note](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) with required cluster/user/context configuration to create/update resources

#### Cloud resources

ThingPark Enterprise OCP deployment have following requirement:

- A **Kubernetes control plan version 1.19+**
- A dedicated node pool based on Virtual machine scale set:
  - Standard_D4s_v4 instances
  - Node Count: 3
  - Deployed on 3 Availability Zones

- Worker nodes for ThingPark Enterprise workload scheduling must be labelled using following commands:

   ```shell
   kubectl label nodes <node1> thingpark.enterprise.actility.com/nodegroup-name=tpe
   kubectl label nodes <node2> thingpark.enterprise.actility.com/nodegroup-name=tpe
   kubectl label nodes <node3> thingpark.enterprise.actility.com/nodegroup-name=tpe
   ```
- A Service Principal allowed to push Blob in a Container. Following informations are will be asked for backup configuration:
  - A SubscriptionID
  - A ClientId
  - A Secret 
  - A TenantID

### 1.3. Additional provisioned resources
#### Cloud resources

Installation processus will provision dynamically following resources:

- `Premium_LRS` block volumes for cloud persistence (local persistence not covered)
- Public IP and inbound Load Balancer

#### Data stack

- The data stack is composed by database & messaging service. 
- Currently, the only supported option to fulfill requirements is to deploy `thingpark-data` helm chart. 
- For Information, appendix provide details about this stack 

#### Infrastructure stack

- Infrastructure stack refer to additional kubernetes operators/controllers required by ThingPark Enterprise deployment. 
- These requirements are fulfilled by thingpark-enterprise-controllers chart. It optionally deploy following third parties:
  - ingress-nginx controller
  - cert manager

### 1.4. Current limitations

- See [Limitations](./limitations.md)

---
## 2. Installation

### STEP 1: Configuration preparation
1. Retrieve configuration bootstrap sample:
```shell 
export CONFIG_REPO_BASEURL=https://github.com/actility/thingpark-enterprise-kubernetes/raw/main
eval $(curl $CONFIG_REPO_BASEURL/VERSIONS)
curl $CONFIG_REPO_BASEURL/samples/values-production.yaml -o custom-values.yaml

```
2. Prepare Helm configuration 
   ```shell   
   # Configure actility helm repository authentication
   helm repo add --username <InstallationID> --password <InstallationID> actility https://repository.next.thingpark.com/charts
   helm repo update
   # Set the deployment namespace as an environment variable
   export NAMESPACE=thingpark-enterprise
   ```
  
3. Prepare your deployment values following guidelines provided in sample values file. Validate configuration consistency using a dry-run:

```shell 
helm upgrade -i --dry-run tpe actility/thingpark-enterprise --version $THINGPARK_ENTERPRISE_VERSION \
-f custom-values.yaml
```

### STEP 2: Data stack deployment

2. Deploy the chart using your customization: 
```shell
helm upgrade -i tpe-data-controllers -n $NAMESPACE --create-namespace  \
   actility/thingpark-data-controllers --version $THINGPARK_DATA_CONTROLLERS_VERSION

helm  upgrade -i tpe-data -n $NAMESPACE \
  actility/thingpark-data --version $THINGPARK_DATA_VERSION \
  -f $CONFIG_REPO_BASEURL/configs/segments/values-s-segment.yaml \
  -f $CONFIG_REPO_BASEURL/configs/distributions/values-azure-aks.yaml \
  -f custom-values.yaml
```

### STEP 3: ThingPark Enterprise deployment
1. Deploy the `thingpark-enterprise-controllers` chart:
```shell
helm upgrade -i tpe-controllers -n $NAMESPACE \
  actility/thingpark-enterprise-controllers --version $THINGPARK_ENTERPRISE_CONTROLLERS_VERSION \
  -f $CONFIG_REPO_BASEURL/configs/segments/values-s-segment.yaml \
  -f custom-values.yaml

```

2. Finally deploy the `thingpark-enterprise` chart using your customization:
```shell
helm upgrade -i tpe --debug --timeout 10m -n $NAMESPACE \
  actility/thingpark-enterprise --version $THINGPARK_ENTERPRISE_VERSION \
  -f $CONFIG_REPO_BASEURL/configs/segments/values-s-segment.yaml \
  -f $CONFIG_REPO_BASEURL/configs/distributions/values-azure-aks.yaml \
  -f custom-values.yaml
```

## 3. Post installation considerations

1. **After** Thingpark Enterprise Helm deployment, Load Balancer ip can be retreive using following command:
```shell
kubectl get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```
2. You **MUST** version controle custom-values.yaml file for disaster recovery


## Additional references

[Cert Manager](https://cert-manager.io/docs/) allow to provision certificates from various providers.

## Appendix

### thingpark-data chart resources
`thingpark-data` Chart deploy following  ThingPark Enterprise  databases requirements as kubernetes workloads

- A MariaDB Galera cluster
- A Kafka cluster
- A MongoDB replicaset

#### SQL Database
- A dedicated MariaDB 10.4.22 Galera cluster 
- An account to create application databases & users

#### Kafka Cluster
- A Kafka 2.8.1 cluster
- Preprovisionned topic with following configurations:

 topicName                | partitions | replicas | retention.ms | segment.bytes
 ---                      | ---        | ---      | ---          | ---
OSS.LRR.v1                | 6          | 2        | 21600000     | 107374182
OSS.DEV.v1                | 6          | 2        | 21600000     | 107374182
OSS.NOTIF.v1              | 6          | 2        | 21600000     | 107374182
OSS.TASK.DEV.v1           | 6          | 2        | 21600000     | 107374182
OSS.TASK.RES.v1           | 6          | 2        | 21600000     | 107374182
AS.TPX.FLOW.v1            | 6          | 2        | 21600000     | 107374182

#### MongoDB 
- MongoDB 4.2 cluster 
- An account to create application collections & users 


