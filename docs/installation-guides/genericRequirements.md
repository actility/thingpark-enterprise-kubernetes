# Kubernetes Requirements
---
## 1. Workstation
Following requirements must be installed on the deployment host:
- Linux with bash shell
- `helm v3.7.1`: [Offical Installation Note](https://helm.sh/docs/intro/install/)
- `kubectl` installed/configured [Offical Installation Note](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) with required cluster/user/context configuration to create/update resources
---
## 2. ThingPark Enterprise OCP platform sizing

### Segments sizing 
Before selecting hosting resources, the next table allow you to select a **ThingPark Enterprise OCP sizing segment** for your IoT deployment (S up to XXL). It gives you the number of base stations and devices, and the LoRaWAN® uplink/downlink traffic rate.

 _  | Small (S)	| Medium (M) | Large (L) | Extra-Large (XL)	| Double-Extra-Large (XXL)
---|---|---|---|---|---
**Base stations**	|	Up to 10 | Up to 50 | Up to 100	| Up to 200	| Up to 1000
**Devices** | Up to 2 000	| Up to 10 000 | Up to 20 000	| Up to 50 000 | Up to 300 000
**Average Traffic Rate** (uplink + downlink) | 0.6 msg/sec | 3 msg/sec| 6 msg/sec	| 15 msg/sec| 90 msg/sec
**Peak Traffic Rate1** | 3 msg/sec | 15 msg/sec	| 30 msg/sec | 60 msg/sec	| 180 msg/sec

### Compute requirements
This table detail required CPU/RAM resources on workers dedicated for ThingPark Enterprise OCP workloads.

 _  | Small (S)	| Medium (M) | Large (L) | Extra-Large (XL)	| Double-Extra-Large (XXL)
---|---|---|---|---|---
**Number of worker** | 3 in 3 Availability Zones | 3 in 3 Availability Zones | 3 in 3 Availability Zones | 3 in 3 Availability Zones | 3 in 3 Availability Zones
**CPU** (Min Allocatable per node)| Under study |Under study|3500m|7500m|31500m
**RAM** (Min Allocatable per node)| Under study |Under study|12,5Gi|27,5Gi|118Gi
Recommended Azure Instances| Under study|Under study| D4sv4 / D4sv5 | D8sv4 / D8sv5 | D32sv4 / D32sv5 
Recommended Amazon Instances|Under study|Under study|m5.xlarge|m5.2xlarge|m5.8xlarge|


### Storage
This section is provided for information and calculate cost in targeted cloud hosting environment. Storage is dynamically provisionned on cloud platform using provided Storage Class

 Cloud  | service |  Small (S)	| Medium (M) | Large (L) | Extra-Large (XL)	| Double-Extra-Large (XXL)
---|---|---|---|---|---|---
 **Azure** | mariadb-galera | 3 x 5Gi Premium SSD LRS	|3 x 5Gi (-)	|3 x 10Gi (-)	| 3 x 15Gi (-)| 3 x 30Gi (-) 
 _ | mongodb | 2 x 10Gi Premium SSD LRS	|2 x 15Gi 	|2  x 25Gi (-)	| 2 x 45Gi (-)| 2 x 1000Gi (-)
 _ | kafka | 2 x 10Gi Premium SSD LRS	|2 x 15Gi (-)	|2  x 20Gi (-)	| 2 x 30Gi (-)| 2 x 40Gi (-)
 _ | lrc | 2 x 5Gi Premium SSD LRS	|2 x 5Gi (-)	|2  x 5Gi (-)	| 2 x 10Gi (-)| 2 x 15Gi (-)
 _ | zookeeper | 6 x 5Gi Premium SSD LRS	|6 x 5Gi (-)	|6 x 5Gi (-)	| 6 x 5Gi (-)| 6 x 5Gi(-)
 _ | lrc-ftp | 2 x 10Gi Standard SSD LRS	|2 x 10Gi (-)	|2  x 10Gi (-)	| 2 x 10Gi (-) | 2 x 10Gi (-)
 _ | node-red | 1 x 10Gi Standard SSD LRS	|1 x 10Gi (-)	|1  x 10Gi (-)	| 1 x 10Gi (-) | 1 x 10Gi (-)
 **Amazon** | mariadb-galera | 3 x 5Gi gp2	|3 x 5Gi (-)	|3 x 10Gi (-)	| 3 x 15Gi (-)| 3 x 30Gi (-) 
 _ | mongodb | 2 x 10Gi  gp2	|2 x 15Gi 	|2  x 25Gi (-)	| 2 x 45Gi (-)| 2 x 365Gi (-)
 _ | kafka | 2 x 10Gi  gp2	|2 x 15Gi (-)	|2  x 20Gi (-)	| 2 x 30Gi (-)| 2 x 40Gi (-)
 _ | lrc | 2 x 5Gi  gp2	|2 x 5Gi (-)	|2  x 5Gi (-)	| 2 x 10Gi (-)| 2 x 15Gi (-)
 _ | zookeeper | 6 x 5Gi  gp2	|6 x 5Gi (-)	|6 x 5Gi (-)	| 6 x 5Gi (-)| 6 x 5Gi(-)
 _ | lrc-ftp | 2 x 10Gi  gp2	|2 x 10Gi (-)	|2  x 10Gi (-)	| 2 x 10Gi (-) | 2 x 10Gi (-)
 _ | node-red | 1 x 10Gi  gp2	|1 x 10Gi (-)	|1  x 10Gi (-)	| 1 x 10Gi (-) | 1 x 10Gi (-)

--- 
## 3. Dedicated node identification

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
## 4. Configuration preparation
1. Retrieve configuration bootstrap sample
    ```shell 
    export CONFIG_REPO_BASEURL=https://raw.githubusercontent.com/actility/thingpark-enterprise-kubernetes/release-1.0
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
    ```
  
3. Prepare your deployment values following guidelines provided in sample values file. Validate configuration consistency using a dry-run
    ```shell 
    helm template tpe actility/thingpark-enterprise --version $THINGPARK_ENTERPRISE_VERSION \
    -f custom-values.yaml
    ```
---
## 5. Next steps
Use the appropriate guide for installation on your distribution:
- [**Azure Kubernetes Service**](./azureKubernetesService.md)
- [**Amazon Elastic Kubernetes Service**](./elasticKubernetesService.md)
