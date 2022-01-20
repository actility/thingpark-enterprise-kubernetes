# Thingpark Enterprise uninstall
## Uninstallation without loosing data

- When you intend to stop all Thingpark Enterprise for a later re-deployment:
1. Stop safely the mariadb statefulset using scale
```shell
kubectl scale statefulset tpe-mariadb-galera --replicas=0

```
2. Uninstall charts

```shell
helm uninstall tpe tpe-controllers tpe-data tpe-data-controllers
```
## Full uninstallation
1. Start by uninstall charts
```shell
helm uninstall tpe tpe-controllers tpe-data tpe-data-controllers
```
2. Delete the namespace 
```shell
kubectl delete ns $NAMESPACE
```
3. Cleanup persistent volumes (for local persistance only)

- Connect to each workers to cleanup folders within /opt/data `/mnt/data/`
```shell
sudo rm -rf /mnt/data/*
```

