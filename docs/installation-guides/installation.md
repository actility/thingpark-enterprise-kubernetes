## Installation Guide
## 1. Requirements
---
### 1.1. Workstation
Following requirements must be installed on the deployment host:
- Linux with bash shell
- `helm v3.7.1`: [Offical Installation Note](https://helm.sh/docs/intro/install/)
- `kubectl` installed/configured [Offical Installation Note](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) with required cluster/user/context configuration to create/update resources
- Admin access to kubernetes control plan, at least for targeted namespace

---
### 1.2. Backup
Depending your hosting, backup requirements are:
- For **Amazon**
  - A `S3 bucket` to store manual,upgrade and scheduled backups. Upgrade backups are mandatory
  - To allow backup pull/push to bucket, either:
    - An `IAM User` authorized to perform get/put to the bucket with an Access key ID/Secret access key
    - EKS Node Group configured to use an `IAM role` with an attached IAM policy allowed to to perform get/put to the bucket

- For **Azure**
  - An `Azure Blob Container` with an optional `lifecycle management policy` to manage backup retention
  - A `Service Principal` allowed to push Blob to the Container. Following informations are required for backup configuration:
    - A SubscriptionID
    - A ClientId
    - A Secret
    - A TenantID

---
### 1.3. Kubernetes Cluster
#### 1.3.1 Control plan
- A Kubernetes control plan version **1.21+**

#### 1.3.2 Dedicated node identification

Worker nodes for ThingPark Enterprise workload must be dedicated using following configuration:
- Add  `thingpark.enterprise.actility.com/nodegroup-name=tpe` label to each one:
  ```shell
  export NODE_SELECTOR_LABEL=thingpark.enterprise.actility.com/nodegroup-name=tpe
  kubectl label nodes <node1> $NODE_SELECTOR_LABEL
  kubectl label nodes <node2> $NODE_SELECTOR_LABEL
  kubectl label nodes <node3> $NODE_SELECTOR_LABEL
  ```
- Add a taint
  ```shell
  kubectl taint nodes <node1> $NODE_SELECTOR_LABEL:NoSchedule
  kubectl taint nodes <node2> $NODE_SELECTOR_LABEL:NoSchedule
  kubectl taint nodes <node3> $NODE_SELECTOR_LABEL:NoSchedule
  ```
---
### 1.4. Configuration preparation
1. Retrieve configuration bootstrap sample
    ```shell 
    export CONFIG_REPO_BASEURL=https://raw.githubusercontent.com/actility/thingpark-enterprise-kubernetes/main
    eval $(curl $CONFIG_REPO_BASEURL/VERSIONS)
    curl $CONFIG_REPO_BASEURL/samples/values-production.yaml -o custom-values.yaml
    ```

2. Prepare Helm configuration 
    ```shell   
    # Configure actility helm repository authentication
    helm repo add --username <InstallationID> --password <InstallationID> actility https://repository.thingpark.com/charts
    helm repo update
    # Set the deployment namespace as an environment variable
    export NAMESPACE=thingpark-enterprise
    # Set the ThingPark segment choosed at capacity planning step
    # Value in s,m,l,xl,xxl
    export SEGMENT=m
    # Set the targeted environment
    # Value azure,amazon
    export HOSTING=azure
    ```
  
3. Prepare your deployment values following guidelines provided in sample values file. Validate configuration consistency using a dry-run
    ```shell 
    helm template tpe actility/thingpark-enterprise --version $THINGPARK_ENTERPRISE_VERSION \
    -f custom-values.yaml
    ```
---
## 2. Installation

## STEP 1: Data stack deployment

1. Deploy the chart using your customization
    ```shell
    helm upgrade -i tpe-data-controllers -n $NAMESPACE --create-namespace  \
      actility/thingpark-data-controllers --version $THINGPARK_DATA_CONTROLLERS_VERSION \
      -f $CONFIG_REPO_BASEURL/configs/values.yaml

    helm  upgrade -i tpe-data -n $NAMESPACE \
      actility/thingpark-data --version $THINGPARK_DATA_VERSION \
      -f $CONFIG_REPO_BASEURL/configs/$HOSTING/values-$SEGMENT-segment.yaml \
      -f custom-values.yaml
    ```
## STEP 2: ThingPark Enterprise deployment
1. Deploy the `thingpark-enterprise-controllers` chart
    ```shell
    helm upgrade -i tpe-controllers -n $NAMESPACE \
      actility/thingpark-enterprise-controllers --version $THINGPARK_ENTERPRISE_CONTROLLERS_VERSION \
      -f $CONFIG_REPO_BASEURL/configs/$HOSTING/values-$SEGMENT-segment.yaml \
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
      -f $CONFIG_REPO_BASEURL/configs/$HOSTING/values-$SEGMENT-segment.yaml \
      -f custom-values.yaml
    ```
2. Wait for all statefulsets and deployments readiness:

    ```shell
    kubectl get -n $NAMESPACE statefulsets.apps,deployments.apps
    kubectl get -n $NAMESPACE -w statefulsets.apps
    kubectl get -n $NAMESPACE -w deployments.apps
    ```

## STEP 3: Post installation considerations

1. **After** Thingpark Enterprise Helm deployment, Load Balancer ip can be retreive using following command:
```shell
kubectl get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```
2. Ensure the custom-values.yaml file is carrefully backuped, for example in a GIT repository. This file is required in case of disastery recovery
