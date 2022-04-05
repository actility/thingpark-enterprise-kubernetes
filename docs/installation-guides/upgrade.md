# Thingpark Enterprise upgrade

## Upgrade from 1.0.x
ThingPark Enterprise 1.1.x  charts introduce:
- Thingpark Enterprise 7.1.1
- Explicit usage of **Container Storage Interface (CSI) driver**:
  - The current storage class specify the in-tree driver as storage provisioner. Current AKS cluster versions use CSIMigration* FeatureFlags to redirect calls to CSI driver
  - Azure in-tree to CSI driver transition start with [Kubernetes 1.21](https://azure.microsoft.com/en-us/updates/general-availability-csi-storage-driver-support-on-azure-kubernetes-service).
  - Deprecated since 1.19, in-tree plugin removal is [planned in 1.26](https://kubernetes.io/blog/2021/12/10/storage-in-tree-to-csi-migration-status-update/#timeline-and-status).
  - New chart version explicitly specify usage of CSI provider
- Kubernetes specific sizing configurations for L, XL, XXL segments   

It require two steps:
1. Thingpark Enterprise 7.1.1 upgrade using legacy storage and compute resources sizing. 
2. Platform redeployment to match targeted segment sizing.

### STEP 1: Thingpark Enterprise upgrade
#### Requirements
- The custom values configuration file used for initial deployment

#### Tpe helm release update

1. Prepare workstation environment
    ```shell 
    # Set the deployment namespace as an environment variable
    export NAMESPACE=thingpark-enterprise
    export CONFIG_REPO_BASEURL=https://raw.githubusercontent.com/actility/thingpark-enterprise-kubernetes/release-7.1
    eval $(curl $CONFIG_REPO_BASEURL/VERSIONS)
    helm repo update
    ```
2. Upgrade the tpe release using the 1.1.x chart and the provided legacy configuration

     ```shell
    helm upgrade -i tpe --debug --timeout 10m -n $NAMESPACE \
      actility/thingpark-enterprise --version $THINGPARK_ENTERPRISE_VERSION \
      -f $CONFIG_REPO_BASEURL/configs/legacy/values-s-segment-azure.yaml \
      -f custom-values.yaml
    ```

### STEP 2: Storage & Sizing
#### Requirements

1. Plan a maintenance window. Data path is impacted by this upgrade
2. Backup your deployment just before to start migration
    ```shell 
    kubectl exec -it -n $NAMESPACE deploy/thingpark-enterprise-controller -- backup
    ```
Take a note of backup name

#### Migration
1. Prepare workstation environment
    ```shell
    # Set the ThingPark segment choosed at capacity planning step
    # Value in s,m,l,xl,xxl
    export SEGMENT=l
    # Set the targeted environment
    # Value azure,amazon
    export HOSTING=azure
    ```
2. Uninstall all releases
    ```shell
    helm uninstall -n $NAMESPACE tpe tpe-controllers tpe-data tpe-data-controllers
   ```
3. Remove namespace to cleanup PV and remaining resources
    ```shell
    kubectl delete ns $NAMESPACE
    ```
4. Re-deploy chart releases using new sizing configuration datas Follow the **Installation section** of [installation procedure](./installation.md)


5. Restore data 
    ```shell
    kubectl exec -it -n $NAMESPACE deploy/thingpark-enterprise-controller -- restore -e backup_name=<backup name> 
    ```
>To rollback upgrade for any reason, see the  **Rollback to a thingpark-enterprise upgrade section** in [Rollback procedures](../operation-guides/rollback.md)
