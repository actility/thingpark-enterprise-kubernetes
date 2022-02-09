# ThingPark Enterprise on Azure Kubernetes Service
---
## 1. Overview
### 1.1. Requirements
#### Workstation
- `aws cli` [Official Installation Note](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed/configured on workstation 

#### Cloud resources

ThingPark Enterprise OCP deployment have following requirement:
- A **Kubernetes control plan version 1.19+**
- A dedicated node pool based on Virtual machine scale set:
  - m5.xlarge instances with 40Gi root device volume
  - Node Count: 3
  - Deployed on 3 Availability Zones

- A S3 bucket to store manual,upgrade and scheduled backups. Upgrade backups are mandatory
- To allow backup pull/push to bucket, either:
  - An IAM User authorized to perform get/put to the bucket with an Access key ID/Secret access key
  - EKS Node Group configured to use an IAM role with an attached IAM policy allowed to to perform get/put to the bucket


### 1.2. Additional provisioned resources
#### Cloud resources

Installation process will provision dynamically following resources:

- `gp2` block volumes for cloud persistence 
- Inbound Amazon Network Load Balancer

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
      -f $CONFIG_REPO_BASEURL/configs/distributions/values-amazon-eks.yaml \
      -f custom-values.yaml
    ```
### STEP 2: ThingPark Enterprise deployment
1. Deploy the `thingpark-enterprise-controllers` chart
    ```shell
    helm upgrade -i tpe-controllers -n $NAMESPACE \
      -f $CONFIG_REPO_BASEURL/configs/values.yaml \
      actility/thingpark-enterprise-controllers --version $THINGPARK_ENTERPRISE_CONTROLLERS_VERSION \
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
      -f $CONFIG_REPO_BASEURL/configs/distributions/values-amazon-eks.yaml \
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
    You must resolve the `.Value.global.dnsHostname` provided in the [customized configuration](../../samples/values-production.yaml) to the load balancer ip. [Configuration sample](../../samples/values-production.yaml) show how to configure deployment to use [externalDNS](https://github.com/kubernetes-sigs/external-dns) and dynamically provision a route 53 DNS zone.
  
2. Ensure the custom-values.yaml file is carrefully backuped, for example in a GIT repository. This file is required in case of disastery recovery
