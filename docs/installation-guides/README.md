# Installation Guides

## 1. Kubernetes distributions
- ThingPark Enterprise on [**Azure Kubernetes Service**](./azureKubernetesService.md)


## 2. Cross installation resources 
### 2.1. Base Station configuration 

- [**Base Station**](./bsConfigurationNotes.md) configuration notes

### 2.2. Network flows
Base station **to** kubernetes cluster (either workers or load balancer):

- **2022:** key-installer & reverse ssh
- **2404, 2504:**: LRC1 / LRC2 IEC 104 unencrypted when `defaultBsSecurity` is set to `DISABLE` or  `MIXED`
- **3001, 3101**: LRC1 / LRC2 IEC 104 over TLS when `defaultBsSecurity` is set to `IPSEC_X509` or  `MIXED`
- **3002:** SFTP over TLS when `defaultBsSecurity` to set to `IPSEC_X509` or  `MIXED`
- **3102:** SFTP when `defaultBsSecurity` is set to `DISABLE` or  `MIXED`

Other flows **from** base station

- DNS
- ICMP: for ip interface failover (optional)
- NTP

From worstation **to** kubernetes cluster (either workers or load balancer):

- **HTTPS**:  ThingPark Enterprise Api's access 

From worstation **to** kubernetes cluster control plan:

- **HTTPS**: Api access with a kubernetes cluster admin account

Other flows **from** kubernetes cluster:

- **SMTP** to your SMTP server (optional but recommended)
- **HTTPS** to Actility repositories
- Application server outbound flows

Other flows **to** kubernetes cluster:

- Application server inbound flows

## 3. Uninstall
- [Uninstall](uninstall.md) Thingpark Enterprise