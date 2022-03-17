# Rollbacks
## Rollback to a thingpark-enterprise upgrade
This procedure apply to a rollback for any reason after an upgrade:

1. Identify latest backup automatically triggered during upgrade:
    ```shell
    kubectl exec -it -n $NAMESPACE deploy/thingpark-enterprise-controller -- list-backups
    ```

2. Rollback to the previous Helm revision:
    ```shell
    helm rollback -n $NAMESPACE tpe
    ```

3. Start data restoration using identified backup:
    ```shell
    kubectl exec -it -n $NAMESPACE deploy/thingpark-enterprise-controller -- restore -e backup_name=<backup name> 
    Executing playbook restore.yml

    - Start restoring a data backup on hosts: localhost -
    Gathering Facts...
    localhost ok
    Check parameters...
    localhost ok: {
        "changed": false,
        "msg": "thingpark-enterprise-backup-20220120093259 backup will be use to restore"
    }
    WARNING: Destructive Operation !!!...
    [WARNING: Destructive Operation !!!]
    This Operation will restore a previous state of your TPE instance. 
    Are you sure you want to delete current datas? (yes/no)

    ```

## Rollback a thingpark-enterprise configuration revision

This procedure allow to restore a previous Helm revision with data restoration:  

1. Identify the release revision you want to rollback to and take a note of `APP VERSION` :
    ```shell
    helm history -n $NAMESPACE tpe
    REVISION	UPDATED                 	STATUS    	CHART                           	APP VERSION	DESCRIPTION
    ...                           
    8       	Thu Jan 20 10:24:54 2022	superseded	thingpark-enterprise-1.0.2	7.1.0      	Upgrade complete                    
    ...
    ```
2. List available backup to retrieve the one that you want to restore
    ```shell
    kubectl exec -it -n $NAMESPACE deploy/thingpark-enterprise-controller -- list-backups
    ```

3. Validate that backup `appVersion` stored in its metadatas match with your ThingPark X.Y.Z Helm revision `APP VERSION`:

    ```shell
    kubectl exec -it -n $NAMESPACE deploy/thingpark-enterprise-controller -- get-backup-metadatas -e backup_name=<backup name>
    ...

    Backup metadatas:...
    localhost ok: {
        "changed": false,
        "msg": [
            "helm:",
            "    appVersion: 7.1.0",
            "    chart: thingpark-enterprise-1.0.2",
            "    releaseName: tpe",
            "    releaseNamespace: thingpark",
            "    revision: '7'",
            "id: thingpark-enterprise-backup-20220120093259",
            "tm: '2022-01-20T09:32:59Z'",
            "type: on-demand"
        ]
    }
    ...
    ```

4. Trigger the Helm revision rollback:
    ```shell
    helm rollback -n $NAMESPACE tpe <revision>
    ```

5. After all `Deployment`/`Statefulset` back to an `Available` state, start the restoration procedure using identified backup:
    ```shell
    kubectl exec -it -n $NAMESPACE deploy/thingpark-enterprise-controller -- restore -e backup_name=<backup name>
    Executing playbook restore.yml

    - Start restoring a data backup on hosts: localhost -
    Gathering Facts...
    localhost ok
    Check parameters...
    localhost ok: {
        "changed": false,
        "msg": "thingpark-enterprise-backup-20220120093259 backup will be use to restore"
    }
    WARNING: Destructive Operation !!!...
    [WARNING: Destructive Operation !!!]
    This Operation will restore a previous state of your TPE instance. 
    Are you sure you want to delete current datas? (yes/no)

    ```
