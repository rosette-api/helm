# Helm Chart for Persistent Volume Demo
## Before starting
The data models for the different languages can be quite large (several GB). Therefore Persistent Volumes were selected over emptyDir due to the data model file size. The provided examples use NFS as the Persistent Volume but need not be NFS, it can be any of the volumes k8s supports. For example, Azure Disk, GCE Persistent Disk, AWS EBS etc. Another option considered was emptyDir. Although emptyDir are shared between Pods the directory would need to be populated on creation. This population of data can take some time and consume network resources. Also on Pod deletion the emptyDir would be deleted as well requiring the emptyDir to be recreated on Pod creation. As noted in the Persistent Volume definition, the data models used by RS are mounted ReadOnlyMany.

## Overview
The Helm chart automates much of the k8s deployment by parameterizing Helm yaml templates which in turn produce k8s yaml files which are deployed. In addition, the Helm chart supports versioning and can be shared between users quite easily by packaging and version control.

In order to  deploy the entire Rosette Enterprise application and components with Helm only one command needs to be executed `helm install demo ./rosette-server` This will install the Helm Chart from the ./rosette-server directory as the `demo-rosette-server` deployment. Executing `helm list` will show the newly created deployment. To delete all the resources for the deployment only a single command is needed `helm delete demo`.

### Prerequisites
Prior to deploying the demo, as mentioned in `Rosette Enterprise k8s Persistent Volume Deployment` README, an NFS server with roots specific for the Rosette Enterprise version needs to be deployed. Note any type of Persistent Volume can be used, NFS was used in this example. The Rosette Enterprise configuration files need to be extracted and customized for your deployment (this includes the Rosette Server runtime configuration). Refer to the [helm/rosette-server/README](/rosette-server/README.md) for information on how to extract these components. Once the prerequisites are done the `helm/helm/rosette-server/values.yaml` file can be updated with details about your deployment and Rosette Enterprise can be deployed.

#### Root (Model) Extraction
Please refer to the [README](/rosette-server/README.md) file in the `helm/rosette-server` directory for information on how to pull the roots.

#### Configuration Extraction
The configuration can be deployed by running [`stage-rosette-servers.sh`](/rosette-server/stage-rosette-server.sh). It will create the configuration directories in `helm/helm/rosette-server`. Note: the configuration files must be deployed inside the chart directory (`helm/helm/rosette-server`) if the configuration files were installed in a subdirectory then the `values.yaml` must be updated and the `confDirectory`, `configDirectory` and `configRosapiDirectory` values updated to point the subdirectory. This Chart assumes that the `rosette/server-enterprise:1.25.1` image is being used. If a different version is being used please update `Chart.yaml` and update the `appVersion` Please refer to the README file in the `helm/rosette-server` directory for more information.

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
|image||Keys in this section refer to the Rosette Enterprise Docker image used for the deployment.|
||repository|The base image name being used. Default rosette/server-enterprise, the version is taken from the `appVersion` in the `Chart.yaml`|
||pullPolicy|Docker pull policy, default IfNotPresent|
|rosetteServer||Values controlling where configuration have been placed (under `./rosette-server`)|
||confDirectory|The subdirectory holding the Rosette runtime configuration|
||configDirectory|The subdirectory holding the Rosette configuration|
||configRosapiDirectory|The subdirectory holding the Rosette customization configuration|
|rexTrainingServer||Not used in this deployment|
|loadBalancer||
||port|the port the load balancer will expose|
||sessionAffinity|what type of affinity to use, session affinity is not required|
|resources||Resource requests and limits|
|livenessProbe||Configures timing of the liveness probe|
|readinessProbe||Configures timing of the liveness probe|
|storage||Details on the persistent storage|
|nfs||Configuration for the NFS server|
||enabled|Enables the NFS server.|
||address|DNS name or address of the server. Must be set.|
||storageClassName|Storage class name to use when connecting|
||roots||Information about the root volume|
||mountPoint|The mount point that the Persistent Volume should use. Default /var/nfsshare/roots|
||claimRequestSize|Size of the claim|
||storageCapacity|Capacity of the volume|
|autoscaling||
||enabled|Enables autoscaling|
||minReplicas|Minimum number of replicas|
||maxReplicas|Maximum number of replicas|
||Metrics|Information to configure the horizontal autoscaler|
|securityContext||Restricts security of the Pod|
||runAsNonRoot|Runs a non-root user|
||runAsUser|Run as user 2001, this matches the Rosette user|

#### Notes
The majority of the deployment of Rosette Enterprise is straight forward. There are a few points of interest which deserve some explanation.

For the helm example, the `values.yaml` needs to be updated with information specific for your environment:
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
### Monitoring

First enable the usage tracker in Rosette Server with a configuration file:

`config/com.basistech.ws.local.usage.tracker.cfg`
```
usage-tracker-root: /var/tmp
enabled: true
```

Above enables a Prometheus endpoint at `/rest/usage/metrics`.

#### Prometheus with Helm
1. Install [Prometheus via Helm](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus) first.
2. Add following annotations to pods:

```
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/path: /rest/usage/metrics
        prometheus.io/port: "8181"
```

#### Prometheus Operator
1. Install [Prometheus Operator](https://prometheus-operator.dev/).
2. Add a ServiceMonitor for the instance:

```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: rosette-monitor
spec:
  selector:
    matchLabels:
      app.kubernetes.io/instance: <helm-instance-name>
      app.kubernetes.io/name: rosette-server
  endpoints:
  - port: http
    path: /rest/usage/metrics
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
