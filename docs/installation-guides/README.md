# Installation Guides
## 1. Overview
### 1.1. Deployment components
Thingpark Enterprise deployment on kubernetes is composed of a **ThingPark Data Stack** and the  **ThingPark Enterprise Stack**.
Each stack is deployed by 2 Helm Charts:
- One installing required kubernetes extentions like operators and other controllers 
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
Kubernetes extentions   ├──────────────────────────────────┤                  ├──────────────────────────────────┤ 
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

### 1.2. Ingress/egress network flows 

#### 1.2.1 Base station TO kubernetes cluster (either workers or load balancer):

- **2022:** key-installer & reverse ssh
- **2404, 2504:**: LRC1 / LRC2 IEC 104 unencrypted when `defaultBsSecurity` is set to `DISABLE` or  `MIXED`
- **3001, 3101**: LRC1 / LRC2 IEC 104 over TLS when `defaultBsSecurity` is set to `IPSEC_X509` or  `MIXED`
- **3002:** SFTP over TLS when `defaultBsSecurity` to set to `IPSEC_X509` or  `MIXED`
- **3102:** SFTP when `defaultBsSecurity` is set to `DISABLE` or  `MIXED`

#### 1.2.2. Other flows FROM base station

- DNS
- ICMP: for ip interface failover (optional)
- NTP

#### 1.2.3. From worstation TO kubernetes cluster (either workers or load balancer):

- **HTTPS**:  ThingPark Enterprise Api's access 

#### 1.2.4. From worstation TO kubernetes cluster control plan:

- **HTTPS**: Api access with a kubernetes cluster admin account

#### 1.2.5. Other flows FROM kubernetes cluster:

- **SMTP** to your SMTP server (optional but recommended)
- **HTTPS** to Actility repositories
- Application server outbound flows
- Container images repositories:
  - repository.thingpark.com
- Actility repository: 
  - **HTTPS** to repository.thingpark.com

#### 1.2.6. Other flows TO kubernetes cluster:
- Application server inbound flows

### 1.3. Current limitations

- See [Limitations](./limitations.md)


## 2. Installation on supported distributions
ThingPark Enterprise  can be deployed on following kubernetes distributions:
- [**Azure Kubernetes Service**](./azureKubernetesService.md)

## 3. Uninstall
- [Uninstall](uninstall.md) Thingpark Enterprise