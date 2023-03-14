# Helm Chart for Persistent Volume Demo
## Before starting
The data models for the different languages can be quite large (several GB). Therefore Persistent Volumes were selected over emptyDir due to the data model file size. The provided examples use NFS as the Persistent Volume but need not be NFS, it can be any of the volumes k8s supports. For example, Azure Disk, GCE Persistent Disk, AWS EBS etc. Another option considered was emptyDir. Although emptyDir are shared between Pods the directory would need to be populated on creation. This population of data can take some time and consume network resources. Also on Pod deletion the emptyDir would be deleted as well requiring the emptyDir to be recreated on Pod creation. As noted in the Persistent Volume definition, the data models used by RS are mounted ReadOnlyMany.

## Overview
The Helm chart automates much of the k8s deployment by parameterizing Helm yaml templates which in turn produce k8s yaml files which are deployed. In addition, the Helm chart supports versioning and can be shared between users quite easily by packaging and version control.

In order to  deploy the entire Rosette Enterprise application and components with Helm only one command needs to be executed `helm install demo ./rosette-server` This will install the Helm Chart in the ./rosette-server directory as the `rosette-server-demo` deployment. Executing `helm list` will show the newly created deployment. To delete all the resources for the deployment only a single command is needed `helm delete demo`.

### Prerequisites
Prior to deploying the demo, as mentioned in `Rosette Enterprise k8s Persistent Volume Deployment` README, an NFS server with roots specific for the Rosette Enterprise version needs to be deployed. Note any type of Persistent Volume can be used, NFS was used in this example. The Rosette Enterprise configuration files need to be extracted and customized for your deployment (this includes the Rosette Server runtime configuration). Refer to the `rosette-server/README` for information on how to extract these components. Finally, the `rosette-license.xml` needs to be deployed to the `./rosette-server/config/rosapi` directory. Once the prerequisites are done the `./rosette-server/values.yaml` file can be updated with details about your deployment and Rosette Enterprise can be deployed. 

#### Root (Model) Extraction 
Please refer to the README file in the `../rosette-server` directory for information on how to pull the roots. 

#### Configuration Extraction
The configuration can be deployed by running `../rosette-server/install-config.sh` and specifying the `./helm/rosette-server` directory as an output directory. Note: the configuration files must be deployed inside the chart directory (`./helm/rosette-server`) if the configuration files were installed in a subdirectory then the `values.yaml` must be updated and the `confDirectory`, `configDirectory` and `configRosapiDirectory` values updated to point the subdirectory. This script assumes that the `rosette/server-enterprise:1.24.1` image has been loaded. Please refer to the README file in the ../rosette-server directory for more information.

### Helm Directory Structure
The syntax for the parameter replacement in the templates is fairly straightforward. In the common case for a yaml file: `server: {{ .Values.nfsServer.address }}` tells the template engine to take the value from the values.yaml file (the leading . indicates the root of the project) with the remainder of the value following the hierarchy of the document. In this case server would end up with the value 10.23.2.1 e.g. `server: 10.23.2.1`:
```
#values.yaml snippet
nfsServer:
  address: 10.22.2.1
```

For the rosette-server project the files are as follows:

|File|Purpose|
|----|-------|
|Chart.yaml|Contains high level version and project information|
|values.yaml|This file contains values that will be replaced in the template files, this file must be customized for your environment.| 
|/templates|This directory contains template files for the resources in the project.|
|/templates/serviceaccount.yaml|Definition of the service account used for this project. Empty for this sample.| 
|/templates/roots-persistent-volume.yaml|Defines the Persistent Volume that maps to the NFS server hosting the roots.|
|/templates/roots-persistent-volume-claim.yaml|The claim for the roots volume| 
|/templates/config-configmap.yaml|ConfigMap for files found in `/config` directory|
|/templates/config-rosapi-configmap.yaml|ConfigMap for configuration files and license file found in `/config/rosapi`|
|/templates/conf-configmap.yaml|ConfigMap for Rosette Server runtime configuration|
|/templates/horizontal-autoscale.yaml|Horizontal Pod Autoscaler|  
|/templates/loadbalancer.yaml|Ingress point for the application|
|/templates/deployment.yaml|The deployment descriptor for the application|
|/templates/_helpers.tbl|Helper macros used in the templates|
|/templates/NOTES.txt|Text that is displayed when the chart is deployed|

