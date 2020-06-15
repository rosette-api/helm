# Helm Chart for Persistent Volume Demo

## Overview
The Helm chart automates much of the k8s deployment by parameterizing Helm yaml templates which in turn produce k8s yaml files which are deployed. In addition, the Helm chart supports versioning and can be shared between users quite easily by packaging and version control.

In order to  deploy the entire Rosette Enterprise application and components with Helm only one command needs to be executed `helm install demo ./rosent-pv` This will install the Helm Chart in the ./rosent-pv directory as the `rosent-pv-demo` deployment. Executing `helm list` will show the newly created deployment. To delete all the resources for the deployment only a single command is needed `helm delete demo`.

### Prerequisites
Prior to deploying the demo, as mentioned in `Rosette Enterprise k8s Persistent Volume Deployment` README, an NFS server with roots specific for the Rosette Enterprise version needs to be deployed. Also, the Rosette Enterprise configuration files need to be extracted and customized for your deployment. Finally, the `rosette-license.xml` needs to be deployed to the `./rosent-pv/config/rosapi` directory. Once the prerequisites are done the `./rosent-pv/values.yaml` file can be updated with details about your deployment and  Rosette Enterprise can be deployed.

### Helm Directory Structure
The syntax for the parameter replacement in the templates is fairly straightforward. In the common case for a yaml file: `server: {{ .Values.nfsServer.address }}` tells the template engine to take the value from the values.yaml file (the leading . indicates the root of the project) with the remainder of the value following the hierarchy of the document. In this case server would end up with the value 10.23.2.1 e.g. `server: 10.23.2.1`:
```
#values.yaml snippet
nfsServer:
  address: 10.22.2.1
```

For the rosent-pv project the files are as follows:

|File|Purpose|
|----|-------|
|Chart.yaml|Contains high level version and project information|
|values.yaml|This file contains values that will be replaced in the template files, this file must be customized for your environment.| 
|/templates|This directory contains template files for the resources in the project.|
|/templates/serviceaccount.yaml|Definition of the service account used for this project| 
|/templates/roots-persistent-volume.yaml|Defines the Persistent Volume that maps to the NFS server hosting the roots.|
|/templates/roots-persistent-volume-claim.yaml|The claim for the roots volume| 
|/templates/config-configmap.yaml|ConfigMap for files found in `/config` directory|
|/templates/config-rosapi-configmap.yaml|ConfigMap for configuration files and license file found in `/config/rosapi`|
|/templates/horizontal-autoscale.yaml|Horizontal Pod Autoscaler|  
|/templates/loadbalancer.yaml|Ingress point for the application|
|/templates/deployment-configmap.yaml|The deployment descriptor for the application|
|/templates/_helpers.tbl|Helper macros used in the templates|
|/templates/NOTES.txt|Text that is displayed when the chart is deployed|

#### values.yaml
Most aspects of the deployment can be configured by modifying the values.yaml file. 
|Key|Subkey|Purpose|
|---|------|-------|
|rosentimage||Keys in this section refer to the Rosette Enterprise Docker image used for the deployment.|
||imageName|The base image name being used. Default rosette/server-enterprise|
||imageVersion|The version of the image to pull. Must be set. The final name will be the concatenation of `<imageName>:<imageVersion>` e.g. rosette/enterprise:1.16.0|
||pullPolicy|Docker pull policy, default IfNotPresent|
||port|The port Rosette Enterprise should listen on, default 8181|
||jvmMaxHeap|The value (in GB) given to the JVMs -Xmx flag, default is 4|
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

In the `deployment-configmap.yaml`:
1. The startup command for the container executes two commands, the first is a shell script `update_k8s_config.sh` which will update the Rosette Enterprise launcher's -Xmx flag with the amount of memory specified in the `values.yaml` file (`rosentimage.jvmMaxHeap`). The second script is the actual Rosette Enterprise launcher. The `update_k8s_config.sh` works by reading the containers environment variable `ROSETTE_JVM_MAX_HEAP` which is also set in the deployment descriptor. 
2. The `livenessProbe` and `readinessProbe` will both wait 120 seconds before activating due to the time it could take Rosette Enterprise to start and warm up. The value, `initialDelaySeconds` for these probes can be adjusted downward depending on the specification of the Nodes that the application is being deployed on. The value can be adjusted by modifying the `rosentimage.probeDelay` key in the `values.yaml` file. The liveness and readiness probes both look at worker health to determine server readiness and health rather than using `/rest/v1/info` or `/rest/v1/ping` which may be active before workers are ready.

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
demo	        default  	1       	2020-03-09 16:20:04.119739 -0400 EDT	deployed	rosent-pv-0.1.0	1.16.0     

# To deploy the Rosette Persistent Volume Demo using NFS make sure
# 1) A k8s cluster exists
# 2) A NFS server is installed and the values.yaml file is
#    updated with the NFS address or name and directory being shared.
# 3) Helm is installed
# 4) There is a Rosette Enterprise container in the registry and the values.yaml has been updated with the name, and version.
# check for basic errors in the files
# helm lint <directory containing the Chart>
$ helm lint ./rosent-pv 

# install the Chart
# helm install <name> <directory containing the Chart>
$ helm install demo ./rosent-pv

# After some time the deployment will complete and become available
$ helm list
# Test it using the curl command seen from the NOTES.txt during install.

# Verify the autoscaler
$ kubectl get hpa
NAME                 REFERENCE                   TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
demo-rosent-pv       Deployment/demo-rosent-pv   3%/50%    1         3         1          5m34s

# Test the deployment by getting the external IP and PORT and making a curl request to /rest/v1/info
$ kubectl get service demo-rosent-pv

$ curl http://ip:port/rest/v1/info

# when you are done you can delete the deployment by:
$ helm list
# using the name of the deployment
# helm delete <deployment name>
# For example:
$ helm delete demo
```
#### Load Testing
If you would like to load test the deployment to validate the scaling metrics used there is a k6 project located [here](https://github.com/rosette-api/k6) that can be used to drive Rosette Enterprise using sample data for all endpoints.