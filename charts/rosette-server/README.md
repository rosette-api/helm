# Introduction
Rosette uses natural language processing, statistical modeling, and machine learning to analyze unstructured and semi-structured text across hundreds of language-script combinations, 
revealing valuable information and actionable data. Rosette provides endpoints for extracting entities and relationships, translating and comparing the similarity of names, categorizing 
and adding linguistic tags to text and more. Rosette Server is the on-premises installation of Rosette, with access to Rosette's functions as RESTful web service endpoints. 
This solves cloud security worries and allows customization (models/indexes) as needed for your business.

This chart bootstraps a Rosette Server deployment, and also populates a persistent volume with the Rosette Roots required for the Rosette Server's successful operation.

# Prerequisites
- A Rosette License secret available in the namespace where the installation will happen and `licenseSecretName` set in **values.yaml** or
provided during installation like `--set licenseSecretName=<license secret name>`.
If you don't have a license already available in the namespace, you can create one with
  ```
  kubectl create secret generic rosette-license-file --from-file=<license-file>
  ```
    - _Your license file will be included in the shipment from Rosette Support._
- A static persistent volume or a storage class capable of dynamically provisioning persistent volumes for the Rosette Roots and the corresponding
key set in **values.yaml** or provided during installation like `--set storageClassName=<storage class>` and/or `--set rootsVolumeName=<volume>`.
For more instructions on how to dynamically setup the roots storage, see [examples](#rosette-roots-storage-examples).

# Installation
Before installing or updating the chart you can set the desired endpoints and languages in **values.yaml** by uncommenting the values or by providing them to the command like
`--set "enabledEndpoints={language,morphology}" --set "enabledLanguages={eng,fra}"`. This will start a post hook job, that extracts the necessary Rosette Roots
 to the persistent volume provided. See more details about the job at the [root extraction section](#rosette-roots-extraction)

To add the repo to helm, run
```shell
helm repo add babelstreet https://charts.babelstreet.com
```

and then you can install the chart with
```shell
helm install rosette-server babelstreet/rosette-server --timeout=1h
```

This command will create a deployment for Rosette Server and a persistent volume claim for the Rosette Roots persistent volume.
The extraction of the roots can be a lengthy process, depending on which endpoints and languages are enabled and also on available system resources.
Make sure to set a long enough timeout for the process to finish considering your resources.

# Uninstall
To uninstall the release, run
```shell
helm uninstall rosette-server
```
To fully remove all Rosette Server associated components from the cluster, you will need to manually delete the secret and potentially
the Rosette Roots persistent volume, depending on its reclaim policy.

# Parameters

## Common parameters

| Name                                          | Description                                                                                                                                                                                                | Value                     |
|-----------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------|
| replicaCount                                  | Number of desired Rosette Server pods                                                                                                                                                                      | 1                         |
| image.repository                              | The repository and image name for the Rosette Server containers                                                                                                                                            | rosette/server-enterprise |
| image.pullPolicy                              | The pull policy for the Rosette Server image                                                                                                                                                               | IfNotPresent              |
| image.tag                                     | The tag of the Rosette Server image. If not provided, defaults to `appVersion` from **Chart.yaml**.                                                                                                        | ""                        |
| imagePullSecrets                              | An optional list of references to secrets in the same namespace to use for pulling any of the images                                                                                                       | []                        |
| nameOverride                                  | String to partially override rosette-server.fullname template used in naming Kubernetes objects. The release name will be maintained.                                                                      | ""                        |
| fullnameOverride                              | String to override rosette-server.fullname template used in naming Kubernetes objects                                                                                                                      | ""                        |
| serviceAccount.create                         | Specifies whether a service account should be created for Rosette Server pods                                                                                                                              | true                      |
| serviceAccount.annotations                    | Annotations to add to the service account                                                                                                                                                                  | {}                        |
| serviceAccount.name                           | The name of the service account to use. If not set and create is true, a name is generated using the fullname template                                                                                     | ""                        |
| podAnnotations                                | Annotations added to the Rosette Server pods                                                                                                                                                               | {}                        |
| podSecurityContext                            | Security context for the Rosette Server pods                                                                                                                                                               | {}                        |
| securityContext                               | Security context to for the Rosette Server containers                                                                                                                                                      | {}                        |
| initContainer.image                           | The image to run init scripts. Must be capable of running bash files and curl queries. If not provided the Rosette Server image is used.                                                                   | ""                        |
| initContainer.tag                             | Tag of the init container's image                                                                                                                                                                          | ""                        |
| service.type                                  | Type of the Rosette Server service                                                                                                                                                                         | ClusterIP                 |
| service.port                                  | The port on which Rosette Server is available in the containers. Need to match what is in `conf.wrapper.conf`.                                                                                             | 8181                      |
| ingress.enabled                               | Set to true to enable ingress object creation for the Rosette Server service                                                                                                                               | false                     |
| ingress.className                             | The ingress class to use for the ingress object                                                                                                                                                            | ""                        |
| ingress.annotations                           | Annotations added to the ingress object. Check your Ingress controllers annotations for configuring your ingress object.                                                                                   | {}                        |
| ingress.hosts                                 | The ingress rules to use                                                                                                                                                                                   | []                        |
| ingress.hosts.[].host                         | The host the rule applies to                                                                                                                                                                               |                           |
| ingress.hosts.[].paths                        | The paths used for the given host. All map to the Rosette Server service.                                                                                                                                  |                           |
| ingress.hosts.[].paths.[].path                | A path to map to the Rosette Server service with the  given host                                                                                                                                           |                           |
| ingress.hosts.[].paths.[].pathType            | The type of the given path. Determines path matching behaviour.                                                                                                                                            |                           |
| ingress.tls                                   | Ingress TLS configurations                                                                                                                                                                                 | []                        |
| ingress.tls.[].secretName                     | The TLS secret to use with the given hosts. For how to create the secret, check the [Kubernetes documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls).                      |                           |
| ingress.tls.[].hosts                          | A list of hosts using the secret                                                                                                                                                                           |                           |
| resources                                     | Resource requests and limitations for the Rosette Server containers. For more detail on how you can calculate your resource requirements, see the [Resource requirements section](#resource-requirements). |                           |
| resources.requests.ephemeral-storage          | The ephemeral storage requested for the Rosette Server containers                                                                                                                                          | 2Gi                       |
| autoscaling.enabled                           | Set to true to enable horizontal pod autoscaling for the Rosette Server pods                                                                                                                               | false                     |
| autoscaling.minReplicas                       | The lower limit for the number of replicas to which the autoscaler can scale down                                                                                                                          | 1                         |
| autoscaling.maxReplicas                       | The upper limit for the number of pods that can be set by the autoscaler                                                                                                                                   | 100                       |
| autoscaling.targetCPUUtilizationPercentage    | The target average CPU utilization (represented as a percentage of requested CPU) over all the pods                                                                                                        | 80                        |
| autoscaling.targetMemoryUtilizationPercentage | The target average memory utilization (represented as a percentage of requested memory) over all the pods                                                                                                  | 80                        |
| nodeSelector                                  | Selector which must match a node's labels for the Rosette Server pods to be scheduled on that node                                                                                                         | {}                        |
| tolerations                                   | Tolerations for Rosette Server pods                                                                                                                                                                        | []                        |
| affinity                                      | Affinity constraints for Rosette Server pods                                                                                                                                                               | {}                        |
| probes.initialDelaySeconds                    | Number of seconds after the container has started before liveness/readiness probes are initiated                                                                                                           | 60                        |
| probes.timeoutSeconds                         | Number of seconds after which the liveness/readiness probe times out                                                                                                                                       | 5                         |
| probes.periodSeconds                          | How often to perform the liveness/readiness probe                                                                                                                                                          | 30                        |
| probes.failureThreshold                       | Minimum consecutive failures for the liveness/readiness probe to be considered failed after having succeeded                                                                                               | 3                         |

## Rosette Roots extraction parameters

| Name                                  | Description                                                                                                                                                                                                                             | Value         |
|---------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------|
| rosette.roots.rex                     | The version of the REX root                                                                                                                                                                                                             | 7.55.8.c71.0  |
| rosette.roots.rbl                     | The version of the RBL root                                                                                                                                                                                                             | 7.47.0.c71.0  |
| rosette.roots.rli                     | The version of the RLI root                                                                                                                                                                                                             | 7.23.10.c71.0 |
| rosette.roots.tvec                    | The version of the TVEC root                                                                                                                                                                                                            | 6.0.1.c71.0   |
| rosette.roots.rnirnt                  | The version of the RNI-RNT root                                                                                                                                                                                                         | 7.43.0.c71.0  |
| rosette.roots.tcat                    | The version of the TCAT root                                                                                                                                                                                                            | 2.0.17.c71.0  |
| rosette.roots.ascent                  | The version of the ASCENT root                                                                                                                                                                                                          | 2.0.7.c71.0   |
| rosette.roots.nlp4j                   | The version of the NLP4J root                                                                                                                                                                                                           | 1.2.12.c71.0  |
| rosette.roots.rct                     | The version of the RCT root                                                                                                                                                                                                             | 3.0.16.c71.0  |
| rosette.roots.relax                   | The version of the RELAX root                                                                                                                                                                                                           | 3.0.4.c71.0   |
| rosette.roots.topics                  | The version of the TOPICS root                                                                                                                                                                                                          | 2.0.3.c71.0   |
| enabledEndpoints                      | A list of Rosette Server endpoints to enable                                                                                                                                                                                            | [language]    |
| enabledLanguages                      | A list of languages to be enabled for roots split by languages                                                                                                                                                                          | [eng]         |
| rootsExtractionSecurityContext        | Security context for the root extraction pod                                                                                                                                                                                            | {}            |
| rootsImageRepository                  | The repository prefix to use when downloading Rosette Roots images. The default "rosette/" will download from DockerHub                                                                                                                 | "rosette/"    |

## Overrides for configurations located in Root storage parameters

| Name                                  | Description                                                                                                                                                                                                                             | Value         |
|---------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------|
| rootsOverride.enabled                 | Set to true to enable custom override logic for configurations inside the root directories, that supports helm upgrade/rollback. More details are in the [Root configurations override section](#root-configurations-overrides).        | false         |
| rootsOverride.overrideVolumeClaimName | A preexisting volume claim's name (in the namespace of the release), prepopulated with the config files/directories used for *override*, or *addition* operations. If not defined *addition* and *override* operations will be skipped. | ""            |
| rootsOverride.backupVolumeClaimName   | A preexisting volume claim's name (in the namespace of the release), where rollback information should be saved. If not defined rollback information is saved to the Rosette Roots volume.                                              | ""            |
| rootsOverride.separator               | A character sequence not included in any of the file paths                                                                                                                                                                              | "&&&"         |
| rootsOverride.delete                  | A list of *deletion* operations to delete a file or directory from a Rosette Root                                                                                                                                                       | []            |
| rootsOverride.delete.[].root          | The name of the root where the entry should be deleted from                                                                                                                                                                             |               |
| rootsOverride.delete.[].targetPath    | The path under the `<root>/<version>` directory to the entry to be deleted. Must be a valid file or directory.                                                                                                                          |               |
| rootsOverride.add                     | A list of *addition* operations to add a file or directory to a Rosette Root                                                                                                                                                            | []            |
| rootsOverride.add.[].root             | The name of the root where the entry should be added to                                                                                                                                                                                 |               |
| rootsOverride.add.[].targetPath       | The path under the `<root>/<version>` directory where the entry should be added. A file or directory must not exist on that path.                                                                                                       |               |
| rootsOverride.add.[].originPath       | The path in the override volume where the entry should be copied from                                                                                                                                                                   |               |
| rootsOverride.override                | A list of *override* operations to override a file or directory in a Rosette Root                                                                                                                                                       | []            |
| rootsOverride.override.[].root        | The name of the root where the entry should be overwritten                                                                                                                                                                              |               |
| rootsOverride.override.[].targetPath  | The path under the `<root>/<version>` directory where the entry should be overwritten. Must be a valid file or directory.                                                                                                               |               |
| rootsOverride.override.[].originPath  | The path in the override volume where the entry should be copied from. The entry must be the same type (file or directory) as the target                                                                                                |               |

## Rosette Server parameters

| Name                      | Description                                                                                                                                                                                                      | Value           |
|---------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------|
| licenseSecretName         | The name of a secret created from the Rosette License file                                                                                                                                                       | ""              |
| storageClassName          | The storage class of the Rosette Roots persistent volume claim. Immutable after installation.                                                                                                                    | ""              |
| rootsVolumeName           | The name of the persistent volume the Rosette Roots persistent volume claim should bind to. Immutable after installation.                                                                                        | ""              |
| rootsAccessMode           | The access mode of the Rosette Roots persistent volume claim. Can be ReadWriteOnce or ReadWriteMany. Immutable after installation.                                                                               | "ReadWriteMany" |
| rootsResourceRequest      | The requested storage size for the Rosette Roots persistent volume claim. For more detail on how you can calculate your storage requirements, see the [Resource requirements section](#disk-space-requirements). | "150Gi"         |
| conf                      | Rosette Server logging and Tanuki Wrapper configuration files                                                                                                                                                    |                 |
| conf.java_opts.conf       | A file used by Tanuki internally                                                                                                                                                                                 |                 |
| conf.log4j2.xml           | The log4j logger's configuration file used by the Rosette Server instance                                                                                                                                        |                 |
| conf.logging.properties   | Logging properties file supplied to the JVM                                                                                                                                                                      |                 |
| conf.wrapper.conf         | The Tanuki Wrapper's configuration file                                                                                                                                                                          |                 |
| conf.wrapper-license.conf | The Tanuki configuration file. Do not change.                                                                                                                                                                    |                 |
| config                    | Rosette Server system configuration files. For more detail see the [User Guide](https://support.rosette.com/hc/en-us/articles/360049878432-Configuration-files#UUID-eeb37d25-91f6-75ae-5f91-6ca3b853f9d9)        |                 |
| rosapi                    | Individual endpoint configuration files. For more detail see the [User Guide](https://support.rosette.com/hc/en-us/articles/360049878432-Configuration-files#UUID-2891ac06-0339-4a4c-8344-8cfdb8a0dec9)          |                 |

# Rosette Roots extraction
This chart needs a persistent volume to store the Rosette Roots. It can be provided in two ways:
- By setting `rootsVolumeName` and `storageClassName`, you can provide a previously created Persistent Volume that has the matching name and storage class.
- By setting `storageClassName` to a storage class that is capable of dynamic provisioning and leaving `rootsVolumeName` empty.

The `storageClassName`, `rootsVolumeName` and `rootsAccessMode` properties are immutable after installation.

The roots needed for your selected endpoints and languages will be automatically extracted to the persistent volume backing the persistent volume claim
managed by the chart. This happens in a post hook job. The job uses the rosette/root images to check if the extraction of a given root is needed and to extract it.
This can be a time-consuming process, especially if the images have to be pulled as well. The job gets terminated when the helm release times out, so make
sure the [timeout](https://helm.sh/docs/intro/using_helm/#helpful-options-for-installupgraderollback) on the helm command provides enough time for the process to finish considering your system resources.

To allow the root extraction process to work properly, `rootsAccessMode` should, preferably, be `ReadWriteMany`. If the persistent volume doesn't allow `many` access, `ReadWriteOnce`
works as well. In this case, the job is scheduled to the same node as the Rosette Server pod(s), with a required affinity. Make sure that this node has enough
resources for the job, otherwise a deadlock situation can arise if the extraction of new roots are expected.

**TODO:  SETH pushed the `InitContainer` execution that does the perm change.  Decide if that's the right thing.** 

The runtime user for the Root extraction images and Rosette Server is `2001`. If user `2001` doesn't have write access on the volume, the extraction will fail. To avoid this, you can give user id `2001` write access on your volume,
or set `rootsExtractionSecurityContext` in **values.yaml**, and change the user inside the containers.

The Rosette Server startup fails if all required roots are not found, so the Rosette Server pods might restart a few times while the root extraction is ongoing. During the extraction of the
last root, Rosette Server will be able to start up, but endpoints relying on the root being extracted will fail if they receive a request before the extraction is complete.
To recover from this possible state, once all the extractions complete the  Rosette Server deployment is updated to register any potential changes. To make this possible it uses a
service account which is able to patch the Rosette Server deployment.

## Root configurations overrides
There might be some need to change/add/delete some files from the Rosette Roots. For example the Rosette Names services have some configuration files inside their root and
the Rosette Entity Extractor can be customized by adding [new gazetteer or regex files to its root](https://support.rosette.com/hc/en-us/articles/360052969712-Modifying-Entity-Extraction-Processors).
The `rootsOverride` section (and the corresponding functionality) in **values.yaml** aims to help make these file changes inside the Rosette Roots in a way, that works with the helm update/rollback process.
The functionality is disabled by default, and can be enabled by setting `rootsOverride.enabled` to true. It has 3 possible operations:

- *deletion*: Deletes a file or directory inside the Rosette Root directory if one exists at the specified path
- *addition*: Adds a file or directory inside the Rosette Root directory if one doesn't already exists at the specified path
- *override*: Replaces a file or directory inside the Rosette Root directory if one exists at the specified path

The operations run in the above mentioned order. All operations have 2 common parameters:
- `root`: The name of the Rosette Root, in which the files should be changed. Possible values are the same as the keys of `rosette.roots` in **values.yaml**.
- `targetPath`: The path inside the `<root>/<version>` directory where the operation should be done. Cannot contain `..`. Leading `/` is ignored. Cannot be empty.

The *addition* and *override* operations require a volume which has been prepopulated with the files or directories to be added/to be used for overriding. A volume claim bounded to this volume
must be provided with `rootsOverride.overrideVolumeClaimName`. These operations also have a third parameter:
- `originPath`: The path inside the override volume to the file/directory to be used for the addition/override. Leading `/` is ignored. Cannot be empty.

All operations are done in the currently active Rosette Root versions only.

A backup volume can be provided to the functionality through its volume claim set in `rootsOverride.backupVolumeClaimName`. If one is not provided but the functionality is enabled,
a backup directory will be created in the Rosette Roots volume. Every release with the functionality enabled will create a new directory with the release name in the backup volume.
If a directory with the release name already exists (e.g.: from a previously deleted release) when a new release is installed, the old directory is pruned before a new one is created.
The backup volume should not be changed after the functionality is enabled.

### Limitations
- Editing files in the Rosette Roots volume without the use of this functionality when it is enabled, can lead to unrecoverable errors!
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
    - During the installation, make sure the `/entities` endpoint is enabled, and `rootsOverride.overrideVolumeClaimName` is set to the previously created PVC.
- Make an `/entities` request to observe the default behavior.  The response should return a single entity of type `LOCATION` for `Italy`.
  ```
  curl -H "content-type: application/json" \
       -d '{"content":"Pizza and lasagna originates from Italy"}' \
       <rosette-server-service>/rest/v1/entities
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

# Resource requirements

## Memory requirements

The following table details the JVM heap memory requirements needed by the different endpoints.
If the container reaches its memory limit, it sends a SIGKILL to the JVM process running Rosette Server, which then gets restarted.
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

Rosette Base Linguistics and Rosette Language Identification are always extracted for base functionality. These take up **5GB** and cover the
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

# Rosette Roots storage examples
## hostPath
### Important
`hostPath` volumes are node specific, so in a multinode cluster if the pod gets rescheduled to another node, the contents of the volume need to be repopulated on that node as well.
In a multinode cluster if `rootsAccessMode` is set to `ReadWriteOnce`, the job will be required to schedule on the same node as the Rosette Server pod, but in other cases
the unpacking of the roots cannot be guaranteed to happen on the same node where the Rosette Server pod will be scheduled.
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
     ./rosette-server
```
This will create directory for the Rosette roots persistent volume claim under `/mnt/hostpath`

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

The provided example uses the persistent disk approach. It dynamically provisions a balanced persistent disk, with the label `component: rosette-server`.
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
        name: rosette-roots-gcp-pd-example-sc
      provisioner: pd.csi.storage.gke.io
      volumeBindingMode: WaitForFirstConsumer
      allowVolumeExpansion: true
      parameters:
        type: pd-balanced
        labels: component=rosette-server
      EOF
      ```
    - create the storage class
      ```
      kubectl create -f gcp-persistent-disk-storage-class.yaml
      ```
- Create a secret from a license file if one doesn't already exist
  ```
  kubectl create secret generic rosette-license-file --from-file=<path-to-license-file>
  ```
- Remove the `spec.selector` object from `templates/pvc-roots.yaml` as the driver does not support it
- Set up **values.yaml**
    - Set `licenseSecretName` to the name of the secret created from the license file
        - in the above example it would be `rosette-license-file`
    - Set `storageClassName` to `rosette-roots-gcp-pd-example-sc`
    - Set `rootsAccessMode` to `ReadWriteOnce` and `replicaCount` to `1`. The persistent disk driver doesn't support `ReadWriteMany`. This will force Kubernetes to schedule all pods to the same node.
        - Make sure that the node has enough resources to run the root extraction pod and 2 of the rosette-server pods for rolling the deployment.
    - Set the `probes` values to make sure the container has enough time to avoid a restart loop because the server doesn't have enough time to startup.
    - Set `rootsResourceRequest` depending on the number of [endpoints and languages enabled](#disk-space-requirements)
- Run `helm install`.
    - Depending on the number of endpoints and roots enabled the installation process can be lengthy so make sure to set a reasonable
    [timeout](https://helm.sh/docs/intro/using_helm/#helpful-options-for-installupgraderollback) considering your system resources.

If the populate-roots pod is stuck or constantly errors out, make sure to set the userId in the pod or containers to one that can write to the disk
- run `kubectl logs pod <populate-roots-pod> <container>`. If it prints Permission Denied messages the user in the container doesn't have privileges to write to the disk
- set `rootsExtractionSecurityContext` in **values.yaml** to change the pod's securityContext
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
       --set storageClass.provisionerName=rosette-nfs-subdir-external-provisioner
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
    name: rosette-roots-nfs-example-sc
  provisioner: rosette-nfs-subdir-external-provisioner
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

### Create a secret from the license file
If no rosette license secret exists in the cluster, create one by running
```
kubectl create secret generic rosette-license-file --from-file=<path-to-license-file>
```
### 4. Fix PVC template
Remove the `spec.selector` object from `templates/pvc-roots.yaml` as the provisioner does not support it.  Ensure you retain `spec`.

### 5. Setup values.yaml
- Set `licenseSecretName` to the name of the secret created from the license file
    - in the above example it would be `rosette-license-file`
- Set `storageClassName` to `rosette-roots-nfs-example-sc`
- Set `rootsAccessMode` to `ReadWriteMany`
- Set the `probes` values to make sure the container has enough time to avoid a restart loop because the server doesn't have enough time to startup
- Set `rootsResourceRequest` depending on the number of [endpoints and languages enabled](#disk-space-requirements)

### 6. Run helm install
Depending on the number of endpoints and roots enabled the install process can be lengthy so make sure to set a reasonable [timeout](https://helm.sh/docs/intro/using_helm/#helpful-options-for-installupgraderollback) considering your system resources

### Note
If the populate-roots pod is stuck or constantly errors out, make sure to set the userId in the pod or containers to one that can write to the disk
- run `kubectl logs pod <populate-roots-pod> <container>`. If it prints Permission Denied messages the user in the container doesn't have privileges to write to the disk
- set `rootsExtractionSecurityContext` in **values.yaml** to change the pod's securityContext