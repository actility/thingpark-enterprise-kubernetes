# Planning installation
## 1. Supported Kubernetes Services
ThingPark Enterprise OCP over Kubernetes requires a control plan version **1.21+** exposed by following provider:
- **Azure Kubernetes Service**
- **Amazon Elastic Kubernetes Service**


## 2. Platform sizing

### 2.1. Capacity planning
Before selecting hosting resources, the next table allow you to select a **ThingPark Enterprise OCP sizing segment** for your IoT deployment (S up to XXL). It gives you the number of base stations and devices, and the LoRaWAN® uplink/downlink traffic rate.

 _  | Small (S)	| Medium (M) | Large (L) | Extra-Large (XL)	| Double-Extra-Large (XXL)
---|---|---|---|---|---
**Base stations**	|	Up to 10 | Up to 50 | Up to 100	| Up to 200	| Up to 1000
**Devices** | Up to 2 000	| Up to 10 000 | Up to 20 000	| Up to 50 000 | Up to 300 000
**Average Traffic Rate** (uplink + downlink) | 0.6 msg/sec | 3 msg/sec| 6 msg/sec	| 15 msg/sec| 90 msg/sec
**Peak Traffic Rate1** | 3 msg/sec | 15 msg/sec	| 30 msg/sec | 60 msg/sec	| 180 msg/sec

### 2.2. Compute requirements
This table details required CPU/RAM resources on workers dedicated for ThingPark Enterprise OCP workloads.

 _  | Small (S)	| Medium (M) | Large (L) | Extra-Large (XL)	| Double-Extra-Large (XXL)
---|---|---|---|---|---
**Number of worker** | 3 in 3 Availability Zones | 3 in 3 Availability Zones | 3 in 3 Availability Zones | 3 in 3 Availability Zones | 3 in 3 Availability Zones
**CPU** (Min Allocatable per node)| Under study |Under study|3500m|7500m|31500m
**RAM** (Min Allocatable per node)| Under study |Under study|12,5Gi|27,5Gi|118Gi
Recommended Azure Instances| Under study|Under study| D4sv4 / D4sv5 | D8sv4 / D8sv5 | D32sv4 / D32sv5 
Recommended Amazon Instances|Under study|Under study|m5.xlarge|m5.2xlarge|m5.8xlarge|


### 2.3. Storage
This section is provided for information to calculate cost in targeted cloud hosting environment. Storage is dynamically provisionned on cloud platform using provided Storage Class

 Cloud  | service |  Small (S)	| Medium (M) | Large (L) | Extra-Large (XL)	| Double-Extra-Large (XXL)
