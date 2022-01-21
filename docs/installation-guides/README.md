# Installation Guides

## 1. Kubernetes distributions support
ThingPark Enterprise  can be deployed on following kubernetes distributions:
- [**Azure Kubernetes Service**](./azureKubernetesService.md)

## 2. Base Station configuration 

- TLS activation is not supported by SUPLOG in the current release. Hence, activating TLS requires a custom base station image.

## 3. Ingress/egress network flows 

### 3.1. Base station TO kubernetes cluster (either workers or load balancer):

- **2022:** key-installer & reverse ssh
- **2404, 2504:**: LRC1 / LRC2 IEC 104 unencrypted when `defaultBsSecurity` is set to `DISABLE` or  `MIXED`
- **3001, 3101**: LRC1 / LRC2 IEC 104 over TLS when `defaultBsSecurity` is set to `IPSEC_X509` or  `MIXED`
- **3002:** SFTP over TLS when `defaultBsSecurity` to set to `IPSEC_X509` or  `MIXED`
- **3102:** SFTP when `defaultBsSecurity` is set to `DISABLE` or  `MIXED`

### 3.2. Other flows FROM base station

- DNS
- ICMP: for ip interface failover (optional)
- NTP

### 3.3. From worstation TO kubernetes cluster (either workers or load balancer):

- **HTTPS**:  ThingPark Enterprise Api's access 

### 3.4. From worstation TO kubernetes cluster control plan:

- **HTTPS**: Api access with a kubernetes cluster admin account

### 3.5. Other flows FROM kubernetes cluster:

- **SMTP** to your SMTP server (optional but recommended)
- **HTTPS** to Actility repositories
- Application server outbound flows
- Container images repositories:
  - repository.thingpark.com
- Actility repository: 
  - **HTTPS** to repository.thingpark.com

### 3.6. Other flows TO kubernetes cluster:
- Application server inbound flows

## 4. Uninstall
- [Uninstall](uninstall.md) Thingpark Enterprise