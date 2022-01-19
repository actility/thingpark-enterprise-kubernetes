# Backup & Restoration

## Manual backup

A manual backup can be triggered by running backup script in the thingpark-enterprise-controller deployment context. 

1. Run script through kub api using following command:
```shell
kubectl exec -it deploy/thingpark-enterprise-controller -- backup
```

3. Backup are push to blob storage: 

## Backup retention

Backup rentention is set by global.backup.ttl for both on-demand and scheduled backups. However it only manage control plan backup life cycle, database backups retention should be set using cloud storage features:
- [Amazon S3 Lifecycle](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)
- [Azure Storage lifecycle management](https://docs.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview)

## Disaster recovery
A ThingPark deployment can be fully re deployed from a backup in the following way:


1. Use installation guide to deploy a new ThingPark Enterprise on your cluster. Use Charts version that you want to restore.

2. Identify a backup that you want to restore by listing available one:
  
```shell
kubectl exec -it deploy/thingpark-enterprise-controller -- list-backups
```

3. Validate that backup match with redeployed version

```shell
kubectl exec -it deploy/thingpark-enterprise-controller -- get-backup-metadatas -e backup_name=<backup name>
```

4. Trigger restoration:

```shell
kubectl exec -it deploy/thingpark-enterprise-controller -- restore -e backup_name=<backup name> 
```

