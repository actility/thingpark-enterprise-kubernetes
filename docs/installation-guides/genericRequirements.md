# Kubernetes Requirements
## 1. Workstation
Following requirements must be installed on the deployment host:
- Linux with bash shell
- `helm v3.7.1`: [Offical Installation Note](https://helm.sh/docs/intro/install/)
- `kubectl` installed/configured [Offical Installation Note](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) with required cluster/user/context configuration to create/update resources


## 2. Dedicated node identification

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

## 3. Configuration preparation
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

## 4. Next steps
Use the appropriate guide for installation on your distribution:
- [**Azure Kubernetes Service**](./azureKubernetesService.md)
- [**Amazon Elastic Kubernetes Service**](./elasticKubernetesService.md)
