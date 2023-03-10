# Before starting
 Persistent Volumes were selected over emptyDir due to the data model file size. The provided examples use NFS as the Persistent Volume but it need not be NFS, it can be any of the volumes k8s supports. For example, Azure Disk, GCE Persistent Disk, AWS EBS etc. Another option considered was emptyDir. Although emptyDir are shared between Pods the directory would need to be populated on creation. This population of data can take some time and consume network resources. Also on Pod deletion the emptyDir would be deleted as well requiring the emptyDir to be recreated on Pod creation. As noted in the Persistent Volume definition, the data models used by RS are mounted ReadOnlyMany.

Prior to deploying the demo, a Persistent Volume with roots specific for the Rosette Enterprise version needs to be deployed. The Rosette Enterprise configuration files need to be extracted and customized for your deployment (this includes the Rosette Server runtime configuration). Refer to the `rosette-server/README` for information on how to extract these components. Finally, the `rosette-license.xml` needs to be deployed to the `/config/rosapi` directory.

## NFS Specifics
If using NFS as the persistent volume then the configuration will need to be updated for the location and type of network share being used. In this example the following is being specified:

```
  mountOptions:
    - hard
    - nfsvers=4.1
  nfs:
    path: /var/nfsshare/config
    server: 10.150.0.39
```
The host address, mount point and perhaps mechanism for mounting will differ for each environment. Once the mount points are created the models and data files must be deployed to the roots persistent volume and the configuration (with the rosette-license.xml) must be deployed to the config persistent volume. 

## ConfigMaps
Before deploying, ConfigMaps must be created for `/config` ,`/config/rosapi` and `/conf`. Refer to `rosette-server/README.md` for information on how to extract and configure these files. Note, the configuration files need to be modified for the target environment and `rosette-license.xml` needs to be deployed to the `./config/rosapi` directory prior to ConfigMap creation.

To create the config maps the following commands can be used:
```
# From the base directory where the config directory was extracted:
kubectl create configmap rosette-pv-config-configmap --dry-run=client --from-file=./config/ -o yaml  > config-configmap.yaml

kubectl create configmap rosette-pv-config-rosapi-configmap --dry-run=client --from-file=./config/rosapi -o yaml  > config-rosapi-configmap.yaml

# From the base directory where the conf directory was extracted:
create configmap rosette-pv-conf-configmap --dry-run=client --from-file=./conf -o yaml  > conf-configmap.yaml
```
Note: the names of the ConfigMaps are significant and is used in the k8s deployment.

# Deployment
In this example, the `roots-persistent-volume.yaml` needs to have the following updated with the NFS shared directory and NFS server name or IP:
```
nfs:
    path: /var/nfsshare/roots
    server: 10.150.0.39
```

On a linux based NFS server the network you can find the shares by `showmount -e <NFS host>` for example
```
[nfs-test ~]$ showmount -e localhost
Export list for localhost:
/var/nfsshare/roots          *
```
When deploying the k8s files for the first time it is recommended to create the roots persistent volume, then check the status to verify that it was created correctly, and then create the persistent volume claim.
For example:
```
kubectl create -f roots-persistent-volume.yaml
kubectl describe persistentvolumes
```
Then continue to the roots persistent volume claim:
```
kubectl create -f roots-persistent-volume-claim.yaml
kubectl describe persistentvolumeclaims
```
Then deploy the deployment, horizontal autoscaler and loadbalancer.


Using kubectl the following components should be deployed (complete list):
```
kubectl create -f roots-persistent-volume.yaml
kubectl describe persistentvolumes
# Looking for "Status:          Available"
kubectl create -f roots-persistent-volume-claim.yaml
kubectl describe persistentvolumeclaims
# Looking for "Status:        Bound"
kubectl create -f conf-configmap.yaml
kubectl create -f config-configmap.yaml
kubectl create -f config-rosapi-configmap.yaml
kubectl create -f deployment.yaml
kubectl get pods
# from the get pods command
# Looking status "RUNNING"
# Then  ex: kubectl logs rosette-pv-deployment-c8b58fd7f-dcm5f
# Running Rosette Server Edition...
kubectl create -f horizontal-autoscale.yaml
kubectl create -f loadbalancer.yaml
```

# Status
Find the ingress:
`kubectl get services` or `kubectl get service rosette-pv-lb` (looking for an external IP) and then 
`curl http://<RS entrypoint>:8181/rest/v1/pi
ng` should return a message similar to "{"message":"Rosette at your service","time":1609336474002}"

# Removal

`kubectl delete persistentvolumeclaims rosette-pv-roots-claim` or use the `-f` flag and the filename e.g. `kubectl delete -f deployment.yaml` using all the files used to create the deployment. 
 
### Trouble Shooting
#### Liveness

`curl http://<RS entrypoint>:8181/rest/v1/ping` should return a message similar to `"{"message":"Rosette at your service","time":1609336474002}"`
When the command `curl http://<RS entrypoint>:8181/rest/v1/ping` is run there may be a couple of different outputs until Rosette Server has started.
* Before the server (jetty) can accept requests you will get : `curl: "(52) Empty reply from server"`
* Once the server (jetty) can accept requests, but before Rosette is ready you will get an HTML error message.
* After waiting approximately 40 seconds and once everything has started, you will get the message `"{"message":"Rosette at your service","time":1609337322171}"`  Note: the k8s deployment.yaml file has other healthcheck and liveness URLs listed.

##### Other things to look for
1. You shouldn't see any ERROR in the logs. Once the server is ready you should see something similar to:

```
INFO   | jvm 1    | 2020/12/30 14:08:09 | WrapperManager: Initializing...
INFO   | jvm 1    | 2020/12/30 14:08:37 | [WARN ] 2020-12-30 14:08:37.777 [WrapperListener_start_runner] com.basistech.ws.launcher.RosapiProductionLauncher - Rosette Server is ready
```
The log is useful when it comes to diagnosing startup issues. Common problems could include a missing license file or unable to find roots.

2. Bash and curl are installed on the container. Using the CONTAINER ID you can `docker exec -it <container id> bash`  and on the container itself execute `curl http://localhost:8181/rest/v1/ping` In the container the license file should be in `/rosette/server/launcher/config/rosapi/rosette-license.xml`.
