# Base station configuration notes
## Requirements
- Have a base station access with the mlbadmin account (can be asked to support)

## Base station limitations
- The current suplog version doesn't support all configuration parameters required to join a ThingPark Enterprise Kubernetes cluster
- The TLS configuration script doesn't support custom SSH ports
- The TLS option can't be selected from suplog

As a result, following notes allow to work arround theses limitation in order to use ThingPark Enterprise Kubernetes Proof of concept

## Encryption deactivation
### ThingPark Enterprise configuration update
> Note:
> For security reasons, a base station must always be authenticated and protected through a VPN. If you choose not to activate the encryption provided by ThingPark, you should ensure that the base station is authenticated and connected through a corporate VPN.

- If you plan to use clear flow between Base Station and ThingPark Enterprise cluster, start by reconfigure ingress controller inbounds
1. Add the following  `ingress-nginx.tcp` block  in your `custom-values.yaml`

```yaml
ingress-nginx:
  controller:
    service:
      annotations:
        external-dns.alpha.kubernetes.io/hostname: *dnsHostname
  tcp:
    2404: thingpark-enterprise/tpe-lrc-0:2404
    2504: thingpark-enterprise/tpe-lrc-1:2404
    3102: thingpark-enterprise/tpe-lrc-cluster:22
```
2. Using the mlbadmin account, connect to base station to edit `/home/actility/usr/etc/lrr/lrr.ini` file
3. Update the lrr.ini following sections (only relevant keys are showed):

```ini
[download:0]
        ftpaddr=<.Value.global.dnsHostname>
        ftppass=<encrypted pass>
        ftpport=3102
        ftpuser=ftp-lrc
        use_sftp=1

[download:1]
        ftpaddr=
        ftppass=
        ftpport=
        ftpuser=
        use_sftp=1

...
  Omitted for clarity
...

[laplrc:0]
        addr=<.Value.global.dnsHostname>
        port=2404

[laplrc:1]
        addr=<.Value.global.dnsHostname>
        port=2504

...
  Omitted for clarity
...

[lrr]
        nblrc=2
...
  Omitted for clarity
...

[services]                                                                     
        checkvpn2=0                                                            
        tls=0                                                              
                 
...
  Omitted for clarity
...

[support:0]                                                                    
        addr=<.Value.global.dnsHostname>
        ftpaddr=<.Value.global.dnsHostname>
        ftppass=<encrypted pass>
        ftpport=3102                                                           
        ftpuser=ftp-support                                                    
        pass=<encrypted pass>
        port=2022                                                              
        use_sftp=1                                                             
        user=support                                                           
                                                                               
[support:1]                                                    
        addr=                                                  
        ftpaddr=                                               
        use_sftp=1  
```

4. Restart lrr

```shell
 /etc/init.d/lrr restart
```



## Using TLS Encryption

1. Using the mlbadmin account, connect to base station to edit `/home/actility/usr/etc/lrr/lrr.ini` file

2. Patch the `/home/actility/lrr/tlsmgr/checktls.sh` GetTLSCerts function by updating port variable (line 543):
```shell
PORT=2022
```
Update vpn.cfg to reach Thingpark Enterprise instance key installer:
```shell
SRV=<.Value.global.dnsHostname>
```
3. Update the lrr.ini following sections (only relevant keys are showed):

```ini
[download:0]
        ftpaddr=localhost
        ftppass=<encrypted pass>
        ftpport=2021
        ftpuser=ftp-lrc
        use_sftp=1

[download:1]
        ftpaddr=
        ftppass=
        ftpport=
        ftpuser=
        use_sftp=1

...
  Omitted for clarity
...

[laplrc:0]
        addr=localhost
        port=12404

[laplrc:1]
        addr=localhost
        port=12504

...
  Omitted for clarity
...

[lrr]
        nblrc=2
...
  Omitted for clarity
...

[services]                                                                     
        checkvpn2=0                                                            
        tls=1                                                                  
                 
...
  Omitted for clarity
...

[support:0]                                                                    
        addr=<.Value.global.dnsHostname>
        ftpaddr=localhost                                                      
        ftppass=<encrypted pass>
        ftpport=3002                                                           
        ftpuser=ftp-support                                                    
        pass=<encrypted pass>
        port=2022                                                              
        use_sftp=1                                                             
        user=support                                                           
                                                                               
[support:1]                                                    
        addr=                                                  
        ftpaddr=                                               
        use_sftp=1  
```

4. Clean eventual certificate and restart lrr

```shell
 /etc/init.d/checktls clean

 /etc/init.d/lrr restart
```