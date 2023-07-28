# Instructions
This process will pull the Rosette Server image matching the appVersion specified in the [Chart file](/helm/rosette-server/Chart.yaml)  from dockerhub ([Rosette Server](https://hub.docker.com/r/rosette/server-enterprise/tags)) and update the configuration in order to be deployed using Helm.

1. Copy the `rosette-license.xml` file to the directory with `stage-rosette-server.sh`.
2. Edit the `endpoints-to-install.txt` and indicate the licensed endpoints to install.
3. Edit the  `languages-to-install.txt` and indicate the licensed languages to install.
4. Run `stage-rosette-server.sh`. This script will make the required changes to the default Rosette Server configuration, and create a staging directory holding the Rosette Server docker image and the persistent volume contents.
5. Deploy the staged persistent volume files to the NFS Server and extract them 
6. If applicable, load the Rosette Server docker image from the containers directory, tag it with the repository you will be using and push it.
7. Configure the helm chart with the name of the NFS Server, the mount point and size of the persistent volume and update the repository the docker image is stored in.
8. Once the configuration files have been modified and models extracted then RS can be deployed using the instructions in the `helm` directory. Alternatively, RS' configuration can be tested using the `docker` deployment described in the `./docker` directory.

## Other Scripts

The script `clean-setup.sh` will delete the endpoints-to-install.txt file and comment out all languages to install. 

The script `setup.sh` will create the endpoints-to-install.txt file and comment out all languages to install.

## Other Notes
If you are deploying a subset of endpoints you are licensed for on a k8s pod or container then refer to `./misc/README.md` for information on how to restrict the allowed endpoints. 

|Directory|Purpose|
|---------|-------|
|docker|This directory contains docker files used to run Rosette Server locally (e.g. laptop running Docker). In this configuration the models, data files, and configuration information are mounted as simple volumes from the host OS. This configuration is used as a 'quick start' to get Rosette Server up and running locally to verify the extraction before running k8s.|

## Background
### Making Rosette Server compliant with Containerization Best Practices

When referring to containerization best practices documents such as "Best practices for operating containers" (Google, Best practices for operating containers 2021). There are certain properties of containers that are considered to be of high importance. Those properties are: 

* Containers should be stateless
  * Any persistent data should be external to the container
* Containers should be immutable
  * Containers should not change. This includes changes to configuration or updates.
* Containers should use the native logging mechanisms
  * Native logging using stdout/stderr allows easier log aggregation
* Containers should enable monitoring
  * Liveness and Readiness Probes to ensure the operational readiness of the container.

## Rosette Server
### Overview
Rosette Server (RS) consists of four basic components, *`configuration`* (configuration controlling the operation of the endpoints and configuration controlling the execution of the RS process itself), the *`data models`* used by RS endpoints (roots), the *`RS license file`* and the *`RS process`* itself (the RS container). 

### Stateless and Immutable
In order to make the RS container stateless and immutable the configuration and data models are externalized from the container. In our k8s deployments the configuration files are exposed using ConfigMaps and shared between Pods. The data models (roots) are exposed using Persistent Volume Claims using static Persistent Volumes and shared between Pods. In sharing the data models the startup time of the Pods is greatly reduced. Persistent Volumes can use many different types of volumes, Azure Disk, GCE Persistent Disk, AWS EBS etc. See [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/).

Note: while ConfigMaps are the typical mechanism for sharing configuration information in k8s it is possible to share RS configuration using Persistent Volumes as well since no secret information is exposed.

### Disabling or Redirecting Tracking
RS allows tracking of API calls by profile. The default logging location for usage tracking is located in the `./config` directory. This is a known issue as this will not work in a k8s deployment. In k8s either usage tracking should be disabled completely or directed to a persistent location outside of the container. To disable usage tracking edit the `./config/com.basistech.ws.local.usage.tracker.cfg` file and set `enabled: false`.

### Using Native Logging Mechanisms
The default behavior of RS is to log to a file on disk which can be disabled by modifying the `/conf/wrapper.conf` file and setting `wrapper.logfile=../logs/wrapper.log` to be empty e.g. `wrapper.logfile=`. This will force RS to log to stdout/stderr. Note: this change also supports immutable containers.

### Containers Should Enable Monitoring
Currently the same endpoint is used for liveness and readiness `/rest/metrics/health/worker` this endpoint will return the following information:
```
{
  "healthy": true,
  "message": null,
  "error": null,
  "details": null,
  "timestamp": "2021-05-26T16:53:46.908Z"
}
```

### Advanced Configuration
It should be noted that the files contained in the `./conf`, `./config` and `./config/rosapi` directories behave just like the typical RS configuration. Therefore, any RS configuration documentation will apply to the files in these directories.

### Worker thread count
 The `workerThreadCount` setting is the number of threads in the worker that are created to do the actual work. The default is 2 and it is not recommended to go above 2-3x the number of available cores. To change this setting edit the file `./config/com.basistech.ws.worker.cfg` and change `workerThreadCount` to the desired value. Note: make sure the line is uncommented.

### Warm Up Worker
The `warmUpWorker` setting controls if the worker threads are warmed up when the server starts or if they are warmed up on the first request. The default is false which means the first call will initialize the worker thread. The tradeoff is server startup time vs. initial request time. If warm up is set to true then the first request will take longer. If set to false then the server will take longer to start overall.

To change this setting edit the file `./config/com.basistech.ws.worker.cfg` and change `warmUpWorker` to the desired value.

### Rosette Server Process Configuration
There are several settings to control the execution of the RS process itself. The two most common are the minimum and maximum Java Virtual Machine (JVM) memory. See [Tanuki](https://wrapper.tanukisoftware.com/doc/english/properties.html) for a complete list. Note: not all combinations of settings have been tested with RS so some configurations may result in undefined results.

### Java Virtual Machine Memory
To set the minimum and maximum memory edit the `./conf/wrapper.conf`.
* wrapper.java.maxmemory
  * This will set the maximum amount of memory (in megabytes) that the JVM allocates
  * To set maximum memory to 16G, 16*1024=16384
  * `wrapper.java.maxmemory=16384`
* wrapper.java.initmemory
  * This will set the initial amount of memory (in megabytes) allocated by the JVM at startup
  * Note typically initmemory and maxmemory are equal to reduce the JVM from performing expensive memory allocations

# References

Google. (2021, May 25). Best practices for operating containers. Cloud Architecture Center. https://cloud.google.com/architecture/best-practices-for-operating-containers#:~:text=Immutable%20means%20that%20a%20container,deployments%20safer%20and%20more%20repeatable. 