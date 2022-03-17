# Galera cluster recovery

Major kubernetes cluster outage or accidental volontary disruption can lead to loose galera quorum and to a full cluster failure. 

Follow next step to recover by re bootsraping the cluster. 

1.  Check the galera statefulset pod state, it will return failure conditions:

    ```shell
    kubectl get po -n $NAMESPACE -l app.kubernetes.io/name=mariadb-galera -o jsonpath='{.items[].status.containerStatuses[].ready}'
    ```
    ```shell
    kubectl get po -n $NAMESPACE -l app.kubernetes.io/name=mariadb-galera -o jsonpath='{.items[].status.containerStatuses[].state}'|jq
    {
    "waiting": {
        "message": "back-off 5m0s restarting failed container=mariadb-galera pod=tpe-mariadb-galera-0_thingpark-enterprise(6faab544-25fd-4e77-a6b9-185e058462dd)",
        "reason": "CrashLoopBackOff"
    }
    }

    ```

2.  Stop the cluster by destroying the statefulset and stop the sql proxy

    ```shell
    kubectl delete statefulsets.apps mariadb-galera 
    kubectl scale deployment sql-proxy --replicas=0
    ```

3.  Retrieve `grastate.dat` content of each node using each `data-mariadb-galera-0`, `data-mariadb-galera-1` ,`data-mariadb-galera-2` volume claim name , for instance:

    ```shell
    kubectl run --restart=Never -n $NAMESPACE -i --rm --tty volpod --overrides='
    {
        "apiVersion": "v1",
        "kind": "Pod",
        "metadata": {
            "name": "volpod"
        },
        "spec": {
            "containers": [{
                "command": [
                    "cat",
                    "/mnt/data/grastate.dat"
                ],
                "image": "bitnami/minideb",
                "name": "mycontainer",
                "volumeMounts": [{
                    "mountPath": "/mnt",
                    "name": "galeradata"
                }]
            }],
            "restartPolicy": "Never",
            "volumes": [{
                "name": "galeradata",
                "persistentVolumeClaim": {
                    "claimName": "data-mariadb-galera-0"
                }
            }]
        }
    }' --image="bitnami/minideb"

    ```

4.  As a result, you obtain each node state, for instance (This situation reflect an improper cluster stop (all safe_to_bootstrap equal 0)):

    ```shell
    ## Node 0
    # GALERA saved state
    version: 2.1
    uuid:    f23062b8-3ed3-11eb-9979-0e1cb0f4f878
    seqno:   14
    safe_to_bootstrap: 0
    pod "volpod" deleted

    ## Node 1
    # GALERA saved state
    version: 2.1
    uuid:    f23062b8-3ed3-11eb-9979-0e1cb0f4f878
    seqno:   14
    safe_to_bootstrap: 0
    pod "volpod" deleted

    ## Node 2
    # GALERA saved state
    version: 2.1
    uuid:    f23062b8-3ed3-11eb-9979-0e1cb0f4f878
    seqno:   14
    safe_to_bootstrap: 0
    ```
5.  Bootstrap the cluster:
  
    -   **Option 1:** One node have a `safe_to_bootstrap: 1`:

        ```shell
        # GALERA saved state
        version: 2.1
        uuid:    f23062b8-3ed3-11eb-9979-0e1cb0f4f878
        seqno:   14
        safe_to_bootstrap: 1
        pod "volpod" deleted
        ```

        This node should be used to bootstrap the cluster, for instance with the node 1:

        ```shell
        helm -n $NAMESPACE upgrade -i tpe-data actility/thingpark-data \
          --version $THINGPARK_DATA_VERSION --reuse-values \
          --set mariadb-galera.podManagementPolicy=Parallel  \
          --set mariadb-galera.galera.bootstrap.bootstrapFromNode=1
        ```

    -   **Option 2:** All nodes have a `safe_to_bootstrap: 0`:

        Cluster should be bootstrapped with the node with the highest `seqno`:

        ```shell
        helm -n $NAMESPACE upgrade -i tpe-data actility/thingpark-data \
          --version $THINGPARK_DATA_VERSION --reuse-values \
          --set mariadb-galera.podManagementPolicy=Parallel \
          --set mariadb-galera.galera.bootstrap.forceSafeToBootstrap=true \
          --set mariadb-galera.galera.bootstrap.bootstrapFromNode=1
        ```


6.  Wait for the end of recovery and reset helm release values in following way:  by stopping the galera cluster in this way:

    ```shell
    # Wait until all pods became READY
    kubectl get statefulsets.apps mariadb-galera -w
    # Scale down gracefully mariadb galera cluster  (wait until the end of pod deletion at each steps)
    kubectl scale statefulsets.apps mariadb-galera --replicas=2
    kubectl scale statefulsets.apps mariadb-galera --replicas=1
    # Delete stalefulset
    kubectl  delete statefulsets.apps mariadb-galera
    ```

7.  And finally upgrade the tpe-data release and restart sql-proxy router deployment:

    ```shell
    helm -n  $NAMESPACE -i tpe-data \
      actility/thingpark-data --version $THINGPARK_DATA_VERSION \
      -f $CONFIG_REPO_BASEURL/configs/segments/values-s-segment.yaml \
      -f $CONFIG_REPO_BASEURL/configs/distributions/values-azure-aks.yaml \
      -f custom-values.yaml

    kubectl scale $NAMESPACE deployment sql-proxy --replicas=2
    ```