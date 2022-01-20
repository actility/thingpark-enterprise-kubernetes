# Operation Guide

## Roaming Operations

### Get ThingPark Exchange synchronisation status

- Synchronisation status can be checked using following command
    ```shell
    kubectl exec -it -n $NAMESPACE lrc-0 --container lrc -- get-tex-sync-status.sh
    ```

### Force ThingPark Exchange resync

- Synchronisation can be force using following command:
    ```shell
    kubectl exec -it -n $NAMESPACE lrc-0 --container lrc -- force-tex-resync.sh
    ```

### rfRegions export
- rfRegions matching a specific ismBand can be exported as a tarball archive using following command:
    ```shell
    # Map on your machine required internal service
    kubectl port-forward -n $NAMESPACE service/twa-admin 8080:8080

    # Download tarball for your ismBand as query string parameter 
    curl -o rfRegions.tar.gz  http://localhost:8080/thingpark/wirelessAdmin/rest/systems/operators/1/rfRegions/export?ismBandID=eu868
    ```