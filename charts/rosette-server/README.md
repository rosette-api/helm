# Introduction
Our product is a full text processing pipeline from data preparation to extracting the most relevant information and 
analysis utilizing precise, focused AI that has built-in human understanding. Text Analytics provides foundational 
linguistic analysis for identifying languages and relating words. The result is enriched and normalized text for 
high-speed search and processing without translation.

Text Analytics extracts events and entities — people, organizations, and places — from unstructured text and adds the 
structure of associating those entities into events that deliver only the necessary information for near real-time 
decision making. Accompanying tools shorten the process of training AI models to recognize domain-specific events.

The product delivers a multitude of ways to sharpen and expand search results. Semantic similarity expands search beyond 
keywords to words with the same meaning, even in other languages. Sentiment analysis and topic extraction help filter 
results to what’s relevant.

This chart bootstraps a Babel Street Analytics Server deployment, and also populates a persistent volume with the 
Analytics Roots required for the server's successful operation.

# Table of Contents
- [**Introduction**](#Introduction)
- [**Prerequisites**](#Prerequisites)
- [**Installation**](#Installation)
  - [Installing with Argo CD](#Installing-with-Argo-CD)
  - [Download the templates](#Download-the-templates)
- [**Uninstall**](#Uninstall)
- [**Parameters**](#Parameters)
  - [Global parameters](#Global-parameters)
  - [Common parameters](#Common-parameters)
  - [Analytics Roots extraction parameters](#Analytics-Roots-extraction-parameters)
  - [Persistent Volume Permissions Parameters](#Persistent-Volume-Permissions-Parameters)
  - [Overrides for configurations located in Root storage parameters](#Overrides-for-configurations-located-in-Root-storage-parameters)
  - [Analytics Server parameters](#Analytics-Server-parameters)
  - [Indoc Coref Server parameters](#Indoc-Coref-Server-parameters)
  - [API keys parameters](#API-keys-parameters)
- [**Analytics Roots extraction**](#Analytics-Roots-extraction)
  - [Root configurations overrides](#Root-configurations-overrides)
- [**Custom profiles**](#Custom-profiles)
  - [Data paths for custom profiles](#Data-paths-for-custom-profiles)
- [**Resource requirements**](#Resource-requirements)
  - [Memory requirements](#Memory-requirements)
  - [Disk space requirements](#Disk-space-requirements)
- [**Analytics Roots storage examples**](#Analytics-Roots-storage-examples)
  - [hostPath](#hostPath)
  - [GCP Persistent Disk](#GCP-Persistent-Disk)
  - [NFS server](#NFS-server)
- [**Troubleshooting**](#Troubleshooting)
  - [Troubleshoot Argo CD](#Troubleshoot-Argo-CD)

# Prerequisites
- A license secret available in the namespace where the installation will happen and `licenseSecretName` set in **values.yaml** or
provided during installation like `--set licenseSecretName=<license secret name>`.
If you don't have a license already available in the namespace, you can create one with
  ```
  kubectl create secret generic analytics-license-file --from-file=<license-file>
  ```
    - _Your license file will be included in the shipment from Analytics Support._
- A static persistent volume or a storage class capable of dynamically provisioning persistent volumes for the Analytics Roots and the corresponding
key set in **values.yaml** or provided during installation like `--set storageClassName=<storage class>` and/or `--set rootsVolumeName=<volume>`.
  - The persistent volume should have ownership of `2001:0` and a permission mode of `775` or `770`.
    This can be done for you with an Init Container.  See [**Persistent Volume Permissions Parameters**](#persistent-volume-permissions-parameters) for more information.
  - For more instructions on how to dynamically setup the roots storage, see [examples](#analytics-roots-storage-examples).

# Installation
Before installing or updating the chart you can set the desired endpoints and languages in **values.yaml** by uncommenting the values or by providing them to the command like
`--set "enabledEndpoints={language,morphology}" --set "enabledLanguages={eng,fra}"`. These lists are comma separated WITHOUT spaces.  This will start a post hook job,
that extracts the necessary Analytics Roots to the persistent volume provided.
See more details about the job at the [root extraction section](#analytics-roots-extraction)

To add the repo to helm, run
```shell
helm repo add babelstreet https://charts.babelstreet.com
```

and then you can install the chart with
```shell
helm install analytics-server babelstreet/rosette-server --timeout=1h
```

This command will create a deployment for Analytics Server and a persistent volume claim for the Analytics Roots persistent volume.
The extraction of the roots can be a lengthy process, depending on which endpoints and languages are enabled and also on available system resources.
Make sure to set a long enough timeout for the process to finish considering your resources.

## Installing with Argo CD
The chart is maintained to be used with Helm installation primarily, but it is possible to install it with Argo CD as well. Be sure to check out
the corresponding [troubleshooting section](#troubleshoot-argo-cd) if you run into issues or reach out to Analytics Support for help.

## Download the templates
Use this [link](https://charts.babelstreet.com/rosette-server-3.3.0.tgz) to download the chart and its templates

# Uninstall
To uninstall the release, run
```shell
helm uninstall analytics-server
```
To fully remove all Analytics Server associated components from the cluster, you will need to manually delete the license secret and potentially
the Analytics Roots persistent volume, depending on its reclaim policy.

# Parameters

## Global parameters
| Name                    | Description                                                                                                                                                      | Value |
|-------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------|
| global.imageRegistry    | If defined it overrides `image.registry`, `initContainer.registry`,  `indoccoref.image.registry`. It is also appended to the beginning of `rootsImageRepository` | ""    |
| global.imagePullSecrets | If defiend it overrides `imagePullSecrets` and `indoccoref.imagePullSecrets`                                                                                     | []    |

## Common parameters

| Name                                          | Description                                                                                                                                                                                                                             | Value                     |
|-----------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------|
| replicaCount                                  | Number of desired Analytics Server pods                                                                                                                                                                                                 | 1                         |
| image.registry                                | The registry for the Analytics Server image                                                                                                                                                                                             |                           |
| image.repository                              | The repository and image name for the Analytics Server containers                                                                                                                                                                       | rosette/server-enterprise |
| image.pullPolicy                              | The pull policy for the Analytics Server image                                                                                                                                                                                          | IfNotPresent              |
| image.tag                                     | The tag of the Analytics Server image. If not provided, defaults to `appVersion` from **Chart.yaml**.                                                                                                                                   | ""                        |
| imagePullSecrets                              | An optional list of references to secrets in the same namespace to use for pulling Analytics Server, Analytics Roots or initContainer images. For pulling Indoc Coref Server images, see [this section](#indoc-coref-server-parameters) | []                        |
| nameOverride                                  | String to partially override the template used in naming Kubernetes objects. The release name will be maintained.                                                                                                                       | ""                        |
| fullnameOverride                              | String to fully override the template used in naming Kubernetes objects                                                                                                                                                                 | ""                        |
| serviceAccount.create                         | Specifies whether a service account should be created for Analytics Server pods                                                                                                                                                         | true                      |
| serviceAccount.annotations                    | Annotations to add to the service account                                                                                                                                                                                               | {}                        |
| serviceAccount.name                           | The name of the service account to use. If not set and create is true, a name is generated using the fullname template                                                                                                                  | ""                        |
| podAnnotations                                | Annotations added to the Analytics Server pods                                                                                                                                                                                          | {}                        |
| podSecurityContext                            | Security context for the Analytics Server pods                                                                                                                                                                                          | {}                        |
| securityContext                               | Security context for the Analytics Server containers                                                                                                                                                                                    | {}                        |
| initContainer.registry                        | The registry for the init container's image                                                                                                                                                                                             |                           |
| initContainer.image                           | The image to run init scripts. Must be capable of running bash files and curl queries. If not provided the Analytics Server image is used.                                                                                              | ""                        |
| initContainer.tag                             | Tag of the init container's image                                                                                                                                                                                                       | ""                        |
| service.type                                  | Type of the Analytics Server service                                                                                                                                                                                                    | ClusterIP                 |
| service.port                                  | The port on which Analytics Server is available in the containers. Need to match what is in `conf.wrapper.conf`.                                                                                                                        | 8181                      |
| ingress.enabled                               | Set to true to enable ingress object creation for the Analytics Server service                                                                                                                                                          | false                     |
| ingress.className                             | The ingress class to use for the ingress object                                                                                                                                                                                         | ""                        |
| ingress.annotations                           | Annotations added to the ingress object. Check your Ingress controllers annotations for configuring your ingress object.                                                                                                                | {}                        |
| ingress.hosts                                 | The ingress rules to use                                                                                                                                                                                                                | []                        |
| ingress.hosts.[].host                         | The host the rule applies to                                                                                                                                                                                                            |                           |
| ingress.hosts.[].paths                        | The paths used for the given host. All map to the Analytics Server service.                                                                                                                                                             |                           |
| ingress.hosts.[].paths.[].path                | A path to map to the Analytics Server service with the given host                                                                                                                                                                       |                           |
| ingress.hosts.[].paths.[].pathType            | The type of the given path. Determines path matching behaviour.                                                                                                                                                                         |                           |
| ingress.tls                                   | Ingress TLS configurations                                                                                                                                                                                                              | []                        |
| ingress.tls.[].secretName                     | The TLS secret to use with the given hosts. For how to create the secret, check the [Kubernetes documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls).                                                   |                           |
| ingress.tls.[].hosts                          | A list of hosts using the secret                                                                                                                                                                                                        |                           |
| resources                                     | Resource requests and limitations for the Analytics Server containers. For more detail on how you can calculate your resource requirements, see the [Resource requirements section](#resource-requirements).                            |                           |
| resources.requests.ephemeral-storage          | The ephemeral storage requested for the Analytics Server containers                                                                                                                                                                     | 2Gi                       |
| autoscaling.enabled                           | Set to true to enable horizontal pod autoscaling for the Analytics Server pods                                                                                                                                                          | false                     |
| autoscaling.minReplicas                       | The lower limit for the number of replicas to which the autoscaler can scale down                                                                                                                                                       | 1                         |
| autoscaling.maxReplicas                       | The upper limit for the number of pods that can be set by the autoscaler                                                                                                                                                                | 100                       |
| autoscaling.targetCPUUtilizationPercentage    | The target average CPU utilization (represented as a percentage of requested CPU) over all the pods                                                                                                                                     | 80                        |
| autoscaling.targetMemoryUtilizationPercentage | The target average memory utilization (represented as a percentage of requested memory) over all the pods                                                                                                                               | 80                        |
| nodeSelector                                  | Selector which must match a node's labels for the Analytics Server pods to be scheduled on that node                                                                                                                                    | {}                        |
| tolerations                                   | Tolerations for Analytics Server pods                                                                                                                                                                                                   | []                        |
| affinity                                      | Affinity constraints for Analytics Server pods                                                                                                                                                                                          | {}                        |
| probes.initialDelaySeconds                    | Number of seconds after the container has started before liveness/readiness probes are initiated                                                                                                                                        | 60                        |
| probes.timeoutSeconds                         | Number of seconds after which the liveness/readiness probe times out                                                                                                                                                                    | 5                         |
| probes.periodSeconds                          | How often to perform the liveness/readiness probe                                                                                                                                                                                       | 30                        |
| probes.failureThreshold                       | Minimum consecutive failures for the liveness/readiness probe to be considered failed after having succeeded                                                                                                                            | 3                         |

## Analytics Roots extraction parameters

| Name                                    | Description                                                                                                                                                | Value         |
|-----------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------|
| roots.version.rex                       | The version of the REX root                                                                                                                                | 7.56.2.c79.0 |
| roots.version.rbl                       | The version of the RBL root                                                                                                                                | 7.47.9.c79.0 |
| roots.version.rli                       | The version of the RLI root                                                                                                                                | 7.23.18.c79.0 |
| roots.version.tvec                      | The version of the TVEC root                                                                                                                               | 7.0.7.c79.0 |
| roots.version.rnirnt                    | The version of the RNI-RNT root                                                                                                                            | 7.51.0.c79.0 |
| roots.version.tcat                      | The version of the TCAT root                                                                                                                               | 3.0.6.c79.0 |
| roots.version.ascent                    | The version of the ASCENT root                                                                                                                             | 3.0.6.c79.0 |
| roots.version.nlp4j                     | The version of the NLP4J root                                                                                                                              | 2.0.6.c79.0 |
| roots.version.rct                       | The version of the RCT root                                                                                                                                | 3.0.24.c79.0 |
| roots.version.relax                     | The version of the RELAX root                                                                                                                              | 4.0.6.c79.0 |
| roots.version.topics                    | The version of the TOPICS root                                                                                                                             | 4.0.4.c79.0 |
| enabledEndpoints                        | A list of Analytics Server endpoints to enable.  When passed as a command line property; comma separated and no spaces.                                    | {language}    |
| enabledLanguages                        | A list of languages to be enabled for roots split by languages.  When passed as a command line property; comma separated and no spaces.                    | {eng}         |
| rootsImageRepository                    | The repository prefix to use when downloading Analytics Roots images. The default "rosette/" will download from DockerHub                                  | "rosette/"    |
| rootsExtraction.upgrade.annotations     | Annotations for the Analytics Roots extraction job that runs during install and upgrade. If not defined the appropriate helm hook annotations are applied. | {}            |
| rootsExtraction.upgrade.podAnnotations  | Annotations for the Analytics Roots extraction job's pod that runs during install and upgrade.                                                             | {}            |
| rootsExtraction.rollback.annotations    | Annotations for the Analytics Roots extraction job that runs during rollback. If not defined the appropriate helm hook annotations are applied.            | {}            |
| rootsExtraction.rollback.podAnnotations | Annotations for the Analytics Roots extraction job's pod that runs during rollback.                                                                        | {}            |
## Persistent Volume Permissions Parameters

| Name                                                  | Description                                                                                                                                      | Value          |
|-------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|----------------|
| volumePermissions.enabled                             | Run the Init Container that sets permissions for the root extraction directory.  Will also set the security context for the root extraction pod. | false          |
| volumePermissions.initContainer.runAsUserId           | The user ID that the container process should run as.                                                                                            | 0              |
| volumePermissions.initContainer.imagePullPolicy       | The pull policy for the image.                                                                                                                   | "IfNotPresent" |
| volumePermissions.rootVolume.chown.userId             | The user ID to pass to `chown`                                                                                                                   | 2001           |
| volumePermissions.rootVolume.chown.groupId            | The group ID to pass to `chown`                                                                                                                  | 0              |
| volumePermissions.rootVolume.chmod.octalMode          | The octal model to pass to `chmod`. The Analytics Server container needs at least read and execute permissions on the roots volume.              | 775            |
| volumePermissions.securityContext.fsGroup             | The fsGroup group ID to use in the root extraction security context                                                                              | ""             |
| volumePermissions.securityContext.fsGroupChangePolicy | The change policy to use in the root extraction security context                                                                                 | ""             |

## Overrides for configurations located in Root storage parameters

| Name                                  | Description                                                                                                                                                                                                                             | Value |
|---------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------|
| rootsOverride.enabled                 | Set to true to enable custom override logic for configurations inside the root directories, that supports helm upgrade/rollback. More details are in the [Root configurations override section](#root-configurations-overrides).        | false |
| rootsOverride.overrideVolumeClaimName | A preexisting volume claim's name (in the namespace of the release), prepopulated with the config files/directories used for *override*, or *addition* operations. If not defined *addition* and *override* operations will be skipped. | ""    |
| rootsOverride.backupVolumeClaimName   | A preexisting volume claim's name (in the namespace of the release), where rollback information should be saved. If not defined rollback information is saved to the Analytics Roots volume.                                            | ""    |
| rootsOverride.separator               | A character sequence not included in any of the file paths                                                                                                                                                                              | "&&&" |
| rootsOverride.delete                  | A list of *deletion* operations to delete a file or directory from an Analytics Root                                                                                                                                                    | []    |
| rootsOverride.delete.[].root          | The name of the root where the entry should be deleted from                                                                                                                                                                             |       |
| rootsOverride.delete.[].targetPath    | The path under the `<root>/<version>` directory to the entry to be deleted. Must be a valid file or directory.                                                                                                                          |       |
| rootsOverride.add                     | A list of *addition* operations to add a file or directory to an Analytics Root                                                                                                                                                         | []    |
| rootsOverride.add.[].root             | The name of the root where the entry should be added to                                                                                                                                                                                 |       |
| rootsOverride.add.[].targetPath       | The path under the `<root>/<version>` directory where the entry should be added. A file or directory must not exist on that path.                                                                                                       |       |
| rootsOverride.add.[].originPath       | The path in the override volume where the entry should be copied from                                                                                                                                                                   |       |
| rootsOverride.override                | A list of *override* operations to override a file or directory in an Analytics Root                                                                                                                                                    | []    |
| rootsOverride.override.[].root        | The name of the root where the entry should be overwritten                                                                                                                                                                              |       |
| rootsOverride.override.[].targetPath  | The path under the `<root>/<version>` directory where the entry should be overwritten. Must be a valid file or directory.                                                                                                               |       |
| rootsOverride.override.[].originPath  | The path in the override volume where the entry should be copied from. The entry must be the same type (file or directory) as the target                                                                                                |       |

## Analytics Server parameters

| Name                          | Description                                                                                                                                                                                                        | Value           |
|-------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------|
| licenseSecretName             | The name of a secret created from the Analytics License file                                                                                                                                                       | ""              |
| storageClassName              | The storage class of the Analytics Roots persistent volume claim. Immutable after installation.                                                                                                                    | ""              |
| rootsVolumeName               | The name of the persistent volume the Analytics Roots persistent volume claim should bind to. Immutable after installation.                                                                                        | ""              |
| rootsAccessMode               | The access mode of the Analytics Roots persistent volume claim. Can be ReadWriteOnce or ReadWriteMany. Immutable after installation.                                                                               | "ReadWriteMany" |
| rootsResourceRequest          | The requested storage size for the Analytics Roots persistent volume claim. For more detail on how you can calculate your storage requirements, see the [Resource requirements section](#disk-space-requirements). | "150Gi"         |
| rootsUseSelectorLabels        | Set to true to use the selector labels for the Analytics Roots persistent volume claim.                                                                                                                            | "true"          | 
| customProfilesVolumeClaimName | A persistent volume claim that is bound to a persistent volume with the custom profile directories                                                                                                                 | ""              | 
| conf                          | Analytics Server logging and Tanuki Wrapper configuration files                                                                                                                                                    |                 |
| conf.java_opts.conf           | A file used by Tanuki internally                                                                                                                                                                                   |                 |
| conf.log4j2.xml               | The log4j logger's configuration file used by the Analytics Server instance                                                                                                                                        |                 |
| conf.logging.properties       | Logging properties file supplied to the JVM                                                                                                                                                                        |                 |
| conf.wrapper.conf             | The Tanuki Wrapper's configuration file                                                                                                                                                                            |                 |
| conf.wrapper-license.conf     | The Tanuki configuration file. Do not change.                                                                                                                                                                      |                 |
| config                        | Analytics Server system configuration files. For more detail see the [User Guide](https://docs.babelstreet.com/Extract/en/rosette-server-user-guide.html#system-configuration-files)                               |                 |
| rosapi                        | Individual endpoint configuration files. For more detail see the [User Guide](https://docs.babelstreet.com/Extract/en/rosette-server-user-guide.html#endpoint-and-transport-rules-configuration-files)             |                 |

## Indoc Coref Server parameters
The Indoc Coref Server enhances the Entity Extractor's results by finding coreferences of the entities.
When enabled, a deployment of the Indoc Coref Server will be deployed alongside the Analytics Server deployment, which is automatically configured to be able to
communicate with it. The Indoc Coref Server is deployed as a subchart. By default, it only has the `indoccoref.enabled` parameter in the Analytics Server **values.yaml**,
but it can be further customized with the following parameters:

| Name                                                     | Description                                                                                                                                                                           | Default                  |
|----------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------|
| indoccoref.enabled                                       | Enables the Indoc Coref Server deployment                                                                                                                                             | false                    |
| indoccoref.replicaCount                                  | Number of desired Indoc Coref Server pods                                                                                                                                             | 1                        |
| indoccoref.image.registry                                | The registry for the Indoc Coref Server image                                                                                                                                         |                          |
| indoccoref.image.repository                              | The repository and image name for the Indoc Coref Server containers                                                                                                                   | rosette/fastcoref-server |
| indoccoref.image.pullPolicy                              | The pull policy for the Indoc Coref Server image                                                                                                                                      | IfNotPresent             |
| indoccoref.image.tag                                     | The tag of the Indoc Coref Server image. If not provided uses default version for the accompanying Analytics Server                                                                   | ""                       |
| indoccoref.imagePullSecrets                              | An optional list of references to secrets in the same namespace to use for pulling the Indoc Coref Server image.                                                                      | []                       |
| indoccoref.nameOverride                                  | String to partially override indoc-coref.fullname template used in naming Kubernetes objects. The release name will be maintained.                                                    | ""                       |
| indoccoref.fullnameOverride                              | String to override indoc-coref.fullname template used in naming Kubernetes objects                                                                                                    | ""                       |
| indoccoref.serviceAccount.create                         | Specifies whether a service account should be created for Indoc Coref Server pods                                                                                                     | true                     |
| indoccoref.serviceAccount.annotations                    | Annotations to add to the service account                                                                                                                                             | {}                       |
| indoccoref.serviceAccount.name                           | The name of the service account to use. If not set and create is true, a name is generated using the fullname template                                                                | ""                       |
| indoccoref.podAnnotations                                | Annotations added to the Indoc Coref Server pods                                                                                                                                      | {}                       |
| indoccoref.podLabels                                     | Labels added to the Indoc Coref Server pods                                                                                                                                           | {}                       |
| indoccoref.podSecurityContext                            | Security context for the Indoc Coref Server pods                                                                                                                                      | {}                       |
| indoccoref.securityContext                               | Security context to for the Indoc Coref Server containers                                                                                                                             | {}                       |
| indoccoref.service.type                                  | Type of the Indoc Coref Server service                                                                                                                                                | ClusterIP                |
| indoccoref.service.port                                  | The port on which Indoc Coref Server is available in the containers. For the base image this is `5000`.                                                                               | 5000                     |
| indoccoref.ingress.enabled                               | Set to true to enable ingress object creation for the Indoc Coref Server service                                                                                                      | false                    |
| indoccoref.ingress.className                             | The ingress class to use for the ingress object                                                                                                                                       | ""                       |
| indoccoref.ingress.annotations                           | Annotations added to the ingress object. Check your Ingress controllers annotations for configuring your ingress object.                                                              | {}                       |
| indoccoref.ingress.hosts                                 | The ingress rules to use                                                                                                                                                              | []                       |
| indoccoref.ingress.hosts.[].host                         | The host the rule applies to                                                                                                                                                          |                          |
| indoccoref.ingress.hosts.[].paths                        | The paths used for the given host. All map to the Indoc Coref Server service.                                                                                                         |                          |
| indoccoref.ingress.hosts.[].paths.[].path                | A path to map to the Indoc Coref Server service with the  given host                                                                                                                  |                          |
| indoccoref.ingress.hosts.[].paths.[].pathType            | The type of the given path. Determines path matching behaviour.                                                                                                                       |                          |
| indoccoref.ingress.tls                                   | Ingress TLS configurations                                                                                                                                                            | []                       |
| indoccoref.ingress.tls.[].secretName                     | The TLS secret to use with the given hosts. For how to create the secret, check the [Kubernetes documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls). |                          |
| indoccoref.ingress.tls.[].hosts                          | A list of hosts using the secret                                                                                                                                                      |                          |
| indoccoref.resources                                     | Resource requests and limitations for the Indoc Coref Server containers.                                                                                                              | {}                       |
| indoccoref.autoscaling.enabled                           | Set to true to enable horizontal pod autoscaling for the Indoc Coref Server pods                                                                                                      | false                    |
| indoccoref.autoscaling.minReplicas                       | The lower limit for the number of replicas to which the autoscaler can scale down                                                                                                     | 1                        |
| indoccoref.autoscaling.maxReplicas                       | The upper limit for the number of pods that can be set by the autoscaler                                                                                                              | 100                      |
| indoccoref.autoscaling.targetCPUUtilizationPercentage    | The target average CPU utilization (represented as a percentage of requested CPU) over all the pods                                                                                   | 80                       |
| indoccoref.autoscaling.targetMemoryUtilizationPercentage | The target average memory utilization (represented as a percentage of requested memory) over all the pods                                                                             | 80                       |
| indoccoref.nodeSelector                                  | Selector which must match a node's labels for the Indoc Coref Server pods to be scheduled on that node                                                                                | {}                       |
| indoccoref.tolerations                                   | Tolerations for Indoc Coref Server pods                                                                                                                                               | []                       |
| indoccoref.affinity                                      | Affinity constraints for Indoc Coref Server pods                                                                                                                                      | {}                       |

## API keys parameters
By default, no authorization is required when making calls to Analytics Server. If required, you can turn on
API key protection for the endpoints by setting `apikeys.enabled` to true. This will start a database server StatefulSet
alongside the Analytics Server deployment. It will also update the configuration provided through `config.com.basistech.ws.apikeys.cfg`
so that the Analytics Server pods will connect to this database. This means the following values are overwritten:
- dbConnectionMode
- dbURI
- dbName
- dbUser
- dbPassword
- dbSSLMode

Enabling the feature will also create a cronjob that regularly creates a backup of the database

The apikeys also need a PVC to store the database and its backups. It's name must be provided in the 
`apikeys.persistentVolumeClaimName` parameter. If the PVC already contains a database with the name 
provided by `apikeys.dbName`, it will be used, otherwise a new database will be created. Databases are searched and stored
in the root directory of the PVC. The PVC's root directory must have read and write permissions for `2001:0`. The 
`apikeys.volumePermissionOverride` section can be used to add read, write and execute permissions to all users for the 
root directory of the PVC and read, write permissions for all files contained immediately in it. 

The following parameters can be used to further customize the API key behavior:

| Name                                     | Description                                                                                                                                                                       | Default                                                   |
|------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------|
| apikeys.enabled                          | Enables the API key protection for the Analytics Server endpoints.                                                                                                                | false                                                     |
| apikeys.persistentVolumeClaimName        | The PVC where the database file and its backups should be stored. A valid PVC must be provided.                                                                                   | ""                                                        |
| apikeys.volumePermissionOverride.enabled | Enables the init container to add write permissions to the files in the root directory of the database PVC.                                                                       | false                                                     |
| apikeys.volumePermissionOverride.userId  | The userId to use in the volume permissions override init container.                                                                                                              | 0                                                         |
| apikeys.dbName                           | The name of the database to be used for the API keys.                                                                                                                             | apikeys                                                   |
| apikeys.dbAccessSecretName               | The name of the secret containing the database access credentials. It must have a values with the keys `username` and `password`.                                                 | ""                                                        |
| apikeys.backup.cronSchedule              | The cron schedule for the database backup job. Defaults to an hourly schedule.                                                                                                    | "0 * * * *"                                               |
| apikeys.backup.restartPolicy             | The restart policy for the database backup job's pod.                                                                                                                             | Never                                                     |
| apikeys.backup.ttlSecondsAfterFinished   | The time after completed/failed backup jobs are deleted.                                                                                                                          | 600                                                       |
| apikeys.backup.backoffLimit              | The number of retries before the backup job is considered failed.                                                                                                                 | 3                                                         |
| apikeys.upgradeTimeoutSeconds            | How long to wait for the database server to be upgraded/rolled back/installed, before failing the operation. Separately applied to 2 wait processes.                              | 300                                                       |
| apikeys.hookAnnotations                  | Annotations for the database server scaling hook job. Should make sure to scale down the database server StatefulSet to 1 replica after every install/upgrade/rollback operation. | Defaults to scale down to 1 replica after every operation |
| apikeys.service.type                     | The type of the service for the database server StatefulSet.                                                                                                                      | ClusterIP                                                 |
| apikeys.service.port                     | The port of the service for the database server StatefulSet.                                                                                                                      | 5432                                                      |
| apikeys.clusterDomain                    | The cluster domain. Needed so Analytics Server pods can find the individual database server pods. Change it if it is different in your cluster.                                   | cluster.local                                             |
| apikeys.serviceAccount.create            | Specifies whether a service account should be created for the database server pods.                                                                                               | true                                                      |
| apikeys.serviceAccount.annotations       | Annotations to add to the service account.                                                                                                                                        | {}                                                        |
| apikeys.serviceAccount.name              | The name of the service account to use. If not set and create is true, a name is generated using the fullname template.                                                           | ""                                                        |
| apikeys.podAnnotations                   | Annotations added to the database server pods.                                                                                                                                    | {}                                                        |
| apikeys.podLabels                        | Labels added to the database server pods.                                                                                                                                         | {}                                                        |
| apikeys.podSecurityContext               | Security context for the database server pods.                                                                                                                                    | {}                                                        |
| apikeys.securityContext                  | Security context for the database server container.                                                                                                                               | {}                                                        |
| apikeys.resources                        | Resource requests and limitations for the database server container.                                                                                                              | {}                                                        |
| apikeys.nodeSelector                     | Selector which must match a node's labels for the database server pods to be scheduled on that node.                                                                              | {}                                                        |
| apikeys.tolerations                      | Tolerations for the database server pods.                                                                                                                                         | []                                                        |
| apikeys.affinity                         | Affinity constraints for the database server pods.                                                                                                                                | {}                                                        |
| apikeys.probes.initialDelaySeconds       | Number of seconds after the container has started before liveness/readiness probes are initiated for the database server.                                                         | 5                                                         |
| apikeys.probes.timeoutSeconds            | Number of seconds after which the liveness/readiness probe times out for the database server.                                                                                     | 10                                                        |
| apikeys.probes.periodSeconds             | How often to perform the liveness/readiness probe for the database server.                                                                                                        | 10                                                        |
| apikeys.probes.failureThreshold          | Minimum consecutive failures for the liveness/readiness probe to be considered failed after having succeeded for the database server.                                             | 3                                                         |

### Connecting to the API key management console
Using the official Analytics Server image, the API key management console will be available in all pods. You can access it
by using the following bash script. Before you run it make sure to update the RELEASE_NAME variable to the name of your release.:
```bash
RELEASE_NAME=<YOUR_RELEASE_NAME>

POD_ID=$(kubectl get pods -l app.kubernetes.io/instance=$RELEASE_NAME,app.kubernetes.io/component=restful-server -o jsonpath='{.items[0].metadata.name}')

kubectl exec -it $POD_ID -- /rosette/server/bin/rosette-apikeys
```

On Windows you should be able to use the following batch script. Before you run it make sure to update the RELEASE_NAME 
variable to the name of your release.:

```bat
set "RELEASE_NAME=<YOUR_RELEASE_NAME>"

for /f "tokens=*" %%i in ('kubectl get pods -l "app.kubernetes.io/instance=%RELEASE_NAME%,app.kubernetes.io/component=restful-server" -o "jsonpath="{.items[0].metadata.name}""') do set "POD_ID=%%i"

kubectl exec -it %POD_ID% -- /rosette/server/bin/rosette-apikeys
```

If you are connecting to an API key management console after running an upgrade/rollback, make sure you connect through a
pod that has the latest configuration. Otherwise, it might connect to the wrong database (if it was changed in the update)
and the console will close when the pod is destroyed.

### Create a database access secret
To create a secret with the database access credentials, you can use the following command:
```bash
kubectl create secret generic --from-literal=username=<USER> --from-literal=password=<PASSWORD> <SECRET-NAME>
```
### Limitations
If the database server pod fails to launch successfully (for example due to wrong database credentials being provided), 
manual intervention is required because of a [kubernetes known issue](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#forced-rollback).
After upgrading or rolling back the chart the failing pod needs to be deleted. The following command can be used to find the failing pod:
```bash
kubectl get pods -l app.kubernetes.io/instance=<YOUR-RELEASE-NAME>,app.kubernetes.io/component=apikeys-db-server
```

The database backups are created on the same PVC the database is located at also.

The info endpoint must be left unprotected as it is used by the health probes of the Analytics Server pods. Because of 
this when the configuration is updated at the pod startup, the info endpoint will always be added to the unsecured endpoints.

To achieve zero-downtime during updates (rollback or upgrade), a secondary database server is started which will be running while the main 
database server is updating. Changes that are only handled by this server are not persisted. Because of this **the key
management console should not be used during updates**. Analytics Server should work fine with the secondary database.

**There is a known issue** with Analytics Server, where during updates if the server is under constant load, it cannot 
release the closed connections from its database connection pool. This can lead to 401 responses from Analytics Server while
the load persists. To avoid this:
- Try to limit requests to Analytics Server during updates.
- Run multiple replicas of Analytics Server. This does not guarantee to solve the issue entirely, there will be stray 401
responses, but the issue will resolve itself relatively quickly.

If the database server pod crashes, the Analytics Server requests will hang, and may return 401 responses, even if the database
server comes back online during the 30 seconds database connection timeout period.

# Analytics Roots extraction
This chart needs a persistent volume to store the Analytics Roots. It can be provided in two ways:
- By setting `rootsVolumeName` and `storageClassName`, you can provide a previously created Persistent Volume that has the matching name and storage class.
- By setting `storageClassName` to a storage class that is capable of dynamic provisioning and leaving `rootsVolumeName` empty.

The `storageClassName`, `rootsVolumeName` and `rootsAccessMode` properties are immutable after installation.

The roots needed for your selected endpoints and languages will be automatically extracted to the persistent volume backing the persistent volume claim
managed by the chart. This happens in a post hook job. The job uses the rosette/root images to check if the extraction of a given root is needed and to extract it.
This can be a time-consuming process, especially if the images have to be pulled as well. The job gets terminated when the helm release times out, so make
sure the [timeout](https://helm.sh/docs/intro/using_helm/#helpful-options-for-installupgraderollback) on the helm command provides enough time for the process to finish considering your system resources.

To allow the root extraction process to work properly, `rootsAccessMode` should, preferably, be `ReadWriteMany`. If the persistent volume doesn't allow `many` access, `ReadWriteOnce`
works as well. In this case, the job is scheduled to the same node as the Analytics Server pod(s), with a required affinity. Make sure that this node has enough
resources for the job, otherwise a deadlock situation can arise if the extraction of new roots are expected.

The Analytics Server startup fails if all required roots are not found, so the Analytics Server pods might restart a few times while the root extraction is ongoing. During the extraction of the
last root, Analytics Server will be able to start up, but endpoints relying on the root being extracted will fail if they receive a request before the extraction is complete.
To recover from this possible state, once all the extractions complete the Analytics Server deployment is updated to register any potential changes. To make this possible it uses a
service account which is able to patch the Analytics Server deployment.

## Root configurations overrides
There might be some need to change/add/delete some files from the Analytics Roots. For example the Names services have some configuration files inside their root and
the Entity Extractor can be customized by adding [new gazetteer or regex files to its root](https://docs.babelstreet.com/Extract/en/entity-extractor.html#modifying-entity-extraction-processors).
The `rootsOverride` section (and the corresponding functionality) in **values.yaml** aims to help make these file changes inside the Analytics Roots in a way, that works with the helm update/rollback process.
The functionality is disabled by default, and can be enabled by setting `rootsOverride.enabled` to true. It has 3 possible operations:

- *deletion*: Deletes a file or directory inside a root's directory if one exists at the specified path
- *addition*: Adds a file or directory inside a root's directory if one doesn't already exist at the specified path
- *override*: Replaces a file or directory inside a root's directory if one exists at the specified path

The operations run in the above mentioned order. All operations have 2 common parameters:
- `root`: The name of the Analytics Root, in which the files should be changed. Possible values are the same as the keys of `roots.version` in **values.yaml**.
- `targetPath`: The path inside the `<root>/<version>` directory where the operation should be done. Cannot contain `..`. Leading `/` is ignored. Cannot be empty.

The *addition* and *override* operations require a volume which has been prepopulated with the files or directories to be added/to be used for overriding. A volume claim bounded to this volume
must be provided with `rootsOverride.overrideVolumeClaimName`. These operations also have a third parameter:
- `originPath`: The path inside the override volume to the file/directory to be used for the addition/override. Leading `/` is ignored. Cannot be empty.

All operations are done in the currently active Analytics Root versions only.

A backup volume can be provided to the functionality through its volume claim set in `rootsOverride.backupVolumeClaimName`. If one is not provided but the functionality is enabled,
a backup directory will be created in the Analytics Roots volume. Every release with the functionality enabled will create a new directory with the release name in the backup volume.
If a directory with the release name already exists (e.g.: from a previously deleted release) when a new release is installed, the old directory is pruned before a new one is created.
The backup volume should not be changed after the functionality is enabled.

### Limitations
- Editing files in the Analytics Roots volume without the use of this functionality when it is enabled, can lead to unrecoverable errors!
- Successful rollback after a failed upgrade(s) can lead to future inconsistencies
- If the functionality was enabled when a release was deleted with --keep-history, rollback will only work if the same volume is attached to it
- If the functionality was enabled when a release was deleted and the same backup volume is used for a new release with the same name, the functionality must be enabled

### `/entities` gazetteer example
The following example showcases how the root configuration override functionality can be used to change the behaviour of the `/entities` endpoint.
You will need a license that includes the `/entities` endpoint.

- Setup before installing the chart
    - Create a PV for override files in the cluster, and a corresponding PVC in the namespace the chart will be installed in.
    - Create two files in that volume:
        ```
        cat > pizza.txt << EOF
        FOOD
        Pizza
        pizza
        EOF
        ```
        ```
        cat > morefood.txt << EOF
        FOOD
        Pizza
        pizza
        Lasagna
        lasagna
        EOF
        ```
- [Install the chart](#installation)
    - During the installation, make sure the `/entities` endpoint and `rootsOverride.enabled` are enabled, and `rootsOverride.overrideVolumeClaimName` is set to the previously created PVC.
- Make an `/entities` request to observe the default behavior.  The response should return a single entity of type `LOCATION` for `Italy`.
  ```
  curl -H "content-type: application/json" \
       -d '{"content":"Pizza and lasagna originates from Italy"}' \
       <analytics-server-service>/rest/v1/entities
  ```
- Add the `pizza.txt` gazetteer to the installation.
    - Add the following to `rootsOverride` (or uncomment it in the original) **values.yaml**:
        ```
          add:
            - root: "rex"
              targetPath: "/data/gazetteer/eng/accept/food.txt"
              originPath: "pizza.txt"
        ```
    - Run a `helm upgrade`
    - Once the requests are directed to the new pods (the ones that started when the root extraction job finished - should not take more than 2-3 minutes), rerun the previous `curl` request
    - The response should still include the `Italy` entity, but also a `FOOD` entity for `Pizza`.
- Override the gazetteer with `morefood.txt`
    - Remove the `add` element from `rootsOverride` and add (or uncomment in the original):
        ```
          override:
            - root: "rex"
              targetPath: "/data/gazetteer/eng/accept/food.txt"
              originPath: "morefood.txt"
        ```
    - Run a `helm upgrade`
    - Once the requests are directed to the new pods (the ones that started when the root extraction job finished - should not take more than 2-3 minutes), rerun the previous `curl` request
    - The response should still include the `Italy` and `Pizza` entities, but `lasagna` should also be an entity of the `FOOD` type.
- Remove changes
    - Remove the `override` element from `rootsOverride` and add (or uncomment in the original):
        ```
          delete:
            - root: "rex"
              targetPath: "/data/gazetteer/eng/accept/food.txt"
        ```
    - Run a `helm upgrade`
    - Once the requests are directed to the new pods (the ones that started when the root extraction job finished - should not take more than 2-3 minutes), rerun the previous `curl` request
    - The response should only include `Italy`.

#### Rollbacks
At this point if you run
```
helm rollback <release>
```
or
```
helm rollback <release> 3
```
the request should return with both `FOOD` types in it.  Running
```
helm rollback <release> 2
```
should return with only `Pizza` being identified as a `FOOD`.

# Custom profiles
To use custom profiles with Analytics Server, set `customProfilesVolumeClaimName` to a persistent volume claim in the same namespace as the chart.
When this value is set the volume will be mounted into the Analytics Server pods, so make sure if using multiple Analytics Server pods that the volume has read access for many. 
The Analytics Server instances will automatically be configured to use this volume as their `profile-data-root` directory. Any other configuration changes 
(like rosapi.feature.CUSTOM_PROFILE_UNDER_APP_ID) must be made in their respective configuration files.
Read more about Analytics Server's custom profiles at the [official documentation](https://docs.babelstreet.com/Extract/en/rosette-server-user-guide.html#custom-profiles).

## Data paths for custom profiles
Profiles can include custom data sets, for example the entities endpoint can be enriched with custom gazetteers or regexes.
Entities can be configured to use these files by providing `dataOverlayDirectory` in the `rex-factory-config.yaml` file.
These files should be on the same PVC as the custom profiles. Their path in the container will be `/rosette/server/custom-profiles`.
As this path might change in the future, starting with Analytics Server 1.31.0 (helm chart version 1.3.0) you should use 
the `${profile-root}` variable in your configuration files.

### Example
Assuming you have a directory structure like the following on your custom profiles PVC:
```
my-profile
| - config
   \ - rosapi
        \ - rex-factory-config.yaml
\ - data
    | ...
```
You would want to set your `dataOverlayDirectory` in the `rex-factory-config.yaml` to either `file:///rosette/server/custom-profiles/my-profile/data` 
or `file://${profile-root}/my-profile/data`.
# Resource requirements

## Memory requirements

The following table details the JVM heap memory requirements needed by the different endpoints.
If the container reaches its memory limit, it sends a SIGKILL to the JVM process running Analytics Server, which then gets restarted.
The model files for each endpoint are memory mapped outside the JVM heap.  In addition to the memory selected for the heap,
you should select enough excess memory to allow most of the models to be memory mapped.

| Endpoint                                                           | Min Memory | Note                                                                                       |
|--------------------------------------------------------------------|------------|--------------------------------------------------------------------------------------------|
| categories                                                         | 1GB        | add 1.5GB if morphology is not already enabled                                             |
| dependencies                                                       | 0.4GB      |                                                                                            |
| entities                                                           | 1GB        | add 1.5GB if morphology is not already enabled                                             |
| language                                                           | 0.25GB     |                                                                                            |
| morphology, sentences, tokens, semantics/similar, semantics/vector | 1.5GB      |                                                                                            |
| name-deduplication                                                 | 2GB        | add 2GB if neither name-similarity or name-translation is on                               |
| name-similarity                                                    | 2GB        | combined with name-translation                                                             |
| name-translation                                                   | 2GB        | combined with name-similarity                                                              |
| address-similarity                                                 | 3GB        |                                                                                            |
| relationships                                                      | 3GB        | add 1.5GB if morphology is not already enabled; add 1GB if entities is not already enabled |
| sentiment                                                          | 1GB        | add 1.5GB if morphology is not already enabled; add 1GB if entities is not already enabled |
| topics                                                             | 1.5GB      | add 1.5GB if morphology is not already enabled; add 1GB if entities is not already enabled |
| transliteration                                                    | 0.5GB      |                                                                                            |

## Disk space requirements

To support `upgrade` and `rollback` actions, ensure your volume has **at least** twice the required storage.

Base Linguistics and Language Identification are always extracted for base functionality. These take up **5GB** and cover the
`/language`, `/morphology`, `/sentences`, `/tokens` endpoints. The following table details the disk space requirements for the rest of the endpoints.
If 2 endpoints require the same root, it will only be extracted once. 
(e.g.: if topics and sentiment are enabled, they would require 59.75GB. 3GB for ascent, 1.75 for topics, and 55GB for rex shared by both endpoints )

| Endpoint           | Roots size | Roots                                                |
|--------------------|------------|------------------------------------------------------|
| address-similarity | 8GB        | rni-rnt                                              |
| categories         | 0.15GB     | tcat                                                 |
| dependencies       | 0.75GB     | nlp4j                                                |
| entities           | 55GB       | rex - all languages                                  |
| name-deduplication | 8GB        | rni-rnt                                              |
| name-similarity    | 8GB        | rni-rnt                                              |
| name-translation   | 8GB        | rni-rnt                                              |
| relationships      | 56.75GB    | relax(1GB), rex - all languages(55GB), nlp4j(0.75GB) |
| semantics          | 22GB       | tvec - all languages                                 |
| sentiment          | 58GB       | ascent(3GB)   rex - all languages(55GB)              |
| topics             | 56.75GB    | topics(1.75GB) rex - all languages(55GB)             |
| transliteration    | 1.75GB     | rct                                                  |

# Analytics Roots storage examples
## hostPath
### Important
`hostPath` volumes are node specific, so in a multinode cluster if the pod gets rescheduled to another node, the contents of the volume need to be repopulated on that node as well.
In a multinode cluster if `rootsAccessMode` is set to `ReadWriteOnce`, the job will be required to schedule on the same node as the Analytics Server pod, but in other cases
the unpacking of the roots cannot be guaranteed to happen on the same node where the Analytics Server pod will be scheduled.
To read more about hostpath volumes, visit the [Kubernetes documentation](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath)

This storage type is only recommended for non-production installs.

### Example
There are a variety of possible `hostPath` provisioners. All of them provide their own steps to take when installing the provisioner. Make sure to follow the steps provided by your chosen provisoner. This example uses a [hostpath-provioner from ArtifactHUB](https://artifacthub.io/packages/helm/rimusz/hostpath-provisioner)

To install the provisioner in a cluster run:
```bash
helm repo add rimusz https://charts.rimusz.net
helm upgrade --install hostpath-provisioner rimusz/hostpath-provisioner
```
Then set `storageClassName` in **values.yaml** to `hostpath` or install the chart with
```bash
helm install <release name> \
     --set licenseSecretName=<license-secret> \
     --set storageClassName=hostpath \
     babelstreet/rosette-server
```
This will create directory for the Analytics roots persistent volume claim under `/mnt/hostpath`

To use a different directory to store the volumes in or a different name for the storage class the provisioner can be installed with
```bash
helm upgrade --install hostpath-provisioner rimusz/hostpath-provisioner \
             --set storageClass.name=<SC-name> \
             --set nodeHostPath=<Path to host dir>
```

The complete list of configuration options can be found at [ArtifactHUB](https://artifacthub.io/packages/helm/rimusz/hostpath-provisioner#configuration)
## GCP Persistent Disk
### [Storage provisioners in GCP](https://cloud.google.com/kubernetes-engine/docs/concepts/persistent-volumes#storageclasses)
GCP provides 2 provisioner engines for GKE clusters with preinstalled storage classes:
- [Compute Engine PD CSI](https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/gce-pd-csi-driver#create_a_storageclass) is a Compute Engine persistent disk based storage provisioner
- [Kubernetes Filestore CSI](https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/filestore-csi-driver#storage-class) is a Filestore instance based storage provisioner

Read more about [GCP Persistent Volumes and dynamic provisioning](https://cloud.google.com/kubernetes-engine/docs/concepts/persistent-volumes)

**WARNING:  Please note that GKE Autopilot clusters are not provisioned with sufficient resources to
launch a stack.**

#### Persistent Disk storage

The provided example uses the persistent disk approach. It dynamically provisions a balanced persistent disk, with the label `component: analytics-server`.
[See possible parameters for dynamically provisioned persistent disk.](https://github.com/kubernetes-sigs/gcp-compute-persistent-disk-csi-driver?tab=readme-ov-file#createvolume-parameters)

The following is the process to launch the chart with persistent disk storage:

- Make sure the GKE cluster has the driver
    - run `kubectl get csidriver`. The result should contain a driver with the name `pd.csi.storage.gke.io`.
    - if the driver is not installed follow the [instructions from Google](https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/gce-pd-csi-driver#enabling_the_on_an_existing_cluster)
    to install it
- Create a storage class from the provided example
    - create the file `gcp-persistent-disk-storage-class.yaml`
      ```
      cat > gcp-persistent-disk-storage-class.yaml << EOF
      apiVersion: storage.k8s.io/v1
      kind: StorageClass
      metadata:
        name: analytics-roots-gcp-pd-example-sc
      provisioner: pd.csi.storage.gke.io
      volumeBindingMode: WaitForFirstConsumer
      allowVolumeExpansion: true
      parameters:
        type: pd-balanced
        labels: component=analytics-server
      EOF
      ```
    - create the storage class
      ```
      kubectl create -f gcp-persistent-disk-storage-class.yaml
      ```
- Create a secret from a license file if one doesn't already exist
  ```
  kubectl create secret generic analytics-license-file --from-file=<path-to-license-file>
  ```
- Set up **values.yaml**
    - Set `licenseSecretName` to the name of the secret created from the license file
        - in the above example it would be `analytics-license-file`
    - Set `storageClassName` to `analytics-roots-gcp-pd-example-sc`
    - Set `rootsAccessMode` to `ReadWriteOnce` and `replicaCount` to `1`. The persistent disk driver doesn't support `ReadWriteMany`. This will force Kubernetes to schedule all pods to the same node.
        - Make sure that the node has enough resources to run the root extraction pod and 2 of the Analytics Server pods for rolling the deployment.
    - Set `rootsUseSelectorLabels` to `false`. The persistent disk driver doesn't support selector labels. 
    - Set the `probes` values to make sure the container has enough time to avoid a restart loop because the server doesn't have enough time to startup.
    - Set `rootsResourceRequest` depending on the number of [endpoints and languages enabled](#disk-space-requirements)
- Run `helm install`.
    - Depending on the number of endpoints and roots enabled the installation process can be lengthy so make sure to set a reasonable
    [timeout](https://helm.sh/docs/intro/using_helm/#helpful-options-for-installupgraderollback) considering your system resources.

## NFS server
### NFS storage class
Kubernetes does not have an internal NFS provisioner. To dynamically create persistent volumes using NFS the [documentation](https://kubernetes.io/docs/concepts/storage/storage-classes/#nfs) suggests 2 external providers.
- [NFS Ganesha server and external provisioner](https://github.com/kubernetes-sigs/nfs-ganesha-server-and-external-provisioner)
- [NFS subdir external provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner)

This example uses the subdirectory approach, which creates a directory for every dynamically provisioned PV inside the exported NFS directory.

### Set up an NFS server
#### Create NFS server virtual machine
This step is optional and is only required if an NFS server is not available in your environment. The concept for this example is that a virtual machine is created, started and then a directory is exported with NFS to all the Nodes in the cluster.

A virtual machine is used since it more closely mimics NFS servers which are typically appliances or machines rather than containers. Note, there are some containerized NFS servers that could be used if a container is required.

#### Set up of the VM
Once the VM instance is created and started, perform the following (one time setup)

##### Set up the directory for the roots:
```
sudo mkdir -p /var/nfsshare
sudo chmod -R 755 /var/nfsshare
sudo yum install -y nfs-utils
sudo chown nfsnobody:nfsnobody /var/nfsshare
```

##### Create an NFS Server:
Note `systemctl` typically doesn't run in a container which is another reason a VM was selected (ease of deployment):

**Enable the NFS services**
```
sudo systemctl enable rpcbind
sudo systemctl enable nfs-server
sudo systemctl enable nfs-lock
sudo systemctl enable nfs-idmap
```

**Expose the nfsshare directory**
```
echo -e "/var/nfsshare\t\t*(rw,sync,no_root_squash,no_all_squash)" | sudo tee --append /etc/exports
```

**Confirm the output**
```
$ cat /etc/exports
/var/nfsshare		*(rw,sync,no_root_squash,no_all_squash)
```

**Start the NFS services**
```
sudo systemctl start rpcbind
sudo systemctl start nfs-server
sudo systemctl start nfs-lock
sudo systemctl start nfs-idmap
```

##### Allow the NFS traffic through the firewall:
```
sudo firewall-cmd --permanent --zone=public --add-service=nfs
sudo firewall-cmd --permanent --zone=public --add-service=mountd
sudo firewall-cmd --permanent --zone=public --add-service=rpc-bind
```
##### Verify NFS is serving:
```
showmount -e localhost
```

### Set up the provisioner
Once the NFS server is accessible from the cluster, the provisioner needs to be installed. The easiest way is to use Helm, but the documentation describes [Kustomize](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner?tab=readme-ov-file#with-kustomize) and [Manual](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner?tab=readme-ov-file#manually) setup steps as well. This example uses the Helm install.
- To make the chart accessible for Helm, run:
  ```
  helm repo add nfs-subdir-external-provisioner \
       https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner

  helm install <release-name> \
       nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
       --set nfs.server=<NFS server Ip address or hostname> \
       --set nfs.path=<exported NFS server path> \
       --set storageClass.provisionerName=analytics-nfs-subdir-external-provisioner
  ```

Read more about the NFS chart and its possible parameters [here](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/blob/master/charts/nfs-subdir-external-provisioner/README.md).

### Create a storage class from the provided example
If the provisioner is installed with Helm, it will create a storage class, with the provided or default values. This example will not use this class, instead it will create a new one with the same provisioner.
- Create `nfs-storage-class.yaml` file
  ```
  cat > nfs-storage-class.yaml << 'EOF'
  apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
    name: analytics-roots-nfs-example-sc
  provisioner: analytics-nfs-subdir-external-provisioner
  parameters:
    pathPattern: "${.PVC.namespace}-${.PVC.name}"
    onDelete: delete
  EOF
  ```
- Run
  ```
  kubectl create -f nfs-storage-class.yaml
  ```

This storage class will create volumes backed by a newly created directory under the exported NFS directory. The directory name will be `<namespace>-<release-fullname>-roots-claim` and it will be deleted on the deletion of the chart.

Use pathPattern to customize where the roots will be extracted under the NFS access point (e.g. `pathPattern: "analytics-roots/${.PVC.namespace}-${.PVC.name}"` will create the persistent volumes under <nfs-root>/analytics-roots on the NFS server). 
### Create a secret from the license file
If no analytics license secret exists in the cluster, create one by running
```
kubectl create secret generic analytics-license-file --from-file=<path-to-license-file>
```

### Setup values.yaml
- Set `licenseSecretName` to the name of the secret created from the license file
    - in the above example it would be `analytics-license-file`
- Set `storageClassName` to `analytics-roots-nfs-example-sc`
- Set `rootsAccessMode` to `ReadWriteMany`
- Set `rootsUseSelectorLabels` to `false`. The NFS provisioner doesn't support selector labels.
- Set the `probes` values to make sure the container has enough time to avoid a restart loop because the server doesn't have enough time to startup
- Set `rootsResourceRequest` depending on the number of [endpoints and languages enabled](#disk-space-requirements)

### Run helm install
Depending on the number of endpoints and roots enabled the install process can be lengthy so make sure to set a reasonable [timeout](https://helm.sh/docs/intro/using_helm/#helpful-options-for-installupgraderollback) considering your system resources

# Troubleshooting
**The populate-roots pod completes successfully but no roots have been extracted**

Check the logs of the containers. If they print something along the lines of: `/roots-vol/.root-rbl-7.47.2.c73.0.unpacked exists.  Root already unpacked.`,
it means that hidden marker files are already present from a previous installation. To fix this, delete the marker files and run the job again.

If the pod gets deleted before the logs could be read, you can turn off the pod deletion by changing the 
rootExtraction.\<operation\>.annotations."helm.sh/hook-delete-policy" to before-hook-creation.
When doing this do make sure that the other helm hook annotations ("helm.sh/hook" and "helm.sh/hook-weight") are set correctly as well.

**The populate-roots pod is stuck or constantly errors out**

Check the logs of the pod. If it prints Permission Denied messages the user in the container doesn't have privileges to write to the disk.
The default user id in the containers is `2001` so make sure that the user with this id has write permissions to the persistent volume.
You can use an [init container](#persistent-volume-permissions-parameters) to overwrite the permissions of the volume.

**The Analytics Server container only logs a few lines**

If the Analytics Server container's log only shows until the following text: `wrapper  | --> Wrapper Started as Console`, 
it is possible your console cannot handle the VT100 escape code the Tanuki Wrapper uses to set the console title. 
To fix this, remove `wrapper.console.title` key from `wrapper.conf` in the `conf` section of the values.yaml file.

**The API keys database always reports it is running in cluster mode when trying to connect to it**

The chart uses H2 clustering to achieve zero-downtime upgrades to the database. There is a small window of time when the
secondary database is running while the main database updates, where if a backup/copy is made from the main database, the copy 
will be in a state where it expects to be accessed through cluster mode. To remove this clustering flag (which only 
allows accessing the database with the given URL) from the database file, run the following command with the parameters from your deployment:
```bash
java -cp <h2-jar> org.h2.tools.Shell -url "jdbc:h2:<The-url-for-your-database>;CLUSTER=''"\
  -user <DB-USER> -password <DB-PASSWORD> -sql "SELECT 1";
```
## Troubleshoot Argo CD
**The chart fails to install with missing roots when using Argo CD**

The chart relies on the Helm hook lifecycle to not wait for most things to be healthy before continuing with post-install/upgrade hooks. 
Argo CD converts post-install/upgrade hooks to postSync ones, which will only run after the resources are healthy. This can cause a deadlock
with the Analytics Server failing to start as the roots are not extracted and the roots not being extracted because the Analytics Server is not running.
To avoid this situation you should set the `rootsExtraction.upgrade.annotations` values to remove the default Helm hooks that are assigned. E.g.:
```yaml
rootExtraction:
  upgrade:
    annotations:
      defaults: "false"
```
The key and value you provide as an annotation is not important as long as it is not a Helm or Argo CD hook.