---|---|---|---|---|---|---
 **Azure** | mariadb-galera | 3 x 5Gi (1) |3 x 5Gi (1) |3 x 10Gi (1) | 3 x 15Gi (1) | 3 x 30Gi (1)
 _ | mongodb | 2 x 10Gi (1)	|2 x 15Gi (1)	|2  x 25Gi (1)	| 2 x 45Gi (1) | 2 x 1000Gi (1)
 _ | kafka | 2 x 10Gi (1)	|2 x 15Gi (1)	|2  x 20Gi (1) | 2 x 30Gi (1) | 2 x 40Gi (1)
 _ | lrc | 2 x 5Gi (1)	|2 x 5Gi (1)	|2  x 5Gi (1) | 2 x 10Gi (1) | 2 x 15Gi (1)
 _ | zookeeper | 6 x 5Gi (1)	| 6 x 5Gi (1) |6 x 5Gi (1) | 6 x 5Gi (1) | 6 x 5Gi (1)
 _ | lrc-ftp | 2 x 10Gi (2)	| 2 x 10Gi (2) |2  x 10Gi (2) | 2 x 10Gi (2) | 2 x 10Gi (2)
 _ | node-red | 1 x 10Gi (2) | 1 x 10Gi (2)	|1  x 10Gi (2) | 1 x 10Gi (2) | 1 x 10Gi (2)
 **Amazon** | mariadb-galera | 3 x 5Gi (3) |3 x 5Gi ((3) | 3 x 10Gi (3) | 3 x 15Gi (3)| 3 x 30Gi (3) 
 _ | mongodb | 2 x 10Gi  (3)	|2 x 15Gi 	| 2  x 25Gi (3) | 2 x 45Gi (3) | 2 x 365Gi (3)
 _ | kafka | 2 x 10Gi  (3)	| 2 x 15Gi (3) | 2  x 20Gi (3) | 2 x 30Gi (3) | 2 x 40Gi (3)
 _ | lrc | 2 x 5Gi  (3)	| 2 x 5Gi (3) |2  x 5Gi (3)	| 2 x 10Gi (3) | 2 x 15Gi (3)
 _ | zookeeper | 6 x 5Gi  (3)	| 6 x 5Gi (3) | 6 x 5Gi (3)	| 6 x 5Gi (3) | 6 x 5Gi (3)
 _ | lrc-ftp | 2 x 10Gi  (3)	| 2 x 10Gi (3) | 2  x 10Gi (3) | 2 x 10Gi (3) | 2 x 10Gi (3)
 _ | node-red | 1 x 10Gi  (3)	| 1 x 10Gi (3) | 1  x 10Gi (3) | 1 x 10Gi (3) | 1 x 10Gi (3)

- **(1)**: Azure Premium SSD LRS 
- **(2)**: Azure Standard SSD LRS
- **(3)**: Amazon gp2

## 3. Packaging
Thingpark Enterprise deployment on kubernetes is composed of a **ThingPark Data Stack** and the  **ThingPark Enterprise Stack**.
Each stack is deployed by 2 Helm Charts:
- One installing required kubernetes extensions like operators and other controllers 
- One installing applications

```
                               THINGPARK DATA STACK                  |            THINGPARK ENTERPRISE STACK
                                                                     |  
                    -------------------------------------------------------------------------------------------------
                                                                     |
                        ┌──────────────────────────────────┐                  ┌─────────────────────────────────┐
                        |          thingpark-data          |                  |      thingpark-enterprise       |
                        ├──────────────────────────────────┤                  ├─────────────────────────────────┤ 
                        |      - mongo replicaset          |                  |             - lrc               |
                        |                                  |                  |                                 |
                        |      - mariadb-galera cluster    |        uses      |             - twa               |
Application layer       |                                  |       ◄────      |                                 |
                        |      - zookeeper cluster         |                  |             - rca               |
                        |                                  |                  |                                 |
                        |      - kafka cluster             |                  |              - ...              |
                        |                                  |                  |                                 |
                        └──────────────────────────────────┘                  └─────────────────────────────────┘                                  
---                                      | uses                                               | uses
                                         ▼                                                    ▼
                        ┌──────────────────────────────────┐                  ┌──────────────────────────────────┐
                        |   thingpark-data-controllers     |                  | thingpark-enterprise-controllers |
Kubernetes extensions   ├──────────────────────────────────┤                  ├──────────────────────────────────┤ 
       layer            |   - Strimzi kafka operator       |                  |   - ingress-nginx controller     |
                        |                                  |                  |                                  |
                        |   - Percona mongodb operator     |                  |   - cert-manager operator        |
                        |                                  |                  |                                  |
                        └──────────────────────────────────┘                  └──────────────────────────────────┘
---                                      | uses                                               | uses
                                         ▼                                                    ▼
                        ┌─────────────────────────────────────────────────────────────────────────────────────────┐          
Kubernetes native       │                                Kubernetes Control plane                                 |
components layer        │                                     & Data plane                                        │ 
                        └─────────────────────────────────────────────────────────────────────────────────────────┘  

```

## 4. Kubernetes cluster ingress/egress network flows 

### 4.1 Base station TO kubernetes cluster (either workers or load balancer)

- **2022:** key-installer & reverse ssh
- **2404, 2504:**: LRC1 / LRC2 IEC 104 unencrypted when `defaultBsSecurity` is set to `DISABLE` or  `MIXED`
- **3001, 3101**: LRC1 / LRC2 IEC 104 over TLS when `defaultBsSecurity` is set to `IPSEC_X509` or  `MIXED`
- **3002:** SFTP over TLS when `defaultBsSecurity` to set to `IPSEC_X509` or  `MIXED`
- **3102:** SFTP when `defaultBsSecurity` is set to `DISABLE` or  `MIXED`

### 4.2. Other flows FROM base station

- DNS
- ICMP: for ip interface failover (optional)
- NTP

### 4.3. From worstation TO kubernetes cluster (either workers or load balancer)

- **HTTPS**:  ThingPark Enterprise Api's access 

### 4.4. From worstation TO kubernetes cluster control plan

- **HTTPS**: Api access with a kubernetes cluster admin account

### 4.5. Other flows FROM kubernetes cluster

- **SMTP** to your SMTP server (optional but recommended)
- - Application servers outbound flows
- **HTTPS** to `repository.thingpark.com`  Actility repositories
- Container images registries:
  - `https://repository.thingpark.com/`
  - `https://quay.io` (jetstack/cert-manager)
  - `https://hub.docker.com/` (percona/percona-server-mongodb-operator, strimzi/strimzi-kafka-operator, bitnami/mariadb-galera, actility/mariadb-galera)
  - `https://k8s.gcr.io` (kubernetes/ingress-nginx, external-dns)

### 4.6. Other flows TO kubernetes cluster
- Application servers inbound flows

### 4.7. Other flows FROM workstation
Following Helm chart repositories must be accessible to administer the deployment:
- `https://repository.thingpark.com/`
- `https://github.com/`
- `https://raw.githubusercontent.com`
- `https://charts.jetstack.io` (jetstack/cert-manager)
- `https://strimzi.io/charts` (strimzi/strimzi-kafka-operator)
- `https://percona.github.io` (percona-helm-charts)

## 5. Kubernetes cluster internal flow
- ThingPark Enterprise workloads can be isolated from other one on cluster activating provided NetworkPolicies.
- As a reminder, a [networking plugin](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/) which supports NetworkPolicy have to be used, otherwise any activation will have no effect.

## 6. Installed third parties
### 6.1. Data stack

- The data stack includes database & messaging services required by TPE.
- The only supported option to fulfill these requirements is to deploy `thingpark-data` helm chart.
- Following third parties are used:
  - strimzi/strimzi-kafka-operator
  - percona/percona-server-mongodb-operator
  - bitnami/mariadb-galera

### 6.2. Infrastructure stack

- Infrastructure stack refer to additional kubernetes operators/controllers required by ThingPark Enterprise deployment. 
- These requirements are fulfilled by thingpark-enterprise-controllers chart. It optionally deploy following third parties:
  - kubernetes/ingress-nginx
  - cert manager

## 7. Current limitations

- See [Limitations](./limitations.md)

## 8. Installation
- Follow [**installation guide**](./installation.md) to deploy ThingPark Enterprise on your Kubernetes Cluster.

## 9. Uninstall
- [Uninstall](uninstall.md) Thingpark Enterprise
