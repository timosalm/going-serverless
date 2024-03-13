
## Container image building

```
export REGISTRY_HOST=harbor.main.emea.end2end.link/going-serverless
```

### Project CraC

```
docker build . -t $REGISTRY_HOST/inclusion-crac:checkpointer --file crac/Dockerfile
docker run --cap-add CHECKPOINT_RESTORE --cap-add SYS_PTRACE --volume $PWD/crac-files:/opt/crac-files -p 8080:8080 --rm --name inclusion-crac-checkpointer $REGISTRY_HOST/inclusion-crac:checkpointer
# Wait until checkpoint creation succeeded
docker commit --change='ENTRYPOINT ["/opt/app/entrypoint.sh"]' $(docker ps -qf "name=inclusion-crac-checkpointer") $REGISTRY_HOST/inclusion-crac
docker kill $(docker ps -qf "name=inclusion-crac-checkpointer")
```

## Container image building with kpack

### Without optimizations
```
kp image create inclusion --git https://github.com/timosalm/going-serverless --tag $REGISTRY_HOST/inclusion --env BP_JVM_VERSION=17
```

### GraalVM Native Image
```
kp image create inclusion-native --git https://github.com/timosalm/going-serverless --tag $REGISTRY_HOST/inclusion-native --env BP_JVM_VERSION=17 --env BP_NATIVE_IMAGE=true
```

## Running the application on Knative
### Without optimizations
```
kn service create inclusion --image $REGISTRY_HOST/inclusion
kubectl logs -l app=inclusion-00001 -c user-container | grep "Started InclusionApplication"
# Started InclusionApplication in 9.534 seconds (process running for 10.477)
watch kubectl get pods
hey -n 1000 -c 1000 -m GET $(kn service describe inclusion -o url)
kubectl top pods -l app=inclusion-00001 --containers
# POD                                           NAME             CPU(cores)   MEMORY(bytes)
# inclusion-00001-deployment-86b7c5fdd4-hgjsg   user-container   2m           404Mi
```

### GraalVM Native Image
```
kn service create inclusion-native --image $REGISTRY_HOST/inclusion-native
kubectl logs -l app=inclusion-native-00001 -c user-container | grep "Started InclusionApplication"
# Started InclusionApplication in 0.79 seconds (process running for 0.797)
watch kubectl get pods
hey -n 1000 -c 1000 -m GET $(kn service describe inclusion-native -o url)
kubectl top pods -l app=inclusion-native-00001 --containers
# POD                                                  NAME             CPU(cores)   MEMORY(bytes)
# inclusion-native-00001-deployment-58f9c764f4-d8sdz   user-container   1m           105Mi
```