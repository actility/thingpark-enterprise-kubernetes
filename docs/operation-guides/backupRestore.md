# Backup & Restoration

## Enable scheduled backup

Scheduled backup can be enabled after initial deployment by updating helm `thingpark-enterprise` release and it's custom-values.yaml configuration: 
1. Add a `schedule` key in backup block with appropriate cron expression:
    ```yaml
    backup:
    schedule: "30 2 * * *"
    ```
2. Upgrade the chart release

    ```shell
    helm upgrade -i tpe -n $NAMESPACE \
      actility/thingpark-enterprise --version $THINGPARK_ENTERPRISE_VERSION \
      -f $CONFIG_REPO_BASEURL/configs/segments/values-s-segment.yaml \
      -f $CONFIG_REPO_BASEURL/configs/distributions/values-azure-aks.yaml \
      -f custom-values.yaml
    ```
3. Backups retention should be set using cloud storage features:
- [Amazon S3 Lifecycle](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)
- [Azure Storage lifecycle management](https://docs.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview)

## Trigger manually a backup

A manual backup can be triggered by running backup script in the thingpark-enterprise-controller deployment context. 

1. Run script through kub api using following command:
    ```shell
    kubectl exec -it -n $NAMESPACE deploy/thingpark-enterprise-controller -- backup
    ```

2. Backup are push to blob storage: 
    ```json
    localhost ok: {
        "changed": false,
        "msg": "New backup thingpark-enterprise-backup-20220120091609 successfully pushed to remote storage"
    }
    ```

## Disaster recovery
A ThingPark deployment can be fully re-deployed from a backup.
Requirements are: 
- An access to same backup storage as recovered deployment
- Use the `custom-values.yaml` file and the same Chart version used to install the recovered deployment
- Re-deploy with the same namespace name

Procedure :

1. Use [installation guide](../installation-guides/README.md) to deploy a new ThingPark Enterprise Helm release on your cluster. Use Charts version that you want to restore.

2. Identify a backup that you want to restore by listing available one:
    ```shell
    kubectl exec -it -n $NAMESPACE deploy/thingpark-enterprise-controller -- list-backups
    ```

3. Validate that backup `chart`, `appVersion` and `releaseNamespace` match with redeployed version:
    ```shell
    kubectl exec -it -n $NAMESPACE deploy/thingpark-enterprise-controller -- get-backup-metadatas -e backup_name=<backup name>
    ```

4. Trigger the data restoration (command will ask for confirmation):
    ```shell
    kubectl exec -it -n $NAMESPACE deploy/thingpark-enterprise-controller -- restore -e backup_name=<backup name> 
    ```

