# Overview
The `run-docker.sh` script assumes `./roots`, `./config`, `./config/rosapi`, and `./conf` have been created/populated and the rosette-license.xml has been copied to `./config/rosapi/`. These directories can be created by running `../rosette-server/install-config.sh` and `../rosette-server/extract-roots.sh` and installing the roots and configuration to the `docker` directory. You will have received the `rosette-license.xml` file from Basis Technology. 

The `run-docker.sh` performs the following:
```
docker run -d -p 8181:8181 \
-v ${BASE_DIR}/roots:/rosette/server/roots \
-v ${BASE_DIR}/config:/rosette/server/launcher/config \
-v ${BASE_DIR}/conf:/rosette/server/conf \
 rosette/server-enterprise:1.24.1 bash \
 -c '/rosette/server/bin/launch.sh console'
```

In this example three volumes are mounted:

`/rosette/server/roots` which must be mapped to the directory where the roots were extracted (this will be a Persistent Volume in the k8s/helm deployments).

`/rosette/server/launcher/config` which must be mapped to the directory where the configuration was extracted. In the k8s/helm deployments these are mapped to ConfigMaps.

The third volume, `/rosette/server/conf` is used to expose Rosette Server's configuration file to the host file system. As the other configuration, in the k8s/helm deployments this is mapped to a ConfigMap.

## Trouble Shooting
Note, this general troubleshooting mechanism can be used for the k8s deployments as well.
`curl http://localhost:8181/rest/v1/ping` should return a message similar to `"{"message":"Rosette at your service","time":1609336474002}"`
When the command `curl http://localhost:8181/rest/v1/ping` is run there may be a couple of different outputs until Rosette Server has started.
* Before the server (jetty) can accept requests you will get : `curl: "(52) Empty reply from server"`
* Once the server (jetty) can accept requests, but before Rosette is ready you will get an HTML error message.
* After waiting approximately 40 seconds and once everything has started, you will get the message `"{"message":"Rosette at your service","time":1609337322171}"`  Note: the k8s deployment.yaml file has other healthcheck and liveness URLs listed.

### Other things to look for
1. You shouldn't see any ERROR in the logs. Once the server is ready you should see something similar to:

```
INFO   | jvm 1    | 2020/12/30 14:08:09 | WrapperManager: Initializing...
INFO   | jvm 1    | 2020/12/30 14:08:37 | [WARN ] 2020-12-30 14:08:37.777 [WrapperListener_start_runner] com.basistech.ws.launcher.RosapiProductionLauncher - Rosette Server is ready
```
The log is useful when it comes to diagnosing startup issues. Common problems could include a missing license file or unable to find roots.

2. On the host machine running `docker ps` should list the running container. The STATUS should be 'Up'. Bash and curl are installed on the container. Using the CONTAINER ID you can `docker exec -it <container id> bash`  and on the container itself execute `curl http://localhost:8181/rest/v1/ping` In the container, the license file should be in `/rosette/server/launcher/config/rosapi/rosette-license.xml`.