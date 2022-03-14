# Reconfigure ThingPark Enterprise
## Generic updates
- ThingPark Enterprise deployment configuration can be updated depending impacted settings. See [values.yaml](../../samples/values-production.yaml) to find all configuration details. 

- If ingress-nginx block is impacted, update the tpe helm release:
    ```shell
    helm upgrade -i tpe-controllers -n $NAMESPACE \
        actility/thingpark-enterprise-controllers --version $THINGPARK_ENTERPRISE_CONTROLLERS_VERSION \
        -f $CONFIG_REPO_BASEURL/configs/$HOSTING/values-$SEGMENT-segment.yaml \
        -f custom-values.yaml
    ```

- For all other configuration update, update the tpe helm release:

    ```shell
    helm upgrade -i tpe --debug --timeout 10m -n $NAMESPACE \
      actility/thingpark-enterprise --version $THINGPARK_ENTERPRISE_VERSION \
      -f $CONFIG_REPO_BASEURL/configs/$HOSTING/values-$SEGMENT-segment.yaml \
      -f custom-values.yaml
    ```
  
## Specific operations
### Lora netId/nsId reconfiguration
- If a Lora configuration is required, then following post operation should be done:
    ```shell
    kubectl exec -it -n $NAMESPACE deploy/thingpark-enterprise-controller -- full-provisioning
    ```