#### values.yaml
Most aspects of the deployment can be configured by modifying the values.yaml file. 
|Key|Subkey|Purpose|
|---|------|-------|
|rsimage||Keys in this section refer to the Rosette Enterprise Docker image used for the deployment.|
||imageName|The base image name being used. Default rosette/server-enterprise|
||imageVersion|The version of the image to pull. Must be set. The final name will be the concatenation of `<imageName>:<imageVersion>` e.g. rosette/enterprise:1.19.0|
||pullPolicy|Docker pull policy, default IfNotPresent|
||port|The port Rosette Enterprise should listen on, default 8181|
||cpuLimit|The resource limit on CPUs. Default is 8|
||cpuRequest|The requested number of CPUs. Default is 4|
||memoryLimit|The resource limit on memory. Default is 8G|
||memoryRequest|The requested number of memory. Default is 16G|
||confDirectory|The subdirectory holding the Rosette runtime configuration|
||configDirectory|The subdirectory holding the Rosette configuration|
||configRosapiDirectory|The subdirectory holding the Rosette customization configuration|
||probeDelay|The number of seconds the readiness and liveness probes will wait before becoming active.|
|nfsServer||Configuration for the NFS server|
||address|DNS name or address of the server. Must be set.|
||rootsMountPoint|The mount point that the Persistent Volume should use. Default /var/nfsshare/roots|
|loadBalancer||Configuration of the ingress point|
||port|The port to expose. Default 8181.|
||sessionAffinity|What kind of session affinity should be used, default is None|
|horizontalLoadBalancer||Configuration on how to scale|
||targetCPUUtilizationPercent|What point should CPU trigger a scaling event. Default is 50%|
||targetMinReplicas|The minimum number of replicas to keep active. Default is 1. Update based on your load.|
||targetMaxReplicas|The maximum number of replicas to keep active at any one time. Default is 3. Update based on your load.|

#### Notes
The majority of the deployment of Rosette Enterprise is straight forward. There are a few points of interest which deserve some explanation. 

In the `deployment.yaml`:
1. The `livenessProbe` and `readinessProbe` will both wait 120 seconds before activating due to the time it could take Rosette Enterprise to start and warm up. The value, `initialDelaySeconds` for these probes can be adjusted downward depending on the specification of the Nodes that the application is being deployed on. The value can be adjusted by modifying the `rosentimage.probeDelay` key in the `values.yaml` file. The liveness and readiness probes both look at worker health to determine server readiness and health rather than using `/rest/v1/info` or `/rest/v1/ping` which may be active before workers are ready.
2. Finally, each container maintains service logs which can be routed to stderr/stdout. Refer to `rosette-server/README.md` for information on how to redirect the logs. By default, the logs are kept in the container but can be exposed via mount point if desired.



4. For the helm example, the `values.yaml` needs to be updated with information specific for your environment:
```
nfsServer:
  address: 10.150.0.39
  rootsMountPoint: /var/nfsshare/roots
```



### Setup k8s Environment for Helm
#### Helm
In order to install Helm client for your platform refer to [installing Helm](https://helm.sh/docs/intro/install/)

Test that Helm is installed:
```
#List deployments, there shouldn't be any at this point but this will check the setup.
$ helm list
```
### Basic Helm Commands for this Project
```
# list deployments made by helm
$ helm list
NAME         	NAMESPACE	REVISION	UPDATED                             	STATUS  	CHART          	APP VERSION
demo	        default  	1       	2020-03-09 16:20:04.119739 -0400 EDT	deployed	rosette-server-0.1.0	1.18.0     

# To deploy the Rosette Persistent Volume Demo using NFS make sure
# 1) A k8s cluster exists
# 2) A NFS server is installed and the values.yaml file is
#    updated with the NFS address or name and directory being shared.
# 3) Helm is installed
# 4) There is a Rosette Enterprise container in the registry and the values.yaml has been updated with the name, and version.
# check for basic errors in the files
# helm lint <directory containing the Chart>
$ helm lint ./rosette-server 

# install the Chart
# helm install <name> <directory containing the Chart>
$ helm install demo ./rosette-server

# After some time the deployment will complete and become available
$ helm list
# Test it using the curl command seen from the NOTES.txt during install.

# Verify the autoscaler
$ kubectl get hpa
NAME                 REFERENCE                   TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
demo-rosette-server       Deployment/demo-rosette-server   3%/50%    1         3         1          5m34s

# Test the deployment by getting the external IP and PORT and making a curl request to /rest/v1/info
$ kubectl get service demo-rosette-server

$ curl http://ip:port/rest/v1/info

# when you are done you can delete the deployment by:
$ helm list
# using the name of the deployment
# helm delete <deployment name>
# For example:
$ helm delete demo
```

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
